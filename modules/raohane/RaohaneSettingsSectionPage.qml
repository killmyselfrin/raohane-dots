pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
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
    readonly property bool compactLayout: width < 700

    function entryHeight(entry): int {
        return entry?.type === "text" ? 80 : 68
    }

    function entryOffset(index: int): real {
        let offset = 0
        for (let i = 0; i < index && i < root.entries.length; ++i)
            offset += root.entryHeight(root.entries[i])
        return offset
    }

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
            y: RaohaneTheme.spacingLarge
            width: Math.min(
                Math.max(0, settingsFlick.width - (root.compactLayout ? RaohaneTheme.panelPadding * 2 : 52)),
                root.compactLayout ? 680 : 820
            )
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: RaohaneTheme.spacingLarge

            RaohaneSurface {
                id: sectionHero
                width: parent.width
                height: root.compactLayout ? 98 : 110
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
                    width: 158
                    height: 158
                    radius: 79
                    anchors {
                        right: parent.right
                        top: parent.top
                        rightMargin: -46
                        topMargin: -74
                    }
                    color: RaohaneTheme.accentSoft
                    opacity: root.headerEntered ? 0.34 : 0.12

                    Behavior on opacity {
                        NumberAnimation { duration: RaohaneMotion.relaxed }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
                    anchors.rightMargin: RaohaneTheme.panelPadding + RaohaneTheme.spacingSmall
                    spacing: RaohaneTheme.spacingLarge

                    RaohaneSurface {
                        Layout.preferredWidth: root.compactLayout ? 44 : 50
                        Layout.preferredHeight: root.compactLayout ? 44 : 50
                        surfaceRadius: RaohaneTheme.radiusSmall
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.pageInfo?.icon ?? "tune"
                            iconSize: root.compactLayout ? 21 : 24
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingTiny

                        Text {
                            text: root.pageInfo?.name ?? qsTr("Settings")
                            color: RaohaneTheme.text
                            font.pixelSize: root.compactLayout ? 15 : 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneSettingsPageRegistry.sectionDescription(root.sectionKey)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                            lineHeight: 1.22
                            maximumLineCount: root.compactLayout ? 2 : 3
                            elide: Text.ElideRight
                            wrapMode: Text.WordWrap
                        }
                    }

                    RaohaneSurface {
                        visible: !root.compactLayout
                        Layout.preferredWidth: settingCount.implicitWidth + RaohaneTheme.panelPadding * 2
                        Layout.preferredHeight: 30
                        surfaceRadius: RaohaneTheme.radiusSmall
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
