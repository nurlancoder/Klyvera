use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum IpcError {
    #[error("I/O error at {path}: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("I/O error: {0}")]
    Stream(#[source] std::io::Error),

    #[error("invalid JSON message: {0}")]
    Json(#[source] serde_json::Error),

    #[error("protocol error: {0}")]
    Protocol(String),

    #[error("unsupported protocol version {0}")]
    UnsupportedVersion(u32),

    #[error("invalid request: {0}")]
    BadRequest(String),

    #[error("another daemon is already listening at {0}")]
    AlreadyRunning(PathBuf),

    #[error("peer uid {peer} does not match our uid {ours}")]
    PeerUid { peer: u32, ours: u32 },

    #[error("message exceeds {0} bytes")]
    TooLarge(usize),

    #[error("invalid socket path: {0}")]
    InvalidSocketPath(PathBuf),

    #[error(transparent)]
    Config(#[from] klyvera_config::ConfigError),
}

impl IpcError {
    pub(crate) fn io(path: impl Into<PathBuf>, source: std::io::Error) -> Self {
        Self::Io {
            path: path.into(),
            source,
        }
    }

    pub(crate) fn stream(source: std::io::Error) -> Self {
        Self::Stream(source)
    }

    pub(crate) fn protocol(message: impl Into<String>) -> Self {
        Self::Protocol(message.into())
    }
}
