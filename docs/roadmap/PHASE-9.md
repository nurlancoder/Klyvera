# Phase 9 — Notification activation

Goal: make notification-card activation reach its backing desktop notification
and update the local unread state.

Status: implementation and offscreen policy tests complete. The Quickshell
adapter call has not been run in a live session.

## Steps

- [x] Verify the current Quickshell notification object exposes its invocation
      method before wiring it.
- [x] Route notification-center activation through the Quickshell bridge to the
      matching tracked notification.
- [x] Mark an activated history entry as read without changing other entries.
- [x] Add regression coverage for activation, missing tracked objects and
      unread-count updates.
- [x] Run all offscreen QML behavior tests, pure-QML lint and documentation
      checks; record target-only limitations.

## Exit criteria

- Activating a history row marks only that entry as read.
- If the backing notification is still tracked, its default action is invoked.
- A missing tracked object does not prevent the local read state from updating.
- Quickshell invocation behavior remains **UNVERIFIED-ON-TARGET** until run in
  the target session.
- Quickshell may dismiss a non-resident notification when its action is invoked;
  the local history entry remains and is marked read.
