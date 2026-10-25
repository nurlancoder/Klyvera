import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"

Controls.AbstractButton {
    id: root

    property string label: ""
    property string description: ""

    checkable: true
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 0
    implicitWidth: Theme.scaled(Theme.layout.spaces.sidebarWidth + Theme.spacing.xl)
    implicitHeight: Math.max(
        Theme.scaled(Theme.accessibility.preferredTargetSize),
        contentRow.implicitHeight + Theme.scaled(Theme.spacing.xs) * 2)
    Accessible.role: Accessible.CheckBox
    Accessible.name: label
    Accessible.description: description
    Accessible.checkable: true
    Accessible.checked: checked

    contentItem: RowLayout {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.scaled(Theme.spacing.sm)
        anchors.rightMargin: Theme.scaled(Theme.spacing.sm)
        spacing: Theme.scaled(Theme.spacing.md)

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.label
                color: !root.enabled ? Theme.textDisabled : Theme.textPrimary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                elide: Text.ElideRight
            }
            Text {
                visible: root.description.length > 0
                Layout.fillWidth: true
                text: root.description
                color: Theme.textSecondary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                wrapMode: Text.Wrap
            }
        }

        Rectangle {
            id: track
            Layout.alignment: Qt.AlignVCenter
            width: Theme.scaled(Theme.accessibility.minimumTargetSize + Theme.spacing.md)
            height: Theme.scaled(Theme.accessibility.minimumTargetSize)
            radius: height / 2
            color: !root.enabled ? Theme.surfaceSunken
                : root.checked ? Theme.accentPurple : Theme.surfaceActive
            border.width: Theme.scaledInt(Theme.borders.hairline)
            border.color: root.checked ? Theme.accentPurple : Theme.borderStrong

            Rectangle {
                id: knob
                readonly property real inset: Theme.scaled(Theme.spacing.xxs - Theme.borders.hairline)
                width: Theme.scaled(Theme.accessibility.minimumTargetSize)
                    - inset * 2
                height: width
                radius: width / 2
                y: inset
                x: root.checked ? track.width - width - inset : inset
                color: !root.enabled ? Theme.textDisabled
                    : root.checked ? Theme.onAccent : Theme.textSecondary

                Behavior on x {
                    NumberAnimation {
                        duration: Theme.motionDuration(Theme.motion.durationFast)
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    background: Rectangle {
        radius: Theme.scaled(Theme.radius.sm)
        color: root.pressed ? Theme.surfaceActive
            : root.hovered ? Theme.surfaceHover : "transparent"
        border.width: 0
        border.color: Theme.focusRing

        FocusRing {
            show: root.activeFocus
        }
    }
}
