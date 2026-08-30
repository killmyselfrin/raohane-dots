pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    required property var context
    property date now: new Date()

    readonly property string wallpaperSource: RaohaneConfig.lockWallpaperPath.length > 0
        ? RaohaneConfig.lockWallpaperPath
        : (RaohaneConfig.wallpaperPath.length > 0 ? RaohaneConfig.wallpaperPath : RaohanePaths.defaultWallpaperUrl)

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
    }

    RaohaneSurface {
        width: Math.min(parent.width - 64, 500)
        height: Math.min(parent.height - 86, 560)
        anchors.centerIn: parent
        surfaceRadius: RaohaneTheme.radiusHero
        raised: true
        showSheen: false
        border.color: RaohaneTheme.borderStrong

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 28
            spacing: 15

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 64
                height: 64
                radius: 20
                color: RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: RaohaneTheme.border

                Text {
                    anchors.centerIn: parent
                    text: "ラ"
                    color: RaohaneTheme.accent
                    font.pixelSize: 25
                    font.weight: Font.DemiBold
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

            Rectangle {
                id: passwordBox
                Layout.fillWidth: true
                Layout.maximumWidth: 380
                Layout.alignment: Qt.AlignHCenter
                height: 50
                radius: 15
                color: passwordInput.activeFocus ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                border.width: 1
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
                        color: root.context.showFailure ? RaohaneTheme.critical : RaohaneTheme.textMuted
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

                    Rectangle {
                        width: 36
                        height: 36
                        radius: 11
                        color: unlockMouse.containsMouse ? RaohaneTheme.surfaceRaised : "transparent"
                        border.width: unlockMouse.containsMouse ? 1 : 0
                        border.color: RaohaneTheme.borderStrong
                        opacity: unlockMouse.enabled ? 1 : 0.45

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.context.unlockInProgress ? "hourglass_top" : "arrow_forward"
                            iconSize: 18
                            fill: 1
                            color: root.context.unlockInProgress ? RaohaneTheme.textMuted : RaohaneTheme.accent
                        }

                        MouseArea {
                            id: unlockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                            enabled: !root.context.unlockInProgress && root.context.currentText.length > 0
                            onClicked: root.context.tryUnlock()
                        }
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

    component SystemButton: Rectangle {
        id: control
        required property string icon
        property bool danger: false
        signal triggered()

        width: 40
        height: 40
        radius: 12
        color: pointer.containsMouse ? RaohaneTheme.surfaceHover : "transparent"
        border.width: pointer.containsMouse ? 1 : 0
        border.color: control.danger && pointer.containsMouse ? RaohaneTheme.critical : RaohaneTheme.border

        RaohaneIcon {
            anchors.centerIn: parent
            text: control.icon
            iconSize: 18
            color: control.danger && pointer.containsMouse ? RaohaneTheme.critical : RaohaneTheme.textMuted
        }

        MouseArea {
            id: pointer
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: control.triggered()
        }
    }
}
