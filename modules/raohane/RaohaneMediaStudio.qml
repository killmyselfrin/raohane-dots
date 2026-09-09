pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

Item {
    id: root

    implicitHeight: studioColumn.implicitHeight

    readonly property bool gamingActive: RaohaneScenes.gaming
    readonly property var positionOptions: [
        { value: "top-left", label: qsTr("Top left"), icon: "north_west" },
        { value: "top-right", label: qsTr("Top right"), icon: "north_east" },
        { value: "bottom-left", label: qsTr("Bottom left"), icon: "south_west" },
        { value: "bottom-right", label: qsTr("Bottom right"), icon: "south_east" }
    ]

    function previewPlayer(): void {
        RaohaneState.mediaOverlayOpen = true
    }

    ColumnLayout {
        id: studioColumn
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: qsTr("Media Position Studio")
                    color: RaohaneTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Choose where the media surface appears in normal use and while Gaming Scene is active.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }

            RaohaneIconButton {
                buttonSize: 30
                iconSize: 15
                icon: "visibility"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.previewPlayer()
            }

            RaohaneSurface {
                Layout.preferredWidth: liveLabel.implicitWidth + 24
                Layout.preferredHeight: 28
                surfaceRadius: 11
                raised: false
                showSheen: false
                color: RaohaneTheme.accentSoft
                border.color: RaohaneTheme.accentBorder

                Text {
                    id: liveLabel
                    anchors.centerIn: parent
                    text: root.gamingActive ? qsTr("LIVE · GAMING") : qsTr("LIVE · DESKTOP")
                    color: RaohaneTheme.accent
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            PlacementCard {
                Layout.fillWidth: true
                title: qsTr("Desktop")
                subtitle: qsTr("Default media position")
                badge: root.gamingActive ? qsTr("STANDBY") : qsTr("ACTIVE")
                activePolicy: !root.gamingActive
                value: RaohaneConfig.mediaOverlayPosition
                gaming: false
                positions: root.positionOptions
                onSelected: position => RaohaneConfig.mediaOverlayPosition = position
            }

            PlacementCard {
                Layout.fillWidth: true
                title: qsTr("Gaming")
                subtitle: qsTr("Used automatically in Gaming Scene")
                badge: root.gamingActive ? qsTr("ACTIVE") : qsTr("STANDBY")
                activePolicy: root.gamingActive
                value: RaohaneConfig.mediaOverlayGamingPosition
                gaming: true
                positions: root.positionOptions
                onSelected: position => RaohaneConfig.mediaOverlayGamingPosition = position
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.rightMargin: 4
            spacing: 8

            RaohaneIcon {
                text: "visibility"
                iconSize: 12
                color: RaohaneTheme.textFaint
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Changes are saved immediately. Preview opens the real overlay using the policy active for the current Scene.")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }
        }
    }

    component PlacementCard: RaohaneSurface {
        id: card

        required property string title
        required property string subtitle
        required property string badge
        required property string value
        required property bool gaming
        required property bool activePolicy
        required property var positions
        signal selected(string position)

        Layout.preferredHeight: 294
        surfaceRadius: RaohaneTheme.radiusLarge
        raised: false
        showSheen: false
        border.color: card.activePolicy ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: card.title
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: card.subtitle
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: card.badge
                    color: card.activePolicy ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                }
            }

            Rectangle {
                id: monitor
                Layout.fillWidth: true
                Layout.preferredHeight: 184
                radius: 15
                color: RaohaneTheme.surfaceDeep
                border.width: 1
                border.color: card.activePolicy ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                clip: true

                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 10
                    radius: 10
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.borderFaint

                    Rectangle {
                        anchors.centerIn: parent
                        width: 64
                        height: 1
                        color: RaohaneTheme.borderFaint
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 1
                        height: 48
                        color: RaohaneTheme.borderFaint
                    }

                    Text {
                        anchors.centerIn: parent
                        text: card.gaming ? qsTr("GAME") : qsTr("DESKTOP")
                        color: card.activePolicy ? RaohaneTheme.accent : RaohaneTheme.textFaint
                        opacity: card.activePolicy ? 0.66 : 0.42
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: card.positions

                        delegate: Rectangle {
                            id: cornerButton
                            required property var modelData

                            readonly property bool active: card.value === String(modelData.value)
                            readonly property bool leftSide: String(modelData.value).endsWith("left")
                            readonly property bool topSide: String(modelData.value).startsWith("top")

                            width: card.gaming ? 82 : 92
                            height: card.gaming ? 31 : 34
                            x: leftSide ? 9 : parent.width - width - 9
                            y: topSide ? 9 : parent.height - height - 9
                            radius: 9
                            color: active ? RaohaneTheme.accentSoft
                                : cornerMouse.containsMouse ? RaohaneTheme.surfaceRaised
                                : RaohaneTheme.surfaceDeep
                            border.width: 1
                            border.color: active ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            Behavior on color {
                                ColorAnimation { duration: RaohaneMotion.micro }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 5

                                RaohaneIcon {
                                    text: String(cornerButton.modelData.icon)
                                    iconSize: card.gaming ? 11 : 12
                                    color: cornerButton.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: String(cornerButton.modelData.label)
                                    color: cornerButton.active ? RaohaneTheme.text : RaohaneTheme.textMuted
                                    font.pixelSize: 7
                                    font.weight: cornerButton.active ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: cornerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: card.selected(String(cornerButton.modelData.value))
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                RaohaneIcon {
                    text: card.positions.find(item => String(item.value) === card.value)?.icon ?? "south_east"
                    iconSize: 13
                    color: RaohaneTheme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: card.positions.find(item => String(item.value) === card.value)?.label ?? qsTr("Bottom right")
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    text: card.activePolicy ? qsTr("in use now") : qsTr("saved")
                    color: card.activePolicy ? RaohaneTheme.accent : RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: card.activePolicy ? Font.DemiBold : Font.Normal
                }
            }
        }
    }
}
