import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    readonly property var steps: [
        {
            key: "bar",
            target: "bar",
            card: "bottomRight",
            icon: "space_dashboard",
            eyebrow: qsTr("SHELL BASICS"),
            title: qsTr("Meet the Bar"),
            description: qsTr("The floating Bar is your always-available control strip: launcher, workspaces, live context, clock and system status."),
            hint: qsTr("Everything important stays close without turning the desktop into a dashboard.")
        },
        {
            key: "dock",
            target: "dock",
            card: "topRight",
            icon: "dock_to_bottom",
            eyebrow: qsTr("APPS"),
            title: qsTr("The Dock stays out of the way"),
            description: qsTr("Move the pointer to the lower edge to reveal running and pinned applications. Auto-hide keeps the workspace calm when you do not need it."),
            hint: qsTr("Hover the highlighted area now to see the Dock reveal itself.")
        },
        {
            key: "launcher",
            target: "launcher",
            card: "bottomRight",
            icon: "search",
            eyebrow: qsTr("FIND ANYTHING"),
            title: qsTr("Launcher"),
            description: qsTr("Apps, commands and search results live in one focused surface. Start typing and Raohane narrows the result set immediately."),
            hint: qsTr("The real Launcher is open behind this guide, so you can inspect it while the tour continues.")
        },
        {
            key: "controlCenter",
            target: "controlCenter",
            card: "leftCenter",
            icon: "tune",
            eyebrow: qsTr("SYSTEM CONTROL"),
            title: qsTr("Control Center"),
            description: qsTr("Audio, brightness, connectivity, notifications and quick system actions are grouped into one compact panel on the right."),
            hint: qsTr("This is the place for frequent changes that should not require opening Settings.")
        },
        {
            key: "sidebar",
            target: "sidebar",
            card: "rightCenter",
            icon: "view_sidebar",
            eyebrow: qsTr("AT A GLANCE"),
            title: qsTr("Left Sidebar"),
            description: qsTr("The left side collects glanceable information and secondary tools without competing with your active window."),
            hint: qsTr("Raohane keeps large panels at the edges so the center of the screen stays focused.")
        },
        {
            key: "overview",
            target: "overview",
            card: "bottomCenter",
            icon: "grid_view",
            eyebrow: qsTr("SPACES"),
            title: qsTr("Overview"),
            description: qsTr("Overview turns your Hyprland workspaces into a visual map, making it easier to understand where windows and tasks live."),
            hint: qsTr("Use it when the desktop becomes busy and you need spatial context again.")
        },
        {
            key: "wallpaper",
            target: "wallpaper",
            card: "bottomLeft",
            icon: "wallpaper",
            eyebrow: qsTr("ATMOSPHERE"),
            title: qsTr("Wallpaper Selector"),
            description: qsTr("Browse, preview and apply wallpapers from a dedicated visual library. Raohane uses the background as part of the shell atmosphere."),
            hint: qsTr("You can preview images before committing them, so experimenting is safe.")
        },
        {
            key: "settings",
            target: "settings",
            card: "bottomLeft",
            icon: "settings",
            eyebrow: qsTr("MAKE IT YOURS"),
            title: qsTr("Settings"),
            description: qsTr("Themes, Style Studio, Bar and Dock behavior, desktop layout, integrations and profile controls all live here."),
            hint: qsTr("The tour opens the Theme Library first because visual identity is the fastest way to make Raohane feel personal.")
        },
        {
            key: "context",
            target: "context",
            card: "bottomRight",
            icon: "radio_button_checked",
            eyebrow: qsTr("LIVE CONTEXT"),
            title: qsTr("Context Island"),
            description: qsTr("The center of the Bar can react to media, privacy activity and the current context without opening another window."),
            hint: qsTr("It stays intentionally small: useful information appears only when there is something worth showing.")
        },
        {
            key: "session",
            target: "session",
            card: "bottomRight",
            icon: "power_settings_new",
            eyebrow: qsTr("SESSION"),
            title: qsTr("Session controls"),
            description: qsTr("Lock, logout, reboot and power actions use a dedicated Raohane surface so destructive actions remain deliberate and easy to recognize."),
            hint: qsTr("You are still in the tour; no power action will be triggered automatically.")
        },
        {
            key: "finish",
            target: "finish",
            card: "center",
            icon: "check_circle",
            eyebrow: qsTr("YOU ARE READY"),
            title: qsTr("This is your Raohane"),
            description: qsTr("You now know the main surfaces. Explore at your own pace, change anything in Settings, and let the shell stay quiet when you are working."),
            hint: qsTr("The onboarding will not appear automatically again, but it can be replayed later.")
        }
    ]

    readonly property var stepData: root.steps[Math.max(0, Math.min(root.steps.length - 1, RaohaneOnboardingState.step))]

    function targetRectFor(target: string): var {
        const w = overlayWindow.width
        const h = overlayWindow.height
        const settingsW = Math.min(w - 96, 1040)
        const settingsH = Math.min(h - 96, 700)
        const wallpaperW = Math.min(w - 96, 1080)
        const wallpaperH = Math.min(h - 104, 700)

        switch (target) {
        case "bar":
            return { x: 8, y: RaohaneConfig.barBottom ? h - 68 : 0, width: Math.max(0, w - 16), height: 68, radius: 26 }
        case "dock": {
            const dockW = Math.min(580, Math.max(300, w * 0.58))
            return {
                x: (w - dockW) / 2,
                y: h - RaohaneConfig.dockHeight - RaohaneConfig.dockBottomMargin - 24,
                width: dockW,
                height: RaohaneConfig.dockHeight + 20,
                radius: 32
            }
        }
        case "launcher": {
            const launcherW = Math.min(660, w - 56)
            const launcherH = Math.min(560, Math.max(360, h * 0.61))
            return { x: (w - launcherW) / 2, y: 72, width: launcherW, height: launcherH, radius: 30 }
        }
        case "controlCenter":
            return { x: Math.max(8, w - 448), y: 8, width: Math.min(440, w - 16), height: Math.min(680, h - 16), radius: 30 }
        case "sidebar":
            return { x: 8, y: 8, width: Math.min(386, w - 16), height: Math.max(0, h - 16), radius: 30 }
        case "overview":
            return { x: Math.max(24, w * 0.06), y: Math.max(72, h * 0.08), width: Math.max(0, w * 0.88), height: Math.max(0, h * 0.76), radius: 34 }
        case "wallpaper":
            return { x: (w - wallpaperW) / 2, y: (h - wallpaperH) / 2, width: wallpaperW, height: wallpaperH, radius: 30 }
        case "settings":
            return { x: (w - settingsW) / 2, y: (h - settingsH) / 2, width: settingsW, height: settingsH, radius: 30 }
        case "context": {
            const islandW = Math.min(520, Math.max(240, w * 0.38))
            return {
                x: (w - islandW) / 2,
                y: RaohaneConfig.barBottom ? h - 60 : 7,
                width: islandW,
                height: 48,
                radius: 26
            }
        }
        case "session": {
            const sessionW = Math.min(760, w - 80)
            const sessionH = Math.min(520, h - 80)
            return { x: (w - sessionW) / 2, y: (h - sessionH) / 2, width: sessionW, height: sessionH, radius: 34 }
        }
        default:
            return { x: w * 0.22, y: h * 0.18, width: w * 0.56, height: h * 0.58, radius: 34 }
        }
    }

    function cardPosition(place: string, cardWidth: real, cardHeight: real): var {
        const w = overlayWindow.width
        const h = overlayWindow.height
        const margin = 28

        switch (place) {
        case "topRight": return { x: w - cardWidth - margin, y: 92 }
        case "bottomRight": return { x: w - cardWidth - margin, y: h - cardHeight - 34 }
        case "bottomLeft": return { x: margin, y: h - cardHeight - 34 }
        case "leftCenter": return { x: margin, y: (h - cardHeight) / 2 }
        case "rightCenter": return { x: w - cardWidth - margin, y: (h - cardHeight) / 2 }
        case "bottomCenter": return { x: (w - cardWidth) / 2, y: h - cardHeight - 30 }
        default: return { x: (w - cardWidth) / 2, y: (h - cardHeight) / 2 }
        }
    }

    PanelWindow {
        id: overlayWindow

        property bool cardEntered: true
        readonly property var targetRect: root.targetRectFor(root.stepData.target)
        readonly property bool hasSpotlight: root.stepData.target !== "finish"
        readonly property color scrimColor: RaohaneTheme.dark
            ? Qt.rgba(0, 0, 0, 0.50)
            : Qt.rgba(0.12, 0.12, 0.11, 0.29)

        visible: RaohaneOnboardingState.active
        screen: root.focusedScreen
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-onboarding"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        mask: Region {
            item: coachCard
        }

        onVisibleChanged: {
            if (visible) {
                cardEntered = false
                Qt.callLater(() => cardEntered = true)
            }
        }

        Connections {
            target: RaohaneOnboardingState

            function onStepChanged(): void {
                overlayWindow.cardEntered = false
                Qt.callLater(() => overlayWindow.cardEntered = true)
            }
        }

        Rectangle {
            visible: !overlayWindow.hasSpotlight
            anchors.fill: parent
            color: overlayWindow.scrimColor

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }
        }

        Rectangle {
            visible: overlayWindow.hasSpotlight
            x: 0
            y: 0
            width: parent.width
            height: Math.max(0, spotlight.y)
            color: overlayWindow.scrimColor
        }

        Rectangle {
            visible: overlayWindow.hasSpotlight
            x: 0
            y: spotlight.y + spotlight.height
            width: parent.width
            height: Math.max(0, parent.height - y)
            color: overlayWindow.scrimColor
        }

        Rectangle {
            visible: overlayWindow.hasSpotlight
            x: 0
            y: spotlight.y
            width: Math.max(0, spotlight.x)
            height: spotlight.height
            color: overlayWindow.scrimColor
        }

        Rectangle {
            visible: overlayWindow.hasSpotlight
            x: spotlight.x + spotlight.width
            y: spotlight.y
            width: Math.max(0, parent.width - x)
            height: spotlight.height
            color: overlayWindow.scrimColor
        }

        Rectangle {
            id: spotlight

            visible: overlayWindow.hasSpotlight
            x: overlayWindow.targetRect.x
            y: overlayWindow.targetRect.y
            width: overlayWindow.targetRect.width
            height: overlayWindow.targetRect.height
            radius: overlayWindow.targetRect.radius
            color: "transparent"
            border.width: 2
            border.color: RaohaneTheme.accentBorder

            Behavior on x { NumberAnimation { duration: 360; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on y { NumberAnimation { duration: 360; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on width { NumberAnimation { duration: 360; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on height { NumberAnimation { duration: 360; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on radius { NumberAnimation { duration: 300; easing.type: RaohaneMotion.easeStandard } }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -7
                radius: parent.radius + 7
                color: "transparent"
                border.width: 1
                border.color: RaohaneTheme.accentGlow

                SequentialAnimation on opacity {
                    running: overlayWindow.visible && overlayWindow.hasSpotlight
                    loops: Animation.Infinite
                    NumberAnimation { from: 0.24; to: 0.72; duration: 950; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.72; to: 0.24; duration: 950; easing.type: Easing.InOutSine }
                }
            }
        }

        RaohaneSurface {
            id: coachCard

            readonly property var desiredPosition: root.cardPosition(root.stepData.card, width, height)

            width: Math.min(430, overlayWindow.width - 48)
            height: Math.min(420, Math.max(350, content.implicitHeight + 42))
            x: desiredPosition.x
            y: desiredPosition.y
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            opacity: overlayWindow.cardEntered ? 1 : 0
            scale: overlayWindow.cardEntered ? 1 : 0.975

            transform: Translate {
                y: overlayWindow.cardEntered ? 0 : 12
                Behavior on y {
                    NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized }
                }
            }

            Behavior on x { NumberAnimation { duration: 360; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on y { NumberAnimation { duration: 360; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard } }
            Behavior on scale { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized } }

            ColumnLayout {
                id: content
                anchors.fill: parent
                anchors.margins: 22
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        Layout.preferredWidth: 44
                        Layout.preferredHeight: 44
                        radius: 15
                        color: RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.accentBorder

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.stepData.icon
                            iconSize: 22
                            fill: root.stepData.key === "finish" ? 1 : 0.15
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: root.stepData.eyebrow
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.5
                        }

                        Text {
                            text: qsTr("Step %1 of %2").arg(RaohaneOnboardingState.step + 1).arg(root.steps.length)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 10
                        }
                    }

                    RaohaneSurface {
                        Layout.preferredWidth: 70
                        Layout.preferredHeight: 28
                        surfaceRadius: 10
                        transparentIdle: true
                        interactive: true
                        hovered: skipPointer.containsMouse
                        pressed: skipPointer.pressed
                        showSheen: false

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Skip tour")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 10
                            font.weight: Font.Medium
                        }

                        MouseArea {
                            id: skipPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneOnboardingState.skip()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.stepData.title
                    color: RaohaneTheme.text
                    font.pixelSize: root.stepData.key === "finish" ? 27 : 23
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.stepData.description
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 13
                    lineHeight: 1.35
                    wrapMode: Text.WordWrap
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 66
                    surfaceRadius: RaohaneTheme.radiusSmall
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RaohaneIcon {
                            Layout.preferredWidth: 20
                            text: root.stepData.key === "dock" ? "mouse" : "lightbulb"
                            iconSize: 17
                            color: RaohaneTheme.accentSecondary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.stepData.hint
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 11
                            lineHeight: 1.25
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5

                    Repeater {
                        model: root.steps.length

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 3
                            radius: 2
                            color: index <= RaohaneOnboardingState.step
                                ? RaohaneTheme.accent
                                : RaohaneTheme.border
                            opacity: index === RaohaneOnboardingState.step ? 1 : 0.62

                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 10

                    RaohaneSurface {
                        Layout.preferredWidth: 104
                        Layout.preferredHeight: 40
                        surfaceRadius: RaohaneTheme.radiusSmall
                        transparentIdle: RaohaneOnboardingState.step === 0
                        interactive: RaohaneOnboardingState.step > 0
                        enabled: RaohaneOnboardingState.step > 0
                        hovered: backPointer.containsMouse
                        pressed: backPointer.pressed
                        showSheen: false

                        Row {
                            anchors.centerIn: parent
                            spacing: 6

                            RaohaneIcon {
                                text: "arrow_back"
                                iconSize: 15
                                color: RaohaneTheme.textMuted
                            }
                            Text {
                                text: qsTr("Back")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }

                        MouseArea {
                            id: backPointer
                            anchors.fill: parent
                            enabled: RaohaneOnboardingState.step > 0
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: RaohaneOnboardingState.previous()
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RaohaneSurface {
                        Layout.preferredWidth: root.stepData.key === "finish" ? 174 : 126
                        Layout.preferredHeight: 40
                        surfaceRadius: RaohaneTheme.radiusSmall
                        active: true
                        interactive: true
                        hovered: nextPointer.containsMouse
                        pressed: nextPointer.pressed
                        showSheen: false

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                text: root.stepData.key === "finish" ? qsTr("Enter Raohane") : qsTr("Next")
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }

                            RaohaneIcon {
                                text: root.stepData.key === "finish" ? "check" : "arrow_forward"
                                iconSize: 15
                                color: RaohaneTheme.accent
                            }
                        }

                        MouseArea {
                            id: nextPointer
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneOnboardingState.next()
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "onboarding"

        function open(): void { RaohaneOnboardingState.replay() }
        function reset(): void { RaohaneOnboardingState.reset() }
        function next(): void { RaohaneOnboardingState.next() }
        function previous(): void { RaohaneOnboardingState.previous() }
        function skip(): void { RaohaneOnboardingState.skip() }
        function status(): string { return RaohaneOnboardingState.active ? "open" : "closed" }
        function step(): int { return RaohaneOnboardingState.step }
    }
}
