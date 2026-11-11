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
    // A bundled original mark: no optional asset probe or remote artwork.
    readonly property string logoUrl: RaohanePaths.fileUrl(
        RaohanePaths.join(RaohanePaths.assetsPath, "icons/raohane-emblem.png"))

    function finishIntro(): void {
        introAnimation.stop()
        panelWindow.introActive = false
        panelWindow.entered = panelWindow.visible
        if (panelWindow.visible) stage.forceActiveFocus()
    }

    property int setupStep: 0
    readonly property var stepNames: [qsTr("Welcome"), qsTr("Appearance"), qsTr("Wallpaper"), qsTr("Bar"), qsTr("Ready when you are")]

    function advance(): void {
        if (panelWindow.introActive) { root.finishIntro(); return }
        if (setupStep < 4) { setupStep++; stage.forceActiveFocus() }
    }
    function previous(): void {
        if (panelWindow.introActive) root.finishIntro()
        else if (setupStep > 0) setupStep--
    }
    function startTour(): void {
        if (setupStep !== 4) return
        RaohaneConfig.saveNow()
        RaohaneOnboardingState.markCompleted()
        RaohaneOnboardingState.start()
    }
    function skipWelcome(): void {
        // Completion is explicit and available only after all setup pages.
        if (setupStep !== 4 || panelWindow.introActive) return
        RaohaneConfig.saveNow()
        RaohaneOnboardingState.skip()
    }

    PanelWindow {
        id: panelWindow

        property bool entered: false
        property bool introActive: false
        property real introLogo: 0
        property real introName: 0
        property real curtainOpacity: 1


        // The language picker is another full-screen Overlay layer. Do not
        // display a second clickable Welcome beneath it.
        visible: RaohaneState.welcomeOpen
            && RaohaneI18n.languageChosen && !RaohaneI18n.pickerOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
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
            introAnimation.stop()
            panelWindow.introActive = false
            if (!visible)
                return
            Qt.callLater(() => {
                if (!panelWindow.visible || !RaohaneState.welcomeOpen || RaohaneOnboardingState.active)
                    return
                if (!RaohaneMotion.enabled || !RaohaneMotion.transformMotionEnabled || RaohanePerformance.gameModeActive) {
                    root.finishIntro()
                    return
                }
                panelWindow.introLogo = 0
                panelWindow.introName = 0
                panelWindow.curtainOpacity = 1
                panelWindow.introActive = true
                introFocus.forceActiveFocus()
                introAnimation.restart()
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
            color: RaohaneTheme.background
            opacity: 0.88
        }

        // Finite fullscreen introduction. No shader, frame timer or loading gate.
        FocusScope {
            id: introFocus
            anchors.fill: parent
            z: 200
            visible: panelWindow.introActive
            opacity: panelWindow.curtainOpacity
            Rectangle { anchors.fill: parent; color: RaohaneTheme.background }
            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width * 0.68, 600) * (0.65 + panelWindow.introLogo * 0.35)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: RaohaneTheme.accentBorder
                opacity: panelWindow.introLogo * 0.45
            }
            Column {
                anchors.centerIn: parent
                spacing: 24
                Image {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: root.compactLayout ? 110 : 160
                    height: width
                    source: root.logoUrl
                    sourceSize: Qt.size(320, 320)
                    opacity: panelWindow.introLogo
                    scale: 0.72 + panelWindow.introLogo * 0.28
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "RAOHANE"
                    color: RaohaneTheme.text
                    font.pixelSize: root.compactLayout ? 30 : 48
                    font.weight: Font.Light
                    font.letterSpacing: root.compactLayout ? 8 : 14
                    opacity: panelWindow.introName
                    transform: Translate { y: (1 - panelWindow.introName) * 14 }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: qsTr("Your desktop, your atmosphere")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 13
                    opacity: panelWindow.introName
                }
            }
            Text {
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 32
                text: qsTr("Click or press any key to continue")
                color: RaohaneTheme.textFaint
                font.pixelSize: 11
                opacity: panelWindow.introName
            }
            MouseArea { anchors.fill: parent; onClicked: root.finishIntro() }
            Keys.onPressed: event => { root.finishIntro(); event.accepted = true }
        }
        SequentialAnimation {
            id: introAnimation
            NumberAnimation { target: panelWindow; property: "introLogo"; from: 0; to: 1; duration: 600; easing.type: Easing.OutCubic }
            NumberAnimation { target: panelWindow; property: "introName"; from: 0; to: 1; duration: 650; easing.type: Easing.OutCubic }
            PauseAnimation { duration: 2400 }
            NumberAnimation { target: panelWindow; property: "curtainOpacity"; from: 1; to: 0; duration: 350 }
            onFinished: root.finishIntro()
        }
        Connections {
            target: RaohaneMotion
            function onEnabledChanged() { if (!RaohaneMotion.enabled && panelWindow.introActive) root.finishIntro() }
            function onTransformMotionEnabledChanged() { if (!RaohaneMotion.transformMotionEnabled && panelWindow.introActive) root.finishIntro() }
        }
        Connections {
            target: RaohanePerformance
            function onGameModeActiveChanged() { if (RaohanePerformance.gameModeActive && panelWindow.introActive) root.finishIntro() }
        }

        Item {
            id: stage
            anchors.fill: parent
            focus: panelWindow.visible && !panelWindow.introActive
            opacity: panelWindow.entered ? 1 : 0

            Behavior on opacity {
                enabled: RaohaneMotion.enabled && !RaohanePerformance.gameModeActive
                NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeStandard }
            }

            RaohaneSurface {
                id: welcomeCard
                width: Math.max(0, Math.min(parent.width - (root.compactLayout ? 24 : 80), 1060))
                height: Math.max(0, Math.min(parent.height - (root.compactLayout ? 24 : 80), 680))
                anchors.centerIn: parent
                surfaceRadius: RaohaneTheme.radiusHero
                idleColor: RaohaneTheme.surfaceDeep
                idleBorderColor: RaohaneTheme.borderStrong
                showSheen: false
                showInnerRim: false

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: root.compactLayout ? 16 : 30
                    spacing: root.compactLayout ? 16 : 30

                    ColumnLayout {
                        visible: !root.compactLayout
                        Layout.preferredWidth: 190
                        Layout.fillHeight: true
                        spacing: 12

                        RowLayout {
                            spacing: 10
                            Image {
                                source: root.logoUrl
                                sourceSize: Qt.size(64, 64)
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                            }
                            Text {
                                text: "RAOHANE"
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                font.letterSpacing: 2
                            }
                        }
                        Text {
                            Layout.topMargin: 28
                            text: qsTr("Make yourself at home")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 12
                        }
                        Repeater {
                            model: root.stepNames
                            delegate: WelcomeButton {
                                required property int index
                                required property string modelData
                                Layout.fillWidth: true
                                label: (index + 1) + "  " + modelData
                                icon: index < root.setupStep ? "check" : "circle"
                                emphasized: index === root.setupStep
                                enabled: index <= root.setupStep
                                onTriggered: root.setupStep = index
                            }
                        }
                        Item { Layout.fillHeight: true }
                        StatusChip {
                            icon: "dark_mode"
                            label: RaohaneTheme.presetName
                            active: true
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Made for Hyprland")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        visible: !root.compactLayout
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: RaohaneTheme.borderFaint
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: root.compactLayout ? 12 : 18

                        Text {
                            text: qsTr("Step %1 of 5").arg(root.setupStep + 1)
                            color: RaohaneTheme.accent
                            font.pixelSize: 12
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            height: 3
                            radius: 2
                            color: RaohaneTheme.borderFaint
                            Rectangle { width: parent.width * (root.setupStep + 1) / 5; height: 3; radius: 2; color: RaohaneTheme.accent }
                        }
                        Text {
                            Layout.fillWidth: true
                            text: root.setupStep === 0 ? qsTr("Welcome to Raohane") : root.stepNames[root.setupStep]
                            color: RaohaneTheme.text
                            font.pixelSize: root.compactLayout ? 28 : 38
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Take your time. Your desktop will wait until you finish setup.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 13
                            wrapMode: Text.WordWrap
                        }
                        Flickable {
                            id: setupScroll
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            contentHeight: setupContent.implicitHeight
                            boundsBehavior: Flickable.StopAtBounds
                            ColumnLayout {
                                id: setupContent
                                width: setupScroll.width
                                spacing: 16
                                Image {
                                    visible: root.setupStep === 0 || root.setupStep === 4
                                    Layout.alignment: Qt.AlignHCenter
                                    Layout.topMargin: 24
                                    Layout.preferredWidth: 140
                                    Layout.preferredHeight: 140
                                    source: root.logoUrl
                                    sourceSize: Qt.size(280, 280)
                                }
                                Text {
                                    visible: root.setupStep === 0 || root.setupStep === 4
                                    Layout.fillWidth: true
                                    text: root.setupStep === 0 ? qsTr("Your desktop, your atmosphere") : qsTr("Everything is ready. Make yourself at home.")
                                    horizontalAlignment: Text.AlignHCenter
                                    color: RaohaneTheme.accent
                                    font.pixelSize: 20
                                    wrapMode: Text.WordWrap
                                }
                                Text {
                                    visible: root.setupStep === 0 || root.setupStep === 4
                                    Layout.fillWidth: true
                                    text: root.setupStep === 0 ? qsTr("Choose your colors, a wallpaper and a bar style. You can change everything later in Settings.") : RaohaneTheme.presetName + " · " + RaohaneConfig.barStylePreset
                                    horizontalAlignment: Text.AlignHCenter
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 14
                                    wrapMode: Text.WordWrap
                                }
                                Repeater {
                                    model: root.setupStep === 1 ? RaohaneTheme.builtInPresets : []
                                    delegate: WelcomeButton {
                                        required property var modelData
                                        Layout.fillWidth: true
                                        label: modelData.name
                                        icon: RaohaneConfig.themePreset === modelData.id ? "check_circle" : "palette"
                                        emphasized: RaohaneConfig.themePreset === modelData.id
                                        onTriggered: RaohaneConfig.themePreset = modelData.id
                                    }
                                }
                                GridLayout {
                                    visible: root.setupStep === 2
                                    Layout.fillWidth: true
                                    columns: 2
                                    columnSpacing: 12
                                    rowSpacing: 12
                                    Repeater {
                                        model: ["nature/08-path.jpg", "nature/01-bythewater.jpg", "abstract/01-cascade.png", "abstract/04-flow.jpg", "anime/01-lantern-girl.svg", "anime/02-the-last-train.svg"]
                                        delegate: WelcomeButton {
                                            required property string modelData
                                            readonly property string path: RaohanePaths.join(RaohanePaths.bundledWallpaperDirectory, modelData)
                                            Layout.fillWidth: true
                                            Layout.preferredHeight: 120
                                            label: ""
                                            icon: ""
                                            emphasized: RaohaneConfig.wallpaperPath === path
                                            Image { anchors.fill: parent; anchors.margins: 6; source: RaohanePaths.fileUrl(parent.path); fillMode: Image.PreserveAspectCrop; clip: true; sourceSize: Qt.size(480, 240) }
                                            onTriggered: RaohaneWallpapers.apply(path)
                                            Accessible.name: modelData
                                        }
                                    }
                                }
                                Loader {
                                    Layout.fillWidth: true
                                    active: root.setupStep === 3
                                    sourceComponent: RaohaneBarAppearanceSettings {}
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            WelcomeButton {
                                visible: root.setupStep > 0
                                label: qsTr("Back")
                                icon: "arrow_back"
                                onTriggered: root.previous()
                            }
                            Item { Layout.fillWidth: true }
                            WelcomeButton {
                                visible: root.setupStep === 4
                                label: qsTr("Show me around")
                                icon: "explore"
                                onTriggered: root.startTour()
                            }
                            WelcomeButton {
                                emphasized: true
                                label: root.setupStep === 4 ? qsTr("Finish setup") : qsTr("Continue")
                                icon: "arrow_forward"
                                onTriggered: root.setupStep === 4 ? root.skipWelcome() : root.advance()
                            }
                        }

                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.advance()
                    event.accepted = true
                } else if (event.key === Qt.Key_Escape) {
                    root.previous()
                    event.accepted = true
                }
            }
        }
    }

    IpcHandler {
        target: "welcome"

        function open(): void { RaohaneState.setPrimaryOpen("welcome", true) }
        function next(): void { root.advance() }
        function back(): void { root.previous() }
        function step(): int { return root.setupStep }
        function close(): void { root.skipWelcome() }
        function reset(): void { RaohaneOnboardingState.reset() }
        function tour(): void { root.startTour() }
        function status(): string { return RaohaneState.welcomeOpen ? "open" : "closed" }
        function phase(): string { return panelWindow.introActive ? "intro" : RaohaneState.welcomeOpen ? "welcome" : "closed" }
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

        implicitWidth: Math.max(120, buttonContent.implicitWidth + 32)
        Layout.preferredHeight: 46
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
            id: buttonContent
            anchors.centerIn: parent
            spacing: 8
            Text { text: button.label; color: button.emphasized ? RaohaneTheme.text : RaohaneTheme.textMuted; font.pixelSize: 13; font.weight: Font.DemiBold }
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
