#!/usr/bin/env python3
"""Check repository Markdown for a single H1 and working relative links."""

from __future__ import annotations

import re
import sys
from pathlib import Path
from urllib.parse import unquote, urlsplit

ROOT = Path(__file__).resolve().parents[1]
EXCLUDED = {
    ".git",
    ".github",
    ".venv",
    "build",
    "dist",
    "node_modules",
    "out",
    "target",
}
LINK = re.compile(r"!?\[[^\]]*\]\(([^)\s]+)(?:\s+\"[^\"]*\")?\)")
SKIP_SCHEMES = {"http", "https", "mailto", "data"}
SKIP_PARTS = ("#", "?")


def markdown_files() -> list[Path]:
    files = []
    for path in ROOT.rglob("*.md"):
        if any(part in EXCLUDED for part in path.relative_to(ROOT).parts):
            continue
        files.append(path)
    return sorted(files)


def strip_fences(text: str) -> str:
    lines = []
    fenced = False
    fence = ""
    for line in text.splitlines():
        stripped = line.lstrip()
        if not fenced and stripped.startswith("```"):
            fenced = True
            fence = stripped[:3]
            lines.append("")
            continue
        if fenced and stripped.startswith(fence):
            fenced = False
            lines.append("")
            continue
        lines.append("" if fenced else line)
    return "\n".join(lines)


def check_file(path: Path) -> list[str]:
    errors: list[str] = []
    text = strip_fences(path.read_text(encoding="utf-8", errors="replace"))
    relative = path.relative_to(ROOT)

    h1 = [line for line in text.splitlines() if line.startswith("# ")]
    if len(h1) != 1:
        errors.append(f"{relative}: expected one H1, found {len(h1)}")

    for match in LINK.finditer(text):
        target = match.group(1).strip()
        if not target or target.startswith(SKIP_PARTS):
            continue
        parsed = urlsplit(target)
        if parsed.scheme in SKIP_SCHEMES or parsed.netloc:
            continue
        if target.startswith("/"):
            continue

        local = (path.parent / unquote(parsed.path)).resolve()
        try:
            local.relative_to(ROOT)
        except ValueError:
            errors.append(f"{relative}: link escapes the repository: {target}")
            continue
        if not local.exists():
            errors.append(f"{relative}: missing link target: {target}")

    return errors


def main() -> int:
    files = markdown_files()
    errors = [error for path in files for error in check_file(path)]
    if errors:
        print(f"documentation check failed: {len(errors)} error(s)", file=sys.stderr)
        for error in errors:
            print(f"  - {error}", file=sys.stderr)
        return 1
    print(f"documentation check passed: {len(files)} Markdown files")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
