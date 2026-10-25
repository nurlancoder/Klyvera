pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import "../styles"

FocusScope {
    id: root

    property var tabs: []
    property int currentIndex: 0
    signal tabSelected(int index)

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    Accessible.role: Accessible.PageTabList
    Accessible.name: qsTr("Tabs")

    function select(index) {
        if (tabs.length === 0)
            return
        const next = (index + tabs.length) % tabs.length
        currentIndex = next
        tabSelected(next)
    }

    function focusTab(index) {
        if (tabs.length === 0)
            return
        const next = (index + tabs.length) % tabs.length
        select(next)
        const item = row.children[next]
        if (item)
            item.forceActiveFocus()
    }

    Row {
        id: row
        spacing: 0

        Repeater {
            model: root.tabs

            delegate: Controls.AbstractButton {
                id: tab
                required property int index
                required property var modelData

                text: String(modelData)
                checkable: true
                checked: root.currentIndex === index
                hoverEnabled: true
                focusPolicy: Qt.StrongFocus
                padding: 0
                implicitHeight: Theme.scaled(Theme.accessibility.preferredTargetSize)
                implicitWidth: label.implicitWidth + Theme.scaled(Theme.spacing.md) * 2
                Accessible.role: Accessible.PageTab
                Accessible.name: String(modelData)
                Accessible.selected: checked
                onClicked: root.select(index)
                Keys.onLeftPressed: root.focusTab(index - 1)
                Keys.onRightPressed: root.focusTab(index + 1)

                contentItem: Text {
                    id: label
                    anchors.centerIn: parent
                    text: tab.text
                    color: tab.checked ? Theme.textPrimary
                        : tab.hovered ? Theme.textPrimary : Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
                    font.weight: tab.checked
                        ? Theme.typography.weightSemibold : Theme.typography.label.weight
                }

                background: Rectangle {
                    color: tab.pressed ? Theme.surfaceActive
                        : tab.hovered ? Theme.surfaceHover : "transparent"
                    border.width: 0
                    border.color: Theme.focusRing

                    FocusRing {
                        show: tab.activeFocus
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: Theme.scaled(Theme.borders.focus)
                        color: tab.checked ? Theme.accentPurple : "transparent"
                    }
                }
            }
        }
    }
}
