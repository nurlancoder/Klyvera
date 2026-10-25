use std::fs::{self, File, OpenOptions};
use std::io::{self, Write};
use std::path::Path;
use std::time::{SystemTime, UNIX_EPOCH};

use serde::Serialize;

use crate::paths::ensure_private_dir;
use crate::ConfigError;

const TEMP_ATTEMPTS: u8 = 8;

/// Write bytes to a private file by renaming a temporary file in the same
/// directory. The parent directory is created (or tightened) to mode 0700.
pub fn write_bytes_atomic(path: &Path, bytes: &[u8]) -> Result<(), ConfigError> {
    let parent = path.parent().ok_or_else(|| {
        ConfigError::Validation(format!("path has no parent directory: {}", path.display()))
    })?;
    ensure_private_dir(parent)?;
    let file_name = path.file_name().ok_or_else(|| {
        ConfigError::Validation(format!("path has no file name: {}", path.display()))
    })?;

    let mut last_error = None;
    for attempt in 0..TEMP_ATTEMPTS {
        let temporary = parent.join(format!(
            ".{}.tmp.{}.{}.{}",
            file_name.to_string_lossy(),
            std::process::id(),
            nonce(),
            attempt
        ));
        let mut options = OpenOptions::new();
        options.write(true).create_new(true);
        #[cfg(unix)]
        {
            use std::os::unix::fs::OpenOptionsExt;
            options.mode(0o600);
        }
        let mut file = match options.open(&temporary) {
            Ok(file) => file,
            Err(error) if error.kind() == io::ErrorKind::AlreadyExists => {
                last_error = Some(error);
                continue;
            }
            Err(error) => return Err(ConfigError::io(&temporary, error)),
        };

        let result = write_flush_rename(&mut file, &temporary, path, parent, bytes);
        if result.is_err() {
            let _ = fs::remove_file(&temporary);
        }
        return result;
    }

    Err(ConfigError::io(
        path,
        last_error.unwrap_or_else(|| io::Error::other("could not create a temporary file")),
    ))
}

fn write_flush_rename(
    file: &mut File,
    temporary: &Path,
    destination: &Path,
    parent: &Path,
    bytes: &[u8],
) -> Result<(), ConfigError> {
    file.write_all(bytes)
        .map_err(|error| ConfigError::io(temporary, error))?;
    file.sync_all()
        .map_err(|error| ConfigError::io(temporary, error))?;
    set_private_file_permissions(temporary)?;
    fs::rename(temporary, destination).map_err(|error| ConfigError::io(destination, error))?;
    sync_directory(parent)?;
    Ok(())
}

#[cfg(unix)]
fn set_private_file_permissions(path: &Path) -> Result<(), ConfigError> {
    use std::os::unix::fs::PermissionsExt;
    fs::set_permissions(path, fs::Permissions::from_mode(0o600))
        .map_err(|error| ConfigError::io(path, error))
}

#[cfg(not(unix))]
fn set_private_file_permissions(_path: &Path) -> Result<(), ConfigError> {
    Ok(())
}

fn sync_directory(path: &Path) -> Result<(), ConfigError> {
    let directory = File::open(path).map_err(|error| ConfigError::io(path, error))?;
    directory
        .sync_all()
        .map_err(|error| ConfigError::io(path, error))
}

fn nonce() -> u128 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or_default()
}

pub fn write_json_atomic<T: Serialize>(path: &Path, value: &T) -> Result<(), ConfigError> {
    let mut bytes = serde_json::to_vec_pretty(value).map_err(|error| ConfigError::Json {
        path: path.to_path_buf(),
        source: error,
    })?;
    bytes.push(b'\n');
    write_bytes_atomic(path, &bytes)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;

    #[test]
    fn writes_private_files_and_overwrites_atomically() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("nested/config.json");
        write_bytes_atomic(&path, b"first").unwrap();
        assert_eq!(fs::read(&path).unwrap(), b"first");
        let mode = fs::metadata(&path).unwrap().permissions().mode();
        assert_eq!(mode & 0o777, 0o600);
        let directory_mode = fs::metadata(path.parent().unwrap())
            .unwrap()
            .permissions()
            .mode();
        assert_eq!(directory_mode & 0o777, 0o700);

        write_bytes_atomic(&path, b"second").unwrap();
        assert_eq!(fs::read(&path).unwrap(), b"second");
        let leftovers: Vec<_> = fs::read_dir(path.parent().unwrap())
            .unwrap()
            .filter_map(Result::ok)
            .filter(|entry| entry.file_name().to_string_lossy().contains(".tmp."))
            .collect();
        assert!(leftovers.is_empty());
    }

    #[test]
    fn rejects_relative_parentless_path() {
        assert!(matches!(
            write_bytes_atomic(Path::new("/"), b"x"),
            Err(ConfigError::Validation(_))
        ));
    }
}
