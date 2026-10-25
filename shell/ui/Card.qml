import QtQuick
import QtQuick.Layouts
import "../styles"

Rectangle {
    id: root

    default property alias content: body.data
    property string title: ""
    property string subtitle: ""
    property string actionText: ""
    property real contentPadding: Theme.spacing.md
    signal actionClicked()

    readonly property bool hasHeader: title.length > 0 || subtitle.length > 0 || actionText.length > 0

    implicitWidth: Theme.scaled(Theme.layout.spaces.cardMinWidth)
    implicitHeight: layout.implicitHeight + Theme.scaled(contentPadding) * 2
    color: Theme.surface
    radius: Theme.scaled(Theme.radius.md)
    border.width: Theme.scaledInt(Theme.borders.hairline)
    border.color: Theme.borderSubtle

    ColumnLayout {
        id: layout
        x: Theme.scaled(root.contentPadding)
        y: Theme.scaled(root.contentPadding)
        width: parent.width - Theme.scaled(root.contentPadding) * 2
        spacing: Theme.scaled(Theme.spacing.md)

        RowLayout {
            visible: root.hasHeader
            Layout.fillWidth: true
            spacing: Theme.scaled(Theme.spacing.sm)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    visible: root.title.length > 0
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                    font.weight: Theme.typography.title.weight
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.subtitle.length > 0
                    Layout.fillWidth: true
                    text: root.subtitle
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    elide: Text.ElideRight
                }
            }

            Button {
                visible: root.actionText.length > 0
                label: root.actionText
                variant: "ghost"
                compact: true
                onClicked: root.actionClicked()
            }
        }

        Item {
            id: body
            Layout.fillWidth: true
            implicitHeight: childrenRect.height
        }
    }
}
