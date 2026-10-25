import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../shell/styles"
import "../shell/ui"

Rectangle {
    id: root

    property string themeName: "dark"
    property bool dialogVisible: false
    property bool reduceMotion: false
    readonly property string layoutClass: Theme.layoutClass(width)

    color: Theme.surfaceSunken

    onThemeNameChanged: Theme.themeName = themeName
    onReduceMotionChanged: Theme.reduceMotion = reduceMotion
    Component.onCompleted: {
        Theme.themeName = themeName
        Theme.reduceMotion = reduceMotion
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: gallery.implicitHeight + Theme.scaled(Theme.spacing.xxl) * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Controls.ScrollBar.vertical: Controls.ScrollBar { }

        Column {
            id: gallery
            x: Theme.scaled(Theme.spacing.xxl)
            y: Theme.scaled(Theme.spacing.xl)
            width: Math.min(flick.width - Theme.scaled(Theme.spacing.xxl) * 2,
                Theme.scaled(root.layoutClass === "compact" ? 900
                    : root.layoutClass === "regular" ? 1120
                    : root.layoutClass === "wide" ? 1440 : 1640))
            spacing: Theme.scaled(Theme.spacing.lg)

            RowLayout {
                width: parent.width
                spacing: Theme.scaled(Theme.spacing.lg)

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: "Klyvera"
                        color: Theme.textPrimary
                        font.family: Theme.typography.headingFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.display.size)
                        font.weight: Theme.typography.display.weight
                        font.letterSpacing: Theme.typography.display.letterSpacing
                    }
                    Text {
                        text: qsTr("Your workspace. Your flow.")
                        color: Theme.textSecondary
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                    }
                }

                Text {
                    text: qsTr("Component library  ·  Phase 3")
                    color: Theme.textSecondary
                    font.family: Theme.typography.monoFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    Layout.alignment: Qt.AlignBottom
                }
                Text {
                    text: root.layoutClass + "  ·  " + root.width + " px"
                    color: Theme.accentMint
                    font.family: Theme.typography.monoFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    Layout.alignment: Qt.AlignBottom
                }
            }

            Panel {
                width: parent.width

                WorkspaceIndicator {
                    Layout.alignment: Qt.AlignVCenter
                    currentWorkspace: 2
                }
                Item {
                    Layout.fillWidth: true
                }
                Clock {
                    showDate: true
                    now: new Date(2026, 9, 25, 9, 41)
                    Layout.alignment: Qt.AlignVCenter
                }
                SystemIndicators {
                    Layout.alignment: Qt.AlignVCenter
                    unreadNotifications: 3
                    batteryLevel: 78
                    volume: 64
                }
            }

            Card {
                width: parent.width
                title: qsTr("Actions")
                subtitle: qsTr("Intent, hierarchy and pending state")

                ColumnLayout {
                    width: parent.width
                    spacing: Theme.scaled(Theme.spacing.md)

                    Flow {
                        width: parent.width
                        spacing: Theme.scaled(Theme.spacing.sm)

                        Button { label: qsTr("Create space"); variant: "primary" }
                        Button { label: qsTr("Duplicate"); variant: "secondary" }
                        Button { label: qsTr("Skip"); variant: "ghost" }
                        Button { label: qsTr("Remove"); variant: "danger" }
                        Button {
                            label: qsTr("Saving")
                            variant: "secondary"
                            loading: true
                        }
                        Button {
                            label: qsTr("Open dialog")
                            variant: "ghost"
                            iconName: "sliders"
                            onClicked: root.dialogVisible = true
                        }
                    }

                    RowLayout {
                        spacing: Theme.scaled(Theme.spacing.sm)
                        IconButton { iconName: "refresh"; accessibleName: qsTr("Refresh") }
                        IconButton { iconName: "terminal"; accessibleName: qsTr("Open terminal") }
                        IconButton { iconName: "power"; accessibleName: qsTr("Power options") }
                        IconButton {
                            iconName: "trash"
                            accessibleName: qsTr("Delete")
                            enabled: false
                        }
                    }
                }
            }

            GridLayout {
                width: parent.width
                columns: root.layoutClass === "compact" ? 1 : 2
                columnSpacing: Theme.scaled(Theme.layout.spaces.gridGap)
                rowSpacing: Theme.scaled(Theme.layout.spaces.gridGap)

                Card {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    title: qsTr("Inputs")
                    subtitle: qsTr("Keyboard and pointer ready")

                    ColumnLayout {
                        width: parent.width
                        spacing: Theme.scaled(Theme.spacing.md)

                        TextField {
                            Layout.fillWidth: true
                            label: qsTr("Workspace name")
                            placeholder: qsTr("Name this space")
                            text: qsTr("API platform")
                        }
                        SearchField {
                            Layout.fillWidth: true
                            placeholder: qsTr("Search projects")
                        }
                        Toggle {
                            Layout.fillWidth: true
                            label: qsTr("Restore windows on launch")
                            description: qsTr("Reopen each application in its saved position")
                            checked: true
                        }
                        Slider {
                            Layout.fillWidth: true
                            label: qsTr("Interface scale")
                            from: 80
                            to: 140
                            value: 100
                            stepSize: 5
                            valueSuffix: "%"
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    title: qsTr("Workspace list")
                    subtitle: qsTr("Spaces, projects and saved context")

                    ColumnLayout {
                        width: parent.width
                        spacing: 0

                        Tabs {
                            Layout.fillWidth: true
                            tabs: [qsTr("Overview"), qsTr("Windows"), qsTr("Git")]
                            currentIndex: 0
                        }

                        ListItem {
                            width: parent.width
                            title: qsTr("API platform")
                            description: qsTr("Rust services and terminal")
                            iconName: "code"
                            trailingText: "12m"
                            selected: true
                        }
                        ListItem {
                            width: parent.width
                            title: qsTr("Design system")
                            description: qsTr("Tokens, QML and documentation")
                            iconName: "grid"
                            trailingText: "1h"
                        }
                        ListItem {
                            width: parent.width
                            title: qsTr("Release prep")
                            description: qsTr("Packaging and manual checks")
                            iconName: "folder"
                            trailingText: "3h"
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    title: qsTr("Feedback")
                    subtitle: qsTr("Calm, specific, dismissible")

                    ColumnLayout {
                        width: parent.width
                        spacing: Theme.scaled(Theme.spacing.md)

                        Toast {
                            Layout.fillWidth: true
                            visible: true
                            message: qsTr("Workspace created")
                            detail: qsTr("API platform is ready to launch.")
                            tone: "success"
                            actionText: qsTr("View")
                            timeout: 0
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(Theme.spacing.sm)

                            Skeleton {
                                Layout.fillWidth: true
                                variant: "text"
                            }
                            Skeleton {
                                Layout.preferredWidth: Theme.scaled(Theme.spacing.xl)
                                Layout.preferredHeight: Theme.scaled(Theme.spacing.xl)
                                variant: "circle"
                            }
                        }

                        Skeleton {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Theme.scaled(Theme.spacing.xxl)
                        }
                    }
                }

                Card {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    title: qsTr("Empty and error states")
                    subtitle: qsTr("Always offer the next step")

                    ColumnLayout {
                        width: parent.width
                        spacing: Theme.scaled(Theme.spacing.md)

                        EmptyState {
                            Layout.fillWidth: true
                            iconName: "folder"
                            title: qsTr("No projects yet")
                            message: qsTr("Create a space to keep its windows, paths and commands together.")
                            actionText: qsTr("Create project")
                        }

                        ErrorState {
                            Layout.fillWidth: true
                            message: qsTr("The workspace file could not be read. A verified backup is available.")
                            actionText: qsTr("Restore backup")
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: Theme.scaled(Theme.spacing.md)

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Pure QML components. No Quickshell imports. Tokens for every size and color.")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    wrapMode: Text.Wrap
                }
                Text {
                    text: qsTr("Klyvera 0.1")
                    color: Theme.textDisabled
                    font.family: Theme.typography.monoFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                }
            }
        }
    }

    ConfirmDialog {
        id: dialog
        title: qsTr("Delete workspace?")
        message: qsTr("This removes the saved layout and project links. Your files stay untouched.")
        confirmText: qsTr("Delete workspace")
        cancelText: qsTr("Keep it")
        primaryVariant: "danger"

        onRejected: root.dialogVisible = false
        onAccepted: root.dialogVisible = false
    }

    onDialogVisibleChanged: {
        if (dialogVisible)
            dialog.open()
        else
            dialog.close()
    }
}
