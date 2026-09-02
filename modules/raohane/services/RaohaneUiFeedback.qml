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
    // Keep the Qt path intentionally quiet. The primary PipeWire path plays the
    // pre-mastered WAV directly; this value only applies if that path fails.
    property real volume: 0.32
    property bool ready: false
    property double lastPlayedAt: 0
    property string pendingExternalKind: "tap"

    readonly property string soundDirectory: RaohanePaths.join(RaohanePaths.cacheDirectory, "sounds")

    function canPlay(): bool {
        if (!root.enabled || !root.ready)
            return false
        const now = Date.now()
        if (now - root.lastPlayedAt < 32)
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

        // QtMultimedia can be silent on otherwise healthy PipeWire sessions when
        // its platform/backend plugin is unavailable. Prefer the native PipeWire
        // player and only fall back to SoundEffect if the helper cannot play.
        if (!externalPlayer.running) {
            root.pendingExternalKind = normalizedKind
            externalPlayer.command = [
                "bash",
                Quickshell.shellPath("scripts/play-ui-sound.sh"),
                root.soundFile(normalizedKind)
            ]
            externalPlayer.running = true
            return
        }

        // Do not spawn an unbounded number of short players during rapid input.
        // A click that lands while pw-play is still finishing uses Qt instead.
        root.playQt(normalizedKind)
    }

    SoundEffect {
        id: tapSound
        source: root.ready ? RaohanePaths.fileUrl(RaohanePaths.join(root.soundDirectory, "ui-tap.wav")) : ""
        volume: root.volume
    }

    SoundEffect {
        id: navigateSound
        source: root.ready ? RaohanePaths.fileUrl(RaohanePaths.join(root.soundDirectory, "ui-navigate.wav")) : ""
        volume: Math.max(0, root.volume * 0.82)
    }

    SoundEffect {
        id: confirmSound
        source: root.ready ? RaohanePaths.fileUrl(RaohanePaths.join(root.soundDirectory, "ui-confirm.wav")) : ""
        volume: Math.max(0, root.volume * 0.88)
    }

    Process {
        id: externalPlayer

        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && root.enabled && root.ready)
                root.playQt(root.pendingExternalKind)
        }
    }

    Process {
        id: generator
        command: [
            "python3",
            Quickshell.shellPath("scripts/generate-ui-sounds.py"),
            root.soundDirectory
        ]

        onExited: (exitCode, exitStatus) => {
            root.ready = exitCode === 0
            if (!root.ready)
                console.warn("RaohaneUiFeedback: failed to prepare UI sounds")
        }
    }

    Component.onCompleted: generator.running = true
}
