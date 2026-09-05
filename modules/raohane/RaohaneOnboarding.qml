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
                y: RaohaneConfig.barBottom ? Math.max(0, h - 58) : 0,
                width: Math.max(0, w - 12),
                height: Math.min(58, h),
                radius: 12
            }
        case "dock": {
            const dockW = Math.min(620, Math.max(300, w * 0.56))
            const dockH = Math.min(h, RaohaneConfig.dockHeight + RaohaneConfig.dockBottomMargin + 16)
            return {
                x: (w - dockW) / 2,
                y: Math.max(0, h - dockH),
                width: dockW,
                height: dockH,
                radius: 12
            }
        }
        case "launcher": {
            const launcherW = Math.min(620, Math.max(360, w - 56))
            const launcherH = Math.min(560, Math.max(360, h * 0.61))
            return {
                x: (w - launcherW) / 2 - 5,
                y: 72,
                width: launcherW + 10,
                height: Math.min(launcherH + 12, h - 82),
                radius: 14
            }
        }
        case "controlCenter": {
            const panelW = Math.min(430, Math.max(310, w - 28))
            const panelH = Math.min(640, Math.max(540, h - 44))
            return {
                x: Math.max(8, w - panelW - 20),
                y: 8,
                width: Math.min(w - 8, panelW + 12),
                height: Math.min(h - 16, panelH + 12),
                radius: 14
            }
        }
        case "sidebar":
            return {
                x: 8,
                y: 8,
                width: Math.min(384, w - 16),
                height: Math.max(0, h - 16),
                radius: 14
            }
        case "overview": {
            const overviewW = Math.min(w - 96, 1040)
            const overviewH = Math.min(h - 112, 680)
            return root.centeredRect(Math.max(0, overviewW + 12), Math.max(0, overviewH + 12), 14)
        }
        case "wallpaper": {
            const wallpaperW = Math.min(w - 96, 1080)
            const wallpaperH = Math.min(h - 104, 700)
            return root.centeredRect(Math.max(0, wallpaperW + 12), Math.max(0, wallpaperH + 12), 14)
        }
        case "settings": {
            const settingsW = Math.min(w - 96, 1040)
            const settingsH = Math.min(h - 96, 700)
            return root.centeredRect(Math.max(0, settingsW + 12), Math.max(0, settingsH + 12), 14)
        }
        case "context": {
            const islandW = Math.min(520, Math.max(240, w * 0.38))
            return {
                x: (w - islandW) / 2,
                y: RaohaneConfig.barBottom ? Math.max(6, h - 54) : 6,
                width: islandW,
                height: 46,
                radius: 10
            }
        }
        case "session": {
            const sessionW = Math.min(w - 96, 850)
            const sessionH = Math.min(h - 112, 540)
            return root.centeredRect(Math.max(0, sessionW + 12), Math.max(0, sessionH + 12), 14)
        }
        default:
            return root.centeredRect(w * 0.54, h * 0.56, 14)
        }
    }

    function cardPosition(place: string, cardWidth: real, cardHeight: real): var {
        const w = overlayWindow.width
        const h = overlayWindow.height
        const margin = 24

        switch (place) {
        case "topRight": return { x: w - cardWidth - margin, y: 84 }
        case "bottomRight": return { x: w - cardWidth - margin, y: h - cardHeight - 28 }
        case "bottomLeft": return { x: margin, y: h - cardHeight - 28 }
        case "leftCenter": return { x: margin, y: (h - cardHeight) / 2 }
        case "rightCenter": return { x: w - cardWidth - margin, y: (h - cardHeight) / 2 }
        case "bottomCenter": return { x: (w - cardWidth) / 2, y: h - cardHeight - 26 }
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
        const margin = 24
        const gap = 20
        const w = overlayWindow.width
        const h = overlayWindow.height
        const target = overlayWindow.targetRect
        const preferredRect = { x: preferred.x, y: preferred.y, width: cardWidth, height: cardHeight }

        if (!overlayWindow.hasSpotlight || !root.overlaps(preferredRect, target, 10))
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
            if (validX && validY && !root.overlaps(rect, target, 8))
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

            Rectangle {
                anchors.fill: parent
                anchors.margins: -5
                radius: parent.radius + 5
                color: "transparent"
                border.width: 1
                border.color: RaohaneTheme.accentGlow
                opacity: 0.34
            }
        }

        RaohaneSurface {
            id: coachCard
            z: 10

            readonly property var desiredPosition: root.safeCardPosition(root.stepData.card, width, height)

            width: Math.min(400, overlayWindow.width - 40)
            height: Math.min(336, overlayWindow.height - 48)
            x: desiredPosition.x
            y: desiredPosition.y
            surfaceRadius: 12
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            opacity: overlayWindow.cardEntered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 14
                anchors.bottomMargin: 14
                width: 2
                radius: 1
                color: RaohaneTheme.accent
                opacity: 0.82
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 16
                anchors.topMargin: 16
                anchors.bottomMargin: 14
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    RaohaneIcon {
                        text: root.stepData.icon
                        iconSize: 19
                        fill: root.stepData.key === "finish" ? 1 : 0.18
                        color: RaohaneTheme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: root.stepData.eyebrow
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.25
                        }

                        Text {
                            text: qsTr("Step %1 of %2").arg(RaohaneOnboardingState.step + 1).arg(root.steps.length)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    CoachButton {
                        compact: true
                        label: qsTr("Skip tour")
                        onTriggered: RaohaneOnboardingState.skip()
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.stepData.title
                    color: RaohaneTheme.text
                    font.pixelSize: root.stepData.key === "finish" ? 22 : 19
                    font.weight: Font.DemiBold
                    wrapMode: Text.WordWrap
                }

                Text {
                    Layout.fillWidth: true
                    text: root.stepData.description
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                    lineHeight: 1.28
                    wrapMode: Text.WordWrap
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    surfaceRadius: 9
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 9
                        spacing: 8

                        Rectangle {
                            Layout.preferredWidth: 2
                            Layout.preferredHeight: 18
                            radius: 1
                            color: RaohaneTheme.accentSecondary
                            opacity: 0.72
                        }

                        RaohaneIcon {
                            text: root.stepData.key === "dock" ? "mouse" : "lightbulb"
                            iconSize: 14
                            color: RaohaneTheme.accentSecondary
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.stepData.hint
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            lineHeight: 1.18
                            wrapMode: Text.WordWrap
                        }
                    }
                }

                Item { Layout.fillHeight: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    Repeater {
                        model: root.steps.length

                        Rectangle {
                            required property int index
                            Layout.fillWidth: true
                            Layout.preferredHeight: 3
                            radius: 1
                            color: index <= RaohaneOnboardingState.step ? RaohaneTheme.accent : RaohaneTheme.border
                            opacity: index === RaohaneOnboardingState.step ? 1 : 0.48

                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    CoachButton {
                        enabled: RaohaneOnboardingState.step > 0
                        opacity: enabled ? 1 : 0.34
                        icon: "arrow_back"
                        label: qsTr("Back")
                        onTriggered: RaohaneOnboardingState.previous()
                    }

                    Item { Layout.fillWidth: true }

                    CoachButton {
                        emphasized: true
                        icon: root.stepData.key === "finish" ? "check" : "arrow_forward"
                        label: root.stepData.key === "finish" ? qsTr("Enter Raohane") : qsTr("Next")
                        onTriggered: RaohaneOnboardingState.next()
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

    component CoachButton: RaohaneSurface {
        id: button

        required property string label
        property string icon: ""
        property bool emphasized: false
        property bool compact: false
        signal triggered()

        implicitWidth: Math.max(compact ? 72 : 88, buttonRow.implicitWidth + 18)
        implicitHeight: compact ? 28 : 34
        surfaceRadius: 8
        raised: false
        active: emphasized
        transparentIdle: !emphasized
        interactive: enabled
        hovered: buttonMouse.containsMouse
        pressed: buttonMouse.pressed
        hoverScale: 1
        pressedScale: 1
        showSheen: false

        RowLayout {
            id: buttonRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon {
                visible: button.icon.length > 0
                text: button.icon
                iconSize: 13
                fill: button.emphasized ? 1 : 0
                color: button.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: button.label
                color: button.emphasized ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: button.compact ? 7 : 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: buttonMouse
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }
}
