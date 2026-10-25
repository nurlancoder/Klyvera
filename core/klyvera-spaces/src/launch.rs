use std::path::PathBuf;
use std::process::{Command, Stdio};

use crate::desktop::DesktopIndex;
use crate::error::SpaceError;
use crate::model::{LayoutHints, Space, TerminalCommand};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ProcessKind {
    App,
    Command,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct PlannedProcess {
    pub label: String,
    pub argv: Vec<String>,
    pub cwd: Option<PathBuf>,
    pub kind: ProcessKind,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OpenPlan {
    pub space_id: String,
    pub profile_hash: String,
    pub project_paths: Vec<PathBuf>,
    pub apps: Vec<PlannedProcess>,
    pub commands: Vec<PlannedProcess>,
    pub layout: Option<LayoutHints>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct OpenReport {
    pub started_apps: usize,
    pub started_commands: usize,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum CommandAuthorization {
    None,
    TrustedHash(String),
}

impl OpenPlan {
    pub fn total_processes(&self) -> usize {
        self.apps.len() + self.commands.len()
    }
}

/// Resolve a Space into absolute argv-only processes. No process is started.
pub fn build_plan(space: &Space, index: &DesktopIndex) -> Result<OpenPlan, SpaceError> {
    space.validate()?;
    space.validate_existing_paths()?;

    let mut apps = Vec::with_capacity(space.apps.len());
    for app in &space.apps {
        let entry = index.resolve(&app.desktop_id)?;
        if entry.terminal {
            return Err(SpaceError::Desktop(format!(
                "'{}' requires a terminal and cannot be launched by Klyvera",
                entry.name
            )));
        }
        apps.push(PlannedProcess {
            label: entry.name.clone(),
            argv: entry.exec.clone(),
            cwd: None,
            kind: ProcessKind::App,
        });
    }

    let roots = canonical_roots(space)?;
    let mut commands = Vec::with_capacity(space.commands.len());
    for command in &space.commands {
        commands.push(plan_command(command, &roots)?);
    }

    Ok(OpenPlan {
        space_id: space.id.clone(),
        profile_hash: space.profile_hash()?,
        project_paths: space.project_paths.clone(),
        apps,
        commands,
        layout: space.layout.clone(),
    })
}

fn canonical_roots(space: &Space) -> Result<Vec<PathBuf>, SpaceError> {
    space
        .project_paths
        .iter()
        .map(|path| std::fs::canonicalize(path).map_err(|_| SpaceError::MissingPath(path.clone())))
        .collect()
}

fn plan_command(
    command: &TerminalCommand,
    roots: &[PathBuf],
) -> Result<PlannedProcess, SpaceError> {
    let cwd = match command.cwd_or(roots.first().map(PathBuf::as_path)) {
        Some(path) => {
            let canonical = std::fs::canonicalize(path)
                .map_err(|_| SpaceError::MissingPath(path.to_path_buf()))?;
            let metadata = std::fs::metadata(&canonical)
                .map_err(|_| SpaceError::MissingPath(path.to_path_buf()))?;
            if !metadata.is_dir() {
                return Err(SpaceError::MissingPath(path.to_path_buf()));
            }
            if !roots.iter().any(|root| canonical.starts_with(root)) {
                return Err(SpaceError::Invalid(format!(
                    "command '{}' cwd must be inside one of the Space project paths",
                    command.label
                )));
            }
            Some(canonical)
        }
        None => None,
    };

    Ok(PlannedProcess {
        label: command.label.clone(),
        argv: command.argv.clone(),
        cwd,
        kind: ProcessKind::Command,
    })
}

/// Start the processes in a plan. Commands require an explicit confirmation
/// matching the plan's profile hash; the daemon never infers trust.
pub fn execute(
    plan: &OpenPlan,
    authorization: CommandAuthorization,
) -> Result<OpenReport, SpaceError> {
    if !plan.commands.is_empty() {
        match authorization {
            CommandAuthorization::TrustedHash(hash) if hash == plan.profile_hash => {}
            _ => {
                return Err(SpaceError::Untrusted {
                    profile_hash: plan.profile_hash.clone(),
                });
            }
        }
    }

    let mut report = OpenReport::default();
    for process in &plan.apps {
        spawn(process)?;
        report.started_apps += 1;
    }
    for process in &plan.commands {
        spawn(process)?;
        report.started_commands += 1;
    }
    Ok(report)
}

fn spawn(process: &PlannedProcess) -> Result<(), SpaceError> {
    let program = process
        .argv
        .first()
        .ok_or_else(|| SpaceError::Invalid("process has an empty argv".to_owned()))?;
    let mut command = Command::new(program);
    command
        .args(&process.argv[1..])
        .stdin(Stdio::null())
        .stdout(Stdio::null())
        .stderr(Stdio::null());
    if let Some(cwd) = &process.cwd {
        command.current_dir(cwd);
    }
    command
        .spawn()
        .map(|_| ())
        .map_err(|error| SpaceError::Launch {
            program: program.clone(),
            source: error,
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::desktop::DesktopEntry;
    use crate::model::{AppRef, TerminalCommand};
    use crate::trust::TrustStore;

    fn fixture() -> (tempfile::TempDir, Space, DesktopIndex) {
        let temp = tempfile::tempdir().unwrap();
        let project = temp.path().join("project");
        std::fs::create_dir_all(project.join("sub")).unwrap();
        let mut space = Space::new("Launch", vec![project]).unwrap();
        space.apps = vec![AppRef::new("test.desktop")];
        space.commands = vec![TerminalCommand::new(
            "Test command",
            vec!["/bin/true".to_owned()],
        )];
        let index = DesktopIndex::from_entries([DesktopEntry {
            id: "test.desktop".to_owned(),
            name: "Test App".to_owned(),
            exec: vec!["/bin/true".to_owned()],
            icon: None,
            terminal: false,
            no_display: false,
            comment: None,
        }]);
        (temp, space, index)
    }

    #[test]
    fn builds_an_argv_only_plan() {
        let (_temp, space, index) = fixture();
        let plan = build_plan(&space, &index).unwrap();
        assert_eq!(plan.apps[0].argv, vec!["/bin/true"]);
        assert_eq!(plan.commands[0].kind, ProcessKind::Command);
        assert_eq!(plan.commands[0].cwd, Some(space.project_paths[0].clone()));
        assert_eq!(plan.profile_hash, space.profile_hash().unwrap());
    }

    #[test]
    fn commands_require_a_confirmation_matching_the_profile_hash() {
        let (_temp, space, index) = fixture();
        let plan = build_plan(&space, &index).unwrap();
        assert!(matches!(
            execute(&plan, CommandAuthorization::None),
            Err(SpaceError::Untrusted { .. })
        ));
        assert!(matches!(
            execute(&plan, CommandAuthorization::TrustedHash("0".repeat(64))),
            Err(SpaceError::Untrusted { .. })
        ));
        let report = execute(
            &plan,
            CommandAuthorization::TrustedHash(plan.profile_hash.clone()),
        )
        .unwrap();
        assert_eq!(
            report,
            OpenReport {
                started_apps: 1,
                started_commands: 1
            }
        );
    }

    #[test]
    fn trust_store_matches_plan_hash_after_editing() {
        let (temp, mut space, index) = fixture();
        let mut trust = TrustStore::open(temp.path().join("trust.json")).unwrap();
        trust.trust(&space).unwrap();
        assert!(trust.is_trusted(&space).unwrap());

        space.commands[0].argv.push("--new".to_owned());
        let plan = build_plan(&space, &index).unwrap();
        assert!(!trust.is_trusted(&space).unwrap());
        assert!(execute(
            &plan,
            CommandAuthorization::TrustedHash(plan.profile_hash.clone())
        )
        .is_ok());
    }

    #[test]
    fn missing_projects_outside_cwds_and_terminal_apps_are_rejected() {
        let (temp, mut space, mut index) = fixture();
        space.commands[0].cwd = Some(temp.path().to_path_buf());
        assert!(matches!(
            build_plan(&space, &index),
            Err(SpaceError::Invalid(_))
        ));
        space.commands[0].cwd = Some(space.project_paths[0].join("sub"));
        assert!(build_plan(&space, &index).is_ok());

        space.project_paths = vec![temp.path().join("missing")];
        assert!(matches!(
            build_plan(&space, &index),
            Err(SpaceError::MissingPath(_))
        ));

        let (_temp2, space2, _) = fixture();
        index = DesktopIndex::from_entries([DesktopEntry {
            id: "test.desktop".to_owned(),
            name: "Terminal App".to_owned(),
            exec: vec!["/bin/true".to_owned()],
            icon: None,
            terminal: true,
            no_display: false,
            comment: None,
        }]);
        assert!(matches!(
            build_plan(&space2, &index),
            Err(SpaceError::Desktop(_))
        ));
    }
}
