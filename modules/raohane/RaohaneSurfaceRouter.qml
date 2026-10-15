import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.services

// Resident control plane for shell surfaces whose presentation is loaded on
// demand. IPC, compositor shortcuts and cross-lifetime transaction handoffs
// live here so a closed surface never needs to remain instantiated merely to
// open itself again.
Scope {
    id: root

    function startScreenTranslation(): void {
        if (!RaohaneScreenTranslation.start())
            return
        RaohaneState.setPrimaryOpen("screenTranslator", false)
    }

    IpcHandler {
        target: "raohaneLauncher"

        function toggle(): void { RaohaneState.togglePrimary("launcher") }
        function open(): void { RaohaneState.setPrimaryOpen("launcher", true) }
        function close(): void { RaohaneState.setPrimaryOpen("launcher", false) }
    }

    IpcHandler {
        target: "search"

        function toggle(): void { RaohaneState.togglePrimary("overview") }
        function workspacesToggle(): void { RaohaneState.togglePrimary("overview") }
        function close(): void { RaohaneState.setPrimaryOpen("overview", false) }
        function open(): void { RaohaneState.setPrimaryOpen("overview", true) }
        function clipboardToggle(): void {
            RaohaneSearch.query = ":"
            RaohaneState.setPrimaryOpen("launcher", true)
        }
    }

    IpcHandler {
        target: "taskManager"

        function toggle(): void { RaohaneState.togglePrimary("taskManager") }
        function open(): void { RaohaneState.setPrimaryOpen("taskManager", true) }
        function close(): void { RaohaneState.setPrimaryOpen("taskManager", false) }
        function refresh(): void { RaohaneProcesses.refresh() }
    }

    IpcHandler {
        target: "sidebarRight"

        function toggle(): void { RaohaneState.togglePrimary("controlCenter") }
        function open(): void { RaohaneState.setPrimaryOpen("controlCenter", true) }
        function close(): void { RaohaneState.setPrimaryOpen("controlCenter", false) }
    }

    IpcHandler {
        target: "settings"

        function toggle(): void { RaohaneState.togglePrimary("settings") }
        function open(): void { RaohaneState.setPrimaryOpen("settings", true) }
        function close(): void { RaohaneState.setPrimaryOpen("settings", false) }
        function status(): string { return RaohaneState.settingsOpen ? "open" : "closed" }
        function page(page: string): void { RaohaneSettingsRouter.request(page, "") }
    }

    IpcHandler {
        target: "sidebarLeft"

        function toggle(): void { RaohaneState.togglePrimary("leftSidebar") }
        function open(): void { RaohaneState.setPrimaryOpen("leftSidebar", true) }
        function close(): void { RaohaneState.setPrimaryOpen("leftSidebar", false) }
    }

    IpcHandler {
        target: "screenTranslator"

        function translate(): void { root.startScreenTranslation() }
        function open(): void { RaohaneState.setPrimaryOpen("screenTranslator", true) }
        function close(): void { RaohaneState.setPrimaryOpen("screenTranslator", false) }
    }

    Connections {
        target: RaohaneScreenTranslation

        function onTranslationFinished(): void {
            RaohaneState.setPrimaryOpen("screenTranslator", true)
        }
    }

    CompositorGlobalShortcut {
        name: "raohaneLauncherToggle"
        description: "Toggles the Raohane launcher"
        onPressed: RaohaneState.togglePrimary("launcher")
    }

    CompositorGlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Close Raohane workspace overview"
        onPressed: RaohaneState.setPrimaryOpen("overview", false)
    }

    CompositorGlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggle Raohane workspace overview"
        onPressed: RaohaneState.togglePrimary("overview")
    }

    CompositorGlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Open clipboard search in Raohane launcher"
        onPressed: {
            RaohaneSearch.query = ":"
            RaohaneState.setPrimaryOpen("launcher", true)
        }
    }

    CompositorGlobalShortcut {
        name: "taskManagerToggle"
        description: "Toggle the Raohane Task Manager"
        onPressed: RaohaneState.togglePrimary("taskManager")
    }

    CompositorGlobalShortcut {
        name: "sidebarRightToggle"
        description: "Toggles Raohane control center"
        onPressed: RaohaneState.togglePrimary("controlCenter")
    }

    CompositorGlobalShortcut {
        name: "settingsToggle"
        description: "Toggles Raohane settings"
        onPressed: RaohaneState.togglePrimary("settings")
    }

    CompositorGlobalShortcut {
        name: "sidebarLeftToggle"
        description: "Toggle the Raohane left sidebar"
        onPressed: RaohaneState.togglePrimary("leftSidebar")
    }

    CompositorGlobalShortcut {
        name: "screenTranslate"
        description: "Select a region and translate its text with Raohane"
        onPressed: root.startScreenTranslation()
    }
}
