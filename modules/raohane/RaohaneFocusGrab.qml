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
        if (window && root.dismissable.indexOf(window) < 0)
            root.dismissable = [...root.dismissable, window]
    }

    function removeDismissable(window): void {
        root.dismissable = root.dismissable.filter(item => item !== window)
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
