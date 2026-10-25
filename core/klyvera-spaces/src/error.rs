use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum SpaceError {
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

    #[error("invalid Space: {0}")]
    Invalid(String),

    #[error("Space '{0}' was not found")]
    NotFound(String),

    #[error("Space '{0}' already exists")]
    Exists(String),

    #[error("project path does not exist or is not a directory: {0}")]
    MissingPath(PathBuf),

    #[error("duplicate project path: {0}")]
    DuplicatePath(PathBuf),

    #[error("desktop entry not found: {0}")]
    DesktopNotFound(String),

    #[error("desktop entry error: {0}")]
    Desktop(String),

    #[error("commands for profile {profile_hash} have not been confirmed; review and trust this profile first")]
    Untrusted { profile_hash: String },

    #[error("failed to start '{program}': {source}")]
    Launch {
        program: String,
        #[source]
        source: std::io::Error,
    },

    #[error("Space document is too large ({size} bytes, limit {limit})")]
    TooLarge { size: u64, limit: usize },

    #[error("unsafe archive or file path: {0}")]
    UnsafePath(String),

    #[error(transparent)]
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
