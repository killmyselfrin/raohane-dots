pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    required property string identityText
    required property string timeText
    required property string dateText

    signal settingsRequested()
    signal powerRequested()

    implicitHeight: 60

    RowLayout {
        anchors.fill: parent
        spacing: RaohaneTheme.spacing

        RaohaneSurface {
            Layout.preferredWidth: 44
            Layout.preferredHeight: 44
            Layout.alignment: Qt.AlignVCenter
            surfaceRadius: RaohaneTheme.radiusLarge
            active: true
            showSheen: false
            showInnerRim: false

            RaohaneIcon {
                anchors.centerIn: parent
                text: "spa"
                iconSize: 23
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
                font.pixelSize: 14
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
                font.pixelSize: 7
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
        buttonSize: 32
        iconSize: 15
        transparentIdle: !emphasized
        showSheen: false
        hoverScale: 1
        pressedScale: 1
    }
}
