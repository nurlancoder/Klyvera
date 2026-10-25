//! Typed Klyvera configuration.
//!
//! The crate owns the XDG directory policy, versioned configuration documents,
//! strict validation and atomic private writes. Other Klyvera crates reuse the
//! path and atomic-write helpers so file permissions stay consistent.

mod atomic;
mod error;
mod model;
mod paths;
mod store;

pub use atomic::{write_bytes_atomic, write_json_atomic};
pub use error::ConfigError;
pub use model::{Accent, Appearance, Config, Launcher, Notifications, Theme, SCHEMA_VERSION};
pub use paths::{ensure_private_dir, Paths};
pub use store::{load, load_or_default, parse, save, to_json_string, MAX_CONFIG_BYTES};

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn defaults_are_stable_for_the_qml_and_css_contracts() {
        let config = Config::default();
        assert_eq!(config.appearance.theme, Theme::Dark);
        assert_eq!(config.appearance.accent, Accent::Purple);
        assert_eq!(config.appearance.scale, 1.0);
        assert!(!config.appearance.reduce_motion);
    }
}
