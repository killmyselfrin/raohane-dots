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
                flickDeceleration: 2400

                delegate: Item {
                    id: centerEntry
                    required property var modelData
                    property bool entered: false

                    width: listView.width
                    height: card.implicitHeight
                    opacity: entered ? 1 : 0
                    scale: entered ? 1 : 0.985

                    Component.onCompleted: entered = true

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
                    }
                    Behavior on scale {
                        NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
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
                spacing: 7
                visible: RaohaneNotifications.list.length === 0

                RaohaneSurface {
                    width: 48
                    height: 48
                    surfaceRadius: 15
                    anchors.horizontalCenter: parent.horizontalCenter
                    raised: false
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "notifications_none"
                        iconSize: 23
                        symbolWeight: 420
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

    component ActionButton: RaohaneIconButton {
        id: action

        property string tooltip: ""
        signal triggered()

        buttonSize: 28
        iconSize: 15
        emphasized: active
        transparentIdle: !active
        showSheen: false
        onClicked: action.triggered()
    }
}
