pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

Scope {
    id: root

    property bool lyricsOpen: false
    property bool lyricsFocus: false

    // Lyrics-only cannot sample arbitrary Wayland client pixels underneath the
    // layer surface. Keep the text legible with a theme-aware foreground and a
    // restrained opposite-polarity outline instead of adding another card.
    readonly property color lyricsFocusForeground: RaohaneTheme.dark ? "#fffdfc" : "#171719"
    readonly property color lyricsFocusSecondary: RaohaneTheme.dark ? "#e7e5ef" : "#2d2b31"
    readonly property color lyricsFocusHalo: RaohaneTheme.dark
        ? Qt.rgba(0.01, 0.012, 0.02, 0.82)
        : Qt.rgba(1, 1, 1, 0.90)

    readonly property color playerAccent: RaohaneCoverAccent.available
        ? RaohaneCoverAccent.accent
        : RaohaneTheme.accent
    readonly property real lyricsFocusAccentMix: RaohaneTheme.dark ? 0.34 : 0.24
    readonly property color lyricsFocusActive: Qt.rgba(
        root.lyricsFocusForeground.r * (1 - root.lyricsFocusAccentMix) + root.playerAccent.r * root.lyricsFocusAccentMix,
        root.lyricsFocusForeground.g * (1 - root.lyricsFocusAccentMix) + root.playerAccent.g * root.lyricsFocusAccentMix,
        root.lyricsFocusForeground.b * (1 - root.lyricsFocusAccentMix) + root.playerAccent.b * root.lyricsFocusAccentMix,
        1)

    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function toggle(): void { RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen }
    function open(): void { RaohaneState.mediaOverlayOpen = true }
    function close(): void {
        RaohaneState.mediaOverlayOpen = false
        root.lyricsOpen = false
        root.lyricsFocus = false
    }
    function showLyrics(): void {
        RaohaneState.mediaOverlayOpen = true
        root.lyricsOpen = true
        root.lyricsFocus = false
        if (!RaohaneLyrics.available && !RaohaneLyrics.loading)
            RaohaneLyrics.forceRefresh()
    }
    function toggleLyricsFocus(): void {
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

        // Only the list position moves. Lyric text itself deliberately has no
        // scale/color/opacity animations so the reading target stays stable.
        if (animated && root.lyricsFocus && RaohaneMotion.enabled) {
            lyricsScrollAnimation.stop()
            lyricsScrollAnimation.from = lyricsList.contentY
            lyricsScrollAnimation.to = targetContentY
            lyricsScrollAnimation.start()
        } else {
            lyricsList.contentY = targetContentY
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
        implicitWidth: root.lyricsFocus ? 620 : root.lyricsOpen ? 560 : 520
        implicitHeight: root.lyricsFocus ? 470 : root.lyricsOpen ? 420 : 310
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-media-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }
        margins {
            top: 20
            right: 20
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

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.lyricsFocus ? 4 : 16
                spacing: root.lyricsFocus ? 0 : 10

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.lyricsOpen

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 34
                            spacing: 8

                            RaohaneSurface {
                                Layout.preferredHeight: 28
                                Layout.preferredWidth: Math.min(220, playerIdentity.implicitWidth + 42)
                                surfaceRadius: 9
                                raised: false
                                showSheen: false
                                active: RaohaneMedia.available
                                border.color: RaohaneMedia.available ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 9
                                    spacing: 6

                                    RaohaneIcon {
                                        text: RaohaneMedia.isPlaying ? "graphic_eq" : "music_note"
                                        iconSize: 13
                                        fill: RaohaneMedia.isPlaying ? 1 : 0
                                        color: RaohaneMedia.available ? root.playerAccent : RaohaneTheme.textFaint
                                    }

                                    Text {
                                        id: playerIdentity
                                        Layout.fillWidth: true
                                        text: RaohaneMedia.available
                                            ? (RaohaneMedia.playerName || qsTr("Media player"))
                                            : qsTr("No player")
                                        color: RaohaneMedia.available ? RaohaneTheme.textMuted : RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            Item { Layout.fillWidth: true }

                            MiniButton {
                                visible: RaohaneMedia.playerCount > 1
                                icon: "chevron_left"
                                onClicked: RaohaneMedia.cyclePlayer(-1)
                            }

                            Text {
                                visible: RaohaneMedia.playerCount > 1
                                text: (RaohaneMedia.activePlayerIndex + 1) + "/" + RaohaneMedia.playerCount
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                                font.weight: Font.Medium
                            }

                            MiniButton {
                                visible: RaohaneMedia.playerCount > 1
                                icon: "chevron_right"
                                onClicked: RaohaneMedia.cyclePlayer(1)
                            }

                            MiniButton {
                                icon: "lyrics"
                                tooltip: qsTr("Lyrics")
                                enabled: RaohaneMedia.available
                                onClicked: root.showLyrics()
                            }

                            MiniButton {
                                icon: "close"
                                tooltip: qsTr("Close")
                                onClicked: root.close()
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 18

                            Item {
                                Layout.preferredWidth: 146
                                Layout.preferredHeight: 146
                                Layout.alignment: Qt.AlignVCenter

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -5
                                    radius: 24
                                    color: Qt.rgba(root.playerAccent.r, root.playerAccent.g, root.playerAccent.b, 0.10)
                                    border.width: 1
                                    border.color: Qt.rgba(root.playerAccent.r, root.playerAccent.g, root.playerAccent.b, 0.16)
                                }

                                RaohaneSurface {
                                    anchors.fill: parent
                                    surfaceRadius: 20
                                    raised: false
                                    showSheen: false
                                    clip: true
                                    border.color: Qt.rgba(root.playerAccent.r, root.playerAccent.g, root.playerAccent.b, 0.42)

                                    Image {
                                        id: coverArt
                                        anchors.fill: parent
                                        source: RaohaneMedia.artUrl
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        visible: status === Image.Ready
                                    }

                                    Column {
                                        anchors.centerIn: parent
                                        visible: !RaohaneMedia.available || coverArt.status !== Image.Ready
                                        spacing: 4

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "音"
                                            color: root.playerAccent
                                            font.pixelSize: 40
                                            font.weight: Font.DemiBold
                                        }

                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: "RAOHANE"
                                            color: RaohaneTheme.textFaint
                                            font.pixelSize: 8
                                            font.weight: Font.DemiBold
                                            font.letterSpacing: 1.1
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 5

                                Item { Layout.preferredHeight: 2 }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                        ? RaohaneMedia.title
                                        : qsTr("Nothing is playing")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 17
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                        ? RaohaneMedia.artist
                                        : qsTr("Start a MPRIS-compatible player")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: RaohaneMedia.available && RaohaneMedia.album.length > 0
                                    text: RaohaneMedia.album
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }

                                Item { Layout.fillHeight: true }

                                RaohaneSlider {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    from: 0
                                    to: 1
                                    stepSize: 0.001
                                    value: RaohaneMedia.progress
                                    enabled: RaohaneMedia.canSeek
                                    showHandle: hovered || activeFocus
                                    trackHeight: 6
                                    onMoved: ratio => RaohaneMedia.seekRatio(ratio)
                                }

                                RowLayout {
                                    Layout.fillWidth: true

                                    Text {
                                        text: RaohaneMedia.formatTime(RaohaneMedia.position)
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: RaohaneMedia.length > 0
                                            ? RaohaneMedia.formatTime(RaohaneMedia.length)
                                            : "—"
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        font.weight: Font.Medium
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 46
                                    spacing: 7

                                    MainButton {
                                        icon: "skip_previous"
                                        enabled: RaohaneMedia.canGoPrevious
                                        onClicked: RaohaneMedia.previous()
                                    }

                                    MainButton {
                                        icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                                        enabled: RaohaneMedia.canTogglePlaying
                                        emphasized: true
                                        onClicked: RaohaneMedia.togglePlaying()
                                    }

                                    MainButton {
                                        icon: "skip_next"
                                        enabled: RaohaneMedia.canGoNext
                                        onClicked: RaohaneMedia.next()
                                    }

                                    Item { Layout.fillWidth: true }

                                    RaohaneIcon {
                                        visible: RaohaneMedia.volumeSupported
                                        text: RaohaneMedia.volume <= 0.01 ? "volume_off" : "volume_up"
                                        iconSize: 15
                                        color: RaohaneTheme.textMuted
                                    }

                                    RaohaneSlider {
                                        visible: RaohaneMedia.volumeSupported
                                        Layout.preferredWidth: visible ? 92 : 0
                                        Layout.preferredHeight: 22
                                        from: 0
                                        to: 1
                                        stepSize: 0.01
                                        value: RaohaneMedia.volume
                                        showHandle: hovered || activeFocus
                                        trackHeight: 5
                                        onMoved: value => RaohaneMedia.setVolume(value)
                                    }
                                }
                            }
                        }
                    }
                }

                RaohaneSurface {
                    id: lyricsPage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.lyricsOpen
                    surfaceRadius: root.lyricsFocus ? 0 : 15
                    showSheen: false
                    showInnerRim: !root.lyricsFocus
                    raised: false
                    color: root.lyricsFocus ? "transparent" : RaohaneTheme.surfaceSubtle
                    border.width: root.lyricsFocus ? 0 : 1
                    border.color: root.lyricsFocus ? "transparent" : RaohaneTheme.borderFaint
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.lyricsFocus ? 16 : 10
                        spacing: root.lyricsFocus ? 0 : 8

                        RowLayout {
                            Layout.fillWidth: true
                            visible: !root.lyricsFocus
                            spacing: 8

                            MiniButton {
                                icon: "arrow_back"
                                tooltip: qsTr("Back to player")
                                onClicked: root.lyricsOpen = false
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Lyrics")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneLyrics.syncedAvailable
                                        ? qsTr("Synced · %1").arg(RaohaneLyrics.providerName)
                                        : qsTr("%1 · %2").arg(RaohaneMedia.artist).arg(RaohaneMedia.title)
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
                                    color: RaohaneTheme.accent
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
                                width: Math.min(parent.width - 32, 420)
                                visible: !RaohaneLyrics.loading && RaohaneLyrics.instrumental
                                spacing: 7

                                RaohaneIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "graphic_eq"
                                    iconSize: 30
                                    color: RaohaneTheme.accent
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
                                width: Math.min(parent.width - 32, 420)
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
                                visible: !RaohaneLyrics.loading && RaohaneLyrics.available && !RaohaneLyrics.instrumental
                                clip: true
                                spacing: root.lyricsFocus ? 10 : 4
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
                                    readonly property int distanceFromCurrent: RaohaneLyrics.currentLineIndex < 0
                                        ? 0
                                        : Math.abs(index - RaohaneLyrics.currentLineIndex)

                                    width: ListView.view.width
                                    height: lyricText.implicitHeight + (root.lyricsFocus ? 30 : 16)
                                    opacity: !root.lyricsFocus
                                        ? 1
                                        : current
                                            ? 1
                                            : distanceFromCurrent === 1
                                                ? 0.62
                                                : distanceFromCurrent === 2
                                                    ? 0.38
                                                    : 0.22

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 10
                                        color: lyricLine.current && !root.lyricsFocus
                                            ? RaohaneTheme.accentSoft
                                            : "transparent"
                                        border.width: lyricLine.current && !root.lyricsFocus ? 1 : 0
                                        border.color: RaohaneTheme.accentBorder
                                    }

                                    Rectangle {
                                        visible: lyricLine.current && !root.lyricsFocus
                                        anchors.left: parent.left
                                        anchors.leftMargin: 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 3
                                        height: Math.min(parent.height - 18, 28)
                                        radius: 2
                                        color: root.playerAccent
                                    }

                                    Text {
                                        id: lyricText
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: root.lyricsFocus ? 20 : 12
                                            rightMargin: root.lyricsFocus ? 20 : 12
                                        }
                                        text: String(lyricLine.modelData.text ?? "")
                                        color: root.lyricsFocus
                                            ? (lyricLine.current ? root.lyricsFocusActive : root.lyricsFocusSecondary)
                                            : (lyricLine.current ? RaohaneTheme.text : RaohaneTheme.textMuted)
                                        font.pixelSize: root.lyricsFocus ? 14 : 10
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

                    // Lyrics-only intentionally stays visually pure. Right-click
                    // anywhere in the surface to return without persistent chrome.
                    MouseArea {
                        anchors.fill: parent
                        z: 200
                        visible: root.lyricsFocus
                        acceptedButtons: Qt.RightButton
                        onClicked: root.toggleLyricsFocus()
                    }
                }

                RaohaneSurface {
                    id: lyricsTransport
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.lyricsOpen && !root.lyricsFocus ? 52 : 0
                    visible: root.lyricsOpen && !root.lyricsFocus
                    surfaceRadius: 14
                    showSheen: false
                    raised: false
                    border.color: RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 7

                        MiniButton {
                            icon: "replay_10"
                            tooltip: qsTr("Back 10 seconds")
                            enabled: RaohaneMedia.available && RaohaneMedia.activePlayer?.canSeek
                            onClicked: RaohaneMedia.seekSeconds(-10)
                        }

                        Item { Layout.fillWidth: true }

                        MainButton {
                            icon: "skip_previous"
                            enabled: RaohaneMedia.canGoPrevious
                            onClicked: RaohaneMedia.previous()
                        }

                        MainButton {
                            icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                            enabled: RaohaneMedia.canTogglePlaying
                            emphasized: true
                            onClicked: RaohaneMedia.togglePlaying()
                        }

                        MainButton {
                            icon: "skip_next"
                            enabled: RaohaneMedia.canGoNext
                            onClicked: RaohaneMedia.next()
                        }

                        Item { Layout.fillWidth: true }

                        MiniButton {
                            icon: "forward_10"
                            tooltip: qsTr("Forward 10 seconds")
                            enabled: RaohaneMedia.available && RaohaneMedia.activePlayer?.canSeek
                            onClicked: RaohaneMedia.seekSeconds(10)
                        }
                    }
                }
            }
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
        buttonSize: 30
        iconSize: 15
        transparentIdle: true
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }

    component MainButton: RaohaneIconButton {
        id: control
        buttonSize: control.emphasized ? 42 : 36
        iconSize: control.emphasized ? 20 : 17
        surfaceRadius: control.emphasized ? 14 : 11
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
