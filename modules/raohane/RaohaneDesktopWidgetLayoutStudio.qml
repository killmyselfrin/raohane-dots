pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var composition: RaohaneConfig.sanitizeDesktopWidgetComposition(RaohaneConfig.desktopWidgetComposition)

    implicitHeight: studioColumn.implicitHeight

    function commit(next): void {
        RaohaneConfig.desktopWidgetComposition = RaohaneConfig.sanitizeDesktopWidgetComposition(next)
    }

    function moveWithin(zone: string, index: int, delta: int): void {
        const source = root.composition[zone]?.slice() ?? []
        const target = index + delta
        if (index < 0 || index >= source.length || target < 0 || target >= source.length)
            return
        const item = source.splice(index, 1)[0]
        source.splice(target, 0, item)
        const next = {
            primary: root.composition.primary.slice(),
            secondary: root.composition.secondary.slice()
        }
        next[zone] = source
        root.commit(next)
    }

    function moveAcross(zone: string, index: int): void {
        const otherZone = zone === "primary" ? "secondary" : "primary"
        const source = root.composition[zone]?.slice() ?? []
        if (index < 0 || index >= source.length)
            return
        const destination = root.composition[otherZone]?.slice() ?? []
        const item = source.splice(index, 1)[0]
        destination.push(item)
        const next = {
            primary: root.composition.primary.slice(),
            secondary: root.composition.secondary.slice()
        }
        next[zone] = source
        next[otherZone] = destination
        root.commit(next)
    }

    function resetLayout(): void {
        root.commit(RaohaneConfig.defaultDesktopWidgetComposition())
    }

    ColumnLayout {
        id: studioColumn

        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Widget Layout")
                    color: RaohaneTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Reorder widgets or move them between the primary and secondary desktop rails.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    lineHeight: 1.15
                    wrapMode: Text.WordWrap
                }
            }

            RaohaneSurface {
                Layout.preferredWidth: resetRow.implicitWidth + 22
                Layout.preferredHeight: 34
                surfaceRadius: 10
                raised: false
                transparentIdle: true
                interactive: true
                hovered: resetMouse.containsMouse
                pressed: resetMouse.pressed
                hoverScale: 1
                pressedScale: 1
                showSheen: false
                border.color: resetMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                RowLayout {
                    id: resetRow
                    anchors.centerIn: parent
                    spacing: 6

                    RaohaneIcon {
                        text: "restart_alt"
                        iconSize: 14
                        color: resetMouse.containsMouse ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }

                    Text {
                        text: qsTr("Reset")
                        color: resetMouse.containsMouse ? RaohaneTheme.text : RaohaneTheme.textMuted
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                MouseArea {
                    id: resetMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.resetLayout()
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width < 680 ? 1 : 2
            columnSpacing: 10
            rowSpacing: 10

            ZoneCard {
                Layout.fillWidth: true
                zone: "primary"
                title: qsTr("Primary rail")
                icon: "view_agenda"
                items: root.composition.primary
            }

            ZoneCard {
                Layout.fillWidth: true
                zone: "secondary"
                title: qsTr("Secondary rail")
                icon: "view_sidebar"
                items: root.composition.secondary
            }
        }
    }

    component ZoneCard: RaohaneSurface {
        id: zoneCard

        required property string zone
        required property string title
        required property string icon
        required property var items

        Layout.preferredHeight: zoneColumn.implicitHeight + 24
        surfaceRadius: 12
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                topMargin: 12
                bottomMargin: 12
            }
            width: 3
            radius: 2
            color: RaohaneTheme.accent
            opacity: 0.58
        }

        ColumnLayout {
            id: zoneColumn

            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
                leftMargin: 15
            }
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                RaohaneIcon {
                    text: zoneCard.icon
                    iconSize: 16
                    color: RaohaneTheme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: zoneCard.title
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                RaohaneSurface {
                    implicitWidth: countLabel.implicitWidth + 14
                    implicitHeight: 24
                    surfaceRadius: 8
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint

                    Text {
                        id: countLabel
                        anchors.centerIn: parent
                        text: String(zoneCard.items.length)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                }
            }

            Text {
                visible: zoneCard.items.length === 0
                Layout.fillWidth: true
                text: qsTr("This rail is empty")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
            }

            Repeater {
                model: zoneCard.items

                delegate: RaohaneSurface {
                    id: widgetRow

                    required property var modelData
                    required property int index

                    readonly property string widgetId: String(modelData)
                    readonly property var definition: RaohaneDesktopWidgetRegistry.definition(widgetId)

                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    surfaceRadius: 10
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 11
                        anchors.rightMargin: 6
                        spacing: 8

                        RaohaneIcon {
                            text: widgetRow.definition?.icon ?? "widgets"
                            iconSize: 16
                            color: RaohaneTheme.accent
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 0

                            Text {
                                Layout.fillWidth: true
                                text: widgetRow.definition?.title ?? widgetRow.widgetId
                                color: RaohaneTheme.text
                                font.pixelSize: 9
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: widgetRow.definition?.detail ?? ""
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 8
                                elide: Text.ElideRight
                            }
                        }

                        RaohaneIconButton {
                            enabled: widgetRow.index > 0
                            opacity: enabled ? 1 : 0.30
                            buttonSize: 29
                            iconSize: 13
                            icon: "arrow_upward"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: root.moveWithin(zoneCard.zone, widgetRow.index, -1)
                        }

                        RaohaneIconButton {
                            enabled: widgetRow.index < zoneCard.items.length - 1
                            opacity: enabled ? 1 : 0.30
                            buttonSize: 29
                            iconSize: 13
                            icon: "arrow_downward"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: root.moveWithin(zoneCard.zone, widgetRow.index, 1)
                        }

                        RaohaneIconButton {
                            buttonSize: 29
                            iconSize: 13
                            icon: zoneCard.zone === "primary" ? "arrow_forward" : "arrow_back"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: root.moveAcross(zoneCard.zone, widgetRow.index)
                        }
                    }
                }
            }
        }
    }
}
