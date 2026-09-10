pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    property string queryText: ""

    signal queryEdited(string text)
    signal clearRequested()
    signal settingsRequested()
    signal escapeRequested()
    signal selectionMoveRequested(int delta)
    signal submitRequested()

    function focusSearch(): void {
        searchInput.forceActiveFocus()
    }

    implicitHeight: 52
    spacing: RaohaneTheme.spacing

    RaohaneSurface {
        Layout.fillWidth: true
        Layout.preferredHeight: 50
        surfaceRadius: RaohaneTheme.radiusHero
        raised: false
        active: searchInput.activeFocus
        showSheen: false
        showInnerRim: false
        idleColor: RaohaneTheme.surface
        activeColor: RaohaneTheme.surface
        idleBorderColor: RaohaneTheme.borderStrong
        activeBorderColor: RaohaneTheme.accentBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding + 1
            anchors.rightMargin: RaohaneTheme.spacing + 1
            spacing: RaohaneTheme.spacing

            RaohaneIcon {
                text: "search"
                iconSize: 19
                fill: searchInput.activeFocus ? 1 : 0
                symbolWeight: searchInput.activeFocus ? 540 : 430
                color: searchInput.activeFocus ? RaohaneTheme.accent : RaohaneTheme.textMuted
            }

            TextInput {
                id: searchInput

                Layout.fillWidth: true
                color: RaohaneTheme.text
                selectionColor: RaohaneTheme.accentSoft
                selectedTextColor: RaohaneTheme.text
                font.pixelSize: 12
                clip: true
                text: root.queryText

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: searchInput.text.length === 0
                    text: qsTr("Search Raohane")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 10
                }

                onTextChanged: {
                    if (root.queryText !== text)
                        root.queryEdited(text)
                }

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        root.escapeRequested()
                        event.accepted = true
                    } else if (event.key === Qt.Key_Down) {
                        root.selectionMoveRequested(1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Up) {
                        root.selectionMoveRequested(-1)
                        event.accepted = true
                    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        root.submitRequested()
                        event.accepted = true
                    }
                }
            }

            RaohaneIconButton {
                visible: searchInput.text.length > 0
                buttonSize: 30
                iconSize: 14
                icon: "backspace"
                transparentIdle: true
                showSheen: false
                hoverScale: 1
                pressedScale: 1
                onClicked: root.clearRequested()
            }
        }
    }

    RaohaneIconButton {
        buttonSize: 48
        iconSize: 19
        icon: "settings"
        transparentIdle: false
        showSheen: false
        hoverScale: 1
        pressedScale: 1
        onClicked: root.settingsRequested()
    }
}
