# Installer

The prototype ISO uses interactive `archinstall` (decision 0003). Start it from
the live session with `Super + I` or by running `archinstall` in `foot`.

After the installed system boots:

1. Install `klyvera-meta` from the Klyvera local repository or a published
   package repository. The live image carries the package files at
   `/usr/share/klyvera/repo/x86_64` and a pacman config at
   `/etc/pacman.d/klyvera-local.conf`; dependencies still come from the target
   repositories unless they are preinstalled or cached.
2. Run `klyvera-shell-setup` as the user.
3. Add the printed include to `~/.config/hypr/hyprland.conf`:
   `source = /etc/xdg/klyvera/hypr/klyvera.conf`
4. Enable the user daemon:
   `systemctl --user enable --now klyvera-daemon`
5. Log out and back in, or start `qs -c klyvera`.

The ISO does not yet ship a branded graphical installer or an automated
post-install hook. This is prototype scope, not a finished consumer install
experience.
