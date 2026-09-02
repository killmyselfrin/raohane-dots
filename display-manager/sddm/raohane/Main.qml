import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import SddmComponents 2.0

Item {
    id: root

    width: Screen.width
    height: Screen.height

    property date now: new Date()
    property string statusMessage: ""
    property bool loginPending: false
    property bool entered: false

    readonly property bool compact: width < 980 || height < 680
    readonly property color accent: "#a9b7a4"
    readonly property color accentStrong: "#c1cfbc"
    readonly property color ink: "#f1efe9"
    readonly property color muted: "#b4b1aa"
    readonly property color panel: "#d91a1e20"
    readonly property color panelRaised: "#ee202426"
    readonly property color line: "#28ffffff"
    readonly property color lineStrong: "#45ffffff"
    readonly property color danger: "#e3a5a0"

    function beginLogin(): void {
        const user = usernameField.text.trim()
        if (user.length === 0) {
            root.statusMessage = "Enter a user name"
            usernameField.forceActiveFocus()
            return
        }

        root.statusMessage = "Authenticating…"
        root.loginPending = true
        sddm.login(user, passwordField.text, sessionBox.currentIndex)
    }

    function clearAuthentication(): void {
        root.loginPending = false
        passwordField.text = ""
        passwordField.forceActiveFocus()
    }

    Component.onCompleted: {
        root.entered = true
        if (usernameField.text.length > 0)
            passwordField.forceActiveFocus()
        else
            usernameField.forceActiveFocus()
    }

    TextConstants {
        id: textConstants
    }

    Connections {
        target: sddm

        function onLoginSucceeded() {
            root.statusMessage = "Welcome"
        }

        function onLoginFailed() {
            root.statusMessage = textConstants.loginFailed
            root.clearAuthentication()
        }

        function onInformationMessage(message) {
            if (message && String(message).length > 0)
                root.statusMessage = String(message)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Image {
        anchors.fill: parent
        source: "background.png"
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#a80b0e10" }
            GradientStop { position: 0.52; color: "#8d111416" }
            GradientStop { position: 1.0; color: "#c70a0c0d" }
        }
    }

    Rectangle {
        width: Math.max(root.width, root.height) * 0.72
        height: width
        radius: width / 2
        x: -width * 0.38
        y: -height * 0.44
        color: root.accent
        opacity: root.entered ? 0.075 : 0

        Behavior on opacity { NumberAnimation { duration: 420 } }
    }

    Rectangle {
        width: Math.max(root.width, root.height) * 0.56
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -width * 0.31
        anchors.bottomMargin: -height * 0.34
        color: "#8fa0ad"
        opacity: root.entered ? 0.045 : 0

        Behavior on opacity { NumberAnimation { duration: 520 } }
    }

    Item {
        id: stage
        width: Math.min(parent.width - (root.compact ? 36 : 96), 1180)
        height: Math.min(parent.height - (root.compact ? 42 : 92), 720)
        anchors.centerIn: parent
        opacity: root.entered ? 1 : 0
        scale: root.entered ? 1 : 0.988

        Behavior on opacity { NumberAnimation { duration: 260 } }
        Behavior on scale { NumberAnimation { duration: 360; easing.type: Easing.OutCubic } }

        Item {
            id: atmospherePane
            visible: !root.compact
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                right: authCard.left
                rightMargin: 72
            }

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 5

                Row {
                    spacing: 10

                    Rectangle {
                        width: 30
                        height: 2
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: root.accentStrong
                        opacity: 0.88
                    }

                    Text {
                        text: "RAOHANE · WELCOME HOME"
                        color: root.muted
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.35
                    }
                }

                Text {
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: root.ink
                    font.pixelSize: Math.min(112, Math.max(78, root.height * 0.115))
                    font.weight: Font.ExtraLight
                    font.letterSpacing: -2.8
                }

                Text {
                    text: Qt.formatDate(root.now, "dddd, d MMMM")
                    color: root.ink
                    opacity: 0.84
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                Text {
                    width: Math.min(500, atmospherePane.width)
                    topPadding: 14
                    text: "Choose your session, sign in, and continue into your workspace."
                    color: root.muted
                    font.pixelSize: 10
                    lineHeight: 1.4
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                spacing: 9

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    color: root.accentStrong
                    opacity: 0.85
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "DISPLAY MANAGER  /  " + String(sddm.hostName).toUpperCase()
                    color: root.muted
                    font.pixelSize: 9
                    font.letterSpacing: 0.9
                }
            }
        }

        Rectangle {
            id: authCard
            width: root.compact ? Math.min(stage.width, 500) : 446
            height: root.compact ? Math.min(stage.height, 636) : 628
            x: root.compact ? (stage.width - width) / 2 : stage.width - width
            anchors.verticalCenter: parent.verticalCenter
            radius: 30
            color: root.panel
            border.width: 1
            border.color: root.lineStrong
            clip: true

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "transparent"
                border.width: 1
                border.color: "#0cffffff"
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 3
                color: root.accentStrong
                opacity: 0.68
            }

            Rectangle {
                width: 210
                height: 210
                radius: 105
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -120
                anchors.topMargin: -115
                color: root.accent
                opacity: 0.055
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.compact ? 24 : 30
                spacing: 13

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 13

                    Rectangle {
                        Layout.preferredWidth: 64
                        Layout.preferredHeight: 64
                        radius: 21
                        color: "#18ffffff"
                        border.width: 1
                        border.color: root.line
                        clip: true

                        Image {
                            anchors.fill: parent
                            anchors.margins: 8
                            source: "avatar.svg"
                            fillMode: Image.PreserveAspectFit
                            opacity: 0.92
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 3

                        Text {
                            Layout.fillWidth: true
                            text: usernameField.text.length > 0 ? usernameField.text : "User"
                            color: root.ink
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.compact ? Qt.formatTime(root.now, "HH:mm") + " · " + Qt.formatDate(root.now, "d MMMM") : "Raohane session gateway"
                            color: root.muted
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        radius: 13
                        color: "#17ffffff"
                        border.width: 1
                        border.color: root.line

                        Text {
                            anchors.centerIn: parent
                            text: "ろ"
                            color: root.accentStrong
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Item { Layout.preferredHeight: 3 }

                Text {
                    text: "ACCOUNT"
                    color: root.muted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                TextField {
                    id: usernameField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    text: userModel.lastUser
                    color: root.ink
                    selectionColor: root.accent
                    selectedTextColor: "#151817"
                    placeholderText: textConstants.userName
                    placeholderTextColor: root.muted
                    font.pixelSize: 12
                    leftPadding: 16
                    rightPadding: 16
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    enabled: !root.loginPending
                    background: Rectangle {
                        radius: 15
                        color: usernameField.activeFocus ? "#26ffffff" : "#16ffffff"
                        border.width: 1
                        border.color: usernameField.activeFocus ? root.accent : root.line
                    }
                    Keys.onReturnPressed: passwordField.forceActiveFocus()
                    Keys.onEnterPressed: passwordField.forceActiveFocus()
                }

                Text {
                    text: "PASSWORD"
                    color: root.muted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                TextField {
                    id: passwordField
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    color: root.ink
                    selectionColor: root.accent
                    selectedTextColor: "#151817"
                    placeholderText: textConstants.password
                    placeholderTextColor: root.muted
                    font.pixelSize: 12
                    leftPadding: 16
                    rightPadding: 48
                    verticalAlignment: TextInput.AlignVCenter
                    echoMode: revealButton.checked ? TextInput.Normal : TextInput.Password
                    passwordCharacter: "•"
                    selectByMouse: true
                    enabled: !root.loginPending
                    background: Rectangle {
                        radius: 15
                        color: passwordField.activeFocus ? "#26ffffff" : "#16ffffff"
                        border.width: 1
                        border.color: passwordField.activeFocus ? root.accent : root.line
                    }
                    Keys.onReturnPressed: root.beginLogin()
                    Keys.onEnterPressed: root.beginLogin()
                    Keys.onEscapePressed: passwordField.text = ""

                    ToolButton {
                        id: revealButton
                        width: 38
                        height: 38
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        checkable: true
                        focusPolicy: Qt.NoFocus
                        text: checked ? "◉" : "◎"
                        contentItem: Text {
                            text: revealButton.text
                            color: revealButton.checked ? root.accentStrong : root.muted
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: 14
                        }
                        background: Rectangle {
                            radius: 11
                            color: revealButton.pressed ? "#22ffffff" : "transparent"
                        }
                    }
                }

                Text {
                    text: "SESSION"
                    color: root.muted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                ComboBox {
                    id: sessionBox
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex
                    enabled: !root.loginPending
                    leftPadding: 16
                    rightPadding: 44

                    contentItem: Text {
                        leftPadding: 0
                        text: sessionBox.displayText
                        color: root.ink
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                        font.pixelSize: 12
                    }

                    indicator: Text {
                        x: sessionBox.width - width - 16
                        y: (sessionBox.height - height) / 2
                        text: "⌄"
                        color: root.accentStrong
                        font.pixelSize: 16
                    }

                    background: Rectangle {
                        radius: 15
                        color: sessionBox.activeFocus ? "#26ffffff" : "#16ffffff"
                        border.width: 1
                        border.color: sessionBox.activeFocus ? root.accent : root.line
                    }

                    delegate: ItemDelegate {
                        required property int index
                        width: sessionBox.width - 12
                        height: 42
                        text: sessionBox.textAt(index)
                        highlighted: sessionBox.highlightedIndex === index
                        contentItem: Text {
                            text: parent.text
                            color: root.ink
                            verticalAlignment: Text.AlignVCenter
                            elide: Text.ElideRight
                            font.pixelSize: 11
                        }
                        background: Rectangle {
                            radius: 11
                            color: parent.highlighted ? "#26ffffff" : "transparent"
                        }
                    }

                    popup: Popup {
                        y: sessionBox.height + 7
                        width: sessionBox.width
                        implicitHeight: Math.min(contentItem.implicitHeight + 12, 270)
                        padding: 6

                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                            currentIndex: sessionBox.highlightedIndex
                            ScrollIndicator.vertical: ScrollIndicator { }
                        }

                        background: Rectangle {
                            radius: 17
                            color: root.panelRaised
                            border.width: 1
                            border.color: root.lineStrong
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 26
                    text: root.statusMessage
                    color: root.statusMessage === textConstants.loginFailed ? root.danger : root.muted
                    opacity: text.length > 0 ? 1 : 0
                    font.pixelSize: 9
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight

                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Button {
                    id: loginButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    enabled: !root.loginPending
                    onClicked: root.beginLogin()

                    contentItem: Row {
                        anchors.centerIn: parent
                        spacing: 9

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.loginPending ? "· · ·" : textConstants.login
                            color: "#121513"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !root.loginPending
                            text: "→"
                            color: "#121513"
                            font.pixelSize: 15
                            font.weight: Font.Medium
                        }
                    }

                    background: Rectangle {
                        radius: 16
                        color: loginButton.pressed ? "#92a18e" : (loginButton.hovered ? "#b6c5b1" : root.accentStrong)
                        opacity: loginButton.enabled ? 1 : 0.58
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 2
                    spacing: 8

                    PowerButton {
                        Layout.fillWidth: true
                        visible: sddm.canSuspend
                        glyph: "—"
                        label: "Suspend"
                        onTriggered: sddm.suspend()
                    }

                    PowerButton {
                        Layout.fillWidth: true
                        visible: sddm.canReboot
                        glyph: "↻"
                        label: "Restart"
                        onTriggered: sddm.reboot()
                    }

                    PowerButton {
                        Layout.fillWidth: true
                        visible: sddm.canPowerOff
                        glyph: "⏻"
                        label: "Power"
                        onTriggered: sddm.powerOff()
                    }
                }
            }
        }
    }

    component PowerButton: Button {
        id: powerButton
        required property string glyph
        required property string label
        signal triggered()

        Layout.preferredHeight: 44
        focusPolicy: Qt.TabFocus
        onClicked: powerButton.triggered()

        contentItem: Row {
            anchors.centerIn: parent
            spacing: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: powerButton.glyph
                color: powerButton.hovered ? root.ink : root.muted
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: powerButton.label
                color: powerButton.hovered ? root.ink : root.muted
                font.pixelSize: 9
                font.weight: Font.Medium
            }
        }

        background: Rectangle {
            radius: 13
            color: powerButton.pressed ? "#25ffffff" : (powerButton.hovered ? "#18ffffff" : "#0dffffff")
            border.width: 1
            border.color: powerButton.hovered ? root.lineStrong : root.line
        }
    }
}
