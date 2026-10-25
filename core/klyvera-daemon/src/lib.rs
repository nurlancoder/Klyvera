//! Klyvera user-session daemon.
//!
//! One request at a time on a private Unix socket. Project data never leaves
//! the machine; structured logs contain event names and status only.

mod daemon;
mod error;
mod signal;

pub use daemon::{run, DaemonConfig};
pub use error::DaemonError;
