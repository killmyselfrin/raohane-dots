import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

// Raohane-owned full-screen command overlay. This intentionally keeps the
// first native version compact: it owns the runtime/IPC boundary without
// pulling the inherited WidgetCanvas/common widget graph into shell startup.
Scope {
    id: root

    property date now: new Date()
    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function open(): void {
        RaohaneState.overlayOpen = true
    }

    function close(): void {
        RaohaneState.overlayOpen = false
    }

    function toggle(): void {
        RaohaneState.overlayOpen = !RaohaneState.overlayOpen
    }

    function openSurface(name: string): void {
        root.close()
        switch (name) {
        case "launcher":
            RaohaneState.launcherOpen = true
            break
        case "control":
            RaohaneState.controlCenterOpen = true
            break
        case "media":
            RaohaneState.mediaOverlayOpen = true
            break
        case "settings":
            RaohaneState.settingsOpen = true
            break
        case "osk":
            RaohaneState.oskOpen = true
            break
        case "session":
            RaohaneState.sessionOpen = true
            break
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    PanelWindow {
        id: overlayWindow

        visible: RaohaneState.overlayOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell:raohane-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

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
                color: "#9908070d"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }

            Rectangle {
                id: commandDeck
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 860)
                height: Math.min(parent.height - 80, 430)
                radius: 30
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border

                MouseArea {
                    anchors.fill: parent
                    // Consume clicks so the scrim behind the deck does not close it.
                    onClicked: mouse => mouse.accepted = true
                }

                Rectangle {
                    width: 4
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                    }
                    radius: 2
                    color: RaohaneTheme.accent
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                text: "RAOHANE / OVERLAY"
                                color: RaohaneTheme.accent
                                font.pixelSize: 11
                                font.bold: true
                                font.letterSpacing: 1.5
                            }

                            Text {
                                text: qsTr("Command deck")
                                color: RaohaneTheme.text
                                font.pixelSize: 24
                                font.weight: Font.DemiBold
                            }
                        }

                        ColumnLayout {
                            spacing: 0

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatTime(root.now, "HH:mm")
                                color: RaohaneTheme.text
                                font.pixelSize: 28
                                font.weight: Font.Bold
                            }

                            Text {
                                Layout.alignment: Qt.AlignRight
                                text: Qt.formatDate(root.now, "ddd, d MMM")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 11
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.border
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 10
                        rowSpacing: 10

                        QuickAction {
                            glyph: "⌕"
                            title: qsTr("Launcher")
                            subtitle: qsTr("Apps and commands")
                            onTriggered: root.openSurface("launcher")
                        }
                        QuickAction {
                            glyph: "◎"
                            title: qsTr("Control Center")
                            subtitle: qsTr("Network, audio, display")
                            onTriggered: root.openSurface("control")
                        }
                        QuickAction {
                            glyph: "♪"
                            title: qsTr("Media")
                            subtitle: RaohaneMedia.available
                                ? (RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Active player"))
                                : qsTr("No active player")
                            onTriggered: root.openSurface("media")
                        }
                        QuickAction {
                            glyph: "⚙"
                            title: qsTr("Settings")
                            subtitle: qsTr("Configure Raohane")
                            onTriggered: root.openSurface("settings")
                        }
                        QuickAction {
                            glyph: "⌨"
                            title: qsTr("Keyboard")
                            subtitle: qsTr("On-screen keyboard")
                            onTriggered: root.openSurface("osk")
                        }
                        QuickAction {
                            glyph: "⏻"
                            title: qsTr("Session")
                            subtitle: qsTr("Lock, logout, power")
                            onTriggered: root.openSurface("session")
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: RaohaneAudio.ready
                                ? (RaohaneAudio.muted ? qsTr("Audio muted") : qsTr("Volume %1%").arg(Math.round(RaohaneAudio.volume * 100)))
                                : qsTr("Audio unavailable")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 11
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("Esc to close")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 10
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

    component QuickAction: Rectangle {
        id: action

        required property string glyph
        required property string title
        required property string subtitle
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 88
        radius: 18
        color: actionMouse.containsMouse ? "#24ffffff" : "#12ffffff"
        border.width: 1
        border.color: actionMouse.containsMouse ? RaohaneTheme.accentSoft : RaohaneTheme.border

        RowLayout {
            anchors.fill: parent
            anchors.margins: 14
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 42
                Layout.preferredHeight: 42
                radius: 14
                color: RaohaneTheme.accentSoft

                Text {
                    anchors.centerIn: parent
                    text: action.glyph
                    color: RaohaneTheme.accent
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: action.title
                    color: RaohaneTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: action.subtitle
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                }
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }
}
