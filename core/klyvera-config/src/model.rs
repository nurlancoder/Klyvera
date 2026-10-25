use serde::{Deserialize, Serialize};

use crate::error::ConfigError;

pub const SCHEMA_VERSION: u32 = 1;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields, default)]
pub struct Config {
    pub version: u32,
    pub appearance: Appearance,
    pub launcher: Launcher,
    pub notifications: Notifications,
}

impl Default for Config {
    fn default() -> Self {
        Self {
            version: SCHEMA_VERSION,
            appearance: Appearance::default(),
            launcher: Launcher::default(),
            notifications: Notifications::default(),
        }
    }
}

impl Config {
    pub fn validate(&self) -> Result<(), ConfigError> {
        if self.version != SCHEMA_VERSION {
            return Err(ConfigError::Validation(format!(
                "expected configuration version {SCHEMA_VERSION}, found {}",
                self.version
            )));
        }
        if !self.appearance.scale.is_finite() {
            return Err(ConfigError::Validation(
                "appearance.scale must be a finite number".to_owned(),
            ));
        }
        if !(0.75..=3.0).contains(&self.appearance.scale) {
            return Err(ConfigError::Validation(format!(
                "appearance.scale must be between 0.75 and 3.0, found {}",
                self.appearance.scale
            )));
        }
        if !(1..=50).contains(&self.launcher.recent_limit) {
            return Err(ConfigError::Validation(format!(
                "launcher.recentLimit must be between 1 and 50, found {}",
                self.launcher.recent_limit
            )));
        }
        Ok(())
    }
}

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields, default)]
pub struct Appearance {
    pub theme: Theme,
    pub accent: Accent,
    pub scale: f64,
    pub reduce_motion: bool,
}

impl Default for Appearance {
    fn default() -> Self {
        Self {
            theme: Theme::Dark,
            accent: Accent::Purple,
            scale: 1.0,
            reduce_motion: false,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Theme {
    #[default]
    Dark,
    Light,
    HighContrast,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum Accent {
    #[default]
    Purple,
    Blue,
    Mint,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields, default)]
pub struct Launcher {
    pub recent_limit: u8,
}

impl Default for Launcher {
    fn default() -> Self {
        Self { recent_limit: 8 }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields, default)]
pub struct Notifications {
    pub do_not_disturb: bool,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn default_config_is_valid_and_roundtrips() {
        let config = Config::default();
        config.validate().unwrap();
        let json = serde_json::to_string(&config).unwrap();
        let parsed: Config = serde_json::from_str(&json).unwrap();
        assert_eq!(parsed, config);
        assert!(json.contains("\"reduceMotion\":false"));
    }

    #[test]
    fn unknown_fields_are_rejected() {
        let error = serde_json::from_str::<Config>(r#"{"version":1,"surprise":true}"#).unwrap_err();
        assert!(error.to_string().contains("unknown field"));
    }

    #[test]
    fn validation_rejects_out_of_range_scale_and_recent_limit() {
        let mut config = Config::default();
        config.appearance.scale = 0.5;
        assert!(config.validate().is_err());

        config.appearance.scale = 1.25;
        config.launcher.recent_limit = 0;
        assert!(config.validate().is_err());

        config.launcher.recent_limit = 51;
        assert!(config.validate().is_err());

        config.launcher.recent_limit = 8;
        config.appearance.scale = f64::NAN;
        assert!(config.validate().is_err());
    }

    #[test]
    fn theme_and_accent_use_stable_json_names() {
        let mut config = Config::default();
        config.appearance.theme = Theme::HighContrast;
        config.appearance.accent = Accent::Mint;
        let value = serde_json::to_value(&config).unwrap();
        assert_eq!(value["appearance"]["theme"], "high-contrast");
        assert_eq!(value["appearance"]["accent"], "mint");
        assert!(serde_json::from_value::<Config>(
            serde_json::json!({"appearance": {"theme": "sepia"}})
        )
        .is_err());
    }
}
