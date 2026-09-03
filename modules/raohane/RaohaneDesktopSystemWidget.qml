pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

RaohaneSurface {
    id: root

    property bool compact: false

    implicitHeight: root.compact ? 82 : 94
    surfaceRadius: 21
    raised: true
    showSheen: true
    opacity: 0.94

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 10

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: qsTr("SYSTEM")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                font.weight: Font.DemiBold
                font.letterSpacing: 1.1
            }

            Item { Layout.fillWidth: true }

            Text {
                text: RaohaneSystemInfo.hostname
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                RaohaneIcon {
                    text: RaohaneNetwork.materialSymbol
                    iconSize: 14
                    color: RaohaneNetwork.wifiConnected || RaohaneNetwork.ethernet
                        ? RaohaneTheme.accent
                        : RaohaneTheme.textFaint
                }

                Text {
                    Layout.fillWidth: true
                    text: RaohaneNetwork.networkName || (RaohaneNetwork.ethernet ? qsTr("Ethernet") : qsTr("Offline"))
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 6

                RaohaneIcon {
                    text: RaohaneAudio.muted ? "volume_off" : "volume_up"
                    iconSize: 14
                    color: RaohaneAudio.muted ? RaohaneTheme.textFaint : RaohaneTheme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: RaohaneAudio.muted ? qsTr("Muted") : Math.round(RaohaneAudio.volume * 100) + "%"
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    elide: Text.ElideRight
                }
            }
        }
    }
}
