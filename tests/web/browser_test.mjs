import { createRequire } from "node:module";

const webRequire = createRequire(new URL("../../web/package.json", import.meta.url));
const { chromium } = webRequire("playwright");
const axePath = webRequire.resolve("axe-core/axe.min.js");
const base = process.env.BASE_URL ?? "http://127.0.0.1:4173";
const browser = await chromium.launch({
  headless: true,
  executablePath: process.env.CHROMIUM_PATH || undefined,
  args: ["--no-sandbox", "--disable-dev-shm-usage", "--no-proxy-server", "--proxy-bypass-list=*", "--disable-background-networking", "--disable-component-update", "--disable-sync", "--disable-default-apps", "--no-first-run"],
});

const pages = ["/", "/az/", "/docs/"];
const widths = [320, 360, 375, 390, 430, 600, 768, 900, 1000, 1024, 1280, 1440, 1920, 2560];
let assertions = 0;
const failures = [];
const pass = () => {
  assertions += 1;
};
const check = (condition, message) => {
  if (!condition) failures.push(message);
  else pass();
};

try {
  const page = await browser.newPage({ viewport: { width: 1440, height: 900 } });
  const errors = [];
  page.on("console", (message) => {
    if (message.type() === "error" && !message.text().includes("favicon")) errors.push(`console: ${message.text()}`);
  });
  page.on("pageerror", (error) => errors.push(`pageerror: ${error.message}`));

  const waitReady = async () => {
    for (let attempt = 0; attempt < 120; attempt += 1) {
      try {
        const ready = await page.evaluate(() => document.readyState === "complete" && Boolean(document.querySelector("h1")));
        if (ready) return true;
      } catch {
      }
      await page.waitForTimeout(250);
    }
    return false;
  };

  for (const path of pages) {
    errors.length = 0;
    console.log(`loading ${path}`);
    await page.setViewportSize({ width: 375, height: 900 });
    const response = await page.goto(`${base}${path}`, { waitUntil: "commit", timeout: 30000 });
    check(response?.status() === 200, `${path}: HTTP status ${response?.status()}`);
    check(await waitReady(), `${path}: page did not become ready`);
    check(errors.length === 0, `${path}: ${errors.join("; ")}`);

    const productImages = page.locator(".product-frame img, .media-frame img");
    for (const image of await productImages.all()) {
      await image.scrollIntoViewIfNeeded();
      await image.evaluate((element) => element.decode());
    }

    for (const width of widths) {
      console.log(`checking ${path} at ${width}px`);
      await page.setViewportSize({ width, height: 900 });
      await page.evaluate(() => window.scrollTo(0, 0));

      const metrics = await page.evaluate(() => {
        const visible = (selector) => {
          const element = document.querySelector(selector);
          if (!element) return false;
          const style = getComputedStyle(element);
          const rect = element.getBoundingClientRect();
          return style.display !== "none" && style.visibility !== "hidden" && rect.width > 0 && rect.height > 0;
        };
        const h1 = document.querySelector("h1");
        const spans = h1 ? [...h1.querySelectorAll("span")] : [];
        const columnCount = (selector) => {
          const element = document.querySelector(selector);
          return element ? getComputedStyle(element).gridTemplateColumns.split(" ").filter(Boolean).length : 0;
        };
        return {
          overflow: document.documentElement.scrollWidth - window.innerWidth,
          headerTop: document.querySelector(".site-header")?.getBoundingClientRect().top ?? Infinity,
          h1Count: document.querySelectorAll("h1").length,
          spanOverflow: spans.map((span) => span.scrollWidth - span.parentElement.clientWidth),
          heroSpanLines: spans.map((span) => {
            const style = getComputedStyle(span);
            return { height: span.getBoundingClientRect().height, lineHeight: parseFloat(style.lineHeight) };
          }),
          navVisible: visible(".site-nav"),
          menuVisible: visible("[data-menu-toggle]"),
          brokenImages: [...document.images].filter((image) => image.complete && image.naturalWidth === 0).length,
          skipLink: Boolean(document.querySelector("a.skip-link[href='#main']")),
          main: Boolean(document.querySelector("main#main")),
          theme: document.documentElement.dataset.theme,
          heroColumns: columnCount(".hero-grid"),
          splitColumns: columnCount(".split"),
          docsColumns: columnCount(".docs-layout"),
          headerTargets: [...document.querySelectorAll(".header-actions a, .header-actions button")]
            .filter((element) => getComputedStyle(element).display !== "none")
            .map((element) => {
              const rect = element.getBoundingClientRect();
              return { width: rect.width, height: rect.height, label: element.getAttribute("aria-label") || element.textContent.trim() };
            }),
          productImages: [...document.querySelectorAll(".product-frame img, .media-frame img")].map((image) => {
            const rect = image.getBoundingClientRect();
            return {
              src: image.currentSrc,
              naturalWidth: image.naturalWidth,
              naturalHeight: image.naturalHeight,
              width: rect.width,
              height: rect.height,
            };
          }),
        };
      });

      check(metrics.overflow <= 1, `${path} ${width}: horizontal overflow ${metrics.overflow}px`);
      check(Math.abs(metrics.headerTop) <= 1, `${path} ${width}: header starts at ${metrics.headerTop}px`);
      check(metrics.h1Count === 1, `${path} ${width}: expected one h1`);
      check(metrics.brokenImages === 0, `${path} ${width}: ${metrics.brokenImages} broken images`);
      check(metrics.skipLink && metrics.main, `${path} ${width}: missing skip link or main`);
      check(metrics.spanOverflow.every((value) => value <= 1), `${path} ${width}: hero span overflow ${metrics.spanOverflow.join(",")}`);
      if (path !== "/docs/" && width <= 600) {
        check(
          metrics.heroSpanLines.every((span) => span.height <= span.lineHeight + 1),
          `${path} ${width}: a hero title line wrapped unexpectedly`,
        );
      }
      check(metrics.theme === "dark", `${path} ${width}: expected dark theme, got ${metrics.theme}`);
      if (path !== "/docs/") {
        const expectedLandingColumns = width <= 1100 ? 1 : 2;
        check(metrics.heroColumns === expectedLandingColumns, `${path} ${width}: expected ${expectedLandingColumns} hero columns, got ${metrics.heroColumns}`);
        check(metrics.splitColumns === expectedLandingColumns, `${path} ${width}: expected ${expectedLandingColumns} feature columns, got ${metrics.splitColumns}`);
      } else {
        const expectedDocsColumns = width <= 1000 ? 1 : 2;
        check(metrics.docsColumns === expectedDocsColumns, `${path} ${width}: expected ${expectedDocsColumns} docs columns, got ${metrics.docsColumns}`);
      }
      for (const target of metrics.headerTargets) {
        check(target.width >= 44 && target.height >= 44, `${path} ${width}: header target "${target.label}" is ${target.width}x${target.height}px`);
      }
      for (const image of metrics.productImages) {
        check(image.src.includes("/illustrations/"), `${path} ${width}: product art is not using the scalable illustration (${image.src})`);
        check(image.naturalWidth >= 1200 && image.naturalHeight >= 700, `${path} ${width}: low-resolution product art (${image.naturalWidth}x${image.naturalHeight})`);
        check(image.width <= width + 1, `${path} ${width}: product illustration exceeds viewport (${image.width}px)`);
        check(Math.abs(image.width / image.height - 1.6) < 0.04, `${path} ${width}: product illustration aspect ratio is ${image.width / image.height}`);
      }

      if (width <= 1000) {
        check(!metrics.navVisible, `${path} ${width}: desktop nav should be hidden`);
        check(metrics.menuVisible, `${path} ${width}: menu button should be visible`);
      } else {
        check(metrics.navVisible, `${path} ${width}: desktop nav should be visible`);
        check(!metrics.menuVisible, `${path} ${width}: menu button should be hidden`);
      }
    }

    await page.setViewportSize({ width: 375, height: 900 });
    await page.evaluate(() => window.scrollTo(0, 0));

    const axeAt = async (label) => {
      await page.addScriptTag({ path: axePath });
      const axe = await page.evaluate(async () => {
        const results = await window.axe.run(document, {
          runOnly: { type: "tag", values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa"] },
        });
        return results.violations.map((violation) => ({
          id: violation.id,
          impact: violation.impact,
          nodes: violation.nodes.map((node) => node.target.join(" ")),
        }));
      });
      const serious = axe.filter((violation) => violation.impact === "serious" || violation.impact === "critical");
      check(
        serious.length === 0,
        `${path} axe ${label}: ${serious.map((item) => `${item.id} ${item.nodes.slice(0, 4).join(", ")}`).join("; ")}`,
      );
    };

    const toggle = page.locator("[data-menu-toggle]");
    await toggle.click();
    check((await toggle.getAttribute("aria-expanded")) === "true", `${path} mobile: menu did not expand`);
    check(await page.locator("[data-mobile-nav]").isVisible(), `${path} mobile: nav panel not visible`);
    const mobileTargets = await page.locator("[data-mobile-nav] a").evaluateAll((links) =>
      links.map((link) => {
        const rect = link.getBoundingClientRect();
        return { width: rect.width, height: rect.height, label: link.textContent.trim() };
      }),
    );
    for (const target of mobileTargets) {
      check(target.width >= 44 && target.height >= 44, `${path} mobile: menu target "${target.label}" is ${target.width}x${target.height}px`);
    }
    check(
      (await page.evaluate(() => document.activeElement?.closest("[data-mobile-nav]") !== null)) === true,
      `${path} mobile: focus did not enter menu`,
    );
    await page.keyboard.press("Escape");
    check((await toggle.getAttribute("aria-expanded")) === "false", `${path} mobile: Escape did not close menu`);
    check(!(await page.locator("[data-mobile-nav]").isVisible()), `${path} mobile: menu remained visible`);
    check(
      (await page.evaluate(() => document.activeElement?.hasAttribute("data-menu-toggle"))) === true,
      `${path} mobile: focus did not return to menu button`,
    );

    await axeAt("dark");
    await page.locator("[data-theme-toggle]").click();
    check((await page.evaluate(() => document.documentElement.dataset.theme)) === "light", `${path}: first theme toggle should be light`);
    await axeAt("light");
    await page.locator("[data-theme-toggle]").click();
    check(
      (await page.evaluate(() => document.documentElement.dataset.theme)) === "high-contrast",
      `${path}: second theme toggle should be high contrast`,
    );
    await axeAt("high-contrast");
    await page.locator("[data-theme-toggle]").click();
    check((await page.evaluate(() => document.documentElement.dataset.theme)) === "dark", `${path}: third theme toggle should be dark`);
    const stored = await page.evaluate(() => localStorage.getItem("klyvera-theme"));
    check(stored === "dark", `${path}: theme persistence failed, got ${stored}`);

    await page.setViewportSize({ width: 1440, height: 900 });
    await page.evaluate(() => window.scrollTo(0, 0));
    await axeAt("desktop");
    check(errors.length === 0, `${path}: ${errors.join("; ")}`);
  }
} finally {
  await browser.close();
}

if (failures.length) {
  console.error(`browser checks failed: ${failures.length}/${assertions}`);
  for (const failure of failures) console.error(`  - ${failure}`);
  process.exit(1);
}
console.log(`browser checks passed: ${assertions} assertions across ${pages.length} pages and ${widths.length} widths`);
