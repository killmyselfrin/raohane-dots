import QtQuick
import Quickshell

import qs.modules.raohane
import qs.modules.raohane.config
import qs.modules.raohane.services

// Raohane's Hyprland integration composition. The active family resolves only
// Raohane-owned presentation and service types at shell startup. Stateful
// product surfaces bind to stable registry ids so state, lifecycle policy and
// future placement metadata have one shared identity.
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
    RaohanePanelLoader { surfaceId: "osd"; component: RaohaneOsd {} }
    RaohanePanelLoader { surfaceId: "osk"; component: RaohaneOnScreenKeyboard {} }
    RaohanePanelLoader { surfaceId: "overlay"; component: RaohaneOverlay {} }
    RaohanePanelLoader { surfaceId: "overview"; component: RaohaneOverview {} }
    RaohanePanelLoader { component: RaohanePolkit {} }
    RaohanePanelLoader { surfaceId: "regionSelector"; component: RaohaneRegionSelector {} }
    RaohanePanelLoader { component: RaohaneScreenCorners {} }
    RaohanePanelLoader { surfaceId: "screenTranslator"; component: RaohaneScreenTranslator {} }
    RaohanePanelLoader { surfaceId: "leftSidebar"; component: RaohaneSidebarLeft {} }

    RaohanePanelLoader { surfaceId: "launcher"; component: RaohaneLauncher {} }
    RaohanePanelLoader { surfaceId: "controlCenter"; component: RaohaneControlCenter {} }
    RaohanePanelLoader { surfaceId: "settings"; component: RaohaneSettings {} }
    RaohanePanelLoader { surfaceId: "displaySettings"; component: RaohaneDisplaySettings {} }
    RaohanePanelLoader { surfaceId: "welcome"; component: RaohaneWelcome {} }
    RaohanePanelLoader { component: RaohaneLanguageWelcome {} }
    RaohanePanelLoader { component: RaohaneOnboarding {} }
    RaohanePanelLoader { surfaceId: "mediaOverlay"; component: RaohaneMediaOverlay {} }
    RaohanePanelLoader { surfaceId: "wallpaper"; component: RaohaneWallpaperSelector {} }
    RaohanePanelLoader { surfaceId: "desktopMenu"; component: RaohaneDesktopMenu {} }
    RaohanePanelLoader { surfaceId: "session"; component: RaohaneSessionScreen {} }
    RaohanePanelLoader { surfaceId: "taskManager"; component: RaohaneTaskManager {} }

    RaohanePanelLoader { component: RaohaneDropShelfPanel {} }
    RaohanePanelLoader { component: RaohaneScreenFrame {} }
}
