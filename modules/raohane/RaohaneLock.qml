pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// Raohane-owned secure session lock. The compositor lock contract and PAM
// transaction live entirely in the native module; legacy LockScreen/LockSurface
// are no longer needed by the active panel family.
Scope {
    id: root

    property alias context: lockContext

    function lock(): void {
        RaohaneState.closeTransientSurfaces()
        if (!RaohaneState.screenLocked)
            RaohaneState.screenLocked = true
    }

    function unlock(): void {
        RaohaneState.screenLocked = false
        lockContext.reset()
    }

    RaohaneLockContext {
        id: lockContext

        onUnlocked: root.unlock()
    }

    Component {
        id: lockSurfaceComponent

        WlSessionLockSurface {
            color: "transparent"

            RaohaneLockSurface {
                anchors.fill: parent
                context: lockContext
            }
        }
    }

    WlSessionLock {
        id: sessionLock
        locked: RaohaneState.screenLocked
        surface: lockSurfaceComponent
    }

    Connections {
        target: RaohaneState

        function onScreenLockedChanged(): void {
            if (RaohaneState.screenLocked) {
                lockContext.reset()
                lockContext.refreshFingerprints()
                refocusTimer.restart()
            } else {
                lockContext.reset()
            }
        }
    }

    Timer {
        id: refocusTimer
        interval: 120
        repeat: false
        onTriggered: lockContext.shouldRefocus()
    }

    IpcHandler {
        target: "lock"

        function activate(): void { root.lock() }
        function focus(): void { lockContext.shouldRefocus() }
        function status(): string { return RaohaneState.screenLocked ? "locked" : "unlocked" }
    }

    CompositorGlobalShortcut {
        name: "lock"
        description: "Locks the Raohane session"
        onPressed: root.lock()
    }

    CompositorGlobalShortcut {
        name: "lockFocus"
        description: "Restores keyboard focus to the Raohane lock screen"
        onPressed: lockContext.shouldRefocus()
    }
}
