pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../styles"
import "../ui"

Rectangle {
    id: root

    property string userName: "Klyvera"
    property string hostName: ""
    property string errorText: ""
    property bool busy: false
    property int batteryLevel: 100
    property bool networkOnline: true
    property date now: new Date()
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"
    readonly property bool stacked: compact || height < 720
    readonly property bool shortScreen: height < 600

    signal unlockRequested(string password)
    signal sessionRequested(string action)

    color: Theme.background

    function submit() {
        if (passwordField.text.length === 0 || busy)
            return
        busy = true
        unlockRequested(passwordField.text)
    }

    function clearPassword() {
        passwordField.text = ""
        passwordField.focusInput()
    }

    function fail(message) {
        busy = false
        errorText = message
        passwordField.text = ""
        Qt.callLater(passwordField.focusInput)
    }

    Component.onCompleted: Qt.callLater(passwordField.focusInput)

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            width: Theme.scaled(Theme.spacing.xxxl)
            height: width
            radius: width / 2
            color: Theme.accentPurple
            opacity: 0.05
            x: root.width * 0.72
            y: -width * 0.25
        }
        Rectangle {
            width: Theme.scaled(Theme.spacing.huge)
            height: width
            radius: width / 2
            color: Theme.accentBlue
            opacity: 0.04
            x: -width * 0.3
            y: root.height - width * 0.55
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Theme.scaled(root.stacked ? Theme.spacing.md : Theme.spacing.xxl)
        spacing: Theme.scaled(root.stacked ? Theme.spacing.sm : Theme.spacing.xl)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(Theme.spacing.sm)

            Text {
                text: "Klyvera"
                color: Theme.textPrimary
                font.family: Theme.typography.headingFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                font.weight: Theme.typography.weightBold
                font.letterSpacing: -0.2
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: Theme.scaled(Theme.spacing.xs)
                Icon {
                    name: "wifi"
                    color: root.networkOnline ? Theme.textSecondary : Theme.textDisabled
                    size: Theme.scaled(Theme.icon.sizes.sm)
                }
                Icon {
                    name: "battery"
                    level: root.batteryLevel / 100
                    color: root.batteryLevel <= 15 ? Theme.danger : Theme.textSecondary
                    size: Theme.scaled(Theme.icon.sizes.sm)
                }
                Text {
                    text: root.batteryLevel + "%"
                    color: Theme.textSecondary
                    font.family: Theme.typography.monoFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.stacked ? 1 : 2
            columnSpacing: Theme.scaled(Theme.spacing.xxl)
            rowSpacing: Theme.scaled(Theme.spacing.sm)

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                visible: !root.shortScreen
                spacing: Theme.scaled(Theme.spacing.xs)

                Text {
                    Layout.minimumWidth: 0
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: Theme.textPrimary
                    font.family: Theme.typography.headingFamily
                    font.pixelSize: Theme.scaledInt(root.compact ? 72 : 104)
                    font.weight: Theme.typography.weightBold
                    font.letterSpacing: -2
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: Qt.formatDate(root.now, "dddd, d MMMM")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.heading3.size)
                    font.weight: Theme.typography.weightMedium
                    opacity: 0.9
                }
            }

            Rectangle {
                id: profileCard
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.preferredWidth: Theme.scaled(420)
                Layout.maximumWidth: Theme.scaled(420)
                Layout.preferredHeight: profileContent.implicitHeight
                    + Theme.scaled(Theme.spacing.xxl) * 2
                Layout.fillHeight: !root.stacked
                Layout.alignment: root.stacked ? Qt.AlignHCenter : Qt.AlignVCenter
                radius: Theme.scaled(Theme.radius.xl)
                color: Theme.surface
                border.width: Theme.scaledInt(Theme.borders.hairline)
                border.color: Theme.borderSubtle

                ColumnLayout {
                    id: profileContent
                    anchors.centerIn: parent
                    width: parent.width - Theme.scaled(Theme.spacing.xxl) * 2
                    spacing: Theme.scaled(Theme.spacing.md)

                    Rectangle {
                        Layout.alignment: Qt.AlignHCenter
                        width: Theme.scaled(Theme.spacing.xxxl)
                        height: width
                        radius: width / 2
                        color: Theme.selection
                        border.width: Theme.scaledInt(Theme.borders.hairline)
                        border.color: Theme.borderStrong

                        Text {
                            anchors.centerIn: parent
                            text: root.userName.length > 0 ? root.userName[0].toUpperCase() : "K"
                            color: Theme.accentPurple
                            font.family: Theme.typography.headingFamily
                            font.pixelSize: Theme.scaledInt(Theme.typography.heading2.size)
                            font.weight: Theme.typography.weightBold
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.userName
                        color: Theme.textPrimary
                        font.family: Theme.typography.headingFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.heading2.size)
                        font.weight: Theme.typography.heading2.weight
                        horizontalAlignment: Text.AlignHCenter
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: root.hostName.length > 0
                        text: root.hostName
                        color: Theme.textSecondary
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                        horizontalAlignment: Text.AlignHCenter
                    }

                    TextField {
                        id: passwordField
                        Layout.fillWidth: true
                        label: qsTr("Password")
                        placeholder: qsTr("Enter your password")
                        echoMode: TextInput.Password
                        errorText: root.errorText
                        enabled: !root.busy
                        onAccepted: root.submit()
                        onTextChanged: {
                            if (root.errorText.length > 0)
                                root.errorText = ""
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        label: root.busy ? qsTr("Unlocking") : qsTr("Unlock")
                        variant: "primary"
                        loading: root.busy
                        onClicked: root.submit()
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.scaledInt(Theme.borders.hairline)
                        color: Theme.borderSubtle
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: root.height >= 720
                        spacing: Theme.scaled(Theme.spacing.xs)

                        Button {
                            Layout.fillWidth: true
                            label: qsTr("Suspend")
                            variant: "ghost"
                            compact: true
                            onClicked: root.sessionRequested("suspend")
                        }
                        Button {
                            Layout.fillWidth: true
                            label: qsTr("Restart")
                            variant: "ghost"
                            compact: true
                            onClicked: root.sessionRequested("reboot")
                        }
                        Button {
                            Layout.fillWidth: true
                            label: qsTr("Shut down")
                            variant: "ghost"
                            compact: true
                            onClicked: root.sessionRequested("shutdown")
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Local authentication. No password leaves this computer.")
                        color: Theme.textDisabled
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.Wrap
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Text {
                Layout.fillWidth: true
                text: qsTr("Klyvera 0.1.0-prototype")
                color: Theme.textDisabled
                font.family: Theme.typography.monoFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            }
            Text {
                text: qsTr("Your workspace. Your flow.")
                color: Theme.textDisabled
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            }
        }
    }

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
}
