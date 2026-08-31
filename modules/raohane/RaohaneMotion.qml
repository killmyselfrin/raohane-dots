pragma Singleton

import QtQuick

QtObject {
    id: root

    // One motion language for the entire shell. Durations still respect the
    // persisted Style Studio motion scale through RaohaneTheme. Expose the
    // scale here too so shared interaction primitives have an explicit motion
    // contract without duplicating duration math.
    readonly property real motionScale: RaohaneTheme.motionScale
    readonly property int micro: RaohaneTheme.animationFast
    readonly property int standard: RaohaneTheme.animationDuration
    readonly property int relaxed: RaohaneTheme.animationSlow
    readonly property int enter: Math.round(RaohaneTheme.animationSlow * 1.18)

    readonly property int easeStandard: Easing.OutCubic
    readonly property int easeEmphasized: Easing.OutQuart
    readonly property int easeEnter: Easing.OutBack
    readonly property int easeExit: Easing.InCubic

    readonly property real pressScale: 0.965
    readonly property real softPressScale: 0.982
    readonly property real hoverScale: 1.012
    readonly property real subtleHoverScale: 1.006
    readonly property real disabledOpacity: 0.42
}
