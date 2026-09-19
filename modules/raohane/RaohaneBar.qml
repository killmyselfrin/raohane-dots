pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var activeLayout: RaohaneBarModuleRegistry.sanitizeLayout(
        RaohaneConfig.barModuleLayout,
        "horizontal"
    )
    readonly property bool showDateConfigured: RaohaneConfig.barShowDate
    readonly property bool contextConfigured: root.activeLayout.left.includes("context")
        || root.activeLayout.center.includes("context")
        || root.activeLayout.right.includes("context")

    function styleValue(key: string, fallback): var {
        const style = RaohaneConfig.style
        if (!style || !Object.prototype.hasOwnProperty.call(style, key))
            return fallback
        return style[key]
    }

    function togglePrimarySurface(surfaceId: string): void {
        if (surfaceId === "controlCenter") {
            RaohaneState.togglePrimary("controlCenter")
            return
        }
        RaohaneState.togglePrimary(surfaceId)
    }

    function toggleTransientSurface(surfaceId: string): void {
        RaohaneState.toggleSurface(surfaceId)
    }

    Variants {
        model: {
            const screens = Quickshell.screens
            const configured = RaohaneConfig.barScreenList
            if (!configured || configured.length === 0)
                return screens
            return screens.filter(screen => configured.includes(screen.name))
        }

        PanelWindow {
            id: barWindow
            required property ShellScreen modelData

            screen: modelData
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            implicitHeight: Math.max(40, barWindow.podHeight + barWindow.outerGap * 2)

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool contextAttention: root.contextConfigured
                && (RaohaneContext.mode === "event"
                    || RaohaneContext.mode === "recording"
                    || RaohaneContext.mode === "privacy")
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow || contextAttention
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
            readonly property bool effectiveFullscreen: monitorHasFullscreen && !monitorHasSpecialOpen
            readonly property bool fullscreenSuppressed: effectiveFullscreen && !superShow
            readonly property bool contentShown: !fullscreenSuppressed && mustShow
            readonly property int podHeight: Math.max(34, Math.min(64, Math.round(RaohaneConfig.barHeight)))
            readonly property string surfaceStyle: RaohaneConfig.barSurfaceStyle
            readonly property string groupStyle: RaohaneConfig.barGroupStyle
            readonly property int edgeMargin: Math.max(0, Math.round(RaohaneConfig.barEdgeMargin * RaohaneTheme.densityScale))
            readonly property int effectiveEdgeMargin: surfaceStyle === "hug" || surfaceStyle === "panel" ? 0 : edgeMargin
            readonly property int outerGap: surfaceStyle === "hug" || surfaceStyle === "panel" ? 0 : 6
            readonly property int podRadius: Math.max(0, Math.min(Math.round(RaohaneConfig.barRadius), Math.floor(podHeight / 2)))
            readonly property int effectiveRadius: surfaceStyle === "hug" ? Math.min(10, podRadius) : podRadius
            readonly property int moduleSpacing: Math.max(0, Math.round(RaohaneConfig.barModuleSpacing))
            readonly property int effectiveModuleSpacing: groupStyle === "segmented" ? 1 : moduleSpacing
            readonly property int horizontalPadding: Math.max(2, Math.round(RaohaneConfig.barHorizontalPadding))
            readonly property bool zoneBackgroundVisible: RaohaneConfig.barShowBackground
                && surfaceStyle !== "panel"
                && groupStyle === "pills"
            readonly property bool surfaceMotionAllowed: RaohaneMotion.transformMotionEnabled
                && !RaohanePerformance.gameModeActive

            // Keep the layer-shell surface alive across fullscreen transitions.
            // Hiding/recreating the window itself could leave the bar missing
            // after games changed fullscreen state. A zero-sized input mask makes
            // the resident transparent surface fully click-through while hidden.
            visible: RaohaneState.barOpen && !RaohaneState.screenLocked
            mask: Region {
                width: barWindow.fullscreenSuppressed ? 0 : barWindow.width
                height: barWindow.fullscreenSuppressed ? 0 : barWindow.height
            }
            exclusiveZone: fullscreenSuppressed
                ? 0
                : (autoHide && (!mustShow || !RaohaneConfig.barAutoHidePushWindows))
                    ? 0
                    : implicitHeight

            WlrLayershell.namespace: "quickshell:raohane-bar"
            WlrLayershell.layer: (monitorHasFullscreen && (monitorHasSpecialOpen || superShow))
                ? WlrLayer.Overlay
                : WlrLayer.Top

            anchors {
                top: !RaohaneConfig.barBottom
                bottom: RaohaneConfig.barBottom
                left: true
                right: true
            }

            Timer {
                id: superRevealTimer
                interval: RaohaneConfig.barShowOnSuperDelay
                repeat: false
                onTriggered: barWindow.superShow = true
            }

            Connections {
                target: RaohaneState
                function onSuperDownChanged(): void {
                    if (!RaohaneConfig.barShowOnSuper)
                        return
                    if (RaohaneState.superDown) {
                        superRevealTimer.restart()
                    } else {
                        superRevealTimer.stop()
                        barWindow.superShow = false
                    }
                }
            }

            MouseArea {
                id: hoverRegion
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            Item {
                id: barContent
                width: parent.width
                height: barWindow.implicitHeight
                y: {
                    if (barWindow.contentShown)
                        return RaohaneConfig.barBottom
                            ? barWindow.height - height - barWindow.outerGap
                            : barWindow.outerGap
                    return RaohaneConfig.barBottom ? barWindow.height + 2 : -height - 4
                }

                Behavior on y {
                    enabled: barWindow.surfaceMotionAllowed
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeEmphasized
                    }
                }

                RaohaneSurface {
                    id: panelSurface
                    visible: RaohaneConfig.barShowBackground && barWindow.surfaceStyle === "panel"
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    height: barWindow.podHeight
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: RaohaneConfig.barOpacity
                    raised: RaohaneConfig.barShadow
                    showSheen: false
                    border.color: RaohaneTheme.border
                }

                RaohaneSurface {
                    id: leftIsland
                    visible: root.activeLayout.left.length > 0
                    anchors {
                        left: parent.left
                        leftMargin: barWindow.effectiveEdgeMargin
                        verticalCenter: parent.verticalCenter
                    }
                    width: visible
                        ? Math.min(parent.width * 0.38, Math.max(48, leftRow.implicitWidth + 18))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: RaohaneConfig.barOpacity
                    raised: RaohaneConfig.barShadow
                    transparentIdle: !barWindow.zoneBackgroundVisible
                    showSheen: false
                    border.color: barWindow.zoneBackgroundVisible ? RaohaneTheme.border : "transparent"

                    RowLayout {
                        id: leftRow
                        anchors {
                            fill: parent
                            leftMargin: barWindow.horizontalPadding
                            rightMargin: barWindow.horizontalPadding
                        }
                        spacing: barWindow.effectiveModuleSpacing

                        Repeater {
                            model: root.activeLayout.left

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible && !barWindow.fullscreenSuppressed
                                showDate: root.showDateConfigured
                                groupStyle: barWindow.groupStyle
                                showBackground: RaohaneConfig.barShowBackground
                                primaryAction: root.togglePrimarySurface
                                transientAction: root.toggleTransientSurface
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                RaohaneSurface {
                    id: centerIsland
                    visible: root.activeLayout.center.length > 0
                    anchors.centerIn: parent
                    width: visible
                        ? Math.min(parent.width * 0.42, Math.max(48, centerRow.implicitWidth + barWindow.horizontalPadding * 2))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: RaohaneConfig.barOpacity
                    raised: RaohaneConfig.barShadow
                    transparentIdle: !barWindow.zoneBackgroundVisible
                    showSheen: false
                    border.color: barWindow.zoneBackgroundVisible ? RaohaneTheme.border : "transparent"

                    RowLayout {
                        id: centerRow
                        anchors {
                            fill: parent
                            leftMargin: barWindow.horizontalPadding
                            rightMargin: barWindow.horizontalPadding
                        }
                        spacing: barWindow.effectiveModuleSpacing

                        Repeater {
                            model: root.activeLayout.center

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible && !barWindow.fullscreenSuppressed
                                showDate: root.showDateConfigured
                                groupStyle: barWindow.groupStyle
                                showBackground: RaohaneConfig.barShowBackground
                                primaryAction: root.togglePrimarySurface
                                transientAction: root.toggleTransientSurface
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                RaohaneSurface {
                    id: rightIsland
                    visible: root.activeLayout.right.length > 0
                    anchors {
                        right: parent.right
                        rightMargin: barWindow.effectiveEdgeMargin
                        verticalCenter: parent.verticalCenter
                    }
                    width: visible
                        ? Math.min(parent.width * 0.40, Math.max(48, rightRow.implicitWidth + 18))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    surfaceRadius: barWindow.effectiveRadius
                    opacity: RaohaneConfig.barOpacity
                    raised: RaohaneConfig.barShadow
                    transparentIdle: !barWindow.zoneBackgroundVisible
                    showSheen: false
                    border.color: barWindow.zoneBackgroundVisible ? RaohaneTheme.border : "transparent"

                    RowLayout {
                        id: rightRow
                        anchors {
                            fill: parent
                            leftMargin: barWindow.horizontalPadding
                            rightMargin: barWindow.horizontalPadding
                        }
                        spacing: barWindow.effectiveModuleSpacing

                        Repeater {
                            model: root.activeLayout.right

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible && !barWindow.fullscreenSuppressed
                                showDate: root.showDateConfigured
                                groupStyle: barWindow.groupStyle
                                showBackground: RaohaneConfig.barShowBackground
                                primaryAction: root.togglePrimarySurface
                                transientAction: root.toggleTransientSurface
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"
        function toggle(): void { RaohaneState.barOpen = !RaohaneState.barOpen }
        function open(): void { RaohaneState.barOpen = true }
        function close(): void { RaohaneState.barOpen = false }
        function mode(): string { return "horizontal" }
    }

    CompositorGlobalShortcut {
        name: "barToggle"
        description: "Toggles the Raohane bar"
        onPressed: RaohaneState.barOpen = !RaohaneState.barOpen
    }
}
