pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io

import qs.modules.raohane.config
import qs.modules.raohane.services

Scope {
    id: root

    function monitorSnapshot(): var {
        return Quickshell.screens.map(screen => {
            const monitor = Hyprland.monitorFor(screen)
            const specialName = String(monitor?.lastIpcObject?.specialWorkspace?.name ?? "")
            return {
                name: String(screen.name ?? ""),
                width: Number(screen.width ?? 0),
                height: Number(screen.height ?? 0),
                workspace: Number(monitor?.activeWorkspace?.id ?? 0),
                fullscreen: Boolean(monitor?.activeWorkspace?.hasFullscreen ?? false),
                specialWorkspace: specialName
            }
        })
    }

    function phase4Snapshot(): var {
        return {
            ready: RaohaneConfig.ready,
            monitors: root.monitorSnapshot(),
            focusedMonitor: String(Hyprland.focusedMonitor?.name ?? ""),
            scenes: {
                ready: RaohaneScenes.ready,
                selected: RaohaneScenes.selectedSceneId,
                active: RaohaneScenes.activeSceneId,
                source: RaohaneScenes.activationSource,
                activeAppId: RaohaneScenes.activeAppId,
                autoSwitch: RaohaneScenes.autoSwitchEnabled,
                autoScene: RaohaneScenes.autoSceneActive,
                manualOverride: RaohaneScenes.manualOverride,
                policy: RaohaneScenes.activePolicy
            },
            bar: {
                open: RaohaneState.barOpen,
                vertical: RaohaneConfig.barVertical,
                autoHide: RaohaneConfig.barAutoHide,
                showOnSuper: RaohaneConfig.barShowOnSuper
            },
            controlCenter: {
                open: RaohaneState.controlCenterOpen,
                dnd: RaohaneNotifications.silent
            },
            quickControls: {
                wifi: {
                    enabled: RaohaneNetwork.wifiEnabled,
                    connected: RaohaneNetwork.wifiConnected,
                    busy: RaohaneNetwork.wifiBusy,
                    error: RaohaneNetwork.wifiToggleError
                },
                bluetooth: {
                    available: RaohaneBluetooth.available,
                    enabled: RaohaneBluetooth.enabled,
                    connected: RaohaneBluetooth.connected,
                    busy: RaohaneBluetooth.busy,
                    error: RaohaneBluetooth.lastError
                },
                easyEffects: {
                    available: RaohaneEasyEffects.available,
                    active: RaohaneEasyEffects.active,
                    busy: RaohaneEasyEffects.busy,
                    error: RaohaneEasyEffects.lastError
                },
                keepAwake: RaohaneIdle.inhibit
            },
            performance: {
                gameMode: RaohanePerformance.gameModeActive,
                busy: RaohanePerformance.busy,
                error: RaohanePerformance.lastError
            },
            context: {
                mode: RaohaneContext.mode,
                title: RaohaneContext.title,
                detail: RaohaneContext.detail,
                tone: RaohaneContext.eventTone,
                progress: RaohaneContext.eventProgress
            },
            lock: {
                locked: RaohaneState.screenLocked
            },
            settings: {
                open: RaohaneState.settingsOpen
            },
            tasks: {
                open: RaohaneState.taskManagerOpen,
                busy: RaohaneProcesses.busy,
                processCount: RaohaneProcesses.processes.length,
                generation: RaohaneProcesses.generation
            },
            media: {
                available: RaohaneMedia.available,
                playing: RaohaneMedia.isPlaying,
                title: RaohaneMedia.title,
                artist: RaohaneMedia.artist,
                player: RaohaneMedia.playerName
            },
            lyrics: {
                loading: RaohaneLyrics.loading,
                available: RaohaneLyrics.available,
                synced: RaohaneLyrics.syncedAvailable,
                status: RaohaneLyrics.debugStatus,
                error: RaohaneLyrics.errorText
            },
            chrome: {
                frameEnabled: RaohaneConfig.frameEnabled,
                roundingMode: RaohaneConfig.screenRoundingMode,
                hotCornersEnabled: RaohaneConfig.hotCornersEnabled,
                overlayOpen: RaohaneState.overlayOpen,
                oskOpen: RaohaneState.oskOpen,
                sidebarLeftOpen: RaohaneState.leftSidebarOpen,
                dropShelfOpen: RaohaneDropShelf.open
            },
            capture: {
                regionSelectorOpen: RaohaneState.regionSelectorOpen,
                screenTranslatorOpen: RaohaneState.screenTranslatorOpen,
                recorder: {
                    available: RaohaneRecorder.available,
                    recording: RaohaneRecorder.recording,
                    owned: RaohaneRecorder.ownedRecording,
                    mode: RaohaneRecorder.captureMode,
                    sound: RaohaneRecorder.captureSound,
                    elapsed: RaohaneRecorder.elapsedSeconds,
                    error: RaohaneRecorder.lastError
                }
            }
        }
    }

    IpcHandler {
        target: "runtime"

        function phase4(): string {
            return JSON.stringify(root.phase4Snapshot())
        }

        function monitors(): string {
            return JSON.stringify(root.monitorSnapshot())
        }

        function ready(): string {
            return RaohaneConfig.ready ? "ready" : "loading"
        }
    }
}
