import QtQuick
import "../styles"

Item {
    id: root

    property string label: ""
    property string placeholder: ""
    property string helperText: ""
    property string errorText: ""
    property string leadingIcon: ""
    property bool showClear: false
    property bool readOnly: false
    property string text: ""
    onTextChanged: {
        if (input.text !== text)
            input.text = text
    }
    property alias echoMode: input.echoMode
    property alias maximumLength: input.maximumLength
    property alias inputMethodHints: input.inputMethodHints
    property bool handleNavigationKeys: false
    signal accepted()
    signal navigationRequested(int key)
    signal escapePressed()

    readonly property bool hasError: errorText.length > 0
    implicitWidth: Theme.scaled(Theme.layout.spaces.sidebarWidth)
    implicitHeight: column.implicitHeight

    function focusInput() {
        input.forceActiveFocus()
    }

    function clear() {
        text = ""
        input.forceActiveFocus()
    }

    Column {
        id: column
        width: parent.width
        spacing: Theme.scaled(Theme.spacing.xs)

        Text {
            visible: root.label.length > 0
            text: root.label
            color: root.hasError ? Theme.danger : Theme.textSecondary
            font.family: Theme.typography.uiFamily
            font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
            font.weight: Theme.typography.label.weight
            Accessible.ignored: true
        }

        Rectangle {
            id: field
            width: parent.width
            height: Theme.scaled(Theme.accessibility.preferredTargetSize)
            radius: Theme.scaled(Theme.radius.sm)
            color: root.readOnly ? Theme.surfaceSunken : Theme.surface
            border.width: root.hasError
                ? Theme.scaledInt(Theme.borders.focus)
                : Theme.scaledInt(Theme.borders.hairline)
            border.color: root.hasError ? Theme.danger : Theme.borderStrong

            FocusRing {
                show: input.activeFocus
            }

            Icon {
                id: leading
                visible: root.leadingIcon.length > 0
                anchors.left: parent.left
                anchors.leftMargin: Theme.scaled(Theme.spacing.sm)
                anchors.verticalCenter: parent.verticalCenter
                name: root.leadingIcon
                color: root.hasError ? Theme.danger : Theme.textSecondary
                size: Theme.scaled(Theme.icon.sizes.sm)
            }

            IconButton {
                id: clearButton
                visible: root.showClear && input.text.length > 0 && !root.readOnly
                anchors.right: parent.right
                anchors.rightMargin: Theme.scaled(Theme.spacing.xxs)
                anchors.verticalCenter: parent.verticalCenter
                compact: true
                iconName: "close"
                accessibleName: qsTr("Clear text")
                onClicked: root.clear()
            }

            Text {
                id: placeholderLabel
                visible: input.text.length === 0 && root.placeholder.length > 0
                anchors.left: leading.visible ? leading.right : parent.left
                anchors.leftMargin: leading.visible
                    ? Theme.scaled(Theme.spacing.xs)
                    : Theme.scaled(Theme.spacing.sm)
                anchors.right: clearButton.visible ? clearButton.left : parent.right
                anchors.rightMargin: Theme.scaled(Theme.spacing.sm)
                anchors.verticalCenter: parent.verticalCenter
                text: root.placeholder
                color: Theme.textDisabled
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                elide: Text.ElideRight
                Accessible.ignored: true
            }

            TextInput {
                id: input
                text: root.text
                onTextChanged: {
                    if (root.text !== text)
                        root.text = text
                }
                anchors.left: leading.visible ? leading.right : parent.left
                anchors.leftMargin: leading.visible
                    ? Theme.scaled(Theme.spacing.xs)
                    : Theme.scaled(Theme.spacing.sm)
                anchors.right: clearButton.visible
                    ? clearButton.left : parent.right
                anchors.rightMargin: Theme.scaled(Theme.spacing.sm)
                anchors.verticalCenter: parent.verticalCenter
                height: implicitHeight
                color: root.readOnly ? Theme.textSecondary : Theme.textPrimary
                selectionColor: Theme.selection
                selectedTextColor: Theme.textPrimary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                selectByMouse: true
                readOnly: root.readOnly
                clip: true
                Accessible.role: Accessible.EditableText
                Accessible.name: root.label.length > 0 ? root.label : root.placeholder
                Accessible.description: root.hasError ? root.errorText : root.helperText
                Accessible.focusable: true
                onAccepted: root.accepted()
                Keys.onPressed: function(event) {
                    if (root.handleNavigationKeys
                        && (event.key === Qt.Key_Up || event.key === Qt.Key_Down
                            || event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown)) {
                        root.navigationRequested(event.key)
                        event.accepted = true
                    }
                }
                Keys.onEscapePressed: {
                    if (root.showClear && text.length > 0)
                        root.clear()
                    else
                        root.escapePressed()
                }
            }

            TapHandler {
                onTapped: root.focusInput()
            }
        }

        Text {
            visible: root.hasError || root.helperText.length > 0
            width: parent.width
            text: root.hasError ? root.errorText : root.helperText
            color: root.hasError ? Theme.danger : Theme.textSecondary
            font.family: Theme.typography.uiFamily
            font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            wrapMode: Text.Wrap
            Accessible.ignored: true
        }
    }
}
