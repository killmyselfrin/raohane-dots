pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Polkit
import Quickshell.Wayland

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var flow: agent.flow
    readonly property bool responseVisible: root.flow?.responseVisible ?? false
    property bool interactionAvailable: false

    readonly property string message: {
        const value = String(root.flow?.message ?? "").trim()
        return value.endsWith(".") ? value.slice(0, -1) : value
    }
    readonly property string prompt: {
        const value = String(root.flow?.inputPrompt ?? "").trim()
        const cleaned = value.endsWith(":") ? value.slice(0, -1) : value
        return cleaned.length > 0 ? cleaned : (root.responseVisible ? qsTr("Input") : qsTr("Password"))
    }

    function cancel(): void {
        if (root.flow)
            root.flow.cancelAuthenticationRequest()
    }

    function submit(): void {
        if (!root.flow || !root.interactionAvailable)
            return
        root.flow.submit(inputField.text)
        root.interactionAvailable = false
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.interactionAvailable = true
            inputField.text = ""
            Qt.callLater(inputField.forceActiveFocus)
        }
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed(): void {
            root.interactionAvailable = true
            inputField.text = ""
            Qt.callLater(inputField.forceActiveFocus)
        }
    }

    Connections {
        target: agent

        function onIsActiveChanged(): void {
            if (!agent.isActive) {
                root.interactionAvailable = false
                inputField.text = ""
            }
        }
    }

    PanelWindow {
        id: authWindow

        screen: root.focusedScreen
        visible: agent.isActive
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-polkit"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: "#b3080710"

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }
        }

        Rectangle {
            id: dialog
            width: Math.min(parent.width - 72, 470)
            height: content.implicitHeight + 44
            anchors.centerIn: parent
            radius: 26
            color: RaohaneTheme.glassStrong
            border.width: 1
            border.color: RaohaneTheme.border

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.cancel()
                    event.accepted = true
                }
            }

            ColumnLayout {
                id: content
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 22
                }
                spacing: 13

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 54
                    height: 54
                    radius: 18
                    color: RaohaneTheme.accentSoft
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "security"
                        iconSize: 27
                        color: RaohaneTheme.accent
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Authentication required")
                    color: RaohaneTheme.text
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.message.length > 0
                    text: root.message
                    color: RaohaneTheme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    font.pixelSize: 10
                }

                Text {
                    Layout.fillWidth: true
                    text: root.prompt
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 14
                    color: "#74120f19"
                    border.width: 1
                    border.color: inputField.activeFocus ? RaohaneTheme.accent : RaohaneTheme.border

                    TextInput {
                        id: inputField
                        anchors.fill: parent
                        anchors.leftMargin: 13
                        anchors.rightMargin: 13
                        verticalAlignment: TextInput.AlignVCenter
                        enabled: root.interactionAvailable
                        color: RaohaneTheme.text
                        selectionColor: RaohaneTheme.accentSoft
                        selectedTextColor: RaohaneTheme.text
                        echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
                        font.pixelSize: 11
                        clip: true
                        onAccepted: root.submit()

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.cancel()
                                event.accepted = true
                            }
                        }
                    }

                    Text {
                        anchors {
                            left: parent.left
                            leftMargin: 13
                            verticalCenter: parent.verticalCenter
                        }
                        visible: inputField.text.length === 0 && !inputField.activeFocus
                        text: root.prompt
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 10
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: 104
                        height: 38
                        radius: 13
                        color: cancelMouse.containsMouse ? "#24ffffff" : "#15ffffff"
                        border.width: 1
                        border.color: RaohaneTheme.border

                        Text {
                            anchors.centerIn: parent
                            text: qsTr("Cancel")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: cancelMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.cancel()
                        }
                    }

                    Rectangle {
                        width: 128
                        height: 38
                        radius: 13
                        opacity: root.interactionAvailable ? 1 : 0.5
                        color: authMouse.containsMouse && root.interactionAvailable ? "#5bc879ff" : RaohaneTheme.accentSoft
                        border.width: 1
                        border.color: RaohaneTheme.accent

                        Text {
                            anchors.centerIn: parent
                            text: root.interactionAvailable ? qsTr("Authenticate") : qsTr("Checking…")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        MouseArea {
                            id: authMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            enabled: root.interactionAvailable
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.submit()
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "RAOHANE / POLKIT"
                    color: RaohaneTheme.textMuted
                    horizontalAlignment: Text.AlignRight
                    font.pixelSize: 8
                    font.letterSpacing: 0.8
                    font.weight: Font.DemiBold
                }
            }
        }
    }
}
