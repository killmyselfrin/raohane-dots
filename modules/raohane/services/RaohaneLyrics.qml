pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

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

    function clear(): void {
        resolver.running = false
        requestWatchdog.stop()
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

        resolver.running = false
        requestWatchdog.stop()

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
        root.debugStatus = "resolving"

        resolver.serialToken = serial
        resolver.keyToken = key
        resolver.metaToken = meta
        resolver.command = [
            "python3",
            Quickshell.shellPath("scripts/lyrics-resolve.py"),
            meta.artist,
            meta.title,
            meta.album,
            String(meta.duration)
        ]
        resolver.running = true
        requestWatchdog.restart()
    }

    function hasLyrics(record): bool {
        return Boolean(record?.instrumental)
            || String(record?.syncedLyrics ?? "").trim().length > 0
            || String(record?.plainLyrics ?? "").trim().length > 0
    }

    function artistMatches(recordArtist: string, wantedArtist: string): bool {
        if (recordArtist === wantedArtist)
            return true
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

    function applyResolverPayload(serial: int, key: string, meta, payload: string): void {
        if (serial !== root.requestSerial)
            return

        requestWatchdog.stop()
        root.loading = false

        let result = null
        try {
            result = JSON.parse(String(payload ?? "").trim())
        } catch (error) {
            root.debugStatus = "invalid-response"
            root.errorText = qsTr("Lyrics resolver returned invalid data")
            return
        }

        root.debugStatus = String(result?.status ?? "resolver-error")
        if (!result?.ok) {
            root.instrumental = false
            root.plainLyrics = ""
            root.lines = []
            root.errorText = root.debugStatus === "network-error"
                ? qsTr("Lyrics service could not be reached. Try refresh.")
                : qsTr(String(result?.error ?? "Lyrics were not found for this track"))
            return
        }

        const record = result.record
        if (!root.recordMatches(record, meta, false)) {
            root.instrumental = false
            root.plainLyrics = ""
            root.lines = []
            root.debugStatus = "identity-mismatch"
            root.errorText = qsTr("Lyrics were not found for this track")
            return
        }

        root.applyRecord(record, key, meta)
    }

    function applyRecord(record, key: string, meta): void {
        if (!root.recordMatches(record, meta, false)) {
            root.loading = false
            root.debugStatus = "identity-mismatch"
            root.errorText = qsTr("Lyrics were not found for this track")
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

    Process {
        id: resolver
        property int serialToken: 0
        property string keyToken: ""
        property var metaToken: ({})
        running: false

        stdout: StdioCollector {
            onStreamFinished: root.applyResolverPayload(
                resolver.serialToken,
                resolver.keyToken,
                resolver.metaToken,
                text
            )
        }

        onExited: (exitCode, exitStatus) => {
            if (resolver.serialToken !== root.requestSerial || !root.loading)
                return
            if (exitCode !== 0) {
                requestWatchdog.stop()
                root.loading = false
                root.debugStatus = "resolver-failed"
                root.errorText = qsTr("Lyrics resolver failed to start")
            }
        }
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
        interval: 15000
        repeat: false
        onTriggered: {
            resolver.running = false
            root.loading = false
            root.debugStatus = "timeout"
            root.errorText = qsTr("Lyrics request timed out. Try refresh.")
        }
    }

    Component.onCompleted: root.scheduleLookup()
}
