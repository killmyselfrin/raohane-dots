import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.services

// Native compact left sidebar used while the old large sidebar is retired from
// the active runtime. It deliberately depends only on Raohane services/state.
Scope {
    id: root

    function open(): void { RaohaneState.leftSidebarOpen = true }
    function close(): void { RaohaneState.leftSidebarOpen = false }
    function toggle(): void { RaohaneState.leftSidebarOpen = !RaohaneState.leftSidebarOpen }

    PanelWindow {
        id: sidebarWindow

        visible: RaohaneState.leftSidebarOpen
        implicitWidth: 360
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            bottom: true
            left: true
        }

        margins {
            top: 14
            bottom: 14
            left: 14
        }

        WlrLayershell.namespace: "quickshell:raohane-sidebar-left"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            text: "RAOHANE / SIDE"
                            color: RaohaneTheme.accent
                            font.pixelSize: 10
                            font.bold: true
                            font.letterSpacing: 1.2
                        }
                        Text {
                            text: qsTr("Quick glance")
                            color: RaohaneTheme.text
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                    }

                    SmallButton {
                        glyph: "×"
                        onTriggered: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 106
                    radius: 20
                    color: "#14ffffff"
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 78
                            Layout.preferredHeight: 78
                            radius: 16
                            color: RaohaneTheme.accentSoft
                            clip: true

                            Image {
                                anchors.fill: parent
                                source: RaohaneMedia.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                text: "音"
                                color: RaohaneTheme.accent
                                font.pixelSize: 24
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 3

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title : qsTr("No active player")
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist : qsTr("Start music to see it here")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                SmallButton {
                                    glyph: "⏮"
                                    enabled: RaohaneMedia.canGoPrevious
                                    onTriggered: RaohaneMedia.previous()
                                }
                                SmallButton {
                                    glyph: RaohaneMedia.isPlaying ? "Ⅱ" : "▶"
                                    emphasized: true
                                    enabled: RaohaneMedia.canTogglePlaying
                                    onTriggered: RaohaneMedia.togglePlaying()
                                }
                                SmallButton {
                                    glyph: "⏭"
                                    enabled: RaohaneMedia.canGoNext
                                    onTriggered: RaohaneMedia.next()
                                }
                                Item { Layout.fillWidth: true }
                                SmallButton {
                                    glyph: "↗"
                                    onTriggered: {
                                        root.close()
                                        RaohaneState.mediaOverlayOpen = true
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    text: qsTr("AUDIO")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.bold: true
                    font.letterSpacing: 1.2
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78
                    radius: 18
                    color: "#10ffffff"
                    border.width: 1
                    border.color: RaohaneTheme.border

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: RaohaneAudio.muted ? qsTr("Muted") : qsTr("Volume")
                                color: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: RaohaneAudio.ready ? Math.round(RaohaneAudio.volume * 100) + "%" : "—"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            id: volumeTrack
                            Layout.fillWidth: true
                            Layout.preferredHeight: 7
                            radius: height / 2
                            color: "#2affffff"

                            Rectangle {
                                width: parent.width * (RaohaneAudio.muted ? 0 : RaohaneAudio.volume)
                                height: parent.height
                                radius: parent.radius
                                color: RaohaneTheme.accent
                            }

                            MouseArea {
                                anchors.fill: parent
                                enabled: RaohaneAudio.ready
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: mouse => RaohaneAudio.setVolume(mouse.x / width)
                                onPositionChanged: mouse => {
                                    if (pressed)
                                        RaohaneAudio.setVolume(mouse.x / width)
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ActionButton {
                        glyph: "⌕"
                        title: qsTr("Launcher")
                        onTriggered: {
                            root.close()
                            RaohaneState.launcherOpen = true
                        }
                    }
                    ActionButton {
                        glyph: "◎"
                        title: qsTr("Control")
                        onTriggered: {
                            root.close()
                            RaohaneState.controlCenterOpen = true
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ActionButton {
                        glyph: "⚙"
                        title: qsTr("Settings")
                        onTriggered: {
                            root.close()
                            RaohaneState.settingsOpen = true
                        }
                    }
                    ActionButton {
                        glyph: "⏻"
                        title: qsTr("Session")
                        onTriggered: {
                            root.close()
                            RaohaneState.sessionOpen = true
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("This native sidebar replaces the inherited startup dependency graph. More widgets will move here during the next migration passes.")
                    wrapMode: Text.WordWrap
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                }
            }
        }
    }

    IpcHandler {
        target: "sidebarLeft"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggle the Raohane left sidebar"
        onPressed: root.toggle()
    }

    component SmallButton: Rectangle {
        id: button
        required property string glyph
        property bool emphasized: false
        signal triggered()

        implicitWidth: 30
        implicitHeight: 30
        radius: 15
        opacity: button.enabled ? 1 : 0.35
        color: emphasized ? RaohaneTheme.accentSoft
            : buttonMouse.containsMouse && button.enabled ? "#24ffffff" : "transparent"
        border.width: emphasized ? 1 : 0
        border.color: RaohaneTheme.border

        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: emphasized ? RaohaneTheme.accent : RaohaneTheme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            enabled: button.enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }

    component ActionButton: Rectangle {
        id: action
        required property string glyph
        required property string title
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: 16
        color: actionMouse.containsMouse ? "#24ffffff" : "#10ffffff"
        border.width: 1
        border.color: actionMouse.containsMouse ? RaohaneTheme.accentSoft : RaohaneTheme.border

        RowLayout {
            anchors.centerIn: parent
            spacing: 8
            Text {
                text: action.glyph
                color: RaohaneTheme.accent
                font.pixelSize: 16
            }
            Text {
                text: action.title
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
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
