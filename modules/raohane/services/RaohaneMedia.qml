pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Singleton {
    id: root

    property MprisPlayer activePlayer: null
    property real livePosition: 0

    readonly property list<MprisPlayer> players: Mpris.players.values.filter(player => root.acceptPlayer(player))
    readonly property int playerCount: players.length
    readonly property int activePlayerIndex: activePlayer ? players.indexOf(activePlayer) : -1

    readonly property bool available: activePlayer !== null
    readonly property bool isPlaying: activePlayer?.isPlaying ?? false
    readonly property bool canTogglePlaying: activePlayer?.canTogglePlaying ?? false
    readonly property bool canGoPrevious: activePlayer?.canGoPrevious ?? false
    readonly property bool canGoNext: activePlayer?.canGoNext ?? false
    readonly property bool canSeek: (activePlayer?.canSeek ?? false) && (activePlayer?.positionSupported ?? false)
    readonly property bool canRaise: activePlayer?.canRaise ?? false
    readonly property bool canQuit: activePlayer?.canQuit ?? false
    readonly property bool volumeSupported: (activePlayer?.volumeSupported ?? false) && (activePlayer?.canControl ?? false)
    readonly property bool shuffleSupported: (activePlayer?.shuffleSupported ?? false) && (activePlayer?.canControl ?? false)

    readonly property string title: activePlayer?.trackTitle ?? ""
    readonly property string artist: activePlayer?.trackArtist ?? ""
    readonly property string album: activePlayer?.trackAlbum ?? ""
    readonly property string albumArtist: activePlayer?.trackAlbumArtist ?? ""
    readonly property string artUrl: activePlayer?.trackArtUrl ?? ""
    readonly property string playerName: activePlayer?.identity ?? activePlayer?.desktopEntry ?? ""
    readonly property string desktopEntry: activePlayer?.desktopEntry ?? ""
    readonly property string dbusName: activePlayer?.dbusName ?? ""

    readonly property real position: available ? livePosition : 0
    readonly property real length: activePlayer?.length ?? 0
    readonly property real progress: length > 0 ? Math.max(0, Math.min(1, position / length)) : 0
    readonly property real volume: volumeSupported ? Math.max(0, Math.min(1, activePlayer?.volume ?? 1)) : 1
    readonly property bool shuffle: shuffleSupported ? Boolean(activePlayer?.shuffle ?? false) : false

    function acceptPlayer(player): bool {
        if (!player)
            return false

        const bus = player.dbusName ?? ""
        if (bus.startsWith("org.mpris.MediaPlayer2.playerctld"))
            return false

        if (bus.endsWith(".mpd") && !bus.endsWith("MediaPlayer2.mpd"))
            return false

        return true
    }

    function chooseBestPlayer(): void {
        const candidates = root.players
        if (candidates.length === 0) {
            root.activePlayer = null
            root.livePosition = 0
            return
        }

        const playing = candidates.find(player => player.isPlaying)
        if (playing) {
            root.activePlayer = playing
            root.refreshPosition()
            return
        }

        if (root.activePlayer && candidates.includes(root.activePlayer)) {
            root.refreshPosition()
            return
        }

        root.activePlayer = candidates[0]
        root.refreshPosition()
    }

    function promote(player): void {
        if (!root.acceptPlayer(player))
            return
        if (player.isPlaying || root.activePlayer === null) {
            root.activePlayer = player
            root.refreshPosition()
        }
    }

    function selectPlayer(index: int): void {
        if (index < 0 || index >= root.players.length)
            return
        root.activePlayer = root.players[index]
        root.refreshPosition()
    }

    function cyclePlayer(direction: int): void {
        const count = root.players.length
        if (count <= 1)
            return
        const current = root.activePlayerIndex >= 0 ? root.activePlayerIndex : 0
        const nextIndex = (current + (direction >= 0 ? 1 : -1) + count) % count
        root.selectPlayer(nextIndex)
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
        const target = Math.max(0, Math.min(1, ratio)) * root.length
        root.activePlayer.position = target
        root.livePosition = target
    }

    function seekSeconds(offset: real): void {
        if (!root.activePlayer?.canSeek)
            return
        root.activePlayer.seek(offset)
        Qt.callLater(root.refreshPosition)
    }

    function setVolume(value: real): void {
        if (!root.volumeSupported)
            return
        root.activePlayer.volume = Math.max(0, Math.min(1, value))
    }

    function toggleShuffle(): void {
        if (root.shuffleSupported)
            root.activePlayer.shuffle = !root.activePlayer.shuffle
    }

    function raisePlayer(): void {
        if (root.canRaise)
            root.activePlayer.raise()
    }

    function quitPlayer(): void {
        if (root.canQuit)
            root.activePlayer.quit()
    }

    function pauseAll(): void {
        for (const player of root.players) {
            if (player.canPause)
                player.pause()
        }
    }

    function refreshPosition(): void {
        if (!root.activePlayer) {
            root.livePosition = 0
            return
        }
        root.livePosition = Math.max(0, Number(root.activePlayer.position ?? 0))
    }

    function formatTime(seconds: real): string {
        const safe = Math.max(0, Math.floor(Number(seconds) || 0))
        const minutes = Math.floor(safe / 60)
        const remaining = safe % 60
        return minutes + ":" + String(remaining).padStart(2, "0")
    }

    onPlayersChanged: Qt.callLater(root.chooseBestPlayer)
    onActivePlayerChanged: Qt.callLater(root.refreshPosition)

    Timer {
        interval: 500
        repeat: true
        running: root.available
        onTriggered: root.refreshPosition()
    }

    Instantiator {
        model: Mpris.players

        Connections {
            required property MprisPlayer modelData
            target: modelData

            Component.onCompleted: root.promote(modelData)
            Component.onDestruction: Qt.callLater(root.chooseBestPlayer)

            function onPlaybackStateChanged(): void {
                if (modelData.isPlaying) {
                    root.activePlayer = modelData
                    root.refreshPosition()
                } else if (root.activePlayer === modelData) {
                    root.refreshPosition()
                    Qt.callLater(root.chooseBestPlayer)
                }
            }

            function onPostTrackChanged(): void {
                if (modelData.isPlaying || root.activePlayer === modelData) {
                    root.activePlayer = modelData
                    Qt.callLater(root.refreshPosition)
                }
            }
        }
    }

    IpcHandler {
        target: "raohaneMpris"

        function playPause(): void { root.togglePlaying() }
        function previous(): void { root.previous() }
        function next(): void { root.next() }
        function pauseAll(): void { root.pauseAll() }
        function playerNext(): void { root.cyclePlayer(1) }
        function playerPrevious(): void { root.cyclePlayer(-1) }
        function seekForward(): void { root.seekSeconds(10) }
        function seekBack(): void { root.seekSeconds(-10) }
    }
}
