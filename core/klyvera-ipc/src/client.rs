use std::io::{BufReader, Write};
use std::os::unix::net::UnixStream;
use std::path::{Path, PathBuf};
use std::time::Duration;

use crate::error::IpcError;
use crate::protocol::{read_frame, write_frame, Request, Response};

const CLIENT_TIMEOUT: Duration = Duration::from_secs(10);

#[derive(Debug)]
pub struct Client {
    path: PathBuf,
    stream: UnixStream,
}

impl Client {
    pub fn connect(path: impl Into<PathBuf>) -> Result<Self, IpcError> {
        let path = path.into();
        let stream = UnixStream::connect(&path).map_err(|error| IpcError::io(&path, error))?;
        crate::socket::verify_peer(&stream)?;
        stream
            .set_read_timeout(Some(CLIENT_TIMEOUT))
            .map_err(IpcError::stream)?;
        stream
            .set_write_timeout(Some(CLIENT_TIMEOUT))
            .map_err(IpcError::stream)?;
        Ok(Self { path, stream })
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn call(&mut self, request: &Request) -> Result<Response, IpcError> {
        request.validate()?;
        let encoded = request.encode()?;
        write_frame(&mut self.stream, &encoded)?;

        let mut reader = BufReader::new(&mut self.stream);
        let frame = read_frame(&mut reader)?
            .ok_or_else(|| IpcError::protocol("daemon closed the connection without a response"))?;
        let response = Response::parse(&frame)?;
        if response.request_id != request.request_id {
            return Err(IpcError::protocol(format!(
                "response requestId '{}' does not match '{}'",
                response.request_id, request.request_id
            )));
        }
        Ok(response)
    }

    pub fn shutdown(&mut self) {
        let _ = self.stream.shutdown(std::net::Shutdown::Both);
        let _ = self.stream.flush();
    }
}

impl Drop for Client {
    fn drop(&mut self) {
        let _ = self.stream.shutdown(std::net::Shutdown::Both);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::protocol::Command;
    use crate::socket::bind_listener;
    use serde_json::json;
    use std::thread;

    #[test]
    fn client_roundtrips_with_a_local_server() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("daemon.sock");
        let listener = bind_listener(&path).unwrap();
        let server = thread::spawn(move || {
            let (mut stream, _) = listener.accept().unwrap();
            crate::socket::verify_peer(&stream).unwrap();
            let mut reader = BufReader::new(&stream);
            let frame = read_frame(&mut reader).unwrap().unwrap();
            let request = Request::parse(&frame).unwrap();
            assert_eq!(request.command, Command::Ping);
            let response = Response::ok(request.request_id, Some(json!({"pong": true})));
            write_frame(&mut stream, &response.encode().unwrap()).unwrap();
        });

        let mut client = Client::connect(&path).unwrap();
        let response = client.call(&Request::new(Command::Ping)).unwrap();
        assert!(response.ok);
        assert_eq!(response.data, Some(json!({"pong": true})));
        server.join().unwrap();
    }

    #[test]
    fn missing_socket_is_a_clear_error() {
        let temp = tempfile::tempdir().unwrap();
        assert!(Client::connect(temp.path().join("missing.sock")).is_err());
    }
}
