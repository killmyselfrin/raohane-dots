pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var layout: RaohaneQuickControlRegistry.sanitizeLayout(RaohaneConfig.quickControlTiles)
    readonly property var availableTiles: RaohaneQuickControlRegistry.tileIds.filter(id => root.layout.indexOf(id) < 0)

    implicitHeight: studioColumn.implicitHeight

    function commit(items): void {
        RaohaneConfig.quickControlTiles = RaohaneQuickControlRegistry.sanitizeLayout(items)
    }

    function addTile(id: string): void {
        if (!RaohaneQuickControlRegistry.isKnown(id) || root.layout.indexOf(id) >= 0)
            return
        const next = root.layout.slice()
        next.push(id)
        root.commit(next)
    }

    function removeAt(index: int): void {
        if (index < 0 || index >= root.layout.length)
            return
        const next = root.layout.slice()
        next.splice(index, 1)
        root.commit(next)
    }

    function move(index: int, delta: int): void {
        const target = index + delta
        if (index < 0 || index >= root.layout.length || target < 0 || target >= root.layout.length)
            return
        const next = root.layout.slice()
        const item = next.splice(index, 1)[0]
        next.splice(target, 0, item)
        root.commit(next)
    }

    function resetLayout(): void {
        root.commit(RaohaneQuickControlRegistry.defaultLayout)
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
                    text: qsTr("Quick Controls Studio")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Choose and reorder Control Center tiles. Changes apply live and are saved automatically.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    wrapMode: Text.WordWrap
                }
            }

            RaohaneSurface {
                Layout.preferredWidth: resetRow.implicitWidth + 20
                Layout.preferredHeight: 32
                surfaceRadius: 10
                raised: false
                interactive: true
                hovered: resetMouse.containsMouse
                pressed: resetMouse.pressed
                showSheen: false

                RowLayout {
                    id: resetRow
                    anchors.centerIn: parent
                    spacing: 5

                    RaohaneIcon {
                        text: "restart_alt"
                        iconSize: 14
                        color: RaohaneTheme.textMuted
                    }

                    Text {
                        text: qsTr("Reset")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
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

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: activeColumn.implicitHeight + 22
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            border.color: RaohaneTheme.borderFaint

            ColumnLayout {
                id: activeColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 11
                }
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RaohaneIcon {
                        text: "dashboard_customize"
                        iconSize: 15
                        color: RaohaneTheme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Active tiles")
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: qsTr("%1 tiles").arg(root.layout.length)
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 7
                    }
                }

                Repeater {
                    model: root.layout

                    delegate: RaohaneSurface {
                        id: activeRow
                        required property var modelData
                        required property int index

                        readonly property string tileId: String(modelData)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        surfaceRadius: 11
                        raised: false
                        showSheen: false
                        border.color: RaohaneTheme.borderFaint

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 6
                            spacing: 8

                            RaohaneIcon {
                                text: RaohaneQuickControlRegistry.definition(activeRow.tileId)?.icon ?? "toggle_on"
                                iconSize: 16
                                color: RaohaneTheme.accent
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -1

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneQuickControlRegistry.label(activeRow.tileId)
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneQuickControlRegistry.description(activeRow.tileId)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }

                            RaohaneIconButton {
                                enabled: activeRow.index > 0
                                opacity: enabled ? 1 : 0.34
                                buttonSize: 27
                                iconSize: 13
                                icon: "arrow_upward"
                                transparentIdle: true
                                showSheen: false
                                onClicked: root.move(activeRow.index, -1)
                            }

                            RaohaneIconButton {
                                enabled: activeRow.index < root.layout.length - 1
                                opacity: enabled ? 1 : 0.34
                                buttonSize: 27
                                iconSize: 13
                                icon: "arrow_downward"
                                transparentIdle: true
                                showSheen: false
                                onClicked: root.move(activeRow.index, 1)
                            }

                            RaohaneIconButton {
                                enabled: root.layout.length > 1
                                opacity: enabled ? 1 : 0.34
                                buttonSize: 27
                                iconSize: 13
                                icon: "close"
                                transparentIdle: true
                                showSheen: false
                                onClicked: root.removeAt(activeRow.index)
                            }
                        }
                    }
                }
            }
        }

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: availableColumn.implicitHeight + 22
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            border.color: RaohaneTheme.borderFaint

            ColumnLayout {
                id: availableColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 11
                }
                spacing: 7

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RaohaneIcon {
                        text: "add_circle"
                        iconSize: 15
                        color: RaohaneTheme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Available tiles")
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    visible: root.availableTiles.length === 0
                    Layout.fillWidth: true
                    text: qsTr("All Quick Control tiles are active.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                }

                Repeater {
                    model: root.availableTiles

                    delegate: RaohaneSurface {
                        id: availableRow
                        required property var modelData

                        readonly property string tileId: String(modelData)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        surfaceRadius: 11
                        raised: false
                        showSheen: false
                        border.color: RaohaneTheme.borderFaint

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 7
                            spacing: 8

                            RaohaneIcon {
                                text: RaohaneQuickControlRegistry.definition(availableRow.tileId)?.icon ?? "toggle_on"
                                iconSize: 16
                                color: RaohaneTheme.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -1

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneQuickControlRegistry.label(availableRow.tileId)
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneQuickControlRegistry.description(availableRow.tileId)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }

                            RaohaneIconButton {
                                buttonSize: 29
                                iconSize: 14
                                icon: "add"
                                transparentIdle: true
                                showSheen: false
                                onClicked: root.addTile(availableRow.tileId)
                            }
                        }
                    }
                }
            }
        }
    }
}
