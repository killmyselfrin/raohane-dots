pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Io

import qs.modules.raohane.config

Singleton {
    id: root

    property bool enabled: true
    property real volume: 0.42
    property bool ready: false
    property double lastPlayedAt: 0
    property string pendingExternalKind: "tap"

    readonly property string soundDirectory: RaohanePaths.join(RaohanePaths.cacheDirectory, "sounds")

    function canPlay(): bool {
        if (!root.enabled)
            return false
        const now = Date.now()
        if (now - root.lastPlayedAt < 28)
            return false
        root.lastPlayedAt = now
        return true
    }

    function soundFile(kind: string): string {
        switch (kind) {
        case "navigate":
            return RaohanePaths.join(root.soundDirectory, "ui-navigate.wav")
        case "confirm":
            return RaohanePaths.join(root.soundDirectory, "ui-confirm.wav")
        default:
            return RaohanePaths.join(root.soundDirectory, "ui-tap.wav")
        }
    }

    function playQt(kind: string): void {
        if (!root.ready)
            return
        switch (kind) {
        case "navigate":
            navigateSound.play()
            break
        case "confirm":
            confirmSound.play()
            break
        default:
            tapSound.play()
            break
        }
    }

    function play(kind: string): void {
        const normalizedKind = kind === "navigate" || kind === "confirm" ? kind : "tap"
        if (!root.canPlay())
            return

        // The helper now owns preparation as well as playback. This makes every
        // click self-healing when ~/.cache was cleared or the startup generator
        // failed before PipeWire/QtMultimedia became available.
        if (!externalPlayer.running) {
            root.pendingExternalKind = normalizedKind
            externalPlayer.command = [
                "bash",
                RaohanePaths.join(RaohanePaths.scriptsPath, "play-ui-sound.sh"),
                root.soundDirectory,
                normalizedKind
            ]
            externalPlayer.running = true
            return
        }

        root.playQt(normalizedKind)
    }

    SoundEffect {
        id: tapSound
        source: root.ready ? RaohanePaths.fileUrl(root.soundFile("tap")) : ""
        volume: root.volume
    }

    SoundEffect {
        id: navigateSound
        source: root.ready ? RaohanePaths.fileUrl(root.soundFile("navigate")) : ""
        volume: Math.max(0, root.volume * 0.86)
    }

    SoundEffect {
        id: confirmSound
        source: root.ready ? RaohanePaths.fileUrl(root.soundFile("confirm")) : ""
        volume: Math.max(0, root.volume * 0.92)
    }

    Process {
        id: externalPlayer

        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                root.ready = true
                return
            }
            console.warn("RaohaneUiFeedback: native player failed with exit code", exitCode)
            root.playQt(root.pendingExternalKind)
        }
    }

    Process {
        id: generator
        command: [
            "python3",
            RaohanePaths.join(RaohanePaths.scriptsPath, "generate-ui-sounds.py"),
            root.soundDirectory
        ]

        onExited: (exitCode, exitStatus) => {
            root.ready = exitCode === 0
            if (!root.ready)
                console.warn("RaohaneUiFeedback: startup sound preparation failed; playback helper will retry on demand")
        }
    }

    Component.onCompleted: generator.running = true
}
