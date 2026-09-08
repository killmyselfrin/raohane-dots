pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
        root.draftMode = options[(index + delta + options.length) % options.length]
    }

    function cycleScale(delta: int): void {
        const options = root.scaleOptions()
        let index = options.findIndex(value => Math.abs(value - root.draftScale) < 0.001)
        if (index < 0)
            index = 0
        root.draftScale = options[(index + delta + options.length) % options.length]
    }

    function cycleVrr(delta: int): void {
        const options = [-1, 0, 1, 2, 3]
        let index = options.indexOf(root.draftVrr)
        if (index < 0)
            index = 1
        root.draftVrr = options[(index + delta + options.length) % options.length]
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
            frame.entered = false
            RaohaneMonitorManager.refresh()
            Qt.callLater(() => {
                root.loadDraft()
                frame.entered = true
            })
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0.005, 0.008, 0.018, 0.70)
                : Qt.rgba(0.14, 0.13, 0.12, 0.26)
            opacity: frame.entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }
        }

        RaohaneSurface {
            id: frame
            property bool entered: false

            anchors.centerIn: parent
            width: Math.min(panelWindow.width - 64, 1100)
            height: Math.min(panelWindow.height - 64, 720)
            surfaceRadius: 19
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 20
                    rightMargin: 20
                }
                height: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.42
            }

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 70

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 14
                        spacing: 11

                        Rectangle {
                            Layout.preferredWidth: 3
                            Layout.preferredHeight: 36
                            radius: 2
                            color: RaohaneTheme.accent
                        }

                        RaohaneSurface {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            surfaceRadius: 12
                            active: true
                            raised: false
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "monitor"
                                iconSize: 20
                                fill: 1
                                symbolWeight: 550
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: qsTr("Displays")
                                color: RaohaneTheme.text
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                                font.letterSpacing: -0.15
                            }

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Resolution, refresh rate, scale, layout, rotation and adaptive sync")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
                        }

                        HeaderAction {
                            icon: "refresh"
                            label: RaohaneMonitorManager.refreshing ? qsTr("Reading…") : qsTr("Refresh")
                            enabled: !RaohaneMonitorManager.refreshing
                            onTriggered: RaohaneMonitorManager.refresh()
                        }

                        RaohaneIconButton {
                            buttonSize: 32
                            iconSize: 15
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: {
                                if (RaohaneMonitorManager.pending)
                                    RaohaneMonitorManager.revertTemporary()
                                RaohaneState.setPrimaryOpen("displaySettings", false)
                            }
                        }
                    }

                    Rectangle {
                        anchors {
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        height: 1
                        color: RaohaneTheme.borderFaint
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 0

                    RaohaneSurface {
                        Layout.preferredWidth: 252
                        Layout.fillHeight: true
                        surfaceRadius: 0
                        raised: false
                        showSheen: false
                        showInnerRim: false
                        color: RaohaneTheme.surfaceDeep
                        border.width: 0

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 9

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 6
                                Layout.rightMargin: 4
                                spacing: 8

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("CONNECTED DISPLAYS")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 0.9
                                }

                                RaohaneSurface {
                                    Layout.preferredWidth: monitorCount.implicitWidth + 16
                                    Layout.preferredHeight: 24
                                    surfaceRadius: 8
                                    raised: false
                                    showSheen: false
                                    border.color: RaohaneTheme.borderFaint

                                    Text {
                                        id: monitorCount
                                        anchors.centerIn: parent
                                        text: String(RaohaneMonitorManager.monitors.length)
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }

                            Flickable {
                                id: monitorFlick
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                contentWidth: width
                                contentHeight: monitorColumn.implicitHeight
                                clip: true
                                boundsBehavior: Flickable.StopAtBounds

                                ScrollBar.vertical: ScrollBar {
                                    policy: ScrollBar.AsNeeded
                                    width: 4
                                    contentItem: Rectangle {
                                        implicitWidth: 4
                                        radius: 2
                                        color: RaohaneTheme.accent
                                        opacity: 0.38
                                    }
                                }

                                Column {
                                    id: monitorColumn
                                    width: parent.width - 6
                                    spacing: 6

                                    Repeater {
                                        model: RaohaneMonitorManager.monitors

                                        delegate: RaohaneSurface {
                                            id: monitorCard
                                            required property var modelData
                                            required property int index

                                            width: monitorColumn.width
                                            height: 78
                                            surfaceRadius: 12
                                            active: root.selectedIndex === index
                                            transparentIdle: !active && !hovered
                                            interactive: true
                                            hovered: monitorMouse.containsMouse || activeFocus
                                            pressed: monitorMouse.pressed
                                            showSheen: false
                                            hoverScale: 1
                                            pressedScale: 1
                                            activeFocusOnTab: true
                                            border.color: active ? RaohaneTheme.accentBorder
                                                : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
                                            color: active ? RaohaneTheme.surfaceRaised
                                                : hovered ? RaohaneTheme.surfaceSubtle : RaohaneTheme.surfaceDeep

                                            Rectangle {
                                                anchors {
                                                    left: parent.left
                                                    top: parent.top
                                                    bottom: parent.bottom
                                                    leftMargin: 2
                                                    topMargin: 11
                                                    bottomMargin: 11
                                                }
                                                width: 3
                                                radius: 2
                                                color: RaohaneTheme.accent
                                                opacity: monitorCard.active ? 1 : monitorCard.hovered ? 0.42 : 0
                                            }

                                            ColumnLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 13
                                                anchors.rightMargin: 10
                                                anchors.topMargin: 9
                                                anchors.bottomMargin: 9
                                                spacing: 2

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 7

                                                    RaohaneIcon {
                                                        text: "monitor"
                                                        iconSize: 15
                                                        fill: monitorCard.active ? 1 : 0
                                                        color: monitorCard.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                                    }

                                                    Text {
                                                        Layout.fillWidth: true
                                                        text: monitorCard.modelData.name
                                                        color: RaohaneTheme.text
                                                        font.pixelSize: 10
                                                        font.weight: Font.DemiBold
                                                        elide: Text.ElideRight
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
                                                    font.pixelSize: 8
                                                    elide: Text.ElideRight
                                                }
                                            }

                                            MouseArea {
                                                id: monitorMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onPressed: monitorCard.forceActiveFocus()
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
                                font.pixelSize: 9
                                lineHeight: 1.15
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
                        id: settingsFlick
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        contentWidth: width
                        contentHeight: settingsColumn.implicitHeight + 36
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        flickDeceleration: 2600

                        ScrollBar.vertical: ScrollBar {
                            policy: ScrollBar.AsNeeded
                            width: 4
                            contentItem: Rectangle {
                                implicitWidth: 4
                                radius: 2
                                color: RaohaneTheme.accent
                                opacity: 0.42
                            }
                        }

                        Column {
                            id: settingsColumn
                            width: Math.min(parent.width - 44, 740)
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 16
                            spacing: 10

                            RowLayout {
                                width: parent.width
                                height: 52
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 3
                                    Layout.preferredHeight: 34
                                    radius: 2
                                    color: RaohaneTheme.accent
                                    opacity: root.selectedMonitor ? 0.82 : 0.20
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.selectedMonitor
                                            ? (root.selectedMonitor.description || root.selectedMonitor.name)
                                            : qsTr("Select a display")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.selectedMonitor
                                            ? qsTr("Changes are tested for 15 seconds before being saved by Raohane.")
                                            : qsTr("Connect a display or refresh the monitor list.")
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                    }
                                }
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
                                height: root.draftAutoPosition ? 66 : 106
                                surfaceRadius: 12
                                raised: false
                                showSheen: false
                                color: RaohaneTheme.surfaceDeep
                                border.color: RaohaneTheme.borderFaint

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 11
                                    anchors.topMargin: 9
                                    anchors.bottomMargin: 9
                                    spacing: 7

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 10

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 1

                                            Text {
                                                text: qsTr("Automatic position")
                                                color: RaohaneTheme.text
                                                font.pixelSize: 10
                                                font.weight: Font.DemiBold
                                            }

                                            Text {
                                                Layout.fillWidth: true
                                                text: qsTr("Let Hyprland place this output automatically")
                                                color: RaohaneTheme.textFaint
                                                font.pixelSize: 8
                                                elide: Text.ElideRight
                                            }
                                        }

                                        RaohaneSwitch {
                                            Layout.preferredWidth: 42
                                            Layout.preferredHeight: 24
                                            checked: root.draftAutoPosition
                                            enabled: false
                                        }

                                        MouseArea {
                                            Layout.preferredWidth: 42
                                            Layout.fillHeight: true
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
                                height: 38
                                spacing: 8

                                ActionButton {
                                    Layout.preferredWidth: 144
                                    title: qsTr("Test changes")
                                    icon: "check"
                                    primary: true
                                    enabled: !!root.selectedMonitor && !RaohaneMonitorManager.pending
                                    onTriggered: RaohaneMonitorManager.applyTemporary(root.draftConfiguration())
                                }

                                ActionButton {
                                    Layout.preferredWidth: 126
                                    title: qsTr("Preferred")
                                    icon: "restart_alt"
                                    enabled: !!root.selectedMonitor && !RaohaneMonitorManager.pending
                                    onTriggered: RaohaneMonitorManager.resetToPreferred(root.selectedMonitor.name)
                                }

                                Item { Layout.fillWidth: true }

                                ActionButton {
                                    visible: RaohaneMonitorManager.monitors.length > 1
                                    Layout.preferredWidth: 116
                                    title: root.selectedMonitor?.dpmsStatus ? qsTr("Sleep") : qsTr("Wake")
                                    icon: root.selectedMonitor?.dpmsStatus ? "bedtime" : "light_mode"
                                    enabled: !!root.selectedMonitor
                                    onTriggered: RaohaneMonitorManager.dpms(root.selectedMonitor.name, !root.selectedMonitor.dpmsStatus)
                                }
                            }

                            RaohaneSurface {
                                visible: RaohaneMonitorManager.pending
                                width: parent.width
                                height: 68
                                surfaceRadius: 12
                                active: true
                                showSheen: false
                                border.color: RaohaneTheme.accentBorder

                                Rectangle {
                                    anchors {
                                        left: parent.left
                                        top: parent.top
                                        bottom: parent.bottom
                                        leftMargin: 2
                                        topMargin: 11
                                        bottomMargin: 11
                                    }
                                    width: 3
                                    radius: 2
                                    color: RaohaneTheme.accent
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    RaohaneIcon {
                                        text: "timer"
                                        iconSize: 18
                                        fill: 1
                                        color: RaohaneTheme.accent
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: qsTr("Keep these display settings?")
                                            color: RaohaneTheme.text
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            text: qsTr("Reverting automatically in %1 seconds").arg(RaohaneMonitorManager.revertSeconds)
                                            color: RaohaneTheme.textFaint
                                            font.pixelSize: 8
                                        }
                                    }

                                    ActionButton {
                                        Layout.preferredWidth: 86
                                        title: qsTr("Keep")
                                        icon: "check"
                                        primary: true
                                        onTriggered: RaohaneMonitorManager.confirmTemporary()
                                    }

                                    ActionButton {
                                        Layout.preferredWidth: 90
                                        title: qsTr("Revert")
                                        icon: "undo"
                                        onTriggered: RaohaneMonitorManager.revertTemporary()
                                    }
                                }
                            }

                            Text {
                                visible: RaohaneMonitorManager.errorMessage.length > 0
                                width: parent.width
                                text: RaohaneMonitorManager.errorMessage
                                color: RaohaneTheme.critical
                                font.pixelSize: 9
                                lineHeight: 1.15
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

    component HeaderAction: RaohaneSurface {
        id: headerAction
        required property string icon
        required property string label
        signal triggered()

        implicitWidth: headerRow.implicitWidth + 20
        implicitHeight: 34
        surfaceRadius: 10
        transparentIdle: !hovered
        showSheen: false
        interactive: true
        hovered: headerMouse.containsMouse || activeFocus
        pressed: headerMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity
        border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Row {
            id: headerRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: headerAction.icon
                iconSize: 14
                color: headerAction.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: headerAction.label
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: headerMouse
            anchors.fill: parent
            enabled: headerAction.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: headerAction.forceActiveFocus()
            onClicked: headerAction.triggered()
        }
    }

    component ChoiceStepper: RaohaneSurface {
        id: choice

        required property string label
        required property string detail
        required property string value
        signal previous()
        signal next()

        height: 62
        surfaceRadius: 12
        raised: false
        showSheen: false
        color: RaohaneTheme.surfaceDeep
        border.color: RaohaneTheme.borderFaint
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 9
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: choice.label
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: choice.detail
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            RaohaneSurface {
                Layout.preferredWidth: 226
                Layout.preferredHeight: 36
                surfaceRadius: 10
                raised: false
                showSheen: false
                color: RaohaneTheme.surfaceSubtle
                border.color: RaohaneTheme.borderFaint

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 3
                    anchors.rightMargin: 3
                    spacing: 2

                    RaohaneIconButton {
                        buttonSize: 29
                        iconSize: 13
                        icon: "chevron_left"
                        transparentIdle: true
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        onClicked: choice.previous()
                    }

                    Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: choice.value
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    RaohaneIconButton {
                        buttonSize: 29
                        iconSize: 13
                        icon: "chevron_right"
                        transparentIdle: true
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        onClicked: choice.next()
                    }
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

        height: 36
        surfaceRadius: 10
        raised: false
        showSheen: false
        color: RaohaneTheme.surfaceSubtle
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 3
            spacing: 3

            Text {
                text: positionControl.axis
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 12
                icon: "remove"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: positionControl.decrease()
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: String(positionControl.value)
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 12
                icon: "add"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: positionControl.increase()
            }
        }
    }

    component ActionButton: RaohaneSurface {
        id: action
        required property string title
        required property string icon
        property bool primary: false
        signal triggered()

        Layout.preferredHeight: 36
        surfaceRadius: 10
        active: primary
        transparentIdle: !primary && !hovered
        showSheen: false
        interactive: true
        hovered: actionMouse.containsMouse || activeFocus
        pressed: actionMouse.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity
        border.color: primary ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Row {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: action.icon
                iconSize: 14
                fill: action.primary || action.hovered ? 1 : 0
                symbolWeight: action.primary ? 550 : action.hovered ? 500 : 420
                color: action.primary ? RaohaneTheme.accent
                    : action.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
            }

            Text {
                text: action.title
                color: action.primary ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            enabled: action.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: action.forceActiveFocus()
            onClicked: action.triggered()
        }
    }
}
