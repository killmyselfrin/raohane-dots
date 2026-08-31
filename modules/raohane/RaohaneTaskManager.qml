pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    property string query: ""
    property string sortMode: "cpu"
    property string selectedCommand: ""
    property string pendingAction: ""
    property string pendingCommand: ""

    readonly property var groups: {
        const generation = RaohaneProcesses.generation
        const source = RaohaneProcesses.processes
        const grouped = ({})

        for (const process of source) {
            const name = String(process.command ?? qsTr("Process"))
            const key = name.toLowerCase()
            if (!grouped[key]) {
                grouped[key] = {
                    command: name,
                    cpu: 0,
                    memoryPercent: 0,
                    rssMiB: 0,
                    pids: [],
                    processes: []
                }
            }
            const group = grouped[key]
            group.cpu += Number(process.cpu ?? 0)
            group.memoryPercent += Number(process.memoryPercent ?? 0)
            group.rssMiB += Number(process.rssMiB ?? 0)
            group.pids.push(Number(process.pid))
            group.processes.push(process)
        }

        const needle = root.query.trim().toLowerCase()
        let values = Object.keys(grouped).map(key => grouped[key])
        if (needle.length > 0) {
            values = values.filter(group => {
                if (group.command.toLowerCase().includes(needle))
                    return true
                return group.processes.some(process => String(process.pid).includes(needle))
            })
        }

        values.sort((left, right) => {
            if (root.sortMode === "memory")
                return right.rssMiB - left.rssMiB || left.command.localeCompare(right.command)
            if (root.sortMode === "name")
                return left.command.localeCompare(right.command)
            return right.cpu - left.cpu || right.rssMiB - left.rssMiB
        })
        return values
    }

    readonly property var selectedGroup: {
        const name = root.selectedCommand
        if (name.length === 0)
            return null
        for (const group of root.groups) {
            if (group.command === name)
                return group
        }
        return null
    }

    function close(): void {
        root.pendingAction = ""
        root.pendingCommand = ""
        RaohaneState.setPrimaryOpen("taskManager", false)
    }

    function formatMemory(value: real): string {
        const mib = Math.max(0, Number(value ?? 0))
        if (mib >= 1024)
            return (mib / 1024).toFixed(mib >= 10240 ? 0 : 1) + " GiB"
        return mib.toFixed(mib >= 100 ? 0 : 1) + " MiB"
    }

    function formatAge(seconds: real): string {
        const value = Math.max(0, Math.floor(Number(seconds ?? 0)))
        if (value >= 86400)
            return Math.floor(value / 86400) + "d " + Math.floor((value % 86400) / 3600) + "h"
        if (value >= 3600)
            return Math.floor(value / 3600) + "h " + Math.floor((value % 3600) / 60) + "m"
        if (value >= 60)
            return Math.floor(value / 60) + "m " + (value % 60) + "s"
        return value + "s"
    }

    function requestSignal(signalName: string): void {
        const group = root.selectedGroup
        if (!group)
            return

        if (root.pendingAction === signalName && root.pendingCommand === group.command) {
            if (signalName === "KILL")
                RaohaneProcesses.forceKill(group.pids)
            else
                RaohaneProcesses.terminate(group.pids)
            root.pendingAction = ""
            root.pendingCommand = ""
            return
        }

        root.pendingAction = signalName
        root.pendingCommand = group.command
        confirmTimer.restart()
    }

    Connections {
        target: RaohaneState

        function onTaskManagerOpenChanged(): void {
            if (!RaohaneState.taskManagerOpen)
                return
            root.query = ""
            root.pendingAction = ""
            root.pendingCommand = ""
            RaohaneProcesses.refresh()
            Qt.callLater(searchInput.forceActiveFocus)
        }
    }

    Connections {
        target: RaohaneProcesses
        function onGenerationChanged(): void {
            if (root.selectedCommand.length > 0 && !root.selectedGroup)
                root.selectedCommand = ""
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: RaohaneState.taskManagerOpen
        onTriggered: RaohaneProcesses.refresh()
    }

    Timer {
        id: confirmTimer
        interval: 4200
        repeat: false
        onTriggered: {
            root.pendingAction = ""
            root.pendingCommand = ""
        }
    }

    PanelWindow {
        id: taskWindow

        visible: RaohaneState.taskManagerOpen
        screen: root.focusedScreen
        implicitWidth: Math.min(1040, Math.max(760, screen?.width - 160 ?? 960))
        implicitHeight: Math.min(700, Math.max(540, screen?.height - 140 ?? 620))
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        anchors {
            top: true
            left: true
        }

        margins {
            top: Math.max(42, ((screen?.height ?? implicitHeight) - implicitHeight) / 2)
            left: Math.max(42, ((screen?.width ?? implicitWidth) - implicitWidth) / 2)
        }

        WlrLayershell.namespace: "quickshell:raohane-task-manager"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        RaohaneSurface {
            anchors.fill: parent
            raised: true
            showSheen: false
            surfaceRadius: RaohaneTheme.radiusLarge
            border.color: RaohaneTheme.borderStrong
            clip: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                } else if (event.key === Qt.Key_F5) {
                    RaohaneProcesses.refresh()
                    event.accepted = true
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 13

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 42
                        height: 42
                        radius: RaohaneTheme.radiusSmall
                        color: RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "browse_activity"
                            iconSize: 21
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: qsTr("Task Manager")
                            color: RaohaneTheme.text
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: qsTr("Applications and processes running in your session")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }

                    Text {
                        text: qsTr("Load %1 / %2 cores").arg(RaohaneProcesses.loadOne.toFixed(2)).arg(RaohaneProcesses.cpuCount)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                    }

                    Rectangle {
                        width: 38
                        height: 38
                        radius: RaohaneTheme.radiusSmall
                        color: refreshMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border
                        opacity: RaohaneProcesses.busy ? 0.55 : 1

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "refresh"
                            iconSize: 18
                            color: RaohaneTheme.textMuted
                        }

                        MouseArea {
                            id: refreshMouse
                            anchors.fill: parent
                            enabled: !RaohaneProcesses.busy
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: RaohaneProcesses.refresh()
                        }
                    }

                    Rectangle {
                        width: 38
                        height: 38
                        radius: RaohaneTheme.radiusSmall
                        color: closeMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "close"
                            iconSize: 18
                            color: RaohaneTheme.textMuted
                        }

                        MouseArea {
                            id: closeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.close()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: RaohaneTheme.radiusSmall
                        color: RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: searchInput.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            RaohaneIcon {
                                text: "search"
                                iconSize: 17
                                color: RaohaneTheme.textMuted
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                color: RaohaneTheme.text
                                selectionColor: RaohaneTheme.accentSoft
                                selectedTextColor: RaohaneTheme.text
                                font.pixelSize: 11
                                clip: true
                                text: root.query
                                onTextChanged: root.query = text
                            }

                            Text {
                                visible: searchInput.text.length === 0
                                text: qsTr("Search applications or PID")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 10
                            }
                        }
                    }

                    SortButton { mode: "cpu"; icon: "speed"; title: qsTr("CPU") }
                    SortButton { mode: "memory"; icon: "memory"; title: qsTr("Memory") }
                    SortButton { mode: "name"; icon: "sort_by_alpha"; title: qsTr("Name") }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    StatCard {
                        icon: "apps"
                        title: qsTr("Applications")
                        value: String(root.groups.length)
                    }
                    StatCard {
                        icon: "account_tree"
                        title: qsTr("Processes")
                        value: String(RaohaneProcesses.processes.length)
                    }
                    StatCard {
                        icon: "memory"
                        title: qsTr("Memory")
                        value: root.formatMemory(RaohaneProcesses.memoryUsedMiB) + " / " + root.formatMemory(RaohaneProcesses.memoryTotalMiB)
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 12

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: RaohaneTheme.radius
                        color: RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border
                        clip: true

                        ListView {
                            id: groupList
                            anchors.fill: parent
                            anchors.margins: 7
                            model: root.groups
                            spacing: 4
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                id: groupRow
                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                height: 52
                                radius: RaohaneTheme.radiusSmall
                                readonly property bool selected: root.selectedCommand === modelData.command
                                color: selected ? RaohaneTheme.surfacePressed
                                    : rowMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                                border.width: selected ? 1 : 0
                                border.color: selected ? RaohaneTheme.accentBorder : "transparent"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 11
                                    anchors.rightMargin: 11
                                    spacing: 10

                                    Rectangle {
                                        width: 32
                                        height: 32
                                        radius: 10
                                        color: groupRow.selected ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceRaised

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: "deployed_code"
                                            iconSize: 16
                                            color: groupRow.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            Layout.fillWidth: true
                                            text: groupRow.modelData.command
                                            color: RaohaneTheme.text
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            elide: Text.ElideRight
                                        }
                                        Text {
                                            text: qsTr("%1 process(es)").arg(groupRow.modelData.pids.length)
                                            color: RaohaneTheme.textFaint
                                            font.pixelSize: 8
                                        }
                                    }

                                    Text {
                                        Layout.preferredWidth: 70
                                        text: groupRow.modelData.cpu.toFixed(1) + "%"
                                        color: groupRow.modelData.cpu >= 50 ? RaohaneTheme.warning : RaohaneTheme.textMuted
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        Layout.preferredWidth: 82
                                        text: root.formatMemory(groupRow.modelData.rssMiB)
                                        color: RaohaneTheme.textMuted
                                        horizontalAlignment: Text.AlignRight
                                        font.pixelSize: 9
                                    }
                                }

                                MouseArea {
                                    id: rowMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        root.selectedCommand = groupRow.modelData.command
                                        root.pendingAction = ""
                                        root.pendingCommand = ""
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: root.groups.length === 0 && !RaohaneProcesses.busy
                                text: root.query.length > 0 ? qsTr("No matching processes") : qsTr("No process data")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 272
                        Layout.fillHeight: true
                        radius: RaohaneTheme.radius
                        color: RaohaneTheme.surfaceSubtle
                        border.width: 1
                        border.color: RaohaneTheme.border

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 13
                            spacing: 10

                            Item {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: root.selectedGroup === null

                                ColumnLayout {
                                    anchors.centerIn: parent
                                    spacing: 7
                                    RaohaneIcon {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: "select_check_box"
                                        iconSize: 28
                                        color: RaohaneTheme.textFaint
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        text: qsTr("Select an application")
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 10
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                visible: root.selectedGroup !== null
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: root.selectedGroup?.command ?? ""
                                    color: RaohaneTheme.text
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    DetailStat { title: qsTr("CPU"); value: (root.selectedGroup?.cpu ?? 0).toFixed(1) + "%" }
                                    DetailStat { title: qsTr("RAM"); value: root.formatMemory(root.selectedGroup?.rssMiB ?? 0) }
                                }

                                Text {
                                    text: qsTr("Processes")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                ListView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    model: root.selectedGroup?.processes ?? []
                                    spacing: 4
                                    clip: true

                                    delegate: Rectangle {
                                        required property var modelData
                                        width: ListView.view.width
                                        height: 35
                                        radius: 9
                                        color: RaohaneTheme.surfaceRaised

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 9
                                            anchors.rightMargin: 9
                                            Text {
                                                text: "PID " + modelData.pid
                                                color: RaohaneTheme.text
                                                font.pixelSize: 8
                                                font.weight: Font.DemiBold
                                            }
                                            Item { Layout.fillWidth: true }
                                            Text {
                                                text: modelData.cpu.toFixed(1) + "% · " + root.formatAge(modelData.elapsedSeconds)
                                                color: RaohaneTheme.textFaint
                                                font.pixelSize: 8
                                            }
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: root.pendingAction.length > 0 && root.pendingCommand === (root.selectedGroup?.command ?? "")
                                    text: root.pendingAction === "KILL"
                                        ? qsTr("Press Force stop again to confirm")
                                        : qsTr("Press End again to confirm")
                                    color: root.pendingAction === "KILL" ? RaohaneTheme.critical : RaohaneTheme.warning
                                    font.pixelSize: 8
                                    wrapMode: Text.WordWrap
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7

                                    ProcessButton {
                                        Layout.fillWidth: true
                                        title: root.pendingAction === "TERM" && root.pendingCommand === (root.selectedGroup?.command ?? "")
                                            ? qsTr("Confirm end") : qsTr("End")
                                        icon: "stop_circle"
                                        warning: true
                                        onTriggered: root.requestSignal("TERM")
                                    }
                                    ProcessButton {
                                        Layout.fillWidth: true
                                        title: root.pendingAction === "KILL" && root.pendingCommand === (root.selectedGroup?.command ?? "")
                                            ? qsTr("Confirm") : qsTr("Force stop")
                                        icon: "dangerous"
                                        danger: true
                                        onTriggered: root.requestSignal("KILL")
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: RaohaneProcesses.errorText.length > 0
                            ? RaohaneProcesses.errorText
                            : qsTr("Only processes owned by your user are shown · F5 refreshes manually")
                        color: RaohaneProcesses.errorText.length > 0 ? RaohaneTheme.critical : RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                    Text {
                        text: RaohaneProcesses.busy ? qsTr("Refreshing…") : qsTr("Live · 1.5 s")
                        color: RaohaneProcesses.busy ? RaohaneTheme.accent : RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "taskManager"
        function toggle(): void { RaohaneState.togglePrimary("taskManager") }
        function open(): void { RaohaneState.setPrimaryOpen("taskManager", true) }
        function close(): void { root.close() }
        function refresh(): void { RaohaneProcesses.refresh() }
    }

    CompositorGlobalShortcut {
        name: "taskManagerToggle"
        description: "Toggle the Raohane Task Manager"
        onPressed: RaohaneState.togglePrimary("taskManager")
    }

    component SortButton: Rectangle {
        id: sortButton
        required property string mode
        required property string icon
        required property string title

        Layout.preferredWidth: 92
        Layout.preferredHeight: 42
        radius: RaohaneTheme.radiusSmall
        color: root.sortMode === mode ? RaohaneTheme.surfacePressed
            : sortMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: root.sortMode === mode ? RaohaneTheme.accentBorder : RaohaneTheme.border

        RowLayout {
            anchors.centerIn: parent
            spacing: 6
            RaohaneIcon {
                text: sortButton.icon
                iconSize: 15
                color: root.sortMode === sortButton.mode ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }
            Text {
                text: sortButton.title
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: sortMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sortMode = sortButton.mode
        }
    }

    component StatCard: Rectangle {
        id: stat
        required property string icon
        required property string title
        required property string value

        Layout.fillWidth: true
        Layout.preferredHeight: 54
        radius: RaohaneTheme.radiusSmall
        color: RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: RaohaneTheme.border

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 11
            spacing: 8
            RaohaneIcon { text: stat.icon; iconSize: 17; color: RaohaneTheme.textMuted }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0
                Text { text: stat.title; color: RaohaneTheme.textFaint; font.pixelSize: 8 }
                Text { text: stat.value; color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
            }
        }
    }

    component DetailStat: Rectangle {
        id: detail
        required property string title
        required property string value

        Layout.fillWidth: true
        Layout.preferredHeight: 48
        radius: RaohaneTheme.radiusSmall
        color: RaohaneTheme.surfaceRaised

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 0
            Text { Layout.alignment: Qt.AlignHCenter; text: detail.value; color: RaohaneTheme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { Layout.alignment: Qt.AlignHCenter; text: detail.title; color: RaohaneTheme.textFaint; font.pixelSize: 8 }
        }
    }

    component ProcessButton: Rectangle {
        id: processButton
        required property string title
        required property string icon
        property bool warning: false
        property bool danger: false
        signal triggered()

        Layout.preferredHeight: 38
        radius: RaohaneTheme.radiusSmall
        color: buttonMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceRaised
        border.width: 1
        border.color: danger ? RaohaneTheme.critical : warning ? RaohaneTheme.warning : RaohaneTheme.border

        RowLayout {
            anchors.centerIn: parent
            spacing: 5
            RaohaneIcon {
                text: processButton.icon
                iconSize: 14
                color: processButton.danger ? RaohaneTheme.critical
                    : processButton.warning ? RaohaneTheme.warning : RaohaneTheme.textMuted
            }
            Text {
                text: processButton.title
                color: processButton.danger ? RaohaneTheme.critical : RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: processButton.triggered()
        }
    }
}
