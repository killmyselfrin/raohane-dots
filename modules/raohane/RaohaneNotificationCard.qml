pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.modules.raohane.services

Rectangle {
    id: root

    required property var notification
    property bool compact: false
    property int bodyLineLimit: compact ? 2 : 4

    implicitHeight: Math.max(compact ? 92 : 104, content.implicitHeight + 24)
    radius: compact ? 18 : 22
    color: RaohaneTheme.glassStrong
    border.width: 1
    border.color: notification.urgency === "critical" ? RaohaneTheme.critical : RaohaneTheme.border
    clip: true

    Rectangle {
        width: 3
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        radius: 2
        color: root.notification.urgency === "critical" ? RaohaneTheme.critical : RaohaneTheme.accent
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
            leftMargin: 15
        }
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            Rectangle {
                width: 34
                height: 34
                radius: 12
                color: RaohaneTheme.accentSoft
                clip: true

                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    implicitSize: 23
                    source: root.notification.image !== ""
                        ? root.notification.image
                        : Quickshell.iconPath(root.notification.appIcon, "")
                    visible: source !== ""
                }

                RaohaneIcon {
                    anchors.centerIn: parent
                    visible: !appIcon.visible
                    text: root.notification.urgency === "critical" ? "warning" : "notifications"
                    iconSize: 19
                    color: root.notification.urgency === "critical" ? RaohaneTheme.critical : RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: -1

                Text {
                    Layout.fillWidth: true
                    text: root.notification.appName || qsTr("Notification")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.5
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.notification.summary || qsTr("Notification")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                width: 28
                height: 28
                radius: 10
                color: closeMouse.containsMouse ? "#28ffffff" : "transparent"

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 16
                    color: RaohaneTheme.textMuted
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: RaohaneNotifications.discardNotification(root.notification.notificationId)
                }
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification.body
            textFormat: Text.PlainText
            color: RaohaneTheme.textMuted
            font.pixelSize: 10
            wrapMode: Text.Wrap
            maximumLineCount: root.bodyLineLimit
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.notification.actions.length > 0
            spacing: 6

            Item { Layout.fillWidth: true }

            Repeater {
                model: root.notification.actions.slice(0, root.compact ? 1 : 2)

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: Math.max(66, actionLabel.implicitWidth + 20)
                    height: 28
                    radius: 14
                    color: actionMouse.containsMouse ? RaohaneTheme.accentSoft : "#20ffffff"
                    border.width: 1
                    border.color: actionMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.border

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.modelData.text
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: RaohaneNotifications.attemptInvokeAction(
                            root.notification.notificationId,
                            actionButton.modelData.identifier
                        )
                    }
                }
            }
        }
    }
}
