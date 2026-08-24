pragma Singleton

import QtQuick

Item {
    id: root

    property bool recording: false
    property bool microphone: false
    property bool camera: false
    property string eventTitle: ""
    property string eventDetail: ""
    property bool mediaActive: false
    property string mediaTitle: ""
    property string mediaArtist: ""
    property string windowTitle: ""

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

    readonly property string title: recording ? qsTr("Recording")
        : camera ? qsTr("Camera in use")
        : microphone ? qsTr("Microphone in use")
        : eventTitle.length > 0 ? eventTitle
        : mediaActive ? mediaTitle
        : windowTitle.length > 0 ? windowTitle
        : qsTr("Raohane")

    readonly property string detail: recording ? qsTr("Privacy indicator")
        : camera && microphone ? qsTr("Camera and microphone")
        : camera ? qsTr("Privacy indicator")
        : microphone ? qsTr("Privacy indicator")
        : eventTitle.length > 0 ? eventDetail
        : mediaActive ? mediaArtist
        : windowTitle.length > 0 ? qsTr("Active window")
        : "ラオハネ"

    function showEvent(title: string, detail: string): void {
        eventTitle = title
        eventDetail = detail
        eventTimer.restart()
    }

    function clear(): void {
        recording = false
        microphone = false
        camera = false
        eventTitle = ""
        eventDetail = ""
        mediaActive = false
        mediaTitle = ""
        mediaArtist = ""
        windowTitle = ""
        eventTimer.stop()
    }

    function statusJson(): string {
        return JSON.stringify({
            mode: mode,
            recording: recording,
            microphone: microphone,
            camera: camera,
            mediaActive: mediaActive,
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
