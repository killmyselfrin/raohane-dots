pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property string sectionKey: "general"
    readonly property var pageInfo: RaohaneSettingsPageRegistry.page(root.sectionKey)
    readonly property var entries: RaohaneSettingsPageRegistry.sectionEntries(root.sectionKey)

    function changeNumber(key: string, delta: real, minimum: real, maximum: real): void {
        const current = Number(RaohaneConfig[key] ?? 0)
        RaohaneConfig[key] = Math.max(minimum, Math.min(maximum, current + delta))
    }

    function goTo(search: string): void {
        const needle = String(search ?? "").toLowerCase()
        if (needle === "")
            return
        if (root.sectionKey === "bar" && (needle.includes("module") || needle.includes("studio") || needle.includes("layout"))) {
            settingsFlick.contentY = Math.max(0, settingsList.implicitHeight + 118)
            return
        }
        const index = root.entries.findIndex(entry => String(entry.label).toLowerCase().includes(needle) || entry.key.toLowerCase().includes(needle))
        if (index >= 0)
            settingsFlick.contentY = Math.max(0, index * 68 - 18)
    }

    Flickable {
        id: settingsFlick
        anchors.fill: parent
        contentWidth: width
        contentHeight: sectionColumn.implicitHeight + 42
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        Column {
            id: sectionColumn
            y: 18
            width: Math.min(settingsFlick.width - 48, 720)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            RaohaneSurface {
                width: parent.width
                height: 104
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                clip: true

                Rectangle {
                    width: 150
                    height: 150
                    radius: 75
                    anchors {
                        right: parent.right
                        top: parent.top
                        rightMargin: -45
                        topMargin: -72
                    }
                    color: RaohaneTheme.accentSoft
                    opacity: 0.48
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
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.pageInfo?.icon ?? "tune"
                            iconSize: 23
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            text: root.pageInfo?.name ?? qsTr("Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneSettingsPageRegistry.sectionDescription(root.sectionKey)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            lineHeight: 1.2
                            wrapMode: Text.WordWrap
                        }
                    }

                    RaohaneSurface {
                        Layout.preferredWidth: settingCount.implicitWidth + 22
                        Layout.preferredHeight: 28
                        surfaceRadius: 12
                        transparentIdle: true
                        showSheen: false

                        Text {
                            id: settingCount
                            anchors.centerIn: parent
                            text: qsTr("%1 settings").arg(root.entries.length)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            RaohaneSurface {
                width: parent.width
                height: settingsList.implicitHeight
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint
                clip: true

                Column {
                    id: settingsList
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: root.entries

                        delegate: Item {
                            id: settingRow
                            required property var modelData
                            required property int index
                            readonly property bool toggleRow: modelData.type === "toggle"
                            readonly property bool rowHovered: settingMouse.containsMouse || activeFocus

                            width: settingsList.width
                            height: modelData.type === "text" ? 76 : 64
                            activeFocusOnTab: toggleRow

                            Rectangle {
                                anchors.fill: parent
                                color: settingRow.rowHovered ? RaohaneTheme.surfaceHover : "transparent"
                                opacity: settingRow.rowHovered ? 0.72 : 0

                                Behavior on opacity {
                                    NumberAnimation { duration: RaohaneMotion.micro }
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 12
                                spacing: 18

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2

                                    Text {
                                        Layout.fillWidth: true
                                        text: settingRow.modelData.label
                                        color: RaohaneTheme.text
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: settingRow.modelData.detail
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                        lineHeight: 1.15
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                RaohaneSwitch {
                                    visible: settingRow.toggleRow
                                    Layout.preferredWidth: 42
                                    Layout.preferredHeight: 24
                                    checked: Boolean(RaohaneConfig[settingRow.modelData.key])
                                    enabled: false
                                    opacity: 1
                                }

                                RaohaneSurface {
                                    visible: settingRow.modelData.type === "number"
                                    Layout.preferredWidth: 126
                                    Layout.preferredHeight: 34
                                    surfaceRadius: 11
                                    raised: false
                                    showSheen: false
                                    border.color: RaohaneTheme.borderFaint

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 3
                                        anchors.rightMargin: 3
                                        spacing: 2

                                        RaohaneIconButton {
                                            buttonSize: 27
                                            iconSize: 13
                                            icon: "remove"
                                            transparentIdle: true
                                            showSheen: false
                                            onClicked: root.changeNumber(settingRow.modelData.key, -Number(settingRow.modelData.step), Number(settingRow.modelData.min), Number(settingRow.modelData.max))
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            horizontalAlignment: Text.AlignHCenter
                                            text: String(RaohaneConfig[settingRow.modelData.key])
                                            color: RaohaneTheme.text
                                            font.pixelSize: 9
                                            font.weight: Font.DemiBold
                                        }

                                        RaohaneIconButton {
                                            buttonSize: 27
                                            iconSize: 13
                                            icon: "add"
                                            transparentIdle: true
                                            showSheen: false
                                            onClicked: root.changeNumber(settingRow.modelData.key, Number(settingRow.modelData.step), Number(settingRow.modelData.min), Number(settingRow.modelData.max))
                                        }
                                    }
                                }

                                RaohaneSurface {
                                    visible: settingRow.modelData.type === "text"
                                    Layout.preferredWidth: Math.min(310, root.width * 0.42)
                                    Layout.preferredHeight: 34
                                    surfaceRadius: 10
                                    raised: false
                                    hovered: field.activeFocus
                                    showSheen: false
                                    border.color: field.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                                    TextInput {
                                        id: field
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        verticalAlignment: TextInput.AlignVCenter
                                        text: String(RaohaneConfig[settingRow.modelData.key] ?? "")
                                        color: RaohaneTheme.text
                                        selectionColor: RaohaneTheme.accentSoft
                                        selectedTextColor: RaohaneTheme.text
                                        font.pixelSize: 9
                                        clip: true
                                        onEditingFinished: RaohaneConfig[settingRow.modelData.key] = text
                                    }
                                }
                            }

                            Rectangle {
                                visible: settingRow.index < root.entries.length - 1
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    leftMargin: 16
                                    rightMargin: 16
                                }
                                height: 1
                                color: RaohaneTheme.borderFaint
                            }

                            MouseArea {
                                id: settingMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: settingRow.toggleRow ? Qt.LeftButton : Qt.NoButton
                                cursorShape: settingRow.toggleRow ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: settingRow.forceActiveFocus()
                                onClicked: {
                                    if (settingRow.toggleRow)
                                        RaohaneConfig[settingRow.modelData.key] = !Boolean(RaohaneConfig[settingRow.modelData.key])
                                }
                            }

                            Keys.onPressed: event => {
                                if (!settingRow.toggleRow)
                                    return
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    RaohaneConfig[settingRow.modelData.key] = !Boolean(RaohaneConfig[settingRow.modelData.key])
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }

            RaohaneBarStudio {
                visible: root.sectionKey === "bar"
                width: parent.width
            }
        }
    }
}
