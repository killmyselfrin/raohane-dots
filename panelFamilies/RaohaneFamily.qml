import QtQuick
import Quickshell

import qs.modules.common
import qs.modules.raohane
import qs.modules.ii.background
import qs.modules.ii.dock
import qs.modules.ii.lock
import qs.modules.ii.mediaControls
import qs.modules.ii.notificationPopup
import qs.modules.ii.onScreenKeyboard
import qs.modules.ii.overview
import qs.modules.ii.polkit
import qs.modules.ii.regionSelector
import qs.modules.ii.screenCorners
import qs.modules.ii.screenTranslator
import qs.modules.ii.sessionScreen
import qs.modules.ii.sidebarLeft
import qs.modules.ii.overlay
import qs.modules.ii.verticalBar
import qs.modules.ii.wallpaperSelector
import qs.modules.ii.desktopMenu
import qs.modules.ii.dropover
import qs.modules.ii.frame

// Raohane's stable panel family.
//
// The mature foundation stays underneath, while user-facing surfaces are
// replaced here one at a time with Raohane-native implementations.
Scope {
    Component.onCompleted: {
        // Keep the permanent dock/sidebar media widgets disabled. The mature
        // media backend remains available while Raohane-owned surfaces migrate.
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
    PanelLoader { component: NotificationPopup {} }
    PanelLoader { component: RaohaneOsd {} }
    PanelLoader { component: OnScreenKeyboard {} }
    PanelLoader { component: Overlay {} }
    PanelLoader { component: Overview {} }
    PanelLoader { component: Polkit {} }
    PanelLoader { component: RegionSelector {} }
    PanelLoader { component: ScreenCorners {} }
    PanelLoader { component: ScreenTranslator {} }
    PanelLoader { component: SessionScreen {} }
    PanelLoader { component: SidebarLeft {} }

    // Raohane-owned daily-driver surfaces.
    PanelLoader { component: RaohaneLauncher {} }
    PanelLoader { component: RaohaneControlCenter {} }
    PanelLoader { component: RaohaneSettings {} }
    PanelLoader { component: RaohaneMediaOverlay {} }

    PanelLoader { extraCondition: Config.options.bar.vertical; component: VerticalBar {} }
    PanelLoader { component: WallpaperSelector {} }
    PanelLoader { component: DesktopMenu {} }
    PanelLoader { component: DropShelfPanel {} }
    PanelLoader { component: NiriBackdrop {} }
    PanelLoader { component: ScreenFrame {} }
}
