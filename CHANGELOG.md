# Changelog

All notable changes to Klyvera are documented here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and
the project intends to use [Semantic Versioning](https://semver.org/). Klyvera is
pre-release: interfaces may change without notice.

## [Unreleased]

### Added

- Repository foundation: contribution rules, security policy, code of conduct,
  issue and pull request templates, and CI skeleton.
- Design tokens, generated Qt and CSS themes, WCAG contrast report and the design
  system guide.
- Rust core: versioned configuration, Spaces model/store/trust, `.desktop`
  resolution, argv-only launch planning, verified backups and restore, versioned
  Unix-socket IPC, a user daemon and the `klyvera` CLI.
- JSON Schemas and validated examples for configuration and Spaces, plus a schema
  validation test.
- Spaces specification and core engineering guide.
- Pure QML component library for the shell, a typed generated theme, an offscreen
  component gallery with dark/light/dialog screenshots, and a dialog focus test.
- Nine pure QML shell pages and target-only Quickshell/Hyprland adapters,
  including argv-only process probes, a notification server and offscreen page
  screenshots.
- Three PKGBUILDs, a deterministic package build, a user systemd unit, a
  Quickshell setup command and an archiso profile with a local package repository.
- Static Vite + TypeScript website with English and Azerbaijani landing pages,
  an English documentation hub, generated theme tokens, local screenshots,
  Playwright/axe browser checks and a GitHub Pages workflow.
- Operational documentation: website build and deployment, threat model, manual
  test checklist, troubleshooting and release process.

### Changed

- The CLI now ensures the XDG layout exists with `0700` permissions before
  touching state.

### Security

- Documented trust boundaries, residual risks and the unsigned-artifact release
  gap in `docs/threat-model.md` and `docs/RELEASE.md`.

### Planned

- `0.1.0-prototype`: target-verified packages, a bootable ISO, a live Hyprland
  session, signed artifacts and a verified Pages deployment.

