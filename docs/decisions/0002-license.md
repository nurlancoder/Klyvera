# 0002 — Project license

- **Status:** proposed; **pending maintainer confirmation**
- **Date:** 2026-10-25
- **Deciders:** maintainer

## Context

Klyvera is intended to be free software that individuals and companies can use,
modify and redistribute. It dynamically links Qt (LGPL-3.0) and integrates with
GPL-compatible and permissively licensed upstream projects. The maintainer has not
yet made a final license decision.

## Provisional decision

Use **Apache License 2.0** as the provisional project license. The repository
contains the Apache-2.0 text in `LICENSE`, and source files are not individually
headed with a different license.

Apache-2.0 provides an explicit patent grant and clear redistribution terms. It is
compatible with the intended dynamic Qt use and with the permissively licensed
Rust dependencies.

## Pending

The maintainer must confirm or replace this choice. Until then:

- Do not describe the project as "finally licensed" or "relicensed".
- Do not add code under an incompatible license.
- Do not remove `LICENSE` or this record.
- Third-party licenses remain governed by their own terms.

If the license changes, add a new decision record and update `README.md`,
`CONTRIBUTING.md`, `THIRD_PARTY_NOTICES.md` and any package metadata.

## Alternatives considered

- **MIT:** simpler and permissive, but no explicit patent grant.
- **GPL-3.0-or-later:** strong copyleft; may discourage some contributors and
  commercial adoption, and is unnecessary for the stated goals.
- **MPL-2.0:** file-level copyleft; a reasonable fallback but less familiar to
  the target audience.
