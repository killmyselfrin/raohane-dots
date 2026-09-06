pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts

import qs.modules.raohane.services

Item {
    id: root

    property int currentPage: 0
    property int transitionDirection: 1
    property string pendingControl: ""
    property bool initialPageLoaded: false
    readonly property bool compactNav: width < 860
    readonly property var pages: RaohaneSettingsPageRegistry.pages
    readonly property var currentPageInfo: root.pages[root.currentPage] ?? null
    readonly property bool pageOwnsHeader: Boolean(root.currentPageInfo?.hideHeader)

    function showPage(pageKey: string, controlKey: string): void {
        const index = RaohaneSettingsPageRegistry.resolvePageIndex(pageKey)
        if (index < 0 || index >= root.pages.length)
            return
        root.pendingControl = String(controlKey ?? "")
        if (root.currentPage === index) {
            Qt.callLater(root.configureLoadedPage)
            return
        }
        root.transitionDirection = index > root.currentPage ? 1 : -1
        root.currentPage = index
    }

    function configureLoadedPage(): void {
        const page = root.currentPageInfo
        if (!pageLoader.item || !page)
            return
        if (pageLoader.item.hasOwnProperty("sectionKey"))
            pageLoader.item.sectionKey = page.key
        if (root.pendingControl !== "" && typeof pageLoader.item.goTo === "function")
            pageLoader.item.goTo(root.pendingControl)
        root.pendingControl = ""
    }

    function resolvedSource(source: string): string {
        const value = String(source ?? "")
        return value.length > 0 ? String(Qt.resolvedUrl(value)) : ""
    }

    function preparePageEnter(): void {
        pageFrame.opacity = 0
        pageFrame.x = root.transitionDirection * 14
        pageEnter.restart()
    }

    function loadCurrentPage(animated: bool): void {
        pageExit.stop()
        pageEnter.stop()

        const nextSource = String(root.currentPageInfo?.source ?? "")
        const sameSource = String(pageLoader.source) === root.resolvedSource(nextSource)

        if (!animated || !RaohaneMotion.enabled || String(pageLoader.source) === "") {
            pageFrame.opacity = 1
            pageFrame.x = 0
            if (sameSource && pageLoader.item)
                Qt.callLater(root.configureLoadedPage)
            else
                pageLoader.source = nextSource
            return
        }

        pageExit.restart()
    }

    onCurrentPageChanged: {
        if (root.currentPageInfo?.key === "about" && RaohaneSystemInfo.cpu === "")
            RaohaneSystemInfo.refresh()
        root.loadCurrentPage(root.initialPageLoaded)
    }

    Component.onCompleted: {
        pageLoader.source = root.currentPageInfo?.source ?? ""
        root.initialPageLoaded = true
    }

    Connections {
        target: RaohaneSettingsRouter

        function onPageRequested(pageKey: string, controlKey: string): void {
            root.showPage(pageKey, controlKey)
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        RaohaneSettingsNavigation {
            Layout.fillHeight: true
            Layout.preferredWidth: implicitWidth
            pages: root.pages
            currentPage: root.currentPage
            compact: root.compactNav
            onPageRequested: index => {
                if (index >= 0 && index < root.pages.length)
                    RaohaneSettingsRouter.request(root.pages[index].key, "")
            }
        }

        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            color: RaohaneTheme.borderFaint
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                RaohaneSettingsPageHeader {
                    Layout.fillWidth: true
                    Layout.preferredHeight: visible ? implicitHeight : 0
                    visible: !root.pageOwnsHeader
                    pageInfo: root.currentPageInfo
                    compact: root.compactNav
                }

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    Item {
                        id: pageFrame
                        anchors.fill: parent
                        opacity: 1

                        Loader {
                            id: pageLoader
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            anchors.bottomMargin: 10

                            onLoaded: {
                                Qt.callLater(root.configureLoadedPage)
                                if (!root.initialPageLoaded || !RaohaneMotion.enabled) {
                                    pageFrame.opacity = 1
                                    pageFrame.x = 0
                                    return
                                }
                                root.preparePageEnter()
                            }
                        }
                    }

                    ParallelAnimation {
                        id: pageExit

                        NumberAnimation {
                            target: pageFrame
                            property: "opacity"
                            from: 1
                            to: 0
                            duration: RaohaneMotion.micro
                            easing.type: RaohaneMotion.easeExit
                        }

                        NumberAnimation {
                            target: pageFrame
                            property: "x"
                            from: 0
                            to: -root.transitionDirection * 8
                            duration: RaohaneMotion.micro
                            easing.type: RaohaneMotion.easeExit
                        }

                        onFinished: {
                            const nextSource = String(root.currentPageInfo?.source ?? "")
                            if (nextSource === "") {
                                pageLoader.source = ""
                                pageFrame.x = 0
                                pageFrame.opacity = 1
                                return
                            }

                            if (String(pageLoader.source) === root.resolvedSource(nextSource) && pageLoader.item) {
                                root.configureLoadedPage()
                                root.preparePageEnter()
                            } else {
                                pageLoader.source = nextSource
                            }
                        }
                    }

                    ParallelAnimation {
                        id: pageEnter

                        NumberAnimation {
                            target: pageFrame
                            property: "opacity"
                            from: 0
                            to: 1
                            duration: RaohaneMotion.standard
                            easing.type: RaohaneMotion.easeStandard
                        }

                        NumberAnimation {
                            target: pageFrame
                            property: "x"
                            from: root.transitionDirection * 14
                            to: 0
                            duration: RaohaneMotion.relaxed
                            easing.type: RaohaneMotion.easeEmphasized
                        }
                    }
                }
            }
        }
    }
}
