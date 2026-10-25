import QtQuick
import "../styles"

Item {
    id: root

    property string iconName: "folder"
    property color iconColor: Theme.textSecondary
    property string title: ""
    property string message: ""
    property string actionText: ""
    signal actionClicked()

    implicitWidth: Theme.scaled(Theme.layout.spaces.cardMinWidth * 1.25)
    implicitHeight: column.implicitHeight + Theme.scaled(Theme.spacing.lg) * 2
    Accessible.role: Accessible.StaticText
    Accessible.name: message.length > 0 ? title + ". " + message : title

    Column {
        id: column
        anchors.centerIn: parent
        width: Math.min(root.width > 0 ? root.width : root.implicitWidth,
            Theme.scaled(Theme.layout.spaces.cardMinWidth * 1.5))
        spacing: Theme.scaled(Theme.spacing.md)

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.scaled(Theme.spacing.xxxl)
            height: width
            radius: width / 2
            color: Theme.surfaceRaised
            border.width: Theme.scaledInt(Theme.borders.hairline)
            border.color: Theme.borderSubtle

            Icon {
                anchors.centerIn: parent
                name: root.iconName
                color: root.iconColor
                size: Theme.scaled(Theme.icon.sizes.lg)
            }
        }

        Text {
            width: parent.width
            visible: root.title.length > 0
            text: root.title
            color: Theme.textPrimary
            font.family: Theme.typography.uiFamily
            font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
            font.weight: Theme.typography.title.weight
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Text {
            width: parent.width
            visible: root.message.length > 0
            text: root.message
            color: Theme.textSecondary
            font.family: Theme.typography.uiFamily
            font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
            lineHeight: Theme.typography.body.lineHeight / Theme.typography.body.size
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Button {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.actionText.length > 0
            label: root.actionText
            onClicked: root.actionClicked()
        }
    }
}
