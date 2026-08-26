pragma Singleton

import QtQuick
import Quickshell.Wayland
import qs.services

Item {
    id: root

    // Ephemeral context signals. Recording/privacy wiring is intentionally kept
    // separate from the live media/window bindings below so those integrations
    // can be migrated without destabilising the existing capture stack.
    property bool recording: false
    property bool microphone: false
    property bool camera: false
    property string eventTitle: ""
    property string eventDetail: ""

    readonly property var activePlayer: MprisController.activePlayer
    readonly property var activeTrack: MprisController.activeTrack
    readonly property bool mediaActive: activePlayer !== null
    readonly property string mediaTitle: activeTrack?.title ?? ""
    readonly property string mediaArtist: activeTrack?.artist ?? ""

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

    readonly property string title: recording ? qsTr("Recording")
        : camera ? qsTr("Camera in use")
        : microphone ? qsTr("Microphone in use")
        : eventTitle.length > 0 ? eventTitle
        : mediaActive ? (mediaTitle.length > 0 ? mediaTitle : qsTr("Media"))
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
        eventTimer.stop()
    }

    function statusJson(): string {
        return JSON.stringify({
            mode: mode,
            recording: recording,
            microphone: microphone,
            camera: camera,
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
