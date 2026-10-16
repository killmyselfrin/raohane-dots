pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property int selectedIndex: 0
    property var draggedWindow: null
    property bool dragging: false

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property int activeWorkspaceId: Math.max(1, Math.min(100, Hyprland.focusedMonitor?.activeWorkspace?.id ?? 1))
    readonly property int workspaceCount: Math.max(2, RaohaneConfig.overviewWorkspaceCount)
    readonly property int columns: Math.max(1, Math.min(RaohaneConfig.overviewColumns, workspaceCount))
    readonly property int groupStart: Math.floor((activeWorkspaceId - 1) / workspaceCount) * workspaceCount + 1
    readonly property var workspaceIds: Array.from({ length: workspaceCount }, (_, index) => groupStart + index)
    // Build one index whenever the Hyprland workspace model changes. Overview
    // cards then resolve their workspace in O(1) instead of each performing a
    // separate linear find() through the full model on every reactive update.
    readonly property var workspaceById: {
        const result = ({})
        for (const workspace of Hyprland.workspaces.values)
            result[String(workspace.id)] = workspace
        return result
    }

    function workspaceForId(workspaceId: int): var {
        return root.workspaceById[String(workspaceId)] ?? null
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

    // Target a validated compositor address, never an implicitly focused window.
    function moveWindowToWorkspace(toplevel, workspaceId: int): void {
        if (!toplevel || workspaceId < 1 || workspaceId > 100)
            return
        if (Number(toplevel?.workspace?.id ?? 0) === workspaceId)
            return
        const address = String(toplevel?.address ?? "").replace(/^0x/i, "")
        if (!/^[0-9a-fA-F]+$/.test(address))
            return
        const selector = "address:0x" + address
        if (Hyprland.usingLua)
            Hyprland.dispatch('hl.dsp.window.move({ window = "' + selector
                + '", workspace = "' + workspaceId + '", follow = false })')
        else
            Hyprland.dispatch("movetoworkspacesilent " + workspaceId + "," + selector)
    }

    function beginWindowDrag(toplevel, x: real, y: real): void {
        if (!RaohaneState.overviewOpen || !toplevel?.wayland || !toplevel?.address)
            return
        root.draggedWindow = toplevel
        dragProxy.toplevel = toplevel
        dragProxy.originWorkspaceId = Number(toplevel?.workspace?.id ?? 0)
        dragProxy.x = x - dragProxy.width / 2
        dragProxy.y = y - dragProxy.height / 2
        root.dragging = true
    }

    function moveWindowDrag(x: real, y: real): void {
        if (!root.dragging)
            return
        dragProxy.x = x - dragProxy.width / 2
        dragProxy.y = y - dragProxy.height / 2
    }

    function finishWindowDrag(): void {
        if (!root.dragging)
            return
        dragProxy.Drag.drop()
        root.dragging = false
        root.draggedWindow = null
        dragProxy.toplevel = null
    }

    function cancelWindowDrag(): void {
        if (root.dragging)
            dragProxy.Drag.cancel()
        root.dragging = false
        root.draggedWindow = null
        dragProxy.toplevel = null
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

    Component.onCompleted: {
        if (RaohaneState.overviewOpen)
            root.syncSelection()
    }

    Connections {
        target: RaohaneState
        function onOverviewOpenChanged(): void {
            if (RaohaneState.overviewOpen) {
                root.syncSelection()
                panelWindow.present()
            } else {
                root.cancelWindowDrag()
                panelWindow.dismissVisual()
            }
        }
    }

    PanelWindow {
        id: panelWindow

        property bool presented: false

        visible: presented
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

        function present(): void {
            closeTimer.stop()
            if (!presented)
                overviewPanel.entered = false
            presented = true
            Qt.callLater(() => {
                if (!RaohaneState.overviewOpen)
                    return
                overviewPanel.entered = true
                overviewPanel.forceActiveFocus()
            })
        }

        function dismissVisual(): void {
            overviewPanel.entered = false
            closeTimer.restart()
        }

        Component.onCompleted: {
            if (RaohaneState.overviewOpen)
                present()
        }

        Timer {
            id: closeTimer
            interval: Math.max(1, RaohaneMotion.standard)
            repeat: false
            onTriggered: panelWindow.presented = false
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0.005, 0.008, 0.018, 0.72)
                : Qt.rgba(0.14, 0.13, 0.12, 0.24)
            opacity: overviewPanel.entered ? 1 : 0

            Behavior on opacity {
                enabled: RaohaneMotion.enabled && !RaohanePerformance.gameModeActive
                NumberAnimation {
                    duration: overviewPanel.entered
                        ? RaohaneMotion.standard : Math.round(RaohaneMotion.standard * 0.68)
                    easing.type: overviewPanel.entered ? RaohaneMotion.easeEnter : RaohaneMotion.easeExit
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        RaohaneSurface {
            id: overviewPanel
            property bool entered: false

            width: Math.min(parent.width - 80, 1200)
            height: Math.min(parent.height - 92, 760)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: true
            idleBorderColor: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0

            transform: Translate {
                y: overviewPanel.entered || !RaohaneMotion.transformMotionEnabled
                    || RaohanePerformance.gameModeActive ? 0 : 12
                Behavior on y {
                    enabled: RaohaneMotion.transformMotionEnabled && !RaohanePerformance.gameModeActive
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on opacity {
                enabled: RaohaneMotion.enabled && !RaohanePerformance.gameModeActive
                NumberAnimation {
                    duration: overviewPanel.entered
                        ? RaohaneMotion.standard : Math.round(RaohaneMotion.standard * 0.68)
                    easing.type: overviewPanel.entered ? RaohaneMotion.easeEnter : RaohaneMotion.easeExit
                }
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
                anchors.margins: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
                spacing: RaohaneTheme.spacingLarge

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    spacing: RaohaneTheme.spacing + 2

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: RaohaneTheme.radiusLarge
                        active: true
                        raised: false
                        showSheen: false
                        showInnerRim: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "view_cozy"
                            iconSize: 19
                            fill: 1
                            symbolWeight: 550
                            grade: 30
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

                        Text {
                            text: qsTr("Spaces")
                            color: RaohaneTheme.text
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            font.letterSpacing: -0.25
                        }

                        Text {
                            text: qsTr("Workspaces and open windows")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    RaohaneSurface {
                        implicitWidth: currentWorkspaceRow.implicitWidth + RaohaneTheme.spacingLarge
                        implicitHeight: 30
                        surfaceRadius: RaohaneTheme.radiusSmall
                        active: true
                        showSheen: false
                        showInnerRim: false

                        Row {
                            id: currentWorkspaceRow
                            anchors.centerIn: parent
                            spacing: RaohaneTheme.spacingSmall

                            Rectangle {
                                width: 6
                                height: 6
                                radius: 3
                                anchors.verticalCenter: parent.verticalCenter
                                color: RaohaneTheme.accent
                            }

                            Text {
                                text: qsTr("Workspace %1").arg(root.activeWorkspaceId)
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    RaohaneSurface {
                        implicitWidth: groupText.implicitWidth + RaohaneTheme.spacingLarge
                        implicitHeight: 30
                        surfaceRadius: RaohaneTheme.radiusSmall
                        transparentIdle: true
                        showSheen: false
                        showInnerRim: false

                        Text {
                            id: groupText
                            anchors.centerIn: parent
                            text: qsTr("%1–%2").arg(root.groupStart).arg(root.groupStart + root.workspaceCount - 1)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            font.weight: Font.Medium
                        }
                    }

                    RaohaneIconButton {
                        buttonSize: 32
                        iconSize: 16
                        icon: "close"
                        transparentIdle: true
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
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
                    columnSpacing: RaohaneTheme.spacing + 1
                    rowSpacing: RaohaneTheme.spacing + 1

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
                            presented: overviewPanel.entered
                            previewEnabled: RaohaneState.overviewOpen
                                && index === root.selectedIndex && !RaohanePerformance.gameModeActive
                            dragCanvas: overviewPanel
                            onHoveredIndex: hoveredIndex => {
                                if (!root.dragging)
                                    root.selectedIndex = hoveredIndex
                            }
                            onWorkspaceActivated: workspaceId => root.activateWorkspace(workspaceId)
                            onWindowActivated: toplevel => root.activateWindow(toplevel)
                            onWindowDropped: (toplevel, workspaceId) => root.moveWindowToWorkspace(toplevel, workspaceId)
                            onWindowDragStarted: (toplevel, x, y) => root.beginWindowDrag(toplevel, x, y)
                            onWindowDragMoved: (x, y) => root.moveWindowDrag(x, y)
                            onWindowDragFinished: root.finishWindowDrag()
                            onWindowDragCanceled: root.cancelWindowDrag()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    spacing: RaohaneTheme.spacing

                    RaohaneIcon {
                        text: "keyboard"
                        iconSize: 14
                        color: RaohaneTheme.textFaint
                    }

                    Text {
                        text: qsTr("Arrows navigate · 1–9/0 opens · Enter opens · Esc closes")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 6
                        height: 6
                        radius: 3
                        color: RaohaneTheme.accent
                        opacity: 0.72
                    }

                    Text {
                        text: qsTr("Workspace %1").arg(root.activeWorkspaceId)
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }
                }
            }
        // One drag proxy outside the grid: moving it does not relayout cards.
        RaohaneSurface {
            id: dragProxy
            property var toplevel: null
            property int originWorkspaceId: 0
            z: 500
            visible: root.dragging
            width: 164
            height: 34
            surfaceRadius: RaohaneTheme.radiusSmall
            raised: true
            active: true
            showSheen: false
            opacity: 0.94

            Drag.active: root.dragging
            Drag.source: dragProxy
            Drag.keys: ["raohane-overview-window"]
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            Drag.supportedActions: Qt.MoveAction

            Text {
                anchors.centerIn: parent
                width: parent.width - 18
                text: String(dragProxy.toplevel?.title ?? "")
                font.pixelSize: 9
                font.weight: Font.DemiBold
                color: RaohaneTheme.text
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }
        }
        }
    }
}
