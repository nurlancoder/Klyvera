use std::path::PathBuf;

pub enum CliError {
    Config(#[from] klyvera_config::ConfigError),

    Space(#[from] klyvera_spaces::SpaceError),

    Backup(#[from] klyvera_backup::BackupError),

    Ipc(#[from] klyvera_ipc::IpcError),

    Io {
        path: PathBuf,
        source: std::io::Error,
    },

    Usage(String),

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
