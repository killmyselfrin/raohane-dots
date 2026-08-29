import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    readonly property var player: RaohaneMedia.activePlayer
    readonly property real progress: RaohaneMedia.progress
    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function toggle(): void { RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen }
    function open(): void { RaohaneState.mediaOverlayOpen = true }
    function close(): void { RaohaneState.mediaOverlayOpen = false }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.mediaOverlayOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: 404
        implicitHeight: 116
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-media-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }
        margins {
            top: 16
            right: 16
        }

        Rectangle {
            anchors.fill: parent
            radius: RaohaneTheme.radiusLarge
            color: RaohaneTheme.surfaceRaised
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 11

                Rectangle {
                    Layout.preferredWidth: 88
                    Layout.preferredHeight: 88
                    radius: 14
                    color: "#16ffffff"
                    clip: true

                    Image {
                        id: coverArt
                        anchors.fill: parent
                        source: RaohaneMedia.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                        visible: status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !RaohaneMedia.available || coverArt.status !== Image.Ready
                        text: "音"
                        color: RaohaneTheme.accent
                        font.pixelSize: 25
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 3

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -1

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title
                                    : qsTr("No active player")
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist
                                    : qsTr("Start music to use media controls")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
                        }

                        ControlButton {
                            glyph: "×"
                            onClicked: root.close()
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 3
                        radius: 2
                        color: "#24ffffff"

                        Rectangle {
                            width: parent.width * root.progress
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: RaohaneMedia.canSeek
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: mouse => RaohaneMedia.seekRatio(mouse.x / width)
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 5

                        Text {
                            text: "音 / RAOHANE"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            font.letterSpacing: 0.6
                        }

                        Item { Layout.fillWidth: true }

                        ControlButton {
                            glyph: "⏮"
                            enabled: RaohaneMedia.canGoPrevious
                            onClicked: RaohaneMedia.previous()
                        }
                        ControlButton {
                            glyph: RaohaneMedia.isPlaying ? "Ⅱ" : "▶"
                            enabled: RaohaneMedia.canTogglePlaying
                            emphasized: true
                            onClicked: RaohaneMedia.togglePlaying()
                        }
                        ControlButton {
                            glyph: "⏭"
                            enabled: RaohaneMedia.canGoNext
                            onClicked: RaohaneMedia.next()
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "raohaneMedia"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "raohaneMediaOverlayToggle"
        description: "Toggle the Raohane media overlay"
        onPressed: root.toggle()
    }

    component ControlButton: Rectangle {
        id: control

        required property string glyph
        property bool emphasized: false
        signal clicked()

        implicitWidth: 28
        implicitHeight: 28
        radius: 10
        opacity: control.enabled ? 1 : 0.32
        color: control.emphasized
            ? RaohaneTheme.accentSoft
            : mouse.containsMouse && control.enabled ? RaohaneTheme.surfaceHover : "transparent"
        border.width: control.emphasized ? 1 : 0
        border.color: control.emphasized ? "#35b88cff" : "transparent"

        Text {
            anchors.centerIn: parent
            text: control.glyph
            color: control.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
            font.pixelSize: control.emphasized ? 13 : 14
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: control.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: control.clicked()
        }
    }
}
