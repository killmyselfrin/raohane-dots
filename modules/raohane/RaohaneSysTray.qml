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
        spacing: RaohaneTheme.spacingTiny

        Repeater {
            model: SystemTray.items

            delegate: RaohaneSurface {
                id: trayButton

                required property SystemTrayItem modelData
                readonly property var trayItem: modelData ?? null

                Layout.preferredWidth: 27
                Layout.preferredHeight: 27
                surfaceRadius: RaohaneTheme.radiusSmall
                raised: false
                transparentIdle: true
                hovered: trayMouse.containsMouse
                pressed: trayMouse.pressed
                interactive: trayItem !== null
                hoverScale: 1
                pressedScale: 1
                showSheen: false
                showInnerRim: false
                idleBorderColor: "transparent"
                hoverBorderColor: RaohaneTheme.borderStrong
                pressedBorderColor: RaohaneTheme.borderStrong

                RaohaneAdaptiveIcon {
                    anchors.centerIn: parent
                    iconSource: String(trayButton.trayItem?.icon ?? "")
                    iconSize: 17
                    fallbackColor: trayButton.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                    imageScale: trayButton.transformMotionAllowed && trayMouse.pressed ? 0.92 : 1

                    Behavior on imageScale {
                        enabled: trayButton.transformMotionAllowed
                        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
                    }
                }

                function showMenu(): void {
                    const item = trayButton.trayItem
                    if (!root.parentWindow || !item || !item.hasMenu)
                        return
                    const point = trayButton.mapToItem(null, 0, trayButton.height)
                    item.display(root.parentWindow, Math.round(point.x), Math.round(point.y))
                }

                MouseArea {
                    id: trayMouse
                    anchors.fill: parent
                    enabled: trayButton.trayItem !== null
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: mouse => {
                        const item = trayButton.trayItem
                        if (!item)
                            return

                        if (mouse.button === Qt.MiddleButton) {
                            item.secondaryActivate()
                            return
                        }

                        if (mouse.button === Qt.RightButton || item.onlyMenu) {
                            trayButton.showMenu()
                            return
                        }

                        item.activate()
                    }

                    onWheel: wheel => {
                        const item = trayButton.trayItem
                        if (!item)
                            return
                        const delta = wheel.angleDelta.y !== 0 ? wheel.angleDelta.y : wheel.angleDelta.x
                        if (delta === 0)
                            return
                        item.scroll(delta, wheel.angleDelta.x !== 0 && wheel.angleDelta.y === 0)
                        wheel.accepted = true
                    }
                }
            }
        }
    }
}
