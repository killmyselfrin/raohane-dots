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

    Timer {
        interval: Math.max(1000, RaohaneConfig.wallpaperChangeInterval)
        running: RaohaneConfig.wallpaperChangeInterval > 0
            && !RaohaneState.screenLocked
        repeat: true
        onTriggered: RaohaneWallpapers.autoAdvance()
    }

    PanelWindow {
        id: backgroundWindow

        required property var modelData

        readonly property HyprlandMonitor monitor: Hyprland.monitorFor(modelData)
        // Hyprland already exposes fullscreen state on the active workspace.
        // Avoid filtering every workspace and walking every toplevel whenever
        // the compositor model changes; Background is resident for the session.
        readonly property bool activeWorkspaceFullscreen: backgroundWindow.monitor?.activeWorkspace?.hasFullscreen ?? false
        readonly property bool hiddenForFullscreen: RaohaneConfig.wallpaperHideWhenFullscreen
            && !RaohaneState.screenLocked
            && backgroundWindow.activeWorkspaceFullscreen

        readonly property string requestedPath: {
            if (RaohaneState.screenLocked && RaohaneConfig.lockWallpaperPath.length > 0)
                return RaohaneConfig.lockWallpaperPath
            if (RaohaneConfig.wallpaperPreview && RaohaneWallpapers.previewPath.length > 0
                    && (RaohaneWallpapers.previewScreenName.length === 0
                        || RaohaneWallpapers.previewScreenName === String(modelData.name)))
                return RaohaneWallpapers.previewPath
            // Monitor overrides are optional and fall back to the existing
            // global wallpaper. A configured monitor keeps its own background
            // even when other outputs change or the global slideshow runs.
            const configured = RaohaneConfig.wallpaperPathForScreen(String(modelData.name))
            return configured.length > 0 ? configured : RaohanePaths.defaultWallpaperPath
        }

        property string currentPath: ""
        property string previousPath: ""
        property real transitionProgress: 1.0

        readonly property bool currentIsVideo: RaohaneWallpapers.isVideo(currentPath)
        readonly property bool previewingVideo: currentIsVideo
            && RaohaneConfig.wallpaperPreview
            && RaohaneWallpapers.previewPath === currentPath
            && (RaohaneWallpapers.previewScreenName.length === 0
                || RaohaneWallpapers.previewScreenName === String(modelData.name))
        readonly property bool previousIsVideo: RaohaneWallpapers.isVideo(previousPath)

        readonly property int transitionDuration: RaohaneMotion.panelMotionEnabled
            ? Math.round(RaohaneConfig.wallpaperTransitionDuration * RaohaneTheme.motionScale) : 0

        function switchToRequestedPath(): void {
            // Finish the current dissolve, then consume the latest request.
            // Rapid selections do not promote a half-visible frame to the back layer.
            if (transitionAnimation.running)
                return
            // Keep the visible image until the replacement is decoded.
            if (!RaohaneWallpapers.isVideo(requestedPath)
                    && requestedPath.length > 0
                    && (pendingImage.source.toString() !== root.fileUrl(requestedPath)
                        || pendingImage.status !== Image.Ready))
                return
            if (requestedPath === currentPath)
                return

            transitionAnimation.stop()
            previousPath = currentPath
            currentPath = requestedPath

            if (transitionDuration <= 0 || previousPath.length === 0 || currentPath.length === 0) {
                previousPath = ""
                transitionProgress = 1.0
                return
            }

            transitionProgress = 0.0
            transitionAnimation.restart()
        }

        onRequestedPathChanged: switchToRequestedPath()
        Component.onCompleted: switchToRequestedPath()

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

            // Preload only the requested still; stale loads cannot commit a path.
            Image {
                id: pendingImage
                visible: false
                source: backgroundWindow.requestedPath.length > 0
                    && !RaohaneWallpapers.isVideo(backgroundWindow.requestedPath)
                    ? root.fileUrl(backgroundWindow.requestedPath) : ""
                asynchronous: true
                cache: true
                onStatusChanged: {
                    if (status === Image.Ready)
                        backgroundWindow.switchToRequestedPath()
                }
            }

            Image {
                id: previousImage
                anchors.fill: parent
                visible: backgroundWindow.previousPath.length > 0 && !backgroundWindow.previousIsVideo
                source: backgroundWindow.previousPath.length > 0 && !backgroundWindow.previousIsVideo
                    ? root.fileUrl(backgroundWindow.previousPath)
                    : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: true
                smooth: true
                // Keep the old image opaque beneath the incoming image: fading
                // both layers exposes the dark canvas halfway through.
                opacity: 1.0
            }

            Image {
                id: currentImage
                anchors.fill: parent
                visible: backgroundWindow.currentPath.length > 0 && !backgroundWindow.currentIsVideo
                source: backgroundWindow.currentPath.length > 0 && !backgroundWindow.currentIsVideo
                    ? root.fileUrl(backgroundWindow.currentPath)
                    : ""
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

                    MediaPlayer {
                        id: videoPlayer
                        source: root.fileUrl(backgroundWindow.currentPath)
                        videoOutput: videoOutput
                        loops: MediaPlayer.Infinite

                        // Wallpaper audio is never part of the desktop experience.
                        // Muting an AudioOutput still makes FFmpeg decode the audio
                        // stream, which wastes work and can spam timestamp warnings on
                        // imperfect MP4 loops. Disable the track at the player level.
                        activeAudioTrack: -1
                        onTracksChanged: activeAudioTrack = -1

                        Component.onCompleted: {
                            play()
                            if (backgroundWindow.previewingVideo && RaohaneWallpapers.videoPreviewPaused)
                                Qt.callLater(() => videoPlayer.pause())
                        }
                        onSourceChanged: play()
                    }

                    // MediaPlayer has no default child-object property. Keep
                    // this signal subscription alongside the player under Item.
                    Connections {
                        target: RaohaneWallpapers
                        function onVideoPreviewPausedChanged(): void {
                            if (!backgroundWindow.previewingVideo)
                                return
                            if (RaohaneWallpapers.videoPreviewPaused)
                                videoPlayer.pause()
                            else
                                videoPlayer.play()
                        }
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

        // Right-click on uncovered wallpaper opens the native desktop menu.
        // This area accepts only the secondary button; ordinary clicks still
        // pass through to normal wallpaper/desktop behavior.
        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            enabled: !RaohaneState.screenLocked && !backgroundWindow.hiddenForFullscreen
            onClicked: mouse => {
                RaohaneState.desktopMenuScreen = backgroundWindow.modelData
                RaohaneState.desktopMenuX = mouse.x
                RaohaneState.desktopMenuY = mouse.y
                RaohaneState.desktopMenuWidgetId = ""
                RaohaneState.desktopMenuWidgetMonitor = ""
                RaohaneState.setPrimaryOpen("desktopMenu", true)
            }
        }

        NumberAnimation {
            id: transitionAnimation
            target: backgroundWindow
            property: "transitionProgress"
            from: 0.0
            to: 1.0
            duration: backgroundWindow.transitionDuration
            easing.type: Easing.InOutCubic
            onFinished: {
                backgroundWindow.previousPath = ""
                backgroundWindow.transitionProgress = 1.0
                backgroundWindow.switchToRequestedPath()
            }
        }
    }
}
