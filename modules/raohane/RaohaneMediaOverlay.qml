pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    property bool lyricsOpen: false
    property bool lyricsFocus: false

    // The default player lives at a configurable screen edge. Gaming scenes
    // keep their own corner and use an even denser presentation so media
    // controls never sit on the aiming/focus area.
    readonly property bool gamingScene: RaohaneScenes.gaming
    readonly property bool gamingEdgeMode: root.gamingScene && !root.lyricsFocus
    readonly property int gamingAutoHideSeconds: RaohaneConfig.sanitizeMediaOverlayGamingAutoHideSeconds(
        RaohaneConfig.mediaOverlayGamingAutoHideSeconds)
    readonly property bool gamingAutoHideEnabled: root.gamingScene && root.gamingAutoHideSeconds > 0
    readonly property string overlayPosition: root.gamingScene
        ? RaohaneConfig.sanitizeMediaOverlayPosition(RaohaneConfig.mediaOverlayGamingPosition)
        : RaohaneConfig.sanitizeMediaOverlayPosition(RaohaneConfig.mediaOverlayPosition)
    readonly property bool positionLeft: root.overlayPosition.endsWith("-left")
    readonly property bool positionRight: root.overlayPosition.endsWith("-right")
    readonly property bool positionTop: root.overlayPosition.startsWith("top-")
    readonly property bool positionBottom: root.overlayPosition.startsWith("bottom-")

    readonly property color lyricsFocusForeground: "#fffdfc"
    readonly property color lyricsFocusSecondary: "#e7e5ef"
    readonly property color lyricsFocusHalo: Qt.rgba(0.01, 0.012, 0.02, 0.88)

    readonly property color playerAccent: RaohaneCoverAccent.available
        ? RaohaneCoverAccent.accent
        : RaohaneTheme.accent
    readonly property real lyricsFocusAccentMix: 0.30
    readonly property color lyricsFocusActive: Qt.rgba(
        root.lyricsFocusForeground.r * (1 - root.lyricsFocusAccentMix) + root.playerAccent.r * root.lyricsFocusAccentMix,
        root.lyricsFocusForeground.g * (1 - root.lyricsFocusAccentMix) + root.playerAccent.g * root.lyricsFocusAccentMix,
        root.lyricsFocusForeground.b * (1 - root.lyricsFocusAccentMix) + root.playerAccent.b * root.lyricsFocusAccentMix,
        1)

    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function armGamingAutoHide(): void {
        gamingAutoHideTimer.stop()
        if (!RaohaneState.mediaOverlayOpen
                || !root.gamingAutoHideEnabled
                || root.lyricsOpen
                || root.lyricsFocus
                || mediaHover.hovered)
            return
        gamingAutoHideTimer.interval = root.gamingAutoHideSeconds * 1000
        gamingAutoHideTimer.restart()
    }

    function toggle(): void {
        RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen
        Qt.callLater(root.armGamingAutoHide)
    }
    function open(): void {
        RaohaneState.mediaOverlayOpen = true
        Qt.callLater(root.armGamingAutoHide)
    }
    function close(): void {
        gamingAutoHideTimer.stop()
        RaohaneState.mediaOverlayOpen = false
        root.lyricsOpen = false
        root.lyricsFocus = false
    }
    function showLyrics(): void {
        gamingAutoHideTimer.stop()
        RaohaneState.mediaOverlayOpen = true
        root.lyricsOpen = true
        root.lyricsFocus = false
        if (!RaohaneLyrics.available && !RaohaneLyrics.loading)
            RaohaneLyrics.forceRefresh()
        Qt.callLater(() => root.centerCurrentLyric(false))
    }
    function toggleLyrics(): void {
        if (root.lyricsOpen) {
            root.lyricsOpen = false
            root.lyricsFocus = false
            Qt.callLater(root.armGamingAutoHide)
        } else {
            root.showLyrics()
        }
    }
    function toggleLyricsFocus(): void {
        gamingAutoHideTimer.stop()
        root.lyricsFocus = !root.lyricsFocus
        Qt.callLater(() => root.centerCurrentLyric(false))
    }
    function centerCurrentLyric(animated: bool): void {
        if (!root.lyricsOpen)
            return
        lyricsStage.centerCurrentLine(animated)
    }

    onGamingSceneChanged: Qt.callLater(root.armGamingAutoHide)
    onGamingAutoHideSecondsChanged: Qt.callLater(root.armGamingAutoHide)

    Connections {
        target: RaohaneState
        function onMediaOverlayOpenChanged(): void {
            if (RaohaneState.mediaOverlayOpen)
                Qt.callLater(root.armGamingAutoHide)
            else
                gamingAutoHideTimer.stop()
        }
    }

    Connections {
        target: RaohaneLyrics
        function onCurrentLineIndexChanged(): void {
            if (!root.lyricsOpen || !RaohaneLyrics.syncedAvailable || RaohaneLyrics.currentLineIndex < 0)
                return
            Qt.callLater(() => root.centerCurrentLyric(true))
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.mediaOverlayOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: root.lyricsFocus ? 720
            : root.lyricsOpen ? 620
            : root.gamingEdgeMode ? 430
            : 540
        implicitHeight: root.lyricsFocus ? 520
            : root.lyricsOpen ? 470
            : root.gamingEdgeMode ? 108
            : 126
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-media-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            left: root.positionLeft
            right: root.positionRight
            top: root.positionTop
            bottom: root.positionBottom
        }
        margins {
            left: root.positionLeft ? 24 : 0
            right: root.positionRight ? 24 : 0
            top: root.positionTop ? 26 : 0
            bottom: root.positionBottom ? 26 : 0
        }

        RaohaneSurface {
            id: mediaSurface
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: !root.lyricsFocus
            showSheen: !root.lyricsFocus
            showInnerRim: !root.lyricsFocus
            color: root.lyricsFocus ? "transparent" : RaohaneTheme.surfaceRaised
            border.width: root.lyricsFocus ? 0 : 1
            border.color: root.lyricsFocus ? "transparent" : RaohaneTheme.borderStrong
            clip: true
            opacity: panelWindow.visible ? 1 : 0

            HoverHandler {
                id: mediaHover
                onHoveredChanged: {
                    if (hovered)
                        gamingAutoHideTimer.stop()
                    else
                        root.armGamingAutoHide()
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.lyricsFocus ? 6 : 9
                spacing: root.lyricsOpen && !root.lyricsFocus ? 7 : 0

                RaohaneMediaLyricsStage {
                    id: lyricsStage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.lyricsOpen

                    focusMode: root.lyricsFocus
                    artUrl: RaohaneMedia.artUrl
                    accent: root.playerAccent
                    title: RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Lyrics")
                    subtitle: RaohaneLyrics.syncedAvailable
                        ? qsTr("%1 · synced by %2").arg(RaohaneMedia.artist).arg(RaohaneLyrics.providerName)
                        : RaohaneMedia.artist
                    mediaAvailable: RaohaneMedia.available
                    lyricsLoading: RaohaneLyrics.loading
                    lyricsAvailable: RaohaneLyrics.available
                    instrumental: RaohaneLyrics.instrumental
                    errorText: RaohaneLyrics.errorText
                    lines: RaohaneLyrics.displayLines
                    syncedAvailable: RaohaneLyrics.syncedAvailable
                    syncedIndex: RaohaneLyrics.currentLineIndex
                    canSeek: RaohaneMedia.canSeek
                    focusActive: root.lyricsFocusActive
                    focusSecondary: root.lyricsFocusSecondary
                    focusHalo: root.lyricsFocusHalo

                    onBackRequested: {
                        root.lyricsOpen = false
                        Qt.callLater(root.armGamingAutoHide)
                    }
                    onRefreshRequested: RaohaneLyrics.forceRefresh()
                    onFocusRequested: root.toggleLyricsFocus()
                    onCloseRequested: root.close()
                    onSeekRequested: time => {
                        if (RaohaneMedia.length > 0)
                            RaohaneMedia.seekRatio(time / RaohaneMedia.length)
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.lyricsOpen && !root.lyricsFocus ? 1 : 0
                    visible: root.lyricsOpen && !root.lyricsFocus
                    color: RaohaneTheme.borderFaint
                }

                RaohaneMediaPlayerHud {
                    id: playerHud
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: !root.lyricsFocus

                    lyricsOpen: root.lyricsOpen
                    gamingEdgeMode: root.gamingEdgeMode
                    mediaAvailable: RaohaneMedia.available
                    playing: RaohaneMedia.isPlaying
                    canSeek: RaohaneMedia.canSeek
                    canRaise: RaohaneMedia.canRaise
                    canGoPrevious: RaohaneMedia.canGoPrevious
                    canTogglePlaying: RaohaneMedia.canTogglePlaying
                    canGoNext: RaohaneMedia.canGoNext
                    volumeSupported: RaohaneMedia.volumeSupported
                    playerCount: RaohaneMedia.playerCount
                    progress: RaohaneMedia.progress
                    volume: RaohaneMedia.volume
                    accent: root.playerAccent
                    artUrl: RaohaneMedia.artUrl
                    playerName: RaohaneMedia.playerName
                    title: RaohaneMedia.title
                    artist: RaohaneMedia.artist
                    album: RaohaneMedia.album
                    elapsedText: RaohaneMedia.length > 0
                        ? RaohaneMedia.formatTime(RaohaneMedia.position)
                        : "--:--"
                    remainingText: RaohaneMedia.length > 0
                        ? "−" + RaohaneMedia.formatTime(Math.max(0, RaohaneMedia.length - RaohaneMedia.position))
                        : "--:--"

                    onCyclePlayerRequested: step => RaohaneMedia.cyclePlayer(step)
                    onSeekRequested: ratio => RaohaneMedia.seekRatio(ratio)
                    onLyricsRequested: root.toggleLyrics()
                    onRaiseRequested: RaohaneMedia.raisePlayer()
                    onCloseRequested: root.close()
                    onPreviousRequested: RaohaneMedia.previous()
                    onTogglePlayingRequested: RaohaneMedia.togglePlaying()
                    onNextRequested: RaohaneMedia.next()
                    onVolumeRequested: value => RaohaneMedia.setVolume(value)
                }
            }
        }
    }

    Timer {
        id: gamingAutoHideTimer
        interval: Math.max(1000, root.gamingAutoHideSeconds * 1000)
        repeat: false
        onTriggered: {
            if (root.gamingAutoHideEnabled
                    && RaohaneState.mediaOverlayOpen
                    && !root.lyricsOpen
                    && !root.lyricsFocus
                    && !mediaHover.hovered)
                root.close()
            else
                root.armGamingAutoHide()
        }
    }

    IpcHandler {
        target: "raohaneMedia"
        function toggle(): void { root.toggle() }
        function open(): void { root.open() }
        function close(): void { root.close() }
        function lyrics(): void { root.showLyrics() }
    }

    CompositorGlobalShortcut {
        name: "raohaneMediaOverlayToggle"
        description: "Toggle the Raohane media overlay"
        onPressed: root.toggle()
    }
}
