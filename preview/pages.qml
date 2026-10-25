import QtQuick
import "../shell/styles"
import "../shell/pages" as Pages
import "../shell/integration" as Integration

Item {
    id: root

    width: 1440
    height: 900
    property string surface: "launcher"
    property string themeName: "dark"
    property bool reduceMotion: true

    onThemeNameChanged: Theme.themeName = themeName
    onReduceMotionChanged: Theme.reduceMotion = reduceMotion

    Component.onCompleted: {
        Theme.themeName = themeName
        Theme.reduceMotion = reduceMotion
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceSunken
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        opacity: 0.35
    }

    Loader {
        anchors.fill: parent
        sourceComponent: root.surface === "launcher" ? launcherPage
            : root.surface === "spaces" ? spacesPage
            : root.surface === "editor" ? editorPage
            : root.surface === "control" ? controlPage
            : root.surface === "notifications" ? notificationsPage
            : root.surface === "monitor" ? monitorPage
            : root.surface === "lock" ? lockPage
            : root.surface === "session" ? sessionPage
            : root.surface === "welcome" ? welcomePage
            : null
    }

    Component {
        id: launcherPage
        Pages.Launcher {
            anchors.fill: parent
            apps: Integration.MockService.apps
            spaces: Integration.MockService.spaces
            settingsPages: Integration.MockService.settingsPages
            recentItems: Integration.MockService.recentItems
        }
    }

    Component {
        id: spacesPage
        Pages.SpacesPage {
            anchors.fill: parent
            spaces: Integration.MockService.spaces
            installedApps: Integration.MockService.apps
            selectedId: Integration.MockService.spaces[0].id
        }
    }

    Component {
        id: editorPage
        Item {
            anchors.fill: parent

            Pages.SpaceEditor {
                anchors.centerIn: parent
                width: Math.min(parent.width - Theme.scaled(Theme.spacing.xl) * 2,
                    Theme.scaled(Theme.layout.spaces.wizardMaxWidth))
                height: parent.height - Theme.scaled(Theme.spacing.lg) * 2
                installedApps: Integration.MockService.apps
                title: qsTr("Edit Space")
                trusted: true
                draft: ({
                    "id": "api-platform",
                    "name": "API platform",
                    "description": "Rust services, terminal and release checks",
                    "icon": "code",
                    "accent": "purple",
                    "projectPaths": ["/home/dev/src/api", "/home/dev/src/shared"],
                    "apps": ["org.klyvera.Terminal.desktop", "org.klyvera.Code.desktop"],
                    "commands": [
                        { "label": "Run tests", "executable": "cargo", "args": ["test"], "cwd": "/home/dev/src/api" }
                    ]
                })
            }
        }
    }

    Component {
        id: controlPage
        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: Theme.overlay
                opacity: 0.55
            }

            Pages.ControlCenter {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: Math.min(Theme.scaled(Theme.layout.controlCenter.widthWide),
                    parent.width - Theme.scaled(Theme.spacing.lg))
                audio: Integration.MockService.audio
                network: Integration.MockService.network
                bluetooth: Integration.MockService.bluetooth
                power: Integration.MockService.power
                displays: Integration.MockService.displays
                shortcuts: Integration.MockService.shortcuts
                host: Integration.MockService.host
                capabilities: Integration.MockService.capabilities
                themeName: Theme.themeName
            }
        }
    }

    Component {
        id: notificationsPage
        Item {
            anchors.fill: parent

            Rectangle {
                anchors.fill: parent
                color: Theme.overlay
                opacity: 0.55
            }

            Pages.NotificationCenter {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                width: Math.min(Theme.scaled(Theme.layout.controlCenter.widthRegular),
                    parent.width - Theme.scaled(Theme.spacing.lg))
                notifications: Integration.MockService.notifications
            }
        }
    }

    Component {
        id: monitorPage
        Pages.SystemMonitor {
            anchors.fill: parent
            monitor: Integration.MockService.monitor
            capabilities: Integration.MockService.capabilities
        }
    }

    Component {
        id: lockPage
        Pages.LockScreen {
            anchors.fill: parent
            userName: "Klyvera"
            hostName: Integration.MockService.host.name
            batteryLevel: Integration.MockService.power.batteryLevel
            networkOnline: Integration.MockService.network.enabled
        }
    }

    Component {
        id: sessionPage
        Pages.SessionMenu {
            anchors.fill: parent
            userName: "Klyvera"
            hostName: Integration.MockService.host.name
            batteryLevel: Integration.MockService.power.batteryLevel
            charging: Integration.MockService.power.charging
            networkOnline: Integration.MockService.network.enabled
        }
    }

    Component {
        id: welcomePage
        Pages.Welcome {
            anchors.fill: parent
            themeName: Theme.themeName
            accent: "purple"
        }
    }
}
