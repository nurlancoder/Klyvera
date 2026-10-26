#!/usr/bin/env python3
import os
import sys
from pathlib import Path

os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
os.environ.setdefault("QT_QUICK_BACKEND", "software")

from PySide6.QtCore import QUrl, Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtQuick import QQuickItem, QQuickView
from PySide6.QtTest import QTest

QML = Path(__file__).with_name("notification_center.qml")


def find_item(parent: QQuickItem, object_name: str) -> QQuickItem | None:
    if parent.objectName() == object_name:
        return parent
    for child in parent.childItems():
        result = find_item(child, object_name)
        if result is not None:
            return result
    return None


def keyboard_activate(
    view: QQuickView,
    root: QQuickItem,
    object_name: str,
    key: Qt.Key,
) -> bool:
    item = find_item(root, object_name)
    if item is None:
        print(f"notification control not found: {object_name}", file=sys.stderr)
        return False
    item.forceActiveFocus()
    QTest.qWait(30)
    if view.activeFocusItem() is not item:
        print(f"keyboard focus did not reach {object_name}", file=sys.stderr)
        return False
    QTest.keyClick(view, key)
    QTest.qWait(30)
    return True


def main() -> int:
    app = QGuiApplication(sys.argv)
    view = QQuickView()
    view.setResizeMode(QQuickView.SizeRootObjectToView)
    view.resize(520, 720)
    view.setSource(QUrl.fromLocalFile(str(QML)))
    if view.status() == QQuickView.Error:
        for error in view.errors():
            print(error.toString(), file=sys.stderr)
        return 1

    view.show()
    QTest.qWait(200)
    root = view.rootObject()
    if root.property("observedUnreadCount") != 1:
        print("unread notification count is incorrect", file=sys.stderr)
        return 1

    if not keyboard_activate(view, root, "notificationActivate-unread-build",
                             Qt.Key_Space):
        return 1
    if root.property("activatedId") != "unread-build":
        print("keyboard activation did not emit the notification id",
              file=sys.stderr)
        return 1

    if not keyboard_activate(view, root, "notificationDismiss-unread-build",
                             Qt.Key_Space):
        return 1
    if root.property("dismissedId") != "unread-build":
        print("keyboard dismissal did not emit the notification id",
              file=sys.stderr)
        return 1

    if not keyboard_activate(view, root, "notificationDoNotDisturbToggle",
                             Qt.Key_Space):
        return 1
    if root.property("quietMode") is not True:
        print("keyboard toggle did not enable quiet mode", file=sys.stderr)
        return 1

    if not keyboard_activate(view, root, "notificationClearAllButton",
                             Qt.Key_Space):
        return 1
    if root.property("clearAllCount") != 1:
        print("keyboard clear-all did not emit its request", file=sys.stderr)
        return 1

    body = find_item(root, "notificationBody-unread-build")
    if body is None or body.property("lineCount") < 2:
        print("long notification body did not wrap across multiple lines",
              file=sys.stderr)
        return 1

    empty_state = find_item(root, "notificationEmptyState")
    error_state = find_item(root, "notificationErrorState")
    if empty_state is None or error_state is None:
        print("notification empty or error state was not found", file=sys.stderr)
        return 1
    root.setProperty("notifications", [])
    QTest.qWait(50)
    if root.property("observedUnreadCount") != 0 or not empty_state.isVisible():
        print("empty notification state or unread count is incorrect",
              file=sys.stderr)
        return 1
    root.setProperty("errorText", "Notification service unavailable.")
    QTest.qWait(50)
    if not error_state.isVisible() or empty_state.isVisible():
        print("notification error state did not replace the empty history",
              file=sys.stderr)
        return 1

    print(
        "notification center unread count, wrapped text, empty/error states "
        "and keyboard actions: ok"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
