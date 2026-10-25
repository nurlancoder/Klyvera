# 0003 — Installer for the prototype ISO

- **Status:** accepted for the prototype
- **Date:** 2026-10-25
- **Deciders:** maintainer

## Context

The live ISO must boot and run the Klyvera session without a network. The project
has one maintainer, no budget and no server infrastructure. A fully offline
target installation is desirable but is not implemented by the prototype.
Calamares is polished but brings a large Qt/Python stack and a second
configuration format. A custom
installer would duplicate partitioning, encryption, bootloader and package
logic that already exists upstream.

## Decision

Use Arch Linux's official `archinstall` on the prototype live ISO (interactive
mode). The ISO documentation includes the post-install steps that connect the
installed system to the Klyvera shell and daemon. The image carries the Klyvera
packages and a local pacman config, but non-Klyvera dependencies still come from
configured repositories unless they are cached on the target.

Revisit a branded Calamares or custom installer after the package set, signing
and first-boot flow are stable.

## Consequences

- The prototype live session works offline; installation of non-Klyvera packages
  generally needs repository access.
- The prototype ISO has a functional, text-based installer with Arch's current
  partitioning and encryption support.
- Klyvera branding is carried by the live session, not the installer UI.
- Installation is English-first and assumes the user can follow documented
  post-install commands.
- The ISO cannot be called a polished consumer installer yet; this is recorded
  as unverified prototype scope.

## Alternatives considered

- **Calamares:** better graphical UX, but heavy and requires maintaining a
  branded module set before the core product is stable.
- **Custom Rust installer:** highest control, but too much scope and risk for a
  solo prototype with no target test machine yet.
- **No installer:** the ISO would only be a live demo, not a product path.
