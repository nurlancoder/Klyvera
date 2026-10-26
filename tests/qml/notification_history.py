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

QML = Path(__file__).with_name("notification_history.qml")


def main() -> int:
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.setSource(QUrl.fromLocalFile(str(QML)))
    if view.status() == QQuickView.Error:
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        return 1

    root = view.rootObject()
    root.receiveMany(35, True)
    QTest.qWait(50)
    if root.property("notificationCount") != 30:
        print("notification history did not stay within its 30-entry limit",
              file=sys.stderr)
        return 1
    if root.property("trackedCount") != 35:
        print("tracked notification references were not retained",
              file=sys.stderr)
        return 1
    if root.property("newestId") != "n34" or root.property("oldestId") != "n5":
        print("history did not retain the newest 30 notifications",
              file=sys.stderr)
        return 1
    if (root.property("newestTrackedId") != "n34"
            or root.property("oldestTrackedId") != "n0"):
        print("tracked notification references did not preserve their arrival order",
              file=sys.stderr)
        return 1

    root.dismiss("n20")
    QTest.qWait(20)
    if root.property("lastDismissedId") != "n20":
        print("dismiss did not reach the backing notification", file=sys.stderr)
        return 1
    if (root.property("notificationCount") != 29
            or root.property("trackedCount") != 34):
        print("dismiss did not remove the notification and its tracked reference",
              file=sys.stderr)
        return 1

    root.clearAll()
    QTest.qWait(20)
    if root.property("notificationCount") != 0 or root.property("trackedCount") != 0:
        print("clear-all did not empty both notification collections",
              file=sys.stderr)
        return 1
    if root.property("dismissedCount") != 35:
        print("clear-all did not dismiss all tracked backing notifications",
              file=sys.stderr)
        return 1
    if root.property("doNotDisturb") is not True:
        print("notifications were not recorded while quiet mode was enabled",
              file=sys.stderr)
        return 1

    print("notification history limit, quiet-mode retention, dismiss and clear-all: ok")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
