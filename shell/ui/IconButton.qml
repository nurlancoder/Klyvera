import QtQuick
import QtQuick.Controls as Controls
import "../styles"

Controls.AbstractButton {
    id: root

    property string iconName: ""
    property string accessibleName: ""
    property bool compact: false
    property color glyphColor: "transparent"
    property real iconLevel: 1.0

    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 0
    implicitWidth: Theme.scaled(compact
        ? Theme.accessibility.minimumTargetSize
        : Theme.layout.panel.iconButtonSize)
    implicitHeight: implicitWidth
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName.length > 0 ? accessibleName : iconName

    contentItem: Icon {
        objectName: "iconButtonGlyph"
        anchors.centerIn: parent
        name: root.iconName
        color: root.glyphColor.a > 0
            ? root.glyphColor
            : (!root.enabled ? Theme.textDisabled
                : root.pressed ? Theme.textPrimary : Theme.textSecondary)
        level: root.iconLevel
        size: Theme.scaled(root.compact ? Theme.icon.sizes.sm : Theme.icon.sizes.md)
    }

    background: Rectangle {
        radius: Theme.scaled(Theme.radius.sm)
        color: !root.enabled ? "transparent"
            : root.pressed ? Theme.surfaceActive
            : root.hovered ? Theme.surfaceHover : "transparent"
        border.width: 0
        border.color: Theme.focusRing

        FocusRing {
            show: root.activeFocus
        }
    }

    Tooltip {
        id: tooltip
        text: root.accessibleName
    }

    Timer {
        id: hoverTimer
        interval: 450
        onTriggered: {
            if (root.accessibleName.length > 0)
                tooltip.open()
        }
    }

    onHoveredChanged: {
        if (hovered) {
            hoverTimer.restart()
        } else {
            hoverTimer.stop()
            tooltip.close()
        }
    }
    onActiveFocusChanged: {
        if (activeFocus && root.accessibleName.length > 0)
            tooltip.open()
        else if (!hovered)
            tooltip.close()
    }
}
