pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property string orientation: RaohaneConfig.barVertical ? "vertical" : "horizontal"

    implicitHeight: studioColumn.implicitHeight

    ColumnLayout {
        id: studioColumn
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Bar Studio")
                    color: RaohaneTheme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Configure appearance and drag modules into the layout. Changes apply live and are saved automatically.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 48
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            border.color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    Layout.leftMargin: 5
                    text: qsTr("Editing layout")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 9
                    font.weight: Font.Medium
                }

                Item { Layout.fillWidth: true }

                Repeater {
                    model: [
                        { id: "horizontal", label: qsTr("Horizontal"), icon: "horizontal_rule" },
                        { id: "vertical", label: qsTr("Vertical"), icon: "more_vert" }
                    ]

                    delegate: RaohaneSurface {
                        id: modeButton
                        required property var modelData

                        readonly property bool selected: root.orientation === String(modelData.id)

                        Layout.preferredWidth: modeRow.implicitWidth + 20
                        Layout.preferredHeight: 32
                        surfaceRadius: RaohaneTheme.radius
                        raised: false
                        active: selected
                        transparentIdle: !selected
                        interactive: true
                        hovered: modeMouse.containsMouse
                        pressed: modeMouse.pressed
                        showSheen: false
                        showInnerRim: false
                        idleBorderColor: "transparent"
                        hoverBorderColor: "transparent"
                        activeBorderColor: "transparent"
                        activeColor: RaohaneTheme.accentSoft

                        RowLayout {
                            id: modeRow
                            anchors.centerIn: parent
                            spacing: 6

                            RaohaneIcon {
                                text: modeButton.modelData.icon
                                iconSize: 14
                                fill: modeButton.selected ? 1 : 0
                                color: modeButton.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }

                            Text {
                                text: modeButton.modelData.label
                                color: modeButton.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: modeButton.selected ? Font.DemiBold : Font.Medium
                            }
                        }

                        MouseArea {
                            id: modeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.orientation = String(modeButton.modelData.id)
                        }
                    }
                }
            }
        }

        RaohaneBarAppearanceSettings {
            Layout.fillWidth: true
        }

        RaohaneBarLayoutEditor {
            Layout.fillWidth: true
            orientation: root.orientation
        }
    }
}
