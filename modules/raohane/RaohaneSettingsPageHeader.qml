pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var pageInfo: null
    property var displayedPageInfo: null
    property bool compact: false
    property int direction: 1

    implicitHeight: 78

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
            anchors.leftMargin: 22
            anchors.rightMargin: 20
            spacing: 11

            RaohaneSurface {
                Layout.preferredWidth: 38
                Layout.preferredHeight: 38
                surfaceRadius: 11
                active: true
                raised: false
                showSheen: false

                RaohaneIcon {
                    anchors.centerIn: parent
                    text: root.displayedPageInfo?.icon ?? "settings"
                    iconSize: 18
                    fill: 1
                    symbolWeight: 550
                    grade: 30
                    color: RaohaneTheme.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: root.displayedPageInfo?.name ?? qsTr("Settings")
                    color: RaohaneTheme.text
                    font.pixelSize: 16
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

            RaohaneSurface {
                visible: !root.compact
                Layout.preferredWidth: groupText.implicitWidth + 18
                Layout.preferredHeight: 24
                surfaceRadius: 9
                transparentIdle: true
                showSheen: false

                Text {
                    id: groupText
                    anchors.centerIn: parent
                    text: root.displayedPageInfo?.group ?? qsTr("SYSTEM")
                    color: RaohaneTheme.textFaint
                    font.pixelSize: 7
                    font.weight: Font.DemiBold
                    font.letterSpacing: 0.75
                }
            }

            Item {
                Layout.preferredWidth: root.compact ? 44 : 344
                Layout.fillHeight: true
            }
        }
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

    Rectangle {
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            leftMargin: 22
            rightMargin: 20
        }
        height: 1
        color: RaohaneTheme.borderFaint
    }
}
