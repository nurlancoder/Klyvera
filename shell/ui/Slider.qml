import QtQuick
import "../styles"

FocusScope {
    id: root

    property string label: ""
    property real from: 0
    property real to: 100
    property real value: 0
    property real stepSize: 1
    property string valueSuffix: ""

    readonly property real ratio: to > from
        ? Math.max(0, Math.min(1, (value - from) / (to - from)))
        : 0
    readonly property string valueText: {
        const rounded = Math.round(value * 10) / 10
        return rounded.toLocaleString(Qt.locale(), "f", rounded % 1 === 0 ? 0 : 1) + valueSuffix
    }

    implicitWidth: Theme.scaled(Theme.layout.spaces.sidebarWidth)
    implicitHeight: column.implicitHeight
    Accessible.role: Accessible.Slider
    Accessible.name: label.length > 0 ? label : qsTr("Slider")
    Accessible.description: valueText

    function clamp(candidate) {
        return Math.max(from, Math.min(to, candidate))
    }

    function snap(candidate) {
        if (stepSize <= 0)
            return clamp(candidate)
        return clamp(from + Math.round((candidate - from) / stepSize) * stepSize)
    }

    function setFromPosition(position, width) {
        if (width <= 0)
            return
        value = snap(from + Math.max(0, Math.min(1, position / width)) * (to - from))
    }

    function stepBy(steps) {
        value = snap(value + steps * stepSize)
    }

    Keys.onPressed: function(event) {
        switch (event.key) {
        case Qt.Key_Left:
        case Qt.Key_Down:
            stepBy(-1)
            break
        case Qt.Key_Right:
        case Qt.Key_Up:
            stepBy(1)
            break
        case Qt.Key_PageUp:
            stepBy(10)
            break
        case Qt.Key_PageDown:
            stepBy(-10)
            break
        case Qt.Key_Home:
            value = from
            break
        case Qt.Key_End:
            value = to
            break
        default:
            return
        }
        event.accepted = true
    }

    Column {
        id: column
        width: parent.width
        spacing: Theme.scaled(Theme.spacing.xs)

        Row {
            width: parent.width
            spacing: Theme.scaled(Theme.spacing.sm)

            Text {
                id: labelText
                text: root.label
                color: Theme.textSecondary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                font.weight: Theme.typography.caption.weight
            }
            Item {
                width: Math.max(0, parent.width - labelText.width - valueLabel.width
                    - Theme.scaled(Theme.spacing.sm) * 2)
                height: 1
            }
            Text {
                id: valueLabel
                text: root.valueText
                color: Theme.textPrimary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                font.weight: Theme.typography.weightSemibold
            }
        }

        Rectangle {
            id: track
            width: parent.width
            height: Theme.scaled(Theme.accessibility.minimumTargetSize)
            color: "transparent"
            radius: Theme.scaled(Theme.radius.sm)
            border.width: 0
            border.color: Theme.focusRing

            FocusRing {
                show: root.activeFocus
            }

            Rectangle {
                id: groove
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: Theme.scaled(Theme.spacing.xs - Theme.borders.hairline)
                radius: height / 2
                color: Theme.surfaceActive
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: root.ratio * parent.width
                height: groove.height
                radius: groove.radius
                color: root.enabled ? Theme.accentPurple : Theme.textDisabled
            }

            Rectangle {
                id: knob
                width: Theme.scaled(Theme.accessibility.minimumTargetSize)
                    - Theme.scaled(Theme.spacing.xxs)
                height: width
                radius: width / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.ratio * (track.width - width)
                color: root.activeFocus ? Theme.focusRing
                    : root.enabled ? Theme.accentPurple : Theme.textDisabled
                border.width: Theme.scaledInt(Theme.borders.hairline)
                border.color: Theme.surfaceSunken
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onPressed: function(mouse) {
                    root.forceActiveFocus()
                    root.setFromPosition(mouse.x, track.width)
                }
                onPositionChanged: function(mouse) {
                    if (pressed)
                        root.setFromPosition(mouse.x, track.width)
                }
            }
        }
    }
}
