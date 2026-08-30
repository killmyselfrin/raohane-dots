pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

import qs.modules.raohane.config
import qs.modules.raohane.services

RaohaneSurface {
    id: root

    required property var notification
    property bool compact: false

    readonly property var styleConfig: RaohaneConfig.style ?? ({})
    readonly property bool effectiveCompact: compact || Boolean(styleConfig.notificationCompact ?? false)
    readonly property real notificationScale: Number(styleConfig.notificationScale ?? 1.0)
    readonly property int styleBodyLines: Math.max(1, Math.min(6, Number(styleConfig.notificationBodyLines ?? 4)))
    property int bodyLineLimit: effectiveCompact ? Math.min(2, styleBodyLines) : styleBodyLines
    readonly property bool criticalNotification: notification.urgency === "critical"

    implicitHeight: Math.round(Math.max(effectiveCompact ? 90 : 104, content.implicitHeight + 24) * notificationScale)
    surfaceRadius: Math.round((effectiveCompact ? 17 : 20) * notificationScale)
    raised: true
    border.color: criticalNotification ? RaohaneTheme.critical : RaohaneTheme.borderStrong
    clip: true

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.effectiveCompact ? 10 : 12
        }
        spacing: root.effectiveCompact ? 5 : 7

        RowLayout {
            Layout.fillWidth: true
            spacing: root.effectiveCompact ? 8 : 10

            Rectangle {
                width: root.effectiveCompact ? 30 : 34
                height: width
                radius: root.effectiveCompact ? 10 : 12
                color: RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.border
                clip: true

                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    implicitSize: root.effectiveCompact ? 19 : 22
                    source: root.notification.image !== ""
                        ? root.notification.image
                        : Quickshell.iconPath(root.notification.appIcon, "")
                    visible: source !== ""
                }

                RaohaneIcon {
                    anchors.centerIn: parent
                    visible: !appIcon.visible
                    text: root.criticalNotification ? "warning" : "notifications"
                    iconSize: root.effectiveCompact ? 16 : 18
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
                    font.pixelSize: root.effectiveCompact ? 11 : 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                width: root.effectiveCompact ? 26 : 28
                height: width
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
            font.pixelSize: root.effectiveCompact ? 9 : 10
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
                model: root.notification.actions.slice(0, root.effectiveCompact ? 1 : 2)

                delegate: Rectangle {
                    id: actionButton
                    required property var modelData

                    width: Math.max(68, actionLabel.implicitWidth + 22)
                    height: root.effectiveCompact ? 27 : 29
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
