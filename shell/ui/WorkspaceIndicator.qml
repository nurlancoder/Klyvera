pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import "../styles"

Row {
    id: root

    property var workspaces: [1, 2, 3, 4, 5]
    property int currentWorkspace: 1
    signal workspaceSelected(int workspace)

    spacing: Theme.scaled(Theme.spacing.xxs)
    Accessible.role: Accessible.PageTabList
    Accessible.name: qsTr("Workspaces")

    function select(workspace) {
        currentWorkspace = workspace
        workspaceSelected(workspace)
    }

    function focusWorkspace(index) {
        if (workspaces.length === 0)
            return
        const next = (index + workspaces.length) % workspaces.length
        const item = children[next]
        select(workspaces[next])
        if (item)
            item.forceActiveFocus()
    }

    Repeater {
        model: root.workspaces

        delegate: Controls.AbstractButton {
            id: button
            required property int index
            required property var modelData

            readonly property bool active: root.currentWorkspace === modelData
            hoverEnabled: true
            focusPolicy: Qt.StrongFocus
            padding: 0
            implicitWidth: Theme.scaled(Theme.spacing.xl)
            implicitHeight: Theme.scaled(Theme.accessibility.minimumTargetSize)
            Accessible.role: Accessible.PageTab
            Accessible.name: qsTr("Workspace %1").arg(modelData)
            Accessible.selected: active
            onClicked: root.select(modelData)
            Keys.onLeftPressed: root.focusWorkspace(index - 1)
            Keys.onRightPressed: root.focusWorkspace(index + 1)

            contentItem: Item {
                anchors.fill: parent

                Rectangle {
                    id: dot
                    anchors.centerIn: parent
                    width: button.active ? Theme.scaled(Theme.spacing.lg)
                        : button.hovered ? Theme.scaled(Theme.spacing.md)
                        : Theme.scaled(Theme.spacing.sm)
                    height: Theme.scaled(Theme.spacing.sm)
                    radius: height / 2
                    color: button.active ? Theme.accentPurple
                        : button.hovered ? Theme.textSecondary : Theme.borderStrong

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.motion.durationFast
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            background: Rectangle {
                radius: Theme.scaled(Theme.radius.sm)
                color: button.pressed ? Theme.surfaceActive
                    : button.hovered ? Theme.surfaceHover : "transparent"
                border.width: 0
                border.color: Theme.focusRing

                FocusRing {
                    show: button.activeFocus
                }
            }
        }
    }
}
