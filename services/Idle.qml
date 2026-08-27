pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick

import qs.modules.raohane.services

// Temporary compatibility facade for inherited consumers. RaohaneIdle owns
// the actual Wayland inhibition backend; this service only preserves the old API.
Singleton {
    id: root

    property bool inhibit: RaohaneIdle.inhibit
    property bool syncing: false

    function toggleInhibit(active = null): void {
        if (active !== null)
            RaohaneIdle.setInhibit(Boolean(active))
        else
            RaohaneIdle.toggleInhibit()
    }

    onInhibitChanged: {
        if (!root.syncing && root.inhibit !== RaohaneIdle.inhibit)
            RaohaneIdle.setInhibit(root.inhibit)
    }

    Connections {
        target: RaohaneIdle
        function onInhibitChanged(): void {
            root.syncing = true
            root.inhibit = RaohaneIdle.inhibit
            root.syncing = false
        }
    }
}
