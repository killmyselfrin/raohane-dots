pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config

Scope {
    id: root

    readonly property var focusedScreen: Quickshell.screens.find(screen => screen.name === Hyprland.focusedMonitor?.name)
        ?? Quickshell.screens[0]
    readonly property var catalog: [
        { type: "clock", icon: "schedule", title: qsTr("Clock"), detail: qsTr("Large time, date and Raohane mark") },
        { type: "context", icon: "bubble_chart", title: qsTr("Context"), detail: qsTr("Active window, privacy and shell state") },
        { type: "media", icon: "album", title: qsTr("Media"), detail: qsTr("MPRIS artwork, track and progress") },
        { type: "system", icon: "memory", title: qsTr("System"), detail: qsTr("Memory, disk and kernel summary") }
    ]

    function close(): void {
        RaohaneState.setPrimaryOpen("widgetStudio", false)
    }

    function beginArrange(): void {
        root.close()
        RaohaneState.beginDesktopWidgetEdit()
    }

    PanelWindow {
        id: studioWindow

        visible: RaohaneState.widgetStudioOpen
        screen: root.focusedScreen
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.namespace: "quickshell:raohane-widget-studio"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        onVisibleChanged: {
            if (visible) {
                studioCard.entered = false
                Qt.callLater(() => studioCard.entered = true)
                RaohaneFocusGrab.addDismissable(studioWindow)
            } else {
                studioCard.entered = false
                RaohaneFocusGrab.removeDismissable(studioWindow)
            }
        }

        Connections {
            target: RaohaneFocusGrab
            function onDismissed(): void { root.close() }
        }

        Rectangle {
            anchors.fill: parent
            color: RaohaneTheme.dark ? "#75000000" : "#382b2925"

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        RaohaneSurface {
            id: studioCard
            property bool entered: false

            width: Math.min(parent.width - 80, 820)
            height: Math.min(parent.height - 80, 610)
            anchors.centerIn: parent
            surfaceRadius: RaohaneTheme.radiusHero
            raised: true
            showSheen: false
            border.color: RaohaneTheme.borderStrong
            clip: true
            focus: visible
            opacity: entered ? 1 : 0
            scale: entered ? 1 : 0.985

            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.standard; easing.type: RaohaneMotion.easeStandard } }
            Behavior on scale { NumberAnimation { duration: RaohaneMotion.enter; easing.type: RaohaneMotion.easeEmphasized } }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.AllButtons
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    RaohaneSurface {
                        Layout.preferredWidth: 42
                        Layout.preferredHeight: 42
                        surfaceRadius: 14
                        active: true
                        showSheen: false

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "widgets"
                            iconSize: 21
                            fill: 1
                            color: RaohaneTheme.accent
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            text: qsTr("Desktop Widget Studio")
                            color: RaohaneTheme.text
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: qsTr("Native Raohane widgets · %1 active").arg(RaohaneConfig.desktopWidgets.length)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 9
                        }
                    }

                    StudioAction {
                        icon: "drag_pan"
                        label: qsTr("Arrange")
                        selected: true
                        onTriggered: root.beginArrange()
                    }

                    RaohaneIconButton {
                        buttonSize: 32
                        iconSize: 15
                        icon: "close"
                        transparentIdle: true
                        onClicked: root.close()
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: RaohaneTheme.borderFaint
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 10

                        SectionLabel { text: qsTr("ADD TO %1").arg(root.focusedScreen?.name ?? qsTr("DESKTOP")) }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 2
                            columnSpacing: 9
                            rowSpacing: 9

                            Repeater {
                                model: root.catalog

                                delegate: CatalogCard {
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    icon: modelData.icon
                                    title: modelData.title
                                    detail: modelData.detail
                                    onTriggered: RaohaneConfig.addDesktopWidget(modelData.type, root.focusedScreen?.name ?? "")
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillHeight: true
                        Layout.preferredWidth: 1
                        color: RaohaneTheme.borderFaint
                    }

                    ColumnLayout {
                        Layout.preferredWidth: 280
                        Layout.fillHeight: true
                        spacing: 10

                        RowLayout {
                            Layout.fillWidth: true

                            SectionLabel { text: qsTr("ACTIVE WIDGETS") }
                            Item { Layout.fillWidth: true }
                            StudioAction {
                                icon: "restart_alt"
                                label: qsTr("Reset")
                                onTriggered: RaohaneConfig.resetDesktopWidgets()
                            }
                        }

                        Flickable {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            contentWidth: width
                            contentHeight: activeColumn.implicitHeight
                            clip: true
                            boundsBehavior: Flickable.StopAtBounds

                            Column {
                                id: activeColumn
                                width: parent.width
                                spacing: 7

                                Repeater {
                                    model: RaohaneConfig.desktopWidgets

                                    delegate: ActiveWidgetRow {
                                        required property var modelData
                                        width: activeColumn.width
                                        widgetData: modelData
                                    }
                                }

                                Text {
                                    visible: RaohaneConfig.desktopWidgets.length === 0
                                    width: parent.width
                                    topPadding: 24
                                    text: qsTr("No widgets yet. Add one from the catalog.")
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    root.close()
                    event.accepted = true
                }
            }
        }

        IpcHandler {
            target: "widgetStudio"
            function toggle(): void { RaohaneState.togglePrimary("widgetStudio") }
            function open(): void { RaohaneState.setPrimaryOpen("widgetStudio", true) }
            function close(): void { root.close() }
            function arrange(): void { root.beginArrange() }
        }
    }

    component SectionLabel: Text {
        color: RaohaneTheme.textFaint
        font.pixelSize: 8
        font.weight: Font.DemiBold
        font.letterSpacing: 0.8
    }

    component StudioAction: RaohaneSurface {
        id: action

        required property string icon
        required property string label
        property bool selected: false
        signal triggered()

        Layout.preferredWidth: actionRow.implicitWidth + 18
        Layout.preferredHeight: 31
        surfaceRadius: 10
        active: selected
        transparentIdle: !selected
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

    component CatalogCard: RaohaneSurface {
        id: card

        required property string icon
        required property string title
        required property string detail
        signal triggered()

        Layout.minimumWidth: 160
        Layout.minimumHeight: 140
        surfaceRadius: 18
        interactive: true
        hovered: cardMouse.containsMouse
        pressed: cardMouse.pressed
        showSheen: false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 7

            RaohaneSurface {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                surfaceRadius: 12
                active: card.hovered
                showSheen: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: card.icon
                    iconSize: 19
                    color: RaohaneTheme.accent
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                text: card.title
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: card.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                Item { Layout.fillWidth: true }
                Text { text: qsTr("Add"); color: RaohaneTheme.accent; font.pixelSize: 8; font.weight: Font.DemiBold }
                RaohaneIcon { text: "add"; iconSize: 14; color: RaohaneTheme.accent }
            }
        }

        MouseArea {
            id: cardMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: card.triggered()
        }
    }

    component ActiveWidgetRow: RaohaneSurface {
        id: row

        required property var widgetData

        height: 54
        surfaceRadius: 14
        showSheen: false
        raised: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 8
            spacing: 10

            RaohaneIcon {
                text: row.widgetData.type === "clock" ? "schedule"
                    : row.widgetData.type === "context" ? "bubble_chart"
                    : row.widgetData.type === "media" ? "album" : "memory"
                iconSize: 17
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: String(row.widgetData.type).charAt(0).toUpperCase() + String(row.widgetData.type).slice(1)
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    text: row.widgetData.screen || qsTr("Primary screen")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                }
            }

            RaohaneIconButton {
                buttonSize: 29
                iconSize: 14
                icon: "delete"
                transparentIdle: true
                onClicked: RaohaneConfig.removeDesktopWidget(String(row.widgetData.id))
            }
        }
    }
}
