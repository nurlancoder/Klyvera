# Decision 0004 — Website favicon

Status: accepted
Date: 2026-10-25

## Context

`design/brand.md` names the wordmark as the only current brand asset and
forbids inventing a mascot, gradient mark or geometric monogram without a
decision. Browsers still request a site icon, and shipping a broken or default
icon looks unfinished.

## Decision

The website uses a 32×32 utility favicon containing the letter **K** in the
system sans-serif stack on the dark background colour. It is not the wordmark,
not a logo, and must not be used in product chrome or marketing material. The
wordmark remains the only brand mark.

The icon is a locally authored SVG. It has no external font or image
dependency.

## Consequences

- The site has a complete browser identity without inventing a symbol.
- A future logo decision can replace `web/public/favicon.svg` without changing
  the product brand notes.
- The favicon does not imply affiliation with any upstream project.
