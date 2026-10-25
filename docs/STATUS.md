# Status

Klyvera is a **prototype**. This file records what has actually been run, what is
written but cannot be exercised on the Debian-based development workstation, and
what is blocked. It is updated after every step.

Last updated: 2026-10-25 (Phase 4)

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

### Shell component library (Phase 3)

- `shell/styles/Theme.qml` now emits typed inline components for spacing,
  radius, borders, elevation, typography, motion, icons, layout and
  accessibility. `qmllint` resolves nested token access such as
  `Theme.typography.body.size` and `Theme.layout.panel.height`.
- Twenty components from the design-system inventory are implemented in
  `shell/ui/`: Panel, WorkspaceIndicator, Clock, SystemIndicators, Button,
  IconButton, TextField, SearchField, ListItem, Card, Toggle, Slider, Tabs,
  Dialog, ConfirmDialog, Toast, Tooltip, EmptyState, ErrorState and Skeleton.
- Internal `Icon` and `FocusRing` helpers provide Canvas icons and token-based
  focus outlines. `shell/ui/qmldir` exposes the library as
  `Klyvera.Components`.
- Interaction work includes roving tabs, slider keyboard stepping, Escape to
  clear search text, reduce-motion handling, accessible names, focus rings and a
  modal dialog that traps Tab/Backtab focus and dismisses with Escape.
- `preview/main.qml` renders a mock-data gallery without Quickshell and reflows
  to one column below 1280 px. The `preview/render.py` harness writes dark,
  light and open-dialog screenshots at 1440×1520 plus compact (1180×1400), wide
  (1920×1500) and ultrawide (2560×1400) renders to `docs/screenshots/`.
- `tests/qml/dialog_focus.py` is a permanent offscreen behaviour test for initial
  focus, Tab/Backtab containment, Escape dismissal and the `rejected` signal.

### Shell surfaces and integration (Phase 4)

- `shell/integration/ServiceContract.qml` defines the shell data contract for
  apps, Spaces, settings, recents, notifications, displays, audio, network,
  Bluetooth, power, host, monitor and capabilities. `MockService.qml` supplies
  deterministic preview data.
- Nine pure QML pages in `shell/pages/`: Launcher, SpacesPage, SpaceEditor,
  ControlCenter, NotificationCenter, SystemMonitor, LockScreen, SessionMenu and
  Welcome. They import only Qt Quick, `shell/ui`, `shell/styles` and the pure
  integration contract.
- Launcher provides fuzzy app/Space/settings results, recents, sectioned rows,
  keyboard selection, Escape clearing and layout-class reflow.
- Spaces UI provides list/detail, a three-step editor, folder and app choices,
  inline validation, import/export signals and command trust confirmation. The
  editor rejects shell interpreters, control bytes and command working
  directories outside the project or containing `..`.
- Control center covers appearance, display, audio, network, Bluetooth, power,
  shortcuts and about; each service failure has a visible degraded state rather
  than fake data.
- Notification center, system monitor, lock screen, session menu and first-run
  welcome are implemented, including unread state, do-not-disturb, destructive
  action confirmation, reduced-motion awareness and accessible names.
- `shell/integration/quickshell/` contains target-only adapters: per-screen
  panel and overlay windows, Hyprland workspaces, IPC targets, argv-only system
  probes, UPower battery state and a Quickshell notification server.
  `shell.qml` is the Quickshell entry point and the directory is excluded from
  local and CI lint because its target modules are absent.
- `packaging/config/hypr/klyvera.conf` and
  `packaging/config/hypr/conf.d/10-klyvera.conf` document the includeable
  keybindings for launcher, control center, notifications, session menu and lock.
- `preview/pages.qml` renders all nine surfaces plus a light Spaces view; the
  launcher is also rendered at 1180, 1440, 1920 and 2560 px widths.
  `docs/screenshots/` contains the resulting PNGs.
- `tests/qml/pages_behavior.py` verifies fuzzy launcher search and Space command
  validation, including shell rejection and `..` working-directory rejection.
- `TextField` now uses guarded two-way text sync instead of an alias to avoid
  binding loops. `Slider` exposes a `moved` signal for user-driven changes.
  `FocusRing` is public so pages can use it through directory imports.

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
- `pyside6-qmllint 6.12` over `shell/ui`, `shell/styles`, `shell/integration`
  (non-Quickshell files), `shell/pages`, `preview` and `tests/qml`: exit status
  0. The two warnings are the known standalone `Theme.qml` and `MockService.qml`
  singleton warnings. The Quickshell target directory is deliberately excluded
  because its modules do not exist here.
- `python3 tests/qml/dialog_focus.py` offscreen: initial focus on the primary
  action, nine Tab and five Backtab presses contained, Escape closed the dialog
  and emitted `rejected`.
- `python3 tests/qml/pages_behavior.py` offscreen: fuzzy query returned the Code
  result, a `bash` command was rejected, a command working directory containing
  `..` was rejected and a valid argv command passed validation.
- `python3 preview/render.py` offscreen with the software Qt Quick backend:
  six component screenshots across four layout classes written successfully.
  Rendered sizes and component geometry were probed at runtime; no key component
  had zero size.
- `python3 preview/render_pages.py` offscreen: nine page screenshots, a light
  Spaces view and launcher renders at 1180, 1440, 1920 and 2560 px widths.
- `./scripts/check.sh` with the temporary Qt/shellcheck environment:
  **0 failures, 1 skipped** (website not built yet).
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
- QML has not been rendered in a Quickshell session or a Wayland session. The
  gallery, page previews, screenshots and behaviour tests run under offscreen Qt
  Quick only, and none of the screenshots have had a human visual review on the
  target. The standalone lint emits two known false-positive singleton warnings
  for `Theme.qml` and `MockService.qml`; exit status is success.
- The Quickshell adapter in `shell/integration/quickshell/` has not been linted
  or executed. Its import names, window properties, IPC handlers, UPower calls,
  notification fields and process collectors must be validated on Arch with
  Quickshell and Hyprland.
- The Hyprland fragment has not been included in a live Hyprland configuration.
  Keybind conflicts, `qs` availability and session-lock wiring are unverified.
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

- Packaging, archiso profile, ISO workflow (Phase 5).
- Website (Phase 6).
- Hardening, manual test checklist, release notes (Phase 7).
