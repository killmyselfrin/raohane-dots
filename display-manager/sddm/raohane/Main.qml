import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import QtQuick.Layouts

Rectangle {
    id: root
    width: Screen.width
    height: Screen.height
    color: "#0c0e18"
    property date now: new Date()
    property bool appeared: false
    property bool leaving: false
    property bool pending: false
    property bool failed: false
    property string message: ""
    readonly property bool reducedMotion: String(config.ReduceMotion || "") === "true"
    readonly property string backgroundImage: String(config.wallpaper || config.Background || "background.png")
    readonly property color foreground: "#f5f2ff"
    readonly property color secondary: "#a9adc4"
    readonly property color lavender: "#b9a7ff"
    readonly property color borderColor: "#404b506b"
    readonly property real uiScale: Math.min(1.35, (width - 48) / 1100, (height - 100) / 560)

    function authenticate() {
        if (pending || leaving) return
        if (!userField.text.trim().length) {
            message = qsTr("Enter your user name")
            userField.forceActiveFocus()
            return
        }
        if (sessionBox.currentIndex < 0) {
            message = qsTr("No desktop session is installed")
            return
        }
        failed = false
        pending = true
        message = qsTr("Signing in…")
        sddm.login(userField.text.trim(), password.text, sessionBox.currentIndex)
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.pending = false
            root.failed = true
            password.clear()
            root.message = qsTr("Could not sign in. Check your password and try again.")
            if (!root.reducedMotion) shake.restart()
            password.forceActiveFocus()
        }
        function onLoginSucceeded() {
            password.clear()
            root.leaving = true
            root.message = qsTr("Welcome home")
        }
        function onInformationMessage(value) { root.message = String(value || "") }
    }
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }
    Component.onCompleted: {
        appeared = true
        if (userField.text.length) password.forceActiveFocus()
        else userField.forceActiveFocus()
    }
    Image {
        anchors.fill: parent
        source: root.backgroundImage
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: Math.min(root.width, 2560)
        asynchronous: true
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: "#a30b0d18" }
            GradientStop { position: 1; color: "#650b0d18" }
        }
    }
    Text {
        anchors { left: parent.left; top: parent.top; margins: 28 }
        text: "R A O H A N E"
        color: root.foreground
        font { pixelSize: 12; letterSpacing: 3; weight: Font.DemiBold }
    }

    component Pill: Controls.Button {
        id: pill
        property string symbol: ""
        property bool primary: false
        hoverEnabled: true
        implicitHeight: 68
        opacity: enabled ? 1 : 0.4
        scale: down ? 0.97 : 1
        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 130 } }
        contentItem: RowLayout {
            spacing: 12
            Text {
                text: pill.symbol === "⏻" ? "" : pill.symbol
                color: pill.primary ? "#191526" : root.lavender
                font.pixelSize: 22
                Layout.preferredWidth: 28
                horizontalAlignment: Text.AlignHCenter
                Image {
                    anchors.centerIn: parent
                    width: 22; height: 22
                    visible: pill.symbol === "⏻"
                    source: visible ? "power.svg" : ""
                }
            }
            Text {
                text: pill.text
                color: pill.primary ? "#191526" : root.foreground
                font { pixelSize: 14; weight: Font.Medium }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        leftPadding: 23
        rightPadding: 23
        background: Rectangle {
            radius: height / 2
            color: pill.primary ? root.lavender : pill.hovered ? "#ee303044" : "#e51b1e2c"
            border.width: 1
            border.color: pill.activeFocus ? root.lavender : root.borderColor
            Behavior on color { ColorAnimation { duration: root.reducedMotion ? 0 : 160 } }
        }
    }
    component Card: Rectangle {
        color: "#d9191d2a"
        radius: 22
        border.color: root.borderColor
    }
    Item {
        id: scene
        objectName: "scene"
        width: 1100
        height: 560
        anchors.centerIn: parent
        scale: root.uiScale * (root.appeared && !root.leaving ? 1 : 0.97)
        opacity: root.appeared && !root.leaving ? 1 : 0
        enabled: !root.leaving
        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 400; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 500; easing.type: Easing.OutCubic } }

        Column {
            width: 270
            spacing: 14
            Card {
                width: parent.width
                height: 240
                Column {
                    anchors { fill: parent; margins: 24 }
                    spacing: 16
                    Text { text: qsTr("YOUR SPACE"); color: root.secondary; font { pixelSize: 10; letterSpacing: 2 } }
                    Text { text: Qt.formatTime(root.now, "HH:mm"); color: root.foreground; font { pixelSize: 60; weight: Font.Light; letterSpacing: -3 } }
                    Text { width: parent.width; text: Qt.formatDate(root.now, "dddd, d MMMM"); color: root.secondary; font.pixelSize: 13; wrapMode: Text.WordWrap }
                    Rectangle { width: parent.width; height: 1; color: root.borderColor }
                    Text { width: parent.width; text: String(sddm.hostName || "Raohane"); color: root.lavender; font.pixelSize: 13; elide: Text.ElideRight }
                }
            }
            Card {
                width: parent.width
                height: 306
                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    spacing: 10
                    Text { text: qsTr("POWER"); color: root.secondary; font { pixelSize: 10; letterSpacing: 2 } Layout.leftMargin: 8 }
                    Pill { text: qsTr("Suspend"); symbol: "☾"; Layout.fillWidth: true; enabled: sddm.canSuspend && !root.pending; onClicked: sddm.suspend() }
                    Pill { text: qsTr("Restart"); symbol: "↻"; Layout.fillWidth: true; enabled: sddm.canReboot && !root.pending; onClicked: sddm.reboot() }
                    Pill { text: qsTr("Power off"); symbol: "⏻"; Layout.fillWidth: true; enabled: sddm.canPowerOff && !root.pending; onClicked: sddm.powerOff() }
                }
            }
        }

        Column {
            width: 440
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 22
            Rectangle {
                width: 158
                height: 158
                radius: 79
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#272a3b"
                border.color: root.borderColor
                Canvas {
                    id: avatarImage
                    anchors { fill: parent; margins: 5 }
                    property url source: Qt.resolvedUrl(String(config.Avatar || "avatar.svg"))
                    onSourceChanged: loadImage(source)
                    Component.onCompleted: loadImage(source)
                    onImageLoaded: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.reset()
                        if (!isImageLoaded(source)) return
                        ctx.save()
                        ctx.beginPath()
                        ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2)
                        ctx.clip()
                        ctx.drawImage(source, 0, 0, width, height)
                        ctx.restore()
                    }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.leaving ? qsTr("Welcome home") : qsTr("Welcome back")
                color: root.foreground
                font { pixelSize: 22; weight: Font.Medium }
            }
            Card {
                id: loginPanel
                width: parent.width
                height: 270
                color: "#a9151926"
                transform: Translate { id: shakeTransform }
                ColumnLayout {
                    anchors { fill: parent; margins: 22 }
                    spacing: 12
                    Controls.TextField {
                        id: userField
                        objectName: "userField"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        text: String(userModel.lastUser || "")
                        placeholderText: qsTr("User name")
                        Accessible.name: qsTr("User name")
                        color: root.foreground
                        placeholderTextColor: root.secondary
                        enabled: !root.pending
                        selectByMouse: true
                        leftPadding: 16
                        background: Rectangle { radius: 20; color: "#272a3b"; border.color: userField.activeFocus ? root.lavender : "transparent" }
                        onAccepted: password.forceActiveFocus()
                        onTextEdited: { password.clear(); root.message = ""; root.failed = false }
                    }
                    Controls.TextField {
                        id: password
                        objectName: "password"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 48
                        enabled: !root.pending
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        passwordMaskDelay: 0
                        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        placeholderText: qsTr("Password")
                        Accessible.name: qsTr("Password")
                        placeholderTextColor: root.secondary
                        color: root.foreground
                        leftPadding: 18
                        background: Rectangle {
                            radius: 27
                            color: "#272a3b"
                            border.color: root.failed ? "#f2a0b6" : password.activeFocus ? root.lavender : root.borderColor
                            Behavior on border.color { ColorAnimation { duration: root.reducedMotion ? 0 : 120 } }
                        }
                        onAccepted: root.authenticate()
                    }
                    Text {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 28
                        text: root.message.length ? root.message : keyboard.capsLock ? qsTr("Caps Lock is on") : qsTr("Choose your session, then sign in")
                        color: root.failed ? "#f2a0b6" : root.secondary
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        verticalAlignment: Text.AlignVCenter
                    }
                    Pill {
                        objectName: "signIn"
                        Layout.fillWidth: true
                        Layout.preferredHeight: 44
                        primary: true
                        text: root.pending ? qsTr("Signing in…") : qsTr("Sign in")
                        symbol: "→"
                        enabled: !root.pending && sessionBox.currentIndex >= 0
                        onClicked: root.authenticate()
                    }
                }
            }
        }

        Column {
            width: 270
            anchors.right: parent.right
            spacing: 14
            Card {
                width: parent.width
                height: 420
                Text {
                    anchors { left: parent.left; top: parent.top; margins: 22 }
                    text: "RAOHANE"
                    color: root.secondary
                    font { pixelSize: 10; letterSpacing: 2 }
                }
                Image {
                    anchors { left: parent.left; right: parent.right; top: parent.top; bottom: dialogue.top; margins: 18; topMargin: 52 }
                    source: String(config.Mascot || "mascot.svg")
                    fillMode: Image.PreserveAspectFit
                    sourceSize.width: 480
                    asynchronous: true
                }
                Rectangle {
                    id: dialogue
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20 }
                    height: 64
                    radius: 18
                    color: "#302c43"
                    Text {
                        anchors { fill: parent; margins: 12 }
                        text: root.leaving ? qsTr("Welcome home.\nI missed you.") : qsTr("A little pause.\nYour space is waiting.")
                        color: root.foreground
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.WordWrap
                    }
                }
            }
            Card {
                width: parent.width
                height: 126
                ColumnLayout {
                    anchors { fill: parent; margins: 16 }
                    Text { text: qsTr("DESKTOP SESSION"); color: root.secondary; font { pixelSize: 10; letterSpacing: 1 } }
                Controls.ComboBox {
                    id: sessionBox
                    objectName: "sessionBox"
                    Layout.preferredWidth: 240
                    Layout.fillWidth: true
                    Layout.preferredHeight: 48
                    model: sessionModel
                    textRole: "name"
                    currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                    enabled: !root.pending
                    leftPadding: 22
                    rightPadding: 28
                    Accessible.name: qsTr("Desktop session")
                    contentItem: Text { text: sessionBox.displayText; color: root.foreground; font.pixelSize: 13; elide: Text.ElideRight; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 34; color: "#e51b1e2c"; border.color: sessionBox.activeFocus ? root.lavender : root.borderColor }
                    delegate: Controls.ItemDelegate {
                        width: sessionBox.width
                        contentItem: Text { text: model.name; color: root.foreground; elide: Text.ElideRight; font.pixelSize: 13 }
                        background: Rectangle { color: highlighted ? "#39334f" : "#1b1e2c" }
                        highlighted: sessionBox.highlightedIndex === index
                    }
                    popup: Controls.Popup {
                        y: sessionBox.height + 6
                        width: sessionBox.width
                        padding: 6
                        implicitHeight: Math.min(contentItem.implicitHeight + 12, 240)
                        contentItem: ListView {
                            clip: true
                            implicitHeight: contentHeight
                            model: sessionBox.popup.visible ? sessionBox.delegateModel : null
                            currentIndex: sessionBox.highlightedIndex
                            Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
                        }
                        background: Rectangle { color: "#1b1e2c"; radius: 16; border.color: root.borderColor }
                    }
                }
                }
            }
        }
    }
    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeTransform; property: "x"; to: -8; duration: 45 }
        NumberAnimation { target: shakeTransform; property: "x"; to: 8; duration: 65 }
        NumberAnimation { target: shakeTransform; property: "x"; to: 0; duration: 80 }
    }
}
