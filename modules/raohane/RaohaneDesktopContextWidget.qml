pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.raohane.services

RaohaneSurface {
    id: root
    property bool compact: false
    readonly property bool hasMedia: RaohaneMedia.available
    readonly property string coverUrl: root.hasMedia ? String(RaohaneMedia.artUrl ?? "") : ""
    readonly property bool expanded: height >= 290 && width >= 300
    property bool showLyrics: true
    implicitHeight: root.hasMedia && !root.compact ? 360 : 176
    surfaceRadius: RaohaneTheme.radiusHero
    idleColor: RaohaneTheme.surfaceDeep
    idleBorderColor: RaohaneTheme.borderStrong
    showSheen: false
    showInnerRim: false
    clip: true

    Rectangle {
        anchors.fill: parent
        radius: root.surfaceRadius
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: RaohaneTheme.accentSoft }
            GradientStop { position: 1; color: "transparent" }
        }
        opacity: 0.35
    }
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            Item {
                visible: root.width >= 280
                Layout.preferredWidth: visible ? Math.min(root.width * 0.33, root.expanded ? 136 : 108) : 0
                Layout.preferredHeight: width
                Canvas {
                    id: record
                    anchors.fill: parent
                    property string art: root.visible && root.hasMedia ? root.coverUrl : ""
                    property string previousArt: ""
                    property real progress: RaohaneMedia.progress
                    onProgressChanged: if (record.visible && root.visible && root.hasMedia) requestPaint()
                    onArtChanged: {
                        if (previousArt.length) unloadImage(previousArt)
                        previousArt = art
                        if (art.length) loadImage(art)
                        requestPaint()
                    }
                    onImageLoaded: requestPaint()
                    onWidthChanged: requestPaint()
                    onHeightChanged: requestPaint()
                    Connections {
                        target: RaohaneTheme
                        function onAccentChanged() { record.requestPaint() }
                        function onSurfaceDeepChanged() { record.requestPaint() }
                    }
                    onPaint: {
                        const c = getContext("2d"), size = Math.min(width, height), r = size / 2
                        c.reset(); c.save(); c.beginPath(); c.arc(r, r, r - 3, 0, Math.PI * 2); c.clip()
                        c.fillStyle = RaohaneTheme.surfaceDeep; c.fillRect(0, 0, size, size)
                        if (art.length && isImageLoaded(art)) {
                            c.drawImage(art, 0, 0, size, size)
                        }
                        c.strokeStyle = RaohaneTheme.accent; c.lineWidth = 1
                        for (let n = 0; n < 5; n++) {
                            c.globalAlpha = 0.12; c.beginPath(); c.arc(r, r, r * (0.45 + n * 0.11), 0, Math.PI * 2); c.stroke()
                        }
                        c.globalAlpha = 1; c.restore()
                        c.strokeStyle = RaohaneTheme.accent; c.lineWidth = 2
                        c.globalAlpha = 0.25; c.beginPath(); c.arc(r, r, r - 2, 0, Math.PI*2); c.stroke()
                        c.globalAlpha = 1; c.lineWidth = 3
                        c.beginPath(); c.arc(r, r, r - 2, -Math.PI/2, -Math.PI/2 + Math.PI*2*Math.max(0, Math.min(1, progress))); c.stroke()
                    }
                }
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.27
                    height: width
                    radius: width / 2
                    color: RaohaneTheme.accentSoft
                    border.color: RaohaneTheme.accent
                    Rectangle {
                        anchors.centerIn: parent
                        width: 9; height: 9; radius: 5
                        color: RaohaneTheme.surfaceDeep
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                spacing: 5
                Text {
                    Layout.fillWidth: true
                    text: root.hasMedia ? (RaohaneMedia.title || qsTr("Unknown track")) : qsTr("Your next favourite song")
                    color: RaohaneTheme.text
                    font.pixelSize: root.expanded ? 18 : 15
                    font.weight: Font.Bold
                    maximumLineCount: 2; wrapMode: Text.WordWrap; elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: root.hasMedia ? (RaohaneMedia.artist || RaohaneMedia.playerName) : qsTr("Start a player to bring this record to life")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
                Text {
                    visible: root.hasMedia && root.expanded
                    Layout.fillWidth: true
                    text: RaohaneMedia.playerName
                    color: RaohaneTheme.accent
                    font.pixelSize: 10; elide: Text.ElideRight
                }
                RaohaneSlider {
                    Layout.fillWidth: true
                    visible: root.hasMedia
                    enabled: RaohaneMedia.canSeek
                    value: RaohaneMedia.progress
                    trackHeight: 4
                    onMoved: value => RaohaneMedia.seekRatio(value)
                    Accessible.name: qsTr("Track position")
                }
                RowLayout {
                    visible: root.hasMedia && root.expanded
                    Layout.fillWidth: true
                    Text { text: RaohaneMedia.formatTime(RaohaneMedia.position); color: RaohaneTheme.textMuted; font.pixelSize: 10 }
                    Item { Layout.fillWidth: true }
                    Text { text: RaohaneMedia.formatTime(RaohaneMedia.length); color: RaohaneTheme.textMuted; font.pixelSize: 10 }
                }
                RowLayout {
                    visible: root.hasMedia
                    spacing: 8
                    RaohaneIconButton {
                        icon: "skip_previous"; buttonSize: 28
                        enabled: RaohaneMedia.canGoPrevious
                        Accessible.name: qsTr("Previous track")
                        onClicked: RaohaneMedia.previous()
                    }
                    RaohaneIconButton {
                        icon: RaohaneMedia.isPlaying ? "pause" : "play_arrow"
                        buttonSize: 34; emphasized: true
                        enabled: RaohaneMedia.canTogglePlaying
                        Accessible.name: RaohaneMedia.isPlaying ? qsTr("Pause") : qsTr("Play")
                        onClicked: RaohaneMedia.togglePlaying()
                    }
                    RaohaneIconButton {
                        icon: "skip_next"; buttonSize: 28
                        enabled: RaohaneMedia.canGoNext
                        Accessible.name: qsTr("Next track")
                        onClicked: RaohaneMedia.next()
                    }
                }
            }
        }
        Rectangle { visible: root.expanded; Layout.fillWidth: true; implicitHeight: 1; color: RaohaneTheme.borderFaint }
        RowLayout {
            visible: root.expanded
            Layout.fillWidth: true
            RaohaneIconButton {
                icon: "subtitles"; emphasized: root.showLyrics
                Accessible.name: qsTr("Lyrics")
                onClicked: root.showLyrics = !root.showLyrics
            }
            Text { text: root.showLyrics ? qsTr("Lyrics") : qsTr("Album"); color: RaohaneTheme.text; font.pixelSize: 12 }
            Item { Layout.fillWidth: true }
            RaohaneIconButton {
                icon: "refresh"; buttonSize: 26
                visible: root.hasMedia && root.showLyrics
                Accessible.name: qsTr("Refresh lyrics")
                onClicked: RaohaneLyrics.forceRefresh()
            }
        }
        Loader {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.visible && root.expanded && root.showLyrics && root.hasMedia && RaohaneLyrics.available
            visible: active
            sourceComponent: RaohaneMediaLyricsViewport {
                lines: RaohaneLyrics.displayLines
                syncedAvailable: RaohaneLyrics.syncedAvailable
                syncedIndex: RaohaneLyrics.currentLineIndex
                canSeek: RaohaneMedia.canSeek
                onSeekRequested: time => RaohaneMedia.seekRatio(time / Math.max(1, RaohaneMedia.length))
                onSyncedIndexChanged: centerCurrentLine(false)
            }
        }
        Text {
            visible: root.expanded && (!root.showLyrics || !root.hasMedia || !RaohaneLyrics.available)
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignVCenter
            text: !root.showLyrics ? (RaohaneMedia.album || qsTr("No album information"))
                : RaohaneLyrics.loading ? qsTr("Finding lyrics…")
                : RaohaneLyrics.instrumental ? qsTr("Instrumental")
                : qsTr("Lyrics will appear here when available")
            color: RaohaneTheme.textMuted
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
    }
}
