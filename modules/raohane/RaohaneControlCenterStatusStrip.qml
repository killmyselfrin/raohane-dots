pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property string networkIcon
    required property string networkValue
    property bool networkActive: false

    required property string bluetoothIcon
    required property string bluetoothValue
    property bool bluetoothActive: false

    required property string audioIcon
    required property string audioValue
    property bool audioActive: false

    required property string privacyValue
    property bool privacyActive: false

    implicitHeight: 68
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    showInnerRim: false
    idleColor: RaohaneTheme.surfaceSubtle
    idleBorderColor: RaohaneTheme.borderFaint
    showStateRail: root.privacyActive
    stateRailColor: RaohaneTheme.critical
    stateRailWidth: 2
    stateRailLength: 28
    stateRailOpacity: 0.82
    clip: true

    GridLayout {
        anchors.fill: parent
        anchors.margins: RaohaneTheme.spacingSmall
        columns: 4
        columnSpacing: RaohaneTheme.spacingTiny
        rowSpacing: 0

        StatusCell {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: root.networkIcon
            label: qsTr("Network")
            value: root.networkValue
            statusActive: root.networkActive
        }

        StatusCell {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: root.bluetoothIcon
            label: qsTr("Bluetooth")
            value: root.bluetoothValue
            statusActive: root.bluetoothActive
        }

        StatusCell {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: root.audioIcon
            label: qsTr("Audio")
            value: root.audioValue
            statusActive: root.audioActive
        }

        StatusCell {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: root.privacyActive ? "shield_person" : "verified_user"
            label: qsTr("Privacy")
            value: root.privacyValue
            statusActive: root.privacyActive
            critical: root.privacyActive
        }
    }

    component StatusCell: RaohaneSurface {
        id: status

        required property string icon
        required property string label
        required property string value
        property bool statusActive: false
        property bool critical: false

        surfaceRadius: RaohaneTheme.radiusSmall
        raised: false
        showSheen: false
        showInnerRim: false
        transparentIdle: true
        active: status.statusActive
        activeColor: status.critical
            ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.09)
            : RaohaneTheme.accentSoft
        activeBorderColor: status.critical
            ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.22)
            : RaohaneTheme.accentBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacingSmall
            anchors.rightMargin: RaohaneTheme.spacingSmall
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon {
                text: status.icon
                iconSize: 16
                fill: status.statusActive ? 1 : 0
                color: status.critical ? RaohaneTheme.critical
                    : status.statusActive ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: status.label
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: status.value
                    color: status.critical ? RaohaneTheme.critical : RaohaneTheme.text
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }
}
