pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    property date now: new Date()

    function open(): void { RaohaneState.setPrimaryOpen("leftSidebar", true) }
    function close(): void { RaohaneState.setPrimaryOpen("leftSidebar", false) }
    function toggle(): void { RaohaneState.togglePrimary("leftSidebar") }

    function openPrimary(surfaceId: string): void {
        RaohaneState.setPrimaryOpen(surfaceId, true)
    }

    function openMedia(): void {
        root.close()
        Qt.callLater(() => RaohaneState.setSurfaceOpen("mediaOverlay", true))
    }

    Connections {
        target: RaohaneState
        function onLeftSidebarOpenChanged(): void {
            if (RaohaneState.leftSidebarOpen) {
                root.now = new Date()
                RaohaneAudio.refresh(true)
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: RaohaneState.leftSidebarOpen
        onTriggered: root.now = new Date()
    }

    PanelWindow {
        id: sidebarWindow

        visible: RaohaneState.leftSidebarOpen
        screen: root.focusedScreen
        implicitWidth: 126
        implicitHeight: 412
        color: "transparent"
        exclusiveZone: 0
        exclusionMode: ExclusionMode.Ignore

        anchors {
            top: true
            left: true
        }

        margins {
            left: 14
            top: Math.max(72, Math.round(((root.focusedScreen?.height ?? 800) - sidebarWindow.implicitHeight) / 2))
        }

        WlrLayershell.namespace: "quickshell:raohane-sidebar-left"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        RaohaneSurface {
            id: panel
            property bool entered: false

            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            showSheen: true
            border.color: RaohaneTheme.borderStrong
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: RaohaneMotion.standard
                    easing.type: RaohaneMotion.easeStandard
                }
            }

            Component.onCompleted: Qt.callLater(() => panel.entered = true)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 9
                spacing: 5

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    surfaceRadius: 12
                    active: true
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 7

                        RaohaneIcon {
                            text: "spa"
                            iconSize: 17
                            fill: 1
                            symbolWeight: 560
                            grade: 40
                            color: RaohaneTheme.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: -1

                            Text {
                                text: "Raohane"
                                color: RaohaneTheme.text
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: Qt.formatTime(root.now, "HH:mm")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 6
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    surfaceRadius: 10
                    raised: false
                    showSheen: false
                    color: RaohaneTheme.surfaceDeep
                    border.color: RaohaneTheme.borderFaint

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 6
                        anchors.rightMargin: 6
                        anchors.topMargin: 4
                        anchors.bottomMargin: 4
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 25
                            spacing: 4

                            RaohaneIconButton {
                                buttonSize: 24
                                iconSize: 13
                                icon: RaohaneAudio.muted || RaohaneAudio.volume <= 0.001
                                    ? "volume_off"
                                    : RaohaneAudio.volume < 0.5 ? "volume_down" : "volume_up"
                                emphasized: !RaohaneAudio.muted && RaohaneAudio.volume > 0.001
                                transparentIdle: RaohaneAudio.muted || RaohaneAudio.volume <= 0.001
                                showSheen: false
                                hoverScale: 1
                                pressedScale: 1
                                onClicked: RaohaneAudio.toggleMute()
                            }

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Volume")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 6
                                font.weight: Font.Medium
                            }

                            Text {
                                text: Math.round(RaohaneAudio.volume * 100) + "%"
                                color: RaohaneAudio.muted ? RaohaneTheme.textFaint : RaohaneTheme.accent
                                font.pixelSize: 6
                                font.weight: Font.DemiBold
                            }
                        }

                        RaohaneSlider {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 20
                            from: 0
                            to: 1
                            stepSize: 0.02
                            value: RaohaneAudio.volume
                            showHandle: false
                            trackHeight: 3
                            enabled: RaohaneAudio.ready
                            onMoved: nextValue => RaohaneAudio.setVolume(nextValue)
                        }
                    }
                }

                RailAction {
                    icon: "apps"
                    label: qsTr("Apps")
                    onTriggered: root.openPrimary("launcher")
                }

                RailAction {
                    icon: "space_dashboard"
                    label: qsTr("Overview")
                    onTriggered: root.openPrimary("overview")
                }

                RailAction {
                    icon: "music_note"
                    label: qsTr("Media")
                    selected: RaohaneMedia.isPlaying
                    onTriggered: root.openMedia()
                }

                RailAction {
                    icon: "wallpaper"
                    label: qsTr("Wallpaper")
                    onTriggered: root.openPrimary("wallpaper")
                }

                RailAction {
                    icon: "settings"
                    label: qsTr("Settings")
                    onTriggered: root.openPrimary("settings")
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RailAction {
                    icon: "power_settings_new"
                    label: qsTr("Session")
                    accent: true
                    onTriggered: root.openPrimary("session")
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

    component RailAction: RaohaneSurface {
        id: action

        required property string icon
        required property string label
        property bool accent: false
        property bool selected: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 38
        surfaceRadius: 10
        active: action.accent || action.selected
        transparentIdle: !action.accent && !action.selected && !action.hovered
        raised: false
        showSheen: false
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 7
            spacing: 7

            RaohaneIcon {
                text: action.icon
                iconSize: 15
                fill: action.accent || action.selected ? 1 : action.hovered ? 0.32 : 0
                symbolWeight: action.accent || action.selected ? 550 : 440
                color: action.accent || action.selected || action.hovered
                    ? RaohaneTheme.accent
                    : RaohaneTheme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: action.label
                color: action.accent || action.selected || action.hovered
                    ? RaohaneTheme.text
                    : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: action.accent || action.selected ? Font.DemiBold : Font.Medium
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
