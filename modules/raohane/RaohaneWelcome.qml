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

    function phase(value: real, start: real, end: real): real {
        if (end <= start)
            return value >= end ? 1 : 0
        return Math.max(0, Math.min(1, (value - start) / (end - start)))
    }

    function skipWelcome(): void {
        RaohaneOnboardingState.complete()
    }

    PanelWindow {
        id: panelWindow

        property real reveal: 0

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
            if (!visible)
                return
            panelWindow.reveal = 0
            introAnimation.restart()
            Qt.callLater(() => hero.forceActiveFocus())
        }

        NumberAnimation {
            id: introAnimation
            target: panelWindow
            property: "reveal"
            from: 0
            to: 1
            duration: 1450
            easing.type: Easing.OutCubic
        }

        Image {
            anchors.fill: parent
            source: RaohaneConfig.wallpaperPath.length > 0
                ? RaohanePaths.fileUrl(RaohaneConfig.wallpaperPath)
                : RaohanePaths.defaultWallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: RaohaneTheme.dark ? 0.36 : 0.28
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: RaohaneTheme.dark
                        ? Qt.rgba(0.04, 0.045, 0.043, 0.88)
                        : Qt.rgba(0.91, 0.90, 0.87, 0.86)
                }
                GradientStop {
                    position: 0.52
                    color: RaohaneTheme.dark
                        ? Qt.rgba(0.04, 0.045, 0.043, 0.69)
                        : Qt.rgba(0.91, 0.90, 0.87, 0.64)
                }
                GradientStop {
                    position: 1
                    color: RaohaneTheme.dark
                        ? Qt.rgba(0.02, 0.024, 0.023, 0.93)
                        : Qt.rgba(0.88, 0.87, 0.84, 0.91)
                }
            }
        }

        Rectangle {
            width: Math.min(parent.width * 0.54, 840)
            height: width
            radius: width / 2
            x: parent.width - width * 0.68
            y: -height * 0.42
            color: "transparent"
            border.width: 1
            border.color: RaohaneTheme.accentGlow
            opacity: 0.28 * root.phase(panelWindow.reveal, 0.05, 0.48)

            NumberAnimation on rotation {
                running: panelWindow.visible
                from: -7
                to: 7
                duration: 12000
                loops: Animation.Infinite
                easing.type: Easing.InOutSine
            }
        }

        Rectangle {
            width: Math.min(parent.width * 0.36, 540)
            height: width
            radius: width / 2
            x: parent.width * 0.55
            y: parent.height - height * 0.42
            color: RaohaneTheme.accentSoft
            opacity: 0.24 * root.phase(panelWindow.reveal, 0.18, 0.62)

            SequentialAnimation on scale {
                running: panelWindow.visible
                loops: Animation.Infinite
                NumberAnimation { from: 0.96; to: 1.035; duration: 2900; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.035; to: 0.96; duration: 2900; easing.type: Easing.InOutSine }
            }
        }

        Item {
            id: hero

            anchors.fill: parent
            focus: panelWindow.visible

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Math.max(44, parent.width * 0.065)
                    rightMargin: Math.max(44, parent.width * 0.065)
                    topMargin: Math.max(38, parent.height * 0.055)
                    bottomMargin: Math.max(38, parent.height * 0.055)
                }
                spacing: Math.max(34, parent.width * 0.045)

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 620
                    Layout.fillHeight: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 11
                        opacity: root.phase(panelWindow.reveal, 0.02, 0.26)

                        transform: Translate {
                            y: 12 * (1 - root.phase(panelWindow.reveal, 0.02, 0.26))
                        }

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 13
                            color: RaohaneTheme.accentSoft
                            border.width: 1
                            border.color: RaohaneTheme.accentBorder

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "spa"
                                iconSize: 20
                                fill: 0.18
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            spacing: -1

                            Text {
                                text: "RAOHANE"
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                font.letterSpacing: 2.4
                            }

                            Text {
                                text: qsTr("Hyprland · Quickshell")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 10
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "はじめまして"
                        color: RaohaneTheme.accentSecondary
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        font.letterSpacing: 1.2
                        opacity: root.phase(panelWindow.reveal, 0.12, 0.36)

                        transform: Translate {
                            y: 14 * (1 - root.phase(panelWindow.reveal, 0.12, 0.36))
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 12
                        text: qsTr("Welcome to\nRaohane")
                        color: RaohaneTheme.text
                        font.pixelSize: Math.max(48, Math.min(76, panelWindow.width * 0.055))
                        font.weight: Font.DemiBold
                        font.letterSpacing: -2.2
                        lineHeight: 0.91
                        wrapMode: Text.WordWrap
                        opacity: root.phase(panelWindow.reveal, 0.19, 0.47)

                        transform: Translate {
                            y: 22 * (1 - root.phase(panelWindow.reveal, 0.19, 0.47))
                        }
                    }

                    Rectangle {
                        Layout.topMargin: 21
                        Layout.preferredWidth: 92 * root.phase(panelWindow.reveal, 0.32, 0.62)
                        Layout.preferredHeight: 2
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.82
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 560
                        Layout.topMargin: 23
                        text: qsTr("A calm desktop shell that keeps the interface close when you need it — and quiet when you do not.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 16
                        lineHeight: 1.35
                        wrapMode: Text.WordWrap
                        opacity: root.phase(panelWindow.reveal, 0.36, 0.64)

                        transform: Translate {
                            y: 16 * (1 - root.phase(panelWindow.reveal, 0.36, 0.64))
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 570
                        Layout.topMargin: 24
                        spacing: 8
                        opacity: root.phase(panelWindow.reveal, 0.46, 0.72)

                        Repeater {
                            model: [
                                qsTr("11 guided stops"),
                                qsTr("Live interface tour"),
                                RaohaneTheme.presetName
                            ]

                            RaohaneSurface {
                                Layout.preferredWidth: Math.max(124, chipLabel.implicitWidth + 24)
                                Layout.preferredHeight: 32
                                surfaceRadius: 12
                                showSheen: false

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 570
                        Layout.topMargin: 30
                        spacing: 12
                        opacity: root.phase(panelWindow.reveal, 0.55, 0.84)

                        transform: Translate {
                            y: 14 * (1 - root.phase(panelWindow.reveal, 0.55, 0.84))
                        }

                        RaohaneSurface {
                            Layout.preferredWidth: 214
                            Layout.preferredHeight: 50
                            surfaceRadius: 16
                            active: true
                            interactive: true
                            hovered: startPointer.containsMouse
                            pressed: startPointer.pressed
                            showSheen: false

                            Row {
                                anchors.centerIn: parent
                                spacing: 9

                                Text {
                                    text: qsTr("Show me around")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }

                                RaohaneIcon {
                                    text: "arrow_forward"
                                    iconSize: 17
                                    color: RaohaneTheme.accent
                                }
                            }

                            MouseArea {
                                id: startPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneOnboardingState.start()
                            }
                        }

                        RaohaneSurface {
                            Layout.preferredWidth: 152
                            Layout.preferredHeight: 50
                            surfaceRadius: 16
                            transparentIdle: true
                            interactive: true
                            hovered: skipPointer.containsMouse
                            pressed: skipPointer.pressed
                            showSheen: false

                            Text {
                                anchors.centerIn: parent
                                text: qsTr("Explore myself")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }

                            MouseArea {
                                id: skipPointer
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.skipWelcome()
                            }
                        }
                    }

                    Text {
                        Layout.topMargin: 14
                        text: qsTr("The tour uses the real Raohane surfaces, not screenshots.")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 10
                        opacity: root.phase(panelWindow.reveal, 0.68, 0.92)
                    }

                    Item { Layout.fillHeight: true }
                }

                Item {
                    id: previewStage

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 420
                    visible: panelWindow.width >= 960
                    opacity: root.phase(panelWindow.reveal, 0.24, 0.76)

                    transform: Translate {
                        x: 32 * (1 - root.phase(panelWindow.reveal, 0.24, 0.76))
                    }

                    Rectangle {
                        id: previewFrame

                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.94, 570)
                        height: Math.min(parent.height * 0.80, 620)
                        radius: 44
                        color: RaohaneTheme.dark
                            ? Qt.rgba(0.07, 0.075, 0.072, 0.38)
                            : Qt.rgba(0.97, 0.96, 0.93, 0.34)
                        border.width: 1
                        border.color: RaohaneTheme.borderFaint

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 18
                            radius: 32
                            color: RaohaneTheme.background
                            opacity: 0.42
                        }

                        RaohaneSurface {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                topMargin: 34
                                leftMargin: 38
                                rightMargin: 38
                            }
                            height: 46
                            surfaceRadius: 20
                            raised: true
                            showSheen: false

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8

                                Rectangle {
                                    Layout.preferredWidth: 28
                                    Layout.preferredHeight: 28
                                    radius: 10
                                    color: RaohaneTheme.accentSoft

                                    RaohaneIcon {
                                        anchors.centerIn: parent
                                        text: "apps"
                                        iconSize: 14
                                        color: RaohaneTheme.accent
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 48
                                    Layout.preferredHeight: 7
                                    radius: 4
                                    color: RaohaneTheme.borderStrong
                                }

                                Item { Layout.fillWidth: true }

                                RaohaneSurface {
                                    Layout.preferredWidth: 142
                                    Layout.preferredHeight: 30
                                    surfaceRadius: 15
                                    active: true
                                    showSheen: false

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        RaohaneIcon {
                                            text: "spa"
                                            iconSize: 13
                                            color: RaohaneTheme.accent
                                        }

                                        Text {
                                            text: qsTr("Context Island")
                                            color: RaohaneTheme.textMuted
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                RaohaneIcon {
                                    text: "wifi"
                                    iconSize: 15
                                    color: RaohaneTheme.textMuted
                                }

                                RaohaneIcon {
                                    text: "volume_up"
                                    iconSize: 15
                                    color: RaohaneTheme.textMuted
                                }
                            }
                        }

                        RaohaneSurface {
                            width: Math.min(340, parent.width * 0.67)
                            height: 170
                            anchors.centerIn: parent
                            surfaceRadius: 28
                            raised: true
                            showSheen: false

                            SequentialAnimation on scale {
                                running: panelWindow.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 0.985; to: 1.015; duration: 2300; easing.type: Easing.InOutSine }
                                NumberAnimation { from: 1.015; to: 0.985; duration: 2300; easing.type: Easing.InOutSine }
                            }

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 18
                                spacing: 9

                                RowLayout {
                                    Layout.fillWidth: true

                                    RaohaneIcon {
                                        text: "search"
                                        iconSize: 18
                                        color: RaohaneTheme.accent
                                    }

                                    Text {
                                        text: qsTr("Launcher")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "⌘"
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 11
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 1
                                    color: RaohaneTheme.borderFaint
                                }

                                Repeater {
                                    model: 3

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 9

                                        Rectangle {
                                            Layout.preferredWidth: 26
                                            Layout.preferredHeight: 26
                                            radius: 9
                                            color: RaohaneTheme.surfaceSubtle
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 90 + index * 24
                                            Layout.preferredHeight: 7
                                            radius: 4
                                            color: index === 0 ? RaohaneTheme.accentSoft : RaohaneTheme.border
                                        }

                                        Item { Layout.fillWidth: true }
                                    }
                                }
                            }
                        }

                        RaohaneSurface {
                            width: 150
                            height: 230
                            anchors {
                                right: parent.right
                                rightMargin: 30
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: 52
                            }
                            surfaceRadius: 26
                            raised: true
                            showSheen: false
                            rotation: 1.2

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 9

                                Text {
                                    text: qsTr("Quick Controls")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                }

                                Repeater {
                                    model: ["wifi", "bluetooth", "dark_mode", "volume_up"]

                                    RaohaneSurface {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 34
                                        surfaceRadius: 11
                                        active: index === 0
                                        showSheen: false

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 7

                                            RaohaneIcon {
                                                text: modelData
                                                iconSize: 14
                                                color: index === 0 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                            }

                                            Rectangle {
                                                width: 45
                                                height: 6
                                                radius: 3
                                                color: index === 0 ? RaohaneTheme.accentSoft : RaohaneTheme.border
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RaohaneSurface {
                            width: Math.min(300, parent.width * 0.58)
                            height: 62
                            anchors {
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                                bottomMargin: 36
                            }
                            surfaceRadius: 31
                            raised: true
                            showSheen: false

                            Row {
                                anchors.centerIn: parent
                                spacing: 12

                                Repeater {
                                    model: ["folder", "language", "terminal", "music_note", "settings"]

                                    Rectangle {
                                        width: 36
                                        height: 36
                                        radius: 12
                                        color: index === 2 ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceSubtle

                                        RaohaneIcon {
                                            anchors.centerIn: parent
                                            text: modelData
                                            iconSize: 17
                                            color: index === 2 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                                rightMargin: 30
                                bottomMargin: 18
                            }
                            text: qsTr("LIVE PREVIEW")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.6
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
}
