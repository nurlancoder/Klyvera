import QtQuick
import "../../shell/pages" as Pages

Item {
    id: root

    width: 520
    height: 720

    property var notifications: [
        {
            "id": "unread-build",
            "app": "Build runner",
            "title": "Build finished",
            "body": "The workspace build completed successfully and the detailed "
                + "validation report is available locally for review. "
                + "No project data was sent to a remote service.",
            "urgency": "normal",
            "time": "12:30",
            "read": false
        },
        {
            "id": "read-sync",
            "app": "Source control",
            "title": "Changes synchronized",
            "body": "The latest local changes are available.",
            "urgency": "low",
            "time": "12:20",
            "read": true
        }
    ]
    property bool quietMode: false
    property string errorText: ""
    property int clearAllCount: 0
    property string activatedId: ""
    property string dismissedId: ""

    readonly property int observedUnreadCount: notificationCenter.unreadCount

    Pages.NotificationCenter {
        id: notificationCenter
        anchors.fill: parent
        notifications: root.notifications
        doNotDisturb: root.quietMode
        errorText: root.errorText
        onNotificationActivated: function(id) { root.activatedId = id }
        onDismissRequested: function(id) { root.dismissedId = id }
        onClearAllRequested: root.clearAllCount += 1
        onDoNotDisturbPicked: function(enabled) { root.quietMode = enabled }
    }
}
