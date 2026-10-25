pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

Item {
    id: root

    property string section: "appearance"
    property string themeName: "dark"
    property string accent: "purple"
    property real interfaceScale: 1.0
    property bool reduceMotion: false
    property bool nightLight: false
    property bool batterySaver: false
    property var audio: ({ "available": false, "volume": 0, "muted": false, "outputs": [], "inputs": [] })
    property var network: ({ "available": false, "enabled": false, "connections": [] })
    property var bluetooth: ({ "available": false, "enabled": false, "devices": [] })
    property var power: ({ "available": false, "batteryLevel": 100, "charging": false, "profile": "balanced", "profiles": [] })
    property var displays: []
    property var shortcuts: []
    property var host: ({ "version": "0.1.0-prototype", "kernel": "", "session": "wayland", "compositor": "unknown" })
    property var capabilities: ({ "audio": false, "network": false, "bluetooth": false, "battery": false })
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"
    readonly property var sections: [
        { "id": "appearance", "name": qsTr("Appearance"), "icon": "sun" },
        { "id": "display", "name": qsTr("Display"), "icon": "grid" },
        { "id": "audio", "name": qsTr("Audio"), "icon": "volume" },
        { "id": "network", "name": qsTr("Network"), "icon": "wifi" },
        { "id": "bluetooth", "name": qsTr("Bluetooth"), "icon": "wifi" },
        { "id": "power", "name": qsTr("Power"), "icon": "battery" },
        { "id": "shortcuts", "name": qsTr("Shortcuts"), "icon": "sliders" },
        { "id": "about", "name": qsTr("About"), "icon": "info" }
    ]

    signal themeChanged(string themeName)
    signal accentPicked(string accent)
    signal scalePicked(real scale)
    signal reduceMotionPicked(bool enabled)
    signal nightLightPicked(bool enabled)
    signal volumeChanged(real volume)
    signal mutedChanged(bool muted)
    signal audioDeviceSelected(string deviceId)
    signal networkToggled(bool enabled)
    signal networkConnectionRequested(string connectionId)
    signal bluetoothToggled(bool enabled)
    signal bluetoothDeviceRequested(string deviceId)
    signal powerProfileChanged(string profile)
    signal batterySaverPicked(bool enabled)
    signal diagnosticsRequested()
    signal retryRequested()
    signal closeRequested()

    function accentColor(value) {
        return value === "blue" ? Theme.accentBlue
            : value === "mint" ? Theme.accentMint : Theme.accentPurple
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(Theme.spacing.md)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(Theme.spacing.sm)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: qsTr("Control center")
                    color: Theme.textPrimary
                    font.family: Theme.typography.headingFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.heading1.size)
                    font.weight: Theme.typography.heading1.weight
                    font.letterSpacing: Theme.typography.heading1.letterSpacing
                }
                Text {
                    text: qsTr("Local settings, system services and device controls.")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                    wrapMode: Text.Wrap
                }
            }

            Button {
                label: qsTr("Done")
                variant: "secondary"
                compact: true
                onClicked: root.closeRequested()
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: root.compact ? 2 : 4
            columnSpacing: Theme.scaled(Theme.spacing.xs)
            rowSpacing: Theme.scaled(Theme.spacing.xs)

            Repeater {
                model: root.sections

                delegate: Controls.AbstractButton {
                    id: tile
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(Theme.accessibility.preferredTargetSize)
                    hoverEnabled: true
                    focusPolicy: Qt.StrongFocus
                    padding: 0
                    Accessible.role: Accessible.PageTab
                    Accessible.name: tile.modelData.name
                    Accessible.selected: root.section === tile.modelData.id
                    onClicked: root.section = tile.modelData.id

                    contentItem: RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.scaled(Theme.spacing.sm)
                        anchors.rightMargin: Theme.scaled(Theme.spacing.sm)
                        spacing: Theme.scaled(Theme.spacing.xs)

                        Icon {
                            name: tile.modelData.icon
                            color: root.section === tile.modelData.id
                                ? Theme.accentPurple : Theme.textSecondary
                            size: Theme.scaled(Theme.icon.sizes.sm)
                        }
                        Text {
                            Layout.fillWidth: true
                            text: tile.modelData.name
                            color: root.section === tile.modelData.id
                                ? Theme.textPrimary : Theme.textSecondary
                            font.family: Theme.typography.uiFamily
                            font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                            font.weight: root.section === tile.modelData.id
                                ? Theme.typography.weightSemibold : Theme.typography.weightMedium
                            elide: Text.ElideRight
                        }
                    }

                    background: Rectangle {
                        radius: Theme.scaled(Theme.radius.sm)
                        color: root.section === tile.modelData.id
                            ? Theme.selection
                            : tile.hovered ? Theme.surfaceHover : Theme.surface
                        border.width: Theme.scaledInt(Theme.borders.hairline)
                        border.color: root.section === tile.modelData.id
                            ? Theme.accentPurple : Theme.borderSubtle
                        FocusRing { show: tile.activeFocus }
                    }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: contentBody.implicitHeight + Theme.scaled(Theme.spacing.md)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar { }

            ColumnLayout {
                id: contentBody
                width: parent.width
                spacing: Theme.scaled(Theme.spacing.md)

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "appearance"
                    spacing: Theme.scaled(Theme.spacing.md)

                    Card {
                        Layout.fillWidth: true
                        title: qsTr("Theme")
                        subtitle: qsTr("Calm by default, high contrast when you need it")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.md)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.xs)

                                Repeater {
                                    model: [
                                        { "id": "dark", "name": qsTr("Dark") },
                                        { "id": "light", "name": qsTr("Light") },
                                        { "id": "highContrast", "name": qsTr("High contrast") }
                                    ]
                                    delegate: Button {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        label: modelData.name
                                        variant: root.themeName === modelData.id ? "primary" : "secondary"
                                        onClicked: root.themeChanged(modelData.id)
                                    }
                                }
                            }

                            Text {
                                text: qsTr("Accent")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
                            }

                            RowLayout {
                                spacing: Theme.scaled(Theme.spacing.sm)

                                Repeater {
                                    model: ["purple", "blue", "mint"]
                                    delegate: Controls.AbstractButton {
                                        id: swatch
                                        required property string modelData
                                        implicitWidth: Theme.scaled(Theme.accessibility.preferredTargetSize)
                                        implicitHeight: implicitWidth
                                        padding: 0
                                        Accessible.role: Accessible.RadioButton
                                        Accessible.name: qsTr("%1 accent").arg(swatch.modelData)
                                        Accessible.selected: root.accent === swatch.modelData
                                        onClicked: root.accentPicked(swatch.modelData)

                                        contentItem: Rectangle {
                                            anchors.centerIn: parent
                                            width: Theme.scaled(Theme.spacing.lg)
                                            height: width
                                            radius: width / 2
                                            color: root.accentColor(swatch.modelData)
                                            border.width: root.accent === swatch.modelData
                                                ? Theme.scaledInt(Theme.borders.focus) : 0
                                            border.color: Theme.textPrimary
                                        }
                                        background: Rectangle {
                                            radius: Theme.scaled(Theme.radius.sm)
                                            color: swatch.hovered ? Theme.surfaceHover : "transparent"
                                            FocusRing { show: swatch.activeFocus }
                                        }
                                    }
                                }
                            }

                            Slider {
                                Layout.fillWidth: true
                                label: qsTr("Interface scale")
                                from: 80
                                to: 140
                                stepSize: 5
                                value: root.interfaceScale * 100
                                valueSuffix: "%"
                                onMoved: function(value) { root.scalePicked(value / 100) }
                            }

                            Toggle {
                                Layout.fillWidth: true
                                label: qsTr("Reduce motion")
                                description: qsTr("Remove transitions and animated loaders")
                                checked: root.reduceMotion
                                onClicked: root.reduceMotionPicked(checked)
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "display"
                    spacing: Theme.scaled(Theme.spacing.md)

                    Card {
                        Layout.fillWidth: true
                        title: qsTr("Displays")
                        subtitle: qsTr("One panel per output, portrait or landscape")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.xxs)

                            Repeater {
                                model: root.displays
                                delegate: ListItem {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    title: modelData.name
                                    description: modelData.width + " × " + modelData.height
                                        + " · " + modelData.refresh + " Hz · "
                                        + Math.round(modelData.scale * 100) + "%"
                                    iconName: "grid"
                                    trailingText: modelData.primary ? qsTr("Primary") : modelData.id
                                    selected: modelData.primary
                                    enabled: false
                                }
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        title: qsTr("Comfort")
                        subtitle: qsTr("Reduce eye strain without changing the palette")

                        Toggle {
                            width: parent.width
                            label: qsTr("Night light")
                            description: qsTr("Warm the display after sunset when the compositor supports it")
                            checked: root.nightLight
                            onClicked: root.nightLightPicked(checked)
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "audio"
                    spacing: Theme.scaled(Theme.spacing.md)

                    MissingService {
                        Layout.fillWidth: true
                        visible: !root.capabilities.audio || !root.audio.available
                        serviceName: qsTr("Audio")
                        detail: qsTr("PipeWire or WirePlumber is not available in this session.")
                    }

                    Card {
                        Layout.fillWidth: true
                        visible: root.capabilities.audio && root.audio.available
                        title: qsTr("Output")
                        subtitle: qsTr("Volume and routing")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            Slider {
                                Layout.fillWidth: true
                                label: qsTr("Volume")
                                from: 0
                                to: 100
                                value: root.audio.volume
                                valueSuffix: "%"
                                onMoved: function(value) { root.volumeChanged(value) }
                            }
                            Toggle {
                                Layout.fillWidth: true
                                label: qsTr("Mute")
                                description: qsTr("Silence all output without losing the level")
                                checked: root.audio.muted
                                onClicked: root.mutedChanged(checked)
                            }

                            Repeater {
                                model: root.audio.outputs
                                delegate: ListItem {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    title: modelData.name
                                    description: modelData.description
                                    iconName: "volume"
                                    trailingText: modelData.active ? qsTr("Active") : ""
                                    selected: modelData.active
                                    onClicked: root.audioDeviceSelected(modelData.id)
                                }
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        visible: root.capabilities.audio && root.audio.available
                        title: qsTr("Input")
                        subtitle: qsTr("Microphones and capture devices")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.xxs)

                            Repeater {
                                model: root.audio.inputs
                                delegate: ListItem {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    title: modelData.name
                                    description: modelData.description
                                    iconName: "volume"
                                    trailingText: modelData.active ? qsTr("Active") : ""
                                    selected: modelData.active
                                    onClicked: root.audioDeviceSelected(modelData.id)
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "network"
                    spacing: Theme.scaled(Theme.spacing.md)

                    MissingService {
                        Layout.fillWidth: true
                        visible: !root.capabilities.network || !root.network.available
                        serviceName: qsTr("Network")
                        detail: qsTr("NetworkManager is not available. Wired connections may still work.")
                    }

                    Card {
                        Layout.fillWidth: true
                        visible: root.capabilities.network && root.network.available
                        title: qsTr("Network")
                        subtitle: qsTr("Wi-Fi and wired connections")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            Toggle {
                                Layout.fillWidth: true
                                label: qsTr("Wi-Fi")
                                description: qsTr("Scan and join wireless networks")
                                checked: root.network.enabled
                                onClicked: root.networkToggled(checked)
                            }

                            Repeater {
                                model: root.network.connections
                                delegate: ListItem {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    title: modelData.name
                                    description: modelData.kind === "ethernet"
                                        ? qsTr("Wired connection") : qsTr("Wi-Fi network")
                                    iconName: modelData.kind === "ethernet" ? "grid" : "wifi"
                                    trailingText: modelData.active
                                        ? qsTr("Connected") : modelData.signal + "%"
                                    selected: modelData.active
                                    onClicked: root.networkConnectionRequested(modelData.id)
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "bluetooth"
                    spacing: Theme.scaled(Theme.spacing.md)

                    MissingService {
                        Layout.fillWidth: true
                        visible: !root.capabilities.bluetooth || !root.bluetooth.available
                        serviceName: qsTr("Bluetooth")
                        detail: qsTr("BlueZ is not available in this session.")
                    }

                    Card {
                        Layout.fillWidth: true
                        visible: root.capabilities.bluetooth && root.bluetooth.available
                        title: qsTr("Bluetooth")
                        subtitle: qsTr("Paired devices and adapters")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            Toggle {
                                Layout.fillWidth: true
                                label: qsTr("Bluetooth")
                                description: qsTr("Enable the adapter and device discovery")
                                checked: root.bluetooth.enabled
                                onClicked: root.bluetoothToggled(checked)
                            }

                            Repeater {
                                model: root.bluetooth.devices
                                delegate: ListItem {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    title: modelData.name
                                    description: modelData.description
                                    iconName: "grid"
                                    trailingText: modelData.connected ? qsTr("Connected") : qsTr("Connect")
                                    selected: modelData.connected
                                    onClicked: root.bluetoothDeviceRequested(modelData.id)
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "power"
                    spacing: Theme.scaled(Theme.spacing.md)

                    MissingService {
                        Layout.fillWidth: true
                        visible: !root.capabilities.battery || !root.power.available
                        serviceName: qsTr("Battery")
                        detail: qsTr("UPower reports no battery on this system.")
                    }

                    Card {
                        Layout.fillWidth: true
                        visible: root.capabilities.battery && root.power.available
                        title: qsTr("Battery")
                        subtitle: root.power.charging ? qsTr("Charging") : qsTr("On battery")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.sm)

                                Icon {
                                    name: "battery"
                                    level: root.power.batteryLevel / 100
                                    color: root.power.batteryLevel <= 15
                                        ? Theme.danger : Theme.accentMint
                                    size: Theme.scaled(Theme.icon.sizes.lg)
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.power.batteryLevel + "%"
                                    color: Theme.textPrimary
                                    font.family: Theme.typography.headingFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.heading3.size)
                                    font.weight: Theme.typography.heading3.weight
                                }
                                Text {
                                    visible: root.power.charging
                                    text: qsTr("Charging")
                                    color: Theme.accentMint
                                    font.family: Theme.typography.uiFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                }
                            }

                            Text {
                                text: qsTr("Power profile")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.xs)

                                Repeater {
                                    model: root.power.profiles
                                    delegate: Button {
                                        required property string modelData
                                        Layout.fillWidth: true
                                        label: modelData === "power-saver" ? qsTr("Saver")
                                            : modelData === "performance" ? qsTr("Performance")
                                            : qsTr("Balanced")
                                        variant: root.power.profile === modelData
                                            ? "primary" : "secondary"
                                        onClicked: root.powerProfileChanged(modelData)
                                    }
                                }
                            }

                            Toggle {
                                Layout.fillWidth: true
                                label: qsTr("Battery saver")
                                description: qsTr("Reduce background work when unplugged")
                                checked: root.batterySaver
                                onClicked: root.batterySaverPicked(checked)
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "shortcuts"
                    spacing: Theme.scaled(Theme.spacing.md)

                    Card {
                        Layout.fillWidth: true
                        title: qsTr("Keyboard shortcuts")
                        subtitle: qsTr("Every surface is usable without a pointer")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.xxs)

                            Repeater {
                                model: root.shortcuts
                                delegate: RowLayout {
                                    id: shortcut
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: Theme.scaled(Theme.accessibility.preferredTargetSize)

                                    Text {
                                        Layout.fillWidth: true
                                        text: shortcut.modelData.action
                                        color: Theme.textPrimary
                                        font.family: Theme.typography.uiFamily
                                        font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                                    }
                                    Text {
                                        text: shortcut.modelData.binding
                                        color: Theme.textSecondary
                                        font.family: Theme.typography.monoFamily
                                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.section === "about"
                    spacing: Theme.scaled(Theme.spacing.md)

                    Card {
                        Layout.fillWidth: true
                        title: qsTr("Klyvera")
                        subtitle: qsTr("Your workspace. Your flow.")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Prototype %1 · local-first · no accounts · no telemetry")
                                    .arg(root.host.version)
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                                wrapMode: Text.Wrap
                            }

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: Theme.scaled(Theme.spacing.md)
                                rowSpacing: Theme.scaled(Theme.spacing.xs)

                                Text { text: qsTr("Session"); color: Theme.textSecondary; font.family: Theme.typography.uiFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                                Text { Layout.fillWidth: true; text: root.host.session + " / " + root.host.compositor; color: Theme.textPrimary; font.family: Theme.typography.monoFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                                Text { text: qsTr("Kernel"); color: Theme.textSecondary; font.family: Theme.typography.uiFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                                Text { Layout.fillWidth: true; text: root.host.kernel.length > 0 ? root.host.kernel : qsTr("unknown"); color: Theme.textPrimary; font.family: Theme.typography.monoFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                                Text { text: qsTr("License"); color: Theme.textSecondary; font.family: Theme.typography.uiFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                                Text { Layout.fillWidth: true; text: qsTr("Apache-2.0 (pending confirmation)"); color: Theme.textPrimary; font.family: Theme.typography.uiFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.sm)

                                Button {
                                    label: qsTr("Copy diagnostics")
                                    variant: "secondary"
                                    compact: true
                                    onClicked: root.diagnosticsRequested()
                                }
                                Item { Layout.fillWidth: true }
                            }
                        }
                    }
                }
            }
        }
    }

    component MissingService: ColumnLayout {
        id: missing

        property string serviceName: ""
        property string detail: ""

        spacing: Theme.scaled(Theme.spacing.xs)

        EmptyState {
            Layout.fillWidth: true
            iconName: "warning"
            iconColor: Theme.warning
            title: qsTr("%1 unavailable").arg(missing.serviceName)
            message: missing.detail + " " + qsTr("Klyvera keeps the rest of the shell usable and never fakes a connection.")
            actionText: qsTr("Check again")
            onActionClicked: root.retryRequested()
        }
    }
}
