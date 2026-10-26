// Target-only Quickshell adapter. This file cannot be linted or run on Kali
// because the Quickshell and Hyprland modules are absent. The UI consumes the
// same property/signal contract through pure pages and MockService.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../../styles"
import "../../ui" as UI
import "../../pages" as Pages

ShellRoot {
    id: root

    property bool launcherOpen: false
    property bool controlCenterOpen: false
    property bool notificationsOpen: false
    property bool sessionMenuOpen: false
    property var spaces: []
    property var apps: []
    property var notifications: []
    property var systemBridge: system
    property var notificationBridge: notificationServer
    property string lastError: ""
    property string settingsSection: "appearance"

    readonly property var settingsPages: [
        { "id": "appearance", "name": "Appearance", "description": "Theme, accent, scale and motion", "icon": "sun" },
        { "id": "display", "name": "Display", "description": "Monitors, resolution and refresh", "icon": "grid" },
        { "id": "audio", "name": "Audio", "description": "Output, input and volume", "icon": "volume" },
        { "id": "network", "name": "Network", "description": "Wi-Fi and wired connections", "icon": "wifi" },
        { "id": "bluetooth", "name": "Bluetooth", "description": "Devices and pairing", "icon": "wifi" },
        { "id": "power", "name": "Power", "description": "Battery, profiles and suspend", "icon": "battery" },
        { "id": "shortcuts", "name": "Keyboard shortcuts", "description": "System and Spaces bindings", "icon": "sliders" },
        { "id": "about", "name": "About Klyvera", "description": "Version, host and diagnostics", "icon": "info" }
    ]

    function focusedScreen() {
        const monitor = Hyprland.focusedMonitor
        if (monitor) {
            for (let i = 0; i < Quickshell.screens.length; i++) {
                if (Quickshell.screens[i].name === monitor.name)
                    return Quickshell.screens[i]
            }
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null
    }

    function isFocusedScreen(screen) {
        const monitor = Hyprland.focusedMonitor
        return monitor ? screen.name === monitor.name : screen === Quickshell.screens[0]
    }

    function closeOverlays() {
        launcherOpen = false
        controlCenterOpen = false
        notificationsOpen = false
        sessionMenuOpen = false
    }

    function toggleLauncher() {
        const next = !launcherOpen
        closeOverlays()
        launcherOpen = next
    }

    function toggleControlCenter() {
        const next = !controlCenterOpen
        closeOverlays()
        controlCenterOpen = next
    }

    function toggleNotifications() {
        const next = !notificationsOpen
        closeOverlays()
        notificationsOpen = next
    }

    function toggleSessionMenu() {
        const next = !sessionMenuOpen
        closeOverlays()
        sessionMenuOpen = next
    }

    function dispatchWorkspace(workspace) {
        Hyprland.dispatch("workspace " + workspace)
    }

    function launchDesktopEntry(desktopId) {
        let entry = null
        for (let i = 0; i < DesktopEntries.applications.length; i++) {
            if (DesktopEntries.applications[i].id === desktopId) {
                entry = DesktopEntries.applications[i]
                break
            }
        }
        if (!entry) {
            lastError = "Desktop entry not found: " + desktopId
            return
        }
        entry.execute()
    }

    function openSpace(spaceId) {
        coreOpen.command = ["klyvera", "spaces", "open", spaceId]
        coreOpen.running = true
    }

    function copyDiagnostics() {
        coreDoctor.command = ["klyvera", "doctor", "--json"]
        coreDoctor.running = true
    }

    Component.onCompleted: {
        root.apps = DesktopEntries.applications.map(function(entry) {
            return {
                "id": entry.id,
                "name": entry.name,
                "description": entry.comment ? entry.comment : "",
                "icon": entry.icon,
                "keywords": entry.keywords ? entry.keywords : []
            }
        })
        coreList.running = true
    }

    Process {
        id: coreList
        command: ["klyvera", "spaces", "list", "--json"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const parsed = JSON.parse(text)
                    root.spaces = parsed.spaces ? parsed.spaces : []
                } catch (error) {
                    root.lastError = "Could not read Spaces from klyvera core."
                }
            }
        }
    }

    Process {
        id: coreOpen
        onExited: function(code) {
            if (code !== 0)
                root.lastError = "Klyvera Core could not open the Space."
        }
    }

    Process {
        id: coreDoctor
        stdout: StdioCollector { onStreamFinished: console.log(text) }
    }

    QuickshellSystemBridge {
        id: system
    }

    QuickshellNotificationBridge {
        id: notificationServer
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            anchors.top: true
            anchors.left: true
            anchors.right: true
            implicitHeight: 40
            exclusiveZone: 40
            color: "transparent"

            UI.Panel {
                anchors.fill: parent
                UI.WorkspaceIndicator {
                    workspaces: root.workspaceIds()
                    currentWorkspace: Hyprland.focusedWorkspace
                        ? Hyprland.focusedWorkspace.id : 1
                    onWorkspaceSelected: function(workspace) {
                        root.dispatchWorkspace(workspace)
                    }
                }
                Item { Layout.fillWidth: true }
                UI.Clock {
                    showDate: true
                    Layout.alignment: Qt.AlignVCenter
                }
                UI.SystemIndicators {
                    Layout.alignment: Qt.AlignVCenter
                    wifiEnabled: root.system.network.enabled
                    volume: root.system.audio.volume
                    muted: root.system.audio.muted
                    unreadNotifications: root.notificationServer.notifications.length
                    batteryLevel: root.system.power.batteryLevel
                    charging: root.system.power.charging
                    onIndicatorClicked: function(indicator) {
                        if (indicator === "notifications")
                            root.toggleNotifications()
                        else
                            root.toggleControlCenter()
                    }
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.launcherOpen && root.isFocusedScreen(modelData)
            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Pages.Launcher {
                anchors.fill: parent
                apps: root.apps
                spaces: root.spaces
                settingsPages: root.settingsPages
                recentItems: []
                onDismissed: root.launcherOpen = false
                onAppRequested: function(desktopId) { root.launchDesktopEntry(desktopId) }
                onSpaceRequested: function(spaceId) { root.openSpace(spaceId) }
                onSettingsRequested: function(pageId) {
                    root.settingsSection = pageId
                    root.controlCenterOpen = true
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.controlCenterOpen && root.isFocusedScreen(modelData)
            anchors.top: true
            anchors.right: true
            anchors.bottom: true
            implicitWidth: 460
            color: Theme.surfaceSunken
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Pages.ControlCenter {
                anchors.fill: parent
                anchors.margins: Theme.scaled(Theme.spacing.md)
                section: root.settingsSection
                themeName: Theme.themeName
                interfaceScale: Theme.scale
                audio: root.system.audio
                network: root.system.network
                bluetooth: root.system.bluetooth
                power: root.system.power
                displays: root.system.displays
                shortcuts: root.system.shortcuts
                host: root.system.host
                capabilities: root.system.capabilities
                onCloseRequested: root.controlCenterOpen = false
                onRetryRequested: root.system.refresh()
                onThemeChanged: function(themeName) { Theme.themeName = themeName }
                onDiagnosticsRequested: root.copyDiagnostics()
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.notificationsOpen && root.isFocusedScreen(modelData)
            anchors.top: true
            anchors.right: true
            anchors.bottom: true
            implicitWidth: 420
            color: Theme.surfaceSunken
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Pages.NotificationCenter {
                anchors.fill: parent
                anchors.margins: Theme.scaled(Theme.spacing.md)
                notifications: root.notificationServer.notifications
                doNotDisturb: root.notificationServer.doNotDisturb
                onCloseRequested: root.notificationsOpen = false
                onClearAllRequested: root.notificationServer.clearAll()
                onDismissRequested: function(notificationId) {
                    root.notificationServer.dismiss(notificationId)
                }
                onNotificationActivated: function(notificationId) {
                    root.notificationServer.activate(notificationId)
                }
                onDoNotDisturbPicked: function(enabled) {
                    root.notificationServer.doNotDisturb = enabled
                }
            }
        }
    }

    Variants {
        model: Quickshell.screens

        delegate: PanelWindow {
            required property var modelData
            screen: modelData
            visible: root.sessionMenuOpen && root.isFocusedScreen(modelData)
            anchors.top: true
            anchors.left: true
            anchors.right: true
            anchors.bottom: true
            color: "transparent"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

            Pages.SessionMenu {
                anchors.fill: parent
                userName: root.system.host.name
                hostName: root.system.host.name
                batteryLevel: root.system.power.batteryLevel
                charging: root.system.power.charging
                networkOnline: root.system.network.enabled
                onCloseRequested: root.sessionMenuOpen = false
                onSessionRequested: function(action) {
                    root.sessionMenuOpen = false
                    if (action === "suspend")
                        Quickshell.execDetached(["systemctl", "suspend"])
                    else if (action === "reboot")
                        Quickshell.execDetached(["systemctl", "reboot"])
                    else if (action === "shutdown")
                        Quickshell.execDetached(["systemctl", "poweroff"])
                    else if (action === "logout")
                        Hyprland.dispatch("exit")
                    else if (action === "lock")
                        lockRequested()
                }
            }
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { root.toggleLauncher() }
        function close(): void { root.launcherOpen = false }
    }

    IpcHandler {
        target: "controlcenter"
        function toggle(): void { root.toggleControlCenter() }
        function close(): void { root.controlCenterOpen = false }
    }

    IpcHandler {
        target: "notifications"
        function toggle(): void { root.toggleNotifications() }
        function close(): void { root.notificationsOpen = false }
    }

    IpcHandler {
        target: "session"
        function toggle(): void { root.toggleSessionMenu() }
        function close(): void { root.sessionMenuOpen = false }
    }

    IpcHandler {
        target: "spaces"
        function refresh(): void { coreList.running = true }
        function open(spaceId: string): void { root.openSpace(spaceId) }
    }

    signal lockRequested()

    function workspaceIds() {
        const ids = []
        for (let i = 0; i < Hyprland.workspaces.length; i++)
            ids.push(Hyprland.workspaces[i].id)
        return ids.length > 0 ? ids : [1, 2, 3, 4, 5]
    }
}
