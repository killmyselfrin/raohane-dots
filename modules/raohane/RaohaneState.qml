pragma Singleton

import QtQuick

// Raohane-owned cross-surface state. Keep product-specific state here instead
// of GlobalStates.qml because the foundation synchronizer refreshes that file
// from end4-pC.
QtObject {
    property bool mediaOverlayOpen: false
}
