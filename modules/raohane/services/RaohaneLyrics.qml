pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import QtQml
import Quickshell

Singleton {
    id: root

    property bool loading: false
    property bool instrumental: false
    property string plainLyrics: ""
    property var lines: []
    property string errorText: ""
    property string providerName: "LRCLIB"
    property string debugStatus: "idle"
    property int requestSerial: 0
    property var cache: ({})
    property var activeRequest: null

    readonly property bool syncedAvailable: lines.length > 0
    readonly property bool available: instrumental || syncedAvailable || plainLyrics.trim().length > 0
    readonly property int currentLineIndex: root.findCurrentLine(RaohaneMedia.position)
    readonly property var displayLines: syncedAvailable ? lines : root.makePlainLines(plainLyrics)

    function compactSpaces(value: string): string {
        return String(value ?? "").replace(/\s+/g, " ").trim()
    }

    function stripDecorators(value: string): string {
        return root.compactSpaces(String(value ?? "")
            .replace(/\s*[\[(](official\s+)?(audio|video|music\s+video|visuali[sz]er|lyrics?|lyric\s+video)[^\])]*[\])]/gi, "")
            .replace(/\s*[|·•]\s*(official\s+)?(audio|video|lyrics?|visuali[sz]er).*$/gi, ""))
    }

    function cleanArtist(value: string): string {
        return root.compactSpaces(root.stripDecorators(value)
            .replace(/\s*[-–—]\s*topic\s*$/i, "")
            .replace(/\s*[-–—]\s*vevo\s*$/i, "")
            .replace(/\s+topic\s*$/i, ""))
    }

    function cleanTitle(value: string): string {
        return root.stripDecorators(value)
    }

    function cleanAlbum(value: string): string {
        return root.stripDecorators(value)
    }

    function comparable(value: string): string {
        return root.compactSpaces(String(value ?? "")
            .toLowerCase()
            .replace(/[’‘`]/g, "'")
            .replace(/[^\p{L}\p{N}]+/gu, " "))
    }

    function metadata(): var {
        return {
            artist: root.cleanArtist(RaohaneMedia.artist),
            title: root.cleanTitle(RaohaneMedia.title),
            album: root.cleanAlbum(RaohaneMedia.album),
            duration: Math.round(Number(RaohaneMedia.length) || 0)
        }
    }

    function trackKey(meta): string {
        return [
            root.comparable(meta.artist),
            root.comparable(meta.title),
            meta.duration
        ].join("|")
    }

    function cancelRequest(): void {
        requestWatchdog.stop()
        if (root.activeRequest) {
            try { root.activeRequest.abort() } catch (error) {}
        }
        root.activeRequest = null
    }

    function clear(): void {
        root.cancelRequest()
        root.loading = false
        root.instrumental = false
        root.plainLyrics = ""
        root.lines = []
        root.errorText = ""
        root.debugStatus = "idle"
    }

    function scheduleLookup(): void {
        lookupTimer.restart()
    }

    function forceRefresh(): void {
        const meta = root.metadata()
        const key = root.trackKey(meta)
        if (Object.prototype.hasOwnProperty.call(root.cache, key))
            delete root.cache[key]
        root.lookup()
    }

    function lookup(): void {
        const meta = root.metadata()
        root.requestSerial += 1
        const serial = root.requestSerial

        root.cancelRequest()

        if (!RaohaneMedia.available || meta.artist.length === 0 || meta.title.length === 0) {
            root.clear()
            return
        }

        const key = root.trackKey(meta)
        const cached = root.cache[key]
        if (cached && root.recordMatches(cached, meta, false)) {
            root.applyRecord(cached, key, meta)
            return
        }

        root.loading = true
        root.instrumental = false
        root.plainLyrics = ""
        root.lines = []
        root.errorText = ""

        // Browser MPRIS metadata frequently has a useful artist/title but an
        // unreliable album/channel value. LRCLIB only requires artist/title,
        // so album is intentionally not part of lookup requests.
        root.requestExact(serial, key, meta, true)
    }

    function requestExact(serial: int, key: string, meta, withDuration: bool): void {
        if (serial !== root.requestSerial)
            return

        root.debugStatus = withDuration ? "exact-duration" : "exact"
        const params = [
            "artist_name=" + encodeURIComponent(meta.artist),
            "track_name=" + encodeURIComponent(meta.title)
        ]
        if (withDuration && meta.duration >= 1 && meta.duration <= 3600)
            params.push("duration=" + meta.duration)

        root.getJson(
            "https://lrclib.net/api/get?" + params.join("&"),
            serial,
            record => {
                if (root.recordMatches(record, meta, withDuration)) {
                    root.applyRecord(record, key, meta)
                    return
                }
                if (withDuration)
                    root.requestExact(serial, key, meta, false)
                else
                    root.requestStructuredSearch(serial, key, meta)
            },
            () => {
                if (withDuration)
                    root.requestExact(serial, key, meta, false)
                else
                    root.requestStructuredSearch(serial, key, meta)
            }
        )
    }

    function requestStructuredSearch(serial: int, key: string, meta): void {
        if (serial !== root.requestSerial)
            return

        root.debugStatus = "structured-search"
        const params = [
            "track_name=" + encodeURIComponent(meta.title),
            "artist_name=" + encodeURIComponent(meta.artist)
        ]

        root.getJson(
            "https://lrclib.net/api/search?" + params.join("&"),
            serial,
            records => {
                const best = root.chooseBestRecord(records, meta)
                if (best) {
                    root.applyRecord(best, key, meta)
                    return
                }
                root.requestLooseSearch(serial, key, meta)
            },
            () => root.requestLooseSearch(serial, key, meta)
        )
    }

    function requestLooseSearch(serial: int, key: string, meta): void {
        if (serial !== root.requestSerial)
            return

        root.debugStatus = "loose-search"
        const query = root.compactSpaces(meta.artist + " " + meta.title)
        root.getJson(
            "https://lrclib.net/api/search?q=" + encodeURIComponent(query),
            serial,
            records => {
                const best = root.chooseBestRecord(records, meta)
                if (best)
                    root.applyRecord(best, key, meta)
                else
                    root.finishNotFound(serial)
            },
            () => root.finishNotFound(serial)
        )
    }

    function hasLyrics(record): bool {
        return Boolean(record?.instrumental)
            || String(record?.syncedLyrics ?? "").trim().length > 0
            || String(record?.plainLyrics ?? "").trim().length > 0
    }

    function artistMatches(recordArtist: string, wantedArtist: string): bool {
        if (recordArtist === wantedArtist)
            return true

        // Allow collaborator suffixes only when the normalized base artist is
        // substantial enough to avoid matching unrelated short names.
        return (wantedArtist.length >= 5 && recordArtist.includes(wantedArtist))
            || (recordArtist.length >= 5 && wantedArtist.includes(recordArtist))
    }

    function recordMatches(record, meta, strictDuration: bool): bool {
        if (!record || !root.hasLyrics(record))
            return false

        const wantedTitle = root.comparable(meta.title)
        const wantedArtist = root.comparable(meta.artist)
        const recordTitle = root.comparable(root.cleanTitle(record.trackName ?? record.name ?? ""))
        const recordArtist = root.comparable(root.cleanArtist(record.artistName ?? ""))

        if (wantedTitle.length === 0 || wantedArtist.length === 0)
            return false
        if (recordTitle !== wantedTitle || !root.artistMatches(recordArtist, wantedArtist))
            return false

        const wantedDuration = Number(meta.duration) || 0
        const recordDuration = Number(record.duration) || 0
        if (strictDuration && wantedDuration > 0 && recordDuration > 0)
            return Math.abs(wantedDuration - recordDuration) <= 4

        return true
    }

    function chooseBestRecord(records, meta): var {
        if (!Array.isArray(records) || records.length === 0)
            return null

        const wantedAlbum = root.comparable(meta.album)
        const wantedDuration = Number(meta.duration) || 0
        let best = null
        let bestScore = Number.POSITIVE_INFINITY

        for (const record of records) {
            if (!root.recordMatches(record, meta, false))
                continue

            const recordAlbum = root.comparable(root.cleanAlbum(record.albumName ?? ""))
            const recordDuration = Number(record.duration) || 0
            let score = 0

            if (wantedDuration > 0 && recordDuration > 0) {
                const diff = Math.abs(wantedDuration - recordDuration)
                // Search endpoints can return another recording/version of the
                // same song. Reject large duration mismatches.
                if (diff > 10)
                    continue
                score += diff
            }

            if (wantedAlbum.length > 0 && recordAlbum === wantedAlbum)
                score -= 4
            if (String(record.syncedLyrics ?? "").trim().length > 0)
                score -= 2

            if (score < bestScore) {
                bestScore = score
                best = record
            }
        }

        return best
    }

    function getJson(url: string, serial: int, onSuccess, onNotFound): void {
        if (serial !== root.requestSerial)
            return

        root.cancelRequest()

        const request = new XMLHttpRequest()
        root.activeRequest = request
        request.open("GET", url)
        request.setRequestHeader("Accept", "application/json")
        request.setRequestHeader("Lrclib-Client", "Raohane/0.10.0-dev (https://github.com/killmyselfrin/raohane-dots)")
        request.onreadystatechange = function() {
            if (request.readyState !== 4 || serial !== root.requestSerial)
                return

            requestWatchdog.stop()
            if (root.activeRequest === request)
                root.activeRequest = null

            if (request.status === 200) {
                try {
                    onSuccess(JSON.parse(request.responseText))
                } catch (error) {
                    root.loading = false
                    root.debugStatus = "invalid-response"
                    root.errorText = qsTr("Lyrics response could not be read")
                }
                return
            }

            if (request.status === 404 || request.status === 400) {
                onNotFound()
                return
            }

            root.loading = false
            root.debugStatus = "http-error"
            root.errorText = request.status === 429
                ? qsTr("Lyrics service is busy. Try again shortly.")
                : qsTr("Could not load lyrics (HTTP %1)").arg(request.status)
        }
        requestWatchdog.restart()
        request.send()
    }

    function applyRecord(record, key: string, meta): void {
        if (!root.recordMatches(record, meta, false)) {
            root.finishNotFound(root.requestSerial)
            return
        }

        const compact = {
            trackName: String(record.trackName ?? record.name ?? ""),
            artistName: String(record.artistName ?? ""),
            albumName: String(record.albumName ?? ""),
            duration: Number(record.duration) || 0,
            instrumental: Boolean(record.instrumental),
            plainLyrics: String(record.plainLyrics ?? ""),
            syncedLyrics: String(record.syncedLyrics ?? "")
        }

        root.cache[key] = compact
        root.instrumental = compact.instrumental
        root.plainLyrics = compact.plainLyrics
        root.lines = root.parseSyncedLyrics(compact.syncedLyrics)
        root.loading = false
        root.errorText = ""
        root.debugStatus = "matched"
        console.info("[RaohaneLyrics] matched", compact.artistName, "-", compact.trackName, "duration", compact.duration)
    }

    function finishNotFound(serial: int): void {
        if (serial !== root.requestSerial)
            return

        root.cancelRequest()
        root.loading = false
        root.instrumental = false
        root.plainLyrics = ""
        root.lines = []
        root.debugStatus = "not-found"
        root.errorText = qsTr("Lyrics were not found for this track")
    }

    function parseSyncedLyrics(value: string): var {
        const result = []
        const rows = String(value ?? "").split(/\r?\n/)
        for (const row of rows) {
            const timestampPattern = /\[(\d{1,3}):(\d{2}(?:\.\d{1,3})?)\]/g
            const times = []
            let match = null
            while ((match = timestampPattern.exec(row)) !== null) {
                const minutes = Number(match[1]) || 0
                const seconds = Number(match[2]) || 0
                times.push(minutes * 60 + seconds)
            }
            if (times.length === 0)
                continue

            const text = row.replace(/\[[^\]]+\]/g, "").trim()
            if (text.length === 0)
                continue
            for (const time of times)
                result.push({ time: time, text: text })
        }
        result.sort((left, right) => left.time - right.time)
        return result
    }

    function makePlainLines(value: string): var {
        const result = []
        for (const row of String(value ?? "").split(/\r?\n/)) {
            const text = row.trim()
            if (text.length > 0)
                result.push({ time: -1, text: text })
        }
        return result
    }

    function findCurrentLine(position: real): int {
        if (!root.syncedAvailable)
            return -1
        const current = Number(position) || 0
        for (let index = root.lines.length - 1; index >= 0; --index) {
            if (current + 0.08 >= Number(root.lines[index].time))
                return index
        }
        return -1
    }

    Connections {
        target: RaohaneMedia

        function onTitleChanged(): void { root.scheduleLookup() }
        function onArtistChanged(): void { root.scheduleLookup() }
        function onAlbumChanged(): void { root.scheduleLookup() }
        function onLengthChanged(): void { root.scheduleLookup() }
        function onActivePlayerChanged(): void { root.scheduleLookup() }
    }

    Timer {
        id: lookupTimer
        interval: 450
        repeat: false
        onTriggered: root.lookup()
    }

    Timer {
        id: requestWatchdog
        interval: 12000
        repeat: false
        onTriggered: {
            if (root.activeRequest) {
                try { root.activeRequest.abort() } catch (error) {}
                root.activeRequest = null
            }
            root.loading = false
            root.debugStatus = "timeout"
            root.errorText = qsTr("Lyrics request timed out. Try refresh.")
        }
    }

    Component.onCompleted: root.scheduleLookup()
}
