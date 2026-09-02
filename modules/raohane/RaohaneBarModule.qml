pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.config
import qs.modules.raohane.services

// One reusable renderer for a registered bar module. This keeps module behavior
// out of the horizontal bar geometry so ordering can come entirely from the
// persisted layout.
Item {
    id: root

    required property string moduleId
    property var screen: null
    property var parentWindow: null
    property bool hostActive: true

    readonly property bool known: RaohaneBarModuleRegistry.isKnown(moduleId)

    implicitWidth: contentLoader.item?.implicitWidth ?? contentLoader.item?.width ?? 0
    implicitHeight: contentLoader.item?.implicitHeight ?? contentLoader.item?.height ?? 0
    width: implicitWidth
    height: implicitHeight
    visible: known && contentLoader.status === Loader.Ready

    function componentFor(id: string): Component {
        switch (id) {
        case "launcher": return launcherComponent
        case "workspaces": return workspacesComponent
        case "context": return contextComponent
        case "tray": return trayComponent
        case "system": return systemComponent
        case "clock": return clockComponent
        case "control": return controlComponent
        case "separator": return separatorComponent
        default: return null
        }
    }

    Loader {
        id: contentLoader
        anchors.centerIn: parent
        active: root.known
        sourceComponent: root.componentFor(root.moduleId)
    }

    Component {
        id: launcherComponent

        RaohaneIconButton {
            implicitWidth: 30
            implicitHeight: 30
            buttonSize: 30
            iconSize: 17
            icon: "apps"
            onClicked: RaohaneState.togglePrimary("launcher")
        }
    }

    Component {
        id: workspacesComponent

        RaohaneWorkspaces {
            screen: root.screen
        }
    }

    Component {
        id: contextComponent

        RaohaneContextIsland {
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor

                onClicked: mouse => {
                    if (RaohaneContext.mode !== "media") {
                        if (mouse.button === Qt.LeftButton)
                            RaohaneState.togglePrimary("controlCenter")
                        return
                    }

                    if (mouse.button === Qt.MiddleButton) {
                        RaohaneMedia.togglePlaying()
                    } else if (mouse.button === Qt.RightButton) {
                        RaohaneMedia.cyclePlayer(1)
                    } else {
                        RaohaneState.toggleSurface("mediaOverlay")
                    }
                }

                onWheel: wheel => {
                    if (RaohaneContext.mode !== "media" || !RaohaneMedia.volumeSupported)
                        return
                    const step = wheel.angleDelta.y >= 0 ? 0.04 : -0.04
                    RaohaneMedia.setVolume(RaohaneMedia.volume + step)
                    wheel.accepted = true
                }
            }
        }
    }

    Component {
        id: trayComponent

        RaohaneSysTray {
            parentWindow: root.parentWindow
        }
    }

    Component {
        id: systemComponent

        RaohaneSystemIcons {
            onActivated: RaohaneState.togglePrimary("controlCenter")
        }
    }

    Component {
        id: clockComponent

        RaohaneClock {
            showDate: RaohaneConfig.barShowDate
            active: root.hostActive
        }
    }

    Component {
        id: controlComponent

        RaohaneIconButton {
            implicitWidth: 30
            implicitHeight: 30
            buttonSize: 30
            iconSize: 16
            icon: "tune"
            onClicked: RaohaneState.togglePrimary("controlCenter")
        }
    }

    Component {
        id: separatorComponent

        Item {
            implicitWidth: 1
            implicitHeight: 17

            Rectangle {
                anchors.fill: parent
                color: RaohaneTheme.borderFaint
            }
        }
    }
}
