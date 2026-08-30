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
        implicitWidth: 454
        implicitHeight: 140
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
            anchors.centerIn: mediaSurface
            width: mediaSurface.width + 12
            height: mediaSurface.height + 12
            radius: RaohaneTheme.radiusLarge + 5
            color: "transparent"
            border.width: 4
            border.color: "#20c56cff"
        }

        RaohaneSurface {
            id: mediaSurface
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            border.color: RaohaneTheme.accentBorder
            clip: true

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 28
                    rightMargin: 28
                }
                height: 1
                color: RaohaneTheme.accentSecondary
                opacity: 0.38
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 13

                Rectangle {
                    Layout.preferredWidth: 106
                    Layout.preferredHeight: 106
                    radius: 18
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.borderStrong
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

                    Rectangle {
                        anchors.fill: parent
                        visible: coverArt.status === Image.Ready
                        color: "transparent"
                        border.width: 1
                        border.color: "#2bffffff"
                        radius: parent.radius
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !RaohaneMedia.available || coverArt.status !== Image.Ready
                        text: "音"
                        color: RaohaneTheme.accent
                        font.pixelSize: 27
                        font.weight: Font.Bold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

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
                                    : qsTr("Start music to use media controls")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
                        }

                        Rectangle {
                            implicitWidth: contextLabel.implicitWidth + 14
                            implicitHeight: 24
                            radius: 9
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                id: contextLabel
                                anchors.centerIn: parent
                                text: "CONTEXT"
                                color: RaohaneTheme.accent
                                font.pixelSize: 7
                                font.weight: Font.DemiBold
                                font.letterSpacing: 0.8
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
                        Layout.preferredHeight: 5
                        radius: 3
                        color: "#24ffffff"

                        Rectangle {
                            width: parent.width * root.progress
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                        }

                        Rectangle {
                            visible: root.progress > 0.01
                            x: Math.max(0, parent.width * root.progress - 4)
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            radius: 4
                            color: RaohaneTheme.accentSecondary
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
                        spacing: 6

                        Text {
                            text: "音 / RAOHANE"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            font.letterSpacing: 0.8
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

        implicitWidth: 30
        implicitHeight: 30
        radius: 11
        opacity: control.enabled ? 1 : 0.32
        color: control.emphasized
            ? RaohaneTheme.accentSoft
            : mouse.containsMouse && control.enabled ? RaohaneTheme.surfaceHover : "transparent"
        border.width: control.emphasized || mouse.containsMouse ? 1 : 0
        border.color: control.emphasized ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong
        scale: mouse.containsMouse && control.enabled ? 1.05 : 1

        Behavior on scale {
            NumberAnimation { duration: RaohaneTheme.animationFast; easing.type: Easing.OutCubic }
        }

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
