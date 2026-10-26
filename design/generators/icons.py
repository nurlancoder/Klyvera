#!/usr/bin/env python3
"""Validate the Klyvera icon manifest and generate QML Shape components."""
from __future__ import annotations

import argparse
import json
import math
import re
import sys
from pathlib import Path
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[2]
MANIFEST_PATH = ROOT / "design" / "icons" / "manifest.json"
CATALOG_PATH = ROOT / "shell" / "ui" / "IconCatalog.qml"
GENERATED_DIR = ROOT / "shell" / "ui" / "icons" / "generated"
NAME_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
NUMBER_PATTERN = re.compile(r"[+-]?(?:\d+(?:\.\d*)?|\.\d+)(?:[eE][+-]?\d+)?")
PATH_DATA_PATTERN = re.compile(r"^[MmLlHhVvCcSsQqTtAaZzEe0-9.,+\-\s]+$")
SVG_TAGS = {"circle", "line", "path", "polygon", "polyline", "rect"}
SVG_ROOT_ATTRIBUTES = {"fill", "height", "viewBox", "width"}
SVG_ATTRIBUTES = {
    "cx", "cy", "d", "fill", "height", "points", "r", "rx", "ry",
    "stroke", "stroke-linecap", "stroke-linejoin", "stroke-width",
    "width", "x", "x1", "x2", "y", "y1", "y2",
}


class IconManifestError(ValueError):
    """The icon manifest or one of its SVG assets is invalid."""


def _display_path(path: Path) -> str:
    try:
        return str(path.relative_to(ROOT))
    except ValueError:
        return str(path)


def _number(value: str | None, path: Path, attribute: str) -> float:
    try:
        result = float(value) if value is not None else math.nan
    except ValueError as error:
        raise IconManifestError(
            f"{_display_path(path)}: invalid number for {attribute}"
        ) from error
    if not math.isfinite(result):
        raise IconManifestError(f"{_display_path(path)}: invalid number for {attribute}")
    return result


def _format_number(value: float) -> str:
    return format(value, ".12g")


def _point_values(value: str, path: Path) -> list[float]:
    tokens = NUMBER_PATTERN.findall(value)
    remainder = NUMBER_PATTERN.sub("", value)
    if remainder.strip(" ,\t\r\n") or len(tokens) < 4 or len(tokens) % 2:
        raise IconManifestError(f"{_display_path(path)}: invalid SVG points")
    values = [float(token) for token in tokens]
    if not all(math.isfinite(item) for item in values):
        raise IconManifestError(f"{_display_path(path)}: non-finite SVG points")
    return values


def _shape_path(element: ElementTree.Element, path: Path) -> str:
    tag = element.tag.rsplit("}", 1)[-1]
    if tag == "path":
        value = element.get("d", "")
        if not value or not PATH_DATA_PATTERN.fullmatch(value):
            raise IconManifestError(f"{_display_path(path)}: invalid SVG path data")
        return value
    if tag == "line":
        x1 = _number(element.get("x1"), path, "x1")
        y1 = _number(element.get("y1"), path, "y1")
        x2 = _number(element.get("x2"), path, "x2")
        y2 = _number(element.get("y2"), path, "y2")
        return f"M {_format_number(x1)} {_format_number(y1)} L {_format_number(x2)} {_format_number(y2)}"
    if tag == "circle":
        cx = _number(element.get("cx"), path, "cx")
        cy = _number(element.get("cy"), path, "cy")
        radius = _number(element.get("r"), path, "r")
        if radius <= 0:
            raise IconManifestError(f"{_display_path(path)}: circle radius must be positive")
        left = _format_number(cx - radius)
        right = _format_number(radius * 2)
        y = _format_number(cy)
        r = _format_number(radius)
        return f"M {left} {y} a {r} {r} 0 1 0 {right} 0 a {r} {r} 0 1 0 -{right} 0"
    if tag in {"polyline", "polygon"}:
        values = _point_values(element.get("points", ""), path)
        commands = [f"M {_format_number(values[0])} {_format_number(values[1])}"]
        commands.extend(
            f"L {_format_number(values[index])} {_format_number(values[index + 1])}"
            for index in range(2, len(values), 2)
        )
        if tag == "polygon":
            commands.append("Z")
        return " ".join(commands)
    if tag == "rect":
        x = _number(element.get("x", "0"), path, "x")
        y = _number(element.get("y", "0"), path, "y")
        width = _number(element.get("width"), path, "width")
        height = _number(element.get("height"), path, "height")
        rx = _number(element.get("rx", "0"), path, "rx")
        ry = _number(element.get("ry", "0"), path, "ry")
        if width <= 0 or height <= 0 or rx < 0 or ry < 0:
            raise IconManifestError(f"{_display_path(path)}: invalid rectangle geometry")
        if rx == 0 and ry == 0:
            return (
                f"M {_format_number(x)} {_format_number(y)} "
                f"H {_format_number(x + width)} V {_format_number(y + height)} "
                f"H {_format_number(x)} Z"
            )
        if rx == 0:
            rx = ry
        if ry == 0:
            ry = rx
        rx = min(rx, width / 2)
        ry = min(ry, height / 2)
        return (
            f"M {_format_number(x + rx)} {_format_number(y)} "
            f"H {_format_number(x + width - rx)} "
            f"A {_format_number(rx)} {_format_number(ry)} 0 0 1 "
            f"{_format_number(x + width)} {_format_number(y + ry)} "
            f"V {_format_number(y + height - ry)} "
            f"A {_format_number(rx)} {_format_number(ry)} 0 0 1 "
            f"{_format_number(x + width - rx)} {_format_number(y + height)} "
            f"H {_format_number(x + rx)} "
            f"A {_format_number(rx)} {_format_number(ry)} 0 0 1 "
            f"{_format_number(x)} {_format_number(y + height - ry)} "
            f"V {_format_number(y + ry)} "
            f"A {_format_number(rx)} {_format_number(ry)} 0 0 1 "
            f"{_format_number(x + rx)} {_format_number(y)} Z"
        )
    raise IconManifestError(f"{_display_path(path)}: unsupported SVG element {tag!r}")


def _parse_svg(path: Path) -> list[str]:
    try:
        root = ElementTree.parse(path).getroot()
    except (ElementTree.ParseError, OSError) as error:
        raise IconManifestError(f"{_display_path(path)}: {error}") from error

    if root.tag.rsplit("}", 1)[-1] != "svg":
        raise IconManifestError(f"{_display_path(path)}: root element must be svg")
    if root.get("viewBox") != "0 0 24 24":
        raise IconManifestError(
            f"{_display_path(path)}: viewBox must be '0 0 24 24'"
        )
    invalid_root_attributes = set(root.attrib) - SVG_ROOT_ATTRIBUTES
    if invalid_root_attributes:
        names = ", ".join(sorted(invalid_root_attributes))
        raise IconManifestError(
            f"{_display_path(path)}: unsupported root attributes: {names}"
        )
    if root.get("fill", "none") != "none":
        raise IconManifestError(f"{_display_path(path)}: root fill must be 'none'")

    paths = []
    for element in root.iter():
        if element is root:
            continue
        tag = element.tag.rsplit("}", 1)[-1]
        if tag not in SVG_TAGS:
            raise IconManifestError(
                f"{_display_path(path)}: unsupported SVG element {tag!r}"
            )
        invalid_attributes = set(element.attrib) - SVG_ATTRIBUTES
        if invalid_attributes:
            names = ", ".join(sorted(invalid_attributes))
            raise IconManifestError(
                f"{_display_path(path)}: unsupported attributes: {names}"
            )
        for paint in ("fill", "stroke"):
            if element.get(paint) not in {None, "none", "currentColor"}:
                raise IconManifestError(
                    f"{_display_path(path)}: {paint} must be none or currentColor"
                )
        paths.append(_shape_path(element, path))

    if not paths:
        raise IconManifestError(f"{_display_path(path)}: SVG has no drawable geometry")
    return paths


def validate_manifest(manifest: object, root: Path = ROOT) -> list[dict[str, str]]:
    if not isinstance(manifest, dict):
        raise IconManifestError("manifest must be a JSON object")
    if set(manifest) != {"schemaVersion", "projectLicense", "licenseStatus", "icons"}:
        raise IconManifestError("manifest has missing or unknown top-level keys")
    if type(manifest["schemaVersion"]) is not int or manifest["schemaVersion"] != 1:
        raise IconManifestError("schemaVersion must be 1")
    if manifest["projectLicense"] != "Apache-2.0":
        raise IconManifestError("projectLicense must match the provisional project license")
    if manifest["licenseStatus"] != "provisional":
        raise IconManifestError("licenseStatus must remain provisional")
    entries = manifest["icons"]
    if not isinstance(entries, list) or not entries:
        raise IconManifestError("icons must be a non-empty array")

    names: list[str] = []
    files: list[str] = []
    for entry in entries:
        if not isinstance(entry, dict) or set(entry) != {"name", "file", "source", "license"}:
            raise IconManifestError("each icon must define name, file, source and license")
        name = entry["name"]
        if not isinstance(name, str) or not NAME_PATTERN.fullmatch(name):
            raise IconManifestError(f"invalid icon name: {name!r}")
        if entry["file"] != f"shell/assets/icons/{name}.svg":
            raise IconManifestError(f"{name}: file must be shell/assets/icons/{name}.svg")
        if entry["source"] != "original-project-artwork":
            raise IconManifestError(f"{name}: source must document original project artwork")
        if entry["license"] != "project-license-pending":
            raise IconManifestError(f"{name}: license must remain project-license-pending")
        names.append(name)
        files.append(entry["file"])

        icon_path = root / entry["file"]
        if not icon_path.is_file():
            raise IconManifestError(f"{name}: SVG source is missing: {entry['file']}")
        if root.resolve() not in icon_path.resolve().parents:
            raise IconManifestError(f"{name}: SVG source escapes the repository")
        _parse_svg(icon_path)

    if len(names) != len(set(names)):
        raise IconManifestError("icon names must be unique")
    if names != sorted(names):
        raise IconManifestError("icons must be sorted by name")

    source_files = {
        path.name for path in (root / "shell" / "assets" / "icons").glob("*.svg")
    }
    listed_files = {Path(file).name for file in files}
    missing = sorted(source_files - listed_files)
    extra = sorted(listed_files - source_files)
    if missing or extra:
        details = []
        if missing:
            details.append(f"unlisted SVG files: {', '.join(missing)}")
        if extra:
            details.append(f"manifest files without sources: {', '.join(extra)}")
        raise IconManifestError("; ".join(details))

    return entries


def load_manifest(path: Path = MANIFEST_PATH, root: Path = ROOT) -> list[dict[str, str]]:
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        raise IconManifestError(f"cannot read {path}: {error}") from error
    return validate_manifest(manifest, root)


def _component_name(name: str) -> str:
    return "".join(part[:1].upper() + part[1:] for part in name.split("-"))


def _component_path(name: str, root: Path = ROOT) -> Path:
    return root / "shell" / "ui" / "icons" / "generated" / f"{_component_name(name)}.qml"


def build_catalog(entries: list[dict[str, str]]) -> str:
    names = [entry["name"] for entry in entries]
    lines = [
        "pragma Singleton",
        "import QtQuick",
        "",
        "QtObject {",
        f"    readonly property var names: {json.dumps(names)}",
        "",
        "    function hasIcon(name) {",
        "        return names.indexOf(name) !== -1",
        "    }",
        "",
        "    function component(name) {",
        "        switch (name) {",
    ]
    for entry in entries:
        file_name = f"{_component_name(entry['name'])}.qml"
        lines.append(
            f'        case "{entry["name"]}": '
            f'return Qt.resolvedUrl("./icons/generated/{file_name}")'
        )
    lines.extend(
        [
            '        default: return ""',
            "        }",
            "    }",
            "}",
            "",
        ]
    )
    return "\n".join(lines)


def build_component(entry: dict[str, str], root: Path = ROOT) -> str:
    name = entry["name"]
    icon_path = root / entry["file"]
    shape_paths = _parse_svg(icon_path)
    lines = [
        "import QtQuick",
        "import QtQuick.Shapes",
        'import "../../../styles"',
        "",
        "Item {",
        "    id: root",
        "",
        "    property color color: Theme.textPrimary",
        "    implicitWidth: 24",
        "    implicitHeight: 24",
        "",
        "    Shape {",
        "        width: 24",
        "        height: 24",
        "        transform: Scale {",
        "            origin.x: 0",
        "            origin.y: 0",
        "            xScale: root.width / 24",
        "            yScale: root.height / 24",
        "        }",
    ]
    for shape_path in shape_paths:
        lines.extend(
            [
                "        ShapePath {",
                "            strokeColor: root.color",
                '            fillColor: "transparent"',
                "            strokeWidth: Theme.icon.strokeWidth",
                "            capStyle: ShapePath.RoundCap",
                "            joinStyle: ShapePath.RoundJoin",
                f"            PathSvg {{ path: {json.dumps(shape_path)} }}",
                "        }",
            ]
        )
    lines.extend(["    }", "}", ""])
    return "\n".join(lines)


def build_outputs(entries: list[dict[str, str]], root: Path = ROOT) -> dict[Path, str]:
    outputs = {root / "shell" / "ui" / "IconCatalog.qml": build_catalog(entries)}
    outputs.update(
        {_component_path(entry["name"], root): build_component(entry, root) for entry in entries}
    )
    return outputs


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="fail if generated QML is stale")
    args = parser.parse_args()

    try:
        entries = load_manifest()
        outputs = build_outputs(entries)
    except IconManifestError as error:
        print(f"error: {error}", file=sys.stderr)
        return 1

    expected_files = {path.resolve() for path in outputs}
    generated_files = {path.resolve() for path in GENERATED_DIR.glob("*.qml")}
    unexpected = sorted(generated_files - expected_files)
    if unexpected:
        for path in unexpected:
            print(
                f"unexpected generated file: {path.relative_to(ROOT)}",
                file=sys.stderr,
            )
        return 1

    if args.check:
        stale = []
        for path, content in outputs.items():
            if not path.is_file() or path.read_text(encoding="utf-8") != content:
                stale.append(path.relative_to(ROOT))
        if stale:
            for path in stale:
                print(f"missing or stale generated file: {path}", file=sys.stderr)
            return 1
        print(f"icon manifest and {len(entries)} generated components are in sync")
        return 0

    for path, content in outputs.items():
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
    print(f"generated icon catalog and {len(entries)} SVG components")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
