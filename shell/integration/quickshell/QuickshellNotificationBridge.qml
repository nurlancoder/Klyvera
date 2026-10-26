// Target-only notification bridge backed by Quickshell's notification server.
import QtQuick
import Quickshell.Services.Notifications
import "../NotificationHistory.js" as NotificationHistory

NotificationServer {
    id: root

    property var notifications: []
    property var tracked: []
    property bool doNotDisturb: false

    keepOnReload: true
    actionsSupported: true
    bodySupported: true
    imageSupported: true

    onNotification: function(notification) {
        const urgency = notification.urgency === NotificationUrgency.Critical
            ? "critical" : notification.urgency === NotificationUrgency.Low
            ? "low" : "normal"
        const entry = {
            "id": String(notification.id),
            "app": notification.appName ? notification.appName : "Klyvera",
            "title": notification.summary ? notification.summary : "",
            "body": notification.body ? notification.body : "",
            "urgency": urgency,
            "time": new Date().toLocaleTimeString(Qt.locale(), "HH:mm"),
            "read": false
        }
        const state = NotificationHistory.record(notifications, tracked, entry, notification)
        notifications = state.notifications
        tracked = state.tracked
    }

    function dismiss(notificationId: string) {
        const state = NotificationHistory.dismiss(notifications, tracked, notificationId)
        notifications = state.notifications
        tracked = state.tracked
    }

    function clearAll() {
        const state = NotificationHistory.clear(tracked)
        notifications = state.notifications
        tracked = state.tracked
    }
}
