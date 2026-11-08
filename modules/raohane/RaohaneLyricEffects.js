// Raohane-owned, data-only lyric vocabulary. Five base triggers in each of
// forty semantic families (200 total). The lyric service remains unchanged:
// LRCLIB provides line timing, not word timing.
const definitions = [
    ["rose", "petal", "роза", "розы", "лепесток", "rose", "petal"],
    ["flower", "petal", "цветок", "цветы", "букет", "flower", "bloom"],
    ["wings", "wing", "крылья", "крыло", "перья", "wings", "feather"],
    ["angel", "light", "ангел", "ангела", "небеса", "angel", "heaven"],
    ["rain", "rain", "дождь", "капли", "ливень", "rain", "drizzle"],
    ["storm", "rain", "гроза", "гром", "молния", "storm", "thunder"],
    ["snow", "snow", "снег", "снежинка", "метель", "snow", "blizzard"],
    ["ice", "snow", "лед", "льдина", "иней", "ice", "frost"],
    ["fire", "flame", "огонь", "пламя", "костер", "fire", "flame"],
    ["embers", "flame", "искра", "угли", "пепел", "embers", "spark"],
    ["stars", "star", "звезда", "звезды", "созвездие", "stars", "starlight"],
    ["moon", "star", "луна", "месяц", "лунный", "moon", "moonlight"],
    ["sun", "light", "солнце", "рассвет", "лучи", "sun", "sunrise"],
    ["sky", "wind", "небо", "облака", "горизонт", "sky", "cloud"],
    ["heart", "heart", "сердце", "сердцем", "сердца", "heart", "heartbeat"],
    ["love", "heart", "любовь", "люблю", "нежность", "love", "darling"],
    ["tears", "rain", "слеза", "слезы", "плач", "tears", "crying"],
    ["pain", "shadow", "боль", "рана", "шрам", "pain", "hurt"],
    ["dream", "star", "сон", "сны", "мечта", "dream", "dreaming"],
    ["memory", "light", "память", "воспоминание", "прошлое", "memory", "remember"],
    ["ocean", "wave", "океан", "море", "волна", "ocean", "sea"],
    ["river", "wave", "река", "ручей", "течение", "river", "stream"],
    ["wind", "wind", "ветер", "бриз", "вихрь", "wind", "breeze"],
    ["forest", "leaf", "лес", "деревья", "чаща", "forest", "woods"],
    ["leaves", "leaf", "листва", "листья", "листок", "leaves", "leaf"],
    ["autumn", "leaf", "осень", "октябрь", "увядание", "autumn", "fall"],
    ["spring", "petal", "весна", "апрель", "пробуждение", "spring", "blossom"],
    ["summer", "light", "лето", "июль", "жара", "summer", "sunshine"],
    ["winter", "snow", "зима", "декабрь", "холод", "winter", "cold"],
    ["night", "shadow", "ночь", "темнота", "полночь", "night", "midnight"],
    ["shadow", "shadow", "тень", "силуэт", "мрак", "shadow", "darkness"],
    ["light", "light", "свет", "сияние", "свеча", "light", "glow"],
    ["time", "ring", "время", "часы", "минута", "time", "clock"],
    ["distance", "wind", "далеко", "расстояние", "дорога", "distance", "faraway"],
    ["home", "light", "дом", "очаг", "убежище", "home", "shelter"],
    ["freedom", "wing", "свобода", "воля", "полет", "freedom", "fly"],
    ["silence", "shadow", "тишина", "молчание", "покой", "silence", "quiet"],
    ["voice", "ring", "голос", "шепот", "крик", "voice", "whisper"],
    ["music", "ring", "музыка", "песня", "мелодия", "music", "song"],
    ["hope", "star", "надежда", "вера", "будущее", "hope", "believe"]
]

var families = definitions.map(function (entry) {
    return { id: entry[0], motif: entry[1], words: entry.slice(2) }
})

// Contexts override the first generic hit. The visual anchor is still a
// single semantic word, never a glyph-covering effect across an entire line.
const contexts = [
    { phrase: "разбитое сердце", word: "сердце", family: "heart" },
    { phrase: "broken heart", word: "heart", family: "heart" },
    { phrase: "ангельские крылья", word: "крылья", family: "wings" },
    { phrase: "angel wings", word: "wings", family: "wings" },
    { phrase: "под дождем", word: "дождем", family: "rain" },
    { phrase: "in the rain", word: "rain", family: "rain" },
    { phrase: "звездное небо", word: "небо", family: "stars" },
    { phrase: "starry sky", word: "sky", family: "stars" }
]

function normalize(value) {
    return String(value || "").toLocaleLowerCase().replace(/ё/g, "е")
}

function russianStem(term) {
    // Conservative word-family matching: it only applies to whole tokens
    // followed by known inflectional suffixes, never to arbitrary substrings.
    return term.replace(/(иями|ьями|ами|ями|ого|ему|ому|ыми|ими|иях|ия|ья|ый|ий|ая|ое|ые|ов|ев|ей|ам|ям|ах|ях|ом|ем|ой|ою|ею|а|я|ы|и|у|ю|е|о)$/u, "")
}

const russianEndings = new Set([
    "", "а", "я", "ы", "и", "у", "ю", "е", "о", "ом", "ем", "ам", "ям", "ах", "ях",
    "ой", "ою", "ею", "ов", "ев", "ей", "ий", "ый", "ая", "ое", "ые", "его", "ого",
    "ему", "ому", "ыми", "ими", "ами", "ями", "ия", "ья", "иях", "ьям",
    "ьях", "ьями", "ьев", "еть", "ют", "ет", "ут", "ит", "л", "ла", "ли"
])

function wordMatches(token, word) {
    if (token === word)
        return true
    if (/^[a-z]+$/.test(word)) {
        if (word.length < 4)
            return false
        return token === word + "s" || token === word + "es"
            || token === word + "ed" || token === word + "ing"
            || (word.endsWith("y") && token === word.slice(0, -1) + "ies")
    }
    if (word.length < 4 || !/^[а-я]+$/u.test(word))
        return false
    const stem = russianStem(word)
    return stem.length >= 3 && token.startsWith(stem)
        && russianEndings.has(token.slice(stem.length))
}

function tokenize(text) {
    const result = []
    const expression = /[\p{L}\p{N}]+/gu
    let token
    while ((token = expression.exec(text)) !== null)
        result.push({ value: normalize(token[0]), start: token.index, end: token.index + token[0].length })
    return result
}

function detect(text) {
    const tokens = tokenize(String(text || ""))
    if (tokens.length === 0)
        return null

    for (const context of contexts) {
        const phraseTokens = tokenize(context.phrase)
        for (let start = 0; start <= tokens.length - phraseTokens.length; ++start) {
            if (!phraseTokens.every((piece, offset) => tokens[start + offset].value === piece.value))
                continue
            const hit = phraseTokens.findIndex(piece => piece.value === normalize(context.word))
            if (hit < 0)
                continue
            const family = families.find(entry => entry.id === context.family)
            return { start: tokens[start + hit].start, end: tokens[start + hit].end,
                family: family.id, motif: family.motif }
        }
    }

    // Exactly one effect for the active lyric line. Earlier words win;
    // equal-position matches are resolved by the declared family order.
    for (const token of tokens) {
        for (const family of families) {
            if (family.words.some(word => wordMatches(token.value, normalize(word))))
                return { start: token.start, end: token.end, family: family.id, motif: family.motif }
        }
    }
    return null
}
