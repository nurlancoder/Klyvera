use std::fs;
use std::path::Path;

use serde_json::{Map, Value};

use crate::atomic::write_json_atomic;
use crate::model::{Config, SCHEMA_VERSION};
use crate::ConfigError;

pub const MAX_CONFIG_BYTES: usize = 1024 * 1024;

pub fn load(path: &Path) -> Result<Config, ConfigError> {
    let bytes = read_limited(path)?;
    parse(path, &bytes)
}

pub fn parse(path: &Path, bytes: &[u8]) -> Result<Config, ConfigError> {
    if bytes.len() > MAX_CONFIG_BYTES {
        return Err(ConfigError::TooLarge {
            size: bytes.len() as u64,
            limit: MAX_CONFIG_BYTES,
        });
    }
    let value: Value =
        serde_json::from_slice(bytes).map_err(|error| ConfigError::json(path, error))?;
    let value = migrate_value(value)?;
    let config: Config =
        serde_json::from_value(value).map_err(|error| ConfigError::json(path, error))?;
    config.validate()?;
    Ok(config)
}

/// Load the configuration, or return defaults when the file does not exist.
/// The caller decides whether to persist the defaults.
pub fn load_or_default(path: &Path) -> Result<Config, ConfigError> {
    match load(path) {
        Ok(config) => Ok(config),
        Err(error) if error.is_not_found() => Ok(Config::default()),
        Err(error) => Err(error),
    }
}

pub fn save(path: &Path, config: &Config) -> Result<(), ConfigError> {
    config.validate()?;
    write_json_atomic(path, config)
}

pub fn to_json_string(config: &Config) -> Result<String, ConfigError> {
    config.validate()?;
    let mut json = serde_json::to_string_pretty(config).map_err(|error| ConfigError::Json {
        path: Path::new("config.json").to_path_buf(),
        source: error,
    })?;
    json.push('\n');
    Ok(json)
}

fn read_limited(path: &Path) -> Result<Vec<u8>, ConfigError> {
    let metadata = fs::metadata(path).map_err(|error| ConfigError::io(path, error))?;
    if metadata.len() > MAX_CONFIG_BYTES as u64 {
        return Err(ConfigError::TooLarge {
            size: metadata.len(),
            limit: MAX_CONFIG_BYTES,
        });
    }
    let bytes = fs::read(path).map_err(|error| ConfigError::io(path, error))?;
    if bytes.len() > MAX_CONFIG_BYTES {
        return Err(ConfigError::TooLarge {
            size: bytes.len() as u64,
            limit: MAX_CONFIG_BYTES,
        });
    }
    Ok(bytes)
}

pub(crate) fn migrate_value(mut value: Value) -> Result<Value, ConfigError> {
    let version = match value.get("version") {
        None => 0,
        Some(version) => version.as_u64().ok_or_else(|| {
            ConfigError::Validation("version must be a non-negative integer".to_owned())
        })?,
    };

    if version > u64::from(SCHEMA_VERSION) {
        return Err(ConfigError::UnsupportedVersion(version));
    }

    if version == 0 {
        let object = value.as_object_mut().ok_or_else(|| {
            ConfigError::Validation("configuration root must be a JSON object".to_owned())
        })?;
        migrate_zero_to_one(object)?;
    }

    Ok(value)
}

fn migrate_zero_to_one(object: &mut Map<String, Value>) -> Result<(), ConfigError> {
    let legacy_keys = ["theme", "accent", "scale", "reduceMotion"];
    let mut appearance = Map::new();
    for key in legacy_keys {
        if let Some(value) = object.remove(key) {
            appearance.insert(key.to_owned(), value);
        }
    }

    if !appearance.is_empty() {
        match object.get_mut("appearance") {
            Some(Value::Object(existing)) => {
                for (key, value) in appearance {
                    if existing.insert(key.clone(), value).is_some() {
                        return Err(ConfigError::Validation(format!(
                            "legacy key '{key}' conflicts with appearance.{key}"
                        )));
                    }
                }
            }
            Some(_) => {
                return Err(ConfigError::Validation(
                    "appearance must be a JSON object".to_owned(),
                ));
            }
            None => {
                object.insert("appearance".to_owned(), Value::Object(appearance));
            }
        }
    }

    object.insert("version".to_owned(), Value::from(SCHEMA_VERSION));
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::os::unix::fs::PermissionsExt;
    use tempfile::tempdir;

    #[test]
    fn saves_and_loads_config_with_private_permissions() {
        let temp = tempdir().unwrap();
        let path = temp.path().join("config.json");
        let mut config = Config::default();
        config.appearance.theme = crate::model::Theme::Light;
        config.appearance.scale = 1.25;
        save(&path, &config).unwrap();
        assert_eq!(load(&path).unwrap(), config);
        assert_eq!(
            fs::metadata(&path).unwrap().permissions().mode() & 0o777,
            0o600
        );
    }

    #[test]
    fn missing_file_returns_defaults() {
        let temp = tempdir().unwrap();
        let path = temp.path().join("missing.json");
        assert_eq!(load_or_default(&path).unwrap(), Config::default());
        assert!(load(&path).unwrap_err().is_not_found());
    }

    #[test]
    fn migrates_legacy_flat_appearance() {
        let temp = tempdir().unwrap();
        let path = temp.path().join("config.json");
        let legacy = br#"{
            "theme": "light",
            "accent": "blue",
            "scale": 1.25,
            "reduceMotion": true,
            "launcher": { "recentLimit": 12 }
        }"#;
        let config = parse(&path, legacy).unwrap();
        assert_eq!(config.version, 1);
        assert_eq!(config.appearance.theme, crate::model::Theme::Light);
        assert_eq!(config.appearance.accent, crate::model::Accent::Blue);
        assert_eq!(config.appearance.scale, 1.25);
        assert!(config.appearance.reduce_motion);
        assert_eq!(config.launcher.recent_limit, 12);
    }

    #[test]
    fn empty_object_becomes_versioned_defaults() {
        let temp = tempdir().unwrap();
        let config = parse(&temp.path().join("config.json"), b"{}").unwrap();
        assert_eq!(config, Config::default());
    }

    #[test]
    fn rejects_future_invalid_and_oversized_documents() {
        let temp = tempdir().unwrap();
        let path = temp.path().join("config.json");

        let error = parse(&path, br#"{"version": 99}"#).unwrap_err();
        assert!(matches!(error, ConfigError::UnsupportedVersion(99)));

        let error = parse(&path, br#"{"version": "one"}"#).unwrap_err();
        assert!(matches!(error, ConfigError::Validation(_)));

        let error = parse(&path, br#"[1, 2, 3]"#).unwrap_err();
        assert!(matches!(error, ConfigError::Validation(_)));

        let error = parse(&path, br#"{"appearance":{"scale":9.0}}"#).unwrap_err();
        assert!(matches!(error, ConfigError::Validation(_)));

        let oversized = vec![b' '; MAX_CONFIG_BYTES + 1];
        let error = parse(&path, &oversized).unwrap_err();
        assert!(matches!(error, ConfigError::TooLarge { .. }));
    }

    #[test]
    fn legacy_appearance_conflict_is_rejected() {
        let temp = tempdir().unwrap();
        let path = temp.path().join("config.json");
        let error =
            parse(&path, br#"{"theme":"light","appearance":{"theme":"dark"}}"#).unwrap_err();
        assert!(matches!(error, ConfigError::Validation(_)));
    }
}
