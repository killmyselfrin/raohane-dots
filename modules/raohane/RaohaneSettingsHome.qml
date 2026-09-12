pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.modules.raohane.config
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
    readonly property string sceneStatus: RaohaneScenes.autoSceneActive
        ? qsTr("Scene · %1 · auto").arg(root.sceneName)
        : qsTr("Scene · %1").arg(root.sceneName)
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
                        : qsTr("Updates ready")
    readonly property string updateIcon: RaohaneUpdater.applying
        ? "system_update_alt"
        : RaohaneUpdater.checking
            ? "sync"
            : RaohaneUpdater.errorText.length > 0
                ? "error"
                : RaohaneUpdater.updateAvailable ? "new_releases" : "verified"

    function openPage(page: string): void {
        RaohaneSettingsRouter.request(page, "")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: RaohaneTheme.spacing

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 166
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            clip: true
            showSheen: false
            showInnerRim: false
            idleBorderColor: RaohaneTheme.borderStrong

            Loader {
                anchors.fill: parent
                active: !RaohaneWallpapers.isVideo(RaohaneConfig.wallpaperPath)

                sourceComponent: Image {
                    anchors.fill: parent
                    visible: !RaohaneWallpapers.isVideo(RaohaneConfig.wallpaperPath)
                    source: visible ? RaohaneConfig.wallpaperPath : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    opacity: status === Image.Ready ? (RaohaneTheme.dark ? 0.24 : 0.18) : 0
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(RaohaneTheme.background.r, RaohaneTheme.background.g, RaohaneTheme.background.b,
                            RaohaneTheme.dark ? 0.95 : 0.97)
                    }
                    GradientStop {
                        position: 0.64
                        color: Qt.rgba(RaohaneTheme.background.r, RaohaneTheme.background.g, RaohaneTheme.background.b,
                            RaohaneTheme.dark ? 0.86 : 0.91)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(RaohaneTheme.background.r, RaohaneTheme.background.g, RaohaneTheme.background.b,
                            RaohaneTheme.dark ? 0.66 : 0.74)
                    }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: RaohaneTheme.panelPadding
                spacing: RaohaneTheme.panelPadding

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: RaohaneTheme.spacingSmall

                    RowLayout {
                        spacing: RaohaneTheme.spacing

                        RaohaneSurface {
                            Layout.preferredWidth: 40
                            Layout.preferredHeight: 40
                            surfaceRadius: RaohaneTheme.radiusLarge
                            active: true
                            raised: false
                            showSheen: false
                            showInnerRim: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "spa"
                                iconSize: 20
                                fill: 1
                                symbolWeight: 560
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: 1

                            Text {
                                text: qsTr("Raohane")
                                color: RaohaneTheme.text
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: qsTr("A minimal Hyprland shell, shaped live")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 10
                            }
                        }
                    }

                    RowLayout {
                        Layout.topMargin: RaohaneTheme.spacingSmall
                        spacing: RaohaneTheme.spacingSmall

                        StatusChip {
                            icon: RaohaneNetwork.materialSymbol
                            text: RaohaneNetwork.networkName || qsTr("Offline")
                            active: RaohaneNetwork.wifiStatus !== "disabled"
                        }

                        StatusChip {
                            icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                            text: qsTr("%1% volume").arg(Math.round(RaohaneAudio.volume * 100))
                            active: RaohaneAudio.ready && !RaohaneAudio.muted
                        }

                        StatusChip {
                            icon: RaohanePrivacy.recordingActive ? "screen_record"
                                : RaohanePrivacy.cameraActive ? "videocam"
                                : RaohanePrivacy.microphoneActive ? "mic" : "shield"
                            text: RaohanePrivacy.recordingActive ? qsTr("Screen capture")
                                : RaohanePrivacy.cameraActive ? qsTr("Camera active")
                                : RaohanePrivacy.microphoneActive ? qsTr("Microphone active")
                                : qsTr("Privacy clear")
                            active: RaohanePrivacy.recordingActive || RaohanePrivacy.cameraActive || RaohanePrivacy.microphoneActive
                            critical: active
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 118
                    color: RaohaneTheme.borderFaint
                }

                ColumnLayout {
                    Layout.preferredWidth: 218
                    Layout.alignment: Qt.AlignVCenter
                    spacing: RaohaneTheme.spacingSmall

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: RaohaneTheme.spacingSmall

                        MoodChip { label: RaohaneTheme.presetName; active: true }
                        MoodChip { label: RaohaneTheme.dark ? qsTr("Dark") : qsTr("Light") }
                    }

                    StatusChip {
                        Layout.fillWidth: true
                        maxChipWidth: 218
                        icon: RaohaneScenes.activeSceneId === "gaming" ? "sports_esports"
                            : RaohaneScenes.activeSceneId === "focus" ? "center_focus_strong"
                            : RaohaneScenes.activeSceneId === "work" ? "work" : "tune"
                        text: root.sceneStatus
                        active: RaohaneScenes.activeSceneId !== "balanced" || RaohaneScenes.autoSceneActive
                        page: "Scenes"
                    }

                    StatusChip {
                        Layout.fillWidth: true
                        maxChipWidth: 218
                        icon: root.updateIcon
                        text: root.updateStatus
                        active: RaohaneUpdater.updateAvailable || RaohaneUpdater.checking || RaohaneUpdater.applying
                        critical: RaohaneUpdater.errorText.length > 0
                        page: "About"
                    }

                    PathChip {
                        Layout.fillWidth: true
                        label: qsTr("Open native.json")
                        path: RaohanePaths.nativeConfigFile
                        icon: "tune"
                    }
                }
            }
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 68
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            idleBorderColor: RaohaneTheme.border

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: RaohaneTheme.spacing + 2
                anchors.rightMargin: RaohaneTheme.spacing
                spacing: RaohaneTheme.spacing + 1

                ColumnLayout {
                    Layout.preferredWidth: root.width < 760 ? 126 : 158
                    spacing: 2

                    Text {
                        text: qsTr("Style profile")
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Start broad, tune details later")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.preferredHeight: 40
                    color: RaohaneTheme.borderFaint
                }

                RaohaneStyleProfiles {
                    Layout.fillWidth: true
                    compact: root.width < 760
                    showDescription: root.width >= 900
                }

                RaohaneIconButton {
                    buttonSize: 32
                    iconSize: 15
                    icon: "tune"
                    transparentIdle: true
                    showSheen: false
                    hoverScale: 1
                    pressedScale: 1
                    onClicked: root.openPage("Themes")
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: RaohaneTheme.spacing

            ColumnLayout {
                spacing: 2

                Text {
                    text: qsTr("Control deck")
                    color: RaohaneTheme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("Open a subsystem directly; every change applies live")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                }
            }

            Item { Layout.fillWidth: true }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.width >= 760 ? 3 : 2
            columnSpacing: RaohaneTheme.spacingSmall + 1
            rowSpacing: RaohaneTheme.spacingSmall + 1

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "palette"
                title: qsTr("Themes")
                detail: qsTr("Theme Library, accent color and Style Studio")
                page: "Themes"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "widgets"
                title: qsTr("Desktop Widgets")
                detail: qsTr("Clock, context, system status and desktop composition")
                page: "Desktop Widgets"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "wand_stars"
                title: qsTr("Appearance")
                detail: qsTr("Screen framing, rounding and interaction chrome")
                page: "Appearance"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "dock_to_bottom"
                title: qsTr("Bar & Dock")
                detail: qsTr("Floating bar, Context Island and application dock")
                page: "Bar & Dock"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "instant_mix"
                title: qsTr("Quick Controls")
                detail: qsTr("Choose the controls shown in the command surface")
                page: "Quick Controls"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "music_note"
                title: qsTr("Media & OSD")
                detail: qsTr("Media overlay, Island behavior and system feedback")
                page: "Media & OSD"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "view_quilt"
                title: qsTr("Desktop & Spaces")
                detail: qsTr("Wallpaper, transitions and workspace overview")
                page: "Desktop & Spaces"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "monitor"
                title: qsTr("Displays")
                detail: qsTr("Resolution, refresh rate, scale, rotation and VRR")
                page: "Displays"
            }

            DeckCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                icon: "keyboard"
                title: qsTr("Keyboard & Motion")
                detail: qsTr("Keybinds, input behavior and animation preferences")
                page: "Keyboard & Motion"
            }
        }
    }

    component PathChip: RaohaneSurface {
        id: pathChip

        required property string label
        required property string path
        required property string icon

        implicitHeight: 31
        surfaceRadius: RaohaneTheme.radius
        transparentIdle: true
        showSheen: false
        showInnerRim: false
        hovered: pathMouse.containsMouse
        pressed: pathMouse.pressed
        interactive: true
        hoverScale: 1
        pressedScale: 1
        idleBorderColor: RaohaneTheme.borderFaint
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacingSmall + 2
            anchors.rightMargin: RaohaneTheme.spacingSmall + 2
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon {
                text: pathChip.icon
                iconSize: 14
                color: pathChip.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                Layout.fillWidth: true
                text: pathChip.label
                color: pathChip.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            RaohaneIcon {
                text: "arrow_outward"
                iconSize: 12
                color: RaohaneTheme.textFaint
            }
        }

        MouseArea {
            id: pathMouse
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onPressed: pathChip.forceActiveFocus()
            onClicked: mouse => {
                if (mouse.button === Qt.RightButton)
                    Quickshell.clipboardText = pathChip.path
                else
                    Qt.openUrlExternally("file://" + pathChip.path)
            }
        }
    }

    component DeckCard: RaohaneSurface {
        id: card

        required property string icon
        required property string title
        required property string detail
        required property string page

        Layout.minimumHeight: 70
        surfaceRadius: RaohaneTheme.radiusLarge
        hovered: cardMouse.containsMouse || activeFocus
        pressed: cardMouse.pressed
        interactive: true
        raised: false
        showSheen: false
        showInnerRim: false
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        idleBorderColor: RaohaneTheme.borderFaint
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong
        showStateRail: card.hovered
        stateRailWidth: 2
        stateRailLength: 24
        stateRailOpacity: 0.72

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacing + 2
            anchors.rightMargin: RaohaneTheme.spacing + 1
            spacing: RaohaneTheme.spacing

            RaohaneSurface {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                surfaceRadius: RaohaneTheme.radius
                active: card.hovered
                raised: false
                showSheen: false
                showInnerRim: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: card.icon
                    iconSize: 17
                    fill: card.hovered ? 0.45 : 0
                    symbolWeight: card.hovered ? 520 : 430
                    color: card.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: card.title
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: card.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }

            RaohaneIcon {
                text: "chevron_right"
                iconSize: 15
                color: card.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: card.forceActiveFocus()
            onClicked: root.openPage(card.page)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.openPage(card.page)
                event.accepted = true
            }
        }
    }

    component StatusChip: RaohaneSurface {
        id: chip

        required property string icon
        required property string text
        property bool critical: false
        property string page: ""
        property int maxChipWidth: 170

        Layout.preferredWidth: Math.min(maxChipWidth, chipRow.implicitWidth + 20)
        Layout.preferredHeight: 29
        surfaceRadius: RaohaneTheme.radius
        raised: false
        showSheen: false
        showInnerRim: false
        hovered: chip.page.length > 0 && chipMouse.containsMouse
        pressed: chip.page.length > 0 && chipMouse.pressed
        interactive: chip.page.length > 0
        hoverScale: 1
        pressedScale: 1
        idleColor: RaohaneTheme.surfaceSubtle
        activeColor: chip.critical
            ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.12)
            : RaohaneTheme.accentSoft
        idleBorderColor: RaohaneTheme.borderFaint
        hoverBorderColor: chip.critical ? RaohaneTheme.critical : RaohaneTheme.borderStrong
        pressedBorderColor: chip.critical ? RaohaneTheme.critical : RaohaneTheme.borderStrong
        activeBorderColor: chip.critical
            ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.62)
            : RaohaneTheme.borderStrong

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon {
                text: chip.icon
                iconSize: 13
                color: chip.critical ? RaohaneTheme.critical : chip.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                width: Math.min(chip.maxChipWidth - 42, implicitWidth)
                text: chip.text
                color: RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            RaohaneIcon {
                visible: chip.page.length > 0
                text: "chevron_right"
                iconSize: 11
                color: chip.hovered ? RaohaneTheme.accent : RaohaneTheme.textFaint
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            enabled: chip.page.length > 0
            hoverEnabled: enabled
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: root.openPage(chip.page)
        }
    }

    component MoodChip: RaohaneSurface {
        id: mood

        required property string label

        Layout.preferredWidth: labelText.implicitWidth + 20
        Layout.preferredHeight: 27
        surfaceRadius: RaohaneTheme.radius
        raised: false
        showSheen: false
        showInnerRim: false
        idleColor: RaohaneTheme.surfaceSubtle
        activeColor: RaohaneTheme.accentSoft
        idleBorderColor: RaohaneTheme.borderFaint
        activeBorderColor: RaohaneTheme.accentBorder

        Text {
            id: labelText
            anchors.centerIn: parent
            text: mood.label
            color: mood.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: Font.Medium
        }
    }
}
