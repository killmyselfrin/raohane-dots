import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

// Raohane-owned full-screen command deck. It stays lightweight while hidden
// and routes feature entry points through the same native surface coordinator.
Scope {
    id: root

    property date now: new Date()
    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function open(): void {
        root.now = new Date()
        RaohaneState.setPrimaryOpen("overlay", true)
    }

    function close(): void {
        RaohaneState.setPrimaryOpen("overlay", false)
    }

    function toggle(): void {
        RaohaneState.togglePrimary("overlay")
    }

    function openSurface(name: string): void {
        switch (name) {
        case "launcher": RaohaneState.setPrimaryOpen("launcher", true); break
        case "control": RaohaneState.setPrimaryOpen("controlCenter", true); break
        case "tasks": RaohaneState.setPrimaryOpen("taskManager", true); break
        case "settings": RaohaneState.setPrimaryOpen("settings", true); break
        case "translate": RaohaneState.setPrimaryOpen("screenTranslator", true); break
        case "session": RaohaneState.setPrimaryOpen("session", true); break
        case "media":
            root.close()
            RaohaneState.mediaOverlayOpen = true
            break
        case "osk":
            root.close()
            RaohaneState.oskOpen = true
            break
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: RaohaneState.overlayOpen
        onTriggered: root.now = new Date()
    }

    PanelWindow {
        id: overlayWindow

        visible: RaohaneState.overlayOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell:raohane-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

        onVisibleChanged: {
            if (visible) {
                commandDeck.entered = false
                Qt.callLater(() => commandDeck.entered = true)
            } else {
                commandDeck.entered = false
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: overlayWindow.visible

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.background
                opacity: commandDeck.entered ? 0.72 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            RaohaneSurface {
                id: commandDeck
                property bool entered: false

                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 900)
                height: Math.min(parent.height - 80, 500)
                raised: true
                showSheen: false
                surfaceRadius: RaohaneTheme.radiusLarge
                border.color: RaohaneTheme.borderStrong
                opacity: entered ? 1 : 0
                scale: entered ? 1 : 0.98

                transform: Translate {
                    y: commandDeck.entered ? 0 : 12
                    Behavior on y {
                        NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }
                Behavior on scale {
                    NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: mouse => mouse.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 22
                    spacing: 14

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        RaohaneSurface {
                            width: 42
                            height: 42
                            surfaceRadius: RaohaneTheme.radiusSmall
                            active: true
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "dashboard_customize"
                                iconSize: 20
                                fill: 1
                                symbolWeight: 540
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: qsTr("Command Deck")
                                color: RaohaneTheme.text
                                font.pixelSize: 19
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: RaohanePrivacy.recordingActive ? qsTr("Screen capture active")
                                    : RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive ? qsTr("Privacy device active")
                                    : qsTr("Fast access without leaving the current workspace")
                                color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                                    ? RaohaneTheme.warning : RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }

                        ColumnLayout {
                            spacing: -1
                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatTime(root.now, "HH:mm")
                                color: RaohaneTheme.text
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatDate(root.now, "ddd, d MMM")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                            }
                        }
                    }

                    RaohaneDivider { Layout.fillWidth: true }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 4
                        columnSpacing: 9
                        rowSpacing: 9

                        QuickAction {
                            icon: "search"
                            title: qsTr("Launcher")
                            subtitle: qsTr("Apps & commands")
                            onTriggered: root.openSurface("launcher")
                        }
                        QuickAction {
                            icon: "tune"
                            title: qsTr("Control Center")
                            subtitle: qsTr("Audio & devices")
                            onTriggered: root.openSurface("control")
                        }
                        QuickAction {
                            icon: "music_note"
                            title: qsTr("Media")
                            subtitle: RaohaneMedia.available
                                ? (RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Active player"))
                                : qsTr("No active player")
                            onTriggered: root.openSurface("media")
                        }
                        QuickAction {
                            icon: "browse_activity"
                            title: qsTr("Tasks")
                            subtitle: qsTr("CPU, RAM & processes")
                            onTriggered: root.openSurface("tasks")
                        }
                        QuickAction {
                            icon: "translate"
                            title: qsTr("Translate")
                            subtitle: qsTr("Capture & OCR")
                            onTriggered: root.openSurface("translate")
                        }
                        QuickAction {
                            icon: "keyboard"
                            title: qsTr("Keyboard")
                            subtitle: qsTr("On-screen input")
                            onTriggered: root.openSurface("osk")
                        }
                        QuickAction {
                            icon: "settings"
                            title: qsTr("Settings")
                            subtitle: qsTr("Configure Raohane")
                            onTriggered: root.openSurface("settings")
                        }
                        QuickAction {
                            icon: "power_settings_new"
                            title: qsTr("Session")
                            subtitle: qsTr("Lock, logout & power")
                            onTriggered: root.openSurface("session")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        RaohaneIcon {
                            text: RaohaneAudio.muted ? "volume_off" : "volume_up"
                            iconSize: 14
                            color: RaohaneTheme.textMuted
                        }
                        Text {
                            text: RaohaneAudio.ready
                                ? (RaohaneAudio.muted ? qsTr("Muted") : qsTr("%1% volume").arg(Math.round(RaohaneAudio.volume * 100)))
                                : qsTr("Audio unavailable")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            visible: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            spacing: 5
                            RaohaneIcon {
                                text: RaohanePrivacy.recordingActive ? "screen_record"
                                    : RaohanePrivacy.cameraActive ? "videocam" : "mic"
                                iconSize: 13
                                fill: 1
                                color: RaohaneTheme.warning
                            }
                            Text {
                                text: qsTr("Privacy active")
                                color: RaohaneTheme.warning
                                font.pixelSize: 8
                            }
                        }

                        Text {
                            text: qsTr("Esc to close")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "overlay"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "overlayToggle"
        description: "Toggle the Raohane command overlay"
        onPressed: root.toggle()
    }

    component QuickAction: RaohaneSurface {
        id: action

        required property string icon
        required property string title
        required property string subtitle
        signal triggered()

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 92
        surfaceRadius: RaohaneTheme.radius
        showSheen: false
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        hoverScale: 1.012
        pressedScale: RaohaneMotion.pressScale
        activeFocusOnTab: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7

            RaohaneSurface {
                width: 36
                height: 36
                surfaceRadius: 11
                active: action.hovered || action.activeFocus
                showSheen: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: action.icon
                    iconSize: 18
                    fill: action.pressed ? 0.75 : action.hovered || action.activeFocus ? 1 : 0
                    symbolWeight: action.pressed ? 560 : action.hovered || action.activeFocus ? 520 : 430
                    color: action.hovered || action.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: action.title
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: action.subtitle
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: action.forceActiveFocus()
            onClicked: action.triggered()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                action.triggered()
                event.accepted = true
            }
        }
    }
}
