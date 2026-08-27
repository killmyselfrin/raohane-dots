pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    signal activated()

    implicitWidth: statusRow.implicitWidth
    implicitHeight: 30

    RowLayout {
        id: statusRow
        anchors.centerIn: parent
        spacing: 7

        RaohaneIcon {
            text: RaohaneAudio.muted ? "volume_off" : "volume_up"
            iconSize: 17
            color: RaohaneAudio.muted ? RaohaneTheme.accent : RaohaneTheme.textMuted
        }

        RaohaneIcon {
            visible: RaohaneAudio.microphoneMuted
            text: "mic_off"
            iconSize: 16
            color: RaohaneTheme.accent
        }

        RaohaneIcon {
            text: RaohaneNetwork.materialSymbol
            iconSize: 17
            color: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                ? RaohaneTheme.text
                : RaohaneTheme.textMuted
        }

        RaohaneIcon {
            visible: RaohaneBluetooth.available
            text: RaohaneBluetooth.connected
                ? "bluetooth_connected"
                : RaohaneBluetooth.enabled ? "bluetooth" : "bluetooth_disabled"
            iconSize: 17
            color: RaohaneBluetooth.connected ? RaohaneTheme.accent : RaohaneTheme.textMuted
        }

        Item {
            visible: RaohaneNotifications.silent || RaohaneNotifications.unread > 0
            Layout.preferredWidth: 21
            Layout.preferredHeight: 22

            RaohaneIcon {
                anchors.centerIn: parent
                text: RaohaneNotifications.silent ? "notifications_off" : "notifications"
                iconSize: 16
                color: RaohaneNotifications.unread > 0 ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Rectangle {
                visible: RaohaneNotifications.unread > 0
                width: 7
                height: 7
                radius: 4
                anchors {
                    right: parent.right
                    top: parent.top
                }
                color: RaohaneTheme.accent
                border.width: 1
                border.color: RaohaneTheme.glassStrong
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.activated()
    }
}
