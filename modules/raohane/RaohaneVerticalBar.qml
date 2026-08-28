pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

// Minimal native vertical presentation. It keeps vertical configurations
// bootable without loading modules/ii/verticalBar; richer parity can evolve
// independently of the compatibility framework.
Scope {
    id: root

    property date now: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: root.now = new Date()
    }

    Variants {
        model: {
            const screens = Quickshell.screens
            const configured = RaohaneConfig.barScreenList
            if (!configured || configured.length === 0)
                return screens
            return screens.filter(screen => configured.includes(screen.name))
        }

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData

            screen: modelData
            visible: RaohaneState.barOpen && !RaohaneState.screenLocked
            implicitWidth: 62
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: RaohaneConfig.barAutoHide && !barMouse.containsMouse ? 0 : implicitWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            WlrLayershell.namespace: "quickshell:raohane-vertical-bar"
            WlrLayershell.layer: WlrLayer.Top

            MouseArea {
                id: barMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            Rectangle {
                anchors {
                    fill: parent
                    margins: 7
                }
                radius: 24
                color: RaohaneTheme.glass
                border.width: 1
                border.color: RaohaneTheme.border

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 7
                    spacing: 8

                    BarButton {
                        glyph: "羅"
                        emphasized: true
                        onTriggered: RaohaneState.launcherOpen = !RaohaneState.launcherOpen
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.border
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Repeater {
                            model: Math.max(2, Math.min(10, RaohaneConfig.overviewWorkspaceCount))

                            delegate: Rectangle {
                                id: workspaceButton
                                required property int index

                                readonly property int workspaceId: index + 1
                                readonly property var monitor: Hyprland.monitorFor(barWindow.screen)
                                readonly property bool active: (monitor?.activeWorkspace?.id ?? 1) === workspaceId
                                readonly property var workspace: Hyprland.workspaces.values.find(candidate => candidate.id === workspaceId) ?? null
                                readonly property bool occupied: (workspace?.toplevels?.values?.length ?? 0) > 0

                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredWidth: 36
                                Layout.preferredHeight: 32
                                radius: 12
                                color: active ? RaohaneTheme.accentSoft
                                    : workspaceMouse.containsMouse ? "#24ffffff" : "transparent"
                                border.width: active ? 1 : 0
                                border.color: RaohaneTheme.border

                                Text {
                                    anchors.centerIn: parent
                                    text: workspaceButton.workspaceId
                                    color: workspaceButton.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                    font.pixelSize: 10
                                    font.weight: workspaceButton.active ? Font.Bold : Font.Medium
                                }

                                Rectangle {
                                    visible: workspaceButton.occupied
                                    width: 3
                                    height: 8
                                    radius: 2
                                    anchors {
                                        right: parent.right
                                        rightMargin: 4
                                        verticalCenter: parent.verticalCenter
                                    }
                                    color: workspaceButton.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                }

                                MouseArea {
                                    id: workspaceMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (workspaceButton.workspace)
                                            workspaceButton.workspace.activate()
                                        else if (Hyprland.usingLua)
                                            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspaceButton.workspaceId}" })`)
                                        else
                                            Hyprland.dispatch("workspace " + workspaceButton.workspaceId)
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatTime(root.now, "HH\nmm")
                        horizontalAlignment: Text.AlignHCenter
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        lineHeight: 0.9
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.border
                    }

                    BarButton {
                        glyph: RaohaneAudio.muted ? "×" : "♪"
                        onTriggered: RaohaneAudio.toggleMute()
                    }

                    BarButton {
                        glyph: "◎"
                        onTriggered: RaohaneState.controlCenterOpen = !RaohaneState.controlCenterOpen
                    }

                    BarButton {
                        glyph: "⏻"
                        onTriggered: RaohaneState.sessionOpen = true
                    }
                }
            }
        }
    }

    component BarButton: Rectangle {
        id: button
        required property string glyph
        property bool emphasized: false
        signal triggered()

        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        radius: 13
        color: emphasized ? RaohaneTheme.accentSoft
            : buttonMouse.containsMouse ? "#24ffffff" : "transparent"
        border.width: emphasized ? 1 : 0
        border.color: RaohaneTheme.border

        Text {
            anchors.centerIn: parent
            text: button.glyph
            color: emphasized ? RaohaneTheme.accent : RaohaneTheme.text
            font.pixelSize: 15
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }
}
