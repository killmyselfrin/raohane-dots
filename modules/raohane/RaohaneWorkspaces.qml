pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.modules.raohane.config

Item {
    id: root

    property var screen: null

    readonly property var monitor: root.screen ? Hyprland.monitorFor(root.screen) : Hyprland.focusedMonitor
    readonly property int activeWorkspaceId: Math.max(1, root.monitor?.activeWorkspace?.id ?? 1)
    readonly property int workspaceCount: Math.max(2, Math.min(10, RaohaneConfig.overviewWorkspaceCount))
    readonly property int groupStart: Math.floor((root.activeWorkspaceId - 1) / root.workspaceCount) * root.workspaceCount + 1
    readonly property var workspaceIds: Array.from({ length: root.workspaceCount }, (_, index) => root.groupStart + index)

    implicitWidth: workspaceRow.implicitWidth
    implicitHeight: workspaceRow.implicitHeight

    function workspaceForId(workspaceId: int): var {
        return Hyprland.workspaces.values.find(workspace => workspace.id === workspaceId) ?? null
    }

    function activateWorkspace(workspaceId: int): void {
        const workspace = root.workspaceForId(workspaceId)
        if (workspace) {
            workspace.activate()
            return
        }

        if (Hyprland.usingLua)
            Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspaceId}" })`)
        else
            Hyprland.dispatch("workspace " + workspaceId)
    }

    function moveRelative(delta: int): void {
        const offset = Math.max(0, Math.min(root.workspaceCount - 1, root.activeWorkspaceId - root.groupStart))
        const nextOffset = Math.max(0, Math.min(root.workspaceCount - 1, offset + delta))
        root.activateWorkspace(root.groupStart + nextOffset)
    }

    RowLayout {
        id: workspaceRow
        spacing: 3

        Repeater {
            model: root.workspaceIds

            delegate: Rectangle {
                id: workspaceButton

                required property var modelData
                required property int index

                readonly property int workspaceId: Number(modelData)
                readonly property var workspaceObject: root.workspaceForId(workspaceId)
                readonly property bool active: root.activeWorkspaceId === workspaceId
                readonly property bool occupied: (workspaceObject?.toplevels?.values?.length ?? 0) > 0
                readonly property bool urgent: workspaceObject?.urgent ?? false

                Layout.preferredWidth: active ? 31 : 25
                Layout.preferredHeight: 28
                radius: 10
                color: active
                    ? RaohaneTheme.accentSoft
                    : workspaceMouse.containsMouse ? "#24ffffff" : "transparent"
                border.width: active || urgent ? 1 : 0
                border.color: urgent ? "#ff7373" : RaohaneTheme.border

                Behavior on Layout.preferredWidth {
                    NumberAnimation {
                        duration: RaohaneTheme.animationDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: workspaceButton.occupied ? -2 : 0
                    text: workspaceButton.workspaceId
                    color: workspaceButton.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: workspaceButton.active ? Font.DemiBold : Font.Medium
                }

                Rectangle {
                    visible: workspaceButton.occupied
                    width: workspaceButton.active ? 8 : 5
                    height: 2
                    radius: 1
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                        bottomMargin: 4
                    }
                    color: workspaceButton.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    opacity: workspaceButton.active ? 1 : 0.7
                }

                MouseArea {
                    id: workspaceMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.activateWorkspace(workspaceButton.workspaceId)
                    onWheel: wheel => {
                        if (wheel.angleDelta.y === 0)
                            return
                        root.moveRelative(wheel.angleDelta.y > 0 ? -1 : 1)
                        wheel.accepted = true
                    }
                }
            }
        }
    }
}
