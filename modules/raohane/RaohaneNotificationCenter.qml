pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

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

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: qsTr("Notifications")
                    color: RaohaneTheme.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    text: RaohaneNotifications.unread > 0
                        ? qsTr("%1 unread").arg(RaohaneNotifications.unread)
                        : qsTr("You're all caught up")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                }
            }

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: RaohaneTheme.borderFaint
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: listView
                anchors.fill: parent
                clip: true
                spacing: 7
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
                spacing: 7
                visible: RaohaneNotifications.list.length === 0

                Rectangle {
                    width: 48
                    height: 48
                    radius: 15
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "notifications_none"
                        iconSize: 23
                        color: RaohaneTheme.textMuted
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No notifications")
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("New activity will appear here")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
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
        radius: 9
        opacity: enabled ? 1 : 0.4
        color: active
            ? RaohaneTheme.surfaceRaised
            : mouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: active || mouse.containsMouse ? 1 : 0
        border.color: active ? RaohaneTheme.borderStrong : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: action.icon
            iconSize: 15
            fill: action.active ? 1 : 0
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
