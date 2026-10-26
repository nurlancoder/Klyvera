#!/usr/bin/env python3
import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QObject, QUrl
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest

QML = Path(__file__).with_name("pages_behavior.qml")


def main() -> int:
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(1440, 900)
    view.setSource(QUrl.fromLocalFile(str(QML)))
    if view.status() == QQuickView.Error:
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        return 1

    root = view.rootObject()
    QTest.qWait(250)

    search = root.findChild(QObject, "launcherSearch")
    if search is None:
        print("launcher search field not found", file=sys.stderr)
        return 1

    search.setProperty("text", "code")
    QTest.qWait(250)
    count = root.property("launcherCount")
    first_id = root.property("launcherFirstId")
    if count < 1 or "Code" not in first_id:
        print(f"fuzzy launcher result wrong: count={count} first={first_id!r}",
              file=sys.stderr)
        return 1

    if not root.property("shellRejected"):
        print("shell interpreter was not rejected", file=sys.stderr)
        return 1
    if not root.property("traversalRejected"):
        print("command cwd traversal was not rejected", file=sys.stderr)
        return 1
    if not root.property("validAccepted"):
        print("valid argv command was rejected", file=sys.stderr)
        return 1

    print("launcher fuzzy search and Space command validation: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
