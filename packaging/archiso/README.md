# Live ISO

The profile in `profile/` builds a Klyvera live image with:

- a `klyvera` live user with passwordless sudo (live image only);
- autologin on tty1 and Hyprland on Wayland;
- the packaged Klyvera shell, daemon and the `archinstall` installer;
- an offline local repository at `/var/cache/klyvera/localrepo` for the build;
- a copy of the Klyvera packages at `/usr/share/klyvera/repo/x86_64` inside the
  live image.

## Build on Arch

```bash
sudo pacman -S --needed archiso
./packaging/pkgbuild/build-packages.sh
sudo KLYVERA_PACKAGE_OUT="$PWD/packaging/pkgbuild/out" \
  ./packaging/archiso/build.sh
```

The ISO and its `.sha256` are written to `packaging/archiso/out/`. The build
script requires root because `mkarchiso` needs loop devices and a chroot.

`quickshell` (0.3.2 at the time of the packaging test), `hyprland`, `archiso`
and `archinstall` were confirmed in the Arch `extra` repository. The package set
is explicit but not version-pinned because Arch repositories are rolling.

The profile and ISO have not been built. The live image carries the Klyvera
packages at `/usr/share/klyvera/repo`, but a fully offline target install also
needs the non-Klyvera dependency packages; `archinstall` otherwise resolves them
from the network.

## Test

On an Arch host with KVM:

```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 \
  -drive file=packaging/archiso/out/klyvera-0.1.0-x86_64.iso,media=cdrom,readonly=on \
  -boot d
```

The profile and ISO have not been built or booted. Network firmware, GPU
acceleration, autologin, installer launch, audio and offline installation are all
unverified.
