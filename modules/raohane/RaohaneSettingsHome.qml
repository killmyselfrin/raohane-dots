pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    readonly property string sceneName: {
        switch (RaohaneScenes.activeSceneId) {
        case "gaming": return qsTr("Gaming")
        case "focus": return qsTr("Focus")
        case "work": return qsTr("Work")
        default: return qsTr("Balanced")
        }
    }

    readonly property string sceneDetail: RaohaneScenes.autoSceneActive
        ? qsTr("%1 · Automatic").arg(root.sceneName)
        : root.sceneName

    readonly property string updateStatus: RaohaneUpdater.applying
        ? qsTr("Installing update")
        : RaohaneUpdater.checking
            ? qsTr("Checking updates")
            : RaohaneUpdater.errorText.length > 0
                ? qsTr("Update needs attention")
                : RaohaneUpdater.updateAvailable
                    ? qsTr("Update available")
                    : RaohaneUpdater.lastCheckedText.length > 0
                        ? qsTr("Up to date · %1").arg(RaohaneUpdater.lastCheckedText)
                        : qsTr("Up to date")

    readonly property var personalizePages: root.resolvePages(["themes", "widgets", "interface"])
    readonly property var shellPages: root.resolvePages(["bar", "quick", "scenes", "general", "desktop"])
    readonly property var systemPages: root.resolvePages([
        "displays", "graphics", "hyprland", "preferences", "services", "profile",
        "backup", "language", "about"
    ])

    function resolvePages(keys): var {
        const result = []
        for (const key of keys) {
            const page = RaohaneSettingsPageRegistry.page(key)
            if (page)
                result.push(page)
        }
        return result
    }

    function openPage(page): void {
        RaohaneSettingsRouter.request(String(page ?? ""), "")
    }

    Flickable {
        id: flick
        anchors.fill: parent
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        contentWidth: width
        contentHeight: homeColumn.implicitHeight + RaohaneTheme.spacingLarge * 2

        Controls.ScrollBar.vertical: Controls.ScrollBar {
            policy: flick.contentHeight > flick.height
                ? Controls.ScrollBar.AsNeeded
                : Controls.ScrollBar.AlwaysOff
        }

        ColumnLayout {
            id: homeColumn

            width: Math.min(flick.width - RaohaneTheme.spacingLarge * 2, 900)
            x: Math.max(RaohaneTheme.spacingLarge, (flick.width - width) / 2)
            y: RaohaneTheme.spacingLarge
            spacing: RaohaneTheme.spacingLarge

            SectionTitle {
                title: qsTr("Current setup")
                subtitle: qsTr("The settings that most often change during a session.")
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: setupRows.implicitHeight
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                idleBorderColor: "transparent"
                clip: true

                ColumnLayout {
                    id: setupRows
                    width: parent.width
                    spacing: 0

                    OverviewRow {
                        icon: "palette"
                        title: qsTr("Theme")
                        detail: RaohaneTheme.presetName
                        onTriggered: root.openPage("themes")
                    }

                    RaohaneDivider {
                        Layout.fillWidth: true
                        Layout.leftMargin: RaohaneTheme.panelPadding
                        Layout.rightMargin: RaohaneTheme.panelPadding
                        color: RaohaneTheme.borderFaint
                    }

                    OverviewRow {
                        icon: RaohaneScenes.activeSceneId === "gaming" ? "sports_esports"
                            : RaohaneScenes.activeSceneId === "focus" ? "center_focus_strong"
                            : RaohaneScenes.activeSceneId === "work" ? "work" : "tune"
                        title: qsTr("Scene")
                        detail: root.sceneDetail
                        onTriggered: root.openPage("scenes")
                    }

                    RaohaneDivider {
                        Layout.fillWidth: true
                        Layout.leftMargin: RaohaneTheme.panelPadding
                        Layout.rightMargin: RaohaneTheme.panelPadding
                        color: RaohaneTheme.borderFaint
                    }

                    OverviewRow {
                        icon: RaohaneUpdater.errorText.length > 0 ? "error"
                            : RaohaneUpdater.updateAvailable ? "new_releases"
                            : RaohaneUpdater.checking || RaohaneUpdater.applying ? "sync"
                            : "verified"
                        title: qsTr("Software updates")
                        detail: root.updateStatus
                        accent: RaohaneUpdater.updateAvailable || RaohaneUpdater.checking || RaohaneUpdater.applying
                        critical: RaohaneUpdater.errorText.length > 0
                        onTriggered: root.openPage("about")
                    }
                }
            }

            CategorySection {
                title: qsTr("Personalize")
                subtitle: qsTr("Theme, desktop composition and visual appearance.")
                pages: root.personalizePages
            }

            CategorySection {
                title: qsTr("Shell")
                subtitle: qsTr("Bar, quick controls, scenes and desktop behavior.")
                pages: root.shellPages
            }

            CategorySection {
                title: qsTr("System")
                subtitle: qsTr("Displays, input, integrations and Raohane maintenance.")
                pages: root.systemPages
            }
        }
    }

    component SectionTitle: ColumnLayout {
        required property string title
        property string subtitle: ""

        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: parent.title
            color: RaohaneTheme.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            visible: parent.subtitle.length > 0
            Layout.fillWidth: true
            text: parent.subtitle
            color: RaohaneTheme.textMuted
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }
    }

    component OverviewRow: Item {
        id: row

        required property string icon
        required property string title
        required property string detail
        property bool accent: false
        property bool critical: false
        signal triggered()

        Layout.fillWidth: true
        Layout.preferredHeight: 58

        Rectangle {
            anchors.fill: parent
            color: rowHover.hovered ? RaohaneTheme.surfaceHover : "transparent"

            Behavior on color {
                ColorAnimation { duration: RaohaneMotion.micro }
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding
            anchors.rightMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacing + 2

            RaohaneIcon {
                text: row.icon
                iconSize: 18
                fill: row.accent ? 0.7 : 0
                color: row.critical ? RaohaneTheme.critical
                    : row.accent ? RaohaneTheme.accent
                    : RaohaneTheme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: row.title
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.preferredWidth: Math.min(280, implicitWidth)
                text: row.detail
                color: row.critical ? RaohaneTheme.critical
                    : row.accent ? RaohaneTheme.accent
                    : RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.Medium
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }

            RaohaneIcon {
                text: "chevron_right"
                iconSize: 14
                color: rowHover.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
            }
        }

        HoverHandler {
            id: rowHover
        }

        TapHandler {
            onTapped: row.triggered()
        }
    }

    component CategorySection: ColumnLayout {
        id: section

        required property string title
        required property string subtitle
        required property var pages

        Layout.fillWidth: true
        spacing: RaohaneTheme.spacingSmall

        SectionTitle {
            Layout.fillWidth: true
            title: section.title
            subtitle: section.subtitle
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: categoryRows.implicitHeight
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            idleBorderColor: "transparent"
            clip: true

            ColumnLayout {
                id: categoryRows
                width: parent.width
                spacing: 0

                Repeater {
                    model: section.pages

                    delegate: Item {
                        id: categoryRow

                        required property var modelData
                        required property int index

                        Layout.fillWidth: true
                        Layout.preferredHeight: 62

                        Rectangle {
                            anchors.fill: parent
                            color: categoryHover.hovered ? RaohaneTheme.surfaceHover : "transparent"

                            Behavior on color {
                                ColorAnimation { duration: RaohaneMotion.micro }
                            }
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: RaohaneTheme.panelPadding
                            anchors.rightMargin: RaohaneTheme.panelPadding
                            spacing: RaohaneTheme.spacing + 2

                            RaohaneIcon {
                                text: String(categoryRow.modelData?.icon ?? "tune")
                                iconSize: 18
                                color: categoryHover.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: String(categoryRow.modelData?.name ?? "")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: String(categoryRow.modelData?.subtitle ?? "")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    elide: Text.ElideRight
                                }
                            }

                            RaohaneIcon {
                                text: "chevron_right"
                                iconSize: 14
                                color: categoryHover.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
                            }
                        }

                        RaohaneDivider {
                            visible: categoryRow.index < section.pages.length - 1
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                leftMargin: RaohaneTheme.panelPadding
                                rightMargin: RaohaneTheme.panelPadding
                            }
                            color: RaohaneTheme.borderFaint
                        }

                        HoverHandler {
                            id: categoryHover
                        }

                        TapHandler {
                            onTapped: root.openPage(categoryRow.modelData?.key ?? "")
                        }
                    }
                }
            }
        }
    }
}
