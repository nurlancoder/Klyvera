# Packaging

Klyvera ships as three Arch packages and a live ISO profile.

| Path | Purpose |
| --- | --- |
| `pkgbuild/klyvera-core/` | Rust daemon and CLI, systemd user unit |
| `pkgbuild/klyvera-shell/` | pure QML, Quickshell adapter, Hyprland fragment, setup command |
| `pkgbuild/klyvera-meta/` | desktop dependency set |
| `systemd/` | user unit source copied by `klyvera-core` |
| `desktop/` | desktop entry copied by `klyvera-shell` |
| `scripts/` | per-user setup helper copied by `klyvera-shell` |
| `config/hypr/` | includeable Hyprland fragment and keybindings |
| `archiso/` | live ISO profile and build script |
| `installer/` | installer decision and post-install steps |

The packages were built with `makepkg` in an official Arch container and
inspected with `namcap`; `mkarchiso` and installation were not run. Treat ISO,
install and live-session claims as **UNVERIFIED-ON-TARGET** until the commands in
`docs/packaging.md` are run on an Arch target.
