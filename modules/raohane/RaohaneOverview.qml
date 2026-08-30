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
            color: "#c006040c"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            anchors.centerIn: overviewPanel
            width: overviewPanel.width + 14
            height: overviewPanel.height + 14
            radius: RaohaneTheme.radiusHero + 6
            color: "transparent"
            border.width: 4
            border.color: "#1fc56cff"
        }

        RaohaneSurface {
            id: overviewPanel
            width: Math.min(parent.width - 90, 1240)
            height: Math.min(parent.height - 96, 760)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            border.color: RaohaneTheme.accentBorder
            clip: true
            focus: true

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

            RowLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.preferredWidth: 214
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 9

                            Rectangle {
                                width: 36
                                height: 36
                                radius: 13
                                color: RaohaneTheme.accentSoft
                                border.width: 1
                                border.color: RaohaneTheme.accentGlow

                                Text {
                                    anchors.centerIn: parent
                                    text: "間"
                                    color: RaohaneTheme.text
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0
                                Text {
                                    text: qsTr("Spaces")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: "RAOHANE / WORKFLOW"
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    font.letterSpacing: 0.8
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            radius: 12
                            color: RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: RaohaneTheme.border

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                spacing: 7

                                RaohaneIcon {
                                    text: "search"
                                    iconSize: 14
                                    color: RaohaneTheme.textFaint
                                }
                                Text {
                                    text: qsTr("Navigate spaces")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Repeater {
                                model: root.workspaceIds

                                delegate: Rectangle {
                                    id: railItem
                                    required property var modelData
                                    required property int index

                                    readonly property int workspaceId: Number(modelData)
                                    readonly property var workspaceObject: root.workspaceForId(workspaceId)
                                    readonly property int windowCount: workspaceObject?.toplevels.values.length ?? 0
                                    readonly property bool active: workspaceId === root.activeWorkspaceId
                                    readonly property bool selected: index === root.selectedIndex

                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 42
                                    radius: 13
                                    color: active || selected
                                        ? RaohaneTheme.accentSoft
                                        : railMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                                    border.width: active || selected || railMouse.containsMouse ? 1 : 0
                                    border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderStrong

                                    Rectangle {
                                        visible: railItem.active
                                        anchors {
                                            left: parent.left
                                            verticalCenter: parent.verticalCenter
                                        }
                                        width: 3
                                        height: 20
                                        radius: 2
                                        color: RaohaneTheme.accentSecondary
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Rectangle {
                                            width: 25
                                            height: 25
                                            radius: 9
                                            color: railItem.active ? RaohaneTheme.accentHover : RaohaneTheme.surfaceSubtle
                                            Text {
                                                anchors.centerIn: parent
                                                text: railItem.workspaceId
                                                color: railItem.active ? RaohaneTheme.accent : RaohaneTheme.text
                                                font.pixelSize: 9
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: -1
                                            Text {
                                                text: railItem.active ? qsTr("Current space") : qsTr("Workspace %1").arg(railItem.workspaceId)
                                                color: RaohaneTheme.text
                                                font.pixelSize: 9
                                                font.weight: railItem.active ? Font.DemiBold : Font.Medium
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: qsTr("%1 windows").arg(railItem.windowCount)
                                                color: RaohaneTheme.textFaint
                                                font.pixelSize: 7
                                            }
                                        }
                                    }

                                    MouseArea {
                                        id: railMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.selectedIndex = railItem.index
                                        onClicked: root.activateWorkspace(railItem.workspaceId)
                                    }
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        RaohaneSurface {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 76
                            surfaceRadius: 15

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 4

                                Text {
                                    text: qsTr("Space behavior")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: qsTr("%1 columns · group %2–%3")
                                        .arg(root.columns)
                                        .arg(root.groupStart)
                                        .arg(root.groupStart + root.workspaceCount - 1)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                }
                                Text {
                                    text: qsTr("Arrows navigate · Enter opens")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: RaohaneTheme.borderFaint
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.margins: 18
                    spacing: 13

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: qsTr("Spaces Overview")
                                color: RaohaneTheme.text
                                font.pixelSize: 20
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: qsTr("Organize your workflow across immersive Hyprland spaces")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }

                        Rectangle {
                            width: groupText.implicitWidth + 18
                            height: 29
                            radius: 11
                            color: RaohaneTheme.surfaceSubtle
                            border.width: 1
                            border.color: RaohaneTheme.borderStrong

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

                        RaohaneIconButton {
                            buttonSize: 32
                            iconSize: 16
                            icon: "close"
                            onClicked: root.close()
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        columns: root.columns
                        columnSpacing: 11
                        rowSpacing: 11

                        Repeater {
                            model: root.workspaceIds

                            delegate: RaohaneSurface {
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
                                Layout.minimumHeight: 138
                                surfaceRadius: 20
                                active: workspaceCard.active || workspaceCard.selected
                                hovered: workspaceMouse.containsMouse
                                border.color: workspaceCard.active
                                    ? RaohaneTheme.accentBorder
                                    : workspaceCard.selected ? RaohaneTheme.accentGlow : RaohaneTheme.border

                                Rectangle {
                                    visible: workspaceCard.active
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        top: parent.top
                                        leftMargin: 18
                                        rightMargin: 18
                                    }
                                    height: 2
                                    radius: 1
                                    color: RaohaneTheme.accentSecondary
                                    opacity: 0.75
                                }

                                ColumnLayout {
                                    z: 1
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 7

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Rectangle {
                                            width: 34
                                            height: 34
                                            radius: 12
                                            color: workspaceCard.active ? RaohaneTheme.accentHover : RaohaneTheme.surfaceSubtle
                                            border.width: 1
                                            border.color: workspaceCard.active ? RaohaneTheme.accentGlow : RaohaneTheme.border

                                            Text {
                                                anchors.centerIn: parent
                                                text: String(workspaceCard.workspaceId).padStart(2, "0")
                                                color: workspaceCard.active ? RaohaneTheme.accent : RaohaneTheme.text
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: -1
                                            Text {
                                                Layout.fillWidth: true
                                                text: workspaceCard.active ? qsTr("Current workspace") : qsTr("Workspace %1").arg(workspaceCard.workspaceId)
                                                color: RaohaneTheme.text
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                                elide: Text.ElideRight
                                            }
                                            Text {
                                                text: qsTr("%1 windows").arg(workspaceCard.windows.length)
                                                color: RaohaneTheme.textFaint
                                                font.pixelSize: 7
                                            }
                                        }

                                        Rectangle {
                                            visible: workspaceCard.active
                                            width: activeText.implicitWidth + 14
                                            height: 22
                                            radius: 9
                                            color: RaohaneTheme.accentSoft
                                            Text {
                                                id: activeText
                                                anchors.centerIn: parent
                                                text: qsTr("ACTIVE")
                                                color: RaohaneTheme.accent
                                                font.pixelSize: 7
                                                font.weight: Font.Bold
                                                font.letterSpacing: 0.6
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
                                                Layout.preferredHeight: 27
                                                surfaceRadius: 9
                                                hovered: windowMouse.containsMouse
                                                opacity: modelData?.wayland ? 1 : 0.65
                                                showSheen: false

                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 7
                                                    anchors.rightMargin: 7
                                                    spacing: 7

                                                    Rectangle {
                                                        width: 6
                                                        height: 6
                                                        radius: 3
                                                        color: windowRow.modelData?.urgent
                                                            ? RaohaneTheme.critical
                                                            : windowRow.modelData?.activated ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: windowRow.modelData?.title ?? qsTr("Window")
                                                        color: windowRow.modelData?.activated ? RaohaneTheme.accent : RaohaneTheme.text
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
                                            text: workspaceCard.active ? qsTr("live") : qsTr("ready")
                                            color: workspaceCard.active ? RaohaneTheme.success : RaohaneTheme.textFaint
                                            font.pixelSize: 7
                                            font.weight: Font.DemiBold
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
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
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
