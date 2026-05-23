// $lib/O/lang/registry.ts — static map of available languages.
//
// Adding a language is a code edit (intentional — keeps it grep-able and
// type-checked). Each entry's resolve() lazily builds the parser and reports
// whether the result came from the generated artifact or a live build, plus
// a stale flag the header UI uses to surface a "regen" affordance.

import type { LRLanguage } from "@codemirror/language"
import type { HighlightStyle } from "@codemirror/language"

import * as stho   from "./grammars/stho"
import * as tsstho from "./grammars/tsstho"
// < lezer-grammar would be next: highlight the .grammar files we're editing.

export type LangResolve = {
    language: LRLanguage | null
    source:   'generated' | 'live'
    stale:    boolean
    warnings: any[]
}

export type LangEntry = {
    label:          string
    highlightStyle: HighlightStyle | null
    resolve:        () => Promise<LangResolve>
    // Path to the .grammar source under src/lib/O/lang/grammars/<name>/
    // — surfaced so the "generate" action can locate it via Wormhole.
    grammar_path?:  string
    generated_path?: string
}

export const REGISTRY: Record<string, LangEntry> = {
    stho: {
        label:          'stho',
        highlightStyle: stho.highlightStyle,
        resolve:        stho.resolve,
        grammar_path:   'src/lib/O/lang/grammars/stho/stho.grammar',
        generated_path: 'src/lib/O/lang/grammars/stho/stho.grammar.ts',
    },
    tsstho: {
        label:          'tsstho',
        highlightStyle: tsstho.highlightStyle,
        resolve:        tsstho.resolve,
        grammar_path:   'src/lib/O/lang/grammars/tsstho/tsstho.grammar',
        generated_path: 'src/lib/O/lang/grammars/tsstho/tsstho.grammar.ts',
    },
}

export const LANG_OPTIONS = Object.entries(REGISTRY).map(([value, e]) => ({
    value, label: e.label,
}))
