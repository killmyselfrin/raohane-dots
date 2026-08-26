pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var popupNotifications: RaohaneNotifications.popupList.slice(-3).reverse()

    Loader {
        active: root.popupNotifications.length > 0 && !GlobalStates.sidebarRightOpen

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

                    delegate: RaohaneNotificationCard {
                        required property var modelData
                        width: notificationStack.width
                        notification: modelData
                    }
                }
            }
        }
    }
}
