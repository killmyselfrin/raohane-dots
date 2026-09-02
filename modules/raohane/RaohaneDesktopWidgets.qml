pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root
    property var screen
    property bool shown: true
    property date now: new Date()
    readonly property bool compact: RaohaneConfig.desktopWidgetsCompact || width < 1280
    readonly property int edge: compact ? 34 : 54
    readonly property int cardWidth: compact ? 238 : 294
    readonly property string layoutPreset: RaohaneConfig.desktopWidgetsLayout

    opacity: shown ? RaohaneConfig.desktopWidgetsOpacity : 0
    scale: RaohaneConfig.desktopWidgetsScale
    transformOrigin: Item.Center
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeStandard } }
    Behavior on scale { NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeEmphasized } }

    Timer {
        interval: 1000
        running: root.shown && RaohaneConfig.desktopWidgetClock
        repeat: true
        onTriggered: root.now = new Date()
    }

    ColumnLayout {
        id: primaryColumn
        x: root.layoutPreset === "right" ? parent.width - width - root.edge : root.edge
        y: root.compact ? 72 : 92
        width: Math.min(root.compact ? 370 : 510, parent.width * 0.44)
        spacing: 12

        Behavior on x { NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeEmphasized } }

        Item {
            visible: RaohaneConfig.desktopWidgetClock
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 118 : 148
            ColumnLayout {
                anchors.fill: parent
                spacing: 1
                RowLayout {
                    spacing: 8
                    Rectangle { width: 7; height: 7; radius: 4; color: RaohaneTheme.accent }
                    Text {
                        text: "ラオハネ  ·  RAOHANE"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1.4
                    }
                }
                Text {
                    Layout.topMargin: 4
                    text: Qt.formatTime(root.now, "HH:mm")
                    color: RaohaneTheme.text
                    font.pixelSize: root.compact ? 58 : 76
                    font.weight: Font.Light
                    font.letterSpacing: -3
                }
                Text {
                    text: Qt.formatDate(root.now, "dddd, d MMMM")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }
        }

        WidgetCard {
            visible: RaohaneConfig.desktopWidgetContext
            Layout.fillWidth: true
            Layout.preferredHeight: RaohaneMedia.available ? 116 : 82
            RowLayout {
                anchors.fill: parent
                anchors.margins: 13
                spacing: 12
                Rectangle {
                    id: contextArtwork
                    Layout.preferredWidth: RaohaneMedia.available ? 74 : 44
                    Layout.preferredHeight: width
                    radius: RaohaneMedia.available ? 18 : 14
                    color: RaohaneTheme.accentSoft
                    clip: true
                    Image {
                        id: artImage
                        anchors.fill: parent
                        visible: RaohaneMedia.available && status === Image.Ready
                        source: RaohaneMedia.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                    RaohaneIcon {
                        anchors.centerIn: parent
                        visible: !artImage.visible
                        text: RaohaneMedia.available ? "music_note" : RaohaneContext.icon
                        iconSize: RaohaneMedia.available ? 28 : 21
                        fill: 1
                        color: RaohaneTheme.accent
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 3
                    Text {
                        text: RaohaneMedia.available ? qsTr("NOW PLAYING") : qsTr("LIVE CONTEXT")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                        font.letterSpacing: 1
                    }
                    Text {
                        Layout.fillWidth: true
                        text: RaohaneMedia.available ? (RaohaneMedia.title || qsTr("Unknown track")) : RaohaneContext.title
                        color: RaohaneTheme.text
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                    Text {
                        Layout.fillWidth: true
                        text: RaohaneMedia.available ? (RaohaneMedia.artist || RaohaneMedia.playerName) : RaohaneContext.detail
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        elide: Text.ElideRight
                    }
                    Rectangle {
                        visible: RaohaneMedia.available
                        Layout.fillWidth: true
                        Layout.topMargin: 5
                        Layout.preferredHeight: 3
                        radius: 2
                        color: RaohaneTheme.border
                        Rectangle {
                            width: parent.width * RaohaneMedia.progress
                            height: parent.height
                            radius: parent.radius
                            color: RaohaneTheme.accent
                            Behavior on width { NumberAnimation { duration: 450; easing.type: RaohaneMotion.easeStandard } }
                        }
                    }
                }
                RaohaneIcon {
                    visible: RaohaneMedia.available
                    text: RaohaneMedia.isPlaying ? "graphic_eq" : "pause"
                    iconSize: 18
                    fill: 1
                    color: RaohaneTheme.accent
                }
            }
        }
    }

    ColumnLayout {
        id: secondaryColumn
        x: root.layoutPreset === "left" ? root.edge : parent.width - width - root.edge
        y: root.layoutPreset === "balanced"
            ? parent.height - height - (RaohaneConfig.dockEnabled ? (root.compact ? 104 : 122) : root.edge)
            : Math.min(parent.height - height - root.edge, primaryColumn.y + primaryColumn.height + 16)
        width: root.cardWidth
        spacing: 10

        Behavior on x { NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeEmphasized } }
        Behavior on y { NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeEmphasized } }

        WidgetCard {
            visible: RaohaneConfig.desktopWidgetSystem
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 82 : 94
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: qsTr("SYSTEM"); color: RaohaneTheme.textFaint; font.pixelSize: 8; font.weight: Font.DemiBold; font.letterSpacing: 1.1 }
                    Item { Layout.fillWidth: true }
                    Text { text: RaohaneSystemInfo.hostname; color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                }
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    StatusPill {
                        Layout.fillWidth: true
                        icon: RaohaneNetwork.materialSymbol
                        label: RaohaneNetwork.networkName || (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                        active: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                    }
                    StatusPill {
                        Layout.fillWidth: true
                        icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                        label: RaohaneAudio.muted ? qsTr("Muted") : Math.round(RaohaneAudio.volume * 100) + "%"
                        active: !RaohaneAudio.muted
                    }
                }
            }
        }

        WidgetCard {
            visible: RaohaneConfig.desktopWidgetMotto
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? 52 : 62
            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                spacing: 11
                Rectangle { width: 2; height: 27; radius: 1; color: RaohaneTheme.accent; opacity: 0.68 }
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0
                    Text { text: qsTr("Move gently. Stay present."); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.Medium }
                    Text { visible: !root.compact; text: "静かに、前へ"; color: RaohaneTheme.textMuted; font.pixelSize: 8; font.letterSpacing: 0.8 }
                }
                RaohaneIcon { text: "spa"; iconSize: 18; fill: 0.18; color: RaohaneTheme.accent }
            }
        }
    }

    component WidgetCard: RaohaneSurface {
        surfaceRadius: 21
        raised: true
        showSheen: true
        opacity: visible ? 0.94 : 0
        Behavior on opacity { NumberAnimation { duration: RaohaneMotion.relaxed; easing.type: RaohaneMotion.easeStandard } }
    }

    component StatusPill: RowLayout {
        id: pill
        required property string icon
        required property string label
        property bool active: false
        spacing: 6
        RaohaneIcon { text: pill.icon; iconSize: 14; color: pill.active ? RaohaneTheme.accent : RaohaneTheme.textFaint }
        Text { Layout.fillWidth: true; text: pill.label; color: RaohaneTheme.textMuted; font.pixelSize: 9; elide: Text.ElideRight }
    }
}
