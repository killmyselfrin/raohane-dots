pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property bool ready: false
    property string activeSceneId: "balanced"
    property string activationSource: "startup"

    property bool baselineCaptured: false
    property bool baselineDnd: false
    property bool baselineKeepAwake: false
    property bool baselineGameMode: false
    property bool restoringBaseline: false
    property bool desiredGameMode: false

    readonly property var sceneIds: ["balanced", "gaming", "focus", "work"]
    readonly property var activePolicy: root.policyFor(root.activeSceneId)
    readonly property bool gaming: root.activeSceneId === "gaming"

    signal sceneActivated(string sceneId, string source)
    signal policyApplied(string sceneId)

    function sanitizeSceneId(value): string {
        const requested = String(value ?? "").trim().toLowerCase()
        return root.sceneIds.includes(requested) ? requested : "balanced"
    }

    function policyFor(sceneId): var {
        switch (root.sanitizeSceneId(sceneId)) {
        case "gaming":
            return {
                notificationPolicy: "dnd",
                keepAwake: true,
                dockPolicy: "hide",
                contextMode: "gaming",
                gameMode: true,
                motionHint: "fast"
            }
        case "focus":
            return {
                notificationPolicy: "dnd",
                keepAwake: false,
                dockPolicy: "hide",
                contextMode: "focus",
                gameMode: false,
                motionHint: "quiet"
            }
        case "work":
            return {
                notificationPolicy: "inherit",
                keepAwake: true,
                dockPolicy: "inherit",
                contextMode: "work",
                gameMode: false,
                motionHint: "balanced"
            }
        default:
            return {
                notificationPolicy: "inherit",
                keepAwake: false,
                dockPolicy: "inherit",
                contextMode: "default",
                gameMode: false,
                motionHint: "balanced"
            }
        }
    }

    function captureBaseline(): void {
        if (root.baselineCaptured)
            return
        root.baselineDnd = RaohaneNotifications.silent
        root.baselineKeepAwake = RaohaneIdle.inhibit
        root.baselineGameMode = RaohanePerformance.gameModeActive
        root.baselineCaptured = true
    }

    function requestGameMode(enabled: bool): void {
        root.desiredGameMode = Boolean(enabled)
        if (RaohanePerformance.busy) {
            gameModeRetry.restart()
            return
        }
        if (RaohanePerformance.gameModeActive !== root.desiredGameMode)
            RaohanePerformance.setGameMode(root.desiredGameMode)
        else
            root.finishBaselineRestoreIfReady()
    }

    function finishBaselineRestoreIfReady(): void {
        if (!root.restoringBaseline)
            return
        if (RaohanePerformance.busy || RaohanePerformance.gameModeActive !== root.desiredGameMode)
            return
        root.restoringBaseline = false
        root.baselineCaptured = false
    }

    function applyActivePolicy(): void {
        if (!root.ready)
            return

        if (root.activeSceneId === "balanced") {
            if (!root.baselineCaptured)
                return
            root.restoringBaseline = true
            RaohaneNotifications.silent = root.baselineDnd
            RaohaneIdle.setInhibit(root.baselineKeepAwake)
            root.requestGameMode(root.baselineGameMode)
            root.policyApplied(root.activeSceneId)
            return
        }

        root.restoringBaseline = false
        root.captureBaseline()
        const policy = root.activePolicy
        RaohaneNotifications.silent = policy.notificationPolicy === "dnd"
            ? true
            : root.baselineDnd
        RaohaneIdle.setInhibit(policy.keepAwake ? true : root.baselineKeepAwake)
        root.requestGameMode(Boolean(policy.gameMode))
        root.policyApplied(root.activeSceneId)
    }

    function activate(sceneId, source): bool {
        const requested = String(sceneId ?? "").trim().toLowerCase()
        if (!root.sceneIds.includes(requested))
            return false

        root.activationSource = String(source ?? "manual") || "manual"
        if (root.activeSceneId !== requested)
            root.activeSceneId = requested
        else if (root.ready)
            saveTimer.restart()

        root.sceneActivated(requested, root.activationSource)
        sceneApplyTimer.restart()
        return true
    }

    function reset(source): void {
        root.activate("balanced", source ?? "manual")
    }

    function snapshot(): var {
        return {
            version: 1,
            activeScene: root.activeSceneId
        }
    }

    function loadState(text: string): void {
        try {
            const parsed = JSON.parse(text)
            root.activeSceneId = root.sanitizeSceneId(parsed?.activeScene)
        } catch (error) {
            console.warn("[RaohaneScenes] Invalid scene state, using balanced:", error)
            root.activeSceneId = "balanced"
        }
        root.activationSource = "startup"
        root.ready = true
        startupApply.restart()
    }

    function saveNow(): void {
        if (!root.ready)
            return
        stateFile.setText(JSON.stringify(root.snapshot(), null, 2) + "\n")
    }

    onActiveSceneIdChanged: {
        if (root.ready)
            saveTimer.restart()
    }

    Connections {
        target: RaohanePerformance

        function onGameModeApplied(enabled: bool): void {
            if (enabled !== root.desiredGameMode)
                gameModeRetry.restart()
            else
                root.finishBaselineRestoreIfReady()
        }
    }

    Timer {
        id: saveTimer
        interval: 120
        repeat: false
        onTriggered: root.saveNow()
    }

    Timer {
        id: sceneApplyTimer
        interval: 20
        repeat: false
        onTriggered: root.applyActivePolicy()
    }

    Timer {
        id: startupApply
        interval: 900
        repeat: false
        onTriggered: root.applyActivePolicy()
    }

    Timer {
        id: gameModeRetry
        interval: 220
        repeat: false
        onTriggered: root.requestGameMode(root.desiredGameMode)
    }

    Process {
        id: ensureStateDirectory
        command: ["mkdir", "-p", RaohanePaths.stateDirectory]
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                console.warn("[RaohaneScenes] Could not create state directory")
                root.ready = true
                return
            }
            stateFile.reload()
        }
    }

    FileView {
        id: stateFile
        path: RaohanePaths.sceneStateFile
        onLoaded: root.loadState(stateFile.text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                root.ready = true
                saveTimer.restart()
            } else {
                console.warn("[RaohaneScenes] Could not load scene state:", error)
                root.ready = true
            }
        }
    }

    IpcHandler {
        target: "scenes"

        function current(): string {
            return root.activeSceneId
        }

        function list(): string {
            return JSON.stringify(root.sceneIds)
        }

        function activate(sceneId: string): string {
            return root.activate(sceneId, "ipc") ? root.activeSceneId : "invalid-scene"
        }

        function reset(): string {
            root.reset("ipc")
            return root.activeSceneId
        }
    }

    Component.onCompleted: ensureStateDirectory.running = true
}
