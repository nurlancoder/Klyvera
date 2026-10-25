# Contributing to Klyvera

Thanks for taking the time to contribute. Klyvera is an original, local-first
project. Contributions must be original work or properly licensed third-party
material recorded in `THIRD_PARTY_NOTICES.md`.

## Before you start

- Read `AGENTS.md`, `docs/vision.md`, `docs/architecture.md` and
  `docs/STATUS.md`.
- For anything larger than a small fix, open an issue first so the design can be
  discussed.
- Do not copy code, configuration or assets from other desktop projects.

## Development setup

The development workstation may be Debian-based while the target is Arch Linux.
Use the tools available on your system; CI runs the full matrix.

```bash
git clone <repository-url> klyvera
cd klyvera
./scripts/install-hooks.sh
./scripts/check.sh
```

Requirements by layer:

- Rust stable (`cargo`, `rustfmt`, `clippy`)
- Python 3.11+ for the token generator
- Node.js 20+ and npm for the website
- `shellcheck` for shell scripts
- Qt 6 QML tooling for `qmllint` and the preview harness

## Checks

Run the aggregate check before opening a pull request:

```bash
./scripts/check.sh
```

The script skips toolchains that are not installed and prints a clear
`SKIP`/`FAIL` line. CI is authoritative. Do not claim a check passed if it was
skipped locally.

## Code style

- Rust: `rustfmt` defaults, Clippy warnings are errors, edition 2021.
- QML: `PascalCase.qml`, camelCase properties, signals in the past tense. Pure
  components under `shell/ui/` must not import Quickshell.
- JSON: 2-space indent, versioned persisted data, schemas under `schemas/`.
- Bash: `#!/usr/bin/env bash`, `set -euo pipefail`, quote everything, shellcheck
  clean.
- Docs: one H1, sentence-case headings, fenced code blocks with a language.

## Commits

Use Conventional Commits: `feat:`, `fix:`, `docs:`, `test:`, `chore:`, `ci:`,
`refactor:`. Imperative subject, 72 characters or fewer. Keep commits small and
focused. Never commit secrets or personal data.

## Pull requests

- Describe the problem and the approach.
- List the checks you ran and the checks you could not run.
- Mark target-only behaviour as unverified; do not describe it as working.
- Update `docs/STATUS.md` when the state of a feature changes.
- Update `CHANGELOG.md` for user-visible changes.

## Security

Do not open a public issue for vulnerabilities. Follow `SECURITY.md`.

## License

By contributing, you agree that your contribution is licensed under the same
license as the project (Apache-2.0, pending maintainer confirmation).
