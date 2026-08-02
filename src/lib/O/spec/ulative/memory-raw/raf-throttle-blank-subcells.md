---
name: raf-throttle-blank-subcells
description: "headless Voro shot shows CELLS but BLANK sub-cells (0 vsub-groups, state N>0) = morph_voronoi clears vsubs synchronously but restores via requestAnimationFrame, which a background/unfocused runner tab THROTTLES/PAUSES; fix = document.hidden sync-paint + setTimeout backstop"
metadata:
  node_type: memory
  type: project
  originSessionId: 12f2682d-1c3e-4f5e-ba2c-7e09ee65b139
---

2026-07-14: burned ~an hour on "the glass renders cells but the ▦ sub-cells are BLANK" on every `runner_shot --svg` (`0 vsub-groups` in the DOM even though the render's own `cy_render.vsubs` mirror said 13). NOT a tuples-face bug, NOT a keyed-each dup, NOT a compile error — the `op:'svg'` DOM and the component `$state` genuinely disagreed.

ROOT CAUSE: `Cytui.morph_voronoi()` clears `vtips=[]` and `vsubs=[]` SYNCHRONOUSLY at tween start ("stale walls mid-tween would lie"), then restores them only inside the `requestAnimationFrame` frame loop's terminal `paint_final` (k>=1). A headless runner tab (booted `?B=`, never focused) is a BACKGROUND tab: the browser PAUSES rAF when `document.hidden`, and THROTTLES it to ~1fps when the tab is "visible" but its window is unfocused (`document.hidden` false). So the tween's restore never fires (or fires seconds late) and `vsubs` stays cleared — the glass shows cells (vcells kept its pre-morph value) but blank sub-cells. Repeated settle-morphs (a `diag_cure` relayout, ResizeObserver) each re-clear, so it never self-heals while more morphs queue.

FIX (Cytui.svelte morph_voronoi): (1) `if (still || document.hidden) { ...paint the settled state synchronously (incl. dying-cell cleanup)...; return }` BEFORE the clear — a hidden tab has no animation to watch, so snap to the end; (2) a `setTimeout(MORPH_MS+150)` **backstop** that force-lands `paint_final` if `vsubs` is still empty by then (setTimeout is NOT rAF-throttled) — catches the unfocused-but-visible 1fps case; cleared when the tween lands normally.

**Why:** the DISTINCT TELL — DOM `groups:0` but `state_vsubs:N>0` (added to `op:'svg'` reply: `groups`, `state_vsubs`, `svgs`, `cands`) = a MID-CLEAR render, not a build failure. A build failure shows `built:0`/`descs:0` in the `vsub` census; a rAF-throttle shows `built:N` then a trailing `morph-clear` with no restoring paint. Verify via the film strip (`runner_shot --why`): a `morph` line with no following `vsub` census line = the tween never terminated.

**How to apply:** ANY render-side state a Cytui rAF loop clears-then-restores is fragile to a headless/background shot. Gate the settled paint on `document.hidden`, and/or back it with a setTimeout. When a `--svg`/`--why` shot looks blank, RE-SHOOT after ~2s (it self-heals as morphs drain) before concluding the feature is broken — and check `state_vsubs` vs `groups`. Related: [[hmr-socket-dead-tell]] (a DIFFERENT blank: HMR dead, edits don't land), [[frozen-boot-empty-first-run]]. Added a `reload` op to `runner_ask.mjs`/LiesFunk (runner-only `location.reload()` over the ask rails) — the fleet wedge-healer, no more human-at-the-browser.
