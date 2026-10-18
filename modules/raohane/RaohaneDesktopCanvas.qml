pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config

Variants {
    id: root
    model: Quickshell.screens

    PanelWindow {
        id: desktopWindow
        required property var modelData
        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        readonly property list<HyprlandWorkspace> monitorWorkspaces: Hyprland.workspaces.values.filter(workspace =>
            workspace.monitor && desktopWindow.monitor && workspace.monitor.name === desktopWindow.monitor.name)
        readonly property bool fullscreenActive: monitorWorkspaces.some(workspace =>
            workspace.active && workspace.toplevels.values.some(window => window.wayland?.fullscreen))
        readonly property bool canvasVisible: RaohaneConfig.desktopWidgetsEnabled
            && !RaohaneState.screenLocked
            && !(RaohaneConfig.wallpaperHideWhenFullscreen && fullscreenActive)
        readonly property bool editInputEnabled: canvasVisible && !fullscreenActive
            && RaohaneState.desktopWidgetEditMode
            && RaohaneState.desktopWidgetEditScreenName === String(modelData.name)

        onFullscreenActiveChanged: {
            if (fullscreenActive && editInputEnabled)
                RaohaneState.desktopWidgetEditMode = false
        }
        onEditInputEnabledChanged: {
            if (editInputEnabled)
                Qt.callLater(() => desktopWidgets.forceActiveFocus())
        }

        Connections {
            target: RaohaneState
            function onScreenLockedChanged(): void {
                if (RaohaneState.screenLocked)
                    RaohaneState.desktopWidgetEditMode = false
            }
        }

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:raohane-desktop-widgets"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: desktopWindow.editInputEnabled ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        // Keep unoccupied wallpaper click-through. Only existing widget
        // faces receive pointer events (right-click for context actions).
        mask: Region {
            // While editing, the whole desktop accepts drag operations.
            // Leaving edit mode restores the exact original widget-only mask.
            Region {
                x: 0
                y: 0
                width: desktopWindow.editInputEnabled ? desktopWindow.width : 0
                height: desktopWindow.editInputEnabled ? desktopWindow.height : 0
            }
            Region {
                x: desktopWidgets.primaryHitRect.x
                y: desktopWidgets.primaryHitRect.y
                width: desktopWidgets.primaryHitRect.width
                height: desktopWidgets.primaryHitRect.height
            }
            Region {
                x: desktopWidgets.secondaryHitRect.x
                y: desktopWidgets.secondaryHitRect.y
                width: desktopWidgets.secondaryHitRect.width
                height: desktopWidgets.secondaryHitRect.height
            }
            Region {
                x: desktopWidgets.freeHitRect("clock").x
                y: desktopWidgets.freeHitRect("clock").y
                width: desktopWidgets.freeHitRect("clock").width
                height: desktopWidgets.freeHitRect("clock").height
            }
            Region {
                x: desktopWidgets.freeHitRect("context").x
                y: desktopWidgets.freeHitRect("context").y
                width: desktopWidgets.freeHitRect("context").width
                height: desktopWidgets.freeHitRect("context").height
            }
            Region {
                x: desktopWidgets.freeHitRect("system").x
                y: desktopWidgets.freeHitRect("system").y
                width: desktopWidgets.freeHitRect("system").width
                height: desktopWidgets.freeHitRect("system").height
            }
            Region {
                x: desktopWidgets.freeHitRect("motto").x
                y: desktopWidgets.freeHitRect("motto").y
                width: desktopWidgets.freeHitRect("motto").width
                height: desktopWidgets.freeHitRect("motto").height
            }
        }

        RaohaneDesktopWidgets {
            id: desktopWidgets
            anchors.fill: parent
            screen: desktopWindow.modelData
            shown: desktopWindow.canvasVisible
        }
    }
}
