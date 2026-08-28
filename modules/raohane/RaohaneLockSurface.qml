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
        color: "#b4070610"
    }

    Rectangle {
        width: Math.min(parent.width - 48, 520)
        height: Math.min(parent.height - 70, 590)
        anchors.centerIn: parent
        radius: 34
        color: RaohaneTheme.glassStrong
        border.width: 1
        border.color: RaohaneTheme.border

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 30
            spacing: 18

            Item { Layout.fillHeight: true }

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 76
                height: 76
                radius: 25
                color: RaohaneTheme.accentSoft
                border.width: 1
                border.color: RaohaneTheme.border

                Text {
                    anchors.centerIn: parent
                    text: "ラ"
                    color: RaohaneTheme.accent
                    font.pixelSize: 32
                    font.weight: Font.Bold
                }
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatTime(root.now, "HH:mm")
                color: RaohaneTheme.text
                font.pixelSize: 58
                font.weight: Font.Light
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: Qt.formatDate(root.now, "dddd, d MMMM")
                color: RaohaneTheme.textMuted
                font.pixelSize: 13
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: RaohanePaths.username.length > 0 ? RaohanePaths.username : qsTr("User")
                color: RaohaneTheme.text
                font.pixelSize: 17
                font.weight: Font.DemiBold
            }

            Rectangle {
                id: passwordBox
                Layout.fillWidth: true
                Layout.maximumWidth: 390
                Layout.alignment: Qt.AlignHCenter
                height: 54
                radius: 18
                color: root.context.showFailure ? "#2dff668c" : "#20ffffff"
                border.width: 1
                border.color: root.context.showFailure ? RaohaneTheme.critical
                    : passwordInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.border

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 17
                    anchors.rightMargin: 9
                    spacing: 10

                    RaohaneIcon {
                        text: root.context.showFailure ? "lock_reset" : "lock"
                        iconSize: 20
                        color: root.context.showFailure ? RaohaneTheme.critical : RaohaneTheme.textMuted
                    }

                    TextInput {
                        id: passwordInput
                        Layout.fillWidth: true
                        text: root.context.currentText
                        color: RaohaneTheme.text
                        selectionColor: RaohaneTheme.accent
                        selectedTextColor: "#190c20"
                        echoMode: TextInput.Password
                        passwordCharacter: "●"
                        font.pixelSize: 16
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
                        width: 38
                        height: 38
                        radius: 13
                        color: unlockMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.accentSoft

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: root.context.unlockInProgress ? "hourglass_top" : "arrow_forward"
                            iconSize: 19
                            color: root.context.unlockInProgress ? RaohaneTheme.textMuted : RaohaneTheme.text
                        }

                        MouseArea {
                            id: unlockMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
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
                font.pixelSize: 10
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 8

                Rectangle {
                    width: 42
                    height: 42
                    radius: 14
                    color: suspendMouse.containsMouse ? RaohaneTheme.accentSoft : "#18ffffff"
                    border.width: 1
                    border.color: RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "bedtime"
                        iconSize: 19
                        color: RaohaneTheme.textMuted
                    }

                    MouseArea {
                        id: suspendMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: RaohaneSession.suspend()
                    }
                }

                Rectangle {
                    width: 42
                    height: 42
                    radius: 14
                    color: rebootMouse.containsMouse ? "#2dff668c" : "#18ffffff"
                    border.width: 1
                    border.color: rebootMouse.containsMouse ? RaohaneTheme.critical : RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "restart_alt"
                        iconSize: 19
                        color: rebootMouse.containsMouse ? RaohaneTheme.critical : RaohaneTheme.textMuted
                    }

                    MouseArea {
                        id: rebootMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: RaohaneSession.reboot()
                    }
                }

                Rectangle {
                    width: 42
                    height: 42
                    radius: 14
                    color: powerMouse.containsMouse ? "#2dff668c" : "#18ffffff"
                    border.width: 1
                    border.color: powerMouse.containsMouse ? RaohaneTheme.critical : RaohaneTheme.border

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "power_settings_new"
                        iconSize: 19
                        color: powerMouse.containsMouse ? RaohaneTheme.critical : RaohaneTheme.textMuted
                    }

                    MouseArea {
                        id: powerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: RaohaneSession.poweroff()
                    }
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "RAOHANE / LOCK"
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                font.letterSpacing: 1.2
                font.weight: Font.DemiBold
            }
        }
    }

    Connections {
        target: root.context
        function onShouldRefocus(): void { passwordInput.forceActiveFocus() }
    }
}
