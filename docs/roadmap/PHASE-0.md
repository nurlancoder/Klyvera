# Phase 0 — Foundation

Goal: a repository that a new contributor can understand, a CI baseline, and an
honest record of what has and has not been run.

## Steps

- [x] Create the directory skeleton, `.gitignore`, `.gitattributes`,
      `.editorconfig`.
- [x] Write `AGENTS.md` with stack, environment rules, conventions, checks and
      security invariants.
- [x] Write root documents: `README.md`, `LICENSE` (provisional Apache-2.0),
      `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CHANGELOG.md`,
      `THIRD_PARTY_NOTICES.md`.
- [x] Add issue forms, pull request template and Dependabot configuration.
- [x] Add the CI skeleton, pre-commit hook, hook installer and aggregate check
      script.
- [x] Write `docs/vision.md`, `docs/architecture.md` with the layer diagram,
      decision records, roadmap and `docs/STATUS.md`.
- [x] Run every check available on the development workstation; record skipped
      checks honestly.

## Exit criteria

- `./scripts/check.sh --fast` passes locally (skips missing toolchains).
- The repository has no secrets, generated build output or personal data.
- Every planned layer has a home in the layout.
- `docs/STATUS.md` lists DONE, UNVERIFIED-ON-TARGET and BLOCKED.

## Notes

`shellcheck`, `qmllint` and a Qt QML runtime are not installed on the development
workstation. The scripts are syntax-checked with `bash -n`; CI installs
shellcheck and Qt tools. See `docs/STATUS.md`.
