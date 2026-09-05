pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: root.compact ? 46 : 54
    surfaceRadius: 0
    transparentIdle: true
    showInnerRim: false
    showSheen: false
    border.width: 0

    RowLayout {
        anchors.fill: parent
        spacing: 9

        Rectangle {
            width: 1
            height: 29
            radius: 1
            color: RaohaneTheme.accent
            opacity: 0.62
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: qsTr("Move gently. Stay present.")
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.Medium
            }

            Text {
                visible: !root.compact
                text: "静かに、前へ"
                color: RaohaneTheme.textMuted
                font.pixelSize: 7
                font.letterSpacing: 0.75
            }
        }
    }
}
