use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::{Command, Output, Stdio};

use serde_json::Value;

struct Env {
    _temp: tempfile::TempDir,
    root: PathBuf,
    project: PathBuf,
}

impl Env {
    fn new() -> Self {
        let temp = tempfile::tempdir().unwrap();
        let root = temp.path().to_path_buf();
        let project = root.join("project");
        std::fs::create_dir_all(&project).unwrap();
        std::fs::create_dir_all(root.join("config")).unwrap();
        std::fs::create_dir_all(root.join("data")).unwrap();
        std::fs::create_dir_all(root.join("run")).unwrap();
        Self {
            _temp: temp,
            root,
            project,
        }
    }

    fn command(&self) -> Command {
        let mut command = Command::new(env!("CARGO_BIN_EXE_klyvera"));
        command
            .current_dir(&self.root)
            .env("XDG_CONFIG_HOME", self.root.join("config"))
            .env("XDG_DATA_HOME", self.root.join("data"))
            .env("XDG_RUNTIME_DIR", self.root.join("run"))
            .env("HOME", &self.root);
        command
    }

    fn run(&self, arguments: &[&str]) -> Output {
        self.command().args(arguments).output().unwrap()
    }

    fn json(&self, arguments: &[&str]) -> Value {
        let output = self.run(arguments);
        assert!(
            output.status.success(),
            "command failed: {}\n{}",
            String::from_utf8_lossy(&output.stdout),
            String::from_utf8_lossy(&output.stderr)
        );
        serde_json::from_slice(&output.stdout).unwrap()
    }
}

fn stderr(output: &Output) -> String {
    String::from_utf8_lossy(&output.stderr).into_owned()
}

#[test]
fn creates_lists_exports_imports_and_backs_up_spaces() {
    let env = Env::new();
    let project = env.project.to_str().unwrap();
    let created = env.json(&["--json", "spaces", "new", "Demo", "--path", project]);
    assert_eq!(created["created"], true);
    assert_eq!(created["id"], "demo");

    let list = env.json(&["--json", "spaces", "list"]);
    assert_eq!(list["spaces"].as_array().unwrap().len(), 1);
    assert_eq!(list["errors"].as_array().unwrap().len(), 0);

    let show = env.json(&["--json", "spaces", "show", "demo"]);
    assert_eq!(show["space"]["name"], "Demo");
    assert_eq!(show["trusted"], false);

    let exported = env.json(&["--json", "spaces", "export", "demo"]);
    assert_eq!(exported["id"], "demo");

    let archive_path = env.root.join("demo-space.json");
    let output = env.run(&[
        "spaces",
        "export",
        "demo",
        "--output",
        archive_path.to_str().unwrap(),
    ]);
    assert!(output.status.success(), "{}", stderr(&output));
    let bytes = std::fs::read(&archive_path).unwrap();
    assert_eq!(
        serde_json::from_slice::<Value>(&bytes).unwrap()["id"],
        "demo"
    );

    let deleted = env.json(&["--json", "spaces", "delete", "demo"]);
    assert_eq!(deleted["deleted"], true);

    let mut child = env
        .command()
        .args(["spaces", "import", "-", "--json"])
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .unwrap();
    child.stdin.as_mut().unwrap().write_all(&bytes).unwrap();
    let output = child.wait_with_output().unwrap();
    assert!(output.status.success(), "{}", stderr(&output));
    let imported: Value = serde_json::from_slice(&output.stdout).unwrap();
    assert_eq!(imported["imported"], true);
    assert_eq!(imported["id"], "demo");

    let backup = env.json(&["--json", "backup"]);
    assert_eq!(backup["files"], 1);
    let archive = backup["path"].as_str().unwrap().to_owned();
    assert!(Path::new(&archive).is_file());

    let backups = env.json(&["--json", "backups"]);
    assert_eq!(backups["backups"].as_array().unwrap().len(), 1);

    let verified = env.json(&["--json", "verify", &archive]);
    assert_eq!(verified["verified"], true);
    assert_eq!(verified["files"], 1);

    let dry = env.json(&["--json", "restore", &archive, "--dry-run"]);
    assert_eq!(dry["dryRun"], true);

    let refused = env.run(&["restore", &archive]);
    assert!(!refused.status.success());
    assert!(stderr(&refused).contains("--yes"));

    let doctor = env.json(&["--json", "doctor"]);
    assert_eq!(doctor["ok"], true, "{doctor}");
}

#[cfg(unix)]
#[test]
fn doctor_creates_private_runtime_directories() {
    use std::os::unix::fs::PermissionsExt;

    let env = Env::new();
    let doctor = env.json(&["--json", "doctor"]);
    assert_eq!(doctor["ok"], true, "{doctor}");

    for directory in ["config/klyvera", "data/klyvera"] {
        let mode = std::fs::metadata(env.root.join(directory))
            .unwrap()
            .permissions()
            .mode()
            & 0o777;
        assert_eq!(mode, 0o700, "{directory}");
    }
}

#[test]
fn commands_require_trust_and_shells_are_rejected() {
    let env = Env::new();
    let project = env.project.to_str().unwrap();
    let command = r#"{"label":"True","argv":["/bin/true"]}"#;
    let created = env.json(&[
        "--json",
        "spaces",
        "new",
        "Task",
        "--path",
        project,
        "--command",
        command,
    ]);
    assert_eq!(created["space"]["commands"].as_array().unwrap().len(), 1);

    let dry = env.json(&["--json", "spaces", "open", "task", "--dry-run"]);
    assert_eq!(dry["dryRun"], true);
    assert_eq!(dry["plan"]["commands"][0]["argv"][0], "/bin/true");

    let refused = env.run(&["spaces", "open", "task"]);
    assert!(!refused.status.success());
    assert!(stderr(&refused).contains("not confirmed"));

    let trusted = env.json(&["--json", "spaces", "trust", "task"]);
    assert_eq!(trusted["trusted"], true);
    assert_eq!(trusted["profileHash"].as_str().unwrap().len(), 64);

    let opened = env.json(&["--json", "spaces", "open", "task"]);
    assert_eq!(opened["startedCommands"], 1);

    let untrusted = env.json(&["--json", "spaces", "untrust", "task"]);
    assert_eq!(untrusted["removed"], 1);
    assert!(!env.run(&["spaces", "open", "task"]).status.success());

    let shell = r#"{"label":"Shell","argv":["/bin/sh","-c","true"]}"#;
    let rejected = env.run(&[
        "spaces",
        "new",
        "Shell",
        "--path",
        project,
        "--command",
        shell,
    ]);
    assert!(!rejected.status.success());
    assert!(stderr(&rejected).contains("shell"));
}
