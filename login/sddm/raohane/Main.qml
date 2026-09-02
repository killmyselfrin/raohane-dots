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
    readonly property real panelWidth: Math.max(480, root.width * 0.31)

    function submitLogin() {
        if (root.loginBusy || root.currentUser.length === 0 || passwordInput.text.length === 0)
            return
        root.loginBusy = true
        errorText.text = ""
        sddm.login(root.currentUser, passwordInput.text, root.selectedSession)
    }

    function sessionDisplayName(value): string {
        let label = String(value ?? "").trim()
        label = label.replace(/\s*\(uwsm-managed\)/gi, " · UWSM")
        label = label.replace(/\s*\(wayland\)/gi, "")
        return label
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            root.loginBusy = false
            errorText.text = qsTr("Wrong password")
            passwordShakeAnimation.restart()
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
        opacity: wallpaperImage.status === Image.Ready ? 0.14 : 0.0
    }

    Rectangle {
        id: panelBlend
        x: loginPanel.x + loginPanel.width - 2
        y: loginPanel.y + 1
        width: Math.max(132, root.width * 0.10)
        height: loginPanel.height - 2
        color: "transparent"
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.00; color: Qt.rgba(0.035, 0.055, 0.052, 0.22) }
            GradientStop { position: 0.45; color: Qt.rgba(0.035, 0.055, 0.052, 0.07) }
            GradientStop { position: 1.00; color: Qt.rgba(0.035, 0.055, 0.052, 0.0) }
        }
    }

    Rectangle {
        id: loginPanel
        x: 20
        y: 20
        width: root.panelWidth
        height: root.height - 40
        radius: 26
        color: Qt.rgba(0.028, 0.045, 0.043, 0.78)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: parent.radius - 1
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(0.72, 0.76, 0.68, 0.025)
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
                opacity: 0.82
            }

            Text {
                text: "RAOHANE"
                color: root.textColor
                opacity: 0.92
                font.pixelSize: 12
                font.bold: true
                font.letterSpacing: 4.6
            }

            Text {
                text: "静寂"
                color: root.mutedColor
                opacity: 0.46
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
                opacity: 0.72
                font.pixelSize: 18
                font.weight: Font.Light
            }

            Text {
                width: parent.width
                text: root.currentUser.length > 0 ? root.currentUser : qsTr("Raohane")
                color: root.textColor
                opacity: 0.94
                font.pixelSize: 56
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
            color: passwordInput.activeFocus
                ? Qt.rgba(0.11, 0.14, 0.13, 0.58)
                : Qt.rgba(0.07, 0.10, 0.09, 0.48)
            border.width: 1
            border.color: passwordInput.activeFocus ? root.accent : Qt.rgba(1, 1, 1, 0.12)

            transform: Translate { id: passwordShake }

            Behavior on color {
                ColorAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Text {
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 20
                }
                text: "⌑"
                color: root.textColor
                opacity: passwordInput.activeFocus ? 0.72 : 0.48
                font.pixelSize: 20

                Behavior on opacity { NumberAnimation { duration: 130 } }
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
                opacity: passwordInput.activeFocus ? 0.60 : 0.40
                font.pixelSize: 15

                Behavior on opacity { NumberAnimation { duration: 130 } }
            }

            Row {
                id: passwordDots
                anchors {
                    left: parent.left
                    verticalCenter: parent.verticalCenter
                    leftMargin: 56
                }
                spacing: 7
                visible: passwordInput.text.length > 0

                Repeater {
                    model: Math.min(passwordInput.text.length, 12)

                    delegate: Rectangle {
                        id: passwordDot
                        width: 7
                        height: 7
                        radius: 3.5
                        color: root.loginBusy ? root.accent : root.textColor
                        opacity: 0
                        scale: 0.35

                        ParallelAnimation {
                            id: dotEntrance
                            NumberAnimation {
                                target: passwordDot
                                property: "opacity"
                                from: 0
                                to: 0.86
                                duration: 115
                                easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: passwordDot
                                property: "scale"
                                from: 0.35
                                to: 1.0
                                duration: 170
                                easing.type: Easing.OutBack
                            }
                        }

                        Behavior on color { ColorAnimation { duration: 120 } }
                        Component.onCompleted: dotEntrance.start()
                    }
                }

                Text {
                    visible: passwordInput.text.length > 12
                    anchors.verticalCenter: parent.verticalCenter
                    text: "···"
                    color: root.textColor
                    opacity: 0.48
                    font.pixelSize: 11
                    font.letterSpacing: 1.5
                }
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
                color: "transparent"
                selectionColor: "transparent"
                selectedTextColor: "transparent"
                echoMode: TextInput.NoEcho
                font.pixelSize: 17
                verticalAlignment: TextInput.AlignVCenter
                selectByMouse: true
                focus: true
                enabled: !root.loginBusy
                onTextChanged: typingPulse.restart()
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
                opacity: root.loginBusy ? 0.50 : submitMouse.containsMouse ? 0.96 : 0.80
                scale: submitMouse.pressed ? 0.96 : 1

                Behavior on opacity { NumberAnimation { duration: 120 } }
                Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

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

        SequentialAnimation {
            id: typingPulse
            running: false
            NumberAnimation {
                target: passwordShell
                property: "scale"
                to: 1.006
                duration: 45
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: passwordShell
                property: "scale"
                to: 1.0
                duration: 115
                easing.type: Easing.OutCubic
            }
        }

        SequentialAnimation {
            id: passwordShakeAnimation
            running: false
            NumberAnimation { target: passwordShake; property: "x"; to: -8; duration: 45; easing.type: Easing.OutCubic }
            NumberAnimation { target: passwordShake; property: "x"; to: 7; duration: 55; easing.type: Easing.InOutCubic }
            NumberAnimation { target: passwordShake; property: "x"; to: -5; duration: 50; easing.type: Easing.InOutCubic }
            NumberAnimation { target: passwordShake; property: "x"; to: 3; duration: 45; easing.type: Easing.InOutCubic }
            NumberAnimation { target: passwordShake; property: "x"; to: 0; duration: 65; easing.type: Easing.OutCubic }
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
            opacity: 0.68
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
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            model: sessionModel
            currentIndex: root.selectedSession

            onCurrentIndexChanged: {
                if (currentIndex >= 0)
                    positionViewAtIndex(currentIndex, ListView.Contain)
            }

            delegate: Rectangle {
                id: sessionChip
                width: Math.max(126, Math.min(188, sessionLabel.implicitWidth + 62))
                height: 52
                radius: 16
                color: index === root.selectedSession
                    ? Qt.rgba(0.18, 0.22, 0.19, 0.58)
                    : sessionMouse.containsMouse
                        ? Qt.rgba(0.11, 0.14, 0.13, 0.54)
                        : Qt.rgba(0.07, 0.10, 0.09, 0.46)
                border.width: 1
                border.color: index === root.selectedSession ? root.accent : Qt.rgba(1, 1, 1, 0.09)

                Text {
                    anchors {
                        left: parent.left
                        verticalCenter: parent.verticalCenter
                        leftMargin: 16
                    }
                    text: "◈"
                    color: index === root.selectedSession ? root.accent : root.mutedColor
                    opacity: index === root.selectedSession ? 0.82 : 0.50
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
                    text: root.sessionDisplayName(name)
                    color: root.textColor
                    opacity: index === root.selectedSession ? 0.92 : 0.68
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
                    border.color: index === root.selectedSession ? root.accent : Qt.rgba(1, 1, 1, 0.22)
                    opacity: 0.82
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
            id: sessionPrevious
            visible: sessionList.contentWidth > sessionList.width + 2 && sessionList.contentX > 4
            anchors {
                left: sessionList.left
                verticalCenter: sessionList.verticalCenter
                leftMargin: 3
            }
            width: 30
            height: 30
            radius: 15
            color: Qt.rgba(0.035, 0.055, 0.052, 0.72)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            Text {
                anchors.centerIn: parent
                text: "‹"
                color: root.textColor
                opacity: 0.72
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sessionList.contentX = Math.max(0, sessionList.contentX - 170)
            }
        }

        Rectangle {
            id: sessionNext
            visible: sessionList.contentWidth > sessionList.width + 2
                && sessionList.contentX < sessionList.contentWidth - sessionList.width - 4
            anchors {
                right: sessionList.right
                verticalCenter: sessionList.verticalCenter
                rightMargin: 3
            }
            width: 30
            height: 30
            radius: 15
            color: Qt.rgba(0.035, 0.055, 0.052, 0.72)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.10)

            Text {
                anchors.centerIn: parent
                text: "›"
                color: root.textColor
                opacity: 0.72
                font.pixelSize: 18
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: sessionList.contentX = Math.min(
                    Math.max(0, sessionList.contentWidth - sessionList.width),
                    sessionList.contentX + 170
                )
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
            color: Qt.rgba(1, 1, 1, 0.055)
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
                    color: suspendMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.055) : Qt.rgba(1, 1, 1, 0.018)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "◔"
                        color: root.textColor
                        opacity: 0.76
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
                    opacity: 0.62
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
                    color: restartMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.055) : Qt.rgba(1, 1, 1, 0.018)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "↻"
                        color: root.textColor
                        opacity: 0.76
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
                    opacity: 0.62
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
                    color: powerMouse.containsMouse ? Qt.rgba(1, 1, 1, 0.055) : Qt.rgba(1, 1, 1, 0.018)
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: "⏻"
                        color: root.textColor
                        opacity: 0.76
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
                    opacity: 0.62
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
                opacity: 0.58
                font.pixelSize: 18
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("Enter to continue")
                color: root.mutedColor
                opacity: 0.38
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
            opacity: 0.80
            font.pixelSize: 17
            font.weight: Font.Light
        }

        Rectangle {
            width: 46
            height: 2
            radius: 1
            color: root.accent
            opacity: 0.70
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
        opacity: 0.030
        font.pixelSize: 146
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
        opacity: 0.072
        font.pixelSize: 10
        lineHeight: 1.20
        horizontalAlignment: Text.AlignHCenter
    }

    Component.onCompleted: passwordInput.forceActiveFocus()
}
