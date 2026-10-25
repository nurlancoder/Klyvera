//! Klyvera Spaces: profiles, validation, storage, trust and launch planning.
//!
//! A Space is user-owned JSON. Commands are argv arrays, never shell strings,
//! and confirmation is tied to the profile SHA-256 so edits invalidate trust.

mod desktop;
mod error;
mod launch;
mod model;
mod store;
mod trust;

pub use desktop::{desktop_search_roots, parse_desktop, parse_exec, DesktopEntry, DesktopIndex};
pub use error::SpaceError;
pub use launch::{
    build_plan, execute, CommandAuthorization, OpenPlan, OpenReport, PlannedProcess, ProcessKind,
};
pub use model::{
    slugify, validate_desktop_id, validate_id, AppRef, LayoutHints, Space, SpaceAccent,
    TerminalCommand, MAX_SPACE_BYTES, SPACE_VERSION,
};
pub use store::{ListReport, LoadFailure, SpaceStore};
pub use trust::TrustStore;
