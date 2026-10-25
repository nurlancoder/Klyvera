use std::path::{Path, PathBuf};

use crate::error::SpaceError;
use crate::model::{unix_now, validate_id, Space, MAX_SPACE_BYTES, SPACE_VERSION};
use klyvera_config::{ensure_private_dir, write_json_atomic};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LoadFailure {
    pub file: String,
    pub message: String,
}

#[derive(Debug, Clone, Default)]
pub struct ListReport {
    pub spaces: Vec<Space>,
    pub errors: Vec<LoadFailure>,
}

#[derive(Debug, Clone)]
pub struct SpaceStore {
    directory: PathBuf,
}

impl SpaceStore {
    pub fn open(directory: impl Into<PathBuf>) -> Result<Self, SpaceError> {
        let directory = directory.into();
        if !directory.is_absolute() {
            return Err(SpaceError::Invalid(format!(
                "spaces directory must be absolute: {}",
                directory.display()
            )));
        }
        ensure_private_dir(&directory)?;
        Ok(Self { directory })
    }

    pub fn directory(&self) -> &Path {
        &self.directory
    }

    pub fn path_for(&self, id: &str) -> Result<PathBuf, SpaceError> {
        validate_id(id)?;
        Ok(self.directory.join(format!("{id}.json")))
    }

    pub fn exists(&self, id: &str) -> Result<bool, SpaceError> {
        Ok(self.path_for(id)?.is_file())
    }

    pub fn get(&self, id: &str) -> Result<Space, SpaceError> {
        let path = self.path_for(id)?;
        let space = read_space_file(&path).map_err(|error| {
            if error.is_not_found() {
                SpaceError::NotFound(id.to_owned())
            } else {
                error
            }
        })?;
        if space.id != id {
            return Err(SpaceError::Invalid(format!(
                "file {} contains Space '{}' instead of '{id}'",
                path.display(),
                space.id
            )));
        }
        Ok(space)
    }

    pub fn list(&self) -> ListReport {
        let mut report = ListReport::default();
        let Ok(read_dir) = std::fs::read_dir(&self.directory) else {
            return report;
        };
        let mut paths = read_dir
            .flatten()
            .map(|entry| entry.path())
            .filter(|path| path.extension().and_then(|value| value.to_str()) == Some("json"))
            .collect::<Vec<_>>();
        paths.sort();

        for path in paths {
            let file = path
                .file_name()
                .map(|name| name.to_string_lossy().into_owned())
                .unwrap_or_else(|| "<unknown>".to_owned());
            let Ok(metadata) = std::fs::symlink_metadata(&path) else {
                report.errors.push(LoadFailure {
                    file,
                    message: "could not read file metadata".to_owned(),
                });
                continue;
            };
            if metadata.file_type().is_symlink() || !metadata.is_file() {
                report.errors.push(LoadFailure {
                    file,
                    message: "space files must be regular files, not symlinks".to_owned(),
                });
                continue;
            }
            match read_space_file(&path) {
                Ok(space) => {
                    let stem = path.file_stem().and_then(|value| value.to_str());
                    if stem != Some(space.id.as_str()) {
                        report.errors.push(LoadFailure {
                            file,
                            message: format!(
                                "file name does not match the Space id '{}'",
                                space.id
                            ),
                        });
                    } else {
                        report.spaces.push(space);
                    }
                }
                Err(error) => report.errors.push(LoadFailure {
                    file,
                    message: error.to_string(),
                }),
            }
        }
        report.spaces.sort_by(|left, right| {
            left.name
                .to_lowercase()
                .cmp(&right.name.to_lowercase())
                .then_with(|| left.id.cmp(&right.id))
        });
        report
    }

    /// Create a locally authored Space. Project paths must already exist.
    pub fn create_new(&self, mut space: Space) -> Result<Space, SpaceError> {
        space.validate()?;
        space.validate_existing_paths()?;
        space.normalize_timestamps();
        self.write_new(space)
    }

    /// Persist an imported Space. Structural validation applies; missing project
    /// folders are reported when the Space is opened, not at import time.
    pub fn save_imported(&self, mut space: Space) -> Result<Space, SpaceError> {
        space.validate()?;
        space.normalize_timestamps();
        self.write_new(space)
    }

    fn write_new(&self, space: Space) -> Result<Space, SpaceError> {
        let path = self.path_for(&space.id)?;
        if path.exists() {
            return Err(SpaceError::Exists(space.id));
        }
        write_json_atomic(&path, &space)?;
        Ok(space)
    }

    pub fn update(&self, mut space: Space) -> Result<Space, SpaceError> {
        let path = self.path_for(&space.id)?;
        let existing = self.get(&space.id)?;
        space.created_at = existing.created_at;
        space.updated_at = unix_now().max(space.created_at);
        space.validate()?;
        space.validate_existing_paths()?;
        write_json_atomic(&path, &space)?;
        Ok(space)
    }

    /// Move a Space file to the trash directory instead of deleting it.
    pub fn delete(&self, id: &str) -> Result<PathBuf, SpaceError> {
        let path = self.path_for(id)?;
        if !path.is_file() {
            return Err(SpaceError::NotFound(id.to_owned()));
        }
        let trash = self.directory.join(".trash");
        ensure_private_dir(&trash)?;
        let destination = unique_trash_path(&trash, id, unix_now());
        std::fs::rename(&path, &destination).map_err(|error| SpaceError::io(&path, error))?;
        Ok(destination)
    }

    pub fn export_json(&self, id: &str) -> Result<Vec<u8>, SpaceError> {
        let space = self.get(id)?;
        let mut bytes = serde_json::to_vec_pretty(&space)
            .map_err(|error| SpaceError::json(format!("{id}.json"), error))?;
        bytes.push(b'\n');
        Ok(bytes)
    }

    pub fn parse_import(bytes: &[u8]) -> Result<Space, SpaceError> {
        if bytes.len() > MAX_SPACE_BYTES {
            return Err(SpaceError::TooLarge {
                size: bytes.len() as u64,
                limit: MAX_SPACE_BYTES,
            });
        }
        let mut space: Space = serde_json::from_slice(bytes)
            .map_err(|error| SpaceError::json("import".to_owned(), error))?;
        if space.version != SPACE_VERSION {
            return Err(SpaceError::Invalid(format!(
                "expected version {SPACE_VERSION}, found {}",
                space.version
            )));
        }
        space.normalize_timestamps();
        space.validate()?;
        Ok(space)
    }
}

fn read_space_file(path: &Path) -> Result<Space, SpaceError> {
    let metadata = std::fs::symlink_metadata(path).map_err(|error| SpaceError::io(path, error))?;
    if metadata.file_type().is_symlink() || !metadata.is_file() {
        return Err(SpaceError::Invalid(format!(
            "space file must be a regular file: {}",
            path.display()
        )));
    }
    if metadata.len() > MAX_SPACE_BYTES as u64 {
        return Err(SpaceError::TooLarge {
            size: metadata.len(),
            limit: MAX_SPACE_BYTES,
        });
    }
    let bytes = std::fs::read(path).map_err(|error| SpaceError::io(path, error))?;
    let mut space: Space = serde_json::from_slice(&bytes)
        .map_err(|error| SpaceError::json(path.display().to_string(), error))?;
    space.normalize_timestamps();
    space.validate()?;
    Ok(space)
}

fn unique_trash_path(trash: &Path, id: &str, timestamp: u64) -> PathBuf {
    let base = trash.join(format!("{id}.{timestamp}.json"));
    if !base.exists() {
        return base;
    }
    for suffix in 1..=1000 {
        let candidate = trash.join(format!("{id}.{timestamp}.{suffix}.json"));
        if !candidate.exists() {
            return candidate;
        }
    }
    // The timestamp and bounded suffix loop make a collision extremely
    // unlikely; overwriting an old trash entry is safer than failing a delete.
    base
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::model::TerminalCommand;

    fn project(temp: &tempfile::TempDir) -> PathBuf {
        let path = temp.path().join("project");
        std::fs::create_dir_all(&path).unwrap();
        path
    }

    fn make_space(temp: &tempfile::TempDir) -> Space {
        Space::new("Demo Space", vec![project(temp)]).unwrap()
    }

    #[test]
    fn creates_reads_lists_updates_and_trashes_spaces() {
        let temp = tempfile::tempdir().unwrap();
        let store = SpaceStore::open(temp.path().join("data/spaces")).unwrap();
        let mut space = make_space(&temp);
        space.commands = vec![TerminalCommand::new("test", vec!["/bin/true".to_owned()])];
        let created = store.create_new(space).unwrap();
        assert!(store.exists(&created.id).unwrap());

        let loaded = store.get(&created.id).unwrap();
        assert_eq!(loaded.name, "Demo Space");

        let listing = store.list();
        assert_eq!(listing.spaces.len(), 1);
        assert!(listing.errors.is_empty());

        let mut changed = loaded;
        changed.name = "Renamed".to_owned();
        changed.description = Some("Updated".to_owned());
        let updated = store.update(changed).unwrap();
        assert_eq!(updated.created_at, created.created_at);
        assert!(updated.updated_at >= updated.created_at);
        assert_eq!(store.get(&created.id).unwrap().name, "Renamed");

        let trashed = store.delete(&created.id).unwrap();
        assert!(trashed.is_file());
        assert!(matches!(
            store.get(&created.id),
            Err(SpaceError::NotFound(_))
        ));
        assert_eq!(
            store.delete(&created.id).unwrap_err().to_string(),
            "Space 'demo-space' was not found"
        );
    }

    #[test]
    fn refuses_duplicate_ids_and_missing_project_paths() {
        let temp = tempfile::tempdir().unwrap();
        let store = SpaceStore::open(temp.path().join("spaces")).unwrap();
        let space = make_space(&temp);
        store.create_new(space.clone()).unwrap();
        assert!(matches!(
            store.create_new(space),
            Err(SpaceError::Exists(_))
        ));

        let missing = Space::new("Missing", vec![temp.path().join("nope")]).unwrap();
        assert!(matches!(
            store.create_new(missing),
            Err(SpaceError::MissingPath(_))
        ));
    }

    #[test]
    fn import_roundtrip_and_collision() {
        let temp = tempfile::tempdir().unwrap();
        let store = SpaceStore::open(temp.path().join("spaces")).unwrap();
        let space = make_space(&temp);
        store.create_new(space.clone()).unwrap();

        let exported = store.export_json(&space.id).unwrap();
        let parsed = SpaceStore::parse_import(&exported).unwrap();
        assert_eq!(parsed, space);
        let another = SpaceStore::open(temp.path().join("other")).unwrap();
        another.save_imported(parsed).unwrap();
        assert_eq!(another.get(&space.id).unwrap().name, space.name);

        assert!(matches!(
            store.save_imported(space),
            Err(SpaceError::Exists(_))
        ));
    }

    #[test]
    fn imported_spaces_may_have_missing_folders() {
        let temp = tempfile::tempdir().unwrap();
        let store = SpaceStore::open(temp.path().join("spaces")).unwrap();
        let space = Space::new("Missing", vec![temp.path().join("does-not-exist")]).unwrap();
        store.save_imported(space.clone()).unwrap();
        assert_eq!(
            store.get(&space.id).unwrap().project_paths,
            space.project_paths
        );
    }

    #[test]
    fn rejects_malformed_and_oversized_documents() {
        assert!(SpaceStore::parse_import(b"not json").is_err());
        let oversized = vec![b' '; MAX_SPACE_BYTES + 1];
        assert!(matches!(
            SpaceStore::parse_import(&oversized),
            Err(SpaceError::TooLarge { .. })
        ));
        let wrong_version = br#"{"version":99,"id":"x","name":"X","projectPaths":["/tmp"]}"#;
        assert!(SpaceStore::parse_import(wrong_version).is_err());
    }

    #[test]
    fn list_reports_bad_files_without_hiding_good_ones() {
        let temp = tempfile::tempdir().unwrap();
        let directory = temp.path().join("spaces");
        let store = SpaceStore::open(&directory).unwrap();
        store.create_new(make_space(&temp)).unwrap();
        std::fs::write(directory.join("broken.json"), b"{").unwrap();

        let mut renamed = make_space(&temp);
        renamed.id = "different-id".to_owned();
        let path = directory.join("renamed.json");
        std::fs::write(&path, serde_json::to_vec(&renamed).unwrap()).unwrap();

        let listing = store.list();
        assert_eq!(listing.spaces.len(), 1);
        assert_eq!(listing.errors.len(), 2);
        assert!(listing
            .errors
            .iter()
            .any(|error| error.file == "broken.json"));
        assert!(listing
            .errors
            .iter()
            .any(|error| error.file == "renamed.json"));
    }

    #[cfg(unix)]
    #[test]
    fn list_rejects_symlinked_space_files() {
        let temp = tempfile::tempdir().unwrap();
        let directory = temp.path().join("spaces");
        let store = SpaceStore::open(&directory).unwrap();
        let space = make_space(&temp);
        store.create_new(space.clone()).unwrap();
        std::os::unix::fs::symlink(
            directory.join(format!("{}.json", space.id)),
            directory.join("link.json"),
        )
        .unwrap();

        let listing = store.list();
        assert_eq!(listing.spaces.len(), 1);
        assert!(listing.errors.iter().any(|error| error.file == "link.json"));
    }

    #[test]
    fn files_and_directories_are_private() {
        #[cfg(unix)]
        {
            use std::os::unix::fs::PermissionsExt;
            let temp = tempfile::tempdir().unwrap();
            let directory = temp.path().join("spaces");
            let store = SpaceStore::open(&directory).unwrap();
            let space = store.create_new(make_space(&temp)).unwrap();
            let file_mode = std::fs::metadata(store.path_for(&space.id).unwrap())
                .unwrap()
                .permissions()
                .mode();
            let dir_mode = std::fs::metadata(&directory).unwrap().permissions().mode();
            assert_eq!(file_mode & 0o777, 0o600);
            assert_eq!(dir_mode & 0o777, 0o700);
        }
    }

    #[test]
    fn relative_directories_and_unsafe_ids_are_rejected() {
        assert!(SpaceStore::open(PathBuf::from("relative")).is_err());
        let temp = tempfile::tempdir().unwrap();
        let store = SpaceStore::open(temp.path().join("spaces")).unwrap();
        assert!(store.path_for("../escape").is_err());
        assert!(store.path_for("Bad_ID").is_err());
    }
}
