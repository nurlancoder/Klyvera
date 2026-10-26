#!/usr/bin/env python3
"""Validate Klyvera schema examples and representative invalid documents."""

from __future__ import annotations

import json
import sys
from pathlib import Path

try:
    from jsonschema import Draft202012Validator
except ImportError:
    print("jsonschema is required: pip install jsonschema", file=sys.stderr)
    raise SystemExit(2)

ROOT = Path(__file__).resolve().parent.parent
CASES = {
    ROOT / "schemas/config.schema.json": [
        ROOT / "schemas/examples/config.default.json",
    ],
    ROOT / "schemas/space.schema.json": [
        ROOT / "schemas/examples/space.example.json",
    ],
}


def load(path: Path) -> object:
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def invalid_cases() -> list[tuple[Path, str, object]]:
    config_schema = ROOT / "schemas/config.schema.json"
    space_schema = ROOT / "schemas/space.schema.json"
    return [
        (
            config_schema,
            "scale out of range",
            {
                "version": 1,
                "appearance": {"theme": "dark", "accent": "purple", "scale": 9},
            },
        ),
        (
            config_schema,
            "unknown field",
            {"version": 1, "surprise": True},
        ),
        (
            space_schema,
            "relative project path",
            {
                "version": 1,
                "id": "demo",
                "name": "Demo",
                "projectPaths": ["relative"],
            },
        ),
        (
            space_schema,
            "project traversal",
            {
                "version": 1,
                "id": "demo",
                "name": "Demo",
                "projectPaths": ["/srv/projects/../../etc"],
            },
        ),
        (
            space_schema,
            "unknown field",
            {
                "version": 1,
                "id": "demo",
                "name": "Demo",
                "projectPaths": ["/srv/projects/demo"],
                "surprise": True,
            },
        ),
        (
            space_schema,
            "command without argv",
            {
                "version": 1,
                "id": "demo",
                "name": "Demo",
                "projectPaths": ["/srv/projects/demo"],
                "commands": [{"label": "Tests"}],
            },
        ),
        (
            space_schema,
            "unsafe desktop id",
            {
                "version": 1,
                "id": "demo",
                "name": "Demo",
                "projectPaths": ["/srv/projects/demo"],
                "apps": [{"desktopId": "../escape.desktop"}],
            },
        ),
    ]


def main() -> int:
    failures = 0
    checked = 0

    for schema_path, examples in CASES.items():
        schema = load(schema_path)
        try:
            Draft202012Validator.check_schema(schema)
        except Exception as error:
            print(f"FAIL {schema_path.name}: invalid schema: {error}")
            failures += 1
            continue
        validator = Draft202012Validator(schema)
        for example in examples:
            checked += 1
            errors = sorted(validator.iter_errors(load(example)), key=lambda error: list(error.path))
            if errors:
                failures += 1
                for error in errors:
                    print(f"FAIL {example.relative_to(ROOT)}: {error.message}")
            else:
                print(f"ok   {example.relative_to(ROOT)}")

    schemas = {path.name: load(path) for path in CASES}
    for schema_path, description, document in invalid_cases():
        checked += 1
        validator = Draft202012Validator(schemas[schema_path.name])
        errors = list(validator.iter_errors(document))
        if errors:
            print(f"ok   rejected {description}")
        else:
            failures += 1
            print(f"FAIL accepted invalid document: {description}")

    print(f"{checked - failures}/{checked} schema checks passed")
    return 1 if failures else 0


if __name__ == "__main__":
    raise SystemExit(main())
