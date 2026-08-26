import Quickshell

// Product-local lazy loader. RaohaneFamily itself is instantiated only after
// the compatibility Config is ready, so individual native surfaces do not need
// to re-import Config/Appearance just to decide whether they may be created.
LazyLoader {
    property bool extraCondition: true
    active: extraCondition
}
