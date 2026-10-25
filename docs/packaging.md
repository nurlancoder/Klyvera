# Packaging and live image

Klyvera targets Arch Linux. Packages are built and inspected in an official Arch
container; installation, `mkarchiso`, ISO boot and the live session remain
**UNVERIFIED-ON-TARGET**.

## Packages

| Package | Contents |
| --- | --- |
| `klyvera-core` | `/usr/bin/klyvera`, `/usr/bin/klyvera-daemon`, systemd user unit, license and docs |
| `klyvera-shell` | `/usr/share/klyvera/shell`, Hyprland fragment, desktop entry, `klyvera-shell-setup` |
| `klyvera-meta` | Shell, core and desktop runtime dependencies |

The shell package never writes to a home directory. `klyvera-shell-setup`
creates only one symlink:

```
${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/klyvera
  -> /usr/share/klyvera/shell/integration/quickshell
```

It refuses to overwrite an existing path.

## Package build

`packaging/pkgbuild/build-packages.sh`:

- requires a clean Git tree and Arch tools (`makepkg`, `repo-add`);
- installs only declared files and uses `options=('!debug')` for the core;
- reads the version from `core/Cargo.toml` and checks each `pkgver`;
- creates a deterministic-prefix archive from `HEAD`;
- builds all three packages; the core package contains both release binaries;
- creates a local pacman repository.

The prototype PKGBUILDs use `sha256sums=('SKIP')`. Release builds must replace
that with `updpkgsums` output and sign packages before any public repository is
published.

## Verification run

On 2026-10-25, `packaging/pkgbuild/build-packages.sh` ran as an unprivileged user
inside `archlinux:latest` with `base-devel`, `git` and `rust`:

- `klyvera-core-0.1.0-1-x86_64.pkg.tar.zst`
- `klyvera-shell-0.1.0-1-any.pkg.tar.zst`
- `klyvera-meta-0.1.0-1-any.pkg.tar.zst`
- `klyvera-local.db.tar.gz` and `.files.tar.gz`

`namcap` reported no errors. Its warnings were limited to QML module visibility
(Quickshell and Qt modules are not installed during `--nodeps` builds),
potentially unneeded core dependencies (`gcc-libs`, `systemd`) and the empty meta
package's declared dependencies. `bsdtar` confirmed the expected file lists.
`pacman -Si` confirmed Quickshell, Hyprland, archiso and archinstall are in the
Arch repositories used for the test.

A smoke install used `pacman -U --nodeps` for all three packages in the same
container. `klyvera --version`, `klyvera doctor --json`,
`klyvera-shell-setup` and `systemd-analyze verify` on the user unit passed.
This does not prove dependency-resolved installation or runtime behavior on a
target. `mkarchiso` was not run.

## Daemon

`packaging/systemd/klyvera-daemon.service` runs as a user service with:

- no new privileges, a private `/tmp`, a strict read-only system and home;
- write access limited to `~/.config/klyvera`, `~/.local/share/klyvera` and
  `$XDG_RUNTIME_DIR/klyvera`;
- only Unix sockets, no network address family;
- `UMask=0077`, which matches the core's `0700`/`0600` file policy.

The unit has not been started on a systemd target.

## Live ISO

The archiso profile:

- installs `klyvera-meta` from `/var/cache/klyvera/localrepo`;
- creates a live `klyvera` user with passwordless sudo, only in the live image;
- autologins on tty1 and starts Hyprland;
- links the packaged Quickshell tree into the live user's config;
- launches `archinstall` from `Super + I`;
- enables NetworkManager and Bluetooth.

Build:

```bash
./packaging/pkgbuild/build-packages.sh
sudo ./packaging/archiso/build.sh
```

Outputs land in `packaging/archiso/out/` with a SHA-256 file. The local
repository is unsigned and uses `TrustAll`; this is prototype-only and must be
replaced before distribution.

## Upgrade and rollback

- Packages are versioned together; `klyvera-meta` pins the core and shell
  versions.
- Configuration is migrated by the core's versioned config loader before writes.
- Space imports are validated and untrusted commands require a hash-bound trust
  entry.
- Backups are created before restore; the last pre-restore backup is retained.

## Unverified

- `mkarchiso` execution and ISO build.
- Dependency-resolved package installation, conflicts with real repositories,
  systemd user unit startup and service sandbox behavior.
- Live ISO boot, autologin, Hyprland startup, font/GPU support, installer launch,
  offline local repository access and audio.
- Fully offline target installation; the image carries Klyvera packages but not
  every dependency.
- Package signing, keyring distribution and reproducible builds.
