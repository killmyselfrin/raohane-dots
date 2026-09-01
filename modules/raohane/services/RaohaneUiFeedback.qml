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
    property real volume: 0.16
    property bool ready: false
    property double lastPlayedAt: 0

    readonly property string soundDirectory: RaohanePaths.join(RaohanePaths.cacheDirectory, "sounds")

    function canPlay(): bool {
        if (!root.enabled || !root.ready)
            return false
        const now = Date.now()
        if (now - root.lastPlayedAt < 24)
            return false
        root.lastPlayedAt = now
        return true
    }

    function play(kind: string): void {
        if (!root.canPlay())
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

    function tap(): void { root.play("tap") }
    function navigate(): void { root.play("navigate") }
    function confirm(): void { root.play("confirm") }

    SoundEffect {
        id: tapSound
        source: RaohanePaths.fileUrl(RaohanePaths.join(root.soundDirectory, "ui-tap.wav"))
        volume: root.volume
    }

    SoundEffect {
        id: navigateSound
        source: RaohanePaths.fileUrl(RaohanePaths.join(root.soundDirectory, "ui-navigate.wav"))
        volume: Math.max(0, root.volume * 0.84)
    }

    SoundEffect {
        id: confirmSound
        source: RaohanePaths.fileUrl(RaohanePaths.join(root.soundDirectory, "ui-confirm.wav"))
        volume: Math.max(0, root.volume * 0.92)
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
            if (exitCode !== 0)
                console.warn("[RaohaneUiFeedback] Could not prepare UI sounds")
        }
    }

    Component.onCompleted: generator.running = true
}