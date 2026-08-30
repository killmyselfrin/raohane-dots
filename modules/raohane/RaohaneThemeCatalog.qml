pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    readonly property var themes: RaohaneTheme.presets
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
        contentHeight: content.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: content
            width: parent.width
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.topMargin: 12
                spacing: 12

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: qsTr("Theme Library")
                        color: RaohaneTheme.text
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                    }

                    Text {
                        Layout.fillWidth: true
                        text: qsTr("Choose the base mood first. Raohane keeps the same layout and behavior across every preset.")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 9
                        wrapMode: Text.WordWrap
                    }
                }

                Rectangle {
                    Layout.preferredWidth: activeLabel.implicitWidth + 24
                    Layout.preferredHeight: 30
                    radius: 15
                    color: RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.border

                    Text {
                        id: activeLabel
                        anchors.centerIn: parent
                        text: qsTr("Active · %1").arg(RaohaneTheme.presetName)
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.Medium
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                columns: root.width >= 930 ? 4 : root.width >= 650 ? 3 : 2
                columnSpacing: 9
                rowSpacing: 9

                Repeater {
                    model: root.themes

                    delegate: Rectangle {
                        id: themeCard
                        required property var modelData
                        required property int index

                        readonly property bool selected: RaohaneConfig.themePreset === String(modelData.id)

                        Layout.fillWidth: true
                        Layout.preferredHeight: 126
                        radius: 18
                        color: modelData.surfaceRaised
                        border.width: selected ? 2 : 1
                        border.color: selected ? root.accentColor("theme") : modelData.border
                        clip: true

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 7

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 62
                                radius: 13
                                color: themeCard.modelData.background
                                border.width: 1
                                border.color: themeCard.modelData.border

                                Rectangle {
                                    anchors {
                                        top: parent.top
                                        left: parent.left
                                        right: parent.right
                                        margins: 7
                                    }
                                    height: 15
                                    radius: 8
                                    color: themeCard.modelData.surfaceRaised
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7
                                        Repeater {
                                            model: 4
                                            Rectangle {
                                                required property int index
                                                width: index === 1 ? 14 : 5
                                                height: 4
                                                radius: 2
                                                color: index === 1 ? themeCard.modelData.accent : themeCard.modelData.textMuted
                                                opacity: index === 1 ? 1 : 0.5
                                            }
                                        }
                                    }
                                }

                                Rectangle {
                                    anchors {
                                        horizontalCenter: parent.horizontalCenter
                                        bottom: parent.bottom
                                        bottomMargin: 7
                                    }
                                    width: parent.width * 0.58
                                    height: 25
                                    radius: 9
                                    color: themeCard.modelData.surface
                                    border.width: 1
                                    border.color: themeCard.modelData.border

                                    Rectangle {
                                        anchors { left: parent.left; top: parent.top; margins: 6 }
                                        width: parent.width * 0.46
                                        height: 4
                                        radius: 2
                                        color: themeCard.modelData.text
                                        opacity: 0.7
                                    }
                                    Rectangle {
                                        anchors { left: parent.left; bottom: parent.bottom; leftMargin: 6; bottomMargin: 6 }
                                        width: parent.width * 0.28
                                        height: 3
                                        radius: 2
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
                                    Text { Layout.fillWidth: true; text: themeCard.modelData.name; color: themeCard.modelData.text; font.pixelSize: 10; font.weight: Font.DemiBold; elide: Text.ElideRight }
                                    Text { Layout.fillWidth: true; text: themeCard.modelData.tone; color: themeCard.modelData.textMuted; font.pixelSize: 7; elide: Text.ElideRight }
                                }
                                Text { text: themeCard.selected ? "✓" : ""; color: themeCard.modelData.accent; font.pixelSize: 12; font.weight: Font.Bold }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: RaohaneConfig.themePreset = String(themeCard.modelData.id)
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.preferredHeight: 1
                color: RaohaneTheme.borderFaint
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                spacing: 10

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text { text: qsTr("Style Studio"); color: RaohaneTheme.text; font.pixelSize: 16; font.weight: Font.DemiBold }
                    Text { Layout.fillWidth: true; text: qsTr("Fine-tune the current theme live. Every change is saved and shared surfaces update together."); color: RaohaneTheme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
                }

                Rectangle {
                    implicitWidth: resetLabel.implicitWidth + 22
                    implicitHeight: 30
                    radius: 12
                    color: resetMouse.containsMouse ? RaohaneTheme.surfaceHover : RaohaneTheme.surfaceSubtle
                    border.width: 1
                    border.color: RaohaneTheme.border
                    Text { id: resetLabel; anchors.centerIn: parent; text: qsTr("Reset style"); color: RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: Font.DemiBold }
                    MouseArea { id: resetMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: RaohaneTheme.resetStyle() }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                columns: root.width >= 800 ? 2 : 1
                columnSpacing: 10
                rowSpacing: 10

                StyleSlider { Layout.fillWidth: true; title: qsTr("Glass opacity"); detail: qsTr("How solid the frosted surfaces feel"); value: Number(root.styleValue("glassOpacity", 1.0)); minimum: 0.55; maximum: 1.0; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => root.setStyle("glassOpacity", nextValue) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Border strength"); detail: qsTr("Hairline contrast around cards and islands"); value: Number(root.styleValue("borderStrength", 1.0)); minimum: 0.45; maximum: 1.5; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => root.setStyle("borderStrength", nextValue) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Corner radius"); detail: qsTr("Global roundness without changing layout"); value: Number(root.styleValue("radiusScale", 1.0)); minimum: 0.7; maximum: 1.4; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => root.setStyle("radiusScale", nextValue) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Interface density"); detail: qsTr("Compact or airy shared spacing and shell heights"); value: Number(root.styleValue("densityScale", 1.0)); minimum: 0.82; maximum: 1.18; step: 0.03; multiplier: 100; suffix: "%"; onUserChanged: nextValue => root.setStyle("densityScale", nextValue) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Motion"); detail: qsTr("Animation speed and presence; 0 disables shared motion"); value: Number(root.styleValue("motionScale", 1.0)); minimum: 0.0; maximum: 1.4; step: 0.1; multiplier: 100; suffix: "%"; onUserChanged: nextValue => root.setStyle("motionScale", nextValue) }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Accent intensity"); detail: qsTr("Strength of active states, pills and selected borders"); value: Number(root.styleValue("accentStrength", 1.0)); minimum: 0.45; maximum: 1.5; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => root.setStyle("accentStrength", nextValue) }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.preferredHeight: accentBlock.implicitHeight + 24
                radius: 18
                color: RaohaneTheme.surfaceSubtle
                border.width: 1
                border.color: RaohaneTheme.border

                ColumnLayout {
                    id: accentBlock
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 12 }
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Accent"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Text { text: qsTr("one accent across the whole shell"); color: RaohaneTheme.textFaint; font.pixelSize: 8 }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 7
                        Repeater {
                            model: root.accents
                            delegate: Rectangle {
                                id: accentButton
                                required property var modelData
                                readonly property bool selected: String(root.styleValue("accentMode", "theme")) === String(modelData.id)
                                width: accentRow.implicitWidth + 18
                                height: 30
                                radius: 12
                                color: selected ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceRaised
                                border.width: 1
                                border.color: selected ? RaohaneTheme.accentBorder : RaohaneTheme.border
                                Row {
                                    id: accentRow
                                    anchors.centerIn: parent
                                    spacing: 6
                                    Rectangle { width: 10; height: 10; radius: 5; anchors.verticalCenter: parent.verticalCenter; color: root.accentColor(String(accentButton.modelData.id)); border.width: 1; border.color: RaohaneTheme.borderStrong }
                                    Text { anchors.verticalCenter: parent.verticalCenter; text: accentButton.modelData.name; color: accentButton.selected ? RaohaneTheme.text : RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: accentButton.selected ? Font.DemiBold : Font.Normal }
                                }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setStyle("accentMode", String(accentButton.modelData.id)) }
                            }
                        }
                    }

                    Text {
                        text: qsTr("Custom color")
                        color: RaohaneTheme.textMuted
                        font.pixelSize: 8
                        font.weight: Font.DemiBold
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 7

                        Repeater {
                            model: root.palette
                            delegate: Rectangle {
                                id: swatch
                                required property var modelData
                                readonly property bool selected: String(root.styleValue("accentMode", "theme")) === "custom"
                                    && String(root.styleValue("customAccent", "#657987")).toLowerCase() === String(modelData).toLowerCase()
                                width: 26
                                height: 26
                                radius: 8
                                color: String(modelData)
                                border.width: selected ? 3 : 1
                                border.color: selected ? RaohaneTheme.text : RaohaneTheme.borderStrong
                                scale: swatchMouse.containsMouse ? 1.08 : 1.0
                                Behavior on scale { NumberAnimation { duration: RaohaneTheme.animationFast } }
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
                        spacing: 8

                        Rectangle {
                            width: 30
                            height: 30
                            radius: 10
                            color: String(root.styleValue("customAccent", "#657987"))
                            border.width: 1
                            border.color: RaohaneTheme.borderStrong
                        }

                        Rectangle {
                            Layout.preferredWidth: 150
                            Layout.preferredHeight: 32
                            radius: 10
                            color: RaohaneTheme.surfaceRaised
                            border.width: 1
                            border.color: customHex.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.border

                            TextInput {
                                id: customHex
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                verticalAlignment: TextInput.AlignVCenter
                                text: String(root.styleValue("customAccent", "#657987")).toUpperCase()
                                color: RaohaneTheme.text
                                selectionColor: RaohaneTheme.accentSoft
                                selectedTextColor: RaohaneTheme.text
                                font.pixelSize: 9
                                font.capitalization: Font.AllUppercase
                                maximumLength: 7
                                validator: RegularExpressionValidator { regularExpression: /^#[0-9A-Fa-f]{6}$/ }
                                onAccepted: root.applyCustomAccent(text)
                                onEditingFinished: root.applyCustomAccent(text)
                            }
                        }

                        Rectangle {
                            implicitWidth: applyHexLabel.implicitWidth + 20
                            implicitHeight: 32
                            radius: 10
                            color: applyHexMouse.containsMouse ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceRaised
                            border.width: 1
                            border.color: applyHexMouse.containsMouse ? RaohaneTheme.accentBorder : RaohaneTheme.border
                            Text { id: applyHexLabel; anchors.centerIn: parent; text: qsTr("Apply HEX"); color: RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: Font.DemiBold }
                            MouseArea { id: applyHexMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: root.applyCustomAccent(customHex.text) }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("Any #RRGGBB color")
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text { text: qsTr("Glass highlight"); color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold }
                            Text { text: qsTr("Keep the subtle one-pixel sheen on shared surfaces"); color: RaohaneTheme.textMuted; font.pixelSize: 8 }
                        }
                        Rectangle {
                            width: 48
                            height: 27
                            radius: 14
                            color: Boolean(root.styleValue("sheenEnabled", true)) ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceRaised
                            border.width: 1
                            border.color: Boolean(root.styleValue("sheenEnabled", true)) ? RaohaneTheme.accentBorder : RaohaneTheme.border
                            Rectangle {
                                width: 19; height: 19; radius: 10; anchors.verticalCenter: parent.verticalCenter
                                x: Boolean(root.styleValue("sheenEnabled", true)) ? parent.width - width - 4 : 4
                                color: Boolean(root.styleValue("sheenEnabled", true)) ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                Behavior on x { NumberAnimation { duration: RaohaneTheme.animationFast } }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: root.setStyle("sheenEnabled", !Boolean(root.styleValue("sheenEnabled", true))) }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 14
                text: qsTr("Theme, Style Studio and custom accent are saved in ~/.config/raohane/native.json and restored after restart.")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
                wrapMode: Text.WordWrap
            }
        }
    }

    component StyleSlider: Rectangle {
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

        readonly property real normalized: maximum <= minimum ? 0 : Math.max(0, Math.min(1, (value - minimum) / (maximum - minimum)))
        readonly property string shownValue: String(Math.round(value * multiplier)) + suffix

        Layout.preferredHeight: 78
        radius: 18
        color: RaohaneTheme.surfaceSubtle
        border.width: 1
        border.color: sliderMouse.containsMouse ? RaohaneTheme.borderStrong : RaohaneTheme.border

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
                    Text { Layout.fillWidth: true; text: control.title; color: RaohaneTheme.text; font.pixelSize: 9; font.weight: Font.DemiBold; elide: Text.ElideRight }
                    Text { Layout.fillWidth: true; text: control.detail; color: RaohaneTheme.textMuted; font.pixelSize: 7; elide: Text.ElideRight }
                }
                Text { text: control.shownValue; color: RaohaneTheme.textMuted; font.pixelSize: 8; font.weight: Font.DemiBold }
            }

            Item {
                id: trackArea
                Layout.fillWidth: true
                Layout.preferredHeight: 18
                Rectangle {
                    anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter }
                    height: 5
                    radius: 3
                    color: RaohaneTheme.borderFaint
                    Rectangle { width: parent.width * control.normalized; height: parent.height; radius: parent.radius; color: RaohaneTheme.accent; opacity: 0.7 }
                }
                Rectangle {
                    width: sliderMouse.pressed ? 16 : 14
                    height: width
                    radius: width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    x: Math.max(0, Math.min(trackArea.width - width, control.normalized * trackArea.width - width / 2))
                    color: RaohaneTheme.surfaceRaised
                    border.width: 2
                    border.color: RaohaneTheme.accent
                    Behavior on width { NumberAnimation { duration: RaohaneTheme.animationFast } }
                }
                MouseArea {
                    id: sliderMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    preventStealing: true
                    cursorShape: pressed ? Qt.ClosedHandCursor : Qt.PointingHandCursor
                    function applyPosition(mouseX: real): void {
                        if (width <= 0 || control.maximum <= control.minimum)
                            return
                        const ratio = Math.max(0, Math.min(1, mouseX / width))
                        const raw = control.minimum + ratio * (control.maximum - control.minimum)
                        const snapped = control.step > 0 ? control.minimum + Math.round((raw - control.minimum) / control.step) * control.step : raw
                        control.userChanged(Math.max(control.minimum, Math.min(control.maximum, Number(snapped.toFixed(3)))))
                    }
                    onPressed: mouse => applyPosition(mouse.x)
                    onPositionChanged: mouse => { if (pressed) applyPosition(mouse.x) }
                }
            }
        }
    }
}
