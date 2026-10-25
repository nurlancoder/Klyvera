import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"

Controls.AbstractButton {
    id: root

    property string title: ""
    property string description: ""
    property string iconName: ""
    property string trailingText: ""
    property bool selected: false
    default property alias trailing: trailingSlot.data

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 0
    implicitWidth: Theme.scaled(Theme.layout.spaces.sidebarWidth)
    implicitHeight: Math.max(
        Theme.scaled(Theme.accessibility.preferredTargetSize),
        contentRow.implicitHeight + Theme.scaled(Theme.spacing.sm) * 2)
    Accessible.role: Accessible.ListItem
    Accessible.name: description.length > 0 ? title + ". " + description : title
    Accessible.selected: selected

    contentItem: RowLayout {
        id: contentRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: Theme.scaled(Theme.spacing.md)
        anchors.rightMargin: Theme.scaled(Theme.spacing.md)
        spacing: Theme.scaled(Theme.spacing.sm)

        Icon {
            visible: root.iconName.length > 0
            name: root.iconName
            color: root.selected ? Theme.accentPurple : Theme.textSecondary
            size: Theme.scaled(Theme.icon.sizes.md)
            Layout.alignment: Qt.AlignVCenter
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                color: !root.enabled ? Theme.textDisabled : Theme.textPrimary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.bodyStrong.size)
                font.weight: Theme.typography.bodyStrong.weight
                elide: Text.ElideRight
            }
            Text {
                visible: root.description.length > 0
                Layout.fillWidth: true
                text: root.description
                color: !root.enabled ? Theme.textDisabled : Theme.textSecondary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                elide: Text.ElideRight
            }
        }

        Text {
            visible: root.trailingText.length > 0
            text: root.trailingText
            color: Theme.textSecondary
            font.family: Theme.typography.uiFamily
            font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            Layout.alignment: Qt.AlignVCenter
        }

        Item {
            id: trailingSlot
            Layout.preferredWidth: childrenRect.width
            Layout.preferredHeight: childrenRect.height
            Layout.alignment: Qt.AlignVCenter
        }
    }

    background: Rectangle {
        radius: Theme.scaled(Theme.radius.sm)
        color: root.pressed ? Theme.surfaceActive
            : root.hovered ? Theme.surfaceHover
            : root.selected ? Theme.selection : "transparent"
        border.width: 0
        border.color: Theme.focusRing

        FocusRing {
            show: root.activeFocus
        }

        Rectangle {
            visible: root.selected
            width: Theme.scaled(Theme.borders.focus)
            height: parent.height - Theme.scaled(Theme.spacing.sm) * 2
            x: 0
            y: Theme.scaled(Theme.spacing.sm)
            radius: width / 2
            color: Theme.accentPurple
        }
    }
}
