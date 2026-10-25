# AGENTS.md — Klyvera engineering guide

If context is lost, read AGENTS.md and docs/STATUS.md before doing anything.

## What Klyvera is

Klyvera is an original, local-first Linux desktop product for developers and
technical users. Tagline: **Your workspace. Your flow.**

- **Klyvera Shell** — panel, launcher, notifications, control center (Quickshell + QML).
- **Klyvera Spaces** — project-based workspace profiles; the flagship feature.
- **Klyvera Themes** — token-driven appearance, dark/light/high-contrast.
- **Klyvera Core** — Rust services and CLI.
- **Klyvera OS** — later: Arch-based ISO built with archiso.
- Audience: developers and technical Linux users. Quality bar: polished commercial
  product, not a dotfiles pack.
- Constraints: solo developer, zero budget, no servers, no paid services, no API
  keys, no telemetry, no accounts. Everything is local-first and works offline.

## Stack (do not change without a decision record)

| Layer | Choice |
| --- | --- |
| Base OS | Arch Linux |
| Compositor | Hyprland (Wayland) |
| Shell UI | Quickshell + QML (Qt 6) |
| Core | Rust stable, multi-crate workspace |
| Scripts | Bash, shellcheck-clean, only where Rust is overkill |
| Config/profiles | JSON + JSON Schema |
| Docs | Markdown |
| Website | Static Vite + TypeScript, GitHub Pages |
| CI | GitHub Actions |
| Packaging | PKGBUILD; archiso profile for the ISO |

Changing any row requires a new record in `docs/decisions/`.

## Environment rules (critical)

We develop on Kali Linux (Debian-based), **not** Arch. Hyprland, a real Wayland
session, pacman and mkarchiso cannot be run here.

- Never claim something works on the target if it was not run on the target.
  Mark such items **UNVERIFIED-ON-TARGET** in `docs/STATUS.md`.
- Work only inside this repository. Never modify system files, use sudo, run as
  root, or delete anything outside the project.
- Do not install system packages. User-level tool installs (cargo, npm, pip in a
  temporary venv) are acceptable. Ask before anything system-wide.
- Never commit secrets, API keys, tokens, personal paths or user data. A thorough
  `.gitignore` exists; keep it current.
- Never run `git push`. The maintainer pushes.
- Do not copy code, configuration or assets from other desktop projects
  (Omarchy, HyDE, ML4W, Dank Linux, end-4, and so on). Everything is original.
- Do not imply affiliation with Arch Linux, Hyprland or Quickshell. Credit
  upstream projects in `docs/CREDITS.md` and track licenses in
  `THIRD_PARTY_NOTICES.md`.

## Working protocol

1. At the start of a phase, update `docs/roadmap/PHASE-N.md` with its step list.
2. Work one step at a time. Keep files focused and small; name things clearly.
3. Comment the **why**, not the what. No comments that restate code.
4. Write tests with or before the code. No dead code. No TODO without an entry
   in `docs/STATUS.md`.
5. After each step run every check that can run here:
   `cargo fmt --check`, `cargo clippy -- -D warnings`, `cargo test`,
   `qmllint`, `shellcheck`, JSON Schema validation, token generation check,
   `npm run build`. Fix failures before committing.
6. Commit each completed step with Conventional Commits. Keep commits small.
7. Update `docs/STATUS.md` after each step with three lists:
   **DONE**, **UNVERIFIED-ON-TARGET**, **BLOCKED**.
8. Continue to the next step and phase automatically. Stop and ask only when:
   a decision is genuinely the maintainer's (license, pricing, legal); a system
   package is required; an action is destructive; or three honest attempts at a
   problem have failed.
9. Be honest. Do not write "works", "tested" or "production ready" unless it was
   actually run in the claimed environment. Never invent benchmarks or features.

## Commands

```bash
# Rust core (after Phase 2)
cd core && cargo fmt --check && cargo clippy --all-targets -- -D warnings && cargo test

# Design tokens (after Phase 1)
python3 design/generators/generate.py --check

# Web (after Phase 6)
cd web && npm ci && npm run build

# Scripts
shellcheck scripts/*.sh .githooks/*

# Local aggregate check
./scripts/check.sh
```

## Conventions

- Rust: edition 2021, `rustfmt` defaults, `clippy` warnings are errors. Errors
  use typed enums/`thiserror`; no panics for user input. No shell execution:
  launch processes with argv arrays only (`std::process::Command` / `exec`).
- QML: pure components in `shell/ui/` must **not** import Quickshell. All
  Quickshell/Hyprland access lives in `shell/integration/` behind interfaces.
  Sizes come from tokens and a scale factor, never hard-coded pixels.
- QML file names: `PascalCase.qml`; properties/functions camelCase; signals past
  tense (`clicked`); IDs lowerCamelCase.
- JSON: 2-space indent, schemas in `schemas/`, version field on persisted data.
- Bash: `#!/usr/bin/env bash`, `set -euo pipefail`, quote everything, pass
  shellcheck.
- Docs: Markdown, one H1, sentence case headings, code fences with language.
- Git: Conventional Commits (`feat:`, `fix:`, `docs:`, `test:`, `chore:`,
  `ci:`, `refactor:`). Subject imperative, <= 72 characters. No secrets.
- File permissions: runtime config dirs `0700`, files `0600`, Unix socket `0600`.

## Security invariants

- Never execute shell strings from profiles. Apps are argv arrays, resolved via
  installed `.desktop` entries.
- Imported profiles are untrusted. Any command execution requires explicit user
  confirmation recorded per profile hash.
- Validate paths: reject traversal, require existence for project paths.
- IPC: Unix socket in `XDG_RUNTIME_DIR`, mode `0600`, versioned JSON protocol.
- Structured logs contain no personal data (no usernames, paths, file names).
- Atomic writes for config; backup before restore.

## Repository layout

```
design/     tokens.json, generators, brand notes
docs/       vision, architecture, specs, decisions, roadmap, STATUS, MANUAL_TEST
core/       Rust workspace: config, spaces, backup, ipc, daemon, cli
shell/      ui/ (pure QML), integration/ (Quickshell), pages/, styles/, assets/
preview/    mock-data harness for pure-QML rendering and screenshots
schemas/    JSON Schemas for profiles and config
packaging/  pkgbuild/, archiso/, installer/
web/        landing page and docs site
scripts/    developer scripts (shellcheck-clean)
tests/      cross-component and end-to-end tests
.github/    workflows, issue/PR templates
```

## License

Apache-2.0 is the intended default, **pending maintainer confirmation**. See
`docs/decisions/0002-license.md`. Do not relicense without a decision record.
