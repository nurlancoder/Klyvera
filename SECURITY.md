# Security policy

Klyvera is local-first software: it stores workspace profiles, launches local
applications and talks to a local daemon over a Unix socket. We take the
following classes of issue seriously:

- Code execution from imported Spaces or configuration (shell injection, argv
  confusion, unsafe `.desktop` parsing).
- Path traversal, symlink escape, or writes outside the intended configuration
  directories.
- Weak file or socket permissions; leaks of profile data through logs, IPC or
  backups.
- Denial of service in the daemon or IPC protocol.
- Supply-chain issues in direct or transitive dependencies.

## Reporting a vulnerability

**Do not open a public issue, discussion or pull request for a vulnerability.**

Use GitHub's private vulnerability reporting for this repository
(*Security* tab → *Report a vulnerability*). If that is unavailable, contact the
maintainer through the contact method listed on their GitHub profile. Do not send
secrets in the first message; describe the impact and how to reproduce it.

Please include:

- Affected component and version or commit.
- Reproduction steps or a minimal proof of concept.
- Impact assessment and any prerequisites.
- Whether the issue is already public.

## What to expect

Klyvera is maintained by one person with no budget. We aim to acknowledge a
report within 7 days and to agree on a disclosure timeline together. There is no
bug bounty and no paid support. Fixes are released as soon as practical, with a
credit unless you ask to remain anonymous.

## Supported versions

There are no stable releases yet. Security fixes target the `main` branch and
the most recent prototype tag.

## Scope notes

- The Klyvera daemon is a user-session service. It is not intended to be exposed
  to the network.
- Imported profiles are untrusted by design and require explicit confirmation
  before any command is run.
- Third-party components (Hyprland, Quickshell, Qt, system services) should be
  reported upstream unless Klyvera's integration is the cause.
