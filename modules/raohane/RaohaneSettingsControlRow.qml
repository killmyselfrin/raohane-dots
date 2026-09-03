pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config

Item {
    id: root

    property var entry: null
    property bool lastRow: false

    readonly property bool toggleRow: root.entry?.type === "toggle"
    readonly property bool numberRow: root.entry?.type === "number"
    readonly property bool textRow: root.entry?.type === "text"
    readonly property bool rowHovered: settingMouse.containsMouse || activeFocus

    height: root.textRow ? 76 : 64
    activeFocusOnTab: root.toggleRow

    function changeNumber(delta: real): void {
        if (!root.entry)
            return
        const current = Number(RaohaneConfig[root.entry.key] ?? 0)
        const minimum = Number(root.entry.min)
        const maximum = Number(root.entry.max)
        RaohaneConfig[root.entry.key] = Math.max(minimum, Math.min(maximum, current + delta))
    }

    Rectangle {
        anchors.fill: parent
        color: root.rowHovered ? RaohaneTheme.surfaceHover : "transparent"
        opacity: root.rowHovered ? 0.72 : 0

        Behavior on opacity {
            NumberAnimation { duration: RaohaneMotion.micro }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 12
        spacing: 18

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                Layout.fillWidth: true
                text: root.entry?.label ?? ""
                color: RaohaneTheme.text
                font.pixelSize: 10
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                Layout.fillWidth: true
                text: root.entry?.detail ?? ""
                color: RaohaneTheme.textMuted
                font.pixelSize: 8
                lineHeight: 1.15
                wrapMode: Text.WordWrap
            }
        }

        RaohaneSwitch {
            visible: root.toggleRow
            Layout.preferredWidth: 42
            Layout.preferredHeight: 24
            checked: root.entry ? Boolean(RaohaneConfig[root.entry.key]) : false
            enabled: false
            opacity: 1
        }

        RaohaneSurface {
            visible: root.numberRow
            Layout.preferredWidth: 126
            Layout.preferredHeight: 34
            surfaceRadius: 11
            raised: false
            showSheen: false
            border.color: RaohaneTheme.borderFaint

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 3
                anchors.rightMargin: 3
                spacing: 2

                RaohaneIconButton {
                    buttonSize: 27
                    iconSize: 13
                    icon: "remove"
                    transparentIdle: true
                    showSheen: false
                    onClicked: root.changeNumber(-Number(root.entry?.step ?? 0))
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: root.entry ? String(RaohaneConfig[root.entry.key]) : ""
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: Font.DemiBold
                }

                RaohaneIconButton {
                    buttonSize: 27
                    iconSize: 13
                    icon: "add"
                    transparentIdle: true
                    showSheen: false
                    onClicked: root.changeNumber(Number(root.entry?.step ?? 0))
                }
            }
        }

        RaohaneSurface {
            visible: root.textRow
            Layout.preferredWidth: Math.min(310, root.width * 0.42)
            Layout.preferredHeight: 34
            surfaceRadius: 10
            raised: false
            hovered: field.activeFocus
            showSheen: false
            border.color: field.activeFocus ? RaohaneTheme.accentBorder : RaohaneTheme.borderFaint

            TextInput {
                id: field
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
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

    Rectangle {
        visible: !root.lastRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 16
            rightMargin: 16
        }
        height: 1
        color: RaohaneTheme.borderFaint
    }

    MouseArea {
        id: settingMouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: root.toggleRow ? Qt.LeftButton : Qt.NoButton
        cursorShape: root.toggleRow ? Qt.PointingHandCursor : Qt.ArrowCursor
        onPressed: root.forceActiveFocus()
        onClicked: {
            if (root.toggleRow && root.entry)
                RaohaneConfig[root.entry.key] = !Boolean(RaohaneConfig[root.entry.key])
        }
    }

    Keys.onPressed: event => {
        if (!root.toggleRow || !root.entry)
            return
        if (event.key === Qt.Key_Space || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            RaohaneConfig[root.entry.key] = !Boolean(RaohaneConfig[root.entry.key])
            event.accepted = true
        }
    }
}
