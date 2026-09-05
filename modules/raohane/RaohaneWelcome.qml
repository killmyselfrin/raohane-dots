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
                hero.forceActiveFocus()
            })
        }

        Image {
            anchors.fill: parent
            source: RaohaneConfig.wallpaperPath.length > 0
                ? RaohanePaths.fileUrl(RaohaneConfig.wallpaperPath)
                : RaohanePaths.defaultWallpaperUrl
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: true
            opacity: RaohaneTheme.dark ? 0.34 : 0.27
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0.025, 0.03, 0.029, 0.84)
                : Qt.rgba(0.90, 0.89, 0.86, 0.82)
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop {
                    position: 0
                    color: RaohaneTheme.dark
                        ? Qt.rgba(0.03, 0.035, 0.033, 0.20)
                        : Qt.rgba(0.96, 0.95, 0.92, 0.18)
                }
                GradientStop {
                    position: 0.62
                    color: "transparent"
                }
                GradientStop {
                    position: 1
                    color: RaohaneTheme.dark
                        ? Qt.rgba(0.01, 0.015, 0.014, 0.28)
                        : Qt.rgba(0.80, 0.79, 0.76, 0.18)
                }
            }
        }

        Item {
            id: hero

            anchors.fill: parent
            focus: panelWindow.visible
            opacity: panelWindow.entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: Math.max(34, parent.width * 0.055)
                    rightMargin: Math.max(34, parent.width * 0.055)
                    topMargin: Math.max(30, parent.height * 0.05)
                    bottomMargin: Math.max(30, parent.height * 0.05)
                }
                spacing: Math.max(30, parent.width * 0.04)

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.maximumWidth: 590
                    Layout.fillHeight: true
                    spacing: 0

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        Rectangle {
                            Layout.preferredWidth: 2
                            Layout.preferredHeight: 28
                            radius: 1
                            color: RaohaneTheme.accent
                        }

                        RaohaneIcon {
                            text: "spa"
                            iconSize: 18
                            fill: 0.2
                            color: RaohaneTheme.accent
                        }

                        ColumnLayout {
                            spacing: 0

                            Text {
                                text: "RAOHANE"
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                font.letterSpacing: 2.4
                            }

                            Text {
                                text: qsTr("Hyprland · Quickshell")
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    Item { Layout.fillHeight: true }

                    Text {
                        text: "はじめまして"
                        color: RaohaneTheme.accentSecondary
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        font.letterSpacing: 1.1
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.topMargin: 8
                        text: qsTr("Welcome to\nRaohane")
                        color: RaohaneTheme.text
                        font.pixelSize: Math.max(44, Math.min(66, panelWindow.width * 0.048))
                        font.weight: Font.DemiBold
                        font.letterSpacing: -1.8
                        lineHeight: 0.93
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        Layout.topMargin: 16
                        Layout.preferredWidth: 74
                        Layout.preferredHeight: 2
                        radius: 1
                        color: RaohaneTheme.accent
                        opacity: 0.82
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 520
                        Layout.topMargin: 18
                        text: qsTr("A calm desktop shell that keeps the interface close when you need it — and quiet when you do not.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 14
                        lineHeight: 1.32
                        wrapMode: Text.WordWrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 520
                        Layout.topMargin: 20
                        spacing: 7

                        Repeater {
                            model: [
                                qsTr("%1 guided stops").arg(RaohaneOnboardingState.totalSteps),
                                qsTr("Live interface tour"),
                                RaohaneTheme.presetName
                            ]

                            RaohaneSurface {
                                Layout.preferredWidth: Math.max(112, chipLabel.implicitWidth + 20)
                                Layout.preferredHeight: 28
                                surfaceRadius: 8
                                raised: false
                                showSheen: false
                                border.color: RaohaneTheme.borderFaint

                                Text {
                                    id: chipLabel
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 8
                                    font.weight: Font.Medium
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 520
                        Layout.topMargin: 24
                        spacing: 9

                        WelcomeButton {
                            Layout.preferredWidth: 180
                            emphasized: true
                            label: qsTr("Show me around")
                            icon: "arrow_forward"
                            onTriggered: RaohaneOnboardingState.start()
                        }

                        WelcomeButton {
                            Layout.preferredWidth: 142
                            label: qsTr("Explore myself")
                            icon: "explore"
                            onTriggered: root.skipWelcome()
                        }
                    }

                    Text {
                        Layout.topMargin: 11
                        text: qsTr("The tour uses the real Raohane surfaces, not screenshots.")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }

                    Item { Layout.fillHeight: true }
                }

                Item {
                    id: previewStage

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: 390
                    visible: panelWindow.width >= 920

                    Rectangle {
                        id: previewFrame

                        anchors.centerIn: parent
                        width: Math.min(parent.width * 0.95, 540)
                        height: Math.min(parent.height * 0.78, 560)
                        radius: 14
                        color: RaohaneTheme.dark
                            ? Qt.rgba(0.055, 0.06, 0.058, 0.50)
                            : Qt.rgba(0.96, 0.95, 0.92, 0.48)
                        border.width: 1
                        border.color: RaohaneTheme.borderFaint
                        clip: true

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.topMargin: 14
                            anchors.bottomMargin: 14
                            width: 2
                            radius: 1
                            color: RaohaneTheme.accent
                            opacity: 0.68
                        }

                        RaohaneSurface {
                            anchors {
                                top: parent.top
                                left: parent.left
                                right: parent.right
                                topMargin: 20
                                leftMargin: 22
                                rightMargin: 22
                            }
                            height: 38
                            surfaceRadius: 9
                            raised: false
                            showSheen: false
                            border.color: RaohaneTheme.borderFaint

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                spacing: 7

                                RaohaneIcon {
                                    text: "apps"
                                    iconSize: 13
                                    color: RaohaneTheme.accent
                                }

                                Rectangle {
                                    Layout.preferredWidth: 36
                                    Layout.preferredHeight: 4
                                    radius: 2
                                    color: RaohaneTheme.borderStrong
                                }

                                Item { Layout.fillWidth: true }

                                Row {
                                    spacing: 5

                                    RaohaneIcon { text: "spa"; iconSize: 12; color: RaohaneTheme.accent }
                                    Text { text: qsTr("Context Island"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                                }

                                Item { Layout.fillWidth: true }

                                RaohaneIcon { text: "wifi"; iconSize: 13; color: RaohaneTheme.textMuted }
                                RaohaneIcon { text: "volume_up"; iconSize: 13; color: RaohaneTheme.textMuted }
                            }
                        }

                        RaohaneSurface {
                            width: Math.min(320, parent.width * 0.68)
                            height: 150
                            anchors.centerIn: parent
                            surfaceRadius: 11
                            raised: false
                            showSheen: false
                            border.color: RaohaneTheme.borderStrong

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 13
                                spacing: 7

                                RowLayout {
                                    Layout.fillWidth: true

                                    RaohaneIcon {
                                        text: "search"
                                        iconSize: 16
                                        color: RaohaneTheme.accent
                                    }

                                    Text {
                                        text: qsTr("Launcher")
                                        color: RaohaneTheme.text
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        text: "⌘"
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 9
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
                                        spacing: 8

                                        Rectangle {
                                            Layout.preferredWidth: 3
                                            Layout.preferredHeight: 13
                                            radius: 1
                                            color: index === 0 ? RaohaneTheme.accent : RaohaneTheme.borderStrong
                                            opacity: index === 0 ? 1 : 0.5
                                        }

                                        RaohaneIcon {
                                            text: index === 0 ? "terminal" : index === 1 ? "settings" : "folder"
                                            iconSize: 13
                                            color: index === 0 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        }

                                        Rectangle {
                                            Layout.preferredWidth: 72 + index * 20
                                            Layout.preferredHeight: 4
                                            radius: 2
                                            color: index === 0 ? RaohaneTheme.accentSoft : RaohaneTheme.border
                                        }

                                        Item { Layout.fillWidth: true }
                                    }
                                }
                            }
                        }

                        RaohaneSurface {
                            width: 138
                            height: 176
                            anchors {
                                right: parent.right
                                rightMargin: 18
                                verticalCenter: parent.verticalCenter
                                verticalCenterOffset: 70
                            }
                            surfaceRadius: 10
                            raised: false
                            showSheen: false
                            border.color: RaohaneTheme.borderFaint

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 6

                                Text {
                                    text: qsTr("Quick Controls")
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                }

                                Repeater {
                                    model: ["wifi", "bluetooth", "dark_mode", "volume_up"]

                                    RaohaneSurface {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 27
                                        surfaceRadius: 7
                                        active: index === 0
                                        raised: false
                                        showSheen: false

                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 6

                                            RaohaneIcon {
                                                text: modelData
                                                iconSize: 12
                                                color: index === 0 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                            }

                                            Rectangle {
                                                width: 34
                                                height: 3
                                                radius: 2
                                                color: index === 0 ? RaohaneTheme.accentSoft : RaohaneTheme.border
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        RaohaneSurface {
                            width: Math.min(270, parent.width * 0.58)
                            height: 48
                            anchors {
                                bottom: parent.bottom
                                horizontalCenter: parent.horizontalCenter
                                bottomMargin: 22
                            }
                            surfaceRadius: 10
                            raised: false
                            showSheen: false
                            border.color: RaohaneTheme.borderFaint

                            Row {
                                anchors.centerIn: parent
                                spacing: 9

                                Repeater {
                                    model: ["folder", "language", "terminal", "music_note", "settings"]

                                    RaohaneIcon {
                                        text: modelData
                                        iconSize: 16
                                        fill: index === 2 ? 1 : 0
                                        color: index === 2 ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                    }
                                }
                            }
                        }

                        Text {
                            anchors {
                                right: parent.right
                                bottom: parent.bottom
                                rightMargin: 15
                                bottomMargin: 8
                            }
                            text: qsTr("LIVE PREVIEW")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.4
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

    component WelcomeButton: RaohaneSurface {
        id: button

        required property string label
        required property string icon
        property bool emphasized: false
        signal triggered()

        Layout.preferredHeight: 42
        surfaceRadius: 9
        raised: false
        active: emphasized
        transparentIdle: !emphasized
        interactive: true
        hovered: pointer.containsMouse
        pressed: pointer.pressed
        showSheen: false
        hoverScale: 1
        pressedScale: 1

        Row {
            anchors.centerIn: parent
            spacing: 7

            Text {
                text: button.label
                color: button.emphasized ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 10
                font.weight: Font.DemiBold
            }

            RaohaneIcon {
                text: button.icon
                iconSize: 14
                fill: button.emphasized ? 1 : 0
                color: button.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: button.triggered()
        }
    }
}
