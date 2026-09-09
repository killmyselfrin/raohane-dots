pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

FocusScope {
    id: root

    property string query: ""
    property int currentIndex: 0
    property real maximumResultsHeight: 340
    readonly property bool active: root.activeFocus
    readonly property bool resultsOpen: root.activeFocus && root.query.trim().length > 0
    readonly property var entries: RaohaneSettingsPageRegistry.searchEntries()
    readonly property var filteredEntries: root.filtered(root.query)
    signal activated()

    implicitWidth: 300
    implicitHeight: 34
    z: 100

    function filtered(value: string): var {
        return RaohaneSettingsPageRegistry.rankedSearch(root.entries, value)
    }

    function selectResult(index: int): void {
        root.currentIndex = Math.max(0, Math.min(root.filteredEntries.length - 1, index))
        resultsList.positionViewAtIndex(root.currentIndex, ListView.Contain)
    }

    onFilteredEntriesChanged: {
        root.currentIndex = 0
        Qt.callLater(() => resultsList.positionViewAtBeginning())
    }

    function focusSearch(): void {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    function clear(): void {
        root.query = ""
        root.currentIndex = 0
    }

    function activate(index: int): void {
        if (root.filteredEntries.length === 0)
            return
        const safeIndex = Math.max(0, Math.min(root.filteredEntries.length - 1, index))
        const entry = root.filteredEntries[safeIndex]
        RaohaneSettingsRouter.requestSearch(entry.section, entry.key)
        root.clear()
        root.activated()
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
                    font.pixelSize: 11
                    clip: true
                    text: root.query
                    activeFocusOnTab: true
                    Accessible.name: qsTr("Search settings")

                    onTextChanged: {
                        if (root.query !== text)
                            root.query = text
                        root.currentIndex = 0
                    }

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Down && root.filteredEntries.length > 0) {
                            root.selectResult(root.currentIndex + 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Up && root.filteredEntries.length > 0) {
                            root.selectResult(root.currentIndex - 1)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(root.currentIndex)
                            event.accepted = true
                        } else if (event.key === Qt.Key_Escape && root.query.length > 0) {
                            root.clear()
                            event.accepted = true
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.query.length === 0 && !searchInput.activeFocus
                    text: qsTr("Search settings")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 11
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
        visible: root.resultsOpen
        anchors {
            top: searchBox.bottom
            topMargin: 7
            left: parent.left
            right: parent.right
        }
        height: Math.max(0, Math.min(root.maximumResultsHeight,
            root.filteredEntries.length > 0 ? root.filteredEntries.length * 49 + 11 : 50))
        surfaceRadius: 14
        raised: true
        showSheen: false
        border.color: RaohaneTheme.borderStrong
        clip: true
        z: 101
        opacity: root.resultsOpen ? 1 : 0

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
            currentIndex: root.currentIndex
            keyNavigationEnabled: false

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: FocusScope {
                id: resultRow
                required property var modelData
                required property int index
                width: resultsList.width
                height: 46
                activeFocusOnTab: true
                Accessible.role: Accessible.Button
                Accessible.name: modelData.label + ", " + modelData.detail
                Accessible.onPressAction: root.activate(resultRow.index)
                onActiveFocusChanged: {
                    if (activeFocus)
                        root.selectResult(index)
                }

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
                            text: resultRow.modelData.icon ?? "tune"
                            iconSize: 15
                            fill: resultRow.index === root.currentIndex ? 1 : 0
                            color: resultRow.index === root.currentIndex ? RaohaneTheme.accent : RaohaneTheme.textMuted
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                text: resultRow.modelData.label
                                textFormat: Text.PlainText
                                color: RaohaneTheme.text
                                font.pixelSize: 11
                                font.weight: resultRow.index === root.currentIndex ? Font.DemiBold : Font.Medium
                                elide: Text.ElideRight
                            }

                            Text {
                                Layout.fillWidth: true
                                text: resultRow.modelData.detail
                                textFormat: Text.PlainText
                                color: RaohaneTheme.textMuted
                                font.pixelSize: 9
                                elide: Text.ElideRight
                            }
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
                    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Up) {
                        searchInput.forceActiveFocus()
                        root.selectResult(resultRow.index + (event.key === Qt.Key_Down ? 1 : -1))
                        event.accepted = true
                    }
                }
            }
        }
    }
}
