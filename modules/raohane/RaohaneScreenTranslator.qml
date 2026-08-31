pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

Scope {
    id: root

    property string targetLanguage: "ru"
    property string sourceText: ""
    property string translatedText: ""
    property string errorText: ""
    property bool copied: false

    readonly property bool busy: translateProcess.running || captureDelay.running
    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function open(): void { RaohaneState.setPrimaryOpen("screenTranslator", true) }
    function close(): void { RaohaneState.setPrimaryOpen("screenTranslator", false) }

    function startTranslation(): void {
        if (root.busy)
            return
        root.errorText = ""
        root.copied = false
        root.close()
        captureDelay.restart()
    }

    function applyResult(payload: string): void {
        let result
        try {
            result = JSON.parse(String(payload ?? ""))
        } catch (error) {
            root.sourceText = ""
            root.translatedText = ""
            root.errorText = qsTr("The translation backend returned invalid data.")
            root.open()
            return
        }

        root.targetLanguage = String(result?.target ?? root.targetLanguage)
        root.sourceText = String(result?.source ?? "")
        root.translatedText = String(result?.translation ?? "")
        root.errorText = result?.ok ? "" : String(result?.error ?? qsTr("Translation failed."))
        root.open()
    }

    Timer {
        id: captureDelay
        interval: 140
        repeat: false
        onTriggered: translateProcess.exec([
            Quickshell.shellPath("scripts/screen-translate.sh"),
            root.targetLanguage
        ])
    }

    Process {
        id: translateProcess
        stdout: StdioCollector { onStreamFinished: root.applyResult(text) }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0 && !RaohaneState.screenTranslatorOpen) {
                root.errorText = qsTr("The screen translation process exited unexpectedly.")
                root.open()
            }
        }
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
                Qt.callLater(() => translatorPanel.entered = true)
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
                color: RaohaneTheme.dark ? "#66000000" : "#385b5750"
                opacity: translatorPanel.entered ? 1 : 0

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }
            }

            RaohaneSurface {
                id: translatorPanel
                property bool entered: false

                anchors.centerIn: parent
                width: Math.min(parent.width - 64, 820)
                height: Math.min(parent.height - 72, 520)
                surfaceRadius: RaohaneTheme.radiusHero
                raised: true
                showSheen: false
                border.color: RaohaneTheme.borderStrong
                clip: true
                opacity: entered ? 1 : 0
                scale: entered ? 1 : 0.982

                transform: Translate {
                    y: translatorPanel.entered ? 0 : 12
                    Behavior on y {
                        NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                    }
                }

                Behavior on opacity {
                    NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
                }
                Behavior on scale {
                    NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        spacing: 9

                        RaohaneSurface {
                            width: 34
                            height: 34
                            surfaceRadius: 11
                            active: true
                            showSheen: false

                            RaohaneIcon {
                                anchors.centerIn: parent
                                text: "translate"
                                iconSize: 18
                                fill: 1
                                symbolWeight: 540
                                color: RaohaneTheme.accent
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                text: qsTr("Screen Translator")
                                color: RaohaneTheme.text
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.errorText.length > 0
                                    ? root.errorText
                                    : qsTr("Capture an area and translate recognized text")
                                color: root.errorText.length > 0 ? RaohaneTheme.critical : RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight

                                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                            }
                        }

                        RaohaneSurface {
                            id: languageButton
                            width: 58
                            height: 30
                            surfaceRadius: 9
                            transparentIdle: true
                            showSheen: false
                            interactive: true
                            hovered: languageMouse.containsMouse || activeFocus
                            pressed: languageMouse.pressed
                            hoverScale: 1.015
                            pressedScale: RaohaneMotion.pressScale
                            activeFocusOnTab: true

                            Text {
                                anchors.centerIn: parent
                                text: root.targetLanguage === "ru" ? "→ RU" : "→ EN"
                                color: languageButton.hovered ? RaohaneTheme.accent : RaohaneTheme.text
                                font.pixelSize: 8
                                font.weight: Font.DemiBold

                                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                            }

                            MouseArea {
                                id: languageMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: languageButton.forceActiveFocus()
                                onClicked: root.targetLanguage = root.targetLanguage === "ru" ? "en" : "ru"
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.targetLanguage = root.targetLanguage === "ru" ? "en" : "ru"
                                    event.accepted = true
                                }
                            }
                        }

                        RaohaneIconButton {
                            buttonSize: 30
                            iconSize: 15
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
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
                        spacing: 8

                        TextPanel {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            title: qsTr("Recognized text")
                            value: root.sourceText.length > 0 ? root.sourceText : qsTr("No capture yet. Press Capture area to begin.")
                            empty: root.sourceText.length === 0
                        }

                        TextPanel {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            title: root.targetLanguage === "ru" ? qsTr("Translation · Russian") : qsTr("Translation · English")
                            value: root.translatedText.length > 0 ? root.translatedText : qsTr("The translated text will appear here.")
                            empty: root.translatedText.length === 0
                            highlighted: root.translatedText.length > 0
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        TranslateButton {
                            Layout.fillWidth: true
                            icon: "crop_free"
                            title: root.busy ? qsTr("Working…") : qsTr("Capture area")
                            primary: true
                            enabled: !root.busy
                            onTriggered: root.startTranslation()
                        }

                        TranslateButton {
                            Layout.preferredWidth: 158
                            icon: root.copied ? "check_circle" : "content_copy"
                            title: root.copied ? qsTr("Copied") : qsTr("Copy translation")
                            enabled: root.translatedText.length > 0
                            onTriggered: {
                                Quickshell.clipboardText = root.translatedText
                                root.copied = true
                                copiedTimer.restart()
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "screenTranslator"
        function translate(): void { root.startTranslation() }
        function open(): void { root.open() }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "screenTranslate"
        description: "Select a region and translate its text with Raohane"
        onPressed: root.startTranslation()
    }

    component TextPanel: RaohaneSurface {
        id: panel
        required property string title
        required property string value
        property bool empty: false
        property bool highlighted: false
        surfaceRadius: 15
        raised: false
        showSheen: false
        border.color: highlighted ? RaohaneTheme.accentBorder : RaohaneTheme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 7

            Text {
                text: panel.title
                color: panel.highlighted ? RaohaneTheme.accent : RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: Font.DemiBold

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            TextEdit {
                Layout.fillWidth: true
                Layout.fillHeight: true
                readOnly: true
                selectByMouse: true
                text: panel.value
                color: panel.empty ? RaohaneTheme.textMuted : RaohaneTheme.text
                selectionColor: RaohaneTheme.accentSoft
                selectedTextColor: RaohaneTheme.text
                font.pixelSize: panel.highlighted ? 11 : 10
                font.weight: panel.highlighted ? Font.Medium : Font.Normal
                wrapMode: TextEdit.Wrap
                clip: true
            }
        }
    }

    component TranslateButton: RaohaneSurface {
        id: button
        required property string icon
        required property string title
        property bool primary: false
        signal triggered()

        Layout.preferredHeight: 38
        surfaceRadius: 11
        active: primary
        transparentIdle: !primary
        showSheen: false
        interactive: true
        hovered: pointer.containsMouse || activeFocus
        pressed: pointer.pressed
        hoverScale: 1.01
        pressedScale: RaohaneMotion.pressScale
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

        Row {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: button.icon
                iconSize: 14
                fill: button.primary || button.hovered ? 1 : 0
                symbolWeight: button.pressed ? 560 : button.primary || button.hovered ? 520 : 430
                color: button.primary ? RaohaneTheme.accent
                    : button.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
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
