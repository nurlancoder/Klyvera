## What changed

<!-- Describe the problem and the approach. Link the issue if one exists. -->

## Checks

List what you actually ran. Do not tick a box for a check that was skipped.

- [ ] `cargo fmt --check`
- [ ] `cargo clippy --all-targets -- -D warnings`
- [ ] `cargo test`
- [ ] `python3 design/generators/generate.py --check`
- [ ] `qmllint`
- [ ] `shellcheck`
- [ ] JSON Schema validation
- [ ] `npm run build`
- [ ] `./scripts/check.sh`

## Verification honesty

- [ ] Behaviour that requires Arch Linux, Hyprland, Quickshell, pacman or
      mkarchiso is marked **UNVERIFIED-ON-TARGET**, not described as working.
- [ ] `docs/STATUS.md` is updated with DONE / UNVERIFIED-ON-TARGET / BLOCKED.

## Safety

- [ ] No secrets, tokens, personal paths or user data are included.
- [ ] No third-party code or assets were copied without a license record.
- [ ] No shell strings from untrusted profiles are executed.
- [ ] File and socket permissions follow the security invariants in AGENTS.md.

## Notes for the maintainer

<!-- Anything that needs a decision, a system package, or manual target testing. -->
