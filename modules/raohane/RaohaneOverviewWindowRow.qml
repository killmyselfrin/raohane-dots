pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property var toplevel
    signal activated(var toplevel)

    Layout.fillWidth: true
    Layout.preferredHeight: 26
    surfaceRadius: 8
    transparentIdle: !Boolean(root.toplevel?.activated)
    active: Boolean(root.toplevel?.activated)
    hovered: pointer.containsMouse
    pressed: pointer.pressed
    interactive: true
    showSheen: false
    hoverScale: 1.004
    pressedScale: 0.992
    opacity: root.toplevel?.wayland ? 1 : 0.65

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 7
        anchors.rightMargin: 7
        spacing: 7

        Rectangle {
            width: 5
            height: 5
            radius: 3
            color: root.toplevel?.urgent
                ? RaohaneTheme.critical
                : root.toplevel?.activated ? RaohaneTheme.accent : RaohaneTheme.textFaint

            Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        }

        Text {
            Layout.fillWidth: true
            text: root.toplevel?.title ?? qsTr("Window")
            color: root.toplevel?.activated ? RaohaneTheme.text : RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: root.toplevel?.activated ? Font.DemiBold : Font.Normal
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
