import QtQuick
import "../../shell/styles"
import "../../shell/ui"

Item {
    id: testRoot

    width: 800
    height: 600
    property string lastEvent: ""

    Button {
        objectName: "underlyingButton"
        label: "Underlying"
        x: Theme.scaled(Theme.spacing.md)
        y: Theme.scaled(Theme.spacing.md)
    }

    Dialog {
        id: dialog
        objectName: "focusDialog"
        title: "Focus test"
        message: "Tab and Backtab must stay inside the dialog."
        primaryText: "Confirm"
        secondaryText: "Cancel"
        onRejected: testRoot.lastEvent = "rejected"
        onAccepted: testRoot.lastEvent = "accepted"
    }
}
