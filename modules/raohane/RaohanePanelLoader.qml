import Quickshell

// Product-local lazy loader. RaohaneFamily is instantiated only after the
// native RaohaneConfig is ready, so individual surfaces can stay focused on
// their own visibility/runtime conditions.
LazyLoader {
    property bool extraCondition: true
    active: extraCondition
}
