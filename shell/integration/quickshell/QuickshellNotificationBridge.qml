// Target-only notification bridge backed by Quickshell's notification server.
import QtQuick
import Quickshell.Services.Notifications

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
        notification.tracked = true
        tracked = tracked.concat([notification])
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
        if (!doNotDisturb)
            notifications = [entry].concat(notifications).slice(0, 30)
    }

    function dismiss(notificationId: string) {
        const remaining = []
        for (let i = 0; i < tracked.length; i++) {
            if (String(tracked[i].id) === notificationId)
                tracked[i].dismiss()
            else
                remaining.push(tracked[i])
        }
        tracked = remaining
        notifications = notifications.filter(function(entry) {
            return entry.id !== notificationId
        })
    }

    function clearAll() {
        for (let i = 0; i < tracked.length; i++)
            tracked[i].dismiss()
        tracked = []
        notifications = []
    }
}
