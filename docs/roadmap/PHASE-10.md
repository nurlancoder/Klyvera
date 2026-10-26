# Phase 10 — CI recovery

Goal: resolve failures reported by GitHub Actions after PR #16 merged into
`main`.

## Steps

- [x] Reproduce and correct landing-page title overflow and wrapping failures
      reported by the browser suite.
- [x] Make the QML lint job invoke the installed Qt 6 linter reliably.
- [x] Build package source archives before dropping privileges so the
      unprivileged package build does not depend on Git metadata access.
- [x] Let the Pages workflow enable the repository's Pages site when permitted;
      confirm repository settings and deployment on a new Actions run.
- [x] Run focused local checks and record target/remote-only verification
      limits. A GitHub Actions run is still required before closing the phase.

## Exit criteria

- The exact reported responsive title measurements pass in the browser suite.
- The QML job resolves `qmllint` explicitly and fails clearly if unavailable.
- The package build consumes a committed source archive prepared before the
  build user is switched, without allowing a dirty-tree archive.
- Pages configuration has an explicit enablement attempt; repository settings
  and deployment remain unverified until a new Actions run succeeds.
