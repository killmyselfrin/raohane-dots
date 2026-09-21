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
        spacing: RaohaneTheme.spacing

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: RaohaneTheme.spacingTiny
            Layout.rightMargin: RaohaneTheme.spacingTiny
            spacing: RaohaneTheme.spacing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Player position")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Choose where the compact media player appears in normal and Gaming scenes.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                text: root.gamingActive ? qsTr("Gaming active") : qsTr("Desktop active")
                color: RaohaneTheme.accent
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 14
                icon: "visibility"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.previewPlayer()
            }
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: placementRows.implicitHeight
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            border.color: RaohaneTheme.borderFaint
            clip: true

            Column {
                id: placementRows
                width: parent.width
                spacing: 0

                PositionRow {
                    width: parent.width
                    title: qsTr("Desktop")
                    detail: qsTr("Default position outside Gaming Scene")
                    value: RaohaneConfig.mediaOverlayPosition
                    activePolicy: !root.gamingActive
                    positions: root.positionOptions
                    onSelected: position => RaohaneConfig.mediaOverlayPosition = position
                }

                RaohaneDivider {
                    width: parent.width - RaohaneTheme.panelPadding * 2
                    x: RaohaneTheme.panelPadding
                    color: RaohaneTheme.borderFaint
                }

                PositionRow {
                    width: parent.width
                    title: qsTr("Gaming")
                    detail: qsTr("Position used automatically while Gaming Scene is active")
                    value: RaohaneConfig.mediaOverlayGamingPosition
                    activePolicy: root.gamingActive
                    positions: root.positionOptions
                    onSelected: position => RaohaneConfig.mediaOverlayGamingPosition = position
                }

                RaohaneDivider {
                    width: parent.width - RaohaneTheme.panelPadding * 2
                    x: RaohaneTheme.panelPadding
                    color: RaohaneTheme.borderFaint
                }

                Item {
                    width: parent.width
                    height: 68

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: RaohaneTheme.panelPadding
                        anchors.rightMargin: RaohaneTheme.panelPadding
                        spacing: RaohaneTheme.spacingLarge

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Gaming auto-hide")
                                color: RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: qsTr("Close the compact player automatically after interaction")
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        RowLayout {
                            spacing: 4

                            Repeater {
                                model: root.autoHideOptions

                                delegate: RaohaneSurface {
                                    id: hideChoice
                                    required property var modelData

                                    readonly property int optionValue: Number(modelData.value)
                                    readonly property bool selected: RaohaneConfig.mediaOverlayGamingAutoHideSeconds === optionValue

                                    width: optionValue === 0 ? 48 : 42
                                    height: 30
                                    surfaceRadius: RaohaneTheme.radiusSmall
                                    active: selected
                                    raised: false
                                    showSheen: false
                                    showInnerRim: false
                                    interactive: true
                                    hovered: hideMouse.containsMouse || activeFocus
                                    pressed: hideMouse.pressed
                                    hoverScale: 1
                                    pressedScale: 1
                                    activeFocusOnTab: true
                                    transparentIdle: !selected
                                    hoverColor: RaohaneTheme.surfaceHover
                                    activeColor: RaohaneTheme.accentSoft
                                    idleBorderColor: "transparent"
                                    hoverBorderColor: "transparent"
                                    activeBorderColor: "transparent"

                                    Text {
                                        anchors.centerIn: parent
                                        text: String(hideChoice.modelData.label)
                                        color: hideChoice.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                        font.weight: hideChoice.selected ? Font.DemiBold : Font.Medium
                                    }

                                    MouseArea {
                                        id: hideMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onPressed: hideChoice.forceActiveFocus()
                                        onClicked: RaohaneConfig.mediaOverlayGamingAutoHideSeconds = hideChoice.optionValue
                                    }

                                    Keys.onPressed: event => {
                                        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                            RaohaneConfig.mediaOverlayGamingAutoHideSeconds = hideChoice.optionValue
                                            event.accepted = true
                                        }
                                    }
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
            spacing: RaohaneTheme.spacingSmall

            RaohaneIcon {
                text: "info"
                iconSize: 12
                color: RaohaneTheme.textFaint
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Changes apply immediately. Preview opens the real player using the current Scene policy.")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }
        }
    }

    component PositionRow: Item {
        id: row

        required property string title
        required property string detail
        required property string value
        required property bool activePolicy
        required property var positions
        signal selected(string position)

        height: 72

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding
            anchors.rightMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacingLarge

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: RaohaneTheme.spacingSmall

                    Text {
                        text: row.title
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }

                    Text {
                        visible: row.activePolicy
                        text: qsTr("Active")
                        color: RaohaneTheme.accent
                        font.pixelSize: 7
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: row.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            RowLayout {
                spacing: 4

                Repeater {
                    model: row.positions

                    delegate: RaohaneSurface {
                        id: positionChoice
                        required property var modelData

                        readonly property bool selected: row.value === String(modelData.value)

                        width: 38
                        height: 32
                        surfaceRadius: RaohaneTheme.radiusSmall
                        active: selected
                        raised: false
                        showSheen: false
                        showInnerRim: false
                        interactive: true
                        hovered: positionMouse.containsMouse || activeFocus
                        pressed: positionMouse.pressed
                        hoverScale: 1
                        pressedScale: 1
                        activeFocusOnTab: true
                        transparentIdle: !selected
                        hoverColor: RaohaneTheme.surfaceHover
                        activeColor: RaohaneTheme.accentSoft
                        idleBorderColor: "transparent"
                        hoverBorderColor: "transparent"
                        activeBorderColor: "transparent"

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: String(positionChoice.modelData.icon)
                            iconSize: 15
                            fill: positionChoice.selected ? 1 : 0
                            color: positionChoice.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        MouseArea {
                            id: positionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onPressed: positionChoice.forceActiveFocus()
                            onClicked: row.selected(String(positionChoice.modelData.value))
                        }

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                row.selected(String(positionChoice.modelData.value))
                                event.accepted = true
                            }
                        }
                    }
                }
            }
        }
    }
}
