pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var layout: RaohaneQuickControlRegistry.sanitizeLayout(RaohaneConfig.quickControlTiles)
    readonly property var availableTiles: RaohaneQuickControlRegistry.tileIds.filter(id => root.layout.indexOf(id) < 0)
    readonly property int sliderCount: Number(RaohaneConfig.quickSliderBrightness)
        + Number(RaohaneConfig.quickSliderVolume)
        + Number(RaohaneConfig.quickSliderMic)

    implicitHeight: studioColumn.implicitHeight

    function commit(items): void {
        const sanitized = RaohaneQuickControlRegistry.sanitizeLayout(items)
        RaohaneConfig.quickControlTiles = sanitized.slice()
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
        spacing: 12

        RaohaneSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: previewColumn.implicitHeight + 28
            surfaceRadius: RaohaneTheme.radiusLarge
            raised: false
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceSubtle
            border.color: "transparent"
            clip: true

            ColumnLayout {
                id: previewColumn
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 14
                }
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 9

                    RaohaneIcon {
                        text: "dashboard_customize"
                        iconSize: 17
                        fill: 1
                        color: RaohaneTheme.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Active tiles")
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    RaohaneSurface {
                        Layout.preferredWidth: previewCount.implicitWidth + 18
                        Layout.preferredHeight: 26
                        surfaceRadius: RaohaneTheme.radiusSmall
                        raised: false
                        showSheen: false
                        showInnerRim: false
                        idleColor: RaohaneTheme.surfaceDeep
                        idleBorderColor: "transparent"

                        Text {
                            id: previewCount
                            anchors.centerIn: parent
                            text: qsTr("%1 tiles").arg(root.layout.length)
                            color: RaohaneTheme.accent
                            font.pixelSize: 8
                            font.weight: Font.DemiBold
                        }
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: root.layout

                        delegate: RaohaneSurface {
                            id: previewTile
                            required property var modelData

                            readonly property string tileId: String(modelData)

                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            surfaceRadius: RaohaneTheme.radius
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            idleColor: RaohaneTheme.surfaceDeep
                            idleBorderColor: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 11
                                spacing: 8

                                RaohaneIcon {
                                    text: RaohaneQuickControlRegistry.definition(previewTile.tileId)?.icon ?? "toggle_on"
                                    iconSize: 16
                                    fill: 0.25
                                    color: RaohaneTheme.accent
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneQuickControlRegistry.label(previewTile.tileId)
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Rectangle {
                                    Layout.preferredWidth: 6
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: RaohaneTheme.accent
                                    opacity: 0.58
                                }
                            }
                        }
                    }
                }

                RaohaneSurface {
                    visible: root.sliderCount > 0
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? sliderPreviewRow.implicitHeight + 12 : 0
                    surfaceRadius: RaohaneTheme.radius
                    raised: false
                    showSheen: false
                    showInnerRim: false
                    idleColor: RaohaneTheme.surfaceDeep
                    idleBorderColor: "transparent"

                    RowLayout {
                        id: sliderPreviewRow
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: 10
                            rightMargin: 10
                        }
                        spacing: 10

                        SliderPreview {
                            visible: RaohaneConfig.quickSliderBrightness
                            Layout.fillWidth: true
                            icon: "brightness_medium"
                            label: qsTr("Brightness")
                            value: 0.72
                        }

                        SliderPreview {
                            visible: RaohaneConfig.quickSliderVolume
                            Layout.fillWidth: true
                            icon: "volume_up"
                            label: qsTr("Volume")
                            value: 0.58
                        }

                        SliderPreview {
                            visible: RaohaneConfig.quickSliderMic
                            Layout.fillWidth: true
                            icon: "mic"
                            label: qsTr("Microphone")
                            value: 0.44
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            spacing: 12

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: activeColumn.implicitHeight + 26
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                border.color: "transparent"

                ColumnLayout {
                    id: activeColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 13
                    }
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        RaohaneIcon {
                            text: "view_agenda"
                            iconSize: 17
                            color: RaohaneTheme.accent
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Active tiles")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        RaohaneIconButton {
                            buttonSize: 28
                            iconSize: 13
                            icon: "restart_alt"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: root.resetLayout()
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
                            Layout.preferredHeight: 50
                            surfaceRadius: RaohaneTheme.radius
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            transparentIdle: true
                            interactive: true
                            hovered: activeRowMouse.containsMouse
                            pressed: activeRowMouse.pressed
                            hoverColor: RaohaneTheme.surfaceHover
                            idleBorderColor: "transparent"
                            hoverBorderColor: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 6
                                spacing: 8

                                RaohaneIcon {
                                    text: RaohaneQuickControlRegistry.definition(activeRow.tileId)?.icon ?? "toggle_on"
                                    iconSize: 16
                                    color: RaohaneTheme.accent
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneQuickControlRegistry.label(activeRow.tileId)
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                RaohaneIconButton {
                                    enabled: activeRow.index > 0
                                    opacity: enabled ? 1 : 0.28
                                    buttonSize: 29
                                    iconSize: 13
                                    icon: "arrow_upward"
                                    transparentIdle: true
                                    showSheen: false
                                    hoverScale: 1
                                    pressedScale: 1
                                    onClicked: root.move(activeRow.index, -1)
                                }

                                RaohaneIconButton {
                                    enabled: activeRow.index < root.layout.length - 1
                                    opacity: enabled ? 1 : 0.28
                                    buttonSize: 29
                                    iconSize: 13
                                    icon: "arrow_downward"
                                    transparentIdle: true
                                    showSheen: false
                                    hoverScale: 1
                                    pressedScale: 1
                                    onClicked: root.move(activeRow.index, 1)
                                }

                                RaohaneIconButton {
                                    enabled: root.layout.length > 1
                                    opacity: enabled ? 1 : 0.28
                                    buttonSize: 29
                                    iconSize: 13
                                    icon: "close"
                                    transparentIdle: true
                                    showSheen: false
                                    hoverScale: 1
                                    pressedScale: 1
                                    onClicked: root.removeAt(activeRow.index)
                                }
                            }

                            MouseArea {
                                id: activeRowMouse
                                anchors.fill: parent
                                z: -1
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignTop
                Layout.preferredHeight: Math.max(82, availableColumn.implicitHeight + 26)
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                border.color: "transparent"

                ColumnLayout {
                    id: availableColumn
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 13
                    }
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 9

                        RaohaneIcon {
                            text: "add_circle"
                            iconSize: 17
                            color: RaohaneTheme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Available tiles")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        visible: root.availableTiles.length === 0
                        Layout.fillWidth: true
                        text: qsTr("All Quick Control tiles are active.")
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }

                    Repeater {
                        model: root.availableTiles

                        delegate: RaohaneSurface {
                            id: availableRow
                            required property var modelData

                            readonly property string tileId: String(modelData)

                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            surfaceRadius: RaohaneTheme.radius
                            raised: false
                            showSheen: false
                            showInnerRim: false
                            transparentIdle: true
                            interactive: true
                            hovered: availableRowMouse.containsMouse
                            pressed: availableRowMouse.pressed
                            hoverColor: RaohaneTheme.surfaceHover
                            idleBorderColor: "transparent"
                            hoverBorderColor: "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 7
                                spacing: 8

                                RaohaneIcon {
                                    text: RaohaneQuickControlRegistry.definition(availableRow.tileId)?.icon ?? "toggle_on"
                                    iconSize: 16
                                    color: RaohaneTheme.textMuted
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: RaohaneQuickControlRegistry.label(availableRow.tileId)
                                    color: RaohaneTheme.text
                                    font.pixelSize: 9
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                RaohaneIconButton {
                                    buttonSize: 29
                                    iconSize: 13
                                    icon: "add"
                                    transparentIdle: true
                                    showSheen: false
                                    hoverScale: 1
                                    pressedScale: 1
                                    onClicked: root.addTile(availableRow.tileId)
                                }
                            }

                            MouseArea {
                                id: availableRowMouse
                                anchors.fill: parent
                                z: -1
                                hoverEnabled: true
                                acceptedButtons: Qt.NoButton
                            }
                        }
                    }
                }
            }
        }
    }

    component SliderPreview: Item {
        id: sliderPreview

        required property string icon
        required property string label
        required property real value

        implicitHeight: 34

        RowLayout {
            anchors.fill: parent
            spacing: 6

            RaohaneIcon {
                text: sliderPreview.icon
                iconSize: 13
                color: RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 3

                Text {
                    Layout.fillWidth: true
                    text: sliderPreview.label
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    color: RaohaneTheme.borderStrong

                    Rectangle {
                        width: parent.width * sliderPreview.value
                        height: parent.height
                        radius: parent.radius
                        color: RaohaneTheme.accent
                    }
                }
            }
        }
    }
}
