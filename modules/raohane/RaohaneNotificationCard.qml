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

    implicitHeight: Math.max(compact ? 92 : 108, content.implicitHeight + 26)
    surfaceRadius: compact ? 17 : 20
    raised: true
    border.color: criticalNotification ? RaohaneTheme.critical : RaohaneTheme.borderStrong
    clip: true

    Rectangle {
        width: 3
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
        }
        radius: 2
        color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.accent
        opacity: 0.9
    }

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: 24
            rightMargin: 24
        }
        height: 1
        color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.accentSecondary
        opacity: 0.26
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
            leftMargin: 16
        }
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                width: 36
                height: 36
                radius: 13
                color: root.criticalNotification ? "#32ff6f91" : RaohaneTheme.accentSoft
                border.width: 1
                border.color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.borderStrong
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
                    text: root.criticalNotification ? "warning" : "notifications"
                    iconSize: 19
                    color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.accent
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
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.7
                        elide: Text.ElideRight
                    }

                    Rectangle {
                        visible: root.criticalNotification
                        implicitWidth: criticalLabel.implicitWidth + 12
                        implicitHeight: 20
                        radius: 8
                        color: "#2eff6f91"

                        Text {
                            id: criticalLabel
                            anchors.centerIn: parent
                            text: "URGENT"
                            color: RaohaneTheme.critical
                            font.pixelSize: 7
                            font.weight: Font.Bold
                            font.letterSpacing: 0.7
                        }
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
                width: 30
                height: 30
                radius: 11
                color: closeMouse.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
                border.width: closeMouse.containsMouse ? 1 : 0
                border.color: RaohaneTheme.borderStrong

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "close"
                    iconSize: 15
                    color: closeMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
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
                    height: 30
                    radius: 11
                    color: actionMouse.containsMouse ? RaohaneTheme.accentHover : RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: actionMouse.containsMouse ? RaohaneTheme.accentBorder : RaohaneTheme.border

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.modelData.text
                        color: actionMouse.containsMouse ? RaohaneTheme.text : RaohaneTheme.textMuted
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
