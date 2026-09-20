pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    property string sectionKey: "general"
    property bool settingsEntered: false
    property bool extensionEntered: false

    readonly property var pageInfo: RaohaneSettingsPageRegistry.page(root.sectionKey)
    readonly property var entries: RaohaneSettingsPageRegistry.sectionEntries(root.sectionKey)
    readonly property string extensionSource: RaohaneSettingsSectionRegistry.source(root.sectionKey)
    readonly property bool compactLayout: width < 700

    function entryHeight(entry): int {
        return entry?.type === "text" ? 74 : 62
    }

    function entryOffset(index: int): real {
        let offset = 0
        for (let i = 0; i < index && i < root.entries.length; ++i)
            offset += root.entryHeight(root.entries[i])
        return offset
    }

    function replayEntrance(): void {
        settingsEntered = false
        extensionEntered = false
        settingsTimer.restart()
        extensionTimer.restart()
    }

    function goTo(search: string): void {
        const needle = String(search ?? "").trim()
        if (needle === "")
            return
        if (RaohaneSettingsSectionRegistry.ownsControl(root.sectionKey, needle)) {
            settingsFlick.contentY = Math.max(0, extensionLoader.y - RaohaneTheme.spacingLarge)
            return
        }
        const normalized = needle.toLowerCase()
        const index = root.entries.findIndex(entry => String(entry.label).toLowerCase().includes(normalized) || entry.key.toLowerCase().includes(normalized))
        if (index >= 0)
            settingsFlick.contentY = Math.max(0, root.entryOffset(index) - RaohaneTheme.spacingLarge)
    }

    onSectionKeyChanged: Qt.callLater(root.replayEntrance)
    Component.onCompleted: root.replayEntrance()


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
        contentHeight: sectionColumn.implicitHeight + RaohaneTheme.panelPadding * 3
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            width: 4
            anchors.right: parent.right
            anchors.rightMargin: RaohaneTheme.spacingTiny
            contentItem: Rectangle {
                implicitWidth: 4
                radius: 2
                color: RaohaneTheme.accent
                opacity: 0.38
            }
        }

        Column {
            id: sectionColumn
            y: RaohaneTheme.spacing
            width: Math.min(
                Math.max(0, settingsFlick.width - (root.compactLayout ? RaohaneTheme.panelPadding * 2 : 52)),
                root.compactLayout ? 680 : 820
            )
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: RaohaneTheme.spacing


            RaohaneSurface {
                id: settingsSurface
                width: parent.width
                height: settingsList.implicitHeight
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                idleColor: RaohaneTheme.surfaceDeep
                border.color: "transparent"
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
