import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.raohane
import qs.modules.ii.background
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
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
        // Force the temporary config bridge to exist before compatibility
        // surfaces begin reacting to native settings.
        RaohaneLegacyBridge.load()

        if (Config.options?.dock)
            Config.options.dock.showMedia = false
        if (Config.options?.sidebar)
            Config.options.sidebar.mediaPlayer = false
    }

    PanelLoader { extraCondition: !Config.options.bar.vertical; component: RaohaneBar {} }
    PanelLoader { component: Background {} }
    PanelLoader { extraCondition: Config.options.dock.enable; component: Dock {} }
    PanelLoader { component: Lock {} }
    PanelLoader { component: MediaControls {} }
    PanelLoader { component: RaohaneNotificationPopup {} }
    PanelLoader { component: RaohaneOsd {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Overview {} }
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
