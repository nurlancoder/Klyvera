# Status

Klyvera is a **prototype**. This file records what has actually been run, what is
written but cannot be exercised on the Debian-based development workstation, and
what is blocked. It is updated after every step.

Last updated: 2026-10-25 (Phase 0)

## Done

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
- Local checks run: `bash -n` on all shell scripts and
  `./scripts/check.sh --fast` (0 failures, 6 skips).

## Unverified on target

- The CI workflow has not been executed on GitHub; its YAML and expressions are
  unverified in a runner.
- The pre-commit hook is installed locally via `core.hooksPath`, but its
  shellcheck path has not run because shellcheck is absent here.
- Nothing has been run on Arch Linux or in a Hyprland/Wayland session yet.
- No QML has been rendered or linted on this workstation.

## Blocked

- **shellcheck** is not installed on the development workstation. Scripts are
  syntax-checked with `bash -n`; shellcheck runs in CI. Installing it would
  require a system package, so it is deferred.
- **qmllint / Qt QML runtime** is not installed (Qt libraries exist, but the QML
  tooling and QtQuick modules do not). QML work in Phase 3 cannot be linted or
  rendered locally unless a user-level Qt runtime is provided. CI defines the
  lint job; screenshots remain blocked until a runtime is available.
- **Hyprland, Quickshell, pacman, mkarchiso** cannot run on Kali. All target-only
  work is unverified by definition.
- **License** is provisional Apache-2.0 and needs maintainer confirmation
  (`docs/decisions/0002-license.md`). This is a maintainer decision, not a
  blocker for development.

## Missing / not yet built

- Design tokens and generators (Phase 1).
- Rust core workspace (Phase 2).
- QML components, preview harness, screenshots (Phase 3).
- Launcher, Spaces UI, control center, integration layer (Phase 4).
- Packaging, archiso profile, ISO workflow (Phase 5).
- Website (Phase 6).
- Hardening, manual test checklist, release notes (Phase 7).
