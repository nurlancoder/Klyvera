# Spaces specification

Klyvera Spaces are local, versioned workspace profiles. A Space records project
directories, optional applications and terminal commands, and presentation hints.
The Rust core is the authority for validation; the JSON Schemas describe the same
shape for editors and external tools.

## Storage

All state lives under the XDG data directory:

| Path | Purpose |
| --- | --- |
| `$XDG_DATA_HOME/klyvera/spaces/<id>.json` | One file per Space. |
| `$XDG_DATA_HOME/klyvera/spaces/.trash/` | Deleted Spaces, retained for recovery. |
| `$XDG_DATA_HOME/klyvera/trust.json` | Command confirmations keyed by profile hash. |
| `$XDG_DATA_HOME/klyvera/backups/` | Verified `backup-*.tar.gz` archives. |

Configuration is separate at `$XDG_CONFIG_HOME/klyvera/config.json`. Klyvera
creates owned directories with mode `0700` and writes files with mode `0600`
using an atomic replace. Space files larger than 512 KiB are rejected.

## Document format

```json
{
  "version": 1,
  "id": "klyvera-core",
  "name": "Klyvera Core",
  "description": "Rust services, schemas and tests",
  "icon": "code",
  "accent": "purple",
  "projectPaths": ["/srv/projects/klyvera"],
  "apps": [{"desktopId": "code.desktop"}],
  "layout": {
    "monitor": "DP-1",
    "workspace": 2,
    "masterCount": 2,
    "gapsIn": 4,
    "gapsOut": 8
  },
  "commands": [
    {
      "label": "Tests",
      "argv": ["cargo", "test"],
      "cwd": "/srv/projects/klyvera/core"
    }
  ],
  "createdAt": 1760000000,
  "updatedAt": 1760000000
}
```

Persisted documents require `version`, `id`, `name` and at least one
`projectPaths` entry. Unknown fields are rejected. Optional fields are omitted
unless they carry a value. Imported profiles with zero `createdAt`/`updatedAt`
are normalised on import.

## Fields and limits

| Field | Rules |
| --- | --- |
| `version` | Exactly `1` for this specification. |
| `id` | 1–64 lowercase ASCII letters, digits or hyphens; starts and ends with a letter or digit. Unique on disk. |
| `name` | 1–80 characters, no surrounding whitespace, no control characters. |
| `description` | At most 280 characters, no control characters. |
| `icon` | 1–64 lowercase letters, digits or hyphens. Symbolic name, not a path. |
| `accent` | `purple`, `blue`, `mint` or `neutral`. |
| `projectPaths` | 1–16 unique absolute paths, at most 4096 bytes each. No `.` or `..` components. Paths must be existing directories when a Space is opened. |
| `apps` | At most 32 unique `.desktop` ids. Relative paths are allowed, but must end in `.desktop`, contain no backslash, NUL, traversal component or empty component. Terminal applications are rejected at launch. |
| `layout` | Hints only: monitor 1–64 safe characters, workspace 1–99, master count 1–10, gaps 0–100. The core never applies compositor state itself. |
| `commands` | At most 16 commands with a trimmed 1–80 character label and 1–32 argv strings of at most 4096 bytes. The program must not be a shell interpreter. |
| `cwd` | Optional absolute path inside one of the Space's project paths when opened. No traversal. |
| `createdAt`, `updatedAt` | Unix seconds. Maintained by the core; imported values are normalised. |

Slug generation lowercases ASCII letters, turns other runs into single hyphens
and falls back to `space` when nothing usable remains.

## Commands and trust

Commands are always argv arrays. Klyvera never parses a command string, never
invokes a shell and rejects `sh`, `bash`, `zsh`, `fish`, `dash`, `ksh`, `csh`,
`tcsh`, `nu`, `xonsh`, `elvish`, `pwsh`, `powershell` and `cmd` as the program.
This prevents profile authors from smuggling a shell pipeline into a Space.

A Space's **profile hash** is the lowercase SHA-256 of its canonical JSON
serialization. Any change to any field changes the hash.

Imported or edited Spaces are untrusted. Opening a Space that contains commands
requires a confirmation recorded for its current profile hash:

```bash
klyvera spaces trust my-space
klyvera spaces open my-space
```

`trust` replaces earlier confirmations for the same Space; `untrust` removes
them. Trust is checked when opening, not when saving. `--dry-run` never needs
trust because it starts nothing. The daemon re-reads the trust file for each
open request, so confirming while the daemon runs takes effect immediately.

## Launch semantics

Opening resolves desktop ids through the standard XDG application directories,
rejects entries marked `Terminal`, and starts each app and command with an argv
array. Child stdin, stdout and stderr are null; no shell is involved. Command
working directories default to the first project path. A command `cwd` must
resolve inside one of the project roots.

Layout hints are returned by the core and are not applied here. Applying them is
Hyprland integration work and remains **UNVERIFIED-ON-TARGET**.

## Import and export

Export writes the exact persisted JSON document to stdout or to a chosen file.
Import accepts a file or `-` for stdin, rejects documents over 512 KiB, validates
the whole profile, assigns a fresh timestamp if needed, and refuses to overwrite
an existing id. Imported Spaces may refer to project folders that do not exist
yet; validation of existing folders happens when opening.

Unknown versions and unknown fields fail closed.

## Backup and restore

Backups are timestamped tar.gz archives containing `config/config.json`,
`spaces/<id>.json` and a `manifest.json` with a SHA-256 and size per file.
Verification checks the archive structure, path safety, manifest limits, sizes
and every digest before any file is used. Restore verifies first, creates a
pre-restore backup, extracts to a staging directory, validates the staged data,
then replaces live files. Displaced Spaces are moved to the trash rather than
deleted.

## Schemas

- `schemas/config.schema.json`
- `schemas/space.schema.json`
- `schemas/examples/config.default.json`
- `schemas/examples/space.example.json`

Run `python3 tests/validate_schemas.py` to validate examples and representative
invalid documents. The schemas are a structural convenience; stricter semantic
checks (for example shell rejection and canonical path duplicates) are always
enforced by the Rust model.

## CLI

```bash
klyvera spaces list
klyvera spaces new "Klyvera Core" --path /srv/projects/klyvera --app code.desktop
klyvera spaces show klyvera-core
klyvera spaces open klyvera-core --dry-run
klyvera spaces trust klyvera-core
klyvera spaces export klyvera-core --output space.json
klyvera spaces import space.json
klyvera spaces delete klyvera-core
klyvera backup
klyvera backups
klyvera verify "$XDG_DATA_HOME/klyvera/backups/backup-YYYYMMDD-HHMMSS.tar.gz"
klyvera restore ARCHIVE --dry-run
klyvera restore ARCHIVE --yes
klyvera status --json
klyvera doctor
```

Global flags are `--json` and `--dry-run`. Destructive restore requires `--yes`
unless it is a dry run.
