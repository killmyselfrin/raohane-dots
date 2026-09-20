import QtQuick
import Quickshell

// Product-local lazy loader. Surface lifetime is declared in
// RaohaneSurfaceRegistry: resident surfaces keep global entrypoints alive,
// while on-demand surfaces are instantiated only while their runtime state is
// open. Surfaces with deferredUnload stay alive for one relaxed motion cycle
// after state closes so their own exit animation can finish before destruction.
LazyLoader {
    id: root

    property bool extraCondition: true
    property string surfaceId: ""
    property bool unloadHeld: false

    readonly property var surfaceMetadata: surfaceId.length > 0
        ? RaohaneSurfaceRegistry.definition(surfaceId)
        : null
    readonly property bool registryValid: surfaceId.length === 0 || surfaceMetadata !== null
    readonly property string loadPolicy: surfaceMetadata?.loadPolicy ?? "resident"
    readonly property bool policyValid: loadPolicy === "resident" || loadPolicy === "on-demand"
    readonly property bool resident: loadPolicy === "resident"
    readonly property bool surfaceRequested: surfaceId.length === 0
        || RaohaneState.surfaceOpen(surfaceId)
    readonly property bool deferredUnload: surfaceMetadata?.deferredUnload === true
    readonly property int unloadDelay: deferredUnload
        ? Math.max(100, RaohaneMotion.relaxed + 40)
        : 0

    property Timer unloadTimer: Timer {
        interval: root.unloadDelay
        repeat: false
        onTriggered: root.unloadHeld = false
    }

    active: extraCondition
        && registryValid
        && policyValid
        && (resident || surfaceRequested || unloadHeld)

    Component.onCompleted: root.unloadHeld = !resident && surfaceRequested

    onSurfaceRequestedChanged: {
        if (resident)
            return

        if (surfaceRequested) {
            root.unloadTimer.stop()
            unloadHeld = true
            return
        }

        if (deferredUnload && unloadHeld) {
            root.unloadTimer.restart()
            return
        }

        unloadHeld = false
    }

    onRegistryValidChanged: {
        if (!registryValid)
            console.warn("[RaohanePanelLoader] Unknown surface id:", surfaceId)
    }

    onPolicyValidChanged: {
        if (!policyValid)
            console.warn("[RaohanePanelLoader] Invalid load policy:", loadPolicy, "for", surfaceId)
    }
}
