pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

FocusScope {
    id: root

    property var apps: []
    property var spaces: []
    property var settingsPages: []
    property var recentItems: []
    property string errorText: ""
    property int selectedIndex: 0
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property real panelWidth: Theme.scaled(
        layoutClass === "compact" ? Theme.layout.launcher.widthCompact
            : layoutClass === "regular" ? Theme.layout.launcher.widthRegular
            : layoutClass === "wide" ? Theme.layout.launcher.widthWide
            : Theme.layout.launcher.widthUltrawide)
    readonly property var results: buildResults(search.text)

    signal dismissed()
    signal appRequested(string desktopId)
    signal spaceRequested(string spaceId)
    signal settingsRequested(string pageId)

    focus: true

    function score(query, text) {
        if (query.length === 0)
            return 1
        const needle = query.toLocaleLowerCase()
        const haystack = String(text).toLocaleLowerCase()
        if (haystack === needle)
            return 1000
        if (haystack.startsWith(needle))
            return 700 - haystack.length
        const direct = haystack.indexOf(needle)
        if (direct >= 0)
            return 500 - direct * 2 - haystack.length / 100
        let cursor = -1
        let gaps = 0
        for (let i = 0; i < needle.length; i++) {
            const next = haystack.indexOf(needle[i], cursor + 1)
            if (next < 0)
                return -1
            if (cursor >= 0)
                gaps += next - cursor - 1
            cursor = next
        }
        return 220 - gaps * 3 - haystack.length / 50
    }

    function buildResults(query) {
        const needle = query.trim()
        if (needle.length === 0)
            return recentItems
        const entries = []
        for (let i = 0; i < apps.length; i++) {
            const app = apps[i]
            entries.push({
                "id": app.id,
                "type": "app",
                "section": qsTr("Applications"),
                "title": app.name,
                "subtitle": app.description,
                "icon": app.icon,
                "text": app.name + " " + app.description + " "
                    + (app.keywords ? app.keywords.join(" ") : "")
            })
        }
        for (let i = 0; i < spaces.length; i++) {
            const space = spaces[i]
            entries.push({
                "id": space.id,
                "type": "space",
                "section": qsTr("Spaces"),
                "title": space.name,
                "subtitle": space.description,
                "icon": space.icon,
                "text": space.name + " " + space.description + " Space"
            })
        }
        for (let i = 0; i < settingsPages.length; i++) {
            const page = settingsPages[i]
            entries.push({
                "id": page.id,
                "type": "settings",
                "section": qsTr("Settings"),
                "title": page.name,
                "subtitle": page.description,
                "icon": page.icon,
                "text": page.name + " " + page.description + " Settings"
            })
        }
        const ranked = []
        for (let i = 0; i < entries.length; i++) {
            const rank = score(needle, entries[i].text)
            if (rank >= 0) {
                const entry = entries[i]
                entry.rank = rank
                ranked.push(entry)
            }
        }
        ranked.sort(function(a, b) {
            if (b.rank !== a.rank)
                return b.rank - a.rank
            return a.title.localeCompare(b.title)
        })
        return ranked.slice(0, 14)
    }

    function moveSelection(key) {
        if (results.length === 0)
            return
        let step = 1
        if (key === Qt.Key_Up)
            step = -1
        else if (key === Qt.Key_PageDown)
            step = 5
        else if (key === Qt.Key_PageUp)
            step = -5
        selectedIndex = (selectedIndex + step + results.length) % results.length
        resultsView.positionViewAtIndex(selectedIndex, ListView.Contain)
    }

    function activate(item) {
        if (!item)
            return
        if (item.type === "app")
            appRequested(item.id)
        else if (item.type === "space")
            spaceRequested(item.id)
        else if (item.type === "settings")
            settingsRequested(item.id)
        dismissed()
    }

    function activateSelected() {
        if (results.length > 0)
            activate(results[Math.max(0, Math.min(selectedIndex, results.length - 1))])
    }

    function reset() {
        search.clear()
        selectedIndex = 0
        Qt.callLater(search.focusInput)
    }

    onResultsChanged: selectedIndex = 0
    Component.onCompleted: Qt.callLater(search.focusInput)

    Rectangle {
        anchors.fill: parent
        color: Theme.overlay

        MouseArea {
            anchors.fill: parent
            onClicked: root.dismissed()
        }
    }

    Rectangle {
        id: panel
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(Theme.scaled(Theme.spacing.xl), (root.height - height) * 0.22)
        width: Math.min(root.panelWidth,
            root.width - Theme.scaled(Theme.layout.launcher.gutter) * 2)
        height: Math.min(root.height * Theme.layout.launcher.maxHeightRatio,
            Theme.scaled(680))
        radius: Theme.scaled(Theme.radius.lg)
        color: Theme.surfaceRaised
        border.width: Theme.scaledInt(Theme.borders.hairline)
        border.color: Theme.borderStrong
        Accessible.role: Accessible.Dialog
        Accessible.name: qsTr("Klyvera launcher")

        MouseArea {
            anchors.fill: parent
            onClicked: search.focusInput()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(Theme.spacing.md)
            spacing: Theme.scaled(Theme.spacing.sm)

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(Theme.spacing.xs)

                SearchField {
                    id: search
                    objectName: "launcherSearch"
                    Layout.fillWidth: true
                    placeholder: qsTr("Search apps, Spaces and settings")
                    showClear: true
                    handleNavigationKeys: true
                    onNavigationRequested: function(key) { root.moveSelection(key) }
                    onAccepted: root.activateSelected()
                    onEscapePressed: {
                        if (search.text.length > 0)
                            search.clear()
                        else
                            root.dismissed()
                    }
                }

                IconButton {
                    compact: true
                    iconName: "close"
                    accessibleName: qsTr("Close launcher")
                    onClicked: root.dismissed()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaledInt(Theme.borders.hairline)
                color: Theme.borderSubtle
            }

            Text {
                Layout.leftMargin: Theme.scaled(Theme.spacing.sm)
                Layout.rightMargin: Theme.scaled(Theme.spacing.sm)
                visible: search.text.trim().length > 0 && root.results.length > 0
                text: qsTr("%1 results").arg(root.results.length)
                color: Theme.textSecondary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: resultsView
                    anchors.fill: parent
                    visible: root.errorText.length === 0 && root.results.length > 0
                    model: root.results
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    currentIndex: root.selectedIndex
                    spacing: Theme.scaled(Theme.spacing.xxs)

                    Controls.ScrollBar.vertical: Controls.ScrollBar { }

                    delegate: Item {
                        id: row
                        required property int index
                        required property var modelData
                        width: resultsView.width
                        height: sectionLabel.visible ? sectionLabel.height
                            + itemButton.implicitHeight + Theme.scaled(Theme.spacing.xs)
                            : itemButton.implicitHeight

                        Text {
                            id: sectionLabel
                            readonly property string sectionName: row.modelData.section
                                ? row.modelData.section : qsTr("Recent")
                            visible: row.index === 0
                                || (root.results[row.index - 1].section
                                    ? root.results[row.index - 1].section : qsTr("Recent"))
                                    !== sectionName
                            text: sectionName
                            color: Theme.textSecondary
                            font.family: Theme.typography.uiFamily
                            font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
                            font.weight: Theme.typography.label.weight
                            font.letterSpacing: 0.6
                            height: visible ? implicitHeight + Theme.scaled(Theme.spacing.xs) : 0
                            leftPadding: Theme.scaled(Theme.spacing.md)
                            verticalAlignment: Text.AlignBottom
                        }

                        ListItem {
                            id: itemButton
                            y: sectionLabel.height
                            width: parent.width
                            title: row.modelData.title
                            description: row.modelData.subtitle
                            iconName: row.modelData.icon
                            trailingText: row.modelData.type === "space" ? qsTr("Space")
                                : row.modelData.type === "settings" ? qsTr("Settings") : ""
                            selected: row.index === root.selectedIndex
                            onHoveredChanged: {
                                if (hovered)
                                    root.selectedIndex = row.index
                            }
                            onClicked: root.activate(row.modelData)
                        }
                    }
                }

                EmptyState {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: root.errorText.length === 0 && root.results.length === 0
                    iconName: "search"
                    title: qsTr("No matches")
                    message: qsTr("Try a project name, application or setting. Commands stay local and never run from search.")
                }

                ErrorState {
                    anchors.centerIn: parent
                    width: parent.width
                    visible: root.errorText.length > 0
                    message: root.errorText
                    actionText: qsTr("Retry")
                    onActionClicked: search.focusInput()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Theme.scaled(Theme.spacing.sm)
                Layout.rightMargin: Theme.scaled(Theme.spacing.sm)
                spacing: Theme.scaled(Theme.spacing.md)

                Text {
                    text: qsTr("↑↓ navigate   Enter open   Esc close")
                    color: Theme.textDisabled
                    font.family: Theme.typography.monoFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
                Text {
                    text: root.layoutClass
                    color: Theme.textDisabled
                    font.family: Theme.typography.monoFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                }
            }
        }
    }
}
