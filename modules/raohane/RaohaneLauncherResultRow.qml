pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RaohaneSurface {
    id: root

    required property var result
    required property int rowIndex
    property bool selected: false

    signal hoverRequested(int index)
    signal activateRequested(int index)

    Layout.fillWidth: true
    Layout.preferredHeight: 55
    surfaceRadius: RaohaneTheme.radiusLarge
    active: root.selected
    hovered: resultMouse.containsMouse || activeFocus
    pressed: resultMouse.pressed
    interactive: true
    transparentIdle: !root.selected && !root.hovered
    showSheen: false
    showInnerRim: root.selected
    hoverScale: 1
    pressedScale: 1
    activeFocusOnTab: true
    showStateRail: root.selected
    stateRailWidth: 3
    stateRailLength: 24
    stateRailOpacity: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: RaohaneTheme.spacing + 2
        anchors.rightMargin: RaohaneTheme.panelPadding
        spacing: RaohaneTheme.spacing + 1

        RaohaneSurface {
            Layout.preferredWidth: 36
            Layout.preferredHeight: 36
            surfaceRadius: RaohaneTheme.radius
            active: root.selected
            showSheen: false
            showInnerRim: false

            Loader {
                anchors.centerIn: parent
                width: 28
                height: 28
                sourceComponent: {
                    if (root.result.iconType === "system")
                        return systemIcon
                    if (root.result.iconType === "material")
                        return materialIcon
                    if (root.result.iconType === "text")
                        return textIcon
                    return fallbackIcon
                }
            }

            Component {
                id: systemIcon
                RaohaneAdaptiveIcon {
                    anchors.centerIn: parent
                    iconSource: String(root.result.iconName ?? "")
                    iconSize: 25
                    fallbackColor: root.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            Component {
                id: materialIcon
                RaohaneIcon {
                    anchors.centerIn: parent
                    text: root.result.iconName
                    iconSize: 18
                    fill: root.selected ? 1 : 0
                    symbolWeight: root.selected ? 540 : 430
                    color: root.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }
            }

            Component {
                id: textIcon
                Text {
                    anchors.centerIn: parent
                    text: root.result.iconName
                    color: root.selected ? RaohaneTheme.accent : RaohaneTheme.text
                    font.pixelSize: 15
                }
            }

            Component {
                id: fallbackIcon
                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "apps"
                    iconSize: 17
                    color: RaohaneTheme.textMuted
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

            Text {
                Layout.fillWidth: true
                text: root.result.name
                color: RaohaneTheme.text
                font.pixelSize: 9
                font.weight: root.selected ? Font.DemiBold : Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.result.comment || root.result.type
                color: RaohaneTheme.textMuted
                font.pixelSize: 7
                elide: Text.ElideRight
            }
        }

        Text {
            text: root.result.verb
            color: root.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
            font.pixelSize: 7
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }
    }

    MouseArea {
        id: resultMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onPressed: root.forceActiveFocus()
        onEntered: root.hoverRequested(root.rowIndex)
        onClicked: root.activateRequested(root.rowIndex)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
            root.activateRequested(root.rowIndex)
            event.accepted = true
        }
    }
}
