import Quickshell
import Quickshell.Io

import qs.modules.raohane.services

// Resident control plane for shell surfaces whose presentation is loaded on
// demand. IPC and compositor shortcuts live here so a closed surface never
// needs to remain instantiated merely to open itself again.
Scope {
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
}
