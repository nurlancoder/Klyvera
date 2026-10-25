# Phase 5 — Packaging and live image

Goal: reproducible Arch packages for the core and shell, a live ISO profile built
with archiso, and a documented installer path. The live session is offline-capable;
a fully offline target installation is not implemented in this phase.

## Steps

- [x] Write separated `klyvera-core`, `klyvera-shell` and `klyvera-meta`
      PKGBUILDs with install manifests, licenses and a shared source archive.
- [x] Add a systemd user unit for the daemon with a minimal sandbox.
- [x] Add the Quickshell config, Hyprland fragment, desktop entry and a
      non-destructive per-user setup command.
- [x] Record the installer decision and document package, install and upgrade
      behavior.
- [x] Add the archiso profile with live user, autologin, the Klyvera packages,
      branding, installer and a local package repository.
- [x] Add the Arch package CI job and keep the ISO build manual but scripted
      until a self-hosted Arch runner exists.
- [x] Record verified and UNVERIFIED-ON-TARGET work in `docs/STATUS.md`.

## Verification

- `bash -n` and `shellcheck 0.11.0` pass for every helper script.
- `makepkg` built `klyvera-core`, `klyvera-shell` and `klyvera-meta` inside the
  official `archlinux:latest` container on 2026-10-25. `repo-add` created the
  local repository. `namcap` reported only expected dependency-visibility
  warnings because the build used `--nodeps`; package file lists were inspected.
- `pacman -Si` confirmed `quickshell 0.3.2`, `hyprland 0.56.2`, `archiso 91`
  and `archinstall 4.5` are available in the Arch repositories used by the test.
- The packages were installed with `pacman -U --nodeps` in the Arch container.
  `klyvera --version`, `klyvera doctor --json`, `klyvera-shell-setup` and
  `systemd-analyze verify` on the user unit all passed. This is not a
  dependency-resolved target install.
- `mkarchiso` was not executed: the workstation has no Arch target, loop-device
  budget or disk headroom for an ISO build. The profile and ISO remain
  **UNVERIFIED-ON-TARGET**.

## Exit criteria

- [x] PKGBUILDs pass `bash -n`, shellcheck on their helper scripts and `makepkg`
  metadata checks in an Arch container.
- [x] Package contents include only declared files and licenses.
- [x] The live ISO profile has an explicit package set, a reproducible local
  repository path and a documented build command. Versions are not pinned;
  Arch repositories are rolling.
- [x] No package writes into a user's home directory at install time.
- [x] The ISO, package installation, signing and install path are labelled
  **UNVERIFIED-ON-TARGET**. Package build is verified; ISO build, boot and
  install are not.
- [x] A fully offline installation of the complete desktop stack is explicitly
  deferred and recorded in `docs/STATUS.md`. The image carries the Klyvera
  packages; `archinstall` still resolves non-Klyvera dependencies from
  repositories unless they are cached.
