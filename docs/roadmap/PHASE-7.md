# Phase 7 — Hardening and release readiness

Goal: make the prototype safe to evaluate and possible to release without
turning unverified target work into production claims.

This phase does not publish a release, sign packages or declare the project
stable. It closes documentation and process gaps around the code that already
exists, records the trust boundaries and defines the checks a maintainer must run
on the Arch target.

## Steps

- [x] Write a threat model covering profiles, command trust, launch planning,
      daemon IPC, backups, packaging, the live image and the website.
- [x] Add a manual test checklist for the Rust core, QML shell, Hyprland session,
      packaging, installer and website, with explicit pass criteria.
- [x] Document troubleshooting for the local development workstation and the
      Arch target.
- [x] Define the release process: versioning, artifact verification, signing
      gap, checksums and rollback.
- [x] Link the operational documents from the README and documentation site.
- [x] Update the changelog, status record and site verification counts.
- [x] Run the final local audit and record exact results.

## Exit criteria

- Every security boundary has an owner, a verification method and a residual
  risk statement.
- The manual test document distinguishes local checks from target-only checks.
- No document claims an ISO, package installation, live session or deployment
  that has not run.
- Release instructions require target checks, checksums and signing before a
  public artifact is published.
- The complete local check suite passes; skipped checks are listed by reason.
- **UNVERIFIED-ON-TARGET** items remain visible in `docs/STATUS.md`.
