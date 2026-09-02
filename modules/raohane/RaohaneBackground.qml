pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

import qs.modules.raohane.config
import qs.modules.raohane.services

Variants {
    id: root
    model: Quickshell.screens

    function fileUrl(path: string): string {
        if (!path || path.length === 0)
            return ""
        return path.startsWith("file://") ? path : "file://" + path
    }

    function isVideo(path: string): bool {
        const lower = (path ?? "").toLowerCase()
        return lower.endsWith(".mp4")
            || lower.endsWith(".webm")
            || lower.endsWith(".mkv")
            || lower.endsWith(".mov")
            || lower.endsWith(".avi")
    }

    Timer {
        interval: Math.max(1000, RaohaneConfig.wallpaperChangeInterval)
        running: RaohaneConfig.wallpaperChangeInterval > 0
        repeat: true
        onTriggered: {
            if (RaohaneWallpapers.wallpapers.length > 0)
                RaohaneWallpapers.randomFromCurrentFolder()
        }
    }

    PanelWindow {
        id: backgroundWindow

        required property var modelData

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        readonly property list<HyprlandWorkspace> monitorWorkspaces: Hyprland.workspaces.values.filter(workspace =>
            workspace.monitor && backgroundWindow.monitor
            && workspace.monitor.name === backgroundWindow.monitor.name
        )
        readonly property var activeFullscreenWorkspace: monitorWorkspaces.find(workspace =>
            workspace.active
            && workspace.toplevels.values.some(window => window.wayland?.fullscreen)
        ) ?? null
        readonly property bool hiddenForFullscreen: RaohaneConfig.wallpaperHideWhenFullscreen
            && !RaohaneState.screenLocked
            && activeFullscreenWorkspace !== null

        readonly property string requestedPath: {
            if (RaohaneState.screenLocked && RaohaneConfig.lockWallpaperPath.length > 0)
                return RaohaneConfig.lockWallpaperPath
            if (RaohaneConfig.wallpaperPreview && RaohaneWallpapers.previewPath.length > 0)
                return RaohaneWallpapers.previewPath
            if (RaohaneWallpapers.confirmedPath.length > 0)
                return RaohaneWallpapers.confirmedPath
            return RaohaneConfig.wallpaperPath
        }

        property string currentPath: requestedPath
        property string previousPath: ""
        property real transitionProgress: 1.0

        readonly property bool currentIsVideo: root.isVideo(currentPath)
        readonly property bool previousIsVideo: root.isVideo(previousPath)

        function switchToRequestedPath(): void {
            if (requestedPath === currentPath)
                return

            previousPath = currentPath
            currentPath = requestedPath

            if (RaohaneConfig.wallpaperTransitionDuration <= 0 || currentPath.length === 0) {
                previousPath = ""
                transitionProgress = 1.0
                return
            }

            transitionProgress = 0.0
            transitionAnimation.restart()
        }

        onRequestedPathChanged: switchToRequestedPath()

        screen: modelData
        color: "#09080d"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell:raohane-background"
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Item {
            id: content
            anchors.fill: parent
            opacity: backgroundWindow.hiddenForFullscreen ? 0 : 1
            enabled: !backgroundWindow.hiddenForFullscreen

            Behavior on opacity {
                NumberAnimation {
                    duration: 170
                    easing.type: Easing.OutCubic
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#17111d" }
                    GradientStop { position: 0.52; color: "#0d0b12" }
                    GradientStop { position: 1.0; color: "#08070c" }
                }
            }

            Image {
                id: previousImage
                anchors.fill: parent
                visible: backgroundWindow.previousPath.length > 0 && !backgroundWindow.previousIsVideo
                source: root.fileUrl(backgroundWindow.previousPath)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                opacity: 1.0 - backgroundWindow.transitionProgress
            }

            Image {
                id: currentImage
                anchors.fill: parent
                visible: backgroundWindow.currentPath.length > 0 && !backgroundWindow.currentIsVideo
                source: root.fileUrl(backgroundWindow.currentPath)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                opacity: backgroundWindow.transitionProgress
            }

            Loader {
                id: currentVideoLoader
                anchors.fill: parent
                // Destroy the player while a fullscreen client hides the background.
                // Keeping an invisible MediaPlayer alive still decodes frames and wastes
                // GPU/CPU time in games, which defeats wallpaperHideWhenFullscreen.
                active: backgroundWindow.currentPath.length > 0
                    && backgroundWindow.currentIsVideo
                    && !backgroundWindow.hiddenForFullscreen
                opacity: backgroundWindow.transitionProgress

                sourceComponent: Item {
                    anchors.fill: parent

                    VideoOutput {
                        id: videoOutput
                        anchors.fill: parent
                        fillMode: VideoOutput.PreserveAspectCrop
                    }

                    AudioOutput {
                        id: mutedAudio
                        muted: true
                    }

                    MediaPlayer {
                        id: videoPlayer
                        source: root.fileUrl(backgroundWindow.currentPath)
                        audioOutput: mutedAudio
                        videoOutput: videoOutput
                        loops: MediaPlayer.Infinite

                        Component.onCompleted: play()
                        onSourceChanged: play()
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                color: "#000000"
                opacity: RaohaneState.screenLocked
                    ? RaohaneConfig.lockWallpaperDim
                    : RaohaneConfig.wallpaperDim

                Behavior on opacity {
                    NumberAnimation {
                        duration: 220
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                opacity: 0.045
                gradient: Gradient {
                    GradientStop { position: 0.0; color: RaohaneTheme.accent }
                    GradientStop { position: 0.28; color: "#00000000" }
                    GradientStop { position: 1.0; color: "#00000000" }
                }
            }
        }

        NumberAnimation {
            id: transitionAnimation
            target: backgroundWindow
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: RaohaneConfig.wallpaperTransitionDuration
            easing.type: Easing.InOutCubic
            onFinished: {
                backgroundWindow.previousPath = ""
                backgroundWindow.transitionProgress = 1.0
            }
        }
    }
}
