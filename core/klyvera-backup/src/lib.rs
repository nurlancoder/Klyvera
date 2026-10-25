//! Integrity-checked, local-only backups for Klyvera configuration and Spaces.
//!
//! Archives are tar.gz with a SHA-256 manifest. Restore verifies structure,
//! paths, sizes and hashes, validates the staged JSON, then creates a
//! pre-restore backup before replacing live files.

mod archive;
mod error;
mod manifest;

pub use archive::{
    create_backup, list_backups, restore_backup, verify_backup, BackupInfo, BackupSummary,
    RestoreReport, VerifyReport,
};
pub use error::BackupError;
pub use manifest::{
    ArchivePath, BackupFile, BackupManifest, BACKUP_VERSION, MANIFEST_FILE, MAX_FILES,
    MAX_FILE_BYTES, MAX_MANIFEST_BYTES, MAX_TOTAL_BYTES,
};
