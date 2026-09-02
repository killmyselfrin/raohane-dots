pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var widgets: [
        { key: "desktopWidgetClock", icon: "schedule", title: qsTr("Clock and date"), detail: qsTr("Large time with a restrained Japanese label") },
        { key: "desktopWidgetContext", icon: "music_note", title: qsTr("Media and live context"), detail: qsTr("Album art, track progress, privacy and active-window state") },
        { key: "desktopWidgetSystem", icon: "monitor_heart", title: qsTr("System status"), detail: qsTr("Network, audio level and host status") },
        { key: "desktopWidgetMotto", icon: "spa", title: qsTr("Quiet motto"), detail: qsTr("A small ambient Japanese-inspired card") }
    ]

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: studioColumn.implicitHeight + 42
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: studioColumn
            y: 18
            width: Math.min(parent.width - 48, 820)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 14

            RaohaneSurface {
                width: parent.width
                height: 238
                surfaceRadius: RaohaneTheme.radiusHero
                raised: false
                showSheen: false
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: RaohaneTheme.background
                    opacity: 0.52
                }
                Rectangle {
                    width: 260
                    height: 260
                    radius: 130
                    x: parent.width - 180
                    y: -150
                    color: RaohaneTheme.accentSoft
                    opacity: 0.42
                }

                ColumnLayout {
                    anchors { left: parent.left; top: parent.top; leftMargin: 22; topMargin: 22 }
                    spacing: 2
                    Text { text: "ラオハネ  ·  18:42"; color: RaohaneTheme.textMuted; font.pixelSize: 8; font.letterSpacing: 1 }
                    Text { text: qsTr("Your desktop, composed quietly"); color: RaohaneTheme.text; font.pixelSize: 20; font.weight: Font.DemiBold }
                    Text { text: qsTr("Changes appear on the desktop immediately and persist after restart."); color: RaohaneTheme.textMuted; font.pixelSize: 9 }
                }

                RowLayout {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 20 }
                    spacing: 9

                    PreviewCard { visible: RaohaneConfig.desktopWidgetClock; Layout.fillWidth: true; icon: "schedule"; title: "18:42"; detail: qsTr("Tuesday, 2 September") }
                    PreviewCard { visible: RaohaneConfig.desktopWidgetContext; Layout.fillWidth: true; icon: "music_note"; title: qsTr("Now playing"); detail: qsTr("Live media context") }
                    PreviewCard { visible: RaohaneConfig.desktopWidgetSystem; Layout.fillWidth: true; icon: "wifi"; title: qsTr("System ready"); detail: qsTr("Network · Audio") }
                    PreviewCard { visible: RaohaneConfig.desktopWidgetMotto; Layout.fillWidth: true; icon: "spa"; title: qsTr("Stay present"); detail: "静かに、前へ" }
                }
            }

            RowLayout {
                width: parent.width
                spacing: 10

                RaohaneSurface {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 64
                    surfaceRadius: 18
                    active: RaohaneConfig.desktopWidgetsEnabled
                    interactive: true
                    hovered: masterMouse.containsMouse
                    pressed: masterMouse.pressed
                    showSheen: false
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 14
                        spacing: 11
                        RaohaneIcon { text: "widgets"; iconSize: 20; fill: 1; color: RaohaneTheme.accent }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: qsTr("Desktop widget layer"); color: RaohaneTheme.text; font.pixelSize: 11; font.weight: Font.DemiBold }
                            Text { text: qsTr("Show all enabled widgets above the wallpaper"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                        }
                        RaohaneSwitch { checked: RaohaneConfig.desktopWidgetsEnabled; enabled: false; opacity: 1 }
                    }
                    MouseArea { id: masterMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: RaohaneConfig.desktopWidgetsEnabled = !RaohaneConfig.desktopWidgetsEnabled }
                }

                RaohaneSurface {
                    Layout.preferredWidth: 210
                    Layout.preferredHeight: 64
                    surfaceRadius: 18
                    active: RaohaneConfig.desktopWidgetsCompact
                    interactive: true
                    hovered: compactMouse.containsMouse
                    pressed: compactMouse.pressed
                    showSheen: false
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 13
                        spacing: 9
                        RaohaneIcon { text: "compress"; iconSize: 18; color: RaohaneTheme.accent }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: qsTr("Compact"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                            Text { text: qsTr("Smaller spacing"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                        }
                        RaohaneSwitch { checked: RaohaneConfig.desktopWidgetsCompact; enabled: false; opacity: 1 }
                    }
                    MouseArea { id: compactMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: RaohaneConfig.desktopWidgetsCompact = !RaohaneConfig.desktopWidgetsCompact }
                }
            }

            GridLayout {
                width: parent.width
                columns: width < 650 ? 1 : 2
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: root.widgets
                    RaohaneSurface {
                        id: widgetOption
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: 86
                        surfaceRadius: 19
                        active: Boolean(RaohaneConfig[modelData.key])
                        interactive: true
                        hovered: optionMouse.containsMouse
                        pressed: optionMouse.pressed
                        showSheen: false
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 15
                            anchors.rightMargin: 13
                            spacing: 12
                            RaohaneSurface {
                                Layout.preferredWidth: 42
                                Layout.preferredHeight: 42
                                surfaceRadius: 13
                                active: widgetOption.active
                                showSheen: false
                                RaohaneIcon { anchors.centerIn: parent; text: widgetOption.modelData.icon; iconSize: 20; fill: widgetOption.active ? 1 : 0; color: RaohaneTheme.accent }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                Text { Layout.fillWidth: true; text: widgetOption.modelData.title; color: RaohaneTheme.text; font.pixelSize: 11; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                Text { Layout.fillWidth: true; text: widgetOption.modelData.detail; color: RaohaneTheme.textMuted; font.pixelSize: 8; wrapMode: Text.WordWrap }
                            }
                            RaohaneSwitch { checked: widgetOption.active; enabled: false; opacity: 1 }
                        }
                        MouseArea {
                            id: optionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneConfig[widgetOption.modelData.key] = !Boolean(RaohaneConfig[widgetOption.modelData.key])
                        }
                    }
                }
            }
        }
    }

    component PreviewCard: RaohaneSurface {
        id: previewCard
        required property string icon
        required property string title
        required property string detail
        Layout.preferredHeight: 74
        surfaceRadius: 16
        raised: true
        showSheen: false
        RowLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 8
            RaohaneIcon { text: previewCard.icon; iconSize: 17; color: RaohaneTheme.accent }
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Text { Layout.fillWidth: true; text: previewCard.title; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold; elide: Text.ElideRight }
                Text { Layout.fillWidth: true; text: previewCard.detail; color: RaohaneTheme.textMuted; font.pixelSize: 7; elide: Text.ElideRight }
            }
        }
    }
}
