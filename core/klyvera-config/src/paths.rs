use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use crate::ConfigError;

/// Klyvera-owned directories, already scoped to the application.
///
/// `from_env` appends `klyvera` to the XDG roots. `new` takes the final
/// application directories directly, which keeps tests independent of the
/// process environment.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paths {
    config_dir: PathBuf,
    data_dir: PathBuf,
    runtime_dir: Option<PathBuf>,
}

impl Paths {
    pub fn from_env() -> Result<Self, ConfigError> {
        let home = env::var_os("HOME")
            .filter(|value| !value.is_empty())
            .map(PathBuf::from);

        let config_home = xdg_dir(
            "XDG_CONFIG_HOME",
            home.as_deref().map(|h| h.join(".config")),
        )?;
        let data_home = xdg_dir(
            "XDG_DATA_HOME",
            home.as_deref().map(|h| h.join(".local/share")),
        )?;
        let runtime_home = match env::var_os("XDG_RUNTIME_DIR") {
            Some(value) if !value.is_empty() => {
                Some(absolute("XDG_RUNTIME_DIR", PathBuf::from(value))?)
            }
            _ => None,
        };

        Ok(Self {
            config_dir: config_home.join("klyvera"),
            data_dir: data_home.join("klyvera"),
            runtime_dir: runtime_home.map(|path| path.join("klyvera")),
        })
    }

    pub fn new(config_dir: PathBuf, data_dir: PathBuf, runtime_dir: Option<PathBuf>) -> Self {
        Self {
            config_dir,
            data_dir,
            runtime_dir,
        }
    }

    pub fn config_dir(&self) -> &Path {
        &self.config_dir
    }

    pub fn data_dir(&self) -> &Path {
        &self.data_dir
    }

    pub fn runtime_dir(&self) -> Option<&Path> {
        self.runtime_dir.as_deref()
    }

    pub fn config_file(&self) -> PathBuf {
        self.config_dir.join("config.json")
    }

    pub fn spaces_dir(&self) -> PathBuf {
        self.data_dir.join("spaces")
    }

    pub fn trust_file(&self) -> PathBuf {
        self.data_dir.join("trust.json")
    }

    pub fn backups_dir(&self) -> PathBuf {
        self.data_dir.join("backups")
    }

    pub fn socket_path(&self) -> Result<PathBuf, ConfigError> {
        let runtime = self
            .runtime_dir
            .as_ref()
            .ok_or(ConfigError::MissingEnv("XDG_RUNTIME_DIR"))?;
        Ok(runtime.join("daemon.sock"))
    }

    /// Create the directories Klyvera owns and tighten them to mode 0700.
    pub fn ensure_layout(&self) -> Result<(), ConfigError> {
        ensure_private_dir(&self.config_dir)?;
        ensure_private_dir(&self.data_dir)?;
        ensure_private_dir(&self.spaces_dir())?;
        ensure_private_dir(&self.backups_dir())?;
        Ok(())
    }

    pub fn ensure_runtime_dir(&self) -> Result<PathBuf, ConfigError> {
        let runtime = self
            .runtime_dir
            .as_ref()
            .ok_or(ConfigError::MissingEnv("XDG_RUNTIME_DIR"))?;
        ensure_private_dir(runtime)?;
        Ok(runtime.clone())
    }
}

fn xdg_dir(name: &'static str, fallback: Option<PathBuf>) -> Result<PathBuf, ConfigError> {
    match env::var_os(name) {
        Some(value) if !value.is_empty() => absolute(name, PathBuf::from(value)),
        _ => {
            let fallback = fallback.ok_or(ConfigError::MissingEnv("HOME"))?;
            absolute("HOME", fallback)
        }
    }
}

fn absolute(name: &'static str, path: PathBuf) -> Result<PathBuf, ConfigError> {
    if path.is_absolute() {
        Ok(path)
    } else {
        Err(ConfigError::RelativePath { name, path })
    }
}

pub fn ensure_private_dir(path: &Path) -> Result<(), ConfigError> {
    if path.as_os_str().is_empty() {
        return Err(ConfigError::Validation(
            "refusing to create an empty directory path".to_owned(),
        ));
    }
    fs::create_dir_all(path).map_err(|error| ConfigError::io(path, error))?;
    set_private_dir_permissions(path)?;
    Ok(())
}

#[cfg(unix)]
fn set_private_dir_permissions(path: &Path) -> Result<(), ConfigError> {
    use std::os::unix::fs::PermissionsExt;
    let permissions = fs::Permissions::from_mode(0o700);
    fs::set_permissions(path, permissions).map_err(|error| ConfigError::io(path, error))
}

#[cfg(not(unix))]
fn set_private_dir_permissions(_path: &Path) -> Result<(), ConfigError> {
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;

    #[test]
    fn explicit_paths_have_expected_layout() {
        let paths = Paths::new(
            PathBuf::from("/tmp/k/config"),
            PathBuf::from("/tmp/k/data"),
            Some(PathBuf::from("/tmp/k/run")),
        );
        assert_eq!(paths.config_file(), Path::new("/tmp/k/config/config.json"));
        assert_eq!(paths.spaces_dir(), Path::new("/tmp/k/data/spaces"));
        assert_eq!(paths.trust_file(), Path::new("/tmp/k/data/trust.json"));
        assert_eq!(paths.backups_dir(), Path::new("/tmp/k/data/backups"));
        assert_eq!(
            paths.socket_path().unwrap(),
            Path::new("/tmp/k/run/daemon.sock")
        );
    }

    #[test]
    fn runtime_is_required_for_socket() {
        let paths = Paths::new(
            PathBuf::from("/tmp/k/config"),
            PathBuf::from("/tmp/k/data"),
            None,
        );
        assert!(matches!(
            paths.socket_path(),
            Err(ConfigError::MissingEnv("XDG_RUNTIME_DIR"))
        ));
    }

    #[test]
    fn layout_creates_private_directories() {
        let temp = tempfile::tempdir().unwrap();
        let paths = Paths::new(
            temp.path().join("config"),
            temp.path().join("data"),
            Some(temp.path().join("run")),
        );
        paths.ensure_layout().unwrap();
        for directory in [
            paths.config_dir(),
            paths.data_dir(),
            &paths.spaces_dir(),
            &paths.backups_dir(),
        ] {
            let mode = fs::metadata(directory).unwrap().permissions().mode();
            assert_eq!(mode & 0o777, 0o700, "{directory:?}");
        }
        paths.ensure_runtime_dir().unwrap();
    }

    #[test]
    fn empty_relative_and_missing_home_are_rejected() {
        assert!(matches!(
            absolute("XDG_CONFIG_HOME", PathBuf::from("relative")),
            Err(ConfigError::RelativePath { .. })
        ));
        assert!(matches!(
            ensure_private_dir(Path::new("")),
            Err(ConfigError::Validation(_))
        ));
    }
}
