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

    readonly property var sceneIds: ["balanced", "gaming", "focus", "work"]
    readonly property var activePolicy: root.policyFor(root.activeSceneId)
    readonly property bool gaming: root.activeSceneId === "gaming"

    signal sceneActivated(string sceneId, string source)

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

    function activate(sceneId, source): bool {
        const next = root.sanitizeSceneId(sceneId)
        if (!root.sceneIds.includes(String(sceneId ?? "").trim().toLowerCase()))
            return false

        root.activationSource = String(source ?? "manual") || "manual"
        if (root.activeSceneId !== next)
            root.activeSceneId = next
        else if (root.ready)
            saveTimer.restart()

        root.sceneActivated(next, root.activationSource)
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
        root.ready = true
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

    Timer {
        id: saveTimer
        interval: 120
        repeat: false
        onTriggered: root.saveNow()
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
