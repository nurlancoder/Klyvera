use std::collections::BTreeMap;
use std::path::{Path, PathBuf};

use crate::error::SpaceError;
use crate::model::validate_desktop_id;

const MAX_DESKTOP_BYTES: u64 = 128 * 1024;
const MAX_DEPTH: usize = 4;

pub struct DesktopEntry {
    pub id: String,
    pub name: String,
    pub exec: Vec<String>,
    pub icon: Option<String>,
    pub terminal: bool,
    pub no_display: bool,
    pub comment: Option<String>,
}

pub struct DesktopIndex {
    entries: BTreeMap<String, DesktopEntry>,
}

impl DesktopIndex {
    pub fn load_default() -> Self {
        Self::load(&desktop_search_roots())
    }

    pub fn load(roots: &[PathBuf]) -> Self {
        let mut index = Self::default();
        for root in roots {
            let Ok(canonical) = std::fs::canonicalize(root) else {
                continue;
            };
            index.scan_root(&canonical, &canonical, 0);
        }
        index
    }

    pub fn from_entries(entries: impl IntoIterator<Item = DesktopEntry>) -> Self {
        Self {
            entries: entries
                .into_iter()
                .map(|entry| (entry.id.clone(), entry))
                .collect(),
        }
    }

    fn scan_root(&mut self, root: &Path, directory: &Path, depth: usize) {
        if depth > MAX_DEPTH {
            return;
        }
        let Ok(read_dir) = std::fs::read_dir(directory) else {
            return;
        };
        let mut paths = read_dir
            .flatten()
            .map(|entry| entry.path())
            .collect::<Vec<_>>();
        paths.sort();

        for path in paths {
            let Ok(metadata) = std::fs::symlink_metadata(&path) else {
                continue;
            };
            if metadata.file_type().is_symlink() {
                continue;
            }
            if metadata.is_dir() {
                self.scan_root(root, &path, depth + 1);
                continue;
            }
            if !metadata.is_file() || metadata.len() > MAX_DESKTOP_BYTES {
                continue;
            }
            if path.extension().and_then(|extension| extension.to_str()) != Some("desktop") {
                continue;
            }
            let Ok(relative) = path.strip_prefix(root) else {
                continue;
            };
            let Some(id) = relative.to_str().map(|value| value.replace('\\', "/")) else {
                continue;
            };
            if validate_desktop_id(&id).is_err() || self.entries.contains_key(&id) {
                continue;
            }
            let Ok(contents) = std::fs::read_to_string(&path) else {
                continue;
            };
            if let Ok(Some(entry)) = parse_desktop(&contents, &id) {
                self.entries.insert(id, entry);
            }
        }
    }

    pub fn resolve(&self, id: &str) -> Result<&DesktopEntry, SpaceError> {
        validate_desktop_id(id)?;
        self.entries
            .get(id)
            .ok_or_else(|| SpaceError::DesktopNotFound(id.to_owned()))
    }

    pub fn list(&self) -> Vec<&DesktopEntry> {
        let mut entries = self
            .entries
            .values()
            .filter(|entry| !entry.no_display)
            .collect::<Vec<_>>();
        entries.sort_by(|left, right| {
            left.name
                .to_lowercase()
                .cmp(&right.name.to_lowercase())
                .then_with(|| left.id.cmp(&right.id))
        });
        entries
    }

    pub fn len(&self) -> usize {
        self.entries.len()
    }

    pub fn is_empty(&self) -> bool {
        self.entries.is_empty()
    }
}

pub fn desktop_search_roots() -> Vec<PathBuf> {
    let mut roots = Vec::new();
    if let Some(home) = std::env::var_os("XDG_DATA_HOME")
        .map(PathBuf::from)
        .filter(|path| path.is_absolute())
        .or_else(|| {
            std::env::var_os("HOME")
                .map(PathBuf::from)
                .map(|home| home.join(".local/share"))
        })
    {
        roots.push(home.join("applications"));
        roots.push(home.join("flatpak/exports/share/applications"));
    }

    let data_dirs = std::env::var("XDG_DATA_DIRS")
        .ok()
        .filter(|value| !value.trim().is_empty())
        .map(|value| {
            value
                .split(':')
                .filter(|part| !part.is_empty())
                .map(PathBuf::from)
                .collect::<Vec<_>>()
        })
        .unwrap_or_else(|| {
            vec![
                PathBuf::from("/usr/local/share"),
                PathBuf::from("/usr/share"),
            ]
        });
    for directory in data_dirs {
        roots.push(directory.join("applications"));
        roots.push(directory.join("flatpak/exports/share/applications"));
    }
    roots.push(PathBuf::from("/var/lib/flatpak/exports/share/applications"));
    roots.push(PathBuf::from("/var/lib/snapd/desktop/applications"));

    let mut seen = std::collections::BTreeSet::new();
    roots.retain(|path| path.is_absolute() && seen.insert(path.clone()));
    roots
}

pub fn parse_desktop(contents: &str, id: &str) -> Result<Option<DesktopEntry>, SpaceError> {
    let mut in_group = false;
    let mut seen_group = false;
    let mut name: Option<String> = None;
    let mut exec: Option<String> = None;
    let mut icon: Option<String> = None;
    let mut comment: Option<String> = None;
    let mut entry_type = "Application".to_owned();
    let mut terminal = false;
    let mut hidden = false;
    let mut no_display = false;

    for raw_line in contents.lines() {
        let line = raw_line.trim_end_matches('\r').trim();
        if line.is_empty() || line.starts_with('#') {
            continue;
        }
        if line.starts_with('[') && line.ends_with(']') {
            in_group = line == "[Desktop Entry]";
            seen_group |= in_group;
            continue;
        }
        if !in_group {
            continue;
        }
        let Some((key, value)) = line.split_once('=') else {
            continue;
        };
        let key = key.trim();
        let value = value.trim();
        match key {
            "Name" => name = Some(unescape_value(value)),
            "Exec" => exec = Some(value.to_owned()),
            "Icon" => icon = Some(unescape_value(value)),
            "Comment" => comment = Some(unescape_value(value)),
            "Type" => entry_type = value.to_owned(),
            "Terminal" => terminal = parse_bool(value),
            "Hidden" => hidden = parse_bool(value),
            "NoDisplay" => no_display = parse_bool(value),
            _ => {}
        }
    }

    if !seen_group || hidden || entry_type != "Application" {
        return Ok(None);
    }
    let Some(exec) = exec else {
        return Ok(None);
    };
    let argv = parse_exec(&exec)?;
    let stem = id
        .rsplit('/')
        .next()
        .unwrap_or(id)
        .trim_end_matches(".desktop");
    Ok(Some(DesktopEntry {
        id: id.to_owned(),
        name: name
            .filter(|value| !value.trim().is_empty())
            .unwrap_or_else(|| stem.to_owned()),
        exec: argv,
        icon: icon.filter(|value| !value.is_empty()),
        terminal,
        no_display,
        comment: comment.filter(|value| !value.is_empty()),
    }))
}

pub fn parse_exec(input: &str) -> Result<Vec<String>, SpaceError> {
    let mut tokens = Vec::new();
    let mut current = String::new();
    let mut started = false;
    let mut quoted = false;
    let mut characters = input.chars();

    while let Some(character) = characters.next() {
        match character {
            '"' => {
                quoted = !quoted;
                started = true;
            }
            '\\' => {
                let Some(escaped) = characters.next() else {
                    return Err(SpaceError::Desktop(
                        "Exec ends with a trailing backslash".to_owned(),
                    ));
                };
                current.push(escaped);
                started = true;
            }
            character if character.is_whitespace() && !quoted => {
                if started {
                    tokens.push(std::mem::take(&mut current));
                    started = false;
                }
            }
            character => {
                current.push(character);
                started = true;
            }
        }
    }
    if quoted {
        return Err(SpaceError::Desktop(
            "Exec contains an unterminated quote".to_owned(),
        ));
    }
    if started {
        tokens.push(current);
    }

    let mut argv = Vec::new();
    for token in tokens {
        if let Some(expanded) = expand_field_codes(&token)? {
            argv.push(expanded);
        }
    }
    if argv.is_empty() {
        return Err(SpaceError::Desktop(
            "Exec does not contain a program".to_owned(),
        ));
    }
    if argv[0].is_empty() {
        return Err(SpaceError::Desktop(
            "Exec program must not be empty".to_owned(),
        ));
    }
    Ok(argv)
}

fn expand_field_codes(token: &str) -> Result<Option<String>, SpaceError> {
    let mut output = String::new();
    let mut saw_code = false;
    let mut characters = token.chars();
    while let Some(character) = characters.next() {
        if character != '%' {
            output.push(character);
            continue;
        }
        let Some(code) = characters.next() else {
            return Err(SpaceError::Desktop(
                "Exec contains a trailing '%'; use '%%' for a literal percent".to_owned(),
            ));
        };
        if code == '%' {
            output.push('%');
            continue;
        }
        if matches!(
            code,
            'f' | 'F' | 'u' | 'U' | 'i' | 'c' | 'k' | 'd' | 'D' | 'n' | 'N' | 'v' | 'm'
        ) {
            saw_code = true;
        } else {
            return Err(SpaceError::Desktop(format!(
                "Exec contains unknown field code '%{code}'"
            )));
        }
    }
    if output.is_empty() && saw_code {
        Ok(None)
    } else {
        Ok(Some(output))
    }
}

fn parse_bool(value: &str) -> bool {
    value.eq_ignore_ascii_case("true")
}

fn unescape_value(value: &str) -> String {
    let mut output = String::with_capacity(value.len());
    let mut characters = value.chars();
    while let Some(character) = characters.next() {
        if character != '\\' {
            output.push(character);
            continue;
        }
        match characters.next() {
            Some('s') => output.push(' '),
            Some('n') => output.push('\n'),
            Some('t') => output.push('\t'),
            Some('r') => output.push('\r'),
            Some('\\') => output.push('\\'),
            Some(other) => {
                output.push('\\');
                output.push(other);
            }
            None => output.push('\\'),
        }
    }
    output
}

mod tests {
    use super::*;

    fn parses_a_basic_entry() {
        let contents = "[Desktop Entry]\nType=Application\nName=Code\nExec=code %U\nIcon=code\nNoDisplay=false\n";
        let entry = parse_desktop(contents, "code.desktop")
            .unwrap()
            .expect("entry");
        assert_eq!(entry.name, "Code");
        assert_eq!(entry.exec, vec!["code"]);
        assert_eq!(entry.icon.as_deref(), Some("code"));
        assert!(!entry.no_display);
    }

    fn skips_hidden_and_non_application_entries() {
        for contents in [
            "[Desktop Entry]\nType=Application\nHidden=true\nName=X\nExec=x\n",
            "[Desktop Entry]\nType=Link\nName=X\nURL=https://example.invalid\n",
            "[Desktop Entry]\nName=No exec\n",
        ] {
            assert!(parse_desktop(contents, "x.desktop").unwrap().is_none());
        }
    }

    fn parses_quotes_escapes_and_field_codes() {
        assert_eq!(
            parse_exec(r#"app --name "Hello World" --literal %% --path=/tmp/a\ b %f"#).unwrap(),
            vec![
                "app",
                "--name",
                "Hello World",
                "--literal",
                "%",
                "--path=/tmp/a b"
            ]
        );
    }

    fn rejects_bad_exec_syntax() {
        for bad in [r#"app "unterminated"#, "app trailing\\", "app %z", "app %"] {
            assert!(parse_exec(bad).is_err(), "{bad}");
        }
    }

    fn drops_standalone_field_codes_but_keeps_empty_arguments() {
        assert_eq!(parse_exec("app %U %f").unwrap(), vec!["app"]);
        assert_eq!(parse_exec(r#"app "" --x"#).unwrap(), vec!["app", "", "--x"]);
    }

    fn loads_roots_recursively_with_first_root_precedence() {
        let first = tempfile::tempdir().unwrap();
        let second = tempfile::tempdir().unwrap();
        std::fs::write(
            first.path().join("org.example.App.desktop"),
            "[Desktop Entry]\nType=Application\nName=First\nExec=first %U\n",
        )
        .unwrap();
        std::fs::write(
            second.path().join("org.example.App.desktop"),
            "[Desktop Entry]\nType=Application\nName=Second\nExec=second\n",
        )
        .unwrap();
        std::fs::create_dir_all(second.path().join("nested")).unwrap();
        std::fs::write(
            second.path().join("nested/Other.desktop"),
            "[Desktop Entry]\nType=Application\nName=Other\nExec=other\n",
        )
        .unwrap();
        std::fs::write(
            first.path().join("broken.desktop"),
            "[Desktop Entry]\nType=Application\nName=Broken\nExec=app %z\n",
        )
        .unwrap();

        let index = DesktopIndex::load(&[first.path().to_path_buf(), second.path().to_path_buf()]);
        assert_eq!(index.len(), 2);
        assert_eq!(
            index.resolve("org.example.App.desktop").unwrap().name,
            "First"
        );
        assert_eq!(
            index.resolve("nested/Other.desktop").unwrap().exec,
            vec!["other"]
        );
        assert!(index.resolve("missing.desktop").is_err());
        assert!(index.resolve("../org.example.App.desktop").is_err());
    }

    fn lists_visible_entries_sorted_by_name() {
        let index = DesktopIndex::from_entries([
            DesktopEntry {
                id: "b.desktop".to_owned(),
                name: "Zed".to_owned(),
                exec: vec!["zed".to_owned()],
                icon: None,
                terminal: false,
                no_display: false,
                comment: None,
            },
            DesktopEntry {
                id: "a.desktop".to_owned(),
                name: "alpha".to_owned(),
                exec: vec!["alpha".to_owned()],
                icon: None,
                terminal: false,
                no_display: false,
                comment: None,
            },
            DesktopEntry {
                id: "hidden.desktop".to_owned(),
                name: "Hidden".to_owned(),
                exec: vec!["hidden".to_owned()],
                icon: None,
                terminal: false,
                no_display: true,
                comment: None,
            },
        ]);
        let names = index
            .list()
            .iter()
            .map(|entry| entry.name.as_str())
            .collect::<Vec<_>>();
        assert_eq!(names, vec!["alpha", "Zed"]);
    }
}
