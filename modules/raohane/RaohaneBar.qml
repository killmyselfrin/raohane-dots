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
            implicitHeight: 64

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
            readonly property bool effectiveFullscreen: monitorHasFullscreen && !monitorHasSpecialOpen
            readonly property bool fullscreenSuppressed: effectiveFullscreen && !superShow
            readonly property real podScale: Number(root.styleValue("barScale", 1.0))
            readonly property int podHeight: Math.max(38, Math.min(48, Math.round(RaohaneTheme.barHeight * podScale)))
            readonly property int edgeMargin: Math.max(12, Math.round(16 * RaohaneTheme.densityScale))
            readonly property bool surfaceMotionAllowed: RaohaneMotion.transformMotionEnabled
                && !RaohanePerformance.gameModeActive

            visible: RaohaneState.barOpen && !RaohaneState.screenLocked && !fullscreenSuppressed
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
                height: 52
                y: {
                    if (barWindow.mustShow)
                        return RaohaneConfig.barBottom ? barWindow.height - height - 6 : 6
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
                    id: leftIsland
                    visible: root.activeLayout.left.length > 0
                    anchors {
                        left: parent.left
                        leftMargin: barWindow.edgeMargin
                        verticalCenter: parent.verticalCenter
                    }
                    width: visible
                        ? Math.min(parent.width * 0.38, Math.max(48, leftRow.implicitWidth + 18))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    surfaceRadius: Math.min(RaohaneTheme.radiusLarge, height / 2)
                    raised: true
                    showSheen: false
                    border.color: RaohaneTheme.border

                    RowLayout {
                        id: leftRow
                        anchors {
                            fill: parent
                            leftMargin: 6
                            rightMargin: 8
                        }
                        spacing: 5

                        Repeater {
                            model: root.activeLayout.left

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible
                                showDate: root.showDateConfigured
                                primaryAction: root.togglePrimarySurface
                                transientAction: root.toggleTransientSurface
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                RowLayout {
                    id: centerRow
                    visible: root.activeLayout.center.length > 0
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: root.activeLayout.center

                        delegate: RaohaneBarModule {
                            required property var modelData

                            moduleId: String(modelData)
                            screen: barWindow.screen
                            parentWindow: barWindow
                            hostActive: barWindow.visible
                            showDate: root.showDateConfigured
                            primaryAction: root.togglePrimarySurface
                            transientAction: root.toggleTransientSurface
                            Layout.alignment: Qt.AlignVCenter
                        }
                    }
                }

                RaohaneSurface {
                    id: rightIsland
                    visible: root.activeLayout.right.length > 0
                    anchors {
                        right: parent.right
                        rightMargin: barWindow.edgeMargin
                        verticalCenter: parent.verticalCenter
                    }
                    width: visible
                        ? Math.min(parent.width * 0.40, Math.max(48, rightRow.implicitWidth + 18))
                        : 0
                    height: visible ? barWindow.podHeight : 0
                    surfaceRadius: Math.min(RaohaneTheme.radiusLarge, height / 2)
                    raised: true
                    showSheen: false
                    border.color: RaohaneTheme.border

                    RowLayout {
                        id: rightRow
                        anchors {
                            fill: parent
                            leftMargin: 8
                            rightMargin: 6
                        }
                        spacing: 5

                        Repeater {
                            model: root.activeLayout.right

                            delegate: RaohaneBarModule {
                                required property var modelData

                                moduleId: String(modelData)
                                screen: barWindow.screen
                                parentWindow: barWindow
                                hostActive: barWindow.visible
                                showDate: root.showDateConfigured
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
