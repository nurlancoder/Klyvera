import QtQuick
import "../styles"

Text {
    id: root

    property bool showDate: false
    property date now: new Date()
    property var locale: Qt.locale()

    text: root.locale.toString(root.now, root.showDate ? "ddd d MMM  HH:mm" : "HH:mm")
    color: Theme.textPrimary
    font.family: Theme.typography.uiFamily
    font.pixelSize: Theme.scaledInt(Theme.typography.bodyStrong.size)
    font.weight: Theme.typography.bodyStrong.weight
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    Accessible.role: Accessible.StaticText
    Accessible.name: text

    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
