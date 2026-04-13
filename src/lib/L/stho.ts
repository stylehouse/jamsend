import grammar from './stho.grammar?raw'
import { buildParser } from '@lezer/generator'
import { LanguageSupport, LRLanguage, indentNodeProp, foldNodeProp, foldInside,
    continuedIndent
} from "@codemirror/language"
import { styleTags, tags as t } from "@lezer/highlight"

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
                Name: t.variableName,
                IOness: t.bool,
                Sunpit: t.heading1,
                Title: t.heading3,
                Sunpitness: t.deleted,
                Sigil: t.string,
                Comment: t.lineComment,
                "( )": t.paren
            })
        ]
    }),
    languageData: {
        commentTokens: { line: "#", block: { open: "/*", close: "*/" } },
        closeBrackets: { brackets: ["(", "[", "{", "'", '"', "`"] },
        indentOnInput: /^\s*(?:case |default:|\{|\}|<\/)$/,
    },
})

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
export function stho(): LanguageSupport & { warnings?: any[] } {
    if (!sthoLanguage) {
        let lang: any = stho_substitute()
        warnings && warnings.unshift("Failed to buildParser()")
        lang.warnings = warnings
        return lang
    }
    let lang: any = new LanguageSupport(sthoLanguage)
    if (warnings) lang.warnings = warnings
    return lang
}

import { syntaxTree } from "@codemirror/language"
import { linter } from '@codemirror/lint'
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
