use std::collections::BTreeMap;
use std::fs::{self, File, OpenOptions};
use std::io::{BufReader, Read, Write};
use std::path::{Path, PathBuf};
use std::time::SystemTime;

use flate2::read::GzDecoder;
use flate2::write::GzEncoder;
use flate2::Compression;
use tar::{Archive, Builder, EntryType, Header};

use crate::error::BackupError;
use crate::manifest::{
    sha256_hex, timestamp_id, unix_now, ArchivePath, BackupFile, BackupManifest, BACKUP_VERSION,
    MANIFEST_FILE, MAX_FILES, MAX_FILE_BYTES, MAX_MANIFEST_BYTES, MAX_TOTAL_BYTES,
};
use klyvera_config::{ensure_private_dir, write_bytes_atomic};
use klyvera_spaces::SpaceStore;

const ARCHIVE_SUFFIX: &str = ".tar.gz";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BackupSummary {
    pub id: String,
    pub path: PathBuf,
    pub created_at: u64,
    pub files: usize,
    pub size: u64,
    pub sha256: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BackupInfo {
    pub id: String,
    pub path: PathBuf,
    pub size: u64,
    pub modified_at: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct VerifyReport {
    pub manifest: BackupManifest,
    pub verified_files: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct RestoreReport {
    pub pre_restore_backup: BackupSummary,
    pub restored_config: bool,
    pub restored_spaces: usize,
    pub displaced_spaces: usize,
}

struct SourceFile {
    archive_path: String,
    bytes: Vec<u8>,
    sha256: String,
}

/// Create an integrity-checked backup of `config_file` and the Space files in
/// `spaces_dir`. Missing sources are allowed; unexpected file types are not.
pub fn create_backup(
    backups_dir: &Path,
    config_file: &Path,
    spaces_dir: &Path,
) -> Result<BackupSummary, BackupError> {
    require_absolute(backups_dir, "backups directory")?;
    require_absolute(config_file, "config file")?;
    require_absolute(spaces_dir, "spaces directory")?;
    ensure_private_dir(backups_dir)?;

    let created_at = unix_now();
    let sources = collect_sources(config_file, spaces_dir)?;
    let manifest = BackupManifest::new(
        created_at,
        sources
            .iter()
            .map(|source| BackupFile {
                path: source.archive_path.clone(),
                sha256: source.sha256.clone(),
                size: source.bytes.len() as u64,
            })
            .collect(),
    );
    manifest.validate()?;

    let id = unique_id(backups_dir, timestamp_id("backup", created_at));
    let path = backups_dir.join(format!("{id}{ARCHIVE_SUFFIX}"));
    let temporary = backups_dir.join(format!(".{id}.tmp.{}", nonce()));

    let result = write_archive(&temporary, &sources, &manifest, created_at);
    if let Err(error) = result {
        let _ = fs::remove_file(&temporary);
        return Err(error);
    }
    if let Err(error) = fs::rename(&temporary, &path) {
        let _ = fs::remove_file(&temporary);
        return Err(BackupError::io(&path, error));
    }
    sync_directory(backups_dir)?;

    let size = fs::metadata(&path)
        .map_err(|error| BackupError::io(&path, error))?
        .len();
    let sha256 = hash_file(&path)?;
    Ok(BackupSummary {
        id,
        path,
        created_at,
        files: manifest.files.len(),
        size,
        sha256,
    })
}

fn collect_sources(config_file: &Path, spaces_dir: &Path) -> Result<Vec<SourceFile>, BackupError> {
    let mut sources = Vec::new();
    if let Some(source) = read_source(config_file, "config/config.json", true)? {
        sources.push(source);
    }

    if spaces_dir.exists() {
        let metadata =
            fs::symlink_metadata(spaces_dir).map_err(|error| BackupError::io(spaces_dir, error))?;
        if !metadata.is_dir() || metadata.file_type().is_symlink() {
            return Err(BackupError::Invalid(format!(
                "spaces directory is not a directory: {}",
                spaces_dir.display()
            )));
        }
        let mut names = fs::read_dir(spaces_dir)
            .map_err(|error| BackupError::io(spaces_dir, error))?
            .flatten()
            .filter_map(|entry| entry.file_name().to_str().map(str::to_owned))
            .filter(|name| name.ends_with(".json") && !name.starts_with('.'))
            .collect::<Vec<_>>();
        names.sort();
        for name in names {
            let archive_path = format!("spaces/{name}");
            if ArchivePath::parse(&archive_path).is_err() {
                continue;
            }
            let path = spaces_dir.join(&name);
            if let Some(source) = read_source(&path, &archive_path, true)? {
                sources.push(source);
            }
        }
    }

    if sources.len() > MAX_FILES {
        return Err(BackupError::Invalid(format!(
            "backup would contain more than {MAX_FILES} files"
        )));
    }
    let total = sources
        .iter()
        .map(|source| source.bytes.len())
        .sum::<usize>();
    if total > MAX_TOTAL_BYTES {
        return Err(BackupError::Invalid(
            "backup exceeds the uncompressed size limit".to_owned(),
        ));
    }
    sources.sort_by(|left, right| left.archive_path.cmp(&right.archive_path));
    Ok(sources)
}

fn read_source(
    path: &Path,
    archive_path: &str,
    skip_missing: bool,
) -> Result<Option<SourceFile>, BackupError> {
    let metadata = match fs::symlink_metadata(path) {
        Ok(metadata) => metadata,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound && skip_missing => {
            return Ok(None)
        }
        Err(error) => return Err(BackupError::io(path, error)),
    };
    if metadata.file_type().is_symlink() || !metadata.is_file() {
        return Err(BackupError::Invalid(format!(
            "backup source is not a regular file: {}",
            path.display()
        )));
    }
    if metadata.len() > MAX_FILE_BYTES as u64 {
        return Err(BackupError::Invalid(format!(
            "backup source is too large: {}",
            path.display()
        )));
    }
    let bytes = fs::read(path).map_err(|error| BackupError::io(path, error))?;
    if bytes.len() > MAX_FILE_BYTES {
        return Err(BackupError::Invalid(format!(
            "backup source is too large: {}",
            path.display()
        )));
    }
    let sha256 = sha256_hex(&bytes);
    Ok(Some(SourceFile {
        archive_path: archive_path.to_owned(),
        bytes,
        sha256,
    }))
}

fn write_archive(
    path: &Path,
    sources: &[SourceFile],
    manifest: &BackupManifest,
    mtime: u64,
) -> Result<(), BackupError> {
    let mut options = OpenOptions::new();
    options.write(true).create_new(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let file = options
        .open(path)
        .map_err(|error| BackupError::io(path, error))?;
    let encoder = GzEncoder::new(file, Compression::default());
    let mut builder = Builder::new(encoder);

    for source in sources {
        append_file(&mut builder, &source.archive_path, &source.bytes, mtime)?;
    }
    let mut manifest_bytes = serde_json::to_vec_pretty(manifest)
        .map_err(|error| BackupError::json(MANIFEST_FILE, error))?;
    manifest_bytes.push(b'\n');
    append_file(&mut builder, MANIFEST_FILE, &manifest_bytes, mtime)?;

    let encoder = builder
        .into_inner()
        .map_err(|error| BackupError::io(path, error))?;
    let file = encoder
        .finish()
        .map_err(|error| BackupError::io(path, error))?;
    file.sync_all()
        .map_err(|error| BackupError::io(path, error))?;
    Ok(())
}

fn append_file(
    builder: &mut Builder<GzEncoder<File>>,
    path: &str,
    bytes: &[u8],
    mtime: u64,
) -> Result<(), BackupError> {
    let mut header = Header::new_gnu();
    header.set_entry_type(EntryType::Regular);
    header.set_mode(0o600);
    header.set_uid(0);
    header.set_gid(0);
    header.set_mtime(mtime);
    header.set_size(bytes.len() as u64);
    header.set_cksum();
    builder
        .append_data(&mut header, path, bytes)
        .map_err(|error| {
            BackupError::Invalid(format!("could not write archive entry '{path}': {error}"))
        })
}

/// Verify archive structure, path safety, sizes, the manifest and every hash.
pub fn verify_backup(archive_path: &Path) -> Result<VerifyReport, BackupError> {
    scan_archive(archive_path, None)
}

fn scan_archive(archive_path: &Path, staging: Option<&Path>) -> Result<VerifyReport, BackupError> {
    let file = File::open(archive_path).map_err(|error| BackupError::io(archive_path, error))?;
    let decoder = GzDecoder::new(BufReader::new(file));
    let mut archive = Archive::new(decoder);
    let entries = archive
        .entries()
        .map_err(|error| BackupError::Verify(format!("could not read archive: {error}")))?;

    let mut manifest: Option<BackupManifest> = None;
    let mut files: BTreeMap<String, (String, u64)> = BTreeMap::new();
    let mut total = 0u64;
    let mut count = 0usize;

    for entry in entries {
        let entry =
            entry.map_err(|error| BackupError::Verify(format!("invalid tar entry: {error}")))?;
        count += 1;
        if count > MAX_FILES + 1 {
            return Err(BackupError::Verify(
                "archive has too many entries".to_owned(),
            ));
        }
        if !entry.header().entry_type().is_file() {
            return Err(BackupError::Verify(
                "archive contains a non-regular entry".to_owned(),
            ));
        }
        let path = entry
            .path()
            .map_err(|error| BackupError::Verify(format!("invalid entry path: {error}")))?
            .to_str()
            .ok_or_else(|| BackupError::Verify("archive path is not UTF-8".to_owned()))?
            .to_owned();
        let kind = ArchivePath::parse(&path)?;
        let size = entry
            .header()
            .size()
            .map_err(|error| BackupError::Verify(format!("invalid entry size: {error}")))?;
        let limit = match kind {
            ArchivePath::Manifest => MAX_MANIFEST_BYTES,
            _ => MAX_FILE_BYTES,
        };
        if size > limit as u64 {
            return Err(BackupError::Verify(format!(
                "archive entry '{path}' exceeds its size limit"
            )));
        }
        total = total.saturating_add(size);
        if total > MAX_TOTAL_BYTES as u64 {
            return Err(BackupError::Verify(
                "archive exceeds the uncompressed size limit".to_owned(),
            ));
        }

        let mut bytes = Vec::with_capacity(size.min(1024 * 1024) as usize);
        entry
            .take(size + 1)
            .read_to_end(&mut bytes)
            .map_err(|error| BackupError::Verify(format!("could not read '{path}': {error}")))?;
        if bytes.len() as u64 != size {
            return Err(BackupError::Verify(format!(
                "archive entry '{path}' is truncated"
            )));
        }

        match kind {
            ArchivePath::Manifest => {
                if manifest.is_some() {
                    return Err(BackupError::Verify(
                        "archive contains more than one manifest".to_owned(),
                    ));
                }
                let parsed: BackupManifest = serde_json::from_slice(&bytes)
                    .map_err(|error| BackupError::json(MANIFEST_FILE, error))?;
                parsed.validate()?;
                manifest = Some(parsed);
            }
            kind => {
                if files.contains_key(&path) {
                    return Err(BackupError::Verify(format!(
                        "archive contains '{path}' twice"
                    )));
                }
                if let Some(staging) = staging {
                    write_staged(staging, &kind, &bytes)?;
                }
                files.insert(path, (sha256_hex(&bytes), size));
            }
        }
    }

    let manifest =
        manifest.ok_or_else(|| BackupError::Verify("archive has no manifest".to_owned()))?;
    if manifest.version != BACKUP_VERSION {
        return Err(BackupError::Verify(
            "archive manifest version does not match".to_owned(),
        ));
    }
    compare_manifest(&manifest, &files)?;
    Ok(VerifyReport {
        manifest,
        verified_files: files.len(),
    })
}

fn compare_manifest(
    manifest: &BackupManifest,
    files: &BTreeMap<String, (String, u64)>,
) -> Result<(), BackupError> {
    if files.len() != manifest.files.len() {
        return Err(BackupError::Verify(
            "archive file count does not match the manifest".to_owned(),
        ));
    }
    for expected in &manifest.files {
        let Some((hash, size)) = files.get(&expected.path) else {
            return Err(BackupError::Verify(format!(
                "archive is missing '{}'",
                expected.path
            )));
        };
        if *size != expected.size || hash != &expected.sha256 {
            return Err(BackupError::Verify(format!(
                "integrity check failed for '{}'",
                expected.path
            )));
        }
    }
    for path in files.keys() {
        if !manifest.files.iter().any(|file| &file.path == path) {
            return Err(BackupError::Verify(format!(
                "archive contains an unlisted file '{path}'"
            )));
        }
    }
    Ok(())
}

fn write_staged(staging: &Path, kind: &ArchivePath, bytes: &[u8]) -> Result<(), BackupError> {
    let relative = match kind {
        ArchivePath::Manifest => return Ok(()),
        ArchivePath::Config => PathBuf::from("config/config.json"),
        ArchivePath::Space(name) => PathBuf::from("spaces").join(name),
    };
    let destination = staging.join(relative);
    if let Some(parent) = destination.parent() {
        ensure_private_dir(parent)?;
    }
    let mut options = OpenOptions::new();
    options.write(true).create_new(true);
    #[cfg(unix)]
    {
        use std::os::unix::fs::OpenOptionsExt;
        options.mode(0o600);
    }
    let mut file = options
        .open(&destination)
        .map_err(|error| BackupError::io(&destination, error))?;
    file.write_all(bytes)
        .map_err(|error| BackupError::io(&destination, error))?;
    file.sync_all()
        .map_err(|error| BackupError::io(&destination, error))?;
    Ok(())
}

/// Restore a verified backup. A pre-restore backup is always created before
/// any live file is replaced, and the current Spaces are moved to trash.
pub fn restore_backup(
    archive_path: &Path,
    backups_dir: &Path,
    config_file: &Path,
    spaces_dir: &Path,
) -> Result<RestoreReport, BackupError> {
    require_absolute(backups_dir, "backups directory")?;
    require_absolute(config_file, "config file")?;
    require_absolute(spaces_dir, "spaces directory")?;
    verify_backup(archive_path)?;

    ensure_private_dir(backups_dir)?;
    let staging = backups_dir.join(format!(".restore-{}-{}", std::process::id(), nonce()));
    ensure_private_dir(&staging)?;
    let guard = StagingGuard(staging.clone());
    scan_archive(archive_path, Some(&staging))?;

    let staged_config = staging.join("config/config.json");
    let staged_config_bytes = if staged_config.is_file() {
        let bytes =
            fs::read(&staged_config).map_err(|error| BackupError::io(&staged_config, error))?;
        klyvera_config::parse(Path::new("config.json"), &bytes)?;
        Some(bytes)
    } else {
        None
    };

    let staged_spaces_dir = staging.join("spaces");
    let mut staged_spaces = Vec::new();
    if staged_spaces_dir.is_dir() {
        let mut path_list = fs::read_dir(&staged_spaces_dir)
            .map_err(|error| BackupError::io(&staged_spaces_dir, error))?
            .flatten()
            .map(|entry| entry.path())
            .collect::<Vec<_>>();
        path_list.sort();
        for path in path_list {
            let name = path
                .file_name()
                .and_then(|value| value.to_str())
                .ok_or_else(|| BackupError::Invalid("invalid staged Space name".to_owned()))?;
            ArchivePath::parse(&format!("spaces/{name}"))?;
            let bytes = fs::read(&path).map_err(|error| BackupError::io(&path, error))?;
            let space = SpaceStore::parse_import(&bytes)?;
            if format!("{}.json", space.id) != name {
                return Err(BackupError::Invalid(format!(
                    "staged Space '{name}' has a mismatched id"
                )));
            }
            staged_spaces.push((name.to_owned(), bytes));
        }
    }

    let pre_restore_backup = create_backup(backups_dir, config_file, spaces_dir)?;

    let restored_config = match staged_config_bytes {
        Some(bytes) => {
            write_bytes_atomic(config_file, &bytes)?;
            true
        }
        None => false,
    };

    ensure_private_dir(spaces_dir)?;
    let displaced_dir = spaces_dir
        .join(".trash")
        .join(timestamp_id("restore", unix_now()));
    let mut displaced_spaces = 0usize;
    if spaces_dir.is_dir() {
        let mut current = fs::read_dir(spaces_dir)
            .map_err(|error| BackupError::io(spaces_dir, error))?
            .flatten()
            .map(|entry| entry.path())
            .filter(|path| {
                path.extension().and_then(|value| value.to_str()) == Some("json")
                    && fs::symlink_metadata(path)
                        .map(|metadata| metadata.is_file() && !metadata.file_type().is_symlink())
                        .unwrap_or(false)
            })
            .collect::<Vec<_>>();
        current.sort();
        if !current.is_empty() {
            ensure_private_dir(&displaced_dir)?;
            for path in current {
                let Some(name) = path.file_name() else {
                    continue;
                };
                fs::rename(&path, displaced_dir.join(name))
                    .map_err(|error| BackupError::io(&path, error))?;
                displaced_spaces += 1;
            }
        }
    }

    for (name, bytes) in &staged_spaces {
        let destination = spaces_dir.join(name);
        write_bytes_atomic(&destination, bytes)?;
    }

    drop(guard);
    Ok(RestoreReport {
        pre_restore_backup,
        restored_config,
        restored_spaces: staged_spaces.len(),
        displaced_spaces,
    })
}

pub fn list_backups(backups_dir: &Path) -> Result<Vec<BackupInfo>, BackupError> {
    require_absolute(backups_dir, "backups directory")?;
    let read_dir = match fs::read_dir(backups_dir) {
        Ok(read_dir) => read_dir,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => return Ok(Vec::new()),
        Err(error) => return Err(BackupError::io(backups_dir, error)),
    };
    let mut backups = Vec::new();
    for entry in read_dir.flatten() {
        let path = entry.path();
        let Some(name) = path.file_name().and_then(|value| value.to_str()) else {
            continue;
        };
        let Some(id) = name.strip_suffix(ARCHIVE_SUFFIX) else {
            continue;
        };
        let Ok(metadata) = fs::symlink_metadata(&path) else {
            continue;
        };
        if metadata.file_type().is_symlink() || !metadata.is_file() {
            continue;
        }
        backups.push(BackupInfo {
            id: id.to_owned(),
            path,
            size: metadata.len(),
            modified_at: metadata
                .modified()
                .ok()
                .and_then(|time| time.duration_since(SystemTime::UNIX_EPOCH).ok())
                .map(|duration| duration.as_secs())
                .unwrap_or_default(),
        });
    }
    backups.sort_by(|left, right| {
        right
            .modified_at
            .cmp(&left.modified_at)
            .then_with(|| right.id.cmp(&left.id))
    });
    Ok(backups)
}

fn unique_id(backups_dir: &Path, base: String) -> String {
    if !backups_dir.join(format!("{base}{ARCHIVE_SUFFIX}")).exists() {
        return base;
    }
    for suffix in 1..=10_000 {
        let candidate = format!("{base}-{suffix}");
        if !backups_dir
            .join(format!("{candidate}{ARCHIVE_SUFFIX}"))
            .exists()
        {
            return candidate;
        }
    }
    format!("{base}-{}", nonce())
}

fn require_absolute(path: &Path, label: &str) -> Result<(), BackupError> {
    if path.is_absolute() {
        Ok(())
    } else {
        Err(BackupError::Invalid(format!(
            "{label} must be absolute: {}",
            path.display()
        )))
    }
}

fn hash_file(path: &Path) -> Result<String, BackupError> {
    let file = File::open(path).map_err(|error| BackupError::io(path, error))?;
    let mut reader = BufReader::new(file);
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    let mut buffer = [0u8; 64 * 1024];
    loop {
        let read = reader
            .read(&mut buffer)
            .map_err(|error| BackupError::io(path, error))?;
        if read == 0 {
            break;
        }
        hasher.update(&buffer[..read]);
    }
    let digest = hasher.finalize();
    let mut output = String::with_capacity(digest.len() * 2);
    use std::fmt::Write as _;
    for byte in digest {
        let _ = write!(output, "{byte:02x}");
    }
    Ok(output)
}

fn sync_directory(path: &Path) -> Result<(), BackupError> {
    let directory = File::open(path).map_err(|error| BackupError::io(path, error))?;
    directory
        .sync_all()
        .map_err(|error| BackupError::io(path, error))
}

fn nonce() -> u128 {
    SystemTime::now()
        .duration_since(SystemTime::UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or_default()
}

struct StagingGuard(PathBuf);

impl Drop for StagingGuard {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use klyvera_spaces::Space;
    use std::os::unix::fs::PermissionsExt;

    struct Fixture {
        temp: tempfile::TempDir,
        config: PathBuf,
        spaces: PathBuf,
        backups: PathBuf,
        project: PathBuf,
    }

    impl Fixture {
        fn new() -> Self {
            let temp = tempfile::tempdir().unwrap();
            let config = temp.path().join("config/config.json");
            let spaces = temp.path().join("data/spaces");
            let backups = temp.path().join("data/backups");
            let project = temp.path().join("project");
            fs::create_dir_all(&project).unwrap();
            ensure_private_dir(config.parent().unwrap()).unwrap();
            ensure_private_dir(&spaces).unwrap();
            let config_value = klyvera_config::Config::default();
            klyvera_config::save(&config, &config_value).unwrap();
            Self {
                temp,
                config,
                spaces,
                backups,
                project,
            }
        }

        fn add_space(&self, name: &str) -> Space {
            let store = SpaceStore::open(&self.spaces).unwrap();
            let space = Space::new(name, vec![self.project.clone()]).unwrap();
            store.create_new(space).unwrap()
        }
    }

    #[test]
    fn backup_verify_and_restore_roundtrip() {
        let fixture = Fixture::new();
        let first = fixture.add_space("First");
        let second = fixture.add_space("Second");
        let created = create_backup(&fixture.backups, &fixture.config, &fixture.spaces).unwrap();
        assert_eq!(created.files, 3);
        assert!(created.size > 0);
        assert_eq!(created.sha256.len(), 64);
        let stored_mode = fs::metadata(&created.path).unwrap().permissions().mode();
        assert_eq!(stored_mode & 0o777, 0o600);

        let verified = verify_backup(&created.path).unwrap();
        assert_eq!(verified.verified_files, 3);
        assert_eq!(verified.manifest.files.len(), 3);

        let config_before = fs::read(&fixture.config).unwrap();
        let destination = fixture.temp.path().join("restored");
        let dest_config = destination.join("config/config.json");
        let dest_spaces = destination.join("data/spaces");
        ensure_private_dir(dest_config.parent().unwrap()).unwrap();
        ensure_private_dir(&dest_spaces).unwrap();
        klyvera_config::save(
            &dest_config,
            &klyvera_config::Config {
                appearance: klyvera_config::Appearance {
                    theme: klyvera_config::Theme::Light,
                    ..Default::default()
                },
                ..Default::default()
            },
        )
        .unwrap();
        let dest_store = SpaceStore::open(&dest_spaces).unwrap();
        dest_store
            .create_new(Space::new("Old", vec![fixture.project.clone()]).unwrap())
            .unwrap();

        let report =
            restore_backup(&created.path, &fixture.backups, &dest_config, &dest_spaces).unwrap();
        assert!(report.restored_config);
        assert_eq!(report.restored_spaces, 2);
        assert_eq!(report.displaced_spaces, 1);
        assert_eq!(fs::read(&dest_config).unwrap(), config_before);
        assert!(dest_store.get(&first.id).is_ok());
        assert!(dest_store.get(&second.id).is_ok());
        assert!(dest_store.get("old").is_err());
        assert!(report.pre_restore_backup.path.exists());

        let listing = list_backups(&fixture.backups).unwrap();
        assert_eq!(listing.len(), 2);
    }

    #[test]
    fn tampered_archives_fail_verification() {
        let fixture = Fixture::new();
        fixture.add_space("Tamper");
        let created = create_backup(&fixture.backups, &fixture.config, &fixture.spaces).unwrap();
        let mut bytes = fs::read(&created.path).unwrap();
        let middle = bytes.len() / 2;
        bytes[middle] ^= 0xff;
        let tampered = fixture.backups.join("tampered.tar.gz");
        fs::write(&tampered, bytes).unwrap();
        assert!(verify_backup(&tampered).is_err());
    }

    #[test]
    fn restore_rejects_invalid_config_and_leaves_live_files_alone() {
        let fixture = Fixture::new();
        let created = create_backup(&fixture.backups, &fixture.config, &fixture.spaces).unwrap();
        let before = fs::read(&fixture.config).unwrap();

        let bytes = fs::read(&created.path).unwrap();
        let mut decoder = GzDecoder::new(&bytes[..]);
        let mut tar_bytes = Vec::new();
        decoder.read_to_end(&mut tar_bytes).unwrap();
        let invalid_config = b"{\"version\":1,\"appearance\":{\"scale\":99}}\n";
        let manifest = BackupManifest::new(
            unix_now(),
            vec![BackupFile {
                path: "config/config.json".to_owned(),
                sha256: sha256_hex(invalid_config),
                size: invalid_config.len() as u64,
            }],
        );
        let damaged = fixture.backups.join("invalid-config.tar.gz");
        write_test_archive(
            &damaged,
            &[
                ("config/config.json", invalid_config.as_slice()),
                (MANIFEST_FILE, &serde_json::to_vec(&manifest).unwrap()),
            ],
        );

        assert!(
            restore_backup(&damaged, &fixture.backups, &fixture.config, &fixture.spaces).is_err()
        );
        assert_eq!(fs::read(&fixture.config).unwrap(), before);
    }

    #[test]
    fn unsafe_archive_paths_are_rejected() {
        let temp = tempfile::tempdir().unwrap();
        let archive = temp.path().join("evil.tar.gz");
        write_raw_archive(&archive, "../evil", b"owned");
        assert!(verify_backup(&archive).is_err());
    }

    #[test]
    fn invalid_sources_and_relative_directories_are_rejected() {
        let fixture = Fixture::new();
        assert!(create_backup(Path::new("relative"), &fixture.config, &fixture.spaces).is_err());

        fs::remove_file(&fixture.config).unwrap();
        fs::create_dir_all(&fixture.config).unwrap();
        assert!(create_backup(&fixture.backups, &fixture.config, &fixture.spaces).is_err());
    }

    fn write_test_archive(path: &Path, entries: &[(&str, &[u8])]) {
        let file = File::create(path).unwrap();
        let encoder = GzEncoder::new(file, Compression::default());
        let mut builder = Builder::new(encoder);
        for (name, bytes) in entries {
            let mut header = Header::new_gnu();
            header.set_entry_type(EntryType::Regular);
            header.set_mode(0o600);
            header.set_size(bytes.len() as u64);
            header.set_cksum();
            builder.append_data(&mut header, name, *bytes).unwrap();
        }
        builder.into_inner().unwrap().finish().unwrap();
    }

    fn write_raw_archive(path: &Path, name: &str, bytes: &[u8]) {
        let mut header = [0u8; 512];
        header[..name.len()].copy_from_slice(name.as_bytes());
        header[100..108].copy_from_slice(b"0000600\0");
        header[108..116].copy_from_slice(b"0000000\0");
        header[116..124].copy_from_slice(b"0000000\0");
        let size = format!("{:011o}\0", bytes.len());
        header[124..136].copy_from_slice(size.as_bytes());
        header[136..148].copy_from_slice(b"00000000000\0");
        header[148..156].copy_from_slice(b"        ");
        header[156] = b'0';
        header[257..263].copy_from_slice(b"ustar\0");
        header[263..265].copy_from_slice(b"00");
        let checksum: u32 = header.iter().map(|byte| u32::from(*byte)).sum();
        let checksum_field = format!("{checksum:06o}\0 ");
        header[148..156].copy_from_slice(checksum_field.as_bytes());

        let mut tar_bytes = header.to_vec();
        tar_bytes.extend_from_slice(bytes);
        let padding = (512 - bytes.len() % 512) % 512;
        tar_bytes.extend(std::iter::repeat_n(0u8, padding));
        tar_bytes.extend(std::iter::repeat_n(0u8, 1024));

        let file = File::create(path).unwrap();
        let mut encoder = GzEncoder::new(file, Compression::default());
        encoder.write_all(&tar_bytes).unwrap();
        encoder.finish().unwrap();
    }
}
