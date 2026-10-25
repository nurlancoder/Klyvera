import QtQuick
import QtQuick.Layouts
import "../styles"

Rectangle {
    id: root

    property string message: ""
    property string detail: ""
    property string tone: "info"
    property string actionText: ""
    property int timeout: 4000
    signal actionClicked()
    readonly property color toneColor: tone === "success" ? Theme.success
        : tone === "warning" ? Theme.warning
        : tone === "danger" ? Theme.danger : Theme.info

    visible: false
    implicitWidth: Theme.scaled(Theme.layout.spaces.cardMinWidth * 1.25)
    implicitHeight: layout.implicitHeight + Theme.scaled(Theme.spacing.sm) * 2
    radius: Theme.scaled(Theme.radius.md)
    color: Theme.surfaceRaised
    border.width: Theme.scaledInt(Theme.borders.hairline)
    border.color: Theme.borderStrong
    Accessible.role: Accessible.AlertMessage
    Accessible.name: detail.length > 0 ? message + ". " + detail : message

    function show(text, kind, delay) {
        message = text
        tone = kind !== undefined && kind.length > 0 ? kind : "info"
        timeout = delay !== undefined ? delay : 4000
        visible = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: root.timeout
        running: root.visible && root.timeout > 0
        onTriggered: root.visible = false
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: Theme.scaled(Theme.borders.focus)
        radius: parent.radius
        color: root.toneColor
    }

    RowLayout {
        id: layout
        x: Theme.scaled(Theme.spacing.md)
        y: Theme.scaled(Theme.spacing.sm)
        width: parent.width - Theme.scaled(Theme.spacing.md) * 2
        spacing: Theme.scaled(Theme.spacing.sm)

        Icon {
            name: root.tone === "success" ? "check"
                : root.tone === "danger" || root.tone === "warning" ? "warning"
                : "info"
            color: root.toneColor
            size: Theme.scaled(Theme.icon.sizes.md)
            Layout.alignment: Qt.AlignTop
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.message
                color: Theme.textPrimary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                font.weight: Theme.typography.weightMedium
                wrapMode: Text.Wrap
            }
            Text {
                Layout.fillWidth: true
                visible: root.detail.length > 0
                text: root.detail
                color: Theme.textSecondary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                wrapMode: Text.Wrap
            }
        }

        Button {
            visible: root.actionText.length > 0
            label: root.actionText
            variant: "ghost"
            compact: true
            onClicked: root.actionClicked()
        }

        IconButton {
            compact: true
            iconName: "close"
            accessibleName: qsTr("Dismiss notification")
            onClicked: root.visible = false
        }
    }
}
