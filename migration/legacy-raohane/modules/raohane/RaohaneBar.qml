import QtQuick
import Quickshell

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData

            screen: modelData
            anchors.top: true
            implicitHeight: 64
            color: "transparent"
            exclusiveZone: 64

            Rectangle {
                id: workspaceIsland
                width: 174
                height: RaohaneTheme.barHeight
                radius: RaohaneTheme.radius
                anchors.left: parent.left
                anchors.leftMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 10
                color: RaohaneTheme.glass
                border.width: 1
                border.color: RaohaneTheme.border

                Row {
                    anchors.centerIn: parent
                    spacing: 7

                    Repeater {
                        model: 5

                        Rectangle {
                            required property int index
                            width: index === 0 ? 32 : 18
                            height: 18
                            radius: 9
                            color: index === 0 ? RaohaneTheme.accent : RaohaneTheme.accentSoft

                            Text {
                                anchors.centerIn: parent
                                text: index + 1
                                color: index === 0 ? "#24172c" : RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }
                    }
                }
            }

            RaohaneContextIsland {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 8
            }

            Rectangle {
                width: 174
                height: RaohaneTheme.barHeight
                radius: RaohaneTheme.radius
                anchors.right: parent.right
                anchors.rightMargin: 14
                anchors.top: parent.top
                anchors.topMargin: 10
                color: RaohaneTheme.glass
                border.width: 1
                border.color: RaohaneTheme.border

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Text {
                        text: "⌁"
                        color: RaohaneTheme.accent
                        font.pixelSize: 15
                    }

                    Text {
                        id: clockLabel
                        color: RaohaneTheme.text
                        font.pixelSize: 12
                        font.weight: Font.DemiBold

                        function updateTime(): void {
                            text = Qt.formatDateTime(new Date(), "ddd  hh:mm")
                        }

                        Component.onCompleted: updateTime()

                        Timer {
                            interval: 1000
                            running: true
                            repeat: true
                            onTriggered: clockLabel.updateTime()
                        }
                    }
                }
            }
        }
    }
}
