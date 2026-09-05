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

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            MouseArea {
                anchors.fill: parent
                enabled: RaohaneI18n.languageChosen
                onClicked: RaohaneI18n.closePicker()
            }
        }

        RaohaneSurface {
            id: card

            width: Math.min(parent.width - 48, 500)
            height: 336
            anchors.centerIn: parent
            surfaceRadius: 12
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            opacity: panelWindow.entered ? 1 : 0
            focus: panelWindow.visible

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
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 22
                anchors.rightMargin: 20
                anchors.topMargin: 18
                anchors.bottomMargin: 17
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    RaohaneIcon {
                        text: "language"
                        iconSize: 18
                        fill: 1
                        color: RaohaneTheme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            text: "RAOHANE"
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.9
                        }

                        Text {
                            text: "はじめまして · First setup"
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }

                    RaohaneIconButton {
                        visible: RaohaneI18n.languageChosen
                        buttonSize: 28
                        iconSize: 14
                        icon: "close"
                        transparentIdle: true
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        onClicked: RaohaneI18n.closePicker()
                    }
                }

                Item { Layout.preferredHeight: 20 }

                Text {
                    Layout.fillWidth: true
                    text: RaohaneI18n.tr("Choose your language")
                    color: RaohaneTheme.text
                    font.pixelSize: 22
                    font.weight: Font.DemiBold
                    font.letterSpacing: -0.4
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 5
                    text: RaohaneI18n.tr("This language will be used across the entire Raohane shell.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    lineHeight: 1.2
                    wrapMode: Text.WordWrap
                }

                Item { Layout.preferredHeight: 18 }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

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

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 10
                    text: RaohaneI18n.tr("You can change it later in Settings.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
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
        readonly property bool selected: RaohaneI18n.languageChosen && RaohaneI18n.language === code

        Layout.preferredHeight: 92
        surfaceRadius: 9
        active: selected
        interactive: true
        hovered: pointer.containsMouse || activeFocus
        pressed: pointer.pressed
        showSheen: false
        activeFocusOnTab: true
        hoverScale: 1
        pressedScale: 1
        border.color: selected
            ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Rectangle {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 2
            height: languageCard.selected ? 30 : languageCard.hovered ? 18 : 8
            radius: 1
            color: RaohaneTheme.accent
            opacity: languageCard.selected ? 1 : languageCard.hovered ? 0.42 : 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 10
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 28
                radius: 7
                color: RaohaneTheme.accentSoft
                border.width: 1
                border.color: RaohaneTheme.accentBorder

                Text {
                    anchors.centerIn: parent
                    text: languageCard.glyph
                    color: RaohaneTheme.accent
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    font.letterSpacing: 0.7
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: languageCard.title
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: languageCard.subtitle
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                }
            }

            RaohaneIcon {
                visible: languageCard.selected
                text: "check_circle"
                iconSize: 16
                fill: 1
                color: RaohaneTheme.accent
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
