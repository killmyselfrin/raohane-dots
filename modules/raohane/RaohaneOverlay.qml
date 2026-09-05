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
                color: RaohaneTheme.dark
                    ? Qt.rgba(0.005, 0.008, 0.018, 0.76)
                    : Qt.rgba(0.14, 0.13, 0.12, 0.26)
                opacity: commandDeck.entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
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
                width: Math.min(parent.width - 72, 860)
                height: Math.min(parent.height - 96, 472)
                raised: true
                showSheen: false
                surfaceRadius: 17
                border.color: RaohaneTheme.borderStrong
                opacity: entered ? 1 : 0
                clip: true

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
                }

                Rectangle {
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        leftMargin: 18
                        rightMargin: 18
                    }
                    height: 1
                    color: RaohaneTheme.accent
                    opacity: 0.40
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.AllButtons
                    onClicked: mouse => mouse.accepted = true
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.preferredHeight: 31
                            radius: 1.5
                            color: RaohaneTheme.accent
                        }

                        RaohaneIcon {
                            text: "dashboard_customize"
                            iconSize: 19
                            fill: 1
                            symbolWeight: 550
                            color: RaohaneTheme.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: qsTr("Command Deck")
                                color: RaohaneTheme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                font.letterSpacing: -0.2
                            }

                            Text {
                                text: RaohanePrivacy.recordingActive ? qsTr("Screen capture active")
                                    : RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive ? qsTr("Privacy device active")
                                    : qsTr("Fast access without leaving the current workspace")
                                color: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                                    ? RaohaneTheme.warning : RaohaneTheme.textFaint
                                font.pixelSize: 7
                            }
                        }

                        RaohaneSurface {
                            implicitWidth: clockRow.implicitWidth + 16
                            implicitHeight: 30
                            surfaceRadius: 8
                            transparentIdle: true
                            showSheen: false

                            Row {
                                id: clockRow
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    text: Qt.formatDate(root.now, "ddd, d MMM")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Rectangle {
                                    width: 1
                                    height: 13
                                    color: RaohaneTheme.borderFaint
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: Qt.formatTime(root.now, "HH:mm")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }

                        RaohaneIconButton {
                            buttonSize: 29
                            iconSize: 14
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: root.close()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: 4
                        columnSpacing: 7
                        rowSpacing: 7

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
                            accent: true
                            onTriggered: root.openSurface("session")
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 25
                        spacing: 7

                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: RaohaneAudio.ready ? RaohaneTheme.success : RaohaneTheme.textFaint
                        }

                        RaohaneIcon {
                            text: RaohaneAudio.muted ? "volume_off" : "volume_up"
                            iconSize: 12
                            color: RaohaneTheme.textMuted
                        }

                        Text {
                            text: RaohaneAudio.ready
                                ? (RaohaneAudio.muted ? qsTr("Muted") : qsTr("%1% volume").arg(Math.round(RaohaneAudio.volume * 100)))
                                : qsTr("Audio unavailable")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 7
                        }

                        Item { Layout.fillWidth: true }

                        RowLayout {
                            visible: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            spacing: 5

                            Rectangle {
                                width: 5
                                height: 5
                                radius: 2.5
                                color: RaohaneTheme.warning
                            }

                            Text {
                                text: qsTr("Privacy active")
                                color: RaohaneTheme.warning
                                font.pixelSize: 7
                                font.weight: Font.Medium
                            }
                        }

                        Text {
                            text: qsTr("Esc to close")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
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
        property bool accent: false
        signal triggered()

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: 86
        surfaceRadius: 10
        showSheen: false
        raised: false
        active: action.accent
        transparentIdle: !action.accent && !action.hovered
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        border.color: action.accent ? RaohaneTheme.accentBorder
            : action.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
        color: action.accent ? RaohaneTheme.surfaceRaised
            : action.hovered ? RaohaneTheme.surfaceSubtle : RaohaneTheme.surfaceDeep

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
            opacity: action.accent ? 1 : action.hovered ? 0.48 : 0.14

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                RaohaneIcon {
                    text: action.icon
                    iconSize: 17
                    fill: action.accent ? 1 : action.hovered || action.activeFocus ? 0.35 : 0
                    symbolWeight: action.accent ? 550 : action.hovered || action.activeFocus ? 500 : 420
                    color: action.accent || action.hovered || action.activeFocus
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                }

                Item { Layout.fillWidth: true }

                RaohaneIcon {
                    text: "arrow_forward"
                    iconSize: 11
                    color: action.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: action.title
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: action.subtitle
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
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
