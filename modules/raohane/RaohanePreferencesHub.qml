pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property string section: "keybinds"
    signal closeRequested()

    readonly property var shellBindings: [
        { key: "closeWindow", icon: "close", category: qsTr("WINDOW"), label: qsTr("Close active window"), detail: qsTr("Close the currently focused Hyprland window") },
        { key: "launcher", icon: "search", category: qsTr("SHELL"), label: qsTr("Launcher"), detail: qsTr("Open the Raohane application launcher") },
        { key: "settings", icon: "settings", category: qsTr("SHELL"), label: qsTr("Settings"), detail: qsTr("Open Raohane Settings") },
        { key: "controlCenter", icon: "tune", category: qsTr("SHELL"), label: qsTr("Control Center"), detail: qsTr("Open the right-side Control Center") },
        { key: "leftSidebar", icon: "view_sidebar", category: qsTr("SHELL"), label: qsTr("Left Sidebar"), detail: qsTr("Open the left information sidebar") },
        { key: "overview", icon: "grid_view", category: qsTr("SHELL"), label: qsTr("Overview"), detail: qsTr("Open the workspace overview") },
        { key: "clipboardSearch", icon: "content_paste_search", category: qsTr("SEARCH"), label: qsTr("Clipboard search"), detail: qsTr("Open Launcher directly in clipboard search") },
        { key: "wallpaper", icon: "wallpaper", category: qsTr("DESKTOP"), label: qsTr("Wallpaper Selector"), detail: qsTr("Open the wallpaper library") },
        { key: "randomWallpaper", icon: "shuffle", category: qsTr("DESKTOP"), label: qsTr("Random wallpaper"), detail: qsTr("Apply a random wallpaper") },
        { key: "mediaOverlay", icon: "music_note", category: qsTr("SHELL"), label: qsTr("Media overlay"), detail: qsTr("Open the fullscreen-friendly media controls") },
        { key: "session", icon: "power_settings_new", category: qsTr("SYSTEM"), label: qsTr("Session controls"), detail: qsTr("Open lock, logout and power actions") },
        { key: "lock", icon: "lock", category: qsTr("SYSTEM"), label: qsTr("Lock screen"), detail: qsTr("Secure the current Raohane session immediately") },
        { key: "taskManager", icon: "browse_activity", category: qsTr("SYSTEM"), label: qsTr("Task Manager"), detail: qsTr("Open the Raohane process manager") },
        { key: "osk", icon: "keyboard", category: qsTr("TOOLS"), label: qsTr("On-screen keyboard"), detail: qsTr("Toggle the Raohane on-screen keyboard") },
        { key: "screenTranslate", icon: "translate", category: qsTr("TOOLS"), label: qsTr("Screen Translator"), detail: qsTr("Select an area and translate recognized text") },
        { key: "screenshot", icon: "screenshot_region", category: qsTr("CAPTURE"), label: qsTr("Region screenshot"), detail: qsTr("Select a region and copy the screenshot") },
        { key: "regionSearch", icon: "image_search", category: qsTr("CAPTURE"), label: qsTr("Region image search"), detail: qsTr("Capture a region for image search") },
        { key: "regionOcr", icon: "document_scanner", category: qsTr("CAPTURE"), label: qsTr("Region OCR"), detail: qsTr("Recognize text inside a selected region") },
        { key: "regionRecord", icon: "screen_record", category: qsTr("CAPTURE"), label: qsTr("Region recording"), detail: qsTr("Record a selected screen region") },
        { key: "regionRecordWithSound", icon: "video_camera_back", category: qsTr("CAPTURE"), label: qsTr("Region recording with sound"), detail: qsTr("Record a selected region with audio") }
    ]

    function copyObject(value): var {
        const result = ({})
        if (value && typeof value === "object") {
            for (const key of Object.keys(value))
                result[key] = value[key]
        }
        return result
    }

    function keybindValue(key: string): string {
        return String(RaohaneConfig.keybinds?.[key] ?? "")
    }

    function normalizeCombo(value: string): string {
        return String(value ?? "")
            .split("+")
            .map(part => part.trim().toUpperCase())
            .filter(part => part.length > 0)
            .join("+")
    }

    function conflictCount(configKey: string): int {
        const combo = root.normalizeCombo(root.keybindValue(configKey))
        if (combo.length === 0)
            return 0
        let count = 0
        for (const binding of root.shellBindings) {
            if (binding.key !== configKey && root.normalizeCombo(root.keybindValue(binding.key)) === combo)
                count++
        }
        for (let slot = 1; slot <= 4; slot++) {
            const key = "app" + slot + "Keys"
            if (key !== configKey && root.normalizeCombo(root.keybindValue(key)) === combo)
                count++
        }
        return count
    }

    function setKeybind(key: string, value: string): void {
        const next = root.copyObject(RaohaneConfig.keybinds)
        next[key] = value
        RaohaneConfig.keybinds = RaohaneConfig.sanitizeKeybinds(next)
    }

    function resetKeybinds(): void {
        RaohaneConfig.keybinds = RaohaneConfig.defaultKeybinds()
    }

    function animationValue(key: string): var {
        return RaohaneConfig.animations?.[key]
    }

    function setAnimation(key: string, value): void {
        const next = root.copyObject(RaohaneConfig.animations)
        next[key] = value
        RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations(next)
    }

    function changeAnimation(key: string, delta: real, minimum: real, maximum: real): void {
        const current = Number(root.animationValue(key) ?? 0)
        root.setAnimation(key, Math.max(minimum, Math.min(maximum, current + delta)))
    }

    function shellMotionScale(): real {
        return Number(RaohaneConfig.style?.motionScale ?? 1)
    }

    function setShellMotionScale(value: real): void {
        const next = root.copyObject(RaohaneConfig.style)
        next.motionScale = Math.max(0, Math.min(1.4, value))
        RaohaneConfig.style = RaohaneConfig.sanitizeStyle(next)
    }

    function applyMotionPreset(preset: string): void {
        switch (preset) {
        case "snappy":
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({ enabled: true, windowMs: 170, workspaceMs: 220, layerMs: 160, fadeMs: 120, workspaceDistance: 10 })
            root.setShellMotionScale(0.78)
            break
        case "fluid":
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({ enabled: true, windowMs: 330, workspaceMs: 420, layerMs: 300, fadeMs: 240, workspaceDistance: 18 })
            root.setShellMotionScale(1.05)
            break
        case "off":
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({ enabled: false, windowMs: 240, workspaceMs: 300, layerMs: 220, fadeMs: 170, workspaceDistance: 14 })
            root.setShellMotionScale(0)
            break
        default:
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({ enabled: true, windowMs: 240, workspaceMs: 300, layerMs: 220, fadeMs: 170, workspaceDistance: 14 })
            root.setShellMotionScale(0.92)
            break
        }
    }

    function keyName(key: int, text: string): string {
        if (key >= Qt.Key_A && key <= Qt.Key_Z)
            return String.fromCharCode(65 + key - Qt.Key_A)
        if (key >= Qt.Key_0 && key <= Qt.Key_9)
            return String.fromCharCode(48 + key - Qt.Key_0)
        if (key >= Qt.Key_F1 && key <= Qt.Key_F12)
            return "F" + String(1 + key - Qt.Key_F1)
        switch (key) {
        case Qt.Key_Escape: return "Escape"
        case Qt.Key_Return: return "Return"
        case Qt.Key_Enter: return "Return"
        case Qt.Key_Space: return "Space"
        case Qt.Key_Tab: return "Tab"
        case Qt.Key_Backtab: return "Tab"
        case Qt.Key_Backspace: return "Backspace"
        case Qt.Key_Delete: return "Delete"
        case Qt.Key_Insert: return "Insert"
        case Qt.Key_Home: return "Home"
        case Qt.Key_End: return "End"
        case Qt.Key_PageUp: return "Page_Up"
        case Qt.Key_PageDown: return "Page_Down"
        case Qt.Key_Left: return "Left"
        case Qt.Key_Right: return "Right"
        case Qt.Key_Up: return "Up"
        case Qt.Key_Down: return "Down"
        case Qt.Key_Print: return "Print"
        }
        const clean = String(text ?? "").trim()
        return clean.length === 1 ? clean.toUpperCase() : ""
    }

    function comboFromEvent(event): string {
        const key = root.keyName(event.key, event.text)
        if (key === "")
            return ""
        const parts = []
        if (event.modifiers & Qt.MetaModifier)
            parts.push("SUPER")
        if (event.modifiers & Qt.ControlModifier)
            parts.push("CTRL")
        if (event.modifiers & Qt.AltModifier)
            parts.push("ALT")
        if (event.modifiers & Qt.ShiftModifier)
            parts.push("SHIFT")
        parts.push(key)
        return parts.join(" + ")
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 9

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            spacing: 8

            RaohaneIconButton {
                buttonSize: 30
                iconSize: 14
                icon: "arrow_back"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.closeRequested()
            }

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: 28
                radius: 1
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: root.section === "motion" ? qsTr("Motion & animations") : qsTr("Keyboard shortcuts")
                    color: RaohaneTheme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.1
                }

                Text {
                    text: root.section === "motion"
                        ? qsTr("Tune Raohane shell motion and Hyprland compositor transitions")
                        : qsTr("All Raohane shell actions in one configurable shortcut map")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }

            TabButton {
                icon: "keyboard"
                label: qsTr("Keybinds")
                active: root.section === "keybinds"
                onClicked: root.section = "keybinds"
            }

            TabButton {
                icon: "animation"
                label: qsTr("Motion")
                active: root.section === "motion"
                onClicked: root.section = "motion"
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.borderFaint
        }

        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            sourceComponent: root.section === "motion" ? motionPage : keybindPage
        }
    }

    Component {
        id: keybindPage

        Flickable {
            id: keyFlick
            contentWidth: width
            contentHeight: keyColumn.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2600

            Column {
                id: keyColumn
                width: Math.min(keyFlick.width - 24, 840)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 9

                RowLayout {
                    width: parent.width
                    height: 30

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Raohane actions")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    SmallAction {
                        icon: "restart_alt"
                        label: qsTr("Reset defaults")
                        onClicked: root.resetKeybinds()
                    }
                }

                RaohaneSurface {
                    width: parent.width
                    height: actionList.implicitHeight
                    surfaceRadius: 11
                    raised: false
                    showSheen: false
                    color: RaohaneTheme.surfaceDeep
                    border.color: RaohaneTheme.borderFaint
                    clip: true

                    Column {
                        id: actionList
                        width: parent.width

                        Repeater {
                            model: root.shellBindings

                            delegate: Item {
                                id: actionRow
                                required property var modelData
                                required property int index

                                width: actionList.width
                                height: 56

                                Rectangle {
                                    anchors.fill: parent
                                    color: RaohaneTheme.surfaceSubtle
                                    opacity: actionPointer.containsMouse ? 0.50 : 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: RaohaneMotion.micro }
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        bottom: parent.bottom
                                        leftMargin: 2
                                        topMargin: 10
                                        bottomMargin: 10
                                    }
                                    width: 2
                                    radius: 1
                                    color: RaohaneTheme.accent
                                    opacity: actionPointer.containsMouse ? 0.38 : 0

                                    Behavior on opacity {
                                        NumberAnimation { duration: RaohaneMotion.micro }
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 10
                                    spacing: 9

                                    RaohaneIcon {
                                        Layout.preferredWidth: 24
                                        text: actionRow.modelData.icon
                                        iconSize: 15
                                        fill: actionPointer.containsMouse ? 0.38 : 0
                                        symbolWeight: actionPointer.containsMouse ? 500 : 420
                                        color: actionPointer.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted

                                        Behavior on color {
                                            ColorAnimation { duration: RaohaneMotion.micro }
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 0

                                        RowLayout {
                                            Layout.fillWidth: true
                                            spacing: 6

                                            Text {
                                                text: actionRow.modelData.label
                                                color: RaohaneTheme.text
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                text: actionRow.modelData.category
                                                color: RaohaneTheme.textFaint
                                                font.pixelSize: 6
                                                font.weight: Font.DemiBold
                                                font.letterSpacing: 0.65
                                            }
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: actionRow.modelData.detail
                                            color: RaohaneTheme.textFaint
                                            font.pixelSize: 7
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ShortcutRecorder { configKey: actionRow.modelData.key }
                                }

                                Rectangle {
                                    visible: actionRow.index < root.shellBindings.length - 1
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        bottom: parent.bottom
                                        leftMargin: 12
                                        rightMargin: 12
                                    }
                                    height: 1
                                    color: RaohaneTheme.borderFaint
                                }

                                MouseArea {
                                    id: actionPointer
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                    z: -1
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: qsTr("Application shortcuts")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Repeater {
                    model: 4
                    delegate: ApplicationShortcut {
                        required property int index
                        width: keyColumn.width
                        slot: index + 1
                    }
                }

                Text {
                    width: parent.width
                    text: qsTr("Click a shortcut chip and press the new combination. Press Backspace while recording to disable it. Duplicate combinations are highlighted before Hyprland applies the map.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    lineHeight: 1.20
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    Component {
        id: motionPage

        Flickable {
            id: motionFlick
            contentWidth: width
            contentHeight: motionColumn.implicitHeight + 20
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2600

            Column {
                id: motionColumn
                width: Math.min(motionFlick.width - 24, 800)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 9

                Text {
                    width: parent.width
                    text: qsTr("Motion presets")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                GridLayout {
                    width: parent.width
                    columns: width > 620 ? 4 : 2
                    columnSpacing: 6
                    rowSpacing: 6

                    MotionPreset {
                        title: qsTr("Zen")
                        detail: qsTr("Quiet and balanced")
                        icon: "spa"
                        onClicked: root.applyMotionPreset("zen")
                    }
                    MotionPreset {
                        title: qsTr("Snappy")
                        detail: qsTr("Fast response")
                        icon: "bolt"
                        onClicked: root.applyMotionPreset("snappy")
                    }
                    MotionPreset {
                        title: qsTr("Fluid")
                        detail: qsTr("Longer and softer")
                        icon: "water"
                        onClicked: root.applyMotionPreset("fluid")
                    }
                    MotionPreset {
                        title: qsTr("Off")
                        detail: qsTr("Reduced motion")
                        icon: "motion_photos_off"
                        onClicked: root.applyMotionPreset("off")
                    }
                }

                Text {
                    width: parent.width
                    text: qsTr("Fine tuning")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                RaohaneSurface {
                    width: parent.width
                    height: motionRows.implicitHeight
                    surfaceRadius: 11
                    raised: false
                    showSheen: false
                    color: RaohaneTheme.surfaceDeep
                    border.color: RaohaneTheme.borderFaint
                    clip: true

                    Column {
                        id: motionRows
                        width: parent.width

                        ToggleMotionRow {
                            label: qsTr("Hyprland animations")
                            detail: qsTr("Enable compositor window, layer, workspace and fade transitions")
                            checked: Boolean(root.animationValue("enabled"))
                            onToggled: root.setAnimation("enabled", checked)
                        }
                        NumberMotionRow {
                            label: qsTr("Window duration")
                            detail: qsTr("Open, close and window movement timing")
                            keyName: "windowMs"
                            suffix: " ms"
                            minimum: 80
                            maximum: 1200
                            step: 10
                        }
                        NumberMotionRow {
                            label: qsTr("Workspace duration")
                            detail: qsTr("Workspace slide-fade timing")
                            keyName: "workspaceMs"
                            suffix: " ms"
                            minimum: 80
                            maximum: 1600
                            step: 10
                        }
                        NumberMotionRow {
                            label: qsTr("Layer duration")
                            detail: qsTr("Panels and compositor layer timing")
                            keyName: "layerMs"
                            suffix: " ms"
                            minimum: 80
                            maximum: 1200
                            step: 10
                        }
                        NumberMotionRow {
                            label: qsTr("Fade duration")
                            detail: qsTr("Opacity transition timing")
                            keyName: "fadeMs"
                            suffix: " ms"
                            minimum: 60
                            maximum: 1000
                            step: 10
                        }
                        NumberMotionRow {
                            label: qsTr("Workspace travel")
                            detail: qsTr("How far workspace transitions move across the screen")
                            keyName: "workspaceDistance"
                            suffix: "%"
                            minimum: 4
                            maximum: 40
                            step: 1
                        }

                        Item {
                            width: motionRows.width
                            height: 58

                            Rectangle {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    leftMargin: 12
                                    rightMargin: 12
                                }
                                height: 1
                                color: RaohaneTheme.borderFaint
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 13
                                anchors.rightMargin: 10
                                spacing: 12

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        text: qsTr("Raohane shell motion")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        text: qsTr("Scale QML surface transitions independently from Hyprland")
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 7
                                    }
                                }

                                StepControl {
                                    valueText: Math.round(root.shellMotionScale() * 100) + "%"
                                    onDecrease: root.setShellMotionScale(root.shellMotionScale() - 0.05)
                                    onIncrease: root.setShellMotionScale(root.shellMotionScale() + 0.05)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    component ShortcutRecorder: FocusScope {
        id: recorder

        required property string configKey
        property bool recording: false
        readonly property bool conflict: root.conflictCount(configKey) > 0

        implicitWidth: 174
        implicitHeight: 32
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 8
            raised: false
            active: recorder.recording
            hovered: recorderMouse.containsMouse || recorder.activeFocus
            pressed: recorderMouse.pressed
            interactive: true
            showSheen: false
            hoverScale: 1
            pressedScale: 1
            color: RaohaneTheme.surfaceDeep
            border.color: recorder.conflict ? RaohaneTheme.critical
                : active ? RaohaneTheme.accentBorder
                : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 7
                spacing: 5

                RaohaneIcon {
                    text: recorder.conflict ? "warning" : recorder.recording ? "keyboard_alt" : "keyboard"
                    iconSize: 12
                    fill: recorder.recording ? 1 : 0
                    color: recorder.conflict ? RaohaneTheme.critical
                        : recorder.recording ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: recorder.recording ? qsTr("Press shortcut…") : (root.keybindValue(recorder.configKey) || qsTr("Disabled"))
                    color: recorder.conflict ? RaohaneTheme.critical
                        : recorder.recording ? RaohaneTheme.accent : RaohaneTheme.text
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: recorderMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                recorder.recording = true
                recorder.forceActiveFocus()
            }
        }

        Keys.onPressed: event => {
            if (!recorder.recording)
                return
            if (event.key === Qt.Key_Backspace) {
                root.setKeybind(recorder.configKey, "")
                recorder.recording = false
                event.accepted = true
                return
            }
            if (event.key === Qt.Key_Escape && event.modifiers === Qt.NoModifier) {
                recorder.recording = false
                event.accepted = true
                return
            }
            const combo = root.comboFromEvent(event)
            if (combo !== "") {
                root.setKeybind(recorder.configKey, combo)
                recorder.recording = false
                event.accepted = true
            }
        }
    }

    component ApplicationShortcut: RaohaneSurface {
        id: appRow

        required property int slot
        property string nameKey: "app" + slot + "Name"
        property string keysKey: "app" + slot + "Keys"
        property string commandKey: "app" + slot + "Command"

        height: 76
        surfaceRadius: 10
        raised: false
        showSheen: false
        color: RaohaneTheme.surfaceDeep
        border.color: RaohaneTheme.borderFaint

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 2
                topMargin: 10
                bottomMargin: 10
            }
            width: 2
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.18
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RaohaneIcon {
                Layout.preferredWidth: 22
                text: "apps"
                iconSize: 15
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 5

                FieldEditor {
                    configKey: appRow.nameKey
                    placeholderText: qsTr("Application name")
                }

                FieldEditor {
                    configKey: appRow.commandKey
                    placeholderText: qsTr("Command, e.g. firefox or kitty")
                    monospace: true
                }
            }

            ShortcutRecorder { configKey: appRow.keysKey }
        }
    }

    component FieldEditor: RaohaneSurface {
        id: editor

        required property string configKey
        property string placeholderText: ""
        property bool monospace: false

        Layout.fillWidth: true
        Layout.preferredHeight: 28
        surfaceRadius: 7
        raised: false
        showSheen: false
        hovered: editorField.activeFocus
        color: RaohaneTheme.surfaceSubtle
        border.color: editorField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        TextInput {
            id: editorField
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            text: root.keybindValue(editor.configKey)
            color: RaohaneTheme.text
            selectionColor: RaohaneTheme.accentSoft
            selectedTextColor: RaohaneTheme.text
            font.pixelSize: 7
            font.family: editor.monospace ? "JetBrainsMono Nerd Font" : ""
            clip: true
            onEditingFinished: root.setKeybind(editor.configKey, text)

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: editor.placeholderText
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
                visible: editorField.text.length === 0 && !editorField.activeFocus
            }
        }
    }

    component ToggleMotionRow: Item {
        id: toggleRow

        required property string label
        required property string detail
        required property bool checked
        signal toggled(bool checked)

        width: parent?.width ?? 0
        height: 58

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 13
            anchors.rightMargin: 11
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: toggleRow.label
                    color: RaohaneTheme.text
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Text {
                    text: toggleRow.detail
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }

            RaohaneSwitch {
                checked: toggleRow.checked
                onToggled: toggleRow.toggled(checked)
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 12
                rightMargin: 12
            }
            height: 1
            color: RaohaneTheme.borderFaint
        }
    }

    component NumberMotionRow: Item {
        id: numberRow

        required property string label
        required property string detail
        required property string keyName
        required property string suffix
        required property real minimum
        required property real maximum
        required property real step

        width: parent?.width ?? 0
        height: 58

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 13
            anchors.rightMargin: 10
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: numberRow.label
                    color: RaohaneTheme.text
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Text {
                    text: numberRow.detail
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }

            StepControl {
                valueText: String(root.animationValue(numberRow.keyName)) + numberRow.suffix
                onDecrease: root.changeAnimation(numberRow.keyName, -numberRow.step, numberRow.minimum, numberRow.maximum)
                onIncrease: root.changeAnimation(numberRow.keyName, numberRow.step, numberRow.minimum, numberRow.maximum)
            }
        }

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 12
                rightMargin: 12
            }
            height: 1
            color: RaohaneTheme.borderFaint
        }
    }

    component StepControl: RaohaneSurface {
        id: stepControl

        required property string valueText
        signal decrease()
        signal increase()

        Layout.preferredWidth: 124
        Layout.preferredHeight: 32
        surfaceRadius: 8
        raised: false
        showSheen: false
        color: RaohaneTheme.surfaceSubtle
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 2
            anchors.rightMargin: 2
            spacing: 1

            RaohaneIconButton {
                buttonSize: 26
                iconSize: 12
                icon: "remove"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: stepControl.decrease()
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: stepControl.valueText
                color: RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            RaohaneIconButton {
                buttonSize: 26
                iconSize: 12
                icon: "add"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: stepControl.increase()
            }
        }
    }

    component MotionPreset: RaohaneSurface {
        id: preset

        required property string title
        required property string detail
        required property string icon
        signal clicked()

        Layout.fillWidth: true
        Layout.preferredHeight: 66
        surfaceRadius: 9
        raised: false
        hovered: presetMouse.containsMouse || activeFocus
        pressed: presetMouse.pressed
        interactive: true
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        color: hovered ? RaohaneTheme.surfaceSubtle : RaohaneTheme.surfaceDeep
        border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                leftMargin: 2
                topMargin: 9
                bottomMargin: 9
            }
            width: 2
            radius: 1
            color: RaohaneTheme.accent
            opacity: preset.hovered || preset.activeFocus ? 0.48 : 0.16

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.micro }
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 2

            RaohaneIcon {
                text: preset.icon
                iconSize: 15
                fill: preset.hovered || preset.activeFocus ? 0.45 : 0
                color: preset.hovered || preset.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: preset.title
                color: RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: preset.detail
                color: RaohaneTheme.textFaint
                font.pixelSize: 6
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: presetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: preset.forceActiveFocus()
            onClicked: preset.clicked()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                preset.clicked()
                event.accepted = true
            }
        }
    }

    component SmallAction: FocusScope {
        id: smallAction

        required property string icon
        required property string label
        signal clicked()

        implicitWidth: 116
        implicitHeight: 30
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 8
            raised: false
            hovered: smallMouse.containsMouse || smallAction.activeFocus
            pressed: smallMouse.pressed
            interactive: true
            showSheen: false
            hoverScale: 1
            pressedScale: 1
            transparentIdle: !hovered
            border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                RaohaneIcon {
                    text: smallAction.icon
                    iconSize: 12
                    color: smallAction.activeFocus || smallMouse.containsMouse
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: smallAction.label
                    color: RaohaneTheme.text
                    font.pixelSize: 7
                    font.weight: Font.Medium
                }
            }
        }

        MouseArea {
            id: smallMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: smallAction.forceActiveFocus()
            onClicked: smallAction.clicked()
        }
    }

    component TabButton: FocusScope {
        id: tab

        required property string icon
        required property string label
        required property bool active
        signal clicked()

        implicitWidth: 102
        implicitHeight: 30
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 8
            raised: false
            active: tab.active
            transparentIdle: !tab.active && !hovered
            hovered: tabMouse.containsMouse || tab.activeFocus
            pressed: tabMouse.pressed
            interactive: true
            showSheen: false
            hoverScale: 1
            pressedScale: 1
            border.color: tab.active ? RaohaneTheme.accentBorder
                : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

            RowLayout {
                anchors.centerIn: parent
                spacing: 5

                RaohaneIcon {
                    text: tab.icon
                    iconSize: 12
                    fill: tab.active ? 1 : tab.activeFocus || tabMouse.containsMouse ? 0.35 : 0
                    color: tab.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    text: tab.label
                    color: tab.active ? RaohaneTheme.text : RaohaneTheme.textMuted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                }
            }
        }

        MouseArea {
            id: tabMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: tab.forceActiveFocus()
            onClicked: tab.clicked()
        }
    }
}
