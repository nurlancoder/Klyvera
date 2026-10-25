# Brand notes

## Name and tagline

**Klyvera** — pronounced *klih-VEH-rah*. The name is original and chosen for a
calm, clear sound. Always capitalise the K. Do not abbreviate to "Kly" in product
UI; use "Klyvera" or the component name.

Tagline: **Your workspace. Your flow.**

Use the tagline in the landing hero, the README and the first-run welcome screen.
Do not repeat it in every panel; it is a signature, not a label.

## Wordmark

The current wordmark is the name set in Manrope Semibold with slightly tight
tracking, in `textPrimary`. There is no symbol or logo asset yet. Do not invent a
mascot, gradient mark or geometric monogram without a design decision.

Minimum clear space around the wordmark: one `spacing.md` token on all sides.
Minimum size: 20 px cap height. On dark surfaces use `textPrimary`; never place
the wordmark on the accent colour.

## Visual character

- Calm, precise, premium. Closer to a good code editor than to a sci-fi HUD.
- Dark-first, but light and high-contrast themes are first-class.
- One accent at a time. Purple is the default product accent; blue is
  informational; mint is success and live status.
- Flat surfaces with subtle borders and restrained elevation. No heavy
  glassmorphism, no gratuitous glow, no mesh gradients, no decorative noise.
- Motion is short and functional. If it does not explain a change, remove it.

## Colour use

- Background and surface carry the layout. Accent is for interactive emphasis,
  selection and live status only.
- Danger is reserved for destructive actions and errors. Warning is for attention
  that is not yet an error.
- Never encode meaning with colour alone; pair it with an icon, label or shape.
- Text on accent fills uses `onAccent`, not white by habit. The token report
  verifies each pair.

## Typography

- Manrope for headings and the wordmark. Inter for UI and body. Monospace for
  code, commands, IDs and paths.
- Maximum two weights on one surface. Use size and spacing before adding weight.
- Sentence case for labels, buttons and headings. No all-caps except short
  status tags.
- Do not bundle or redistribute the fonts until their OFL texts are included;
  see `THIRD_PARTY_NOTICES.md`.

## Iconography

- Klyvera Line, an original stroke set with uniform `icon.strokeWidth` (1.75)
  and token sizes; no third-party icon files are vendored.
- Icons support labels; they do not replace them, except in a tooltipped icon
  button with an accessible name.
- Do not mix icon families or fill and stroke styles.

## Voice

- Direct, technical, calm. Short sentences.
- Prefer concrete verbs: "Open Space", "Export profile", "Retry".
- Errors say what happened, what was not changed, and what the user can do next.
- Never claim a feature is verified when it is not. The status badge is
  "prototype" until the target test pass is complete.

## Attribution and independence

Klyvera is independent. Do not use the Arch Linux, Hyprland, Quickshell or Qt
logos in Klyvera branding, and do not imply endorsement. Credit upstream projects
in documentation only, following `docs/CREDITS.md`.
