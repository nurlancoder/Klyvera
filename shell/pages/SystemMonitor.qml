pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

Item {
    id: root

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
    property var capabilities: ({ "battery": false })
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"

    signal closeRequested()
    signal refreshRequested()
    signal processRequested(string processId)

    function percent(used, total) {
        if (!total || total <= 0)
            return 0
        return Math.max(0, Math.min(100, (used / total) * 100))
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
                    text: qsTr("System monitor")
                    color: Theme.textPrimary
                    font.family: Theme.typography.headingFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.heading1.size)
                    font.weight: Theme.typography.heading1.weight
                    font.letterSpacing: Theme.typography.heading1.letterSpacing
                }
                Text {
                    text: qsTr("Read locally from /proc and /sys. Nothing is uploaded.")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                    wrapMode: Text.Wrap
                }
            }

            Button {
                label: qsTr("Refresh")
                variant: "secondary"
                iconName: "refresh"
                compact: true
                onClicked: root.refreshRequested()
            }
            IconButton {
                compact: true
                iconName: "close"
                accessibleName: qsTr("Close system monitor")
                onClicked: root.closeRequested()
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: metrics.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar { }

            ColumnLayout {
                id: metrics
                width: parent.width
                spacing: Theme.scaled(Theme.spacing.md)

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.compact ? 1 : 2
                    columnSpacing: Theme.scaled(Theme.spacing.md)
                    rowSpacing: Theme.scaled(Theme.spacing.md)

                    Card {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        title: qsTr("CPU")
                        subtitle: qsTr("Load across all cores")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.sm)

                                Text {
                                    text: Math.round(root.monitor.cpu) + "%"
                                    color: Theme.textPrimary
                                    font.family: Theme.typography.headingFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.heading1.size)
                                    font.weight: Theme.typography.heading1.weight
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: qsTr("now")
                                    color: Theme.textSecondary
                                    font.family: Theme.typography.monoFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                }
                            }

                            Meter {
                                Layout.fillWidth: true
                                value: root.monitor.cpu / 100
                                fillColor: Theme.accentPurple
                            }

                            Sparkline {
                                Layout.fillWidth: true
                                Layout.preferredHeight: Theme.scaled(Theme.spacing.xxl)
                                points: root.monitor.history ? root.monitor.history : []
                                color: Theme.accentPurple
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        title: qsTr("Memory")
                        subtitle: qsTr("Used and available")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.monitor.memoryUsed.toFixed(1) + " GB"
                                    color: Theme.textPrimary
                                    font.family: Theme.typography.headingFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.heading2.size)
                                    font.weight: Theme.typography.heading2.weight
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: qsTr("of %1 GB").arg(root.monitor.memoryTotal.toFixed(0))
                                    color: Theme.textSecondary
                                    font.family: Theme.typography.uiFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                }
                            }
                            Meter {
                                Layout.fillWidth: true
                                value: root.percent(root.monitor.memoryUsed, root.monitor.memoryTotal) / 100
                                fillColor: Theme.accentBlue
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        title: qsTr("Disk")
                        subtitle: qsTr("Root filesystem")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: root.monitor.diskUsed.toFixed(0) + " GB"
                                    color: Theme.textPrimary
                                    font.family: Theme.typography.headingFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.heading2.size)
                                    font.weight: Theme.typography.heading2.weight
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: qsTr("of %1 GB").arg(root.monitor.diskTotal.toFixed(0))
                                    color: Theme.textSecondary
                                    font.family: Theme.typography.uiFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                }
                            }
                            Meter {
                                Layout.fillWidth: true
                                value: root.percent(root.monitor.diskUsed, root.monitor.diskTotal) / 100
                                fillColor: Theme.accentMint
                            }
                        }
                    }

                    Card {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignTop
                        title: qsTr("Battery")
                        subtitle: root.capabilities.battery ? qsTr("UPower") : qsTr("No battery reported")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            RowLayout {
                                Layout.fillWidth: true
                                Icon {
                                    name: "battery"
                                    level: root.monitor.batteryLevel / 100
                                    color: root.monitor.batteryLevel <= 15
                                        ? Theme.danger : Theme.accentMint
                                    size: Theme.scaled(Theme.icon.sizes.lg)
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: root.capabilities.battery
                                        ? root.monitor.batteryLevel + "%" : qsTr("Not available")
                                    color: root.capabilities.battery
                                        ? Theme.textPrimary : Theme.textSecondary
                                    font.family: Theme.typography.headingFamily
                                    font.pixelSize: Theme.scaledInt(Theme.typography.heading2.size)
                                    font.weight: Theme.typography.heading2.weight
                                }
                            }
                            Meter {
                                Layout.fillWidth: true
                                visible: root.capabilities.battery
                                value: root.monitor.batteryLevel / 100
                                fillColor: root.monitor.batteryLevel <= 15
                                    ? Theme.danger : Theme.accentMint
                            }
                            Text {
                                Layout.fillWidth: true
                                visible: !root.capabilities.battery
                                text: qsTr("Desktop systems and virtual machines may not expose a battery. The rest of the monitor keeps working.")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                wrapMode: Text.Wrap
                            }
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    title: qsTr("Top processes")
                    subtitle: qsTr("Highest combined load")

                    ColumnLayout {
                        width: parent.width
                        spacing: Theme.scaled(Theme.spacing.xxs)

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: Theme.scaled(Theme.spacing.md)
                            Layout.rightMargin: Theme.scaled(Theme.spacing.md)
                            Text { Layout.fillWidth: true; text: qsTr("Process"); color: Theme.textSecondary; font.family: Theme.typography.uiFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                            Text { text: qsTr("CPU"); color: Theme.textSecondary; font.family: Theme.typography.uiFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                            Text { text: qsTr("Memory"); color: Theme.textSecondary; font.family: Theme.typography.uiFamily; font.pixelSize: Theme.scaledInt(Theme.typography.caption.size) }
                        }

                        Repeater {
                            model: root.monitor.processes
                            delegate: ListItem {
                                required property var modelData
                                Layout.fillWidth: true
                                title: modelData.name
                                description: qsTr("PID %1").arg(modelData.id)
                                iconName: "terminal"
                                trailingText: modelData.cpu.toFixed(1) + "%  ·  "
                                    + modelData.memory + " MB"
                                onClicked: root.processRequested(modelData.id)
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: !root.monitor.processes || root.monitor.processes.length === 0
                            text: qsTr("Process sampling is not available in this session.")
                            color: Theme.textSecondary
                            font.family: Theme.typography.uiFamily
                            font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                        }
                    }
                }
            }
        }
    }

    component Meter: Rectangle {
        id: meter

        property real value: 0
        property color fillColor: Theme.accentPurple
        implicitHeight: Theme.scaled(Theme.spacing.xs)

        radius: height / 2
        color: Theme.surfaceActive

        Rectangle {
            width: Math.max(0, Math.min(1, meter.value)) * meter.width
            height: parent.height
            radius: parent.radius
            color: meter.fillColor
            Behavior on width {
                NumberAnimation {
                    duration: Theme.motion.durationNormal
                    easing.type: Easing.OutCubic
                }
            }
        }
    }

    component Sparkline: Canvas {
        id: spark

        property var points: []
        property color color: Theme.accentPurple

        onPointsChanged: requestPaint()
        onColorChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            if (!points || points.length < 2)
                return
            ctx.strokeStyle = color
            ctx.lineWidth = Theme.scaled(Theme.borders.focus)
            ctx.lineJoin = "round"
            ctx.lineCap = "round"
            ctx.beginPath()
            for (let i = 0; i < points.length; i++) {
                const x = (i / (points.length - 1)) * width
                const y = height - Math.max(0, Math.min(100, points[i])) / 100 * height
                if (i === 0)
                    ctx.moveTo(x, y)
                else
                    ctx.lineTo(x, y)
            }
            ctx.stroke()
        }
    }
}
