pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool focusMode: false
    property url artUrl: ""
    property color accent: RaohaneTheme.accent
    property string title: qsTr("Lyrics")
    property string subtitle: ""
    property bool mediaAvailable: false
    property bool lyricsLoading: false
    property bool lyricsAvailable: false
    property bool instrumental: false
    property string errorText: ""
    property var lines: []
    property bool syncedAvailable: false
    property int syncedIndex: -1
    property bool canSeek: false
    property color focusActive: RaohaneTheme.text
    property color focusSecondary: RaohaneTheme.textMuted
    property color focusHalo: "transparent"

    signal backRequested()
    signal refreshRequested()
    signal focusRequested()
    signal closeRequested()
    signal seekRequested(real time)

    function centerCurrentLine(animated: bool): void {
        lyricsViewport.centerCurrentLine(animated)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        RaohaneMediaLyricsHeader {
            Layout.fillWidth: true
            Layout.preferredHeight: root.focusMode ? 0 : implicitHeight
            visible: !root.focusMode

            artUrl: root.artUrl
            accent: root.accent
            title: root.title
            subtitle: root.subtitle
            mediaAvailable: root.mediaAvailable
            lyricsLoading: root.lyricsLoading
            lyricsAvailable: root.lyricsAvailable

            onBackRequested: root.backRequested()
            onRefreshRequested: root.refreshRequested()
            onFocusRequested: root.focusRequested()
            onCloseRequested: root.closeRequested()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: root.focusMode ? 0 : 1
            visible: !root.focusMode
            color: RaohaneTheme.borderFaint
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            RaohaneMediaLyricsStatus {
                anchors.fill: parent
                loading: root.lyricsLoading
                instrumental: root.instrumental
                available: root.lyricsAvailable
                errorText: root.errorText
                accent: root.accent
            }

            RaohaneMediaLyricsViewport {
                id: lyricsViewport
                anchors.fill: parent
                anchors.topMargin: root.focusMode ? 0 : 7
                anchors.bottomMargin: root.focusMode ? 0 : 7
                visible: !root.lyricsLoading && root.lyricsAvailable && !root.instrumental

                lines: root.lines
                focusMode: root.focusMode
                syncedAvailable: root.syncedAvailable
                syncedIndex: root.syncedIndex
                canSeek: root.canSeek
                accent: root.accent
                focusActive: root.focusActive
                focusSecondary: root.focusSecondary
                focusHalo: root.focusHalo
                onSeekRequested: time => root.seekRequested(time)
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        z: 200
        visible: root.focusMode
        acceptedButtons: Qt.RightButton
        onClicked: root.focusRequested()
    }
}
