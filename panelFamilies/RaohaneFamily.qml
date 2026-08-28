import QtQuick
import Quickshell

import qs.modules.raohane
import qs.modules.raohane.config
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sidebarLeft
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.dropover
import qs.modules.ii.frame

// Raohane's Hyprland integration composition. Compatibility panels remain
// temporary while their presentation layers are rewritten under modules/raohane.
Scope {
    Component.onCompleted: RaohaneLegacyBridge.load()

    RaohanePanelLoader { component: RaohaneBackground {} }
    RaohanePanelLoader { component: RaohaneDesktopCanvas {} }
    RaohanePanelLoader { extraCondition: !RaohaneConfig.barVertical; component: RaohaneBar {} }
    RaohanePanelLoader { extraCondition: RaohaneConfig.dockEnabled; component: RaohaneDock {} }
    RaohanePanelLoader { component: RaohaneLock {} }
    RaohanePanelLoader { component: RaohaneNotificationPopup {} }
    RaohanePanelLoader { component: RaohaneOsd {} }
    RaohanePanelLoader { component: OnScreenKeyboard {} }
    RaohanePanelLoader { component: Overlay {} }
    RaohanePanelLoader { component: RaohaneOverview {} }
    RaohanePanelLoader { component: RaohanePolkit {} }
    RaohanePanelLoader { component: RegionSelector {} }
    RaohanePanelLoader { component: ScreenCorners {} }
    RaohanePanelLoader { component: ScreenTranslator {} }
    RaohanePanelLoader { component: SidebarLeft {} }

    RaohanePanelLoader { component: RaohaneLauncher {} }
    RaohanePanelLoader { component: RaohaneControlCenter {} }
    RaohanePanelLoader { component: RaohaneSettings {} }
    RaohanePanelLoader { component: RaohaneMediaOverlay {} }
    RaohanePanelLoader { component: RaohaneWallpaperSelector {} }
    RaohanePanelLoader { component: RaohaneDesktopMenu {} }
    RaohanePanelLoader { component: RaohaneSessionScreen {} }

    RaohanePanelLoader { extraCondition: RaohaneConfig.barVertical; component: VerticalBar {} }
    RaohanePanelLoader { component: DropShelfPanel {} }
    RaohanePanelLoader { component: ScreenFrame {} }
}
