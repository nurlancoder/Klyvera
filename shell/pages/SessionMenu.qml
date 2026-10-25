pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

Item {
    id: root

    property string userName: "Klyvera"
    property string hostName: ""
    property int batteryLevel: 100
    property bool charging: false
    property bool networkOnline: true
    property bool busy: false
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"

    signal sessionRequested(string action)
    signal closeRequested()

    function request(action) {
        if (action === "reboot" || action === "shutdown" || action === "logout") {
            confirmAction = action
            confirmDialog.open()
            return
        }
        root.sessionRequested(action)
    }

    property string confirmAction: ""

    function confirmLabel(action) {
        return action === "reboot" ? qsTr("Restart")
            : action === "shutdown" ? qsTr("Shut down") : qsTr("Log out")
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.overlay

        MouseArea {
            anchors.fill: parent
            onClicked: root.closeRequested()
        }
    }

    Rectangle {
        id: panel
        anchors.centerIn: parent
        width: Math.min(Theme.scaled(440), root.width - Theme.scaled(Theme.spacing.xl) * 2)
        height: content.implicitHeight + Theme.scaled(Theme.spacing.lg) * 2
        radius: Theme.scaled(Theme.radius.xl)
        color: Theme.surfaceRaised
        border.width: Theme.scaledInt(Theme.borders.hairline)
        border.color: Theme.borderStrong
        Accessible.role: Accessible.Dialog
        Accessible.name: qsTr("Session menu")

        ColumnLayout {
            id: content
            x: Theme.scaled(Theme.spacing.lg)
            y: Theme.scaled(Theme.spacing.lg)
            width: parent.width - Theme.scaled(Theme.spacing.lg) * 2
            spacing: Theme.scaled(Theme.spacing.md)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(Theme.spacing.sm)

                Rectangle {
                    width: Theme.scaled(Theme.spacing.xxl)
                    height: width
                    radius: width / 2
                    color: Theme.selection

                    Text {
                        anchors.centerIn: parent
                        text: root.userName.length > 0 ? root.userName[0].toUpperCase() : "K"
                        color: Theme.accentPurple
                        font.family: Theme.typography.headingFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                        font.weight: Theme.typography.weightBold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text {
                        text: root.userName
                        color: Theme.textPrimary
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.bodyStrong.size)
                        font.weight: Theme.typography.bodyStrong.weight
                    }
                    Text {
                        text: root.hostName
                        color: Theme.textSecondary
                        font.family: Theme.typography.monoFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    }
                }

                IconButton {
                    compact: true
                    iconName: "close"
                    accessibleName: qsTr("Close session menu")
                    onClicked: root.closeRequested()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaledInt(Theme.borders.hairline)
                color: Theme.borderSubtle
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(Theme.spacing.sm)

                Icon {
                    name: "wifi"
                    color: root.networkOnline ? Theme.accentMint : Theme.textDisabled
                    size: Theme.scaled(Theme.icon.sizes.sm)
                }
                Text {
                    Layout.fillWidth: true
                    text: root.networkOnline ? qsTr("Network connected") : qsTr("Offline")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                }
                Icon {
                    name: "battery"
                    level: root.batteryLevel / 100
                    color: root.batteryLevel <= 15 ? Theme.danger : Theme.textSecondary
                    size: Theme.scaled(Theme.icon.sizes.sm)
                }
                Text {
                    text: root.batteryLevel + "%" + (root.charging ? qsTr(", charging") : "")
                    color: Theme.textSecondary
                    font.family: Theme.typography.monoFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Theme.scaled(Theme.spacing.xs)
                rowSpacing: Theme.scaled(Theme.spacing.xs)

                Repeater {
                    model: [
                        { "id": "lock", "label": qsTr("Lock"), "icon": "moon" },
                        { "id": "logout", "label": qsTr("Log out"), "icon": "arrow-right" },
                        { "id": "suspend", "label": qsTr("Suspend"), "icon": "moon" },
                        { "id": "reboot", "label": qsTr("Restart"), "icon": "refresh" },
                        { "id": "shutdown", "label": qsTr("Shut down"), "icon": "power" }
                    ]
                    delegate: Controls.AbstractButton {
                        id: actionTile
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.scaled(Theme.accessibility.preferredTargetSize)
                        hoverEnabled: true
                        focusPolicy: Qt.StrongFocus
                        padding: 0
                        enabled: !root.busy
                        Accessible.role: Accessible.Button
                        Accessible.name: actionTile.modelData.label
                        onClicked: root.request(actionTile.modelData.id)

                        contentItem: RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: Theme.scaled(Theme.spacing.sm)
                            anchors.rightMargin: Theme.scaled(Theme.spacing.sm)
                            spacing: Theme.scaled(Theme.spacing.xs)

                            Icon {
                                name: actionTile.modelData.icon
                                color: actionTile.modelData.id === "shutdown" || actionTile.modelData.id === "reboot"
                                    ? Theme.danger : Theme.textSecondary
                                size: Theme.scaled(Theme.icon.sizes.sm)
                            }
                            Text {
                                Layout.fillWidth: true
                                text: actionTile.modelData.label
                                color: Theme.textPrimary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                            }
                        }
                        background: Rectangle {
                            radius: Theme.scaled(Theme.radius.sm)
                            color: actionTile.hovered ? Theme.surfaceHover : Theme.surface
                            border.width: Theme.scaledInt(Theme.borders.hairline)
                            border.color: Theme.borderSubtle
                            FocusRing { show: actionTile.activeFocus }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Destructive session actions always ask for confirmation.")
                color: Theme.textDisabled
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }

    ConfirmDialog {
        id: confirmDialog
        title: qsTr("%1?").arg(root.confirmLabel(root.confirmAction))
        message: qsTr("Close applications and continue? Unsaved work may be lost.")
        confirmText: root.confirmLabel(root.confirmAction)
        cancelText: qsTr("Cancel")
        primaryVariant: "danger"
        onAccepted: root.sessionRequested(root.confirmAction)
    }
}
