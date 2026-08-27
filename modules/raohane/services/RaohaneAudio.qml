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

    // Keep the existing service surface stable while device/stream enumeration
    // is migrated separately. Raohane's active UI currently consumes the
    // default sink/source controls only.
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
        const parsed = root.parseVolume(text)
        if (!parsed)
            return
        const wasReady = root.ready
        root.volume = parsed.volume
        root.muted = parsed.muted
        root.ready = true
        if (!wasReady)
            console.debug("[RaohaneAudio] wpctl sink ready")
    }

    function applySource(text): void {
        const parsed = root.parseVolume(text)
        if (!parsed)
            return
        root.microphoneVolume = parsed.volume
        root.microphoneMuted = parsed.muted
        root.microphoneReady = true
    }

    function refresh(): void {
        if (!sinkProbe.running)
            sinkProbe.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"]) 
        if (!sourceProbe.running)
            sourceProbe.exec(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"]) 
    }

    function setVolume(value: real): void {
        const next = root.clampVolume(value)
        root.volume = next
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", next.toFixed(4)])
    }

    function setMuted(value: bool): void {
        root.muted = Boolean(value)
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", root.muted ? "1" : "0"])
    }

    function toggleMute(): void {
        root.setMuted(!root.muted)
    }

    function setMicrophoneVolume(value: real): void {
        const next = root.clampVolume(value)
        root.microphoneVolume = next
        Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", next.toFixed(4)])
    }

    function setMicrophoneMuted(value: bool): void {
        root.microphoneMuted = Boolean(value)
        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", root.microphoneMuted ? "1" : "0"])
    }

    function toggleMicrophoneMute(): void {
        root.setMicrophoneMuted(!root.microphoneMuted)
    }

    function setDefaultSink(node): void {
        if (node?.id !== undefined && Number(node.id) >= 0)
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
    }

    function setDefaultSource(node): void {
        if (node?.id !== undefined && Number(node.id) >= 0)
            Quickshell.execDetached(["wpctl", "set-default", String(node.id)])
    }

    Process {
        id: sinkProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.applySink(text)
        }
    }

    Process {
        id: sourceProbe
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: root.applySource(text)
        }
    }

    Timer {
        interval: 400
        repeat: true
        running: true
        onTriggered: root.refresh()
    }

    Component.onCompleted: root.refresh()
}
