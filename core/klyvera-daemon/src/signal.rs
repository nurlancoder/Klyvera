use std::sync::atomic::{AtomicBool, Ordering};

static SHUTDOWN: AtomicBool = AtomicBool::new(false);

extern "C" fn request_shutdown(_: libc::c_int) {
    SHUTDOWN.store(true, Ordering::SeqCst);
}

/// Install SIGTERM/SIGINT handlers that only flip an atomic flag. The accept
/// loop owns cleanup, so the handler stays async-signal-safe.
pub fn install() -> Result<(), String> {
    #[cfg(unix)]
    {
        // SAFETY: the handler only performs a lock-free atomic store, and the
        // sigaction structures are fully initialised before the call.
        unsafe {
            let mut action: libc::sigaction = std::mem::zeroed();
            action.sa_sigaction = request_shutdown as *const () as usize;
            libc::sigemptyset(&mut action.sa_mask);
            action.sa_flags = 0;
            if libc::sigaction(libc::SIGTERM, &action, std::ptr::null_mut()) != 0 {
                return Err(std::io::Error::last_os_error().to_string());
            }
            if libc::sigaction(libc::SIGINT, &action, std::ptr::null_mut()) != 0 {
                return Err(std::io::Error::last_os_error().to_string());
            }
        }
        Ok(())
    }
    #[cfg(not(unix))]
    {
        Ok(())
    }
}

pub fn requested() -> bool {
    SHUTDOWN.load(Ordering::SeqCst)
}

pub(crate) fn reset() {
    SHUTDOWN.store(false, Ordering::SeqCst);
}
