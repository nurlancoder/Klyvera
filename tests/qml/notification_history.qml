import QtQuick
import "../../shell/integration/NotificationHistory.js" as NotificationHistory

Item {
    id: root

    property var notifications: []
    property var tracked: []
    property var dismissedIds: []
    property var invokedIds: []
    property bool doNotDisturb: false

    readonly property int notificationCount: notifications.length
    readonly property int trackedCount: tracked.length
    readonly property int dismissedCount: dismissedIds.length
    readonly property int invokedCount: invokedIds.length
    readonly property int unreadCount: countUnread()
    readonly property string newestId: notifications.length > 0
        ? notifications[0].id : ""
    readonly property string oldestId: notifications.length > 0
        ? notifications[notifications.length - 1].id : ""
    readonly property string newestTrackedId: tracked.length > 0
        ? String(tracked[tracked.length - 1].id) : ""
    readonly property string oldestTrackedId: tracked.length > 0
        ? String(tracked[0].id) : ""
    readonly property string lastDismissedId: dismissedIds.length > 0
        ? dismissedIds[dismissedIds.length - 1] : ""
    readonly property string lastInvokedId: invokedIds.length > 0
        ? invokedIds[invokedIds.length - 1] : ""

    function receive(id) {
        const notification = {
            "id": id,
            "dismiss": function() {
                root.dismissedIds = root.dismissedIds.concat([id])
            },
            "invoke": function() {
                root.invokedIds = root.invokedIds.concat([id])
            }
        }
        const entry = { "id": id, "title": "Test notification", "read": false }
        const state = NotificationHistory.record(
            notifications, tracked, entry, notification)
        notifications = state.notifications
        tracked = state.tracked
    }

    function countUnread() {
        let count = 0
        for (let i = 0; i < notifications.length; i++) {
            if (!notifications[i].read)
                count += 1
        }
        return count
    }

    function receiveMany(count, quietMode) {
        doNotDisturb = quietMode
        for (let i = 0; i < count; i++)
            receive("n" + i)
    }

    function dismiss(id) {
        const state = NotificationHistory.dismiss(notifications, tracked, id)
        notifications = state.notifications
        tracked = state.tracked
    }

    function activate(id) {
        const state = NotificationHistory.activate(notifications, tracked, id)
        notifications = state.notifications
        tracked = state.tracked
    }

    function isRead(id) {
        for (let i = 0; i < notifications.length; i++) {
            if (notifications[i].id === id)
                return notifications[i].read
        }
        return false
    }

    function dropTracked(id) {
        tracked = tracked.filter(function(notification) {
            return String(notification.id) !== id
        })
    }

    function clearAll() {
        const state = NotificationHistory.clear(tracked)
        notifications = state.notifications
        tracked = state.tracked
    }
}
