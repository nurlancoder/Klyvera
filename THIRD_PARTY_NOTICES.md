# Third-party notices

Klyvera is original work, but it depends on and interoperates with third-party
software. This file records direct dependencies, assets and fonts, their
licenses, and whether the license text is bundled.

No third-party source code or visual assets are currently vendored in this
repository. Entries marked **planned** are not yet shipped. Verify exact versions
and license texts before the first release.

## Planned runtime dependencies

| Component | Use | License | Status |
| --- | --- | --- | --- |
| Qt 6 (Qt Quick, Qt QML, Qt Core) | QML runtime for the shell | LGPL-3.0-only (dynamic linking intended) | planned |
| Quickshell | Wayland shell toolkit | MIT | planned |
| Hyprland | Wayland compositor | BSD-3-Clause | planned |
| Hyprland IPC | compositor control protocol | BSD-3-Clause | planned |

Qt is intended to be dynamically linked. Any static linking or Qt module with a
different license requires a decision record and a license review.

## Planned Rust crates

The core workspace will keep the dependency set small. Each crate's license is
checked when it is added and recorded here.

| Crate | Use | License | Status |
| --- | --- | --- | --- |
| `serde` / `serde_json` | JSON serialization | MIT OR Apache-2.0 | planned |
| `thiserror` | Typed error definitions | MIT OR Apache-2.0 | planned |
| `clap` | CLI parsing | MIT OR Apache-2.0 | planned |
| `sha2` | Profile hashing and integrity | MIT OR Apache-2.0 | planned |
| `tar` | Backup archives | MIT OR Apache-2.0 | planned |
| `flate2` | Compressed backups | MIT OR Apache-2.0 | planned |
| `tempfile` | Atomic write tests | MIT OR Apache-2.0 | planned |
| `libc` | Unix permissions and sockets | MIT OR Apache-2.0 | planned |

## Planned web dependencies

| Component | Use | License | Status |
| --- | --- | --- | --- |
| Vite | Static site build | MIT | planned |
| TypeScript | Type safety | Apache-2.0 | planned |

## Fonts

Manrope and Inter are planned for the product under the SIL Open Font License
1.1. They are **not bundled** in this repository yet. If bundled, the OFL text
and reserved font names will be included, and the fonts will not be sold on their
own.

## Icons

The planned icon set is Lucide, licensed under the ISC license, used at a uniform
stroke width. No icon files are vendored yet. Any icon added must be recorded
here with its source and license.

## Development-only tools

These tools are used to build and test Klyvera and are not distributed with it:
Rust toolchain (MIT/Apache-2.0), Cargo tools, Node.js (MIT), npm (Artistic-2.0),
Python (PSF-2.0), shellcheck (GPL-3.0), qmllint from Qt (LGPL-3.0/GPL-3.0).

## Attribution

Klyvera is independent and is not affiliated with Arch Linux, Hyprland,
Quickshell, or the Qt Company. See `docs/CREDITS.md`.
