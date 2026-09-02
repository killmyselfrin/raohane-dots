import QtQuick 2.15
import SddmComponents 2.0

Rectangle {
    id: root
    width: 1920
    height: 1080
    color: config.background

    property color accent: config.accent
    property color textColor: config.text
    property color mutedColor: config.muted
    property bool loginBusy: false
    property date now: new Date()
    property string currentUser: String(userModel.lastUser || "")
    property int selectedSession: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
    readonly property real panelWidth: Math.max(500, root.width * 0.325)

    function submitLogin() {
        if (root.loginBusy || root.currentUser.length === 0 || passwordInput.text.length === 0)
            return
        root.loginBusy = true
        errorText.text = ""
        sddm.login(root.currentUser, passwordInput.text, root.selectedSession)
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
            GradientStop { position: 0.0; color: "#141916" }
            GradientStop { position: 0.58; color: "#0c100f" }
            GradientStop { position: 1.0; color: "#080a09" }
        }
    }

    Image {
        id: wallpaperImage
        anchors.fill: parent
        source: String(config.wallpaper || "")
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        smooth: true
        opacity: status === Image.Ready ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#050706"
        opacity: wallpaperImage.status === Image.Ready ? 0.18 : 0.0
    }

    Rectangle {
        anchors {
            top: parent.top
            bottom: parent.bottom
            right: parent.right
        }
        width: root.width * 0.34
        color: "#050706"
        opacity: 0.10
    }

    Repeater {
        model: 8
        Rectangle {
            x: loginPanel.x + loginPanel.width - 1 + index * 18
            y: 0
            width: 20
            height: root.height
            color: "#09100d"
            opacity: 0.26 * Math.pow(0.72, index)
        }
    }

    Rectangle {
        id: loginPanel
        x: 20
        y: 20
        width: root.panelWidth
        height: root.height - 40
        radius: 28
        color: Qt.rgba(0.035, 0.055, 0.052, 0.94)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0.72, 0.76, 0.68, 0.05)
        }

        Row {
            anchors {
                left: parent.left
                top: parent.top
                leftMargin: 48
                topMargin: 48
            }
            spacing: 13

            Rectangle {
                width: 8
                height: 8
                radius: 4
                anchors.verticalCenter: parent.verticalCenter
                color: root.accent
                opacity: 0.92
            }

            Text {
                text: "RAOHANE"
                color: root.textColor
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 4.6
            }

            Text {
                text: "静寂"
                color: root.mutedColor
                opacity: 0.58
                font.pixelSize: 12
                font.letterSpacing: 2.4
            }
        }

        Column {
            id: identityBlock
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                leftMargin: 56
                rightMargin: 56
                topMargin: Math.max(205, parent.height * 0.24)
            }
            spacing: 12

            Text {
                text: qsTr("Welcome back")
                color: root.mutedColor
                opacity: 0.78
                font.pixelSize: 18
                font.weight: Font.Light
            }

            Text {
                width: parent.width
                text: root.currentUser.length > 0 ? root.currentUser : qsTr("Raohane")
                color: root.textColor
                font.pixelSize: 58
                font.weight: Font.Light
                elide: Text.ElideRight
            }
        }

        Rectangle {
            id: passwordShell
            anchors {
                left: parent.left
                right: parent.right
                top: identityBlock.bottom
                leftMargin: 56
                rightMargin: 56
                topMargin: 34
            }
            height: 66
            radius: 19
            color: passwordInput.activeFocus ? Qt.rgba(0.12, 0.15, 0.14, 0.76) : Qt.rgba(0.09, 0.12, 0.11, 0.70)
            border.width: 1
            border.color: passwordInput.activeFocus ? root.accent : Qt.rgba(1, 1, 1, 0.15)

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20
                }
                text: "⌑"
                color: root.textColor
                opacity: 0.72
                font.pixelSize: 20
            }

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 55
                }
                visible: passwordInput.text.length === 0
                text: qsTr("Password")
                color: root.mutedColor
                opacity: passwordInput.activeFocus ? 0.66 : 0.46
                font.pixelSize: 15
            }

            TextInput {
                id: passwordInput
                anchors {
                    left: parent.left
                    right: submitButton.left
                    top: parent.top
                    bottom: parent.bottom
                    leftMargin: 55
                    rightMargin: 12
                }
                color: root.textColor
                echoMode: TextInput.Password
                font.pixelSize: 17
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                focus: true
                enabled: !root.loginBusy
                Keys.onReturnPressed: root.submitLogin()
                Keys.onEnterPressed: root.submitLogin()
            }

            Rectangle {
                id: submitButton
                width: 50
                height: 50
                radius: 16
                anchors {
                    right: parent.right
                    verticalCenter: parent.verticalCenter
                    rightMargin: 8
                }
                color: submitMouse.pressed ? Qt.darker(root.accent, 1.13) : root.accent
                opacity: root.loginBusy ? 0.50 : submitMouse.containsMouse ? 1.0 : 0.88

                Text {
                    anchors.centerIn: parent
                    text: root.loginBusy ? "···" : "→"
                    color: "#121613"
                    font.pixelSize: root.loginBusy ? 13 : 23
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: submitMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !root.loginBusy
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.submitLogin()
                }
            }
        }

        Text {
            id: errorText
            anchors {
                left: passwordShell.left
                right: passwordShell.right
                top: passwordShell.bottom
                topMargin: 10
            }
            visible: text.length > 0
            text: ""
            color: "#d7a09b"
            font.pixelSize: 12
            wrapMode: Text.WordWrap
        }

        Text {
            id: sessionTitle
            anchors {
                left: passwordShell.left
                top: passwordShell.bottom
                topMargin: errorText.visible ? 48 : 44
            }
            text: qsTr("Session")
            color: root.mutedColor
            opacity: 0.76
            font.pixelSize: 13
        }

        ListView {
            id: sessionList
            anchors {
                left: passwordShell.left
                right: passwordShell.right
                top: sessionTitle.bottom
                topMargin: 14
            }
            height: 54
            orientation: ListView.Horizontal
            spacing: 10
            clip: true
            model: sessionModel
            currentIndex: root.selectedSession

            delegate: Rectangle {
                id: sessionChip
                width: Math.max(126, Math.min(194, sessionLabel.implicitWidth + 62))
                height: 52
                radius: 16
                color: index === root.selectedSession
                    ? Qt.rgba(0.20, 0.24, 0.21, 0.74)
                    : sessionMouse.containsMouse
                        ? Qt.rgba(0.12, 0.15, 0.14, 0.72)
                        : Qt.rgba(0.09, 0.12, 0.11, 0.62)
                border.width: 1
                border.color: index === root.selectedSession ? root.accent : Qt.rgba(1, 1, 1, 0.12)

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 16
                    }
                    text: "◈"
                    color: index === root.selectedSession ? root.accent : root.mutedColor
                    opacity: index === root.selectedSession ? 0.96 : 0.66
                    font.pixelSize: 13
                }

                Text {
                    id: sessionLabel
                    anchors {
                        left: parent.left
                        right: sessionDot.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 42
                        rightMargin: 10
                    }
                    text: name
                    color: root.textColor
                    opacity: index === root.selectedSession ? 0.96 : 0.76
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }

                Rectangle {
                    id: sessionDot
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        rightMargin: 15
                    }
                    width: 8
                    height: 8
                    radius: 4
                    color: index === root.selectedSession ? root.accent : "transparent"
                    border.width: 1
                    border.color: index === root.selectedSession ? root.accent : Qt.rgba(1, 1, 1, 0.28)
                }

                MouseArea {
                    id: sessionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedSession = index
                }
            }
        }

        Rectangle {
            anchors {
                left: passwordShell.left
                right: passwordShell.right
                bottom: powerRow.top
                bottomMargin: 32
            }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.07)
        }

        Row {
            id: powerRow
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.bottom
                bottomMargin: 98
            }
            spacing: 48

            Item {
                width: 72
                height: 84

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: suspendMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.025)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: "◔"
                        color: root.textColor
                        opacity: 0.84
                        font.pixelSize: 22
                    }

                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.suspend()
                    }
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    text: qsTr("Suspend")
                    color: root.mutedColor
                    opacity: 0.72
                    font.pixelSize: 11
                }
            }

            Item {
                width: 72
                height: 84

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: restartMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.025)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: root.textColor
                        opacity: 0.84
                        font.pixelSize: 20
                    }

                    MouseArea {
                        id: restartMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.reboot()
                    }
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    text: qsTr("Restart")
                    color: root.mutedColor
                    opacity: 0.72
                    font.pixelSize: 11
                }
            }

            Item {
                width: 72
                height: 84

                Rectangle {
                    width: 48
                    height: 48
                    radius: 24
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: powerMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.025)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.14)

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        color: root.textColor
                        opacity: 0.84
                        font.pixelSize: 19
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: sddm.powerOff()
                    }
                }

                Text {
                    anchors {
                        horizontalCenter: parent.horizontalCenter
                        bottom: parent.bottom
                    }
                    text: qsTr("Power off")
                    color: root.mutedColor
                    opacity: 0.72
                    font.pixelSize: 11
                }
            }
        }

        Row {
            anchors {
                left: parent.left
                bottom: parent.bottom
                leftMargin: 48
                bottomMargin: 32
            }
            spacing: 10

            Text {
                text: "›"
                color: root.accent
                opacity: 0.70
                font.pixelSize: 18
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Enter to continue")
                color: root.mutedColor
                opacity: 0.46
                font.pixelSize: 11
                font.letterSpacing: 0.7
            }
        }
    }

    Column {
        anchors {
            left: loginPanel.right
            bottom: parent.bottom
            leftMargin: 68
            bottomMargin: 78
        }
        spacing: 8

        Text {
            text: Qt.formatTime(root.now, "HH:mm")
            color: root.textColor
            font.pixelSize: 84
            font.weight: Font.ExtraLight
            font.letterSpacing: -2.4
        }

        Text {
            text: Qt.formatDate(root.now, "dddd, d MMMM")
            color: root.accent
            opacity: 0.84
            font.pixelSize: 17
            font.weight: Font.Light
        }

        Rectangle {
            width: 46
            height: 2
            radius: 1
            color: root.accent
            opacity: 0.80
        }
    }

    Text {
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 54
            topMargin: 52
        }
        text: "静"
        color: root.textColor
        opacity: 0.045
        font.pixelSize: 150
        font.weight: Font.Light
    }

    Text {
        anchors {
            right: parent.right
            top: parent.top
            rightMargin: 30
            topMargin: 56
        }
        text: "静\nけ\nさ\nの\n中\nに"
        color: root.textColor
        opacity: 0.11
        font.pixelSize: 10
        lineHeight: 1.20
        horizontalAlignment: Text.AlignHCenter
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
