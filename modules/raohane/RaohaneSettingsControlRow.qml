pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as Controls
import QtQuick.Layouts

import qs.modules.raohane.config

RaohaneSurface {
    id: root

    property var entry: null
    property bool lastRow: false
    property bool highlighted: false

    readonly property bool toggleRow: root.entry?.type === "toggle"
    readonly property bool numberRow: root.entry?.type === "number"
    readonly property bool textRow: root.entry?.type === "text"
    readonly property bool choiceRow: root.entry?.type === "choice"
    readonly property var choiceOptions: Array.isArray(root.entry?.options) ? root.entry.options : []
    readonly property bool rowHovered: rowHover.hovered || activeFocus
    readonly property bool compactRow: width < 620

    height: root.numberRow ? 80 : root.textRow ? 70 : 62
    activeFocusOnTab: root.toggleRow || root.numberRow || root.choiceRow
    surfaceRadius: RaohaneTheme.radiusSmall
    active: root.highlighted
    transparentIdle: !root.highlighted
    showSheen: false
    showInnerRim: false
    hovered: root.rowHovered
    hoverColor: RaohaneTheme.surfaceHover
    activeColor: RaohaneTheme.accentSoft
    activeBorderColor: "transparent"
    border.width: 0
    showStateRail: false

    function changeNumber(delta: real): void {
        if (!root.entry)
            return
        const current = Number(RaohaneConfig[root.entry.key] ?? 0)
        const minimum = Number(root.entry.min)
        const maximum = Number(root.entry.max)
        RaohaneConfig[root.entry.key] = Math.max(minimum, Math.min(maximum, current + delta))
    }

    function numberText(): string {
        if (!root.entry)
            return ""
        const value = Number(RaohaneConfig[root.entry.key] ?? 0)
        const step = Number(root.entry.step ?? 1)
        if (step > 0 && step < 0.1)
            return value.toFixed(2)
        if (step > 0 && step < 1)
            return value.toFixed(1)
        return String(Math.round(value))
    }

    function currentChoiceIndex(): int {
        if (!root.entry || root.choiceOptions.length === 0)
            return -1
        const current = String(RaohaneConfig[root.entry.key] ?? "")
        for (let i = 0; i < root.choiceOptions.length; ++i) {
            const option = root.choiceOptions[i]
            if (String(option.value) === current || (option.aliases ?? []).includes(current))
                return i
        }
        return 0
    }

    function currentChoice(): var {
        const index = root.currentChoiceIndex()
        return index >= 0 && index < root.choiceOptions.length ? root.choiceOptions[index] : null
    }

    function setChoice(index: int): void {
        if (!root.entry || index < 0 || index >= root.choiceOptions.length)
            return
        const optionValue = root.choiceOptions[index].value
        RaohaneConfig[root.entry.key] = typeof optionValue === "number"
            ? Number(optionValue)
            : String(optionValue)
    }

    function changeChoice(delta: int): void {
        if (!root.entry || root.choiceOptions.length === 0)
            return
        const current = Math.max(0, root.currentChoiceIndex())
        root.setChoice((current + delta + root.choiceOptions.length) % root.choiceOptions.length)
    }

    RowLayout {
        id: standardRow
        visible: !root.numberRow
        anchors.fill: parent
        anchors.leftMargin: RaohaneTheme.panelPadding
        anchors.rightMargin: RaohaneTheme.panelPadding
        spacing: root.compactRow ? RaohaneTheme.spacing : RaohaneTheme.spacing + RaohaneTheme.spacingSmall

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.entry?.label ?? ""
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.Medium
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.entry?.detail ?? ""
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                lineHeight: 1.16
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
        }

        RaohaneSwitch {
            visible: root.toggleRow
            Layout.preferredWidth: 44
            Layout.preferredHeight: 26
            checked: root.entry ? Boolean(RaohaneConfig[root.entry.key]) : false
            enabled: false
            opacity: 1
        }

        Controls.ComboBox {
            id: choiceCombo
            visible: root.choiceRow
            Layout.preferredWidth: root.compactRow ? Math.max(168, root.width * 0.36) : 210
            Layout.preferredHeight: 36
            model: root.choiceOptions
            currentIndex: root.currentChoiceIndex()
            textRole: "label"
            hoverEnabled: true
            leftPadding: 12
            rightPadding: 34
            topPadding: 0
            bottomPadding: 0

            onActivated: index => root.setChoice(index)

            background: Rectangle {
                radius: RaohaneTheme.radiusSmall
                color: choiceCombo.popup.visible || choiceCombo.activeFocus
                    ? RaohaneTheme.surfaceHover
                    : RaohaneTheme.surfaceDeep
                border.width: 1
                border.color: choiceCombo.popup.visible || choiceCombo.activeFocus
                    ? RaohaneTheme.accentBorder
                    : choiceCombo.hovered ? RaohaneTheme.borderStrong : RaohaneTheme.borderFaint

                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
                Behavior on border.color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            contentItem: RowLayout {
                spacing: RaohaneTheme.spacingSmall

                Rectangle {
                    visible: String(root.currentChoice()?.color ?? "").length > 0
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14
                    radius: 7
                    color: root.currentChoice()?.color ?? "transparent"
                    border.width: 1
                    border.color: RaohaneTheme.borderStrong
                }

                RaohaneIcon {
                    visible: String(root.currentChoice()?.icon ?? "").length > 0
                    text: root.currentChoice()?.icon ?? "tune"
                    iconSize: 14
                    color: RaohaneTheme.accent
                }

                Text {
                    Layout.fillWidth: true
                    text: root.currentChoice()?.label ?? ""
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.Medium
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                }
            }

            indicator: RaohaneIcon {
                x: choiceCombo.width - width - 11
                y: (choiceCombo.height - height) / 2
                text: choiceCombo.popup.visible ? "expand_less" : "expand_more"
                iconSize: 14
                color: choiceCombo.popup.visible ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            delegate: Controls.ItemDelegate {
                id: optionDelegate
                required property var modelData
                required property int index

                width: choiceCombo.width - 8
                height: 38
                leftPadding: 10
                rightPadding: 10
                highlighted: choiceCombo.highlightedIndex === index

                background: Rectangle {
                    radius: RaohaneTheme.radiusSmall
                    color: optionDelegate.highlighted
                        ? RaohaneTheme.surfaceHover
                        : optionDelegate.index === root.currentChoiceIndex()
                            ? RaohaneTheme.accentSoft
                            : "transparent"
                }

                contentItem: RowLayout {
                    spacing: RaohaneTheme.spacingSmall

                    Rectangle {
                        visible: String(optionDelegate.modelData?.color ?? "").length > 0
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        radius: 7
                        color: optionDelegate.modelData?.color ?? "transparent"
                        border.width: 1
                        border.color: RaohaneTheme.borderStrong
                    }

                    RaohaneIcon {
                        visible: String(optionDelegate.modelData?.icon ?? "").length > 0
                        text: optionDelegate.modelData?.icon ?? "tune"
                        iconSize: 14
                        color: optionDelegate.index === root.currentChoiceIndex()
                            ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }

                    Text {
                        Layout.fillWidth: true
                        text: String(optionDelegate.modelData?.label ?? "")
                        color: RaohaneTheme.text
                        font.pixelSize: 9
                        font.weight: optionDelegate.index === root.currentChoiceIndex()
                            ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }

                    RaohaneIcon {
                        visible: optionDelegate.index === root.currentChoiceIndex()
                        text: "check"
                        iconSize: 13
                        fill: 1
                        color: RaohaneTheme.accent
                    }
                }
            }

            popup: Controls.Popup {
                y: choiceCombo.height + 4
                width: choiceCombo.width
                padding: 4
                implicitHeight: Math.min(contentItem.implicitHeight + 8, 260)

                background: Rectangle {
                    radius: RaohaneTheme.radius
                    color: RaohaneTheme.surfaceRaised
                    border.width: 1
                    border.color: RaohaneTheme.accentBorder
                }

                contentItem: ListView {
                    clip: true
                    implicitHeight: contentHeight
                    model: choiceCombo.popup.visible ? choiceCombo.delegateModel : null
                    currentIndex: choiceCombo.highlightedIndex
                    spacing: 2
                    boundsBehavior: Flickable.StopAtBounds
                    Controls.ScrollIndicator.vertical: Controls.ScrollIndicator {}
                }
            }
        }

        RaohaneSurface {
            visible: root.textRow
            Layout.preferredWidth: root.compactRow ? Math.max(180, root.width * 0.40) : Math.min(320, root.width * 0.44)
            Layout.preferredHeight: 36
            surfaceRadius: RaohaneTheme.radiusSmall
            raised: false
            active: field.activeFocus
            showSheen: false
            showInnerRim: false
            idleColor: RaohaneTheme.surfaceDeep
            activeColor: RaohaneTheme.surfaceHover
            idleBorderColor: RaohaneTheme.borderFaint
            activeBorderColor: RaohaneTheme.accentBorder

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                verticalAlignment: TextInput.AlignVCenter
                text: root.entry ? String(RaohaneConfig[root.entry.key] ?? "") : ""
                color: RaohaneTheme.text
                selectionColor: RaohaneTheme.accentSoft
                selectedTextColor: RaohaneTheme.text
                font.pixelSize: 9
                clip: true
                onEditingFinished: {
                    if (root.entry)
                        RaohaneConfig[root.entry.key] = text
                }
            }
        }
    }

    ColumnLayout {
        id: numberRowLayout
        visible: root.numberRow
        anchors.fill: parent
        anchors.leftMargin: RaohaneTheme.panelPadding
        anchors.rightMargin: RaohaneTheme.panelPadding
        anchors.topMargin: 7
        anchors.bottomMargin: 7
        spacing: 3

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.entry?.label ?? ""
                    color: RaohaneTheme.text
                    font.pixelSize: 10
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.entry?.detail ?? ""
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            RaohaneSurface {
                Layout.preferredWidth: Math.max(50, numberValue.implicitWidth + 18)
                Layout.preferredHeight: 24
                surfaceRadius: RaohaneTheme.radiusSmall
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceDeep
                idleBorderColor: "transparent"

                Text {
                    id: numberValue
                    anchors.centerIn: parent
                    text: root.numberText()
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    font.weight: Font.DemiBold
                }
            }
        }

        RaohaneSlider {
            Layout.fillWidth: true
            Layout.preferredHeight: 24
            from: Number(root.entry?.min ?? 0)
            to: Number(root.entry?.max ?? 1)
            stepSize: Number(root.entry?.step ?? 1)
            value: root.entry ? Number(RaohaneConfig[root.entry.key] ?? 0) : 0
            trackHeight: 8
            handleWidth: 3
            handleHeight: 18
            onMoved: value => {
                if (root.entry)
                    RaohaneConfig[root.entry.key] = value
            }
        }
    }

    RaohaneDivider {
        visible: !root.lastRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: RaohaneTheme.panelPadding
            rightMargin: RaohaneTheme.panelPadding
        }
        height: 1
        color: RaohaneTheme.borderFaint
        opacity: 0.62
    }

    HoverHandler {
        id: rowHover
    }

    MouseArea {
        id: settingMouse
        anchors.fill: parent
        enabled: root.toggleRow
        acceptedButtons: Qt.LeftButton
        cursorShape: Qt.PointingHandCursor
        onPressed: root.forceActiveFocus()
        onClicked: {
            if (root.entry)
                RaohaneConfig[root.entry.key] = !Boolean(RaohaneConfig[root.entry.key])
        }
    }

    Keys.onPressed: event => {
        if (!root.entry)
            return
        if (root.toggleRow && (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
            RaohaneConfig[root.entry.key] = !Boolean(RaohaneConfig[root.entry.key])
            event.accepted = true
        } else if (root.numberRow && event.key === Qt.Key_Left) {
            root.changeNumber(-Number(root.entry?.step ?? 0))
            event.accepted = true
        } else if (root.numberRow && event.key === Qt.Key_Right) {
            root.changeNumber(Number(root.entry?.step ?? 0))
            event.accepted = true
        } else if (root.choiceRow && event.key === Qt.Key_Left) {
            root.changeChoice(-1)
            event.accepted = true
        } else if (root.choiceRow && event.key === Qt.Key_Right) {
            root.changeChoice(1)
            event.accepted = true
        }
    }
}
