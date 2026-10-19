import QtQuick
import QtQuick.Window
import QtQuick.Controls as Controls
import QtQuick.Layouts
import SddmComponents 2.0

Item {
    id: root
    width: Screen.width
    height: Screen.height

    property date now: new Date()
    property bool appeared: false
    property bool leaving: false
    property bool pending: false
    property bool switchUser: false
    property bool expandedOptions: false
    property string account: String(userModel.lastUser || "")
    property string message: ""
    readonly property bool compact: width < 1080 || height < 720
    readonly property bool shortScreen: height < 760
    readonly property bool reducedMotion: String(config.ReduceMotion || "") === "true"
    readonly property string backgroundImage: String(config.Background || "").length ? String(config.Background) : "background.png"
    readonly property color foreground: "#f5f2ff"
    readonly property color secondary: "#b1b7d4"
    readonly property color lavender: "#b9a7ff"
    readonly property color borderColor: "#647e95c8"

    function authenticate() {
        if (pending) return
        const selected = switchUser || !account.length ? userField.text.trim() : account
        if (!selected.length) {
            message = "Enter a user name"
            userField.forceActiveFocus()
            return
        }
        pending = true
        message = "Authenticating..."
        sddm.login(selected, password.text, sessionBox.currentIndex)
    }

    function rejected() {
        pending = false
        password.text = ""
        message = "Incorrect password. Try again."
        shake.restart()
        password.forceActiveFocus()
    }

    Connections {
        target: sddm
        function onLoginSucceeded() {
            root.leaving = true
            root.message = "Welcome home ♡"
        }
        function onLoginFailed() { root.rejected() }
        function onInformationMessage(value) {
            if (value) root.message = String(value)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Component.onCompleted: {
        appeared = true
        if (account.length) password.forceActiveFocus()
        else userField.forceActiveFocus()
    }

    Image {
        id: wallpaper
        anchors.fill: parent
        source: root.backgroundImage
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
    }
    // A cached system image keeps SDDM independent of the unlocked user session.
    // De-emphasize bright wallpapers without altering their source.
    Rectangle {
        anchors.fill: parent
        color: "#97070a18"
    }
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#50192842" }
            GradientStop { position: 0.54; color: "#6011132d" }
            GradientStop { position: 1; color: "#b4080c1b" }
        }
    }
    Rectangle {
        width: Math.max(root.width * 0.46, 300)
        height: width
        radius: width / 2
        x: -width * 0.28
        y: -height * 0.32
        color: "#6e65cf"
        opacity: 0.075
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 40
        anchors.top: parent.top
        anchors.topMargin: 27
        text: "✦   R A O H A N E"
        color: foreground
        font.pixelSize: 13
        font.weight: Font.DemiBold
        font.letterSpacing: 2
    }

    Item {
        id: scene
        width: Math.min(root.width - 44, 1180)
        height: Math.min(root.height - 44, 680)
        anchors.centerIn: parent
        opacity: appeared && !leaving ? 1 : 0
        scale: appeared && !leaving ? 1 : 0.965
        Behavior on opacity { NumberAnimation { duration: root.reducedMotion ? 0 : 550; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: root.reducedMotion ? 0 : 720; easing.type: Easing.OutCubic } }

        // Atmospheric mascot is separate from the password surface.
        Item {
            id: character
            visible: !root.compact
            width: 340
            height: 425
            anchors.right: parent.right
            anchors.rightMargin: -18
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 14
            opacity: 0.85
            Image {
                anchors.fill: parent
                source: "mascot.svg"
                fillMode: Image.PreserveAspectFit
                transform: Translate { y: characterDrift.value }
            }
            QtObject { id: characterDrift; property real value: 0 }
            SequentialAnimation {
                running: character.visible && !root.reducedMotion
                loops: Animation.Infinite
                NumberAnimation { target: characterDrift; property: "value"; from: 0; to: -7; duration: 3700; easing.type: Easing.InOutSine }
                NumberAnimation { target: characterDrift; property: "value"; from: -7; to: 0; duration: 3700; easing.type: Easing.InOutSine }
            }
            Rectangle {
                width: 168
                height: 54
                radius: 15
                x: 140
                y: 55
                color: "#d3182039"
                border.width: 1
                border.color: borderColor
                Text {
                    anchors.centerIn: parent
                    text: root.leaving ? "Welcome home ♡" : "Locked...\nSee you soon ♡"
                    font.pixelSize: 12
                    color: foreground
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        Column {
            id: core
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: root.shortScreen ? 0 : 22
            width: Math.min(610, scene.width)
            spacing: root.shortScreen ? 8 : 13
            z: 3

            Rectangle {
                id: clock
                width: parent.width
                height: root.shortScreen ? 150 : 215
                radius: 28
                color: "#c20d1429"
                border.width: 1
                border.color: borderColor
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.leftMargin: 28
                    anchors.rightMargin: 28
                    height: 1
                    color: "#617bb4ff"
                    opacity: 0.6
                }
                Column {
                    anchors.centerIn: parent
                    spacing: 7
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "L O C K E D"
                        font.pixelSize: 11
                        color: secondary
                        font.letterSpacing: 3
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatTime(root.now, "HH:mm")
                        font.pixelSize: root.shortScreen ? 70 : 108
                        font.weight: Font.Light
                        font.letterSpacing: -3
                        color: foreground
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDate(root.now, "dddd, d MMMM")
                        font.pixelSize: 14
                        color: secondary
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: root.shortScreen ? 60 : 88
                radius: 21
                color: "#bd10182b"
                border.width: 1
                border.color: "#497e95c8"
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Text { text: "RAOHANE  /  NOCTURNE"; color: foreground; font.pixelSize: 12; font.weight: Font.DemiBold }
                        Text { text: "Your space. Your colors."; color: secondary; font.pixelSize: 11 }
                    }
                    Rectangle { Layout.preferredWidth: 1; Layout.fillHeight: true; color: borderColor }
                    ColumnLayout {
                        spacing: 3
                        Text { text: root.account.length ? root.account : "Choose account"; color: foreground; font.pixelSize: 13; font.weight: Font.DemiBold }
                        Text { text: sessionBox.displayText; color: secondary; font.pixelSize: 10; elide: Text.ElideRight; Layout.maximumWidth: 150 }
                    }
                }
            }

            Item {
                width: parent.width
                height: 20
                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Repeater {
                        model: 55
                        Rectangle {
                            required property int index
                            width: 3
                            height: 4 + Math.abs(Math.sin(index * 0.36) * Math.cos(index * 0.13)) * 15
                            radius: 2
                            anchors.verticalCenter: parent.verticalCenter
                            color: index < 28 ? "#81cafa" : lavender
                            opacity: 0.35 + (height / 20) * 0.55
                        }
                    }
                }
            }

            Rectangle {
                id: loginPanel
                width: parent.width
                height: (root.switchUser || root.account.length === 0 ? 190 : 140) + (root.expandedOptions ? 160 : 0)
                radius: 24
                color: "#dc0c1326"
                border.width: 1
                border.color: borderColor
                Behavior on height { NumberAnimation { duration: root.reducedMotion ? 0 : 240; easing.type: Easing.OutCubic } }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 9

                    Controls.TextField {
                        id: userField
                        visible: root.switchUser || root.account.length === 0
                        Layout.fillWidth: true
                        Layout.preferredHeight: visible ? 39 : 0
                        placeholderText: "User name"
                        text: root.account
                        color: foreground
                        placeholderTextColor: secondary
                        background: Rectangle { radius: 11; color: "#292c3d"; border.color: borderColor }
                        Keys.onReturnPressed: password.forceActiveFocus()
                    }

                    RowLayout {
                        id: passwordRow
                        Layout.fillWidth: true
                        Layout.preferredHeight: 50
                        spacing: 8
                        transform: Translate { id: shakeTransform; x: 0 }
                        Controls.TextField {
                            id: password
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            enabled: !root.pending
                            echoMode: TextInput.Password
                            placeholderText: "Enter your password"
                            placeholderTextColor: secondary
                            color: foreground
                            leftPadding: 17
                            background: Rectangle {
                                radius: 13
                                color: "#23283b"
                                border.width: 1
                                border.color: password.activeFocus ? lavender : borderColor
                            }
                            Keys.onReturnPressed: root.authenticate()
                            Keys.onEnterPressed: root.authenticate()
                        }
                        Controls.Button {
                            Layout.preferredWidth: 51
                            Layout.fillHeight: true
                            enabled: !root.pending
                            onClicked: root.authenticate()
                            contentItem: Text {
                                text: root.pending ? "···" : "→"
                                font.pixelSize: 24
                                color: "#141526"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                            background: Rectangle { radius: 13; color: lavender }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Controls.Button {
                            text: root.switchUser ? "Use previous account" : "Switch user"
                            visible: root.account.length > 0
                            onClicked: {
                                root.switchUser = !root.switchUser
                                password.text = ""
                                if (root.switchUser) {
                                    userField.text = ""
                                    userField.forceActiveFocus()
                                } else password.forceActiveFocus()
                            }
                            contentItem: Text { text: parent.text; color: secondary; font.pixelSize: 11 }
                            background: Item {}
                        }
                        Item { Layout.fillWidth: true }
                        Controls.Button {
                            text: root.expandedOptions ? "Hide options" : "Session / Power"
                            onClicked: root.expandedOptions = !root.expandedOptions
                            contentItem: Text { text: parent.text; color: secondary; font.pixelSize: 11 }
                            background: Item {}
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.message
                        color: root.message.indexOf("Incorrect") >= 0 ? "#f2a0b6" : secondary
                        horizontalAlignment: Text.AlignHCenter
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    ColumnLayout {
                        visible: root.expandedOptions
                        Layout.fillWidth: true
                        spacing: 8
                        Controls.ComboBox {
                            id: sessionBox
                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
                            model: sessionModel
                            textRole: "name"
                            currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
                            enabled: !root.pending
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            Controls.Button { text: "Suspend"; enabled: sddm.canSuspend; onClicked: sddm.suspend(); Layout.fillWidth: true }
                            Controls.Button { text: "Restart"; enabled: sddm.canReboot; onClicked: sddm.reboot(); Layout.fillWidth: true }
                            Controls.Button { text: "Power off"; enabled: sddm.canPowerOff; onClicked: sddm.powerOff(); Layout.fillWidth: true }
                        }
                    }
                }
            }
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeTransform; property: "x"; to: 10; duration: 45 }
        NumberAnimation { target: shakeTransform; property: "x"; to: -10; duration: 70 }
        NumberAnimation { target: shakeTransform; property: "x"; to: 7; duration: 65 }
        NumberAnimation { target: shakeTransform; property: "x"; to: 0; duration: 75 }
    }

    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 26
        anchors.left: parent.left
        anchors.leftMargin: 40
        text: "GOOD SOFTWARE  /  BRIGHTER DAYS"
        color: secondary
        opacity: 0.65
        font.pixelSize: 10
        font.letterSpacing: 2
    }
}
