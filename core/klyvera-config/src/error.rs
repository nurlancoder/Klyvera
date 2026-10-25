use std::path::PathBuf;

use crate::SCHEMA_VERSION;

#[derive(Debug, thiserror::Error)]
pub enum ConfigError {
    #[error("I/O error at {path}: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("invalid JSON at {path}: {source}")]
    Json {
        path: PathBuf,
        #[source]
        source: serde_json::Error,
    },

    #[error("configuration version {0} is newer than supported version {SCHEMA_VERSION}")]
    UnsupportedVersion(u64),

    #[error("configuration is invalid: {0}")]
    Validation(String),

    #[error("cannot determine {0}; set the corresponding XDG environment variable")]
    MissingEnv(&'static str),

    #[error("{name} must be an absolute path: {path}")]
    RelativePath { name: &'static str, path: PathBuf },

    #[error("configuration file is too large ({size} bytes, limit {limit})")]
    TooLarge { size: u64, limit: usize },
}

impl ConfigError {
    pub fn is_not_found(&self) -> bool {
        matches!(
            self,
            Self::Io { source, .. } if source.kind() == std::io::ErrorKind::NotFound
        )
    }

    pub(crate) fn io(path: impl Into<PathBuf>, source: std::io::Error) -> Self {
        Self::Io {
            path: path.into(),
            source,
        }
    }

    pub(crate) fn json(path: impl Into<PathBuf>, source: serde_json::Error) -> Self {
        Self::Json {
            path: path.into(),
            source,
        }
    }
}
