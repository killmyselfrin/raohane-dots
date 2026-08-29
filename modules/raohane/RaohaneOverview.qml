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

        Rectangle {
            anchors.fill: parent
            color: "#b508070d"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: overviewPanel
            width: Math.min(parent.width - 80, 1060)
            height: Math.min(parent.height - 100, 700)
            anchors.centerIn: parent
            radius: 30
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border
            clip: true

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_Left) {
                    root.selectedIndex = Math.max(0, root.selectedIndex - 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Right) {
                    root.selectedIndex = Math.min(root.workspaceCount - 1, root.selectedIndex + 1)
                    event.accepted = true
                } else if (event.key === Qt.Key_Up) {
                    root.selectedIndex = Math.max(0, root.selectedIndex - root.columns)
                    event.accepted = true
                } else if (event.key === Qt.Key_Down) {
                    root.selectedIndex = Math.min(root.workspaceCount - 1, root.selectedIndex + root.columns)
                    event.accepted = true
                } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.activateSelected()
                    event.accepted = true
                }
            }

            Component.onCompleted: forceActiveFocus()
            onVisibleChanged: {
                if (visible)
                    forceActiveFocus()
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 15
                        color: RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            anchors.centerIn: parent
                            text: "間"
                            color: RaohaneTheme.accent
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -1

                        Text {
                            text: qsTr("Spaces")
                            color: RaohaneTheme.text
                            font.pixelSize: 20
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: qsTr("Hyprland workspaces · arrows / Enter / Esc · click a window to focus")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }

                    Rectangle {
                        width: groupText.implicitWidth + 18
                        height: 29
                        radius: 15
                        color: "#1cffffff"
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            id: groupText
                            anchors.centerIn: parent
                            text: qsTr("GROUP %1–%2").arg(root.groupStart).arg(root.groupStart + root.workspaceCount - 1)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.7
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    columns: root.columns
                    columnSpacing: 10
                    rowSpacing: 10

                    Repeater {
                        model: root.workspaceIds

                        delegate: Rectangle {
                            id: workspaceCard

                            required property var modelData
                            required property int index

                            readonly property int workspaceId: Number(modelData)
                            readonly property var workspaceObject: root.workspaceForId(workspaceId)
                            readonly property var windows: workspaceObject?.toplevels.values ?? []
                            readonly property bool active: workspaceId === root.activeWorkspaceId
                            readonly property bool selected: index === root.selectedIndex

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 130
                            radius: 21
                            color: active
                                ? "#35c879ff"
                                : selected || workspaceMouse.containsMouse ? RaohaneTheme.accentSoft : "#5413101b"
                            border.width: 1
                            border.color: active ? RaohaneTheme.accent
                                : selected || workspaceMouse.containsMouse ? "#72c879ff" : RaohaneTheme.border

                            ColumnLayout {
                                z: 1
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: String(workspaceCard.workspaceId).padStart(2, "0")
                                        color: workspaceCard.active ? RaohaneTheme.accent : RaohaneTheme.text
                                        font.pixelSize: 24
                                        font.weight: Font.Light
                                    }

                                    Item { Layout.fillWidth: true }

                                    Rectangle {
                                        visible: workspaceCard.active
                                        width: activeText.implicitWidth + 14
                                        height: 23
                                        radius: 12
                                        color: RaohaneTheme.accentSoft

                                        Text {
                                            id: activeText
                                            anchors.centerIn: parent
                                            text: qsTr("ACTIVE")
                                            color: RaohaneTheme.accent
                                            font.pixelSize: 7
                                            font.weight: Font.Bold
                                            font.letterSpacing: 0.7
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: RaohaneTheme.border
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4

                                    Repeater {
                                        model: workspaceCard.windows.slice(0, 4)

                                        delegate: RowLayout {
                                            id: windowRow
                                            required property var modelData
                                            Layout.fillWidth: true
                                            spacing: 7
                                            opacity: modelData?.wayland ? 1 : 0.65

                                            Rectangle {
                                                width: 6
                                                height: 6
                                                radius: 3
                                                color: windowRow.modelData?.urgent
                                                    ? "#ff6b7f"
                                                    : windowRow.modelData?.activated ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: windowRow.modelData?.title ?? qsTr("Window")
                                                color: windowRow.modelData?.activated ? RaohaneTheme.accent : RaohaneTheme.text
                                                font.pixelSize: 9
                                                font.weight: windowRow.modelData?.activated ? Font.DemiBold : Font.Normal
                                                elide: Text.ElideRight
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                z: 2
                                                enabled: !!windowRow.modelData?.wayland
                                                hoverEnabled: true
                                                preventStealing: true
                                                acceptedButtons: Qt.LeftButton
                                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                                onEntered: root.selectedIndex = workspaceCard.index
                                                onClicked: root.activateWindow(windowRow.modelData)
                                            }
                                        }
                                    }

                                    Text {
                                        visible: workspaceCard.windows.length === 0
                                        text: qsTr("Empty workspace")
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                    }

                                    Item { Layout.fillHeight: true }
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: qsTr("%1 windows").arg(workspaceCard.windows.length)
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        visible: workspaceCard.windows.length > 4
                                        text: "+" + (workspaceCard.windows.length - 4)
                                        color: RaohaneTheme.accent
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            MouseArea {
                                id: workspaceMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton
                                onEntered: root.selectedIndex = workspaceCard.index
                                onClicked: root.activateWorkspace(workspaceCard.workspaceId)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "RAOHANE / SPACES"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.letterSpacing: 0.9
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: qsTr("Focused workspace %1").arg(root.activeWorkspaceId)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
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
