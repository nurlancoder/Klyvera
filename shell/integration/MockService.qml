pragma Singleton
import QtQuick

ServiceContract {
    id: root

    apps: [
        { "id": "org.klyvera.Terminal.desktop", "name": "Terminal", "description": "Command line for the project", "icon": "terminal", "keywords": ["shell", "console"] },
        { "id": "org.klyvera.Code.desktop", "name": "Code", "description": "Source editor", "icon": "code", "keywords": ["editor", "ide"] },
        { "id": "org.klyvera.Files.desktop", "name": "Files", "description": "Browse project folders", "icon": "folder", "keywords": ["files", "explorer"] },
        { "id": "org.klyvera.Browser.desktop", "name": "Browser", "description": "Web browser", "icon": "grid", "keywords": ["web", "internet"] },
        { "id": "org.klyvera.Settings.desktop", "name": "Settings", "description": "Appearance and system", "icon": "sliders", "keywords": ["preferences", "control"] },
        { "id": "org.klyvera.Monitor.desktop", "name": "System monitor", "description": "CPU, memory and processes", "icon": "clock", "keywords": ["performance", "resources"] }
    ]

    spaces: [
        {
            "id": "api-platform",
            "name": "API platform",
            "description": "Rust services, terminal and release checks",
            "icon": "code",
            "accent": "purple",
            "projectPaths": ["/home/dev/src/api", "/home/dev/src/shared"],
            "apps": ["org.klyvera.Terminal.desktop", "org.klyvera.Code.desktop"],
            "commands": [
                { "executable": "cargo", "args": ["test"], "cwd": "/home/dev/src/api" }
            ],
            "trusted": true,
            "recent": "12m"
        },
        {
            "id": "design-system",
            "name": "Design system",
            "description": "Tokens, QML components and documentation",
            "icon": "grid",
            "accent": "mint",
            "projectPaths": ["/home/dev/src/klyvera"],
            "apps": ["org.klyvera.Code.desktop", "org.klyvera.Browser.desktop"],
            "commands": [],
            "trusted": true,
            "recent": "1h"
        },
        {
            "id": "release-prep",
            "name": "Release prep",
            "description": "Packaging, checksums and manual checks",
            "icon": "folder",
            "accent": "blue",
            "projectPaths": ["/home/dev/src/klyvera"],
            "apps": ["org.klyvera.Terminal.desktop", "org.klyvera.Files.desktop"],
            "commands": [],
            "trusted": false,
            "recent": "3h"
        }
    ]

    settingsPages: [
        { "id": "appearance", "name": "Appearance", "description": "Theme, accent, scale and motion", "icon": "sun" },
        { "id": "display", "name": "Display", "description": "Monitors, resolution and refresh", "icon": "grid" },
        { "id": "audio", "name": "Audio", "description": "Output, input and volume", "icon": "volume" },
        { "id": "network", "name": "Network", "description": "Wi-Fi and wired connections", "icon": "wifi" },
        { "id": "bluetooth", "name": "Bluetooth", "description": "Devices and pairing", "icon": "wifi" },
        { "id": "power", "name": "Power", "description": "Battery, profiles and suspend", "icon": "battery" },
        { "id": "shortcuts", "name": "Keyboard shortcuts", "description": "System and Spaces bindings", "icon": "sliders" },
        { "id": "about", "name": "About Klyvera", "description": "Version, host and diagnostics", "icon": "info" }
    ]

    recentItems: [
        { "id": "recent-api", "type": "space", "title": "API platform", "subtitle": "Space · 12m ago", "icon": "code" },
        { "id": "recent-code", "type": "app", "title": "Code", "subtitle": "Application", "icon": "code" },
        { "id": "recent-files", "type": "app", "title": "Files", "subtitle": "Application", "icon": "folder" },
        { "id": "recent-logs", "type": "space", "title": "Release prep", "subtitle": "Space · 3h ago", "icon": "folder" }
    ]

    notifications: [
        {
            "id": "n1",
            "app": "Klyvera Spaces",
            "title": "API platform is ready",
            "body": "Four applications opened in their saved workspaces.",
            "time": "2m",
            "urgency": "normal",
            "read": false
        },
        {
            "id": "n2",
            "app": "Backup",
            "title": "Verified backup complete",
            "body": "Space data and configuration were archived with a SHA-256 manifest.",
            "time": "18m",
            "urgency": "low",
            "read": false
        },
        {
            "id": "n3",
            "app": "System",
            "title": "Battery at 22%",
            "body": "Plug in soon or switch to the power saver profile.",
            "time": "1h",
            "urgency": "critical",
            "read": false
        }
    ]

    displays: [
        { "id": "eDP-1", "name": "Built-in display", "width": 2560, "height": 1600, "refresh": 120, "scale": 1.6, "primary": true },
        { "id": "DP-1", "name": "Studio display", "width": 3440, "height": 1440, "refresh": 100, "scale": 1.0, "primary": false }
    ]

    shortcuts: [
        { "action": "Open launcher", "binding": "Super + Space" },
        { "action": "Open control center", "binding": "Super + A" },
        { "action": "Spaces overview", "binding": "Super + Tab" },
        { "action": "Lock screen", "binding": "Super + Escape" },
        { "action": "Notifications", "binding": "Super + N" }
    ]

    audio: ({
        "available": true,
        "muted": false,
        "volume": 64,
        "outputs": [
            { "id": "out-1", "name": "Studio monitors", "description": "USB audio", "active": true },
            { "id": "out-2", "name": "Headphones", "description": "3.5 mm", "active": false }
        ],
        "inputs": [
            { "id": "in-1", "name": "Microphone", "description": "Built-in", "active": true }
        ]
    })

    network: ({
        "available": true,
        "enabled": true,
        "connections": [
            { "id": "wifi-1", "name": "Klyvera Lab", "kind": "wifi", "signal": 86, "active": true },
            { "id": "wifi-2", "name": "Guest", "kind": "wifi", "signal": 54, "active": false },
            { "id": "eth-1", "name": "Wired", "kind": "ethernet", "signal": 100, "active": false }
        ]
    })

    bluetooth: ({
        "available": true,
        "enabled": false,
        "devices": [
            { "id": "bt-1", "name": "Keyboard", "description": "Paired", "connected": true },
            { "id": "bt-2", "name": "Headset", "description": "Not connected", "connected": false }
        ]
    })

    power: ({
        "available": true,
        "batteryLevel": 78,
        "charging": false,
        "profile": "balanced",
        "profiles": ["power-saver", "balanced", "performance"]
    })

    host: ({
        "name": "klyvera-dev",
        "version": "0.1.0-prototype",
        "kernel": "6.12.0",
        "session": "wayland",
        "compositor": "Hyprland"
    })

    monitor: ({
        "cpu": 24,
        "memoryUsed": 9.4,
        "memoryTotal": 32,
        "diskUsed": 214,
        "diskTotal": 512,
        "batteryLevel": 78,
        "processes": [
            { "id": "p1", "name": "klyvera-core", "cpu": 4.2, "memory": 182 },
            { "id": "p2", "name": "Hyprland", "cpu": 2.8, "memory": 214 },
            { "id": "p3", "name": "code", "cpu": 1.6, "memory": 640 },
            { "id": "p4", "name": "firefox", "cpu": 0.8, "memory": 912 }
        ]
    })

    capabilities: ({
        "audio": true,
        "network": true,
        "bluetooth": true,
        "battery": true,
        "notifications": true,
        "spaces": true
    })
}
