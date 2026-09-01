pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config

Variants {
    id: root
    model: Quickshell.screens

    property date now: new Date()

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.now = new Date()
    }

    IpcHandler {
        target: "desktopWidgets"

        function open(): void { RaohaneState.setPrimaryOpen("widgetStudio", true) }
        function edit(): void { RaohaneState.beginDesktopWidgetEdit() }
        function done(): void { RaohaneState.endDesktopWidgetEdit() }
        function reset(): void { RaohaneConfig.resetDesktopWidgets() }
        function status(): string {
            return RaohaneConfig.desktopWidgets.length + " widgets · "
                + (RaohaneState.desktopWidgetEditMode ? "editing" : "locked")
        }
    }

    PanelWindow {
        id: desktopWindow

        required property var modelData

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        readonly property list<HyprlandWorkspace> monitorWorkspaces: Hyprland.workspaces.values.filter(workspace =>
            workspace.monitor && desktopWindow.monitor
            && workspace.monitor.name === desktopWindow.monitor.name
        )
        readonly property bool fullscreenActive: monitorWorkspaces.some(workspace =>
            workspace.active
            && workspace.toplevels.values.some(window => window.wayland?.fullscreen)
        )
        readonly property bool canvasVisible: !RaohaneState.screenLocked
            && !(RaohaneConfig.wallpaperHideWhenFullscreen && fullscreenActive)
        readonly property bool primaryScreen: Quickshell.screens.length > 0
            && Quickshell.screens[0].name === modelData.name
        readonly property var visibleWidgets: RaohaneConfig.desktopWidgets.filter(widget =>
            String(widget.screen ?? "") === modelData.name
            || (String(widget.screen ?? "") === "" && desktopWindow.primaryScreen)
        )

        screen: modelData
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-desktop-canvas"
        WlrLayershell.layer: RaohaneState.desktopWidgetEditMode ? WlrLayer.Overlay : WlrLayer.Bottom
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Item {
            anchors.fill: parent
            visible: desktopWindow.canvasVisible || RaohaneState.desktopWidgetEditMode
            opacity: visible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: RaohaneMotion.standard
                    easing.type: RaohaneMotion.easeStandard
                }
            }

            Rectangle {
                visible: RaohaneState.desktopWidgetEditMode
                anchors.fill: parent
                color: RaohaneTheme.dark ? "#4a000000" : "#2affffff"
            }

            MouseArea {
                visible: RaohaneState.desktopWidgetEditMode
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            Repeater {
                model: desktopWindow.visibleWidgets

                delegate: RaohaneDesktopWidget {
                    required property var modelData
                    widgetData: modelData
                    now: root.now
                    screenName: desktopWindow.modelData.name
                }
            }

            RaohaneSurface {
                visible: RaohaneState.desktopWidgetEditMode
                z: 80
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                    topMargin: 22
                }
                width: editRow.implicitWidth + 20
                height: 46
                surfaceRadius: 16
                raised: true
                active: true
                border.color: RaohaneTheme.accentBorder

                RowLayout {
                    id: editRow
                    anchors.centerIn: parent
                    spacing: 7

                    RaohaneIcon {
                        text: "drag_pan"
                        iconSize: 16
                        color: RaohaneTheme.accent
                    }

                    Text {
                        text: qsTr("Arrange desktop widgets")
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    EditAction {
                        icon: "add"
                        label: qsTr("Add")
                        onTriggered: {
                            RaohaneState.endDesktopWidgetEdit()
                            RaohaneState.setPrimaryOpen("widgetStudio", true)
                        }
                    }

                    EditAction {
                        icon: "done"
                        label: qsTr("Done")
                        selected: true
                        onTriggered: RaohaneState.endDesktopWidgetEdit()
                    }
                }
            }
        }
    }

    component EditAction: RaohaneSurface {
        id: action

        required property string icon
        required property string label
        property bool selected: false
        signal triggered()

        Layout.preferredWidth: actionRow.implicitWidth + 16
        Layout.preferredHeight: 30
        surfaceRadius: 10
        active: action.selected
        interactive: true
        hovered: actionMouse.containsMouse
        pressed: actionMouse.pressed
        showSheen: false

        RowLayout {
            id: actionRow
            anchors.centerIn: parent
            spacing: 5

            RaohaneIcon { text: action.icon; iconSize: 13; color: RaohaneTheme.accent }
            Text { text: action.label; color: RaohaneTheme.text; font.pixelSize: 8; font.weight: Font.Medium }
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
