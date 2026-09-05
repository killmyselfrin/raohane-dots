pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var widgets: RaohaneDesktopWidgetRegistry.definitions()
    readonly property var layouts: RaohaneDesktopWidgetRegistry.layouts

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: studioColumn.implicitHeight + 34
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2600

        ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

        Column {
            id: studioColumn

            y: 14
            width: Math.min(parent.width - 36, 860)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 10

            RaohaneSurface {
                width: parent.width
                height: 190
                surfaceRadius: 12
                raised: false
                showSheen: false
                clip: true
                border.color: RaohaneTheme.borderFaint

                Rectangle {
                    anchors.fill: parent
                    color: RaohaneTheme.background
                    opacity: 0.46
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.topMargin: 14
                    anchors.bottomMargin: 14
                    width: 2
                    radius: 1
                    color: RaohaneTheme.accent
                    opacity: 0.76
                }

                ColumnLayout {
                    anchors {
                        left: parent.left
                        top: parent.top
                        leftMargin: 18
                        topMargin: 16
                    }
                    spacing: 1

                    Text {
                        text: "ラオハネ  ·  18:42"
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.letterSpacing: 1
                    }

                    Text {
                        text: qsTr("Your desktop, composed quietly")
                        color: RaohaneTheme.text
                        font.pixelSize: 17
                        font.weight: Font.DemiBold
                    }

                    Text {
                        text: qsTr("Changes appear on the desktop immediately and persist after restart.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                    }
                }

                RowLayout {
                    anchors {
                        left: parent.left
                        right: parent.right
                        bottom: parent.bottom
                        leftMargin: 18
                        rightMargin: 18
                        bottomMargin: 16
                    }
                    spacing: 7

                    Repeater {
                        model: root.widgets

                        delegate: PreviewCard {
                            required property var modelData

                            visible: Boolean(RaohaneConfig[modelData.key])
                            Layout.fillWidth: true
                            icon: modelData.icon
                            title: modelData.title
                            detail: modelData.detail
                        }
                    }
                }
            }

            RowLayout {
                width: parent.width
                spacing: 8

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "widgets"
                    title: qsTr("Desktop widget layer")
                    detail: qsTr("Show all enabled widgets above the wallpaper")
                    checked: RaohaneConfig.desktopWidgetsEnabled
                    onTriggered: RaohaneConfig.desktopWidgetsEnabled = !RaohaneConfig.desktopWidgetsEnabled
                }

                ToggleRow {
                    Layout.preferredWidth: 196
                    icon: "compress"
                    title: qsTr("Compact")
                    detail: qsTr("Smaller spacing")
                    checked: RaohaneConfig.desktopWidgetsCompact
                    onTriggered: RaohaneConfig.desktopWidgetsCompact = !RaohaneConfig.desktopWidgetsCompact
                }
            }

            Column {
                width: parent.width
                spacing: 7

                Text {
                    text: qsTr("COMPOSITION")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1.2
                }

                RowLayout {
                    width: parent.width
                    spacing: 7

                    Repeater {
                        model: root.layouts

                        delegate: RaohaneSurface {
                            id: layoutOption

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.preferredHeight: 54
                            surfaceRadius: 9
                            active: RaohaneConfig.desktopWidgetsLayout === modelData.key
                            interactive: true
                            hovered: layoutMouse.containsMouse
                            pressed: layoutMouse.pressed
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            border.color: layoutOption.active
                                ? RaohaneTheme.accentBorder
                                : layoutOption.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                            Rectangle {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: 2
                                height: layoutOption.active ? 22 : layoutOption.hovered ? 12 : 7
                                radius: 1
                                color: RaohaneTheme.accent
                                opacity: layoutOption.active ? 1 : layoutOption.hovered ? 0.42 : 0
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 11
                                anchors.rightMargin: 10
                                spacing: 8

                                RaohaneIcon {
                                    text: layoutOption.modelData.icon
                                    iconSize: 16
                                    fill: layoutOption.active ? 1 : 0
                                    color: layoutOption.active ? RaohaneTheme.accent : RaohaneTheme.textMuted
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: layoutOption.modelData.title
                                        color: RaohaneTheme.text
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: layoutOption.modelData.detail
                                        color: RaohaneTheme.textMuted
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            MouseArea {
                                id: layoutMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: RaohaneConfig.desktopWidgetsLayout = layoutOption.modelData.key
                            }
                        }
                    }
                }
            }

            RaohaneDesktopWidgetLayoutStudio {
                width: parent.width
            }

            RowLayout {
                width: parent.width
                spacing: 8

                StudioSlider {
                    Layout.fillWidth: true
                    title: qsTr("Widget scale")
                    detail: qsTr("Resize the complete desktop composition")
                    value: RaohaneConfig.desktopWidgetsScale
                    minimum: 0.75
                    maximum: 1.25
                    step: 0.05
                    onUserChanged: value => RaohaneConfig.desktopWidgetsScale = value
                }

                StudioSlider {
                    Layout.fillWidth: true
                    title: qsTr("Surface opacity")
                    detail: qsTr("Blend widgets softly into the wallpaper")
                    value: RaohaneConfig.desktopWidgetsOpacity
                    minimum: 0.45
                    maximum: 1.0
                    step: 0.05
                    onUserChanged: value => RaohaneConfig.desktopWidgetsOpacity = value
                }
            }

            GridLayout {
                width: parent.width
                columns: width < 650 ? 1 : 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: root.widgets

                    delegate: RaohaneSurface {
                        id: widgetOption

                        required property var modelData
                        readonly property bool enabledState: Boolean(RaohaneConfig[modelData.key])

                        Layout.fillWidth: true
                        Layout.preferredHeight: 64
                        surfaceRadius: 10
                        active: enabledState
                        interactive: true
                        hovered: optionMouse.containsMouse
                        pressed: optionMouse.pressed
                        showSheen: false
                        hoverScale: 1
                        pressedScale: 1
                        border.color: widgetOption.enabledState
                            ? RaohaneTheme.accentBorder
                            : widgetOption.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: widgetOption.enabledState ? 26 : widgetOption.hovered ? 14 : 8
                            radius: 1
                            color: RaohaneTheme.accent
                            opacity: widgetOption.enabledState ? 1 : widgetOption.hovered ? 0.38 : 0
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 10
                            spacing: 9

                            RaohaneIcon {
                                text: widgetOption.modelData.icon
                                iconSize: 18
                                fill: widgetOption.enabledState ? 1 : 0
                                color: widgetOption.enabledState ? RaohaneTheme.accent : RaohaneTheme.textMuted
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 1

                                Text {
                                    Layout.fillWidth: true
                                    text: widgetOption.modelData.title
                                    color: RaohaneTheme.text
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: widgetOption.modelData.detail
                                    color: RaohaneTheme.textMuted
                                    font.pixelSize: 7
                                    wrapMode: Text.WordWrap
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                }
                            }

                            RaohaneSwitch {
                                checked: widgetOption.enabledState
                                enabled: false
                                opacity: 1
                            }
                        }

                        MouseArea {
                            id: optionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneConfig[widgetOption.modelData.key] = !Boolean(RaohaneConfig[widgetOption.modelData.key])
                        }
                    }
                }
            }
        }
    }

    component PreviewCard: RaohaneSurface {
        id: previewCard

        required property string icon
        required property string title
        required property string detail

        Layout.preferredHeight: 58
        surfaceRadius: 9
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 9
            anchors.rightMargin: 9
            spacing: 7

            RaohaneIcon {
                text: previewCard.icon
                iconSize: 15
                color: RaohaneTheme.accent
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: previewCard.title
                    color: RaohaneTheme.text
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: previewCard.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }
        }
    }

    component ToggleRow: RaohaneSurface {
        id: toggleRow

        required property string icon
        required property string title
        required property string detail
        required property bool checked
        signal triggered()

        Layout.preferredHeight: 52
        surfaceRadius: 9
        active: checked
        interactive: true
        hovered: toggleMouse.containsMouse
        pressed: toggleMouse.pressed
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        border.color: checked
            ? RaohaneTheme.accentBorder
            : hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 11
            anchors.rightMargin: 9
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: toggleRow.checked ? 20 : 8
                radius: 1
                color: RaohaneTheme.accent
                opacity: toggleRow.checked ? 1 : 0.18
            }

            RaohaneIcon {
                text: toggleRow.icon
                iconSize: 16
                fill: toggleRow.checked ? 1 : 0
                color: toggleRow.checked ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: toggleRow.title
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    text: toggleRow.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                }
            }

            RaohaneSwitch {
                checked: toggleRow.checked
                enabled: false
                opacity: 1
            }
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleRow.triggered()
        }
    }

    component StudioSlider: RaohaneSurface {
        id: sliderCard

        required property string title
        required property string detail
        required property real value
        required property real minimum
        required property real maximum
        required property real step

        signal userChanged(real value)

        Layout.preferredHeight: 66
        surfaceRadius: 10
        raised: false
        showSheen: false
        border.color: studioSlider.hovered || studioSlider.activeFocus ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            RowLayout {
                Layout.fillWidth: true

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
                        text: sliderCard.detail
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 7
                    }
                }

                RaohaneSurface {
                    implicitWidth: valueLabel.implicitWidth + 14
                    implicitHeight: 20
                    surfaceRadius: 7
                    raised: false
                    showSheen: false
                    border.color: RaohaneTheme.borderFaint

                    Text {
                        id: valueLabel
                        anchors.centerIn: parent
                        text: Math.round(sliderCard.value * 100) + "%"
                        color: RaohaneTheme.accent
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                }
            }

            RaohaneSlider {
                id: studioSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                from: sliderCard.minimum
                to: sliderCard.maximum
                value: sliderCard.value
                stepSize: sliderCard.step
                onMoved: nextValue => sliderCard.userChanged(Number(nextValue.toFixed(2)))
            }
        }
    }
}
