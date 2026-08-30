pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var themes: RaohaneTheme.presets

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 32
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 14
            topPadding: 12
            bottomPadding: 20

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: qsTr("Theme Library")
                        color: RaohaneTheme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Choose a complete Raohane mood. Layout and behavior stay the same; shared surfaces, text and accents update live.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    Layout.preferredWidth: activeLabel.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: 15
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.border

                    Text {
                        id: activeLabel
                        anchors.centerIn: parent
                        text: qsTr("Active · %1").arg(RaohaneTheme.presetName)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.preferredHeight: 78
                radius: RaohaneTheme.radiusLarge
                color: RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: RaohaneTheme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Rectangle {
                        width: 40
                        height: 40
                        radius: 14
                        color: RaohaneTheme.surfaceRaised
                        border.width: 1
                        border.color: RaohaneTheme.borderStrong

                        Text {
                            anchors.centerIn: parent
                            text: "静"
                            color: RaohaneTheme.accent
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Minimal by default")
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Themes use restrained glass, thin borders and quiet accents. No preset changes your workspace layout or shortcuts.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            wrapMode: Text.WordWrap
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                columns: root.width >= 940 ? 3 : 2
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: root.themes

                    delegate: Rectangle {
                        id: themeCard
                        required property var modelData
                        required property int index

                        readonly property bool selected: RaohaneConfig.themePreset === String(modelData.id)
                        readonly property bool hovered: themeMouse.containsMouse

                        Layout.fillWidth: true
                        Layout.preferredHeight: 190
                        radius: 20
                        color: modelData.surfaceRaised
                        border.width: selected ? 2 : 1
                        border.color: selected ? modelData.accent : modelData.border
                        clip: true

                        Behavior on border.color { ColorAnimation { duration: RaohaneTheme.animationFast } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 11
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 96
                                radius: 15
                                color: themeCard.modelData.background
                                border.width: 1
                                border.color: themeCard.modelData.border
                                clip: true

                                // Miniature top-bar composition.
                                Rectangle {
                                    x: 8
                                    y: 8
                                    width: 74
                                    height: 18
                                    radius: 9
                                    color: themeCard.modelData.surfaceRaised
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6
                                        Repeater {
                                            model: ["1", "2", "3", "4"]
                                            Text {
                                                required property var modelData
                                                text: modelData
                                                color: modelData === "2" ? themeCard.modelData.accent : themeCard.modelData.textMuted
                                                font.pixelSize: 6
                                                font.weight: modelData === "2" ? Font.Bold : Font.Normal
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        horizontalCenter: parent.horizontalCenter
                                        topMargin: 8
                                    }
                                    width: 92
                                    height: 20
                                    radius: 10
                                    color: themeCard.modelData.surfaceRaised
                                    border.width: 1
                                    border.color: themeCard.selected ? themeCard.modelData.accent : themeCard.modelData.border

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Text { text: "◌"; color: themeCard.modelData.accent; font.pixelSize: 7 }
                                        Text { text: "Raohane"; color: themeCard.modelData.text; font.pixelSize: 6; font.weight: Font.Medium }
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        right: parent.right
                                        topMargin: 8
                                        rightMargin: 8
                                    }
                                    width: 82
                                    height: 18
                                    radius: 9
                                    color: themeCard.modelData.surfaceRaised
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Text {
                                        anchors.centerIn: parent
                                        text: "◦  ◦  ◦   23:46"
                                        color: themeCard.modelData.textMuted
                                        font.pixelSize: 5
                                    }
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.52
                                    height: 35
                                    radius: 10
                                    color: themeCard.modelData.surface
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            top: parent.top
                                            margins: 7
                                        }
                                        height: 4
                                        radius: 2
                                        color: themeCard.modelData.textFaint
                                        opacity: 0.32
                                    }
                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            top: parent.top
                                            leftMargin: 7
                                            topMargin: 18
                                        }
                                        width: parent.width * 0.38
                                        height: 3
                                        radius: 2
                                        color: themeCard.modelData.accent
                                        opacity: 0.7
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        horizontalCenter: parent.horizontalCenter
                                        bottom: parent.bottom
                                        bottomMargin: 8
                                    }
                                    width: 112
                                    height: 20
                                    radius: 10
                                    color: themeCard.modelData.surfaceRaised
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 9
                                        Repeater {
                                            model: 5
                                            Rectangle {
                                                required property int index
                                                width: 6
                                                height: 6
                                                radius: 3
                                                color: index === 2 ? themeCard.modelData.accent : themeCard.modelData.textMuted
                                                opacity: index === 2 ? 1 : 0.55
                                            }
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        text: themeCard.modelData.name
                                        color: themeCard.modelData.text
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: themeCard.modelData.description
                                        color: themeCard.modelData.textMuted
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                }

                                Rectangle {
                                    width: toneLabel.implicitWidth + 14
                                    height: 22
                                    radius: 11
                                    color: themeCard.modelData.surfaceSubtle
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Text {
                                        id: toneLabel
                                        anchors.centerIn: parent
                                        text: themeCard.modelData.tone
                                        color: themeCard.modelData.textMuted
                                        font.pixelSize: 7
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5

                                Repeater {
                                    model: [
                                        themeCard.modelData.background,
                                        themeCard.modelData.surfaceRaised,
                                        themeCard.modelData.accent,
                                        themeCard.modelData.text
                                    ]

                                    Rectangle {
                                        required property var modelData
                                        width: 13
                                        height: 13
                                        radius: 7
                                        color: modelData
                                        border.width: 1
                                        border.color: themeCard.modelData.border
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                Text {
                                    text: themeCard.selected ? qsTr("Selected") : (themeCard.hovered ? qsTr("Apply") : "")
                                    color: themeCard.selected || themeCard.hovered ? themeCard.modelData.accent : themeCard.modelData.textFaint
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                }
                            }
                        }

                        Rectangle {
                            visible: themeCard.selected
                            anchors {
                                top: parent.top
                                right: parent.right
                                topMargin: 9
                                rightMargin: 9
                            }
                            width: 22
                            height: 22
                            radius: 11
                            color: themeCard.modelData.accent

                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: themeCard.modelData.background
                                font.pixelSize: 10
                                font.weight: Font.Bold
                            }
                        }

                        MouseArea {
                            id: themeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneConfig.themePreset = String(themeCard.modelData.id)
                        }
                    }
                }
            }
        }
    }
}
