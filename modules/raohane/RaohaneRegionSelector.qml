import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

// Raohane-owned capture entry point. Selection stays external-tool based so it
// remains lightweight on Wayland while screenshot, OCR, image-search handoff
// and recording stay available through Raohane-owned backend scripts.
Scope {
    id: root

    property bool busy: false

    function prepareCapture(preserveShell: bool): void {
        if (!preserveShell)
            RaohaneState.closePrimarySurfaces("")
        RaohaneState.regionSelectorOpen = false
    }

    function finishScreenshot(): void {
        captureFailsafe.stop()
        RaohaneFocusGrab.resumeDismiss()
        root.busy = false
    }

    function runBackend(scriptName: string): void {
        if (root.busy)
            return
        root.busy = true
        root.prepareCapture(false)
        Quickshell.execDetached([
            "bash",
            Quickshell.shellPath("scripts/" + scriptName)
        ])
        busyReset.restart()
    }

    function screenshot(): void {
        if (root.busy)
            return
        root.busy = true

        // Keep every currently visible Raohane surface in the capture. slurp
        // temporarily takes compositor focus, so pause focus-based dismissal
        // until the detached capture command reports completion through IPC.
        RaohaneFocusGrab.suppressDismiss()
        root.prepareCapture(true)
        captureFailsafe.restart()
        Quickshell.execDetached([
            "bash", "-lc",
            "finish_capture() { qs -c raohane ipc call region captureFinished >/dev/null 2>&1 || true; }; "
                + "trap finish_capture EXIT; "
                + "geometry=\"$(slurp 2>/dev/null)\" || exit 0; "
                + "[ -n \"$geometry\" ] || exit 0; "
                + "grim -g \"$geometry\" - | wl-copy --type image/png && "
                + "notify-send 'Screenshot copied' 'Selected region copied to clipboard' -a 'Raohane Capture' >/dev/null 2>&1 || true"
        ])
    }

    function search(): void {
        root.runBackend("region-search.sh")
    }

    function ocr(): void {
        root.runBackend("region-ocr.sh")
    }

    function record(sound: bool): void {
        if (root.busy)
            return
        root.busy = true
        root.prepareCapture(false)
        const script = RaohanePaths.join(RaohanePaths.scriptsPath, "videos/record.sh")
        if (sound)
            Quickshell.execDetached([script, "--sound"])
        else
            Quickshell.execDetached([script])
        busyReset.restart()
    }

    // The IPC callback is the normal completion path. This timer is only a
    // safety net so focus dismissal cannot remain disabled forever if the
    // capture process or IPC callback is interrupted.
    Timer {
        id: captureFailsafe
        interval: 30000
        repeat: false
        onTriggered: root.finishScreenshot()
    }

    Timer {
        id: busyReset
        interval: 500
        repeat: false
        onTriggered: root.busy = false
    }

    Connections {
        target: RaohaneState
        function onRegionSelectorOpenChanged(): void {
            if (RaohaneState.regionSelectorOpen)
                root.screenshot()
        }
    }

    IpcHandler {
        target: "region"
        function screenshot(): void { root.screenshot() }
        function search(): void { root.search() }
        function ocr(): void { root.ocr() }
        function record(): void { root.record(false) }
        function recordWithSound(): void { root.record(true) }
        function captureFinished(): void { root.finishScreenshot() }
    }

    CompositorGlobalShortcut {
        name: "regionScreenshot"
        description: "Take a screenshot of the selected region"
        onPressed: root.screenshot()
    }

    CompositorGlobalShortcut {
        name: "regionSearch"
        description: "Capture a selected region for image search"
        onPressed: root.search()
    }

    CompositorGlobalShortcut {
        name: "regionOcr"
        description: "Recognize text in the selected region"
        onPressed: root.ocr()
    }

    CompositorGlobalShortcut {
        name: "regionRecord"
        description: "Record a selected region"
        onPressed: root.record(false)
    }

    CompositorGlobalShortcut {
        name: "regionRecordWithSound"
        description: "Record a selected region with sound"
        onPressed: root.record(true)
    }

    Component.onDestruction: RaohaneFocusGrab.resumeDismiss()
}
