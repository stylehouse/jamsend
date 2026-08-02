---
name: webkit-scrollbar-no-var
description: "CSS custom properties don't inherit into ::-webkit-scrollbar pseudo-elements (Chromium) — use literals"
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9e3dbb8f-9bbc-47ee-ac57-34c8fb9daac7
---

**TWO `::-webkit-scrollbar` Chromium pitfalls bit the Langui copper handle (2026-06-25):**

**Pitfall A — standard `scrollbar-color`/`scrollbar-width` DISABLE `::-webkit-scrollbar` styling.** Setting `scrollbar-color` on an element switches Chromium to its standard scrollbar renderer, which **flatly replaces the `::-webkit-scrollbar-thumb` `background-image`** (a texture) with the solid color; `scrollbar-width:thin` likewise overrides the pseudo's width. So a well-meant "Firefox fallback" line (`.x { scrollbar-color: … }`) silently kills the webkit texture. FIX: style scroll areas **purely via `::-webkit-scrollbar` pseudo-elements**; do NOT set the standard props on the same selector (Firefox gets its default; the texture is webkit-only anyway). Also: a single-class global rule (`.scrollbig`, 0,1,1) is too weak to beat CodeMirror's injected `.cm-scroller` scrollbar styles — the editor must own its scrollbar with a component-scoped, more-specific rule.

**Pitfall B — CSS custom properties (`var(--x)`) do NOT reliably inherit into `::-webkit-scrollbar` (and `-thumb`/`-track`) in Chromium.** A `width: var(--gutter)` on `::-webkit-scrollbar` resolves to the guaranteed-invalid value → the declaration is dropped → the scrollbar silently falls back to whatever lower-specificity rule set a literal width (e.g. a global `.scrollbig { width: 12px }`).

Symptom: a scrollbar that should be wide renders thin, and devtools shows your `-thumb` rule applied (its literal values — background/radius — work fine) so it *looks* like the rule is winning — but the bar width came from elsewhere because only the `::-webkit-scrollbar` width used a var.

Fix: write a **literal** value (`width: 2em`) in the `::-webkit-scrollbar` rule, kept in sync by hand with the var that real (non-pseudo) elements like a minimap/chevron use. Hit 2026-06-25 in `Langui.svelte` (the editor scrollbar "looked like scrollsmall"). Related lesson that a styled `-thumb` doesn't prove the bar width — check the `::-webkit-scrollbar` rule separately.
