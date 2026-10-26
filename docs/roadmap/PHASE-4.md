# Phase 4 — Shell features and integration

Goal: every shell surface a user touches, driven by pure QML pages with mock
data and isolated from Quickshell/Hyprland by an integration layer.

## Steps

- [x] Define integration contracts for shell data (spaces, apps, notifications,
      system services) and provide a pure-QML mock implementation.
- [x] Build the keyboard-first launcher with fuzzy search, recents, grouped
      results, empty/error states and layout-class reflow.
- [x] Build the Spaces list, detail, create/edit wizard, folder and app pickers,
      inline validation, import/export and command trust confirmation.
- [x] Build the control center with appearance, display, audio, network,
      Bluetooth, power, shortcuts and about sections plus graceful degradation.
- [x] Build the notification center, system monitor, lock screen, session menu
      and first-run welcome experience.
- [x] Add the target integration layer: Quickshell shell root with a panel per
      screen, Hyprland workspace IPC, notifications, UPower, PipeWire and
      argv-only bridges for NetworkManager and BlueZ.
- [x] Ship modular Hyprland defaults and documented keybindings.
- [x] Add offscreen page previews and behaviour tests, then run lint, tests and
      token checks.
- [x] Record verified and UNVERIFIED-ON-TARGET work in `docs/STATUS.md`.

## Implementation notes

- `shell/integration/ServiceContract.qml` defines the data surface and
  `MockService.qml` provides deterministic preview data.
- Pure pages live in `shell/pages/`; none import Quickshell or Hyprland.
- `shell/integration/quickshell/` contains the target-only adapters and is
  excluded from local and CI lint because the target modules are unavailable on
  the development host.
- `packaging/config/hypr/` contains the includeable Klyvera keybind fragment.
- `preview/pages.qml` and `preview/render_pages.py` render every surface at
  1440×900 and the launcher at 1180, 1440, 1920 and 2560 px widths.
- `tests/qml/pages_behavior.py` checks fuzzy launcher results and rejects shell
  interpreters and command working-directory traversal.

## Exit criteria

- Every page imports only Qt Quick, `shell/ui`, `shell/styles` or pure helpers;
  no page imports Quickshell or Hyprland.
- The launcher is fully operable from the keyboard and reflows without clipping
  at 1180, 1440, 1920 and 2560 px widths.
- Spaces validation rejects unsafe paths and shell commands, and command
  execution needs an explicit confirmation.
- Missing audio, network, Bluetooth or battery services show an honest,
  usable degraded state.
- Local checks pass: qmllint over lintable QML, offscreen tests and previews,
  cargo checks, shellcheck and token drift.
- Everything that needs Arch, Hyprland or Quickshell is labelled
  **UNVERIFIED-ON-TARGET**.

## V3 repair pass — Component geometry

This checklist tracks the follow-up visual repair and does not reopen the
completed shell integration phase above.

- [x] Add an offscreen regression check for button content alignment at the
      configured target size.
- [x] Correct the button content layout without changing its public API or
      interaction behavior.
- [x] Re-run QML behavior tests, focused lint and the
      documentation checks; record local and target limitations.
