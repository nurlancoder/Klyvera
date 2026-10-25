# Status

Klyvera is a **prototype**. This file records what has actually been run, what is
written but cannot be exercised on the Debian-based development workstation, and
what is blocked. It is updated after every step.

Last updated: 2026-10-25 (Phase 2)

## Done

### Foundation

- Repository skeleton and layout for design, docs, core, shell, preview, schemas,
  packaging, web, scripts, tests and GitHub metadata.
- `AGENTS.md` with product rules, stack, environment limits, security invariants,
  conventions and definition of done.
- Root documents: README, provisional Apache-2.0 LICENSE, CONTRIBUTING, SECURITY,
  CODE_OF_CONDUCT, CHANGELOG, THIRD_PARTY_NOTICES, CREDITS.
- Bug and feature issue forms, pull request template, Dependabot configuration.
- CI workflow definition with hygiene, shell, Rust, design-token, QML, JSON Schema
  and website jobs. Jobs detect missing layers and skip cleanly.
- Pre-commit hook, hook installer and `scripts/check.sh` aggregate check.
- Vision, architecture with layer and data-flow diagrams, decision records 0001
  (stack) and 0002 (license pending), Phase 0 roadmap.

### Design system

- `design/tokens.json` with dark, light and high-contrast palettes plus spacing,
  radius, border, elevation, typography, motion, icon, layout and accessibility
  tokens.
- `design/generators/generate.py` with deterministic output, `--check` drift
  detection and a generated WCAG contrast report.
- Generated `shell/styles/Theme.qml`, `shell/styles/qmldir`,
  `web/src/styles/tokens.css` and `docs/contrast-report.md`.
- WCAG AA verified locally for 47 required pairs per theme (text on four
  surfaces, text on accent fills, focus ring on four surfaces): **0 failures in
  all three themes**.
- `docs/design-system.md` documents foundations, states, motion, responsive rules,
  accessibility and component contracts. `design/brand.md` documents the
  wordmark, voice and visual direction.

### Rust core (Phase 2)

- Cargo workspace with six crates, shared dependency policy, stable toolchain
  pinned to `rustfmt` and `clippy`, edition 2021 and rust-version 1.75.
- `klyvera-config`: typed configuration with defaults, strict validation, XDG
  paths, private `0700`/`0600` layout, atomic writes and a real v0→v1 migration.
  18 tests pass.
- `klyvera-spaces`: versioned Space model, slug and id rules, structural and
  launched-path validation, SHA-256 profile hashes, CRUD store with trash,
  import/export, hash-keyed trust records, `.desktop` parsing and an argv-only
  launch planner. Shell interpreters are rejected and command working directories
  must stay inside a Space project root. 33 tests pass.
- `klyvera-backup`: timestamped tar.gz archives with SHA-256 manifests, bounded
  path/size validation, verified restore through a staging directory, a
  pre-restore backup and trash-based displacement. 8 tests pass.
- `klyvera-ipc`: versioned bounded JSON protocol, line framing, `0600` socket
  binding with stale-socket recovery, same-UID peer checks via `SO_PEERCRED` and
  a client. 11 tests pass.
- `klyvera-daemon`: nonblocking accept loop, typed dispatch, signal shutdown,
  per-request trust reload and privacy-preserving event logs. 2 integration tests
  pass.
- `klyvera-cli`: `spaces list|new|show|open|delete|export|import|trust|untrust`,
  `backup`, `backups`, `verify`, `restore`, `status` and `doctor`, with global
  `--json` and `--dry-run`. Restore requires `--yes` and commands require trust.
  2 end-to-end CLI tests pass.
- `schemas/config.schema.json` and `schemas/space.schema.json` with validated
  examples. `tests/validate_schemas.py` checks both examples and rejects seven
  representative invalid documents: **9/9 checks pass**.
- `docs/spaces-spec.md` documents storage, the profile format, limits, command
  trust, launch semantics, backup/restore and the CLI. `core/README.md` documents
  the workspace, checks, data locations and security contract.
- `klyvera doctor` was exercised through the CLI integration test with an isolated
  XDG environment and returned a successful JSON report with honest warnings.

### Checks actually run

- `cargo fmt --all --check` across the workspace.
- `cargo clippy --all-targets -- -D warnings` across the workspace.
- `cargo test --all` across the workspace: **74 tests pass** (config 18, spaces
  33, backup 8, IPC 11, daemon 2, CLI 2).
- `python3 tests/validate_schemas.py` with `jsonschema`: 9/9 checks pass.
- `bash -n` on all shell scripts and `.githooks/pre-commit`.
- `python3 -m py_compile design/generators/generate.py`.
- `python3 design/generators/generate.py --check` (in sync, contrast passes).
- `shellcheck 0.11.0` and `pyside6-qmllint` 6.12 from the temporary user-level
  environment at `/tmp/opencode/klyvera-qt-venv`.
- A QML smoke file imported `shell/styles` and read `Theme.background`,
  `Theme.spacing.md` and `Theme.layoutClass(2700)` successfully with
  `pyside6-qml` and `QT_QPA_PLATFORM=offscreen`.
- YAML parsing of the workflow, Dependabot config and issue forms with PyYAML.

## Unverified on target

- The CI workflow has not been executed on GitHub; its YAML and expressions are
  unverified in a runner.
- Nothing has been run on Arch Linux or in a Hyprland/Wayland session yet.
- The Rust core, daemon and CLI have only run on the Kali Linux x86_64
  development workstation. Cross-distribution packaging, systemd user units and
  target integration are unverified.
- Hyprland layout hints are produced by the core but are not applied anywhere;
  compositor integration is **UNVERIFIED-ON-TARGET**.
- QML has not been rendered in a Quickshell session; only an offscreen Qt Quick
  smoke test has run. The standalone lint emits one known false-positive warning
  ("Type Theme not declared as singleton") because qmllint checks the singleton
  file outside its module context; exit status is success.
- The generated CSS has not been consumed by a web build yet.

## Blocked

- **System-level shellcheck and qmllint are absent.** A temporary user-level
  environment at `/tmp/opencode/klyvera-qt-venv` (PySide6-Essentials 6.12 and
  shellcheck-py 0.11.0) is used for local checks. It is outside the repository
  and not reproducible from the repo; CI installs its own toolchain. A clean
  checkout therefore skips shellcheck and QML lint locally.
- **Hyprland, Quickshell, pacman, mkarchiso** cannot run on Kali. All target-only
  work is unverified by definition.
- **License** is provisional Apache-2.0 and needs maintainer confirmation
  (`docs/decisions/0002-license.md`). This is a maintainer decision, not a
  blocker for development.

## Missing / not yet built

- QML components, preview harness, screenshots (Phase 3).
- Launcher, Spaces UI, control center, integration layer (Phase 4).
- Packaging, archiso profile, ISO workflow (Phase 5).
- Website (Phase 6).
- Hardening, manual test checklist, release notes (Phase 7).
