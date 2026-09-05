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
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 42
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: 28
                radius: 1
                color: RaohaneNotifications.silent ? RaohaneTheme.textFaint : RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: qsTr("Notifications")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.1
                }

                Text {
                    text: RaohaneNotifications.unread > 0
                        ? qsTr("%1 unread").arg(RaohaneNotifications.unread)
                        : qsTr("You're all caught up")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }

            RaohaneSurface {
                visible: RaohaneNotifications.unread > 0
                implicitWidth: unreadText.implicitWidth + 14
                implicitHeight: 24
                surfaceRadius: 7
                active: true
                showSheen: false

                Text {
                    id: unreadText
                    anchors.centerIn: parent
                    text: String(RaohaneNotifications.unread)
                    color: RaohaneTheme.accent
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
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
                spacing: 5
                model: root.notifications
                boundsBehavior: Flickable.StopAtBounds
                flickDeceleration: 2400

                delegate: Item {
                    id: centerEntry
                    required property var modelData
                    property bool entered: false

                    width: listView.width
                    height: card.implicitHeight
                    opacity: entered ? 1 : 0

                    Component.onCompleted: entered = true

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
                    }

                    RaohaneNotificationCard {
                        id: card
                        width: parent.width
                        notification: centerEntry.modelData
                        compact: true
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 6
                visible: RaohaneNotifications.list.length === 0

                RaohaneIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "notifications_none"
                    iconSize: 24
                    symbolWeight: 350
                    color: RaohaneTheme.textFaint
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No notifications")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("New activity will appear here")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }
        }
    }

    component ActionButton: RaohaneIconButton {
        id: action

        property string tooltip: ""
        signal triggered()

        buttonSize: 27
        iconSize: 14
        emphasized: active
        transparentIdle: !active
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        onClicked: action.triggered()
    }
}
