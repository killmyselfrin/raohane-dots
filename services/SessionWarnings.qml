pragma Singleton

import Quickshell
import qs.modules.raohane.services

Singleton {
    readonly property bool packageManagerRunning: RaohaneSessionWarnings.packageManagerRunning
    readonly property bool downloadRunning: RaohaneSessionWarnings.downloadRunning

    function refresh(): void {
        RaohaneSessionWarnings.refresh()
    }
}
