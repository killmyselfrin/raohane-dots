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

    readonly property string wallpaperSource: RaohaneConfig.lockWallpaperPath.length > 0
        ? RaohaneConfig.lockWallpaperPath
        : (RaohaneConfig.wallpaperPath.length > 0 ? RaohaneConfig.wallpaperPath : RaohanePaths.defaultWallpaperUrl)

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
        color: RaohaneTheme.dark ? "#8c000000" : "#785b5750"
        opacity: root.entered ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
        }
    }

    RaohaneSurface {
        id: lockCard
        width: Math.min(parent.width - 64, 500)
        height: Math.min(parent.height - 86, 560)
        anchors.centerIn: parent
        surfaceRadius: RaohaneTheme.radiusHero
        raised: true
        showSheen: false
        border.color: RaohaneTheme.borderStrong
        opacity: root.entered ? 1 : 0
        scale: root.entered ? 1 : 0.982

        transform: Translate {
            y: root.entered ? 0 : 12
            Behavior on y {
                NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
            }
        }

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeStandard }
        }
        Behavior on scale {
            NumberAnimation { duration: RaohaneMotion.mediumDuration; easing.type: RaohaneMotion.easeEmphasized }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 15

            Item { Layout.fillHeight: true }

            RaohaneSurface {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                surfaceRadius: 20
                active: true
                showSheen: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "lock"
                    iconSize: 27
                    fill: 1
                    symbolWeight: 540
                    color: RaohaneTheme.accent
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(root.now, "HH:mm")
                color: RaohaneTheme.text
                font.pixelSize: 52
                font.weight: Font.Light
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(root.now, "dddd, d MMMM")
                color: RaohaneTheme.textMuted
                font.pixelSize: 11
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: RaohanePaths.username.length > 0 ? RaohanePaths.username : qsTr("User")
                color: RaohaneTheme.text
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            RaohaneSurface {
                id: passwordBox
                Layout.fillWidth: true
                Layout.maximumWidth: 380
                Layout.alignment: Qt.AlignHCenter
                height: 50
                surfaceRadius: 15
                raised: false
                hovered: passwordInput.activeFocus
                showSheen: false
                border.color: root.context.showFailure ? RaohaneTheme.critical
                    : passwordInput.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 7
                    spacing: 9

                    RaohaneIcon {
                        text: root.context.showFailure ? "lock_reset" : "lock"
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
                        buttonSize: 36
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

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: root.context.showFailure
                    ? qsTr("Authentication failed. Try again.")
                    : root.context.fingerprintsConfigured
                        ? qsTr("Enter password or use your fingerprint")
                        : qsTr("Enter your password to unlock")
                color: root.context.showFailure ? RaohaneTheme.critical : RaohaneTheme.textMuted
                font.pixelSize: 9

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 7

                SystemButton {
                    icon: "bedtime"
                    onTriggered: RaohaneSession.suspend()
                }
                SystemButton {
                    icon: "restart_alt"
                    danger: true
                    onTriggered: RaohaneSession.reboot()
                }
                SystemButton {
                    icon: "power_settings_new"
                    danger: true
                    onTriggered: RaohaneSession.poweroff()
                }
            }

            Item { Layout.fillHeight: true }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6

                Rectangle {
                    width: 5
                    height: 5
                    radius: 3
                    color: root.context.fingerprintsConfigured ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    scale: root.context.fingerprintsConfigured ? 1.12 : 1

                    Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    Behavior on scale {
                        NumberAnimation { duration: RaohaneMotion.shortDuration; easing.type: RaohaneMotion.easeEmphasized }
                    }
                }

                Text {
                    text: root.context.fingerprintsConfigured ? qsTr("Fingerprint ready") : qsTr("Secure session")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }
        }
    }

    Connections {
        target: root.context
        function onShouldRefocus(): void { passwordInput.forceActiveFocus() }
    }

    component SystemButton: RaohaneSurface {
        id: control
        required property string icon
        property bool danger: false
        signal triggered()

        width: 40
        height: 40
        surfaceRadius: 12
        transparentIdle: true
        showSheen: false
        interactive: true
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
