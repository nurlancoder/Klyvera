use std::path::PathBuf;
use std::process::ExitCode;

use clap::Parser;
use klyvera_config::Paths;
use klyvera_daemon::{run, DaemonConfig};

#[derive(Debug, Parser)]
#[command(
    name = "klyvera-daemon",
    version,
    about = "Klyvera user-session daemon"
)]
struct Arguments {
    /// Override the Unix socket path.
    #[arg(long, value_name = "PATH")]
    socket: Option<PathBuf>,

    /// Log every request outcome.
    #[arg(long)]
    verbose: bool,
}

fn main() -> ExitCode {
    let arguments = Arguments::parse();
    match daemon_config(arguments) {
        Ok(config) => match run(config) {
            Ok(()) => ExitCode::SUCCESS,
            Err(error) => {
                eprintln!("klyvera-daemon: {error}");
                ExitCode::FAILURE
            }
        },
        Err(message) => {
            eprintln!("klyvera-daemon: {message}");
            ExitCode::FAILURE
        }
    }
}

fn daemon_config(arguments: Arguments) -> Result<DaemonConfig, String> {
    let paths = Paths::from_env().map_err(|error| error.to_string())?;
    let socket = match arguments.socket {
        Some(socket) => socket,
        None => paths.socket_path().map_err(|error| error.to_string())?,
    };
    Ok(DaemonConfig {
        paths,
        socket,
        verbose: arguments.verbose,
    })
}
