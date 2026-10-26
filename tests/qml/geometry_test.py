#!/usr/bin/env python3
"""Check that a button's visible content is centered in its target."""
import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickItem, QQuickView
from PySide6.QtTest import QTest

QML = Path(__file__).with_name("geometry_test.qml")


def find_item(parent: QQuickItem, object_name: str) -> QQuickItem | None:
    if parent.objectName() == object_name:
        return parent
    for child in parent.childItems():
        result = find_item(child, object_name)
        if result is not None:
            return result
    return None


def assert_centered(
    item: QQuickItem,
    target: QQuickItem,
    horizontal: bool = True,
    vertical: bool = True,
) -> None:
    origin = item.mapToItem(target, 0, 0)
    if horizontal:
        item_center = origin.x() + item.width() / 2
        target_center = target.width() / 2
        if abs(item_center - target_center) > 1:
            raise AssertionError(
                f"{item.objectName()} horizontal center {item_center:.2f} "
                f"does not match {target.objectName()} center {target_center:.2f}"
            )
    if vertical:
        item_center = origin.y() + item.height() / 2
        target_center = target.height() / 2
        if abs(item_center - target_center) > 1:
            raise AssertionError(
                f"{item.objectName()} vertical center {item_center:.2f} "
                f"does not match {target.objectName()} center {target_center:.2f}"
            )


def main() -> int:
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(480, 180)
    view.setSource(QUrl.fromLocalFile(str(QML)))
    if view.status() == QQuickView.Error:
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        return 1

    view.show()
    QTest.qWait(200)
    root = view.rootObject()
    checks = (
        ("buttonContentRow", "geometryButton", True, True),
        ("iconButtonGlyph", "geometryIconButton", True, True),
        ("geometryTabLabel-0", "geometryTab-0", True, True),
        ("listItemContent", "geometryListItem", False, True),
    )
    for item_name, target_name, horizontal, vertical in checks:
        item = find_item(root, item_name)
        target = find_item(root, target_name)
        if item is None or target is None:
            print(f"geometry target not found: {item_name}, {target_name}", file=sys.stderr)
            return 1
        try:
            assert_centered(item, target, horizontal, vertical)
        except AssertionError as error:
            print(error, file=sys.stderr)
            return 1

    print("Button, IconButton, Tabs and ListItem content geometry: centered")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
