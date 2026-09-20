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

    signal networkRequested()
    signal bluetoothRequested()
    signal audioRequested()

    implicitHeight: 60
    surfaceRadius: RaohaneTheme.radiusLarge
    raised: false
    showSheen: false
    showInnerRim: false
    transparentIdle: true
    idleBorderColor: "transparent"
    showStateRail: false
    clip: true

    GridLayout {
        anchors.fill: parent
        columns: 4
        columnSpacing: RaohaneTheme.spacingSmall
        rowSpacing: 0

        StatusCell {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: root.networkIcon
            label: qsTr("Network")
            value: root.networkValue
            statusActive: root.networkActive
            clickable: true
            onTriggered: root.networkRequested()
        }

        StatusCell {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: root.bluetoothIcon
            label: qsTr("Bluetooth")
            value: root.bluetoothValue
            statusActive: root.bluetoothActive
            clickable: true
            onTriggered: root.bluetoothRequested()
        }

        StatusCell {
            Layout.fillWidth: true
            Layout.fillHeight: true
            icon: root.audioIcon
            label: qsTr("Audio")
            value: root.audioValue
            statusActive: root.audioActive
            clickable: true
            onTriggered: root.audioRequested()
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
        property bool clickable: false
        signal triggered()

        surfaceRadius: RaohaneTheme.radius
        raised: false
        showSheen: false
        showInnerRim: false
        interactive: status.clickable
        hovered: status.clickable && (statusMouse.containsMouse || activeFocus)
        pressed: status.clickable && statusMouse.pressed
        activeFocusOnTab: status.clickable
        hoverScale: 1
        pressedScale: 1
        idleColor: RaohaneTheme.surfaceSubtle
        idleBorderColor: RaohaneTheme.borderFaint
        hoverColor: RaohaneTheme.surfaceHover
        hoverBorderColor: RaohaneTheme.borderStrong
        active: status.statusActive
        activeColor: status.critical
            ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.10)
            : RaohaneTheme.accentSoft
        activeBorderColor: status.critical
            ? Qt.rgba(RaohaneTheme.critical.r, RaohaneTheme.critical.g, RaohaneTheme.critical.b, 0.28)
            : RaohaneTheme.accentBorder

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacing
            anchors.rightMargin: RaohaneTheme.spacing
            anchors.topMargin: RaohaneTheme.spacingSmall
            anchors.bottomMargin: RaohaneTheme.spacingSmall
            spacing: 1

            RowLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacingSmall

                RaohaneIcon {
                    text: status.icon
                    iconSize: 15
                    fill: status.statusActive ? 1 : status.hovered ? 0.35 : 0
                    color: status.critical ? RaohaneTheme.critical
                        : status.statusActive || status.hovered ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: status.label
                    color: status.statusActive || status.hovered ? RaohaneTheme.textMuted : RaohaneTheme.textFaint
                    font.pixelSize: 8
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }
            }

            Text {
                Layout.fillWidth: true
                text: status.value
                color: status.critical ? RaohaneTheme.critical : RaohaneTheme.text
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }

        MouseArea {
            id: statusMouse
            anchors.fill: parent
            enabled: status.clickable
            hoverEnabled: status.clickable
            cursorShape: status.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: status.forceActiveFocus()
            onClicked: status.triggered()
        }

        Keys.onPressed: event => {
            if (!status.clickable)
                return
            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                status.triggered()
                event.accepted = true
            }
        }
    }
}
