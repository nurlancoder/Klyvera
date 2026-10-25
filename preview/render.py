#!/usr/bin/env python3
import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / "docs" / "screenshots"


def main() -> int:
    app = QGuiApplication(sys.argv)  # noqa: F841 - keeps the Qt application alive
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.setTitle("Klyvera component gallery")
    view.resize(1440, 1520)
    view.setSource(QUrl.fromLocalFile(str(ROOT / "preview" / "main.qml")))
    if view.status() == QQuickView.Error:
        return 1

    view.show()
    QTest.qWait(600)
    root = view.rootObject()
    root.setProperty("reduceMotion", True)

    shots = (
        ("components-compact.png", 1180, 1400, "dark", False),
        ("components-dark.png", 1440, 1520, "dark", False),
        ("components-light.png", 1440, 1520, "light", False),
        ("components-dialog.png", 1440, 1520, "dark", True),
        ("components-wide.png", 1920, 1500, "dark", False),
        ("components-ultrawide.png", 2560, 1400, "dark", False),
    )
    OUTPUT.mkdir(parents=True, exist_ok=True)
    for filename, width, height, theme, dialog in shots:
        view.resize(width, height)
        root.setProperty("themeName", theme)
        root.setProperty("dialogVisible", dialog)
        QTest.qWait(600)
        image = view.grabWindow()
        if image.isNull() or not image.save(str(OUTPUT / filename)):
            print(f"failed to save {filename}", file=sys.stderr)
            return 1
        print(f"wrote docs/screenshots/{filename} ({width}x{height}, {theme})")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
