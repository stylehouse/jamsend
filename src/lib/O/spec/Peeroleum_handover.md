# Peeroleum handover

The living checklist for retiring `Peerily`/`MachPeerily` and growing `Peeroleum` against
`Peeroleum_spec.md`. Each heading is meant to shrink as it is solved. This file is the memory the
work would otherwise re-type into each session — keep it current, correct anything stale.

Notation: `[x]` done · `[~]` started/scaffolded · `[ ]` not begun · `// <` a deliberate hole.

---

## Status — start here

**The harness is done and proven in-app** (clean quiescent snap, no timeout): the hand-written
loader compiles + includes both `.g` docks and calls through to the compiled `LakeNetherland`, which
seeds its `%req:wrangle`. Heading 0 ✓, the CLI compiler 1a ✓, two LangTiles grammar wins (L) ✓.

**Heading 2 (mock transport spine) is built and compiles — awaiting the in-app proof.** The spine's
`transport()` now wires a mock-port on `at.c.connection`; the wrangler stands up both sides, pairs the
ports, and pushes one frame B→N. Run the Peregrination Story on :9091 to confirm the clean quiescent
snap (see heading 2). **Next real work: heading 3** — the hello/trust handshake leaf do_fns to
`%req:handshake,finished`. Check every `.g` edit with `npm run lang-compile -- <file>`.

## How the loop works (heading 0)

A `.g` ghost's methods exist on `H` only once the dock is compiled + included (compile →
`src/lib/gen/**.go` → Pantheate `import()` → Otro mount → `eatfunc`). So the top of the test regime
is hand-written `src/lib/O/test/Peregrination.svelte` (mounted in `Machinery.svelte`), not a `.g`.
`Run_A_Peregrination` lays `A:Peregrination` and plonks `A:Lies/A:Lang/A:Pantheate` into the Story Run
(those workers must live in the Run so its own `think`/`reqdo_sweep` pumps the compile chain). Each
tick `Peregrination(A,w)` runs a `%req:ensure_compiled` per `.g` that:
1. reads the source — `H.LiesStore_read_good(wLies,'text/Doc',path)`;
2. mints+wires the dock under `w:Lang/docks` and stamps a **headless** `EditorState.create({doc,
   extensions: await lang(lang_for_path(path))})` (lang registry — NOT legacy `O/stho.ts`);
3. compiles directly — `H.Lang_compile_dock(wLang, dock)` → write → Codebit → Pantheate → include;
4. polls `H[Lang_ghostmeta_name(path)]`; on confirm stamps `w/%compiled,path` and finishes.
When all finish, `await H.LakeNetherland(A,w)` — the compiled wrangler, just a method on `H` now.

Driven by the **Peregrination Story** (`wormhole/Story/Peregrination/toc.snap`), whose Prep opens the
**Ghost/Net/Easy** Waft overlay (`wormhole/Ghost/Net/Easy/toc.snap`) — its `.g` Docs are the manifest.

Run: dev server :9091 → run the `Peregrination` Story → both `w/%compiled,path` flip, both
`req:ensure_compiled,finished`, and `w:Peregrination/%req:wrangle,eternal` appears (LakeNetherland's
write — its `%see` lines get swept at the step boundary like `%log`). Clean quiescent snap = proven.

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

### 0 — Bootstrap loader  `[x]`  DONE
Hand-written `src/lib/O/test/Peregrination.svelte` (mounted in `Machinery.svelte`) reads, compiles,
includes both `.g` docks **self-sufficiently** and calls through to `H.LakeNetherland`. Proven in-app
with a clean quiescent snap: both `req:Codebit`/`req:include` finished, both `%compiled` flipped,
`%req:wrangle` seeded by the compiled wrangler.

The loader, per `.g`: read via `H.LiesStore_read_good(wLies,'text/Doc',path)`, mint+wire the dock
under `w:Lang/docks`, stamp a **headless** `EditorState.create({doc, extensions: await
lang(lang_for_path(path))})` (lang registry — `lang/lang.ts`, NOT legacy `O/stho.ts`), then
`H.Lang_compile_dock(wLang, dock)` — the real collect→render→write→Codebit→Pantheate→include chain,
**no editor/cursor**.

Things learned / dead ends:
- Dock-minting is **cursor-driven** — `dock_askies`/`Dock_open` only furnish the doc the editor's
  Interest cursor is parked on; a bare pull reads the file but mints no dock. The self-sufficient
  path above sidesteps that entirely.
- The compiler reads the stho parser from the EditorState facet line-by-line
  (`LangCompiling.svelte:339,478`), so a headless `EditorState` (no view) is enough — the
  `e_Lang_editorBegins`/`waiting:cm_mount` editor gate is bypassed.
- Include does NOT need a special headless step — Pantheate `import()`s the gen module and Otro
  mounts it (its `eatfunc` runs, Ghostmeta confirms). **Fixed a real bug**: Pantheate keyed every
  include under one `UI:Pantheate-include` slot (`LiesCortex.svelte:271`), so two simultaneous
  includes collided and only one mounted — now keyed by `gen_path` (`LiesCortex.svelte:271`).

Currency gate (done): the loader reads the source, computes `dig(text)`, and **skips the recompile
when `H.Ghostmeta_<name>() === that dige`** — so a `.g` already compiled+included by a prior test
reset is reused, while a drifted dige (edited `.g`) recompiles, never masked by a stale prior compile.

Note on "headless": this means **editor-less / cursor-less** compile (no CodeMirror view, no Interest
cursor) — but the run is still **in-browser**: Otro must mount the gen components so their `eatfunc`
runs (= include). A genuinely no-browser run is heading 1b.

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

### 1b — headless Story-runner  `[ ]`  (the bigger half)
Include is NOT a blocker — it works in-app (Pantheate import + Otro mount; the slot-collision bug is
fixed). What remains for a *fully headless* run (no browser) is the Story runner itself, driven by
`story_drive` via `setTimeout` + GUI (`Story.svelte:1366`+), and the Otro render that mounts gen
components (a headless run would need to evaluate the gen module's `eatfunc` without a DOM, or drive
a minimal Otro over the Run's `UIs`). Goal: run a Book to completion headlessly, emitting the
per-step snap. Surface: `story_drive`/`do_step`/`snap_step`/`advance` (`Story.svelte:1366-1680`),
`Run.main()`/`beliefs`/`all_clear` (`Housing.svelte.ts:811-860`), `Story_subHouse`
(`Story.svelte:1034`); stub Cyto waves + Storui buttons. Until this lands, Story verification is
in-app on :9091.

### 2 — Mock transport spine  `[x]` built, awaiting in-app proof  (spec rung 1)
The spine's `transport()` (`Ghost/N/Peeroleum.g`) declares `%transport,type:mock` +
`%active_transport,type:mock,open` and wires a **mock-port** on `at.c.connection` (raw JS, objects on
`.c`): `send(frame)` → `H.post_do(() => this.partner?.recv(frame))`, `recv(frame)` →
`H.Peeroleum_deliver(w, frame)`. `partner` starts null; the wrangler pairs the two ports. Two new spine
helpers carry the one envelope (spec §4.3): `Peeroleum_send` stamps `%outbox/emit:N,sent` then hands the
frame to the active transport; `Peeroleum_deliver` lands `%inbox/unemit:N,delivered` and `feebly_ponder`s
so a watching do_fn reacts the same run. (Both heading-2 minimal — acks + the rest of the §7 serial
states are heading 4.)

The wrangler `LakeNetherland` (`Ghost/Story/Peregrination.g`) stands up both sides directly (spec §15):
`A:Bearing` / `A:Nearing`, each `w:Peeroleum` with a `%Peering`/`%Pier` (named by the *peer's*
identity) and a mock transport; it pairs `bport.partner = nport` (and back), then `Peeroleum_send`s one
`{header:{type:hello,from:bearing,to:nearing,seq:1}}` B→N. Its `%req:wrangle,eternal` do_fn witnesses the
delivery and stamps `%witnessed:step_1` (the step rides in the *value* — `step` is the Story mainkey, so
it can't be a key). All raw JS: H-receiver actor-laying, objects-on-`.c`, drilled paths — tracked seams.

**To prove:** dev server :9091 → run the `Peregrination` Story. Clean quiescent snap should show, on
Nearing, `%Peering/%Pier/%inbox/%unemit:1,type:hello,seq:1,delivered`, the sender's
`%outbox/emit:1,sent` on Bearing, and `w:Peregrination/%witnessed:step_1`. (`%see` lines sweep at the
step boundary.) Both `.g` compile clean via `lang-compile`, and their generated modules parse as valid
JS. **NB:** the committed `gen/N/Peeroleum.go` + `gen/Story/Peregrination.go` are now stale vs the edited
`.g`; the loader's dige gate recompiles + rewrites them on the next in-app run — no hand-edit needed.

### 3 — hello+trust under mock → `%req:handshake,finished`  `[~]`  (rung 2)
`req_handshake` seeds the four maz leaves (said/heard hello, said/heard trust). Next: leaf do_fns —
each finishes when its protocol particle exists (`Pier/protocol/hello/%said` …); `say_*`/`hear_*`
write those particles and push `e:hello`/`e:trust` frames through `%active_transport`. Cross-side
short-circuit (spec §8). Wrangler `LakeNetherland` gets the `on_step{1,2}` table that drives it and
asserts via existence query + a `%witnessed:step_N` particle (step in the value — `step` is a mainkey).

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
