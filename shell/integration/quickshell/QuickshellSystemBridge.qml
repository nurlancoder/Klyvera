// Target-only system bridge. Every external command is an argv array; no shell
// strings are evaluated. Quickshell and UPower are absent on the development
// host, so this adapter is UNVERIFIED-ON-TARGET until exercised on Arch.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

QtObject {
    id: root

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
        "profiles": ["power-saver", "balanced", "performance"]
    })
    property var host: ({
        "name": "Klyvera",
        "version": "0.1.0-prototype",
        "kernel": "",
        "session": "wayland",
        "compositor": "Hyprland"
    })
    property var displays: []
    property var shortcuts: [
        { "action": "Open launcher", "binding": "Super + Space" },
        { "action": "Control center", "binding": "Super + C" },
        { "action": "Notifications", "binding": "Super + N" },
        { "action": "Session menu", "binding": "Super + Escape" },
        { "action": "Workspaces 1-5", "binding": "Super + 1…5" },
        { "action": "Move window", "binding": "Super + Shift + Arrow" }
    ]
    property var monitor: ({
        "cpu": 0,
        "memoryUsed": 0,
        "memoryTotal": 0,
        "diskUsed": 0,
        "diskTotal": 0,
        "batteryLevel": 100,
        "history": [],
        "processes": []
    })
    property var capabilities: ({
        "audio": false,
        "network": false,
        "bluetooth": false,
        "battery": false
    })
    property bool doNotDisturb: false

    property real lastCpuTotal: 0
    property real lastCpuIdle: 0
    property var history: []

    signal refreshed()

    function refresh() {
        statProbe.running = true
        memProbe.running = true
        diskProbe.running = true
        processProbe.running = true
        audioStatusProbe.running = true
        audioVolumeProbe.running = true
        wifiProbe.running = true
        bluetoothShowProbe.running = true
        bluetoothDeviceProbe.running = true
        hostNameProbe.running = true
        kernelProbe.running = true
        syncPower()
    }

    function syncPower() {
        const device = UPower.displayDevice
        const available = device !== null && device !== undefined
        const level = available && device.percentage !== undefined
            ? Math.round(device.percentage * 100) : 100
        const charging = available && device.state === UPowerDeviceState.Charging
        power = Object.assign({}, power, {
            "available": available,
            "batteryLevel": Math.max(0, Math.min(100, level)),
            "charging": charging
        })
        capabilities = Object.assign({}, capabilities, { "battery": available })
        monitor = Object.assign({}, monitor, { "batteryLevel": level })
    }

    function updateMonitor(partial) {
        monitor = Object.assign({}, monitor, partial)
    }

    function parseStat(text) {
        const line = text.split("\n")[0]
        if (!line || line.indexOf("cpu") !== 0)
            return
        const fields = line.trim().split(/\s+/).slice(1).map(Number)
        if (fields.length < 4 || fields.some(function(value) { return isNaN(value) }))
            return
        const idle = fields[3] + (fields[4] || 0)
        const total = fields.reduce(function(sum, value) { return sum + value }, 0)
        if (lastCpuTotal > 0 && total > lastCpuTotal) {
            const deltaTotal = total - lastCpuTotal
            const deltaIdle = idle - lastCpuIdle
            const usage = Math.max(0, Math.min(100, (1 - deltaIdle / deltaTotal) * 100))
            history = history.concat([usage]).slice(-60)
            updateMonitor({ "cpu": usage, "history": history })
        }
        lastCpuTotal = total
        lastCpuIdle = idle
    }

    function parseMem(text) {
        let totalKb = 0
        let availableKb = 0
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^(MemTotal|MemAvailable):\s+(\d+)/)
            if (!match)
                continue
            if (match[1] === "MemTotal")
                totalKb = Number(match[2])
            else
                availableKb = Number(match[2])
        }
        if (totalKb <= 0)
            return
        const totalGb = totalKb / 1024 / 1024
        const usedGb = Math.max(0, totalKb - availableKb) / 1024 / 1024
        updateMonitor({
            "memoryTotal": Math.round(totalGb * 10) / 10,
            "memoryUsed": Math.round(usedGb * 10) / 10
        })
    }

    function parseDisk(text) {
        const lines = text.trim().split("\n")
        if (lines.length < 2)
            return
        const fields = lines[lines.length - 1].trim().split(/\s+/)
        if (fields.length < 4)
            return
        const total = Number(fields[1])
        const used = Number(fields[2])
        if (isNaN(total) || isNaN(used))
            return
        updateMonitor({
            "diskTotal": Math.round(total / 1024 / 1024 / 1024 * 10) / 10,
            "diskUsed": Math.round(used / 1024 / 1024 / 1024 * 10) / 10
        })
    }

    function parseProcesses(text) {
        const processes = []
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^\s*(\d+)\s+(\S+)\s+([\d.]+)\s+([\d.]+)/)
            if (!match)
                continue
            processes.push({
                "id": Number(match[1]),
                "name": match[2],
                "cpu": Number(match[3]),
                "memory": Math.round(Number(match[4]) * 10)
            })
        }
        processes.sort(function(a, b) { return b.cpu - a.cpu })
        updateMonitor({ "processes": processes.slice(0, 6) })
    }

    function parseVolume(text) {
        const match = text.match(/Volume:\s*([\d.]+)/)
        if (!match)
            return
        const volume = Math.max(0, Math.min(100, Math.round(Number(match[1]) * 100)))
        const muted = text.indexOf("[MUTED]") !== -1
        audio = Object.assign({}, audio, {
            "available": true,
            "volume": volume,
            "muted": muted
        })
        capabilities = Object.assign({}, capabilities, { "audio": true })
    }

    function parseAudioStatus(text) {
        const outputs = []
        const inputs = []
        let section = ""
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i]
            if (line.indexOf("Sinks:") !== -1) {
                section = "outputs"
                continue
            }
            if (line.indexOf("Sources:") !== -1) {
                section = "inputs"
                continue
            }
            if (line.indexOf("├─") !== -1 || line.indexOf("└─") !== -1) {
                if (section === "outputs" && line.indexOf("Sinks:") === -1) {
                    const parts = line.split("│")
                    if (parts.length > 1)
                        section = ""
                }
                continue
            }
            if (section.length === 0 || line.trim().length === 0)
                continue
            const match = line.match(/(\*)?\s*(\d+)\.\s+(.+?)(?:\s+\[vol:.*\])?$/)
            if (!match)
                continue
            const entry = {
                "id": match[2],
                "name": match[3].trim(),
                "description": match[1] ? "Default device" : "PipeWire device",
                "active": match[1] === "*"
            }
            if (section === "outputs")
                outputs.push(entry)
            else
                inputs.push(entry)
        }
        audio = Object.assign({}, audio, {
            "available": true,
            "outputs": outputs,
            "inputs": inputs
        })
        capabilities = Object.assign({}, capabilities, { "audio": true })
    }

    function parseWifi(text) {
        const connections = []
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            if (lines[i].length === 0)
                continue
            const fields = lines[i].split(":")
            if (fields.length < 3)
                continue
            const active = fields[0].trim() === "*"
            const name = fields[1]
            if (name.length === 0)
                continue
            const signal = Number(fields[2])
            connections.push({
                "id": name,
                "name": name,
                "kind": "wifi",
                "active": active,
                "signal": isNaN(signal) ? 0 : signal
            })
        }
        network = Object.assign({}, network, {
            "available": true,
            "enabled": connections.length > 0,
            "connections": connections
        })
        capabilities = Object.assign({}, capabilities, { "network": true })
    }

    function parseBluetoothShow(text) {
        const powered = text.indexOf("Powered: yes") !== -1
        bluetooth = Object.assign({}, bluetooth, {
            "available": true,
            "enabled": powered
        })
        capabilities = Object.assign({}, capabilities, { "bluetooth": true })
    }

    function parseBluetoothDevices(text) {
        const devices = []
        const lines = text.split("\n")
        for (let i = 0; i < lines.length; i++) {
            const match = lines[i].match(/^Device\s+(\S+)\s+(.+)$/)
            if (!match)
                continue
            devices.push({
                "id": match[1],
                "name": match[2],
                "description": match[1],
                "connected": true
            })
        }
        bluetooth = Object.assign({}, bluetooth, { "devices": devices })
    }

    function updateDisplays() {
        const result = []
        for (let i = 0; i < Quickshell.screens.length; i++) {
            const screen = Quickshell.screens[i]
            result.push({
                "id": screen.name,
                "name": screen.name,
                "width": screen.width,
                "height": screen.height,
                "refresh": screen.refreshRate ? Math.round(screen.refreshRate) : 0,
                "scale": screen.devicePixelRatio ? screen.devicePixelRatio : 1,
                "primary": i === 0
            })
        }
        displays = result
    }

    property Timer pollTimer: Timer {
        interval: 2500
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    property Process statProbe: Process {
        command: ["cat", "/proc/stat"]
        stdout: StdioCollector { onStreamFinished: root.parseStat(text) }
    }

    property Process memProbe: Process {
        command: ["cat", "/proc/meminfo"]
        stdout: StdioCollector { onStreamFinished: root.parseMem(text) }
    }

    property Process diskProbe: Process {
        command: ["df", "-P", "-B1", "/"]
        stdout: StdioCollector { onStreamFinished: root.parseDisk(text) }
    }

    property Process processProbe: Process {
        command: ["ps", "-eo", "pid=,comm=,%cpu=,%mem="]
        stdout: StdioCollector { onStreamFinished: root.parseProcesses(text) }
    }

    property Process audioVolumeProbe: Process {
        command: ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector { onStreamFinished: root.parseVolume(text) }
    }

    property Process audioStatusProbe: Process {
        command: ["wpctl", "status"]
        stdout: StdioCollector { onStreamFinished: root.parseAudioStatus(text) }
    }

    property Process wifiProbe: Process {
        command: ["nmcli", "-t", "-f", "IN-USE,SSID,SIGNAL", "device", "wifi"]
        stdout: StdioCollector { onStreamFinished: root.parseWifi(text) }
    }

    property Process bluetoothShowProbe: Process {
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector { onStreamFinished: root.parseBluetoothShow(text) }
    }

    property Process bluetoothDeviceProbe: Process {
        command: ["bluetoothctl", "devices", "Connected"]
        stdout: StdioCollector { onStreamFinished: root.parseBluetoothDevices(text) }
    }

    property Process hostNameProbe: Process {
        command: ["uname", "-n"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.host = Object.assign({}, root.host, { "name": text.trim() })
            }
        }
    }

    property Process kernelProbe: Process {
        command: ["uname", "-r"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.host = Object.assign({}, root.host, { "kernel": text.trim() })
            }
        }
    }

    Component.onCompleted: {
        updateDisplays()
        refresh()
    }
}
