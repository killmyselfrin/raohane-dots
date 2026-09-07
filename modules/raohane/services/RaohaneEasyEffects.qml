pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool available: false
    property bool enabled: false
    property bool busy: false
    property bool requestedEnabled: false
    property bool applyPending: false
    property string lastError: ""
    property string commandError: ""
    property double lastRefreshMs: 0
    property double lastAvailabilityRefreshMs: 0

    readonly property int minimumRefreshInterval: 6000
    readonly property int availabilityRefreshInterval: 300000

    signal activeApplied(bool enabled)

    function refresh(force): void {
        const forced = force === true
        const now = Date.now()
        if (!forced && root.lastRefreshMs > 0
                && now - root.lastRefreshMs < root.minimumRefreshInterval)
            return

        root.lastRefreshMs = now
        if (forced || root.lastAvailabilityRefreshMs === 0
                || now - root.lastAvailabilityRefreshMs >= root.availabilityRefreshInterval) {
            root.lastAvailabilityRefreshMs = now
            root.fetchAvailability()
        }
        root.fetchActiveState()
    }

    function fetchAvailability(): void {
        if (!availabilityProbe.running)
            availabilityProbe.running = true
    }

    function fetchActiveState(): void {
        if (!stateProbe.running && !actionProcess.running)
            stateProbe.running = true
    }

    function launchUi(): void {
        Quickshell.execDetached([
            "bash", "-lc",
            "if command -v easyeffects >/dev/null 2>&1; then exec easyeffects; "
                + "elif command -v flatpak >/dev/null 2>&1 && flatpak info com.github.wwmm.easyeffects >/dev/null 2>&1; then "
                + "exec flatpak run com.github.wwmm.easyeffects; fi"
        ])
        verifyTimer.restart()
    }

    function requestActive(value: bool): void {
        const requested = Boolean(value)
        if (!root.available || root.busy || root.active === requested)
            return

        root.busy = true
        root.requestedActive = requested
        root.applyPending = true
        root.lastError = ""
        root.commandError = ""

        if (requested) {
            actionProcess.command = [
                "bash", "-lc",
                "if command -v easyeffects >/dev/null 2>&1; then "
                    + "easyeffects --hide-window --service-mode >/dev/null 2>&1 & exit 0; "
                    + "elif command -v flatpak >/dev/null 2>&1 && flatpak info com.github.wwmm.easyeffects >/dev/null 2>&1; then "
                    + "flatpak run com.github.wwmm.easyeffects --hide-window --service-mode >/dev/null 2>&1 & exit 0; "
                    + "else exit 127; fi"
            ]
        } else {
            actionProcess.command = [
                "bash", "-lc",
                "pkill -x easyeffects >/dev/null 2>&1 || true; "
                    + "if command -v flatpak >/dev/null 2>&1; then flatpak kill com.github.wwmm.easyeffects >/dev/null 2>&1 || true; fi"
            ]
        }
        actionProcess.running = true
    }

    function disable(): void {
        root.requestActive(false)
    }

    function enable(): void {
        root.requestActive(true)
    }

    function toggle(): void {
        root.requestActive(!root.active)
    }

    function finishVerification(): void {
        root.busy = false
        if (!root.applyPending)
            return

        if (root.active === root.requestedActive) {
            root.applyPending = false
            root.lastError = ""
            root.activeApplied(root.active)
            return
        }

        root.applyPending = false
        root.lastError = qsTr("EasyEffects did not reach the requested state")
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
        onExited: (exitCode, exitStatus) => {
            root.active = exitCode === 0
            root.finishVerification()
        }
    }

    Process {
        id: actionProcess

        stderr: StdioCollector {
            onStreamFinished: {
                const value = String(text ?? "").trim()
                root.commandError = value.length > 0 ? value.split("\n").pop() : ""
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                verifyTimer.restart()
                return
            }
            root.busy = false
            root.applyPending = false
            root.lastError = root.commandError.length > 0
                ? root.commandError
                : qsTr("Could not start the EasyEffects action")
            root.fetchActiveState()
        }
    }

    Timer {
        id: verifyTimer
        interval: 850
        repeat: false
        onTriggered: root.fetchActiveState()
    }

    Component.onCompleted: root.refresh(true)
}
