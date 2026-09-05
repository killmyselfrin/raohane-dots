pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Services.SystemTray

Item {
    id: root

    property var parentWindow: null

    visible: SystemTray.items.values.length > 0
    implicitWidth: trayRow.implicitWidth
    implicitHeight: 30

    RowLayout {
        id: trayRow
        anchors.centerIn: parent
        spacing: 3

        Repeater {
            model: SystemTray.items

            delegate: RaohaneSurface {
                id: trayButton

                required property SystemTrayItem modelData

                Layout.preferredWidth: 27
                Layout.preferredHeight: 27
                surfaceRadius: 8
                raised: false
                transparentIdle: true
                hovered: trayMouse.containsMouse
                pressed: trayMouse.pressed
                interactive: true
                hoverScale: 1
                pressedScale: 1
                showSheen: false
                border.color: trayButton.hovered ? RaohaneTheme.borderStrong : "transparent"

                RaohaneAdaptiveIcon {
                    anchors.centerIn: parent
                    iconSource: String(trayButton.modelData.icon ?? "")
                    iconSize: 17
                    fallbackColor: trayButton.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                    imageScale: trayButton.transformMotionAllowed && trayMouse.pressed ? 0.92 : 1

                    Behavior on imageScale {
                        enabled: trayButton.transformMotionAllowed
                        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                    }
                }

                function showMenu(): void {
                    if (!root.parentWindow || !trayButton.modelData.hasMenu)
                        return
                    const point = trayButton.mapToItem(null, 0, trayButton.height)
                    trayButton.modelData.display(root.parentWindow, Math.round(point.x), Math.round(point.y))
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: Qt.PointingHandCursor

                    onClicked: mouse => {
                        if (mouse.button === Qt.MiddleButton) {
                            trayButton.modelData.secondaryActivate()
                            return
                        }

                        if (mouse.button === Qt.RightButton || trayButton.modelData.onlyMenu) {
                            trayButton.showMenu()
                            return
                        }

                        trayButton.modelData.activate()
                    }

                    onWheel: wheel => {
                        const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                        if (delta === 0)
                            return
                        trayButton.modelData.scroll(delta, wheel.angleDelta.x !== 0 && wheel.angleDelta.y === 0)
                        wheel.accepted = true
                    }
                }
            }
        }
    }
}
