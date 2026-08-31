import QtQuick

FocusScope {
    id: root

    property bool checked: false
    signal toggled(bool checked)

    implicitWidth: 42
    implicitHeight: 24
    activeFocusOnTab: enabled
    opacity: enabled ? 1 : RaohaneMotion.disabledOpacity

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.checked ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceDeep
        border.width: 1
        border.color: root.checked
            ? RaohaneTheme.accentBorder
            : root.activeFocus || pointer.containsMouse
                ? RaohaneTheme.borderStrong
                : RaohaneTheme.border

        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
        Behavior on border.color { ColorAnimation { duration: RaohaneMotion.micro } }
    }

    Rectangle {
        id: thumb
        width: 18
        height: 18
        radius: 9
        anchors.verticalCenter: parent.verticalCenter
        x: root.checked ? root.width - width - 3 : 3
        scale: pointer.pressed ? 0.88 : pointer.containsMouse || root.activeFocus ? 1.06 : 1
        color: root.checked ? RaohaneTheme.accent : RaohaneTheme.surfaceRaised
        border.width: root.checked ? 0 : 1
        border.color: RaohaneTheme.borderStrong

        Behavior on x {
            NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeEmphasized }
        }
        Behavior on scale {
            NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
        }
        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.forceActiveFocus()
        onClicked: root.toggled(!root.checked)
    }

    Keys.onPressed: event => {
        if (!root.enabled)
            return
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            root.toggled(!root.checked)
            event.accepted = true
        }
    }

    Behavior on opacity {
        NumberAnimation { duration: RaohaneMotion.micro; easing.type: RaohaneMotion.easeStandard }
    }
}
