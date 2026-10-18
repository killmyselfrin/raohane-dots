pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

// Two system-dashboard faces using already resident data sources only.
// CPU/GPU labels and RAM snapshot are hardware information, not fabricated
// usage percentages. Network connectivity and volume react to live services.
RaohaneSurface {
    id: root

    property bool compact: false
    property string faceStyle: "minimal"

    readonly property bool aurora: faceStyle === "aurora"
    readonly property bool online: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
    readonly property string connectionName: RaohaneNetwork.networkName
        || (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
    readonly property string audioLabel: RaohaneAudio.muted
        ? qsTr("Muted") : Math.round(RaohaneAudio.volume * 100) + "%"

    implicitHeight: compact ? 122 : 142
    surfaceRadius: aurora ? 20 : 12
    raised: aurora
    showSheen: aurora
    idleColor: aurora ? RaohaneTheme.surfaceRaised : RaohaneTheme.surfaceDeep
    idleBorderColor: aurora ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
    clip: true

    Rectangle {
        anchors.fill: parent
        visible: root.aurora
        radius: root.surfaceRadius
        opacity: 0.22
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: RaohaneTheme.accentSoft }
            GradientStop { position: 1; color: RaohaneTheme.surfaceDeep }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 11 : 14
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            RaohaneIcon {
                text: root.aurora ? "monitor_heart" : "memory"
                iconSize: 15
                color: RaohaneTheme.accent
            }

            Text {
                text: root.aurora ? qsTr("AURORA SYSTEM") : qsTr("SYSTEM STATUS")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
                font.letterSpacing: 1
            }

            Item { Layout.fillWidth: true }

            Rectangle {
                width: 7
                height: 7
                radius: 4
                color: root.online ? RaohaneTheme.success : RaohaneTheme.textFaint
            }

            Text {
                text: root.online ? qsTr("Online") : qsTr("Offline")
                color: root.online ? RaohaneTheme.success : RaohaneTheme.textFaint
                font.pixelSize: 9
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6

            InfoTile {
                Layout.fillWidth: true
                title: qsTr("NETWORK")
                info: root.connectionName
                glyph: RaohaneNetwork.materialSymbol
                active: root.online
            }

            InfoTile {
                Layout.fillWidth: true
                title: qsTr("SOUND")
                info: root.audioLabel
                glyph: RaohaneAudio.muted ? "volume_off" : "volume_up"
                active: !RaohaneAudio.muted
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: RaohaneSystemInfo.cpu || qsTr("CPU information unavailable")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                elide: Text.ElideRight
            }

            Text {
                text: RaohaneSystemInfo.memory || qsTr("RAM —")
                color: root.aurora ? RaohaneTheme.accent : RaohaneTheme.textFaint
                font.pixelSize: 9
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }

    component InfoTile: RaohaneSurface {
        id: tile

        required property string glyph
        required property string title
        required property string info

        Layout.fillHeight: true
        Layout.minimumWidth: 0
        surfaceRadius: 10
        raised: false
        showSheen: false
        idleColor: RaohaneTheme.surfaceSubtle
        idleBorderColor: RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 7
            spacing: 2

            RowLayout {
                Layout.fillWidth: true

                RaohaneIcon {
                    text: tile.glyph
                    iconSize: 13
                    color: tile.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                }

                Text {
                    Layout.fillWidth: true
                    text: tile.title
                    font.pixelSize: 8
                    color: RaohaneTheme.textFaint
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: tile.info
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: RaohaneTheme.text
                elide: Text.ElideRight
            }
        }
    }
}
