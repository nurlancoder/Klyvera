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

Nothing here has been built with `makepkg` or `mkarchiso` on the Debian
development host. Treat all package and ISO claims as **UNVERIFIED-ON-TARGET**
until the commands in `docs/packaging.md` are run on Arch.
