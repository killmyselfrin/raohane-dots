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
