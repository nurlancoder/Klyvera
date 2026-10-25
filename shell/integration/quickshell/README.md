# Quickshell target adapter

This directory is **UNVERIFIED-ON-TARGET**. Quickshell, Hyprland, UPower and
PipeWire are not available on the Debian-based development host, so none of
these files can be linted or run in CI.

The pure UI in `shell/ui/` and `shell/pages/` never imports Quickshell. This
adapter owns every compositor, notification, audio and power dependency.

## Files

- `shell.qml` — Quickshell entry point.
- `QuickshellShell.qml` — per-monitor panel and overlay windows, Hyprland
  workspaces, IPC targets and the Klyvera Core process calls.
- `QuickshellSystemBridge.qml` — argv-only probes for `/proc`, `wpctl`, `nmcli`,
  `bluetoothctl` and UPower.
- `QuickshellNotificationBridge.qml` — notification daemon backed by Quickshell.

## Install for local testing

```bash
mkdir -p ~/.config/quickshell
ln -s "$PWD/shell/integration/quickshell" ~/.config/quickshell/klyvera
qs -c klyvera
```

Add the Hyprland fragment from `packaging/config/hypr/conf.d/10-klyvera.conf`
to the running Hyprland configuration, or include
`packaging/config/hypr/klyvera.conf`.

## IPC

```bash
qs -c klyvera ipc call launcher toggle
qs -c klyvera ipc call controlcenter toggle
qs -c klyvera ipc call notifications toggle
qs -c klyvera ipc call session toggle
qs -c klyvera ipc call spaces open <space-id>
```

## Known gaps

- Lock screen and first-run Welcome windows are designed in pure QML but not yet
  bound to the target session-lock protocol.
- `SpacesPage` is not mounted in the target shell yet; the launcher calls
  `klyvera spaces open` directly.
- Display refresh rate falls back to 0 when Quickshell does not expose it.
