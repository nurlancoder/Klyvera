#!/usr/bin/env python3
"""Verify every SVG catalog icon loads, renders and receives its requested tint."""
import json
import sys
from pathlib import Path
from time import monotonic

from PySide6.QtCore import QUrl
from PySide6.QtGui import QColor, QGuiApplication
from PySide6.QtQuick import QQuickItem, QQuickView
from PySide6.QtTest import QTest

ROOT = Path(__file__).resolve().parents[2]
MANIFEST = ROOT / "design" / "icons" / "manifest.json"
NAMES = [
    icon["name"]
    for icon in json.loads(MANIFEST.read_text(encoding="utf-8"))["icons"]
]

app = QGuiApplication(sys.argv)
view = QQuickView()
view.resize(len(NAMES) * 24, 24)
view.setSource(QUrl.fromLocalFile(str(ROOT / "tests" / "qml" / "icon_assets.qml")))

if view.status() != QQuickView.Ready:
    errors = "\n".join(error.toString() for error in view.errors())
    raise SystemExit(f"icon preview failed to load:\n{errors}")

view.show()
QTest.qWait(100)
root = view.rootObject()
icons = {}


def find_item(parent: QQuickItem, object_name: str) -> QQuickItem | None:
    if parent.objectName() == object_name:
        return parent
    for child in parent.childItems():
        result = find_item(child, object_name)
        if result is not None:
            return result
    return None


for name in NAMES:
    icon = find_item(root, f"icon-{name}")
    if icon is None:
        raise SystemExit(f"icon delegate was not created: {name}")
    icons[name] = icon

deadline = monotonic() + 5
while monotonic() < deadline:
    if all(icon.property("assetLoaded") for icon in icons.values()):
        break
    QTest.qWait(100)

for name, icon in icons.items():
    uses_asset = name != "battery"
    if bool(icon.property("usesAsset")) != uses_asset:
        raise SystemExit(f"unexpected renderer selected for {name}")
    loader = find_item(icon, "assetLoader")
    if loader is None:
        raise SystemExit(f"asset loader was not created for {name}")
    if uses_asset and not icon.property("assetLoaded"):
        raise SystemExit(f"generated QML component failed to load: {name}")
    if not uses_asset and loader.property("item") is not None:
        raise SystemExit("dynamic battery icon unexpectedly loaded a static component")

image = view.grabWindow()


def has_tinted_pixel(
    red: int,
    green: int,
    blue: int,
    start_x: int,
    end_x: int,
) -> bool:
    return any(
        (pixel := image.pixelColor(x, y)).alpha() > 0
        and abs(pixel.red() - red) < 20
        and abs(pixel.green() - green) < 20
        and abs(pixel.blue() - blue) < 20
        for y in range(image.height())
        for x in range(start_x, end_x)
    )


for index, name in enumerate(NAMES):
    if not has_tinted_pixel(255, 0, 255, index * 24, (index + 1) * 24):
        raise SystemExit(f"icon did not render its requested tint: {name}")

icons["search"].setProperty("color", QColor("#00FF00"))
QTest.qWait(100)
search_loader = find_item(icons["search"], "assetLoader")
search_component = search_loader.property("item")
if QColor(search_component.property("color")).name() != "#00ff00":
    raise SystemExit("SVG component did not receive its updated tint")
activity_loader = find_item(icons["activity"], "assetLoader")
activity_component = activity_loader.property("item")
if QColor(activity_component.property("color")).name() != "#ff00ff":
    raise SystemExit("changing one icon's tint altered the other components")

print(f"SVG catalog rendered {len(NAMES) - 1} Shape components with tint binding; battery fallback: ok")
