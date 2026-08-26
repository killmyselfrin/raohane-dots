pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml.Models
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property MprisPlayer activePlayer: null
    readonly property list<MprisPlayer> players: Mpris.players.values.filter(player => root.acceptPlayer(player))

    readonly property bool available: activePlayer !== null
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canSeek: activePlayer?.canSeek ?? false

    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property real position: activePlayer?.position ?? 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0

    function acceptPlayer(player): bool {
        if (!player)
            return false

        const bus = player.dbusName ?? ""
        if (bus.startsWith("org.mpris.MediaPlayer2.playerctld"))
            return false

        // Ignore the non-instance MPD compatibility bus when an instance bus is
        // available. This prevents a common duplicate without depending on any
        // external shell configuration.
        if (bus.endsWith(".mpd") && !bus.endsWith("MediaPlayer2.mpd"))
            return false

        return true
    }

    function chooseBestPlayer(): void {
        const candidates = root.players
        if (candidates.length === 0) {
            root.activePlayer = null
            return
        }

        const playing = candidates.find(player => player.isPlaying)
        if (playing) {
            root.activePlayer = playing
            return
        }

        if (root.activePlayer && candidates.includes(root.activePlayer))
            return

        root.activePlayer = candidates[0]
    }

    function promote(player): void {
        if (!root.acceptPlayer(player))
            return
        if (player.isPlaying || root.activePlayer === null)
            root.activePlayer = player
    }

    function togglePlaying(): void {
        if (root.canTogglePlaying)
            root.activePlayer.togglePlaying()
    }

    function previous(): void {
        if (root.canGoPrevious)
            root.activePlayer.previous()
    }

    function next(): void {
        if (root.canGoNext)
            root.activePlayer.next()
    }

    function seekRatio(ratio: real): void {
        if (!root.canSeek || root.length <= 0)
            return
        root.activePlayer.position = Math.max(0, Math.min(1, ratio)) * root.length
    }

    function pauseAll(): void {
        for (const player of root.players) {
            if (player.canPause)
                player.pause()
        }
    }

    onPlayersChanged: Qt.callLater(root.chooseBestPlayer)

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: root.promote(modelData)
            Component.onDestruction: Qt.callLater(root.chooseBestPlayer)

            function onPlaybackStateChanged(): void {
                if (modelData.isPlaying)
                    root.activePlayer = modelData
                else if (root.activePlayer === modelData)
                    Qt.callLater(root.chooseBestPlayer)
            }

            function onPostTrackChanged(): void {
                if (modelData.isPlaying)
                    root.activePlayer = modelData
            }
        }
    }

    IpcHandler {
        target: "raohaneMpris"

        function playPause(): void { root.togglePlaying() }
        function previous(): void { root.previous() }
        function next(): void { root.next() }
        function pauseAll(): void { root.pauseAll() }
    }
}
