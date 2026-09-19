pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    implicitHeight: column.implicitHeight

    readonly property var indicatorOptions: [
        { id: "line", label: qsTr("Line"), icon: "remove" },
        { id: "dot", label: qsTr("Dot"), icon: "fiber_manual_record" },
        { id: "pill", label: qsTr("Pill"), icon: "pill" }
    ]

    readonly property var dateFormatOptions: [
        { id: "short", label: qsTr("Short"), icon: "calendar_today" },
        { id: "compact", label: qsTr("Compact"), icon: "date_range" },
        { id: "numeric", label: qsTr("Numeric"), icon: "123" }
    ]

    ColumnLayout {
        id: column
        width: parent.width
        spacing: 12

        Text {
            Layout.fillWidth: true
            text: qsTr("Module settings")
            color: RaohaneTheme.text
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }

        Text {
            Layout.fillWidth: true
            text: qsTr("Tune module behavior here so each option has one clear owner.")
            color: RaohaneTheme.textMuted
            font.pixelSize: 9
            wrapMode: Text.WordWrap
        }

        ModuleCard {
            title: qsTr("Workspaces")
            subtitle: qsTr("Control how workspace indicators are represented on the bar.")

            SettingSlider {
                Layout.fillWidth: true
                title: qsTr("Visible workspaces")
                detail: qsTr("Number of workspace buttons shown by the bar")
                value: RaohaneConfig.barWorkspaceCount
                minimum: 2
                maximum: 10
                step: 1
                suffix: ""
                onUserChanged: value => RaohaneConfig.barWorkspaceCount = Math.round(value)
            }

            SettingToggle {
                Layout.fillWidth: true
                title: qsTr("Workspace numbers")
                detail: qsTr("Show workspace numbers inside the indicators")
                checked: RaohaneConfig.barWorkspaceShowNumbers
                onToggled: value => RaohaneConfig.barWorkspaceShowNumbers = value
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Indicator style")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.indicatorOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        option: modelData
                        selected: RaohaneConfig.barWorkspaceIndicatorStyle === String(modelData.id)
                        onChosen: RaohaneConfig.barWorkspaceIndicatorStyle = String(modelData.id)
                    }
                }
            }
        }

        ModuleCard {
            title: qsTr("Clock")
            subtitle: qsTr("Control time and date presentation for the clock module.")

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 700 ? 2 : 1
                columnSpacing: 8
                rowSpacing: 8

                SettingToggle {
                    Layout.fillWidth: true
                    title: qsTr("Show date")
                    detail: qsTr("Display the date alongside the clock")
                    checked: RaohaneConfig.barShowDate
                    onToggled: value => RaohaneConfig.barShowDate = value
                }

                SettingToggle {
                    Layout.fillWidth: true
                    title: qsTr("24-hour clock")
                    detail: qsTr("Use 24-hour time instead of AM/PM")
                    checked: RaohaneConfig.barClock24Hour
                    onToggled: value => RaohaneConfig.barClock24Hour = value
                }

                SettingToggle {
                    Layout.fillWidth: true
                    title: qsTr("Show seconds")
                    detail: qsTr("Include seconds in the clock")
                    checked: RaohaneConfig.barClockShowSeconds
                    onToggled: value => RaohaneConfig.barClockShowSeconds = value
                }
            }

            Text {
                Layout.fillWidth: true
                visible: RaohaneConfig.barShowDate
                text: qsTr("Date format")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                visible: RaohaneConfig.barShowDate
                spacing: 8

                Repeater {
                    model: root.dateFormatOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        option: modelData
                        selected: RaohaneConfig.barClockDateFormat === String(modelData.id)
                        onChosen: RaohaneConfig.barClockDateFormat = String(modelData.id)
                    }
                }
            }
        }
    }

    component ModuleCard: RaohaneSurface {
        id: card

        required property string title
        required property string subtitle
        default property alias content: contentColumn.data

        Layout.fillWidth: true
        implicitHeight: contentColumn.implicitHeight + 24
        surfaceRadius: 14
        raised: false
        showSheen: false
        color: RaohaneTheme.surfaceSubtle
        border.color: RaohaneTheme.borderFaint

        ColumnLayout {
            id: contentColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 9

            Text {
                Layout.fillWidth: true
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
                wrapMode: Text.WordWrap
            }
        }
    }

    component SettingToggle: RaohaneSurface {
        id: toggle

        required property string title
        required property string detail
        property bool checked: false
        signal toggled(bool value)

        Layout.preferredHeight: 54
        surfaceRadius: 11
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 11
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: toggle.title
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: toggle.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            RaohaneSwitch {
                checked: toggle.checked
                onToggled: value => toggle.toggled(value)
            }
        }
    }

    component SettingSlider: RaohaneSurface {
        id: sliderRow

        required property string title
        required property string detail
        property real value: 0
        property real minimum: 0
        property real maximum: 10
        property real step: 1
        property string suffix: ""
        signal userChanged(real value)

        Layout.preferredHeight: 78
        surfaceRadius: 11
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 11
            spacing: 6

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        Layout.fillWidth: true
                        text: sliderRow.title
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: sliderRow.detail
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                }

                Text {
                    text: String(Math.round(sliderRow.value)) + sliderRow.suffix
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }
            }

            RaohaneSlider {
                Layout.fillWidth: true
                from: sliderRow.minimum
                to: sliderRow.maximum
                value: sliderRow.value
                stepSize: sliderRow.step
                onMoved: value => sliderRow.userChanged(value)
            }
        }
    }

    component ChoiceChip: RaohaneSurface {
        id: chip

        required property var option
        property bool selected: false
        signal chosen()

        implicitWidth: 126
        implicitHeight: 34
        surfaceRadius: 10
        raised: false
        showSheen: false
        active: selected
        transparentIdle: !selected
        interactive: true
        hovered: chipMouse.containsMouse
        pressed: chipMouse.pressed
        hoverScale: 1
        pressedScale: 1

        RowLayout {
            anchors.centerIn: parent
            spacing: 6

            RaohaneIcon {
                text: String(chip.option.icon ?? "")
                iconSize: 13
                fill: chip.selected ? 1 : 0
                color: chip.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            Text {
                text: String(chip.option.label ?? "")
                color: chip.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: chip.selected ? Font.DemiBold : Font.Medium
            }
        }

        MouseArea {
            id: chipMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.chosen()
        }
    }
}
