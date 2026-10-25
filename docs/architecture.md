# Architecture

Klyvera is split into layers with explicit trust boundaries. The UI never talks
to Hyprland or system services directly; it goes through the integration layer.
Persistent state is owned by Klyvera Core.

## Layer diagram

```
┌──────────────────────────────────────────────────────────────────────────┐
│ KLYVERA UI                                                               │
│                                                                          │
│  shell/ui/          pure QML components: no Quickshell imports           │
│  shell/pages/       launcher, Spaces, control center, notifications      │
│  shell/styles/      generated Theme.qml from design/tokens.json          │
│  preview/           mock-data harness, renders pure QML without Hyprland │
└───────────────────────────────┬──────────────────────────────────────────┘
                                │ properties, signals, view models
┌───────────────────────────────▼──────────────────────────────────────────┐
│ INTEGRATION LAYER                                                        │
│                                                                          │
│  shell/integration/                                                      │
│    Quickshell shell surfaces and panels                                  │
│    Hyprland IPC adapter (workspaces, windows, monitors)                  │
│    system-service adapters (PipeWire, NetworkManager, BlueZ, UPower)     │
│    Klyvera Core IPC client                                               │
│                                                                          │
│  Adapters expose the same interfaces whether the service exists or not.  │
└───────────────┬──────────────────────────────────┬───────────────────────┘
                │ versioned JSON over Unix socket  │ D-Bus / CLI / files
┌───────────────▼──────────────────┐   ┌───────────▼───────────────────────┐
│ KLYVERA CORE (Rust)              │   │ HYPRLAND / WAYLAND + SERVICES     │
│                                  │   │                                   │
│  klyvera-config   typed config   │   │  Hyprland, Wayland protocols      │
│  klyvera-spaces   Space model    │   │  PipeWire, WirePlumber            │
│  klyvera-backup   archives       │   │  NetworkManager, BlueZ            │
│  klyvera-ipc      protocol       │   │  UPower, portals                  │
│  klyvera-daemon   session service│   │  freedesktop notifications        │
│  klyvera-cli      user CLI       │   │                                   │
└───────────────┬──────────────────┘   └───────────┬───────────────────────┘
                │                                  │
┌───────────────▼──────────────────────────────────▼───────────────────────┐
│ ARCH LINUX                                                               │
│  kernel, systemd user session, filesystem, packages, XDG directories     │
└──────────────────────────────────────────────────────────────────────────┘
```

## Data flow

```
key press ──► QML page ──► integration adapter ──► core IPC / Hyprland
                  │                                    │
                  └── view-model state ◄───────────────┘

Space selection ──► core validates paths and app argv
                ──► user confirmation if profile is untrusted
                ──► apps launched as argv arrays (no shell)
                ──► compositor layout hints applied through Hyprland IPC
```

## Ownership of state

| State | Owner | Location |
| --- | --- | --- |
| Appearance and general config | `klyvera-config` | `$XDG_CONFIG_HOME/klyvera/config.json` |
| Spaces | `klyvera-spaces` | `$XDG_DATA_HOME/klyvera/spaces/*.json` |
| Import trust records | `klyvera-spaces` | `$XDG_DATA_HOME/klyvera/trust.json` |
| Backups | `klyvera-backup` | user-selected path, timestamped archive |
| Daemon socket | `klyvera-daemon` | `$XDG_RUNTIME_DIR/klyvera/daemon.sock` |
| UI transient state | QML | memory only |
| Service state | PipeWire, NetworkManager, BlueZ, UPower | never duplicated |

All persistent directories are created with mode `0700`; files are `0600`. Writes
are atomic (temporary file in the same directory, fsync, rename). Every persisted
document carries a schema version.

## Trust boundaries

1. **Imported profiles are untrusted.** Import computes a hash of the profile.
   Commands and layout hints are not executed until the user confirms that hash;
   the confirmation is stored per hash. Re-importing changed content invalidates
   the confirmation.
2. **No shell.** Application entries are argv arrays. `.desktop` `Exec` lines are
   parsed according to the desktop entry specification with field codes removed,
   not passed through `sh -c`.
3. **Paths are validated.** Spaces may reference existing directories only, with
   traversal rejected and canonical paths compared against allowed roots.
4. **IPC is user-local.** The Unix socket lives under `XDG_RUNTIME_DIR` with mode
   `0600`, and the daemon verifies peer credentials where the platform allows it.
   Messages are versioned JSON with bounded sizes.
5. **Logs contain no personal data.** No usernames, home paths, project names or
   command lines. Messages identify components and error classes only.

## Failure and degradation

- Missing Hyprland IPC: Spaces still open applications; layout hints are reported
  as unavailable.
- Missing system service: the corresponding control-center section shows an
  explanatory empty state and a retry action.
- Missing daemon: the UI falls back to read-only config and offers to start it;
  the CLI reports a clear diagnostic.
- Corrupt JSON: the file is not silently overwritten. The error names the file and
  schema version; a backup of the previous good file is kept where possible.

## Process model

- **Shell**: one Quickshell process per graphical session; one panel instance per
  output; a single launcher/control-center instance.
- **Core daemon**: one per user session, started on demand or by the systemd user
  unit. Serializes writes to Spaces and owns the IPC socket.
- **CLI**: short-lived client. It can operate directly on files when the daemon is
  not running, using the same library code.

## Technology decisions

The stack is recorded in `docs/decisions/0001-stack.md`. Changes require a new
decision record. Development happens on a Debian-based workstation; target-only
behaviour is tracked in `docs/STATUS.md`.
