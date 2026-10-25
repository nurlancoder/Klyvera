use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum BackupError {
    #[error("I/O error at {path}: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("invalid JSON in {path}: {source}")]
    Json {
        path: String,
        #[source]
        source: serde_json::Error,
    },

    #[error("invalid backup: {0}")]
    Invalid(String),

    #[error("backup verification failed: {0}")]
    Verify(String),

    #[error("unsafe archive path: {0}")]
    UnsafePath(String),

    #[error("backup not found: {0}")]
    NotFound(String),

    #[error(transparent)]
    Config(#[from] klyvera_config::ConfigError),

    #[error(transparent)]
    Space(#[from] klyvera_spaces::SpaceError),
}

impl BackupError {
    pub(crate) fn io(path: impl Into<PathBuf>, source: std::io::Error) -> Self {
        Self::Io {
            path: path.into(),
            source,
        }
    }

    pub(crate) fn json(path: impl Into<String>, source: serde_json::Error) -> Self {
        Self::Json {
            path: path.into(),
            source,
        }
    }
}
