pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland

// Raohane-owned shared focus/dismiss coordinator for overlay surfaces.
// Hyprland is the product compositor, so no compositor abstraction is needed.
Singleton {
    id: root

    signal dismissed()

    property var persistent: []
    property var dismissable: []

    function dismiss(): void {
        root.dismissable = []
        root.dismissed()
    }

    function addPersistent(window): void {
        if (window && root.persistent.indexOf(window) < 0)
            root.persistent = [...root.persistent, window]
    }

    function removePersistent(window): void {
        root.persistent = root.persistent.filter(item => item !== window)
    }

    function addDismissable(window): void {
        if (!window)
            return

        // The Control Center is a primary command surface, not a transient
        // popup. Screenshot/region-selection tools temporarily take compositor
        // focus; registering the panel in HyprlandFocusGrab makes that look like
        // an outside click and closes it before it can be captured. Keep the
        // panel outside the transient grab while it is the active primary
        // surface. It still closes through its own close button, IPC shortcut,
        // or when another primary Raohane surface is opened.
        if (RaohaneState.controlCenterOpen) {
            root.addPersistent(window)
            return
        }

        if (root.dismissable.indexOf(window) < 0)
            root.dismissable = [...root.dismissable, window]
    }

    function removeDismissable(window): void {
        root.dismissable = root.dismissable.filter(item => item !== window)
        root.removePersistent(window)
    }

    function hasActive(element): bool {
        if (!element)
            return false
        if (element.activeFocus)
            return true
        return Array.from(element.children ?? []).some(child => root.hasActive(child))
    }

    HyprlandFocusGrab {
        id: grab
        windows: root.dismissable.every(window => !window?.focusable)
            || root.dismissable.some(window => root.hasActive(window?.contentItem))
            ? [...root.dismissable, ...root.persistent]
            : [...root.dismissable]
        active: root.dismissable.length > 0
        onCleared: root.dismiss()
    }
}
