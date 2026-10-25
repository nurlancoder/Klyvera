import QtQuick
import QtQuick.Controls as Controls
import "../styles"

Controls.AbstractButton {
    id: root

    property string label: ""
    property string iconName: ""
    property string variant: "secondary"
    property bool loading: false
    property bool compact: false
    property string accessibleName: label

    readonly property color contentColor: !enabled
        ? Theme.textDisabled
        : (variant === "primary" || variant === "danger")
            ? Theme.onAccent
            : Theme.textPrimary
    readonly property color fillColor: {
        if (!enabled)
            return Theme.surfaceSunken
        if (variant === "primary")
            return pressed ? Qt.darker(Theme.accentPurple, 1.12)
                : hovered ? Qt.lighter(Theme.accentPurple, 1.08) : Theme.accentPurple
        if (variant === "danger")
            return pressed ? Qt.darker(Theme.danger, 1.12)
                : hovered ? Qt.lighter(Theme.danger, 1.08) : Theme.danger
        if (variant === "ghost")
            return pressed ? Theme.surfaceActive : hovered ? Theme.surfaceHover : "transparent"
        return pressed ? Theme.surfaceActive : hovered ? Theme.surfaceHover : Theme.surfaceRaised
    }

    text: label
    enabled: !loading
    hoverEnabled: true
    focusPolicy: Qt.StrongFocus
    padding: 0
    implicitHeight: Theme.scaled(compact
        ? Theme.layout.panel.iconButtonSize
        : Theme.accessibility.preferredTargetSize)
    implicitWidth: Math.max(
        Theme.scaled(Theme.accessibility.minimumTargetSize * 2),
        contentRow.implicitWidth + Theme.scaled(Theme.spacing.md) * 2)
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName.length > 0 ? accessibleName : label
    Accessible.description: loading ? qsTr("Loading") : ""

    contentItem: Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.scaled(Theme.spacing.xs)

        Controls.BusyIndicator {
            visible: root.loading
            running: root.loading
            implicitWidth: Theme.scaled(Theme.icon.sizes.sm)
            implicitHeight: Theme.scaled(Theme.icon.sizes.sm)
        }
        Icon {
            visible: root.iconName.length > 0
            name: root.iconName
            color: root.contentColor
            size: Theme.scaled(Theme.icon.sizes.sm)
        }
        Text {
            visible: root.label.length > 0
            text: root.label
            color: root.contentColor
            font.family: Theme.typography.uiFamily
            font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
            font.weight: root.variant === "primary" || root.variant === "danger"
                ? Theme.typography.weightSemibold : Theme.typography.label.weight
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        radius: Theme.scaled(Theme.radius.sm)
        color: root.fillColor
        border.width: root.variant === "secondary"
            ? Theme.scaledInt(Theme.borders.hairline) : 0
        border.color: Theme.borderStrong

        FocusRing {
            show: root.activeFocus
        }
    }
}
