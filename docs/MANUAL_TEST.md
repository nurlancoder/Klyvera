# Manual test checklist

This checklist is for the maintainer and for anyone evaluating a Klyvera build.
It separates checks that can run on the Debian-based development workstation
from checks that require the Arch target. Do not mark a target item as passed
from a container or an offscreen render.

Record the date, commit, environment and exact commands with each run. A checked
box without evidence is not a verification.

## Safety rules

- Never run Klyvera as root. The CLI, daemon and shell are user-session software.
- Use a disposable XDG home or a test account for destructive backup/restore
  checks.
- Do not run `mkarchiso`, package installation or installer tests on a production
  workstation.
- Do not execute commands from a profile you have not reviewed.
- Do not publish a package, ISO or site from a dirty tree.

## 1. Local automated checks

Run from the repository root:

```bash
./scripts/check.sh
```

Expected: the summary reports `0 failure(s)` and lists every skipped check with a
reason. Skips caused by missing local Qt, shellcheck, browser or schema tooling
are acceptable only if CI covers them.

Run the individual checks when a failure needs isolating:

```bash
cd core
cargo fmt --all --check
cargo clippy --all-targets -- -D warnings
cargo test --all
```

```bash
python3 design/generators/generate.py --check
python3 tests/validate_schemas.py
bash -n scripts/*.sh .githooks/*
shellcheck scripts/*.sh .githooks/*
```

```bash
cd web
npm ci
npm run build
npm run check
```

Expected: 75 Rust tests pass, generated tokens are in sync, schema checks pass,
static site checks pass and the web build completes.

## 2. Website visual and keyboard review

Start the preview server:

```bash
cd web
npm run preview -- --host 127.0.0.1 --port 4173
```

Open `http://127.0.0.1:4173/`, `/az/` and `/docs/` in a browser. Check every item
at 320, 375, 768, 1024, 1440 and 1920 px wide:

- [ ] No horizontal scrolling, clipped text, overlapping panels or cut-off focus
      rings.
- [ ] The hero title wraps or scales without colliding with the screenshot.
- [ ] Navigation changes to the menu below 900 px and returns above it.
- [ ] The mobile menu opens, traps focus, closes with Escape and returns focus to
      the menu button.
- [ ] The theme control cycles dark → light → high contrast → dark and the choice
      survives a reload.
- [ ] Both landing pages have equivalent structure and correct `lang` metadata.
- [ ] Links underline on hover and show a visible focus ring.
- [ ] Skip-to-content works with a keyboard.
- [ ] Long code blocks and tables scroll without widening the page.
- [ ] The rendered screenshots look intentionally composed and are labelled as
      previews.
- [ ] No external font, tracker, broken image or unexpected network request
      appears in the browser network panel.
- [ ] With JavaScript disabled, headings, prose, links, navigation and the
      language switch remain readable.

Install the browser once, then run the automated checks while the preview is
running:

```bash
cd web
npx playwright install chromium
BASE_URL=http://127.0.0.1:4173 npm run test:browser
```

With system Chromium and no display server:

```bash
cd web
CHROMIUM_PATH=/usr/bin/chromium env -u DISPLAY -u WAYLAND_DISPLAY npm run test:browser
```

For the Pages base, rebuild with `--base=/Klyvera/`, start `vite preview` with
the same base and set `BASE_URL=http://127.0.0.1:4173/Klyvera`.

## 3. Website deployment review

- [ ] Confirm GitHub Pages is configured to deploy from **GitHub Actions**.
- [ ] Push a commit or run the Pages workflow manually.
- [ ] Confirm the build job installs dependencies, builds with the repository
      base path and passes static checks.
- [ ] Open the deployed project URL and repeat the visual, keyboard, theme and
      mobile checks.
- [ ] Confirm the sitemap, canonical links, manifest and Open Graph image resolve
      under the deployed base path.
- [ ] Record the workflow URL and live URL in `docs/STATUS.md`.

Until this section has run, deployment is **UNVERIFIED**.

## 4. Core CLI with isolated state

Build the workspace binaries and use a temporary XDG environment:

```bash
cargo build --workspace
export PATH="$PWD/core/target/debug:$PATH"
tmp="$(mktemp -d)"
export XDG_CONFIG_HOME="$tmp/config"
export XDG_DATA_HOME="$tmp/data"
export XDG_RUNTIME_DIR="$tmp/run"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
```

Check:

- [ ] `klyvera --version` succeeds.
- [ ] `klyvera doctor --json` reports the isolated paths and no unexpected
      warnings.
- [ ] Runtime directories are `0700` and sensitive files are `0600`.
- [ ] `klyvera spaces new` rejects a missing project path.
- [ ] A Space with an argv command is created and listed.
- [ ] A shell-interpreter command is rejected.
- [ ] A command working directory containing `..` or leaving the project root is
      rejected.
- [ ] `klyvera spaces open <id> --dry-run` prints argv and no shell string.
- [ ] An untrusted imported command cannot launch.
- [ ] Trusting the exact profile hash allows the command; editing the profile
      invalidates trust.
- [ ] `klyvera backup` creates a manifest-covered archive.
- [ ] `klyvera verify` accepts the archive and rejects a corrupted copy.
- [ ] `klyvera restore` without `--yes` is refused.
- [ ] Restore with `--yes` creates a pre-restore backup and does not accept a
      traversal name.
- [ ] `klyvera-daemon` starts, the socket is `0600`, a normal request succeeds
      and a malformed frame is rejected without terminating the daemon.

Clean up only the temporary directory you created:

```bash
unset XDG_CONFIG_HOME XDG_DATA_HOME XDG_RUNTIME_DIR
rm -rf "$tmp"
```

## 5. QML and shell surfaces

Offscreen local checks:

- [ ] `qmllint` passes over the pure QML tree with only documented singleton
      warnings.
- [ ] `python3 tests/qml/dialog_focus.py` passes.
- [ ] `python3 tests/qml/pages_behavior.py` passes.
- [ ] `python3 preview/render.py` and `python3 preview/render_pages.py` produce
      non-empty images and no component has zero size.

Target session checks:

- [ ] Quickshell starts from the packaged entry point with no QML import errors.
- [ ] Panel, launcher, control center, notification center, system monitor, lock
      screen, session menu and welcome open on the intended monitor.
- [ ] Keyboard navigation works for every surface; Escape closes overlays.
- [ ] Workspace indicators follow Hyprland workspace changes.
- [ ] Audio, network, Bluetooth, display, battery and power failures show
      degraded states rather than fake values.
- [ ] Lock screen cannot be bypassed with the test keybindings.
- [ ] The daemon socket connects from the shell and the UI updates after a Space
      change.
- [ ] Import/export and command trust prompts work with the real filesystem.

## 6. Packaging on the target

Run only on an Arch evaluation machine:

- [ ] Build packages with `packaging/pkgbuild/build-packages.sh` from a clean
      tree.
- [ ] Inspect package contents with `bsdtar`; no build files, secrets or local
      paths are present.
- [ ] `namcap` findings are reviewed and either fixed or documented.
- [ ] Replace `SKIP` checksums with real values before any public distribution.
- [ ] Install through a dependency-resolved pacman transaction, not `--nodeps`.
- [ ] `klyvera --version`, `klyvera doctor --json` and
      `systemctl --user status klyvera-daemon` succeed.
- [ ] `klyvera-shell-setup` creates only the documented Quickshell symlink and
      refuses to overwrite an existing path.
- [ ] Logout/login starts the user service without manual intervention.
- [ ] Remove the packages and confirm they leave no executable binaries, units or
      shell files behind.

## 7. ISO and installer

Run this section in a disposable VM, never on a workstation disk:

- [ ] `packaging/pkgbuild/build-packages.sh` succeeds.
- [ ] `sudo ./packaging/archiso/build.sh` succeeds and produces an ISO plus the
      recorded SHA-256.
- [ ] The ISO boots to the live session with networking available.
- [ ] The live user does not expose a persistent account or reusable password.
- [ ] Hyprland starts, the Klyvera shell loads and the live system powers off
      cleanly.
- [ ] `archinstall` launches from the documented keybinding.
- [ ] A fully offline install works; otherwise record the network dependency.
- [ ] The installed system boots, the user service starts and the shell launches.
- [ ] Package signatures or a documented keyring are verified; until then, do not
      distribute the image.
- [ ] The ISO checksum matches the published value.

## 8. Release evidence

For each release candidate, record:

- Commit SHA and version.
- Host distribution, kernel, Rust, Node and Arch container versions.
- Exact commands and exit status.
- Test counts and skipped checks.
- Known **UNVERIFIED-ON-TARGET** items.
- Package and ISO SHA-256 values.
- Website workflow and live URL, once available.
- Any deviation from this checklist.

A release is not ready when any mandatory target item is unchecked, when package
signing is absent, or when the website workflow has not deployed successfully.
