pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property string requestedSource: ""
    property string currentSource: ""
    property string accentHex: ""
    property bool busy: false
    property var cache: ({})

    readonly property bool available: /^#[0-9a-fA-F]{6}$/.test(root.accentHex)
    readonly property color accent: root.available ? root.accentHex : "transparent"

    function requestAccent(source): void {
        const normalized = String(source ?? "").trim()
        root.requestedSource = normalized

        if (normalized.length === 0) {
            root.accentHex = ""
            debounce.stop()
            return
        }

        const cached = root.cache[normalized]
        if (cached) {
            root.accentHex = cached
            debounce.stop()
            return
        }

        debounce.restart()
    }

    function startExtraction(): void {
        if (extractor.running || root.requestedSource.length === 0)
            return

        const cached = root.cache[root.requestedSource]
        if (cached) {
            root.accentHex = cached
            return
        }

        root.currentSource = root.requestedSource
        root.busy = true
        extractor.running = true
    }

    function applyResult(payload: string): void {
        const value = String(payload ?? "").trim().split("\n")[0] ?? ""
        if (!/^#[0-9a-fA-F]{6}$/.test(value))
            return

        const nextCache = Object.assign({}, root.cache)
        nextCache[root.currentSource] = value
        root.cache = nextCache

        if (root.currentSource === root.requestedSource)
            root.accentHex = value
    }

    Component.onCompleted: root.requestAccent(RaohaneMedia.artUrl)

    Connections {
        target: RaohaneMedia

        function onArtUrlChanged(): void {
            root.requestAccent(RaohaneMedia.artUrl)
        }
    }

    Timer {
        id: debounce
        interval: 180
        repeat: false
        onTriggered: root.startExtraction()
    }

    Process {
        id: extractor
        running: false
        command: [
            "python3",
            Quickshell.shellPath("scripts/cover-accent.py"),
            root.currentSource
        ]

        stdout: StdioCollector {
            onStreamFinished: root.applyResult(text)
        }

        onExited: (exitCode, exitStatus) => {
            root.busy = false

            if (root.currentSource === root.requestedSource && exitCode !== 0)
                root.accentHex = ""

            if (root.currentSource !== root.requestedSource)
                Qt.callLater(root.startExtraction)
        }
    }
}
