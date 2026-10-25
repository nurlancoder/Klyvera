pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

Rectangle {
    id: root

    property int step: 0
    property string themeName: "dark"
    property string accent: "purple"
    property string userName: ""
    readonly property int stepCount: 3
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"

    signal themeChanged(string themeName)
    signal accentPicked(string accent)
    signal finishRequested()
    signal createSpaceRequested()
    signal importRequested()
    signal skipRequested()

    color: Theme.background

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(Theme.spacing.xxl)
        spacing: Theme.scaled(Theme.spacing.xl)

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Klyvera"
                color: Theme.textPrimary
                font.family: Theme.typography.headingFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.heading3.size)
                font.weight: Theme.typography.weightBold
            }
            Item { Layout.fillWidth: true }
            Button {
                label: qsTr("Skip")
                variant: "ghost"
                compact: true
                onClicked: root.skipRequested()
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.fillWidth: true
            Layout.maximumWidth: Theme.scaled(980)
            spacing: Theme.scaled(Theme.spacing.xxl)

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(Theme.spacing.md)

                Text {
                    Layout.fillWidth: true
                    text: root.step === 0 ? qsTr("Your workspace.\nYour flow.")
                        : root.step === 1 ? qsTr("Make it yours.")
                        : qsTr("Start with a Space.")
                    color: Theme.textPrimary
                    font.family: Theme.typography.headingFamily
                    font.pixelSize: Theme.scaledInt(root.compact
                        ? Theme.typography.heading1.size : Theme.typography.display.size)
                    font.weight: Theme.typography.weightBold
                    font.letterSpacing: -0.6
                    lineHeight: 1.05
                    wrapMode: Text.Wrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.step === 0
                        ? qsTr("A calm, local-first desktop for developers. No accounts, no telemetry, no cloud requirement.")
                        : root.step === 1
                            ? qsTr("Pick an appearance now. Every colour and size comes from the same token system.")
                            : qsTr("A Space remembers the folders, applications and commands for one project.")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                    lineHeight: Theme.typography.body.lineHeight / Theme.typography.body.size
                    wrapMode: Text.Wrap
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.xs)

                    Repeater {
                        model: root.stepCount
                        delegate: Rectangle {
                            required property int index
                            width: index === root.step
                                ? Theme.scaled(Theme.spacing.lg)
                                : Theme.scaled(Theme.spacing.xs)
                            height: Theme.scaled(Theme.spacing.xxs)
                            radius: height / 2
                            color: index <= root.step ? Theme.accentPurple : Theme.surfaceActive
                            Behavior on width {
                                NumberAnimation {
                                    duration: Theme.motionDuration(Theme.motion.durationNormal)
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.sm)

                    Button {
                        visible: root.step > 0
                        label: qsTr("Back")
                        variant: "ghost"
                        onClicked: root.step -= 1
                    }

                    Button {
                        visible: root.step < root.stepCount - 1
                        label: qsTr("Continue")
                        variant: "primary"
                        iconName: "arrow-right"
                        onClicked: root.step += 1
                    }

                    Button {
                        visible: root.step === root.stepCount - 1
                        label: qsTr("Create first Space")
                        variant: "primary"
                        iconName: "plus"
                        onClicked: root.createSpaceRequested()
                    }

                    Button {
                        visible: root.step === root.stepCount - 1
                        label: qsTr("Import")
                        variant: "secondary"
                        iconName: "folder"
                        onClicked: root.importRequested()
                    }

                    Item { Layout.fillWidth: true }

                    Button {
                        visible: root.step === root.stepCount - 1
                        label: qsTr("Finish")
                        variant: "ghost"
                        onClicked: root.finishRequested()
                    }
                }
            }

            Item {
                Layout.preferredWidth: root.compact ? 0 : Theme.scaled(360)
                Layout.preferredHeight: Theme.scaled(320)
                visible: !root.compact

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.scaled(Theme.radius.xl)
                    color: Theme.surface
                    border.width: Theme.scaledInt(Theme.borders.hairline)
                    border.color: Theme.borderSubtle

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.scaled(Theme.spacing.lg)
                        spacing: Theme.scaled(Theme.spacing.md)

                        Text {
                            text: root.step === 0 ? qsTr("What stays local")
                                : root.step === 1 ? qsTr("Appearance")
                                : qsTr("A Space contains")
                            color: Theme.textPrimary
                            font.family: Theme.typography.headingFamily
                            font.pixelSize: Theme.scaledInt(Theme.typography.heading3.size)
                            font.weight: Theme.typography.heading3.weight
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.scaled(Theme.spacing.xs)
                            visible: root.step === 0

                            BenefitRow { iconName: "folder"; text: qsTr("Projects stay on disk") }
                            BenefitRow { iconName: "terminal"; text: qsTr("Commands are argv only") }
                            BenefitRow { iconName: "check"; text: qsTr("Backups are verifiable") }
                            BenefitRow { iconName: "moon"; text: qsTr("No telemetry or accounts") }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.scaled(Theme.spacing.sm)
                            visible: root.step === 1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.xs)

                                Repeater {
                                    model: [
                                        { "id": "dark", "label": qsTr("Dark") },
                                        { "id": "light", "label": qsTr("Light") },
                                        { "id": "highContrast", "label": qsTr("Contrast") }
                                    ]
                                    delegate: Button {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        label: modelData.label
                                        variant: root.themeName === modelData.id
                                            ? "primary" : "secondary"
                                        compact: true
                                        onClicked: root.themeChanged(modelData.id)
                                    }
                                }
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
                                        Accessible.name: qsTr("%1 accent").arg(swatch.modelData)
                                        onClicked: root.accentPicked(swatch.modelData)

                                        contentItem: Rectangle {
                                            anchors.centerIn: parent
                                            width: Theme.scaled(Theme.spacing.lg)
                                            height: width
                                            radius: width / 2
                                            color: swatch.modelData === "blue" ? Theme.accentBlue
                                                : swatch.modelData === "mint" ? Theme.accentMint
                                                : Theme.accentPurple
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
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: Theme.scaled(Theme.spacing.xs)
                            visible: root.step === 2

                            BenefitRow { iconName: "folder"; text: qsTr("Project folders") }
                            BenefitRow { iconName: "grid"; text: qsTr("Applications to launch") }
                            BenefitRow { iconName: "terminal"; text: qsTr("Optional trusted commands") }
                            BenefitRow { iconName: "sliders"; text: qsTr("Layout hints") }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: qsTr("Prototype · Apache-2.0 pending · built for Arch Linux and Hyprland")
                color: Theme.textDisabled
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                elide: Text.ElideRight
            }
            Text {
                text: qsTr("Step %1 of %2").arg(root.step + 1).arg(root.stepCount)
                color: Theme.textDisabled
                font.family: Theme.typography.monoFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            }
        }
    }

    component BenefitRow: RowLayout {
        id: benefit
        property string iconName: "check"
        property string text: ""

        Layout.fillWidth: true
        spacing: Theme.scaled(Theme.spacing.sm)

        Rectangle {
            width: Theme.scaled(Theme.spacing.xl)
            height: width
            radius: Theme.scaled(Theme.radius.sm)
            color: Theme.surfaceRaised
            border.width: Theme.scaledInt(Theme.borders.hairline)
            border.color: Theme.borderSubtle
            Icon {
                anchors.centerIn: parent
                name: benefit.iconName
                color: Theme.accentMint
                size: Theme.scaled(Theme.icon.sizes.sm)
            }
        }
        Text {
            Layout.fillWidth: true
            text: benefit.text
            color: Theme.textSecondary
            font.family: Theme.typography.uiFamily
            font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            elide: Text.ElideRight
        }
    }
}
