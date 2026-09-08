pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property var toplevel
    signal activated(var toplevel)

    readonly property bool activeWindow: Boolean(root.toplevel?.activated)

    Layout.fillWidth: true
    Layout.preferredHeight: 34
    surfaceRadius: 8
    transparentIdle: !root.activeWindow && !root.hovered
    active: root.activeWindow
    hovered: pointer.containsMouse || activeFocus
    pressed: pointer.pressed
    interactive: true
    showSheen: false
    hoverScale: 1
    pressedScale: 1
    activeFocusOnTab: !!root.toplevel?.wayland
    opacity: root.toplevel?.wayland ? 1 : 0.62
    border.color: root.activeWindow
        ? RaohaneTheme.accentBorder
        : root.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
            bottom: parent.bottom
            leftMargin: 2
            topMargin: 8
            bottomMargin: 8
        }
        width: 3
        radius: 2
        color: root.toplevel?.urgent
            ? RaohaneTheme.critical
            : root.activeWindow ? RaohaneTheme.accent : RaohaneTheme.textFaint
        opacity: root.activeWindow || root.toplevel?.urgent ? 1 : 0.30

        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 9
        anchors.rightMargin: 8
        spacing: 7

        RaohaneIcon {
            text: root.toplevel?.urgent ? "priority_high" : "web_asset"
            iconSize: 13
            fill: root.activeWindow || root.toplevel?.urgent ? 1 : 0
            symbolWeight: root.activeWindow ? 520 : 390
            color: root.toplevel?.urgent
                ? RaohaneTheme.critical
                : root.activeWindow ? RaohaneTheme.accent : RaohaneTheme.textFaint
        }

        Text {
            Layout.fillWidth: true
            text: root.toplevel?.title ?? qsTr("Window")
            color: root.activeWindow ? RaohaneTheme.text : RaohaneTheme.textMuted
            font.pixelSize: 8
            font.weight: root.activeWindow ? Font.DemiBold : Font.Medium
            elide: Text.ElideRight
        }

        Rectangle {
            visible: root.activeWindow
            width: 6
            height: 6
            radius: 3
            color: RaohaneTheme.accent
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
        onPressed: root.forceActiveFocus()
        onClicked: root.activated(root.toplevel)
    }

    Keys.onPressed: event => {
        if (!root.toplevel?.wayland)
            return
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.activated(root.toplevel)
            event.accepted = true
        }
    }
}
