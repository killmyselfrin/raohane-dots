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
    readonly property var autoHideOptions: [
        { value: 0, label: qsTr("Off") },
        { value: 4, label: "4s" },
        { value: 8, label: "8s" },
        { value: 15, label: "15s" }
    ]

    function previewPlayer(): void {
        RaohaneState.mediaOverlayOpen = true
    }

    ColumnLayout {
        id: studioColumn
        width: parent.width
        spacing: RaohaneTheme.spacingLarge

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: RaohaneTheme.spacingTiny
            Layout.rightMargin: RaohaneTheme.spacingTiny
            spacing: RaohaneTheme.spacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacingTiny

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
                Layout.preferredWidth: liveLabel.implicitWidth + 2 * RaohaneTheme.panelPadding
                Layout.preferredHeight: 28
                surfaceRadius: RaohaneTheme.radiusLarge
                active: true
                raised: false
                showSheen: false
                showInnerRim: false
                activeColor: RaohaneTheme.accentSoft
                activeBorderColor: RaohaneTheme.accentBorder
                showStateRail: true
                stateRailWidth: 2
                stateRailLength: 14
                stateRailOpacity: 0.82

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
            spacing: RaohaneTheme.spacingLarge

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

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: 82
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            active: root.gamingActive
            activeColor: RaohaneTheme.surface
            idleBorderColor: RaohaneTheme.borderFaint
            activeBorderColor: RaohaneTheme.accentBorder
            showStateRail: root.gamingActive
            stateRailWidth: 3
            stateRailLength: 28
            stateRailOpacity: 0.70

            RowLayout {
                anchors.fill: parent
                anchors.margins: RaohaneTheme.spacingLarge
                spacing: RaohaneTheme.spacingLarge

                RaohaneSurface {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    Layout.alignment: Qt.AlignVCenter
                    surfaceRadius: RaohaneTheme.radiusLarge
                    active: root.gamingActive
                    showSheen: false
                    showInnerRim: false
                    idleColor: RaohaneTheme.surfaceSubtle
                    idleBorderColor: RaohaneTheme.borderFaint

                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "timer"
                        iconSize: 18
                        fill: root.gamingActive ? 1 : 0
                        color: root.gamingActive ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

                    Text {
                        text: qsTr("Gaming auto-hide")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Close the compact player automatically after interaction")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Hover pauses the timer. Lyrics stay open until you close them.")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }
                }

                RowLayout {
                    spacing: Math.max(2, RaohaneTheme.spacingSmall - 1)

                    Repeater {
                        model: root.autoHideOptions

                        delegate: RaohaneSurface {
                            id: autoHideButton
                            required property var modelData

                            readonly property int optionValue: Number(modelData.value)
                            readonly property bool selected: RaohaneConfig.mediaOverlayGamingAutoHideSeconds === optionValue

                            width: optionValue === 0 ? 48 : 42
                            height: 30
                            surfaceRadius: RaohaneTheme.radius
                            active: selected
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            interactive: true
                            hovered: autoHideMouse.containsMouse || activeFocus
                            pressed: autoHideMouse.pressed
                            hoverScale: 1
                            pressedScale: 1
                            activeFocusOnTab: true
                            idleColor: RaohaneTheme.surfaceDeep
                            hoverColor: RaohaneTheme.surfaceRaised
                            activeColor: RaohaneTheme.accentSoft
                            idleBorderColor: RaohaneTheme.borderFaint
                            hoverBorderColor: RaohaneTheme.borderStrong
                            activeBorderColor: RaohaneTheme.accentBorder

                            Text {
                                anchors.centerIn: parent
                                text: String(autoHideButton.modelData.label)
                                color: autoHideButton.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                font.pixelSize: 8
                                font.weight: autoHideButton.selected ? Font.DemiBold : Font.Medium
                            }

                            MouseArea {
                                id: autoHideMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: autoHideButton.forceActiveFocus()
                                onClicked: RaohaneConfig.mediaOverlayGamingAutoHideSeconds = autoHideButton.optionValue
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    RaohaneConfig.mediaOverlayGamingAutoHideSeconds = autoHideButton.optionValue
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: RaohaneTheme.spacingTiny
            Layout.rightMargin: RaohaneTheme.spacingTiny
            spacing: RaohaneTheme.spacingSmall + 2

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
        active: card.activePolicy
        activeColor: RaohaneTheme.surface
        idleBorderColor: RaohaneTheme.borderFaint
        activeBorderColor: RaohaneTheme.accentBorder
        showStateRail: card.activePolicy
        stateRailWidth: 3
        stateRailLength: 30
        stateRailOpacity: 0.72

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: RaohaneTheme.panelPadding + RaohaneTheme.spacingTiny
            spacing: RaohaneTheme.spacingLarge

            RowLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacing

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.max(1, RaohaneTheme.spacingTiny - 1)

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

            RaohaneSurface {
                id: monitor
                Layout.fillWidth: true
                Layout.preferredHeight: 184
                surfaceRadius: RaohaneTheme.radiusHero
                active: card.activePolicy
                raised: false
                showSheen: false
                showInnerRim: true
                idleColor: RaohaneTheme.surfaceDeep
                activeColor: RaohaneTheme.surfaceDeep
                idleBorderColor: RaohaneTheme.borderFaint
                activeBorderColor: RaohaneTheme.accentBorder
                clip: true

                RaohaneSurface {
                    anchors.fill: parent
                    anchors.margins: RaohaneTheme.spacing + 1
                    surfaceRadius: RaohaneTheme.radius
                    raised: false
                    showSheen: false
                    showInnerRim: false
                    idleColor: RaohaneTheme.surfaceSubtle
                    idleBorderColor: RaohaneTheme.borderFaint

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

                        delegate: RaohaneSurface {
                            id: cornerButton
                            required property var modelData

                            readonly property bool selected: card.value === String(modelData.value)
                            readonly property bool leftSide: String(modelData.value).endsWith("left")
                            readonly property bool topSide: String(modelData.value).startsWith("top")

                            width: card.gaming ? 82 : 92
                            height: card.gaming ? 31 : 34
                            x: leftSide ? RaohaneTheme.spacing : parent.width - width - RaohaneTheme.spacing
                            y: topSide ? RaohaneTheme.spacing : parent.height - height - RaohaneTheme.spacing
                            surfaceRadius: RaohaneTheme.radiusSmall
                            active: selected
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            interactive: true
                            hovered: cornerMouse.containsMouse || activeFocus
                            pressed: cornerMouse.pressed
                            hoverScale: 1
                            pressedScale: 1
                            activeFocusOnTab: true
                            idleColor: RaohaneTheme.surfaceDeep
                            hoverColor: RaohaneTheme.surfaceRaised
                            activeColor: RaohaneTheme.accentSoft
                            idleBorderColor: RaohaneTheme.borderFaint
                            hoverBorderColor: RaohaneTheme.borderStrong
                            activeBorderColor: RaohaneTheme.accentBorder

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: RaohaneTheme.spacingSmall + 2
                                anchors.rightMargin: RaohaneTheme.spacingSmall + 2
                                spacing: Math.max(2, RaohaneTheme.spacingSmall - 1)

                                RaohaneIcon {
                                    text: String(cornerButton.modelData.icon)
                                    iconSize: card.gaming ? 11 : 12
                                    color: cornerButton.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: String(cornerButton.modelData.label)
                                    color: cornerButton.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                                    font.pixelSize: 7
                                    font.weight: cornerButton.selected ? Font.DemiBold : Font.Medium
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                id: cornerMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onPressed: cornerButton.forceActiveFocus()
                                onClicked: card.selected(String(cornerButton.modelData.value))
                            }

                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                    card.selected(String(cornerButton.modelData.value))
                                    event.accepted = true
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacingSmall + 1

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
