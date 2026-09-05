pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: root.compact ? 40 : 46
    surfaceRadius: 0
    transparentIdle: true
    showInnerRim: false
    showSheen: false
    border.width: 0

    RowLayout {
        anchors.fill: parent
        spacing: 9

        Rectangle {
            width: 2
            height: root.compact ? 22 : 26
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.58
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: qsTr("Move gently. Stay present.")
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.Medium
                font.letterSpacing: 0.1
            }

            Text {
                visible: !root.compact
                text: "静かに、前へ"
                color: RaohaneTheme.textMuted
                font.pixelSize: 7
                font.letterSpacing: 0.8
            }
        }
    }
}
