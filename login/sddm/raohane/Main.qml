import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.background

    property color accent: config.accent
    property color textColor: config.text
    property color mutedColor: config.muted
    property int cardRadius: Number(config.radius)
    property bool loginBusy: false

    function submitLogin() {
        if (loginBusy || userField.text.length === 0 || passwordField.text.length === 0)
            return
        loginBusy = true
        errorText.text = ""
        sddm.login(userField.text, passwordField.text, sessionBox.currentIndex)
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginBusy = false
            errorText.text = qsTr("Authentication failed")
            passwordField.selectAll()
            passwordField.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#171713" }
            GradientStop { position: 0.48; color: root.color }
            GradientStop { position: 1.0; color: "#0c0d0c" }
        }
    }

    Rectangle {
        width: Math.max(parent.width, parent.height) * 0.7
        height: width
        radius: width / 2
        x: parent.width * 0.58
        y: -height * 0.34
        color: root.accent
        opacity: 0.055
    }

    Rectangle {
        width: Math.max(parent.width, parent.height) * 0.55
        height: width
        radius: width / 2
        x: -width * 0.35
        y: parent.height * 0.58
        color: "#d2b7b0"
        opacity: 0.035
    }

    Column {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Math.max(48, parent.width * 0.055)
            topMargin: Math.max(42, parent.height * 0.06)
        }
        spacing: 6

        Text {
            text: Qt.formatTime(new Date(), "HH:mm")
            color: root.textColor
            font.pixelSize: Math.max(54, parent.parent.width * 0.055)
            font.weight: Font.Light
        }

        Text {
            text: Qt.formatDate(new Date(), "dddd, d MMMM")
            color: root.mutedColor
            font.pixelSize: 18
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.childrenChanged()
    }

    Rectangle {
        id: card
        width: Math.min(460, parent.width - 64)
        height: 500
        radius: root.cardRadius
        color: config.surfaceStrong
        border.width: 1
        border.color: "#ffffff20"
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: Math.max(48, parent.width * 0.065)
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 34
            spacing: 18

            ColumnLayout {
                spacing: 4
                Layout.fillWidth: true

                Text {
                    text: "RAOHANE"
                    color: root.accent
                    font.pixelSize: 12
                    font.letterSpacing: 4
                    font.bold: true
                }

                Text {
                    text: qsTr("Welcome back")
                    color: root.textColor
                    font.pixelSize: 30
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("Choose a session and sign in")
                    color: root.mutedColor
                    font.pixelSize: 14
                }
            }

            TextField {
                id: userField
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                text: userModel.lastUser
                placeholderText: qsTr("User")
                color: root.textColor
                selectByMouse: true
                background: Rectangle {
                    radius: 15
                    color: config.surface
                    border.width: userField.activeFocus ? 1 : 0
                    border.color: root.accent
                }
            }

            TextField {
                id: passwordField
                Layout.fillWidth: true
                Layout.preferredHeight: 52
                placeholderText: qsTr("Password")
                echoMode: TextInput.Password
                color: root.textColor
                selectByMouse: true
                focus: true
                onAccepted: root.submitLogin()
                background: Rectangle {
                    radius: 15
                    color: config.surface
                    border.width: passwordField.activeFocus ? 1 : 0
                    border.color: root.accent
                }
            }

            ComboBox {
                id: sessionBox
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                model: sessionModel
                currentIndex: sessionModel.lastIndex
                textRole: "name"
                background: Rectangle {
                    radius: 15
                    color: config.surface
                    border.width: sessionBox.activeFocus ? 1 : 0
                    border.color: root.accent
                }
                contentItem: Text {
                    leftPadding: 16
                    verticalAlignment: Text.AlignVCenter
                    text: sessionBox.displayText
                    color: root.textColor
                    elide: Text.ElideRight
                }
            }

            Text {
                id: errorText
                Layout.fillWidth: true
                text: ""
                color: "#e6a4a4"
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                visible: text.length > 0
            }

            Button {
                Layout.fillWidth: true
                Layout.preferredHeight: 54
                enabled: !root.loginBusy
                onClicked: root.submitLogin()

                background: Rectangle {
                    radius: 16
                    color: parent.pressed ? Qt.darker(root.accent, 1.12) : root.accent
                }

                contentItem: Text {
                    text: root.loginBusy ? qsTr("Signing in…") : qsTr("Enter")
                    color: "#151713"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 15
                    font.bold: true
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Button {
                    Layout.fillWidth: true
                    text: qsTr("Suspend")
                    onClicked: sddm.suspend()
                }
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Restart")
                    onClicked: sddm.reboot()
                }
                Button {
                    Layout.fillWidth: true
                    text: qsTr("Power off")
                    onClicked: sddm.powerOff()
                }
            }
        }
    }
}
