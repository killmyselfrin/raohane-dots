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
        spacing: 4

        Repeater {
            model: SystemTray.items

            delegate: Rectangle {
                id: trayButton

                required property SystemTrayItem modelData

                Layout.preferredWidth: 28
                Layout.preferredHeight: 28
                radius: 9
                color: trayMouse.containsMouse ? "#24ffffff" : "transparent"

                Image {
                    anchors.centerIn: parent
                    width: 18
                    height: 18
                    source: trayButton.modelData.icon
                    sourceSize.width: 18
                    sourceSize.height: 18
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    smooth: true
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
