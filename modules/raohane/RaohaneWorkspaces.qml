pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.modules.raohane.config

Item {
    id: root

    property var screen: null
    property string orientation: "horizontal"
    property bool compactMode: false

    readonly property bool vertical: orientation === "vertical"
    readonly property var monitor: root.screen ? Hyprland.monitorFor(root.screen) : Hyprland.focusedMonitor
    readonly property int activeWorkspaceId: Math.max(1, root.monitor?.activeWorkspace?.id ?? 1)
    readonly property int workspaceCount: Math.max(2, Math.min(10, RaohaneConfig.overviewWorkspaceCount))
    readonly property int groupStart: Math.floor((root.activeWorkspaceId - 1) / root.workspaceCount) * root.workspaceCount + 1
    // Narrow Bar layouts show the active workspace and its neighbors
    // rather than painting six desktops into a 90px clipped slot. The full
    // count and model remain available on normal screens and vertical bars.
    readonly property var workspaceIds: {
        const group = Array.from({ length: root.workspaceCount }, (_, index) => root.groupStart + index)
        if (!root.compactMode || root.vertical)
            return group
        const currentIndex = group.indexOf(root.activeWorkspaceId)
        const start = Math.max(0, Math.min(group.length - 3, currentIndex - 1))
        return group.slice(start, start + 3)
    }

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
            spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

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
            spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

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
        readonly property bool haloStyle: !verticalMode && RaohaneConfig.barStylePreset === "halo"
        readonly property var windows: workspaceObject?.toplevels?.values ?? []
        readonly property bool occupied: windows.length > 0
        readonly property bool urgent: workspaceObject?.urgent ?? false
        // Reuse the compositor's existing model instead of polling hyprctl.
        // HyprlandToplevel exposes appId through its Wayland toplevel handle.
        readonly property var representativeWindow: windows.find(window => Boolean(window?.activated))
            ?? windows.find(window => String(window?.wayland?.appId ?? "").length > 0)
            ?? null
        readonly property string appId: String(representativeWindow?.wayland?.appId ?? "").trim()
        readonly property string workspaceName: String(workspaceObject?.name ?? "").trim()
        readonly property string displayName: workspaceName.length > 0
            && workspaceName !== String(workspaceId)
            ? workspaceName : qsTr("Workspace %1").arg(workspaceId)
        readonly property string appSummary: {
            const ids = []
            for (const window of windows) {
                const id = String(window?.wayland?.appId ?? "").trim()
                if (id.length > 0 && !ids.includes(id))
                    ids.push(id)
                if (ids.length >= 3)
                    break
            }
            return ids.join(", ")
        }

        implicitWidth: verticalMode ? 30 : 26
        implicitHeight: verticalMode ? 26 : 26
        Layout.alignment: Qt.AlignCenter
        Layout.preferredWidth: implicitWidth
        Layout.preferredHeight: implicitHeight
        surfaceRadius: haloStyle ? 13 : RaohaneTheme.radiusSmall
        raised: false
        active: selected
        // In Halo, desktops are round status dots, with a soft highlight
        // on the actual Hyprland active workspace (no synthetic state).
        idleColor: haloStyle
            ? Qt.rgba(RaohaneTheme.textMuted.r, RaohaneTheme.textMuted.g,
                RaohaneTheme.textMuted.b, 0.12)
            : "transparent"
        activeColor: haloStyle
            ? Qt.rgba(RaohaneTheme.accent.r, RaohaneTheme.accent.g,
                RaohaneTheme.accent.b, 0.27)
            : RaohaneTheme.accentSoft
        hovered: workspaceMouse.containsMouse
        pressed: workspaceMouse.pressed
        interactive: true
        transparentIdle: !haloStyle && !selected && !urgent
        hoverScale: 1
        pressedScale: 1
        showSheen: false
        showInnerRim: selected
        idleBorderColor: urgent ? RaohaneTheme.critical : "transparent"
        hoverBorderColor: urgent ? RaohaneTheme.critical : RaohaneTheme.borderStrong
        pressedBorderColor: urgent ? RaohaneTheme.critical : RaohaneTheme.borderStrong
        activeBorderColor: urgent ? RaohaneTheme.critical : RaohaneTheme.accentBorder

        Rectangle {
            visible: !workspaceButton.haloStyle
                && (workspaceButton.selected || workspaceButton.urgent)
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

        Row {
            anchors.centerIn: parent
            anchors.verticalCenterOffset: !workspaceButton.verticalMode && workspaceButton.occupied ? -1 : 0
            spacing: 2

            // Preserve the workspace number even when showing an app icon.
            Text {
                text: workspaceButton.workspaceId
                color: workspaceButton.urgent ? RaohaneTheme.critical
                    : workspaceButton.selected && workspaceButton.haloStyle
                        ? RaohaneTheme.text
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

            Loader {
                active: workspaceButton.appId.length > 0
                width: active ? 12 : 0
                height: active ? 12 : 0
                sourceComponent: RaohaneAdaptiveIcon {
                    iconSource: workspaceButton.appId
                    iconSize: 12
                    fallbackColor: workspaceButton.selected
                        ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }
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
            Accessible.role: Accessible.Button
            Accessible.name: workspaceButton.displayName
            Accessible.description: workspaceButton.appSummary.length > 0
                ? qsTr("Applications: %1").arg(workspaceButton.appSummary)
                : qsTr("Empty workspace")
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
