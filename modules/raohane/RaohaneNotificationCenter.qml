pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

RaohaneSurface {
    id: root

    readonly property var notifications: RaohaneNotifications.list.slice().reverse()

    implicitHeight: 320
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    idleBorderColor: RaohaneTheme.borderFaint
    clip: true
    showStateRail: RaohaneNotifications.unread > 0 || RaohaneNotifications.silent
    stateRailColor: RaohaneNotifications.silent ? RaohaneTheme.textFaint : RaohaneTheme.accent
    stateRailOpacity: RaohaneNotifications.silent ? 0.42 : 0.72
    stateRailWidth: 3
    stateRailLength: 30

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: RaohaneTheme.spacing
        spacing: RaohaneTheme.spacingSmall + 2

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 44
            spacing: RaohaneTheme.spacing

            RaohaneSurface {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                Layout.alignment: Qt.AlignVCenter
                surfaceRadius: RaohaneTheme.radiusLarge
                active: RaohaneNotifications.unread > 0 && !RaohaneNotifications.silent
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                idleBorderColor: RaohaneTheme.borderFaint

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: RaohaneNotifications.silent ? "notifications_off" : "notifications"
                    iconSize: 17
                    fill: RaohaneNotifications.unread > 0 && !RaohaneNotifications.silent ? 1 : 0
                    symbolWeight: RaohaneNotifications.unread > 0 ? 540 : 420
                    color: RaohaneNotifications.silent ? RaohaneTheme.textFaint
                        : RaohaneNotifications.unread > 0 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

                Text {
                    text: qsTr("Notifications")
                    color: RaohaneTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.1
                }

                Text {
                    text: RaohaneNotifications.unread > 0
                        ? qsTr("%1 unread").arg(RaohaneNotifications.unread)
                        : qsTr("You're all caught up")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                }
            }

            RaohaneSurface {
                visible: RaohaneNotifications.unread > 0
                implicitWidth: unreadText.implicitWidth + RaohaneTheme.spacingLarge
                implicitHeight: 26
                surfaceRadius: RaohaneTheme.radiusSmall
                active: true
                showSheen: false
                showInnerRim: false

                Text {
                    id: unreadText
                    anchors.centerIn: parent
                    text: String(RaohaneNotifications.unread)
                    color: RaohaneTheme.accent
                    font.pixelSize: 8
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
                spacing: RaohaneTheme.spacingSmall + 1
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
                spacing: RaohaneTheme.spacingSmall + 2
                visible: RaohaneNotifications.list.length === 0

                RaohaneSurface {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 42
                    height: 42
                    surfaceRadius: RaohaneTheme.radiusLarge
                    raised: false
                    showSheen: false
                    showInnerRim: false
                    idleColor: RaohaneTheme.surfaceSubtle
                    idleBorderColor: RaohaneTheme.borderFaint

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "notifications_none"
                        iconSize: 22
                        symbolWeight: 350
                        color: RaohaneTheme.textFaint
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("No notifications")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("New activity will appear here")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                }
            }
        }
    }

    component ActionButton: RaohaneIconButton {
        id: action

        property string tooltip: ""
        signal triggered()

        buttonSize: 30
        iconSize: 15
        emphasized: active
        transparentIdle: !active
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        onClicked: action.triggered()
    }
}
