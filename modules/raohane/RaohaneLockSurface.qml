pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    required property var context
    property date now: new Date()
    property bool entered: false

    readonly property bool compact: width < 920 || height < 650
    readonly property string wallpaperSource: RaohaneConfig.lockWallpaperPath.length > 0
        ? RaohaneConfig.lockWallpaperPath
        : (RaohaneConfig.wallpaperPath.length > 0 ? RaohaneConfig.wallpaperPath : RaohanePaths.defaultWallpaperUrl)
    readonly property string displayName: RaohaneConfig.profileDisplayName.length > 0
        ? RaohaneConfig.profileDisplayName
        : (RaohanePaths.username.length > 0 ? RaohanePaths.username : qsTr("User"))

    Component.onCompleted: Qt.callLater(() => root.entered = true)

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    Image {
        anchors.fill: parent
        source: root.wallpaperSource
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
    }

    Rectangle {
        anchors.fill: parent
        color: RaohaneTheme.dark ? "#9007090b" : "#76534f49"
        opacity: root.entered ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
        }
    }

    // Quiet atmospheric depth without relying on graphical-effect plugins.
    Rectangle {
        width: Math.max(root.width, root.height) * 0.72
        height: width
        radius: width / 2
        x: -width * 0.34
        y: -height * 0.40
        color: RaohaneTheme.accent
        opacity: root.entered ? (RaohaneTheme.dark ? 0.055 : 0.075) : 0

        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.mediumDuration } }
    }

    Rectangle {
        width: Math.max(root.width, root.height) * 0.58
        height: width
        radius: width / 2
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.rightMargin: -width * 0.32
        anchors.bottomMargin: -height * 0.34
        color: RaohaneTheme.accent
        opacity: root.entered ? (RaohaneTheme.dark ? 0.035 : 0.055) : 0

        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.mediumDuration } }
    }

    Item {
        id: stage
        width: Math.min(parent.width - (root.compact ? 38 : 100), 1120)
        height: Math.min(parent.height - (root.compact ? 42 : 90), 690)
        anchors.centerIn: parent
        opacity: root.entered ? 1 : 0

        transform: Translate {
            y: root.entered ? 0 : 14
            Behavior on y {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
        }

        Item {
            id: timePane
            visible: !root.compact
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                right: authCard.left
                rightMargin: 58
            }

            Column {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4

                Row {
                    spacing: 8

                    Rectangle {
                        width: 28
                        height: 2
                        radius: 1
                        anchors.verticalCenter: parent.verticalCenter
                        color: RaohaneTheme.accent
                        opacity: 0.85
                    }

                    Text {
                        text: qsTr("RAOHANE · SECURE SESSION")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.25
                    }
                }

                Text {
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: RaohaneTheme.text
                    font.pixelSize: Math.min(104, Math.max(72, root.height * 0.11))
                    font.weight: Font.ExtraLight
                    font.letterSpacing: -2.5
                }

                Text {
                    text: Qt.formatDate(root.now, "dddd, d MMMM")
                    color: RaohaneTheme.text
                    opacity: 0.82
                    font.pixelSize: 16
                    font.weight: Font.Medium
                }

                Text {
                    width: Math.min(470, timePane.width)
                    topPadding: 12
                    text: qsTr("Your workspace is protected. Authenticate to continue where you left off.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                    lineHeight: 1.35
                    wrapMode: Text.WordWrap
                }
            }

            Row {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 8
                spacing: 8

                RaohaneIcon {
                    text: "verified_user"
                    iconSize: 16
                    fill: 1
                    symbolWeight: 500
                    color: RaohaneTheme.accent
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.context.fingerprintsConfigured ? qsTr("Password + fingerprint ready") : qsTr("Protected by system authentication")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                }
            }
        }

        RaohaneSurface {
            id: authCard
            width: root.compact ? Math.min(stage.width, 500) : 430
            height: root.compact ? Math.min(stage.height, 590) : Math.min(stage.height, 610)
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: root.compact ? parent.horizontalCenter : undefined
            anchors.right: root.compact ? undefined : parent.right
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: true
            border.color: RaohaneTheme.borderStrong
            clip: true
            scale: root.entered ? 1 : 0.978

            Behavior on scale {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }

            Rectangle {
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                }
                width: 3
                color: RaohaneTheme.accent
                opacity: 0.72
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: root.compact ? 24 : 28
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Item {
                        Layout.preferredWidth: 62
                        Layout.preferredHeight: 62

                        RaohaneSurface {
                            anchors.fill: parent
                            surfaceRadius: 20
                            active: true
                            showSheen: false

                            Image {
                                anchors.fill: parent
                                anchors.margins: 3
                                visible: RaohaneConfig.profileAvatarPath.length > 0
                                source: RaohaneConfig.profileAvatarPath
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                mipmap: true
                                clip: true
                            }

                            RaohaneIcon {
                                anchors.centerIn: parent
                                visible: RaohaneConfig.profileAvatarPath.length === 0
                                text: "person"
                                iconSize: 27
                                fill: 1
                                symbolWeight: 520
                                color: RaohaneTheme.accent
                            }
                        }

                        Rectangle {
                            width: 13
                            height: 13
                            radius: 7
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            color: RaohaneTheme.accent
                            border.width: 3
                            border.color: RaohaneTheme.surfaceRaised
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            text: root.displayName
                            color: RaohaneTheme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Session locked")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }

                    RaohaneSurface {
                        Layout.preferredWidth: 38
                        Layout.preferredHeight: 38
                        surfaceRadius: 12
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "lock"
                            iconSize: 18
                            fill: 1
                            symbolWeight: 560
                            color: RaohaneTheme.accent
                        }
                    }
                }

                ColumnLayout {
                    visible: root.compact
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatTime(root.now, "HH:mm")
                        color: RaohaneTheme.text
                        font.pixelSize: root.height < 600 ? 42 : 52
                        font.weight: Font.Light
                    }

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: Qt.formatDate(root.now, "dddd, d MMMM")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 10
                    }
                }

                Item { Layout.preferredHeight: root.compact ? 2 : 14 }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Welcome back")
                    color: RaohaneTheme.text
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: root.context.fingerprintsConfigured
                        ? qsTr("Enter your password or touch the fingerprint sensor to unlock.")
                        : qsTr("Enter your password to unlock the Raohane session.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    lineHeight: 1.28
                    wrapMode: Text.WordWrap
                }

                Item { Layout.preferredHeight: 4 }

                RaohaneSurface {
                    id: passwordBox
                    Layout.fillWidth: true
                    height: 54
                    surfaceRadius: 16
                    raised: false
                    hovered: passwordInput.activeFocus
                    showSheen: false
                    border.width: root.context.showFailure || passwordInput.activeFocus ? 1 : 1
                    border.color: root.context.showFailure ? RaohaneTheme.critical
                        : passwordInput.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                    transform: Translate { id: failureTranslate; x: 0 }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 15
                        anchors.rightMargin: 7
                        spacing: 9

                        RaohaneIcon {
                            text: root.context.showFailure ? "lock_reset" : "password"
                            iconSize: 18
                            fill: root.context.showFailure ? 1 : 0
                            symbolWeight: root.context.showFailure ? 560 : 430
                            color: root.context.showFailure ? RaohaneTheme.critical : RaohaneTheme.textMuted

                            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                        }

                        TextInput {
                            id: passwordInput
                            Layout.fillWidth: true
                            text: root.context.currentText
                            color: RaohaneTheme.text
                            selectionColor: RaohaneTheme.accentSoft
                            selectedTextColor: RaohaneTheme.text
                            echoMode: TextInput.Password
                            passwordCharacter: "●"
                            font.pixelSize: 15
                            clip: true
                            enabled: !root.context.unlockInProgress

                            onTextEdited: root.context.currentText = text

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    root.context.tryUnlock()
                                    event.accepted = true
                                }
                            }

                            Component.onCompleted: forceActiveFocus()
                        }

                        RaohaneIconButton {
                            buttonSize: 39
                            iconSize: 18
                            icon: root.context.unlockInProgress ? "hourglass_top" : "arrow_forward"
                            emphasized: !root.context.unlockInProgress && root.context.currentText.length > 0
                            transparentIdle: !emphasized
                            showSheen: false
                            enabled: !root.context.unlockInProgress && root.context.currentText.length > 0
                            onClicked: root.context.tryUnlock()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RaohaneIcon {
                        text: root.context.showFailure ? "error" : root.context.fingerprintsConfigured ? "fingerprint" : "shield_lock"
                        iconSize: 16
                        fill: root.context.showFailure ? 1 : 0
                        symbolWeight: 500
                        color: root.context.showFailure ? RaohaneTheme.critical
                            : root.context.fingerprintsConfigured ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.context.showFailure
                            ? qsTr("Authentication failed. Check your password and try again.")
                            : root.context.unlockInProgress
                                ? qsTr("Checking your credentials…")
                                : root.context.fingerprintsConfigured
                                    ? qsTr("Fingerprint sensor is ready")
                                    : qsTr("System authentication is ready")
                        color: root.context.showFailure ? RaohaneTheme.critical : RaohaneTheme.textMuted
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap

                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    }
                }

                Item { Layout.fillHeight: true }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: qsTr("POWER")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                            font.weight: Font.DemiBold
                            font.letterSpacing: 0.8
                        }

                        Text {
                            text: qsTr("Session remains locked")
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                        }
                    }

                    SystemButton {
                        icon: "bedtime"
                        tooltip: qsTr("Suspend")
                        onTriggered: RaohaneSession.suspend()
                    }
                    SystemButton {
                        icon: "restart_alt"
                        tooltip: qsTr("Reboot")
                        danger: true
                        onTriggered: RaohaneSession.reboot()
                    }
                    SystemButton {
                        icon: "power_settings_new"
                        tooltip: qsTr("Power off")
                        danger: true
                        onTriggered: RaohaneSession.poweroff()
                    }
                }
            }
        }
    }

    Connections {
        target: root.context

        function onShouldRefocus(): void {
            passwordInput.forceActiveFocus()
        }

        function onShowFailureChanged(): void {
            if (root.context.showFailure)
                failureAnimation.restart()
        }
    }

    SequentialAnimation {
        id: failureAnimation
        running: false
        NumberAnimation { target: failureTranslate; property: "x"; to: -7; duration: 55 }
        NumberAnimation { target: failureTranslate; property: "x"; to: 7; duration: 70 }
        NumberAnimation { target: failureTranslate; property: "x"; to: -4; duration: 60 }
        NumberAnimation { target: failureTranslate; property: "x"; to: 4; duration: 55 }
        NumberAnimation { target: failureTranslate; property: "x"; to: 0; duration: 50 }
    }

    component SystemButton: RaohaneSurface {
        id: control
        required property string icon
        property string tooltip: ""
        property bool danger: false
        signal triggered()

        width: 40
        height: 40
        surfaceRadius: 12
        transparentIdle: true
        showSheen: false
        interactive: true
        feedback: danger ? "confirm" : "tap"
        hovered: pointer.containsMouse || activeFocus
        pressed: pointer.pressed
        hoverScale: RaohaneMotion.hoverScale
        pressedScale: RaohaneMotion.pressScale
        activeFocusOnTab: true
        border.color: control.danger && control.hovered ? RaohaneTheme.critical
            : control.hovered || control.pressed ? RaohaneTheme.borderStrong : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: control.icon
            iconSize: 18
            fill: control.hovered || control.activeFocus ? 1 : 0
            symbolWeight: control.pressed ? 560 : control.hovered || control.activeFocus ? 520 : 430
            color: control.danger && (control.hovered || control.activeFocus)
                ? RaohaneTheme.critical
                : control.hovered || control.activeFocus ? RaohaneTheme.text : RaohaneTheme.textMuted

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: control.forceActiveFocus()
            onClicked: control.triggered()
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                control.triggered()
                event.accepted = true
            }
        }
    }
}
