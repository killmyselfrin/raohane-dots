pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    implicitHeight: content.implicitHeight

    Column {
        id: content
        width: parent.width
        spacing: 12

        RaohaneSurface {
            width: parent.width
            height: 116
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            border.color: RaohaneTheme.borderFaint
            clip: true

            RaohaneSakuraOverlay {
                anchors.fill: parent
                active: root.visible
                intensity: "subtle"
                speed: "gentle"
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 14

                RaohaneSurface {
                    Layout.preferredWidth: 48
                    Layout.preferredHeight: 48
                    surfaceRadius: 15
                    active: RaohaneConfig.sakuraEnabled
                    showSheen: false

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "local_florist"
                        iconSize: 23
                        fill: RaohaneConfig.sakuraEnabled ? 1 : 0
                        color: RaohaneConfig.sakuraEnabled ? "#f3a9c6" : RaohaneTheme.textMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3

                    Text {
                        text: qsTr("Sakura ambience")
                        color: RaohaneTheme.text
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("A quiet layer of falling petals for Raohane surfaces. The animation sleeps whenever its surface is closed.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        lineHeight: 1.18
                        wrapMode: Text.WordWrap
                    }

                    Text {
                        text: "花びら · hanabira"
                        color: "#e89ab8"
                        font.pixelSize: 7
                        font.weight: Font.Medium
                        font.letterSpacing: 0.7
                    }
                }

                RaohaneSwitch {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 24
                    checked: RaohaneConfig.sakuraEnabled
                    enabled: false
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: RaohaneConfig.sakuraEnabled = !RaohaneConfig.sakuraEnabled
            }
        }

        RaohaneSurface {
            width: parent.width
            height: locationRows.implicitHeight
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            border.color: RaohaneTheme.borderFaint

            Column {
                id: locationRows
                width: parent.width

                ToggleRow {
                    width: parent.width
                    title: qsTr("Settings")
                    detail: qsTr("Let petals drift behind Settings content")
                    checked: RaohaneConfig.sakuraInSettings
                    onToggled: RaohaneConfig.sakuraInSettings = !RaohaneConfig.sakuraInSettings
                }

                Rectangle {
                    width: parent.width - 28
                    height: 1
                    x: 14
                    color: RaohaneTheme.borderFaint
                }

                ToggleRow {
                    width: parent.width
                    title: qsTr("Control Center")
                    detail: qsTr("Show the same ambient layer behind quick controls")
                    checked: RaohaneConfig.sakuraInControlCenter
                    onToggled: RaohaneConfig.sakuraInControlCenter = !RaohaneConfig.sakuraInControlCenter
                }
            }
        }

        RaohaneSurface {
            width: parent.width
            height: tuningColumn.implicitHeight + 20
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            border.color: RaohaneTheme.borderFaint

            ColumnLayout {
                id: tuningColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 14
                    rightMargin: 14
                    topMargin: 10
                }
                spacing: 10

                ChoiceRow {
                    Layout.fillWidth: true
                    title: qsTr("Petal density")
                    detail: qsTr("Subtle is the recommended responsive default")
                    value: RaohaneConfig.sakuraIntensity
                    options: [
                        { value: "subtle", label: qsTr("Subtle") },
                        { value: "standard", label: qsTr("Standard") },
                        { value: "cinematic", label: qsTr("Cinematic") }
                    ]
                    onSelected: value => RaohaneConfig.sakuraIntensity = value
                }

                ChoiceRow {
                    Layout.fillWidth: true
                    title: qsTr("Fall speed")
                    detail: qsTr("Controls the vertical fall, drift and rotation cadence")
                    value: RaohaneConfig.sakuraSpeed
                    options: [
                        { value: "slow", label: qsTr("Slow") },
                        { value: "gentle", label: qsTr("Gentle") },
                        { value: "brisk", label: qsTr("Brisk") }
                    ]
                    onSelected: value => RaohaneConfig.sakuraSpeed = value
                }
            }
        }
    }

    component ToggleRow: Item {
        id: toggleRow
        required property string title
        required property string detail
        required property bool checked
        signal toggled()

        height: 58

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 14

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: toggleRow.title; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                Text { Layout.fillWidth: true; text: toggleRow.detail; color: RaohaneTheme.textFaint; font.pixelSize: 7; elide: Text.ElideRight }
            }

            RaohaneSwitch {
                Layout.preferredWidth: 40
                Layout.preferredHeight: 22
                checked: toggleRow.checked
                enabled: false
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleRow.toggled()
        }
    }

    component ChoiceRow: Item {
        id: choiceRow
        required property string title
        required property string detail
        required property string value
        required property var options
        signal selected(string value)

        implicitHeight: 54

        RowLayout {
            anchors.fill: parent
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { text: choiceRow.title; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                Text { Layout.fillWidth: true; text: choiceRow.detail; color: RaohaneTheme.textFaint; font.pixelSize: 7; elide: Text.ElideRight }
            }

            RowLayout {
                spacing: 4

                Repeater {
                    model: choiceRow.options

                    delegate: RaohaneSurface {
                        required property var modelData
                        readonly property bool selected: String(modelData.value) === choiceRow.value

                        Layout.preferredWidth: 72
                        Layout.preferredHeight: 30
                        surfaceRadius: 9
                        raised: false
                        showSheen: false
                        active: selected
                        interactive: true
                        hovered: optionMouse.containsMouse
                        transparentIdle: !selected && !hovered
                        border.color: selected ? RaohaneTheme.accentBorder
                            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                        Text {
                            anchors.centerIn: parent
                            text: modelData.label
                            color: selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: optionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: choiceRow.selected(String(modelData.value))
                        }
                    }
                }
            }
        }
    }
}
