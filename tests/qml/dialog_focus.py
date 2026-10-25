#!/usr/bin/env python3
import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QObject, QUrl, Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickView
from PySide6.QtTest import QTest

QML = Path(__file__).with_name("dialog_focus.qml")


def active_name(view: QQuickView) -> str:
    item = view.activeFocusItem()
    return item.objectName() if item is not None else ""


def main() -> int:
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(800, 600)
    view.setSource(QUrl.fromLocalFile(str(QML)))
    if view.status() == QQuickView.Error:
        return 1

    view.show()
    QTest.qWait(300)

    root = view.rootObject()
    dialog = root.findChild(QObject, "focusDialog")
    if dialog is None:
        print("dialog object not found", file=sys.stderr)
        return 1

    dialog.open()
    QTest.qWait(300)
    if active_name(view) != "dialogPrimaryButton":
        print(f"unexpected initial focus: {active_name(view)}", file=sys.stderr)
        return 1

    for key in (Qt.Key_Tab,) * 9 + (Qt.Key_Backtab,) * 5:
        QTest.keyClick(view, key)
        QTest.qWait(30)
        name = active_name(view)
        if name not in ("dialogCloseButton", "dialogSecondaryButton", "dialogPrimaryButton"):
            print(f"focus escaped dialog to {name!r}", file=sys.stderr)
            return 1

    QTest.keyClick(view, Qt.Key_Escape)
    QTest.qWait(300)
    if dialog.property("opened"):
        print("Escape did not close dialog", file=sys.stderr)
        return 1
    if root.property("lastEvent") != "rejected":
        print("Escape did not emit rejected", file=sys.stderr)
        return 1

    print("dialog focus trap, Escape and rejected signal: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
