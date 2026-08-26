pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.common.widgets
import qs.modules.raohane.services

Item {
    id: root

    readonly property var notifications: RaohaneNotifications.list.slice().reverse()

    implicitHeight: 300

    ColumnLayout {
        anchors.fill: parent
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: qsTr("通知  /  NOTIFICATIONS")
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.letterSpacing: 1.0
                font.weight: Font.DemiBold
            }

            Rectangle {
                width: unreadLabel.implicitWidth + 14
                height: 22
                radius: 11
                color: RaohaneNotifications.unread > 0 ? RaohaneTheme.accentSoft : "#18ffffff"
                border.width: 1
                border.color: RaohaneTheme.border

                Text {
                    id: unreadLabel
                    anchors.centerIn: parent
                    text: RaohaneNotifications.unread > 0
                        ? qsTr("%1 new").arg(RaohaneNotifications.unread)
                        : qsTr("clear")
                    color: RaohaneNotifications.unread > 0 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }

            Item { Layout.fillWidth: true }

            ActionButton {
                icon: RaohaneNotifications.silent ? "notifications_off" : "notifications_active"
                active: RaohaneNotifications.silent
                tooltip: RaohaneNotifications.silent
                    ? qsTr("Resume notification popups")
                    : qsTr("Pause notification popups")
                onTriggered: RaohaneNotifications.silent = !RaohaneNotifications.silent
            }

            ActionButton {
                icon: "done_all"
                tooltip: qsTr("Mark all read")
                enabled: RaohaneNotifications.unread > 0
                onTriggered: RaohaneNotifications.markAllRead()
            }

            ActionButton {
                icon: "delete_sweep"
                tooltip: qsTr("Clear all notifications")
                enabled: RaohaneNotifications.list.length > 0
                onTriggered: RaohaneNotifications.discardAllNotifications()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: listView
                anchors.fill: parent
                clip: true
                spacing: 8
                model: root.notifications
                boundsBehavior: Flickable.StopAtBounds

                delegate: RaohaneNotificationCard {
                    required property var modelData
                    width: listView.width
                    notification: modelData
                    compact: true
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 8
                visible: RaohaneNotifications.list.length === 0

                Rectangle {
                    width: 54
                    height: 54
                    radius: 18
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: RaohaneTheme.accentSoft
                    border.width: 1
                    border.color: RaohaneTheme.border

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: "notifications_none"
                        iconSize: 26
                        color: RaohaneTheme.accent
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No notifications")
                    color: RaohaneTheme.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Raohane is quiet for now")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                }
            }
        }
    }

    component ActionButton: Rectangle {
        id: action

        required property string icon
        property string tooltip: ""
        property bool active: false
        signal triggered()

        width: 28
        height: 28
        radius: 10
        opacity: enabled ? 1 : 0.4
        color: active || mouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
        border.width: 1
        border.color: active || mouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

        MaterialSymbol {
            anchors.centerIn: parent
            text: action.icon
            iconSize: 15
            color: action.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
        }

        MouseArea {
            id: mouse
            anchors.fill: parent
            enabled: action.enabled
            hoverEnabled: true
            cursorShape: action.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: action.triggered()
        }
    }
}
