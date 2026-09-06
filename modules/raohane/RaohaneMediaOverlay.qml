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
    }

    Connections {
        target: RaohaneLyrics
        function onCurrentLineIndexChanged(): void {
            if (!root.lyricsOpen || !RaohaneLyrics.syncedAvailable || RaohaneLyrics.currentLineIndex < 0)
                return
            Qt.callLater(() => {
                if (lyricsList.count > 0)
                    lyricsList.positionViewAtIndex(RaohaneLyrics.currentLineIndex, ListView.Center)
            })
        }
    }

    PanelWindow {
        id: panelWindow

        visible: RaohaneState.mediaOverlayOpen
        screen: root.focusedScreen
        exclusiveZone: 0
        implicitWidth: root.lyricsOpen ? 500 : 410
        implicitHeight: root.lyricsOpen ? 360 : 236
        color: "transparent"

        WlrLayershell.namespace: "quickshell:raohane-media-overlay"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            right: true
        }
        margins {
            top: 18
            right: 18
        }

        RaohaneSurface {
            id: mediaSurface
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            showSheen: !root.lyricsFocus
            border.color: root.lyricsFocus ? "transparent" : RaohaneTheme.borderStrong
            clip: true
            opacity: panelWindow.visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.lyricsFocus ? 8 : 12
                spacing: root.lyricsFocus ? 0 : 9

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !root.lyricsOpen

                    RowLayout {
                        anchors.fill: parent
                        spacing: 12

                        RaohaneSurface {
                            Layout.preferredWidth: 92
                            Layout.preferredHeight: 92
                            Layout.alignment: Qt.AlignVCenter
                            surfaceRadius: 14
                            raised: false
                            showSheen: false
                            clip: true
                            border.color: RaohaneTheme.borderStrong

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
                                spacing: 2

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "音"
                                    color: RaohaneTheme.accent
                                    font.pixelSize: 27
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "RAOHANE"
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 6
                                    font.letterSpacing: 0.8
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 3

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneMedia.available
                                        ? (RaohaneMedia.playerName || qsTr("Media player"))
                                        : qsTr("No player")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 6
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
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

                            Item { Layout.fillHeight: true }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.title.length > 0
                                    ? RaohaneMedia.title
                                    : qsTr("Nothing is playing")
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                    ? RaohaneMedia.artist
                                    : qsTr("Start a MPRIS-compatible player")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }

                            Item { Layout.fillHeight: true }

                            RaohaneSlider {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 18
                                from: 0
                                to: 1
                                stepSize: 0.001
                                value: RaohaneMedia.progress
                                enabled: RaohaneMedia.canSeek
                                showHandle: false
                                trackHeight: 4
                                onMoved: ratio => RaohaneMedia.seekRatio(ratio)
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: RaohaneMedia.formatTime(RaohaneMedia.position)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 6
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: RaohaneMedia.length > 0
                                        ? RaohaneMedia.formatTime(RaohaneMedia.length)
                                        : "—"
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 6
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
                    surfaceRadius: root.lyricsFocus ? RaohaneTheme.radiusLarge : 14
                    showSheen: false
                    raised: false
                    color: root.lyricsFocus ? "transparent" : RaohaneTheme.surfaceSubtle
                    border.color: root.lyricsFocus ? "transparent" : RaohaneTheme.borderFaint
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: root.lyricsFocus ? 10 : 9
                        spacing: root.lyricsFocus ? 0 : 7

                        RowLayout {
                            Layout.fillWidth: true
                            visible: !root.lyricsFocus
                            spacing: 7

                            MiniButton {
                                icon: "arrow_back"
                                tooltip: qsTr("Back to player")
                                onClicked: root.lyricsOpen = false
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Lyrics")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneLyrics.syncedAvailable
                                        ? qsTr("Synced · %1").arg(RaohaneLyrics.providerName)
                                        : qsTr("%1 · %2").arg(RaohaneMedia.artist).arg(RaohaneMedia.title)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 6
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
                                spacing: 7

                                RaohaneIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "lyrics"
                                    iconSize: 26
                                    color: RaohaneTheme.accent
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: qsTr("Looking for lyrics…")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 9
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 28, 390)
                                visible: !RaohaneLyrics.loading && RaohaneLyrics.instrumental
                                spacing: 6

                                RaohaneIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "graphic_eq"
                                    iconSize: 28
                                    color: RaohaneTheme.accent
                                }
                                Text {
                                    width: parent.width
                                    text: qsTr("Instrumental track")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Text {
                                    width: parent.width
                                    text: qsTr("No vocal lyrics are expected for this recording.")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                            Column {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 28, 390)
                                visible: !RaohaneLyrics.loading && !RaohaneLyrics.available && !RaohaneLyrics.instrumental
                                spacing: 6

                                RaohaneIcon {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "lyrics"
                                    iconSize: 26
                                    color: RaohaneTheme.textFaint
                                }
                                Text {
                                    width: parent.width
                                    text: RaohaneLyrics.errorText.length > 0
                                        ? RaohaneLyrics.errorText
                                        : qsTr("Lyrics are not available yet")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }

                            ListView {
                                id: lyricsList
                                anchors.fill: parent
                                visible: !RaohaneLyrics.loading && RaohaneLyrics.available && !RaohaneLyrics.instrumental
                                clip: true
                                spacing: root.lyricsFocus ? 6 : 2
                                model: RaohaneLyrics.displayLines
                                boundsBehavior: Flickable.StopAtBounds
                                flickDeceleration: 2200

                                delegate: Item {
                                    id: lyricLine
                                    required property var modelData
                                    required property int index
                                    readonly property bool current: RaohaneLyrics.syncedAvailable
                                        && index === RaohaneLyrics.currentLineIndex

                                    width: ListView.view.width
                                    height: lyricText.implicitHeight + (root.lyricsFocus ? 18 : 12)

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 9
                                        color: lyricLine.current && !root.lyricsFocus
                                            ? RaohaneTheme.accentSoft
                                            : "transparent"
                                        border.width: lyricLine.current && !root.lyricsFocus ? 1 : 0
                                        border.color: RaohaneTheme.accentBorder
                                    }

                                    Text {
                                        id: lyricText
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: 9
                                            rightMargin: 9
                                        }
                                        text: String(lyricLine.modelData.text ?? "")
                                        color: lyricLine.current ? RaohaneTheme.text : RaohaneTheme.textMuted
                                        font.pixelSize: root.lyricsFocus ? 12 : 9
                                        font.weight: lyricLine.current ? Font.DemiBold : Font.Normal
                                        wrapMode: Text.WordWrap
                                        horizontalAlignment: Text.AlignHCenter
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

                    MiniButton {
                        anchors {
                            top: parent.top
                            right: parent.right
                            margins: 8
                        }
                        visible: root.lyricsFocus
                        opacity: 0.55
                        icon: "fullscreen_exit"
                        tooltip: qsTr("Show player controls")
                        onClicked: root.toggleLyricsFocus()

                        Behavior on opacity {
                            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                        }
                    }
                }

                RaohaneSurface {
                    id: transportRail
                    Layout.fillWidth: true
                    Layout.preferredHeight: root.lyricsFocus ? 0 : 50
                    visible: !root.lyricsFocus
                    surfaceRadius: 13
                    showSheen: false
                    raised: false
                    border.color: RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        MiniButton {
                            visible: root.lyricsOpen
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
                            visible: root.lyricsOpen
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
        buttonSize: 28
        iconSize: 14
        transparentIdle: true
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }

    component MainButton: RaohaneIconButton {
        id: control
        buttonSize: control.emphasized ? 36 : 32
        iconSize: control.emphasized ? 18 : 16
        surfaceRadius: control.emphasized ? 12 : 10
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
