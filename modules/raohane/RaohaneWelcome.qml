import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property string wallpaperPath: String(RaohaneConfig.wallpaperPath ?? "")
    readonly property bool videoWallpaper: RaohaneWallpapers.isVideo(root.wallpaperPath)

    function skipWelcome(): void {
        RaohaneOnboardingState.complete()
    }

    PanelWindow {
        id: panelWindow

        property bool entered: false

        visible: RaohaneState.welcomeOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            panelWindow.entered = false
            if (!visible)
                return
            Qt.callLater(() => {
                panelWindow.entered = true
                stage.forceActiveFocus()
            })
        }

        Loader {
            anchors.fill: parent
            active: !root.videoWallpaper

            sourceComponent: Image {
                anchors.fill: parent
                source: root.wallpaperPath.length > 0
                    ? RaohanePaths.fileUrl(root.wallpaperPath)
                    : RaohanePaths.defaultWallpaperUrl
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: status === Image.Ready ? 0.32 : 0
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#c9080a14"
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#f0080a14" }
                GradientStop { position: 0.55; color: "#bf0b0d1a" }
                GradientStop { position: 1.0; color: "#df080a14" }
            }
        }

        Rectangle {
            width: Math.min(panelWindow.width * 0.44, 620)
            height: width
            radius: width / 2
            anchors {
                right: parent.right
                top: parent.top
                rightMargin: -Math.round(width * 0.2)
                topMargin: -Math.round(height * 0.28)
            }
            color: RaohaneTheme.accentSoft
            opacity: 0.34
        }

        Item {
            id: stage

            anchors.fill: parent
            focus: panelWindow.visible
            opacity: panelWindow.entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }

            RaohaneSurface {
                id: welcomeCard

                width: Math.min(parent.width - 72, 1120)
                height: Math.min(parent.height - 86, 680)
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true

                Rectangle {
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: 26
                    }
                    width: 58
                    height: 2
                    color: RaohaneTheme.accent
                    opacity: 0.82
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: Math.max(24, Math.min(40, welcomeCard.width * 0.035))
                    spacing: Math.max(28, welcomeCard.width * 0.045)

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: 520
                        spacing: 0

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 38
                                Layout.preferredHeight: 38
                                radius: 12
                                color: RaohaneTheme.accentSoft
                                border.width: 1
                                border.color: RaohaneTheme.accentBorder

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
                                spacing: 0

                                Text {
                                    text: "RAOHANE"
                                    color: RaohaneTheme.text
                                    font.pixelSize: 11
                                    font.weight: Font.DemiBold
                                    font.letterSpacing: 2.6
                                }

                                Text {
                                    text: qsTr("Hyprland · Quickshell")
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                }
                            }

                            Item { Layout.fillWidth: true }

                            StatusChip {
                                icon: "dark_mode"
                                label: RaohaneTheme.presetName
                                active: true
                            }
                        }

                        Item { Layout.fillHeight: true }

                        Text {
                            text: "夜に、ようこそ"
                            color: RaohaneTheme.accent
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            font.letterSpacing: 1.2
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.topMargin: 8
                            text: qsTr("Welcome to Raohane")
                            color: RaohaneTheme.text
                            font.pixelSize: Math.max(37, Math.min(54, welcomeCard.width * 0.052))
                            font.weight: Font.DemiBold
                            font.letterSpacing: -1.35
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 490
                            Layout.topMargin: 13
                            text: qsTr("Your desktop is ready. Learn the surfaces that stay close when you need them — and disappear when you do not.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 13
                            lineHeight: 1.34
                            wrapMode: Text.WordWrap
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 21
                            spacing: 7

                            StatusChip {
                                icon: "route"
                                label: qsTr("%1 guided stops").arg(RaohaneOnboardingState.totalSteps)
                            }
                            StatusChip {
                                icon: "touch_app"
                                label: qsTr("Live interface tour")
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            Layout.topMargin: 25
                            spacing: 9

                            WelcomeButton {
                                Layout.preferredWidth: 188
                                emphasized: true
                                label: qsTr("Show me around")
                                icon: "arrow_forward"
                                onTriggered: RaohaneOnboardingState.start()
                            }

                            WelcomeButton {
                                Layout.preferredWidth: 150
                                label: qsTr("Explore myself")
                                icon: "explore"
                                onTriggered: root.skipWelcome()
                            }
                        }

                        Text {
                            Layout.topMargin: 12
                            text: qsTr("Enter starts the tour · Esc skips it")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }

                        Item { Layout.fillHeight: true }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                width: 5
                                height: 5
                                radius: 3
                                color: RaohaneTheme.success
                            }
                            Text {
                                text: qsTr("Raohane runtime ready")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: qsTr("A live shell, not a mockup")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                            }
                        }
                    }

                    Rectangle {
                        visible: welcomeCard.width >= 820
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 18
                        Layout.bottomMargin: 18
                        color: RaohaneTheme.borderFaint
                    }

                    Item {
                        id: previewStage

                        visible: welcomeCard.width >= 820
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 330

                        RaohaneSurface {
                            id: shellPreview

                            width: Math.min(parent.width, 470)
                            height: Math.min(parent.height - 18, 520)
                            anchors.centerIn: parent
                            surfaceRadius: 22
                            raised: false
                            showSheen: false
                            color: RaohaneTheme.surfaceDeep
                            border.color: RaohaneTheme.border
                            clip: true

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 38
                                    spacing: 7

                                    PreviewPod { icon: "apps"; label: "1   2   3   4" }
                                    Item { Layout.fillWidth: true }
                                    PreviewPod { icon: "spa"; label: qsTr("Raohane") ; active: true }
                                    Item { Layout.fillWidth: true }
                                    PreviewPod { icon: "wifi"; label: Qt.formatTime(new Date(), "HH:mm") }
                                }

                                RaohaneSurface {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 92
                                    surfaceRadius: 16
                                    raised: false
                                    showSheen: false
                                    border.color: RaohaneTheme.borderFaint

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 12
                                        spacing: 10

                                        Rectangle {
                                            Layout.preferredWidth: 42
                                            Layout.preferredHeight: 42
                                            radius: 12
                                            color: RaohaneTheme.accentSoft
                                            border.width: 1
                                            border.color: RaohaneTheme.accentBorder
                                            RaohaneIcon {
                                                anchors.centerIn: parent
                                                text: "search"
                                                iconSize: 20
                                                color: RaohaneTheme.accent
                                            }
                                        }

                                        ColumnLayout {
                                            Layout.fillWidth: true
                                            spacing: 3
                                            Text {
                                                text: qsTr("Launcher")
                                                color: RaohaneTheme.text
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }
                                            Rectangle {
                                                Layout.fillWidth: true
                                                Layout.preferredHeight: 28
                                                radius: 9
                                                color: RaohaneTheme.surfaceSubtle
                                                border.width: 1
                                                border.color: RaohaneTheme.borderFaint
                                                RowLayout {
                                                    anchors.fill: parent
                                                    anchors.leftMargin: 9
                                                    anchors.rightMargin: 9
                                                    RaohaneIcon { text: "search"; iconSize: 12; color: RaohaneTheme.textFaint }
                                                    Text { Layout.fillWidth: true; text: qsTr("Search apps, actions and files"); color: RaohaneTheme.textFaint; font.pixelSize: 7 }
                                                    Text { text: "⌘ K"; color: RaohaneTheme.textFaint; font.pixelSize: 7 }
                                                }
                                            }
                                        }
                                    }
                                }

                                GridLayout {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 142
                                    columns: 2
                                    columnSpacing: 8
                                    rowSpacing: 8

                                    PreviewTile { icon: "wifi"; label: qsTr("Network"); active: true }
                                    PreviewTile { icon: "dark_mode"; label: qsTr("Night Light") }
                                    PreviewTile { icon: "sports_esports"; label: qsTr("Game Mode") }
                                    PreviewTile { icon: "coffee"; label: qsTr("Keep Awake") }
                                }

                                RaohaneSurface {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 72
                                    surfaceRadius: 15
                                    raised: false
                                    showSheen: false
                                    border.color: RaohaneTheme.borderFaint

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6
                                        Text { text: qsTr("System controls"); color: RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: Font.DemiBold }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 5
                                            radius: 3
                                            color: RaohaneTheme.surfaceSubtle
                                            Rectangle { width: parent.width * 0.68; height: parent.height; radius: 3; color: RaohaneTheme.accent }
                                        }
                                        Rectangle {
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 5
                                            radius: 3
                                            color: RaohaneTheme.surfaceSubtle
                                            Rectangle { width: parent.width * 0.46; height: parent.height; radius: 3; color: RaohaneTheme.accent }
                                        }
                                    }
                                }

                                Item { Layout.fillHeight: true }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    Rectangle { width: 5; height: 5; radius: 3; color: RaohaneTheme.success }
                                    Text { text: qsTr("Everything applies live"); color: RaohaneTheme.textFaint; font.pixelSize: 7 }
                                    Item { Layout.fillWidth: true }
                                    Text { text: qsTr("NOCTURNE"); color: RaohaneTheme.accent; font.pixelSize: 7; font.weight: Font.DemiBold; font.letterSpacing: 1.1 }
                                }
                            }
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    RaohaneOnboardingState.start()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    root.skipWelcome()
                    event.accepted = true
                }
            }
        }
    }

    IpcHandler {
        target: "welcome"

        function open(): void { RaohaneState.setPrimaryOpen("welcome", true) }
        function close(): void { root.skipWelcome() }
        function reset(): void { RaohaneOnboardingState.reset() }
        function tour(): void { RaohaneOnboardingState.replay() }
        function status(): string { return RaohaneState.welcomeOpen ? "open" : "closed" }
        function completed(): bool { return RaohaneOnboardingState.completed }
    }

    component StatusChip: Rectangle {
        id: chip
        required property string icon
        required property string label
        property bool active: false

        Layout.preferredWidth: Math.max(104, chipRow.implicitWidth + 18)
        Layout.preferredHeight: 27
        radius: 10
        color: active ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        Row {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6
            RaohaneIcon { text: chip.icon; iconSize: 12; color: chip.active ? RaohaneTheme.accent : RaohaneTheme.textMuted }
            Text { text: chip.label; color: chip.active ? RaohaneTheme.text : RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: Font.Medium }
        }
    }

    component WelcomeButton: RaohaneSurface {
        id: button

        required property string label
        required property string icon
        property bool emphasized: false
        signal triggered()

        Layout.preferredHeight: 43
        surfaceRadius: 12
        raised: false
        active: emphasized
        transparentIdle: !emphasized
        interactive: true
        hovered: pointer.containsMouse
        pressed: pointer.pressed
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        border.color: emphasized ? RaohaneTheme.accentBorder
            : pointer.containsMouse ? RaohaneTheme.borderStrong
            : RaohaneTheme.borderFaint

        Row {
            anchors.centerIn: parent
            spacing: 8
            Text { text: button.label; color: button.emphasized ? RaohaneTheme.text : RaohaneTheme.textMuted; font.pixelSize: 10; font.weight: Font.DemiBold }
            RaohaneIcon { text: button.icon; iconSize: 14; fill: button.emphasized ? 1 : 0; color: button.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }

    component PreviewPod: RaohaneSurface {
        id: pod
        required property string icon
        required property string label
        property bool active: false
        implicitWidth: podRow.implicitWidth + 18
        implicitHeight: 28
        surfaceRadius: 10
        raised: false
        showSheen: false
        border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        Row {
            id: podRow
            anchors.centerIn: parent
            spacing: 6
            RaohaneIcon { text: pod.icon; iconSize: 11; color: pod.active ? RaohaneTheme.accent : RaohaneTheme.textMuted }
            Text { text: pod.label; color: pod.active ? RaohaneTheme.text : RaohaneTheme.textMuted; font.pixelSize: 7; font.weight: Font.Medium }
        }
    }

    component PreviewTile: RaohaneSurface {
        id: tile
        required property string icon
        required property string label
        property bool active: false
        Layout.fillWidth: true
        Layout.fillHeight: true
        surfaceRadius: 13
        raised: false
        showSheen: false
        border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 8
            Rectangle {
                Layout.preferredWidth: 27
                Layout.preferredHeight: 27
                radius: 9
                color: tile.active ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle
                RaohaneIcon { anchors.centerIn: parent; text: tile.icon; iconSize: 13; color: tile.active ? RaohaneTheme.accent : RaohaneTheme.textMuted }
            }
            Text { Layout.fillWidth: true; text: tile.label; color: tile.active ? RaohaneTheme.text : RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: Font.Medium; elide: Text.ElideRight }
        }
    }
}
