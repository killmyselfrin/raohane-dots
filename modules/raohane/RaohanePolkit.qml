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

        onVisibleChanged: {
            if (visible) {
                dialog.entered = false
                Qt.callLater(() => dialog.entered = true)
            } else {
                dialog.entered = false
            }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark
                ? Qt.rgba(0.005, 0.008, 0.018, 0.72)
                : Qt.rgba(0.14, 0.13, 0.12, 0.28)
            opacity: dialog.entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
        }

        RaohaneSurface {
            id: dialog
            property bool entered: false

            width: Math.min(parent.width - 72, 420)
            implicitHeight: content.implicitHeight + 34
            height: implicitHeight
            anchors.centerIn: parent
            surfaceRadius: 14
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            opacity: entered ? 1 : 0

            Behavior on opacity {
                NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    leftMargin: 16
                    rightMargin: 16
                }
                height: 1
                color: RaohaneTheme.accent
                opacity: 0.38
            }

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
                    margins: 17
                }
                spacing: 9

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    Rectangle {
                        Layout.preferredWidth: 3
                        Layout.preferredHeight: 34
                        radius: 1.5
                        color: RaohaneTheme.accent
                    }

                    RaohaneIcon {
                        text: "security"
                        iconSize: 20
                        fill: 1
                        symbolWeight: 540
                        color: RaohaneTheme.accent
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Authentication required")
                            color: RaohaneTheme.text
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.message.length > 0
                            text: root.message
                            color: RaohaneTheme.textFaint
                            wrapMode: Text.Wrap
                            font.pixelSize: 7
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: supplementaryText.implicitHeight + 14
                    visible: root.supplementaryMessage.length > 0
                    surfaceRadius: 8
                    showSheen: false
                    color: RaohaneTheme.surfaceDeep
                    border.color: root.supplementaryIsError ? RaohaneTheme.critical : RaohaneTheme.borderFaint

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
                        font.pixelSize: 7

                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.prompt
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                }

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 38
                    surfaceRadius: 9
                    hovered: inputField.activeFocus
                    showSheen: false
                    color: RaohaneTheme.surfaceDeep
                    border.color: inputField.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                    TextInput {
                        id: inputField
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        verticalAlignment: TextInput.AlignVCenter
                        enabled: root.interactionAvailable
                        color: RaohaneTheme.text
                        selectionColor: RaohaneTheme.accentSoft
                        selectedTextColor: RaohaneTheme.text
                        echoMode: root.responseVisible ? TextInput.Normal : TextInput.Password
                        font.pixelSize: 9
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
                            leftMargin: 10
                            verticalCenter: parent.verticalCenter
                        }
                        visible: inputField.text.length === 0 && !inputField.activeFocus
                        text: root.prompt
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

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

    component AuthButton: RaohaneSurface {
        id: button
        required property string title
        property bool primary: false
        signal triggered()

        Layout.preferredWidth: primary ? 116 : 88
        Layout.preferredHeight: 32
        surfaceRadius: 8
        active: primary
        transparentIdle: !primary && !hovered
        showSheen: false
        interactive: true
        hovered: pointer.containsMouse || activeFocus
        pressed: pointer.pressed
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: enabled
        opacity: enabled ? 1 : RaohaneMotion.disabledOpacity
        border.color: primary ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        Text {
            anchors.centerIn: parent
            text: button.title
            color: button.primary ? RaohaneTheme.accent
                : button.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
            font.pixelSize: 7
            font.weight: Font.DemiBold

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
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
