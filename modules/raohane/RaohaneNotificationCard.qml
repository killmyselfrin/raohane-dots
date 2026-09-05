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

    implicitHeight: Math.round(Math.max(effectiveCompact ? 76 : 88, content.implicitHeight + 20) * notificationScale)
    surfaceRadius: Math.round((effectiveCompact ? 11 : 13) * notificationScale)
    raised: false
    showSheen: false
    border.color: criticalNotification
        ? RaohaneTheme.critical
        : RaohaneTheme.borderFaint
    color: criticalNotification
        ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.055)
        : RaohaneTheme.surfaceDeep
    clip: true

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 2
            topMargin: 9
            bottomMargin: 9
        }
        width: 2
        radius: 1
        color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.accent
        opacity: root.criticalNotification ? 1 : 0.46
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: root.effectiveCompact ? 9 : 10
        }
        spacing: root.effectiveCompact ? 4 : 6

        RowLayout {
            Layout.fillWidth: true
            spacing: root.effectiveCompact ? 7 : 8

            Rectangle {
                width: root.effectiveCompact ? 28 : 31
                height: width
                radius: root.effectiveCompact ? 8 : 9
                color: RaohaneTheme.surfaceRaised
                border.width: 1
                border.color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.borderFaint
                clip: true

                IconImage {
                    id: appIcon
                    anchors.centerIn: parent
                    implicitSize: root.effectiveCompact ? 18 : 20
                    source: root.notification.image !== ""
                        ? root.notification.image
                        : Quickshell.iconPath(root.notification.appIcon, "")
                    visible: source !== ""
                }

                RaohaneIcon {
                    anchors.centerIn: parent
                    visible: !appIcon.visible
                    text: root.criticalNotification ? "warning" : "notifications"
                    iconSize: root.effectiveCompact ? 15 : 17
                    fill: root.criticalNotification ? 1 : 0
                    symbolWeight: root.criticalNotification ? 560 : 390
                    color: root.criticalNotification ? RaohaneTheme.critical : RaohaneTheme.textFaint
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Text {
                        Layout.fillWidth: true
                        text: root.notification.appName || qsTr("Notification")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: root.criticalNotification
                        text: qsTr("Urgent")
                        color: RaohaneTheme.critical
                        font.pixelSize: 6
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.notification.summary || qsTr("Notification")
                    color: RaohaneTheme.text
                    font.pixelSize: root.effectiveCompact ? 9 : 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            RaohaneIconButton {
                buttonSize: root.effectiveCompact ? 24 : 26
                iconSize: 13
                icon: "close"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: RaohaneNotifications.discardNotification(root.notification.notificationId)
            }
        }

        Text {
            Layout.fillWidth: true
            visible: text.length > 0
            text: root.notification.body
            textFormat: Text.PlainText
            color: RaohaneTheme.textMuted
            font.pixelSize: root.effectiveCompact ? 8 : 9
            lineHeight: 1.06
            wrapMode: Text.Wrap
            maximumLineCount: root.bodyLineLimit
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            visible: root.notification.actions.length > 0
            spacing: 5

            Item { Layout.fillWidth: true }

            Repeater {
                model: root.notification.actions.slice(0, root.effectiveCompact ? 1 : 2)

                delegate: RaohaneSurface {
                    id: actionButton
                    required property var modelData

                    width: Math.max(64, actionLabel.implicitWidth + 18)
                    height: root.effectiveCompact ? 24 : 26
                    surfaceRadius: 7
                    raised: false
                    showSheen: false
                    interactive: true
                    hovered: actionMouse.containsMouse || activeFocus
                    pressed: actionMouse.pressed
                    hoverScale: 1
                    pressedScale: 1
                    activeFocusOnTab: true
                    border.color: hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint
                    color: hovered ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceSubtle

                    Text {
                        id: actionLabel
                        anchors.centerIn: parent
                        text: actionButton.modelData.text
                        color: actionButton.pressed || actionButton.hovered
                            ? RaohaneTheme.text
                            : RaohaneTheme.textMuted
                        font.pixelSize: 7
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
