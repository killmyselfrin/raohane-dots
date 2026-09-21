pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var pageInfo: null
    property var displayedPageInfo: null
    property bool compact: false
    property int direction: 1

    implicitHeight: 64

    function syncImmediately(): void {
        headerSwap.stop()
        root.displayedPageInfo = root.pageInfo
        headerContent.opacity = 1
        headerTranslate.x = 0
    }

    onPageInfoChanged: {
        if (!root.displayedPageInfo || !RaohaneMotion.enabled) {
            root.syncImmediately()
            return
        }
        headerSwap.restart()
    }

    Component.onCompleted: root.syncImmediately()

    Item {
        id: headerContent
        anchors.fill: parent
        opacity: 1

        transform: Translate {
            id: headerTranslate
            x: 0
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: RaohaneTheme.panelPadding + 2
            anchors.rightMargin: RaohaneTheme.panelPadding + 2
            spacing: RaohaneTheme.spacing

            RaohaneSurface {
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                surfaceRadius: RaohaneTheme.radiusLarge
                active: false
                raised: false
                transparentIdle: true
                showSheen: false
                showInnerRim: false
                idleBorderColor: "transparent"

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: root.displayedPageInfo?.icon ?? "settings"
                    iconSize: 16
                    fill: 1
                    symbolWeight: 550
                    grade: 30
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: RaohaneTheme.spacingTiny / 3

                Text {
                    Layout.fillWidth: true
                    text: root.displayedPageInfo?.name ?? qsTr("Settings")
                    color: RaohaneTheme.text
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    Layout.fillWidth: true
                    text: root.displayedPageInfo?.subtitle ?? ""
                    color: RaohaneTheme.textMuted
                    font.pixelSize: 8
                    elide: Text.ElideRight
                }
            }

            Item {
                Layout.preferredWidth: root.compact ? 36 : 360
                Layout.fillHeight: true
            }
        }
    }


    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 1
        color: RaohaneTheme.borderFaint
    }

    SequentialAnimation {
        id: headerSwap

        ParallelAnimation {
            NumberAnimation {
                target: headerContent
                property: "opacity"
                to: 0
                duration: RaohaneMotion.micro
                easing.type: RaohaneMotion.easeExit
            }
            NumberAnimation {
                target: headerTranslate
                property: "x"
                to: -root.direction * 5
                duration: RaohaneMotion.micro
                easing.type: RaohaneMotion.easeExit
            }
        }

        ScriptAction {
            script: {
                root.displayedPageInfo = root.pageInfo
                headerTranslate.x = root.direction * 7
            }
        }

        ParallelAnimation {
            NumberAnimation {
                target: headerContent
                property: "opacity"
                to: 1
                duration: RaohaneMotion.standard
                easing.type: RaohaneMotion.easeStandard
            }
            NumberAnimation {
                target: headerTranslate
                property: "x"
                to: 0
                duration: RaohaneMotion.standard
                easing.type: RaohaneMotion.easeEmphasized
            }
        }
    }


}
