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
    readonly property string backgroundImage: String(config.wallpaper || config.Background
                                                     || "background.png")
    readonly property color foreground: "#eeeef5"
    readonly property color secondary: "#a3a7b9"
    readonly property color lavender: "#c1b2ea"
    readonly property color borderColor: "#24c0c8e0"
    readonly property real uiScale: Math.min(1.12, (width - 48) / 1100, (height - 100) / 500)

    // Keep account resolution outside the visual hierarchy. Some greeters,
    // including SDDM test mode, have users but no remembered lastUser.
    Instantiator {
        id: accounts
        model: userModel
        delegate: QtObject {
            property string loginName: String(model.name || "")
        }
    }
    readonly property string loginAccount: {
        const remembered = String(userModel.lastUser || "").trim();
        if (remembered.length)
            return remembered;
        if (!accounts.count)
            return "";
        const index = userModel.lastIndex >= 0 && userModel.lastIndex < accounts.count ? userModel.lastIndex :
                                                                                         0;
        const account = accounts.objectAt(index);
        return account ? account.loginName : "";
    }

    function authenticate() {
        if (pending || leaving)
            return;
        if (!root.loginAccount.length) {
            message = qsTr("No user account is available");
            return;
        }
        if (sessionBox.currentIndex < 0) {
            message = qsTr("No desktop session is installed");
            return;
        }
        failed = false;
        pending = true;
        message = qsTr("Signing in…");
        sddm.login(root.loginAccount, password.text, sessionBox.currentIndex);
    }
    Connections {
        target: sddm
        function onLoginFailed() {
            root.pending = false;
            root.failed = true;
            password.clear();
            root.message = qsTr("Could not sign in. Check your password and try again.");
            if (!root.reducedMotion)
                shake.restart();
            password.forceActiveFocus();
        }
        function onLoginSucceeded() {
            password.clear();
            root.leaving = true;
            root.message = qsTr("Welcome home");
        }
        function onInformationMessage(value) {
            root.message = String(value || "");
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }
    Component.onCompleted: {
        appeared = true;
        password.forceActiveFocus();
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
            GradientStop {
                position: 0
                color: "#910c101b"
            }
            GradientStop {
                position: 1
                color: "#750c101b"
            }
        }
    }
    Text {
        anchors {
            left: parent.left
            top: parent.top
            margins: 36
        }
        text: "raohane"
        color: root.foreground
        font {
            pixelSize: 15
            letterSpacing: 1.4
            weight: Font.Medium
        }
    }

    component Pill: Controls.Button {
        id: pill
        property string symbol: ""
        property bool primary: false
        hoverEnabled: true
        implicitHeight: 52
        opacity: enabled ? 1 : 0.4
        scale: down ? 0.97 : 1
        Accessible.name: text
        Behavior on scale {
            NumberAnimation {
                duration: root.reducedMotion ? 0 : 130
            }
        }
        contentItem: RowLayout {
            spacing: 13
            Image {
                source: pill.symbol === "⏻" ? "power.svg" : pill.symbol === "↻" ? "restart.svg" : pill.symbol
                                                                                  === "☾" ? "sleep.svg" :
                                                                                            "arrow.svg"
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                Layout.alignment: Qt.AlignVCenter
                sourceSize.width: 36
                sourceSize.height: 36
            }
            Text {
                visible: !pill.primary
                text: pill.text
                color: root.foreground
                font {
                    pixelSize: 13
                    weight: Font.Normal
                }
                elide: Text.ElideRight
                Layout.fillWidth: true
            }
        }
        leftPadding: primary ? 13 : 17
        rightPadding: primary ? 13 : 17
        background: Rectangle {
            radius: pill.primary ? 15 : 16
            color: pill.primary ? (pill.hovered ? "#dfd3f7" : root.lavender) : pill.hovered ? "#44323a4c" :
                                                                                              "transparent"
            border.width: 1
            border.color: pill.activeFocus ? root.lavender : "transparent"
            Behavior on color {
                ColorAnimation {
                    duration: root.reducedMotion ? 0 : 160
                }
            }
        }
    }
    component Card: Rectangle {
        color: "#bd141924"
        radius: 26
        border.color: root.borderColor
        // A cheap, static upper rim replaces blur and animated bloom.
        Rectangle {
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
                leftMargin: 26
                rightMargin: 26
            }
            height: 1
            color: "#15ffffff"
        }
    }
    Item {
        id: scene
        objectName: "scene"
        width: 1100
        height: 500
        anchors.centerIn: parent
        scale: root.uiScale * (root.appeared && !root.leaving ? 1 : 0.97)
        opacity: root.appeared && !root.leaving ? 1 : 0
        enabled: !root.leaving
        Behavior on opacity {
            NumberAnimation {
                duration: root.reducedMotion ? 0 : 400
                easing.type: Easing.OutCubic
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.reducedMotion ? 0 : 500
                easing.type: Easing.OutCubic
            }
        }

        Column {
            width: 270
            spacing: 16
            Card {
                width: parent.width
                height: 264
                Column {
                    anchors {
                        fill: parent
                        margins: 26
                    }
                    spacing: 16
                    Text {
                        text: Qt.formatDate(root.now, "dddd").toUpperCase()
                        color: root.secondary
                        font {
                            pixelSize: 10
                            letterSpacing: 1.5
                            weight: Font.Medium
                        }
                    }
                    Text {
                        text: Qt.formatTime(root.now, "HH:mm")
                        color: root.foreground
                        font {
                            pixelSize: 62
                            weight: Font.Light
                            letterSpacing: -3
                        }
                    }
                    Text {
                        width: parent.width
                        text: Qt.formatDate(root.now, "d MMMM yyyy")
                        color: root.secondary
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                    Item {
                        width: 1
                        height: 6
                    }
                    Rectangle {
                        width: parent.width
                        height: 1
                        color: root.borderColor
                    }
                    Row {
                        width: parent.width
                        spacing: 9
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 3
                            color: root.lavender
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            width: parent.width - 14
                            text: String(sddm.hostName || "Raohane")
                            color: root.secondary
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }
                    }
                }
            }
            Card {
                width: parent.width
                height: 220
                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 18
                    }
                    spacing: 4
                    Text {
                        text: qsTr("TAKE A BREAK")
                        color: root.secondary
                        font {
                            pixelSize: 10
                            letterSpacing: 1.4
                        }
                        Layout.leftMargin: 10
                        Layout.bottomMargin: 6
                    }
                    Pill {
                        text: qsTr("Suspend")
                        symbol: "☾"
                        Layout.fillWidth: true
                        enabled: sddm.canSuspend && !root.pending
                        onClicked: sddm.suspend()
                    }
                    Pill {
                        text: qsTr("Restart")
                        symbol: "↻"
                        Layout.fillWidth: true
                        enabled: sddm.canReboot && !root.pending
                        onClicked: sddm.reboot()
                    }
                    Pill {
                        text: qsTr("Power off")
                        symbol: "⏻"
                        Layout.fillWidth: true
                        enabled: sddm.canPowerOff && !root.pending
                        onClicked: sddm.powerOff()
                    }
                }
            }
        }

        Column {
            width: 440
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 20
            Rectangle {
                width: 136
                height: 136
                radius: 68
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#661f2432"
                border.color: root.borderColor
                Canvas {
                    id: avatarImage
                    anchors {
                        fill: parent
                        margins: 4
                    }
                    property url source: Qt.resolvedUrl(String(config.Avatar || "avatar.svg"))
                    onSourceChanged: loadImage(source)
                    Component.onCompleted: loadImage(source)
                    onImageLoaded: requestPaint()
                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        if (!isImageLoaded(source))
                            return;
                        ctx.save();
                        ctx.beginPath();
                        ctx.arc(width / 2, height / 2, width / 2, 0, Math.PI * 2);
                        ctx.clip();
                        ctx.drawImage(source, 0, 0, width, height);
                        ctx.restore();
                    }
                }
            }

            Column {
                width: parent.width
                spacing: 3
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.leaving ? qsTr("Welcome home") : qsTr("Welcome back")
                    color: root.secondary
                    font.pixelSize: 13
                }
            }
            Column {
                width: parent.width
                spacing: 14
                transform: Translate {
                    id: shakeTransform
                }
                Rectangle {
                    width: parent.width
                    height: 60
                    radius: 21
                    color: "#ce1c2230"
                    border.color: root.failed ? "#d8c18f9d" : password.activeFocus ? "#8cc1b2ea" :
                                                                                     root.borderColor
                    Behavior on border.color {
                        ColorAnimation {
                            duration: root.reducedMotion ? 0 : 140
                        }
                    }
                    Controls.TextField {
                        id: password
                        objectName: "password"
                        anchors {
                            left: parent.left
                            right: submitButton.left
                            top: parent.top
                            bottom: parent.bottom
                            leftMargin: 4
                            rightMargin: 6
                        }
                        enabled: !root.pending
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        passwordMaskDelay: 0
                        inputMethodHints: Qt.ImhHiddenText | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                        placeholderText: qsTr("Enter your password")
                        Accessible.name: qsTr("Password")
                        placeholderTextColor: root.secondary
                        color: root.foreground
                        font.pixelSize: 14
                        leftPadding: 18
                        background: Item {}
                        onAccepted: root.authenticate()
                    }
                    Pill {
                        id: submitButton
                        objectName: "signIn"
                        width: 44
                        height: 44
                        anchors {
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            rightMargin: 8
                        }
                        primary: true
                        text: root.pending ? qsTr("Signing in…") : qsTr("Sign in")
                        symbol: "→"
                        enabled: !root.pending && sessionBox.currentIndex >= 0
                        onClicked: root.authenticate()
                    }
                }
                Text {
                    width: parent.width - 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 36
                    text: root.message.length ? root.message : keyboard.capsLock ? qsTr("Caps Lock is on") :
                                                                                   qsTr("Press Enter to sign in")
                    color: root.failed ? "#e0b2bd" : root.secondary
                    opacity: root.message.length || keyboard.capsLock ? 1 : 0.65
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                }
            }
        }

        Column {
            width: 270
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: 16

            Card {
                width: parent.width
                height: 124
                ColumnLayout {
                    anchors {
                        fill: parent
                        margins: 16
                    }
                    Text {
                        text: qsTr("DESKTOP SESSION")
                        color: root.secondary
                        font {
                            pixelSize: 10
                            letterSpacing: 1
                        }
                    }
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
                        contentItem: Text {
                            text: sessionBox.displayText
                            color: root.foreground
                            font.pixelSize: 13
                            elide: Text.ElideRight
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            radius: 34
                            color: "#661f2735"
                            border.color: sessionBox.activeFocus ? root.lavender : root.borderColor
                        }
                        indicator: Text {
                            anchors {
                                right: parent.right
                                verticalCenter: parent.verticalCenter
                                rightMargin: 15
                            }
                            text: "⌄"
                            color: root.secondary
                            font.pixelSize: 17
                        }
                        delegate: Controls.ItemDelegate {
                            width: sessionBox.width
                            contentItem: Text {
                                text: model.name
                                color: root.foreground
                                elide: Text.ElideRight
                                font.pixelSize: 13
                            }
                            background: Rectangle {
                                color: highlighted ? "#39334f" : "#1b1e2c"
                            }
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
                            background: Rectangle {
                                color: "#1b1e2c"
                                radius: 16
                                border.color: root.borderColor
                            }
                        }
                    }
                }
            }
        }
    }
    SequentialAnimation {
        id: shake
        NumberAnimation {
            target: shakeTransform
            property: "x"
            to: -8
            duration: 45
        }
        NumberAnimation {
            target: shakeTransform
            property: "x"
            to: 8
            duration: 65
        }
        NumberAnimation {
            target: shakeTransform
            property: "x"
            to: 0
            duration: 80
        }
    }
}
