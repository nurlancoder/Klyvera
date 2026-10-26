use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};

use crate::error::SpaceError;
use crate::model::{unix_now, Space};
use klyvera_config::{ensure_private_dir, write_json_atomic};

const TRUST_VERSION: u32 = 1;
const MAX_TRUST_BYTES: u64 = 1024 * 1024;

struct TrustDocument {
    version: u32,
    entries: BTreeMap<String, TrustEntry>,
}

impl Default for TrustDocument {
    fn default() -> Self {
        Self {
            version: TRUST_VERSION,
            entries: BTreeMap::new(),
        }
    }
}

struct TrustEntry {
    space_id: String,
    confirmed_at: u64,
}

pub struct TrustStore {
    path: PathBuf,
    document: TrustDocument,
}

impl TrustStore {
    pub fn open(path: impl Into<PathBuf>) -> Result<Self, SpaceError> {
        let path = path.into();
        if !path.is_absolute() {
            return Err(SpaceError::Invalid(format!(
                "trust file must be an absolute path: {}",
                path.display()
            )));
        }
        let document = match std::fs::metadata(&path) {
            Ok(metadata) => {
                if metadata.len() > MAX_TRUST_BYTES {
                    return Err(SpaceError::TooLarge {
                        size: metadata.len(),
                        limit: MAX_TRUST_BYTES as usize,
                    });
                }
                let bytes = std::fs::read(&path).map_err(|error| SpaceError::io(&path, error))?;
                let document: TrustDocument = serde_json::from_slice(&bytes)
                    .map_err(|error| SpaceError::json(path.display().to_string(), error))?;
                validate_document(&document)?;
                document
            }
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => TrustDocument::default(),
            Err(error) => return Err(SpaceError::io(&path, error)),
        };
        Ok(Self { path, document })
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn is_trusted(&self, space: &Space) -> Result<bool, SpaceError> {
        let hash = space.profile_hash()?;
        Ok(self.document.entries.contains_key(&hash))
    }

    pub fn trust(&mut self, space: &Space) -> Result<String, SpaceError> {
        let hash = space.profile_hash()?;
        self.document
            .entries
            .retain(|_, entry| entry.space_id != space.id);
        self.document.entries.insert(
            hash.clone(),
            TrustEntry {
                space_id: space.id.clone(),
                confirmed_at: unix_now(),
            },
        );
        self.save()?;
        Ok(hash)
    }

    pub fn revoke(&mut self, space_id: &str) -> Result<usize, SpaceError> {
        let before = self.document.entries.len();
        self.document
            .entries
            .retain(|_, entry| entry.space_id != space_id);
        let removed = before - self.document.entries.len();
        if removed > 0 {
            self.save()?;
        }
        Ok(removed)
    }

    pub fn trusted_hash(&self, space_id: &str) -> Option<&str> {
        self.document
            .entries
            .iter()
            .find_map(|(hash, entry)| (entry.space_id == space_id).then_some(hash.as_str()))
    }

    pub fn entry_count(&self) -> usize {
        self.document.entries.len()
    }

    fn save(&self) -> Result<(), SpaceError> {
        if let Some(parent) = self.path.parent() {
            ensure_private_dir(parent)?;
        }
        write_json_atomic(&self.path, &self.document)?;
        Ok(())
    }
}

fn validate_document(document: &TrustDocument) -> Result<(), SpaceError> {
    if document.version != TRUST_VERSION {
        return Err(SpaceError::Invalid(format!(
            "unsupported trust version {}, expected {TRUST_VERSION}",
            document.version
        )));
    }
    for hash in document.entries.keys() {
        if hash.len() != 64 || !hash.chars().all(|character| character.is_ascii_hexdigit()) {
            return Err(SpaceError::Invalid(
                "trust file contains an invalid profile hash".to_owned(),
            ));
        }
    }
    Ok(())
}

mod tests {
    use super::*;
    use crate::model::TerminalCommand;

    fn space() -> Space {
        let mut space =
            Space::new("Trusted", vec![PathBuf::from("/tmp/klyvera-trust-project")]).unwrap();
        space.commands = vec![TerminalCommand::new("test", vec!["/bin/true".to_owned()])];
        space
    }

    fn trust_is_tied_to_profile_content() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("data/trust.json");
        let mut space = space();
        let mut store = TrustStore::open(&path).unwrap();
        assert_eq!(store.entry_count(), 0);
        assert!(!store.is_trusted(&space).unwrap());

        let hash = store.trust(&space).unwrap();
        assert_eq!(hash.len(), 64);
        assert!(store.is_trusted(&space).unwrap());
        assert_eq!(store.trusted_hash(&space.id), Some(hash.as_str()));

        let reopened = TrustStore::open(&path).unwrap();
        assert!(reopened.is_trusted(&space).unwrap());

        space.commands[0].argv.push("--changed".to_owned());
        assert!(!reopened.is_trusted(&space).unwrap());
    }

    fn trusting_again_replaces_older_hash_and_revoke_removes_all() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("trust.json");
        let mut space = space();
        let mut store = TrustStore::open(&path).unwrap();
        store.trust(&space).unwrap();
        space.commands.clear();
        store.trust(&space).unwrap();
        assert_eq!(store.entry_count(), 1);
        assert_eq!(store.revoke(&space.id).unwrap(), 1);
        assert_eq!(store.revoke(&space.id).unwrap(), 0);
        assert!(!store.is_trusted(&space).unwrap());
    }

    fn malformed_trust_file_fails_closed() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("trust.json");
        std::fs::write(&path, b"{not json").unwrap();
        assert!(TrustStore::open(&path).is_err());
        std::fs::write(&path, br#"{"version":2,"entries":{}}"#).unwrap();
        assert!(TrustStore::open(&path).is_err());
        std::fs::write(
            &path,
            br#"{"version":1,"entries":{"not-a-hash":{"spaceId":"x","confirmedAt":1}}}"#,
        )
        .unwrap();
        assert!(TrustStore::open(&path).is_err());
    }
}
