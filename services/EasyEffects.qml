pragma Singleton

import QtQuick

import qs.modules.raohane.services

// Temporary compatibility facade for inherited consumers. Process probing and
// lifecycle control are owned by RaohaneEasyEffects.
Singleton {
    readonly property bool available: RaohaneEasyEffects.available
    readonly property bool active: RaohaneEasyEffects.active

    function fetchAvailability(): void { RaohaneEasyEffects.fetchAvailability() }
    function fetchActiveState(): void { RaohaneEasyEffects.fetchActiveState() }
    function disable(): void { RaohaneEasyEffects.disable() }
    function enable(): void { RaohaneEasyEffects.enable() }
    function toggle(): void { RaohaneEasyEffects.toggle() }
    function launchUi(): void { RaohaneEasyEffects.launchUi() }
}
