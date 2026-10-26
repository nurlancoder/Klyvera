use std::path::PathBuf;

use crate::SCHEMA_VERSION;

pub enum ConfigError {
    Io {
        path: PathBuf,
        source: std::io::Error,
    },

    Json {
        path: PathBuf,
        source: serde_json::Error,
    },

    UnsupportedVersion(u64),

    Validation(String),

    MissingEnv(&'static str),

    RelativePath { name: &'static str, path: PathBuf },

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
