import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"

Controls.Popup {
    id: root

    default property alias content: extraContent.data
    property string title: ""
    property string message: ""
    property string primaryText: ""
    property string secondaryText: ""
    property string primaryVariant: "primary"
    property bool closeOnScrim: true
    property bool acceptedPending: false
    signal accepted()
    signal rejected()
    signal confirmed()

    parent: Controls.Overlay.overlay
    anchors.centerIn: parent
    width: Math.min(Theme.scaled(Theme.layout.spaces.cardMinWidth * 1.7),
        parent ? parent.width - Theme.scaled(Theme.spacing.xl) * 2
            : Theme.scaled(Theme.layout.spaces.cardMinWidth * 1.7))
    height: contentItem ? contentItem.implicitHeight : 0
    padding: 0
    modal: true
    dim: true
    focus: true
    closePolicy: Controls.Popup.CloseOnEscape
        | (closeOnScrim ? Controls.Popup.CloseOnPressOutside : 0)
    background: Item { }
    Controls.Overlay.modal: Rectangle { color: Theme.overlay }

    function accept() {
        if (!opened)
            return
        acceptedPending = true
        close()
        accepted()
        confirmed()
    }

    function reject() {
        if (opened)
            close()
    }

    onOpened: {
        acceptedPending = false
        Qt.callLater(function() {
            if (primaryButton.visible)
                primaryButton.forceActiveFocus()
            else if (secondaryButton.visible)
                secondaryButton.forceActiveFocus()
            else
                closeButton.forceActiveFocus()
        })
    }

    onClosed: {
        if (!acceptedPending)
            rejected()
    }

    contentItem: Rectangle {
        implicitHeight: layout.implicitHeight + Theme.scaled(Theme.spacing.lg) * 2
        radius: Theme.scaled(Theme.radius.lg)
        color: Theme.surfaceRaised
        border.width: Theme.scaledInt(Theme.borders.hairline)
        border.color: Theme.borderStrong
        Accessible.role: Accessible.Dialog
        Accessible.name: root.title

        ColumnLayout {
            id: layout
            x: Theme.scaled(Theme.spacing.lg)
            y: Theme.scaled(Theme.spacing.lg)
            width: parent.width - Theme.scaled(Theme.spacing.lg) * 2
            spacing: Theme.scaled(Theme.spacing.md)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(Theme.spacing.sm)

                Text {
                    Layout.fillWidth: true
                    visible: root.title.length > 0
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                    font.weight: Theme.typography.title.weight
                    elide: Text.ElideRight
                }

                IconButton {
                    id: closeButton
                    objectName: "dialogCloseButton"
                    compact: true
                    iconName: "close"
                    accessibleName: qsTr("Close dialog")
                    onClicked: root.reject()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.message.length > 0
                text: root.message
                color: Theme.textSecondary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                lineHeight: Theme.typography.body.lineHeight / Theme.typography.body.size
                wrapMode: Text.Wrap
            }

            Item {
                id: extraContent
                Layout.fillWidth: true
                implicitHeight: childrenRect.height
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
                spacing: Theme.scaled(Theme.spacing.sm)

                Button {
                    id: secondaryButton
                    objectName: "dialogSecondaryButton"
                    visible: root.secondaryText.length > 0
                    label: root.secondaryText
                    variant: "secondary"
                    onClicked: root.reject()
                }

                Button {
                    id: primaryButton
                    objectName: "dialogPrimaryButton"
                    visible: root.primaryText.length > 0
                    label: root.primaryText
                    variant: root.primaryVariant
                    onClicked: root.accept()
                }
            }
        }
    }
}
