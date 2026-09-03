pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: root.compact ? 52 : 62
    surfaceRadius: 21
    raised: true
    showSheen: true
    opacity: 0.94

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 15
        anchors.rightMargin: 15
        spacing: 11

        Rectangle {
            width: 2
            height: 27
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.68
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: qsTr("Move gently. Stay present.")
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.Medium
            }

            Text {
                visible: !root.compact
                text: "静かに、前へ"
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                font.letterSpacing: 0.8
            }
        }

        RaohaneIcon {
            text: "spa"
            iconSize: 18
            fill: 0.18
            color: RaohaneTheme.accent
        }
    }
}
