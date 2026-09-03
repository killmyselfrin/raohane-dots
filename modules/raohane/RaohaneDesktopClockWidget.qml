pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool compact: false
    property date now: new Date()

    implicitHeight: root.compact ? 118 : 148

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 1

        RowLayout {
            spacing: 8

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: RaohaneTheme.accent
            }

            Text {
                text: "ラオハネ  ·  RAOHANE"
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1.4
            }
        }

        Text {
            Layout.topMargin: 4
            text: Qt.formatTime(root.now, "HH:mm")
            color: RaohaneTheme.text
            font.pixelSize: root.compact ? 58 : 76
            font.weight: Font.Light
            font.letterSpacing: -3
        }

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: RaohaneTheme.textMuted
            font.pixelSize: 13
            font.weight: Font.Medium
        }
    }
}
