# Phase 3 — Shell component library

Goal: a pure-QML component library that covers every Phase 4 shell surface,
uses only design tokens, stays free of Quickshell imports and can be rendered
without Hyprland.

## Steps

- [x] Make nested theme tokens statically typed. `Theme.qml` now emits inline
      `SpacingTokens`, `RadiusTokens`, `BorderTokens`, `ElevationTokens`,
      `TypographyTokens`, `MotionTokens`, `IconTokens`, `LayoutTokens` and
      `AccessibilityTokens` components, so `qmllint` resolves every token path.
- [x] Implement the 20 components in the design-system inventory: Panel,
      WorkspaceIndicator, Clock, SystemIndicators, Button, IconButton, TextField,
      SearchField, ListItem, Card, Toggle, Slider, Tabs, Dialog, ConfirmDialog,
      Toast, Tooltip, EmptyState, ErrorState and Skeleton.
- [x] Add internal `Icon` (original Canvas line glyphs with conventional names) and
      `FocusRing`
      helpers, plus `shell/ui/qmldir`.
- [x] Keep interaction states accessible: keyboard focus, arrow-key tabs and
      sliders, Arrow/Page/Home/End slider stepping, Escape search clearing,
      dialog focus trapping, reduce-motion handling and accessible names.
- [x] Add `preview/main.qml`, a mock-data gallery that renders the library
      without Quickshell, and `preview/render.py` for offscreen screenshots.
- [x] Generate dark, light and dialog screenshots plus compact, wide and
      ultrawide renders in `docs/screenshots/`; the gallery reflows from one to
      two columns at the compact breakpoint.
- [x] Add `tests/qml/dialog_focus.py`, a permanent offscreen check that verifies
      initial dialog focus, Tab/Backtab containment, Escape dismissal and the
      `rejected` signal.
- [x] Run `pyside6-qmllint`, the focus behaviour test and the offscreen renderer.

## Component contract

- All visual values come from `Theme`; no component hard-codes a colour, radius
  or duration.
- No file in `shell/ui/` imports Quickshell. Integration stays in Phase 4.
- Icon-only controls require `accessibleName`; form controls expose labels and
  error text to assistive technology.
- Interactive controls use a visible 2 px focus ring with token-defined offset.
- Dialogs are modal, centre themselves, trap keyboard focus, close on Escape and
  emit `rejected` when dismissed without confirming.
- The preview is a development harness, not a shipping shell surface.

## Exit criteria

- `pyside6-qmllint -I shell/ui -I shell/styles` exits successfully for the
  library, preview and test QML.
- The dialog focus test passes offscreen.
- The preview renders dark, light, open-dialog and compact/wide/ultrawide
  screenshots without warnings.
- `python3 design/generators/generate.py --check` still reports every generated
  file in sync.
- `docs/STATUS.md` records what was actually run and what remains unverified.

## Notes

Qt 6.12 from a temporary user-level PySide6 environment is used for linting and
offscreen rendering. The component gallery has not run under Quickshell or in a
Wayland session, and the screenshots have not been checked on the target.
`qmllint` still prints one known singleton warning when `Theme.qml` is linted as
a standalone file; the command exits successfully.

## V3 repair pass — Icon catalog and generator

This checklist tracks the separate V3 repair pass; it does not reopen the
completed shell component-library phase above.

- [x] Inventory the SVG assets, existing Canvas icon coverage, and the
      incomplete SVG-to-QML generator.
- [x] Add a manifest covering every shipped SVG with its name, source,
      provenance, and provisional project-license status.
- [x] Replace the stub generator with deterministic manifest and supported SVG
      geometry validation, then generate the QML catalog and Shape components.
- [x] Add regression tests for manifest completeness, SVG validity, generated
      output and `--check` drift detection; wire them into `scripts/check.sh`.
- [x] Update icon licensing/provenance documentation and record phase results
      and any remaining legal or target-environment blockers.
