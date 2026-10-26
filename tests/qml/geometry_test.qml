import QtQuick
import "../../shell/ui"

Item {
    width: 320
    height: 100

    Button {
        objectName: "geometryButton"
        x: 40
        y: 20
        width: 240
        height: 48
        label: "Centered action"
        iconName: "plus"
        variant: "primary"
    }
}
