pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sinkNode: Pipewire.defaultAudioSink
    readonly property var sourceNode: Pipewire.defaultAudioSource

    readonly property bool ready: Pipewire.ready
        && root.sinkNode !== null
        && root.sinkNode.ready
        && root.sinkNode.audio !== null
    readonly property bool microphoneReady: Pipewire.ready
        && root.sourceNode !== null
        && root.sourceNode.ready
        && root.sourceNode.audio !== null

    readonly property real volume: root.ready
        ? root.clampVolume(root.sinkNode.audio.volume)
        : 0
    readonly property bool muted: root.ready
        ? Boolean(root.sinkNode.audio.muted)
        : false
    readonly property real microphoneVolume: root.microphoneReady
        ? root.clampVolume(root.sourceNode.audio.volume)
        : 0
    readonly property bool microphoneMuted: root.microphoneReady
        ? Boolean(root.sourceNode.audio.muted)
        : false

    readonly property string sinkName: root.nodeLabel(root.sinkNode)
    readonly property string sourceName: root.nodeLabel(root.sourceNode)
    readonly property string lastError: Pipewire.ready && root.sinkNode === null
        ? qsTr("No default audio sink")
        : ""

    readonly property var outputDevices: root.deviceEntries(true)
    readonly property var inputDevices: root.deviceEntries(false)
    readonly property bool devicesRefreshing: false

    function clampVolume(value: real): real {
        return Math.max(0, Math.min(1, Number(value) || 0))
    }

    function nodeLabel(node): string {
        if (!node)
            return ""

        const description = String(node.description ?? "").trim()
        if (description.length > 0)
            return description

        const nickname = String(node.nickname ?? "").trim()
        if (nickname.length > 0)
            return nickname

        return String(node.name ?? "").trim()
    }

    function deviceEntries(sinks: bool): var {
        const activeNode = sinks ? root.sinkNode : root.sourceNode
        const entries = []

        for (const node of Pipewire.nodes.values) {
            if (!node || node.audio === null || node.isStream || Boolean(node.isSink) !== sinks)
                continue

            const name = root.nodeLabel(node)
            if (name.length === 0)
                continue

            entries.push({
                id: Number(node.id),
                name: name,
                active: node === activeNode,
                node: node
            })
        }

        entries.sort((left, right) => {
            if (left.active !== right.active)
                return left.active ? -1 : 1
            return left.name.localeCompare(right.name)
        })
        return entries
    }

    // Retained as compatibility entrypoints for surfaces that previously asked
    // the subprocess backend for a snapshot. The native PipeWire model is live,
    // so no probe needs to be launched here.
    function refresh(force) {}
    function refreshDevices(force): void {}

    function setVolume(value: real): void {
        if (!root.ready)
            return

        const next = root.clampVolume(value)
        root.sinkNode.audio.volume = next
        if (next > 0)
            root.sinkNode.audio.muted = false
    }

    function setMuted(value: bool): void {
        if (root.ready)
            root.sinkNode.audio.muted = Boolean(value)
    }

    function toggleMute(): void {
        root.setMuted(!root.muted)
    }

    function setMicrophoneVolume(value: real): void {
        if (!root.microphoneReady)
            return

        const next = root.clampVolume(value)
        root.sourceNode.audio.volume = next
        if (next > 0)
            root.sourceNode.audio.muted = false
    }

    function setMicrophoneMuted(value: bool): void {
        if (root.microphoneReady)
            root.sourceNode.audio.muted = Boolean(value)
    }

    function toggleMicrophoneMute(): void {
        root.setMicrophoneMuted(!root.microphoneMuted)
    }

    function nextOutputDevice(): var {
        const devices = Array.isArray(root.outputDevices) ? root.outputDevices : []
        if (devices.length === 0)
            return null

        const activeIndex = devices.findIndex(device => Boolean(device?.active))
        const nextIndex = activeIndex >= 0 ? (activeIndex + 1) % devices.length : 0
        return devices[nextIndex]
    }

    function nextOutputName(): string {
        return String(root.nextOutputDevice()?.name ?? "")
    }

    function cycleDefaultSink(): bool {
        const devices = Array.isArray(root.outputDevices) ? root.outputDevices : []
        if (devices.length < 2)
            return false

        const next = root.nextOutputDevice()
        if (!next)
            return false

        root.setDefaultSink(next)
        return true
    }

    function setDefaultSink(entry): void {
        const node = entry?.node ?? null
        if (node)
            Pipewire.preferredDefaultAudioSink = node
    }

    function setDefaultSource(entry): void {
        const node = entry?.node ?? null
        if (node)
            Pipewire.preferredDefaultAudioSource = node
    }

    // Volume and mute are bound properties. Device names and graph membership
    // do not require binding, so tracking only the defaults keeps the native
    // PipeWire subscription as small as possible.
    PwObjectTracker {
        objects: [root.sinkNode, root.sourceNode]
    }
}
