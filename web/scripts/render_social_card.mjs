import { pathToFileURL } from "node:url";
import { createRequire } from "node:module";
import { resolve } from "node:path";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const source = resolve("public/illustrations/social-card.svg");
const output = resolve("public/og.png");
const browser = await chromium.launch({ headless: true });

try {
  const page = await browser.newPage({
    viewport: { width: 1200, height: 630 },
    deviceScaleFactor: 1,
  });
  await page.goto(pathToFileURL(source).href, { waitUntil: "load" });
  await page.screenshot({ path: output, type: "png" });
  console.log("rendered public/og.png at 1200x630");
} finally {
  await browser.close();
}
