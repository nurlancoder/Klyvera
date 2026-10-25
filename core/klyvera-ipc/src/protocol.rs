use std::io::{BufRead, Write};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use serde::{Deserialize, Serialize};
use serde_json::Value;

use crate::error::IpcError;

pub const PROTOCOL_VERSION: u32 = 1;
pub const MAX_MESSAGE_BYTES: usize = 1024 * 1024;
const MAX_REQUEST_ID: usize = 64;
const MAX_SPACE_ID: usize = 128;

pub mod codes {
    pub const BAD_REQUEST: &str = "bad-request";
    pub const UNSUPPORTED_VERSION: &str = "unsupported-version";
    pub const NOT_FOUND: &str = "not-found";
    pub const INVALID_SPACE: &str = "invalid-space";
    pub const UNTRUSTED: &str = "untrusted";
    pub const INTERNAL: &str = "internal";
    pub const PROTOCOL: &str = "protocol";
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "kebab-case")]
pub enum Command {
    Ping,
    Status,
    SpacesList,
    SpaceShow,
    SpaceOpen,
    Stop,
}

impl Command {
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Ping => "ping",
            Self::Status => "status",
            Self::SpacesList => "spaces-list",
            Self::SpaceShow => "space-show",
            Self::SpaceOpen => "space-open",
            Self::Stop => "stop",
        }
    }

    pub fn requires_space(self) -> bool {
        matches!(self, Self::SpaceShow | Self::SpaceOpen)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct Request {
    pub version: u32,
    pub request_id: String,
    pub command: Command,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub space_id: Option<String>,
}

impl Request {
    pub fn new(command: Command) -> Self {
        Self {
            version: PROTOCOL_VERSION,
            request_id: generate_request_id(),
            command,
            space_id: None,
        }
    }

    pub fn for_space(command: Command, space_id: impl Into<String>) -> Self {
        Self {
            space_id: Some(space_id.into()),
            ..Self::new(command)
        }
    }

    pub fn with_request_id(mut self, request_id: impl Into<String>) -> Self {
        self.request_id = request_id.into();
        self
    }

    pub fn validate(&self) -> Result<(), IpcError> {
        if self.version != PROTOCOL_VERSION {
            return Err(IpcError::UnsupportedVersion(self.version));
        }
        validate_request_id(&self.request_id)?;
        match (&self.space_id, self.command.requires_space()) {
            (Some(space_id), true) => {
                if space_id.is_empty() || space_id.len() > MAX_SPACE_ID || space_id.contains('\0') {
                    return Err(IpcError::BadRequest(
                        "spaceId must be 1-128 bytes without NUL".to_owned(),
                    ));
                }
            }
            (None, true) => {
                return Err(IpcError::BadRequest(format!(
                    "{} requires spaceId",
                    self.command.as_str()
                )));
            }
            (Some(_), false) => {
                return Err(IpcError::BadRequest(format!(
                    "{} does not accept spaceId",
                    self.command.as_str()
                )));
            }
            (None, false) => {}
        }
        Ok(())
    }

    pub fn encode(&self) -> Result<Vec<u8>, IpcError> {
        self.validate()?;
        encode_message(self)
    }

    pub fn parse(bytes: &[u8]) -> Result<Self, IpcError> {
        if bytes.len() > MAX_MESSAGE_BYTES {
            return Err(IpcError::TooLarge(MAX_MESSAGE_BYTES));
        }
        let request: Self = serde_json::from_slice(bytes).map_err(IpcError::Json)?;
        request.validate()?;
        Ok(request)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct Response {
    pub version: u32,
    pub request_id: String,
    pub ok: bool,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub data: Option<Value>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub error: Option<ErrorBody>,
}

impl Response {
    pub fn ok(request_id: impl Into<String>, data: Option<Value>) -> Self {
        Self {
            version: PROTOCOL_VERSION,
            request_id: request_id.into(),
            ok: true,
            data,
            error: None,
        }
    }

    pub fn error(request_id: impl Into<String>, code: &str, message: impl Into<String>) -> Self {
        Self {
            version: PROTOCOL_VERSION,
            request_id: request_id.into(),
            ok: false,
            data: None,
            error: Some(ErrorBody {
                code: code.to_owned(),
                message: message.into(),
            }),
        }
    }

    pub fn validate(&self) -> Result<(), IpcError> {
        if self.version != PROTOCOL_VERSION {
            return Err(IpcError::UnsupportedVersion(self.version));
        }
        validate_request_id(&self.request_id)?;
        if self.ok && self.error.is_some() {
            return Err(IpcError::protocol("success response contains an error"));
        }
        if !self.ok && self.error.is_none() {
            return Err(IpcError::protocol("error response has no error body"));
        }
        if self.ok && self.data.is_none() {
            return Err(IpcError::protocol("success response has no data"));
        }
        Ok(())
    }

    pub fn encode(&self) -> Result<Vec<u8>, IpcError> {
        self.validate()?;
        encode_message(self)
    }

    pub fn parse(bytes: &[u8]) -> Result<Self, IpcError> {
        if bytes.len() > MAX_MESSAGE_BYTES {
            return Err(IpcError::TooLarge(MAX_MESSAGE_BYTES));
        }
        let response: Self = serde_json::from_slice(bytes).map_err(IpcError::Json)?;
        response.validate()?;
        Ok(response)
    }
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub struct ErrorBody {
    pub code: String,
    pub message: String,
}

fn validate_request_id(request_id: &str) -> Result<(), IpcError> {
    let valid = (1..=MAX_REQUEST_ID).contains(&request_id.len())
        && request_id
            .chars()
            .all(|character| character.is_ascii_alphanumeric() || "-_.:".contains(character));
    if valid {
        Ok(())
    } else {
        Err(IpcError::BadRequest(
            "requestId must be 1-64 safe ASCII characters".to_owned(),
        ))
    }
}

fn encode_message<T: Serialize>(value: &T) -> Result<Vec<u8>, IpcError> {
    let mut bytes = serde_json::to_vec(value).map_err(IpcError::Json)?;
    bytes.push(b'\n');
    if bytes.len() > MAX_MESSAGE_BYTES {
        return Err(IpcError::TooLarge(MAX_MESSAGE_BYTES));
    }
    Ok(bytes)
}

/// Read one newline-delimited frame. EOF is `Ok(None)`.
pub fn read_frame<R: BufRead>(reader: &mut R) -> Result<Option<Vec<u8>>, IpcError> {
    let mut frame = Vec::new();
    loop {
        let available = reader.fill_buf().map_err(IpcError::stream)?;
        if available.is_empty() {
            if frame.is_empty() {
                return Ok(None);
            }
            break;
        }
        if let Some(newline) = available.iter().position(|byte| *byte == b'\n') {
            let take = newline + 1;
            if frame.len() + take > MAX_MESSAGE_BYTES + 1 {
                return Err(IpcError::TooLarge(MAX_MESSAGE_BYTES));
            }
            frame.extend_from_slice(&available[..take]);
            reader.consume(take);
            break;
        }
        if frame.len() + available.len() > MAX_MESSAGE_BYTES + 1 {
            return Err(IpcError::TooLarge(MAX_MESSAGE_BYTES));
        }
        frame.extend_from_slice(available);
        let consumed = available.len();
        reader.consume(consumed);
    }
    if frame.last() == Some(&b'\n') {
        frame.pop();
        if frame.last() == Some(&b'\r') {
            frame.pop();
        }
    }
    if frame.is_empty() {
        return Err(IpcError::protocol("empty frame"));
    }
    if frame.len() > MAX_MESSAGE_BYTES {
        return Err(IpcError::TooLarge(MAX_MESSAGE_BYTES));
    }
    Ok(Some(frame))
}

pub fn write_frame<W: Write>(writer: &mut W, bytes: &[u8]) -> Result<(), IpcError> {
    if bytes.len() > MAX_MESSAGE_BYTES {
        return Err(IpcError::TooLarge(MAX_MESSAGE_BYTES));
    }
    writer.write_all(bytes).map_err(IpcError::stream)?;
    writer.flush().map_err(IpcError::stream)
}

pub fn generate_request_id() -> String {
    static COUNTER: AtomicU64 = AtomicU64::new(1);
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or_default();
    let counter = COUNTER.fetch_add(1, Ordering::Relaxed);
    format!("{:x}-{:x}-{:x}", std::process::id(), nanos, counter)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;

    #[test]
    fn requests_roundtrip_and_validate_space_rules() {
        let ping = Request::new(Command::Ping);
        let encoded = ping.encode().unwrap();
        let decoded = Request::parse(&encoded).unwrap();
        assert_eq!(decoded, ping);

        let open = Request::for_space(Command::SpaceOpen, "demo");
        assert!(open.validate().is_ok());
        assert_eq!(open.command.as_str(), "space-open");

        let missing = Request {
            space_id: None,
            ..Request::for_space(Command::SpaceShow, "x")
        };
        assert!(missing.validate().is_err());
        let unexpected = Request {
            space_id: Some("x".to_owned()),
            ..Request::new(Command::Ping)
        };
        assert!(unexpected.validate().is_err());
    }

    #[test]
    fn rejects_unknown_fields_bad_versions_and_long_ids() {
        let unknown = br#"{"version":1,"requestId":"x","command":"ping","extra":1}"#;
        assert!(Request::parse(unknown).is_err());
        let future = br#"{"version":2,"requestId":"x","command":"ping"}"#;
        assert!(matches!(
            Request::parse(future),
            Err(IpcError::UnsupportedVersion(2))
        ));
        let long_id = format!(
            r#"{{"version":1,"requestId":"{}","command":"ping"}}"#,
            "a".repeat(65)
        );
        assert!(Request::parse(long_id.as_bytes()).is_err());
        let bad_command = br#"{"version":1,"requestId":"x","command":"rm-rf"}"#;
        assert!(Request::parse(bad_command).is_err());
    }

    #[test]
    fn responses_validate_success_and_error_shapes() {
        let ok = Response::ok("x", Some(serde_json::json!({"pong": true})));
        assert_eq!(Response::parse(&ok.encode().unwrap()).unwrap(), ok);
        let error = Response::error("x", codes::NOT_FOUND, "missing");
        assert_eq!(Response::parse(&error.encode().unwrap()).unwrap(), error);

        let invalid = Response {
            ok: true,
            error: Some(ErrorBody {
                code: codes::INTERNAL.to_owned(),
                message: "x".to_owned(),
            }),
            ..Response::ok("x", Some(Value::Null))
        };
        assert!(invalid.validate().is_err());
    }

    #[test]
    fn frame_reading_handles_eof_crlf_and_oversize() {
        let mut input = Cursor::new(b"{\"a\":1}\r\n{\"b\":2}\n".to_vec());
        assert_eq!(read_frame(&mut input).unwrap().unwrap(), br#"{"a":1}"#);
        assert_eq!(read_frame(&mut input).unwrap().unwrap(), br#"{"b":2}"#);
        assert!(read_frame(&mut input).unwrap().is_none());

        let mut empty = Cursor::new(Vec::new());
        assert!(read_frame(&mut empty).unwrap().is_none());

        let mut blank = Cursor::new(b"\n".to_vec());
        assert!(read_frame(&mut blank).is_err());

        let mut huge = Cursor::new(vec![b'a'; MAX_MESSAGE_BYTES + 2]);
        assert!(matches!(read_frame(&mut huge), Err(IpcError::TooLarge(_))));
    }

    #[test]
    fn generated_ids_are_unique_and_valid() {
        let first = generate_request_id();
        let second = generate_request_id();
        assert_ne!(first, second);
        let request = Request::new(Command::Status).with_request_id(first);
        assert!(request.validate().is_ok());
    }
}
