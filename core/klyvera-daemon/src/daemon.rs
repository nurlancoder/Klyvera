use std::io::BufReader;
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::time::{Duration, Instant};

use klyvera_config::Paths;
use klyvera_ipc::{
    bind_listener, codes, read_frame, remove_socket, verify_peer, write_frame, Command, Request,
    Response, PROTOCOL_VERSION,
};
use klyvera_spaces::{
    build_plan, execute, CommandAuthorization, DesktopIndex, Space, SpaceError, SpaceStore,
    TrustStore,
};
use serde_json::{json, Value};

use crate::error::DaemonError;

const ACCEPT_POLL: Duration = Duration::from_millis(50);
const CLIENT_TIMEOUT: Duration = Duration::from_secs(5);
const MAX_REQUESTS_PER_CONNECTION: usize = 64;

#[derive(Debug, Clone)]
pub struct DaemonConfig {
    pub paths: Paths,
    pub socket: PathBuf,
    pub verbose: bool,
}

struct State {
    paths: Paths,
    trust: TrustStore,
    started: Instant,
    verbose: bool,
}

enum HandlerError {
    Space(SpaceError),
    Internal(String),
}

impl From<SpaceError> for HandlerError {
    fn from(error: SpaceError) -> Self {
        Self::Space(error)
    }
}

pub fn run(config: DaemonConfig) -> Result<(), DaemonError> {
    crate::signal::reset();
    crate::signal::install().map_err(DaemonError::Signal)?;
    config.paths.ensure_layout()?;
    let trust = TrustStore::open(config.paths.trust_file())?;
    let listener = bind_listener(&config.socket)?;
    let _guard = SocketGuard(config.socket.clone());

    listener
        .set_nonblocking(true)
        .map_err(|error| DaemonError::io(&config.socket, error))?;

    let mut state = State {
        paths: config.paths,
        trust,
        started: Instant::now(),
        verbose: config.verbose,
    };
    log(true, "event=daemon-ready");

    loop {
        if crate::signal::requested() {
            break;
        }
        match listener.accept() {
            Ok((stream, _)) => {
                if handle_connection(&mut state, stream) {
                    break;
                }
            }
            Err(error) if error.kind() == std::io::ErrorKind::WouldBlock => {
                std::thread::sleep(ACCEPT_POLL);
            }
            Err(error) if error.kind() == std::io::ErrorKind::Interrupted => {}
            Err(error) => return Err(DaemonError::io("daemon.sock", error)),
        }
    }
    log(true, "event=daemon-stop");
    Ok(())
}

fn handle_connection(state: &mut State, stream: UnixStream) -> bool {
    if verify_peer(&stream).is_err() {
        return false;
    }
    if stream.set_nonblocking(false).is_err() {
        return false;
    }
    let _ = stream.set_read_timeout(Some(CLIENT_TIMEOUT));
    let _ = stream.set_write_timeout(Some(CLIENT_TIMEOUT));

    let mut reader = BufReader::new(&stream);
    let mut writer = &stream;

    for _ in 0..MAX_REQUESTS_PER_CONNECTION {
        let frame = match read_frame(&mut reader) {
            Ok(Some(frame)) => frame,
            Ok(None) => return false,
            Err(_) => {
                log(state.verbose, "event=connection-error");
                return false;
            }
        };
        let request = match Request::parse(&frame) {
            Ok(request) => request,
            Err(error) => {
                let code = match error {
                    klyvera_ipc::IpcError::UnsupportedVersion(_) => codes::UNSUPPORTED_VERSION,
                    _ => codes::PROTOCOL,
                };
                let response = Response::error("protocol-error", code, error.to_string());
                let _ = write_response(&mut writer, &response);
                log(state.verbose, "event=protocol-error");
                return false;
            }
        };

        let (response, stop) = handle_request(state, &request);
        if write_response(&mut writer, &response).is_err() {
            log(state.verbose, "event=write-error");
            return false;
        }
        log(
            state.verbose,
            &format!(
                "event=request command={} ok={}",
                request.command.as_str(),
                response.ok
            ),
        );
        if stop {
            return true;
        }
    }
    false
}

fn write_response(
    writer: &mut &UnixStream,
    response: &Response,
) -> Result<(), klyvera_ipc::IpcError> {
    let bytes = response.encode()?;
    write_frame(writer, &bytes)
}

fn handle_request(state: &mut State, request: &Request) -> (Response, bool) {
    let result = dispatch(state, request);
    match result {
        Ok((data, stop)) => (Response::ok(request.request_id.clone(), Some(data)), stop),
        Err(HandlerError::Space(error)) => (
            Response::error(
                request.request_id.clone(),
                space_error_code(&error),
                error.to_string(),
            ),
            false,
        ),
        Err(HandlerError::Internal(message)) => (
            Response::error(request.request_id.clone(), codes::INTERNAL, message),
            false,
        ),
    }
}

fn dispatch(state: &mut State, request: &Request) -> Result<(Value, bool), HandlerError> {
    match request.command {
        Command::Ping => Ok((
            json!({"pong": true, "protocolVersion": PROTOCOL_VERSION}),
            false,
        )),
        Command::Stop => Ok((json!({"stopping": true}), true)),
        Command::Status => Ok((state.status_data()?, false)),
        Command::SpacesList => Ok((spaces_list_data(state)?, false)),
        Command::SpaceShow => {
            let space = state.space_store()?.get(request.space_id())?;
            let hash = space.profile_hash()?;
            let trusted = state.trust.is_trusted(&space)?;
            let value = serde_json::to_value(&space)
                .map_err(|error| HandlerError::Internal(error.to_string()))?;
            Ok((
                json!({"space": value, "profileHash": hash, "trusted": trusted}),
                false,
            ))
        }
        Command::SpaceOpen => {
            let space = state.space_store()?.get(request.space_id())?;
            let index = DesktopIndex::load_default();
            let plan = build_plan(&space, &index)?;
            let trusted = state.trust.is_trusted(&space)?;
            if !plan.commands.is_empty() && !trusted {
                return Err(SpaceError::Untrusted {
                    profile_hash: plan.profile_hash.clone(),
                }
                .into());
            }
            let authorization = if plan.commands.is_empty() {
                CommandAuthorization::None
            } else {
                CommandAuthorization::TrustedHash(plan.profile_hash.clone())
            };
            let report = execute(&plan, authorization)?;
            let layout = serde_json::to_value(&plan.layout)
                .map_err(|error| HandlerError::Internal(error.to_string()))?;
            Ok((
                json!({
                    "startedApps": report.started_apps,
                    "startedCommands": report.started_commands,
                    "layout": layout,
                }),
                false,
            ))
        }
    }
}

impl State {
    fn space_store(&self) -> Result<SpaceStore, HandlerError> {
        SpaceStore::open(self.paths.spaces_dir()).map_err(HandlerError::Space)
    }

    fn status_data(&self) -> Result<Value, HandlerError> {
        let report = self.space_store()?.list();
        let config = klyvera_config::load_or_default(&self.paths.config_file());
        let (config_ok, theme) = match config {
            Ok(config) => (
                true,
                serde_json::to_value(config.appearance.theme).unwrap_or(Value::Null),
            ),
            Err(_) => (false, Value::Null),
        };
        Ok(json!({
            "version": env!("CARGO_PKG_VERSION"),
            "protocolVersion": PROTOCOL_VERSION,
            "pid": std::process::id(),
            "uptimeSeconds": self.started.elapsed().as_secs(),
            "spaces": report.spaces.len(),
            "spaceErrors": report.errors.len(),
            "configOk": config_ok,
            "theme": theme,
        }))
    }
}

fn spaces_list_data(state: &State) -> Result<Value, HandlerError> {
    let report = state.space_store()?.list();
    let mut spaces = Vec::with_capacity(report.spaces.len());
    for space in &report.spaces {
        spaces.push(space_summary(space));
    }
    let errors = report
        .errors
        .iter()
        .map(|error| json!({"file": error.file, "message": error.message}))
        .collect::<Vec<_>>();
    Ok(json!({"spaces": spaces, "errors": errors}))
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

fn space_error_code(error: &SpaceError) -> &'static str {
    match error {
        SpaceError::NotFound(_) => codes::NOT_FOUND,
        SpaceError::Untrusted { .. } => codes::UNTRUSTED,
        SpaceError::DesktopNotFound(_)
        | SpaceError::Desktop(_)
        | SpaceError::MissingPath(_)
        | SpaceError::DuplicatePath(_)
        | SpaceError::Invalid(_)
        | SpaceError::UnsafePath(_) => codes::INVALID_SPACE,
        SpaceError::Io { .. }
        | SpaceError::Json { .. }
        | SpaceError::Launch { .. }
        | SpaceError::TooLarge { .. }
        | SpaceError::Exists(_)
        | SpaceError::Config(_) => codes::INTERNAL,
    }
}

fn log(enabled: bool, message: &str) {
    if enabled {
        eprintln!("{message}");
    }
}

trait RequestSpaceId {
    fn space_id(&self) -> &str;
}

impl RequestSpaceId for Request {
    fn space_id(&self) -> &str {
        self.space_id.as_deref().unwrap_or_default()
    }
}

struct SocketGuard(PathBuf);

impl Drop for SocketGuard {
    fn drop(&mut self) {
        remove_socket(&self.0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use klyvera_spaces::{Space, TerminalCommand};
    use std::time::Duration;

    fn wait_for_socket(path: &PathBuf) -> klyvera_ipc::Client {
        let deadline = Instant::now() + Duration::from_secs(5);
        loop {
            match klyvera_ipc::Client::connect(path) {
                Ok(client) => return client,
                Err(error) if Instant::now() < deadline => {
                    let _ = error;
                    std::thread::sleep(Duration::from_millis(20));
                }
                Err(error) => panic!("daemon did not start: {error}"),
            }
        }
    }

    #[test]
    fn serves_requests_and_stops_cleanly() {
        let temp = tempfile::tempdir().unwrap();
        let paths = Paths::new(
            temp.path().join("config"),
            temp.path().join("data"),
            Some(temp.path().join("run")),
        );
        paths.ensure_layout().unwrap();
        let project = temp.path().join("project");
        std::fs::create_dir_all(&project).unwrap();
        klyvera_config::save(&paths.config_file(), &klyvera_config::Config::default()).unwrap();

        let store = SpaceStore::open(paths.spaces_dir()).unwrap();
        let simple = store
            .create_new(Space::new("Simple", vec![project.clone()]).unwrap())
            .unwrap();
        let mut scripted = Space::new("Scripted", vec![project]).unwrap();
        scripted.commands = vec![TerminalCommand::new("true", vec!["/bin/true".to_owned()])];
        let scripted = store.create_new(scripted).unwrap();
        let mut trust = TrustStore::open(paths.trust_file()).unwrap();
        trust.trust(&scripted).unwrap();

        let socket = paths.socket_path().unwrap();
        let config = DaemonConfig {
            paths,
            socket: socket.clone(),
            verbose: false,
        };
        let server = std::thread::spawn(move || run(config));

        let mut client = wait_for_socket(&socket);
        let ping = client.call(&Request::new(Command::Ping)).unwrap();
        assert!(ping.ok);
        assert_eq!(ping.data.unwrap()["pong"], true);

        let status = client.call(&Request::new(Command::Status)).unwrap();
        assert!(status.ok);
        let status = status.data.unwrap();
        assert_eq!(status["spaces"], 2);
        assert_eq!(status["configOk"], true);
        assert_eq!(status["protocolVersion"], PROTOCOL_VERSION);

        let list = client.call(&Request::new(Command::SpacesList)).unwrap();
        assert!(list.ok);
        assert_eq!(list.data.unwrap()["spaces"].as_array().unwrap().len(), 2);

        let show = client
            .call(&Request::for_space(Command::SpaceShow, &simple.id))
            .unwrap();
        assert!(show.ok);
        assert_eq!(show.data.unwrap()["space"]["name"], "Simple");

        let missing = client
            .call(&Request::for_space(Command::SpaceShow, "missing"))
            .unwrap();
        assert!(!missing.ok);
        assert_eq!(missing.error.unwrap().code, codes::NOT_FOUND);

        let open = client
            .call(&Request::for_space(Command::SpaceOpen, &scripted.id))
            .unwrap();
        assert!(open.ok, "{open:?}");
        assert_eq!(open.data.unwrap()["startedCommands"], 1);

        let stop = client.call(&Request::new(Command::Stop)).unwrap();
        assert!(stop.ok);
        drop(client);
        server.join().unwrap().unwrap();
        assert!(!socket.exists());
    }

    #[test]
    fn protocol_and_untrusted_errors_are_reported() {
        let temp = tempfile::tempdir().unwrap();
        let paths = Paths::new(
            temp.path().join("config"),
            temp.path().join("data"),
            Some(temp.path().join("run")),
        );
        paths.ensure_layout().unwrap();
        let project = temp.path().join("project");
        std::fs::create_dir_all(&project).unwrap();
        let store = SpaceStore::open(paths.spaces_dir()).unwrap();
        let mut space = Space::new("Untrusted", vec![project]).unwrap();
        space.commands = vec![TerminalCommand::new("true", vec!["/bin/true".to_owned()])];
        let space = store.create_new(space).unwrap();

        let socket = paths.socket_path().unwrap();
        let config = DaemonConfig {
            paths,
            socket: socket.clone(),
            verbose: false,
        };
        let server = std::thread::spawn(move || run(config));
        let mut client = wait_for_socket(&socket);

        let open = client
            .call(&Request::for_space(Command::SpaceOpen, &space.id))
            .unwrap();
        assert!(!open.ok);
        assert_eq!(open.error.as_ref().unwrap().code, codes::UNTRUSTED);

        let _ = client.call(&Request::new(Command::Stop)).unwrap();
        drop(client);
        server.join().unwrap().unwrap();
    }
}
