import Quickshell

// Product-local lazy loader. Surface lifetime is declared in
// RaohaneSurfaceRegistry: resident surfaces keep global entrypoints alive,
// while on-demand surfaces are instantiated only while their runtime state is
// open. Unknown policies fail closed instead of silently changing lifecycle.
LazyLoader {
    id: root

    property bool extraCondition: true
    property string surfaceId: ""
    readonly property var surfaceMetadata: surfaceId.length > 0
        ? RaohaneSurfaceRegistry.definition(surfaceId)
        : null
    readonly property bool registryValid: surfaceId.length === 0 || surfaceMetadata !== null
    readonly property string loadPolicy: surfaceMetadata?.loadPolicy ?? "resident"
    readonly property bool policyValid: loadPolicy === "resident" || loadPolicy === "on-demand"
    readonly property bool resident: loadPolicy === "resident"

    active: extraCondition
        && registryValid
        && policyValid
        && (resident || RaohaneState.surfaceOpen(surfaceId))

    onRegistryValidChanged: {
        if (!registryValid)
            console.warn("[RaohanePanelLoader] Unknown surface id:", surfaceId)
    }

    onPolicyValidChanged: {
        if (!policyValid)
            console.warn("[RaohanePanelLoader] Invalid load policy:", loadPolicy, "for", surfaceId)
    }
}
