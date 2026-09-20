pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
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

        SectionCard {
            icon: "palette"
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
            icon: "dashboard_customize"
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
            icon: "tune"
            title: qsTr("Behavior")
            subtitle: qsTr("Control visibility, fullscreen interaction and the panel background.")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

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

                ToggleRow {
                    Layout.fillWidth: true
                    icon: "calendar_today"
                    title: qsTr("Show date")
                    detail: qsTr("Display the date alongside the clock")
                    checked: RaohaneConfig.barShowDate
                    onToggled: value => RaohaneConfig.barShowDate = value
                }

            }
        }

        SectionCard {
            icon: "straighten"
            title: qsTr("Geometry")
            subtitle: qsTr("Tune panel dimensions independently from the global interface scale.")

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

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
                    showDivider: false
                    enabled: RaohaneConfig.barShowOnSuper
                    onUserChanged: value => RaohaneConfig.barShowOnSuperDelay = Math.round(value)
                }

            }
        }

        SectionCard {
            icon: "horizontal_rule"
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
            icon: "monitor"
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

        property string icon: "tune"
        property string title: ""
        property string subtitle: ""
        default property alias content: body.data

        Layout.fillWidth: true
        implicitHeight: sectionColumn.implicitHeight + 24
        surfaceRadius: RaohaneTheme.radiusLarge
        raised: false
        showSheen: false
        showInnerRim: false
        idleColor: RaohaneTheme.surfaceSubtle
        border.color: "transparent"

        ColumnLayout {
            id: sectionColumn
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                margins: 12
            }
            spacing: 10

            RowLayout {
                Layout.fillWidth: true
                spacing: 9

                RaohaneIcon {
                    Layout.alignment: Qt.AlignTop
                    Layout.topMargin: 1
                    text: section.icon
                    iconSize: 17
                    fill: 0.8
                    color: RaohaneTheme.accent
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: section.title
                        color: RaohaneTheme.text
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: section.subtitle
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap
                    }
                }
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                spacing: 0
            }
        }
    }

    component ChoiceChip: RaohaneSurface {
        id: chip

        required property var option
        property bool selected: false
        signal chosen()

        implicitHeight: 42
        surfaceRadius: RaohaneTheme.radius
        raised: false
        active: selected
        interactive: true
        hovered: chipMouse.containsMouse
        pressed: chipMouse.pressed
        showSheen: false
        showInnerRim: false
        transparentIdle: !selected
        idleBorderColor: "transparent"
        hoverBorderColor: "transparent"
        activeBorderColor: "transparent"
        activeColor: RaohaneTheme.accentSoft
        hoverColor: RaohaneTheme.surfaceHover

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

        implicitHeight: 54
        surfaceRadius: RaohaneTheme.radius
        raised: false
        interactive: enabled
        hovered: enabled && toggleMouse.containsMouse
        pressed: enabled && toggleMouse.pressed
        showSheen: false
        showInnerRim: false
        transparentIdle: true
        idleBorderColor: "transparent"
        hoverBorderColor: "transparent"
        hoverColor: RaohaneTheme.surfaceHover
        opacity: enabled ? 1 : 0.45

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            spacing: 10

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
                    font.weight: Font.Medium
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

    component BarSlider: Item {
        id: sliderRow

        property string title: ""
        property string detail: ""
        property real value: 0
        property real minimum: 0
        property real maximum: 1
        property real step: 0.1
        property real multiplier: 1
        property string suffix: ""
        property bool showDivider: true
        signal userChanged(real value)

        Layout.fillWidth: true
        Layout.preferredHeight: 64
        opacity: enabled ? 1 : 0.42

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 4
            anchors.rightMargin: 4
            anchors.topMargin: 7
            anchors.bottomMargin: 7
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: sliderRow.title
                        color: RaohaneTheme.text
                        font.pixelSize: 10
                        font.weight: Font.Medium
                    }

                    Text {
                        Layout.fillWidth: true
                        text: sliderRow.detail
                        color: RaohaneTheme.textFaint
                        font.pixelSize: 8
                        elide: Text.ElideRight
                    }
                }

                RaohaneSurface {
                    Layout.preferredWidth: Math.max(48, valueText.implicitWidth + 16)
                    Layout.preferredHeight: 24
                    surfaceRadius: RaohaneTheme.radiusSmall
                    raised: false
                    showSheen: false
                    showInnerRim: false
                    idleColor: RaohaneTheme.surfaceDeep
                    idleBorderColor: "transparent"

                    Text {
                        id: valueText
                        anchors.centerIn: parent
                        text: Math.round(sliderRow.value * sliderRow.multiplier) + sliderRow.suffix
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }
                }
            }

            RaohaneSlider {
                Layout.fillWidth: true
                Layout.preferredHeight: 24
                enabled: sliderRow.enabled
                from: sliderRow.minimum
                to: sliderRow.maximum
                stepSize: sliderRow.step
                value: sliderRow.value
                trackHeight: 8
                handleWidth: 3
                handleHeight: 18
                showHandle: true
                onMoved: value => sliderRow.userChanged(value)
            }
        }

        RaohaneDivider {
            visible: sliderRow.showDivider
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
                leftMargin: 4
                rightMargin: 4
            }
            height: 1
            color: RaohaneTheme.borderFaint
            opacity: 0.55
        }
    }

}
