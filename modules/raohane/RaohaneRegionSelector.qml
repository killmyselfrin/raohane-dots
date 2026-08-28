import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

// Native capture entry point. The rich inherited region UI is intentionally
// not loaded at shell startup; screenshots and recording remain functional
// through Raohane-owned external-tool contracts.
Scope {
    id: root

    property bool busy: false

    function screenshot(): void {
        if (root.busy)
            return
        root.busy = true
        RaohaneState.regionSelectorOpen = false
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
        if (root.busy)
            return
        root.busy = true
        RaohaneState.regionSelectorOpen = false
        Quickshell.execDetached([
            "bash", "-lc",
            "tmp=\"$(mktemp --suffix=.png /tmp/raohane-search-XXXXXX)\"; "
                + "geometry=\"$(slurp 2>/dev/null)\" || { rm -f \"$tmp\"; exit 0; }; "
                + "[ -n \"$geometry\" ] || { rm -f \"$tmp\"; exit 0; }; "
                + "grim -g \"$geometry\" \"$tmp\" || { rm -f \"$tmp\"; exit 1; }; "
                + "xdg-open \"$tmp\" >/dev/null 2>&1 || true"
        ])
        busyReset.restart()
    }

    function ocr(): void {
        RaohaneState.regionSelectorOpen = false
        Quickshell.execDetached([
            "notify-send",
            "Raohane Capture",
            "Native OCR is still being migrated; screenshot and recording are available now."
        ])
    }

    function record(sound: bool): void {
        RaohaneState.regionSelectorOpen = false
        const script = RaohanePaths.join(RaohanePaths.scriptsPath, "videos/record.sh")
        if (sound)
            Quickshell.execDetached([script, "--sound"])
        else
            Quickshell.execDetached([script])
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
        description: "Capture a selected region for search"
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
