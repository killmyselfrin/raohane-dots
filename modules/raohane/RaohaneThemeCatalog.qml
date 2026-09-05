pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property string themeQuery: ""
    readonly property var themes: {
        const query = root.themeQuery.trim().toLowerCase()
        if (query.length === 0)
            return RaohaneTheme.presets
        return RaohaneTheme.presets.filter(theme => [theme.name, theme.tone, theme.description, theme.source]
            .some(value => String(value ?? "").toLowerCase().includes(query)))
    }
    readonly property var accents: [
        { id: "theme", name: qsTr("Theme") },
        { id: "ink", name: qsTr("Ink") },
        { id: "sakura", name: qsTr("Sakura") },
        { id: "matcha", name: qsTr("Matcha") },
        { id: "slate", name: qsTr("Slate") },
        { id: "sand", name: qsTr("Sand") },
        { id: "custom", name: qsTr("Custom") }
    ]
    readonly property var palette: [
        "#ef4444", "#f97316", "#eab308", "#84cc16", "#22c55e", "#14b8a6",
        "#06b6d4", "#0ea5e9", "#3b82f6", "#6366f1", "#8b5cf6", "#a855f7",
        "#d946ef", "#ec4899", "#f43f5e", "#9a7077", "#667866", "#657987",
        "#806f59", "#64748b", "#d6d3d1", "#fafafa", "#525252", "#171717"
    ]

    function styleValue(key: string, fallback): var {
        const current = RaohaneConfig.style
        if (!current || !Object.prototype.hasOwnProperty.call(current, key))
            return fallback
        return current[key]
    }

    function setStyle(key: string, value): void {
        const current = RaohaneConfig.style ?? {}
        const next = {}
        for (const name in current)
            next[name] = current[name]
        next[key] = value
        RaohaneConfig.style = RaohaneConfig.sanitizeStyle(next)
    }

    function applyCustomAccent(value: string): void {
        const normalized = String(value ?? "").trim()
        if (!/^#[0-9a-fA-F]{6}$/.test(normalized))
            return
        const current = RaohaneConfig.style ?? {}
        const next = {}
        for (const name in current)
            next[name] = current[name]
        next.customAccent = normalized.toUpperCase()
        next.accentMode = "custom"
        RaohaneConfig.style = RaohaneConfig.sanitizeStyle(next)
    }

    function accentColor(mode: string): color {
        switch (mode) {
        case "ink": return RaohaneTheme.dark ? "#eeeae2" : "#2b2a27"
        case "sakura": return "#9a7077"
        case "matcha": return "#667866"
        case "slate": return "#657987"
        case "sand": return "#806f59"
        case "custom": return String(root.styleValue("customAccent", "#657987"))
        default: return RaohaneTheme.presetAccent
        }
    }

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        flickDeceleration: 2400

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 10
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: qsTr("Theme Library")
                        color: RaohaneTheme.text
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Choose a base mood, then tune the whole shell without changing its layout or behavior.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        wrapMode: Text.WordWrap
                    }
                }

                RaohaneSurface {
                    Layout.preferredWidth: Math.min(220, Math.max(166, root.width * 0.23))
                    Layout.preferredHeight: 30
                    surfaceRadius: 9
                    raised: false
                    showSheen: false
                    active: themeSearch.activeFocus
                    border.color: themeSearch.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 9
                        anchors.rightMargin: 7
                        spacing: 6

                        RaohaneIcon {
                            text: "search"
                            fill: 0
                            color: themeSearch.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textFaint
                            iconSize: 13
                        }

                        TextInput {
                            id: themeSearch
                            Layout.fillWidth: true
                            text: root.themeQuery
                            color: RaohaneTheme.text
                            selectionColor: RaohaneTheme.accentSoft
                            selectedTextColor: RaohaneTheme.text
                            font.pixelSize: 8
                            clip: true
                            onTextEdited: root.themeQuery = text

                            Text {
                                anchors.fill: parent
                                visible: themeSearch.text.length === 0
                                text: qsTr("Search themes")
                                color: RaohaneTheme.textFaint
                                font: themeSearch.font
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        RaohaneIconButton {
                            visible: root.themeQuery.length > 0
                            buttonSize: 20
                            iconSize: 11
                            icon: "close"
                            transparentIdle: true
                            showSheen: false
                            hoverScale: 1
                            pressedScale: 1
                            onClicked: {
                                root.themeQuery = ""
                                themeSearch.text = ""
                                themeSearch.forceActiveFocus()
                            }
                        }
                    }
                }

                RaohaneSurface {
                    Layout.preferredWidth: activeLabel.implicitWidth + 22
                    Layout.preferredHeight: 30
                    surfaceRadius: 9
                    showSheen: false
                    raised: false
                    border.color: RaohaneTheme.borderFaint

                    Row {
                        anchors.centerIn: parent
                        spacing: 5

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 5
                            height: 5
                            radius: 3
                            color: RaohaneTheme.accent
                        }

                        Text {
                            id: activeLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("Active · %1").arg(RaohaneTheme.presetName)
                            color: RaohaneTheme.textMuted
                            font.pixelSize: 8
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                columns: root.width >= 930 ? 4 : root.width >= 650 ? 3 : 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: root.themes

                    delegate: Rectangle {
                        id: themeCard

                        required property var modelData
                        required property int index
                        readonly property bool selected: RaohaneConfig.themePreset === String(modelData.id)
                        readonly property bool hovered: themeMouse.containsMouse

                        Layout.fillWidth: true
                        Layout.preferredHeight: 112
                        radius: 12
                        color: modelData.surfaceRaised
                        border.width: selected ? 2 : 1
                        border.color: selected ? modelData.accent : hovered ? modelData.textMuted : modelData.border
                        clip: true

                        Behavior on border.color {
                            ColorAnimation { duration: RaohaneMotion.micro }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            width: 2
                            height: themeCard.selected ? 34 : themeCard.hovered ? 18 : 8
                            radius: 1
                            color: themeCard.modelData.accent
                            opacity: themeCard.selected ? 1 : themeCard.hovered ? 0.48 : 0

                            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
                        }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 6

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 54
                                radius: 8
                                color: themeCard.modelData.background
                                border.width: 1
                                border.color: themeCard.modelData.border
                                clip: true

                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 6
                                    }
                                    height: 13
                                    radius: 6
                                    color: themeCard.modelData.surfaceRaised
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 6

                                        Repeater {
                                            model: 4

                                            Rectangle {
                                                required property int index
                                                width: index === 1 ? 13 : 4
                                                height: 3
                                                radius: 2
                                                color: index === 1 ? themeCard.modelData.accent : themeCard.modelData.textMuted
                                                opacity: index === 1 ? 1 : 0.46
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        horizontalCenter: parent.horizontalCenter
                                        bottom: parent.bottom
                                        bottomMargin: 6
                                    }
                                    width: parent.width * 0.58
                                    height: 22
                                    radius: 7
                                    color: themeCard.modelData.surface
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            top: parent.top
                                            margins: 5
                                        }
                                        width: parent.width * 0.46
                                        height: 3
                                        radius: 2
                                        color: themeCard.modelData.text
                                        opacity: 0.68
                                    }

                                    Rectangle {
                                        anchors {
                                            left: parent.left
                                            bottom: parent.bottom
                                            leftMargin: 5
                                            bottomMargin: 5
                                        }
                                        width: parent.width * 0.28
                                        height: 2
                                        radius: 1
                                        color: themeCard.modelData.accent
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: themeCard.modelData.name
                                        color: themeCard.modelData.text
                                        font.pixelSize: 9
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: themeCard.modelData.tone
                                        color: themeCard.modelData.textMuted
                                        font.pixelSize: 7
                                        elide: Text.ElideRight
                                    }
                                }

                                RaohaneIcon {
                                    visible: themeCard.selected
                                    text: "check_circle"
                                    iconSize: 16
                                    fill: 1
                                    symbolWeight: 560
                                    color: themeCard.modelData.accent
                                }
                            }
                        }

                        MouseArea {
                            id: themeMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneConfig.themePreset = String(themeCard.modelData.id)
                        }
                    }
                }
            }

            SectionHeader {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                title: qsTr("Style Studio")
                detail: qsTr("Global material, geometry and motion. Every value is saved in native.json.")
                actionText: qsTr("Reset style")
                onAction: RaohaneTheme.resetStyle()
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                columns: root.width >= 800 ? 2 : 1
                columnSpacing: 8
                rowSpacing: 8

                StyleSlider { Layout.fillWidth: true; title: qsTr("Glass opacity"); detail: qsTr("How solid the frosted surfaces feel"); value: Number(root.styleValue("glassOpacity", 1.0)); minimum: 0.55; maximum: 1.0; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("glassOpacity", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Border strength"); detail: qsTr("Hairline contrast around cards and islands"); value: Number(root.styleValue("borderStrength", 1.0)); minimum: 0.45; maximum: 1.5; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("borderStrength", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Corner radius"); detail: qsTr("Global roundness without changing layout"); value: Number(root.styleValue("radiusScale", 1.0)); minimum: 0.7; maximum: 1.4; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("radiusScale", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Interface density"); detail: qsTr("Compact or airy shared spacing"); value: Number(root.styleValue("densityScale", 1.0)); minimum: 0.82; maximum: 1.18; step: 0.03; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("densityScale", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Motion"); detail: qsTr("0 disables shared motion"); value: Number(root.styleValue("motionScale", 1.0)); minimum: 0.0; maximum: 1.4; step: 0.1; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("motionScale", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Accent intensity"); detail: qsTr("Strength of active states and selection"); value: Number(root.styleValue("accentStrength", 1.0)); minimum: 0.45; maximum: 1.5; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("accentStrength", value) }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.preferredHeight: accentBlock.implicitHeight + 20
                surfaceRadius: 11
                showSheen: false
                raised: false
                color: RaohaneTheme.surfaceSubtle
                border.color: RaohaneTheme.borderFaint

                ColumnLayout {
                    id: accentBlock
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 10
                    }
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            text: qsTr("Accent color")
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("one accent across the whole shell")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width >= 760 ? 7 : 4
                        columnSpacing: 6
                        rowSpacing: 6

                        Repeater {
                            model: root.accents

                            delegate: RaohaneSurface {
                                id: accentButton

                                required property var modelData
                                readonly property bool selected: String(root.styleValue("accentMode", "theme")) === String(modelData.id)

                                Layout.fillWidth: true
                                Layout.preferredHeight: 28
                                surfaceRadius: 8
                                showSheen: false
                                raised: false
                                active: selected
                                hovered: accentMouse.containsMouse
                                pressed: accentMouse.pressed
                                interactive: true
                                hoverScale: 1
                                pressedScale: 1

                                Row {
                                    anchors.centerIn: parent
                                    spacing: 5

                                    Rectangle {
                                        width: 9
                                        height: 9
                                        radius: 5
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: root.accentColor(String(accentButton.modelData.id))
                                        border.width: 1
                                        border.color: RaohaneTheme.borderStrong
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: accentButton.modelData.name
                                        color: accentButton.selected ? RaohaneTheme.text : RaohaneTheme.textMuted
                                        font.pixelSize: 8
                                    }
                                }

                                MouseArea {
                                    id: accentMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.setStyle("accentMode", String(accentButton.modelData.id))
                                }
                            }
                        }
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.width >= 850 ? 12 : root.width >= 620 ? 8 : 6
                        columnSpacing: 6
                        rowSpacing: 6

                        Repeater {
                            model: root.palette

                            delegate: Rectangle {
                                id: swatch

                                required property var modelData
                                readonly property bool selected: String(root.styleValue("accentMode", "theme")) === "custom"
                                    && String(root.styleValue("customAccent", "#657987")).toLowerCase() === String(modelData).toLowerCase()

                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                radius: 6
                                color: String(modelData)
                                border.width: selected ? 2 : 1
                                border.color: selected ? RaohaneTheme.text : RaohaneTheme.borderStrong

                                Rectangle {
                                    visible: swatch.selected
                                    anchors.centerIn: parent
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: RaohaneTheme.dark ? "#101010" : "#f8f7f4"
                                    opacity: 0.78
                                }

                                MouseArea {
                                    id: swatchMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.applyCustomAccent(String(swatch.modelData))
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 7

                        Rectangle {
                            width: 28
                            height: 28
                            radius: 7
                            color: String(root.styleValue("customAccent", "#657987"))
                            border.width: 1
                            border.color: RaohaneTheme.borderStrong
                        }

                        RaohaneSurface {
                            Layout.preferredWidth: 146
                            Layout.preferredHeight: 30
                            surfaceRadius: 8
                            showSheen: false
                            raised: false
                            active: customHex.activeFocus
                            border.color: customHex.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

                            TextInput {
                                id: customHex
                                anchors.fill: parent
                                anchors.leftMargin: 9
                                anchors.rightMargin: 9
                                verticalAlignment: TextInput.AlignVCenter
                                text: String(root.styleValue("customAccent", "#657987")).toUpperCase()
                                color: RaohaneTheme.text
                                selectionColor: RaohaneTheme.accentSoft
                                font.pixelSize: 8
                                maximumLength: 7
                                validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
                                onAccepted: root.applyCustomAccent(text)
                                onEditingFinished: root.applyCustomAccent(text)
                            }
                        }

                        Text {
                            text: qsTr("Press Enter to apply any #RRGGBB color")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }

                        Item { Layout.fillWidth: true }
                    }

                    StyleToggle {
                        Layout.fillWidth: true
                        title: qsTr("Glass highlight")
                        detail: qsTr("Keep the subtle one-pixel sheen on shared surfaces")
                        checked: Boolean(root.styleValue("sheenEnabled", true))
                        onUserToggled: value => root.setStyle("sheenEnabled", value)
                    }
                }
            }

            SectionHeader {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                title: qsTr("Advanced Surfaces")
                detail: qsTr("Tune individual shell surfaces while they continue inheriting the active theme and accent.")
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                columns: root.width >= 800 ? 2 : 1
                columnSpacing: 8
                rowSpacing: 8

                StyleSlider { Layout.fillWidth: true; title: qsTr("Bar pod size"); detail: qsTr("Height of the left and right floating bar capsules"); value: Number(root.styleValue("barScale", 1.0)); minimum: 0.85; maximum: 1.15; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("barScale", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Dock height"); detail: qsTr("Overall dock surface height"); value: RaohaneConfig.dockHeight; minimum: 48; maximum: 96; step: 2; multiplier: 1; suffix: " px"; onUserChanged: value => RaohaneConfig.dockHeight = Math.round(value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Dock icon size"); detail: qsTr("Application and control icon size"); value: RaohaneConfig.dockIconSize; minimum: 26; maximum: 64; step: 2; multiplier: 1; suffix: " px"; onUserChanged: value => RaohaneConfig.dockIconSize = Math.round(value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Dock hover lift"); detail: qsTr("How much dock items grow on hover"); value: Number(root.styleValue("dockHoverScale", 1.04)); minimum: 1.0; maximum: 1.12; step: 0.01; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("dockHoverScale", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Context Island size"); detail: qsTr("Independent scale for the center island"); value: Number(root.styleValue("contextIslandScale", 1.0)); minimum: 0.8; maximum: 1.25; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("contextIslandScale", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Notification scale"); detail: qsTr("Overall notification card density"); value: Number(root.styleValue("notificationScale", 1.0)); minimum: 0.85; maximum: 1.15; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: value => root.setStyle("notificationScale", value) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Notification body lines"); detail: qsTr("Maximum body lines before text is elided"); value: Number(root.styleValue("notificationBodyLines", 4)); minimum: 1; maximum: 6; step: 1; multiplier: 1; suffix: ""; onUserChanged: value => root.setStyle("notificationBodyLines", Math.round(value)) }
            }

            RaohaneSurface {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.preferredHeight: advancedToggles.implicitHeight + 18
                surfaceRadius: 11
                showSheen: false
                raised: false
                color: RaohaneTheme.surfaceSubtle
                border.color: RaohaneTheme.borderFaint

                ColumnLayout {
                    id: advancedToggles
                    anchors {
                        left: parent.left
                        right: parent.right
                        top: parent.top
                        margins: 9
                    }
                    spacing: 6

                    StyleToggle { Layout.fillWidth: true; title: qsTr("Context detail"); detail: qsTr("Show the second line inside Context Island"); checked: Boolean(root.styleValue("contextIslandDetail", true)); onUserToggled: value => root.setStyle("contextIslandDetail", value) }
                    StyleToggle { Layout.fillWidth: true; title: qsTr("Context indicators"); detail: qsTr("Show the three quiet state dots on the right"); checked: Boolean(root.styleValue("contextIslandIndicators", true)); onUserToggled: value => root.setStyle("contextIslandIndicators", value) }
                    StyleToggle { Layout.fillWidth: true; title: qsTr("Compact notifications"); detail: qsTr("Use tighter notification spacing and fewer actions"); checked: Boolean(root.styleValue("notificationCompact", false)); onUserToggled: value => root.setStyle("notificationCompact", value) }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 12
                text: qsTr("Theme, Style Studio, custom accent and Advanced Surfaces are saved in ~/.config/raohane/native.json.")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }
        }
    }

    component SectionHeader: RowLayout {
        id: header

        required property string title
        required property string detail
        property string actionText: ""
        signal action()

        spacing: 9

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Text {
                text: header.title
                color: RaohaneTheme.text
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Text {
                Layout.fillWidth: true
                text: header.detail
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }
        }

        RaohaneSurface {
            id: actionButton

            visible: header.actionText !== ""
            implicitWidth: actionLabel.implicitWidth + 20
            implicitHeight: 30
            surfaceRadius: 9
            showSheen: false
            raised: false
            transparentIdle: true
            hovered: actionMouse.containsMouse
            pressed: actionMouse.pressed
            interactive: true
            hoverScale: 1
            pressedScale: 1

            Text {
                id: actionLabel
                anchors.centerIn: parent
                text: header.actionText
                color: actionButton.hovered ? RaohaneTheme.text : RaohaneTheme.textMuted
                font.pixelSize: 8
                font.weight: Font.DemiBold
            }

            MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: header.action()
            }
        }
    }

    component StyleToggle: RaohaneSurface {
        id: toggle

        required property string title
        required property string detail
        property bool checked: false
        signal userToggled(bool value)

        Layout.preferredHeight: 46
        surfaceRadius: 9
        raised: false
        showSheen: false
        border.color: RaohaneTheme.borderFaint

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 9
            spacing: 9

            Rectangle {
                Layout.preferredWidth: 2
                Layout.preferredHeight: toggle.checked ? 18 : 8
                radius: 1
                color: RaohaneTheme.accent
                opacity: toggle.checked ? 0.9 : 0.16
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: toggle.title
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: toggle.detail
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            RaohaneSwitch {
                checked: toggle.checked
                onToggled: value => toggle.userToggled(value)
            }
        }
    }

    component StyleSlider: RaohaneSurface {
        id: control

        required property string title
        required property string detail
        property real value: 0
        property real minimum: 0
        property real maximum: 1
        property real step: 0.05
        property real multiplier: 1
        property string suffix: ""
        signal userChanged(real nextValue)

        readonly property string shownValue: String(Math.round(value * multiplier)) + suffix

        Layout.preferredHeight: 68
        surfaceRadius: 11
        showSheen: false
        raised: false
        color: RaohaneTheme.surfaceSubtle
        border.color: studioSlider.hovered || studioSlider.activeFocus ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                spacing: 7

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: control.title
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        Layout.fillWidth: true
                        text: control.detail
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 7
                        elide: Text.ElideRight
                    }
                }

                RaohaneSurface {
                    implicitWidth: styleValueLabel.implicitWidth + 14
                    implicitHeight: 20
                    surfaceRadius: 7
                    raised: false
                    showSheen: false
                    hovered: studioSlider.hovered || studioSlider.activeFocus
                    border.color: RaohaneTheme.borderFaint

                    Text {
                        id: styleValueLabel
                        anchors.centerIn: parent
                        text: control.shownValue
                        color: studioSlider.hovered || studioSlider.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold

                        Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                    }
                }
            }

            RaohaneSlider {
                id: studioSlider
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                from: control.minimum
                to: control.maximum
                value: control.value
                stepSize: control.step
                onMoved: nextValue => control.userChanged(Number(nextValue.toFixed(3)))
            }
        }
    }
}
