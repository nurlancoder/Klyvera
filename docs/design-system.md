# Design system

Klyvera's appearance is generated from one file: `design/tokens.json`. No
component may hard-code a colour, font size, radius, duration or pixel size.

## Generation

```bash
python3 design/generators/generate.py          # write
python3 design/generators/generate.py --check  # verify in CI
```

| Output | Purpose |
| --- | --- |
| `shell/styles/Theme.qml` | QML singleton with palettes, scales, motion and helpers |
| `shell/styles/qmldir` | `Klyvera.Styles` module exposing the singleton |
| `web/src/styles/tokens.css` | CSS custom properties for the website |
| `docs/contrast-report.md` | Generated WCAG report |

`--check` fails when a generated file is stale or when a required contrast pair
drops below its threshold. Never edit generated files by hand.

Color tokens with eight hexadecimal digits use CSS `#RRGGBBAA` ordering. The
generator converts that trailing alpha to Qt's `#AARRGGBB` form and to CSS
`rgba()` values; object tokens with explicit `hex` and `alpha` remain supported.

Nested token groups are emitted as typed inline QML components. This keeps
`Theme.spacing.md`, `Theme.typography.body.size` and `Theme.layout.panel.height`
statically resolvable by `qmllint` instead of falling back to `QObject`.

### QML usage

```qml
// The relative path depends on the importing file (shell/pages -> ../styles).
import "../styles"

Rectangle {
    color: Theme.surface
    radius: Theme.scaled(Theme.radius.md)
    implicitHeight: Theme.scaled(Theme.layout.panel.height)
    border.width: Theme.scaled(Theme.borders.hairline)
    border.color: Theme.borderSubtle
}
```

- `Theme.scaled(value)` applies the user scale with two-decimal precision.
- `Theme.scaledInt(value)` is available for hairlines and pixel-snapped icons.
- `Theme.motionDuration(ms)` returns `0` when reduce motion is enabled.
- `Theme.layoutClass(width)` returns `compact`, `regular`, `wide` or
  `ultrawide`.
- The integration layer sets `Theme.themeName`, `Theme.scale` and
  `Theme.reduceMotion` from user settings. Pure components only read them.
- `shell/styles/qmldir` declares the `Klyvera.Styles` module for packaging.
  During development, components use a relative directory import so the preview
  harness works without installing Qt modules.

### Component preview

`preview/main.qml` renders the component library with mock data and no
Quickshell dependency. It is wrapped by a `QQuickView`, so it can be captured
offscreen:

```bash
python3 preview/render.py
```

The renderer writes `docs/screenshots/components-dark.png`,
`components-light.png` and `components-dialog.png`. It requires PySide6 and sets
`QT_QPA_PLATFORM=offscreen` and the software Qt Quick backend. The renderer is a
development tool; the screenshots are not a claim that the shell has run in a
Wayland session.

### CSS usage

```css
.card {
  background: var(--klyvera-color-surface);
  border: var(--klyvera-border-hairline) solid var(--klyvera-color-border-subtle);
  border-radius: var(--klyvera-radius-md);
  box-shadow: var(--klyvera-elevation-2);
  padding: calc(var(--klyvera-space-md) * var(--klyvera-scale));
}
```

Set `data-theme="light"` or `data-theme="high-contrast"` on the root element.
Dark is the default. `prefers-reduced-motion` disables durations automatically.

## Foundations

### Colour roles

| Role | Dark | Light | High contrast | Use |
| --- | --- | --- | --- | --- |
| `background` | `#0A0B10` | `#F7F8FB` | `#000000` | Window and page base |
| `surface` | `#151720` | `#FFFFFF` | `#0A0A0A` | Panel, card, field base |
| `surfaceRaised` | `#1A1D27` | `#FFFFFF` | `#141414` | Popovers, menus, dialogs |
| `surfaceHover` | `#1B1E29` | `#F0F2F8` | `#1F1F1F` | Hover state |
| `surfaceActive` | `#222633` | `#E7EAF2` | `#2A2A2A` | Pressed state |
| `surfaceSunken` | `#0E0F15` | `#EFF1F7` | `#000000` | Wells, code blocks |
| `textPrimary` | `#FAFAFA` | `#111318` | `#FFFFFF` | Primary text, icons |
| `textSecondary` | `#9BA1AC` | `#4B5260` | `#D6D6D6` | Supporting text |
| `textDisabled` | `#6B7180` | `#8A909C` | `#A3A3A3` | Disabled text (exempt) |
| `accentPurple` | `#8B7CFF` | `#5B4BE0` | `#C9BFFF` | Product accent, focus |
| `accentBlue` | `#3B82F6` | `#1D4ED8` | `#8AB4FF` | Informational, links |
| `accentMint` | `#5BE7D4` | `#067568` | `#7CF5E4` | Success, live status |
| `danger` | `#FF6B6B` | `#B42318` | `#FF9B9B` | Destructive, error |
| `warning` | `#F5B84B` | `#8A5A00` | `#FFD166` | Caution |
| `onAccent` | `#0A0B10` | `#FFFFFF` | `#000000` | Text/icons on accent fills |
| `borderSubtle` | white 8% | ink 10% | white 40% | Dividers, card edges |
| `borderStrong` | white 14% | ink 20% | white 75% | Inputs, selected edges |
| `focusRing` | `#A99FFF` | `#4A3ACB` | `#FFD166` | Keyboard focus indicator |
| `selection` | purple 28% | purple 16% | amber 35% | Text selection, drag range |

Rules:

- Use `textPrimary` for body text and `textSecondary` for supporting text only.
  Do not use `textSecondary` for essential values or errors.
- Accent fills always pair with `onAccent`. Never assume white is legible on an
  accent.
- Status colours always include a label or icon. Colour alone is not a message.
- Overlays use the `overlay` token; do not invent a new scrim opacity.

### Typography

| Token | Size / line | Weight | Use |
| --- | --- | --- | --- |
| `display` | 40 / 48 | 700 | Welcome and empty hero only |
| `heading1` | 32 / 40 | 700 | Page title |
| `heading2` | 24 / 32 | 700 | Section title |
| `heading3` | 20 / 28 | 600 | Panel title |
| `title` | 16 / 24 | 600 | Card and dialog title |
| `body` | 14 / 22 | 400 | Default text |
| `bodyStrong` | 14 / 22 | 600 | Values, emphasis |
| `caption` | 12 / 18 | 500 | Secondary metadata |
| `label` | 12 / 16 | 600 | Buttons, tabs, field labels |
| `mono` | 13 / 20 | 400 | Paths, commands, IDs |

Families: Manrope (headings), Inter (UI/body), monospace (code). Falls back to
the system stacks in the token file. Minimum body text is 14 token px; do not
shrink secondary text below 12.

### Spacing, radius and borders

Spacing is a 4 px base scale: `none 0`, `xxs 4`, `xs 8`, `sm 12`, `md 16`,
`lg 24`, `xl 32`, `xxl 48`, `xxxl 64`, `huge 96`.

Radius: `none 0`, `xs 4`, `sm 6`, `md 10`, `lg 14`, `xl 20`, `full 9999`.
Use `md` for cards and fields, `sm` for small controls, `lg` for dialogs and
`full` only for pills and avatars.

Borders: `hairline 1`, `strong 2`, `focus 2`. Borders are always scaled and
never used as the only state indicator.

Elevation is restrained: level 1 for menus, level 2 for popovers and dialogs,
level 3 for the launcher. Cards are not elevated by default; they use a border.

### Icons

Klyvera Line, original Canvas glyphs, stroke width 1.75, sizes `sm 16`, `md 20`,
`lg 24`, `xl 32`. The names follow common line-icon vocabulary but no third-party
icon files or path data are vendored. Icons are optically aligned to text and
never stretched. An icon-only control needs an accessible name and a tooltip. Do
not mix filled and outlined sets.

## Component inventory

Phase 3 implements these in `shell/ui/` as pure QML. The rules below are the
contract; deviations need a design decision.

| Component | Purpose |
| --- | --- |
| `Panel` | Top-level bar surface; one per output |
| `WorkspaceIndicator` | Hyprland workspace state, keyboard accessible |
| `Clock` | Date and time, locale-aware |
| `SystemIndicators` | Compact status cluster (network, audio, battery) |
| `Button` | Text or text+icon action |
| `IconButton` | Square icon-only action with accessible name |
| `TextField` | Single-line input with label, helper and error |
| `SearchField` | Launcher/search input with leading icon and clear action |
| `ListItem` | Selectable row with icon, title, description, trailing slot |
| `Card` | Grouped content surface with optional action |
| `Toggle` | Binary switch with label |
| `Slider` | Bounded numeric input with keyboard stepping |
| `Tabs` | Mutually exclusive views, roving focus |
| `Dialog` | Modal surface with title, content and actions |
| `ConfirmDialog` | Destructive confirmation with explicit verb |
| `Toast` | Transient, non-blocking status with optional action |
| `Tooltip` | Supplementary label on hover/focus |
| `EmptyState` | Explains why a surface is empty and what to do |
| `ErrorState` | Explains failure, preserves context, offers retry |
| `Skeleton` | Loading placeholder with reduced-motion alternative |

### States

Every interactive component supports the states that apply to it:

| State | Treatment |
| --- | --- |
| Normal | `surface` / `textPrimary`; borderSubtle where a boundary is needed |
| Hover | `surfaceHover`; no size change; cursor only for pointer users |
| Focus | 2 px `focusRing` outline, 2 px offset, always visible on keyboard focus; never remove without replacement |
| Pressed | `surfaceActive`; instant visual response; no bounce |
| Disabled | `textDisabled`, no pointer events, `accessibleName` retained; explain why nearby when not obvious |
| Loading | Preserve the control's width; show a progress or skeleton; disable repeat actions |
| Error | `danger` text/icon plus a specific message; keep entered data; never clear the field |

Component-specific rules:

- **Button:** default height derives from `preferredTargetSize`; label in
  `label` token; primary uses `accentPurple` with `onAccent`; destructive uses
  `danger` with `onAccent`. Loading keeps the label but disables activation.
- **IconButton:** square, at least `minimumTargetSize`; icon centred; required
  `accessibleName`.
- **TextField/SearchField:** label above, helper below, error replaces helper
  with `danger`; focus ring around the field, not only the caret. Search clears
  with Escape and exposes the clear action as a button.
- **ListItem:** full row is one target; selected state uses `selection` plus a
  visible marker; hover must not shift content. Multi-select is explicit.
- **Toggle:** the whole label is clickable; state is announced as checked, not by
  colour alone. Space toggles.
- **Slider:** arrow keys step, Page Up/Down for larger steps, Home/End for
  bounds; the value is shown as text.
- **Tabs:** arrow keys move between tabs; `aria`-equivalent role/name exposed
  where Qt supports it; selected tab has both colour and an underline.
- **Dialog/ConfirmDialog:** focus is trapped while open, Escape closes unless an
  operation is in progress, initial focus goes to the title or least destructive
  action. ConfirmDialog names the consequence and uses a verb as the action
  label ("Delete Space"), not "OK".
- **Toast/Tooltip:** never the only place important information appears. Toasts
  are announced; tooltips appear on focus as well as hover.
- **EmptyState/ErrorState:** include an icon, one-sentence explanation and at
  most two actions. ErrorState never blames the user.
- **Skeleton:** static block with a slow opacity pulse; with reduce motion it is
  static. Do not fake content with skeleton text.

## Motion

| Token | Value | Use |
| --- | --- | --- |
| `instant` | 0 ms | State that must not lag input |
| `fast` | 120 ms | Hover, focus, toggle, small fades |
| `normal` | 200 ms | Menus, dialogs, expand/collapse |
| `slow` | 320 ms | Launcher and large surface transitions |

Easing: `standard` `cubic-bezier(0.2, 0, 0, 1)`, `decelerate`
`cubic-bezier(0, 0, 0, 1)`, `accelerate` `cubic-bezier(0.3, 0, 1, 1)`.
Animate opacity and transform; avoid animating layout dimensions that force
reflow in the shell. Never flash, loop decoratively or animate on every data
tick.

**Reduce motion:** the setting is exposed as `Theme.reduceMotion` and via
`prefers-reduced-motion` on the web. All durations become zero; transitions are
instant. Loading indicators may still communicate state but must not pulse.

## Responsive rules

| Class | Logical width | Primary adjustments |
| --- | --- | --- |
| `compact` | `< 1280` | Slimmer panel, narrower launcher and control center, single-column Spaces lists, shortened labels with tooltips |
| `regular` | `1280–1919` | Default layout |
| `wide` | `1920–2559` | Wider launcher and control center, two-column Spaces grid |
| `ultrawide` | `>= 2560` | Maximum content widths, more breathing room, no stretched text lines |

Rules:

- Sizes derive from tokens multiplied by the user scale. Layout class is chosen
  from the logical width of the output, not physical pixels.
- The panel is instantiated per output. On a portrait monitor the panel remains
  horizontal and compacts; content never assumes landscape.
- Launcher and control center clamp width to the output width minus the gutter;
  they scroll inside their own content area rather than clipping. Maximum height
  uses the token ratio.
- Text wraps before it truncates; truncation only for single-line identifiers
  with a tooltip and accessible full value.
- Fractional scaling: use `Theme.scaled()`; hairlines use `scaledInt()` and may
  round to 1 px. Verify at 1.25, 1.5 and 2.0 on target.
- Keyboard focus must remain visible after reflow; scroll the focused item into
  view.

## Accessibility

- **Contrast:** all required text and focus-indicator pairs pass WCAG AA. See
  `docs/contrast-report.md` for measured ratios in all themes. Disabled text is
  exempt and labelled as such.
- **Keyboard:** every action reachable without a pointer; Tab order follows
  visual order; Escape closes transient surfaces; arrow keys for roving focus in
  lists, tabs and sliders; focus is trapped only in modal dialogs.
- **Focus:** 2 px `focusRing` with a 2 px offset. Focus is never indicated by
  colour alone and never hidden because of a mouse interaction.
- **Targets:** at least 24×24 token px, preferably 44×44 for primary actions.
- **Labels:** icon buttons need an accessible name. Fields need a persistent
  label, not only a placeholder. Errors are announced where Qt exposes it.
- **Text scaling:** layouts reflow at 200% text size without clipping; avoid
  fixed heights around text.
- **Motion and sound:** respect reduce motion; no essential information is
  conveyed by sound alone.

## Writing in components

- Labels are sentence case and verbs: "Open Space", "Choose folder", "Retry".
- Empty states explain the next action in one sentence.
- Errors name the object and the recovery: "The project folder no longer exists.
  Choose another folder."
- Avoid jargon in destructive confirmations; state exactly what will be deleted
  and whether it can be undone.

## Contributing to the system

1. Change `design/tokens.json`, not generated files.
2. Run the generator and `./scripts/check.sh`.
3. Update this document if a rule changes.
4. Add a decision record for a new component family, icon set or font.
