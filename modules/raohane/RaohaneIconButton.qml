import QtQuick

RaohaneSurface {
    id: root

    required property string icon
    property int buttonSize: 30
    property int iconSize: 17
    property bool emphasized: false
    signal clicked()

    implicitWidth: buttonSize
    implicitHeight: buttonSize
    surfaceRadius: Math.round(buttonSize / 3)
    active: emphasized
    hovered: pointer.containsMouse

    RaohaneIcon {
        anchors.centerIn: parent
        text: root.icon
        iconSize: root.iconSize
        color: root.emphasized || pointer.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
