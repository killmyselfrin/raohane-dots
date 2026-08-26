pragma Singleton

import QtQuick
import Quickshell

Singleton {
    // Raohane installs a system Material Symbols provider through the Arch
    // dependency manifest. Do not rely on a vendored font file.
    property string iconMaterialFamily: "Material Symbols Rounded"
}
