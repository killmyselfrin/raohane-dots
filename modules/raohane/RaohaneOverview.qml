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
            opacity: overviewPanel.entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }

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
            scale: entered ? 1 : 0.982

            transform: Translate {
                y: overviewPanel.entered ? 0 : 12
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }

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

                        delegate: RaohaneSurface {
                            id: workspaceCard

                            required property var modelData
                            required property int index

                            readonly property int workspaceId: Number(modelData)
                            readonly property var workspaceObject: root.workspaceForId(workspaceId)
                            readonly property var windows: workspaceObject?.toplevels.values ?? []
                            readonly property bool activeWorkspace: workspaceId === root.activeWorkspaceId
                            readonly property bool selected: index === root.selectedIndex

                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 128
                            surfaceRadius: 17
                            raised: activeWorkspace || selected
                            hovered: workspaceMouse.containsMouse || activeFocus
                            pressed: workspaceMouse.pressed
                            interactive: true
                            showSheen: false
                            hoverScale: 1.008
                            pressedScale: 0.994
                            activeFocusOnTab: true
                            border.color: activeWorkspace ? RaohaneTheme.accentBorder
                                : selected ? RaohaneTheme.borderStrong
                                : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border

                            Rectangle {
                                visible: workspaceCard.activeWorkspace
                                anchors {
                                    left: parent.left
                                    top: parent.top
                                    bottom: parent.bottom
                                    leftMargin: 3
                                    topMargin: 12
                                    bottomMargin: 12
                                }
                                width: 2
                                radius: 1
                                color: RaohaneTheme.accent
                            }

                            ColumnLayout {
                                z: 1
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: String(workspaceCard.workspaceId).padStart(2, "0")
                                        color: workspaceCard.activeWorkspace ? RaohaneTheme.accent : RaohaneTheme.text
                                        font.pixelSize: 18
                                        font.weight: Font.Medium

                                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                    }

                                    Item { Layout.fillWidth: true }

                                    RaohaneSurface {
                                        visible: workspaceCard.activeWorkspace
                                        implicitWidth: activeText.implicitWidth + 12
                                        implicitHeight: 21
                                        surfaceRadius: 7
                                        active: true
                                        showSheen: false

                                        Text {
                                            id: activeText
                                            anchors.centerIn: parent
                                            text: qsTr("Active")
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 7
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 1
                                    color: RaohaneTheme.borderFaint
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    spacing: 4

                                    Repeater {
                                        model: workspaceCard.windows.slice(0, 4)

                                        delegate: RaohaneSurface {
                                            id: windowRow
                                            required property var modelData

                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 26
                                            surfaceRadius: 8
                                            transparentIdle: !Boolean(windowRow.modelData?.activated)
                                            active: Boolean(windowRow.modelData?.activated)
                                            hovered: windowMouse.containsMouse
                                            pressed: windowMouse.pressed
                                            interactive: true
                                            showSheen: false
                                            hoverScale: 1.004
                                            pressedScale: 0.992
                                            opacity: modelData?.wayland ? 1 : 0.65

                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 7
                                                anchors.rightMargin: 7
                                                spacing: 7

                                                Rectangle {
                                                    width: 5
                                                    height: 5
                                                    radius: 3
                                                    color: windowRow.modelData?.urgent
                                                        ? RaohaneTheme.critical
                                                        : windowRow.modelData?.activated ? RaohaneTheme.accent : RaohaneTheme.textFaint

                                                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: windowRow.modelData?.title ?? qsTr("Window")
                                                    color: windowRow.modelData?.activated ? RaohaneTheme.text : RaohaneTheme.textMuted
                                                    font.pixelSize: 8
                                                    font.weight: windowRow.modelData?.activated ? Font.DemiBold : Font.Normal
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: windowMouse
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
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                    }

                                    Item { Layout.fillHeight: true }
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: qsTr("%1 windows").arg(workspaceCard.windows.length)
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 7
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        visible: workspaceCard.windows.length > 4
                                        text: "+" + (workspaceCard.windows.length - 4)
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 7
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
                                onPressed: workspaceCard.forceActiveFocus()
                                onEntered: root.selectedIndex = workspaceCard.index
                                onClicked: root.activateWorkspace(workspaceCard.workspaceId)
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: qsTr("Arrows navigate · Enter opens · Esc closes")
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
