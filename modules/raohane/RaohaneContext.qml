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
    property bool sceneTransitionMuted: false

    readonly property bool gameplayRecording: RaohaneRecorder.recording
    readonly property bool recording: root.gameplayRecording || RaohanePrivacy.recordingActive
    readonly property bool microphone: RaohanePrivacy.microphoneActive
    readonly property bool camera: RaohanePrivacy.cameraActive

    // The Context Island is the compact media surface. Once the dedicated
    // overlay is open, do not repeat the same track in two places; fall
    // through to the active Scene/window while keeping recording, privacy and
    // transient events at their higher priorities.
    readonly property bool mediaOverlayVisible: RaohaneState.mediaOverlayOpen
    readonly property bool mediaActive: RaohaneMedia.available && !root.mediaOverlayVisible
    readonly property string mediaTitle: RaohaneMedia.title
    readonly property string mediaArtist: RaohaneMedia.artist

    readonly property string sceneId: RaohaneScenes.activeSceneId
    readonly property bool sceneActive: root.sceneId !== "balanced"
    readonly property bool sceneAutomatic: RaohaneScenes.autoSceneActive
    readonly property string sceneSourceAppId: RaohaneScenes.autoSourceAppId
    readonly property var sceneRule: RaohaneScenes.activeRule
    readonly property string sceneRulePattern: String(root.sceneRule?.pattern ?? "")
    readonly property string sceneRuleMatch: String(root.sceneRule?.match ?? "")
    readonly property bool sceneRuleBuiltin: Boolean(root.sceneRule?.builtin ?? false)

    readonly property var activeWindow: ToplevelManager.activeToplevel
    readonly property string windowTitle: activeWindow?.title ?? ""

    readonly property string mode: recording ? "recording"
        : (camera || microphone) ? "privacy"
        : eventTitle.length > 0 ? "event"
        : mediaActive ? "media"
        : sceneActive ? "scene"
        : windowTitle.length > 0 ? "window"
        : "idle"

    readonly property string icon: recording ? "screen_record"
        : camera ? "videocam"
        : microphone ? "mic"
        : eventTitle.length > 0 ? eventIcon
        : mediaActive ? "music_note"
        : sceneActive ? root.sceneIcon(root.sceneId)
        : windowTitle.length > 0 ? "web_asset"
        : "circle"

    readonly property string title: gameplayRecording ? qsTr("Gameplay recording")
        : recording ? qsTr("Screen capture")
        : camera && microphone ? qsTr("Camera and microphone")
        : camera ? qsTr("Camera in use")
        : microphone ? qsTr("Microphone in use")
        : eventTitle.length > 0 ? eventTitle
        : mediaActive ? (mediaTitle.length > 0 ? mediaTitle : qsTr("Media"))
        : sceneActive ? root.sceneLabel(root.sceneId)
        : windowTitle.length > 0 ? windowTitle
        : qsTr("Raohane")

    readonly property string detail: {
        if (gameplayRecording) {
            if (RaohaneRecorder.ownedRecording)
                return qsTr("Recording · %1").arg(RaohaneRecorder.elapsedText)
            return qsTr("wf-recorder is active")
        }
        if (RaohanePrivacy.recordingActive)
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
        if (sceneActive)
            return root.sceneActivityDetail()
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

    function sceneLabel(sceneId: string): string {
        switch (sceneId) {
        case "gaming": return qsTr("Gaming scene")
        case "focus": return qsTr("Focus scene")
        case "work": return qsTr("Work scene")
        default: return qsTr("Balanced scene")
        }
    }

    function sceneDetail(sceneId: string): string {
        switch (sceneId) {
        case "gaming": return qsTr("DND, Keep Awake and Game Mode enabled")
        case "focus": return qsTr("Distractions reduced for focused work")
        case "work": return qsTr("Keep Awake enabled for a work session")
        default: return qsTr("Previous runtime state restored")
        }
    }

    function sceneIcon(sceneId: string): string {
        switch (sceneId) {
        case "gaming": return "sports_esports"
        case "focus": return "center_focus_strong"
        case "work": return "work"
        default: return "tune"
        }
    }

    function sceneActivityDetail(): string {
        if (!root.sceneAutomatic)
            return qsTr("Manual scene · selected by user")
        if (root.sceneSourceAppId.length === 0)
            return qsTr("Automatic scene")
        if (!root.sceneRule)
            return qsTr("Auto · %1").arg(root.sceneSourceAppId)
        return qsTr("Auto · %1 · %2:%3")
            .arg(root.sceneSourceAppId)
            .arg(root.sceneRuleMatch)
            .arg(root.sceneRulePattern)
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

        if (!RaohaneNetwork.wifiEnabled) {
            root.showEvent(
                qsTr("Wi-Fi off"),
                qsTr("Wireless radio is disabled"),
                "signal_wifi_off",
                "info",
                -1,
                2400
            )
            return
        }

        if (RaohaneNetwork.wifiConnected) {
            root.showEvent(
                qsTr("Wi-Fi connected"),
                RaohaneNetwork.networkName || qsTr("Wireless network"),
                RaohaneNetwork.materialSymbol,
                "success",
                -1,
                2700
            )
            return
        }

        root.showEvent(
            qsTr("Wi-Fi on"),
            qsTr("Not connected"),
            RaohaneNetwork.materialSymbol,
            "info",
            -1,
            2400
        )
    }

    function statusJson(): string {
        return JSON.stringify({
            mode: mode,
            recording: recording,
            gameplayRecording: gameplayRecording,
            recorderOwned: RaohaneRecorder.ownedRecording,
            recorderElapsed: RaohaneRecorder.elapsedSeconds,
            microphone: microphone,
            camera: camera,
            unclassifiedVideoCapture: RaohanePrivacy.unclassifiedVideoCaptureActive,
            mediaActive: mediaActive,
            mediaOverlayVisible: mediaOverlayVisible,
            mediaTitle: mediaTitle,
            mediaArtist: mediaArtist,
            windowTitle: windowTitle,
            title: title,
            detail: detail,
            eventTone: eventTone,
            eventProgress: eventProgress,
            scene: sceneId,
            sceneAutomatic: sceneAutomatic,
            sceneSourceAppId: sceneSourceAppId,
            sceneRulePattern: sceneRulePattern,
            sceneRuleMatch: sceneRuleMatch,
            sceneRuleBuiltin: sceneRuleBuiltin,
            sceneTransitionMuted: sceneTransitionMuted
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
        target: RaohaneRecorder

        function onRecordingChanged(): void {
            if (RaohaneRecorder.recording) {
                root.clearTransientEvent()
                return
            }
            if (!root.eventSignalsReady)
                return
            root.showEvent(
                qsTr("Recording stopped"),
                qsTr("Gameplay capture finished"),
                "stop_circle",
                "success",
                -1,
                2400
            )
        }

        function onLastErrorChanged(): void {
            if (!root.eventSignalsReady || RaohaneRecorder.lastError.length === 0)
                return
            root.showEvent(
                qsTr("Recording unavailable"),
                RaohaneRecorder.lastError,
                "error",
                "warning",
                -1,
                3000
            )
        }
    }

    Connections {
        target: RaohaneScenes

        function onSceneActivated(sceneId: string, source: string): void {
            if (!root.eventSignalsReady)
                return
            root.sceneTransitionMuted = true
            sceneTransitionTimer.restart()
            root.showEvent(
                root.sceneLabel(sceneId),
                root.sceneDetail(sceneId),
                root.sceneIcon(sceneId),
                sceneId === "balanced" ? "success" : "accent",
                -1,
                2800
            )
        }

        function onPolicyApplied(sceneId: string): void {
            if (!root.sceneTransitionMuted)
                return
            sceneTransitionTimer.restart()
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
        function onWifiEnabledChanged(): void { networkEventTimer.restart() }
        function onWifiConnectedChanged(): void { networkEventTimer.restart() }
        function onNetworkNameChanged(): void {
            if (RaohaneNetwork.wifiConnected)
                networkEventTimer.restart()
        }
    }

    Connections {
        target: RaohaneBluetooth

        function onPowerApplied(enabled: bool): void {
            if (!root.eventSignalsReady)
                return
            root.showEvent(
                enabled ? qsTr("Bluetooth on") : qsTr("Bluetooth off"),
                enabled ? qsTr("Ready for nearby devices") : qsTr("Bluetooth radio disabled"),
                enabled ? "bluetooth" : "bluetooth_disabled",
                enabled ? "success" : "info",
                -1,
                2400
            )
        }

        function onConnectedChanged(): void {
            if (!root.eventSignalsReady || !RaohaneBluetooth.available || !RaohaneBluetooth.enabled || RaohaneBluetooth.busy)
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
            if (!root.eventSignalsReady || root.sceneTransitionMuted)
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

        function onGameModeApplied(enabled: bool): void {
            if (!root.eventSignalsReady || root.sceneTransitionMuted)
                return
            root.showEvent(
                enabled ? qsTr("Performance mode") : qsTr("Desktop effects restored"),
                enabled ? qsTr("Low-latency shell profile") : qsTr("Normal visual profile"),
                "speed",
                enabled ? "accent" : "success",
                -1,
                2600
            )
        }
    }

    Connections {
        target: RaohaneEasyEffects

        function onActiveApplied(enabled: bool): void {
            if (!root.eventSignalsReady)
                return
            root.showEvent(
                enabled ? qsTr("EasyEffects enabled") : qsTr("EasyEffects bypassed"),
                enabled ? qsTr("Audio processing is active") : qsTr("Audio processing is off"),
                "instant_mix",
                enabled ? "accent" : "info",
                -1,
                2400
            )
        }
    }

    Connections {
        target: RaohaneIdle

        function onInhibitChanged(): void {
            if (!root.eventSignalsReady || root.sceneTransitionMuted)
                return
            root.showEvent(
                RaohaneIdle.inhibit ? qsTr("Keep Awake") : qsTr("Normal idle"),
                RaohaneIdle.inhibit ? qsTr("Automatic idle is temporarily blocked") : qsTr("Automatic idle is restored"),
                RaohaneIdle.inhibit ? "coffee" : "bedtime",
                RaohaneIdle.inhibit ? "accent" : "success",
                -1,
                2400
            )
        }
    }

    Connections {
        target: RaohaneDisplay

        function onTemperatureActiveChanged(): void {
            if (!root.eventSignalsReady)
                return
            root.showEvent(
                RaohaneDisplay.temperatureActive ? qsTr("Night Light") : qsTr("Night Light off"),
                RaohaneDisplay.temperatureActive ? qsTr("Warm display temperature enabled") : qsTr("Normal display temperature restored"),
                RaohaneDisplay.temperatureActive ? "bedtime" : "light_mode",
                RaohaneDisplay.temperatureActive ? "accent" : "success",
                -1,
                2400
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
        interval: 140
        repeat: false
        onTriggered: root.showNetworkEvent()
    }

    Timer {
        id: sceneTransitionTimer
        interval: 1800
        repeat: false
        onTriggered: root.sceneTransitionMuted = false
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
