# Phase 8 — Notification center integrity

Goal: keep notification history behavior honest and bounded, and make each
notification action usable with a keyboard and assistive technology.

Status: complete for the pure notification-history policy and QML notification
surface. Quickshell and a live Wayland notification session have not been
exercised on this workstation.

## Steps

- [x] Add regression coverage for bounded notification history, dismissal,
      clear-all, do-not-disturb retention and keyboard activation.
- [x] Bound visible notification history and preserve the existing tracked
      object lifecycle while retaining notifications during do-not-disturb.
- [x] Give notification activation and dismissal explicit keyboard and
      accessibility semantics.
- [x] Run the offscreen QML behavior suite, lint and documentation checks;
      record target-only limits.

## Exit criteria

- Do-not-disturb does not silently discard notifications described as retained
  in the notification center.
- In-memory notification history has a fixed maximum size. Tracked Quickshell
  references retain their existing lifetime behavior until that contract can
  be verified on target.
- Notification activation and dismissal can be reached with keyboard controls
  and have meaningful accessible names and roles.
- Regression tests pass offscreen; Quickshell/Wayland behavior remains
  **UNVERIFIED-ON-TARGET** until exercised on the target.
- The current adapter has no banner presentation or suppression surface. The
  do-not-disturb control records its selected state; banner suppression is not
  claimed by this phase.
- Tracked Quickshell references remain unbounded as before. Their lifetime and
  a safe eviction policy are **UNVERIFIED-ON-TARGET**.
