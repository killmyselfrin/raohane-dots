pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool compact: false
    property date now: new Date()

    implicitHeight: root.compact ? 98 : 124

    Timer {
        interval: 1000
        running: root.visible
        repeat: true
        onTriggered: root.now = new Date()
    }

    RowLayout {
        anchors.fill: parent
        spacing: 11

        Rectangle {
            Layout.preferredWidth: 2
            Layout.preferredHeight: root.compact ? 48 : 62
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.64
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                spacing: 7

                Text {
                    text: "生きる"
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    font.letterSpacing: 1.2
                }

                Rectangle {
                    width: 20
                    height: 1
                    radius: 1
                    color: RaohaneTheme.textFaint
                    opacity: 0.64
                }

                Text {
                    text: Qt.formatDate(root.now, "ddd").toUpperCase()
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.8
                }
            }

            Text {
                Layout.topMargin: 1
                text: Qt.formatTime(root.now, "HH:mm")
                color: RaohaneTheme.text
                font.pixelSize: root.compact ? 46 : 58
                font.weight: Font.ExtraLight
                font.letterSpacing: -2.1
            }

            Text {
                text: Qt.formatDate(root.now, "dddd, d MMMM")
                color: RaohaneTheme.textMuted
                font.pixelSize: root.compact ? 9 : 10
                font.weight: Font.Medium
            }
        }
    }
}
