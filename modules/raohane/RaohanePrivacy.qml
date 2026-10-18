pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    property int refreshRevision: 0

    // QML can evaluate singleton bindings before their component and
    // functions are fully initialized. Publish explicit idle values first,
    // then evaluate the PipeWire graph once startup is complete.
    property bool initialized: false
    Component.onCompleted: initialized = true

    readonly property var graphNodes: root.initialized && Pipewire.nodes
        ? Pipewire.nodes.values : []
    readonly property var graphLinks: root.initialized && Pipewire.linkGroups
        ? Pipewire.linkGroups.values : []

    readonly property var captureState: {
        if (!root.initialized)
            return {
                microphoneActive: false, cameraActive: false,
                recordingActive: false, unclassifiedVideoCaptureActive: false,
                microphoneApp: "", cameraApp: "", recordingApp: ""
            }
        try {
            return root.buildCaptureState(root.refreshRevision,
                root.graphNodes, root.graphLinks) || root.emptyState()
        } catch (error) {
            console.warn("[Raohane] Unable to read PipeWire capture graph:", error)
            return root.emptyState()
        }
    }

    readonly property bool microphoneActive: root.captureState
        ? root.captureState.microphoneActive === true : false
    readonly property bool cameraActive: root.captureState
        ? root.captureState.cameraActive === true : false
    readonly property bool recordingActive: root.captureState
        ? root.captureState.recordingActive === true : false
    readonly property bool unclassifiedVideoCaptureActive: root.captureState
        ? root.captureState.unclassifiedVideoCaptureActive === true : false

    readonly property string microphoneApp: root.captureState
        ? String(root.captureState.microphoneApp || "") : ""
    readonly property string cameraApp: root.captureState
        ? String(root.captureState.cameraApp || "") : ""
    readonly property string recordingApp: root.captureState
        ? String(root.captureState.recordingApp || "") : ""

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
    // Bind the native typed Qt lists directly. Converting them to a
    // JavaScript array in an intermediate property can produce [undefined]
    // when QML attempts to coerce the result to QList<QObject*>.
    PwObjectTracker {
        objects: root.initialized && Pipewire.nodes
            ? Pipewire.nodes.values : []
    }
    PwObjectTracker {
        objects: root.initialized && Pipewire.linkGroups
            ? Pipewire.linkGroups.values : []
    }
}
