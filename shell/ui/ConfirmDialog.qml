Dialog {
    property string confirmText: qsTr("Confirm")
    property string cancelText: qsTr("Cancel")

    primaryText: confirmText
    secondaryText: cancelText
    primaryVariant: "primary"
    closeOnScrim: false

    function confirmAction() {
        accept()
    }
}
