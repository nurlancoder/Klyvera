import QtQuick
import "../styles"

Row {
    id: root

    property bool wifiEnabled: true
    property int volume: 60
    property bool muted: false
    property int unreadNotifications: 0
    property int batteryLevel: 100
    property bool charging: false
    property bool showBatteryPercent: true

    signal indicatorClicked(string indicator)

    spacing: Theme.scaled(Theme.spacing.xxs)
    Accessible.role: Accessible.ToolBar

    IconButton {
        compact: true
        iconName: "wifi"
        glyphColor: !root.wifiEnabled ? Theme.textDisabled : "transparent"
        accessibleName: root.wifiEnabled ? qsTr("Wi-Fi connected") : qsTr("Wi-Fi off")
        onClicked: root.indicatorClicked("wifi")
    }

    IconButton {
        compact: true
        iconName: root.muted || root.volume <= 0 ? "volume-off" : "volume"
        iconLevel: Math.max(0, Math.min(1, root.volume / 100))
        glyphColor: root.muted ? Theme.textDisabled : "transparent"
        accessibleName: root.muted
            ? qsTr("Muted")
            : qsTr("Volume %1 percent").arg(root.volume)
        onClicked: root.indicatorClicked("volume")
    }

    Item {
        width: notificationButton.implicitWidth
        height: notificationButton.implicitHeight

        IconButton {
            id: notificationButton
            anchors.fill: parent
            compact: true
            iconName: "bell"
            accessibleName: root.unreadNotifications > 0
                ? qsTr("%1 unread notifications").arg(root.unreadNotifications)
                : qsTr("Notifications")
            onClicked: root.indicatorClicked("notifications")
        }

        Rectangle {
            visible: root.unreadNotifications > 0
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: Theme.scaled(Theme.spacing.xxs)
            anchors.rightMargin: Theme.scaled(Theme.spacing.xxs)
            width: Math.max(Theme.scaled(Theme.spacing.md),
                countLabel.implicitWidth + Theme.scaled(Theme.spacing.xxs) * 2)
            height: Theme.scaled(Theme.spacing.md)
            radius: height / 2
            color: Theme.danger

            Text {
                id: countLabel
                anchors.centerIn: parent
                text: root.unreadNotifications > 9 ? "9+" : String(root.unreadNotifications)
                color: Theme.onAccent
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                font.weight: Theme.typography.weightBold
            }
        }
    }

    IconButton {
        compact: true
        iconName: "battery"
        iconLevel: Math.max(0, Math.min(1, root.batteryLevel / 100))
        glyphColor: root.batteryLevel <= 15 && !root.charging ? Theme.danger : "transparent"
        accessibleName: qsTr("Battery %1 percent%2")
            .arg(root.batteryLevel)
            .arg(root.charging ? qsTr(", charging") : "")
        onClicked: root.indicatorClicked("battery")
    }

    Text {
        visible: root.showBatteryPercent
        anchors.verticalCenter: parent.verticalCenter
        text: root.batteryLevel + "%"
        color: root.batteryLevel <= 15 && !root.charging
            ? Theme.danger : Theme.textSecondary
        font.family: Theme.typography.uiFamily
        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
        font.weight: Theme.typography.weightMedium
    }
}
