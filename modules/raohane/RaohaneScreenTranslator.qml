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

    function open(): void {
        RaohaneState.screenTranslatorOpen = true
    }

    function close(): void {
        RaohaneState.screenTranslatorOpen = false
    }

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

        stdout: StdioCollector {
            onStreamFinished: root.applyResult(text)
        }

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
                color: "#4a000000"
            }

            Rectangle {
                anchors.centerIn: parent
                width: Math.min(parent.width - 42, 860)
                height: Math.min(parent.height - 56, 540)
                radius: 26
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border
                clip: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 18
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Rectangle {
                            Layout.preferredWidth: 48
                            Layout.preferredHeight: 48
                            radius: 16
                            color: RaohaneTheme.accentSoft

                            Text {
                                anchors.centerIn: parent
                                text: "文"
                                color: RaohaneTheme.accent
                                font.pixelSize: 22
                                font.bold: true
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Screen Translator")
                                color: RaohaneTheme.text
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.errorText.length > 0
                                    ? root.errorText
                                    : qsTr("Select an area, recognize Russian/English text and translate it without leaving the shell.")
                                color: root.errorText.length > 0 ? "#ff9aa9" : RaohaneTheme.textMuted
                                font.pixelSize: 9
                                wrapMode: Text.WordWrap
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 62
                            Layout.preferredHeight: 36
                            radius: 14
                            color: languageMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                anchors.centerIn: parent
                                text: root.targetLanguage === "ru" ? "→ RU" : "→ EN"
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: languageMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.targetLanguage = root.targetLanguage === "ru" ? "en" : "ru"
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 38
                            Layout.preferredHeight: 38
                            radius: 19
                            color: closeMouse.containsMouse ? "#2affffff" : "#14ffffff"

                            Text {
                                anchors.centerIn: parent
                                text: "×"
                                color: RaohaneTheme.text
                                font.pixelSize: 18
                            }

                            MouseArea {
                                id: closeMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.close()
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: "#3814111c"
                        border.width: 1
                        border.color: RaohaneTheme.border

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            Text {
                                text: qsTr("Recognized text")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            TextEdit {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                readOnly: true
                                selectByMouse: true
                                text: root.sourceText.length > 0 ? root.sourceText : qsTr("No capture yet. Press Capture area to begin.")
                                color: root.sourceText.length > 0 ? RaohaneTheme.text : RaohaneTheme.textMuted
                                selectionColor: RaohaneTheme.accentSoft
                                selectedTextColor: RaohaneTheme.text
                                font.pixelSize: 11
                                wrapMode: TextEdit.Wrap
                                clip: true
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 18
                        color: "#3814111c"
                        border.width: 1
                        border.color: root.translatedText.length > 0 ? RaohaneTheme.accent : RaohaneTheme.border

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 8

                            Text {
                                text: root.targetLanguage === "ru" ? qsTr("Translation · Russian") : qsTr("Translation · English")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                            }

                            TextEdit {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                readOnly: true
                                selectByMouse: true
                                text: root.translatedText.length > 0 ? root.translatedText : qsTr("The translated text will appear here.")
                                color: root.translatedText.length > 0 ? RaohaneTheme.text : RaohaneTheme.textMuted
                                selectionColor: RaohaneTheme.accentSoft
                                selectedTextColor: RaohaneTheme.text
                                font.pixelSize: 12
                                font.weight: Font.Medium
                                wrapMode: TextEdit.Wrap
                                clip: true
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            radius: 14
                            color: captureMouse.containsMouse ? RaohaneTheme.accentSoft : "#22ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.accent

                            Text {
                                anchors.centerIn: parent
                                text: root.busy ? qsTr("Working…") : qsTr("Capture area")
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: captureMouse
                                anchors.fill: parent
                                enabled: !root.busy
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.startTranslation()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 42
                            radius: 14
                            color: copyMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                            border.width: 1
                            border.color: RaohaneTheme.border

                            Text {
                                anchors.centerIn: parent
                                text: root.copied ? qsTr("Copied") : qsTr("Copy translation")
                                color: root.translatedText.length > 0 ? RaohaneTheme.text : RaohaneTheme.textMuted
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            MouseArea {
                                id: copyMouse
                                anchors.fill: parent
                                enabled: root.translatedText.length > 0
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
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
}
