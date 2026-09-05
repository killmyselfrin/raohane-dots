pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool compact: false
    property date now: new Date()

    implicitHeight: root.compact ? 112 : 142

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
            spacing: 7

            Text {
                text: "生きる"
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.Medium
                font.letterSpacing: 1.2
            }

            Rectangle {
                width: 22
                height: 1
                radius: 1
                color: RaohaneTheme.textFaint
                opacity: 0.72
            }
        }

        Text {
            Layout.topMargin: 2
            text: Qt.formatTime(root.now, "HH:mm")
            color: RaohaneTheme.text
            font.pixelSize: root.compact ? 52 : 66
            font.weight: Font.ExtraLight
            font.letterSpacing: -2.4
        }

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: RaohaneTheme.textMuted
            font.pixelSize: 11
            font.weight: Font.Medium
        }
    }
}
