pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

Item {
    id: root

    property var notifications: []
    property bool doNotDisturb: false
    property string errorText: ""
    readonly property int unreadCount: countUnread()
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"

    signal closeRequested()
    signal clearAllRequested()
    signal dismissRequested(string notificationId)
    signal notificationActivated(string notificationId)
    signal doNotDisturbPicked(bool enabled)

    function countUnread() {
        let count = 0
        for (let i = 0; i < notifications.length; i++) {
            if (!notifications[i].read)
                count += 1
        }
        return count
    }

    function urgencyColor(urgency) {
        return urgency === "critical" ? Theme.danger
            : urgency === "low" ? Theme.textDisabled : Theme.accentBlue
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(Theme.spacing.md)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(Theme.spacing.md)

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: qsTr("Notifications")
                    color: Theme.textPrimary
                    font.family: Theme.typography.headingFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.heading1.size)
                    font.weight: Theme.typography.heading1.weight
                    font.letterSpacing: Theme.typography.heading1.letterSpacing
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: root.unreadCount > 0
                        ? qsTr("%1 unread · kept on this device").arg(root.unreadCount)
                        : qsTr("All caught up · nothing leaves this device")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                    wrapMode: Text.Wrap
                }
            }

            Button {
                label: qsTr("Clear all")
                variant: "ghost"
                compact: true
                enabled: root.notifications.length > 0
                onClicked: root.clearAllRequested()
            }
            IconButton {
                compact: true
                iconName: "close"
                accessibleName: qsTr("Close notifications")
                onClicked: root.closeRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: dndRow.implicitHeight + Theme.scaled(Theme.spacing.sm) * 2
            radius: Theme.scaled(Theme.radius.md)
            color: root.doNotDisturb ? Theme.selection : Theme.surface
            border.width: Theme.scaledInt(Theme.borders.hairline)
            border.color: root.doNotDisturb ? Theme.accentPurple : Theme.borderSubtle

            RowLayout {
                id: dndRow
                anchors.fill: parent
                anchors.margins: Theme.scaled(Theme.spacing.sm)
                spacing: Theme.scaled(Theme.spacing.sm)

                Icon {
                    name: "moon"
                    color: root.doNotDisturb ? Theme.accentPurple : Theme.textSecondary
                    size: Theme.scaled(Theme.icon.sizes.md)
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 0
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: qsTr("Do not disturb")
                        color: Theme.textPrimary
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.bodyStrong.size)
                        font.weight: Theme.typography.bodyStrong.weight
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: root.doNotDisturb
                            ? qsTr("Banners are paused. Notifications are still recorded here.")
                            : qsTr("Pause banners without losing notifications")
                        color: Theme.textSecondary
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                        wrapMode: Text.Wrap
                    }
                }
                Toggle {
                    label: ""
                    checked: root.doNotDisturb
                    implicitWidth: Theme.scaled(Theme.accessibility.minimumTargetSize
                        + Theme.spacing.md + Theme.spacing.sm)
                    Accessible.name: qsTr("Do not disturb")
                    onClicked: root.doNotDisturbPicked(checked)
                }
            }
        }

        ErrorState {
            Layout.fillWidth: true
            visible: root.errorText.length > 0
            message: root.errorText
            actionText: ""
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            visible: root.errorText.length === 0

            Controls.ScrollBar.vertical: Controls.ScrollBar { }

            ColumnLayout {
                id: list
                width: parent.width
                spacing: Theme.scaled(Theme.spacing.xs)

                Repeater {
                    model: root.notifications
                    delegate: Rectangle {
                        id: notificationCard
                        required property var modelData
                        Layout.fillWidth: true
                        implicitHeight: cardBody.implicitHeight + Theme.scaled(Theme.spacing.md) * 2
                        radius: Theme.scaled(Theme.radius.md)
                        color: itemMouse.containsMouse ? Theme.surfaceHover : Theme.surface
                        border.width: Theme.scaledInt(Theme.borders.hairline)
                        border.color: notificationCard.modelData.read ? Theme.borderSubtle : Theme.borderStrong
                        Accessible.role: Accessible.ListItem
                        Accessible.name: notificationCard.modelData.app + ". " + notificationCard.modelData.title + ". " + notificationCard.modelData.body
                        Accessible.description: notificationCard.modelData.read ? qsTr("Read") : qsTr("Unread")

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: Theme.scaled(Theme.borders.strong)
                            radius: parent.radius
                            color: root.urgencyColor(notificationCard.modelData.urgency)
                        }

                        RowLayout {
                            id: cardBody
                            anchors.fill: parent
                            anchors.leftMargin: Theme.scaled(Theme.spacing.md)
                            anchors.rightMargin: Theme.scaled(Theme.spacing.sm)
                            anchors.topMargin: Theme.scaled(Theme.spacing.md)
                            anchors.bottomMargin: Theme.scaled(Theme.spacing.md)
                            spacing: Theme.scaled(Theme.spacing.sm)

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.xxs)

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Theme.scaled(Theme.spacing.xs)

                                    Text {
                                        text: notificationCard.modelData.app
                                        color: root.urgencyColor(notificationCard.modelData.urgency)
                                        font.family: Theme.typography.uiFamily
                                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                        font.weight: Theme.typography.weightSemibold
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: notificationCard.modelData.time
                                        color: Theme.textDisabled
                                        font.family: Theme.typography.monoFamily
                                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                    }
                                    Rectangle {
                                        visible: !notificationCard.modelData.read
                                        width: Theme.scaled(Theme.spacing.xs)
                                        height: width
                                        radius: width / 2
                                        color: Theme.accentPurple
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: notificationCard.modelData.title
                                    color: Theme.textPrimary
                                    font.family: Theme.typography.uiFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.bodyStrong.size)
                                    font.weight: Theme.typography.bodyStrong.weight
                                    wrapMode: Text.Wrap
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: notificationCard.modelData.body
                                    color: Theme.textSecondary
                                    font.family: Theme.typography.uiFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                                    lineHeight: Theme.typography.body.lineHeight / Theme.typography.body.size
                                    wrapMode: Text.Wrap
                                }
                            }

                            IconButton {
                                compact: true
                                iconName: "close"
                                accessibleName: qsTr("Dismiss notification")
                                onClicked: root.dismissRequested(notificationCard.modelData.id)
                            }
                        }

                        MouseArea {
                            id: itemMouse
                            anchors.fill: parent
                            anchors.rightMargin: Theme.scaled(Theme.accessibility.preferredTargetSize)
                            hoverEnabled: true
                            onClicked: root.notificationActivated(notificationCard.modelData.id)
                        }
                    }
                }

                EmptyState {
                    Layout.fillWidth: true
                    visible: root.notifications.length === 0
                    iconName: "bell"
                    title: qsTr("No notifications")
                    message: qsTr("Banners and history stay local. Nothing is synced to an account.")
                }
            }
        }
    }
}
