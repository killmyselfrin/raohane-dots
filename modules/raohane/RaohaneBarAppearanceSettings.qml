pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls

import qs.modules.raohane.config

Item {
    id: root

    implicitHeight: column.implicitHeight

    readonly property var presets: [
        { id: "floating", label: qsTr("Floating"), detail: qsTr("Balanced rounded capsules"), height: 44, radius: 18, opacity: 0.94, margin: 16, spacing: 5, padding: 8 },
        { id: "compact", label: qsTr("Compact"), detail: qsTr("Tighter bar for smaller displays"), height: 38, radius: 13, opacity: 0.96, margin: 10, spacing: 3, padding: 6 },
        { id: "pill", label: qsTr("Pill"), detail: qsTr("Soft fully-rounded modules"), height: 48, radius: 24, opacity: 0.92, margin: 18, spacing: 7, padding: 10 },
        { id: "flat", label: qsTr("Flat"), detail: qsTr("Minimal square-edged layout"), height: 42, radius: 4, opacity: 0.98, margin: 8, spacing: 4, padding: 8 }
    ]

    function applyPreset(preset): void {
        RaohaneConfig.barStylePreset = String(preset.id)
        RaohaneConfig.barHeight = Number(preset.height)
        RaohaneConfig.barRadius = Number(preset.radius)
        RaohaneConfig.barOpacity = Number(preset.opacity)
        RaohaneConfig.barEdgeMargin = Number(preset.margin)
        RaohaneConfig.barModuleSpacing = Number(preset.spacing)
        RaohaneConfig.barHorizontalPadding = Number(preset.padding)
    }

    function markCustom(): void {
        RaohaneConfig.barStylePreset = "custom"
    }

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 12

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: qsTr("Bar appearance")
                    color: RaohaneTheme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Choose a preset or tune the Raohane bar manually. Changes apply live.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                text: RaohaneConfig.barStylePreset === "custom"
                    ? qsTr("Custom")
                    : qsTr("Preset")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width >= 720 ? 4 : 2
            columnSpacing: 8
            rowSpacing: 8

            Repeater {
                model: root.presets

                delegate: RaohaneSurface {
                    id: presetCard
                    required property var modelData

                    readonly property bool selected: RaohaneConfig.barStylePreset === String(modelData.id)

                    Layout.fillWidth: true
                    Layout.preferredHeight: 68
                    surfaceRadius: 13
                    raised: false
                    active: selected
                    interactive: true
                    hovered: presetMouse.containsMouse
                    pressed: presetMouse.pressed
                    showSheen: false

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 2

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: presetCard.modelData.label
                                color: presetCard.selected ? RaohaneTheme.accent : RaohaneTheme.text
                                font.pixelSize: 10
                                font.weight: Font.DemiBold
                            }

                            RaohaneIcon {
                                visible: presetCard.selected
                                text: "check"
                                iconSize: 14
                                color: RaohaneTheme.accent
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: presetCard.modelData.detail
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                            elide: Text.ElideRight
                        }
                    }

                    MouseArea {
                        id: presetMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.applyPreset(presetCard.modelData)
                    }
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: width >= 760 ? 2 : 1
            columnSpacing: 10
            rowSpacing: 10

            BarSlider {
                Layout.fillWidth: true
                title: qsTr("Bar height")
                detail: qsTr("Thickness of horizontal pods and vertical bar")
                value: RaohaneConfig.barHeight
                minimum: 34
                maximum: 58
                step: 1
                suffix: " px"
                onUserChanged: value => {
                    root.markCustom()
                    RaohaneConfig.barHeight = Math.round(value)
                }
            }

            BarSlider {
                Layout.fillWidth: true
                title: qsTr("Corner radius")
                detail: qsTr("Roundness of the bar surface")
                value: RaohaneConfig.barRadius
                minimum: 0
                maximum: 30
                step: 1
                suffix: " px"
                onUserChanged: value => {
                    root.markCustom()
                    RaohaneConfig.barRadius = Math.round(value)
                }
            }

            BarSlider {
                Layout.fillWidth: true
                title: qsTr("Opacity")
                detail: qsTr("Transparency of bar surfaces")
                value: RaohaneConfig.barOpacity
                minimum: 0.35
                maximum: 1.0
                step: 0.01
                multiplier: 100
                suffix: "%"
                onUserChanged: value => {
                    root.markCustom()
                    RaohaneConfig.barOpacity = value
                }
            }

            BarSlider {
                Layout.fillWidth: true
                title: qsTr("Edge margin")
                detail: qsTr("Distance from the screen edge")
                value: RaohaneConfig.barEdgeMargin
                minimum: 0
                maximum: 48
                step: 1
                suffix: " px"
                onUserChanged: value => {
                    root.markCustom()
                    RaohaneConfig.barEdgeMargin = Math.round(value)
                }
            }

            BarSlider {
                Layout.fillWidth: true
                title: qsTr("Module spacing")
                detail: qsTr("Gap between modules inside each zone")
                value: RaohaneConfig.barModuleSpacing
                minimum: 0
                maximum: 20
                step: 1
                suffix: " px"
                onUserChanged: value => {
                    root.markCustom()
                    RaohaneConfig.barModuleSpacing = Math.round(value)
                }
            }

            BarSlider {
                Layout.fillWidth: true
                title: qsTr("Horizontal padding")
                detail: qsTr("Space inside left and right bar capsules")
                value: RaohaneConfig.barHorizontalPadding
                minimum: 2
                maximum: 24
                step: 1
                suffix: " px"
                onUserChanged: value => {
                    root.markCustom()
                    RaohaneConfig.barHorizontalPadding = Math.round(value)
                }
            }
        }
    }

    component BarSlider: RaohaneSurface {
        id: sliderCard

        property string title: ""
        property string detail: ""
        property real value: 0
        property real minimum: 0
        property real maximum: 1
        property real step: 0.1
        property real multiplier: 1
        property string suffix: ""
        signal userChanged(real value)

        Layout.preferredHeight: 82
        surfaceRadius: 13
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 5

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: sliderCard.title
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: sliderCard.detail
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: Math.round(sliderCard.value * sliderCard.multiplier) + sliderCard.suffix
                    color: RaohaneTheme.accent
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }

            Controls.Slider {
                Layout.fillWidth: true
                from: sliderCard.minimum
                to: sliderCard.maximum
                stepSize: sliderCard.step
                value: sliderCard.value
                onMoved: sliderCard.userChanged(value)
            }
        }
    }
}
