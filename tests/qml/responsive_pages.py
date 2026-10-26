#!/usr/bin/env python3
"""Check page sizing and responsive layout classes across desktop viewports."""
import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest

ROOT = Path(__file__).resolve().parents[2]
PAGES = ("launcher", "spaces", "editor", "control", "notifications",
         "monitor", "lock", "session", "welcome")
VIEWPORTS = (
    (640, 480),
    (640, 720),
    (768, 600),
    (1024, 768),
    (1279, 720),
    (1280, 800),
    (1440, 900),
    (1919, 1080),
    (1920, 1080),
    (2559, 1440),
    (2560, 1440),
)


def expected_layout_class(width: int) -> str:
    if width < 1280:
        return "compact"
    if width < 1920:
        return "regular"
    if width < 2560:
        return "wide"
    return "ultrawide"


def find_layout_item(item):
    if item.metaObject().indexOfProperty("layoutClass") >= 0:
        return item
    for child in item.childItems():
        layout_item = find_layout_item(child)
        if layout_item is not None:
            return layout_item
    return None


def visible_text_and_controls(item, page):
    for child in item.childItems():
        if child.isVisible() and child.width() > 0 and child.height() > 0:
            class_name = child.metaObject().className()
            if class_name == "QQuickText" or "Button" in class_name:
                origin = child.mapToItem(page, 0, 0)
                clipped = False
                parent = child.parentItem()
                while parent is not None and parent != page:
                    clipped = clipped or parent.clip()
                    parent = parent.parentItem()
                yield (
                    child.objectName() or class_name,
                    origin.x(),
                    origin.y(),
                    child.width(),
                    child.height(),
                    clipped,
                )
            yield from visible_text_and_controls(child, page)


def main() -> int:
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(*VIEWPORTS[0])
    view.setSource(QUrl.fromLocalFile(str(ROOT / "preview" / "pages.qml")))
    if view.status() == QQuickView.Error:
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        return 1

    view.show()
    root = view.rootObject()
    checks = 0
    errors = []

    for surface in PAGES:
        root.setProperty("surface", surface)
        for width, height in VIEWPORTS:
            view.resize(width, height)
            QTest.qWait(50)
            page = root.property("activeSurface")
            if page is None:
                errors.append(f"{surface} at {width}x{height}: preview page did not load")
                continue

            actual_size = (round(page.width()), round(page.height()))
            if actual_size != (width, height):
                errors.append(
                    f"{surface} at {width}x{height}: page bounds are "
                    f"{actual_size[0]}x{actual_size[1]}"
                )
            checks += 1

            for name, x, y, item_width, item_height, clipped in visible_text_and_controls(page, page):
                if clipped:
                    continue
                if x < -2 or y < -2 or x + item_width > width + 2 or y + item_height > height + 2:
                    errors.append(
                        f"{surface} at {width}x{height}: {name} extends beyond "
                        f"the viewport ({x:.0f},{y:.0f},{item_width:.0f},{item_height:.0f})"
                    )
                checks += 1

            layout_item = find_layout_item(page)
            if layout_item is None:
                errors.append(f"{surface}: no responsive layoutClass at {width}px")
            else:
                layout_class = layout_item.property("layoutClass")
                expected_class = expected_layout_class(round(layout_item.width()))
                if layout_class == expected_class:
                    checks += 1
                    continue
                errors.append(
                    f"{surface} at {width}px: expected {expected_class} "
                    f"for a {round(layout_item.width())}px content pane, got {layout_class}"
                )
            checks += 1

    if errors:
        print(f"responsive page checks failed: {len(errors)} issue(s), {checks} assertions")
        for error in errors:
            print(f"  - {error}")
        return 1

    print(f"responsive page checks passed: {checks} assertions across {len(PAGES)} surfaces and {len(VIEWPORTS)} viewports")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
