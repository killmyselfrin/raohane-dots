pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    readonly property var scenes: [
        { id: "balanced", label: qsTr("Balanced"), icon: "tune" },
        { id: "gaming", label: qsTr("Gaming"), icon: "sports_esports" },
        { id: "focus", label: qsTr("Focus"), icon: "center_focus_strong" },
        { id: "work", label: qsTr("Work"), icon: "work" }
    ]

    implicitHeight: 58

    RaohaneSurface {
        anchors.fill: parent
        surfaceRadius: RaohaneTheme.radiusHero
        raised: false
        showSheen: false
        active: RaohaneScenes.autoSceneActive
        activeColor: RaohaneTheme.surface
        idleBorderColor: RaohaneTheme.borderFaint
        activeBorderColor: RaohaneTheme.accentBorder
        showStateRail: RaohaneScenes.autoSceneActive
        stateRailWidth: 3
        stateRailLength: 24
        stateRailOpacity: 0.72

        RowLayout {
            anchors.fill: parent
            anchors.margins: RaohaneTheme.spacingSmall
            spacing: Math.max(2, RaohaneTheme.spacingSmall - 1)

            ColumnLayout {
                Layout.preferredWidth: 72
                Layout.leftMargin: RaohaneTheme.spacingTiny + 1
                spacing: 0

                Text {
                    text: qsTr("Scene")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }

                Text {
                    text: RaohaneScenes.autoSceneActive ? qsTr("AUTO") : qsTr("MANUAL")
                    color: RaohaneScenes.autoSceneActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.7
                }
            }

            Repeater {
                model: root.scenes

                delegate: RaohaneSurface {
                    id: sceneButton
                    required property var modelData

                    readonly property bool selected: RaohaneScenes.activeSceneId === modelData.id

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    surfaceRadius: RaohaneTheme.radius
                    active: selected
                    raised: false
                    showSheen: false
                    showInnerRim: selected
                    transparentIdle: !selected && !hovered
                    interactive: true
                    hovered: sceneMouse.containsMouse || activeFocus
                    pressed: sceneMouse.pressed
                    hoverScale: 1
                    pressedScale: 1
                    activeFocusOnTab: true
                    idleBorderColor: RaohaneTheme.borderFaint
                    hoverBorderColor: RaohaneTheme.borderStrong
                    activeBorderColor: RaohaneTheme.accentBorder

                    Column {
                        anchors.centerIn: parent
                        spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

                        RaohaneIcon {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: sceneButton.modelData.icon
                            iconSize: 14
                            fill: sceneButton.selected ? 1 : 0
                            symbolWeight: sceneButton.selected ? 560 : 430
                            color: sceneButton.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: sceneButton.modelData.label
                            color: sceneButton.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                            font.pixelSize: 7
                            font.weight: sceneButton.selected ? Font.DemiBold : Font.Medium
                        }
                    }

                    MouseArea {
                        id: sceneMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onPressed: sceneButton.forceActiveFocus()
                        onClicked: RaohaneScenes.activate(sceneButton.modelData.id, "control-center")
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                            RaohaneScenes.activate(sceneButton.modelData.id, "control-center")
                            event.accepted = true
                        }
                    }
                }
            }

            RaohaneIconButton {
                Layout.preferredWidth: 34
                Layout.preferredHeight: 34
                buttonSize: 34
                iconSize: 15
                icon: RaohaneScenes.autoSwitchEnabled ? "auto_awesome" : "motion_photos_off"
                emphasized: RaohaneScenes.autoSwitchEnabled
                transparentIdle: !RaohaneScenes.autoSwitchEnabled
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: RaohaneScenes.setAutoSwitch(!RaohaneScenes.autoSwitchEnabled)
            }
        }
    }
}
