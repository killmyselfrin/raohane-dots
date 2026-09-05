pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.modules.raohane.config

Item {
    id: root

    property var screen: null
    property string orientation: "horizontal"

    readonly property bool vertical: orientation === "vertical"
    readonly property var monitor: root.screen ? Hyprland.monitorFor(root.screen) : Hyprland.focusedMonitor
    readonly property int activeWorkspaceId: Math.max(1, root.monitor?.activeWorkspace?.id ?? 1)
    readonly property int workspaceCount: Math.max(2, Math.min(10, RaohaneConfig.overviewWorkspaceCount))
    readonly property int groupStart: Math.floor((root.activeWorkspaceId - 1) / root.workspaceCount) * root.workspaceCount + 1
    readonly property var workspaceIds: Array.from({ length: root.workspaceCount }, (_, index) => root.groupStart + index)

    implicitWidth: workspaceLoader.item?.implicitWidth ?? workspaceLoader.item?.width ?? 0
    implicitHeight: workspaceLoader.item?.implicitHeight ?? workspaceLoader.item?.height ?? 0

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

    Loader {
        id: workspaceLoader
        anchors.centerIn: parent
        sourceComponent: root.vertical ? verticalWorkspaces : horizontalWorkspaces
    }

    Component {
        id: horizontalWorkspaces

        RowLayout {
            spacing: 2

            Repeater {
                model: root.workspaceIds
                delegate: WorkspaceButton {
                    required property var modelData
                    workspaceId: Number(modelData)
                    verticalMode: false
                }
            }
        }
    }

    Component {
        id: verticalWorkspaces

        ColumnLayout {
            spacing: 2

            Repeater {
                model: root.workspaceIds
                delegate: WorkspaceButton {
                    required property var modelData
                    workspaceId: Number(modelData)
                    verticalMode: true
                }
            }
        }
    }

    component WorkspaceButton: RaohaneSurface {
        id: workspaceButton

        required property int workspaceId
        property bool verticalMode: false

        readonly property var workspaceObject: root.workspaceForId(workspaceId)
        readonly property bool selected: root.activeWorkspaceId === workspaceId
        readonly property bool occupied: (workspaceObject?.toplevels?.values?.length ?? 0) > 0
        readonly property bool urgent: workspaceObject?.urgent ?? false

        implicitWidth: verticalMode ? 30 : 26
        implicitHeight: verticalMode ? 26 : 26
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        surfaceRadius: 8
        raised: false
        active: selected
        hovered: workspaceMouse.containsMouse
        pressed: workspaceMouse.pressed
        interactive: true
        transparentIdle: !selected && !urgent
        hoverScale: 1
        pressedScale: 1
        showSheen: false
        border.color: urgent ? RaohaneTheme.critical
            : selected ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong
            : "transparent"

        Behavior on border.color {
            ColorAnimation { duration: RaohaneMotion.micro }
        }

        Rectangle {
            visible: workspaceButton.selected || workspaceButton.urgent
            width: workspaceButton.verticalMode ? 2 : (workspaceButton.selected ? 10 : 6)
            height: workspaceButton.verticalMode ? (workspaceButton.selected ? 12 : 8) : 2
            radius: 1
            color: workspaceButton.urgent ? RaohaneTheme.critical : RaohaneTheme.accent
            opacity: 1

            anchors {
                left: workspaceButton.verticalMode ? parent.left : undefined
                leftMargin: workspaceButton.verticalMode ? 2 : 0
                verticalCenter: workspaceButton.verticalMode ? parent.verticalCenter : undefined
                horizontalCenter: workspaceButton.verticalMode ? undefined : parent.horizontalCenter
                bottom: workspaceButton.verticalMode ? undefined : parent.bottom
                bottomMargin: workspaceButton.verticalMode ? 0 : 2
            }
        }

        Text {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: !workspaceButton.verticalMode && workspaceButton.occupied ? -1 : 0
            text: workspaceButton.workspaceId
            color: workspaceButton.urgent ? RaohaneTheme.critical
                : workspaceButton.selected ? RaohaneTheme.accent
                : workspaceButton.occupied ? RaohaneTheme.textMuted
                : RaohaneTheme.textFaint
            opacity: workspaceButton.selected || workspaceButton.urgent ? 1
                : workspaceButton.occupied ? 0.86 : 0.62
            font.pixelSize: workspaceButton.selected ? 9 : 8
            font.weight: workspaceButton.selected ? Font.DemiBold : Font.Medium

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
        }

        Rectangle {
            visible: workspaceButton.occupied && !workspaceButton.selected && !workspaceButton.urgent
            width: workspaceButton.verticalMode ? 3 : 4
            height: workspaceButton.verticalMode ? 3 : 2
            radius: 1
            color: RaohaneTheme.textFaint
            opacity: 0.68

            anchors {
                horizontalCenter: workspaceButton.verticalMode ? undefined : parent.horizontalCenter
                bottom: workspaceButton.verticalMode ? undefined : parent.bottom
                bottomMargin: workspaceButton.verticalMode ? 0 : 3
                right: workspaceButton.verticalMode ? parent.right : undefined
                rightMargin: workspaceButton.verticalMode ? 4 : 0
                verticalCenter: workspaceButton.verticalMode ? parent.verticalCenter : undefined
            }
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
