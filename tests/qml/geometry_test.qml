import QtQuick
import "../../shell/ui"

Item {
    width: 480
    height: 180

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

    IconButton {
        objectName: "geometryIconButton"
        x: 20
        y: 84
        width: 48
        height: 48
        iconName: "plus"
        accessibleName: "Add"
    }

    Tabs {
        objectName: "geometryTabs"
        x: 90
        y: 84
        tabs: ["Overview", "Windows"]
    }

    ListItem {
        objectName: "geometryListItem"
        x: 20
        y: 136
        width: 420
        height: 40
        title: "Project"
        description: "Workspace description"
        iconName: "folder"
    }
}
