pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property bool loading: false
    property bool instrumental: false
    property bool available: false
    property string errorText: ""
    property color accent: RaohaneTheme.accent

    visible: root.loading || root.instrumental || !root.available

    Column {
        anchors.centerIn: parent
        visible: root.loading
        spacing: 8

        RaohaneIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "lyrics"
            iconSize: 28
            color: root.accent
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
        visible: !root.loading && root.instrumental
        spacing: 7

        RaohaneIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "graphic_eq"
            iconSize: 30
            color: root.accent
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
        visible: !root.loading && !root.available && !root.instrumental
        spacing: 7

        RaohaneIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "lyrics"
            iconSize: 28
            color: RaohaneTheme.textFaint
        }

        Text {
            width: parent.width
            text: root.errorText.length > 0
                ? root.errorText
                : qsTr("Lyrics are not available yet")
            color: RaohaneTheme.textMuted
            font.pixelSize: 9
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
        }
    }
}
