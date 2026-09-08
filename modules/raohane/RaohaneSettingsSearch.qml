pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string query: ""
    property int currentIndex: 0
    readonly property bool active: searchInput.activeFocus || root.query.length > 0
    readonly property var entries: RaohaneSettingsPageRegistry.searchEntries()
    readonly property var filteredEntries: root.filtered(root.query)

    implicitWidth: 300
    implicitHeight: 34
    z: 100

    function filtered(value: string): var {
        const needle = String(value ?? "").trim().toLowerCase()
        if (needle.length === 0)
            return []
        return root.entries.filter(entry => {
            return entry.label.toLowerCase().includes(needle)
                || entry.detail.toLowerCase().includes(needle)
                || entry.key.toLowerCase().includes(needle)
        }).slice(0, 7)
    }

    function focusSearch(): void {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    function clear(): void {
        root.query = ""
        root.currentIndex = 0
        searchInput.text = ""
    }

    function activate(index: int): void {
        if (root.filteredEntries.length === 0)
            return
        const safeIndex = Math.max(0, Math.min(root.filteredEntries.length - 1, index))
        const entry = root.filteredEntries[safeIndex]
        RaohaneSettingsRouter.requestSearch(entry.section, entry.key)
        root.clear()
    }

    RaohaneSurface {
        id: searchBox
        anchors.fill: parent
        surfaceRadius: 11
        raised: false
        active: searchInput.activeFocus
        hovered: searchHover.containsMouse
        showSheen: false

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 10
            anchors.rightMargin: 9
            spacing: 8

            RaohaneIcon {
                text: "search"
                iconSize: 16
                fill: searchInput.activeFocus ? 1 : 0
                color: searchInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted
                Behavior on color { ColorAnimation { duration: RaohaneMotion.micro } }
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TextInput {
                    id: searchInput
                    anchors.fill: parent
                    verticalAlignment: TextInput.AlignVCenter
                    color: RaohaneTheme.text
                    selectionColor: RaohaneTheme.accentSoft
                    selectedTextColor: RaohaneTheme.text
                    font.pixelSize: 10
                    clip: true
                    text: root.query

                    onTextChanged: {
                        if (root.query !== text)
                            root.query = text
                        root.currentIndex = 0
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down && root.filteredEntries.length > 0) {
                            root.currentIndex = Math.min(root.filteredEntries.length - 1, root.currentIndex + 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up && root.filteredEntries.length > 0) {
                            root.currentIndex = Math.max(0, root.currentIndex - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(root.currentIndex)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape) {
                            root.clear()
                            focus = false
                            event.accepted = true
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.query.length === 0 && !searchInput.activeFocus
                    text: qsTr("Search settings")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 10
                }
            }

            RaohaneSurface {
                visible: root.query.length === 0
                Layout.preferredWidth: 42
                Layout.preferredHeight: 22
                surfaceRadius: 8
                raised: false
                showSheen: false
                Text {
                    anchors.centerIn: parent
                    text: "Ctrl F"
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 8
                    font.weight: Font.Medium
                }
            }

            RaohaneIconButton {
                visible: root.query.length > 0
                buttonSize: 26
                iconSize: 14
                icon: "close"
                onClicked: { root.clear(); searchInput.forceActiveFocus() }
            }
        }

        MouseArea {
            id: searchHover
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            hoverEnabled: true
        }
    }

    RaohaneSurface {
        id: resultsPanel
        visible: root.query.length > 0
        anchors {
            top: searchBox.bottom
            topMargin: 7
            left: parent.left
            right: parent.right
        }
        height: root.filteredEntries.length > 0 ? Math.min(310, resultsList.contentHeight + 14) : 50
        surfaceRadius: 14
        raised: true
        showSheen: false
        border.color: RaohaneTheme.borderStrong
        clip: true
        z: 101
        opacity: root.query.length > 0 ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: RaohaneMotion.micro
                easing.type: RaohaneMotion.easeStandard
            }
        }

        Text {
            visible: root.filteredEntries.length === 0
            anchors.centerIn: parent
            text: qsTr("No matching setting")
            color: RaohaneTheme.textMuted
            font.pixelSize: 10
        }

        ListView {
            id: resultsList
            visible: root.filteredEntries.length > 0
            anchors.fill: parent
            anchors.margins: 7
            model: root.filteredEntries
            spacing: 3
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            delegate: FocusScope {
                id: resultRow
                required property var modelData
                required property int index
                width: resultsList.width
                height: 40
                activeFocusOnTab: true

                RaohaneSurface {
                    anchors.fill: parent
                    surfaceRadius: 10
                    raised: false
                    active: resultRow.index === root.currentIndex || resultRow.activeFocus
                    hovered: resultMouse.containsMouse
                    pressed: resultMouse.pressed
                    showSheen: false

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 9

                        RaohaneIcon {
                            text: "tune"
                            iconSize: 15
                            fill: resultRow.index === root.currentIndex ? 1 : 0
                            color: resultRow.index === root.currentIndex ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        Text {
                            Layout.fillWidth: true
                            text: resultRow.modelData.label
                            color: RaohaneTheme.text
                            font.pixelSize: 10
                            font.weight: resultRow.index === root.currentIndex ? Font.DemiBold : Font.Medium
                            elide: Text.ElideRight
                        }

                        Text {
                            text: resultRow.modelData.detail
                            color: RaohaneTheme.textFaint
                            font.pixelSize: 8
                        }

                        RaohaneIcon {
                            text: "arrow_forward"
                            iconSize: 14
                            color: resultRow.index === root.currentIndex ? RaohaneTheme.accent : RaohaneTheme.textFaint
                            opacity: resultRow.index === root.currentIndex || resultMouse.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: RaohaneMotion.micro } }
                        }
                    }
                }

                MouseArea {
                    id: resultMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: root.currentIndex = resultRow.index
                    onPressed: resultRow.forceActiveFocus()
                    onClicked: root.activate(resultRow.index)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                        root.activate(resultRow.index)
                        event.accepted = true
                    }
                }
            }
        }
    }
}
