pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string sectionKey: "general"
    property bool headerEntered: false
    property bool settingsEntered: false
    property bool extensionEntered: false

    readonly property var pageInfo: RaohaneSettingsPageRegistry.page(root.sectionKey)
    readonly property var entries: RaohaneSettingsPageRegistry.sectionEntries(root.sectionKey)
    readonly property string extensionSource: RaohaneSettingsSectionRegistry.source(root.sectionKey)

    function replayEntrance(): void {
        headerEntered = false
        settingsEntered = false
        extensionEntered = false
        headerTimer.restart()
        settingsTimer.restart()
        extensionTimer.restart()
    }

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

    onSectionKeyChanged: Qt.callLater(root.replayEntrance)
    Component.onCompleted: root.replayEntrance()

    Timer {
        id: headerTimer
        interval: 1
        repeat: false
        onTriggered: root.headerEntered = true
    }

    Timer {
        id: settingsTimer
        interval: Math.max(1, RaohaneMotion.staggerStep)
        repeat: false
        onTriggered: root.settingsEntered = true
    }

    Timer {
        id: extensionTimer
        interval: Math.max(1, RaohaneMotion.staggerStep * 2)
        repeat: false
        onTriggered: root.extensionEntered = true
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
                id: sectionHero
                width: parent.width
                height: 104
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                clip: true
                opacity: root.headerEntered ? 1 : 0

                transform: Translate {
                    y: root.headerEntered || !RaohaneMotion.transformMotionEnabled ? 0 : 8
                    Behavior on y {
                        NumberAnimation {
                            duration: RaohaneMotion.relaxed
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeStandard
                    }
                }

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
                    opacity: root.headerEntered ? 0.48 : 0.15

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneMotion.relaxed }
                    }
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
                id: settingsSurface
                width: parent.width
                height: settingsList.implicitHeight
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint
                clip: true
                opacity: root.settingsEntered ? 1 : 0

                transform: Translate {
                    y: root.settingsEntered || !RaohaneMotion.transformMotionEnabled ? 0 : 10
                    Behavior on y {
                        NumberAnimation {
                            duration: RaohaneMotion.relaxed
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeStandard
                    }
                }

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

            Item {
                width: parent.width
                height: extensionLoader.active ? extensionLoader.implicitHeight : 0
                visible: extensionLoader.active
                opacity: root.extensionEntered ? 1 : 0

                transform: Translate {
                    y: root.extensionEntered || !RaohaneMotion.transformMotionEnabled ? 0 : 10
                    Behavior on y {
                        NumberAnimation {
                            duration: RaohaneMotion.relaxed
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: RaohaneMotion.easeStandard
                    }
                }

                Loader {
                    id: extensionLoader
                    width: parent.width
                    active: root.extensionSource !== ""
                    source: root.extensionSource

                    onLoaded: {
                        if (item && item.hasOwnProperty("width"))
                            item.width = width
                    }
                }
            }
        }
    }
}
