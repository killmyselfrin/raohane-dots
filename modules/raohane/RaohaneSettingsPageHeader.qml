pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var pageInfo: null
    property bool compact: false

    implicitHeight: 72

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 18
        spacing: 10

        RaohaneSurface {
            Layout.preferredWidth: 34
            Layout.preferredHeight: 34
            surfaceRadius: 10
            active: true
            raised: false
            showSheen: false

            RaohaneIcon {
                anchors.centerIn: parent
                text: root.pageInfo?.icon ?? "settings"
                iconSize: 17
                fill: 1
                symbolWeight: 550
                grade: 30
                color: RaohaneTheme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                Layout.fillWidth: true
                text: root.pageInfo?.name ?? qsTr("Settings")
                color: RaohaneTheme.text
                font.pixelSize: 15
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.pageInfo?.subtitle ?? ""
                color: RaohaneTheme.textMuted
                font.pixelSize: 7
                elide: Text.ElideRight
            }
        }

        RaohaneSurface {
            visible: !root.compact
            Layout.preferredWidth: groupText.implicitWidth + 16
            Layout.preferredHeight: 22
            surfaceRadius: 8
            transparentIdle: true
            showSheen: false

            Text {
                id: groupText
                anchors.centerIn: parent
                text: root.pageInfo?.group ?? qsTr("SYSTEM")
                color: RaohaneTheme.textFaint
                font.pixelSize: 6
                font.weight: Font.DemiBold
                font.letterSpacing: 0.75
            }
        }

        Item {
            Layout.preferredWidth: root.compact ? 40 : 336
            Layout.fillHeight: true
        }
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 20
            rightMargin: 18
        }
        height: 1
        color: RaohaneTheme.borderFaint
    }
}
