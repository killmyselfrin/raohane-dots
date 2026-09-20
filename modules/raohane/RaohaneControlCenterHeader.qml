pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string identityText
    required property string timeText
    required property string dateText

    signal launcherRequested()
    signal settingsRequested()
    signal powerRequested()

    implicitHeight: 48

    RowLayout {
        anchors.fill: parent
        spacing: RaohaneTheme.spacing

        RaohaneSurface {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            Layout.alignment: Qt.AlignVCenter
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            active: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            idleBorderColor: "transparent"

            RaohaneIcon {
                anchors.centerIn: parent
                text: "spa"
                iconSize: 19
                fill: 1
                symbolWeight: 560
                grade: 40
                color: RaohaneTheme.accent
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            Text {
                text: "Raohane"
                color: RaohaneTheme.text
                font.pixelSize: 12
                font.weight: Font.DemiBold
                font.letterSpacing: 0.2
            }

            Text {
                Layout.fillWidth: true
                text: root.identityText
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                elide: Text.ElideRight
            }
        }

        RaohaneSurface {
            id: searchButton
            Layout.preferredWidth: 210
            Layout.preferredHeight: 32
            Layout.alignment: Qt.AlignVCenter
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            interactive: true
            hovered: searchMouse.containsMouse || activeFocus
            pressed: searchMouse.pressed
            activeFocusOnTab: true
            idleColor: RaohaneTheme.surfaceSubtle
            idleBorderColor: "transparent"
            hoverColor: RaohaneTheme.surfaceHover
            hoverBorderColor: "transparent"
            hoverScale: 1
            pressedScale: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: RaohaneTheme.spacing
                anchors.rightMargin: RaohaneTheme.spacing
                spacing: RaohaneTheme.spacingSmall

                RaohaneIcon {
                    text: "search"
                    iconSize: 14
                    color: searchButton.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Search")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                }

                Text {
                    text: "SUPER + R"
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }

            MouseArea {
                id: searchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onPressed: searchButton.forceActiveFocus()
                onClicked: root.launcherRequested()
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                    root.launcherRequested()
                    event.accepted = true
                }
            }
        }

        ColumnLayout {
            spacing: 0

            Text {
                Layout.alignment: Qt.AlignRight
                text: root.timeText
                color: RaohaneTheme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                Layout.alignment: Qt.AlignRight
                text: root.dateText
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
            }
        }

        HeaderButton {
            icon: "settings"
            onClicked: root.settingsRequested()
        }

        HeaderButton {
            icon: "power_settings_new"
            emphasized: true
            onClicked: root.powerRequested()
        }
    }

    component HeaderButton: RaohaneIconButton {
        Layout.preferredWidth: 32
        Layout.preferredHeight: 32
        buttonSize: 30
        iconSize: 14
        transparentIdle: !emphasized
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
