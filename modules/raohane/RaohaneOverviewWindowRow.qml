pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property var toplevel
    signal activated(var toplevel)
    // The parent Overview owns one floating drag proxy rather than moving
    // delegates managed by a ColumnLayout.
    property Item dragCanvas: null
    property bool dragStarted: false
    property bool suppressClick: false
    property real pressX: 0
    property real pressY: 0
    signal windowDragStarted(var toplevel, real x, real y)
    signal windowDragMoved(real x, real y)
    signal windowDragFinished()
    signal windowDragCanceled()

    function dragPoint(x: real, y: real): point {
        return root.mapToItem(root.dragCanvas, x, y)
    }

    readonly property bool activeWindow: Boolean(root.toplevel?.activated)
    readonly property bool urgentWindow: Boolean(root.toplevel?.urgent)

    Layout.fillWidth: true
    Layout.preferredHeight: 34
    surfaceRadius: RaohaneTheme.radiusSmall
    transparentIdle: !root.activeWindow && !root.hovered
    active: root.activeWindow
    hovered: pointer.containsMouse || activeFocus
    pressed: pointer.pressed
    interactive: true
    showSheen: false
    showInnerRim: root.activeWindow
    hoverScale: 1
    pressedScale: 1
    activeFocusOnTab: !!root.toplevel?.wayland
    opacity: root.toplevel?.wayland ? 1 : 0.62
    idleBorderColor: root.urgentWindow ? RaohaneTheme.critical : RaohaneTheme.borderFaint
    hoverBorderColor: root.urgentWindow ? RaohaneTheme.critical : RaohaneTheme.borderStrong
    pressedBorderColor: root.urgentWindow ? RaohaneTheme.critical : RaohaneTheme.borderStrong
    activeBorderColor: root.urgentWindow ? RaohaneTheme.critical : RaohaneTheme.accentBorder
    showStateRail: root.activeWindow || root.urgentWindow
    stateRailColor: root.urgentWindow ? RaohaneTheme.critical : RaohaneTheme.accent
    stateRailOpacity: root.activeWindow || root.urgentWindow ? 1 : 0.30
    stateRailWidth: 3
    stateRailLength: 18

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: RaohaneTheme.spacing
        anchors.rightMargin: RaohaneTheme.spacingSmall + 2
        spacing: RaohaneTheme.spacingSmall + 1

        Item {
            Layout.preferredWidth: 16
            Layout.preferredHeight: 16

            RaohaneAdaptiveIcon {
                anchors.centerIn: parent
                visible: !root.urgentWindow
                iconSource: String(root.toplevel?.wayland?.appId ?? "")
                iconSize: 16
                fallbackColor: root.activeWindow ? RaohaneTheme.accent : RaohaneTheme.textFaint
            }

            RaohaneIcon {
                anchors.centerIn: parent
                visible: root.urgentWindow
                text: "priority_high"
                iconSize: 15
                fill: 1
                color: RaohaneTheme.critical
            }
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
        onPressed: mouse => {
            root.forceActiveFocus()
            root.pressX = mouse.x
            root.pressY = mouse.y
            root.dragStarted = false
            root.suppressClick = false
        }
        onPositionChanged: mouse => {
            if (!pressed || !root.dragCanvas || !root.toplevel?.wayland
                    || !String(root.toplevel?.address ?? "").length)
                return
            const distance = Math.abs(mouse.x - root.pressX) + Math.abs(mouse.y - root.pressY)
            if (!root.dragStarted && distance >= 14) {
                root.dragStarted = true
                root.suppressClick = true
                const point = root.dragPoint(mouse.x, mouse.y)
                root.windowDragStarted(root.toplevel, point.x, point.y)
            }
            if (root.dragStarted) {
                const point = root.dragPoint(mouse.x, mouse.y)
                root.windowDragMoved(point.x, point.y)
            }
        }
        onReleased: {
            if (root.dragStarted) {
                root.dragStarted = false
                root.windowDragFinished()
            }
        }
        onCanceled: {
            if (root.dragStarted)
                root.windowDragCanceled()
            root.dragStarted = false
        }
        onClicked: {
            if (!root.suppressClick)
                root.activated(root.toplevel)
        }
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
