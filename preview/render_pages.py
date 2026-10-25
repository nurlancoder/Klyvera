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

SURFACES = (
    ("launcher", "launcher.png"),
    ("spaces", "spaces.png"),
    ("editor", "space-editor.png"),
    ("control", "control-center.png"),
    ("notifications", "notifications.png"),
    ("monitor", "system-monitor.png"),
    ("lock", "lock-screen.png"),
    ("session", "session-menu.png"),
    ("welcome", "welcome.png"),
)


def main() -> int:
    app = QGuiApplication(sys.argv)  # noqa: F841 - keeps the Qt application alive
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(1440, 900)
    view.setSource(QUrl.fromLocalFile(str(ROOT / "preview" / "pages.qml")))
    if view.status() == QQuickView.Error:
        return 1

    view.show()
    QTest.qWait(400)
    root = view.rootObject()
    root.setProperty("reduceMotion", True)
    OUTPUT.mkdir(parents=True, exist_ok=True)

    for surface, filename in SURFACES:
        root.setProperty("surface", surface)
        root.setProperty("themeName", "dark")
        QTest.qWait(350)
        image = view.grabWindow()
        if image.isNull() or not image.save(str(OUTPUT / filename)):
            print(f"failed to save {filename}", file=sys.stderr)
            return 1
        print(f"wrote docs/screenshots/{filename}")

    root.setProperty("surface", "spaces")
    root.setProperty("themeName", "light")
    QTest.qWait(350)
    image = view.grabWindow()
    if image.isNull() or not image.save(str(OUTPUT / "spaces-light.png")):
        print("failed to save spaces-light.png", file=sys.stderr)
        return 1
    print("wrote docs/screenshots/spaces-light.png")

    root.setProperty("surface", "launcher")
    root.setProperty("themeName", "dark")
    for width, height, filename in (
        (1180, 800, "launcher-compact.png"),
        (1920, 1080, "launcher-wide.png"),
        (2560, 1080, "launcher-ultrawide.png"),
    ):
        view.resize(width, height)
        QTest.qWait(350)
        image = view.grabWindow()
        if image.isNull() or not image.save(str(OUTPUT / filename)):
            print(f"failed to save {filename}", file=sys.stderr)
            return 1
        print(f"wrote docs/screenshots/{filename} ({width}x{height})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
