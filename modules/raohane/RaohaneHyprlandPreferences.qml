pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property string section: "keybinds"
    signal closeRequested()

    readonly property var coreBindings: [
        { key: "closeWindow", icon: "close", label: qsTr("Close active window"), detail: qsTr("Close the currently focused Hyprland window") },
        { key: "launcher", icon: "search", label: qsTr("Launcher"), detail: qsTr("Open the Raohane application launcher") },
        { key: "settings", icon: "settings", label: qsTr("Settings"), detail: qsTr("Open Raohane Settings") },
        { key: "controlCenter", icon: "tune", label: qsTr("Control Center"), detail: qsTr("Open the right-side Control Center") },
        { key: "mediaOverlay", icon: "music_note", label: qsTr("Media overlay"), detail: qsTr("Open the fullscreen-friendly media controls") },
        { key: "screenshot", icon: "screenshot_region", label: qsTr("Region screenshot"), detail: qsTr("Select a region and copy the screenshot") }
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

    function setKeybind(key: string, value: string): void {
        const next = root.copyObject(RaohaneConfig.keybinds)
        next[key] = value
        RaohaneConfig.keybinds = RaohaneConfig.sanitizeKeybinds(next)
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

    function resetKeybinds(): void {
        RaohaneConfig.keybinds = RaohaneConfig.defaultKeybinds()
    }

    function applyMotionPreset(preset: string): void {
        switch (preset) {
        case "snappy":
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({
                enabled: true, windowMs: 170, workspaceMs: 220, layerMs: 160, fadeMs: 120, workspaceDistance: 10
            })
            root.setShellMotionScale(0.78)
            break
        case "fluid":
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({
                enabled: true, windowMs: 330, workspaceMs: 420, layerMs: 300, fadeMs: 240, workspaceDistance: 18
            })
            root.setShellMotionScale(1.05)
            break
        case "off":
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({
                enabled: false, windowMs: 240, workspaceMs: 300, layerMs: 220, fadeMs: 170, workspaceDistance: 14
            })
            root.setShellMotionScale(0)
            break
        default:
            RaohaneConfig.animations = RaohaneConfig.sanitizeAnimations({
                enabled: true, windowMs: 240, workspaceMs: 300, layerMs: 220, fadeMs: 170, workspaceDistance: 14
            })
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
        anchors.margins: 18
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 46
            spacing: 10

            RaohaneIconButton {
                buttonSize: 34
                iconSize: 16
                icon: "arrow_back"
                transparentIdle: true
                showSheen: false
                onClicked: root.closeRequested()
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: root.section === "motion" ? qsTr("Motion & animations") : qsTr("Keyboard shortcuts")
                    color: RaohaneTheme.text
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }

                Text {
                    text: root.section === "motion"
                        ? qsTr("Tune Raohane shell motion and Hyprland compositor transitions")
                        : qsTr("Record shortcuts for shell actions and your own applications")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
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
            contentHeight: keyColumn.implicitHeight + 28
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2600

            Column {
                id: keyColumn
                width: Math.min(keyFlick.width - 32, 780)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Text {
                    width: parent.width
                    text: qsTr("Raohane actions")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                RaohaneSurface {
                    width: parent.width
                    height: coreList.implicitHeight
                    surfaceRadius: RaohaneTheme.radiusLarge
                    raised: false
                    showSheen: false
                    clip: true

                    Column {
                        id: coreList
                        width: parent.width

                        Repeater {
                            model: root.coreBindings

                            delegate: Item {
                                id: coreRow
                                required property var modelData
                                required property int index
                                width: coreList.width
                                height: 68

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    RaohaneSurface {
                                        Layout.preferredWidth: 38
                                        Layout.preferredHeight: 38
                                        surfaceRadius: 12
                                        raised: false
                                        showSheen: false

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: coreRow.modelData.icon
                                            iconSize: 18
                                            color: RaohaneTheme.accent
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1

                                        Text {
                                            Layout.fillWidth: true
                                            text: coreRow.modelData.label
                                            color: RaohaneTheme.text
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            text: coreRow.modelData.detail
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 8
                                            elide: Text.ElideRight
                                        }
                                    }

                                    ShortcutRecorder {
                                        configKey: coreRow.modelData.key
                                    }
                                }

                                Rectangle {
                                    visible: coreRow.index < root.coreBindings.length - 1
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.bottom: parent.bottom
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    height: 1
                                    color: RaohaneTheme.borderFaint
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: 8

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Application shortcuts")
                        color: RaohaneTheme.text
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    SmallAction {
                        icon: "restart_alt"
                        label: qsTr("Reset defaults")
                        onClicked: root.resetKeybinds()
                    }
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
                    text: qsTr("Click a shortcut chip and press the new combination. Press Backspace while recording to disable it. Application commands are executed through Hyprland's non-blocking exec dispatcher.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    lineHeight: 1.25
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
            contentHeight: motionColumn.implicitHeight + 28
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            flickDeceleration: 2600

            Column {
                id: motionColumn
                width: Math.min(motionFlick.width - 32, 780)
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Text {
                    width: parent.width
                    text: qsTr("Motion presets")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                GridLayout {
                    width: parent.width
                    columns: width > 620 ? 4 : 2
                    columnSpacing: 8
                    rowSpacing: 8

                    MotionPreset { title: qsTr("Zen"); detail: qsTr("Quiet and balanced"); icon: "spa"; onClicked: root.applyMotionPreset("zen") }
                    MotionPreset { title: qsTr("Snappy"); detail: qsTr("Fast response"); icon: "bolt"; onClicked: root.applyMotionPreset("snappy") }
                    MotionPreset { title: qsTr("Fluid"); detail: qsTr("Longer and softer"); icon: "water"; onClicked: root.applyMotionPreset("fluid") }
                    MotionPreset { title: qsTr("Off"); detail: qsTr("Reduced motion"); icon: "motion_photos_off"; onClicked: root.applyMotionPreset("off") }
                }

                Text {
                    width: parent.width
                    text: qsTr("Fine tuning")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                RaohaneSurface {
                    width: parent.width
                    height: motionRows.implicitHeight
                    surfaceRadius: RaohaneTheme.radiusLarge
                    raised: false
                    showSheen: false
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

                        NumberMotionRow { label: qsTr("Window duration"); detail: qsTr("Open, close and window movement timing"); keyName: "windowMs"; suffix: " ms"; minimum: 80; maximum: 1200; step: 10 }
                        NumberMotionRow { label: qsTr("Workspace duration"); detail: qsTr("Workspace slide-fade timing"); keyName: "workspaceMs"; suffix: " ms"; minimum: 80; maximum: 1600; step: 10 }
                        NumberMotionRow { label: qsTr("Layer duration"); detail: qsTr("Panels and compositor layer timing"); keyName: "layerMs"; suffix: " ms"; minimum: 80; maximum: 1200; step: 10 }
                        NumberMotionRow { label: qsTr("Fade duration"); detail: qsTr("Opacity transition timing"); keyName: "fadeMs"; suffix: " ms"; minimum: 60; maximum: 1000; step: 10 }
                        NumberMotionRow { label: qsTr("Workspace travel"); detail: qsTr("How far workspace transitions move across the screen"); keyName: "workspaceDistance"; suffix: "%"; minimum: 4; maximum: 40; step: 1 }

                        Item {
                            width: motionRows.width
                            height: 66

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 14

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: qsTr("Raohane shell motion"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                                    Text { text: qsTr("Scale QML surface transitions independently from Hyprland"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                                }

                                RaohaneSurface {
                                    Layout.preferredWidth: 138
                                    Layout.preferredHeight: 34
                                    surfaceRadius: 11
                                    raised: false
                                    showSheen: false

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 3
                                        anchors.rightMargin: 3
                                        spacing: 2
                                        RaohaneIconButton { buttonSize: 27; iconSize: 13; icon: "remove"; transparentIdle: true; showSheen: false; onClicked: root.setShellMotionScale(root.shellMotionScale() - 0.05) }
                                        Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: Math.round(root.shellMotionScale() * 100) + "%"; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                                        RaohaneIconButton { buttonSize: 27; iconSize: 13; icon: "add"; transparentIdle: true; showSheen: false; onClicked: root.setShellMotionScale(root.shellMotionScale() + 0.05) }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: qsTr("The Zen curve is intentionally non-bouncy: quick acceleration, soft landing and restrained movement. Hyprland settings are written to Raohane's managed compositor snippet and applied with a compositor reload.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    lineHeight: 1.25
                    wrapMode: Text.WordWrap
                }
            }
        }
    }

    component ShortcutRecorder: FocusScope {
        id: recorder
        required property string configKey
        property bool recording: false

        implicitWidth: 180
        implicitHeight: 36
        activeFocusOnTab: true

        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 11
            raised: false
            active: recorder.recording
            hovered: recorderMouse.containsMouse || recorder.activeFocus
            pressed: recorderMouse.pressed
            interactive: true
            showSheen: false

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 8
                spacing: 7

                RaohaneIcon {
                    text: recorder.recording ? "keyboard_alt" : "keyboard"
                    iconSize: 15
                    color: recorder.recording ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
                Text {
                    Layout.fillWidth: true
                    text: recorder.recording ? qsTr("Press shortcut…") : (root.keybindValue(recorder.configKey) || qsTr("Disabled"))
                    color: recorder.recording ? RaohaneTheme.accent : RaohaneTheme.text
                    font.pixelSize: 8
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

        height: 92
        surfaceRadius: 18
        raised: false
        showSheen: false

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            RaohaneSurface {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                surfaceRadius: 13
                raised: false
                showSheen: false
                RaohaneIcon { anchors.centerIn: parent; text: "apps"; iconSize: 19; color: RaohaneTheme.accent }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

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

            ShortcutRecorder {
                configKey: appRow.keysKey
            }
        }
    }

    component FieldEditor: RaohaneSurface {
        id: editor
        required property string configKey
        property string placeholderText: ""
        property bool monospace: false

        Layout.fillWidth: true
        Layout.preferredHeight: 31
        surfaceRadius: 9
        raised: false
        showSheen: false
        hovered: editorField.activeFocus

        TextInput {
            id: editorField
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            verticalAlignment: TextInput.AlignVCenter
            text: root.keybindValue(editor.configKey)
            color: RaohaneTheme.text
            selectionColor: RaohaneTheme.accentSoft
            selectedTextColor: RaohaneTheme.text
            font.pixelSize: 8
            font.family: editor.monospace ? "JetBrainsMono Nerd Font" : ""
            clip: true
            onEditingFinished: root.setKeybind(editor.configKey, text)

            Text {
                anchors.fill: parent
                verticalAlignment: Text.AlignVCenter
                text: editor.placeholderText
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
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
        height: 66

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 14
            spacing: 14
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: toggleRow.label; color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                Text { text: toggleRow.detail; color: RaohaneTheme.textMuted; font.pixelSize: 8 }
            }
            RaohaneSwitch { checked: toggleRow.checked; onToggled: toggleRow.toggled(checked) }
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
        height: 66

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 16
            anchors.rightMargin: 12
            spacing: 14
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text { text: numberRow.label; color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                Text { text: numberRow.detail; color: RaohaneTheme.textMuted; font.pixelSize: 8 }
            }
            RaohaneSurface {
                Layout.preferredWidth: 138
                Layout.preferredHeight: 34
                surfaceRadius: 11
                raised: false
                showSheen: false
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 3
                    anchors.rightMargin: 3
                    spacing: 2
                    RaohaneIconButton { buttonSize: 27; iconSize: 13; icon: "remove"; transparentIdle: true; showSheen: false; onClicked: root.changeAnimation(numberRow.keyName, -numberRow.step, numberRow.minimum, numberRow.maximum) }
                    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: String(root.animationValue(numberRow.keyName)) + numberRow.suffix; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                    RaohaneIconButton { buttonSize: 27; iconSize: 13; icon: "add"; transparentIdle: true; showSheen: false; onClicked: root.changeAnimation(numberRow.keyName, numberRow.step, numberRow.minimum, numberRow.maximum) }
                }
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
        Layout.preferredHeight: 78
        surfaceRadius: 17
        raised: false
        hovered: presetMouse.containsMouse
        pressed: presetMouse.pressed
        interactive: true
        showSheen: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 3
            RaohaneIcon { text: preset.icon; iconSize: 18; color: RaohaneTheme.accent }
            Text { text: preset.title; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
            Text { Layout.fillWidth: true; text: preset.detail; color: RaohaneTheme.textMuted; font.pixelSize: 7; elide: Text.ElideRight }
        }

        MouseArea {
            id: presetMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: preset.clicked()
        }
    }

    component SmallAction: FocusScope {
        id: smallAction
        required property string icon
        required property string label
        signal clicked()

        implicitWidth: 126
        implicitHeight: 34
        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 11
            raised: false
            hovered: smallMouse.containsMouse || smallAction.activeFocus
            pressed: smallMouse.pressed
            interactive: true
            showSheen: false
            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                RaohaneIcon { text: smallAction.icon; iconSize: 14; color: RaohaneTheme.textMuted }
                Text { text: smallAction.label; color: RaohaneTheme.text; font.pixelSize: 8; font.weight: Font.DemiBold }
            }
        }
        MouseArea { id: smallMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: smallAction.clicked() }
    }

    component TabButton: FocusScope {
        id: tab
        required property string icon
        required property string label
        required property bool active
        signal clicked()

        implicitWidth: 112
        implicitHeight: 34
        RaohaneSurface {
            anchors.fill: parent
            surfaceRadius: 11
            raised: false
            active: tab.active
            transparentIdle: !tab.active
            hovered: tabMouse.containsMouse || tab.activeFocus
            pressed: tabMouse.pressed
            interactive: true
            showSheen: false
            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                RaohaneIcon { text: tab.icon; iconSize: 14; fill: tab.active ? 1 : 0; color: tab.active ? RaohaneTheme.accent : RaohaneTheme.textMuted }
                Text { text: tab.label; color: tab.active ? RaohaneTheme.text : RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: Font.DemiBold }
            }
        }
        MouseArea { id: tabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: tab.clicked() }
    }
}
