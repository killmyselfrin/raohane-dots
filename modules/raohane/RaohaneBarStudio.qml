pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var zones: ["left", "center", "right"]
    readonly property var layout: RaohaneBarModuleRegistry.sanitizeLayout(
        RaohaneConfig.barModuleLayout,
        "horizontal"
    )
    readonly property var availableModules: RaohaneBarModuleRegistry.moduleIds.filter(id => {
        return RaohaneBarModuleRegistry.isRepeatable(id) || !root.containsModule(id)
    })

    implicitHeight: studioColumn.implicitHeight

    function zoneLabel(zone: string): string {
        switch (zone) {
        case "left": return qsTr("Left")
        case "center": return qsTr("Center")
        case "right": return qsTr("Right")
        default: return zone
        }
    }

    function zoneItems(zone: string): var {
        return root.layout[zone] ?? []
    }

    function mutableLayout(): var {
        return {
            left: root.layout.left.slice(),
            center: root.layout.center.slice(),
            right: root.layout.right.slice()
        }
    }

    function commit(layout): void {
        RaohaneConfig.barModuleLayout = RaohaneBarModuleRegistry.sanitizeLayout(layout, "horizontal")
    }

    function containsModule(id: string): bool {
        for (let z = 0; z < root.zones.length; ++z) {
            if (root.zoneItems(root.zones[z]).indexOf(id) >= 0)
                return true
        }
        return false
    }

    function removeAt(zone: string, index: int): void {
        const next = root.mutableLayout()
        if (!next[zone] || index < 0 || index >= next[zone].length)
            return
        next[zone].splice(index, 1)
        root.commit(next)
    }

    function moveWithin(zone: string, index: int, delta: int): void {
        const next = root.mutableLayout()
        if (!next[zone])
            return
        const target = index + delta
        if (index < 0 || index >= next[zone].length || target < 0 || target >= next[zone].length)
            return
        const item = next[zone].splice(index, 1)[0]
        next[zone].splice(target, 0, item)
        root.commit(next)
    }

    function moveAcross(zone: string, index: int, delta: int): void {
        const zoneIndex = root.zones.indexOf(zone)
        const targetIndex = zoneIndex + delta
        if (zoneIndex < 0 || targetIndex < 0 || targetIndex >= root.zones.length)
            return

        const next = root.mutableLayout()
        if (!next[zone] || index < 0 || index >= next[zone].length)
            return
        const targetZone = root.zones[targetIndex]
        const item = next[zone].splice(index, 1)[0]
        next[targetZone].push(item)
        root.commit(next)
    }

    function addModule(id: string): void {
        if (!RaohaneBarModuleRegistry.supports(id, "horizontal"))
            return
        if (!RaohaneBarModuleRegistry.isRepeatable(id) && root.containsModule(id))
            return

        const next = root.mutableLayout()
        const targetZone = RaohaneBarModuleRegistry.preferredZone(id)
        next[targetZone].push(id)
        root.commit(next)
    }

    function resetLayout(): void {
        root.commit(RaohaneBarModuleRegistry.defaultLayout)
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
                    text: qsTr("Bar Studio")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Compose the horizontal bar from native modules. Changes apply live and are saved automatically.")
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

        Repeater {
            model: root.zones

            delegate: RaohaneSurface {
                id: zoneCard
                required property var modelData
                required property int index

                readonly property string zoneId: String(modelData)
                readonly property var items: root.zoneItems(zoneId)

                Layout.fillWidth: true
                Layout.preferredHeight: zoneColumn.implicitHeight + 22
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: RaohaneTheme.borderFaint

                ColumnLayout {
                    id: zoneColumn
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
                            text: zoneCard.zoneId === "left" ? "align_horizontal_left"
                                : zoneCard.zoneId === "center" ? "align_horizontal_center"
                                : "align_horizontal_right"
                            iconSize: 15
                            color: RaohaneTheme.accent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.zoneLabel(zoneCard.zoneId)
                            color: RaohaneTheme.text
                            font.pixelSize: 9
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: qsTr("%1 modules").arg(zoneCard.items.length)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 7
                        }
                    }

                    Text {
                        visible: zoneCard.items.length === 0
                        Layout.fillWidth: true
                        text: qsTr("This zone is empty. Add a module below.")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Repeater {
                        model: zoneCard.items

                        delegate: RaohaneSurface {
                            id: moduleRow
                            required property var modelData
                            required property int index

                            readonly property string moduleId: String(modelData)

                            Layout.fillWidth: true
                            Layout.preferredHeight: 42
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
                                    text: RaohaneBarModuleRegistry.definition(moduleRow.moduleId)?.icon ?? "widgets"
                                    iconSize: 15
                                    color: RaohaneTheme.accent
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: -1

                                    Text {
                                        Layout.fillWidth: true
                                        text: RaohaneBarModuleRegistry.label(moduleRow.moduleId)
                                        color: RaohaneTheme.text
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: RaohaneBarModuleRegistry.description(moduleRow.moduleId)
                                        color: RaohaneTheme.textFaint
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                }

                                RaohaneIconButton {
                                    visible: zoneCard.index > 0
                                    buttonSize: 27
                                    iconSize: 13
                                    icon: "west"
                                    transparentIdle: true
                                    showSheen: false
                                    onClicked: root.moveAcross(zoneCard.zoneId, moduleRow.index, -1)
                                }

                                RaohaneIconButton {
                                    enabled: moduleRow.index > 0
                                    opacity: enabled ? 1 : 0.34
                                    buttonSize: 27
                                    iconSize: 13
                                    icon: "arrow_upward"
                                    transparentIdle: true
                                    showSheen: false
                                    onClicked: root.moveWithin(zoneCard.zoneId, moduleRow.index, -1)
                                }

                                RaohaneIconButton {
                                    enabled: moduleRow.index < zoneCard.items.length - 1
                                    opacity: enabled ? 1 : 0.34
                                    buttonSize: 27
                                    iconSize: 13
                                    icon: "arrow_downward"
                                    transparentIdle: true
                                    showSheen: false
                                    onClicked: root.moveWithin(zoneCard.zoneId, moduleRow.index, 1)
                                }

                                RaohaneIconButton {
                                    visible: zoneCard.index < root.zones.length - 1
                                    buttonSize: 27
                                    iconSize: 13
                                    icon: "east"
                                    transparentIdle: true
                                    showSheen: false
                                    onClicked: root.moveAcross(zoneCard.zoneId, moduleRow.index, 1)
                                }

                                RaohaneIconButton {
                                    buttonSize: 27
                                    iconSize: 13
                                    icon: "close"
                                    transparentIdle: true
                                    showSheen: false
                                    onClicked: root.removeAt(zoneCard.zoneId, moduleRow.index)
                                }
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
                        text: qsTr("Available modules")
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }
                }

                Text {
                    visible: root.availableModules.length === 0
                    Layout.fillWidth: true
                    text: qsTr("All single-instance modules are already on the bar.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                }

                Repeater {
                    model: root.availableModules

                    delegate: RaohaneSurface {
                        id: availableRow
                        required property var modelData

                        readonly property string moduleId: String(modelData)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
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
                                text: RaohaneBarModuleRegistry.definition(availableRow.moduleId)?.icon ?? "widgets"
                                iconSize: 15
                                color: RaohaneTheme.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: -1

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneBarModuleRegistry.label(availableRow.moduleId)
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneBarModuleRegistry.description(availableRow.moduleId)
                                    color: RaohaneTheme.textFaint
                                    font.pixelSize: 7
                                    elide: Text.ElideRight
                                }
                            }

                            Text {
                                text: qsTr("to %1").arg(root.zoneLabel(RaohaneBarModuleRegistry.preferredZone(availableRow.moduleId)))
                                color: RaohaneTheme.textFaint
                                font.pixelSize: 7
                            }

                            RaohaneIconButton {
                                buttonSize: 28
                                iconSize: 14
                                icon: "add"
                                onClicked: root.addModule(availableRow.moduleId)
                            }
                        }
                    }
                }
            }
        }
    }
}
