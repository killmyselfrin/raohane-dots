pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property int selectedIndex: 0

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property int activeWorkspaceId: Math.max(1, Math.min(100, Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1))
    readonly property int workspaceCount: Math.max(2, RaohaneConfig.overviewWorkspaceCount)
    readonly property int columns: Math.max(1, Math.min(RaohaneConfig.overviewColumns, workspaceCount))
    readonly property int groupStart: Math.floor((activeWorkspaceId - 1) / workspaceCount) * workspaceCount + 1
    readonly property var workspaceIds: Array.from({ length: workspaceCount }, (_, index) => groupStart + index)

    function workspaceForId(workspaceId: int): var {
        return Hyprland.workspaces.values.find(workspace => workspace.id === workspaceId) ?? null
    }

    function syncSelection(): void {
        root.selectedIndex = Math.max(0, Math.min(root.workspaceCount - 1, root.activeWorkspaceId - root.groupStart))
    }

    function open(): void {
        root.syncSelection()
        RaohaneState.setPrimaryOpen("overview", true)
    }

    function close(): void {
        RaohaneState.setPrimaryOpen("overview", false)
    }

    function toggle(): void {
        RaohaneState.togglePrimary("overview")
    }

    function activateWorkspace(workspaceId: int): void {
        root.close()
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

    function activateWindow(toplevel): void {
        if (!toplevel?.wayland)
            return
        root.close()
        toplevel.wayland.activate()
    }

    function activateSelected(): void {
        const index = Math.max(0, Math.min(root.selectedIndex, root.workspaceIds.length - 1))
        root.activateWorkspace(root.workspaceIds[index])
    }

    function activatePosition(position: int): void {
        const index = position === 0 ? 9 : position - 1
        if (index < 0 || index >= root.workspaceIds.length)
            return
        root.selectedIndex = index
        root.activateWorkspace(root.workspaceIds[index])
    }

    function shortcutLabel(index: int): string {
        if (index >= 0 && index < 9)
            return String(index + 1)
        return index === 9 ? "0" : ""
    }

    function moveSelection(dx: int, dy: int): void {
        const row = Math.floor(root.selectedIndex / root.columns)
        const column = root.selectedIndex % root.columns
        const rows = Math.ceil(root.workspaceCount / root.columns)
        const nextRow = Math.max(0, Math.min(rows - 1, row + dy))
        const nextColumn = Math.max(0, Math.min(root.columns - 1, column + dx))
        root.selectedIndex = Math.min(root.workspaceCount - 1, nextRow * root.columns + nextColumn)
    }

    Connections {
        target: RaohaneState
        function onOverviewOpenChanged(): void {
            if (RaohaneState.overviewOpen)
                root.syncSelection()
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.overviewOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-overview"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: RaohaneState.overviewOpen
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                overviewPanel.entered = false
                Qt.callLater(() => {
                    overviewPanel.entered = true
                    overviewPanel.forceActiveFocus()
                })
            } else {
                overviewPanel.entered = false
            }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark ? "#72000000" : "#345b5750"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        RaohaneSurface {
            id: overviewPanel
            property bool entered: false

            width: Math.min(parent.width - 96, 1040)
            height: Math.min(parent.height - 112, 680)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
                    root.activatePosition(event.key - Qt.Key_0)
                    event.accepted = true
                } else if (event.key === Qt.Key_0) {
                    root.activatePosition(0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                    root.moveSelection(-1, 0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    root.moveSelection(1, 0)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    root.moveSelection(0, -1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    root.moveSelection(0, 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.activateSelected()
                    event.accepted = true
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    spacing: 10

                    RaohaneSurface {
                        width: 36
                        height: 36
                        surfaceRadius: 12
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "space_dashboard"
                            iconSize: 18
                            fill: 1
                            symbolWeight: 540
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: qsTr("Spaces")
                            color: RaohaneTheme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: qsTr("Workspaces and open windows")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    RaohaneSurface {
                        width: groupText.implicitWidth + 16
                        height: 26
                        surfaceRadius: 9
                        transparentIdle: true
                        showSheen: false

                        Text {
                            id: groupText
                            anchors.centerIn: parent
                            text: qsTr("%1–%2").arg(root.groupStart).arg(root.groupStart + root.workspaceCount - 1)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.Medium
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 30
                        iconSize: 15
                        icon: "close"
                        transparentIdle: true
                        showSheen: false
                        onClicked: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: root.columns
                    columnSpacing: 9
                    rowSpacing: 9

                    Repeater {
                        model: root.workspaceIds

                        delegate: RaohaneOverviewWorkspaceCard {
                            required property var modelData
                            required property int index

                            workspaceId: Number(modelData)
                            workspaceObject: root.workspaceForId(workspaceId)
                            cardIndex: index
                            shortcutLabel: root.shortcutLabel(index)
                            activeWorkspace: workspaceId === root.activeWorkspaceId
                            selected: index === root.selectedIndex
                            onHoveredIndex: hoveredIndex => root.selectedIndex = hoveredIndex
                            onWorkspaceActivated: workspaceId => root.activateWorkspace(workspaceId)
                            onWindowActivated: toplevel => root.activateWindow(toplevel)
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Arrows navigate · 1–9/0 opens · Enter opens · Esc closes")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: qsTr("Workspace %1").arg(root.activeWorkspaceId)
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "search"

        function toggle(): void { root.toggle() }
        function workspacesToggle(): void { root.toggle() }
        function close(): void { root.close() }
        function open(): void { root.open() }
        function clipboardToggle(): void {
            RaohaneSearch.query = ":"
            RaohaneState.setPrimaryOpen("launcher", true)
        }
    }

    CompositorGlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Close Raohane workspace overview"
        onPressed: root.close()
    }

    CompositorGlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggle Raohane workspace overview"
        onPressed: root.toggle()
    }

    CompositorGlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Open clipboard search in Raohane launcher"
        onPressed: {
            RaohaneSearch.query = ":"
            RaohaneState.setPrimaryOpen("launcher", true)
        }
    }
}
