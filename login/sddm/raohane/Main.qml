import QtQuick 2.15
import QtQuick.Controls 2.15 as QQC2
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
    property color blush: "#c5aaa3"
    property int cardRadius: Number(config.radius)
    property bool loginBusy: false
    property date now: new Date()
    property string currentUser: String(userModel.lastUser || "")

    function submitLogin() {
        if (root.loginBusy || root.currentUser.length === 0 || passwordInput.text.length === 0)
            return
        root.loginBusy = true
        errorText.text = ""
        sddm.login(root.currentUser, passwordInput.text, sessionBox.currentIndex)
    }

    function userInitial() {
        if (root.currentUser.length === 0)
            return "R"
        return root.currentUser.substring(0, 1).toUpperCase()
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginBusy = false
            errorText.text = qsTr("Wrong password")
            passwordInput.selectAll()
            passwordInput.forceActiveFocus()
        }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.00; color: "#0d0e0c" }
            GradientStop { position: 0.48; color: root.color }
            GradientStop { position: 1.00; color: "#151713" }
        }
    }

    Rectangle {
        width: parent.width * 0.48
        height: width
        radius: width / 2
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: -width * 0.20
            topMargin: -height * 0.38
        }
        color: root.accent
        opacity: 0.035
    }

    Rectangle {
        width: parent.width * 0.38
        height: width
        radius: width / 2
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: -width * 0.38
            bottomMargin: -height * 0.48
        }
        color: root.blush
        opacity: 0.028
    }

    Text {
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: Math.max(56, parent.width * 0.055)
            bottomMargin: Math.max(34, parent.height * 0.035)
        }
        text: "静"
        color: root.textColor
        opacity: 0.025
        font.pixelSize: Math.min(310, parent.height * 0.31)
        font.weight: Font.Light
    }

    Row {
        anchors {
            left: parent.left
            top: parent.top
            leftMargin: Math.max(44, parent.width * 0.045)
            topMargin: Math.max(36, parent.height * 0.045)
        }
        spacing: 12

        Rectangle {
            width: 7
            height: 7
            radius: 3.5
            anchors.verticalCenter: parent.verticalCenter
            color: root.accent
        }

        Text {
            text: "RAOHANE"
            color: root.textColor
            opacity: 0.86
            font.pixelSize: 11
            font.bold: true
            font.letterSpacing: 3.6
        }

        Text {
            text: "静寂"
            color: root.mutedColor
            opacity: 0.62
            font.pixelSize: 11
            font.letterSpacing: 2
        }
    }

    Column {
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: Math.max(58, parent.width * 0.075)
            verticalCenterOffset: -10
        }
        spacing: 10

        Text {
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.textColor
            font.pixelSize: Math.max(72, root.width * 0.066)
            font.weight: Font.ExtraLight
            font.letterSpacing: -2
        }

        Rectangle {
            width: 44
            height: 2
            radius: 1
            color: root.accent
            opacity: 0.82
        }

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: root.mutedColor
            font.pixelSize: 15
            font.weight: Font.Normal
            opacity: 0.82
        }
    }

    Rectangle {
        id: loginCard
        width: Math.min(420, root.width - 64)
        height: 350
        radius: root.cardRadius
        anchors {
            right: parent.right
            verticalCenter: parent.verticalCenter
            rightMargin: Math.max(56, parent.width * 0.075)
        }
        color: config.surfaceStrong
        border.width: 1
        border.color: "#ffffff18"

        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 24
                rightMargin: 24
            }
            height: 1
            color: "#ffffff12"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 18

            RowLayout {
                Layout.fillWidth: true
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    radius: 18
                    color: config.surface
                    border.width: 1
                    border.color: "#ffffff18"

                    Text {
                        anchors.centerIn: parent
                        text: root.userInitial()
                        color: root.accent
                        font.pixelSize: 20
                        font.weight: Font.DemiBold
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.currentUser.length > 0 ? root.currentUser : qsTr("Raohane")
                        color: root.textColor
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: qsTr("Welcome back")
                        color: root.mutedColor
                        opacity: 0.72
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 58
                radius: 19
                color: config.surface
                border.width: passwordInput.activeFocus ? 1 : 1
                border.color: passwordInput.activeFocus ? root.accent : "#ffffff16"

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 18
                    }
                    visible: passwordInput.text.length === 0
                    text: qsTr("Password")
                    color: root.mutedColor
                    opacity: passwordInput.activeFocus ? 0.58 : 0.42
                    font.pixelSize: 14
                }

                TextInput {
                    id: passwordInput
                    anchors {
                        left: parent.left
                        right: enterButton.left
                        top: parent.top
                        bottom: parent.bottom
                        leftMargin: 18
                        rightMargin: 10
                    }
                    color: root.textColor
                    echoMode: TextInput.Password
                    font.pixelSize: 15
                    verticalAlignment: TextInput.AlignVCenter
                    selectByMouse: true
                    focus: true
                    enabled: !root.loginBusy
                    Keys.onReturnPressed: root.submitLogin()
                    Keys.onEnterPressed: root.submitLogin()
                }

                Rectangle {
                    id: enterButton
                    width: 42
                    height: 42
                    radius: 15
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 8
                    }
                    color: enterMouse.pressed ? Qt.darker(root.accent, 1.10) : root.accent
                    opacity: root.loginBusy ? 0.56 : 1

                    Text {
                        anchors.centerIn: parent
                        text: root.loginBusy ? "· · ·" : "→"
                        color: "#161814"
                        font.pixelSize: root.loginBusy ? 12 : 21
                        font.weight: Font.DemiBold
                    }

                    MouseArea {
                        id: enterMouse
                        anchors.fill: parent
                        enabled: !root.loginBusy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.submitLogin()
                    }
                }
            }

            Text {
                id: errorText
                Layout.fillWidth: true
                visible: text.length > 0
                text: ""
                color: "#d7a09b"
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                QQC2.ComboBox {
                    id: sessionBox
                    Layout.preferredWidth: 188
                    Layout.preferredHeight: 40
                    model: sessionModel
                    currentIndex: sessionModel.lastIndex
                    textRole: "name"
                    leftPadding: 14
                    rightPadding: 34

                    background: Rectangle {
                        radius: 15
                        color: config.surface
                        border.width: 1
                        border.color: sessionBox.activeFocus ? root.accent : "#ffffff14"
                    }

                    contentItem: Text {
                        text: sessionBox.displayText
                        color: root.textColor
                        opacity: 0.82
                        font.pixelSize: 12
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    indicator: Text {
                        x: sessionBox.width - width - 13
                        y: (sessionBox.height - height) / 2
                        text: "⌄"
                        color: root.mutedColor
                        opacity: 0.72
                        font.pixelSize: 14
                    }
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 15
                    color: suspendMouse.containsMouse ? "#ffffff10" : config.surface
                    border.width: 1
                    border.color: "#ffffff12"

                    Text {
                        anchors.centerIn: parent
                        text: "–"
                        color: root.mutedColor
                        font.pixelSize: 19
                    }

                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.suspend()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 15
                    color: restartMouse.containsMouse ? "#ffffff10" : config.surface
                    border.width: 1
                    border.color: "#ffffff12"

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: root.mutedColor
                        font.pixelSize: 17
                    }

                    MouseArea {
                        id: restartMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.reboot()
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 40
                    Layout.preferredHeight: 40
                    radius: 15
                    color: powerMouse.containsMouse ? "#ffffff10" : config.surface
                    border.width: 1
                    border.color: "#ffffff12"

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        color: root.mutedColor
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }
    }

    Text {
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: Math.max(44, parent.width * 0.045)
            bottomMargin: Math.max(32, parent.height * 0.04)
        }
        text: qsTr("Enter to continue")
        color: root.mutedColor
        opacity: 0.38
        font.pixelSize: 11
        font.letterSpacing: 0.8
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
