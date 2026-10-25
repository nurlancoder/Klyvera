use std::process::ExitCode;

use clap::Parser;
use klyvera_cli::{run, Cli};

fn main() -> ExitCode {
    let cli = Cli::parse();
    match run(cli) {
        Ok(code) => code,
        Err(error) => {
            eprintln!("klyvera: {error}");
            ExitCode::FAILURE
        }
    }
}
