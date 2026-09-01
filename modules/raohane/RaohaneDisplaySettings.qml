pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property int selectedIndex: 0
    property string draftMode: "preferred"
    property real draftScale: 1
    property int draftTransform: 0
    property int draftVrr: 0
    property int draftBitdepth: 8
    property bool draftAutoPosition: true
    property int draftX: 0
    property int draftY: 0

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var selectedMonitor: RaohaneMonitorManager.monitors.length > 0
        ? RaohaneMonitorManager.monitors[Math.max(0, Math.min(root.selectedIndex, RaohaneMonitorManager.monitors.length - 1))]
        : null

    function modeOptions(): var {
        const options = ["preferred"]
        const seen = ({ preferred: true })
        const available = root.selectedMonitor?.availableModes ?? []
        for (const mode of available) {
            const clean = RaohaneMonitorManager.normalizeMode(mode)
            if (clean.length > 0 && !seen[clean]) {
                seen[clean] = true
                options.push(clean)
            }
        }
        const current = RaohaneMonitorManager.currentMode(root.selectedMonitor)
        if (current !== "preferred" && !seen[current])
            options.splice(1, 0, current)
        return options
    }

    function scaleOptions(): var {
        const base = [0.75, 1, 1.25, 1.5, 1.75, 2, 2.5, 3]
        if (!base.some(value => Math.abs(value - root.draftScale) < 0.001))
            base.push(root.draftScale)
        return base.sort((a, b) => a - b)
    }

    function transformLabel(value: int): string {
        const labels = [
            qsTr("Normal"), qsTr("90°"), qsTr("180°"), qsTr("270°"),
            qsTr("Flipped"), qsTr("Flipped 90°"), qsTr("Flipped 180°"), qsTr("Flipped 270°")
        ]
        return labels[Math.max(0, Math.min(7, value))]
    }

    function vrrLabel(value: int): string {
        switch (value) {
        case -1: return qsTr("Follow global")
        case 1: return qsTr("Always on")
        case 2: return qsTr("Fullscreen")
        case 3: return qsTr("Video / game fullscreen")
        default: return qsTr("Off")
        }
    }

    function loadDraft(): void {
        if (!root.selectedMonitor)
            return
        const config = RaohaneMonitorManager.currentConfiguration(root.selectedMonitor.name)
        if (!config)
            return
        root.draftMode = config.mode
        root.draftScale = config.scale
        root.draftTransform = config.transform
        root.draftVrr = config.vrr
        root.draftBitdepth = config.bitdepth
        root.draftAutoPosition = String(config.position) === "auto"
        const match = String(config.position).match(/^(-?\d+)x(-?\d+)$/)
        root.draftX = match ? Number(match[1]) : Math.round(Number(root.selectedMonitor.x ?? 0))
        root.draftY = match ? Number(match[2]) : Math.round(Number(root.selectedMonitor.y ?? 0))
    }

    function cycleMode(delta: int): void {
        const options = root.modeOptions()
        let index = options.indexOf(root.draftMode)
        if (index < 0)
            index = 0
        index = (index + delta + options.length) % options.length
        root.draftMode = options[index]
    }

    function cycleScale(delta: int): void {
        const options = root.scaleOptions()
        let index = options.findIndex(value => Math.abs(value - root.draftScale) < 0.001)
        if (index < 0)
            index = 0
        index = (index + delta + options.length) % options.length
        root.draftScale = options[index]
    }

    function cycleVrr(delta: int): void {
        const options = [-1, 0, 1, 2, 3]
        let index = options.indexOf(root.draftVrr)
        if (index < 0)
            index = 1
        index = (index + delta + options.length) % options.length
        root.draftVrr = options[index]
    }

    function draftConfiguration(): var {
        if (!root.selectedMonitor)
            return null
        return {
            name: root.selectedMonitor.name,
            mode: root.draftMode,
            position: root.draftAutoPosition ? "auto" : `${root.draftX}x${root.draftY}`,
            scale: root.draftScale,
            transform: root.draftTransform,
            vrr: root.draftVrr,
            bitdepth: root.draftBitdepth
        }
    }

    onSelectedIndexChanged: Qt.callLater(root.loadDraft)
    onSelectedMonitorChanged: Qt.callLater(root.loadDraft)

    Connections {
        target: RaohaneMonitorManager
        function onMonitorsChanged(): void {
            if (root.selectedIndex >= RaohaneMonitorManager.monitors.length)
                root.selectedIndex = Math.max(0, RaohaneMonitorManager.monitors.length - 1)
            Qt.callLater(root.loadDraft)
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.displaySettingsOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-display-settings"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (!visible)
                return
            RaohaneMonitorManager.refresh()
            Qt.callLater(root.loadDraft)
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark ? Qt.rgba(0, 0, 0, 0.48) : Qt.rgba(0.10, 0.10, 0.09, 0.25)
        }

        RaohaneSurface {
            id: frame
            anchors.centerIn: parent
            width: Math.min(panelWindow.width - 70, 1080)
            height: Math.min(panelWindow.height - 70, 720)
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 78

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 18
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            radius: 13
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.accentBorder

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "monitor"
                                iconSize: 21
                                fill: 0.2
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: qsTr("Displays")
                                color: RaohaneTheme.text
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: qsTr("Resolution, refresh rate, scale, layout, rotation and adaptive sync")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }

                        RaohaneSurface {
                            Layout.preferredWidth: 104
                            Layout.preferredHeight: 34
                            surfaceRadius: 11
                            transparentIdle: true
                            interactive: true
                            hovered: refreshMouse.containsMouse
                            pressed: refreshMouse.pressed
                            showSheen: false

                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                RaohaneIcon { text: "refresh"; iconSize: 14; color: RaohaneTheme.textMuted }
                                Text { text: RaohaneMonitorManager.refreshing ? qsTr("Reading…") : qsTr("Refresh"); color: RaohaneTheme.textMuted; font.pixelSize: 9; font.weight: Font.Medium }
                            }

                            MouseArea {
                                id: refreshMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneMonitorManager.refresh()
                            }
                        }

                        RaohaneIconButton {
                            buttonSize: 34
                            iconSize: 17
                            icon: "close"
                            transparentIdle: true
                            onClicked: {
                                if (RaohaneMonitorManager.pending)
                                    RaohaneMonitorManager.revertTemporary()
                                RaohaneState.setPrimaryOpen("displaySettings", false)
                            }
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 1
                        color: RaohaneTheme.borderFaint
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    Item {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 265

                        Rectangle {
                            anchors.fill: parent
                            color: RaohaneTheme.surfaceSubtle
                            opacity: RaohaneTheme.dark ? 0.30 : 0.42
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            Text {
                                text: qsTr("CONNECTED DISPLAYS")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.0
                            }

                            Flickable {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: width
                                contentHeight: monitorColumn.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                Column {
                                    id: monitorColumn
                                    width: parent.width
                                    spacing: 7

                                    Repeater {
                                        model: RaohaneMonitorManager.monitors

                                        delegate: RaohaneSurface {
                                            id: monitorCard
                                            required property var modelData
                                            required property int index

                                            width: monitorColumn.width
                                            height: 84
                                            surfaceRadius: 15
                                            active: root.selectedIndex === index
                                            transparentIdle: !active
                                            interactive: true
                                            hovered: monitorMouse.containsMouse
                                            pressed: monitorMouse.pressed
                                            showSheen: false

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.margins: 12
                                                spacing: 3

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    RaohaneIcon {
                                                        text: "monitor"
                                                        iconSize: 16
                                                        color: monitorCard.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: monitorCard.modelData.name
                                                        color: RaohaneTheme.text
                                                        font.pixelSize: 10
                                                        font.weight: Font.DemiBold
                                                    }
                                                    Rectangle {
                                                        width: 7
                                                        height: 7
                                                        radius: 4
                                                        color: monitorCard.modelData.dpmsStatus ? RaohaneTheme.positive : RaohaneTheme.textFaint
                                                    }
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: monitorCard.modelData.model || monitorCard.modelData.description || qsTr("Display")
                                                    color: RaohaneTheme.textMuted
                                                    font.pixelSize: 8
                                                    elide: Text.ElideRight
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    text: qsTr("%1×%2 · %3 Hz · %4×").arg(monitorCard.modelData.width).arg(monitorCard.modelData.height).arg(Number(monitorCard.modelData.refreshRate).toFixed(1)).arg(Number(monitorCard.modelData.scale).toFixed(2))
                                                    color: RaohaneTheme.textFaint
                                                    font.pixelSize: 7
                                                }
                                            }

                                            MouseArea {
                                                id: monitorMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.selectedIndex = monitorCard.index
                                            }
                                        }
                                    }
                                }
                            }

                            Text {
                                visible: RaohaneMonitorManager.monitors.length === 0
                                Layout.fillWidth: true
                                text: RaohaneMonitorManager.errorMessage || qsTr("No outputs reported by Hyprland.")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: RaohaneTheme.borderFaint
                    }

                    Flickable {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: settingsColumn.implicitHeight + 34
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: settingsColumn
                            width: Math.min(parent.width - 46, 720)
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 18
                            spacing: 11

                            Text {
                                width: parent.width
                                text: root.selectedMonitor
                                    ? (root.selectedMonitor.description || root.selectedMonitor.name)
                                    : qsTr("Select a display")
                                color: RaohaneTheme.text
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                width: parent.width
                                text: root.selectedMonitor
                                    ? qsTr("Changes are tested for 15 seconds before being saved by Raohane.")
                                    : qsTr("Connect a display or refresh the monitor list.")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                            }

                            ChoiceStepper {
                                width: parent.width
                                label: qsTr("Resolution & refresh rate")
                                detail: qsTr("Modes reported directly by Hyprland for this output")
                                value: root.draftMode === "preferred" ? qsTr("Preferred") : root.draftMode
                                enabled: !!root.selectedMonitor
                                onPrevious: root.cycleMode(-1)
                                onNext: root.cycleMode(1)
                            }

                            ChoiceStepper {
                                width: parent.width
                                label: qsTr("Scale")
                                detail: qsTr("Logical desktop scale for this monitor")
                                value: `${Number(root.draftScale).toFixed(2)}×`
                                enabled: !!root.selectedMonitor
                                onPrevious: root.cycleScale(-1)
                                onNext: root.cycleScale(1)
                            }

                            ChoiceStepper {
                                width: parent.width
                                label: qsTr("Rotation")
                                detail: qsTr("Normal, rotated or flipped output transform")
                                value: root.transformLabel(root.draftTransform)
                                enabled: !!root.selectedMonitor
                                onPrevious: root.draftTransform = (root.draftTransform + 7) % 8
                                onNext: root.draftTransform = (root.draftTransform + 1) % 8
                            }

                            ChoiceStepper {
                                width: parent.width
                                label: qsTr("Adaptive sync / VRR")
                                detail: qsTr("Per-display variable refresh rate policy")
                                value: root.vrrLabel(root.draftVrr)
                                enabled: !!root.selectedMonitor
                                onPrevious: root.cycleVrr(-1)
                                onNext: root.cycleVrr(1)
                            }

                            ChoiceStepper {
                                width: parent.width
                                label: qsTr("Color depth")
                                detail: qsTr("10-bit can improve gradients but may affect capture compatibility")
                                value: qsTr("%1-bit").arg(root.draftBitdepth)
                                enabled: !!root.selectedMonitor
                                onPrevious: root.draftBitdepth = root.draftBitdepth === 10 ? 8 : 10
                                onNext: root.draftBitdepth = root.draftBitdepth === 10 ? 8 : 10
                            }

                            RaohaneSurface {
                                width: parent.width
                                height: 108
                                surfaceRadius: 15
                                raised: false
                                showSheen: false
                                border.color: RaohaneTheme.borderFaint

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 13
                                    spacing: 8

                                    RowLayout {
                                        Layout.fillWidth: true
                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text { text: qsTr("Automatic position"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                                            Text { text: qsTr("Let Hyprland place this output automatically"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                                        }
                                        RaohaneSwitch {
                                            Layout.preferredWidth: 42
                                            Layout.preferredHeight: 24
                                            checked: root.draftAutoPosition
                                            enabled: false
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.draftAutoPosition = !root.draftAutoPosition
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        visible: !root.draftAutoPosition
                                        spacing: 8

                                        PositionControl { Layout.fillWidth: true; axis: "X"; value: root.draftX; onDecrease: root.draftX -= 100; onIncrease: root.draftX += 100 }
                                        PositionControl { Layout.fillWidth: true; axis: "Y"; value: root.draftY; onDecrease: root.draftY -= 100; onIncrease: root.draftY += 100 }
                                    }
                                }
                            }

                            RowLayout {
                                width: parent.width
                                spacing: 9

                                RaohaneSurface {
                                    Layout.preferredWidth: 170
                                    Layout.preferredHeight: 42
                                    surfaceRadius: 13
                                    active: true
                                    interactive: !!root.selectedMonitor && !RaohaneMonitorManager.pending
                                    hovered: applyMouse.containsMouse
                                    pressed: applyMouse.pressed
                                    showSheen: false

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7

                                        RaohaneIcon {
                                            text: "check"
                                            iconSize: 15
                                            color: RaohaneTheme.accent
                                        }

                                        Text {
                                            text: qsTr("Test changes")
                                            color: RaohaneTheme.text
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    MouseArea {
                                        id: applyMouse
                                        anchors.fill: parent
                                        enabled: !!root.selectedMonitor && !RaohaneMonitorManager.pending
                                        hoverEnabled: true
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: RaohaneMonitorManager.applyTemporary(root.draftConfiguration())
                                    }
                                }

                                RaohaneSurface {
                                    Layout.preferredWidth: 156
                                    Layout.preferredHeight: 42
                                    surfaceRadius: 13
                                    transparentIdle: true
                                    interactive: !!root.selectedMonitor && !RaohaneMonitorManager.pending
                                    hovered: resetMouse.containsMouse
                                    pressed: resetMouse.pressed
                                    showSheen: false

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7

                                        RaohaneIcon {
                                            text: "restart_alt"
                                            iconSize: 15
                                            color: RaohaneTheme.textMuted
                                        }

                                        Text {
                                            text: qsTr("Preferred")
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                        }
                                    }

                                    MouseArea {
                                        id: resetMouse
                                        anchors.fill: parent
                                        enabled: !!root.selectedMonitor && !RaohaneMonitorManager.pending
                                        hoverEnabled: true
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: RaohaneMonitorManager.resetToPreferred(root.selectedMonitor.name)
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RaohaneSurface {
                                    visible: RaohaneMonitorManager.monitors.length > 1
                                    Layout.preferredWidth: 132
                                    Layout.preferredHeight: 42
                                    surfaceRadius: 13
                                    transparentIdle: true
                                    interactive: !!root.selectedMonitor
                                    hovered: sleepMouse.containsMouse
                                    pressed: sleepMouse.pressed
                                    showSheen: false

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7

                                        RaohaneIcon {
                                            text: root.selectedMonitor?.dpmsStatus ? "bedtime" : "light_mode"
                                            iconSize: 15
                                            color: RaohaneTheme.textMuted
                                        }

                                        Text {
                                            text: root.selectedMonitor?.dpmsStatus ? qsTr("Sleep") : qsTr("Wake")
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 10
                                            font.weight: Font.Medium
                                        }
                                    }

                                    MouseArea {
                                        id: sleepMouse
                                        anchors.fill: parent
                                        enabled: !!root.selectedMonitor
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: RaohaneMonitorManager.dpms(root.selectedMonitor.name, !root.selectedMonitor.dpmsStatus)
                                    }
                                }
                            }

                            RaohaneSurface {
                                visible: RaohaneMonitorManager.pending
                                width: parent.width
                                height: 74
                                surfaceRadius: 15
                                active: true
                                showSheen: false
                                border.color: RaohaneTheme.accentBorder

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 13
                                    spacing: 11

                                    Rectangle {
                                        Layout.preferredWidth: 36
                                        Layout.preferredHeight: 36
                                        radius: 12
                                        color: RaohaneTheme.accentSoft
                                        RaohaneIcon { anchors.centerIn: parent; text: "timer"; iconSize: 18; color: RaohaneTheme.accent }
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text { text: qsTr("Keep these display settings?"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                                        Text { text: qsTr("Reverting automatically in %1 seconds").arg(RaohaneMonitorManager.revertSeconds); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                                    }

                                    RaohaneSurface {
                                        Layout.preferredWidth: 88
                                        Layout.preferredHeight: 34
                                        surfaceRadius: 11
                                        active: true
                                        interactive: true
                                        hovered: keepMouse.containsMouse
                                        pressed: keepMouse.pressed
                                        showSheen: false
                                        Text { anchors.centerIn: parent; text: qsTr("Keep"); color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                                        MouseArea { id: keepMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: RaohaneMonitorManager.confirmTemporary() }
                                    }

                                    RaohaneSurface {
                                        Layout.preferredWidth: 88
                                        Layout.preferredHeight: 34
                                        surfaceRadius: 11
                                        transparentIdle: true
                                        interactive: true
                                        hovered: revertMouse.containsMouse
                                        pressed: revertMouse.pressed
                                        showSheen: false
                                        Text { anchors.centerIn: parent; text: qsTr("Revert"); color: RaohaneTheme.textMuted; font.pixelSize: 9; font.weight: Font.Medium }
                                        MouseArea { id: revertMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: RaohaneMonitorManager.revertTemporary() }
                                    }
                                }
                            }

                            Text {
                                visible: RaohaneMonitorManager.errorMessage.length > 0
                                width: parent.width
                                text: RaohaneMonitorManager.errorMessage
                                color: RaohaneTheme.critical
                                font.pixelSize: 8
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }

        Shortcut {
            sequence: "Escape"
            onActivated: {
                if (RaohaneMonitorManager.pending)
                    RaohaneMonitorManager.revertTemporary()
                RaohaneState.setPrimaryOpen("displaySettings", false)
            }
        }
    }

    IpcHandler {
        target: "displays"
        function open(): void { RaohaneState.setPrimaryOpen("displaySettings", true) }
        function close(): void { RaohaneState.setPrimaryOpen("displaySettings", false) }
        function refresh(): void { RaohaneMonitorManager.refresh() }
        function status(): string { return RaohaneState.displaySettingsOpen ? "open" : "closed" }
    }

    component ChoiceStepper: RaohaneSurface {
        id: choice

        required property string label
        required property string detail
        required property string value
        signal previous()
        signal next()

        height: 64
        surfaceRadius: 15
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 8
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { Layout.fillWidth: true; text: choice.label; color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: choice.detail; color: RaohaneTheme.textMuted; font.pixelSize: 8; elide: Text.ElideRight }
            }

            RaohaneSurface {
                Layout.preferredWidth: 226
                Layout.preferredHeight: 38
                surfaceRadius: 12
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 3
                    RaohaneIconButton { buttonSize: 29; iconSize: 13; icon: "chevron_left"; transparentIdle: true; onClicked: choice.previous() }
                    Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: choice.value; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.Medium; elide: Text.ElideRight }
                    RaohaneIconButton { buttonSize: 29; iconSize: 13; icon: "chevron_right"; transparentIdle: true; onClicked: choice.next() }
                }
            }
        }
    }

    component PositionControl: RaohaneSurface {
        id: positionControl
        required property string axis
        required property int value
        signal decrease()
        signal increase()

        height: 38
        surfaceRadius: 11
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 5
            anchors.rightMargin: 5
            spacing: 3
            Text { text: positionControl.axis; color: RaohaneTheme.textFaint; font.pixelSize: 8; font.weight: Font.DemiBold }
            RaohaneIconButton { buttonSize: 27; iconSize: 12; icon: "remove"; transparentIdle: true; onClicked: positionControl.decrease() }
            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter; text: String(positionControl.value); color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.Medium }
            RaohaneIconButton { buttonSize: 27; iconSize: 12; icon: "add"; transparentIdle: true; onClicked: positionControl.increase() }
        }
    }
}
