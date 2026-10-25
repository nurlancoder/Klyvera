#!/usr/bin/env python3
"""Validate the built Klyvera site without a browser or network access."""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass, field
from html import unescape
from html.parser import HTMLParser
from pathlib import Path
from urllib.parse import unquote, urlsplit

EXTERNAL_SCHEMES = {"http", "https", "mailto"}
FORBIDDEN_MARKERS = (
    "fonts.googleapis.com",
    "fonts.gstatic.com",
    "google-analytics.com",
    "googletagmanager.com",
    "plausible.io",
    "umami.is",
    "static.cloudflareinsights.com",
)


@dataclass
class Tag:
    name: str
    attrs: dict[str, str]
    line: int


@dataclass
class Page:
    path: Path
    relative: Path
    tags: list[Tag] = field(default_factory=list)
    ids: set[str] = field(default_factory=set)
    title: str = ""


class DocumentParser(HTMLParser):
    def __init__(self) -> None:
        super().__init__(convert_charrefs=True)
        self.tags: list[Tag] = []
        self.ids: set[str] = set()
        self.title_parts: list[str] = []
        self.in_title = False

    def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        values = {name: value or "" for name, value in attrs}
        self.tags.append(Tag(tag, values, self.getpos()[0]))
        if values.get("id"):
            self.ids.add(values["id"])
        if tag == "title":
            self.in_title = True

    def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
        self.handle_starttag(tag, attrs)
        if tag == "title":
            self.in_title = False

    def handle_endtag(self, tag: str) -> None:
        if tag == "title":
            self.in_title = False

    def handle_data(self, data: str) -> None:
        if self.in_title:
            self.title_parts.append(data)


class Checker:
    def __init__(self, dist: Path, base: str) -> None:
        self.dist = dist.resolve()
        self.base = base if base.endswith("/") else f"{base}/"
        self.errors: list[str] = []
        self.passes = 0
        self.pages: dict[Path, Page] = {}

    def fail(self, page: Page | None, message: str) -> None:
        prefix = str(page.relative) if page else "site"
        self.errors.append(f"{prefix}: {message}")

    def ok(self) -> None:
        self.passes += 1

    def parse_pages(self) -> None:
        for path in sorted(self.dist.rglob("*.html")):
            relative = path.relative_to(self.dist)
            parser = DocumentParser()
            parser.feed(path.read_text(encoding="utf-8"))
            page = Page(
                path=path,
                relative=relative,
                tags=parser.tags,
                ids=parser.ids,
                title=unescape("".join(parser.title_parts)).strip(),
            )
            self.pages[path.resolve()] = page

    def url_path(self, page: Page) -> str:
        relative = page.relative.as_posix()
        if relative.endswith("index.html"):
            relative = relative[: -len("index.html")]
        return f"/{relative}"

    def resolve_local(self, page: Page, value: str) -> tuple[Path | None, str]:
        parsed = urlsplit(value)
        if parsed.scheme:
            return None, parsed.fragment
        if parsed.netloc:
            return None, parsed.fragment

        path = unquote(parsed.path)
        if not path:
            return page.path, parsed.fragment

        if path.startswith("/"):
            if self.base != "/":
                prefix = self.base.lstrip("/")
                stripped = path.lstrip("/")
                if stripped == prefix.rstrip("/") or stripped == prefix:
                    path = "/"
                elif stripped.startswith(prefix):
                    path = "/" + stripped[len(prefix) :]
                else:
                    return self.dist / "__outside_base__", parsed.fragment
            target = self.dist / path.lstrip("/")
        else:
            target = page.path.parent / path

        if path.endswith("/") or target.is_dir():
            target = target / "index.html"
        return target.resolve(), parsed.fragment

    def check_page(self, page: Page) -> None:
        tags = page.tags

        html_tags = [tag for tag in tags if tag.name == "html"]
        if not html_tags or not html_tags[0].attrs.get("lang"):
            self.fail(page, "missing html lang")
        else:
            self.ok()

        if not page.title:
            self.fail(page, "missing document title")
        else:
            self.ok()

        metas: dict[str, str] = {}
        for tag in tags:
            if tag.name == "meta" and tag.attrs.get("name"):
                metas.setdefault(tag.attrs["name"], tag.attrs.get("content", ""))
        for name in ("description", "viewport"):
            if not metas.get(name):
                self.fail(page, f"missing meta {name}")
            else:
                self.ok()

        canonical = [
            tag.attrs.get("href", "")
            for tag in tags
            if tag.name == "link" and "canonical" in tag.attrs.get("rel", "").split()
        ]
        if len(canonical) != 1 or not canonical[0].startswith("https://"):
            self.fail(page, "expected one https canonical link")
        else:
            self.ok()

        h1s = [tag for tag in tags if tag.name == "h1"]
        if len(h1s) != 1:
            self.fail(page, f"expected exactly one h1, found {len(h1s)}")
        else:
            self.ok()

        if not any(tag.name == "main" and tag.attrs.get("id") == "main" for tag in tags):
            self.fail(page, "missing main#main")
        else:
            self.ok()

        skip = [
            tag
            for tag in tags
            if tag.name == "a" and "skip-link" in tag.attrs.get("class", "").split()
        ]
        if not skip or skip[0].attrs.get("href") != "#main":
            self.fail(page, "skip link must target #main")
        else:
            self.ok()

        if not any(tag.name == "button" and "data-theme-toggle" in tag.attrs for tag in tags):
            self.fail(page, "missing theme toggle")
        else:
            self.ok()

        if not any(tag.name == "button" and "data-menu-toggle" in tag.attrs for tag in tags):
            self.fail(page, "missing mobile menu toggle")
        else:
            self.ok()

        alternate_langs = {
            tag.attrs.get("hreflang")
            for tag in tags
            if tag.name == "link" and "alternate" in tag.attrs.get("rel", "").split()
        }
        if not {"en", "az"} <= alternate_langs:
            self.fail(page, "missing en/az hreflang alternates")
        else:
            self.ok()

        seen_ids: set[str] = set()
        for tag in tags:
            tag_id = tag.attrs.get("id")
            if tag_id:
                if tag_id in seen_ids:
                    self.fail(page, f"duplicate id {tag_id!r} at line {tag.line}")
                seen_ids.add(tag_id)

        self.check_media(page)
        self.check_blank_targets(page)
        self.check_links(page)

    def check_media(self, page: Page) -> None:
        for tag in page.tags:
            if tag.name == "img":
                if "alt" not in tag.attrs or not tag.attrs["alt"].strip():
                    self.fail(page, f"image at line {tag.line} needs non-empty alt text")
                else:
                    self.ok()
                if not tag.attrs.get("width") or not tag.attrs.get("height"):
                    self.fail(page, f"image at line {tag.line} needs width and height")
                else:
                    self.ok()

            values: list[str] = []
            if tag.name in {"img", "script", "source"} and tag.attrs.get("src"):
                values.append(tag.attrs["src"])
            if tag.name == "source" and tag.attrs.get("srcset"):
                values.append(tag.attrs["srcset"])
            if tag.name == "link" and tag.attrs.get("href"):
                rel = tag.attrs.get("rel", "").split()
                if any(item in rel for item in ("stylesheet", "icon", "manifest")):
                    values.append(tag.attrs["href"])

            for value in values:
                for url in self.split_srcset(value):
                    parsed = urlsplit(url)
                    if parsed.scheme or parsed.netloc:
                        self.fail(page, f"external runtime asset at line {tag.line}: {url}")
                        continue
                    target, _ = self.resolve_local(page, url)
                    if target is None or not target.is_file():
                        self.fail(page, f"missing asset at line {tag.line}: {url}")
                    elif not target.is_relative_to(self.dist):
                        self.fail(page, f"asset escapes the site root: {url}")
                    else:
                        self.ok()

    @staticmethod
    def split_srcset(value: str) -> list[str]:
        if " " not in value and "," not in value:
            return [value]
        urls: list[str] = []
        for candidate in value.split(","):
            parts = candidate.strip().split()
            if parts:
                urls.append(parts[0])
        return urls

    def check_blank_targets(self, page: Page) -> None:
        for tag in page.tags:
            if tag.name == "a" and tag.attrs.get("target") == "_blank":
                rel = set(tag.attrs.get("rel", "").split())
                if not {"noopener", "noreferrer"} <= rel:
                    self.fail(page, f"target=_blank at line {tag.line} needs noopener noreferrer")
                else:
                    self.ok()

    def check_links(self, page: Page) -> None:
        for tag in page.tags:
            if tag.name != "a" or not tag.attrs.get("href"):
                continue
            href = tag.attrs["href"]
            parsed = urlsplit(href)
            if parsed.scheme in EXTERNAL_SCHEMES or parsed.netloc:
                if href.startswith("http://"):
                    self.fail(page, f"insecure external link at line {tag.line}: {href}")
                continue

            target, fragment = self.resolve_local(page, href)
            if target is None:
                continue
            if not target.is_file():
                self.fail(page, f"broken link at line {tag.line}: {href}")
                continue
            if not target.is_relative_to(self.dist):
                self.fail(page, f"link escapes the site root at line {tag.line}: {href}")
                continue
            self.ok()

            if fragment:
                target_page = self.pages.get(target)
                if target_page is None:
                    self.fail(page, f"fragment target is not HTML at line {tag.line}: {href}")
                elif fragment not in target_page.ids:
                    self.fail(page, f"missing fragment #{fragment} at line {tag.line}: {href}")
                else:
                    self.ok()

    def check_site_files(self) -> None:
        required = (
            "favicon.svg",
            "site.webmanifest",
            "robots.txt",
            "sitemap.xml",
            "og.png",
            "screenshots/spaces.png",
            "screenshots/spaces-1440.webp",
            "screenshots/space-editor.png",
            "screenshots/control-center.png",
        )
        for name in required:
            if not (self.dist / name).is_file():
                self.fail(None, f"missing site file: {name}")
            else:
                self.ok()

        for path in self.dist.rglob("*"):
            if path.is_file() and path.suffix in {".html", ".css", ".js", ".xml", ".txt", ".webmanifest"}:
                text = path.read_text(encoding="utf-8", errors="replace")
                for marker in FORBIDDEN_MARKERS:
                    if marker in text:
                        self.fail(None, f"tracker or remote font marker in {path.relative_to(self.dist)}")
                scanned = text.replace("http://www.sitemaps.org/schemas/sitemap/0.9", "")
                if "http://" in scanned:
                    self.fail(None, f"insecure http:// reference in {path.relative_to(self.dist)}")

        manifest = self.dist / "site.webmanifest"
        if manifest.is_file():
            try:
                import json

                data = json.loads(manifest.read_text(encoding="utf-8"))
                for key in ("name", "short_name", "start_url", "icons"):
                    if key not in data:
                        self.fail(None, f"manifest missing {key}")
                self.ok()
            except ValueError as error:
                self.fail(None, f"manifest is not valid JSON: {error}")

    def run(self) -> int:
        if not self.dist.is_dir():
            print(f"error: dist directory missing: {self.dist}", file=sys.stderr)
            return 1
        self.parse_pages()
        if not self.pages:
            print("error: no HTML pages found", file=sys.stderr)
            return 1

        for page in self.pages.values():
            self.check_page(page)
        self.check_site_files()

        expected_pages = {"index.html", "az/index.html", "docs/index.html"}
        actual_pages = {page.relative.as_posix() for page in self.pages.values()}
        missing = expected_pages - actual_pages
        if missing:
            self.fail(None, f"missing pages: {', '.join(sorted(missing))}")
        else:
            self.ok()

        if self.errors:
            print(f"website check failed: {len(self.errors)} error(s), {self.passes} passed")
            for error in self.errors:
                print(f"  - {error}")
            return 1

        print(f"website check passed: {len(self.pages)} pages, {self.passes} assertions, base {self.base}")
        return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dist", type=Path, default=Path(__file__).resolve().parents[2] / "web" / "dist")
    parser.add_argument("--base", default="/", help="Vite base path used for the build")
    args = parser.parse_args()
    return Checker(args.dist, args.base).run()


if __name__ == "__main__":
    raise SystemExit(main())
