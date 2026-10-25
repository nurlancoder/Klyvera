import QtQuick
import QtQuick.Controls as Controls
import "../styles"

Controls.Popup {
    id: root

    property string text: ""

    modal: false
    dim: false
    focus: false
    closePolicy: Controls.Popup.NoAutoClose
    padding: Theme.scaled(Theme.spacing.xs)
    width: Math.min(
        Theme.scaled(Theme.layout.spaces.cardMinWidth),
        label.implicitWidth + padding * 2)
    height: label.implicitHeight + padding * 2
    x: parent ? Math.round((parent.width - width) / 2) : 0
    y: parent ? -height - Theme.scaled(Theme.spacing.xs) : 0

    background: Rectangle {
        color: Theme.surfaceRaised
        radius: Theme.scaled(Theme.radius.sm)
        border.width: Theme.scaledInt(Theme.borders.hairline)
        border.color: Theme.borderStrong
    }

    contentItem: Text {
        id: label
        text: root.text
        color: Theme.textPrimary
        font.family: Theme.typography.uiFamily
        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
        wrapMode: Text.NoWrap
    }
}
