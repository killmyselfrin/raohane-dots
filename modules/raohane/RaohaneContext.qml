pragma Singleton

import QtQuick
import Quickshell.Wayland
import qs.modules.raohane.services

Item {
    id: root

    property string eventTitle: ""
    property string eventDetail: ""
    property string eventIcon: "auto_awesome"
    property string eventTone: "info"
    property real eventProgress: -1
    property bool eventSignalsReady: false

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

    readonly property string icon: recording ? "screen_record"
        : camera ? "videocam"
        : microphone ? "mic"
        : eventTitle.length > 0 ? eventIcon
        : mediaActive ? "music_note"
        : windowTitle.length > 0 ? "web_asset"
        : "circle"

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
        return qsTr("Hyprland shell")
    }

    function showEvent(title, detail, icon, tone, progress, duration): void {
        if (root.recording || root.camera || root.microphone)
            return
        root.eventTitle = String(title ?? "")
        root.eventDetail = String(detail ?? "")
        root.eventIcon = String(icon ?? "auto_awesome")
        root.eventTone = String(tone ?? "info")
        const numericProgress = Number(progress)
        root.eventProgress = Number.isFinite(numericProgress) ? Math.max(-1, Math.min(1, numericProgress)) : -1
        eventTimer.interval = Math.max(1100, Number(duration) || 2600)
        eventTimer.restart()
    }

    function clearTransientEvent(): void {
        root.eventTitle = ""
        root.eventDetail = ""
        root.eventIcon = "auto_awesome"
        root.eventTone = "info"
        root.eventProgress = -1
        eventTimer.stop()
    }

    function clear(): void {
        clearTransientEvent()
    }

    function showAudioEvent(): void {
        if (!root.eventSignalsReady || !RaohaneAudio.ready)
            return
        const percent = Math.round(RaohaneAudio.volume * 100)
        root.showEvent(
            RaohaneAudio.muted ? qsTr("Volume muted") : qsTr("Volume"),
            RaohaneAudio.sinkName.length > 0
                ? qsTr("%1% · %2").arg(percent).arg(RaohaneAudio.sinkName)
                : qsTr("%1%").arg(percent),
            RaohaneAudio.muted ? "volume_off" : percent > 66 ? "volume_up" : percent > 0 ? "volume_down" : "volume_mute",
            RaohaneAudio.muted ? "warning" : "accent",
            RaohaneAudio.muted ? 0 : RaohaneAudio.volume,
            2100
        )
    }

    function showMicrophoneEvent(): void {
        if (!root.eventSignalsReady || !RaohaneAudio.microphoneReady)
            return
        const percent = Math.round(RaohaneAudio.microphoneVolume * 100)
        root.showEvent(
            RaohaneAudio.microphoneMuted ? qsTr("Microphone muted") : qsTr("Microphone"),
            RaohaneAudio.sourceName.length > 0
                ? qsTr("%1% · %2").arg(percent).arg(RaohaneAudio.sourceName)
                : qsTr("%1%").arg(percent),
            RaohaneAudio.microphoneMuted ? "mic_off" : "mic",
            RaohaneAudio.microphoneMuted ? "warning" : "accent",
            RaohaneAudio.microphoneMuted ? 0 : RaohaneAudio.microphoneVolume,
            2200
        )
    }

    function showNetworkEvent(): void {
        if (!root.eventSignalsReady)
            return
        root.showEvent(
            RaohaneNetwork.wifiConnected ? qsTr("Wi-Fi connected") : qsTr("Wi-Fi disconnected"),
            RaohaneNetwork.wifiConnected
                ? (RaohaneNetwork.networkName || qsTr("Wireless network"))
                : qsTr("No wireless connection"),
            RaohaneNetwork.materialSymbol,
            RaohaneNetwork.wifiConnected ? "success" : "warning",
            -1,
            2700
        )
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
            detail: detail,
            eventTone: eventTone,
            eventProgress: eventProgress
        })
    }

    Connections {
        target: RaohanePrivacy

        function onRecordingActiveChanged(): void {
            if (RaohanePrivacy.recordingActive)
                root.clearTransientEvent()
        }
        function onCameraActiveChanged(): void {
            if (RaohanePrivacy.cameraActive)
                root.clearTransientEvent()
        }
        function onMicrophoneActiveChanged(): void {
            if (RaohanePrivacy.microphoneActive)
                root.clearTransientEvent()
        }
    }

    Connections {
        target: RaohaneAudio
        function onVolumeChanged(): void { audioEventTimer.restart() }
        function onMutedChanged(): void { audioEventTimer.restart() }
        function onMicrophoneVolumeChanged(): void { microphoneEventTimer.restart() }
        function onMicrophoneMutedChanged(): void { microphoneEventTimer.restart() }
    }

    Connections {
        target: RaohaneNetwork
        function onWifiConnectedChanged(): void { networkEventTimer.restart() }
        function onNetworkNameChanged(): void {
            if (RaohaneNetwork.wifiConnected)
                networkEventTimer.restart()
        }
    }

    Connections {
        target: RaohaneBluetooth

        function onConnectedChanged(): void {
            if (!root.eventSignalsReady || !RaohaneBluetooth.available)
                return
            root.showEvent(
                RaohaneBluetooth.connected ? qsTr("Bluetooth connected") : qsTr("Bluetooth disconnected"),
                RaohaneBluetooth.connected && RaohaneBluetooth.firstConnectedName.length > 0
                    ? RaohaneBluetooth.firstConnectedName
                    : qsTr("No connected device"),
                RaohaneBluetooth.connected ? "bluetooth_connected" : "bluetooth",
                RaohaneBluetooth.connected ? "success" : "info",
                -1,
                2800
            )
        }
    }

    Connections {
        target: RaohaneNotifications

        function onSilentChanged(): void {
            if (!root.eventSignalsReady)
                return
            root.showEvent(
                RaohaneNotifications.silent ? qsTr("Do Not Disturb") : qsTr("Notifications on"),
                RaohaneNotifications.silent ? qsTr("Notification popups are paused") : qsTr("Notification popups are enabled"),
                RaohaneNotifications.silent ? "notifications_off" : "notifications_active",
                RaohaneNotifications.silent ? "warning" : "success",
                -1,
                2500
            )
        }
    }

    Connections {
        target: RaohanePerformance

        function onGameModeActiveChanged(): void {
            if (!root.eventSignalsReady)
                return
            root.showEvent(
                RaohanePerformance.gameModeActive ? qsTr("Performance mode") : qsTr("Desktop effects restored"),
                RaohanePerformance.gameModeActive ? qsTr("Low-latency shell profile") : qsTr("Normal visual profile"),
                "speed",
                RaohanePerformance.gameModeActive ? "accent" : "success",
                -1,
                2600
            )
        }
    }

    Timer {
        id: audioEventTimer
        interval: 70
        repeat: false
        onTriggered: root.showAudioEvent()
    }

    Timer {
        id: microphoneEventTimer
        interval: 70
        repeat: false
        onTriggered: root.showMicrophoneEvent()
    }

    Timer {
        id: networkEventTimer
        interval: 120
        repeat: false
        onTriggered: root.showNetworkEvent()
    }

    Timer {
        id: signalArmTimer
        interval: 1600
        repeat: false
        running: true
        onTriggered: root.eventSignalsReady = true
    }

    Timer {
        id: eventTimer
        interval: 2600
        repeat: false
        onTriggered: root.clearTransientEvent()
    }
}
