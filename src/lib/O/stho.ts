import grammar from './stho.grammar?raw'
import { buildParser } from '@lezer/generator'
import { LanguageSupport, LRLanguage, indentNodeProp, foldNodeProp, foldInside,
    continuedIndent, HighlightStyle, syntaxHighlighting, syntaxTree
} from "@codemirror/language"
import { Tag, styleTags } from "@lezer/highlight"
import { EditorView } from "@codemirror/view"
import { linter } from '@codemirror/lint'

// ── Custom semantic tags ─────────────────────────────────────────────────────
// Own tags rather than borrowed built-ins, so themes stay predictable and
// independent of whatever global highlight style is in use.
export const sthoTags = {
    ioMarker:      Tag.define(),   // IOness:  "i " | "o "
    iterMarker:    Tag.define(),   // Sunpitness: "S "
    name:          Tag.define(),   // Name (variable / key identifiers)
    number:        Tag.define(),   // Number literals
    sigil:         Tag.define(),   // "$", "@", "#" prefix/suffix
    comment:       Tag.define(),   // "#..." line comments
    controlHead:   Tag.define(),   // "if ", "for ", "while ", "else" etc.
    title:         Tag.define(),   // condition text after a control keyword
    methodName:    Tag.define(),   // Name inside a MethodLike
    flugBracket:   Tag.define(),   // "[" / "]" around Flug markers
}

let parser: any
let warnings = capture_warnings(
    () => parser = buildParser(grammar)
)

// < try more of https://github.com/codemirror/lang-example/blob/main/src/index.ts
export const sthoLanguage = parser && LRLanguage.define({
    parser: parser.configure({
        props: [
            indentNodeProp.add({
                Sunpit: continuedIndent({ except: /^\s*S $/ }),
                Sunpitness: continuedIndent({ except: /^\s*S $/ }),
            }),
            foldNodeProp.add({
                Sunpit: foldInside
            }),
            styleTags({
                IOness:                sthoTags.ioMarker,
                Sunpitness:            sthoTags.iterMarker,
                Name:                  sthoTags.name,
                Number:                sthoTags.number,
                Sigil:                 sthoTags.sigil,
                Comment:               sthoTags.comment,
                ControlKeyword:        sthoTags.controlHead,
                ElseKeyword:           sthoTags.controlHead,
                ElseIfKeyword:         sthoTags.controlHead,
                Title:                 sthoTags.title,
                "MethodLike/Name":     sthoTags.methodName,
                "Flugenzoid/( )":      sthoTags.flugBracket,
                "Flugamata/( )":       sthoTags.flugBracket,
            })
        ]
    }),
    languageData: {
        commentTokens: { line: "#", block: { open: "/*", close: "*/" } },
        closeBrackets: { brackets: ["(", "[", "{", "'", '"', "`"] },
        indentOnInput: /^\s*(?:case |default:|\{|\}|<\/)$/,
    },
})

// ── Highlight style ──────────────────────────────────────────────────────────
// Old theme palette preserved here.
export const sthoHighlightStyle = HighlightStyle.define([
    { tag: sthoTags.ioMarker,   color: '#56b6c2', fontWeight: 'bold' },   // cyan  — i/o
    { tag: sthoTags.iterMarker, color: '#c678dd', fontWeight: 'bold' },   // purple — S
    { tag: sthoTags.name,       color: '#abb2bf' },                        // soft white — keys
    { tag: sthoTags.number,     color: '#d19a66' },                        // amber — numbers
    { tag: sthoTags.sigil,      color: '#e06c75' },                        // red — $ @ #
    { tag: sthoTags.comment,    color: '#5c6370', fontStyle: 'italic' },   // grey — comments
    { tag: sthoTags.controlHead,color: '#c678dd' },                        // purple — if/for/else
    { tag: sthoTags.title,      color: '#e5c07b' },                        // gold — conditions
    { tag: sthoTags.methodName, color: '#61afef', fontWeight: 'bold' },   // blue — method names
    { tag: sthoTags.flugBracket,color: '#56b6c2' },                        // cyan — [ ]
])

// ── Random-hue dark theme ────────────────────────────────────────────────────
// Called once per mount so every editor instance gets its own hue.
// Saturation and lightness are fixed to stay clearly dark and readable.
function randomHueDarkTheme() {
    const hue = Math.floor(Math.random() * 360)
    // editor bg: very dark, slight hue
    const bg       = `hsl(${hue}, 18%, 9%)`
    // gutter: a touch lighter / more saturated than bg
    const gutterBg = `hsl(${hue}, 22%, 12%)`
    const gutterFg = `hsl(${hue}, 15%, 38%)`
    // cursor: complement hue, bright
    const cursor   = `hsl(${(hue + 180) % 360}, 70%, 65%)`
    // selection: punchy enough to read against the dark bg
    const selBg    = `hsl(${hue}, 55%, 0%)`

    return EditorView.theme({
        '&':                      { background: bg, color: '#abb2bf' },
        '.cm-content':            { caretColor: cursor },
        '.cm-cursor':             { borderLeftColor: cursor },
        '.cm-gutters':            { background: gutterBg, color: gutterFg, border: 'none' },
        '.cm-activeLineGutter':   { background: `hsl(${hue}, 25%, 9%)` },
        // https://discuss.codemirror.net/t/various-themes-activeline-selections-not-visible/7473/2
        '.cm-activeLine':         { background: `hsla(${hue}, 20%, 9%,0.3)` },
        // < get this fully working. no go when focused or the selection is in one line.
        //    not very important. 
        //    CM's drawSelection() is supposedly a prerequisite for inline selections.
        // // single-line selection: CM draws this only when focused
        // '&.cm-focused .cm-selectionBackground': { background: selBg },
        // // unfocused
        // '.cm-selectionBackground':              { background: selBg },
        '.cm-lineNumbers':        { color: gutterFg },
        '.cm-foldGutter':         { color: gutterFg },
    }, { dark: true })
}

// if stho fails to build, just get something on screen so diag can happen
// we would just use @codemirror/lang-javascript, but its object is unwritable!?
function stho_substitute() {
    let p = buildParser(
        `@tokens { else { ![\n] } }
        @top Program { (Lie* "\n")* }
        Lie { else }
    `)
    let Language = LRLanguage.define({ parser: p.configure({}) })
    return new LanguageSupport(Language)
}

// for EditorState.create extensions[]
// returns an array of extensions: [LanguageSupport, theme, highlighting]
export function stho(): any[] & { warnings?: any[] } {
    const theme = randomHueDarkTheme()
    const highlighting = syntaxHighlighting(sthoHighlightStyle)

    if (!sthoLanguage) {
        let exts: any = [stho_substitute(), theme, highlighting]
        warnings && warnings.unshift("Failed to buildParser()")
        exts.warnings = warnings
        return exts
    }
    let exts: any = [new LanguageSupport(sthoLanguage), theme, highlighting]
    if (warnings) exts.warnings = warnings
    return exts
}

export function simpleLezerLinter() {
    return linter(view => {
        const { state } = view
        const tree = syntaxTree(state)
        if (tree.length === state.doc.length) {
            let pos: number | null = null
            tree.iterate({ enter: n => {
                if (pos == null && n.type.isError) {
                    pos = n.from
                    return false
                }
            }})
            if (pos != null)
                return [{ from: pos, to: pos + 1, severity: 'error', message: 'syntax error' }]
        }
        return []
    })
}

function capture_warnings(y: () => void) {
    const warnings: any[] = []
    const originalWarn = console.warn
    console.warn = (w: any) => warnings.push(w)
    try {
        y()
    } catch (error: any) {
        console.warn = originalWarn
        error.says = error.message
        error.pile = error.stack?.split("\n")
        warnings.unshift(error)
    } finally {
        console.warn = originalWarn
    }
    return warnings.length ? warnings : null
}
