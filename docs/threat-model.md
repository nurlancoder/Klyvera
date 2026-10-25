# Threat model

This document describes what Klyvera protects, where trust changes hands and
which risks remain in the prototype. It is a working model, not a claim that the
system has been independently audited.

## Assets

- Project paths, application choices, commands and layout hints stored in Spaces.
- The trust records that allow imported commands to run.
- Configuration, logs, backups, backup manifests and restored files.
- The daemon Unix socket and the integrity of IPC replies.
- The user's files reachable from a Space project or a compromised command.
- Package contents, package installation scripts and the live image.
- The website source, build output and deployment workflow.

Klyvera does not store passwords, API keys, accounts or telemetry. There is no
server-side user data.

## Actors and assumptions

- The local user is trusted to configure their own workspace. Klyvera runs as
  that user and does not attempt to sandbox launched applications from the user's
  other files.
- A Space imported from another person, a downloaded JSON file or a modified
  backup is **untrusted**.
- A process running as the same Unix user is inside the local security boundary.
  File mode `0600` prevents other users from reading data; it does not isolate
  two processes owned by the same user.
- The system administrator (`root`) and the operating system kernel are outside
  Klyvera's protection boundary.
- A visitor to the static website is untrusted input, but the site has no forms,
  accounts or server-side processing.
- Upstream packages and build tools are part of the supply chain but are not
  reimplemented by Klyvera.

## Trust boundaries

| Boundary | Input | Enforcement |
| --- | --- | --- |
| Profile import → core | JSON, paths, argv arrays, layout hints | Versioned schema, limits, traversal rejection, existing project paths, argv-only commands |
| Trust confirmation → launch | Imported profile hash and explicit user choice | SHA-256 profile hash; launch planning rejects untrusted commands |
| Desktop entry → process launch | Executable name or desktop ID | Installed `.desktop` parsing; argv arrays; no shell string execution |
| CLI/daemon → filesystem | XDG paths and user-selected backup targets | Private `0700` directories, `0600` files, atomic writes, bounded archive paths |
| Local client → daemon | Length-bounded JSON request | Unix socket in `XDG_RUNTIME_DIR`, `0600`, same-UID `SO_PEERCRED`, versioned protocol |
| Backup archive → restore | Archive names, manifest, file tree | SHA-256 manifest, bounded size and path checks, staging directory, pre-restore backup |
| Package build → installed system | PKGBUILD, package file list | Arch container build, `namcap`, file-list inspection, smoke install; signing is not implemented |
| Live image → booted session | archiso profile, local repository, live user bootstrap | Explicit package list, local repository, live-only sudo account; ISO is unverified on target |
| Website source → visitor | HTML, CSS, JS and local images | Static build, local-only runtime assets, no trackers, generated Pages artifact |

## Threats and mitigations

### Imported commands execute without consent

**Risk:** a crafted Space starts an unwanted process.

**Mitigation:** imported profiles are untrusted. Command execution requires trust
recorded against the profile hash. The CLI and UI do not silently trust a
modified profile. Commands are argv arrays; shell interpreters and shell strings
are rejected.

**Residual risk:** a trusted command can still do anything the user can do.
Klyvera does not sandbox launched applications.

### Path traversal or symlink escape

**Risk:** a profile or archive reads or writes outside the project or state
directory.

**Mitigation:** project roots must exist, traversal segments are rejected,
command working directories must stay inside the project, archive paths are
bounded and restore runs through a staging directory with a manifest.

**Residual risk:** the prototype has not been audited against every symlink and
TOCTOU race on the target filesystem. Treat untrusted archives as sensitive input.

### Private data leaks through permissions or logs

**Risk:** another local user reads configuration, socket traffic or logs.

**Mitigation:** runtime directories use `0700`, files and the socket use `0600`,
the daemon unit uses a private temporary directory and a `0077` umask, and event
logs avoid usernames, paths and file names.

**Residual risk:** a process already running as the same user can read the same
data. Logs and backups are sensitive.

### Daemon IPC abuse

**Risk:** an unrelated local process drives privileged operations or crashes the
daemon.

**Mitigation:** the socket lives in `XDG_RUNTIME_DIR`, is mode `0600`, checks the
peer UID and uses a bounded versioned protocol. The request loop is nonblocking
and shutdown is signal-driven.

**Residual risk:** same-UID processes are trusted. There is no authentication
beyond peer credentials and no per-client rate limit.

### Backup restore damages current state

**Risk:** a malformed or malicious archive overwrites files or fills the disk.

**Mitigation:** manifest verification, SHA-256 checks, path and size limits,
staging, a pre-restore backup and a mandatory confirmation flag.

**Residual risk:** restore changes user files. Users must keep an independent
copy of important data and review the archive source.

### Supply-chain or build compromise

**Risk:** a dependency, action or package step injects code into a build.

**Mitigation:** pinned lockfiles, a small Rust dependency policy, CI hygiene,
containerized package builds and explicit package file lists.

**Residual risk:** dependencies are not vendored or audited on every change.
Package signing and a published keyring are not implemented. Dependabot and CI
must be reviewed rather than trusted blindly.

### Unsigned package or live image

**Risk:** a tampered artifact is installed as Klyvera.

**Mitigation:** local build instructions produce checksums and the repository is
kept local for the prototype.

**Residual risk:** public release artifacts are not ready. The prototype uses
`sha256sums=('SKIP')`, an unsigned local pacman repository and `TrustAll` in the
live image. These are explicitly prototype-only and must not be distributed as a
release.

### Website compromise or privacy leak

**Risk:** the site loads a tracker, exposes a secret or deploys unexpected
content.

**Mitigation:** the site is static and local-first, has no forms or accounts, uses
no remote fonts or analytics, and the static checker rejects tracker markers,
insecure URLs and external runtime assets. The Pages workflow requests only the
permissions needed to publish.

**Residual risk:** GitHub Pages and the repository account are external trust
dependencies. Deployment has not run yet; the live URL and Pages configuration
are unverified.

## Security testing performed

- Rust tests cover path validation, shell rejection, command working-directory
  containment, trust hashes, backup restore, IPC socket permissions and peer
  checks.
- Schema tests accept valid examples and reject seven invalid documents.
- Static website checks reject tracker/font markers, insecure URLs, escaping
  assets and broken local links.
- Browser checks run axe WCAG A/AA in three site themes at mobile and desktop
  widths.
- Packaging was built in an Arch container, inspected with `bsdtar` and exercised
  with a `--nodeps` install smoke test.

## Not verified

- No independent security audit or fuzzing campaign has run.
- No live Hyprland/Quickshell session or real ISO boot has been tested.
- No dependency-resolved install, package signature verification or keyring
  distribution has been tested.
- No target filesystem race or hostile archive corpus has been tested.
- No GitHub-hosted CI, Pages deployment or branch-protection policy has run.
