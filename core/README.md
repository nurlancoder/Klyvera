# Klyvera Core

The Rust workspace behind Klyvera Spaces, backups, IPC, the user daemon and the
`klyvera` CLI. Everything is local-first and offline; profiles never contain
shell strings.

## Crates

| Crate | Responsibility |
| --- | --- |
| `klyvera-config` | Versioned configuration, XDG paths, atomic `0600` writes, strict validation and a v0→v1 migration. |
| `klyvera-spaces` | Space model and validation, file store and trash, import/export, profile hashing, trust records, `.desktop` parsing and argv-only launch planning. |
| `klyvera-backup` | Timestamped tar.gz archives, SHA-256 manifests, safe verification and staged restore with a pre-restore backup. |
| `klyvera-ipc` | Versioned bounded JSON protocol over a `0600` Unix socket, framing, peer-UID checks and a client. |
| `klyvera-daemon` | Nonblocking accept loop, typed request dispatch, graceful SIGTERM/SIGINT and IPC shutdown. |
| `klyvera-cli` | The `klyvera` binary: Spaces, trust, backup, restore, status and doctor. |

Dependencies are pinned once in the workspace `Cargo.toml`. The workspace targets
Rust 1.75 or newer and uses edition 2021.

## Build and check

```bash
cd core
cargo fmt --all --check
cargo clippy --all-targets -- -D warnings
cargo test --all
```

From the repository root, `./scripts/check.sh` also runs design-token, shell,
QML and JSON Schema checks when their tools are available.

## Running locally

```bash
cargo run -p klyvera-cli -- spaces list
cargo run -p klyvera-daemon
```

The daemon uses `$XDG_RUNTIME_DIR/klyvera/daemon.sock`. It refuses sockets not
owned by the current user, removes stale sockets, and reloads trust records for
each open request. Logs contain event names and counts only.

## Data locations

- `$XDG_CONFIG_HOME/klyvera/config.json`
- `$XDG_DATA_HOME/klyvera/spaces/<id>.json`
- `$XDG_DATA_HOME/klyvera/spaces/.trash/`
- `$XDG_DATA_HOME/klyvera/trust.json`
- `$XDG_DATA_HOME/klyvera/backups/backup-*.tar.gz`
- `$XDG_RUNTIME_DIR/klyvera/daemon.sock`

Directories are `0700`, files and sockets are `0600`. Configuration and Space
writes are atomic.

## Security contract

- No shell execution from profiles; apps and commands are argv arrays.
- Imported profiles are untrusted until a confirmation matches the profile
  SHA-256, and any edit invalidates that confirmation.
- Project paths must be absolute, traversal-free and existing when opened.
- Restore verifies every digest, stages extraction, validates it and backs up
  current data before replacing anything.
- IPC requires a same-UID peer and a supported protocol version.
- Structured logs exclude usernames, home paths, project names and command lines.

See [`docs/spaces-spec.md`](../docs/spaces-spec.md) for the profile format and
[`docs/STATUS.md`](../docs/STATUS.md) for verified versus target-only behaviour.
