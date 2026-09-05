pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: root.compact ? 70 : 80
    surfaceRadius: 10
    raised: false
    showSheen: false
    border.color: RaohaneTheme.borderFaint

    Rectangle {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 2
        height: root.compact ? 24 : 28
        radius: 1
        color: RaohaneTheme.accent
        opacity: 0.58
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 10
        anchors.topMargin: 9
        anchors.bottomMargin: 9
        spacing: root.compact ? 6 : 7

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: qsTr("SYSTEM")
                color: RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Item { Layout.fillWidth: true }

            Text {
                text: RaohaneSystemInfo.hostname
                color: RaohaneTheme.textMuted
                font.pixelSize: 7
                elide: Text.ElideRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.borderFaint
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            StatusItem {
                Layout.fillWidth: true
                icon: RaohaneNetwork.materialSymbol
                text: RaohaneNetwork.networkName || (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
            }

            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 18
                color: RaohaneTheme.borderFaint
            }

            StatusItem {
                Layout.fillWidth: true
                icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                text: RaohaneAudio.muted ? qsTr("Muted") : Math.round(RaohaneAudio.volume * 100) + "%"
                active: !RaohaneAudio.muted
            }
        }
    }

    component StatusItem: RowLayout {
        id: statusItem

        required property string icon
        required property string text
        required property bool active

        spacing: 5

        RaohaneIcon {
            text: statusItem.icon
            iconSize: 13
            fill: statusItem.active ? 0.8 : 0
            color: statusItem.active ? RaohaneTheme.accent : RaohaneTheme.textFaint
        }

        Text {
            Layout.fillWidth: true
            text: statusItem.text
            color: RaohaneTheme.textMuted
            font.pixelSize: 8
            elide: Text.ElideRight
        }
    }
}
