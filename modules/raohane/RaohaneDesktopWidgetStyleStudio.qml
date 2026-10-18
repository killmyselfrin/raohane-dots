pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

// Compact, static style catalog. No secondary media player, clock timer,
// hardware polling or QML loader is needed to preview a face.
Item {
    id: root

    readonly property var widgetTypes: [
        { id: "clock", icon: "schedule", title: qsTr("Clock") },
        { id: "context", icon: "music_note", title: qsTr("Music") },
        { id: "system", icon: "monitor_heart", title: qsTr("System") }
    ]
    readonly property var faceStyles: RaohaneDesktopWidgetRegistry.faceStyles

    implicitHeight: studio.implicitHeight

    ColumnLayout {
        id: studio
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 9

            RaohaneIcon {
                text: "dashboard_customize"
                iconSize: 20
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: qsTr("WIDGET LIBRARY")
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                    color: RaohaneTheme.text
                }
                Text {
                    text: qsTr("Three looks for every clock, music and system widget")
                    font.pixelSize: 10
                    color: RaohaneTheme.textMuted
                }
            }
        }

        Repeater {
            model: root.widgetTypes

            delegate: ColumnLayout {
                id: section
                required property var modelData
                readonly property string widgetId: String(modelData.id)

                Layout.fillWidth: true
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RaohaneIcon {
                        text: section.modelData.icon
                        iconSize: 16
                        color: RaohaneTheme.accent
                    }
                    Text {
                        text: section.modelData.title
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: qsTr("Select a face")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 9
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: root.faceStyles

                        delegate: RaohaneSurface {
                            id: faceCard
                            required property var modelData

                            readonly property string styleKey: String(modelData.key)
                            readonly property bool selected: RaohaneConfig.desktopWidgetStyle(section.widgetId) === styleKey

                            Layout.fillWidth: true
                            Layout.preferredHeight: 130
                            surfaceRadius: 12
                            showSheen: selected
                            raised: selected
                            hoverScale: 1
                            pressedScale: 1
                            idleColor: styleKey === "aurora" ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceDeep
                            border.width: selected ? 2 : 1
                            border.color: selected ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4
                                    Text {
                                        Layout.fillWidth: true
                                        text: faceCard.modelData.title
                                        color: RaohaneTheme.text
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                    RaohaneIcon {
                                        visible: faceCard.selected
                                        text: "check_circle"
                                        iconSize: 16
                                        color: RaohaneTheme.accent
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 51
                                    radius: faceCard.styleKey === "minimal" ? 5 : 10
                                    color: faceCard.styleKey === "aurora" ?
                                        RaohaneTheme.accentSoft : RaohaneTheme.background
                                    border.width: 1
                                    border.color: faceCard.styleKey === "aurora" ?
                                        RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 9
                                        spacing: 7

                                        Rectangle {
                                            Layout.preferredWidth: faceCard.styleKey === "minimal" ? 2 : 4
                                            Layout.fillHeight: true
                                            radius: 2
                                            color: RaohaneTheme.accent
                                        }

                                        RaohaneIcon {
                                            visible: section.widgetId !== "clock"
                                            text: section.modelData.icon
                                            iconSize: 21
                                            color: RaohaneTheme.accent
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: section.widgetId === "clock" ? "21:42"
                                                : section.widgetId === "context" ? qsTr("Now playing")
                                                : qsTr("Online · 72%")
                                            font.pixelSize: section.widgetId === "clock" ? 24 : 11
                                            font.weight: faceCard.styleKey === "minimal" ? Font.DemiBold : Font.Light
                                            color: RaohaneTheme.text
                                            elide: Text.ElideRight
                                        }
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: faceCard.modelData.detail
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneConfig.setDesktopWidgetStyle(section.widgetId, faceCard.styleKey)
                            }
                        }
                    }
                }
            }
        }
    }
}
