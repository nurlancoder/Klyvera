use std::path::PathBuf;

pub enum SpaceError {
    Io {
        path: PathBuf,
        source: std::io::Error,
    },

    Json {
        path: String,
        source: serde_json::Error,
    },

    Invalid(String),

    NotFound(String),

    Exists(String),

    MissingPath(PathBuf),

    DuplicatePath(PathBuf),

    DesktopNotFound(String),

    Desktop(String),

    Untrusted { profile_hash: String },

    Launch {
        program: String,
        source: std::io::Error,
    },

    TooLarge { size: u64, limit: usize },

    UnsafePath(String),

    Config(#[from] klyvera_config::ConfigError),
}

impl SpaceError {
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

    pub fn is_not_found(&self) -> bool {
        matches!(
            self,
            Self::Io { source, .. } if source.kind() == std::io::ErrorKind::NotFound
        ) || matches!(self, Self::NotFound(_))
    }
}
