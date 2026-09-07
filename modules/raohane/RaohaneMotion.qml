pragma Singleton

import QtQuick

QtObject {
    id: root

    // One motion language for the entire shell. Durations respect the
    // persisted Style Studio motion scale through RaohaneTheme.
    readonly property real motionScale: RaohaneTheme.motionScale
    readonly property bool enabled: motionScale > 0.001

    // Transform motion is intentionally stricter than color/opacity motion.
    // Scale and translation force more scene-graph work on translucent shell
    // surfaces, so the reduced-motion end of Style Studio disables those
    // transforms while still allowing cheap visual feedback to remain useful.
    readonly property bool transformMotionEnabled: motionScale > 0.05

    readonly property int micro: RaohaneTheme.animationFast
    readonly property int standard: RaohaneTheme.animationDuration
    readonly property int relaxed: RaohaneTheme.animationSlow
    readonly property int enter: Math.round(RaohaneTheme.animationSlow * 1.08)

    // Small cadence used by Settings and other dense surfaces. Keep the delay
    // short enough that staggered content still feels immediate rather than
    // theatrical. It scales with the user's persisted motion preference.
    readonly property int staggerStep: Math.max(0, Math.round(22 * motionScale))
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