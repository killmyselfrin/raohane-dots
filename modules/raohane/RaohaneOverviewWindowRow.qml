pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property var toplevel
    signal activated(var toplevel)

    readonly property bool activeWindow: Boolean(root.toplevel?.activated)

    Layout.fillWidth: true
    Layout.preferredHeight: 26
    surfaceRadius: 8
    transparentIdle: !root.activeWindow && !root.hovered
    active: root.activeWindow
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    interactive: true
    showSheen: false
    hoverScale: 1
    pressedScale: 1
    opacity: root.toplevel?.wayland ? 1 : 0.65
    border.color: root.activeWindow
        ? RaohaneTheme.accentBorder
        : root.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 7
        anchors.rightMargin: 7
        spacing: 7

        Rectangle {
            width: root.activeWindow ? 2 : 5
            height: root.activeWindow ? 13 : 5
            radius: width / 2
            color: root.toplevel?.urgent
                ? RaohaneTheme.critical
                : root.activeWindow ? RaohaneTheme.accent : RaohaneTheme.textFaint

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            Behavior on width {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }
            Behavior on height {
                NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.toplevel?.title ?? qsTr("Window")
            color: root.activeWindow ? RaohaneTheme.text : RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: root.activeWindow ? Font.DemiBold : Font.Normal
            elide: Text.ElideRight
        }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        z: 2
        enabled: !!root.toplevel?.wayland
        hoverEnabled: true
        preventStealing: true
        acceptedButtons: Qt.LeftButton
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.activated(root.toplevel)
    }
}
