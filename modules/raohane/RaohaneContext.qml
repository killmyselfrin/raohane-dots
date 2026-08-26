pragma Singleton

import QtQuick
import Quickshell.Wayland
import qs.modules.raohane.services

Item {
    id: root

    property string eventTitle: ""
    property string eventDetail: ""

    readonly property bool recording: RaohanePrivacy.recordingActive
    readonly property bool microphone: RaohanePrivacy.microphoneActive
    readonly property bool camera: RaohanePrivacy.cameraActive

    readonly property bool mediaActive: RaohaneMedia.available
    readonly property string mediaTitle: RaohaneMedia.title
    readonly property string mediaArtist: RaohaneMedia.artist

    readonly property var activeWindow: ToplevelManager.activeToplevel
    readonly property string windowTitle: activeWindow?.title ?? ""

    readonly property string mode: recording ? "recording"
        : (camera || microphone) ? "privacy"
        : eventTitle.length > 0 ? "event"
        : mediaActive ? "media"
        : windowTitle.length > 0 ? "window"
        : "idle"

    readonly property string icon: recording ? "●"
        : camera ? "▣"
        : microphone ? "◆"
        : eventTitle.length > 0 ? "✦"
        : mediaActive ? "♪"
        : windowTitle.length > 0 ? "◇"
        : "ラ"

    readonly property string title: recording ? qsTr("Screen capture")
        : camera && microphone ? qsTr("Camera and microphone")
        : camera ? qsTr("Camera in use")
        : microphone ? qsTr("Microphone in use")
        : eventTitle.length > 0 ? eventTitle
        : mediaActive ? (mediaTitle.length > 0 ? mediaTitle : qsTr("Media"))
        : windowTitle.length > 0 ? windowTitle
        : qsTr("Raohane")

    readonly property string detail: {
        if (recording)
            return RaohanePrivacy.recordingApp || qsTr("Screen sharing or recording")
        if (camera && microphone)
            return RaohanePrivacy.cameraApp || RaohanePrivacy.microphoneApp || qsTr("Privacy capture active")
        if (camera)
            return RaohanePrivacy.cameraApp || qsTr("Privacy capture active")
        if (microphone)
            return RaohanePrivacy.microphoneApp || qsTr("Privacy capture active")
        if (eventTitle.length > 0)
            return eventDetail
        if (mediaActive)
            return mediaArtist
        if (windowTitle.length > 0)
            return qsTr("Active window")
        return "ラオハネ"
    }

    function showEvent(title: string, detail: string): void {
        eventTitle = title
        eventDetail = detail
        eventTimer.restart()
    }

    function clearTransientEvent(): void {
        eventTitle = ""
        eventDetail = ""
        eventTimer.stop()
    }

    function clear(): void {
        clearTransientEvent()
    }

    function statusJson(): string {
        return JSON.stringify({
            mode: mode,
            recording: recording,
            microphone: microphone,
            camera: camera,
            unclassifiedVideoCapture: RaohanePrivacy.unclassifiedVideoCaptureActive,
            mediaActive: mediaActive,
            mediaTitle: mediaTitle,
            mediaArtist: mediaArtist,
            windowTitle: windowTitle,
            title: title,
            detail: detail
        })
    }

    Timer {
        id: eventTimer
        interval: 4200
        repeat: false
        onTriggered: {
            root.eventTitle = ""
            root.eventDetail = ""
        }
    }
}
