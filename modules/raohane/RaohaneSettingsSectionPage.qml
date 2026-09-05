pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string sectionKey: "general"
    readonly property var pageInfo: RaohaneSettingsPageRegistry.page(root.sectionKey)
    readonly property var entries: RaohaneSettingsPageRegistry.sectionEntries(root.sectionKey)
    readonly property string extensionSource: RaohaneSettingsSectionRegistry.source(root.sectionKey)
    readonly property string previewSource: RaohaneSettingsSectionRegistry.previewSource(root.sectionKey)
    property string pendingSearch: ""
    property string highlightedKey: ""

    function goTo(search: string): void {
        root.pendingSearch = String(search ?? "").trim()
        Qt.callLater(root.revealRequestedControl)
    }

    function revealRequestedControl(): void {
        const needle = root.pendingSearch
        if (needle === "")
            return
        settingsList.forceLayout()
        sectionColumn.forceLayout()
        let target = null
        if (RaohaneSettingsSectionRegistry.ownsControl(root.sectionKey, needle)) {
            if (extensionLoader.status !== Loader.Ready)
                return
            target = extensionLoader
        } else {
            const normalized = needle.toLowerCase()
            let index = root.entries.findIndex(entry => entry.key.toLowerCase() === normalized)
            if (index < 0)
                index = root.entries.findIndex(entry => String(entry.label).toLowerCase().includes(normalized) || entry.key.toLowerCase().includes(normalized))
            if (index < 0) {
                root.pendingSearch = ""
                return
            }
            target = controlRepeater.itemAt(index)
            if (!target)
                return
            root.highlightedKey = root.entries[index].key
            highlightTimeout.restart()
        }
        const position = target.mapToItem(settingsFlick.contentItem, 0, 0)
        const maximum = Math.max(0, settingsFlick.contentHeight - settingsFlick.height)
        settingsFlick.contentY = Math.min(maximum, Math.max(0, position.y - 18))
        root.pendingSearch = ""
    }

    onSectionKeyChanged: {
        root.pendingSearch = ""
        root.highlightedKey = ""
        highlightTimeout.stop()
        settingsFlick.contentY = 0
    }

    Timer {
        id: highlightTimeout
        interval: 1800
        onTriggered: root.highlightedKey = ""
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

            Loader {
                width: parent.width
                active: root.previewSource !== ""
                visible: active
                source: root.previewSource
                height: active ? implicitHeight : 0
                onLoaded: Qt.callLater(root.revealRequestedControl)
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
                        id: controlRepeater
                        model: root.entries
                        onItemAdded: Qt.callLater(root.revealRequestedControl)

                        delegate: RaohaneSettingsControlRow {
                            required property var modelData
                            required property int index

                            width: settingsList.width
                            entry: modelData
                            highlighted: root.highlightedKey === modelData.key
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
                    Qt.callLater(root.revealRequestedControl)
                }
            }
        }
    }
}
