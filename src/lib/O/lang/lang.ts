// $lib/O/lang/lang.ts — language-neutral entry point and helpers.
//
// Per-language modules live under ./grammars/<name>/index.ts and export a
// LangEntry. lang(name) resolves an entry via the static REGISTRY, fills in a
// fresh random-hue theme + syntax highlighting, and returns the extensions
// array EditorState.create wants. Per-language parser resolution is the
// language module's own concern — see ./grammars/stho/index.ts for the
// generated-vs-live hash dance.
//
// Pieces that have no reason to know about any specific language live here:
//   - randomHueDarkTheme — one fresh hue per mount
//   - capture_warnings  — collect console.warn during a build step
//   - simpleLezerLinter — surface the first error node from the parse tree
//   - sha_hex           — SubtleCrypto SHA-256 of a string, hex; used for
//                         .grammar-vs-generated freshness checks

import { LanguageSupport, LRLanguage, syntaxHighlighting, syntaxTree } from "@codemirror/language"
import { EditorView } from "@codemirror/view"
import { linter } from "@codemirror/lint"
import { buildParser } from "@lezer/generator"

import { REGISTRY, type LangEntry } from "./registry"

export type { LangEntry } from "./registry"
export { REGISTRY } from "./registry"

// Return value carries extra fields the Lang ghost reads to drive the header
// UI (warnings, source=live|generated, stale flag for the "regen" button).
export type LangExts = any[] & {
    warnings?: any[]
    source?: 'generated' | 'live'
    stale?:  boolean
    name?:   string
}

export async function lang(name: string): Promise<LangExts> {
    const entry: LangEntry | undefined = REGISTRY[name]
    if (!entry) {
        const exts: LangExts = [substitute_language(), randomHueDarkTheme()]
        exts.warnings = [`unknown language: ${name}`]
        exts.name = name
        return exts
    }

    const { language, source, stale, warnings } = await entry.resolve()
    const theme = randomHueDarkTheme()
    const highlighting = entry.highlightStyle
        ? syntaxHighlighting(entry.highlightStyle)
        : null

    const exts: LangExts = language
        ? [new LanguageSupport(language), theme, ...(highlighting ? [highlighting] : [])]
        : [substitute_language(), theme]
    if (warnings && warnings.length) exts.warnings = warnings
    if (source) exts.source = source
    if (stale)  exts.stale = stale
    exts.name = name
    return exts
}

// Light fallback so a diagnostic editor still appears when the real grammar
// fails to build. We can't reuse @codemirror/lang-javascript here — its
// LanguageSupport object is frozen and won't accept further configuration.
function substitute_language(): LanguageSupport {
    const p = buildParser(
        `@tokens { else { ![\n] } }
        @top Program { (Lie* "\n")* }
        Lie { else }
    `)
    const Language = LRLanguage.define({ parser: p.configure({}) })
    return new LanguageSupport(Language)
}

// Called once per editor mount so every instance gets its own hue.
// Saturation and lightness are pinned to stay legibly dark.
export function randomHueDarkTheme() {
    const hue = Math.floor(Math.random() * 360)
    const bg       = `hsl(${hue}, 18%, 9%)`
    const gutterBg = `hsl(${hue}, 22%, 12%)`
    const gutterFg = `hsl(${hue}, 15%, 38%)`
    const cursor   = `hsl(${(hue + 180) % 360}, 70%, 65%)`

    return EditorView.theme({
        '&':                      { background: bg, color: '#abb2bf' },
        '.cm-content':            { caretColor: cursor },
        '.cm-cursor':             { borderLeftColor: cursor },
        '.cm-gutters':            { background: gutterBg, color: gutterFg, border: 'none' },
        '.cm-activeLineGutter':   { background: `hsl(${hue}, 25%, 9%)` },
        // https://discuss.codemirror.net/t/various-themes-activeline-selections-not-visible/7473/2
        '.cm-activeLine':         { background: `hsla(${hue}, 20%, 9%, 0.3)` },
        // < single-line selection: CM's drawSelection() is supposedly a
        //    prerequisite for inline selections. Wire it up later.
        '.cm-lineNumbers':        { color: gutterFg },
        '.cm-foldGutter':         { color: gutterFg },
    }, { dark: true })
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

// Capture console.warn during a build step (buildParser pushes its conflict
// warnings to console.warn). Returns the captured list, or null if nothing
// was logged.
export function capture_warnings(y: () => void): any[] | null {
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

// SHA-256 hex of a UTF-8 string. Used to compare a live .grammar's contents
// against the hash a generated parser stamps in its header.
export async function sha_hex(s: string): Promise<string> {
    const bytes = new TextEncoder().encode(s)
    const hash = await crypto.subtle.digest('SHA-256', bytes)
    return Array.from(new Uint8Array(hash), b => b.toString(16).padStart(2, '0')).join('')
}

// Read the `// hash: …` line a generated .grammar.ts stamps in its header.
// Returns null if the marker isn't present, so the caller can treat the
// generated artifact as hash-unknown (and therefore stale).
export function read_generated_hash(generated_src: string): string | null {
    const m = generated_src.match(/^\/\/ hash:\s*([0-9a-f]+)/m)
    return m ? m[1] : null
}

// Pick a language name from a path. Extension-driven; the Lang ghost can
// override per-doc via docC.sc.lang_override.
export function lang_for_path(path: string): string {
    if (path.endsWith('.grammar')) return 'lezer-grammar'
    if (path.endsWith('.stho'))    return 'stho'
    if (path.endsWith('.ts'))      return 'tsstho'
    if (path.endsWith('.svelte'))  return 'tsstho'
    if (path.endsWith('.md'))      return 'markdown'
    return 'stho'
}
