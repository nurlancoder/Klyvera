import QtQuick
import "../styles"

Rectangle {
    id: root

    property bool show: false

    visible: show
    anchors.fill: parent
    anchors.margins: -Theme.scaled(Theme.borders.focus
        + Theme.accessibility.focusRingOffset)
    color: "transparent"
    radius: Theme.scaled(Theme.radius.sm)
    border.width: Theme.scaledInt(Theme.borders.focus)
    border.color: Theme.focusRing
    z: 1000
}
