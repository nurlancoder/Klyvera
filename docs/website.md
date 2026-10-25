# Website

The Klyvera website is a static Vite + TypeScript site under `web/`. It presents
the product, documents the repository and publishes the current prototype status
without a server, account, tracker or external runtime dependency.

## Pages

| Path | Language | Purpose |
| --- | --- | --- |
| `/` | English | Product landing page |
| `/az/` | Azerbaijani | Localized product landing page |
| `/docs/` | English | Documentation hub and repository guide |

The pages share the same layout and navigation model. No page requires
JavaScript to read its primary content. JavaScript adds theme switching, the
mobile menu, copy controls and reveal animations.

## Design and content rules

- The visual system is generated from `design/tokens.json`; the website consumes
  `web/src/styles/tokens.css` and does not keep a separate colour palette.
- Only local system font stacks, images and icons are used. There are no remote
  fonts, analytics, trackers, APIs or third-party embeds.
- Product screenshots are offscreen renders from mock data. They are labelled as
  previews, not as proof of a live Hyprland session.
- The page says **prototype** and marks target-only work as unverified. Do not
  turn a local check into a production claim.
- The tagline is **"Your workspace. Your flow."**; the Azerbaijani page uses
  **"İş məkanınız. Axınınız."**
- The bilingual pages set `lang`, link to each other with `hreflang` and share
  equivalent content structure.

## Build locally

Requirements: Node.js 20.19+ or 22.12+ and Python 3 for the static checks.

```bash
cd web
npm ci
npm run build
npm run check
```

The production output is written to `web/dist/`. `npm run build` runs the strict
TypeScript check before Vite builds the three HTML entries.

To preview the default build:

```bash
cd web
npm run preview -- --host 127.0.0.1 --port 4173
```

## Project Pages base

GitHub Pages serves the project at
`https://nurlancoder.github.io/Klyvera/`, so the deployment builds with a base
path:

```bash
cd web
npm run build -- --base=/Klyvera/
npm run check -- --base /Klyvera/
npm run preview -- --base=/Klyvera/
```

The base form must end with `/`. The sitemap, canonical links and manifest start
URL currently assume the `nurlancoder/Klyvera` project path. If the repository is
renamed or a custom domain is adopted, update those values and the Pages workflow
before deploying.

## Automated checks

`tests/web/check_site.py` validates the built HTML without a browser or network:

- expected pages and language attributes;
- titles, descriptions, canonical URLs and document headings;
- internal links, fragments and local assets;
- image alternative text, dimensions and local screenshot files;
- `target="_blank"` isolation and absence of insecure `http://` references;
- absence of remote fonts, analytics and tracker markers;
- manifest, favicon and required site files.

`tests/web/browser_test.mjs` uses Playwright and axe-core against the built site.
It checks three pages at 320, 375, 768, 1024, 1280 and 1440 pixels, including
horizontal overflow, hero-span overflow, responsive navigation, the mobile menu,
theme persistence and WCAG A/AA axe rules in dark, light and high-contrast
themes.

Install the test browser and run the checks:

```bash
cd web
npx playwright install chromium
npm run check
npm run preview -- --host 127.0.0.1 --port 4173 &
BASE_URL=http://127.0.0.1:4173 npm run test:browser
```

On a workstation that already has Chromium and no usable display server, point
the test at the system binary and unset the display variables:

```bash
cd web
CHROMIUM_PATH=/usr/bin/chromium env -u DISPLAY -u WAYLAND_DISPLAY npm run test:browser
```

The browser test expects the server to be running. CI installs Chromium, builds
the site with the repository base path, starts `vite preview` and runs both the
static and browser checks.

## Deployment

`.github/workflows/pages.yml` builds and deploys the site when `main` is pushed
or when the workflow is started manually. The workflow derives the base path from
the repository name, configures Pages, uploads `web/dist/` and deploys with the
official GitHub Pages actions.

The repository must have Pages configured to deploy from **GitHub Actions**. The
workflow has not yet run on GitHub; deployment is **UNVERIFIED** until it does.

## Current verification

- `npm run build` and `npm run build -- --base=/Klyvera/` succeed.
- Static checks pass for `/` and `/Klyvera/`: 3 pages, 285 assertions.
- Browser checks pass locally for `/` and `/Klyvera/`: 198 assertions across
  three pages and six viewport widths, including axe runs in all three themes
  and at desktop width.
- Human visual review of the rendered pages is still pending.
- The Pages workflow, GitHub-hosted build and live deployment are unverified.
