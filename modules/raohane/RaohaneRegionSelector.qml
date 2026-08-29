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

    function prepareCapture(): void {
        RaohaneState.closePrimarySurfaces("")
        RaohaneState.regionSelectorOpen = false
    }

    function runBackend(scriptName: string): void {
        if (root.busy)
            return
        root.busy = true
        root.prepareCapture()
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
        root.prepareCapture()
        Quickshell.execDetached([
            "bash", "-lc",
            "geometry=\"$(slurp 2>/dev/null)\" || exit 0; "
                + "[ -n \"$geometry\" ] || exit 0; "
                + "grim -g \"$geometry\" - | wl-copy --type image/png && "
                + "notify-send 'Screenshot copied' 'Selected region copied to clipboard' -a 'Raohane Capture' -i image-x-generic >/dev/null 2>&1 || true"
        ])
        busyReset.restart()
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
        root.prepareCapture()
        const script = RaohanePaths.join(RaohanePaths.scriptsPath, "videos/record.sh")
        if (sound)
            Quickshell.execDetached([script, "--sound"])
        else
            Quickshell.execDetached([script])
        busyReset.restart()
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
}
