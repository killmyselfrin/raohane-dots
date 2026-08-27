pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.raohane.services

// Compatibility facade for inherited surfaces. The old service owned a second
// Quickshell PipeWire backend; all default sink/source control now routes
// through the Raohane-owned wpctl service instead.
Singleton {
    id: root

    property bool syncingSink: false
    property bool syncingSource: false
    property bool sinkInitialized: false
    property bool sourceInitialized: false

    readonly property bool ready: RaohaneAudio.ready
    readonly property real hardMaxValue: 1.0
    readonly property string audioTheme: Config.options?.sounds?.theme ?? "freedesktop"
    readonly property real value: RaohaneAudio.volume

    readonly property var sink: sinkNode
    readonly property var source: sourceNode
    readonly property var outputAppNodes: []
    readonly property var inputAppNodes: []
    readonly property var outputDevices: root.ready ? [sinkNode] : []
    readonly property var inputDevices: RaohaneAudio.microphoneReady ? [sourceNode] : []

    signal sinkProtectionTriggered(string reason)

    function friendlyDeviceName(node): string {
        return String(node?.nickname || node?.description || node?.name || Translation.tr("Unknown"))
    }

    function appNodeDisplayName(node): string {
        return String(node?.properties?.["application.name"] || node?.description || node?.name || Translation.tr("Unknown"))
    }

    function correctType(node, isSink): bool {
        return Boolean(node && node.isSink === isSink && node.audio)
    }

    function appNodes(isSink): var {
        return []
    }

    function devices(isSink): var {
        if (isSink)
            return root.outputDevices
        return root.inputDevices
    }

    function protectedVolume(value: real): real {
        let next = Math.max(0, Math.min(1, Number(value) || 0))
        if (Config.options?.audio?.protection?.enable) {
            const maxAllowed = Math.max(0, Math.min(1, Number(Config.options.audio.protection.maxAllowed) / 100 || 1))
            if (next > maxAllowed) {
                root.sinkProtectionTriggered(Translation.tr("Exceeded max allowed"))
                next = maxAllowed
            }
        }
        return next
    }

    function syncSinkFromNative(): void {
        root.syncingSink = true
        sinkAudio.volume = RaohaneAudio.volume
        sinkAudio.muted = RaohaneAudio.muted
        root.syncingSink = false
        root.sinkInitialized = RaohaneAudio.ready
    }

    function syncSourceFromNative(): void {
        root.syncingSource = true
        sourceAudio.volume = RaohaneAudio.microphoneVolume
        sourceAudio.muted = RaohaneAudio.microphoneMuted
        root.syncingSource = false
        root.sourceInitialized = RaohaneAudio.microphoneReady
    }

    function toggleMute(): void {
        RaohaneAudio.toggleMute()
    }

    function toggleMicMute(): void {
        RaohaneAudio.toggleMicrophoneMute()
    }

    function incrementVolume(): void {
        const step = root.value < 0.1 ? 0.01 : 0.02
        RaohaneAudio.setVolume(root.protectedVolume(root.value + step))
    }

    function decrementVolume(): void {
        const step = root.value < 0.1 ? 0.01 : 0.02
        RaohaneAudio.setVolume(Math.max(0, root.value - step))
    }

    function setDefaultSink(node): void {
        RaohaneAudio.setDefaultSink(node)
    }

    function setDefaultSource(node): void {
        RaohaneAudio.setDefaultSource(node)
    }

    function playSystemSound(soundName): void {
        const ogaPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.oga`
        const oggPath = `/usr/share/sounds/${root.audioTheme}/stereo/${soundName}.ogg`
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", ogaPath])
        Quickshell.execDetached(["ffplay", "-nodisp", "-autoexit", oggPath])
    }

    QtObject {
        id: sinkNode
        readonly property bool ready: root.ready
        readonly property bool isSink: true
        readonly property bool isStream: false
        readonly property int id: -1
        readonly property string name: "default-audio-sink"
        readonly property string nickname: RaohaneAudio.sinkName.length > 0 ? RaohaneAudio.sinkName : "Default Audio Sink"
        readonly property string description: nickname
        readonly property var properties: ({})
        readonly property var audio: sinkAudio
    }

    QtObject {
        id: sinkAudio
        property real volume: 0
        property bool muted: false

        onVolumeChanged: {
            if (root.sinkInitialized && !root.syncingSink && RaohaneAudio.ready
                    && Math.abs(volume - RaohaneAudio.volume) > 0.0005)
                RaohaneAudio.setVolume(root.protectedVolume(volume))
        }
        onMutedChanged: {
            if (root.sinkInitialized && !root.syncingSink && RaohaneAudio.ready
                    && muted !== RaohaneAudio.muted)
                RaohaneAudio.setMuted(muted)
        }
    }

    QtObject {
        id: sourceNode
        readonly property bool ready: RaohaneAudio.microphoneReady
        readonly property bool isSink: false
        readonly property bool isStream: false
        readonly property int id: -1
        readonly property string name: "default-audio-source"
        readonly property string nickname: RaohaneAudio.sourceName.length > 0 ? RaohaneAudio.sourceName : "Default Audio Source"
        readonly property string description: nickname
        readonly property var properties: ({})
        readonly property var audio: sourceAudio
    }

    QtObject {
        id: sourceAudio
        property real volume: 0
        property bool muted: false

        onVolumeChanged: {
            if (root.sourceInitialized && !root.syncingSource && RaohaneAudio.microphoneReady
                    && Math.abs(volume - RaohaneAudio.microphoneVolume) > 0.0005)
                RaohaneAudio.setMicrophoneVolume(volume)
        }
        onMutedChanged: {
            if (root.sourceInitialized && !root.syncingSource && RaohaneAudio.microphoneReady
                    && muted !== RaohaneAudio.microphoneMuted)
                RaohaneAudio.setMicrophoneMuted(muted)
        }
    }

    Connections {
        target: RaohaneAudio

        function onReadyChanged(): void {
            if (RaohaneAudio.ready)
                root.syncSinkFromNative()
            else
                root.sinkInitialized = false
        }
        function onMicrophoneReadyChanged(): void {
            if (RaohaneAudio.microphoneReady)
                root.syncSourceFromNative()
            else
                root.sourceInitialized = false
        }
        function onVolumeChanged(): void {
            if (RaohaneAudio.ready)
                root.syncSinkFromNative()
        }
        function onMutedChanged(): void {
            if (RaohaneAudio.ready)
                root.syncSinkFromNative()
        }
        function onMicrophoneVolumeChanged(): void {
            if (RaohaneAudio.microphoneReady)
                root.syncSourceFromNative()
        }
        function onMicrophoneMutedChanged(): void {
            if (RaohaneAudio.microphoneReady)
                root.syncSourceFromNative()
        }
    }

    Component.onCompleted: {
        if (RaohaneAudio.ready)
            root.syncSinkFromNative()
        if (RaohaneAudio.microphoneReady)
            root.syncSourceFromNative()
    }
}
