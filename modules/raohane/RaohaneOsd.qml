import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property string currentIndicator: "volume"
    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var focusedHyprMonitor: Hyprland.monitorFor(root.focusedScreen)
    readonly property bool focusedFullscreen: focusedHyprMonitor?.activeWorkspace?.hasFullscreen ?? false
    readonly property bool focusedSpecialOpen: (focusedHyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
    readonly property bool barSuppressedByFullscreen: root.focusedFullscreen && !root.focusedSpecialOpen
    readonly property var horizontalBarLayout: RaohaneBarModuleRegistry.sanitizeLayout(
        RaohaneConfig.barModuleLayout,
        "horizontal"
    )
    readonly property bool contextModuleConfigured: root.horizontalBarLayout.left.includes("context")
        || root.horizontalBarLayout.center.includes("context")
        || root.horizontalBarLayout.right.includes("context")
    readonly property var brightnessMonitor: RaohaneDisplay.getMonitorForScreen(focusedScreen)
    readonly property bool contextFeedbackAvailable: RaohaneConfig.contextIslandEnabled
        && root.contextModuleConfigured
        && RaohaneState.barOpen
        && !RaohaneConfig.barVertical
        && !RaohaneState.screenLocked
        && !root.barSuppressedByFullscreen

    readonly property real value: {
        if (currentIndicator === "brightness")
            return Math.max(0, Math.min(1, brightnessMonitor?.brightness ?? 0.5))
        if (currentIndicator === "gamma") {
            const lower = RaohaneDisplay.gammaLowerLimit / 100
            const current = RaohaneDisplay.gamma / 100
            if (lower >= 1)
                return current
            return Math.max(0, Math.min(1, (current - lower) / (1 - lower)))
        }
        return Math.max(0, Math.min(1, RaohaneAudio.volume))
    }

    readonly property string icon: currentIndicator === "brightness"
        ? (RaohaneDisplay.temperatureActive ? "routine" : "light_mode")
        : currentIndicator === "gamma"
            ? "wb_twilight"
            : (RaohaneAudio.muted ? "volume_off" : "volume_up")

    readonly property string label: currentIndicator === "brightness"
        ? qsTr("Brightness")
        : currentIndicator === "gamma"
            ? qsTr("Gamma")
            : qsTr("Volume")

    readonly property int percent: currentIndicator === "gamma"
        ? Math.round(RaohaneDisplay.gamma)
        : Math.round(value * 100)

    function trigger(indicator: string): void {
        if (indicator === "volume" && root.contextFeedbackAvailable) {
            RaohaneState.osdOpen = false
            hideTimer.stop()
            return
        }
        currentIndicator = indicator
        RaohaneState.osdOpen = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: RaohaneConfig.osdTimeout
        repeat: false
        onTriggered: RaohaneState.osdOpen = false
    }

    Connections {
        target: RaohaneDisplay
        function onBrightnessChanged(): void { root.trigger("brightness") }
        function onGammaChanged(): void { root.trigger("gamma") }
    }

    Connections {
        target: RaohaneAudio
        function onVolumeChanged(): void {
            if (RaohaneAudio.ready)
                root.trigger("volume")
        }
        function onMutedChanged(): void {
            if (RaohaneAudio.ready)
                root.trigger("volume")
        }
    }

    Loader {
        active: RaohaneState.osdOpen

        sourceComponent: PanelWindow {
            id: panelWindow

            screen: root.focusedScreen
            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: 304
            implicitHeight: 66

            WlrLayershell.namespace: "quickshell:raohane-osd"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: !RaohaneConfig.barBottom
                bottom: RaohaneConfig.barBottom
            }

            margins {
                top: RaohaneTheme.barHeight + 2 * RaohaneTheme.panelPadding
                bottom: RaohaneTheme.barHeight + 2 * RaohaneTheme.panelPadding
            }

            mask: Region { item: card }

            RaohaneSurface {
                id: card
                property bool entered: false

                width: 276
                height: 54
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: !RaohaneConfig.barBottom ? parent.top : undefined
                anchors.bottom: RaohaneConfig.barBottom ? parent.bottom : undefined
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: true
                showSheen: false
                idleBorderColor: RaohaneTheme.borderStrong
                showStateRail: true
                stateRailColor: RaohaneTheme.accent
                stateRailOpacity: 0.90
                stateRailWidth: 3
                stateRailLength: 36
                opacity: entered ? 1 : 0

                transform: Translate {
                    id: cardTranslate
                    y: card.entered ? 0 : (RaohaneConfig.barBottom ? 5 : -5)

                    Behavior on y {
                        NumberAnimation {
                            duration: RaohaneMotion.standard
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }
                }

                Component.onCompleted: entered = true

                Behavior on opacity {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeStandard
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                    onEntered: RaohaneState.osdOpen = false
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding + 1
                    anchors.rightMargin: RaohaneTheme.panelPadding + 1
                    spacing: RaohaneTheme.spacing + 1

                    RaohaneSurface {
                        Layout.preferredWidth: 32
                        Layout.preferredHeight: 32
                        surfaceRadius: RaohaneTheme.radius
                        raised: false
                        active: true
                        showSheen: false
                        showInnerRim: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.icon
                            iconSize: 18
                            fill: 1
                            symbolWeight: 540
                            color: root.currentIndicator === "volume" && RaohaneAudio.muted
                                ? RaohaneTheme.textFaint
                                : RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingTiny + 1

                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: root.label
                                color: RaohaneTheme.text
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }

                            Item { Layout.fillWidth: true }

                            Text {
                                text: root.percent + "%"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                font.weight: Font.DemiBold
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 4
                            radius: 2
                            color: RaohaneTheme.surfaceDeep
                            border.width: 1
                            border.color: RaohaneTheme.borderFaint

                            Rectangle {
                                width: parent.width * root.value
                                height: parent.height
                                radius: parent.radius
                                color: RaohaneTheme.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: RaohaneMotion.micro
                                        easing.type: RaohaneMotion.easeStandard
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "osdVolume"
        function trigger(): void { root.trigger("volume") }
        function hide(): void { RaohaneState.osdOpen = false }
        function toggle(): void { RaohaneState.osdOpen = !RaohaneState.osdOpen }
    }

    GlobalShortcut {
        name: "osdVolumeTrigger"
        description: "Triggers Raohane volume OSD"
        onPressed: root.trigger("volume")
    }

    GlobalShortcut {
        name: "osdVolumeHide"
        description: "Hides Raohane OSD"
        onPressed: RaohaneState.osdOpen = false
    }
}
