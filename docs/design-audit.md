# Design Audit (Pass 2)

Started: 2026-10-25. Scope: existing QML previews, website, tokens, icons.

## Method
- Review all screenshots in `docs/screenshots/` against the visual checklist (alignment, spacing, hierarchy, contrast, states, clipping).
- Review web build and assets for layout/typography/consistency.
- Record concrete defects with location and fix plan.

## Findings

### V3 repair Phase 2 — Theme tokens and preview review

- The dark component preview exposed a color-order defect: source tokens such
  as `#FFFFFF14` use CSS `#RRGGBBAA`, but the generator treated the final byte
  as Qt's leading alpha. This produced an opaque yellow border instead of a
  subtle translucent white border. The generator now converts the trailing
  alpha to Qt `#AARRGGBB` and CSS `rgba(...)`; focused regression tests cover
  both outputs.
- The regenerated Windows/offscreen Qt screenshots rendered text as square
  placeholders, including after forcing an installed Segoe UI font. The
  generated captures were not retained because they are not usable visual
  evidence. Existing checked-in screenshots remain unchanged. Reliable
  screenshot rendering must be rechecked in the documented Linux Qt
  environment; a real Quickshell/Wayland visual review is also still pending.
- Reviewed the checked-in `components-dark.png`, `components-light.png`,
  `components-dialog.png`, `control-center.png`, `spaces.png` and
  `notifications.png`. Their text is legible and the reviewed layouts show no
  obvious clipping; the control-center and notification previews intentionally
  leave substantial open space around their panel content.
- No target-environment visual conclusions are drawn from these offscreen
  captures. Arch, Quickshell and Wayland appearance remains unverified.

### V3 repair Phase 3 — Icon assets

- The SVG inventory contained 50 original assets, but `Icon.qml` only drew a
  smaller hand-written set and the existing generator emitted empty SVG paths.
  The generated catalog now indexes every manifest asset and the generator
  converts supported SVG geometry into non-empty QML `ShapePath` components.
  `Icon.qml` loads those components while retaining Canvas for dynamic battery
  state and fallback glyphs.
- Generated Shape components use the existing `QtQuick.Shapes` runtime and
  expose a bound color property. Runtime coverage confirms all static icons
  render with their requested tint and their QML component tint updates when
  the parent color changes.
- Asset provenance is recorded as original project artwork. Per-asset license
  status remains pending with the project's provisional license decision; no
  third-party artwork was introduced.

### V3 repair Phase 4 — Button content geometry

- The checked-in component previews showed Button labels pinned to the top-left
  of their targets. The offscreen geometry test reproduced the issue: a
  text-only label center was at y=7 px in a 48 px button.
- `Button.qml` now gives the control a content container whose child row is
  centered within the control-provided content bounds. A regression test
  verifies both axes with an icon-and-label button.
- Automated offscreen verification passed. The screenshots were not regenerated
  on this Windows host; target visual review remains pending.

### V3 repair Phase 5 — Remaining control geometry

- Added offscreen measurements for IconButton, Tabs and ListItem alongside the
  Button regression. Their icon, label and content row align with their target
  bounds; no further component layout changes were indicated.
- The geometry checks are not a substitute for an Arch/Quickshell/Wayland
  review. Existing screenshots were not regenerated.

### V3 repair Phase 6 — Website visual review

- Reviewing the built site revealed a large blank band above the sticky header.
  The inline SVG symbol sprite had no dimensions or positioning and occupied
  the browser's default 300×150 px viewport plus inline baseline space.
- The sprite now has zero dimensions and absolute positioning; all in-page
  `<use>` icons remain present. The header begins at y=0 on the English and
  Azerbaijani landing pages and documentation hub.
- Browser review covered desktop and mobile layouts. The responsive/menu
  interaction and accessible navigation remain intact; deployment itself is
  still unverified.

## Phase B - Tokens v2
- Updated tokens to premium palette with better contrast
- Regenerated Theme.qml, tokens.css, contrast-report.md
- All contrast pairs pass WCAG AA (0 failures)

## Phase C - Icons & Brand
- Added SVG icon set under shell/assets/icons/ (7+ icons, more to add)
- Added brand logomark and wordmark SVGs
- Icon generator script created
- Icon existence test added


## Phase D - Components (polish)
- Audited components for alignment/centering, padding, states
- Focused on Button, IconButton, Tabs, ListItem geometry
- Ensuring proper spacing tokens and responsive behavior


## Status

The V3 repair passes through Phase 4 have focused local regression checks.
Arch/Quickshell/Wayland visual review and the maintainer's project-license
decision remain pending.
