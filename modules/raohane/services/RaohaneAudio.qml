pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource
    readonly property bool ready: sink?.ready ?? false

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property real microphoneVolume: source?.audio?.volume ?? 0
    readonly property bool microphoneMuted: source?.audio?.muted ?? false

    readonly property var outputStreams: Pipewire.nodes.values.filter(node => node.isSink && node.isStream && node.audio)
    readonly property var inputStreams: Pipewire.nodes.values.filter(node => !node.isSink && node.isStream && node.audio)
    readonly property var outputDevices: Pipewire.nodes.values.filter(node => node.isSink && !node.isStream && node.audio)
    readonly property var inputDevices: Pipewire.nodes.values.filter(node => !node.isSink && !node.isStream && node.audio)

    function clampVolume(value: real): real {
        return Math.max(0, Math.min(1, value))
    }

    function setVolume(value: real): void {
        if (root.sink?.audio)
            root.sink.audio.volume = root.clampVolume(value)
    }

    function setMuted(value: bool): void {
        if (root.sink?.audio)
            root.sink.audio.muted = value
    }

    function toggleMute(): void {
        root.setMuted(!root.muted)
    }

    function setMicrophoneVolume(value: real): void {
        if (root.source?.audio)
            root.source.audio.volume = root.clampVolume(value)
    }

    function setMicrophoneMuted(value: bool): void {
        if (root.source?.audio)
            root.source.audio.muted = value
    }

    function toggleMicrophoneMute(): void {
        root.setMicrophoneMuted(!root.microphoneMuted)
    }

    function setDefaultSink(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSink = node
    }

    function setDefaultSource(node): void {
        if (node)
            Pipewire.preferredDefaultAudioSource = node
    }

    PwObjectTracker {
        objects: [root.sink, root.source]
    }
}
