pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.services

// On-demand presentation for the resident RaohaneScreenTranslation transaction
// service. OCR/translation continues after this component is destroyed and the
// resident surface router reopens the presentation when a result is ready.
Scope {
    id: root

    property bool copied: false

    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function close(): void {
        RaohaneState.setPrimaryOpen("screenTranslator", false)
    }

    function startTranslation(): void {
        if (!RaohaneScreenTranslation.start())
            return
        root.close()
    }

    Timer {
        id: copiedTimer
        interval: 1200
        repeat: false
        onTriggered: root.copied = false
    }

    PanelWindow {
        id: translatorWindow

        visible: RaohaneState.screenTranslatorOpen
        screen: root.focusedScreen
        color: "black"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        WlrLayershell.namespace: "quickshell:raohane-screen-translator"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        onVisibleChanged: {
            if (visible) {
                translatorPanel.entered = false
                Qt.callLater(() => {
                    translatorPanel.entered = true
                    translatorPanel.forceActiveFocus()
                })
            } else {
                translatorPanel.entered = false
            }
        }

        FocusScope {
            anchors.fill: parent
            focus: translatorWindow.visible

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }

            ScreencopyView {
                anchors.fill: parent
                captureSource: translatorWindow.screen
                live: false
            }

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.dark
                    ? Qt.rgba(0.005, 0.008, 0.018, 0.72)
                    : Qt.rgba(0.18, 0.17, 0.15, 0.26)
                opacity: translatorPanel.entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: translatorPanel.entered ? RaohaneMotion.easeStandard : RaohaneMotion.easeExit
                    }
                }
            }

            RaohaneSurface {
                id: translatorPanel
                property bool entered: false

                anchors.centerIn: parent
                width: Math.min(parent.width - 80, 840)
                height: Math.min(parent.height - 96, 520)
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                showInnerRim: false
                border.color: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0
                focus: translatorWindow.visible

                transform: Translate {
                    y: translatorPanel.entered || !RaohaneMotion.transformMotionEnabled ? 0 : 8
                    Behavior on y {
                        NumberAnimation {
                            duration: RaohaneMotion.relaxed
                            easing.type: translatorPanel.entered ? RaohaneMotion.easeEmphasized : RaohaneMotion.easeExit
                        }
                    }
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: RaohaneMotion.standard
                        easing.type: translatorPanel.entered ? RaohaneMotion.easeStandard : RaohaneMotion.easeExit
                    }
                }

                Rectangle {
                    anchors {
                        top: parent.top
                        left: parent.left
                        right: parent.right
                        leftMargin: RaohaneTheme.panelPadding
                        rightMargin: RaohaneTheme.panelPadding
                    }
                    height: 2
                    color: RaohaneTheme.accent
                    opacity: translatorPanel.entered ? 0.54 : 0

                    Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard } }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: RaohaneTheme.panelPadding
                    spacing: RaohaneTheme.spacing + 1

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        spacing: RaohaneTheme.spacing + 1

                        RaohaneSurface {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            surfaceRadius: RaohaneTheme.radiusLarge
                            active: true
                            raised: false
                            showSheen: false
                            showInnerRim: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "translate"
                                iconSize: 19
                                fill: 1
                                symbolWeight: 560
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                text: qsTr("Screen Translator")
                                color: RaohaneTheme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                                font.letterSpacing: -0.2
                            }

                            Text {
                                Layout.fillWidth: true
                                text: RaohaneScreenTranslation.errorText.length > 0
                                    ? RaohaneScreenTranslation.errorText
                                    : RaohaneScreenTranslation.busy
                                        ? qsTr("Capturing and translating…")
                                        : qsTr("Capture a region and translate recognized text")
                                color: RaohaneScreenTranslation.errorText.length > 0
                                    ? RaohaneTheme.critical
                                    : RaohaneScreenTranslation.busy
                                        ? RaohaneTheme.accent
                                        : RaohaneTheme.textFaint
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        RaohaneSurface {
                            id: languageButton
                            Layout.preferredWidth: 78
                            Layout.preferredHeight: 32
                            surfaceRadius: RaohaneTheme.radius
                            active: true
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            interactive: true
                            enabled: !RaohaneScreenTranslation.busy
                            hovered: languageMouse.containsMouse || activeFocus
                            pressed: languageMouse.pressed
                            activeFocusOnTab: enabled
                            hoverScale: 1
                            pressedScale: 1
                            opacity: enabled ? 1 : RaohaneMotion.disabledOpacity
                            border.color: hovered ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            Row {
                                anchors.centerIn: parent
                                spacing: 5

                                Text {
                                    text: RaohaneScreenTranslation.targetLanguage === "ru" ? "EN" : "RU"
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                RaohaneIcon {
                                    text: "arrow_forward"
                                    iconSize: 11
                                    color: RaohaneTheme.accent
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    text: RaohaneScreenTranslation.targetLanguage.toUpperCase()
                                    color: RaohaneTheme.text
                                    font.pixelSize: 8
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                id: languageMouse
                                anchors.fill: parent
                                enabled: languageButton.enabled
                                hoverEnabled: true
                                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                onPressed: languageButton.forceActiveFocus()
                                onClicked: RaohaneScreenTranslation.toggleTargetLanguage()
                            }

                            Keys.onPressed: event => {
                                if (!languageButton.enabled)
                                    return
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    RaohaneScreenTranslation.toggleTargetLanguage()
                                    event.accepted = true
                                }
                            }
                        }

                        RaohaneIconButton {
                            buttonSize: 32
                            iconSize: 15
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: root.close()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: RaohaneTheme.spacing

                        TextPanel {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            title: qsTr("Recognized text")
                            icon: "document_scanner"
                            value: RaohaneScreenTranslation.sourceText.length > 0
                                ? RaohaneScreenTranslation.sourceText
                                : qsTr("No capture yet. Press Capture area to begin.")
                            empty: RaohaneScreenTranslation.sourceText.length === 0
                        }

                        TextPanel {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            title: RaohaneScreenTranslation.targetLanguage === "ru"
                                ? qsTr("Translation · Russian")
                                : qsTr("Translation · English")
                            icon: "translate"
                            value: RaohaneScreenTranslation.translatedText.length > 0
                                ? RaohaneScreenTranslation.translatedText
                                : qsTr("The translated text will appear here.")
                            empty: RaohaneScreenTranslation.translatedText.length === 0
                            highlighted: RaohaneScreenTranslation.translatedText.length > 0
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 1
                        color: RaohaneTheme.borderFaint
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 38
                        spacing: RaohaneTheme.spacingSmall + 1

                        Text {
                            Layout.fillWidth: true
                            text: RaohaneScreenTranslation.busy
                                ? qsTr("Working in background…")
                                : qsTr("Select a region of the current screen")
                            color: RaohaneScreenTranslation.busy ? RaohaneTheme.accent : RaohaneTheme.textFaint
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }

                        ActionButton {
                            Layout.preferredWidth: 150
                            icon: root.copied ? "check_circle" : "content_copy"
                            title: root.copied ? qsTr("Copied") : qsTr("Copy translation")
                            enabled: RaohaneScreenTranslation.translatedText.length > 0
                            onTriggered: {
                                Quickshell.clipboardText = RaohaneScreenTranslation.translatedText
                                root.copied = true
                                copiedTimer.restart()
                            }
                        }

                        ActionButton {
                            Layout.preferredWidth: 150
                            icon: "crop_free"
                            title: RaohaneScreenTranslation.busy ? qsTr("Working…") : qsTr("Capture area")
                            primary: true
                            enabled: !RaohaneScreenTranslation.busy
                            onTriggered: root.startTranslation()
                        }
                    }
                }
            }
        }
    }

    component TextPanel: RaohaneSurface {
        id: panel

        required property string title
        required property string icon
        required property string value
        property bool empty: false
        property bool highlighted: false

        surfaceRadius: RaohaneTheme.radiusLarge
        raised: false
        showSheen: false
        showInnerRim: false
        color: RaohaneTheme.surfaceDeep
        border.color: highlighted ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: RaohaneTheme.spacing + 2
            spacing: RaohaneTheme.spacingSmall

            RowLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacingSmall

                RaohaneIcon {
                    text: panel.icon
                    iconSize: 14
                    fill: panel.highlighted ? 1 : 0
                    color: panel.highlighted ? RaohaneTheme.accent : RaohaneTheme.textFaint
                }

                Text {
                    Layout.fillWidth: true
                    text: panel.title
                    color: panel.highlighted ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: RaohaneTheme.borderFaint
            }

            TextEdit {
                Layout.fillWidth: true
                Layout.fillHeight: true
                readOnly: true
                selectByMouse: true
                text: panel.value
                color: panel.empty ? RaohaneTheme.textFaint : RaohaneTheme.text
                selectionColor: RaohaneTheme.accentSoft
                selectedTextColor: RaohaneTheme.text
                font.pixelSize: panel.highlighted ? 11 : 10
                font.weight: panel.highlighted ? Font.Medium : Font.Normal
                wrapMode: TextEdit.Wrap
                clip: true
            }
        }
    }

    component ActionButton: RaohaneSurface {
        id: button

        required property string icon
        required property string title
        property bool primary: false
        signal triggered()

        Layout.preferredHeight: 34
        surfaceRadius: RaohaneTheme.radius
        active: primary
        transparentIdle: !primary && !hovered
        raised: false
        showSheen: false
        showInnerRim: false
        interactive: true
        hovered: pointer.containsMouse || activeFocus
        pressed: pointer.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity
        border.color: primary ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Row {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: button.icon
                iconSize: 13
                fill: button.primary || button.hovered ? 1 : 0
                symbolWeight: button.primary ? 550 : button.hovered ? 500 : 420
                color: button.primary ? RaohaneTheme.accent
                    : button.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
            }

            Text {
                text: button.title
                color: button.primary ? RaohaneTheme.accent : RaohaneTheme.text
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: button.forceActiveFocus()
            onClicked: button.triggered()
        }

        Keys.onPressed: event => {
            if (!button.enabled)
                return
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                button.triggered()
                event.accepted = true
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
    }
}
