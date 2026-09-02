import Quickshell

// Product-local lazy loader. Registered surfaces can opt into demand-driven
// loading later without changing RaohaneFamily composition. Current registry
// entries stay resident to preserve IPC/global-shortcut behavior while the
// architecture migrates incrementally.
LazyLoader {
    id: root

    property bool extraCondition: true
    property string surfaceId: ""
    readonly property var surfaceMetadata: surfaceId.length > 0
        ? RaohaneSurfaceRegistry.definition(surfaceId)
        : null
    readonly property bool registryValid: surfaceId.length === 0 || surfaceMetadata !== null
    readonly property bool resident: !surfaceMetadata || surfaceMetadata.loadPolicy === "resident"

    active: extraCondition
        && registryValid
        && (resident || RaohaneState.surfaceOpen(surfaceId))

    onRegistryValidChanged: {
        if (!registryValid)
            console.warn("[RaohanePanelLoader] Unknown surface id:", surfaceId)
    }
}
