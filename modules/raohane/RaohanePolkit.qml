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
    readonly property bool interactionAvailable: (root.flow?.isResponseRequired ?? false) && !root.submitting
    readonly property string supplementaryMessage: String(root.flow?.supplementaryMessage ?? "").trim()
    readonly property bool supplementaryIsError: root.flow?.supplementaryIsError ?? false
    property bool submitting: false

    readonly property string message: {
        const value = String(root.flow?.message ?? "").trim()
        return value.endsWith(".") ? value.slice(0, -1) : value
    }
    readonly property string prompt: {
        const value = String(root.flow?.inputPrompt ?? "").trim()
        const cleaned = value.endsWith(":") ? value.slice(0, -1) : value
        return cleaned.length > 0 ? cleaned : (root.responseVisible ? qsTr("Input") : qsTr("Password"))
    }

    function focusInput(): void {
        if (root.interactionAvailable)
            Qt.callLater(inputField.forceActiveFocus)
    }

    function preparePrompt(): void {
        root.submitting = false
        inputField.text = ""
        root.focusInput()
    }

    function cancel(): void {
        if (root.flow)
            root.flow.cancelAuthenticationRequest()
    }

    function submit(): void {
        if (!root.flow || !root.interactionAvailable)
            return
        root.submitting = true
        root.flow.submit(inputField.text)
    }

    PolkitAgent {
        id: agent

        onAuthenticationRequestStarted: {
            root.submitting = false
            inputField.text = ""
            root.focusInput()
        }
    }

    Connections {
        target: root.flow
        ignoreUnknownSignals: true

        function onIsResponseRequiredChanged(): void {
            if (root.flow?.isResponseRequired)
                root.preparePrompt()
        }

        function onInputPromptChanged(): void {
            if (root.flow?.isResponseRequired)
                root.preparePrompt()
        }

        function onAuthenticationFailed(): void { root.preparePrompt() }
        function onAuthenticationSucceeded(): void { root.submitting = true }
        function onAuthenticationRequestCancelled(): void {
            root.submitting = false
            inputField.text = ""
        }
    }

    Connections {
        target: agent
        function onIsActiveChanged(): void {
            if (!agent.isActive) {
                root.submitting = false
                inputField.text = ""
            } else {
                root.focusInput()
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
            color: RaohaneTheme.dark ? "#8a000000" : "#465b5750"
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        }

        RaohaneSurface {
            id: dialog
            width: Math.min(parent.width - 72, 450)
            implicitHeight: content.implicitHeight + 40
            height: implicitHeight
            anchors.centerIn: parent
            surfaceRadius: 20
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong

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
                    margins: 20
                }
                spacing: 11

                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 48
                    height: 48
                    radius: 15
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "security"
                        iconSize: 23
                        color: RaohaneTheme.accent
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Authentication required")
                    color: RaohaneTheme.text
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    visible: root.message.length > 0
                    text: root.message
                    color: RaohaneTheme.textMuted
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    font.pixelSize: 9
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: supplementaryText.implicitHeight + 16
                    visible: root.supplementaryMessage.length > 0
                    radius: 10
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: root.supplementaryIsError ? RaohaneTheme.critical : RaohaneTheme.border

                    Text {
                        id: supplementaryText
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            margins: 8
                        }
                        text: root.supplementaryMessage
                        color: root.supplementaryIsError ? RaohaneTheme.critical : RaohaneTheme.textMuted
                        wrapMode: Text.Wrap
                        font.pixelSize: 8
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.prompt
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 44
                    radius: 13
                    color: inputField.activeFocus ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: inputField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                    TextInput {
                        id: inputField
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        enabled: root.interactionAvailable
                        color: RaohaneTheme.text
                        selectionColor: RaohaneTheme.accentSoft
                        selectedTextColor: RaohaneTheme.text
                        echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
                        font.pixelSize: 10
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
                            leftMargin: 12
                            verticalCenter: parent.verticalCenter
                        }
                        visible: inputField.text.length === 0 && !inputField.activeFocus
                        text: root.prompt
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 9
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Item { Layout.fillWidth: true }

                    AuthButton {
                        title: qsTr("Cancel")
                        onTriggered: root.cancel()
                    }
                    AuthButton {
                        title: root.interactionAvailable ? qsTr("Authenticate") : qsTr("Checking…")
                        primary: true
                        enabled: root.interactionAvailable
                        onTriggered: root.submit()
                    }
                }
            }
        }
    }

    component AuthButton: Rectangle {
        id: button
        required property string title
        property bool primary: false
        signal triggered()

        Layout.preferredWidth: primary ? 126 : 96
        Layout.preferredHeight: 36
        radius: 11
        opacity: enabled ? 1 : 0.45
        color: pointer.containsMouse && enabled ? RaohaneTheme.surfaceHover : "transparent"
        border.width: 1
        border.color: primary ? RaohaneTheme.accentBorder : RaohaneTheme.border

        Text {
            anchors.centerIn: parent
            text: button.title
            color: button.primary ? RaohaneTheme.accent : RaohaneTheme.textMuted
            font.pixelSize: 9
            font.weight: Font.DemiBold
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            enabled: button.enabled
            hoverEnabled: true
            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: button.triggered()
        }
    }
}
