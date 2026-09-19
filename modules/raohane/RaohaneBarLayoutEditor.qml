pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property string orientation: RaohaneConfig.barVertical ? "vertical" : "horizontal"

    readonly property bool vertical: orientation === "vertical"
    readonly property var zones: ["left", "center", "right"]
    readonly property var sourceLayout: vertical
        ? RaohaneConfig.barVerticalModuleLayout
        : RaohaneConfig.barModuleLayout
    readonly property var layout: RaohaneBarModuleRegistry.sanitizeLayout(sourceLayout, orientation)
    readonly property int rowHeight: 52
    readonly property int rowGap: 6
    readonly property int pitch: rowHeight + rowGap
    readonly property string availableZone: "__available__"
    readonly property var availableModules: RaohaneBarModuleRegistry.moduleIds.filter(id => {
        if (!RaohaneBarModuleRegistry.supports(id, root.orientation))
            return false
        return RaohaneBarModuleRegistry.isRepeatable(id) || !root.containsModule(id)
    })

    property var dragInfo: null
    property string dropZone: ""
    property int dropIndex: -1
    readonly property bool dragging: dragInfo !== null

    implicitHeight: editorColumn.implicitHeight

    function zoneLabel(zone: string): string {
        if (root.vertical) {
            if (zone === "left") return qsTr("Top")
            if (zone === "center") return qsTr("Middle")
            if (zone === "right") return qsTr("Bottom")
        } else {
            if (zone === "left") return qsTr("Left")
            if (zone === "center") return qsTr("Center")
            if (zone === "right") return qsTr("Right")
        }
        return zone
    }

    function zoneIcon(zone: string): string {
        if (root.vertical) {
            if (zone === "left") return "vertical_align_top"
            if (zone === "center") return "vertical_align_center"
            if (zone === "right") return "vertical_align_bottom"
        } else {
            if (zone === "left") return "align_horizontal_left"
            if (zone === "center") return "align_horizontal_center"
            if (zone === "right") return "align_horizontal_right"
        }
        return "drag_handle"
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

    function commit(next): void {
        const sanitized = RaohaneBarModuleRegistry.sanitizeLayout(next, root.orientation)
        if (root.vertical)
            RaohaneConfig.barVerticalModuleLayout = sanitized
        else
            RaohaneConfig.barModuleLayout = sanitized
    }

    function containsModule(id: string): bool {
        for (let z = 0; z < root.zones.length; ++z) {
            if (root.zoneItems(root.zones[z]).includes(id))
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

    function addModule(id: string, zone: string, index: int): void {
        if (!RaohaneBarModuleRegistry.supports(id, root.orientation))
            return
        if (!RaohaneBarModuleRegistry.isRepeatable(id) && root.containsModule(id))
            return

        const next = root.mutableLayout()
        const target = root.zones.includes(zone) ? zone : RaohaneBarModuleRegistry.preferredZone(id)
        const at = index < 0 ? next[target].length : Math.max(0, Math.min(index, next[target].length))
        next[target].splice(at, 0, id)
        root.commit(next)
    }

    function moveModule(sourceZone: string, sourceIndex: int, id: string, targetZone: string, targetIndex: int): void {
        if (sourceZone === root.availableZone) {
            root.addModule(id, targetZone, targetIndex)
            return
        }

        const next = root.mutableLayout()
        if (!next[sourceZone] || !next[targetZone])
            return
        if (sourceIndex < 0 || sourceIndex >= next[sourceZone].length)
            return

        if (sourceZone === targetZone) {
            const item = next[sourceZone].splice(sourceIndex, 1)[0]
            const at = Math.max(0, Math.min(targetIndex, next[sourceZone].length))
            next[sourceZone].splice(at, 0, item)
        } else {
            const item = next[sourceZone].splice(sourceIndex, 1)[0]
            const at = Math.max(0, Math.min(targetIndex, next[targetZone].length))
            next[targetZone].splice(at, 0, item)
        }
        root.commit(next)
    }

    function indexFromPosition(position: real, count: int): int {
        return Math.max(0, Math.min(Math.round(position / root.pitch), count))
    }

    function commitDrop(targetZone: string): void {
        if (root.dragInfo && root.dropIndex >= 0)
            root.moveModule(
                String(root.dragInfo.zone),
                Number(root.dragInfo.index),
                String(root.dragInfo.id),
                targetZone,
                root.dropIndex
            )
        root.endDrag()
    }

    function endDrag(): void {
        root.dragInfo = null
        root.dropZone = ""
        root.dropIndex = -1
    }

    function resetLayout(): void {
        root.commit(RaohaneBarModuleRegistry.defaultLayoutFor(root.orientation))
    }

    ColumnLayout {
        id: editorColumn
        width: parent.width
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: qsTr("Module layout")
                    color: RaohaneTheme.text
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Drag modules between zones or drag an available module into the exact position you want.")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    wrapMode: Text.WordWrap
                }
            }

            RaohaneIconButton {
                buttonSize: 32
                iconSize: 15
                icon: "restart_alt"
                transparentIdle: true
                showSheen: false
                onClicked: root.resetLayout()
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
                readonly property bool dropActive: root.dragging && root.dropZone === zoneId

                Layout.fillWidth: true
                implicitHeight: zoneColumn.implicitHeight + 20
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                border.color: dropActive ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint
                idleColor: dropActive ? RaohaneTheme.accentSoft : RaohaneTheme.surface

                ColumnLayout {
                    id: zoneColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    spacing: 7

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RaohaneIcon {
                            text: root.zoneIcon(zoneCard.zoneId)
                            iconSize: 16
                            color: zoneCard.dropActive ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.zoneLabel(zoneCard.zoneId)
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: String(zoneCard.items.length)
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    DropArea {
                        id: zoneDrop
                        Layout.fillWidth: true
                        implicitHeight: Math.max(rows.implicitHeight, root.rowHeight)

                        readonly property int liveCount: zoneCard.items.length
                            - ((root.dragInfo && root.dragInfo.zone === zoneCard.zoneId) ? 1 : 0)

                        function updateDrop(yPos): void {
                            root.dropZone = zoneCard.zoneId
                            root.dropIndex = root.indexFromPosition(yPos, zoneDrop.liveCount)
                        }

                        onEntered: drag => zoneDrop.updateDrop(drag.y)
                        onPositionChanged: drag => zoneDrop.updateDrop(drag.y)
                        onExited: {
                            if (root.dropZone === zoneCard.zoneId) {
                                root.dropZone = ""
                                root.dropIndex = -1
                            }
                        }
                        onDropped: root.commitDrop(zoneCard.zoneId)

                        Rectangle {
                            visible: zoneDrop.liveCount === 0
                            anchors.fill: parent
                            radius: 10
                            color: zoneCard.dropActive ? RaohaneTheme.accentSoft : "transparent"
                            border.width: 1
                            border.color: zoneCard.dropActive ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                RaohaneIcon {
                                    text: zoneCard.dropActive ? "download" : "drag_handle"
                                    iconSize: 15
                                    color: zoneCard.dropActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                }

                                Text {
                                    text: zoneCard.dropActive ? qsTr("Release to drop") : qsTr("Drop modules here")
                                    color: zoneCard.dropActive ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                    font.pixelSize: 8
                                }
                            }
                        }

                        Column {
                            id: rows
                            width: parent.width
                            spacing: root.rowGap

                            Repeater {
                                model: zoneCard.items

                                delegate: ModuleRow {
                                    required property var modelData
                                    required property int index

                                    moduleId: String(modelData)
                                    zone: zoneCard.zoneId
                                    rowIndex: index
                                }
                            }

                            Item {
                                visible: root.dragInfo && root.dragInfo.zone === zoneCard.zoneId
                                width: parent.width
                                height: visible ? root.rowHeight : 0
                            }
                        }

                        Rectangle {
                            visible: zoneCard.dropActive && root.dropIndex >= 0 && zoneDrop.liveCount > 0
                            x: 7
                            width: parent.width - 14
                            height: 3
                            radius: 2
                            color: RaohaneTheme.accent
                            y: Math.min(root.dropIndex, zoneDrop.liveCount) * root.pitch - root.rowGap / 2 - height / 2
                            z: 100

                            Behavior on y {
                                NumberAnimation {
                                    duration: RaohaneMotion.micro
                                    easing.type: RaohaneMotion.easeStandard
                                }
                            }
                        }
                    }
                }
            }
        }

        RaohaneSurface {
            Layout.fillWidth: true
            implicitHeight: availableColumn.implicitHeight + 20
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
                    margins: 10
                }
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 7

                    RaohaneIcon {
                        text: "add_box"
                        iconSize: 16
                        color: RaohaneTheme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Available modules")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: qsTr("drag or click to add")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 6

                    Repeater {
                        model: root.availableModules

                        delegate: AvailableChip {
                            required property var modelData
                            moduleId: String(modelData)
                        }
                    }
                }
            }
        }
    }

    component ModuleRow: RaohaneSurface {
        id: row

        required property string moduleId
        required property string zone
        required property int rowIndex

        readonly property bool beingDragged: root.dragInfo
            && root.dragInfo.zone === row.zone
            && root.dragInfo.index === row.rowIndex

        width: parent ? parent.width : implicitWidth
        height: root.rowHeight
        surfaceRadius: 11
        raised: false
        interactive: true
        hovered: dragMouse.containsMouse
        pressed: dragMouse.pressed
        active: beingDragged
        showSheen: false
        scale: beingDragged ? 1.02 : 1
        z: beingDragged ? 200 : 1

        Drag.active: dragMouse.drag.active
        Drag.source: row
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        Behavior on scale {
            NumberAnimation {
                duration: RaohaneMotion.micro
                easing.type: RaohaneMotion.easeEmphasized
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 7
            spacing: 8

            RaohaneIcon {
                text: "drag_indicator"
                iconSize: 16
                color: RaohaneTheme.textFaint
            }

            RaohaneIcon {
                text: RaohaneBarModuleRegistry.definition(row.moduleId)?.icon ?? "widgets"
                iconSize: 16
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: RaohaneBarModuleRegistry.label(row.moduleId)
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: RaohaneBarModuleRegistry.description(row.moduleId)
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            RaohaneIconButton {
                buttonSize: 28
                iconSize: 13
                icon: "close"
                transparentIdle: true
                showSheen: false
                onClicked: root.removeAt(row.zone, row.rowIndex)
            }
        }

        MouseArea {
            id: dragMouse
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                rightMargin: 38
            }
            hoverEnabled: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            drag.target: row
            drag.axis: Drag.XAndYAxis
            onPressed: root.dragInfo = ({ zone: row.zone, index: row.rowIndex, id: row.moduleId })
            onReleased: {
                if (row.Drag.target)
                    row.Drag.drop()
                else
                    root.endDrag()
            }
            onCanceled: root.endDrag()
        }
    }

    component AvailableChip: RaohaneSurface {
        id: chip

        required property string moduleId

        readonly property bool beingDragged: root.dragInfo
            && root.dragInfo.zone === root.availableZone
            && root.dragInfo.id === chip.moduleId

        implicitWidth: chipRow.implicitWidth + 18
        implicitHeight: 34
        surfaceRadius: 11
        raised: false
        interactive: true
        hovered: chipMouse.containsMouse
        pressed: chipMouse.pressed
        active: beingDragged
        showSheen: false
        z: beingDragged ? 200 : 1

        Drag.active: chipMouse.drag.active
        Drag.source: chip
        Drag.hotSpot.x: width / 2
        Drag.hotSpot.y: height / 2

        RowLayout {
            id: chipRow
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: RaohaneBarModuleRegistry.definition(chip.moduleId)?.icon ?? "widgets"
                iconSize: 14
                color: RaohaneTheme.accent
            }

            Text {
                text: RaohaneBarModuleRegistry.label(chip.moduleId)
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: Font.Medium
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
            drag.target: chip
            drag.axis: Drag.XAndYAxis

            property bool moved: false

            onPressed: {
                moved = false
                root.dragInfo = ({ zone: root.availableZone, index: -1, id: chip.moduleId })
            }
            onPositionChanged: {
                if (pressed)
                    moved = true
            }
            onReleased: {
                if (chip.Drag.target) {
                    chip.Drag.drop()
                    return
                }
                if (!moved)
                    root.addModule(chip.moduleId, RaohaneBarModuleRegistry.preferredZone(chip.moduleId), -1)
                root.endDrag()
            }
            onCanceled: root.endDrag()
        }
    }
}
