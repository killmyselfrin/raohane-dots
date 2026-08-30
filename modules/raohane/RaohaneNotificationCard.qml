pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.modules.raohane.services

RaohaneSurface {
    id: root

    required property var notification
    property bool compact: false
    property int bodyLineLimit: compact ? 2 : 4
    readonly property bool criticalNotification: notification.urgency === "critical"

    implicitHeight: Math.max(compact ? 90 : 104, content.implicitHeight + 24)
    surfaceRadius: compact ? 17 : 20
    raised: true
    border.color: criticalNotification ? RaohaneTheme.critical : RaohaneTheme.borderStrong
    clip: true

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 34
                height: 34
                radius: 12
                color: RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.border
                clip: true

                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    implicitSize: 22
                    source: root.notification.image !== ""
                        ? root.notification.image
                        : Quickshell.iconPath(root.notification.appIcon, "")
                    visible: source !== ""
                }

                RaohaneIcon {
                    anchors.centerIn: parent
                    visible: !appIcon.visible
                    text: root.criticalNotification ? "warning" : "notifications"
                    iconSize: 18
                    color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        Layout.fillWidth: true
                        text: root.notification.appName || qsTr("Notification")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.criticalNotification
                        text: qsTr("Urgent")
                        color: RaohaneTheme.critical
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                    }
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
                color: closeMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                border.width: closeMouse.containsMouse ? 1 : 0
                border.color: RaohaneTheme.border

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 14
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
            lineHeight: 1.08
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

                    width: Math.max(68, actionLabel.implicitWidth + 22)
                    height: 29
                    radius: 11
                    color: actionMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: actionMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.modelData.text
                        color: actionMouse.containsMouse ? RaohaneTheme.text : RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.Medium
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
