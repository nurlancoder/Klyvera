# Troubleshooting

Start with the evidence, not with a workaround:

```bash
git rev-parse --short HEAD
klyvera --version
klyvera doctor --json
klyvera status --json
```

On the target, also collect the user unit state:

```bash
systemctl --user status klyvera-daemon --no-pager
journalctl --user -u klyvera-daemon -n 100 --no-pager
```

Do not disable permissions, trust checks, the daemon sandbox or signatures to
make an error disappear. Record the failing command and the exact error instead.

## Development workstation

### Qt or `qmllint` is missing

The Debian workstation does not provide the full target toolchain. `scripts/check.sh`
skips QML lint and offscreen QML tests when PySide6 or `qmllint` is absent. CI
installs its own Qt packages. Do not treat a local skip as a pass.

To run the offscreen checks locally, use a temporary user-level environment such
as the one documented in `docs/design-system.md`. Do not install system packages
without maintainer approval.

### Shellcheck is missing

`scripts/check.sh` reports a skip. The CI `scripts` job installs shellcheck. A
clean local checkout is not a complete substitute for CI.

### Token check fails

```bash
python3 design/generators/generate.py --check
```

If generated files drift, run the generator once and review the diff. Never edit
generated `Theme.qml`, `tokens.css` or `docs/contrast-report.md` by hand.

### Schema checks are skipped

Install `jsonschema` in a temporary Python environment, then run:

```bash
python3 tests/validate_schemas.py
```

### Website build fails

Check the Node version:

```bash
node --version
npm --version
```

Use Node.js 20.19+ or 22.12+. Remove only the local install output if a stale
lockfile or dependency tree is suspected:

```bash
cd web
rm -rf node_modules dist
npm ci
npm run build
```

If `npm run build` passes but assets 404 in preview, the build base and preview
base do not match. Rebuild with the same base used by `vite preview`:

```bash
npm run build -- --base=/Klyvera/
npm run preview -- --base=/Klyvera/
```

The base must end with `/`.

### Browser checks cannot launch Chromium

Playwright's downloaded browser is the CI default. If it is not installed:

```bash
cd web
npx playwright install chromium
```

On a workstation with system Chromium, an unset display server and no usable
GPU, launch the system binary directly:

```bash
cd web
CHROMIUM_PATH=/usr/bin/chromium env -u DISPLAY -u WAYLAND_DISPLAY npm run test:browser
```

The preview server must already be running. If navigation hangs, confirm the
preview is serving the same base path that was used for the build.

### Theme does not persist

The site stores the choice under `klyvera-theme` in `localStorage`. Private
windows, blocked storage or a different origin reset it. Do not replace the
storage check with a cookie; the site has no server.

## CLI and daemon

### `klyvera doctor` warns about paths

Klyvera uses `XDG_CONFIG_HOME`, `XDG_DATA_HOME` and `XDG_RUNTIME_DIR`. If they are
unset in a test shell, the default home paths are used. For isolated testing,
create a temporary runtime directory with mode `0700`:

```bash
tmp="$(mktemp -d)"
export XDG_CONFIG_HOME="$tmp/config"
export XDG_DATA_HOME="$tmp/data"
export XDG_RUNTIME_DIR="$tmp/run"
mkdir -p "$XDG_RUNTIME_DIR"
chmod 700 "$XDG_RUNTIME_DIR"
```

Do not use `chmod 777` or run the CLI with `sudo`.

### Permission denied on the socket

The daemon socket must live under `XDG_RUNTIME_DIR`, be owned by the current
user and use mode `0600`. Check the paths reported by `klyvera doctor` and the
user unit environment. Do not point `XDG_RUNTIME_DIR` at a shared world-writable
directory.

A stale socket after an unclean shutdown is recovered by the daemon. If recovery
fails, stop the user service and inspect the directory before removing anything.
Only remove a socket that is actually stale and inside your own runtime
directory.

### Imported command is refused

This is expected until the exact profile hash is trusted. Review the argv, working
directory and project path first:

```bash
klyvera spaces show <id> --json
```

Trust the reviewed hash through the CLI or UI. Editing the profile changes its
hash and invalidates the record. Do not bypass trust by editing state files.

### Space open fails

- The project root must exist and be a directory.
- The working directory must remain inside the project and cannot contain `..`.
- Commands use argv arrays; shell strings and shell interpreters are rejected.
- Imported files are untrusted until reviewed.
- A dry run shows the planned argv without launching it.

### Backup restore is refused

Restore requires `--yes`. Without it, the CLI must reject the operation. Before
confirming, verify the archive:

```bash
klyvera verify <archive>
```

Restore uses a staging area and creates a pre-restore backup. A manifest mismatch,
unsafe path, expired archive or size violation is a hard failure; do not extract
the archive by hand into the live configuration.

### Daemon exits immediately

Inspect the user journal. Common causes are an unavailable runtime directory, an
existing non-socket path at the socket location, or a unit sandbox that prevents
writing to the configured state directory. Fix the path or permissions; do not
remove `NoNewPrivileges`, `PrivateTmp` or the read-only restrictions to hide the
problem.

## Target Session

### Quickshell does not start

Check that the package is installed and the expected entry point exists:

```bash
command -v qs
test -d /usr/share/klyvera/shell
```

Run `qmllint` against the packaged tree and inspect the Quickshell output for the
first missing module. Target-only adapters are excluded from local lint because
their modules are unavailable on the Debian workstation.

### The shell loads but services are empty

A degraded control center is intentional when a service probe fails. Check the
service directly and the daemon journal. Do not replace a failure with mock data
in a live session.

### Hyprland keybindings do not work

Confirm the Klyvera fragment is included exactly once and that `qs` is on the
session `PATH`. Check for conflicting binds before changing them. The fragment
has not been validated in a live Hyprland session.

### Session lock cannot be tested

Do not test lock-screen behaviour on a machine holding unsaved work. Use a
disposable VM or test account. If the compositor lock protocol or session-lock
wiring is missing, record it as unverified rather than adding a fake lock surface.

## Packaging and image

### `build-packages.sh` refuses to run

The script requires a clean Git tree and matching versions. Commit or stash only
your own work; do not rewrite the version check. The script creates a source
archive from `HEAD`, so uncommitted files are intentionally excluded.

### `makepkg` or `repo-add` is missing

Run the package build in the documented Arch container or on a disposable Arch
target with `base-devel`. Do not install packages on the Debian workstation.

### `namcap` warnings

Review each warning. QML module visibility and empty meta-package warnings are
expected in a `--nodeps` container build. Errors are not expected. Do not add
unused dependencies just to silence a warning.

### Package installation works only with `--nodeps`

That is not a successful dependency-resolved installation. Use a real pacman
transaction on the target and record missing or conflicting dependencies. The
prototype smoke test does not prove a releasable package.

### ISO build fails

`mkarchiso` and the archiso profile are unverified on this workstation. Run the
build in an Arch environment as documented. Do not use `sudo` to work around a
missing local repository file; inspect the package list, local repository and
profile paths first.

### Boot reaches a black screen

Use a VM serial console or TTY. Check that Hyprland and the Klyvera shell started,
then inspect the live user's journal. The live image uses a prototype local
repository with `TrustAll`; that is a known gap, not a release configuration.

## Website deployment

### Pages job cannot configure Pages

The repository must allow Pages deployments from GitHub Actions. The workflow
needs `pages: write` and `id-token: write`. If the repository settings or branch
protection block the deployment, fix the settings; do not publish `web/dist/`
from a local machine as an unreviewed substitute.

### Deployed site is unstyled or links 404

The build base and Pages path disagree. Confirm the workflow base is
`/<repository-name>/` and that `web/dist` was built with the same value. The
sitemap and canonical URLs currently assume the `nurlancoder/Klyvera` path.

### Deployed site differs from local

Confirm the deployed commit, workflow run and artifact. GitHub Pages caches
deployments; check the run summary before rebuilding. The live site and workflow
remain unverified until a deployment is inspected.

## Reporting a problem

Include the commit, environment, exact command, expected result, actual result,
and whether the check ran on Debian or the Arch target. Do not include secrets,
tokens, private paths or personal file names in a public issue. Report security
issues through the private channel in `SECURITY.md`.
