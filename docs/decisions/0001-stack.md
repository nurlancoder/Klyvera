# 0001 — Technology stack

- **Status:** accepted
- **Date:** 2026-10-25
- **Deciders:** maintainer

## Context

Klyvera targets developers on Arch Linux who want a polished, keyboard-first
desktop with project-based workspaces. The project has one maintainer, no budget
and no servers. The shell must integrate with Hyprland, and the core must be
testable without a graphical session.

## Decision

- Arch Linux as the base and packaging target.
- Hyprland on Wayland as the compositor.
- Quickshell with Qt 6 QML for the shell, with pure QML components isolated from
  Quickshell imports.
- Rust stable for core libraries, daemon and CLI, in a multi-crate workspace.
- JSON plus JSON Schema for configuration and Spaces.
- Bash only for small developer and packaging glue.
- Static Vite + TypeScript website on GitHub Pages.
- GitHub Actions for CI, PKGBUILD for packages, archiso for the ISO.

## Consequences

- Development on Debian cannot exercise Hyprland, Quickshell, pacman or
  mkarchiso; those paths stay unverified until tested on target.
- QML purity allows a mock-data preview harness on the development machine.
- Rust gives strong parsing and filesystem safety for untrusted profiles, at the
  cost of a larger build than a scripting implementation.
- Dynamic Qt linking keeps the LGPL obligations manageable; static linking would
  require a new decision and license review.

## Alternatives considered

- **GTK/Vala or Rust GTK shell:** weaker fit for Hyprland-specific panels and
  Quickshell's existing Wayland surface support.
- **Electron/web shell:** unacceptable memory use and no native Wayland panel
  integration.
- **Go or Python core:** viable, but Rust's type system and ownership model fit
  the security invariants better for a long-lived project.
- **Nix-based distribution:** conflicts with the Arch target and the zero-budget,
  small-scope constraint.
