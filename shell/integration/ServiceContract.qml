import QtQuick

QtObject {
    id: root

    property var apps: []
    property var spaces: []
    property var settingsPages: []
    property var recentItems: []
    property var notifications: []
    property var displays: []
    property var shortcuts: []
    property var audio: ({
        "available": false,
        "muted": false,
        "volume": 0,
        "outputs": [],
        "inputs": []
    })
    property var network: ({
        "available": false,
        "enabled": false,
        "connections": []
    })
    property var bluetooth: ({
        "available": false,
        "enabled": false,
        "devices": []
    })
    property var power: ({
        "available": false,
        "batteryLevel": 100,
        "charging": false,
        "profile": "balanced",
        "profiles": []
    })
    property var host: ({
        "name": "Klyvera",
        "version": "0.1.0-prototype",
        "kernel": "",
        "session": "wayland",
        "compositor": "unknown"
    })
    property var monitor: ({
        "cpu": 0,
        "memoryUsed": 0,
        "memoryTotal": 0,
        "diskUsed": 0,
        "diskTotal": 0,
        "batteryLevel": 100,
        "processes": []
    })
    property var capabilities: ({
        "audio": false,
        "network": false,
        "bluetooth": false,
        "battery": false,
        "notifications": false,
        "spaces": false
    })

    signal appRequested(string desktopId)
    signal spaceRequested(string spaceId)
    signal settingsRequested(string pageId)
    signal notificationActivated(string notificationId)
    signal sessionRequested(string action)
    signal folderPickerRequested()

    function launchApp(desktopId) {
        appRequested(desktopId)
    }

    function openSpace(spaceId) {
        spaceRequested(spaceId)
    }

    function openSettings(pageId) {
        settingsRequested(pageId)
    }

    function requestSession(action) {
        sessionRequested(action)
    }
}
