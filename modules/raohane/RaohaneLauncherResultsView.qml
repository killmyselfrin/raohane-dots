pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    property var results: []
    property int selectedIndex: -1

    signal selectionHovered(int index)
    signal activateRequested(int index)

    spacing: RaohaneTheme.spacingSmall - 1

    ColumnLayout {
        Layout.fillWidth: true
        spacing: RaohaneTheme.spacingSmall - 1
        visible: root.results.length > 0

        Repeater {
            model: root.results

            delegate: ResultRow {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                resultData: modelData
                rowIndex: index
                selected: index === root.selectedIndex
            }
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.preferredHeight: 100
        visible: root.results.length === 0

        Column {
            anchors.centerIn: parent
            spacing: RaohaneTheme.spacingSmall

            RaohaneSurface {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 40
                height: 40
                surfaceRadius: RaohaneTheme.radiusLarge
                raised: false
                showSheen: false
                showInnerRim: false
                idleColor: RaohaneTheme.surfaceSubtle
                idleBorderColor: RaohaneTheme.borderFaint

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: "search_off"
                    iconSize: 20
                    color: RaohaneTheme.textFaint
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("No results")
                color: RaohaneTheme.text
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("/ actions    > commands    = math    : clipboard")
                color: RaohaneTheme.textFaint
                font.pixelSize: 8
            }
        }
    }

    component ResultRow: RaohaneSurface {
        id: row

        required property var resultData
        required property int rowIndex
        property bool selected: false

        Layout.preferredHeight: 55
        surfaceRadius: RaohaneTheme.radiusLarge
        active: selected
        hovered: resultMouse.containsMouse || activeFocus
        pressed: resultMouse.pressed
        interactive: true
        transparentIdle: !selected && !hovered
        showSheen: false
        showInnerRim: selected
        hoverScale: 1
        pressedScale: 1
        activeFocusOnTab: true
        showStateRail: selected
        stateRailWidth: 3
        stateRailLength: 24
        stateRailOpacity: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.spacing + 2
            anchors.rightMargin: RaohaneTheme.panelPadding
            spacing: RaohaneTheme.spacing + 1

            RaohaneSurface {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                surfaceRadius: RaohaneTheme.radius
                active: row.selected
                showSheen: false
                showInnerRim: false

                Loader {
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    sourceComponent: {
                        if (row.resultData?.iconType === "system")
                            return systemIcon
                        if (row.resultData?.iconType === "material")
                            return materialIcon
                        if (row.resultData?.iconType === "text")
                            return textIcon
                        return fallbackIcon
                    }
                }

                Component {
                    id: systemIcon
                    RaohaneAdaptiveIcon {
                        anchors.centerIn: parent
                        iconSource: String(row.resultData?.iconName ?? "")
                        iconSize: 25
                        fallbackColor: row.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }
                }

                Component {
                    id: materialIcon
                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: String(row.resultData?.iconName ?? "apps")
                        iconSize: 18
                        fill: row.selected ? 1 : 0
                        symbolWeight: row.selected ? 540 : 430
                        color: row.selected ? RaohaneTheme.accent : RaohaneTheme.textMuted
                    }
                }

                Component {
                    id: textIcon
                    Text {
                        anchors.centerIn: parent
                        text: String(row.resultData?.iconName ?? "")
                        color: row.selected ? RaohaneTheme.accent : RaohaneTheme.text
                        font.pixelSize: 15
                    }
                }

                Component {
                    id: fallbackIcon
                    RaohaneIcon {
                        anchors.centerIn: parent
                        text: "apps"
                        iconSize: 17
                        color: RaohaneTheme.textMuted
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Math.max(1, RaohaneTheme.spacingTiny - 2)

                Text {
                    Layout.fillWidth: true
                    text: String(row.resultData?.name ?? "")
                    color: RaohaneTheme.text
                    font.pixelSize: 9
                    font.weight: row.selected ? Font.DemiBold : Font.Medium
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: String(row.resultData?.comment || row.resultData?.type || "")
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 7
                    elide: Text.ElideRight
                }
            }

            Text {
                text: String(row.resultData?.verb ?? "")
                color: row.selected ? RaohaneTheme.accent : RaohaneTheme.textFaint
                font.pixelSize: 7
                font.weight: Font.DemiBold
                font.letterSpacing: 0.4
            }
        }

        MouseArea {
            id: resultMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onPressed: row.forceActiveFocus()
            onEntered: root.selectionHovered(row.rowIndex)
            onClicked: root.activateRequested(row.rowIndex)
        }

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                root.activateRequested(row.rowIndex)
                event.accepted = true
            }
        }
    }
}
