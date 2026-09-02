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

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:raohane-desktop-widgets"
        WlrLayershell.layer: WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
        anchors { top: true; bottom: true; left: true; right: true }

        RaohaneDesktopWidgets {
            anchors.fill: parent
            screen: desktopWindow.modelData
            shown: desktopWindow.canvasVisible
        }
    }
}
