// $lib/O/lang/grammars/markdown/index.ts — the markdown language entry.
//
// Unlike stho/tsstho (custom .grammar files built with @lezer/generator), markdown
//  is a PREBUILT library language: @codemirror/lang-markdown (which bundles
//   @lezer/markdown).  So there is no .grammar to regen and no live-vs-generated
//    hash dance — resolve() just hands back the lib's `markdownLanguage`.
//
// LAZY ON PURPOSE.  The heavy lib import lives INSIDE resolve(), behind `await
//  import(...)`, so Vite code-splits it into its own chunk fetched only when an
//   .md dock mounts and lang('markdown') runs.  Keep this module top-level free of
//    any `@codemirror/lang-markdown` import — a static import would pull it into the
//     main bundle eagerly (the way tsstho pulls @lezer/javascript today), defeating
//      the split and bloating the runner / old-mobile endpoints that never edit .md.
//   The tag→colour map below uses only @lezer/highlight + @codemirror/language,
//    which are already in the bundle, so it stays static without dragging the lib in.

import { HighlightStyle } from "@codemirror/language"
import { tags as t }      from "@lezer/highlight"
import type { LangResolve } from "../../registry"

// Headings are the locatable units (regions/Points), so they lead the palette; the
//  rest is a light, legible cast over the random-hue editor theme.
export const highlightStyle = HighlightStyle.define([
    { tag: t.heading1,                                          color: "#e0c088", fontWeight: "bold" },
    { tag: t.heading2,                                          color: "#c4aaee", fontWeight: "bold" },
    { tag: [t.heading3, t.heading4, t.heading5, t.heading6],    color: "#8aabcc", fontWeight: "bold" },
    { tag: t.strong,                                            color: "#d8d8e0", fontWeight: "bold" },
    { tag: t.emphasis,                                          color: "#c8c8d4", fontStyle: "italic" },
    { tag: t.link,                                              color: "#6ad0a0", textDecoration: "underline" },
    { tag: t.url,                                               color: "#5a86c8" },
    { tag: t.monospace,                                         color: "#c9b48a" },
    { tag: t.quote,                                             color: "#888", fontStyle: "italic" },
    { tag: t.list,                                              color: "#7a8fa8" },
    { tag: t.contentSeparator,                                  color: "#445566" },
])

export async function resolve(): Promise<LangResolve> {
    const { markdownLanguage } = await import("@codemirror/lang-markdown")
    return { language: markdownLanguage, source: "generated", stale: false, warnings: [] }
}
