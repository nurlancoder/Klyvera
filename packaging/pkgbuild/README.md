# PKGBUILDs

The three packages share one source archive created from the current Git commit.
The prototype uses `sha256sums=('SKIP')`; release packages must replace this with
real checksums from `updpkgsums`.

## Build on Arch

```bash
sudo pacman -S --needed base-devel git rust
./packaging/pkgbuild/build-packages.sh
```

The script refuses a dirty Git tree, creates
`packaging/pkgbuild/sources/klyvera-0.1.0.tar.gz`, builds all three packages in
`--nodeps --nocheck` mode and creates a local repository in
`packaging/pkgbuild/out/`. It was exercised in an official Arch container.

`--nodeps` is intentional for the build host: `klyvera-shell` depends on
Quickshell, which is in Arch `extra`. Installation on a real system still
resolves dependencies through pacman.

`klyvera-shell` installs the Quickshell tree under `/usr/share/klyvera/shell`
and does **not** write into any user's home directory. Run
`klyvera-shell-setup` as the target user.
