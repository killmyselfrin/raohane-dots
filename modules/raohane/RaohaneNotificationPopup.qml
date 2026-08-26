pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Hyprland

import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var popupNotifications: Notifications.popupList.slice(-3).reverse()

    Loader {
        active: root.popupNotifications.length > 0

        sourceComponent: PanelWindow {
            id: panelWindow
            screen: root.focusedScreen
            visible: true
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            implicitWidth: 420
            implicitHeight: Math.min(610, notificationStack.implicitHeight)

            WlrLayershell.namespace: "quickshell:raohane-notification-popup"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                right: true
            }

            margins {
                top: Config.options.bar.bottom ? 14 : 72
                right: 14
            }

            mask: Region { item: notificationStack }

            Column {
                id: notificationStack
                width: 390
                spacing: 8

                Repeater {
                    model: root.popupNotifications

                    delegate: Rectangle {
                        id: notificationCard
                        required property var modelData

                        width: notificationStack.width
                        height: Math.max(104, cardContent.implicitHeight + 24)
                        radius: 22
                        color: RaohaneTheme.glassStrong
                        border.width: 1
                        border.color: modelData.urgency === "critical"
                            ? RaohaneTheme.critical
                            : RaohaneTheme.border
                        clip: true

                        Rectangle {
                            width: 3
                            anchors {
                                left: parent.left
                                top: parent.top
                                bottom: parent.bottom
                            }
                            radius: 2
                            color: notificationCard.modelData.urgency === "critical"
                                ? RaohaneTheme.critical
                                : RaohaneTheme.accent
                        }

                        ColumnLayout {
                            id: cardContent
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: 12
                                leftMargin: 14
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
                                        source: notificationCard.modelData.image !== ""
                                            ? notificationCard.modelData.image
                                            : Quickshell.iconPath(notificationCard.modelData.appIcon, "")
                                        visible: source !== ""
                                    }

                                    MaterialSymbol {
                                        anchors.centerIn: parent
                                        visible: !appIcon.visible
                                        text: notificationCard.modelData.urgency === "critical"
                                            ? "warning"
                                            : "notifications"
                                        iconSize: 19
                                        color: notificationCard.modelData.urgency === "critical"
                                            ? RaohaneTheme.critical
                                            : RaohaneTheme.accent
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: -1

                                    Text {
                                        Layout.fillWidth: true
                                        text: notificationCard.modelData.appName || qsTr("Notification")
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 0.5
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: notificationCard.modelData.summary
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

                                    MaterialSymbol {
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
                                        onClicked: Notifications.discardNotification(notificationCard.modelData.notificationId)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text.length > 0
                                text: notificationCard.modelData.body
                                textFormat: Text.PlainText
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                                wrapMode: Text.Wrap
                                maximumLineCount: 3
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                visible: notificationCard.modelData.actions.length > 0
                                spacing: 6

                                Item { Layout.fillWidth: true }

                                Repeater {
                                    model: notificationCard.modelData.actions.slice(0, 2)

                                    delegate: Rectangle {
                                        id: actionButton
                                        required property var modelData

                                        width: Math.max(66, actionLabel.implicitWidth + 20)
                                        height: 28
                                        radius: 14
                                        color: actionMouse.containsMouse
                                            ? RaohaneTheme.accentSoft
                                            : "#20ffffff"
                                        border.width: 1
                                        border.color: actionMouse.containsMouse
                                            ? RaohaneTheme.accent
                                            : RaohaneTheme.border

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
                                            onClicked: Notifications.attemptInvokeAction(
                                                notificationCard.modelData.notificationId,
                                                actionButton.modelData.identifier
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
