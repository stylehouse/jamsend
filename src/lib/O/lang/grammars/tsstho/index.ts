// $lib/O/lang/grammars/tsstho/index.ts — TypeScript host with stho islands.
//
// Outer parser: @lezer/javascript's parser configured for the "ts" dialect.
// Islands: `stho\`...\`` tagged template literals. Their TemplateString span
// is reparsed by stho's parser via parseMixed; backticks are excluded from
// the inner range so stho sees clean line-oriented source.
//
// The runtime fate of those template calls is the compiler's concern — the
// existing LangCompiling can lift each TaggedTemplateExpression and replace
// it with translated TS when writing to gen/. Until then the `stho` tag can
// be a real function (no-op or runtime-translate) or simply never called at
// runtime if its host file is only ever compiled.
//
// tsstho has no .grammar of its own; it's a configuration over an upstream
// grammar plus an inner parser. registry.ts therefore omits grammar_path
// for this entry, and the gen action stays hidden when a .ts is open.

import { LRLanguage } from "@codemirror/language"
import { HighlightStyle } from "@codemirror/language"
import { parseMixed } from "@lezer/common"
import { tags as t } from "@lezer/highlight"

import { get_inner_parser } from "../stho"
import type { LangResolve } from "../../registry"

// @lezer/javascript (the big TS/JS grammar) is imported LAZILY inside resolve() —
//  a top-level import welds it into the main bundle (and onto the runner / old-mobile
//   endpoints that never open a .ts/.svelte).  Only stho stays eager — it is the .g
//    core, always live.  parseMixed / LRLanguage / @lezer/highlight are already-bundled
//     CM core, so they stay static.

// Highlight palette for the TS host. The inner stho HighlightStyle is
// already applied separately at the editor level via sthoTags, so this set
// covers only the upstream @lezer/javascript tags.
// < unify palettes once we're sure the two coexist well.
export const highlightStyle = HighlightStyle.define([
    { tag: t.keyword,                  color: '#c678dd' },
    { tag: t.controlKeyword,           color: '#c678dd' },
    { tag: t.string,                   color: '#98c379' },
    { tag: t.special(t.string),        color: '#98c379' },
    { tag: t.number,                   color: '#d19a66' },
    { tag: t.bool,                     color: '#d19a66' },
    { tag: t.null,                     color: '#d19a66' },
    { tag: t.comment,                  color: '#5c6370', fontStyle: 'italic' },
    { tag: t.lineComment,              color: '#5c6370', fontStyle: 'italic' },
    { tag: t.blockComment,             color: '#5c6370', fontStyle: 'italic' },
    { tag: t.variableName,             color: '#abb2bf' },
    { tag: t.function(t.variableName), color: '#61afef' },
    { tag: t.definition(t.variableName), color: '#61afef' },
    { tag: t.typeName,                 color: '#e5c07b' },
    { tag: t.className,                color: '#e5c07b' },
    { tag: t.propertyName,             color: '#abb2bf' },
    { tag: t.operator,                 color: '#56b6c2' },
    { tag: t.punctuation,              color: '#abb2bf' },
])

export async function resolve(): Promise<LangResolve> {
    const { parser: jsBaseParser } = await import("@lezer/javascript")   // lazy: the big grammar, .ts/.svelte-only
    const innerParser = await get_inner_parser()
    if (!innerParser) {
        // No inner stho parser — fall back to plain TS. Islands won't nest
        // but the editor still works; this only happens if stho's resolve()
        // itself failed.
        const language = LRLanguage.define({
            parser:       jsBaseParser.configure({ dialect: "ts" }),
            languageData: { commentTokens: { line: "//", block: { open: "/*", close: "*/" } } },
        })
        return { language, source: 'live', stale: false, warnings: ['tsstho: inner stho parser unavailable; nesting disabled'] }
    }

    // parseMixed callback: nest stho into the TemplateString span of any
    // TaggedTemplateExpression tagged `stho`. Overlay trims the leading/
    // trailing backtick so stho's grammar starts on a clean newline-or-text.
    const wrappedTs = jsBaseParser.configure({
        dialect: "ts",
        wrap: parseMixed((node, input) => {
            if (node.type.name !== "TemplateString") return null
            const tagged = node.node.parent
            if (!tagged || tagged.type.name !== "TaggedTemplateExpression") return null
            const tag = tagged.firstChild
            if (!tag) return null
            const tagText = input.read(tag.from, tag.to)
            if (tagText !== "stho") return null
            // strip the two backticks
            const from = node.from + 1
            const to   = node.to - 1
            if (to <= from) return null
            return {
                parser: innerParser,
                overlay: [{ from, to }],
            }
        }),
    })

    const language = LRLanguage.define({
        parser:       wrappedTs,
        languageData: {
            commentTokens: { line: "//", block: { open: "/*", close: "*/" } },
            closeBrackets: { brackets: ["(", "[", "{", "'", '"', "`"] },
            indentOnInput: /^\s*(?:case |default:|\{|\}|<\/)$/,
        },
    })

    return { language, source: 'live', stale: false, warnings: [] }
}
