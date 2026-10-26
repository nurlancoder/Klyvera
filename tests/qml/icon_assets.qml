import QtQuick
import "../../shell/ui"

Item {
    width: IconCatalog.names.length * 24
    height: 24

    Row {
        Repeater {
            model: IconCatalog.names

            delegate: Icon {
                objectName: "icon-" + modelData
                width: 24
                height: 24
                name: modelData
                color: "#FF00FF"
                level: 0.5
            }
        }
    }
}
