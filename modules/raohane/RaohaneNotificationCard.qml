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
    border.color: criticalNotification ? RaohaneTheme.critical : (hovered ? RaohaneTheme.borderStrong : RaohaneTheme.border)
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeEmphasized }
    }

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
                    fill: root.criticalNotification ? 1 : 0
                    symbolWeight: root.criticalNotification ? 560 : 430
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

            RaohaneIconButton {
                buttonSize: root.effectiveCompact ? 26 : 28
                iconSize: 14
                icon: "close"
                transparentIdle: true
                showSheen: false
                onClicked: RaohaneNotifications.discardNotification(root.notification.notificationId)
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

                delegate: RaohaneSurface {
                    id: actionButton
                    required property var modelData

                    width: Math.max(68, actionLabel.implicitWidth + 22)
                    height: root.effectiveCompact ? 27 : 29
                    surfaceRadius: 11
                    raised: false
                    showSheen: false
                    interactive: true
                    hovered: actionMouse.containsMouse || activeFocus
                    pressed: actionMouse.pressed
                    hoverScale: 1.015
                    pressedScale: RaohaneMotion.pressScale
                    activeFocusOnTab: true

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.modelData.text
                        color: actionButton.pressed || actionButton.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.Medium

                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    }

                    MouseArea {
                        id: actionMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: actionButton.forceActiveFocus()
                        onClicked: RaohaneNotifications.attemptInvokeAction(
                            root.notification.notificationId,
                            actionButton.modelData.identifier
                        )
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            RaohaneNotifications.attemptInvokeAction(
                                root.notification.notificationId,
                                actionButton.modelData.identifier
                            )
                            event.accepted = true
                        }
                    }
                }
            }
        }
    }
}
