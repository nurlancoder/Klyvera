
mod client;
mod error;
mod protocol;
mod socket;

pub use client::Client;
pub use error::IpcError;
pub use protocol::{
    codes, generate_request_id, read_frame, write_frame, Command, ErrorBody, Request, Response,
    MAX_MESSAGE_BYTES, PROTOCOL_VERSION,
};
pub use socket::{bind_listener, current_uid, peer_uid, remove_socket, verify_peer};
