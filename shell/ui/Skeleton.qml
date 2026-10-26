import QtQuick
import "../styles"

Rectangle {
    id: root

    property string variant: "block"
    property bool animated: true

    implicitWidth: Theme.scaled(Theme.layout.spaces.cardMinWidth)
    implicitHeight: variant === "text" ? Theme.scaled(Theme.spacing.sm)
        : Theme.scaled(Theme.spacing.md)
    radius: variant === "circle" ? width / 2 : Theme.scaled(Theme.radius.sm)
    color: Theme.surfaceHover
    clip: true
    Accessible.ignored: true

    Rectangle {
        id: shimmer
        width: root.width * 0.35
        height: root.height
        color: Theme.surfaceRaised
        opacity: 0.65
        visible: !Theme.reduceMotion

        NumberAnimation on x {
            from: -shimmer.width
            to: root.width
            duration: Theme.motion.durationSlow * 4
            loops: Animation.Infinite
            running: root.visible && root.animated && !Theme.reduceMotion
            easing.type: Easing.InOutSine
        }
    }
}
