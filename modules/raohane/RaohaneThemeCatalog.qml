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
        { id: "sand", name: qsTr("Sand") }
    ]

    function accentColor(mode: string): color {
        switch (mode) {
        case "ink": return RaohaneTheme.dark ? "#eeeae2" : "#2b2a27"
        case "sakura": return "#9a7077"
        case "matcha": return "#667866"
        case "slate": return "#657987"
        case "sand": return "#806f59"
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
                    Text { Layout.fillWidth: true; text: qsTr("Fine-tune the current theme live. Shared surfaces update together, so the shell stays coherent."); color: RaohaneTheme.textMuted; font.pixelSize: 9; wrapMode: Text.WordWrap }
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

                StyleSlider { Layout.fillWidth: true; title: qsTr("Glass opacity"); detail: qsTr("How solid the frosted surfaces feel"); value: RaohaneTheme.glassOpacity; minimum: 0.55; maximum: 1.0; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => RaohaneTheme.glassOpacity = nextValue }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Border strength"); detail: qsTr("Hairline contrast around cards and islands"); value: RaohaneTheme.borderStrength; minimum: 0.45; maximum: 1.5; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => RaohaneTheme.borderStrength = nextValue }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Corner radius"); detail: qsTr("Global roundness without changing layout"); value: RaohaneTheme.radiusScale; minimum: 0.7; maximum: 1.4; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => RaohaneTheme.radiusScale = nextValue }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Interface density"); detail: qsTr("Compact or airy shared spacing and shell heights"); value: RaohaneTheme.densityScale; minimum: 0.82; maximum: 1.18; step: 0.03; multiplier: 100; suffix: "%"; onUserChanged: nextValue => RaohaneTheme.densityScale = nextValue }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Motion"); detail: qsTr("Animation speed and presence; 0 disables shared motion"); value: RaohaneTheme.motionScale; minimum: 0.0; maximum: 1.4; step: 0.1; multiplier: 100; suffix: "%"; onUserChanged: nextValue => RaohaneTheme.motionScale = nextValue }
                StyleSlider { Layout.fillWidth: true; title: qsTr("Accent intensity"); detail: qsTr("Strength of active states, pills and selected borders"); value: RaohaneTheme.accentStrength; minimum: 0.45; maximum: 1.5; step: 0.05; multiplier: 100; suffix: "%"; onUserChanged: nextValue => RaohaneTheme.accentStrength = nextValue }
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
                    spacing: 9

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: qsTr("Accent"); color: RaohaneTheme.text; font.pixelSize: 10; font.weight: Font.DemiBold }
                        Item { Layout.fillWidth: true }
                        Text { text: qsTr("one quiet accent across the shell"); color: RaohaneTheme.textFaint; font.pixelSize: 8 }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 7
                        Repeater {
                            model: root.accents
                            delegate: Rectangle {
                                id: accentButton
                                required property var modelData
                                readonly property bool selected: RaohaneTheme.accentMode === String(modelData.id)
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
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: RaohaneTheme.accentMode = String(accentButton.modelData.id) }
                            }
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
                            color: RaohaneTheme.sheenEnabled ? RaohaneTheme.accentSoft : RaohaneTheme.surfaceRaised
                            border.width: 1
                            border.color: RaohaneTheme.sheenEnabled ? RaohaneTheme.accentBorder : RaohaneTheme.border
                            Rectangle {
                                width: 19; height: 19; radius: 10; anchors.verticalCenter: parent.verticalCenter
                                x: RaohaneTheme.sheenEnabled ? parent.width - width - 4 : 4
                                color: RaohaneTheme.sheenEnabled ? RaohaneTheme.accent : RaohaneTheme.textFaint
                                Behavior on x { NumberAnimation { duration: RaohaneTheme.animationFast } }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: RaohaneTheme.sheenEnabled = !RaohaneTheme.sheenEnabled }
                        }
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 12
                Layout.rightMargin: 12
                Layout.bottomMargin: 14
                text: qsTr("Theme selection is saved in native.json. Style Studio overrides are live for the current shell session while the persistence schema is being finalized.")
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