pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property int refreshRevision: 0

    // Quickshell ObjectModel.values is a typed Qt list. It can be temporarily
    // unavailable during PipeWire startup and is not guaranteed to implement
    // JavaScript's iterable protocol. Keep every exposed binding defined.
    readonly property var graphNodes: Pipewire.nodes?.values ?? []
    readonly property var graphLinks: Pipewire.linkGroups?.values ?? []
    readonly property var trackedObjects: root.trackableObjects(root.graphNodes, root.graphLinks)
    readonly property var captureState: root.buildCaptureState(root.refreshRevision, root.graphNodes, root.graphLinks)

    readonly property bool microphoneActive: Boolean(root.captureState?.microphoneActive ?? false)
    readonly property bool cameraActive: Boolean(root.captureState?.cameraActive ?? false)
    readonly property bool recordingActive: Boolean(root.captureState?.recordingActive ?? false)
    readonly property bool unclassifiedVideoCaptureActive: Boolean(root.captureState?.unclassifiedVideoCaptureActive ?? false)

    readonly property string microphoneApp: String(root.captureState?.microphoneApp ?? "")
    readonly property string cameraApp: String(root.captureState?.cameraApp ?? "")
    readonly property string recordingApp: String(root.captureState?.recordingApp ?? "")

    function stringProp(props, key): string {
        return String(props?.[key] ?? "")
    }

    function applicationName(node): string {
        const props = node?.properties ?? ({})
        return root.stringProp(props, "application.name")
            || root.stringProp(props, "node.description")
            || String(node?.description ?? "")
            || String(node?.name ?? "")
    }

    function emptyState(): var {
        return {
            microphoneActive: false,
            cameraActive: false,
            recordingActive: false,
            unclassifiedVideoCaptureActive: false,
            microphoneApp: "",
            cameraApp: "",
            recordingApp: ""
        }
    }

    // An indexed copy is compatible with QML lists and regular JS arrays.
    // Do not use [...qtList] or for...of on ObjectModel.values: some Qt
    // versions expose list-like sequences that are not JS-iterable.
    function trackableObjects(nodes, linkGroups): var {
        const objects = []
        const nodeList = nodes ?? []
        const groupList = linkGroups ?? []
        for (let i = 0; i < (nodeList.length ?? 0); ++i) {
            if (nodeList[i])
                objects.push(nodeList[i])
        }
        for (let i = 0; i < (groupList.length ?? 0); ++i) {
            if (groupList[i])
                objects.push(groupList[i])
        }
        return objects
    }

    function buildCaptureState(revision: int, nodes, linkGroups): var {
        const state = root.emptyState()
        if (!Pipewire.ready)
            return state

        const activeNodeIds = new Set()
        const groups = linkGroups ?? []
        for (let i = 0; i < (groups.length ?? 0); ++i) {
            const group = groups[i]
            if (!group || group.state !== PwLinkState.Active)
                continue
            if (group.source)
                activeNodeIds.add(Number(group.source.id))
            if (group.target)
                activeNodeIds.add(Number(group.target.id))
        }

        const nodeList = nodes ?? []
        for (let i = 0; i < (nodeList.length ?? 0); ++i) {
            const node = nodeList[i]
            if (!node || !node.isStream || !activeNodeIds.has(Number(node.id)))
                continue

            const props = node.properties ?? ({})
            const mediaClass = root.stringProp(props, "media.class")
            const mediaCategory = root.stringProp(props, "media.category")
            const mediaRole = root.stringProp(props, "media.role")
            const capture = mediaClass.startsWith("Stream/Input/") || mediaCategory === "Capture"
            if (!capture)
                continue

            const app = root.applicationName(node)
            if (mediaClass.includes("Audio")) {
                state.microphoneActive = true
                if (!state.microphoneApp.length)
                    state.microphoneApp = app
                continue
            }

            if (!mediaClass.includes("Video"))
                continue

            if (mediaRole === "Camera") {
                state.cameraActive = true
                if (!state.cameraApp.length)
                    state.cameraApp = app
            } else if (mediaRole === "Screen" || mediaRole === "Screencast") {
                state.recordingActive = true
                if (!state.recordingApp.length)
                    state.recordingApp = app
            } else {
                state.unclassifiedVideoCaptureActive = true
            }
        }

        return state
    }

    // Older presentation code can still request a refresh. Native PipeWire is
    // already event-driven, so this only invalidates the derived snapshot.
    function refresh(force) {
        root.refreshRevision += 1
    }

    // Node properties and link states are the only privacy fields that require
    // binding. Quickshell keeps the graph itself synchronized with PipeWire.
    PwObjectTracker {
        objects: root.trackedObjects
    }
}
