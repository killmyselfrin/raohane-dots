pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property bool inhibit: false

    function setInhibit(active: bool): void {
        root.inhibit = Boolean(active)
    }

    function toggleInhibit(): void {
        root.inhibit = !root.inhibit
    }

    IdleInhibitor {
        enabled: root.inhibit
        window: PanelWindow {
            implicitWidth: 0
            implicitHeight: 0
            color: "transparent"
            anchors {
                right: true
                bottom: true
            }
            mask: Region { item: null }
        }
    }
}
