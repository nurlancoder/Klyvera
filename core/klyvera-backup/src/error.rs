use std::path::PathBuf;

pub enum BackupError {
    Io {
        path: PathBuf,
        source: std::io::Error,
    },

    Json {
        path: String,
        source: serde_json::Error,
    },

    Invalid(String),

    Verify(String),

    UnsafePath(String),

    NotFound(String),

    Config(#[from] klyvera_config::ConfigError),

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
