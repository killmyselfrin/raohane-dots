pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.config

Scope {
    id: root

    readonly property var activeLayout: RaohaneBarModuleRegistry.sanitizeLayout(
        RaohaneBarModuleRegistry.defaultVerticalLayout,
        "vertical"
    )
    readonly property bool showDateConfigured: RaohaneConfig.barShowDate

    function togglePrimarySurface(surfaceId: string): void {
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
            implicitWidth: 72
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            property bool superShow: false
            readonly property bool autoHide: RaohaneConfig.barAutoHide
            readonly property bool mustShow: !autoHide || hoverRegion.containsMouse || superShow
            readonly property var hyprMonitor: Hyprland.monitorFor(barWindow.screen)
            readonly property bool monitorHasFullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false
            readonly property bool monitorHasSpecialOpen: (hyprMonitor?.lastIpcObject?.specialWorkspace?.name ?? "") !== ""
            readonly property bool effectiveFullscreen: monitorHasFullscreen && !monitorHasSpecialOpen
            readonly property bool fullscreenSuppressed: effectiveFullscreen && !superShow

            visible: RaohaneState.barOpen && !RaohaneState.screenLocked && !fullscreenSuppressed
            exclusiveZone: fullscreenSuppressed
                ? 0
                : (autoHide && (!mustShow || !RaohaneConfig.barAutoHidePushWindows))
                    ? 0
                    : implicitWidth

            anchors {
                top: true
                bottom: true
                left: true
            }

            WlrLayershell.namespace: "quickshell:raohane-vertical-bar"
            WlrLayershell.layer: (monitorHasFullscreen && (monitorHasSpecialOpen || superShow))
                ? WlrLayer.Overlay
                : WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

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
                width: 62
                height: parent.height
                x: barWindow.mustShow ? 5 : -width - 3

                Behavior on x {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeEmphasized
                    }
                }

                RaohaneSurface {
                    id: verticalSurface
                    anchors {
                        fill: parent
                        topMargin: 8
                        bottomMargin: 8
                    }
                    surfaceRadius: RaohaneTheme.radiusLarge
                    raised: true
                    showSheen: false
                    border.color: RaohaneTheme.borderStrong

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 7
                        spacing: 6

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Repeater {
                                model: root.activeLayout.left

                                delegate: RaohaneBarModule {
                                    required property var modelData

                                    moduleId: String(modelData)
                                    orientation: "vertical"
                                    screen: barWindow.screen
                                    parentWindow: barWindow
                                    hostActive: barWindow.visible
                                    showDate: root.showDateConfigured
                                    primaryAction: root.togglePrimarySurface
                                    transientAction: root.toggleTransientSurface
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Repeater {
                                model: root.activeLayout.center

                                delegate: RaohaneBarModule {
                                    required property var modelData

                                    moduleId: String(modelData)
                                    orientation: "vertical"
                                    screen: barWindow.screen
                                    parentWindow: barWindow
                                    hostActive: barWindow.visible
                                    showDate: root.showDateConfigured
                                    primaryAction: root.togglePrimarySurface
                                    transientAction: root.toggleTransientSurface
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }

                        Item { Layout.fillHeight: true }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Repeater {
                                model: root.activeLayout.right

                                delegate: RaohaneBarModule {
                                    required property var modelData

                                    moduleId: String(modelData)
                                    orientation: "vertical"
                                    screen: barWindow.screen
                                    parentWindow: barWindow
                                    hostActive: barWindow.visible
                                    showDate: root.showDateConfigured
                                    primaryAction: root.togglePrimarySurface
                                    transientAction: root.toggleTransientSurface
                                    Layout.alignment: Qt.AlignHCenter
                                }
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
        function mode(): string { return "vertical" }
    }

    CompositorGlobalShortcut {
        name: "barToggle"
        description: "Toggles the Raohane bar"
        onPressed: RaohaneState.barOpen = !RaohaneState.barOpen
    }
}
