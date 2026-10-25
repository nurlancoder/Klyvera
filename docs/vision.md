# Vision

**Your workspace. Your flow.**

## The problem

Developers do not work on one thing. A typical day involves several projects,
each with its own folder, editor window, terminal, browser tabs, notes and
services. Rebuilding that context by hand is slow, error-prone and quietly
exhausting. Existing desktop environments are general-purpose; they know about
windows, not about projects.

## The product

Klyvera is a Linux desktop built around **Spaces**: named, local workspace
profiles that describe a project and the environment it needs.

A Space can hold:

- one or more project paths, validated before use;
- applications to launch, referenced as argv arrays resolved through installed
  `.desktop` entries;
- optional layout hints for the compositor;
- optional terminal commands, treated as untrusted until the user explicitly
  confirms them for that profile hash.

Opening a Space is a single action from the launcher, the panel or the CLI. The
state lives on disk, in plain JSON, under the user's XDG directories. There is no
account and no sync service.

Around Spaces, Klyvera provides a calm shell: a panel, a keyboard-first launcher,
a notification center and a control center for the settings people actually
change, with graceful degradation when a system service is absent.

## Audience

Developers and technical Linux users who:

- run Arch Linux and Hyprland, or are willing to;
- keep many projects open and value fast context switching;
- prefer local files, scripts and keyboard control over cloud accounts;
- care about visual quality and accessibility, not just configurability.

## Product pillars

1. **Spaces are the unit of work.** Every feature should make switching projects
   cheaper.
2. **Local-first and offline.** No servers, accounts, telemetry or paid services.
   Configuration is readable JSON owned by the user.
3. **Keyboard-first.** Every action has a key path, visible focus, and a clear
   escape.
4. **Calm, premium design.** Dark-first, restrained, token-driven. Motion is
   short and optional. Nothing flashes or glows for decoration.
5. **Safe by default.** Imported data is untrusted. No shell strings. Paths are
   validated. The daemon is reachable only by the current user.
6. **Honest engineering.** Target-only behaviour is marked unverified until it is
   run on the target.

## Non-goals

- A general-purpose distribution for absolute beginners.
- A cloud sync, account system, marketplace, or telemetry pipeline.
- Reimplementing audio, networking, Bluetooth, power or notification services.
  Klyvera integrates with PipeWire, NetworkManager, BlueZ, UPower and the
  freedesktop notification spec through adapters.
- Copying another desktop's configuration or visual identity.
- A mobile or web desktop.

## Success criteria for the prototype

These are qualitative on purpose; no invented benchmarks.

- A new user can create a Space with a project folder and two applications, then
  reopen it after a reboot, without editing JSON by hand.
- A keyboard-only user can open the launcher, find an app or Space, and open it.
- Importing a Space never executes anything before explicit confirmation.
- The shell remains usable at 1280×720 and at ultrawide widths, with fractional
  scaling and a portrait monitor.
- Removing or stopping a system service produces an explanatory empty state, not
  a crash.
- Every check listed in `docs/STATUS.md` is either run locally or clearly marked
  as unverified on target.

## Roadmap shape

Foundation and design system first, then a tested Rust core, then pure QML
components, then features, packaging, the website, and finally hardening and a
manual target test pass. Details live in `docs/roadmap/`.
