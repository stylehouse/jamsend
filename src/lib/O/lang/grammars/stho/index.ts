// $lib/O/lang/grammars/stho/index.ts — stho language wiring.
//
// Owns: semantic Tag set, styleTags bindings, HighlightStyle palette,
// indent/fold props, languageData, and the resolve() that picks between a
// generated parser artifact and a live buildParser() of the .grammar.
//
// Generated-vs-live policy:
//   - Hash the live .grammar text (sha-256, hex).
//   - import.meta.glob() for ./stho.grammar.ts. If present, await it; check
//     its exported grammar_hash against the live hash.
//   - Match → use generated. source: 'generated', stale: false.
//   - Mismatch → use live build. source: 'live', stale: true (UI flags the
//     generated artifact as out of date; a regen action overwrites it).
//   - Generated absent → use live build. source: 'live', stale: false.

import { LRLanguage, indentNodeProp, foldNodeProp, foldInside,
    continuedIndent, HighlightStyle } from "@codemirror/language"
import { Tag, styleTags } from "@lezer/highlight"
import { buildParser } from "@lezer/generator"

import grammar from "./stho.grammar?raw"
import { capture_warnings, sha_hex } from "../../lang"
import type { LangResolve } from "../../registry"

// Semantic tags — our own, so themes stay predictable across CM versions
// and independent of any global highlight style in scope.
export const sthoTags = {
    ioMarker:    Tag.define(),   // IOness:  "i " | "o "
    iterMarker:  Tag.define(),   // Sunpitness: "S "
    name:        Tag.define(),   // variable / key identifiers
    number:      Tag.define(),   // number literals
    string:      Tag.define(),   // StringVal puddle literals
    sigil:       Tag.define(),   // "$", "@", "#" prefix/suffix
    puddleSigil: Tag.define(),   // "%" — marks verbatim-TS value
    ampSigil:    Tag.define(),   // "&" — this.method() call head
    comment:     Tag.define(),   // "#..." line comments
    controlHead: Tag.define(),   // "if ", "for ", "while ", "else"
    title:       Tag.define(),   // condition text after a control keyword
    methodName:  Tag.define(),   // Name inside a MethodLike
    flugBracket: Tag.define(),   // "[" / "]" around Flug markers
}

// One-dark-ish palette preserved from the old monolithic stho.ts.
export const highlightStyle = HighlightStyle.define([
    { tag: sthoTags.ioMarker,    color: '#56b6c2', fontWeight: 'bold' },   // cyan — i/o
    { tag: sthoTags.iterMarker,  color: '#c678dd', fontWeight: 'bold' },   // purple — S
    { tag: sthoTags.name,        color: '#abb2bf' },                       // soft white — keys
    { tag: sthoTags.number,      color: '#d19a66' },                       // amber — numbers
    { tag: sthoTags.string,      color: '#98c379' },                       // green — string puddles
    { tag: sthoTags.sigil,       color: '#e06c75' },                       // red — $ @ #
    { tag: sthoTags.puddleSigil, color: '#56b6c2', fontWeight: 'bold' },  // cyan — %
    { tag: sthoTags.ampSigil,    color: '#c678dd', fontWeight: 'bold' },  // purple — &
    { tag: sthoTags.comment,     color: '#5c6370', fontStyle: 'italic' },  // grey — comments
    { tag: sthoTags.controlHead, color: '#c678dd' },                       // purple — if/for/else
    { tag: sthoTags.title,       color: '#e5c07b' },                       // gold — conditions
    { tag: sthoTags.methodName,  color: '#61afef', fontWeight: 'bold' },   // blue — method names
    { tag: sthoTags.flugBracket, color: '#56b6c2' },                       // cyan — [ ]
])

const languageData = {
    commentTokens: { line: "#", block: { open: "/*", close: "*/" } },
    closeBrackets: { brackets: ["(", "[", "{", "'", '"', "`"] },
    indentOnInput: /^\s*(?:case |default:|\{|\}|<\/)$/,
}

// Configure a freshly-supplied parser with stho's indent/fold/styleTag props.
function configure(parser: any) {
    return parser.configure({
        props: [
            indentNodeProp.add({
                Sunpit:     continuedIndent({ except: /^\s*S $/ }),
                Sunpitness: continuedIndent({ except: /^\s*S $/ }),
            }),
            foldNodeProp.add({
                Sunpit: foldInside,
            }),
            styleTags({
                IOness:                sthoTags.ioMarker,
                Sunpitness:            sthoTags.iterMarker,
                Name:                  sthoTags.name,
                Number:                sthoTags.number,
                StringVal:             sthoTags.string,
                Sigil:                 sthoTags.sigil,
                PuddleSigil:           sthoTags.puddleSigil,
                AmpSigil:              sthoTags.ampSigil,
                Comment:               sthoTags.comment,
                ControlKeyword:        sthoTags.controlHead,
                ElseKeyword:           sthoTags.controlHead,
                ElseIfKeyword:         sthoTags.controlHead,
                Title:                 sthoTags.title,
                "MethodLike/Name":     sthoTags.methodName,
                "AmpCall/Name":        sthoTags.methodName,
                "Flugenzoid/( )":      sthoTags.flugBracket,
                "Flugamata/( )":       sthoTags.flugBracket,
            }),
        ],
    })
}

// Discovery glob — empty until a generated artifact is written by the
// in-app gen action. The result is a record of path → loader.
const generated_loaders = import.meta.glob<{
    parser: any,
    grammar_hash: string,
}>('./stho.grammar.ts')

export async function resolve(): Promise<LangResolve> {
    const live_hash = await sha_hex(grammar)

    // Try the generated artifact first.
    let generated: { parser: any, grammar_hash: string } | null = null
    for (const loader of Object.values(generated_loaders)) {
        try {
            generated = await loader()
        } catch (err) {
            console.warn(`stho: generated artifact load failed`, err)
        }
        break
    }

    if (generated && generated.grammar_hash === live_hash) {
        const language = LRLanguage.define({
            parser:       configure(generated.parser),
            languageData,
        })
        return { language, source: 'generated', stale: false, warnings: [] }
    }

    // Live build — slower but always honest about the current .grammar text.
    let live_parser: any
    const warnings = capture_warnings(() => live_parser = buildParser(grammar))

    if (!live_parser) {
        return {
            language: null,
            source:   'live',
            stale:    !!generated,
            warnings: warnings ?? ['stho: buildParser failed'],
        }
    }

    const language = LRLanguage.define({
        parser:       configure(live_parser),
        languageData,
    })
    return {
        language,
        source:   'live',
        // stale = a generated artifact exists but doesn't match current source.
        stale:    !!generated,
        warnings: warnings ?? [],
    }
}

// Re-export of the configured live parser, for siblings (tsstho's parseMixed)
// that want to nest stho without going through resolve() again.
export async function get_inner_parser(): Promise<any | null> {
    const r = await resolve()
    return r.language?.parser ?? null
}
