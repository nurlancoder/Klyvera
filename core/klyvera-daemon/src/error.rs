use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum DaemonError {
    #[error(transparent)]
    Config(#[from] klyvera_config::ConfigError),

    #[error(transparent)]
    Space(#[from] klyvera_spaces::SpaceError),

    #[error(transparent)]
    Ipc(#[from] klyvera_ipc::IpcError),

    #[error("I/O error at {path}: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("signal handling is unavailable: {0}")]
    Signal(String),
}

impl DaemonError {
    pub(crate) fn io(path: impl Into<PathBuf>, source: std::io::Error) -> Self {
        Self::Io {
            path: path.into(),
            source,
        }
    }
}
