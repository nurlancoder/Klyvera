#!/usr/bin/env python3
"""Check Theme.qml references and generated identifiers against source tokens."""
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
THEME_QML = ROOT / "shell" / "styles" / "Theme.qml"
TOKENS_JSON = ROOT / "design" / "tokens.json"
QML_DIRS = [ROOT / "shell", ROOT / "preview", ROOT / "tests" / "qml"]
THEME_PATTERN = re.compile(r"Theme\.([a-zA-Z][a-zA-Z0-9_.]*)")


def defined_properties(theme: str) -> set[str]:
    properties = set()
    stack = []

    for line in theme.splitlines():
        stripped = line.strip()
        object_match = re.match(
            r"readonly\s+property\s+QtObject\s+(\w+):\s+QtObject\s*\{",
            stripped,
        )
        if object_match:
            stack.append(object_match.group(1))
            properties.add(".".join(stack))
            continue

        property_match = re.match(r"readonly\s+property\s+\w+\s+(\w+)", stripped)
        if property_match and stack:
            properties.add(".".join([*stack, property_match.group(1)]))

        if stripped == "}" and stack:
            stack.pop()

    properties.update(
        re.findall(r"(?:readonly\s+)?property\s+\w+\s+(\w+)", theme)
    )
    properties.update(re.findall(r"function\s+(\w+)\s*\(", theme))
    return properties


def numeric_keys(value):
    if isinstance(value, dict):
        for key, nested in value.items():
            if key[:1].isdigit():
                yield key
            yield from numeric_keys(nested)
    elif isinstance(value, list):
        for nested in value:
            yield from numeric_keys(nested)


def main() -> int:
    if not THEME_QML.is_file() or not TOKENS_JSON.is_file():
        print("ERROR: Theme.qml or tokens.json is missing", file=sys.stderr)
        return 1

    theme = THEME_QML.read_text(encoding="utf-8")
    defined = defined_properties(theme)
    references = set()

    for qml_dir in QML_DIRS:
        if not qml_dir.exists():
            continue
        for qml_file in qml_dir.rglob("*.qml"):
            if "quickshell" in qml_file.parts:
                continue
            references.update(
                THEME_PATTERN.findall(qml_file.read_text(encoding="utf-8"))
            )

    missing = references - defined
    if missing:
        print("Missing Theme properties:")
        for name in sorted(missing):
            print(f"  Theme.{name}")
        return 1

    tokens = json.loads(TOKENS_JSON.read_text(encoding="utf-8"))
    for key in sorted(set(numeric_keys(tokens))):
        identifier = f"size{key}"
        if not re.search(rf"\bproperty\s+\w+\s+{re.escape(identifier)}\s*:", theme):
            print(f"Missing legal QML identifier for numeric token {key!r}")
            return 1

    print(f"PASS: {len(references)} Theme references and numeric token identifiers")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
