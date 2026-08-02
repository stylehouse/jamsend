---
name: svelte-comment-tag-gotcha
description: "literal <script>/<style> in a .svelte JS comment → svelte-check \"script was left open\""
metadata: 
  node_type: memory
  type: reference
  originSessionId: 9e3dbb8f-9bbc-47ee-ac57-34c8fb9daac7
---

A literal `<style>` or `<script>` token written inside a Svelte JS `//` (or `/* */`) comment makes **svelte-check** mis-scan the `<script>` block as running open all the way to `</style>`, reporting a structural-looking error **"`<script>` was left open"** at the `</style>` line (the LAST line of the file) — even though the tags are perfectly balanced.

It looks alarming (a structural parse failure at EOF) but the fix is trivial: **don't write the literal tag in a comment** — say "style block" / "script block" instead. Confirmed 2026-06-25 in `Langui.svelte` (a `//  handle (its <style>)` comment triggered it; rewording to "its style block" cleared it).

Debug tip: when a `.svelte` file suddenly reports "script was left open" at `</style>` after an edit, the cause is in your edit, not the file structure — grep your diff for a literal `<script`/`<style` in a comment before hunting brace balance. Related: [[running-check-in-container]].
