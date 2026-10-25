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

`quickshell`, `hyprland` and the Klyvera packages must be available from the
configured repositories. If Quickshell is not in the official repositories, build
it from AUR into the local repository first; the profile will fail the package
resolution step otherwise.

## Test

On an Arch host with KVM:

```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 2 \
  -drive file=packaging/archiso/out/klyvera-0.1.0-x86_64.iso,media=cdrom,readonly=on \
  -boot d
```

The profile and ISO have not been built or booted on target hardware. Network
firmware, GPU acceleration, autologin, installer launch and audio are all
unverified.
