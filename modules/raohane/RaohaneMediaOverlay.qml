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

    // Lyrics-only floats above arbitrary Wayland clients. Keep a stable light
    // reading color and dark halo instead of trying to follow theme polarity;
    // that remains readable over both light and dark application content.
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

        // Motion belongs to the viewport, never to the lyric glyphs themselves.
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
        implicitWidth: root.lyricsFocus ? 700 : root.lyricsOpen ? 660 : 680
        implicitHeight: root.lyricsFocus ? 500 : root.lyricsOpen ? 470 : 300
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

            Item {
                id: playerPage
                anchors.fill: parent
                visible: !root.lyricsOpen

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Item {
                        id: artworkPane
                        Layout.preferredWidth: 242
                        Layout.fillHeight: true
                        clip: true

                        Rectangle {
                            anchors.fill: parent
                            color: Qt.rgba(root.playerAccent.r, root.playerAccent.g, root.playerAccent.b, 0.12)
                        }

                        Image {
                            id: playerCover
                            anchors.fill: parent
                            source: RaohaneMedia.artUrl
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            cache: false
                            visible: status === Image.Ready
                        }

                        Column {
                            anchors.centerIn: parent
                            visible: !RaohaneMedia.available || playerCover.status !== Image.Ready
                            spacing: 6

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "音"
                                color: root.playerAccent
                                font.pixelSize: 52
                                font.weight: Font.DemiBold
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "RAOHANE"
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                font.letterSpacing: 1.6
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 68
                            color: playerCover.visible ? Qt.rgba(0, 0, 0, 0.52) : "transparent"
                        }

                        RowLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.bottomMargin: 14
                            spacing: 8

                            Rectangle {
                                width: 7
                                height: 7
                                radius: 4
                                color: RaohaneMedia.isPlaying ? root.playerAccent : "#b9b7c0"
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available
                                    ? (RaohaneMedia.playerName || qsTr("Media player"))
                                    : qsTr("No player")
                                color: playerCover.visible ? "#f5f4f8" : RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                visible: RaohaneMedia.playerCount > 1
                                text: (RaohaneMedia.activePlayerIndex + 1) + "/" + RaohaneMedia.playerCount
                                color: playerCover.visible ? "#dedce4" : RaohaneTheme.textFaint
                                font.pixelSize: 9
                                font.weight: Font.Medium
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: RaohaneTheme.borderFaint
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 24
                            anchors.rightMargin: 18
                            anchors.topMargin: 16
                            anchors.bottomMargin: 17
                            spacing: 0

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneMedia.isPlaying ? qsTr("NOW PLAYING") : qsTr("MEDIA")
                                    color: root.playerAccent
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 1.35
                                }

                                MiniButton {
                                    visible: RaohaneMedia.playerCount > 1
                                    icon: "chevron_left"
                                    tooltip: qsTr("Previous player")
                                    onClicked: RaohaneMedia.cyclePlayer(-1)
                                }

                                MiniButton {
                                    visible: RaohaneMedia.playerCount > 1
                                    icon: "chevron_right"
                                    tooltip: qsTr("Next player")
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

                            Item { Layout.preferredHeight: 10 }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title
                                    : qsTr("Nothing is playing")
                                color: RaohaneTheme.text
                                font.pixelSize: 21
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 3
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist
                                    : qsTr("Start a MPRIS-compatible player")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                visible: RaohaneMedia.available && RaohaneMedia.album.length > 0
                                text: RaohaneMedia.album
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 9
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
                                Layout.preferredHeight: 18

                                Text {
                                    text: RaohaneMedia.formatTime(RaohaneMedia.position)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: RaohaneMedia.length > 0
                                        ? RaohaneMedia.formatTime(RaohaneMedia.length)
                                        : "—"
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 9
                                    font.weight: Font.Medium
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 52
                                spacing: 8

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
                                    visible: RaohaneMedia.canRaise
                                    icon: "open_in_new"
                                    tooltip: qsTr("Open player")
                                    onClicked: RaohaneMedia.raisePlayer()
                                }

                                RaohaneIcon {
                                    visible: RaohaneMedia.volumeSupported
                                    text: RaohaneMedia.volume <= 0.01 ? "volume_off" : "volume_up"
                                    iconSize: 15
                                    color: RaohaneTheme.textMuted
                                }

                                RaohaneSlider {
                                    visible: RaohaneMedia.volumeSupported
                                    Layout.preferredWidth: visible ? 94 : 0
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

            Item {
                id: lyricsPage
                anchors.fill: parent
                visible: root.lyricsOpen

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: root.lyricsFocus ? 8 : 16
                    spacing: 0

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.lyricsFocus ? 0 : 62
                        visible: !root.lyricsFocus

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            MiniButton {
                                icon: "arrow_back"
                                tooltip: qsTr("Back to player")
                                onClicked: root.lyricsOpen = false
                            }

                            Item {
                                Layout.preferredWidth: 44
                                Layout.preferredHeight: 44
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
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
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneMedia.title.length > 0 ? RaohaneMedia.title : qsTr("Lyrics")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneLyrics.syncedAvailable
                                        ? qsTr("%1 · synced by %2").arg(RaohaneMedia.artist).arg(RaohaneLyrics.providerName)
                                        : RaohaneMedia.artist
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 9
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
                            width: Math.min(parent.width - 40, 450)
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
                            width: Math.min(parent.width - 40, 450)
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
                            anchors.topMargin: root.lyricsFocus ? 0 : 10
                            anchors.bottomMargin: root.lyricsFocus ? 0 : 10
                            visible: !RaohaneLyrics.loading && RaohaneLyrics.available && !RaohaneLyrics.instrumental
                            clip: true
                            spacing: root.lyricsFocus ? 10 : 5
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
                                height: lyricText.implicitHeight + (root.lyricsFocus ? 32 : 18)
                                opacity: !root.lyricsFocus
                                    ? 1
                                    : current
                                        ? 1
                                        : distanceFromCurrent === 1
                                            ? 0.64
                                            : distanceFromCurrent === 2
                                                ? 0.40
                                                : 0.22

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 11
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
                                    height: Math.min(parent.height - 18, 30)
                                    radius: 2
                                    color: root.playerAccent
                                }

                                Text {
                                    id: lyricText
                                    anchors {
                                        left: parent.left
                                        right: parent.right
                                        verticalCenter: parent.verticalCenter
                                        leftMargin: root.lyricsFocus ? 24 : 15
                                        rightMargin: root.lyricsFocus ? 24 : 15
                                    }
                                    text: String(lyricLine.modelData.text ?? "")
                                    color: root.lyricsFocus
                                        ? (lyricLine.current ? root.lyricsFocusActive : root.lyricsFocusSecondary)
                                        : (lyricLine.current ? RaohaneTheme.text : RaohaneTheme.textMuted)
                                    font.pixelSize: root.lyricsFocus ? 15 : 11
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

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.lyricsFocus ? 0 : 1
                        visible: !root.lyricsFocus
                        color: RaohaneTheme.borderFaint
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: root.lyricsFocus ? 0 : 62
                        visible: !root.lyricsFocus

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 6
                            anchors.rightMargin: 6
                            spacing: 8

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

                // Lyrics-only stays visually pure. Right-click anywhere to return
                // without adding persistent chrome over the application underneath.
                MouseArea {
                    anchors.fill: parent
                    z: 200
                    visible: root.lyricsFocus
                    acceptedButtons: Qt.RightButton
                    onClicked: root.toggleLyricsFocus()
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
        buttonSize: control.emphasized ? 44 : 38
        iconSize: control.emphasized ? 21 : 18
        surfaceRadius: control.emphasized ? 15 : 12
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
