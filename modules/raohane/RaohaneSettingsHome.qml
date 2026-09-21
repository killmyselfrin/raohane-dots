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

    readonly property var commonSettings: [
        {
            type: "toggle",
            key: "contextIslandEnabled",
            label: qsTr("Context Island"),
            detail: qsTr("Show live media, privacy and active-window context")
        },
        {
            type: "toggle",
            key: "dockAutoHide",
            label: qsTr("Auto-hide dock"),
            detail: qsTr("Hide the dock when it is not in use")
        },
        {
            type: "toggle",
            key: "nightLightAutomatic",
            label: qsTr("Automatic night light"),
            detail: qsTr("Allow Raohane display service to automate color temperature")
        },
        {
            type: "toggle",
            key: "mediaOverlayEnabled",
            label: qsTr("Media overlay"),
            detail: qsTr("Enable Raohane media overlay surfaces")
        },
        {
            type: "toggle",
            key: "wallpaperHideWhenFullscreen",
            label: qsTr("Hide wallpaper on fullscreen"),
            detail: qsTr("Reduce background rendering behind fullscreen clients")
        }
    ]

    function openPage(page): void {
        RaohaneSettingsRouter.request(String(page ?? ""), "")
    }

    Component.onCompleted: {
        if (RaohaneSystemInfo.kernelVersion === "")
            RaohaneSystemInfo.refresh()
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

            SectionTitle {
                title: qsTr("Common settings")
                subtitle: qsTr("Frequently used controls without repeating the navigation sidebar.")
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: quickRows.implicitHeight
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                idleBorderColor: "transparent"
                clip: true

                Column {
                    id: quickRows
                    width: parent.width
                    spacing: 0

                    Repeater {
                        model: root.commonSettings

                        delegate: RaohaneSettingsControlRow {
                            required property var modelData
                            required property int index

                            width: quickRows.width
                            height: 62
                            entry: modelData
                            lastRow: index >= root.commonSettings.length - 1
                        }
                    }
                }
            }

            SectionTitle {
                title: qsTr("System summary")
                subtitle: qsTr("A quick read-only snapshot of this machine.")
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: systemRows.implicitHeight
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                idleBorderColor: "transparent"
                clip: true

                ColumnLayout {
                    id: systemRows
                    width: parent.width
                    spacing: 0

                    InfoRow {
                        icon: "computer"
                        title: qsTr("Distribution")
                        detail: RaohaneSystemInfo.distroName
                    }

                    RaohaneDivider {
                        Layout.fillWidth: true
                        Layout.leftMargin: RaohaneTheme.panelPadding
                        Layout.rightMargin: RaohaneTheme.panelPadding
                        color: RaohaneTheme.borderFaint
                    }

                    InfoRow {
                        icon: "terminal"
                        title: qsTr("Kernel")
                        detail: RaohaneSystemInfo.kernelVersion
                    }

                    RaohaneDivider {
                        Layout.fillWidth: true
                        Layout.leftMargin: RaohaneTheme.panelPadding
                        Layout.rightMargin: RaohaneTheme.panelPadding
                        color: RaohaneTheme.borderFaint
                    }

                    InfoRow {
                        icon: "developer_board"
                        title: qsTr("GPU")
                        detail: RaohaneSystemInfo.gpu
                    }

                    RaohaneDivider {
                        Layout.fillWidth: true
                        Layout.leftMargin: RaohaneTheme.panelPadding
                        Layout.rightMargin: RaohaneTheme.panelPadding
                        color: RaohaneTheme.borderFaint
                    }

                    OverviewRow {
                        icon: "info"
                        title: qsTr("System information")
                        detail: qsTr("Diagnostics, runtime and hardware details")
                        onTriggered: root.openPage("about")
                    }
                }
            }
        }
    }

    component SectionTitle: ColumnLayout {
        id: sectionTitle

        required property string title
        property string subtitle: ""

        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: sectionTitle.title
            color: RaohaneTheme.text
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        Text {
            visible: sectionTitle.subtitle.length > 0
            Layout.fillWidth: true
            text: sectionTitle.subtitle
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
                Layout.preferredWidth: Math.min(320, implicitWidth)
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

    component InfoRow: Item {
        id: row

        required property string icon
        required property string title
        required property string detail

        Layout.fillWidth: true
        Layout.preferredHeight: 54

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding
            anchors.rightMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacing + 2

            RaohaneIcon {
                text: row.icon
                iconSize: 17
                color: RaohaneTheme.textMuted
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
                Layout.preferredWidth: Math.min(430, implicitWidth)
                text: row.detail.length > 0 ? row.detail : qsTr("Loading…")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }
}
