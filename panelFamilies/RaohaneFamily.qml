import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.raohane
import qs.modules.raohane.config
import qs.modules.ii.lock
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.polkit
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
    Component.onCompleted: {
        RaohaneLegacyBridge.load()

        if (Config.options?.sidebar)
            Config.options.sidebar.mediaPlayer = false
    }

    PanelLoader { component: RaohaneBackground {} }
    PanelLoader { component: RaohaneDesktopCanvas {} }
    PanelLoader { extraCondition: !Config.options.bar.vertical; component: RaohaneBar {} }
    PanelLoader { extraCondition: RaohaneConfig.dockEnabled; component: RaohaneDock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: RaohaneNotificationPopup {} }
    PanelLoader { component: RaohaneOsd {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: RaohaneOverview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SidebarLeft {} }

    PanelLoader { component: RaohaneLauncher {} }
    PanelLoader { component: RaohaneControlCenter {} }
    PanelLoader { component: RaohaneSettings {} }
    PanelLoader { component: RaohaneMediaOverlay {} }
    PanelLoader { component: RaohaneWallpaperSelector {} }
    PanelLoader { component: RaohaneDesktopMenu {} }
    PanelLoader { component: RaohaneSessionScreen {} }

    PanelLoader { extraCondition: Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { component: DropShelfPanel {} }
    PanelLoader { component: ScreenFrame {} }
}
