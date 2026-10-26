# Phase 2 — Klyvera Core (Rust)

Goal: a tested Rust workspace that owns configuration, Spaces, backups, IPC, the
user daemon and the CLI. Nothing in this phase executes shell strings.

## Steps

- [x] Create the Cargo workspace, shared dependency policy and toolchain file.
- [x] `klyvera-config`: typed configuration, XDG paths, atomic 0600 writes,
      version field, a real v0→v1 migration and strict validation. 17 tests pass.
- [x] `klyvera-spaces`: model, Space versioning, strict path and command
      validation, profile hashing, CRUD store, import/export, trust records,
      `.desktop` resolution and argv-only launch planning. 33 tests pass.
- [x] `klyvera-backup`: timestamped tar.gz archives with a SHA-256 manifest,
      integrity verification and safe restore with a pre-restore backup.
      8 tests pass.
- [x] `klyvera-ipc`: versioned, bounded JSON protocol over a 0600 Unix socket,
      peer-UID checks and a small client. 11 tests pass.
- [x] `klyvera-daemon`: nonblocking accept loop, typed request dispatch,
      structured logs without personal data, graceful SIGTERM/SIGINT and IPC
      shutdown. 2 integration tests pass, including live trust reload.
- [x] `klyvera-cli`: `spaces list|new|open|export|import` plus `show`, `delete`,
      `trust`, `backup`, `restore`, `doctor`, `--json` and `--dry-run`.
      2 end-to-end CLI tests pass.
- [x] JSON Schemas for configuration and Spaces, with validated examples.
- [x] Unit tests per crate, parser edge cases and integration tests for daemon
      and CLI. 74 tests pass in total.
- [x] `docs/spaces-spec.md`, `core/README.md`, checks and honest status update.

## Security contract

- Profiles never contain shell strings; commands are argv arrays and shell
  interpreters are rejected as the program.
- Imported profiles are untrusted; commands require a confirmation tied to the
  profile SHA-256 hash.
- Project paths must be absolute, traversal-free and exist when opened.
- The daemon socket lives under `XDG_RUNTIME_DIR` with mode 0600 and same-UID
  peer checks.
- Logs contain event names and counts, never usernames, home paths, project names
  or command lines.

## Exit criteria

- `cargo fmt --check`, `cargo clippy --all-targets -- -D warnings` and
  `cargo test --all` pass locally.
- Schema examples validate with `jsonschema`.
- `klyvera doctor` gives a readable report on Kali with honest warnings.
- Manual target behaviour is listed as unverified, not claimed.

## V3 repair pass — Theme API verification

This checklist tracks the separate V3 repair pass; it does not reopen the
completed Rust core phase above.

- [x] Preserve the merged GitHub palette and valid alpha-color values while
  comparing the required V3 color keys.
- [x] Generate the missing Theme accessors and compatibility token aliases
  without replacing the current token schema or palette.
- [x] Fix generated `qmldir` comment syntax and verify generated-file drift.
- [x] Add and run a static contract test for QML Theme references and numeric
  token identifiers.
- [x] Render component and page previews, inspect at least six screenshots, and
  record concrete findings in `docs/design-audit.md`. The Windows/offscreen
  font-rendering limitation is recorded; unusable regenerated captures
  were not retained.
- [x] Run the phase checks, update `docs/STATUS.md`, and record any blockers.
