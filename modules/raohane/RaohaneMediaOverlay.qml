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

    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function toggle(): void { RaohaneState.mediaOverlayOpen = !RaohaneState.mediaOverlayOpen }
    function open(): void { RaohaneState.mediaOverlayOpen = true }
    function close(): void {
        RaohaneState.mediaOverlayOpen = false
        root.lyricsOpen = false
    }
    function showLyrics(): void {
        RaohaneState.mediaOverlayOpen = true
        root.lyricsOpen = true
        if (!RaohaneLyrics.available && !RaohaneLyrics.loading)
            RaohaneLyrics.forceRefresh()
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
        implicitWidth: 536
        implicitHeight: 344
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

        Rectangle {
            anchors.centerIn: mediaSurface
            width: mediaSurface.width + 10
            height: mediaSurface.height + 10
            radius: RaohaneTheme.radiusLarge + 5
            color: "transparent"
            border.width: 1
            border.color: RaohaneTheme.borderFaint
            opacity: panelWindow.visible ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
        }

        RaohaneSurface {
            id: mediaSurface
            anchors.fill: parent
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: true
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: panelWindow.visible ? 1 : 0
            scale: panelWindow.visible ? 1 : 0.985

            transform: Translate {
                y: panelWindow.visible ? 0 : -7
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
            }

            MouseArea {
                id: surfacePointerGuard
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                preventStealing: true
                hoverEnabled: true
                cursorShape: Qt.ArrowCursor
                onPressed: mouse => mouse.accepted = true
                onReleased: mouse => mouse.accepted = true
                onClicked: mouse => mouse.accepted = true
                onWheel: wheel => wheel.accepted = true
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        id: nowPlayingPage
                        anchors.fill: parent
                        visible: !root.lyricsOpen
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            spacing: 14

                            Rectangle {
                                Layout.preferredWidth: 172
                                Layout.preferredHeight: 172
                                Layout.alignment: Qt.AlignVCenter
                                radius: 22
                                color: RaohaneTheme.surfaceSubtle
                                border.width: 1
                                border.color: RaohaneTheme.border
                                clip: true

                                Image {
                                    id: coverArt
                                    anchors.fill: parent
                                    source: RaohaneMedia.artUrl
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                    visible: status === Image.Ready
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    visible: coverArt.status === Image.Ready
                                    radius: parent.radius
                                    color: "transparent"
                                    border.width: 1
                                    border.color: RaohaneTheme.border
                                }

                                Column {
                                    anchors.centerIn: parent
                                    visible: !RaohaneMedia.available || coverArt.status !== Image.Ready
                                    spacing: 4

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "音"
                                        color: RaohaneTheme.accent
                                        font.pixelSize: 34
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: qsTr("Raohane")
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        font.letterSpacing: 1
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 7

                                    RaohaneSurface {
                                        implicitWidth: playerLabel.implicitWidth + 16
                                        implicitHeight: 27
                                        surfaceRadius: 10
                                        showSheen: false
                                        raised: true

                                        Text {
                                            id: playerLabel
                                            anchors.centerIn: parent
                                            text: RaohaneMedia.available
                                                ? (RaohaneMedia.playerName || qsTr("Media player"))
                                                : qsTr("No player")
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 8
                                            font.weight: Font.Medium
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    MiniButton {
                                        icon: "open_in_new"
                                        tooltip: qsTr("Open player")
                                        enabled: RaohaneMedia.canRaise
                                        onClicked: RaohaneMedia.raisePlayer()
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
                                    font.pixelSize: 20
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneMedia.available && RaohaneMedia.artist.length > 0
                                        ? RaohaneMedia.artist
                                        : qsTr("Start a MPRIS-compatible player")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    visible: RaohaneMedia.album.length > 0
                                    text: RaohaneMedia.album
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }

                                Item { Layout.fillHeight: true }

                                RowLayout {
                                    Layout.fillWidth: true
                                    visible: RaohaneMedia.playerCount > 1
                                    spacing: 7

                                    MiniButton {
                                        icon: "chevron_left"
                                        tooltip: qsTr("Previous player")
                                        onClicked: RaohaneMedia.cyclePlayer(-1)
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Player %1 of %2").arg(RaohaneMedia.activePlayerIndex + 1).arg(RaohaneMedia.playerCount)
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 8
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    MiniButton {
                                        icon: "chevron_right"
                                        tooltip: qsTr("Next player")
                                        onClicked: RaohaneMedia.cyclePlayer(1)
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            RaohaneSlider {
                                id: timelineSlider
                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
                                from: 0
                                to: 1
                                stepSize: 0.001
                                value: RaohaneMedia.progress
                                enabled: RaohaneMedia.canSeek
                                showHandle: RaohaneMedia.canSeek
                                onMoved: ratio => RaohaneMedia.seekRatio(ratio)
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: RaohaneMedia.formatTime(RaohaneMedia.position)
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: RaohaneMedia.length > 0 ? RaohaneMedia.formatTime(RaohaneMedia.length) : "--:--"
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                }
                            }
                        }
                    }

                    RaohaneSurface {
                        id: lyricsPage
                        anchors.fill: parent
                        visible: root.lyricsOpen
                        surfaceRadius: 18
                        showSheen: false
                        color: RaohaneTheme.surfaceSubtle
                        border.color: RaohaneTheme.border
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 7

                            RowLayout {
                                Layout.fillWidth: true
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
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        text: RaohaneLyrics.syncedAvailable
                                            ? qsTr("Synced · %1").arg(RaohaneLyrics.providerName)
                                            : qsTr("%1 · %2").arg(RaohaneMedia.artist).arg(RaohaneMedia.title)
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 7
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
                                    width: Math.min(parent.width - 28, 360)
                                    visible: RaohaneLyrics.loading
                                    spacing: 8

                                    RaohaneIcon {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "lyrics"
                                        iconSize: 28
                                        color: RaohaneTheme.accent
                                    }
                                    Text {
                                        width: parent.width
                                        text: qsTr("Looking for lyrics…")
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 10
                                        horizontalAlignment: Text.AlignHCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Column {
                                    anchors.centerIn: parent
                                    width: Math.min(parent.width - 28, 390)
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
                                    width: Math.min(parent.width - 28, 390)
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
                                    spacing: 2
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
                                        height: lyricText.implicitHeight + 12

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: 10
                                            color: lyricLine.current ? RaohaneTheme.accentSoft : "transparent"
                                            border.width: lyricLine.current ? 1 : 0
                                            border.color: RaohaneTheme.accentBorder

                                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                                            Behavior on border.width {
                                                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                                            }
                                        }

                                        Text {
                                            id: lyricText
                                            anchors {
                                                left: parent.left
                                                right: parent.right
                                                verticalCenter: parent.verticalCenter
                                                leftMargin: 10
                                                rightMargin: 10
                                            }
                                            text: String(lyricLine.modelData.text ?? "")
                                            color: lyricLine.current ? RaohaneTheme.text : RaohaneTheme.textMuted
                                            font.pixelSize: lyricLine.current ? 12 : 10
                                            font.weight: lyricLine.current ? Font.DemiBold : Font.Normal
                                            wrapMode: Text.WordWrap
                                            horizontalAlignment: Text.AlignHCenter

                                            Behavior on color {
                                                ColorAnimation { duration: RaohaneMotion.micro }
                                            }
                                            Behavior on font.pixelSize {
                                                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            acceptedButtons: Qt.LeftButton
                                            preventStealing: true
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
                    }
                }

                RaohaneSurface {
                    id: transportRail
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    surfaceRadius: 18
                    showSheen: false
                    color: RaohaneTheme.surfaceSubtle
                    border.color: RaohaneTheme.border

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        spacing: 8

                        MiniButton {
                            icon: "replay_10"
                            tooltip: qsTr("Back 10 seconds")
                            enabled: RaohaneMedia.available && RaohaneMedia.activePlayer?.canSeek
                            onClicked: RaohaneMedia.seekSeconds(-10)
                        }

                        MiniButton {
                            icon: "shuffle"
                            tooltip: qsTr("Shuffle")
                            enabled: RaohaneMedia.shuffleSupported
                            emphasized: RaohaneMedia.shuffle
                            onClicked: RaohaneMedia.toggleShuffle()
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

                        MiniButton {
                            icon: "lyrics"
                            tooltip: root.lyricsOpen ? qsTr("Back to player") : qsTr("Lyrics")
                            enabled: RaohaneMedia.available
                            emphasized: root.lyricsOpen
                            onClicked: {
                                if (root.lyricsOpen)
                                    root.lyricsOpen = false
                                else
                                    root.showLyrics()
                            }
                        }

                        Item { Layout.fillWidth: true }

                        MiniButton {
                            icon: "forward_10"
                            tooltip: qsTr("Forward 10 seconds")
                            enabled: RaohaneMedia.available && RaohaneMedia.activePlayer?.canSeek
                            onClicked: RaohaneMedia.seekSeconds(10)
                        }

                        RowLayout {
                            visible: RaohaneMedia.volumeSupported
                            spacing: 7

                            RaohaneIcon {
                                text: RaohaneMedia.volume <= 0.01 ? "volume_off" : "volume_up"
                                iconSize: 17
                                symbolWeight: volumeSlider.hovered ? 500 : 430
                                color: volumeSlider.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                            }

                            RaohaneSlider {
                                id: volumeSlider
                                Layout.preferredWidth: 86
                                Layout.preferredHeight: 22
                                from: 0
                                to: 1
                                stepSize: 0.01
                                value: RaohaneMedia.volume
                                handleSize: 12
                                trackHeight: 5
                                onMoved: nextVolume => RaohaneMedia.setVolume(nextVolume)
                            }
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
        id: control

        property string tooltip: ""
        buttonSize: 36
        iconSize: 18
        showSheen: false
        hoverScale: RaohaneMotion.hoverScale
        pressedScale: RaohaneMotion.pressScale
    }

    component MainButton: RaohaneIconButton {
        id: control

        buttonSize: control.emphasized ? 48 : 40
        iconSize: control.emphasized ? 24 : 21
        surfaceRadius: control.emphasized ? 17 : 14
        showSheen: false
        hoverScale: control.emphasized ? 1.035 : RaohaneMotion.hoverScale
        pressedScale: RaohaneMotion.pressScale
    }
}
