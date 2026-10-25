use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::error::BackupError;

pub const BACKUP_VERSION: u32 = 1;
pub const MANIFEST_FILE: &str = "manifest.json";
pub const MAX_FILES: usize = 1000;
pub const MAX_FILE_BYTES: usize = 8 * 1024 * 1024;
pub const MAX_TOTAL_BYTES: usize = 64 * 1024 * 1024;
pub const MAX_MANIFEST_BYTES: usize = 2 * 1024 * 1024;

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct BackupManifest {
    pub version: u32,
    pub created_at: u64,
    pub files: Vec<BackupFile>,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct BackupFile {
    pub path: String,
    pub sha256: String,
    pub size: u64,
}

impl BackupManifest {
    pub fn new(created_at: u64, files: Vec<BackupFile>) -> Self {
        Self {
            version: BACKUP_VERSION,
            created_at,
            files,
        }
    }

    pub fn validate(&self) -> Result<(), BackupError> {
        if self.version != BACKUP_VERSION {
            return Err(BackupError::Invalid(format!(
                "unsupported backup manifest version {}, expected {BACKUP_VERSION}",
                self.version
            )));
        }
        if self.files.len() > MAX_FILES {
            return Err(BackupError::Invalid(format!(
                "manifest lists more than {MAX_FILES} files"
            )));
        }
        let mut seen = std::collections::BTreeSet::new();
        let mut total = 0u64;
        for file in &self.files {
            if !seen.insert(file.path.as_str()) {
                return Err(BackupError::Invalid(format!(
                    "manifest lists '{}' twice",
                    file.path
                )));
            }
            ArchivePath::parse(&file.path)?;
            if file.path == MANIFEST_FILE {
                return Err(BackupError::Invalid(
                    "the manifest must not list itself".to_owned(),
                ));
            }
            if !is_lower_hex_sha256(&file.sha256) {
                return Err(BackupError::Invalid(format!(
                    "manifest contains an invalid SHA-256 for '{}'",
                    file.path
                )));
            }
            if file.size > MAX_FILE_BYTES as u64 {
                return Err(BackupError::Invalid(format!(
                    "manifest entry '{}' is too large",
                    file.path
                )));
            }
            total = total.saturating_add(file.size);
            if total > MAX_TOTAL_BYTES as u64 {
                return Err(BackupError::Invalid(
                    "manifest exceeds the uncompressed size limit".to_owned(),
                ));
            }
        }
        Ok(())
    }
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ArchivePath {
    Manifest,
    Config,
    Space(String),
}

impl ArchivePath {
    pub fn parse(path: &str) -> Result<Self, BackupError> {
        if path.is_empty() || path.contains('\\') || path.contains('\0') || path.starts_with('/') {
            return Err(BackupError::UnsafePath(path.to_owned()));
        }
        if path == MANIFEST_FILE {
            return Ok(Self::Manifest);
        }
        if path == "config/config.json" {
            return Ok(Self::Config);
        }
        let Some(name) = path.strip_prefix("spaces/") else {
            return Err(BackupError::UnsafePath(path.to_owned()));
        };
        if name.contains('/') || name.starts_with('.') {
            return Err(BackupError::UnsafePath(path.to_owned()));
        }
        let stem = name
            .strip_suffix(".json")
            .ok_or_else(|| BackupError::UnsafePath(path.to_owned()))?;
        klyvera_spaces::validate_id(stem).map_err(|_| BackupError::UnsafePath(path.to_owned()))?;
        Ok(Self::Space(name.to_owned()))
    }
}

pub(crate) fn sha256_hex(bytes: &[u8]) -> String {
    let digest = Sha256::digest(bytes);
    let mut output = String::with_capacity(digest.len() * 2);
    use std::fmt::Write as _;
    for byte in digest {
        let _ = write!(output, "{byte:02x}");
    }
    output
}

fn is_lower_hex_sha256(value: &str) -> bool {
    value.len() == 64
        && value
            .chars()
            .all(|character| matches!(character, '0'..='9' | 'a'..='f'))
}

pub(crate) fn timestamp_id(prefix: &str, epoch: u64) -> String {
    let days = (epoch / 86_400) as i64;
    let seconds = epoch % 86_400;
    let (year, month, day) = civil_from_days(days);
    let hour = seconds / 3_600;
    let minute = (seconds % 3_600) / 60;
    let second = seconds % 60;
    format!("{prefix}-{year:04}{month:02}{day:02}-{hour:02}{minute:02}{second:02}")
}

fn civil_from_days(days: i64) -> (i64, u32, u32) {
    let z = days + 719_468;
    let era = if z >= 0 { z } else { z - 146_096 } / 146_097;
    let day_of_era = z - era * 146_097;
    let year_of_era =
        (day_of_era - day_of_era / 1_460 + day_of_era / 36_524 - day_of_era / 146_096) / 365;
    let mut year = year_of_era + era * 400;
    let day_of_year = day_of_era - (365 * year_of_era + year_of_era / 4 - year_of_era / 100);
    let mp = (5 * day_of_year + 2) / 153;
    let day = (day_of_year - (153 * mp + 2) / 5 + 1) as u32;
    let month = if mp < 10 { mp + 3 } else { mp - 9 } as u32;
    if month <= 2 {
        year += 1;
    }
    (year, month, day)
}

pub(crate) fn unix_now() -> u64 {
    std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn timestamps_are_utc_and_stable() {
        assert_eq!(timestamp_id("backup", 0), "backup-19700101-000000");
        assert_eq!(
            timestamp_id("backup", 1_700_000_000),
            "backup-20231114-221320"
        );
    }

    #[test]
    fn archive_paths_are_strict() {
        assert_eq!(
            ArchivePath::parse("config/config.json").unwrap(),
            ArchivePath::Config
        );
        assert_eq!(
            ArchivePath::parse("manifest.json").unwrap(),
            ArchivePath::Manifest
        );
        assert_eq!(
            ArchivePath::parse("spaces/my-space.json").unwrap(),
            ArchivePath::Space("my-space.json".to_owned())
        );
        for path in [
            "../evil",
            "/abs",
            "spaces/../evil.json",
            "spaces/.hidden.json",
            "spaces/Bad_ID.json",
            "spaces/x.json.bak",
            "other/config.json",
            "spaces/nested/x.json",
            "spaces\\x.json",
        ] {
            assert!(ArchivePath::parse(path).is_err(), "{path}");
        }
    }

    #[test]
    fn manifest_validation_catches_duplicates_and_bad_hashes() {
        let file = BackupFile {
            path: "spaces/a.json".to_owned(),
            sha256: "a".repeat(64),
            size: 2,
        };
        let manifest = BackupManifest::new(1, vec![file.clone(), file]);
        assert!(manifest.validate().is_err());

        let manifest = BackupManifest::new(
            1,
            vec![BackupFile {
                path: "spaces/a.json".to_owned(),
                sha256: "not-a-hash".to_owned(),
                size: 2,
            }],
        );
        assert!(manifest.validate().is_err());
    }
}
