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


def main() -> int:
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(320, 100)
    view.setSource(QUrl.fromLocalFile(str(QML)))
    if view.status() == QQuickView.Error:
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        return 1

    view.show()
    QTest.qWait(200)
    button = find_item(view.rootObject(), "geometryButton")
    content = find_item(view.rootObject(), "buttonContentRow")
    if button is None or content is None:
        print("button or its content was not created", file=sys.stderr)
        return 1

    content_origin = content.mapToItem(button, 0, 0)
    content_center_x = content_origin.x() + content.width() / 2
    content_center_y = content_origin.y() + content.height() / 2
    button_center_x = button.width() / 2
    button_center_y = button.height() / 2
    if abs(content_center_x - button_center_x) > 1:
        print(
            f"button content is not horizontally centered: "
            f"content center={content_center_x:.2f}, button center={button_center_x:.2f}",
            file=sys.stderr,
        )
        return 1

    if abs(content_center_y - button_center_y) > 1:
        print(
            f"button content is not vertically centered: "
            f"content center={content_center_y:.2f}, button center={button_center_y:.2f}",
            file=sys.stderr,
        )
        return 1

    print("button icon-and-label content is centered in both axes")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
