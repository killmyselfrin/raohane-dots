pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string sectionKey: "general"
    readonly property var pageInfo: RaohaneSettingsPageRegistry.page(root.sectionKey)
    readonly property var entries: RaohaneSettingsPageRegistry.sectionEntries(root.sectionKey)
    readonly property string extensionSource: RaohaneSettingsSectionRegistry.source(root.sectionKey)

    function goTo(search: string): void {
        const needle = String(search ?? "").trim()
        if (needle === "")
            return
        if (RaohaneSettingsSectionRegistry.ownsControl(root.sectionKey, needle)) {
            settingsFlick.contentY = Math.max(0, extensionLoader.y - 18)
            return
        }
        const normalized = needle.toLowerCase()
        const index = root.entries.findIndex(entry => String(entry.label).toLowerCase().includes(normalized) || entry.key.toLowerCase().includes(normalized))
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

                        delegate: RaohaneSettingsControlRow {
                            required property var modelData
                            required property int index

                            width: settingsList.width
                            entry: modelData
                            lastRow: index >= root.entries.length - 1
                        }
                    }
                }
            }

            Loader {
                id: extensionLoader
                width: parent.width
                active: root.extensionSource !== ""
                visible: active
                source: root.extensionSource
                height: active ? implicitHeight : 0

                onLoaded: {
                    if (item && item.hasOwnProperty("width"))
                        item.width = width
                }
            }
        }
    }
}
