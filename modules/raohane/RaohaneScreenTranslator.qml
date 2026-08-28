import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

// Native screen-translation shell. It owns the active compositor surface now,
// so the old GoogleCloud/common-widget graph is no longer a boot dependency.
// OCR/translation backend migration remains a separate feature pass.
Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(candidate => candidate.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]

    function open(): void { RaohaneState.screenTranslatorOpen = true }
    function close(): void { RaohaneState.screenTranslatorOpen = false }

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
                color: "#26000000"
            }

            Rectangle {
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.bottom
                    bottomMargin: 28
                }
                width: Math.min(parent.width - 40, 620)
                height: 96
                radius: 24
                color: RaohaneTheme.glassStrong
                border.width: 1
                border.color: RaohaneTheme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

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
                        spacing: 2
                        Text {
                            text: qsTr("Screen Translator")
                            color: RaohaneTheme.text
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                        }
                        Text {
                            Layout.fillWidth: true
                            text: qsTr("The native capture surface is active. OCR/translation backend migration is the next step; press Esc to close.")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 40
                        Layout.preferredHeight: 40
                        radius: 20
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
            }
        }
    }

    IpcHandler {
        target: "screenTranslator"
        function translate(): void { root.open() }
        function close(): void { root.close() }
    }

    CompositorGlobalShortcut {
        name: "screenTranslate"
        description: "Open the Raohane screen translation surface"
        onPressed: root.open()
    }
}
