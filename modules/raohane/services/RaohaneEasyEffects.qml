pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool active: false

    function refresh(): void {
        root.fetchAvailability()
        root.fetchActiveState()
    }

    function fetchAvailability(): void {
        if (!availabilityProbe.running)
            availabilityProbe.running = true
    }

    function fetchActiveState(): void {
        if (!stateProbe.running)
            stateProbe.running = true
    }

    function launchUi(): void {
        Quickshell.execDetached([
            "bash", "-lc",
            "if command -v easyeffects >/dev/null 2>&1; then easyeffects; "
                + "elif command -v flatpak >/dev/null 2>&1; then flatpak run com.github.wwmm.easyeffects; fi"
        ])
    }

    function disable(): void {
        root.active = false
        Quickshell.execDetached([
            "bash", "-lc",
            "pkill -x easyeffects >/dev/null 2>&1 || flatpak kill com.github.wwmm.easyeffects >/dev/null 2>&1 || true"
        ])
        refreshTimer.restart()
    }

    function enable(): void {
        root.active = true
        Quickshell.execDetached([
            "bash", "-lc",
            "if command -v easyeffects >/dev/null 2>&1; then "
                + "easyeffects --hide-window --service-mode >/dev/null 2>&1 & "
                + "elif command -v flatpak >/dev/null 2>&1 && flatpak info com.github.wwmm.easyeffects >/dev/null 2>&1; then "
                + "flatpak run com.github.wwmm.easyeffects --hide-window --service-mode >/dev/null 2>&1 & fi"
        ])
        refreshTimer.restart()
    }

    function toggle(): void {
        if (root.active)
            root.disable()
        else
            root.enable()
    }

    Process {
        id: availabilityProbe
        command: [
            "bash", "-lc",
            "command -v easyeffects >/dev/null 2>&1 || "
                + "{ command -v flatpak >/dev/null 2>&1 && flatpak info com.github.wwmm.easyeffects >/dev/null 2>&1; }"
        ]
        onExited: (exitCode, exitStatus) => root.available = exitCode === 0
    }

    Process {
        id: stateProbe
        command: [
            "bash", "-lc",
            "pgrep -x easyeffects >/dev/null 2>&1 || "
                + "{ command -v flatpak >/dev/null 2>&1 && flatpak ps --columns=application 2>/dev/null | grep -Fxq com.github.wwmm.easyeffects; }"
        ]
        onExited: (exitCode, exitStatus) => root.active = exitCode === 0
    }

    Timer {
        id: refreshTimer
        interval: 450
        repeat: false
        onTriggered: root.fetchActiveState()
    }

    Timer {
        interval: 5000
        repeat: true
        running: root.available
        onTriggered: root.fetchActiveState()
    }

    Component.onCompleted: root.refresh()
}
