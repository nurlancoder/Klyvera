use std::fs;
use std::os::unix::fs::{FileTypeExt, PermissionsExt};
use std::os::unix::io::AsRawFd;
use std::os::unix::net::{UnixListener, UnixStream};
use std::path::Path;

use klyvera_config::ensure_private_dir;

use crate::error::IpcError;

const MAX_SOCKET_PATH_BYTES: usize = 107;

/// Return the effective UID of this process.
pub fn current_uid() -> u32 {
    #[cfg(unix)]
    {
        // SAFETY: geteuid has no preconditions and cannot fail.
        unsafe { libc::geteuid() }
    }
    #[cfg(not(unix))]
    {
        0
    }
}

pub fn peer_uid(stream: &UnixStream) -> Result<u32, IpcError> {
    #[repr(C)]
    struct PeerCredentials {
        pid: libc::pid_t,
        uid: libc::uid_t,
        gid: libc::gid_t,
    }

    let mut credentials = PeerCredentials {
        pid: 0,
        uid: 0,
        gid: 0,
    };
    let mut length = std::mem::size_of::<PeerCredentials>() as libc::socklen_t;
    // SAFETY: the socket fd is valid, and the pointer/length describe a
    // correctly sized PeerCredentials buffer for SO_PEERCRED.
    let result = unsafe {
        libc::getsockopt(
            stream.as_raw_fd(),
            libc::SOL_SOCKET,
            libc::SO_PEERCRED,
            (&mut credentials as *mut PeerCredentials).cast(),
            &mut length,
        )
    };
    if result != 0 {
        return Err(IpcError::stream(std::io::Error::last_os_error()));
    }
    if length as usize != std::mem::size_of::<PeerCredentials>() {
        return Err(IpcError::protocol("unexpected SO_PEERCRED size"));
    }
    Ok(credentials.uid)
}

pub fn verify_peer(stream: &UnixStream) -> Result<(), IpcError> {
    let peer = peer_uid(stream)?;
    let ours = current_uid();
    if peer == ours {
        Ok(())
    } else {
        Err(IpcError::PeerUid { peer, ours })
    }
}

/// Bind a 0600 Unix listener, replacing a stale socket left by a crashed
/// daemon but never replacing a live listener or a regular file.
pub fn bind_listener(path: &Path) -> Result<UnixListener, IpcError> {
    if !path.is_absolute() {
        return Err(IpcError::InvalidSocketPath(path.to_path_buf()));
    }
    check_path_length(path)?;
    let parent = path
        .parent()
        .ok_or_else(|| IpcError::InvalidSocketPath(path.to_path_buf()))?;
    ensure_private_dir(parent)?;

    if let Ok(metadata) = fs::symlink_metadata(path) {
        if !metadata.file_type().is_socket() {
            return Err(IpcError::InvalidSocketPath(path.to_path_buf()));
        }
        match UnixStream::connect(path) {
            Ok(_) => return Err(IpcError::AlreadyRunning(path.to_path_buf())),
            Err(error)
                if matches!(
                    error.kind(),
                    std::io::ErrorKind::ConnectionRefused | std::io::ErrorKind::NotFound
                ) =>
            {
                fs::remove_file(path).map_err(|error| IpcError::io(path, error))?;
            }
            Err(error) => return Err(IpcError::io(path, error)),
        }
    }

    let listener = UnixListener::bind(path).map_err(|error| IpcError::io(path, error))?;
    fs::set_permissions(path, fs::Permissions::from_mode(0o600))
        .map_err(|error| IpcError::io(path, error))?;
    Ok(listener)
}

pub fn remove_socket(path: &Path) {
    if let Ok(metadata) = fs::symlink_metadata(path) {
        if metadata.file_type().is_socket() {
            let _ = fs::remove_file(path);
        }
    }
}

fn check_path_length(path: &Path) -> Result<(), IpcError> {
    #[cfg(unix)]
    {
        use std::os::unix::ffi::OsStrExt;
        let length = path.as_os_str().as_bytes().len();
        if length > MAX_SOCKET_PATH_BYTES {
            return Err(IpcError::InvalidSocketPath(path.to_path_buf()));
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    #[test]
    fn binds_private_sockets_and_refuses_live_ones() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("daemon.sock");
        let listener = bind_listener(&path).unwrap();
        let mode = fs::metadata(&path).unwrap().permissions().mode();
        assert_eq!(mode & 0o777, 0o600);
        assert!(matches!(
            bind_listener(&path),
            Err(IpcError::AlreadyRunning(_))
        ));
        drop(listener);
    }

    #[test]
    fn replaces_stale_sockets_only() {
        let temp = tempfile::tempdir().unwrap();
        let path = temp.path().join("daemon.sock");
        let listener = bind_listener(&path).unwrap();
        drop(listener);
        assert!(path.exists());
        let listener = bind_listener(&path).unwrap();
        drop(listener);

        let regular = temp.path().join("regular");
        fs::write(&regular, b"keep me").unwrap();
        assert!(bind_listener(&regular).is_err());
        assert_eq!(fs::read(&regular).unwrap(), b"keep me");
    }

    #[test]
    fn rejects_relative_and_overlong_paths() {
        assert!(bind_listener(Path::new("relative.sock")).is_err());
        let long = PathBuf::from(format!("/tmp/{}", "a".repeat(120)));
        assert!(bind_listener(&long).is_err());
    }

    #[test]
    fn peer_uid_matches_for_a_local_pair() {
        let (left, right) = UnixStream::pair().unwrap();
        assert_eq!(peer_uid(&left).unwrap(), current_uid());
        verify_peer(&left).unwrap();
        drop(right);
    }
}
