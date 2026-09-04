pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    PanelWindow {
        id: panelWindow

        property bool entered: false

        visible: (RaohaneState.welcomeOpen && !RaohaneI18n.languageChosen) || RaohaneI18n.pickerOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-language-welcome"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            panelWindow.entered = false
            if (visible) {
                Qt.callLater(() => {
                    panelWindow.entered = true
                    card.forceActiveFocus()
                })
            }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark ? Qt.rgba(0.02, 0.025, 0.024, 0.72) : Qt.rgba(0.32, 0.31, 0.28, 0.32)
            opacity: panelWindow.entered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard } }

            MouseArea {
                anchors.fill: parent
                enabled: RaohaneI18n.languageChosen
                onClicked: RaohaneI18n.closePicker()
            }
        }

        RaohaneSurface {
            id: card

            width: Math.min(parent.width - 64, 570)
            height: 430
            anchors.centerIn: parent
            surfaceRadius: 30
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            opacity: panelWindow.entered ? 1 : 0
            scale: panelWindow.entered ? 1 : 0.98
            focus: panelWindow.visible

            transform: Translate {
                y: panelWindow.entered ? 0 : 16
                Behavior on y { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized } }
            }
            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard } }
            Behavior on scale { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 34
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 11

                    RaohaneSurface {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        surfaceRadius: 14
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "language"
                            iconSize: 21
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        Text {
                            text: "RAOHANE"
                            color: RaohaneTheme.text
                            font.pixelSize: 11
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.8
                        }
                        Text {
                            text: "はじめまして · First setup"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    RaohaneIconButton {
                        visible: RaohaneI18n.languageChosen
                        buttonSize: 30
                        iconSize: 15
                        icon: "close"
                        transparentIdle: true
                        showSheen: false
                        onClicked: RaohaneI18n.closePicker()
                    }
                }

                Item { Layout.preferredHeight: 28 }

                Text {
                    Layout.fillWidth: true
                    text: RaohaneI18n.tr("Choose your language")
                    color: RaohaneTheme.text
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.7
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    text: RaohaneI18n.tr("This language will be used across the entire Raohane shell.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 11
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                }

                Item { Layout.preferredHeight: 24 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    LanguageCard {
                        Layout.fillWidth: true
                        code: "en_US"
                        title: "English"
                        subtitle: "English (US)"
                        glyph: "EN"
                    }

                    LanguageCard {
                        Layout.fillWidth: true
                        code: "ru_RU"
                        title: "Русский"
                        subtitle: "Русский язык"
                        glyph: "RU"
                    }
                }

                Item { Layout.fillHeight: true }

                Text {
                    Layout.fillWidth: true
                    text: RaohaneI18n.tr("You can change it later in Settings.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape && RaohaneI18n.languageChosen) {
                    RaohaneI18n.closePicker()
                    event.accepted = true
                }
            }
        }

        IpcHandler {
            target: "language"
            function open(): void { RaohaneI18n.openPicker() }
            function close(): void { RaohaneI18n.closePicker() }
            function current(): string { return RaohaneI18n.language }
            function set(code: string): void { RaohaneI18n.setLanguage(code) }
        }
    }

    component LanguageCard: RaohaneSurface {
        id: languageCard

        required property string code
        required property string title
        required property string subtitle
        required property string glyph

        Layout.preferredHeight: 150
        surfaceRadius: 20
        active: RaohaneI18n.languageChosen && RaohaneI18n.language === code
        interactive: true
        hovered: pointer.containsMouse || activeFocus
        pressed: pointer.pressed
        showSheen: false
        activeFocusOnTab: true

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 5

            Rectangle {
                Layout.preferredWidth: 48
                Layout.preferredHeight: 34
                radius: 11
                color: RaohaneTheme.accentSoft
                border.width: 1
                border.color: RaohaneTheme.accentBorder

                Text {
                    anchors.centerIn: parent
                    text: languageCard.glyph
                    color: RaohaneTheme.accent
                    font.pixelSize: 10
                    font.weight: Font.Bold
                    font.letterSpacing: 0.8
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: languageCard.title
                color: RaohaneTheme.text
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: languageCard.subtitle
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: languageCard.forceActiveFocus()
            onClicked: RaohaneI18n.setLanguage(languageCard.code)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                RaohaneI18n.setLanguage(languageCard.code)
                event.accepted = true
            }
        }
    }
}
