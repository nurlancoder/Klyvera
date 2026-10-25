# Phase 6 — Website

Goal: a fast, accessible, bilingual static site that presents the product
honestly and deploys to GitHub Pages without a server or third-party runtime
dependency.

## Steps

- [x] Add a Vite + TypeScript multi-page site under `web/` with English and
      Azerbaijani landing pages and an English documentation hub.
- [x] Build the visual system from `design/tokens.json`: dark, light and
      high-contrast themes, responsive layout classes, no external fonts or
      trackers.
- [x] Present the product with real rendered screenshots, verified project
      numbers and explicit prototype / unverified-on-target labels.
- [x] Add keyboard navigation, skip links, visible focus, reduced-motion
      handling, language metadata and accessible mobile navigation.
- [x] Add local checks for internal links, assets, headings, image alt text and
      build output.
- [x] Add the GitHub Pages workflow and document local build and deployment.
- [x] Record verified and unverified work in `docs/STATUS.md`.

## Implementation notes

- The site has three entries: English landing, Azerbaijani landing and an
  English documentation hub. Azerbaijani documentation links to the English
  hub.
- Build, deployment and verification steps are documented in
  `docs/website.md`.
- Static checks pass for `/` and `/Klyvera/`; Playwright and axe checks pass
  locally at six widths with mobile and desktop axe runs.
- The Pages workflow is committed but has not run on GitHub. Visual review of
  the rendered site is still pending.

## Exit criteria

- `npm ci && npm run build` succeeds from a clean checkout.
- The built site works at `/` and under the `/Klyvera/` project-pages base.
- English and Azerbaijani pages share the same structure, set the correct
  `lang`, and link to each other.
- No page requires JavaScript to read its primary content.
- No external font, analytics, tracker or API request is made.
- Automated checks cover links, assets, headings, alt text and responsive
  overflow.
- Deployment is labelled **UNVERIFIED** until the GitHub Pages workflow runs.
