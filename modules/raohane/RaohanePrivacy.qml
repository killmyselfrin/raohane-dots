pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Services.Pipewire

QtObject {
    id: root

    readonly property var streamNodes: Pipewire.nodes.values.filter(node => node.isStream)

    PwObjectTracker {
        objects: root.streamNodes
    }

    function mediaClass(node): string {
        return String(node?.type ?? "")
    }

    function mediaCategory(node): string {
        return String(node?.properties?.["media.category"] ?? "")
    }

    function mediaRole(node): string {
        return String(node?.properties?.["media.role"] ?? "")
    }

    function isCaptureStream(node): bool {
        const mediaClassValue = mediaClass(node)
        return mediaClassValue.startsWith("Stream/Input/") || mediaCategory(node) === "Capture"
    }

    readonly property var captureStreams: streamNodes.filter(node => isCaptureStream(node))
    readonly property var microphoneStreams: captureStreams.filter(node => {
        const mediaClassValue = mediaClass(node)
        return mediaClassValue.includes("Audio") || node?.audio !== null
    })
    readonly property var videoStreams: captureStreams.filter(node => mediaClass(node).includes("Video"))
    readonly property var cameraStreams: videoStreams.filter(node => mediaRole(node) === "Camera")
    readonly property var screenStreams: videoStreams.filter(node => mediaRole(node) === "Screen")

    readonly property bool microphoneActive: microphoneStreams.length > 0
    readonly property bool cameraActive: cameraStreams.length > 0
    readonly property bool recordingActive: screenStreams.length > 0
    readonly property bool unclassifiedVideoCaptureActive: videoStreams.length > cameraStreams.length + screenStreams.length

    function applicationName(node): string {
        return String(node?.properties?.["application.name"]
            ?? node?.properties?.["node.description"]
            ?? node?.description
            ?? node?.name
            ?? "")
    }

    readonly property string microphoneApp: microphoneStreams.length > 0
        ? applicationName(microphoneStreams[0])
        : ""
    readonly property string cameraApp: cameraStreams.length > 0
        ? applicationName(cameraStreams[0])
        : ""
    readonly property string recordingApp: screenStreams.length > 0
        ? applicationName(screenStreams[0])
        : ""
}
