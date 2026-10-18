pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

// The desktop status deck is read-only; live values belong to the existing
// network, audio and system-info services, not another polling process.
RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: root.compact ? 122 : 142
    surfaceRadius: RaohaneTheme.radiusHero
    raised: true
    showSheen: true
    showInnerRim: true
    idleColor: RaohaneTheme.surfaceRaised
    idleBorderColor: RaohaneTheme.borderFaint
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.compact ? 11 : 14
        spacing: RaohaneTheme.spacingSmall

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            RaohaneIcon {
                text: "monitor_heart"
                iconSize: 14
                color: RaohaneTheme.accent
            }

            Text {
                text: qsTr("SYSTEM")
                color: RaohaneTheme.textMuted
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Item { Layout.fillWidth: true }

            Text {
                Layout.maximumWidth: root.compact ? 100 : 145
                text: RaohaneSystemInfo.hostname
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
                elide: Text.ElideRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: RaohaneTheme.spacingSmall

            StatusTile {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                icon: RaohaneNetwork.materialSymbol
                label: qsTr("Network")
                value: RaohaneNetwork.networkName
                    || (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                statusActive: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
            }

            StatusTile {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                icon: RaohaneAudio.muted ? "volume_off" : "volume_up"
                label: qsTr("Audio")
                value: RaohaneAudio.muted
                    ? qsTr("Muted") : Math.round(RaohaneAudio.volume * 100) + "%"
                statusActive: !RaohaneAudio.muted
            }
        }
    }

    component StatusTile: RaohaneSurface {
        id: tile

        required property string icon
        required property string label
        required property string value
        required property bool statusActive

        Layout.fillHeight: true
        surfaceRadius: RaohaneTheme.radiusLarge
        raised: false
        showSheen: false
        showInnerRim: true
        idleColor: RaohaneTheme.surfaceSubtle
        idleBorderColor: RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 3

            RowLayout {
                Layout.fillWidth: true
                spacing: 4

                RaohaneIcon {
                    text: tile.icon
                    iconSize: 14
                    fill: tile.statusActive ? 1 : 0
                    color: tile.statusActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                }

                Text {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    text: tile.label
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            Item { Layout.fillHeight: true }

            Text {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                text: tile.value
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }
        }
    }
}
