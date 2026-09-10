pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property string currentMode
    signal modeRequested(string prefix)

    spacing: RaohaneTheme.spacingSmall

    ModeChip { Layout.fillWidth: true; label: qsTr("Apps"); icon: "apps"; prefix: ""; selected: root.currentMode === "app" }
    ModeChip { Layout.fillWidth: true; label: qsTr("Actions"); icon: "bolt"; prefix: "/"; selected: root.currentMode === "action" }
    ModeChip { Layout.fillWidth: true; label: qsTr("Commands"); icon: "terminal"; prefix: ">"; selected: root.currentMode === "command" }
    ModeChip { Layout.fillWidth: true; label: qsTr("Math"); icon: "calculate"; prefix: "="; selected: root.currentMode === "calculator" }
    ModeChip { Layout.fillWidth: true; label: qsTr("Clipboard"); icon: "content_paste"; prefix: ":"; selected: root.currentMode === "clipboard" }

    component ModeChip: RaohaneSurface {
        id: chip

        required property string label
        required property string icon
        required property string prefix
        property bool selected: false

        Layout.preferredHeight: 34
        surfaceRadius: RaohaneTheme.radius
        active: selected
        hovered: chipMouse.containsMouse || activeFocus
        pressed: chipMouse.pressed
        interactive: true
        transparentIdle: !selected && !hovered
        showSheen: false
        showInnerRim: selected
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        idleBorderColor: "transparent"
        hoverBorderColor: RaohaneTheme.borderStrong
        pressedBorderColor: RaohaneTheme.borderStrong
        activeBorderColor: RaohaneTheme.accentBorder

        Row {
            anchors.centerIn: parent
            spacing: RaohaneTheme.spacingSmall - 1

            RaohaneIcon {
                text: chip.icon
                iconSize: 12
                fill: chip.selected ? 1 : 0
                symbolWeight: chip.selected ? 540 : 430
                color: chip.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: chip.label
                color: chip.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 7
                font.weight: chip.selected ? Font.DemiBold : Font.Medium
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: chip.forceActiveFocus()
            onClicked: root.modeRequested(chip.prefix)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.modeRequested(chip.prefix)
                event.accepted = true
            }
        }
    }
}
