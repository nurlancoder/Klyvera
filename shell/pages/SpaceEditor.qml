pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts
import "../styles"
import "../ui"

Item {
    id: root

    property var draft: ({
        "id": "",
        "name": "",
        "description": "",
        "icon": "folder",
        "accent": "purple",
        "projectPaths": [],
        "apps": [],
        "commands": []
    })
    property var installedApps: []
    property var errors: ({})
    property int step: 0
    property bool trusted: false
    property string title: qsTr("New Space")
    readonly property string layoutClass: Theme.layoutClass(width)
    readonly property bool compact: layoutClass === "compact"
    readonly property int stepCount: 3
    readonly property var accents: ["purple", "blue", "mint"]
    readonly property var icons: ["folder", "code", "grid", "terminal", "sliders"]

    signal saved(var space)
    signal cancelled()
    signal folderPickerRequested()
    signal commandTrustConfirmed(var space)

    implicitWidth: Theme.scaled(Theme.layout.spaces.wizardMaxWidth)

    function clone(value) {
        return JSON.parse(JSON.stringify(value))
    }

    function load(space) {
        if (!space) {
            draft = {
                "id": "",
                "name": "",
                "description": "",
                "icon": "folder",
                "accent": "purple",
                "projectPaths": [],
                "apps": [],
                "commands": []
            }
            title = qsTr("New Space")
            trusted = false
        } else {
            draft = clone(space)
            if (!draft.projectPaths)
                draft.projectPaths = []
            if (!draft.apps)
                draft.apps = []
            if (!draft.commands)
                draft.commands = []
            title = qsTr("Edit Space")
            trusted = !!space.trusted
        }
        errors = ({})
        step = 0
    }

    function updateDraft(key, value) {
        if (draft[key] === value)
            return
        const next = clone(draft)
        next[key] = value
        draft = next
    }

    function validationError(key) {
        return errors[key] ? errors[key] : ""
    }

    function isUnsafePath(path) {
        if (path.length === 0 || path[0] !== "/")
            return true
        if (path.indexOf("\u0000") >= 0 || path.indexOf("\n") >= 0)
            return true
        const parts = path.split("/")
        for (let i = 0; i < parts.length; i++) {
            if (parts[i] === "..")
                return true
        }
        return false
    }

    function isShell(executable) {
        const name = String(executable).split("/").pop().toLocaleLowerCase()
        return ["sh", "bash", "zsh", "fish", "dash", "ksh", "csh", "tcsh",
            "pwsh", "powershell"].indexOf(name) >= 0
    }

    function hasControlBytes(text) {
        return /[\u0000-\u001f\u007f]/.test(String(text))
    }

    function validate() {
        const found = ({})
        const name = String(draft.name).trim()
        if (name.length < 1)
            found.name = qsTr("Give this Space a name.")
        else if (name.length > 64)
            found.name = qsTr("Keep the name under 64 characters.")

        if (String(draft.description).length > 240)
            found.description = qsTr("Keep the description under 240 characters.")

        if (draft.projectPaths.length === 0)
            found.projects = qsTr("Add at least one project folder.")
        else {
            const seen = ({})
            for (let i = 0; i < draft.projectPaths.length; i++) {
                const path = String(draft.projectPaths[i]).trim()
                if (isUnsafePath(path)) {
                    found.projects = qsTr("Project folders must be absolute paths without '..'.")
                    break
                }
                if (seen[path]) {
                    found.projects = qsTr("Project folders must be unique.")
                    break
                }
                seen[path] = true
            }
        }

        if (draft.apps.length === 0)
            found.apps = qsTr("Choose at least one application.")
        else {
            for (let i = 0; i < draft.apps.length; i++) {
                const desktopId = String(draft.apps[i])
                if (!desktopId.endsWith(".desktop") || desktopId.indexOf("/") >= 0) {
                    found.apps = qsTr("Applications must be installed desktop entries.")
                    break
                }
            }
        }

        for (let i = 0; i < draft.commands.length; i++) {
            const command = draft.commands[i]
            if (!command.executable || String(command.executable).trim().length === 0) {
                found.commands = qsTr("Every command needs an executable.")
                break
            }
            if (isShell(command.executable)) {
                found.commands = qsTr("Shell interpreters are not allowed. Use an explicit program and arguments.")
                break
            }
            if (hasControlBytes(command.executable)) {
                found.commands = qsTr("Commands cannot contain control characters.")
                break
            }
            const args = command.args ? command.args : []
            for (let j = 0; j < args.length; j++) {
                if (hasControlBytes(args[j])) {
                    found.commands = qsTr("Arguments cannot contain control characters.")
                    break
                }
            }
            if (found.commands)
                break
            if (command.cwd && isUnsafePath(String(command.cwd))) {
                found.commands = qsTr("A command working directory must be an absolute path without '..'.")
                break
            }
            if (command.cwd && draft.projectPaths.length > 0) {
                let inside = false
                for (let j = 0; j < draft.projectPaths.length; j++) {
                    const project = String(draft.projectPaths[j]).replace(/\/+$/, "")
                    if (String(command.cwd) === project
                        || String(command.cwd).startsWith(project + "/")) {
                        inside = true
                        break
                    }
                }
                if (!inside) {
                    found.commands = qsTr("A command working directory must stay inside a project folder.")
                    break
                }
            }
        }

        errors = found
        return Object.keys(found).length === 0
    }

    function canContinue() {
        if (step === 0)
            return String(draft.name).trim().length > 0
                && draft.projectPaths.length > 0
        if (step === 1)
            return draft.apps.length > 0
        return true
    }

    function nextStep() {
        if (step === 0) {
            if (!validate())
                return
        }
        if (step < stepCount - 1)
            step += 1
    }

    function previousStep() {
        if (step > 0)
            step -= 1
    }

    function save() {
        if (!validate())
            return
        if (draft.commands.length > 0 && !trusted) {
            trustDialog.open()
            return
        }
        finish()
    }

    function finish() {
        const next = clone(draft)
        next.name = String(next.name).trim()
        next.projectPaths = next.projectPaths.map(function(path) {
            return String(path).trim()
        })
        saved(next)
    }

    function addProjectPath(path) {
        const value = String(path).trim()
        if (value.length === 0)
            return
        const next = clone(draft)
        if (next.projectPaths.indexOf(value) < 0)
            next.projectPaths.push(value)
        draft = next
    }

    function removeProjectPath(index) {
        const next = clone(draft)
        next.projectPaths.splice(index, 1)
        draft = next
    }

    function setApps(ids) {
        const next = clone(draft)
        next.apps = ids
        draft = next
    }

    function addCommand(executable, args, cwd) {
        const next = clone(draft)
        next.commands.push({
            "executable": executable,
            "args": args,
            "cwd": cwd
        })
        draft = next
    }

    function removeCommand(index) {
        const next = clone(draft)
        next.commands.splice(index, 1)
        draft = next
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: Theme.scaled(Theme.spacing.lg)

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(Theme.spacing.md)

            IconButton {
                compact: true
                iconName: "chevron-left"
                accessibleName: qsTr("Back to Spaces")
                onClicked: root.cancelled()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: root.title
                    color: Theme.textPrimary
                    font.family: Theme.typography.headingFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.heading2.size)
                    font.weight: Theme.typography.heading2.weight
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: qsTr("A Space keeps project folders, applications and optional commands together.")
                    color: Theme.textSecondary
                    font.family: Theme.typography.uiFamily
                    font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    wrapMode: Text.Wrap
                }
            }

            Text {
                text: qsTr("Step %1 of %2").arg(root.step + 1).arg(root.stepCount)
                color: Theme.textSecondary
                font.family: Theme.typography.monoFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Theme.scaled(Theme.spacing.xs)

            Repeater {
                model: [qsTr("Details"), qsTr("Projects and apps"), qsTr("Commands and review")]

                delegate: Rectangle {
                    id: stepBar
                    required property int index
                    Layout.fillWidth: true
                    implicitHeight: Theme.scaled(Theme.spacing.xxs)
                    radius: height / 2
                    color: index <= root.step ? Theme.accentPurple : Theme.surfaceActive
                    Accessible.ignored: true
                }
            }
        }

        Flickable {
            id: flick
            Layout.fillWidth: true
            Layout.fillHeight: true
            contentWidth: width
            contentHeight: body.implicitHeight + Theme.scaled(Theme.spacing.md)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Controls.ScrollBar.vertical: Controls.ScrollBar { }

            ColumnLayout {
                id: body
                x: 0
                width: flick.width
                spacing: Theme.scaled(Theme.spacing.md)

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.step === 0
                    spacing: Theme.scaled(Theme.spacing.md)

                    TextField {
                        Layout.fillWidth: true
                        label: qsTr("Name")
                        placeholder: qsTr("API platform")
                        text: root.draft.name
                        errorText: root.validationError("name")
                        maximumLength: 64
                        onTextChanged: root.updateDraft("name", text)
                    }

                    TextField {
                        Layout.fillWidth: true
                        label: qsTr("Description")
                        placeholder: qsTr("What belongs in this workspace?")
                        text: root.draft.description
                        errorText: root.validationError("description")
                        maximumLength: 240
                        onTextChanged: root.updateDraft("description", text)
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(Theme.spacing.md)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(Theme.spacing.xs)
                            Text {
                                text: qsTr("Icon")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
                            }
                            Flow {
                                Layout.fillWidth: true
                                spacing: Theme.scaled(Theme.spacing.xs)
                                Repeater {
                                    model: root.icons
                                    delegate: IconButton {
                                        required property string modelData
                                        iconName: modelData
                                        accessibleName: qsTr("Use %1 icon").arg(modelData)
                                        onClicked: root.updateDraft("icon", modelData)
                                        background: Rectangle {
                                            radius: Theme.scaled(Theme.radius.sm)
                                            color: root.draft.icon === modelData
                                                ? Theme.selection : Theme.surface
                                            border.width: Theme.scaledInt(Theme.borders.hairline)
                                            border.color: root.draft.icon === modelData
                                                ? Theme.accentPurple : Theme.borderStrong
                                            FocusRing { show: parent.activeFocus }
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: Theme.scaled(Theme.spacing.xs)
                            Text {
                                text: qsTr("Accent")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.label.size)
                            }
                            RowLayout {
                                spacing: Theme.scaled(Theme.spacing.xs)
                                Repeater {
                                    model: root.accents
                                    delegate: Controls.AbstractButton {
                                        id: accentButton
                                        required property string modelData
                                        implicitWidth: Theme.scaled(Theme.accessibility.minimumTargetSize)
                                        implicitHeight: implicitWidth
                                        padding: 0
                                        Accessible.role: Accessible.RadioButton
                                        Accessible.name: qsTr("%1 accent").arg(modelData)
                                        Accessible.selected: root.draft.accent === modelData
                                        onClicked: root.updateDraft("accent", modelData)

                                        contentItem: Item {
                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: Theme.scaled(Theme.spacing.md)
                                                height: width
                                                radius: width / 2
                                                color: modelData === "blue" ? Theme.accentBlue
                                                    : modelData === "mint" ? Theme.accentMint
                                                    : Theme.accentPurple
                                                border.width: root.draft.accent === modelData
                                                    ? Theme.scaledInt(Theme.borders.focus) : 0
                                                border.color: Theme.textPrimary
                                            }
                                        }
                                        background: Rectangle {
                                            radius: Theme.scaled(Theme.radius.sm)
                                            color: accentButton.hovered ? Theme.surfaceHover : "transparent"
                                            FocusRing { show: accentButton.activeFocus }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Theme.scaledInt(Theme.borders.hairline)
                        color: Theme.borderSubtle
                    }

                    TextField {
                        id: projectField
                        Layout.fillWidth: true
                        label: qsTr("Project folder")
                        placeholder: "/home/you/src/project"
                        helperText: qsTr("Absolute paths only. Folders are checked again by Klyvera Core.")
                        onAccepted: {
                            root.addProjectPath(text)
                            text = ""
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight
                        spacing: Theme.scaled(Theme.spacing.sm)

                        Button {
                            label: qsTr("Browse")
                            variant: "secondary"
                            iconName: "folder"
                            onClicked: root.folderPickerRequested()
                        }
                        Button {
                            label: qsTr("Add folder")
                            variant: "secondary"
                            iconName: "plus"
                            onClicked: root.addProjectPath(projectField.text)
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.validationError("projects").length > 0
                        text: root.validationError("projects")
                        color: Theme.danger
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                        wrapMode: Text.Wrap
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(Theme.spacing.xxs)

                        Repeater {
                            model: root.draft.projectPaths
                            delegate: ListItem {
                                id: pathRow
                                required property int index
                                required property string modelData
                                Layout.fillWidth: true
                                title: modelData
                                description: qsTr("Project folder")
                                iconName: "folder"
                                trailing: IconButton {
                                    compact: true
                                    iconName: "trash"
                                    accessibleName: qsTr("Remove folder")
                                    onClicked: root.removeProjectPath(pathRow.index)
                                }
                            }
                        }
                    }

                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.step === 1
                    spacing: Theme.scaled(Theme.spacing.md)

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(Theme.spacing.sm)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: qsTr("Applications")
                                color: Theme.textPrimary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                                font.weight: Theme.typography.title.weight
                            }
                            Text {
                                text: qsTr("Only installed desktop entries can be launched. Klyvera never starts shell strings.")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                wrapMode: Text.Wrap
                            }
                        }
                        Button {
                            label: qsTr("Choose apps")
                            iconName: "plus"
                            onClicked: appPicker.open()
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.validationError("apps").length > 0
                        text: root.validationError("apps")
                        color: Theme.danger
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                    }

                    EmptyState {
                        Layout.fillWidth: true
                        visible: root.draft.apps.length === 0
                        iconName: "grid"
                        title: qsTr("No applications yet")
                        message: qsTr("Add the apps you want this Space to open.")
                        actionText: qsTr("Choose apps")
                        onActionClicked: appPicker.open()
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(Theme.spacing.xxs)

                        Repeater {
                            model: root.draft.apps
                            delegate: ListItem {
                                id: appRow
                                required property int index
                                required property string modelData
                                Layout.fillWidth: true
                                title: root.appName(modelData)
                                description: modelData
                                iconName: root.appIcon(modelData)
                                trailing: IconButton {
                                    compact: true
                                    iconName: "close"
                                    accessibleName: qsTr("Remove application")
                                    onClicked: {
                                        const next = root.draft.apps.slice()
                                        next.splice(appRow.index, 1)
                                        root.setApps(next)
                                    }
                                }
                            }
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.step === 2
                    spacing: Theme.scaled(Theme.spacing.md)

                    Card {
                        Layout.fillWidth: true
                        title: qsTr("Review")
                        subtitle: qsTr("Saved locally and validated by the core")

                        ColumnLayout {
                            width: parent.width
                            spacing: Theme.scaled(Theme.spacing.sm)

                            Text {
                                Layout.fillWidth: true
                                text: root.draft.name
                                color: Theme.textPrimary
                                font.family: Theme.typography.headingFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.heading3.size)
                                font.weight: Theme.typography.heading3.weight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: root.draft.description.length > 0
                                    ? root.draft.description : qsTr("No description")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.body.size)
                                wrapMode: Text.Wrap
                            }
                            Text {
                                Layout.fillWidth: true
                                text: qsTr("%1 folders · %2 applications · %3 commands")
                                    .arg(root.draft.projectPaths.length)
                                    .arg(root.draft.apps.length)
                                    .arg(root.draft.commands.length)
                                color: Theme.textSecondary
                                font.family: Theme.typography.monoFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(Theme.spacing.sm)

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0
                            Text {
                                text: qsTr("Optional commands")
                                color: Theme.textPrimary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.title.size)
                                font.weight: Theme.typography.title.weight
                            }
                            Text {
                                text: qsTr("Commands run as explicit programs with literal arguments. Shell interpreters are rejected.")
                                color: Theme.textSecondary
                                font.family: Theme.typography.uiFamily
                                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                                wrapMode: Text.Wrap
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        visible: root.validationError("commands").length > 0
                        text: root.validationError("commands")
                        color: Theme.danger
                        font.family: Theme.typography.uiFamily
                        font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                        wrapMode: Text.Wrap
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(Theme.spacing.xxs)

                        Repeater {
                            model: root.draft.commands
                            delegate: ListItem {
                                id: commandRow
                                required property int index
                                required property var modelData
                                Layout.fillWidth: true
                                title: modelData.executable + (modelData.args
                                    && modelData.args.length > 0
                                    ? " " + modelData.args.join(" ") : "")
                                description: modelData.cwd && modelData.cwd.length > 0
                                    ? modelData.cwd : qsTr("No working directory")
                                iconName: "terminal"
                                trailing: IconButton {
                                    compact: true
                                    iconName: "trash"
                                    accessibleName: qsTr("Remove command")
                                    onClicked: root.removeCommand(commandRow.index)
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: Theme.scaled(Theme.radius.md)
                        color: Theme.surface
                        border.width: Theme.scaledInt(Theme.borders.hairline)
                        border.color: Theme.borderSubtle
                        implicitHeight: commandForm.implicitHeight + Theme.scaled(Theme.spacing.md) * 2

                        ColumnLayout {
                            id: commandForm
                            x: Theme.scaled(Theme.spacing.md)
                            y: Theme.scaled(Theme.spacing.md)
                            width: parent.width - Theme.scaled(Theme.spacing.md) * 2
                            spacing: Theme.scaled(Theme.spacing.sm)

                            TextField {
                                id: executableField
                                Layout.fillWidth: true
                                label: qsTr("Executable")
                                placeholder: "cargo"
                            }
                            TextField {
                                id: argsField
                                Layout.fillWidth: true
                                label: qsTr("Arguments, one per line")
                                placeholder: "test\n--all"
                                helperText: qsTr("Each line is passed as one literal argument. No quoting or shell expansion.")
                            }
                            TextField {
                                id: cwdField
                                Layout.fillWidth: true
                                label: qsTr("Working directory")
                                placeholder: "/home/you/src/project"
                                helperText: qsTr("Optional. Must stay inside one of the project folders.")
                            }
                            Button {
                                Layout.alignment: Qt.AlignRight
                                label: qsTr("Add command")
                                iconName: "plus"
                                onClicked: {
                                    const args = argsField.text.replace(/\r/g, "").split("\n")
                                        .filter(function(value) { return value.length > 0 })
                                    root.addCommand(executableField.text.trim(), args, cwdField.text.trim())
                                    executableField.text = ""
                                    argsField.text = ""
                                    cwdField.text = ""
                                }
                            }
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
                onClicked: root.previousStep()
            }
            Item { Layout.fillWidth: true }
            Button {
                visible: root.step < root.stepCount - 1
                label: qsTr("Continue")
                iconName: "arrow-right"
                enabled: root.canContinue()
                onClicked: root.nextStep()
            }
            Button {
                visible: root.step === root.stepCount - 1
                label: qsTr("Save Space")
                variant: "primary"
                iconName: "check"
                onClicked: root.save()
            }
        }
    }

    Dialog {
        id: appPicker
        title: qsTr("Choose applications")
        message: qsTr("Selected desktop entries open with this Space.")
        primaryText: qsTr("Add selected")
        secondaryText: qsTr("Cancel")
        property var selected: ({})

        onOpened: {
            const next = ({})
            for (let i = 0; i < root.draft.apps.length; i++)
                next[root.draft.apps[i]] = true
            selected = next
        }
        onAccepted: {
            const ids = []
            for (let i = 0; i < root.installedApps.length; i++) {
                const app = root.installedApps[i]
                if (selected[app.id])
                    ids.push(app.id)
            }
            root.setApps(ids)
        }

        content: ColumnLayout {
            width: parent ? parent.width : 0
            spacing: Theme.scaled(Theme.spacing.xxs)

            ListView {
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(260)
                clip: true
                model: root.installedApps
                spacing: Theme.scaled(Theme.spacing.xxs)

                delegate: ListItem {
                    id: pickRow
                    required property var modelData
                    width: ListView.view.width
                    title: modelData.name
                    description: modelData.description
                    iconName: modelData.icon
                    selected: !!appPicker.selected[modelData.id]
                    trailing: Icon {
                        visible: !!appPicker.selected[pickRow.modelData.id]
                        name: "check"
                        color: Theme.accentMint
                        size: Theme.scaled(Theme.icon.sizes.md)
                    }
                    onClicked: {
                        const next = Object.assign({}, appPicker.selected)
                        if (next[modelData.id])
                            delete next[modelData.id]
                        else
                            next[modelData.id] = true
                        appPicker.selected = next
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: root.installedApps.length === 0
                text: qsTr("No desktop entries were found. Install applications or check the desktop entry path.")
                color: Theme.textSecondary
                font.family: Theme.typography.uiFamily
                font.pixelSize: Theme.scaledInt(Theme.typography.caption.size)
                wrapMode: Text.Wrap
            }
        }
    }

    ConfirmDialog {
        id: trustDialog
        title: qsTr("Allow commands?")
        message: qsTr("This Space contains commands. They will only run after this confirmation and the permission is tied to the exact Space content.")
        confirmText: qsTr("Allow and save")
        cancelText: qsTr("Keep disabled")
        primaryVariant: "primary"

        onAccepted: {
            root.trusted = true
            root.commandTrustConfirmed(root.clone(root.draft))
            root.finish()
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
