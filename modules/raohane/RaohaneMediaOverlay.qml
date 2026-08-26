import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs
import qs.modules.common.widgets
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var player: RaohaneMedia.activePlayer
    readonly property real progress: RaohaneMedia.progress

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.mediaOverlayOpen
        screen: Quickshell.screens.find(candidate => candidate.name === WM.focusedMonitor?.name)
            ?? Quickshell.screens[0]
        exclusiveZone: 0
        implicitWidth: 430
        implicitHeight: 128
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-media-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }

        margins {
            top: 18
            right: 18
        }

        Rectangle {
            id: card
            anchors.fill: parent
            radius: 24
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            Rectangle {
                width: 3
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                color: RaohaneTheme.accent
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 96
                    Layout.preferredHeight: 96
                    radius: 18
                    color: RaohaneTheme.accentSoft
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
                        font.pixelSize: 30
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title
                                    : qsTr("No active player")
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist
                                    : qsTr("Start music to use the overlay")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                        }

                        ControlButton {
                            icon: "close"
                            onClicked: RaohaneState.mediaOverlayOpen = false
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Rectangle {
                        id: progressTrack
                        Layout.fillWidth: true
                        Layout.preferredHeight: 5
                        radius: height / 2
                        color: "#35ffffff"

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
                        spacing: 8

                        Text {
                            text: "RAOHANE / MEDIA"
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            font.letterSpacing: 0.9
                        }

                        Item { Layout.fillWidth: true }

                        ControlButton {
                            icon: "skip_previous"
                            enabled: RaohaneMedia.canGoPrevious
                            onClicked: RaohaneMedia.previous()
                        }

                        ControlButton {
                            icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                            enabled: RaohaneMedia.canTogglePlaying
                            emphasized: true
                            onClicked: RaohaneMedia.togglePlaying()
                        }

                        ControlButton {
                            icon: "skip_next"
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

        function toggle(): void {
            RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
        }

        function open(): void {
            RaohaneState.mediaOverlayOpen = true
        }

        function close(): void {
            RaohaneState.mediaOverlayOpen = false
        }
    }

    CompositorGlobalShortcut {
        name: "raohaneMediaOverlayToggle"
        description: "Toggles the Raohane media overlay"
        onPressed: RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
    }

    component ControlButton: Rectangle {
        id: control

        required property string icon
        property bool emphasized: false
        signal clicked()

        implicitWidth: 30
        implicitHeight: 30
        radius: 15
        opacity: control.enabled ? 1 : 0.35
        color: emphasized ? RaohaneTheme.accentSoft
            : mouse.containsMouse && control.enabled ? "#30ffffff" : "transparent"
        border.width: emphasized ? 1 : 0
        border.color: RaohaneTheme.border

        MaterialSymbol {
            anchors.centerIn: parent
            text: control.icon
            iconSize: 17
            color: control.emphasized ? RaohaneTheme.accent : RaohaneTheme.text
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
