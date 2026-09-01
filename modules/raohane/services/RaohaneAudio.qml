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
    property double lastRefreshMs: 0

    property var outputDevices: []
    property var inputDevices: []
    property bool devicesRefreshing: false

    readonly property int minimumRefreshInterval: 1000
    readonly property int selfEventGuardInterval: 1300
    readonly property var outputStreams: []
    readonly property var inputStreams: []

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

    function cleanStatusLine(rawLine: string): string {
        return String(rawLine ?? "")
            .replace(/[│├└─]/g, " ")
            .trim()
    }

    function parseDeviceLine(rawLine: string): var {
        const line = root.cleanStatusLine(rawLine)
        const match = line.match(/^(\*)?\s*([0-9]+)\.\s+(.+)$/)
        if (!match)
            return null

        const rawName = String(match[3] ?? "")
        const name = rawName.replace(/\s+\[vol:.*$/i, "").trim()
        if (!name.length)
            return null

        return {
            id: Number(match[2]),
            name: name,
            active: Boolean(match[1])
        }
    }

    function parseStatus(text): void {
        let section = ""
        const outputs = []
        const inputs = []

        for (const rawLine of String(text ?? "").split("\n")) {
            const line = root.cleanStatusLine(rawLine)
            if (line.endsWith("Sinks:")) {
                section = "sinks"
                continue
            }
            if (line.endsWith("Sources:")) {
                section = "sources"
                continue
            }
            if (line.endsWith("Filters:") || line.endsWith("Streams:") || line === "Video" || line.endsWith("Devices:")) {
                if (section === "sinks" || section === "sources")
                    section = ""
                continue
            }
            if (section !== "sinks" && section !== "sources")
                continue

            const item = root.parseDeviceLine(rawLine)
            if (!item)
                continue
            if (section === "sinks")
                outputs.push(item)
            else
                inputs.push(item)
        }

        root.outputDevices = outputs
        root.inputDevices = inputs
    }

    // Keep the optional force flag untyped for older deployed Quickshell builds.
    function refresh(force) {
        if (volumeProbe.running)
            return

        const forced = force === true
        const now = Date.now()
        if (!forced && root.lastRefreshMs > 0
                && now - root.lastRefreshMs < root.minimumRefreshInterval)
            return

        root.lastRefreshMs = now
        // wpctl creates short-lived PipeWire graph events. Suppress them at the
        // shared registry monitor so Audio and Privacy cannot wake each other.
        RaohanePipeWire.suppressEventsFor(root.selfEventGuardInterval)
        volumeProbe.exec([
            "bash", "-c",
            "printf 'SINK '; wpctl get-volume @DEFAULT_SINK@ 2>/dev/null || printf 'UNAVAILABLE\\n'; "
                + "printf 'SOURCE '; wpctl get-volume @DEFAULT_SOURCE@ 2>/dev/null || printf 'UNAVAILABLE\\n'; "
                + "printf 'SINK_NAME '; wpctl inspect @DEFAULT_SINK@ 2>/dev/null | sed -n 's/^[[:space:]]*node.description = \"\\(.*\\)\"/\\1/p' | head -1; "
                + "printf 'SOURCE_NAME '; wpctl inspect @DEFAULT_SOURCE@ 2>/dev/null | sed -n 's/^[[:space:]]*node.description = \"\\(.*\\)\"/\\1/p' | head -1"
        ])
    }

    function refreshDevices(force): void {
        if (deviceProbe.running)
            return
        root.devicesRefreshing = true
        RaohanePipeWire.suppressEventsFor(root.selfEventGuardInterval)
        deviceProbe.exec(["wpctl", "status"])
    }

    function refreshSoon(): void {
        refreshTimer.restart()
    }

    function setVolume(value: real): void {
        const next = root.clampVolume(value)
        root.volume = next

        const numeric = next.toFixed(4)
        Quickshell.execDetached([
            "bash", "-c",
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
            "bash", "-c",
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
            deviceRefreshTimer.restart()
        }
    }

    function setDefaultSource(node): void {
        if (node?.id !== undefined && Number(node.id) >= 0) {
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
            root.refreshSoon()
            deviceRefreshTimer.restart()
        }
    }

    Connections {
        target: RaohanePipeWire

        function onGraphChanged(): void {
            root.refresh()
        }
    }

    Process {
        id: volumeProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.applyProbe(text)
        }
    }

    Process {
        id: deviceProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.parseStatus(text)
        }
        onExited: root.devicesRefreshing = false
    }

    Timer {
        id: refreshTimer
        interval: 180
        repeat: false
        onTriggered: root.refresh(true)
    }

    Timer {
        id: deviceRefreshTimer
        interval: 320
        repeat: false
        onTriggered: root.refreshDevices(true)
    }

    // A slow fallback only repairs missed events; normal updates are event driven.
    Timer {
        interval: 30000
        repeat: true
        running: true
        onTriggered: root.refresh(true)
    }

    Component.onCompleted: {
        root.refresh(true)
        root.refreshDevices(true)
    }
}
