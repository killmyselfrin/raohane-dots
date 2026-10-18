pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

// The grid is drawn on the actual wallpaper, behind real desktop widget faces.
// No miniature canvas, gallery, extra Quickshell process or persisted edit flag.
Item {
    id: root

    // This QML file is loaded only while the on-desktop editor is active.
    property bool editing: true
    property string monitorName: ""
    readonly property int gridStep: 32

    signal doneRequested()

    visible: editing

    Repeater {
        model: Math.max(0, Math.ceil(root.width / root.gridStep) - 1)
        delegate: Rectangle {
            required property int index
            x: (index + 1) * root.gridStep
            width: 1
            height: root.height
            color: RaohaneTheme.accent
            opacity: 0.16
        }
    }

    Repeater {
        model: Math.max(0, Math.ceil(root.height / root.gridStep) - 1)
        delegate: Rectangle {
            required property int index
            x: 0
            y: (index + 1) * root.gridStep
            width: root.width
            height: 1
            color: RaohaneTheme.accent
            opacity: 0.16
        }
    }

    // The only permanent editing chrome is a compact floating toolbar.
    // All movement and resize handles are attached to the REAL widgets.
    RaohaneSurface {
        id: toolbar
        width: Math.min(Math.max(1, root.width - 24), 710)
        height: 66
        anchors.horizontalCenter: parent.horizontalCenter
        y: 18
        z: 40
        surfaceRadius: 16
        raised: true
        showSheen: false
        border.color: RaohaneTheme.accentBorder

        RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 9

            RaohaneIcon {
                text: "grid_on"
                iconSize: 22
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.preferredWidth: 120
                spacing: 3

                Text {
                    text: qsTr("Edit widgets")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("Drag · Resize · Snap")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                }
            }

            Rectangle {
                width: 1
                Layout.fillHeight: true
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                color: RaohaneTheme.borderFaint
            }

            // Clicking a hidden type enables it. Clicking a visible type
            // selects it, without opening another catalog window.
            Repeater {
                model: RaohaneDesktopWidgetRegistry.definitions()

                delegate: Rectangle {
                    id: typeChip
                    required property var modelData
                    readonly property string widgetId: String(modelData.id)
                    readonly property bool enabledWidget: Boolean(RaohaneConfig[modelData.key])
                    readonly property bool selected: RaohaneState.desktopWidgetEditWidgetId === widgetId

                    Layout.preferredWidth: 35
                    Layout.preferredHeight: 35
                    radius: 10
                    color: selected ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceDeep
                    border.width: selected ? 2 : 1
                    border.color: selected ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                    opacity: enabledWidget ? 1 : 0.6

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: typeChip.modelData.icon
                        iconSize: 17
                        color: typeChip.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!typeChip.enabledWidget)
                                RaohaneConfig[typeChip.modelData.key] = true
                            RaohaneState.desktopWidgetEditWidgetId = typeChip.widgetId
                        }
                    }
                }
            }

            Item { Layout.fillWidth: true }

            ToolAction {
                icon: "restart_alt"
                label: qsTr("Reset")
                onTriggered: {
                    const id = RaohaneState.desktopWidgetEditWidgetId
                    const p = RaohaneConfig.defaultDesktopWidgetFreePlacements()[id]
                    if (p)
                        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, id, p.x, p.y, p.size)
                }
            }

            ToolAction {
                icon: "visibility_off"
                label: qsTr("Hide")
                onTriggered: {
                    const def = RaohaneDesktopWidgetRegistry.definition(RaohaneState.desktopWidgetEditWidgetId)
                    if (def?.key)
                        RaohaneConfig[def.key] = false
                }
            }

            ToolAction {
                icon: "check"
                label: qsTr("Done")
                emphasized: true
                onTriggered: root.doneRequested()
            }
        }
    }

    Text {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 30
        }
        text: qsTr("Drag widgets to move · Drag the corner to resize · Esc to finish")
        color: RaohaneTheme.textMuted
        font.pixelSize: 11
        style: Text.Outline
        styleColor: RaohaneTheme.background
    }

    component ToolAction: Rectangle {
        id: action
        required property string icon
        required property string label
        property bool emphasized: false
        signal triggered()

        Layout.preferredWidth: action.emphasized ? 82 : 61
        Layout.preferredHeight: 35
        radius: 10
        color: emphasized ? RaohaneTheme.accentSoft
            : actionMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceDeep
        border.color: emphasized ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        Row {
            anchors.centerIn: parent
            spacing: 4

            RaohaneIcon {
                text: action.icon
                iconSize: 14
                color: action.emphasized ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: action.label
                font.pixelSize: 10
                font.weight: Font.DemiBold
                color: RaohaneTheme.text
            }
        }

        MouseArea {
            id: actionMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.triggered()
        }
    }
}
