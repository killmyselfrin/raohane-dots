pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var pageInfo: null
    property bool compact: false

    implicitHeight: 82

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 20
        spacing: 11

        RaohaneSurface {
            Layout.preferredWidth: 38
            Layout.preferredHeight: 38
            surfaceRadius: 12
            raised: false
            showSheen: false

            RaohaneIcon {
                anchors.centerIn: parent
                text: root.pageInfo?.icon ?? "settings"
                iconSize: 19
                fill: 1
                symbolWeight: 520
                color: RaohaneTheme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.pageInfo?.group ?? qsTr("SYSTEM")
                color: RaohaneTheme.accent
                opacity: 0.78
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 0.8
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.pageInfo?.name ?? qsTr("Settings")
                color: RaohaneTheme.text
                font.pixelSize: 18
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: root.pageInfo?.subtitle ?? ""
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        Item {
            Layout.preferredWidth: root.compact ? 46 : 360
            Layout.fillHeight: true
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 24
            rightMargin: 20
        }
        height: 1
        color: RaohaneTheme.borderFaint
    }
}
