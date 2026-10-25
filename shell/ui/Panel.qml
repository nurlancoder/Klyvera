import QtQuick
import QtQuick.Layouts
import "../styles"

Rectangle {
    id: root

    default property alias content: contentRow.data
    property real contentSpacing: Theme.layout.panel.gap
    property real horizontalPadding: Theme.layout.panel.padding

    implicitHeight: Theme.scaled(Theme.layout.panel.height)
    color: Theme.surface
    border.width: Theme.scaledInt(Theme.borders.hairline)
    border.color: Theme.borderSubtle

    RowLayout {
        id: contentRow
        anchors.fill: parent
        anchors.leftMargin: Theme.scaled(root.horizontalPadding)
        anchors.rightMargin: Theme.scaled(root.horizontalPadding)
        spacing: Theme.scaled(root.contentSpacing)
    }
}
