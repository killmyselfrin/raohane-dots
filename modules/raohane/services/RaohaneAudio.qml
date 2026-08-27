pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property bool ready: false
    property bool microphoneReady: false
    property real volume: 0
    property bool muted: false
    property real microphoneVolume: 0
    property bool microphoneMuted: false
    property string sinkName: ""
    property string sourceName: ""
    property string lastError: ""

    readonly property var outputStreams: []
    readonly property var inputStreams: []
    readonly property var outputDevices: []
    readonly property var inputDevices: []

    function clampVolume(value: real): real {
        return Math.max(0, Math.min(1, Number(value) || 0))
    }

    function parseVolume(text): var {
        const value = String(text ?? "")
        const match = value.match(/Volume:\s*([0-9]+(?:\.[0-9]+)?)/)
        if (!match)
            return null
        return {
            volume: root.clampVolume(Number(match[1])),
            muted: /\[MUTED\]/i.test(value)
        }
    }

    function applySink(text): void {
        const value = String(text ?? "").trim()
        if (value === "UNAVAILABLE") {
            root.ready = false
            root.lastError = "No default audio sink"
            return
        }

        const parsed = root.parseVolume(value)
        if (!parsed)
            return

        const wasReady = root.ready
        root.volume = parsed.volume
        root.muted = parsed.muted
        root.ready = true
        root.lastError = ""
        if (!wasReady)
            console.debug("[RaohaneAudio] wpctl sink ready")
    }

    function applySource(text): void {
        const value = String(text ?? "").trim()
        if (value === "UNAVAILABLE") {
            root.microphoneReady = false
            return
        }

        const parsed = root.parseVolume(value)
        if (!parsed)
            return

        root.microphoneVolume = parsed.volume
        root.microphoneMuted = parsed.muted
        root.microphoneReady = true
    }

    function applyProbe(text): void {
        for (const rawLine of String(text ?? "").split("\n")) {
            const line = rawLine.trim()
            if (line.startsWith("SINK "))
                root.applySink(line.slice(5))
            else if (line.startsWith("SOURCE "))
                root.applySource(line.slice(7))
            else if (line.startsWith("SINK_NAME "))
                root.sinkName = line.slice(10).trim()
            else if (line.startsWith("SOURCE_NAME "))
                root.sourceName = line.slice(12).trim()
        }
    }

    function refresh(): void {
        if (!volumeProbe.running) {
            volumeProbe.exec([
                "bash", "-lc",
                "printf 'SINK '; wpctl get-volume @DEFAULT_SINK@ 2>/dev/null || printf 'UNAVAILABLE\\n'; "
                    + "printf 'SOURCE '; wpctl get-volume @DEFAULT_SOURCE@ 2>/dev/null || printf 'UNAVAILABLE\\n'; "
                    + "printf 'SINK_NAME '; wpctl inspect @DEFAULT_SINK@ 2>/dev/null | sed -n 's/^[[:space:]]*node.description = \"\\(.*\\)\"/\\1/p' | head -1; "
                    + "printf 'SOURCE_NAME '; wpctl inspect @DEFAULT_SOURCE@ 2>/dev/null | sed -n 's/^[[:space:]]*node.description = \"\\(.*\\)\"/\\1/p' | head -1"
            ])
        }
    }

    function refreshSoon(): void {
        refreshTimer.restart()
    }

    function setVolume(value: real): void {
        const next = root.clampVolume(value)
        root.volume = next

        // A user moving the output slider above zero expects audible output.
        // Keep the operation ordered so a stale mute state cannot win a race.
        const numeric = next.toFixed(4)
        Quickshell.execDetached([
            "bash", "-lc",
            `wpctl set-volume @DEFAULT_SINK@ ${numeric} && `
                + (next > 0 ? "wpctl set-mute @DEFAULT_SINK@ 0" : "true")
        ])
        if (next > 0)
            root.muted = false
        root.refreshSoon()
    }

    function setMuted(value: bool): void {
        const next = Boolean(value)
        root.muted = next
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SINK@", next ? "1" : "0"])
        root.refreshSoon()
    }

    function toggleMute(): void {
        root.setMuted(!root.muted)
    }

    function setMicrophoneVolume(value: real): void {
        const next = root.clampVolume(value)
        root.microphoneVolume = next
        const numeric = next.toFixed(4)
        Quickshell.execDetached([
            "bash", "-lc",
            `wpctl set-volume @DEFAULT_SOURCE@ ${numeric} && `
                + (next > 0 ? "wpctl set-mute @DEFAULT_SOURCE@ 0" : "true")
        ])
        if (next > 0)
            root.microphoneMuted = false
        root.refreshSoon()
    }

    function setMicrophoneMuted(value: bool): void {
        const next = Boolean(value)
        root.microphoneMuted = next
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_SOURCE@", next ? "1" : "0"])
        root.refreshSoon()
    }

    function toggleMicrophoneMute(): void {
        root.setMicrophoneMuted(!root.microphoneMuted)
    }

    function setDefaultSink(node): void {
        if (node?.id !== undefined && Number(node.id) >= 0) {
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
            root.refreshSoon()
        }
    }

    function setDefaultSource(node): void {
        if (node?.id !== undefined && Number(node.id) >= 0) {
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
            root.refreshSoon()
        }
    }

    Process {
        id: volumeProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.applyProbe(text)
        }
    }

    Timer {
        id: refreshTimer
        interval: 120
        repeat: false
        onTriggered: root.refresh()
    }

    Timer {
        interval: 750
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
