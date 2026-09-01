pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell

Singleton {
    id: root

    property bool enabled: true
    property real volume: 0.16
    property double lastPlayedAt: 0

    function canPlay(): bool {
        if (!root.enabled)
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
        source: Quickshell.shellPath("assets/sounds/ui-tap.wav")
        volume: root.volume
    }

    SoundEffect {
        id: navigateSound
        source: Quickshell.shellPath("assets/sounds/ui-navigate.wav")
        volume: Math.max(0, root.volume * 0.84)
    }

    SoundEffect {
        id: confirmSound
        source: Quickshell.shellPath("assets/sounds/ui-confirm.wav")
        volume: Math.max(0, root.volume * 0.92)
    }
}