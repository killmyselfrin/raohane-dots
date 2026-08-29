import QtQuick
import Quickshell

import qs.modules.raohane
import qs.modules.raohane.config
import qs.modules.raohane.services

// Raohane's Hyprland integration composition. The active family resolves only
// Raohane-owned presentation and service types at shell startup.
Scope {
    Component.onCompleted: RaohaneAutostart.runOnce()

    RaohanePanelLoader { component: RaohaneRuntimeProbe {} }
    RaohanePanelLoader { component: RaohaneBackground {} }
    RaohanePanelLoader { component: RaohaneDesktopCanvas {} }
    RaohanePanelLoader { extraCondition: !RaohaneConfig.barVertical; component: RaohaneBar {} }
    RaohanePanelLoader { extraCondition: RaohaneConfig.barVertical; component: RaohaneVerticalBar {} }
    RaohanePanelLoader { extraCondition: RaohaneConfig.dockEnabled; component: RaohaneDock {} }
    RaohanePanelLoader { component: RaohaneLock {} }
    RaohanePanelLoader { component: RaohaneNotificationPopup {} }
    RaohanePanelLoader { component: RaohaneOsd {} }
    RaohanePanelLoader { component: RaohaneOnScreenKeyboard {} }
    RaohanePanelLoader { component: RaohaneOverlay {} }
    RaohanePanelLoader { component: RaohaneOverview {} }
    RaohanePanelLoader { component: RaohanePolkit {} }
    RaohanePanelLoader { component: RaohaneRegionSelector {} }
    RaohanePanelLoader { component: RaohaneScreenCorners {} }
    RaohanePanelLoader { component: RaohaneScreenTranslator {} }
    RaohanePanelLoader { component: RaohaneSidebarLeft {} }

    RaohanePanelLoader { component: RaohaneLauncher {} }
    RaohanePanelLoader { component: RaohaneControlCenter {} }
    RaohanePanelLoader { component: RaohaneSettings {} }
    RaohanePanelLoader { component: RaohaneMediaOverlay {} }
    RaohanePanelLoader { component: RaohaneWallpaperSelector {} }
    RaohanePanelLoader { component: RaohaneDesktopMenu {} }
    RaohanePanelLoader { component: RaohaneSessionScreen {} }

    RaohanePanelLoader { component: RaohaneDropShelfPanel {} }
    RaohanePanelLoader { component: RaohaneScreenFrame {} }
}
