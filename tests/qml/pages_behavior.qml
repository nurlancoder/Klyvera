import QtQuick
import "../../shell/pages" as Pages

Item {
    id: root

    width: 1440
    height: 900
    visible: false

    property int launcherCount: launcher.results.length
    property string launcherFirstId: launcher.results.length > 0
        ? String(launcher.results[0].id) : ""
    property bool shellRejected: false
    property bool traversalRejected: false
    property bool validAccepted: false

    function draftWith(command, cwd) {
        return {
            "id": "",
            "name": "Test Space",
            "description": "",
            "icon": "folder",
            "accent": "purple",
            "projectPaths": ["/tmp/klyvera-project"],
            "apps": ["org.klyvera.Code.desktop"],
            "commands": [{
                "label": "Test",
                "executable": command,
                "args": ["test"],
                "cwd": cwd
            }]
        }
    }

    function runChecks() {
        editor.draft = draftWith("bash", "/tmp/klyvera-project")
        shellRejected = !editor.validate()

        editor.draft = draftWith("cargo", "/tmp/klyvera-project/../etc")
        traversalRejected = !editor.validate()

        editor.draft = draftWith("cargo", "/tmp/klyvera-project")
        validAccepted = editor.validate()
    }

    Pages.Launcher {
        id: launcher
        width: root.width
        height: root.height
        apps: [{ "id": "org.klyvera.Code.desktop", "name": "Code", "description": "Source editor", "icon": "code", "keywords": ["editor"] }]
        spaces: []
        settingsPages: []
        recentItems: []
    }

    Pages.SpaceEditor {
        id: editor
        width: 720
        height: 820
        installedApps: [{ "id": "org.klyvera.Code.desktop", "name": "Code", "description": "Source editor", "icon": "code" }]
    }

    Component.onCompleted: runChecks()
}
