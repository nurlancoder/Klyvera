use std::path::PathBuf;

pub enum DaemonError {
    Config(#[from] klyvera_config::ConfigError),

    Space(#[from] klyvera_spaces::SpaceError),

    Ipc(#[from] klyvera_ipc::IpcError),

    Io {
        path: PathBuf,
        source: std::io::Error,
    },

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
