pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
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
            description: qsTr("The floating Bar keeps launcher, workspaces, live context, time and system status close without taking over the desktop."),
            hint: qsTr("This is Raohane's main navigation rhythm.")
        },
        {
            key: "dock",
            target: "dock",
            card: "topRight",
            icon: "dock_to_bottom",
            eyebrow: qsTr("APPS"),
            title: qsTr("The Dock stays out of the way"),
            description: qsTr("Move the pointer to the lower edge to reveal running and pinned applications. Auto-hide preserves a clean workspace."),
            hint: qsTr("Hover the highlighted edge now to reveal it.")
        },
        {
            key: "launcher",
            target: "launcher",
            card: "bottomRight",
            icon: "search",
            eyebrow: qsTr("FIND ANYTHING"),
            title: qsTr("Launcher"),
            description: qsTr("Apps, commands and search results live in one focused surface. The real Launcher is open behind this guide."),
            hint: qsTr("Start typing whenever you want to narrow the result set.")
        },
        {
            key: "controlCenter",
            target: "controlCenter",
            card: "leftCenter",
            icon: "tune",
            eyebrow: qsTr("SYSTEM CONTROL"),
            title: qsTr("Control Center"),
            description: qsTr("Audio, brightness, connectivity, notifications and frequent system actions are grouped into one compact right-side panel."),
            hint: qsTr("Use this for quick changes instead of opening Settings.")
        },
        {
            key: "sidebar",
            target: "sidebar",
            card: "rightCenter",
            icon: "view_sidebar",
            eyebrow: qsTr("AT A GLANCE"),
            title: qsTr("Left Sidebar"),
            description: qsTr("The left side holds glanceable information and secondary tools while keeping the center of the desktop focused."),
            hint: qsTr("Large supporting surfaces stay at the screen edges.")
        },
        {
            key: "overview",
            target: "overview",
            card: "bottomCenter",
            icon: "grid_view",
            eyebrow: qsTr("SPACES"),
            title: qsTr("Overview"),
            description: qsTr("Overview turns Hyprland workspaces into a visual map so you can understand where windows and tasks live."),
            hint: qsTr("Use it when the desktop becomes busy.")
        },
        {
            key: "wallpaper",
            target: "wallpaper",
            card: "bottomLeft",
            icon: "wallpaper",
            eyebrow: qsTr("ATMOSPHERE"),
            title: qsTr("Wallpaper Selector"),
            description: qsTr("Browse, preview and apply wallpapers from Raohane's visual library. The background is part of the shell atmosphere."),
            hint: qsTr("Preview first, commit only when it feels right.")
        },
        {
            key: "settings",
            target: "settings",
            card: "bottomLeft",
            icon: "settings",
            eyebrow: qsTr("MAKE IT YOURS"),
            title: qsTr("Settings"),
            description: qsTr("Themes, Style Studio, Bar and Dock behavior, desktop layout, integrations and profile controls all live here."),
            hint: qsTr("The tour opens Theme Library first so you can immediately see where visual identity lives.")
        },
        {
            key: "context",
            target: "context",
            card: "bottomRight",
            icon: "radio_button_checked",
            eyebrow: qsTr("LIVE CONTEXT"),
            title: qsTr("Context Island"),
            description: qsTr("The center of the Bar reacts to media, privacy activity and current context without opening another window."),
            hint: qsTr("It stays small and only becomes informative when there is something worth showing.")
        },
        {
            key: "session",
            target: "session",
            card: "bottomRight",
            icon: "power_settings_new",
            eyebrow: qsTr("SESSION"),
            title: qsTr("Session controls"),
            description: qsTr("Lock, logout, reboot and power actions use a dedicated surface so destructive actions remain deliberate."),
            hint: qsTr("The tour never triggers a power action automatically.")
        },
        {
            key: "finish",
            target: "finish",
            card: "center",
            icon: "check_circle",
            eyebrow: qsTr("YOU ARE READY"),
            title: qsTr("This is your Raohane"),
            description: qsTr("You now know the main surfaces. Explore at your own pace and let the shell stay quiet when you are working."),
            hint: qsTr("The tour will not appear automatically again after completion.")
        }
    ]

    readonly property var stepData: root.steps[Math.max(0, Math.min(root.steps.length - 1, RaohaneOnboardingState.step))]

    function clamp(value: real, minimum: real, maximum: real): real {
        return Math.max(minimum, Math.min(maximum, value))
    }

    function centeredRect(width: real, height: real, radius: real): var {
        return {
            x: (overlayWindow.width - width) / 2,
            y: (overlayWindow.height - height) / 2,
            width: width,
            height: height,
            radius: radius
        }
    }

    function targetRectFor(target: string): var {
        const w = overlayWindow.width
        const h = overlayWindow.height

        switch (target) {
        case "bar":
            return {
                x: 6,
                y: RaohaneConfig.barBottom ? Math.max(0, h - 64) : 0,
                width: Math.max(0, w - 12),
                height: Math.min(64, h),
                radius: 25
            }
        case "dock": {
            const dockW = Math.min(640, Math.max(300, w * 0.58))
            const dockH = Math.min(h, RaohaneConfig.dockHeight + RaohaneConfig.dockBottomMargin + 20)
            return {
                x: (w - dockW) / 2,
                y: Math.max(0, h - dockH),
                width: dockW,
                height: dockH,
                radius: Math.min(34, dockH / 2)
            }
        }
        case "launcher": {
            const launcherW = Math.min(640, Math.max(360, w - 56))
            const launcherH = Math.min(560, Math.max(360, h * 0.61))
            return {
                x: (w - launcherW) / 2 - 5,
                y: 72,
                width: launcherW + 10,
                height: Math.min(launcherH + 12, h - 82),
                radius: 31
            }
        }
        case "controlCenter": {
            const panelW = Math.min(404, Math.max(300, w - 28))
            const panelH = Math.min(640, Math.max(540, h - 44))
            return {
                x: Math.max(8, w - panelW - 20),
                y: 8,
                width: Math.min(w - 8, panelW + 12),
                height: Math.min(h - 16, panelH + 12),
                radius: 31
            }
        }
        case "sidebar":
            return {
                x: 8,
                y: 8,
                width: Math.min(384, w - 16),
                height: Math.max(0, h - 16),
                radius: 31
            }
        case "overview": {
            const overviewW = Math.min(w - 96, 1040)
            const overviewH = Math.min(h - 112, 680)
            return root.centeredRect(Math.max(0, overviewW + 12), Math.max(0, overviewH + 12), 34)
        }
        case "wallpaper": {
            const wallpaperW = Math.min(w - 96, 1080)
            const wallpaperH = Math.min(h - 104, 700)
            return root.centeredRect(Math.max(0, wallpaperW + 12), Math.max(0, wallpaperH + 12), 31)
        }
        case "settings": {
            const settingsW = Math.min(w - 96, 1040)
            const settingsH = Math.min(h - 96, 700)
            return root.centeredRect(Math.max(0, settingsW + 12), Math.max(0, settingsH + 12), 31)
        }
        case "context": {
            const islandW = Math.min(520, Math.max(240, w * 0.38))
            return {
                x: (w - islandW) / 2,
                y: RaohaneConfig.barBottom ? Math.max(6, h - 58) : 6,
                width: islandW,
                height: 50,
                radius: 25
            }
        }
        case "session": {
            const sessionW = Math.min(w - 96, 850)
            const sessionH = Math.min(h - 112, 540)
            return root.centeredRect(Math.max(0, sessionW + 12), Math.max(0, sessionH + 12), 35)
        }
        default:
            return root.centeredRect(w * 0.56, h * 0.58, 34)
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

    function overlaps(first, second, padding: real): bool {
        return first.x < second.x + second.width + padding
            && first.x + first.width + padding > second.x
            && first.y < second.y + second.height + padding
            && first.y + first.height + padding > second.y
    }

    function safeCardPosition(place: string, cardWidth: real, cardHeight: real): var {
        const preferred = root.cardPosition(place, cardWidth, cardHeight)
        const margin = 28
        const gap = 24
        const w = overlayWindow.width
        const h = overlayWindow.height
        const target = overlayWindow.targetRect
        const preferredRect = { x: preferred.x, y: preferred.y, width: cardWidth, height: cardHeight }

        if (!overlayWindow.hasSpotlight || !root.overlaps(preferredRect, target, 12))
            return preferred

        const candidates = [
            {
                score: w - (target.x + target.width),
                x: target.x + target.width + gap,
                y: root.clamp(target.y + target.height / 2 - cardHeight / 2, margin, h - cardHeight - margin)
            },
            {
                score: target.x,
                x: target.x - cardWidth - gap,
                y: root.clamp(target.y + target.height / 2 - cardHeight / 2, margin, h - cardHeight - margin)
            },
            {
                score: h - (target.y + target.height),
                x: root.clamp(target.x + target.width / 2 - cardWidth / 2, margin, w - cardWidth - margin),
                y: target.y + target.height + gap
            },
            {
                score: target.y,
                x: root.clamp(target.x + target.width / 2 - cardWidth / 2, margin, w - cardWidth - margin),
                y: target.y - cardHeight - gap
            }
        ]
        candidates.sort((left, right) => right.score - left.score)

        for (const candidate of candidates) {
            const validX = candidate.x >= margin && candidate.x + cardWidth <= w - margin
            const validY = candidate.y >= margin && candidate.y + cardHeight <= h - margin
            const rect = { x: candidate.x, y: candidate.y, width: cardWidth, height: cardHeight }
            if (validX && validY && !root.overlaps(rect, target, 10))
                return { x: candidate.x, y: candidate.y }
        }

        return {
            x: root.clamp(preferred.x, margin, Math.max(margin, w - cardWidth - margin)),
            y: root.clamp(preferred.y, margin, Math.max(margin, h - cardHeight - margin))
        }
    }

    function roundedRectPath(context, x: real, y: real, width: real, height: real, radius: real): void {
        const r = Math.max(0, Math.min(radius, Math.min(width, height) / 2))
        context.beginPath()
        context.moveTo(x + r, y)
        context.lineTo(x + width - r, y)
        context.quadraticCurveTo(x + width, y, x + width, y + r)
        context.lineTo(x + width, y + height - r)
        context.quadraticCurveTo(x + width, y + height, x + width - r, y + height)
        context.lineTo(x + r, y + height)
        context.quadraticCurveTo(x, y + height, x, y + height - r)
        context.lineTo(x, y + r)
        context.quadraticCurveTo(x, y, x + r, y)
        context.closePath()
    }

    PanelWindow {
        id: overlayWindow

        property bool cardEntered: true
        readonly property var targetRect: root.targetRectFor(root.stepData.target)
        readonly property bool hasSpotlight: root.stepData.target !== "finish"
        readonly property color scrimColor: RaohaneTheme.dark
            ? Qt.rgba(0, 0, 0, 0.54)
            : Qt.rgba(0.12, 0.12, 0.11, 0.31)

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

        mask: Region { item: coachCard }

        onVisibleChanged: {
            if (!visible)
                return
            cardEntered = false
            Qt.callLater(() => cardEntered = true)
            scrimCanvas.requestPaint()
        }

        Connections {
            target: RaohaneOnboardingState
            function onStepChanged(): void {
                overlayWindow.cardEntered = false
                Qt.callLater(() => overlayWindow.cardEntered = true)
                scrimCanvas.requestPaint()
            }
        }

        Canvas {
            id: scrimCanvas
            z: 0
            anchors.fill: parent
            antialiasing: true

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()

            onPaint: {
                const context = getContext("2d")
                context.clearRect(0, 0, width, height)
                context.save()
                context.globalCompositeOperation = "source-over"
                context.fillStyle = overlayWindow.scrimColor
                context.fillRect(0, 0, width, height)

                if (overlayWindow.hasSpotlight && spotlight.width > 0 && spotlight.height > 0) {
                    context.globalCompositeOperation = "destination-out"
                    root.roundedRectPath(context, spotlight.x, spotlight.y, spotlight.width, spotlight.height, spotlight.radius)
                    context.fillStyle = "#ffffff"
                    context.fill()
                }
                context.restore()
            }
        }

        Connections {
            target: spotlight
            function onXChanged(): void { scrimCanvas.requestPaint() }
            function onYChanged(): void { scrimCanvas.requestPaint() }
            function onWidthChanged(): void { scrimCanvas.requestPaint() }
            function onHeightChanged(): void { scrimCanvas.requestPaint() }
            function onRadiusChanged(): void { scrimCanvas.requestPaint() }
        }

        Rectangle {
            id: spotlight
            z: 2
            visible: overlayWindow.hasSpotlight
            x: overlayWindow.targetRect.x
            y: overlayWindow.targetRect.y
            width: overlayWindow.targetRect.width
            height: overlayWindow.targetRect.height
            radius: overlayWindow.targetRect.radius
            color: "transparent"
            border.width: 2
            border.color: RaohaneTheme.accentBorder

            Behavior on x { NumberAnimation { duration: 340; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on y { NumberAnimation { duration: 340; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on width { NumberAnimation { duration: 340; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on height { NumberAnimation { duration: 340; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on radius { NumberAnimation { duration: 280; easing.type: RaohaneMotion.easeStandard } }

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
                    NumberAnimation { from: 0.18; to: 0.56; duration: 1150; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 0.56; to: 0.18; duration: 1150; easing.type: Easing.InOutSine }
                }
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: Math.max(0, parent.radius - 5)
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(RaohaneTheme.accent.r, RaohaneTheme.accent.g, RaohaneTheme.accent.b, 0.16)
            }
        }

        RaohaneSurface {
            id: coachCard
            z: 10

            readonly property var desiredPosition: root.safeCardPosition(root.stepData.card, width, height)

            width: Math.min(444, overlayWindow.width - 48)
            height: Math.min(398, overlayWindow.height - 56)
            x: desiredPosition.x
            y: desiredPosition.y
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: overlayWindow.cardEntered ? 1 : 0
            scale: overlayWindow.cardEntered ? 1 : 0.976

            transform: Translate {
                y: overlayWindow.cardEntered ? 0 : 10
                Behavior on y { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized } }
            }

            Behavior on x { NumberAnimation { duration: 340; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on y { NumberAnimation { duration: 340; easing.type: RaohaneMotion.easeEmphasized } }
            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard } }
            Behavior on scale { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized } }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 1
                    topMargin: 20
                    bottomMargin: 20
                }
                width: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.74
            }

            Rectangle {
                anchors {
                    right: parent.right
                    top: parent.top
                    rightMargin: -42
                    topMargin: -58
                }
                width: 158
                height: 158
                radius: 79
                color: "transparent"
                border.width: 1
                border.color: RaohaneTheme.accentGlow
                opacity: 0.22
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 11

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 48
                        Layout.preferredHeight: 48

                        Rectangle {
                            anchors.centerIn: parent
                            width: 48
                            height: 48
                            radius: 16
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.accentBorder
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 36
                            height: 36
                            radius: 13
                            color: "transparent"
                            border.width: 1
                            border.color: RaohaneTheme.accentGlow
                            opacity: 0.6
                        }

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.stepData.icon
                            iconSize: 22
                            fill: root.stepData.key === "finish" ? 1 : 0.18
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: root.stepData.eyebrow
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.45
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
                    lineHeight: 1.34
                    wrapMode: Text.WordWrap
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 62
                    surfaceRadius: RaohaneTheme.radiusSmall
                    raised: false
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        RaohaneSurface {
                            Layout.preferredWidth: 30
                            Layout.preferredHeight: 30
                            surfaceRadius: 10
                            active: true
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: root.stepData.key === "dock" ? "mouse" : "lightbulb"
                                iconSize: 15
                                color: RaohaneTheme.accentSecondary
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.stepData.hint
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 11
                            lineHeight: 1.22
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
                            required property int index

                            Layout.fillWidth: true
                            Layout.preferredHeight: index === RaohaneOnboardingState.step ? 4 : 3
                            radius: 2
                            color: index <= RaohaneOnboardingState.step ? RaohaneTheme.accent : RaohaneTheme.border
                            opacity: index === RaohaneOnboardingState.step ? 1 : 0.55

                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                            Behavior on height { NumberAnimation { duration: RaohaneMotion.micro } }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
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
                        feedback: "navigate"

                        Row {
                            anchors.centerIn: parent
                            spacing: 6
                            RaohaneIcon { text: "arrow_back"; iconSize: 15; color: RaohaneTheme.textMuted }
                            Text { text: qsTr("Back"); color: RaohaneTheme.textMuted; font.pixelSize: 11; font.weight: Font.DemiBold }
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
                        feedback: root.stepData.key === "finish" ? "confirm" : "navigate"

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
