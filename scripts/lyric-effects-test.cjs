#!/usr/bin/env node
// Pure Node test of the QML-imported data helper; no network/Qt is needed.
const assert = require("node:assert/strict")
const fs = require("node:fs")
const path = require("node:path")
const vm = require("node:vm")

const source = fs.readFileSync(path.join(__dirname, "../modules/raohane/RaohaneLyricEffects.js"), "utf8")
const context = vm.createContext({})
vm.runInContext(source, context)
const families = vm.runInContext("families", context)
const detect = value => vm.runInContext(`detect(${JSON.stringify(value)})`, context)

assert.equal(families.length, 40)
assert.equal(families.reduce((sum, group) => sum + group.words.length, 0), 200)
const words = families.flatMap(group => group.words)
assert.equal(new Set(words).size, 200, "base triggers must be distinct")

for (const [lyric, family] of [
    ["Розами укрыты сны", "rose"],
    ["Крыльями укрыла ночь", "wings"],
    ["Голос ангела", "voice"],
    ["Каплями дождя", "rain"],
    ["Stars above us", "stars"],
    ["burning fire", "fire"],
    ["Broken heart in the rain", "heart"],
    ["Ангельские крылья под дождем", "wings"]
]) {
    const match = detect(lyric)
    assert.equal(match?.family, family, lyric)
    assert.ok(match.start >= 0 && match.end > match.start)
    assert.ok(match.end <= lyric.length)
}

for (const lyric of ["Светлана смеётся", "A rosehip bush", "Instrumental", "123 ...", ""]) {
    assert.equal(detect(lyric), null, `false positive: ${lyric}`)
}

const phrase = detect("My broken heart is in the rain")
assert.equal("My broken heart is in the rain".slice(phrase.start, phrase.end), "heart")
console.log("lyric-effects-test: 200 triggers, inflections, context anchors and boundaries pass")
