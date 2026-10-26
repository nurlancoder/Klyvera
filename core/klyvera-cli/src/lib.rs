
mod error;

use std::fs;
use std::io::{Read, Write};
use std::path::{Path, PathBuf};
use std::process::ExitCode;

use clap::{Args, Parser, Subcommand};
use klyvera_backup::{create_backup, list_backups, restore_backup, verify_backup};
use klyvera_config::Paths;
use klyvera_ipc::{Client, Command, Request};
use klyvera_spaces::{
    build_plan, execute, CommandAuthorization, DesktopIndex, OpenPlan, Space, SpaceAccent,
    SpaceStore, TerminalCommand, TrustStore, MAX_SPACE_BYTES,
};
use serde::Serialize;
use serde_json::{json, Value};

pub use error::CliError;

pub struct Cli {
    pub json: bool,

    pub dry_run: bool,

    pub command: Commands,
}

pub enum Commands {
    Spaces {
        command: SpacesCommand,
    },
    Backup,
    Backups,
    Verify {
        archive: PathBuf,
    },
    Restore {
        archive: PathBuf,
        yes: bool,
    },
    Status,
    Doctor,
}

pub enum SpacesCommand {
    List,
    New(NewArgs),
    Show {
        id: String,
    },
    Open {
        id: String,
    },
    Delete {
        id: String,
    },
    Export {
        id: String,
        output: Option<PathBuf>,
    },
    Import {
        source: String,
    },
    Trust {
        id: String,
    },
    Untrust {
        id: String,
    },
}

pub struct NewArgs {
    pub name: String,

    pub paths: Vec<PathBuf>,

    pub id: Option<String>,

    pub description: Option<String>,

    pub icon: Option<String>,

    pub accent: Option<String>,

    pub apps: Vec<String>,

    pub commands: Vec<String>,
}

pub fn run(cli: Cli) -> Result<ExitCode, CliError> {
    match &cli.command {
        Commands::Spaces { command } => run_spaces(&cli, command),
        Commands::Backup => run_backup(&cli),
        Commands::Backups => run_backups(&cli),
        Commands::Verify { archive } => run_verify(&cli, archive),
        Commands::Restore { archive, yes } => run_restore(&cli, archive, *yes),
        Commands::Status => run_status(&cli),
        Commands::Doctor => run_doctor(&cli),
    }
}

fn run_spaces(cli: &Cli, command: &SpacesCommand) -> Result<ExitCode, CliError> {
    match command {
        SpacesCommand::List => spaces_list(cli),
        SpacesCommand::New(arguments) => spaces_new(cli, arguments),
        SpacesCommand::Show { id } => spaces_show(cli, id),
        SpacesCommand::Open { id } => spaces_open(cli, id),
        SpacesCommand::Delete { id } => spaces_delete(cli, id),
        SpacesCommand::Export { id, output } => spaces_export(cli, id, output.as_deref()),
        SpacesCommand::Import { source } => spaces_import(cli, source),
        SpacesCommand::Trust { id } => spaces_trust(cli, id),
        SpacesCommand::Untrust { id } => spaces_untrust(cli, id),
    }
}

fn spaces_list(cli: &Cli) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    let report = store.list();
    if cli.json {
        let spaces = report.spaces.iter().map(space_summary).collect::<Vec<_>>();
        let errors = report
            .errors
            .iter()
            .map(|error| json!({"file": error.file, "message": error.message}))
            .collect::<Vec<_>>();
        emit_json(&json!({"spaces": spaces, "errors": errors}))?;
    } else if report.spaces.is_empty() {
        write_text("No Spaces yet. Create one with: klyvera spaces new\n")?;
    } else {
        for space in &report.spaces {
            write_text(&format!(
                "{}\t{}\t{} apps / {} commands\n",
                space.id,
                space.name,
                space.apps.len(),
                space.commands.len()
            ))?;
        }
    }
    if !cli.json {
        for error in &report.errors {
            eprintln!("warning: {}: {}", error.file, error.message);
        }
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_new(cli: &Cli, arguments: &NewArgs) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let project_paths = arguments
        .paths
        .iter()
        .map(|path| {
            fs::canonicalize(path)
                .map_err(|_| klyvera_spaces::SpaceError::MissingPath(path.clone()))
        })
        .collect::<Result<Vec<_>, _>>()?;

    let mut space = match &arguments.id {
        Some(id) => Space::with_id(id, &arguments.name, project_paths)?,
        None => Space::new(&arguments.name, project_paths)?,
    };
    space.description = arguments.description.clone();
    space.icon = arguments.icon.clone();
    space.accent = match &arguments.accent {
        Some(accent) => SpaceAccent::parse(accent)?,
        None => SpaceAccent::Purple,
    };
    space.apps = arguments
        .apps
        .iter()
        .map(|id| klyvera_spaces::AppRef::new(id.clone()))
        .collect();
    space.commands = arguments
        .commands
        .iter()
        .map(|command| {
            serde_json::from_str::<TerminalCommand>(command)
                .map_err(|error| CliError::Usage(format!("invalid --command JSON: {error}")))
        })
        .collect::<Result<Vec<_>, _>>()?;
    space.validate()?;

    if cli.dry_run {
        if cli.json {
            emit_json(&json!({"dryRun": true, "space": space_value(&space)?}))?;
        } else {
            write_text(&format!(
                "Would create Space '{}' ({}) at {}\n",
                space.name,
                space.id,
                space.path_display()
            ))?;
        }
        return Ok(ExitCode::SUCCESS);
    }

    paths.ensure_layout()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    let created = store.create_new(space)?;
    if cli.json {
        emit_json(&json!({
            "created": true,
            "id": created.id,
            "space": space_value(&created)?,
            "profileHash": created.profile_hash()?,
        }))?;
    } else {
        write_text(&format!(
            "Created Space '{}' ({})\n",
            created.name, created.id
        ))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_show(cli: &Cli, id: &str) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    let space = store.get(id)?;
    let trust = TrustStore::open(paths.trust_file())?;
    let trusted = trust.is_trusted(&space)?;
    if cli.json {
        emit_json(&json!({
            "space": space_value(&space)?,
            "profileHash": space.profile_hash()?,
            "trusted": trusted,
        }))?;
    } else {
        write_text(&format!("{}\n{}\n", space.name, space.id))?;
        if let Some(description) = &space.description {
            write_text(&format!("{description}\n"))?;
        }
        write_text(&format!("Paths: {}\n", space.path_display()))?;
        write_text(&format!(
            "Apps: {}  Commands: {}\n",
            space.apps.len(),
            space.commands.len()
        ))?;
        write_text(&format!(
            "Profile: {}\nTrusted: {}\n",
            space.profile_hash()?,
            if trusted { "yes" } else { "no" }
        ))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_open(cli: &Cli, id: &str) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    let space = store.get(id)?;
    let trust = TrustStore::open(paths.trust_file())?;
    let index = DesktopIndex::load_default();
    let plan = build_plan(&space, &index)?;

    if cli.dry_run {
        if cli.json {
            emit_json(&json!({"dryRun": true, "plan": plan_value(&plan)}))?;
        } else {
            print_plan(&plan)?;
        }
        return Ok(ExitCode::SUCCESS);
    }

    let trusted = trust.is_trusted(&space)?;
    if !plan.commands.is_empty() && !trusted {
        return Err(CliError::Message(format!(
            "commands for '{}' are not confirmed; run: klyvera spaces trust {}",
            space.id, space.id
        )));
    }
    let authorization = if plan.commands.is_empty() {
        CommandAuthorization::None
    } else {
        CommandAuthorization::TrustedHash(plan.profile_hash.clone())
    };
    let report = execute(&plan, authorization)?;
    if cli.json {
        emit_json(&json!({
            "dryRun": false,
            "spaceId": space.id,
            "startedApps": report.started_apps,
            "startedCommands": report.started_commands,
        }))?;
    } else {
        write_text(&format!(
            "Opened '{}': {} apps, {} commands\n",
            space.name, report.started_apps, report.started_commands
        ))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_delete(cli: &Cli, id: &str) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    if cli.dry_run {
        let space = store.get(id)?;
        if cli.json {
            emit_json(&json!({"dryRun": true, "id": space.id}))?;
        } else {
            write_text(&format!("Would move '{}' to trash\n", space.id))?;
        }
        return Ok(ExitCode::SUCCESS);
    }
    let trashed = store.delete(id)?;
    if cli.json {
        emit_json(&json!({"deleted": true, "id": id, "trash": trashed.display().to_string()}))?;
    } else {
        write_text(&format!("Moved '{}' to {}\n", id, trashed.display()))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_export(cli: &Cli, id: &str, output: Option<&Path>) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    let bytes = store.export_json(id)?;
    match output {
        Some(path) => {
            klyvera_config::write_bytes_atomic(path, &bytes)?;
            if cli.json {
                emit_json(
                    &json!({"exported": true, "id": id, "output": path.display().to_string()}),
                )?;
            } else {
                write_text(&format!("Exported '{}' to {}\n", id, path.display()))?;
            }
        }
        None => write_stdout(&bytes)?,
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_import(cli: &Cli, source: &str) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let bytes = read_import(source)?;
    let space = SpaceStore::parse_import(&bytes)?;
    if cli.dry_run {
        if cli.json {
            emit_json(&json!({"dryRun": true, "space": space_value(&space)?}))?;
        } else {
            write_text(&format!(
                "Would import '{}' ({}) with {} path(s)\n",
                space.name,
                space.id,
                space.project_paths.len()
            ))?;
        }
        return Ok(ExitCode::SUCCESS);
    }
    paths.ensure_layout()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    let imported = store.save_imported(space)?;
    if cli.json {
        emit_json(&json!({"imported": true, "id": imported.id, "name": imported.name}))?;
    } else {
        write_text(&format!("Imported '{}' ({})\n", imported.name, imported.id))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_trust(cli: &Cli, id: &str) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let store = SpaceStore::open(paths.spaces_dir())?;
    let space = store.get(id)?;
    let mut trust = TrustStore::open(paths.trust_file())?;
    let hash = trust.trust(&space)?;
    if cli.json {
        emit_json(&json!({"trusted": true, "id": space.id, "profileHash": hash}))?;
    } else {
        write_text(&format!(
            "Trusted '{}' for profile {}\n",
            space.id,
            short_hash(&hash)
        ))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn spaces_untrust(cli: &Cli, id: &str) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let mut trust = TrustStore::open(paths.trust_file())?;
    let removed = trust.revoke(id)?;
    if cli.json {
        emit_json(&json!({"trusted": false, "id": id, "removed": removed}))?;
    } else {
        write_text(&format!("Revoked {removed} confirmation(s) for '{id}'\n"))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn run_backup(cli: &Cli) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    paths.ensure_layout()?;
    let summary = create_backup(
        &paths.backups_dir(),
        &paths.config_file(),
        &paths.spaces_dir(),
    )?;
    if cli.json {
        emit_json(&json!({
            "id": summary.id,
            "path": summary.path.display().to_string(),
            "createdAt": summary.created_at,
            "files": summary.files,
            "size": summary.size,
            "sha256": summary.sha256,
        }))?;
    } else {
        write_text(&format!(
            "Created backup {} ({} files, {} bytes)\n",
            summary.id, summary.files, summary.size
        ))?;
        write_text(&format!("SHA-256: {}\n", summary.sha256))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn run_backups(cli: &Cli) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let backups = list_backups(&paths.backups_dir())?;
    if cli.json {
        let list = backups
            .iter()
            .map(|backup| {
                json!({
                    "id": backup.id,
                    "path": backup.path.display().to_string(),
                    "size": backup.size,
                    "modifiedAt": backup.modified_at,
                })
            })
            .collect::<Vec<_>>();
        emit_json(&json!({"backups": list}))?;
    } else if backups.is_empty() {
        write_text("No backups yet. Create one with: klyvera backup\n")?;
    } else {
        for backup in &backups {
            write_text(&format!(
                "{}\t{}\t{}\n",
                backup.id,
                backup.size,
                backup.path.display()
            ))?;
        }
    }
    Ok(ExitCode::SUCCESS)
}

fn run_verify(cli: &Cli, archive: &Path) -> Result<ExitCode, CliError> {
    let report = verify_backup(archive)?;
    if cli.json {
        emit_json(&json!({
            "verified": true,
            "files": report.verified_files,
            "manifest": report.manifest,
        }))?;
    } else {
        write_text(&format!(
            "Verified {} ({} files, created {})\n",
            archive.display(),
            report.verified_files,
            report.manifest.created_at
        ))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn run_restore(cli: &Cli, archive: &Path, yes: bool) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    if cli.dry_run {
        let report = verify_backup(archive)?;
        if cli.json {
            emit_json(
                &json!({"dryRun": true, "files": report.verified_files, "manifest": report.manifest}),
            )?;
        } else {
            write_text(&format!(
                "Would restore {} files from {}\n",
                report.verified_files,
                archive.display()
            ))?;
        }
        return Ok(ExitCode::SUCCESS);
    }
    if !yes {
        return Err(CliError::Usage(
            "restore replaces live data; pass --yes after reviewing --dry-run".to_owned(),
        ));
    }
    let report = restore_backup(
        archive,
        &paths.backups_dir(),
        &paths.config_file(),
        &paths.spaces_dir(),
    )?;
    if cli.json {
        emit_json(&json!({
            "restored": true,
            "preRestoreBackup": report.pre_restore_backup.id,
            "restoredConfig": report.restored_config,
            "restoredSpaces": report.restored_spaces,
            "displacedSpaces": report.displaced_spaces,
        }))?;
    } else {
        write_text(&format!(
            "Restored config: {}  Spaces: {}  displaced: {}\n",
            if report.restored_config { "yes" } else { "no" },
            report.restored_spaces,
            report.displaced_spaces
        ))?;
        write_text(&format!(
            "Pre-restore backup: {}\n",
            report.pre_restore_backup.id
        ))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn run_status(cli: &Cli) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let (running, daemon, daemon_error) = daemon_status(&paths);
    let config = klyvera_config::load_or_default(&paths.config_file());
    let config_ok = config.is_ok();
    let store = SpaceStore::open(paths.spaces_dir())?;
    let report = store.list();

    if cli.json {
        emit_json(&json!({
            "daemonRunning": running,
            "daemon": daemon,
            "daemonError": daemon_error,
            "configOk": config_ok,
            "spaces": report.spaces.len(),
            "spaceErrors": report.errors.len(),
        }))?;
    } else {
        write_text(&format!(
            "Daemon: {}\n",
            if running { "running" } else { "not running" }
        ))?;
        if let Some(error) = &daemon_error {
            write_text(&format!("Daemon detail: {error}\n"))?;
        }
        write_text(&format!(
            "Config: {}\nSpaces: {} ({} unreadable)\n",
            if config_ok { "ok" } else { "invalid" },
            report.spaces.len(),
            report.errors.len()
        ))?;
    }
    Ok(ExitCode::SUCCESS)
}

fn daemon_status(paths: &Paths) -> (bool, Option<Value>, Option<String>) {
    let socket = match paths.socket_path() {
        Ok(socket) => socket,
        Err(error) => return (false, None, Some(error.to_string())),
    };
    match Client::connect(&socket) {
        Ok(mut client) => match client.call(&Request::new(Command::Status)) {
            Ok(response) if response.ok => (true, response.data, None),
            Ok(response) => (
                true,
                None,
                Some(
                    response
                        .error
                        .map(|error| error.message)
                        .unwrap_or_else(|| "daemon returned an error".to_owned()),
                ),
            ),
            Err(error) => (false, None, Some(error.to_string())),
        },
        Err(error) => (false, None, Some(error.to_string())),
    }
}

struct Check {
    name: &'static str,
    status: &'static str,
    detail: String,
}

impl Check {
    fn ok(name: &'static str, detail: impl Into<String>) -> Self {
        Self {
            name,
            status: "ok",
            detail: detail.into(),
        }
    }

    fn warn(name: &'static str, detail: impl Into<String>) -> Self {
        Self {
            name,
            status: "warn",
            detail: detail.into(),
        }
    }

    fn fail(name: &'static str, detail: impl Into<String>) -> Self {
        Self {
            name,
            status: "fail",
            detail: detail.into(),
        }
    }
}

fn run_doctor(cli: &Cli) -> Result<ExitCode, CliError> {
    let paths = paths()?;
    let mut checks = Vec::new();

    let config_path = paths.config_file();
    match klyvera_config::load(&config_path) {
        Ok(config) => checks.push(Check::ok(
            "config",
            format!(
                "{:?} theme, scale {}",
                config.appearance.theme, config.appearance.scale
            ),
        )),
        Err(error) if error.is_not_found() => checks.push(Check::warn(
            "config",
            "using defaults; config.json has not been written yet",
        )),
        Err(error) => checks.push(Check::fail("config", error.to_string())),
    }

    match SpaceStore::open(paths.spaces_dir()) {
        Ok(store) => {
            let report = store.list();
            if report.errors.is_empty() {
                checks.push(Check::ok(
                    "spaces",
                    format!("{} readable Space(s)", report.spaces.len()),
                ));
            } else {
                checks.push(Check::warn(
                    "spaces",
                    format!(
                        "{} readable, {} unreadable",
                        report.spaces.len(),
                        report.errors.len()
                    ),
                ));
            }
        }
        Err(error) => checks.push(Check::fail("spaces", error.to_string())),
    }

    match TrustStore::open(paths.trust_file()) {
        Ok(trust) => checks.push(Check::ok(
            "trust",
            format!("{} confirmation(s)", trust.entry_count()),
        )),
        Err(error) => checks.push(Check::fail("trust", error.to_string())),
    }

    checks.push(permissions_check(&paths));

    let desktop_count = DesktopIndex::load_default().len();
    if desktop_count == 0 {
        checks.push(Check::warn(
            "desktop",
            "no desktop entries found; Spaces cannot launch apps",
        ));
    } else {
        checks.push(Check::ok(
            "desktop",
            format!("{desktop_count} desktop entries"),
        ));
    }

    let (running, _, daemon_error) = daemon_status(&paths);
    if running {
        checks.push(Check::ok("daemon", "responding on the private socket"));
    } else {
        checks.push(Check::warn(
            "daemon",
            daemon_error.unwrap_or_else(|| "not running".to_owned()),
        ));
    }

    match list_backups(&paths.backups_dir()) {
        Ok(backups) => checks.push(Check::ok("backups", format!("{} backup(s)", backups.len()))),
        Err(error) => checks.push(Check::fail("backups", error.to_string())),
    }

    if !cfg!(target_os = "linux") {
        checks.push(Check::warn("target", "Klyvera targets Linux"));
    }
    if !cfg!(target_arch = "x86_64") && !cfg!(target_arch = "aarch64") {
        checks.push(Check::warn("target", "untested architecture"));
    }

    if cfg!(target_os = "linux") {
        checks.push(Check::warn(
            "hyprland",
            "not checked here; Hyprland layout hints are UNVERIFIED-ON-TARGET",
        ));
    }

    let failed = checks.iter().any(|check| check.status == "fail");
    if cli.json {
        emit_json(&json!({"ok": !failed, "checks": checks}))?;
    } else {
        for check in &checks {
            write_text(&format!(
                "[{}] {}: {}\n",
                check.status, check.name, check.detail
            ))?;
        }
    }
    Ok(if failed {
        ExitCode::FAILURE
    } else {
        ExitCode::SUCCESS
    })
}

fn permissions_check(paths: &Paths) -> Check {
    use std::os::unix::fs::PermissionsExt;

    let mut problems = Vec::new();
    let mut missing = 0;
    for directory in [
        paths.config_dir(),
        paths.data_dir(),
        &paths.spaces_dir(),
        &paths.backups_dir(),
    ] {
        match fs::metadata(directory) {
            Ok(metadata) => {
                let mode = metadata.permissions().mode() & 0o777;
                if mode != 0o700 {
                    problems.push(format!("{} is {:o}", directory.display(), mode));
                }
            }
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => missing += 1,
            Err(error) => problems.push(format!("{}: {error}", directory.display())),
        }
    }
    if !problems.is_empty() {
        Check::fail("permissions", problems.join("; "))
    } else if missing > 0 {
        Check::warn(
            "permissions",
            format!("{missing} runtime directorie(s) not created yet"),
        )
    } else {
        Check::ok("permissions", "runtime directories are 0700")
    }
}

fn permissions_check(_paths: &Paths) -> Check {
    Check::ok("permissions", "not applicable on this platform")
}

fn space_summary(space: &Space) -> Value {
    json!({
        "id": space.id,
        "name": space.name,
        "description": space.description,
        "icon": space.icon,
        "accent": space.accent.as_str(),
        "projectPaths": space.project_paths.iter().map(|path| path.display().to_string()).collect::<Vec<_>>(),
        "appCount": space.apps.len(),
        "commandCount": space.commands.len(),
        "profileHash": space.profile_hash().ok(),
        "updatedAt": space.updated_at,
    })
}

fn space_value(space: &Space) -> Result<Value, CliError> {
    serde_json::to_value(space).map_err(|error| CliError::Message(error.to_string()))
}

fn plan_value(plan: &OpenPlan) -> Value {
    json!({
        "spaceId": plan.space_id,
        "profileHash": plan.profile_hash,
        "projectPaths": plan.project_paths.iter().map(|path| path.display().to_string()).collect::<Vec<_>>(),
        "apps": plan.apps.iter().map(|process| json!({"label": process.label, "argv": process.argv})).collect::<Vec<_>>(),
        "commands": plan.commands.iter().map(|process| json!({
            "label": process.label,
            "argv": process.argv,
            "cwd": process.cwd.as_ref().map(|path| path.display().to_string()),
        })).collect::<Vec<_>>(),
        "layout": plan.layout,
    })
}

fn print_plan(plan: &OpenPlan) -> Result<(), CliError> {
    write_text(&format!("Space: {}\n", plan.space_id))?;
    for path in &plan.project_paths {
        write_text(&format!("Path: {}\n", path.display()))?;
    }
    for app in &plan.apps {
        write_text(&format!("App: {} ({})\n", app.label, app.argv.join(" ")))?;
    }
    for command in &plan.commands {
        write_text(&format!(
            "Command: {} ({}) cwd={}\n",
            command.label,
            command.argv.join(" "),
            command
                .cwd
                .as_ref()
                .map(|path| path.display().to_string())
                .unwrap_or_else(|| "-".to_owned())
        ))?;
    }
    if let Some(layout) = &plan.layout {
        write_text(&format!(
            "Layout: monitor={} workspace={}\n",
            layout.monitor.as_deref().unwrap_or("-"),
            layout
                .workspace
                .map(|workspace| workspace.to_string())
                .unwrap_or_else(|| "-".to_owned())
        ))?;
    }
    Ok(())
}

fn read_import(source: &str) -> Result<Vec<u8>, CliError> {
    if source == "-" {
        let mut bytes = Vec::new();
        std::io::stdin()
            .take(MAX_SPACE_BYTES as u64 + 1)
            .read_to_end(&mut bytes)
            .map_err(|error| CliError::io("<stdin>", error))?;
        if bytes.len() > MAX_SPACE_BYTES {
            return Err(CliError::Message(format!(
                "input exceeds {MAX_SPACE_BYTES} bytes"
            )));
        }
        Ok(bytes)
    } else {
        let path = PathBuf::from(source);
        let metadata = fs::metadata(&path).map_err(|error| CliError::io(&path, error))?;
        if metadata.len() > MAX_SPACE_BYTES as u64 {
            return Err(CliError::Message(format!(
                "{} exceeds {MAX_SPACE_BYTES} bytes",
                path.display()
            )));
        }
        fs::read(&path).map_err(|error| CliError::io(&path, error))
    }
}

fn paths() -> Result<Paths, CliError> {
    let paths = Paths::from_env().map_err(CliError::Config)?;
    paths.ensure_layout().map_err(CliError::Config)?;
    Ok(paths)
}

fn short_hash(hash: &str) -> &str {
    hash.get(..12).unwrap_or(hash)
}

fn emit_json<T: Serialize>(value: &T) -> Result<(), CliError> {
    let text = serde_json::to_string_pretty(value)
        .map_err(|error| CliError::Message(error.to_string()))?;
    write_text(&format!("{text}\n"))
}

fn write_text(text: &str) -> Result<(), CliError> {
    let mut stdout = std::io::stdout().lock();
    stdout
        .write_all(text.as_bytes())
        .and_then(|()| stdout.flush())
        .map_err(|error| CliError::io("<stdout>", error))
}

fn write_stdout(bytes: &[u8]) -> Result<(), CliError> {
    let mut stdout = std::io::stdout().lock();
    stdout
        .write_all(bytes)
        .and_then(|()| stdout.flush())
        .map_err(|error| CliError::io("<stdout>", error))
}
