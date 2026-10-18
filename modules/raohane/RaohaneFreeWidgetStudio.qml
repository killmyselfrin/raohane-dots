pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell

import qs.modules.raohane.config

// Optional free-layout editor. Geometry is normalized to the available
// monitor area; the desktop renderer uses the same placement model.
Item {
    id: root

    property string monitorName: Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "default"
    property string selectedWidgetId: "clock"

    readonly property var monitorScreen: Quickshell.screens.find(s => s.name === root.monitorName)
        ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0] : null)
    readonly property int monitorWidth: Math.max(1, Math.round(root.monitorScreen?.width ?? 1920))
    readonly property int monitorHeight: Math.max(1, Math.round(root.monitorScreen?.height ?? 1080))
    readonly property var selectedDefinition: RaohaneDesktopWidgetRegistry.definition(root.selectedWidgetId)
    readonly property var selectedPlacement: RaohaneConfig.desktopWidgetPlacement(root.monitorName, root.selectedWidgetId)
    readonly property var widgetChoices: RaohaneDesktopWidgetRegistry.definitions()
    readonly property var widgetIds: RaohaneDesktopWidgetRegistry.widgetIds

    // A disconnected output must not leave the editor writing invisible layouts.
    onMonitorScreenChanged: {
        if (root.monitorScreen && root.monitorName !== String(root.monitorScreen.name))
            root.monitorName = String(root.monitorScreen.name)
    }

    implicitHeight: contentColumn.implicitHeight
    focus: false

    // Clicking a widget focuses the preview. Arrow keys then move it in 1%
    // steps without requiring a pointer drag.
    Keys.onPressed: event => {
        if (!root.visible)
            return
        let dx = 0
        let dy = 0
        if (event.key === Qt.Key_Left)
            dx = -0.01
        else if (event.key === Qt.Key_Right)
            dx = 0.01
        else if (event.key === Qt.Key_Up)
            dy = -0.01
        else if (event.key === Qt.Key_Down)
            dy = 0.01
        else
            return
        root.nudgeSelected(dx, dy)
        event.accepted = true
    }

    function nudgeSelected(dx: real, dy: real): void {
        const p = root.selectedPlacement
        if (!p)
            return
        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, root.selectedWidgetId,
            p.x + dx, p.y + dy, p.size)
    }

    function resetSelected(): void {
        const defaults = RaohaneConfig.defaultDesktopWidgetFreePlacements()
        const p = defaults[root.selectedWidgetId]
        if (p)
            RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, root.selectedWidgetId,
                p.x, p.y, p.size)
    }

    function adjustSelectedSize(delta: real): void {
        if (!root.selectedPlacement)
            return
        const p = root.selectedPlacement
        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, root.selectedWidgetId,
            p.x, p.y, Math.round((p.size + delta) * 100) / 100)
    }

    ColumnLayout {
        id: contentColumn
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    text: qsTr("Free layout editor")
                    color: RaohaneTheme.text
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Drag widgets to move them. Drag a corner to resize. Changes are saved for each monitor.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 10
                    wrapMode: Text.WordWrap
                }
            }

            Controls.ComboBox {
                id: monitorSelector
                Layout.preferredWidth: 174
                model: Quickshell.screens.map(s => s.name)
                currentIndex: Math.max(0, model.indexOf(root.monitorName))
                onActivated: root.monitorName = String(currentText)
                font.pixelSize: 11
                background: Rectangle {
                    color: RaohaneTheme.surfaceRaised
                    radius: 9
                    border.color: RaohaneTheme.borderFaint
                }
            }

            Controls.Button {
                text: qsTr("Reset monitor")
                onClicked: RaohaneConfig.resetDesktopWidgetFreeLayout(root.monitorName)
                font.pixelSize: 10
                background: Rectangle {
                    color: RaohaneTheme.surfaceRaised
                    radius: 9
                    border.color: RaohaneTheme.borderFaint
                }
                contentItem: Text {
                    text: parent.text
                    color: RaohaneTheme.text
                    font: parent.font
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        Rectangle {
            id: preview
            Layout.fillWidth: true
            Layout.preferredHeight: Math.max(250, Math.min(490, width * root.monitorHeight / root.monitorWidth))
            radius: 13
            clip: true
            color: RaohaneTheme.background
            border.width: 1
            border.color: RaohaneTheme.borderFaint

            // A static grid previews layout without starting a second media
            // player, visualizer, or any service subscriptions inside Settings.
            Repeater {
                model: 9
                delegate: Rectangle {
                    required property int index
                    x: (index + 1) * preview.width / 10
                    y: 0
                    width: 1
                    height: preview.height
                    color: RaohaneTheme.borderFaint
                    opacity: 0.32
                }
            }

            Repeater {
                model: 5
                delegate: Rectangle {
                    required property int index
                    x: 0
                    y: (index + 1) * preview.height / 6
                    width: preview.width
                    height: 1
                    color: RaohaneTheme.borderFaint
                    opacity: 0.32
                }
            }

            Repeater {
                model: RaohaneDesktopWidgetRegistry.widgetIds

                delegate: Rectangle {
                    id: tile

                    required property var modelData
                    readonly property string widgetId: String(modelData)
                    readonly property var definition: RaohaneDesktopWidgetRegistry.definition(widgetId)
                    readonly property var placement: RaohaneConfig.desktopWidgetPlacement(root.monitorName, widgetId)
                    readonly property bool enabledWidget: Boolean(RaohaneConfig[definition?.key ?? ""])
                    readonly property real baseWidth: Math.max(65,
                        (definition?.freeWidth ?? 280) * preview.width / root.monitorWidth)
                    readonly property real baseHeight: Math.max(30,
                        (definition?.freeHeight ?? 120) * preview.height / root.monitorHeight)
                    property bool editing: false
                    property real workingX: 0
                    property real workingY: 0
                    property real workingSize: 1
                    property real pressPointerX: 0
                    property real pressPointerY: 0
                    property real pressStartX: 0
                    property real pressStartY: 0
                    property real pressStartSize: 1

                    readonly property real shownSize: editing ? workingSize : (placement?.size ?? 1)
                    width: Math.min(preview.width, baseWidth * shownSize)
                    height: Math.min(preview.height, baseHeight * shownSize)
                    readonly property real travelX: Math.max(0, preview.width - width)
                    readonly property real travelY: Math.max(0, preview.height - height)
                    x: editing ? workingX : (placement?.x ?? 0) * travelX
                    y: editing ? workingY : (placement?.y ?? 0) * travelY
                    z: root.selectedWidgetId === widgetId ? 2 : 1
                    visible: enabledWidget
                    radius: 11
                    color: RaohaneTheme.surfaceRaised
                    opacity: 0.94
                    border.width: root.selectedWidgetId === widgetId ? 2 : 1
                    border.color: root.selectedWidgetId === widgetId
                        ? RaohaneTheme.accent : RaohaneTheme.borderFaint

                    function beginInteraction(px, py): void {
                        root.selectedWidgetId = widgetId
                        root.forceActiveFocus()
                        workingX = x
                        workingY = y
                        workingSize = shownSize
                        pressPointerX = px
                        pressPointerY = py
                        pressStartX = x
                        pressStartY = y
                        pressStartSize = workingSize
                        editing = true
                    }

                    function commitInteraction(): void {
                        if (!editing)
                            return
                        const normX = travelX > 0 ? Math.max(0, Math.min(1, workingX / travelX)) : 0
                        const normY = travelY > 0 ? Math.max(0, Math.min(1, workingY / travelY)) : 0
                        RaohaneConfig.setDesktopWidgetPlacement(root.monitorName, widgetId,
                            normX, normY, workingSize)
                        editing = false
                    }

                    RowLayout {
                        anchors {
                            fill: parent
                            margins: 10
                            bottomMargin: 18
                        }
                        spacing: 6

                        RaohaneIcon {
                            text: tile.definition?.icon ?? "widgets"
                            iconSize: 15
                            color: RaohaneTheme.accent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: tile.definition?.title ?? tile.widgetId
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            color: RaohaneTheme.text
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.bottomMargin: 18
                        cursorShape: Qt.SizeAllCursor
                        onPressed: mouse => {
                            const p = mapToItem(preview, mouse.x, mouse.y)
                            tile.beginInteraction(p.x, p.y)
                        }
                        onPositionChanged: mouse => {
                            if (!pressed || !tile.editing)
                                return
                            const p = mapToItem(preview, mouse.x, mouse.y)
                            tile.workingX = Math.max(0, Math.min(tile.travelX,
                                tile.pressStartX + p.x - tile.pressPointerX))
                            tile.workingY = Math.max(0, Math.min(tile.travelY,
                                tile.pressStartY + p.y - tile.pressPointerY))
                        }
                        onReleased: tile.commitInteraction()
                        onCanceled: tile.editing = false
                    }

                    Rectangle {
                        id: resizeHandle
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 2
                        width: 17
                        height: 17
                        radius: 5
                        color: RaohaneTheme.accent

                        RaohaneIcon {
                            anchors.centerIn: parent
                            text: "open_in_full"
                            iconSize: 12
                            color: RaohaneTheme.background
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.SizeFDiagCursor
                            onPressed: mouse => {
                                const p = mapToItem(preview, mouse.x, mouse.y)
                                tile.beginInteraction(p.x, p.y)
                            }
                            onPositionChanged: mouse => {
                                if (!pressed || !tile.editing)
                                    return
                                const p = mapToItem(preview, mouse.x, mouse.y)
                                const dx = (p.x - tile.pressPointerX) / tile.baseWidth
                                const dy = (p.y - tile.pressPointerY) / tile.baseHeight
                                const delta = Math.abs(dx) >= Math.abs(dy) ? dx : dy
                                tile.workingSize = Math.max(0.65, Math.min(1.4,
                                    tile.pressStartSize + delta))
                                tile.workingX = Math.min(tile.pressStartX, tile.travelX)
                                tile.workingY = Math.min(tile.pressStartY, tile.travelY)
                            }
                            onReleased: tile.commitInteraction()
                            onCanceled: tile.editing = false
                        }
                    }
                }
            }

            Text {
                anchors {
                    bottom: parent.bottom
                    left: parent.left
                    margins: 10
                }
                text: root.monitorName + "  ·  " + root.monitorWidth + " × " + root.monitorHeight
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Controls.ComboBox {
                id: selectedWidgetChoice
                Layout.preferredWidth: 170
                model: root.widgetChoices
                textRole: "title"
                currentIndex: Math.max(0, root.widgetIds.indexOf(root.selectedWidgetId))
                onActivated: index => root.selectedWidgetId = String(root.widgetChoices[index].id)
                font.pixelSize: 10
                background: Rectangle {
                    radius: 8
                    color: RaohaneTheme.surfaceRaised
                    border.color: RaohaneTheme.borderFaint
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: (root.selectedDefinition?.title ?? qsTr("Widget")) + "  ·  "
                        + Math.round((root.selectedPlacement?.size ?? 1) * 100) + "%"
                    color: RaohaneTheme.text
                    font.pixelSize: 11
                    font.weight: Font.DemiBold
                }

                Text {
                    text: qsTr("Drag to move; use arrow keys after selection for precise adjustments.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                }
            }

            Controls.Button {
                text: "−"
                enabled: (root.selectedPlacement?.size ?? 1) > 0.65
                onClicked: root.adjustSelectedSize(-0.05)
                font.pixelSize: 14
            }

            Controls.Button {
                text: "+"
                enabled: (root.selectedPlacement?.size ?? 1) < 1.4
                onClicked: root.adjustSelectedSize(0.05)
                font.pixelSize: 14
            }

            Controls.Button {
                text: qsTr("Reset")
                onClicked: root.resetSelected()
                font.pixelSize: 10
            }
        }
    }
}
