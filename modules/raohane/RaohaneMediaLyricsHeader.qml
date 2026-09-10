pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property url artUrl: ""
    property color accent: RaohaneTheme.accent
    property string title: ""
    property string subtitle: ""
    property bool mediaAvailable: false
    property bool lyricsLoading: false
    property bool lyricsAvailable: false

    signal backRequested()
    signal refreshRequested()
    signal focusRequested()
    signal closeRequested()

    implicitHeight: 46

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 3
        anchors.rightMargin: 3
        spacing: 8

        MiniButton {
            icon: "arrow_back"
            tooltip: qsTr("Back to player")
            onClicked: root.backRequested()
        }

        RaohaneSurface {
            Layout.preferredWidth: 32
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            surfaceRadius: RaohaneTheme.radiusSmall
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.12)
            idleBorderColor: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.22)
            clip: true

            Image {
                id: cover
                anchors.fill: parent
                source: root.artUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: cover.status !== Image.Ready
                text: "音"
                color: root.accent
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.title
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.subtitle
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        MiniButton {
            icon: "refresh"
            tooltip: qsTr("Refresh lyrics")
            enabled: root.mediaAvailable && !root.lyricsLoading
            onClicked: root.refreshRequested()
        }

        MiniButton {
            icon: "fullscreen"
            tooltip: qsTr("Lyrics only")
            enabled: root.lyricsAvailable
            onClicked: root.focusRequested()
        }

        MiniButton {
            icon: "close"
            tooltip: qsTr("Close")
            onClicked: root.closeRequested()
        }
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
}
