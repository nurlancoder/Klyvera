use std::fmt::Write as _;
use std::path::{Component, Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::error::SpaceError;

pub const SPACE_VERSION: u32 = 1;
pub const MAX_SPACE_BYTES: usize = 512 * 1024;
const MAX_PATHS: usize = 16;
const MAX_APPS: usize = 32;
const MAX_COMMANDS: usize = 16;
const MAX_ARGV: usize = 32;
const MAX_NAME_CHARS: usize = 80;
const MAX_DESCRIPTION_CHARS: usize = 280;
const MAX_PATH_BYTES: usize = 4096;
const SHELLS: [&str; 14] = [
    "sh",
    "bash",
    "zsh",
    "fish",
    "dash",
    "ksh",
    "csh",
    "tcsh",
    "nu",
    "xonsh",
    "elvish",
    "pwsh",
    "powershell",
    "cmd",
];

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct Space {
    pub version: u32,
    pub id: String,
    pub name: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<String>,
    #[serde(default)]
    pub accent: SpaceAccent,
    pub project_paths: Vec<PathBuf>,
    #[serde(default)]
    pub apps: Vec<AppRef>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub layout: Option<LayoutHints>,
    #[serde(default)]
    pub commands: Vec<TerminalCommand>,
    #[serde(default)]
    pub created_at: u64,
    #[serde(default)]
    pub updated_at: u64,
}

impl Space {
    pub fn new(name: &str, project_paths: Vec<PathBuf>) -> Result<Self, SpaceError> {
        let name = name.trim();
        let now = unix_now();
        let space = Self {
            version: SPACE_VERSION,
            id: slugify(name),
            name: name.to_owned(),
            description: None,
            icon: None,
            accent: SpaceAccent::Purple,
            project_paths,
            apps: Vec::new(),
            layout: None,
            commands: Vec::new(),
            created_at: now,
            updated_at: now,
        };
        space.validate()?;
        Ok(space)
    }

    pub fn with_id(
        id: impl Into<String>,
        name: &str,
        project_paths: Vec<PathBuf>,
    ) -> Result<Self, SpaceError> {
        let mut space = Self::new(name, project_paths)?;
        space.id = id.into();
        space.validate()?;
        Ok(space)
    }

    pub fn validate(&self) -> Result<(), SpaceError> {
        if self.version != SPACE_VERSION {
            return Err(SpaceError::Invalid(format!(
                "expected version {SPACE_VERSION}, found {}",
                self.version
            )));
        }
        validate_id(&self.id)?;
        validate_name(&self.name)?;
        if let Some(description) = &self.description {
            if description.chars().count() > MAX_DESCRIPTION_CHARS {
                return Err(SpaceError::Invalid(format!(
                    "description must be at most {MAX_DESCRIPTION_CHARS} characters"
                )));
            }
            if description.chars().any(char::is_control) {
                return Err(SpaceError::Invalid(
                    "description must not contain control characters".to_owned(),
                ));
            }
        }
        if let Some(icon) = &self.icon {
            validate_icon(icon)?;
        }
        if self.project_paths.is_empty() {
            return Err(SpaceError::Invalid(
                "at least one project path is required".to_owned(),
            ));
        }
        if self.project_paths.len() > MAX_PATHS {
            return Err(SpaceError::Invalid(format!(
                "at most {MAX_PATHS} project paths are allowed"
            )));
        }
        let mut seen = std::collections::BTreeSet::new();
        for path in &self.project_paths {
            validate_structural_path(path, "project path")?;
            if !seen.insert(path.clone()) {
                return Err(SpaceError::DuplicatePath(path.clone()));
            }
        }
        if self.apps.len() > MAX_APPS {
            return Err(SpaceError::Invalid(format!(
                "at most {MAX_APPS} applications are allowed"
            )));
        }
        let mut seen_apps = std::collections::BTreeSet::new();
        for app in &self.apps {
            validate_desktop_id(&app.desktop_id)?;
            if !seen_apps.insert(app.desktop_id.clone()) {
                return Err(SpaceError::Invalid(format!(
                    "duplicate application: {}",
                    app.desktop_id
                )));
            }
        }
        if let Some(layout) = &self.layout {
            layout.validate()?;
        }
        if self.commands.len() > MAX_COMMANDS {
            return Err(SpaceError::Invalid(format!(
                "at most {MAX_COMMANDS} commands are allowed"
            )));
        }
        for command in &self.commands {
            command.validate()?;
        }
        Ok(())
    }

    /// Check that every project path is an existing directory and that
    /// canonical duplicates are rejected. Structural validation is separate so
    /// a Space whose folder moved can still be loaded and edited.
    pub fn validate_existing_paths(&self) -> Result<(), SpaceError> {
        let mut canonical = std::collections::BTreeSet::new();
        for path in &self.project_paths {
            let resolved =
                std::fs::canonicalize(path).map_err(|_| SpaceError::MissingPath(path.clone()))?;
            let metadata =
                std::fs::metadata(&resolved).map_err(|_| SpaceError::MissingPath(path.clone()))?;
            if !metadata.is_dir() {
                return Err(SpaceError::MissingPath(path.clone()));
            }
            if !canonical.insert(resolved) {
                return Err(SpaceError::DuplicatePath(path.clone()));
            }
        }
        Ok(())
    }

    pub fn touch(&mut self) {
        self.updated_at = unix_now();
    }

    /// SHA-256 of the canonical JSON representation. Confirmation is recorded
    /// per hash, so any content change invalidates an earlier confirmation.
    pub fn profile_hash(&self) -> Result<String, SpaceError> {
        let bytes = serde_json::to_vec(self).map_err(|error| SpaceError::json("profile", error))?;
        let digest = Sha256::digest(bytes);
        let mut output = String::with_capacity(digest.len() * 2);
        for byte in digest {
            let _ = write!(output, "{byte:02x}");
        }
        Ok(output)
    }

    /// Normalise optional timestamps for hand-written or imported profiles.
    pub fn normalize_timestamps(&mut self) {
        let now = unix_now();
        if self.created_at == 0 {
            self.created_at = now;
        }
        if self.updated_at == 0 {
            self.updated_at = self.created_at;
        }
        if self.updated_at < self.created_at {
            self.updated_at = self.created_at;
        }
    }

    pub fn path_display(&self) -> String {
        self.project_paths
            .iter()
            .map(|path| path.display().to_string())
            .collect::<Vec<_>>()
            .join(", ")
    }

    pub fn project_path_for_cwd(&self) -> Option<&Path> {
        self.project_paths.first().map(PathBuf::as_path)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SpaceAccent {
    #[default]
    Purple,
    Blue,
    Mint,
    Neutral,
}

impl SpaceAccent {
    pub fn parse(value: &str) -> Result<Self, SpaceError> {
        match value {
            "purple" => Ok(Self::Purple),
            "blue" => Ok(Self::Blue),
            "mint" => Ok(Self::Mint),
            "neutral" => Ok(Self::Neutral),
            other => Err(SpaceError::Invalid(format!(
                "accent must be purple, blue, mint or neutral, found '{other}'"
            ))),
        }
    }

    pub fn as_str(self) -> &'static str {
        match self {
            Self::Purple => "purple",
            Self::Blue => "blue",
            Self::Mint => "mint",
            Self::Neutral => "neutral",
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct AppRef {
    pub desktop_id: String,
}

impl AppRef {
    pub fn new(desktop_id: impl Into<String>) -> Self {
        Self {
            desktop_id: desktop_id.into(),
        }
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields, default)]
pub struct LayoutHints {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub monitor: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub workspace: Option<u8>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub master_count: Option<u8>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub gaps_in: Option<u8>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub gaps_out: Option<u8>,
}

impl LayoutHints {
    fn validate(&self) -> Result<(), SpaceError> {
        if let Some(monitor) = &self.monitor {
            let valid_length = (1..=64).contains(&monitor.len());
            let valid_chars = monitor
                .chars()
                .all(|character| character.is_ascii_alphanumeric() || "-_.:".contains(character));
            if !valid_length || !valid_chars {
                return Err(SpaceError::Invalid(
                    "layout.monitor must be 1-64 characters of letters, digits, '-', '_', '.' or ':'"
                        .to_owned(),
                ));
            }
        }
        if let Some(workspace) = self.workspace {
            if !(1..=99).contains(&workspace) {
                return Err(SpaceError::Invalid(
                    "layout.workspace must be between 1 and 99".to_owned(),
                ));
            }
        }
        if let Some(master_count) = self.master_count {
            if !(1..=10).contains(&master_count) {
                return Err(SpaceError::Invalid(
                    "layout.masterCount must be between 1 and 10".to_owned(),
                ));
            }
        }
        for (name, value) in [("gapsIn", self.gaps_in), ("gapsOut", self.gaps_out)] {
            if let Some(value) = value {
                if value > 100 {
                    return Err(SpaceError::Invalid(format!(
                        "layout.{name} must be between 0 and 100"
                    )));
                }
            }
        }
        Ok(())
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct TerminalCommand {
    pub label: String,
    pub argv: Vec<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cwd: Option<PathBuf>,
}

impl TerminalCommand {
    pub fn new(label: impl Into<String>, argv: Vec<String>) -> Self {
        Self {
            label: label.into(),
            argv,
            cwd: None,
        }
    }

    fn validate(&self) -> Result<(), SpaceError> {
        let label = self.label.trim();
        if label.is_empty() || label.chars().count() > MAX_NAME_CHARS {
            return Err(SpaceError::Invalid(format!(
                "command label must be 1-{MAX_NAME_CHARS} characters"
            )));
        }
        if self.label.chars().any(char::is_control) {
            return Err(SpaceError::Invalid(
                "command label must not contain control characters".to_owned(),
            ));
        }
        if self.argv.is_empty() {
            return Err(SpaceError::Invalid(format!(
                "command '{label}' has an empty argv"
            )));
        }
        if self.argv.len() > MAX_ARGV {
            return Err(SpaceError::Invalid(format!(
                "command '{label}' has more than {MAX_ARGV} arguments"
            )));
        }
        for (index, argument) in self.argv.iter().enumerate() {
            if index == 0 && argument.is_empty() {
                return Err(SpaceError::Invalid(format!(
                    "command '{label}' has an empty program"
                )));
            }
            if argument.len() > MAX_PATH_BYTES {
                return Err(SpaceError::Invalid(format!(
                    "command '{label}' has an argument longer than {MAX_PATH_BYTES} bytes"
                )));
            }
            if argument.contains('\0') {
                return Err(SpaceError::Invalid(format!(
                    "command '{label}' contains a NUL byte"
                )));
            }
        }
        if is_shell(&self.argv[0]) {
            return Err(SpaceError::Invalid(format!(
                "command '{label}' uses a shell interpreter; provide the program and arguments directly"
            )));
        }
        if let Some(cwd) = &self.cwd {
            validate_structural_path(cwd, "command cwd")?;
        }
        Ok(())
    }

    pub fn cwd_or<'a>(&'a self, fallback: Option<&'a Path>) -> Option<&'a Path> {
        self.cwd.as_deref().or(fallback)
    }
}

fn is_shell(program: &str) -> bool {
    let base = program
        .rsplit(['/', '\\'])
        .next()
        .unwrap_or(program)
        .to_ascii_lowercase();
    SHELLS.contains(&base.as_str())
}

pub fn validate_id(id: &str) -> Result<(), SpaceError> {
    let valid_length = (1..=64).contains(&id.len());
    let starts_well = id
        .chars()
        .next()
        .is_some_and(|character| character.is_ascii_alphanumeric());
    let ends_well = id
        .chars()
        .last()
        .is_some_and(|character| character.is_ascii_alphanumeric());
    let valid_chars = id.chars().all(|character| {
        character.is_ascii_lowercase() || character.is_ascii_digit() || character == '-'
    });
    if valid_length && starts_well && ends_well && valid_chars {
        Ok(())
    } else {
        Err(SpaceError::Invalid(format!(
            "id must be 1-64 lowercase letters, digits or hyphens and start and end with a letter or digit: '{id}'"
        )))
    }
}

pub fn validate_desktop_id(id: &str) -> Result<(), SpaceError> {
    if id.is_empty() || id.len() > 256 {
        return Err(SpaceError::Invalid(
            "desktopId must be 1-256 characters".to_owned(),
        ));
    }
    if !id.ends_with(".desktop") {
        return Err(SpaceError::Invalid(format!(
            "desktopId must end with .desktop: '{id}'"
        )));
    }
    if id.starts_with('/') || id.contains('\\') || id.contains('\0') {
        return Err(SpaceError::Invalid(format!(
            "desktopId must be a relative path without backslashes: '{id}'"
        )));
    }
    for component in id.split('/') {
        if component.is_empty() || component == "." || component == ".." {
            return Err(SpaceError::Invalid(format!(
                "desktopId contains an unsafe path component: '{id}'"
            )));
        }
        if component.chars().any(char::is_control) {
            return Err(SpaceError::Invalid(
                "desktopId must not contain control characters".to_owned(),
            ));
        }
    }
    Ok(())
}

pub fn slugify(name: &str) -> String {
    let mut slug = String::new();
    let mut previous_hyphen = false;
    for character in name.chars() {
        if character.is_ascii_alphanumeric() {
            slug.push(character.to_ascii_lowercase());
            previous_hyphen = false;
        } else if !previous_hyphen && !slug.is_empty() {
            slug.push('-');
            previous_hyphen = true;
        }
        if slug.len() >= 64 {
            break;
        }
    }
    while slug.ends_with('-') {
        slug.pop();
    }
    if slug.is_empty() {
        "space".to_owned()
    } else {
        slug
    }
}

fn validate_name(name: &str) -> Result<(), SpaceError> {
    if name.is_empty() {
        return Err(SpaceError::Invalid("name must not be empty".to_owned()));
    }
    if name.trim() != name {
        return Err(SpaceError::Invalid(
            "name must not start or end with whitespace".to_owned(),
        ));
    }
    if name.chars().count() > MAX_NAME_CHARS {
        return Err(SpaceError::Invalid(format!(
            "name must be at most {MAX_NAME_CHARS} characters"
        )));
    }
    if name.chars().any(char::is_control) {
        return Err(SpaceError::Invalid(
            "name must not contain control characters".to_owned(),
        ));
    }
    Ok(())
}

fn validate_icon(icon: &str) -> Result<(), SpaceError> {
    let valid_length = (1..=64).contains(&icon.len());
    let starts_well = icon
        .chars()
        .next()
        .is_some_and(|character| character.is_ascii_lowercase() || character.is_ascii_digit());
    let valid_chars = icon.chars().all(|character| {
        character.is_ascii_lowercase() || character.is_ascii_digit() || character == '-'
    });
    if valid_length && starts_well && valid_chars {
        Ok(())
    } else {
        Err(SpaceError::Invalid(
            "icon must be 1-64 lowercase letters, digits or hyphens".to_owned(),
        ))
    }
}

fn validate_structural_path(path: &Path, label: &str) -> Result<(), SpaceError> {
    if !path.is_absolute() {
        return Err(SpaceError::Invalid(format!(
            "{label} must be absolute: {}",
            path.display()
        )));
    }
    if path.as_os_str().len() > MAX_PATH_BYTES {
        return Err(SpaceError::Invalid(format!(
            "{label} is longer than {MAX_PATH_BYTES} bytes"
        )));
    }
    if path.components().any(|component| {
        matches!(
            component,
            Component::ParentDir | Component::CurDir | Component::Prefix(_)
        )
    }) {
        return Err(SpaceError::Invalid(format!(
            "{label} must not contain '.', '..' or a prefix: {}",
            path.display()
        )));
    }
    #[cfg(unix)]
    {
        use std::os::unix::ffi::OsStrExt;
        if path.as_os_str().as_bytes().contains(&0) {
            return Err(SpaceError::Invalid(format!("{label} contains a NUL byte")));
        }
    }
    Ok(())
}

pub(crate) fn unix_now() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_secs())
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use super::*;

    fn absolute_temp_path() -> PathBuf {
        PathBuf::from("/tmp/klyvera-test-project")
    }

    #[test]
    fn new_space_normalises_name_and_ids() {
        let space = Space::new("  My Demo Project  ", vec![absolute_temp_path()]).unwrap();
        assert_eq!(space.name, "My Demo Project");
        assert_eq!(space.id, "my-demo-project");
        assert_eq!(space.version, SPACE_VERSION);
        assert_eq!(space.profile_hash().unwrap().len(), 64);
    }

    #[test]
    fn slugify_handles_unicode_and_empty_names() {
        assert_eq!(slugify("Hello, World!"), "hello-world");
        assert_eq!(slugify("  ---  "), "space");
        assert_eq!(slugify("Проект"), "space");
        assert_eq!(slugify(&"a".repeat(80)).len(), 64);
    }

    #[test]
    fn validation_rejects_unsafe_and_malformed_fields() {
        let mut space = Space::new("Demo", vec![absolute_temp_path()]).unwrap();
        assert!(space.validate().is_ok());

        space.id = "../escape".to_owned();
        assert!(space.validate().is_err());
        space.id = "good-id".to_owned();

        space.name = "bad\nname".to_owned();
        assert!(space.validate().is_err());
        space.name = "Demo".to_owned();

        space.project_paths = vec![PathBuf::from("relative/path")];
        assert!(space.validate().is_err());
        space.project_paths = vec![PathBuf::from("/tmp/../etc")];
        assert!(space.validate().is_err());
        space.project_paths = vec![absolute_temp_path()];

        space.apps = vec![AppRef::new("../../../evil.desktop")];
        assert!(space.validate().is_err());
        space.apps = vec![AppRef::new("code.desktop"), AppRef::new("code.desktop")];
        assert!(space.validate().is_err());
        space.apps.clear();

        space.commands = vec![TerminalCommand::new("shell", vec!["/bin/sh".to_owned()])];
        assert!(space.validate().is_err());
        space.commands = vec![TerminalCommand::new("ok", vec!["/bin/true".to_owned()])];
        assert!(space.validate().is_ok());
    }

    #[test]
    fn layout_ranges_are_enforced() {
        let mut space = Space::new("Demo", vec![absolute_temp_path()]).unwrap();
        space.layout = Some(LayoutHints {
            workspace: Some(0),
            ..LayoutHints::default()
        });
        assert!(space.validate().is_err());

        space.layout = Some(LayoutHints {
            monitor: Some("bad monitor".to_owned()),
            ..LayoutHints::default()
        });
        assert!(space.validate().is_err());

        space.layout = Some(LayoutHints {
            monitor: Some("DP-1".to_owned()),
            workspace: Some(3),
            master_count: Some(2),
            gaps_in: Some(4),
            gaps_out: Some(8),
        });
        assert!(space.validate().is_ok());
    }

    #[test]
    fn profile_hash_changes_with_content() {
        let mut space = Space::new("Demo", vec![absolute_temp_path()]).unwrap();
        let first = space.profile_hash().unwrap();
        space
            .commands
            .push(TerminalCommand::new("test", vec!["/bin/true".to_owned()]));
        let second = space.profile_hash().unwrap();
        assert_ne!(first, second);
        assert_eq!(second.len(), 64);
        assert!(second
            .chars()
            .all(|character| character.is_ascii_hexdigit()));
    }

    #[test]
    fn timestamps_normalise() {
        let mut space = Space::new("Demo", vec![absolute_temp_path()]).unwrap();
        space.created_at = 0;
        space.updated_at = 0;
        space.normalize_timestamps();
        assert!(space.created_at > 0);
        assert_eq!(space.updated_at, space.created_at);

        space.created_at = 10;
        space.updated_at = 5;
        space.normalize_timestamps();
        assert_eq!(space.updated_at, 10);
    }

    #[test]
    fn desktop_ids_are_relative_and_terminated() {
        assert!(validate_desktop_id("org.example.App.desktop").is_ok());
        assert!(validate_desktop_id("nested/app.desktop").is_ok());
        for bad in [
            "/abs.desktop",
            "../app.desktop",
            "app",
            "a//b.desktop",
            "a\\b.desktop",
            "nested/../app.desktop",
        ] {
            assert!(validate_desktop_id(bad).is_err(), "{bad}");
        }
    }

    #[test]
    fn command_validation_rejects_shells_and_control_bytes() {
        for shell in ["/bin/bash", "zsh", "/usr/bin/fish", "C:\\cmd"] {
            let command = TerminalCommand::new("bad", vec![shell.to_owned()]);
            assert!(command.validate().is_err(), "{shell}");
        }
        let command = TerminalCommand::new("bad", vec!["/bin/echo".to_owned(), "\0".to_owned()]);
        assert!(command.validate().is_err());
        let command = TerminalCommand::new(
            "bad",
            vec!["/bin/echo".to_owned(), "x".repeat(MAX_PATH_BYTES + 1)],
        );
        assert!(command.validate().is_err());
    }

    #[test]
    fn accents_roundtrip() {
        for accent in [
            SpaceAccent::Purple,
            SpaceAccent::Blue,
            SpaceAccent::Mint,
            SpaceAccent::Neutral,
        ] {
            assert_eq!(SpaceAccent::parse(accent.as_str()).unwrap(), accent);
        }
        assert!(SpaceAccent::parse("orange").is_err());
    }
}
