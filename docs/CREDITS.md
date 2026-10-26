# Credits

Klyvera is an independent project. It is not affiliated with, endorsed by, or
sponsored by any of the projects listed here.

## Upstream platforms

- **Arch Linux** — the target distribution and packaging conventions.
  <https://archlinux.org/>
- **Hyprland** — the Wayland compositor Klyvera integrates with.
  <https://hyprland.org/>
- **Quickshell** — the Qt Quick shell toolkit used by the integration layer.
  <https://quickshell.org/>
- **Qt / Qt Quick** — the UI runtime. <https://www.qt.io/>

## Fonts

- **Inter** by Rasmus Andersson, SIL Open Font License 1.1.
- **Manrope** by Mikhail Sharanda, SIL Open Font License 1.1.

The fonts are planned, not yet bundled.

## Icons

The Klyvera Line icon set is original project artwork. Its SVG sources are
listed in `design/icons/manifest.json` and loaded through the generated QML icon
catalog; the Canvas renderer remains for dynamic and fallback glyphs. Names
follow common line-icon vocabulary; no third-party icon files or path data are
used. The per-asset manifest records the provisional project-license status
without treating it as a final license decision.

## Development tools

Rust, Cargo, Node.js, npm, Python, shellcheck, Git and GitHub Actions make this
project possible. Their licenses are recorded in `THIRD_PARTY_NOTICES.md`.

## Design statement

All Klyvera visual design, QML components, Rust code, documentation and copy are
original. General desktop conventions (panels, launchers, control centers) are
shared vocabulary, not copied implementations. No code, configuration or assets
from Omarchy, HyDE, ML4W, Dank Linux, end-4, or similar projects are used.
