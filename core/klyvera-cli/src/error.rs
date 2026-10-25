use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum CliError {
    #[error(transparent)]
    Config(#[from] klyvera_config::ConfigError),

    #[error(transparent)]
    Space(#[from] klyvera_spaces::SpaceError),

    #[error(transparent)]
    Backup(#[from] klyvera_backup::BackupError),

    #[error(transparent)]
    Ipc(#[from] klyvera_ipc::IpcError),

    #[error("I/O error at {path}: {source}")]
    Io {
        path: PathBuf,
        #[source]
        source: std::io::Error,
    },

    #[error("invalid arguments: {0}")]
    Usage(String),

    #[error("{0}")]
    Message(String),
}

impl CliError {
    pub fn io(path: impl Into<PathBuf>, source: std::io::Error) -> Self {
        Self::Io {
            path: path.into(),
            source,
        }
    }
}
