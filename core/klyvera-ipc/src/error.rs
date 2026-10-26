use std::path::PathBuf;

pub enum IpcError {
    Io {
        path: PathBuf,
        source: std::io::Error,
    },

    Stream(#[source] std::io::Error),

    Json(#[source] serde_json::Error),

    Protocol(String),

    UnsupportedVersion(u32),

    BadRequest(String),

    AlreadyRunning(PathBuf),

    PeerUid { peer: u32, ours: u32 },

    TooLarge(usize),

    InvalidSocketPath(PathBuf),

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
