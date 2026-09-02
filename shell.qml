//@ pragma UseQApplication
//@ pragma Env QS_NO_RELOAD_POPUP=1
//@ pragma Env QT_QUICK_CONTROLS_STYLE=Basic
//@ pragma Env QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
////@ pragma Env QT_SCALE_FACTOR=1

import "modules/raohane/config"
import "panelFamilies"
import QtQuick
import Quickshell
import qs.modules.raohane.services

// Raohane is now the only startup family. Legacy panel families and services
// may remain in the repository while migration is in progress, but they must
// not be resolved by the QML engine during shell bootstrap.
ShellRoot {
    RaohaneLoginWallpaperSync {
        active: RaohaneConfig.ready
    }

    LazyLoader {
        active: RaohaneConfig.ready
        component: RaohaneFamily {}
    }
}
