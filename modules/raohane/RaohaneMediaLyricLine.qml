pragma ComponentBehavior: Bound

import QtQuick

RaohaneSurface {
    id: root

    required property var lineData
    property bool current: false
    property bool focusMode: false
    property bool seekEnabled: false
    property color accent: RaohaneTheme.accent
    property color focusActive: RaohaneTheme.text
    property color focusSecondary: RaohaneTheme.textMuted
    property color focusHalo: "transparent"

    signal seekRequested(real time)

    height: lyricText.implicitHeight + (root.focusMode ? 28 : 16)
    surfaceRadius: RaohaneTheme.radius
    raised: false
    active: root.current && !root.focusMode
    transparentIdle: true
    showSheen: false
    showInnerRim: false
    showStateRail: root.current && !root.focusMode
    stateRailColor: root.accent
    stateRailOpacity: 1
    stateRailLength: Math.min(root.height - 16, 28)
    idleBorderColor: "transparent"
    activeBorderColor: "transparent"

    Text {
        id: lyricText
        anchors {
            left: parent.left
            right: parent.right
            verticalCenter: parent.verticalCenter
            leftMargin: root.focusMode ? 24 : 14
            rightMargin: root.focusMode ? 24 : 14
        }
        text: String(root.lineData?.text ?? "")
        color: root.focusMode
            ? (root.current ? root.focusActive : root.focusSecondary)
            : (root.current ? RaohaneTheme.text : RaohaneTheme.textMuted)
        font.pixelSize: root.focusMode ? 15 : 10
        font.weight: root.current ? Font.DemiBold : root.focusMode ? Font.Medium : Font.Normal
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        style: root.focusMode ? Text.Outline : Text.Normal
        styleColor: root.focusMode ? root.focusHalo : "transparent"
    }

    MouseArea {
        anchors.fill: parent
        enabled: root.seekEnabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.seekRequested(Number(root.lineData?.time ?? -1))
    }
}
