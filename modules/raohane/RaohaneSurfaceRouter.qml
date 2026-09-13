import Quickshell
import Quickshell.Io

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

    CompositorGlobalShortcut {
        name: "raohaneLauncherToggle"
        description: "Toggles the Raohane launcher"
        onPressed: RaohaneState.togglePrimary("launcher")
    }
}
