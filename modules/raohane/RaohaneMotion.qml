pragma Singleton

import QtQuick
import qs.modules.raohane.services

QtObject {
    id: root

    // One motion language for the entire shell. The persisted Style Studio
    // scale stays authoritative; Scenes only apply a temporary cadence factor
    // and never rewrite the user's motion preference.
    readonly property real motionScale: RaohaneTheme.motionScale
    readonly property string sceneMotionHint: String(RaohaneScenes.activePolicy?.motionHint ?? "balanced")
    readonly property real sceneDurationFactor: sceneMotionHint === "fast" ? 0.72
        : sceneMotionHint === "quiet" ? 0.82
        : 1.0
    readonly property bool enabled: motionScale > 0.001

    // Transform motion is intentionally stricter than color/opacity motion.
    // Scale and translation force more scene-graph work on translucent shell
    // surfaces, so the reduced-motion end of Style Studio disables those
    // transforms while still allowing cheap visual feedback to remain useful.
    // Scene cadence does not alter this threshold; Gaming's Game Mode remains
    // responsible for disabling expensive transforms where appropriate.
    readonly property bool transformMotionEnabled: motionScale > 0.05

    readonly property int micro: Math.max(0, Math.round(RaohaneTheme.animationFast * sceneDurationFactor))
    readonly property int standard: Math.max(0, Math.round(RaohaneTheme.animationDuration * sceneDurationFactor))
    readonly property int relaxed: Math.max(0, Math.round(RaohaneTheme.animationSlow * sceneDurationFactor))
    readonly property int enter: Math.max(0, Math.round(RaohaneTheme.animationSlow * 1.08 * sceneDurationFactor))

    // Small cadence used by Settings and other dense surfaces. Keep the delay
    // short enough that staggered content still feels immediate rather than
    // theatrical. It scales with the user's persisted motion preference and
    // the temporary Scene cadence.
    readonly property int staggerStep: Math.max(0, Math.round(22 * motionScale * sceneDurationFactor))
    readonly property int selectionTravel: Math.max(1, Math.round(standard * 1.08))

    // Compatibility aliases used by larger surfaces. Keeping these aliases here
    // prevents individual components from inventing their own timing language.
    readonly property int shortDuration: micro
    readonly property int mediumDuration: standard
    readonly property int longDuration: relaxed

    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutQuart
    readonly property int easeEnter: Easing.OutQuart
    readonly property int easeExit: Easing.InCubic

    readonly property real pressScale: 0.968
    readonly property real softPressScale: 0.984
    readonly property real hoverScale: 1.01
    readonly property real subtleHoverScale: 1.004
    readonly property real disabledOpacity: 0.42
}
