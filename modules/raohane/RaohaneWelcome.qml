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
    // Use the actual layer-shell logical size (not monitor mode pixels);
    // monitor scale and output changes can make those differ considerably.
    readonly property bool compactLayout: panelWindow.width < 960 || panelWindow.height < 620
    // Optional original PNG mascot. Fall back to the bundled SVG if it is
    // not installed yet, so Welcome remains functional after an update.
    readonly property string mascotUrl: RaohanePaths.fileUrl(
        RaohanePaths.join(RaohanePaths.assetsPath, "images/raohane-welcome-girl.png"))
    readonly property string fallbackMascotUrl: RaohanePaths.fileUrl(
        RaohanePaths.join(RaohanePaths.assetsPath, "images/welcome-mascot.svg"))

    function startTour(): void {
        if (!RaohaneState.welcomeOpen || RaohaneOnboardingState.active)
            return
        console.info("[RaohaneWelcome] Start guided tour")
        RaohaneOnboardingState.start()
    }

    function skipWelcome(): void {
        if (!RaohaneState.welcomeOpen)
            return
        console.info("[RaohaneWelcome] Skip guided tour")
        // Mark completion before the on-demand window is hidden/unloaded.
        RaohaneOnboardingState.skip()
    }

    PanelWindow {
        id: panelWindow

        property bool entered: false

        // The language picker is another full-screen Overlay layer. Do not
        // display a second clickable Welcome beneath it.
        visible: RaohaneState.welcomeOpen
            && RaohaneI18n.languageChosen && !RaohaneI18n.pickerOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        // The first-run language picker owns focus until a language is
        // selected. Welcome must not compete with its exclusive layer.
        WlrLayershell.keyboardFocus: visible
            ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

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
                if (!panelWindow.visible || !RaohaneState.welcomeOpen || RaohaneOnboardingState.active)
                    return
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

                width: Math.max(0, Math.min(parent.width - (root.compactLayout ? 24 : 72), 1120))
                height: Math.max(0, Math.min(parent.height - (root.compactLayout ? 24 : 86), 680))
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
                    anchors.margins: Math.max(15, Math.min(32, welcomeCard.width * 0.033))
                    spacing: Math.max(16, welcomeCard.width * 0.026)

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.maximumWidth: 540
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

                            // Keep the mascot visible even on small laptop displays.
                            Image {
                                visible: root.compactLayout
                                Layout.preferredWidth: visible ? 56 : 0
                                Layout.preferredHeight: visible ? 56 : 0
                                source: root.mascotUrl
                                onStatusChanged: {
                                    if (status === Image.Error && source.toString() !== root.fallbackMascotUrl)
                                        source = root.fallbackMascotUrl
                                }
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                sourceSize: Qt.size(224, 224)
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
                            text: qsTr("A quieter place to create")
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
                            font.pixelSize: Math.max(30, Math.min(51, welcomeCard.width * 0.052))
                            font.weight: Font.DemiBold
                            font.letterSpacing: -1.35
                            wrapMode: Text.WordWrap
                        }

                        Text {
                            Layout.fillWidth: true
                            Layout.maximumWidth: 490
                            Layout.topMargin: 13
                            text: qsTr("Everything you need, beautifully within reach. Take a short tour or make Raohane your own.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 12
                            lineHeight: 1.35
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
                                Layout.preferredWidth: Math.min(190, Math.max(144, welcomeCard.width * 0.19))
                                emphasized: true
                                label: qsTr("Show me around")
                                icon: "arrow_forward"
                                onTriggered: root.startTour()
                            }

                            WelcomeButton {
                                Layout.preferredWidth: Math.min(155, Math.max(116, welcomeCard.width * 0.145))
                                label: qsTr("Explore myself")
                                icon: "explore"
                                onTriggered: root.skipWelcome()
                            }
                        }

                        Text {
                            Layout.topMargin: 12
                            text: qsTr("Enter starts the tour · Esc skips it")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 10
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
                                text: qsTr("Ready when you are")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: qsTr("Made for Hyprland")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                            }
                        }
                    }

                    Rectangle {
                        visible: !root.compactLayout
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 18
                        Layout.bottomMargin: 18
                        color: RaohaneTheme.borderFaint
                    }

                    // Static local artwork, with SVG fallback when the optional PNG
                    // has not been installed. No background refreshes or timers.
                    Item {
                        id: mascotStage
                        visible: !root.compactLayout
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumWidth: 280

                        RaohaneSurface {
                            id: mascotFrame
                            anchors.centerIn: parent
                            width: Math.min(parent.width, 432)
                            height: Math.min(parent.height - 12, 538)
                            surfaceRadius: 22
                            color: RaohaneTheme.surfaceDeep
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            border.color: RaohaneTheme.borderStrong
                            clip: true

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.top
                                anchors.topMargin: 22
                                width: Math.min(parent.width * 0.84, 320)
                                height: width
                                radius: width / 2
                                color: RaohaneTheme.accentSoft
                                border.color: RaohaneTheme.accentBorder
                                border.width: 1
                                opacity: 0.55
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -14
                                width: Math.min(parent.width * 0.72, 285)
                                height: width
                                radius: width / 2
                                color: "transparent"
                                border.width: 1
                                border.color: RaohaneTheme.accent
                                opacity: 0.21
                            }

                            Image {
                                id: mascotImage
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    top: parent.top
                                    bottom: parent.bottom
                                    leftMargin: 14
                                    rightMargin: 14
                                    topMargin: 26
                                    bottomMargin: 72
                                }
                                source: root.mascotUrl
                                onStatusChanged: {
                                    if (status === Image.Error && source.toString() !== root.fallbackMascotUrl)
                                        source = root.fallbackMascotUrl
                                }
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true
                                smooth: true
                                sourceSize.width: 720
                                sourceSize.height: 720
                                opacity: status === Image.Ready ? 1 : 0

                                Behavior on opacity {
                                    enabled: RaohaneMotion.enabled && !RaohanePerformance.gameModeActive
                                    NumberAnimation { duration: RaohaneMotion.enter }
                                }
                            }

                            RaohaneIcon {
                                anchors.centerIn: mascotImage
                                visible: mascotImage.status === Image.Error
                                text: "favorite"
                                iconSize: 60
                                color: RaohaneTheme.accent
                            }

                            RaohaneIcon {
                                anchors {
                                    right: parent.right
                                    top: parent.top
                                    rightMargin: 23
                                    topMargin: 25
                                }
                                text: "auto_awesome"
                                iconSize: 22
                                color: RaohaneTheme.accent
                                opacity: 0.8
                            }

                            ColumnLayout {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                    leftMargin: 22
                                    rightMargin: 22
                                    bottomMargin: 23
                                }
                                spacing: 5

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("Make yourself at home")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 16
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    text: qsTr("Your desktop, your atmosphere")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.startTour()
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
        activeFocusOnTab: true
        hovered: pointer.containsMouse || activeFocus
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

        Accessible.role: Accessible.Button
        Accessible.name: button.label

        MouseArea {
            id: pointer
            z: 150
            anchors.fill: parent
            enabled: button.enabled
            acceptedButtons: Qt.LeftButton
            preventStealing: true
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: button.forceActiveFocus()
            onClicked: {
                console.info("[RaohaneWelcome] Click:", button.label)
                button.triggered()
            }
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                button.triggered()
                event.accepted = true
            }
        }
    }

}
