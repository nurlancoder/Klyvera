# Phase 1 — Design system

Goal: one token source that produces the QML theme and the web CSS, with verified
contrast, documented component states, motion and responsive rules.

## Steps

- [x] Write `design/tokens.json`: dark, light and high-contrast palettes;
      spacing, radius, border, elevation, typography, motion, icon, layout and
      accessibility tokens.
- [x] Write `design/generators/generate.py` with `--check`, deterministic output
      and a WCAG contrast report.
- [x] Generate `shell/styles/Theme.qml`, `shell/styles/qmldir`,
      `web/src/styles/tokens.css` and `docs/contrast-report.md`.
- [x] Verify every required text and focus-indicator contrast pair passes WCAG
      AA in all three themes.
- [x] Document foundations, component states, motion, responsive behaviour,
      accessibility and brand direction in `docs/design-system.md` and
      `design/brand.md`.
- [x] Run `./scripts/check.sh` and the generator check; record results.

## Exit criteria

- Changing a token and running the generator updates QML and CSS consistently.
- `python3 design/generators/generate.py --check` fails on drift and on contrast
  regressions.
- No component sizes are hard-coded: the layout and spacing scales are complete
  enough for Phase 3.
- The design system documents all required component states and the four layout
  classes.

## Notes

`qmllint` and a QML runtime are not installed on the development workstation, so
the generated `Theme.qml` is reviewed manually but not linted here. The CI QML
job covers linting once the Qt tooling is available.
