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
            bar: {
                open: RaohaneState.barOpen,
                vertical: RaohaneConfig.barVertical,
                autoHide: RaohaneConfig.barAutoHide,
                showOnSuper: RaohaneConfig.barShowOnSuper
            },
            lock: {
                locked: RaohaneState.screenLocked
            },
            settings: {
                open: RaohaneState.settingsOpen
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
                screenTranslatorOpen: RaohaneState.screenTranslatorOpen
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
