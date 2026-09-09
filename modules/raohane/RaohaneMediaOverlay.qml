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
        if (!root.lyricsOpen || !RaohaneLyrics.syncedAvailable || RaohaneLyrics.currentLineIndex < 0 || lyricsList.count <= 0)
            return

        const item = lyricsList.itemAtIndex(RaohaneLyrics.currentLineIndex)
        if (!item) {
            lyricsList.positionViewAtIndex(RaohaneLyrics.currentLineIndex, ListView.Center)
            return
        }

        const maxContentY = Math.max(0, lyricsList.contentHeight - lyricsList.height)
        const targetContentY = Math.max(0, Math.min(maxContentY,
            item.y + item.height / 2 - lyricsList.height / 2))

        // Motion belongs to the viewport, never to the lyric glyphs.
        if (animated && RaohaneMotion.enabled) {
            lyricsScrollAnimation.stop()
            lyricsScrollAnimation.from = lyricsList.contentY
            lyricsScrollAnimation.to = targetContentY
            lyricsScrollAnimation.start()
        } else {
            lyricsList.contentY = targetContentY
        }
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

                Item {
                    id: lyricsStage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.lyricsOpen

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        Item {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.lyricsFocus ? 0 : 46
                            visible: !root.lyricsFocus

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 3
                                anchors.rightMargin: 3
                                spacing: 8

                                MiniButton {
                                    icon: "arrow_back"
                                    tooltip: qsTr("Back to player")
                                    onClicked: {
                                        root.lyricsOpen = false
                                        Qt.callLater(root.armGamingAutoHide)
                                    }
                                }

                                Item {
                                    Layout.preferredWidth: 32
                                    Layout.preferredHeight: 32
                                    clip: true

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 8
                                        color: Qt.rgba(root.playerAccent.r, root.playerAccent.g, root.playerAccent.b, 0.12)
                                    }

                                    Image {
                                        id: lyricsMiniCover
                                        anchors.fill: parent
                                        source: RaohaneMedia.artUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        visible: status === Image.Ready
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: lyricsMiniCover.status !== Image.Ready
                                        text: "音"
                                        color: root.playerAccent
                                        font.pixelSize: 16
                                        font.weight: Font.DemiBold
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Lyrics")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: RaohaneLyrics.syncedAvailable
                                            ? qsTr("%1 · synced by %2").arg(RaohaneMedia.artist).arg(RaohaneLyrics.providerName)
                                            : RaohaneMedia.artist
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        elide: Text.ElideRight
                                    }
                                }

                                MiniButton {
                                    icon: "refresh"
                                    tooltip: qsTr("Refresh lyrics")
                                    enabled: !RaohaneLyrics.loading && RaohaneMedia.available
                                    onClicked: RaohaneLyrics.forceRefresh()
                                }

                                MiniButton {
                                    icon: "fullscreen"
                                    tooltip: qsTr("Lyrics only")
                                    enabled: RaohaneLyrics.available
                                    onClicked: root.toggleLyricsFocus()
                                }

                                MiniButton {
                                    icon: "close"
                                    tooltip: qsTr("Close")
                                    onClicked: root.close()
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.lyricsFocus ? 0 : 1
                            visible: !root.lyricsFocus
                            color: RaohaneTheme.borderFaint
                        }

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            Column {
                                anchors.centerIn: parent
                                visible: RaohaneLyrics.loading
                                spacing: 8

                                RaohaneIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "lyrics"
                                    iconSize: 28
                                    color: root.playerAccent
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: qsTr("Looking for lyrics…")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 10
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 44, 440)
                                visible: !RaohaneLyrics.loading && RaohaneLyrics.instrumental
                                spacing: 7

                                RaohaneIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "graphic_eq"
                                    iconSize: 30
                                    color: root.playerAccent
                                }
                                Text {
                                    width: parent.width
                                    text: qsTr("Instrumental track")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    width: parent.width
                                    text: qsTr("No vocal lyrics are expected for this recording.")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 44, 440)
                                visible: !RaohaneLyrics.loading && !RaohaneLyrics.available && !RaohaneLyrics.instrumental
                                spacing: 7

                                RaohaneIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "lyrics"
                                    iconSize: 28
                                    color: RaohaneTheme.textFaint
                                }
                                Text {
                                    width: parent.width
                                    text: RaohaneLyrics.errorText.length > 0
                                        ? RaohaneLyrics.errorText
                                        : qsTr("Lyrics are not available yet")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                            ListView {
                                id: lyricsList
                                anchors.fill: parent
                                anchors.topMargin: root.lyricsFocus ? 0 : 7
                                anchors.bottomMargin: root.lyricsFocus ? 0 : 7
                                visible: !RaohaneLyrics.loading && RaohaneLyrics.available && !RaohaneLyrics.instrumental
                                clip: true
                                spacing: root.lyricsFocus ? 9 : 4
                                model: RaohaneLyrics.displayLines
                                currentIndex: RaohaneLyrics.syncedAvailable ? RaohaneLyrics.currentLineIndex : -1
                                boundsBehavior: Flickable.StopAtBounds
                                flickDeceleration: 2200
                                cacheBuffer: root.lyricsFocus ? height * 1.5 : 0

                                NumberAnimation {
                                    id: lyricsScrollAnimation
                                    target: lyricsList
                                    property: "contentY"
                                    duration: RaohaneMotion.standard
                                    easing.type: RaohaneMotion.easeStandard
                                }

                                delegate: Item {
                                    id: lyricLine
                                    required property var modelData
                                    required property int index

                                    readonly property bool current: RaohaneLyrics.syncedAvailable
                                        && index === RaohaneLyrics.currentLineIndex

                                    width: ListView.view.width
                                    height: lyricText.implicitHeight + (root.lyricsFocus ? 28 : 16)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: lyricLine.current && !root.lyricsFocus
                                            ? RaohaneTheme.accentSoft
                                            : "transparent"
                                    }

                                    Rectangle {
                                        visible: lyricLine.current && !root.lyricsFocus
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3
                                        height: Math.min(parent.height - 16, 28)
                                        radius: 2
                                        color: root.playerAccent
                                    }

                                    Text {
                                        id: lyricText
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: root.lyricsFocus ? 24 : 14
                                            rightMargin: root.lyricsFocus ? 24 : 14
                                        }
                                        text: String(lyricLine.modelData.text ?? "")
                                        color: root.lyricsFocus
                                            ? (lyricLine.current ? root.lyricsFocusActive : root.lyricsFocusSecondary)
                                            : (lyricLine.current ? RaohaneTheme.text : RaohaneTheme.textMuted)
                                        font.pixelSize: root.lyricsFocus ? 15 : 10
                                        font.weight: lyricLine.current ? Font.DemiBold : root.lyricsFocus ? Font.Medium : Font.Normal
                                        wrapMode: Text.WordWrap
                                        horizontalAlignment: Text.AlignHCenter
                                        style: root.lyricsFocus ? Text.Outline : Text.Normal
                                        styleColor: root.lyricsFocus ? root.lyricsFocusHalo : "transparent"
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        enabled: RaohaneLyrics.syncedAvailable
                                            && Number(lyricLine.modelData.time) >= 0
                                            && RaohaneMedia.canSeek
                                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            if (RaohaneMedia.length > 0)
                                                RaohaneMedia.seekRatio(Number(lyricLine.modelData.time) / RaohaneMedia.length)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        z: 200
                        visible: root.lyricsFocus
                        acceptedButtons: Qt.RightButton
                        onClicked: root.toggleLyricsFocus()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.lyricsOpen && !root.lyricsFocus ? 1 : 0
                    visible: root.lyricsOpen && !root.lyricsFocus
                    color: RaohaneTheme.borderFaint
                }

                Item {
                    id: playerHud
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.lyricsFocus ? 0
                        : root.lyricsOpen ? 74
                        : root.gamingEdgeMode ? 90
                        : 108
                    visible: !root.lyricsFocus

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 2
                        spacing: root.gamingEdgeMode ? 9 : 12

                        Item {
                            Layout.preferredWidth: root.lyricsOpen ? 60 : root.gamingEdgeMode ? 76 : 90
                            Layout.preferredHeight: root.lyricsOpen ? 60 : root.gamingEdgeMode ? 76 : 90
                            Layout.alignment: Qt.AlignVCenter
                            clip: true

                            Rectangle {
                                anchors.fill: parent
                                radius: root.lyricsOpen ? 13 : 16
                                color: Qt.rgba(root.playerAccent.r, root.playerAccent.g, root.playerAccent.b, 0.13)
                                border.width: 1
                                border.color: Qt.rgba(root.playerAccent.r, root.playerAccent.g, root.playerAccent.b, 0.28)
                            }

                            Image {
                                id: hudCover
                                anchors.fill: parent
                                source: RaohaneMedia.artUrl
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !RaohaneMedia.available || hudCover.status !== Image.Ready
                                text: "音"
                                color: root.playerAccent
                                font.pixelSize: root.gamingEdgeMode ? 26 : 30
                                font.weight: Font.DemiBold
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: root.gamingEdgeMode ? 14 : 18
                                spacing: 5

                                Rectangle {
                                    width: 5
                                    height: 5
                                    radius: 3
                                    color: RaohaneMedia.isPlaying ? root.playerAccent : RaohaneTheme.textFaint
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneMedia.available
                                        ? (RaohaneMedia.playerName || qsTr("Media player"))
                                        : qsTr("No player")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                MiniButton {
                                    visible: !root.gamingEdgeMode && RaohaneMedia.playerCount > 1
                                    icon: "chevron_left"
                                    tooltip: qsTr("Previous player")
                                    onClicked: RaohaneMedia.cyclePlayer(-1)
                                }

                                MiniButton {
                                    visible: !root.gamingEdgeMode && RaohaneMedia.playerCount > 1
                                    icon: "chevron_right"
                                    tooltip: qsTr("Next player")
                                    onClicked: RaohaneMedia.cyclePlayer(1)
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title
                                    : qsTr("Nothing is playing")
                                color: RaohaneTheme.text
                                font.pixelSize: root.gamingEdgeMode ? 13 : 15
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist
                                    : qsTr("Start a MPRIS-compatible player")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: root.gamingEdgeMode ? 8 : 9
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: !root.gamingEdgeMode && !root.lyricsOpen
                                    && RaohaneMedia.available && RaohaneMedia.album.length > 0
                                text: RaohaneMedia.album
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 7
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 16
                                spacing: root.gamingEdgeMode ? 4 : 6

                                Text {
                                    Layout.preferredWidth: root.gamingEdgeMode ? 31 : 35
                                    text: RaohaneMedia.length > 0
                                        ? RaohaneMedia.formatTime(RaohaneMedia.position)
                                        : "--:--"
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: root.gamingEdgeMode ? 7 : 8
                                    horizontalAlignment: Text.AlignLeft
                                }

                                RaohaneSlider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 15
                                    from: 0
                                    to: 1
                                    stepSize: 0.001
                                    value: RaohaneMedia.progress
                                    enabled: RaohaneMedia.canSeek
                                    showHandle: hovered || activeFocus
                                    trackHeight: root.gamingEdgeMode ? 3 : 4
                                    onMoved: ratio => RaohaneMedia.seekRatio(ratio)
                                }

                                Text {
                                    Layout.preferredWidth: root.gamingEdgeMode ? 35 : 40
                                    text: RaohaneMedia.length > 0
                                        ? "−" + RaohaneMedia.formatTime(Math.max(0, RaohaneMedia.length - RaohaneMedia.position))
                                        : "--:--"
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: root.gamingEdgeMode ? 7 : 8
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.preferredWidth: root.gamingEdgeMode ? 118 : 142
                            Layout.fillHeight: true
                            spacing: 2

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                spacing: 3

                                MiniButton {
                                    icon: "lyrics"
                                    tooltip: qsTr("Lyrics")
                                    enabled: RaohaneMedia.available
                                    onClicked: root.toggleLyrics()
                                }

                                MiniButton {
                                    visible: !root.gamingEdgeMode && RaohaneMedia.canRaise
                                    icon: "open_in_new"
                                    tooltip: qsTr("Open player")
                                    onClicked: RaohaneMedia.raisePlayer()
                                }

                                Item { Layout.fillWidth: true }

                                MiniButton {
                                    icon: "close"
                                    tooltip: qsTr("Close")
                                    onClicked: root.close()
                                }
                            }

                            Item { Layout.fillHeight: true }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 42
                                spacing: root.gamingEdgeMode ? 3 : 5

                                MainButton {
                                    icon: "skip_previous"
                                    enabled: RaohaneMedia.canGoPrevious
                                    compact: root.gamingEdgeMode
                                    onClicked: RaohaneMedia.previous()
                                }

                                MainButton {
                                    icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                                    enabled: RaohaneMedia.canTogglePlaying
                                    emphasized: true
                                    compact: root.gamingEdgeMode
                                    onClicked: RaohaneMedia.togglePlaying()
                                }

                                MainButton {
                                    icon: "skip_next"
                                    enabled: RaohaneMedia.canGoNext
                                    compact: root.gamingEdgeMode
                                    onClicked: RaohaneMedia.next()
                                }
                            }

                            RowLayout {
                                visible: !root.gamingEdgeMode && !root.lyricsOpen && RaohaneMedia.volumeSupported
                                Layout.fillWidth: true
                                Layout.preferredHeight: visible ? 20 : 0
                                spacing: 5

                                RaohaneIcon {
                                    text: RaohaneMedia.volume <= 0.01 ? "volume_off" : "volume_up"
                                    iconSize: 12
                                    color: RaohaneTheme.textMuted
                                }

                                RaohaneSlider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 18
                                    from: 0
                                    to: 1
                                    stepSize: 0.01
                                    value: RaohaneMedia.volume
                                    showHandle: hovered || activeFocus
                                    trackHeight: 3
                                    onMoved: value => RaohaneMedia.setVolume(value)
                                }
                            }
                        }
                    }
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

    component MiniButton: RaohaneIconButton {
        property string tooltip: ""
        buttonSize: 28
        iconSize: 14
        transparentIdle: true
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }

    component MainButton: RaohaneIconButton {
        id: control
        property bool compact: false
        buttonSize: control.compact
            ? (control.emphasized ? 36 : 32)
            : (control.emphasized ? 40 : 36)
        iconSize: control.compact
            ? (control.emphasized ? 18 : 16)
            : (control.emphasized ? 20 : 17)
        surfaceRadius: control.emphasized ? 13 : 11
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
