# Peeroleum handover

The living checklist for retiring `Peerily`/`MachPeerily` and growing `Peeroleum` against
`Peeroleum_spec.md`. Each heading is meant to shrink as it is solved. This file is the memory the
work would otherwise re-type into each session — keep it current, correct anything stale.

Notation: `[x]` done · `[~]` started/scaffolded · `[ ]` not begun · `// <` a deliberate hole.

---

## Getting started — how the loop works

A `.g` ghost's methods only exist on `H` once the dock is **compiled and included** (Languish →
`src/lib/gen/**.go` → Pantheate `import()` → `eatfunc`). So the top of the test regime is a
hand-written `src/lib/O/test/Peregrination.svelte` (mounted in `Machinery.svelte`), not a `.g`. It:

1. **compiles** each needed `.g` dock by firing `i_elvisto('Lang/Lang','Dock_open',{path})` — the
   same path the editor takes (`Lang.svelte:669` → `Lang_open_dock` → `req:Languish`).
2. **waits for inclusion** — a self-finishing `%req:ensure_compiled` per dock polls
   `H[Lang_ghostmeta_name(path)]` and holds a `%ttlilt` so Story stays open meanwhile; it stamps
   `w/%compiled,path` when the module lands.
3. **calls through** — once every `ensure_compiled` req is finished, `await H.LakeNetherland(A,w)`.
   The wrangler is just a method on `H` now; no separate instance is created.

`Run_A_Peregrination` plonks `A:Lies/A:Lang/A:Pantheate` into the Story Run beside `A:Peregrination`
(same as `Run_A_LangTiles`, `Machinery.svelte:66`). The loader's `Dock_open` elvis *reaches* Lang
via `_find_house` walking up to the main House, but the compile reqs (`req:Languish`/`req:Cortex`/
`req:include`) only progress when the **Run's own** `think`/`reqdo_sweep` pumps those workers — so the
Run needs them. (Early design; they're plonked together.)

This reuses the existing compile→include→run spine (`LiesCortex.svelte:116-523`); the heavier
`Rundown_arm`/BlastPit runner (`LiesCortex.svelte:348-523`) is the snapshot-producing path, not
needed for this loop. Drive it from the **Peregrination Story**
(`wormhole/Story/Peregrination/toc.snap`), whose Prep opens the **Ghost/Net/Easy** Waft overlay
(`wormhole/Ghost/Net/Easy/toc.snap`) — the overlay's `.g` Docs are the compile manifest.

Run: dev server :9091 → run the `Peregrination` Story → expect `w/%compiled,path` to flip for both
docks, then `w/%see:"compiled + included — calling through to LakeNetherland"` and LakeNetherland's
own `%see` in the snap. That green pass = the bootstrap loop proven.

---

## Engine facts (override the spec's aspirational prose)

- `reqy()` is **deleted**. Live req API is C-native on any host C: `host.oai({req,maz,eternal?,
  permanent?},sc?)` (sync), `host.doai(c,sc)?.(req=>…)`, `await host.do()`, `host.finish(child)`,
  `host.all_finished()` (`Stuff.svelte.ts:574-652`). `{req:'p2pman'}` → `H.req_p2pman`;
  `w:Peeroleum` → `H.Peeroleum(A,w)`. `eternal` = never finished, self-settles via `req.sc.ok=1`;
  `permanent` = engine flag, un-finishes on input drift.
- **Not in the engine — do not emit**: `%req:waiting` + computed-max global (spec §13),
  `%exports`/`%aim` hoisting (§12.2), `waits_savepoint` (§12.4). Waiting today =
  `H.i_req_ttlilt(req,secs,{waiting})` (`Hovercraft.svelte:180`) + eternal-foreman `req.sc.ok=1`
  (`LiesStore.svelte:434-555`). See heading 5.
- **LangTiles gaps** (→ raw-JS passthrough, flag `// <`): no auto-`async` (hand-write it), no
  `oa`/`drop`/`empty` verbs, no drilled paths on `oai/r/rm`, no object/`.c` payloads in `sc`, no
  list fan-out. See heading L.

---

## Headings

### 0 — Bootstrap loader  `[~]` (this pass)
Hand-written `src/lib/O/test/Peregrination.svelte` furnishes + compiles + includes the `.g` docks
and calls through to `H.LakeNetherland`. Mounted in `Machinery.svelte`. Story + overlay scaffolded.

What the first run taught us (the GUI-coupling of compile — the heart of heading 1):
- **Trigger**: `Dock_open` only re-points an *already-furnished* dock (`Lang_set_active_dock`,
  `Lang.svelte:452`) — a no-op for a never-opened path. The pull `i_elvisto('Lies/Lies','dock_askies',
  {path})` is what mints `w:Lang/docks/dock:path` (via `e_Lang_dock_content`). Loader now uses it.
- **EditorState gate**: `req:text_loaded`/`Lang_compile_dock` wait on `dock.c.state`, a CodeMirror
  `EditorState` normally stamped only when a *mounted editor* fires `e_Lang_editorBegins`
  (`Lang.svelte:399,1733`). A Story run has no editor → it would hang on `waiting:cm_mount`. The
  loader now stamps a **headless** `EditorState.create({doc, extensions: await lang(lang_for_path(
  path))})` itself — via the lang registry (`src/lib/O/lang/lang.ts`, the same path Langui uses,
  `Langui.svelte:1330`; `.g` → 'stho'). The compiler reads the parser from the facet line-by-line
  (`LangCompiling.svelte:339,478`), no view required. First real piece of the headless compiler.
  (NB: use `lang/lang.ts`, not the legacy hardcoded `O/stho.ts`.)
- **Include still renders**: a `.g`'s methods land on `H` only when its gen component's `onMount`
  runs `H.eatfunc` — and that mount happens when **Otro renders** the `UIs` bucket
  (`Otro.svelte:109`). So `included()` flipping still depends on the app rendering. Fully-headless
  include (mount the gen module without Otro) is heading 1.

Next: re-run and confirm `%compiled,path` flips; then the strict currency gate — `included()`
accepts any prior compile; rigorous is `H[ghostmeta]() === source_dige` (`LiesCortex.svelte:304`).

### 0b — Net/Easy Waft overlay  `[x]`
`wormhole/Ghost/Net/Easy/toc.snap` — the annotation-overlay on-ramp; `What→Doc→Point` situating the
test / peer / transport / spec. Its `.g` Docs double as the loader's compile manifest.
Next: when heading W lands, the loader reads this list instead of the hardcoded `DOCKS`.

### 1a — CLI compiler  `[x]`  (lets the agent self-check `.g` files)
DONE. The pure translator was extracted verbatim from `LangCompiling.svelte` into
`src/lib/O/lang/compile.ts` (`export const LANG_COMPILE`, `@ts-nocheck` — it leans on a loose
`this`=House). The ghost now `import`s it and spreads `...LANG_COMPILE` into its eatfunc, so the
in-app path is **behaviour-identical** (verified: 23 methods conserved, type-check clean bar one
pre-existing implicit-any). Orchestration (active dock, `e:Lies_compiled` write-handoff, `dig`) stays
in the `.svelte`.
The CLI `scripts/lang-compile.ts` (run `npm run lang-compile -- <file.g>`, needs vite-node for the
registry's `?raw`/`import.meta.glob`/external tokenizer) builds the real stho parser via
`lang(lang_for_path(path))`, runs the extracted translator over a tiny C-shaped stub job, and prints
the generated module or the first compile error. Validated against the corpus (its output matches
`gen/test/LangTiles.go` save the ghostmeta dige — and flagged that committed `.go` as stale) and
already caught a real bug (a hyphen in a bareword peel value). Use it to check every `.g` edit.
NB: this also means the loader's headless `dock.c.state` stamp (heading 0) could instead call this
extracted compile directly — but the in-app **include** still needs the render (1b), so the loader
keeps driving the real pipeline for now.

### 1b — headless Story-runner + include  `[ ]`  (the bigger half)
Still GUI-coupled: **include needs Otro to render** the `UIs` bucket so the gen component's `onMount`
runs `eatfunc` (`Otro.svelte:109`); and the Story runner is driven by `story_drive` via `setTimeout`
+ GUI (`Story.svelte:1366`+). Goal: run a Book to completion headlessly, emitting the per-step snap.
Headless include = evaluate the gen module's `eatfunc` without the render (or drive a minimal Otro
over the Run's `UIs`). Surface: `story_drive`/`do_step`/`snap_step`/`advance` (`Story.svelte:1366-1680`),
`Run.main()`/`beliefs`/`all_clear` (`Housing.svelte.ts:811-860`), `Story_subHouse`
(`Story.svelte:1034`); stub Cyto waves + Storui buttons. Until this lands, Story verification is
in-app on :9091.

### 2 — Mock transport spine  `[~]`  (spec rung 1)
`Ghost/N/Peeroleum.g` `transport()` declares `%transport,type:mock` + `%active_transport,type:mock`.
Next (raw JS, objects on `.c`): a `mock_port(shared)` over a shared JS array + partner ref, wired to
`at.c.connection`; delivery `H.post_do(() => partner inbox <- frame)` (spec §15). One frame B→N
delivered, clean snap.

### 3 — hello+trust under mock → `%req:handshake,finished`  `[~]`  (rung 2)
`req_handshake` seeds the four maz leaves (said/heard hello, said/heard trust). Next: leaf do_fns —
each finishes when its protocol particle exists (`Pier/protocol/hello/%said` …); `say_*`/`hear_*`
write those particles and push `e:hello`/`e:trust` frames through `%active_transport`. Cross-side
short-circuit (spec §8). Wrangler `LakeNetherland` gets the `on_step{1,2}` table that drives it and
asserts via existence query + a `%witnessed,step:N` particle.

### 4 — outbox/inbox lifecycle + acks + whittle  `[ ]`  (rung 3)
`%outbox/emit:N` states (sent/acked), `%inbox/unemit:N` serial handling (queued/handling/verified/
delivered), acks, step-boundary cull to `%recent` (whittle 20). Spec §7, §12.

### 5 — per-req demand for time  `[ ]`  (rung 4; engine gap vs spec §13)
Spec §13 wants throwaway `%req:waiting,until:T` + a computed-max global. **Neither exists.** Today's
closest is the particle `%ttlilt` (`Hovercraft.svelte:163-352`) + extend-only global
`leave_running_until`. Decide: build §13 for real, or keep `ttlilt` and rewrite §13 prose. The
bootstrap loader already leans on `ttlilt`.

### 6 — corruption tests  `[ ]`  (rung 5)
`meddle_fn` on an eternal `%req:emit_corruption`, wrap installed on `%active_transport` (not
`Pier.emit`), so it's transport-agnostic. `on_step(4)` publicKey→not-them; `on_step(5)` sign→
invalid-signature; `%faulty,claim:step_N`. Re-applies `MachPeerily.svelte:725-794`. Spec §14.

### 7 — binary frames  `[ ]`  (rung 6)
`body` + `body_hash` folded into the one envelope; `test_binary` as just-another-frame; corruption
identical to a tweaked hello-sign. Spec §4.2, §15.

### 8 — disconnect + reset_handshake  `[ ]`  (rung 7)
`%active_transport e:close` → `o_elvis:reset_handshake` on the Pier: drop protocol/outbox/inbox/
faulty, keep `%Ud`; p2paddy re-dials. Spec §9.

### 9 — webrtc transport alongside mock  `[ ]`  (rung 8)
`PeerJS()` currently stamps `%faulty` immediately to force fall-through. Replace with the real PeerJS
DataChannel (relocated from old Peerily), which tries and may go `%faulty,reason` visibly. Spec §4.1.

### 10 — websocket fallback (the WebRTC-sucks proxy)  `[~]`  (rung 9)
`Socket()` declares `%transport,type:websocket`; `req_transport_select` switches `%active_transport`
to websocket when webrtc is faulty. Modeled on the mock queue this pass. Next: a real `/relay`
websocket endpoint on the dev server (:9091) that forwards a signed frame by `header.to` without
parsing `body`; client `c.connection` → real WS. Spec §4.1, §11.2, §17.

### 11 — Thangs persistence  `[ ]`  (rung 10)
`w:Thangs,thangs:peerings` / `thangs:identities` (Dexie) drive `req:p2pman` (online identities) and
`req:p2paddy` (known peers + `transport.last_good`). Spec §10.

### 12 — migrate Otro, delete Peerily, rename  `[ ]`  (rung 11)
Move Otro onto Peeroleum; delete `Peerily.svelte.ts` + `MachPeerily.svelte`; rename Peeroleum →
Peerily. Spec §16.

### L — LangTiles gaps to close  `[~]`  (so more of this lives in `.g`, not raw JS)
Done so far (all verified with `npm run lang-compile`, corpus output unchanged):
- **Loose peel values** — a bare value may now hold non-word chars (`reason:no-direct-route`),
  via an external `PathVal` token (`io_tokens.ts`) that fires only in value position and only when
  the run carries a non-word, non-dot char (so `mock` stays Name, `3.6` stays Number — no regression;
  stops at `,` `/` `:` `%` `...` whitespace; quote for spaces/commas). The reserved set is just
  `, : =` (`peel()`, `Y.svelte.ts:660`) plus path `/` and whitespace.
- **`n%such → n.sc.such`** — the `%` scalar-child accessor (CLAUDE.md's `Text%dige`), a string-aware
  text transform `Lang_sc_in_text` folded into the inline-atom pass + the raw fallthrough. Tight `%`
  (word before, letter after) only, so spaced modulo `a % b` and a leading `%Foo` PuddleSigil are
  untouched; chains fold (`n%a%b → n.sc.a.sc.b`). Convention: tight `%` is sc-access, modulo needs
  spaces.
- **NB regen:** editing `stho.grammar` makes the generated `stho.grammar.ts` artifact stale — the
  registry `resolve()` falls back to a live `buildParser` (correct, just flagged stale). Regen the
  artifact via the in-app gen action when convenient.

Still open — each a place the spine dropped to raw JS:
- auto-`async` on a method whose body has a bare `await`-verb (`r/rm/roai`/`await x.do()`).
- `drop`/`empty`/`oa` verbs; deep/wildcard `drop Pier/protocol/**`.
- drilled paths on `oai/r/rm` (seed a `%req` under a nested host without pre-resolving it).
- an `H`-receiver actor-laying form (`H i %A:..` laying a sibling actor).
- object/`.c` payloads (`c.connection`, `stashed:{…}`).
- list fan-out / column capture (one `%req:dial` per peer over a thang list).
Corpus + compiler: `Ghost/test/LangTiles.g`, `src/lib/O/LangCompiling.svelte`, `LangCompiler_TODO.md`.

### W — Hide compilation behind Waft architecture  `[ ]`
Make opening a Waft auto-compile its `.g` Docs, so the loader's explicit `Dock_open` loop (and the
hardcoded `DOCKS`) disappears — the Net/Easy overlay's Docs become the manifest directly.

---

## Files in play
- `src/lib/O/test/Peregrination.svelte` — bootstrap loader (hand-written, mounted in Machinery).
- `Ghost/Story/Peregrination.g` — `LakeNetherland`, the wrangler (compiled).
- `Ghost/N/Peeroleum.g` — the spine (compiled).
- `wormhole/Ghost/Net/Easy/toc.snap` — annotation overlay / compile manifest.
- `wormhole/Story/Peregrination/toc.snap` — the Story that drives the loader.
- `src/lib/O/spec/Peeroleum_spec.md` — the pinned design. This file — the living progress.
