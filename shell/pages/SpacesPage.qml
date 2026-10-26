pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

Item {
    id: root

    property var spaces: []
    property var installedApps: []
    property string selectedId: ""
    property string externalError: ""
    property string mode: "list"
    property string spaceSearch: ""
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"
    readonly property var filteredSpaces: filterSpaces(spaceSearch)
    readonly property var selectedSpace: findSpace(selectedId)

    signal spaceOpened(string spaceId)
    signal spacesEdited(var spaces)
    signal importRequested()
    signal exportRequested(string spaceId)
    signal folderPickerRequested()
    signal commandTrustConfirmed(var space)
    signal notifyRequested(string message, string detail, string tone)

    function findSpace(spaceId) {
        for (let i = 0; i < spaces.length; i++) {
            if (spaces[i].id === spaceId)
                return spaces[i]
        }
        return null
    }

    function filterSpaces(query) {
        const needle = query.trim().toLocaleLowerCase()
        if (needle.length === 0)
            return spaces
        const result = []
        for (let i = 0; i < spaces.length; i++) {
            const space = spaces[i]
            if ((space.name + " " + space.description + " " + space.projectPaths.join(" "))
                    .toLocaleLowerCase().indexOf(needle) >= 0) {
                result.push(space)
            }
        }
        return result
    }

    function slugify(name) {
        let slug = String(name).toLocaleLowerCase().trim()
            .replace(/[^a-z0-9]+/g, "-").replace(/^-+|-+$/g, "")
        if (slug.length === 0)
            slug = "space"
        if (slug.length > 48)
            slug = slug.slice(0, 48).replace(/-+$/, "")
        return slug
    }

    function uniqueId(name, exceptId) {
        const base = slugify(name)
        let candidate = base
        let counter = 2
        while (spaces.some(function(space) {
            return space.id === candidate && space.id !== exceptId
        })) {
            candidate = base + "-" + counter
            counter += 1
        }
        return candidate
    }

    function startCreate() {
        externalError = ""
        editor.load(null)
        mode = "editor"
    }

    function startEdit(space) {
        if (!space)
            return
        externalError = ""
        editor.load(space)
        mode = "editor"
    }

    function saveSpace(space) {
        const next = spaces.slice()
        let index = -1
        for (let i = 0; i < next.length; i++) {
            if (next[i].id === space.id) {
                index = i
                break
            }
        }
        if (space.id.length === 0 || index < 0)
            space.id = uniqueId(space.name, space.id)
        space.trusted = !!space.trusted
        space.recent = space.recent ? space.recent : qsTr("just now")
        if (index >= 0)
            next[index] = space
        else
            next.unshift(space)
        spaces = next
        selectedId = space.id
        mode = "list"
        notifyRequested(index >= 0 ? qsTr("Space updated") : qsTr("Space created"),
            space.name, "success")
        spacesEdited(spaces)
    }

    function deleteSelected() {
        if (!selectedSpace)
            return
        const next = []
        for (let i = 0; i < spaces.length; i++) {
            if (spaces[i].id !== selectedSpace.id)
                next.push(spaces[i])
        }
        const deletedName = selectedSpace.name
        spaces = next
        selectedId = next.length > 0 ? next[0].id : ""
        deleteDialog.close()
        notifyRequested(qsTr("Space removed"), deletedName, "warning")
        spacesEdited(spaces)
    }

    function trustSelected() {
        if (!selectedSpace)
            return
        const next = spaces.slice()
        for (let i = 0; i < next.length; i++) {
            if (next[i].id === selectedSpace.id) {
                const copy = JSON.parse(JSON.stringify(next[i]))
                copy.trusted = true
                next[i] = copy
                commandTrustConfirmed(copy)
                break
            }
        }
        spaces = next
        notifyRequested(qsTr("Commands allowed"), qsTr("Permission is tied to this exact Space content."), "success")
        spacesEdited(spaces)
    }

    function appName(desktopId) {
        for (let i = 0; i < installedApps.length; i++) {
            if (installedApps[i].id === desktopId)
                return installedApps[i].name
        }
        return desktopId
    }

    function appIcon(desktopId) {
        for (let i = 0; i < installedApps.length; i++) {
            if (installedApps[i].id === desktopId)
                return installedApps[i].icon
        }
        return "grid"
    }

    function accentColor(accent) {
        if (accent === "blue")
            return Theme.accentBlue
        if (accent === "mint")
            return Theme.accentMint
        return Theme.accentPurple
    }

    Component.onCompleted: {
        if (selectedId.length === 0 && spaces.length > 0)
            selectedId = spaces[0].id
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(Theme.spacing.lg)
        visible: root.mode === "list"

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(Theme.spacing.md)

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: qsTr("Spaces")
                    color: Theme.textPrimary
                    font.family: Theme.typography.headingFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.heading1.size)
                    font.weight: Theme.typography.heading1.weight
                    font.letterSpacing: Theme.typography.heading1.letterSpacing
                }
                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: qsTr("Project-based workspaces for the way you actually work.")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                    wrapMode: Text.Wrap
                }
            }

            Button {
                label: qsTr("Import")
                variant: "secondary"
                iconName: "folder"
                onClicked: root.importRequested()
            }
            Button {
                label: qsTr("New Space")
                variant: "primary"
                iconName: "plus"
                onClicked: root.startCreate()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: root.externalError.length > 0
            radius: Theme.scaled(Theme.radius.md)
            color: Theme.surface
            border.width: Theme.scaledInt(Theme.borders.hairline)
            border.color: Theme.danger
            implicitHeight: errorText.implicitHeight + Theme.scaled(Theme.spacing.md) * 2

            Text {
                id: errorText
                anchors.fill: parent
                anchors.margins: Theme.scaled(Theme.spacing.md)
                text: root.externalError
                color: Theme.danger
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                wrapMode: Text.Wrap
                verticalAlignment: Text.AlignVCenter
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: Theme.scaled(Theme.layout.spaces.gridGap)
            visible: !root.compact

            Rectangle {
                Layout.preferredWidth: Theme.scaled(Theme.layout.spaces.sidebarWidth)
                Layout.fillHeight: true
                radius: Theme.scaled(Theme.radius.lg)
                color: Theme.surface
                border.width: Theme.scaledInt(Theme.borders.hairline)
                border.color: Theme.borderSubtle

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.scaled(Theme.spacing.sm)
                    spacing: Theme.scaled(Theme.spacing.sm)

                    SearchField {
                        Layout.fillWidth: true
                        placeholder: qsTr("Filter Spaces")
                        text: root.spaceSearch
                        onTextChanged: root.spaceSearch = text
                    }

                    ListView {
                        id: spaceList
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        model: root.filteredSpaces
                        clip: true
                        spacing: Theme.scaled(Theme.spacing.xxs)
                        currentIndex: root.filteredSpaces.findIndex(function(space) {
                            return space.id === root.selectedId
                        })

                        Controls.ScrollBar.vertical: Controls.ScrollBar { }

                        delegate: ListItem {
                            required property var modelData
                            width: ListView.view.width
                            title: modelData.name
                            description: modelData.description
                            iconName: modelData.icon
                            trailingText: modelData.recent
                            selected: modelData.id === root.selectedId
                            Accessible.description: modelData.description + ". "
                                + modelData.projectPaths.length + " folders"
                            onClicked: root.selectedId = modelData.id
                        }

                        EmptyState {
                            anchors.fill: parent
                            visible: root.filteredSpaces.length === 0
                            iconName: "folder"
                            title: root.spaceSearch.length > 0 ? qsTr("No matching Spaces") : qsTr("No Spaces yet")
                            message: root.spaceSearch.length > 0
                                ? qsTr("Try a different name or project folder.")
                                : qsTr("Create a Space to group a project's folders, apps and commands.")
                            actionText: root.spaceSearch.length > 0 ? "" : qsTr("New Space")
                            onActionClicked: root.startCreate()
                        }
                    }
                }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumWidth: Theme.scaled(Theme.layout.spaces.cardMinWidth)
                SpaceDetail {
                    anchors.fill: parent
                    space: root.selectedSpace
                    installedApps: root.installedApps
                    onOpenRequested: function(spaceId) { root.spaceOpened(spaceId) }
                    onEditRequested: function(space) { root.startEdit(space) }
                    onDeleteRequested: deleteDialog.open()
                    onExportRequested: function(spaceId) { root.exportRequested(spaceId) }
                    onTrustRequested: root.trustSelected()
                    onImportRequested: root.importRequested()
                    onCreateRequested: root.startCreate()
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.compact
            contentWidth: width
            contentHeight: compactBody.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar { }

            ColumnLayout {
                id: compactBody
                width: parent.width
                spacing: Theme.scaled(Theme.spacing.md)

                SearchField {
                    Layout.fillWidth: true
                    placeholder: qsTr("Filter Spaces")
                    text: root.spaceSearch
                    onTextChanged: root.spaceSearch = text
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(Theme.accessibility.preferredTargetSize)
                    contentWidth: compactList.implicitWidth
                    contentHeight: height
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    visible: root.filteredSpaces.length > 0

                    Row {
                        id: compactList
                        spacing: Theme.scaled(Theme.spacing.xs)

                        Repeater {
                            model: root.filteredSpaces
                            delegate: Controls.AbstractButton {
                                id: compactChip
                                required property var modelData
                                implicitWidth: Theme.scaled(Theme.layout.spaces.cardMinWidth * 0.8)
                                implicitHeight: Theme.scaled(Theme.accessibility.preferredTargetSize)
                                padding: 0
                                hoverEnabled: true
                                focusPolicy: Qt.StrongFocus
                                Accessible.role: Accessible.Button
                                Accessible.name: modelData.name
                                Accessible.description: modelData.description
                                onClicked: root.selectedId = modelData.id

                                contentItem: RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: Theme.scaled(Theme.spacing.sm)
                                    anchors.rightMargin: Theme.scaled(Theme.spacing.sm)
                                    spacing: Theme.scaled(Theme.spacing.xs)

                                    Icon {
                                        name: modelData.icon
                                        color: root.selectedId === modelData.id
                                            ? Theme.accentPurple : Theme.textSecondary
                                        size: Theme.scaled(Theme.icon.sizes.md)
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: modelData.name
                                        color: Theme.textPrimary
                                        font.family: Theme.typography.uiFamily
                                        font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                                        elide: Text.ElideRight
                                    }
                                }
                                background: Rectangle {
                                    radius: Theme.scaled(Theme.radius.sm)
                                    color: root.selectedId === modelData.id
                                        ? Theme.selection
                                        : compactChip.hovered ? Theme.surfaceHover : Theme.surface
                                    border.width: Theme.scaledInt(Theme.borders.hairline)
                                    border.color: root.selectedId === modelData.id
                                        ? Theme.accentPurple : Theme.borderSubtle
                                    FocusRing { show: compactChip.activeFocus }
                                }
                            }
                        }
                    }
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: compactDetail.implicitHeight
                    SpaceDetail {
                        id: compactDetail
                        width: parent.width
                        height: implicitHeight
                        space: root.selectedSpace
                        installedApps: root.installedApps
                        onOpenRequested: function(spaceId) { root.spaceOpened(spaceId) }
                        onEditRequested: function(space) { root.startEdit(space) }
                        onDeleteRequested: deleteDialog.open()
                        onExportRequested: function(spaceId) { root.exportRequested(spaceId) }
                        onTrustRequested: root.trustSelected()
                        onImportRequested: root.importRequested()
                        onCreateRequested: root.startCreate()
                    }
                }
            }
        }
    }

    SpaceEditor {
        id: editor
        anchors.fill: parent
        visible: root.mode === "editor"
        installedApps: root.installedApps
        onSaved: function(space) { root.saveSpace(space) }
        onCancelled: root.mode = "list"
        onFolderPickerRequested: root.folderPickerRequested()
        onCommandTrustConfirmed: function(space) { root.commandTrustConfirmed(space) }
    }

    ConfirmDialog {
        id: deleteDialog
        title: qsTr("Remove this Space?")
        message: qsTr("The Space definition is moved to trash. Project files are never deleted.")
        confirmText: qsTr("Remove Space")
        cancelText: qsTr("Keep it")
        primaryVariant: "danger"
        onAccepted: root.deleteSelected()
    }

    component SpaceDetail: Item {
        id: detail

        property var space: null
        property var installedApps: []
        signal openRequested(string spaceId)
        signal editRequested(var space)
        signal deleteRequested()
        signal exportRequested(string spaceId)
        signal trustRequested()
        signal importRequested()
        signal createRequested()

        implicitHeight: detailBody.implicitHeight + Theme.scaled(Theme.spacing.lg) * 2

        Rectangle {
            anchors.fill: parent
            radius: Theme.scaled(Theme.radius.lg)
            color: Theme.surface
            border.width: Theme.scaledInt(Theme.borders.hairline)
            border.color: Theme.borderSubtle
        }

        EmptyState {
            anchors.centerIn: parent
            width: Math.min(parent.width, Theme.scaled(Theme.layout.spaces.cardMinWidth * 1.5))
            visible: detail.space === null
            iconName: "folder"
            title: qsTr("Choose a Space")
            message: qsTr("Spaces keep project folders, apps and commands in one place.")
            actionText: qsTr("New Space")
            onActionClicked: detail.createRequested()
        }

        Flickable {
            anchors.fill: parent
            anchors.margins: Theme.scaled(Theme.spacing.lg)
            visible: detail.space !== null
            contentWidth: width
            contentHeight: detailBody.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar { }

            ColumnLayout {
                id: detailBody
                width: parent.width
                spacing: Theme.scaled(Theme.spacing.md)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.md)

                    Rectangle {
                        width: Theme.scaled(Theme.spacing.xxxl)
                        height: width
                        radius: Theme.scaled(Theme.radius.md)
                        color: Theme.surfaceRaised
                        border.width: Theme.scaledInt(Theme.borders.hairline)
                        border.color: Theme.borderSubtle

                        Icon {
                            anchors.centerIn: parent
                            name: detail.space ? detail.space.icon : "folder"
                            color: detail.space
                                ? (detail.space.accent === "mint" ? Theme.accentMint
                                    : detail.space.accent === "blue" ? Theme.accentBlue
                                    : Theme.accentPurple)
                                : Theme.textSecondary
                            size: Theme.scaled(Theme.icon.sizes.lg)
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: detail.space ? detail.space.name : ""
                            color: Theme.textPrimary
                            font.family: Theme.typography.headingFamily
                            font.pixelSize: Theme.scaledInt(Theme.typography.heading2.size)
                            font.weight: Theme.typography.heading2.weight
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            text: detail.space ? detail.space.description : ""
                            color: Theme.textSecondary
                            font.family: Theme.typography.uiFamily
                            font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                            wrapMode: Text.Wrap
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.xs)

                    Button {
                        label: qsTr("Open Space")
                        variant: "primary"
                        iconName: "arrow-right"
                        onClicked: detail.openRequested(detail.space.id)
                    }
                    Button {
                        label: qsTr("Edit")
                        variant: "secondary"
                        iconName: "sliders"
                        onClicked: detail.editRequested(JSON.parse(JSON.stringify(detail.space)))
                    }
                    Button {
                        label: qsTr("Export")
                        variant: "ghost"
                        iconName: "folder"
                        onClicked: detail.exportRequested(detail.space.id)
                    }
                    Item { Layout.fillWidth: true }
                    IconButton {
                        iconName: "trash"
                        accessibleName: qsTr("Remove Space")
                        onClicked: detail.deleteRequested()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaledInt(Theme.borders.hairline)
                    color: Theme.borderSubtle
                }

                Text {
                    text: qsTr("Project folders")
                    color: Theme.textPrimary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                    font.weight: Theme.typography.title.weight
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.xxs)

                    Repeater {
                        model: detail.space ? detail.space.projectPaths : []
                        delegate: ListItem {
                            required property string modelData
                            Layout.fillWidth: true
                            title: modelData
                            description: qsTr("Project folder")
                            iconName: "folder"
                            enabled: false
                        }
                    }
                }

                Text {
                    text: qsTr("Applications")
                    color: Theme.textPrimary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                    font.weight: Theme.typography.title.weight
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.xxs)

                    Repeater {
                        model: detail.space ? detail.space.apps : []
                        delegate: ListItem {
                            required property string modelData
                            Layout.fillWidth: true
                            title: detail.appName(modelData)
                            description: modelData
                            iconName: detail.appIcon(modelData)
                            enabled: false
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.sm)

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Commands")
                        color: Theme.textPrimary
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                        font.weight: Theme.typography.title.weight
                    }
                    Text {
                        visible: detail.space && detail.space.commands.length > 0
                        text: detail.space && detail.space.trusted
                            ? qsTr("Allowed for this content") : qsTr("Not trusted")
                        color: detail.space && detail.space.trusted
                            ? Theme.accentMint : Theme.warning
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    }
                    Button {
                        visible: detail.space && detail.space.commands.length > 0
                            && !detail.space.trusted
                        label: qsTr("Review and allow")
                        variant: "secondary"
                        compact: true
                        onClicked: detail.trustRequested()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    visible: detail.space && detail.space.commands.length === 0
                    text: qsTr("No commands. Opening this Space only launches applications.")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    wrapMode: Text.Wrap
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Theme.scaled(Theme.spacing.xxs)

                    Repeater {
                        model: detail.space ? detail.space.commands : []
                        delegate: ListItem {
                            required property var modelData
                            Layout.fillWidth: true
                            title: modelData.executable + (modelData.args
                                && modelData.args.length > 0
                                ? " " + modelData.args.join(" ") : "")
                            description: modelData.cwd && modelData.cwd.length > 0
                                ? modelData.cwd : qsTr("No working directory")
                            iconName: "terminal"
                            enabled: false
                        }
                    }
                }
            }
        }

        function appName(desktopId) {
            for (let i = 0; i < installedApps.length; i++) {
                if (installedApps[i].id === desktopId)
                    return installedApps[i].name
            }
            return desktopId
        }

        function appIcon(desktopId) {
            for (let i = 0; i < installedApps.length; i++) {
                if (installedApps[i].id === desktopId)
                    return installedApps[i].icon
            }
            return "grid"
        }
    }
}
