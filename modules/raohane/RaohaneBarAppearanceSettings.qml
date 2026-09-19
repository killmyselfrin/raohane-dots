pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as Controls
import Quickshell

import qs.modules.raohane.config

Item {
    id: root

    implicitHeight: column.implicitHeight

    readonly property var presets: [
        {
            id: "classic", label: qsTr("Classic"), detail: qsTr("Edge-hugging grouped bar"),
            surface: "hug", group: "pills", height: 44, radius: 14,
            opacity: 0.96, margin: 0, spacing: 5, padding: 8, background: true, shadow: false
        },
        {
            id: "floating", label: qsTr("Float"), detail: qsTr("Floating capsules with soft depth"),
            surface: "float", group: "pills", height: 44, radius: 18,
            opacity: 0.94, margin: 16, spacing: 5, padding: 8, background: true, shadow: true
        },
        {
            id: "islands", label: qsTr("Islands"), detail: qsTr("Separated functional groups"),
            surface: "islands", group: "separated", height: 44, radius: 16,
            opacity: 0.94, margin: 14, spacing: 7, padding: 6, background: true, shadow: true
        },
        {
            id: "compact", label: qsTr("Compact"), detail: qsTr("Dense segmented layout"),
            surface: "float", group: "segmented", height: 38, radius: 10,
            opacity: 0.96, margin: 10, spacing: 1, padding: 5, background: true, shadow: false
        },
        {
            id: "panel", label: qsTr("Panel"), detail: qsTr("Full-width continuous surface"),
            surface: "panel", group: "transparent", height: 42, radius: 0,
            opacity: 0.98, margin: 0, spacing: 5, padding: 8, background: true, shadow: false
        }
    ]

    readonly property var positionOptions: [
        { id: "top", label: qsTr("Top"), icon: "arrow_upward" },
        { id: "left", label: qsTr("Left"), icon: "arrow_back" },
        { id: "bottom", label: qsTr("Bottom"), icon: "arrow_downward" },
        { id: "right", label: qsTr("Right"), icon: "arrow_forward" }
    ]

    readonly property var surfaceOptions: [
        { id: "hug", label: qsTr("Hug"), icon: "line_curve" },
        { id: "float", label: qsTr("Float"), icon: "view_day" },
        { id: "islands", label: qsTr("Islands"), icon: "view_week" },
        { id: "panel", label: qsTr("Panel"), icon: "toolbar" }
    ]

    readonly property var groupOptions: [
        { id: "transparent", label: qsTr("Transparent"), icon: "opacity" },
        { id: "pills", label: qsTr("Pills"), icon: "pill" },
        { id: "separated", label: qsTr("Separated"), icon: "view_column_2" },
        { id: "segmented", label: qsTr("Segmented"), icon: "table_rows" }
    ]

    readonly property var dividerOptions: [
        { id: "line", label: qsTr("Line"), icon: "remove" },
        { id: "dot", label: qsTr("Dot"), icon: "fiber_manual_record" },
        { id: "space", label: qsTr("Space"), icon: "space_bar" }
    ]

    readonly property var workspaceStyleOptions: [
        { id: "numbers", label: qsTr("Numbers"), icon: "123" },
        { id: "dots", label: qsTr("Dots"), icon: "more_horiz" },
        { id: "minimal", label: qsTr("Minimal"), icon: "drag_handle" }
    ]

    readonly property var dateFormatOptions: [
        { id: "short", label: qsTr("Weekday"), detail: qsTr("Mon 20 Sep"), icon: "calendar_view_week" },
        { id: "compact", label: qsTr("Compact"), detail: qsTr("20 Sep"), icon: "calendar_view_day" },
        { id: "numeric", label: qsTr("Numeric"), detail: qsTr("20.09"), icon: "calendar_month" }
    ]

    function positionId(): string {
        if (RaohaneConfig.barVertical)
            return RaohaneConfig.barRight ? "right" : "left"
        return RaohaneConfig.barBottom ? "bottom" : "top"
    }

    function setPosition(position: string): void {
        const value = String(position)
        if (value === "left" || value === "right") {
            RaohaneConfig.barVertical = true
            RaohaneConfig.barRight = value === "right"
            RaohaneConfig.barBottom = false
        } else {
            RaohaneConfig.barVertical = false
            RaohaneConfig.barRight = false
            RaohaneConfig.barBottom = value === "bottom"
        }
    }

    function applyPreset(preset): void {
        RaohaneConfig.barStylePreset = String(preset.id)
        RaohaneConfig.barSurfaceStyle = String(preset.surface)
        RaohaneConfig.barGroupStyle = String(preset.group)
        RaohaneConfig.barHeight = Number(preset.height)
        RaohaneConfig.barRadius = Number(preset.radius)
        RaohaneConfig.barOpacity = Number(preset.opacity)
        RaohaneConfig.barEdgeMargin = Number(preset.margin)
        RaohaneConfig.barModuleSpacing = Number(preset.spacing)
        RaohaneConfig.barHorizontalPadding = Number(preset.padding)
        RaohaneConfig.barShowBackground = Boolean(preset.background)
        RaohaneConfig.barShadow = Boolean(preset.shadow)
    }

    function markCustom(): void {
        RaohaneConfig.barStylePreset = "custom"
    }

    function monitorEnabled(name: string): bool {
        const configured = RaohaneConfig.barScreenList
        return !configured || configured.length === 0 || configured.includes(name)
    }

    function toggleMonitor(name: string): void {
        const screens = Quickshell.screens
        const allNames = screens.map(screen => String(screen.name))
        let next = (!RaohaneConfig.barScreenList || RaohaneConfig.barScreenList.length === 0)
            ? allNames.slice()
            : RaohaneConfig.barScreenList.slice()

        if (next.includes(name))
            next = next.filter(item => item !== name)
        else
            next.push(name)

        RaohaneConfig.barScreenList = next.length === allNames.length ? [] : next
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
                    text: qsTr("Bar configuration")
                    color: RaohaneTheme.text
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: qsTr("Configure the Raohane bar like a desktop panel: position, surface, groups, behavior, displays and geometry.")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 9
                    wrapMode: Text.WordWrap
                }
            }

            Text {
                text: RaohaneConfig.barStylePreset === "custom" ? qsTr("Custom") : qsTr("Preset")
                color: RaohaneTheme.textFaint
                font.pixelSize: 9
            }
        }

        SectionCard {
            title: qsTr("Presets")
            subtitle: qsTr("Start from a complete panel layout, then customize any option.")

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.presets

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 142
                        option: modelData
                        selected: RaohaneConfig.barStylePreset === String(modelData.id)
                        onChosen: root.applyPreset(modelData)
                    }
                }
            }
        }

        SectionCard {
            title: qsTr("Position & surface")
            subtitle: qsTr("Choose where the bar sits and how its surfaces are grouped.")

            Text {
                Layout.fillWidth: true
                text: qsTr("Position")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.positionOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 132
                        option: modelData
                        selected: root.positionId() === String(modelData.id)
                        onChosen: {
                            root.markCustom()
                            root.setPosition(String(modelData.id))
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: qsTr("Bar style")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.surfaceOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 132
                        option: modelData
                        selected: RaohaneConfig.barSurfaceStyle === String(modelData.id)
                        onChosen: {
                            root.markCustom()
                            RaohaneConfig.barSurfaceStyle = String(modelData.id)
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: qsTr("Group style")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.groupOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 132
                        option: modelData
                        selected: RaohaneConfig.barGroupStyle === String(modelData.id)
                        onChosen: {
                            root.markCustom()
                            RaohaneConfig.barGroupStyle = String(modelData.id)
                        }
                    }
                }
            }
        }

        SectionCard {
            title: qsTr("Behavior")
            subtitle: qsTr("Control visibility, fullscreen interaction and the panel background.")

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 720 ? 2 : 1
                columnSpacing: 8
                rowSpacing: 8

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "variable_insert"
                    title: qsTr("Show background")
                    detail: qsTr("Draw panel and group surfaces")
                    checked: RaohaneConfig.barShowBackground
                    onToggled: value => {
                        root.markCustom()
                        RaohaneConfig.barShowBackground = value
                    }
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "filter_vintage"
                    title: qsTr("Surface depth")
                    detail: qsTr("Use the raised surface treatment")
                    checked: RaohaneConfig.barShadow
                    onToggled: value => {
                        root.markCustom()
                        RaohaneConfig.barShadow = value
                    }
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "preview_off"
                    title: qsTr("Auto-hide")
                    detail: qsTr("Hide the bar until interaction requires it")
                    checked: RaohaneConfig.barAutoHide
                    onToggled: value => RaohaneConfig.barAutoHide = value
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "open_in_full"
                    title: qsTr("Push windows")
                    detail: qsTr("Reserve space while the auto-hidden bar is visible")
                    checked: RaohaneConfig.barAutoHidePushWindows
                    enabled: RaohaneConfig.barAutoHide
                    onToggled: value => RaohaneConfig.barAutoHidePushWindows = value
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "keyboard_command_key"
                    title: qsTr("Reveal on Super")
                    detail: qsTr("Temporarily reveal the bar while Super is held")
                    checked: RaohaneConfig.barShowOnSuper
                    onToggled: value => RaohaneConfig.barShowOnSuper = value
                }

            }
        }

        SectionCard {
            title: qsTr("Workspaces")
            subtitle: qsTr("Control how workspace navigation is represented in the bar.")

            BarSlider {
                Layout.fillWidth: true
                title: qsTr("Visible workspaces")
                detail: qsTr("Number of workspace buttons shown around the active workspace group")
                value: RaohaneConfig.barWorkspaceCount
                minimum: 2
                maximum: 10
                step: 1
                suffix: ""
                onUserChanged: value => RaohaneConfig.barWorkspaceCount = Math.round(value)
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
                    model: root.workspaceStyleOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 142
                        option: modelData
                        selected: RaohaneConfig.barWorkspaceStyle === String(modelData.id)
                        onChosen: RaohaneConfig.barWorkspaceStyle = String(modelData.id)
                    }
                }
            }
        }

        SectionCard {
            title: qsTr("Clock")
            subtitle: qsTr("Time and date formatting for the bar clock module.")

            GridLayout {
                Layout.fillWidth: true
                columns: width >= 720 ? 2 : 1
                columnSpacing: 8
                rowSpacing: 8

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "schedule"
                    title: qsTr("24-hour time")
                    detail: qsTr("Use 24-hour time instead of AM/PM")
                    checked: RaohaneConfig.barClock24Hour
                    onToggled: value => RaohaneConfig.barClock24Hour = value
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "timer"
                    title: qsTr("Show seconds")
                    detail: qsTr("Update the clock every second")
                    checked: RaohaneConfig.barClockShowSeconds
                    onToggled: value => RaohaneConfig.barClockShowSeconds = value
                }

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "calendar_today"
                    title: qsTr("Show date")
                    detail: qsTr("Display the date alongside the clock")
                    checked: RaohaneConfig.barShowDate
                    onToggled: value => RaohaneConfig.barShowDate = value
                }
            }

            Text {
                Layout.fillWidth: true
                text: qsTr("Date format")
                color: RaohaneTheme.textMuted
                font.pixelSize: 9
                font.weight: Font.DemiBold
                opacity: RaohaneConfig.barShowDate ? 1 : 0.45
            }

            Flow {
                Layout.fillWidth: true
                spacing: 8
                opacity: RaohaneConfig.barShowDate ? 1 : 0.45
                enabled: RaohaneConfig.barShowDate

                Repeater {
                    model: root.dateFormatOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 150
                        option: modelData
                        selected: RaohaneConfig.barClockDateFormat === String(modelData.id)
                        onChosen: RaohaneConfig.barClockDateFormat = String(modelData.id)
                    }
                }
            }
        }

        SectionCard {
            title: qsTr("Geometry")
            subtitle: qsTr("Tune panel dimensions independently from the global interface scale.")

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
                    detail: qsTr("Roundness of bar surfaces")
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
                    detail: qsTr("Transparency of panel surfaces")
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
                    title: qsTr("Outer gap")
                    detail: qsTr("Distance between a floating bar and the screen edge")
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
                    detail: qsTr("Gap between modules inside a group")
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
                    title: qsTr("Group padding")
                    detail: qsTr("Space inside grouped bar surfaces")
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

                BarSlider {
                    Layout.fillWidth: true
                    title: qsTr("Super reveal delay")
                    detail: qsTr("Delay before Super reveals the bar")
                    value: RaohaneConfig.barShowOnSuperDelay
                    minimum: 0
                    maximum: 1000
                    step: 20
                    suffix: " ms"
                    enabled: RaohaneConfig.barShowOnSuper
                    onUserChanged: value => RaohaneConfig.barShowOnSuperDelay = Math.round(value)
                }

            }
        }

        SectionCard {
            title: qsTr("Divider")
            subtitle: qsTr("Choose how separator modules look inside the panel.")

            Flow {
                Layout.fillWidth: true
                spacing: 8

                Repeater {
                    model: root.dividerOptions

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 132
                        option: modelData
                        selected: RaohaneConfig.barDividerStyle === String(modelData.id)
                        onChosen: RaohaneConfig.barDividerStyle = String(modelData.id)
                    }
                }
            }

            BarSlider {
                Layout.fillWidth: true
                visible: RaohaneConfig.barDividerStyle === "space"
                title: qsTr("Space width")
                detail: qsTr("Width of an invisible spacing divider")
                value: RaohaneConfig.barDividerSpacing
                minimum: 4
                maximum: 48
                step: 1
                suffix: " px"
                onUserChanged: value => RaohaneConfig.barDividerSpacing = Math.round(value)
            }
        }

        SectionCard {
            title: qsTr("Displays")
            subtitle: qsTr("Choose which monitors show the bar. No selection means all displays.")

            Flow {
                Layout.fillWidth: true
                spacing: 8

                ChoiceChip {
                    width: 142
                    option: ({ id: "all", label: qsTr("All displays"), icon: "tv_displays" })
                    selected: !RaohaneConfig.barScreenList || RaohaneConfig.barScreenList.length === 0
                    onChosen: RaohaneConfig.barScreenList = []
                }

                Repeater {
                    model: Quickshell.screens

                    delegate: ChoiceChip {
                        required property var modelData
                        width: 142
                        option: ({
                            id: String(modelData.name),
                            label: String(modelData.name),
                            icon: "monitor"
                        })
                        selected: root.monitorEnabled(String(modelData.name))
                        onChosen: root.toggleMonitor(String(modelData.name))
                    }
                }
            }
        }
    }

    component SectionCard: RaohaneSurface {
        id: section

        property string title: ""
        property string subtitle: ""
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: sectionColumn.implicitHeight + 24
        surfaceRadius: RaohaneTheme.radiusLarge
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        ColumnLayout {
            id: sectionColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 9

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    text: section.title
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: section.subtitle
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    wrapMode: Text.WordWrap
                }
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                spacing: 8
            }
        }
    }

    component ChoiceChip: RaohaneSurface {
        id: chip

        required property var option
        property bool selected: false
        signal chosen()

        implicitHeight: 50
        surfaceRadius: 12
        raised: false
        active: selected
        interactive: true
        hovered: chipMouse.containsMouse
        pressed: chipMouse.pressed
        showSheen: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 10
            spacing: 7

            RaohaneIcon {
                text: String(chip.option.icon ?? "tune")
                iconSize: 15
                fill: chip.selected ? 1 : 0
                color: chip.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: String(chip.option.label ?? chip.option.id ?? "")
                    color: chip.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                    font.pixelSize: 9
                    font.weight: chip.selected ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    visible: String(chip.option.detail ?? "").length > 0
                    Layout.fillWidth: true
                    text: String(chip.option.detail ?? "")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            RaohaneIcon {
                visible: chip.selected
                text: "check"
                iconSize: 13
                color: RaohaneTheme.accent
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

    component ToggleRow: RaohaneSurface {
        id: toggle

        property string icon: "toggle_on"
        property string title: ""
        property string detail: ""
        property bool checked: false
        signal toggled(bool value)

        implicitHeight: 58
        surfaceRadius: 12
        raised: false
        interactive: enabled
        hovered: enabled && toggleMouse.containsMouse
        pressed: enabled && toggleMouse.pressed
        showSheen: false
        opacity: enabled ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 8

            RaohaneIcon {
                text: toggle.icon
                iconSize: 16
                color: toggle.checked ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    text: toggle.title
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                Text {
                    Layout.fillWidth: true
                    text: toggle.detail
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            RaohaneSwitch {
                checked: toggle.checked
                enabled: toggle.enabled
                onToggled: toggle.toggled(checked)
            }
        }

        MouseArea {
            id: toggleMouse
            anchors.fill: parent
            enabled: toggle.enabled
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: toggle.toggled(!toggle.checked)
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
        opacity: enabled ? 1 : 0.45

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
                enabled: sliderCard.enabled
                from: sliderCard.minimum
                to: sliderCard.maximum
                stepSize: sliderCard.step
                value: sliderCard.value
                onMoved: sliderCard.userChanged(value)
            }
        }
    }
}
