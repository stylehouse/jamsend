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

### 0 — Bootstrap loader  `[x]` (this pass)
Hand-written `src/lib/O/test/Peregrination.svelte` compiles + includes the `.g` docks and calls
through to `H.LakeNetherland`. Mounted in `Machinery.svelte`. Story + overlay scaffolded.
Next: the strict currency gate — `included()` currently accepts any prior compile; the rigorous
check is `H[ghostmeta]() === source_dige` (`LiesCortex.svelte:304`). Wire it (read the dock source,
`dig()` it) so edits to a `.g` are picked up without a stale-version false-positive.

### 0b — Net/Easy Waft overlay  `[x]`
`wormhole/Ghost/Net/Easy/toc.snap` — the annotation-overlay on-ramp; `What→Doc→Point` situating the
test / peer / transport / spec. Its `.g` Docs double as the loader's compile manifest.
Next: when heading W lands, the loader reads this list instead of the hardcoded `DOCKS`.

### 1 — CLI compiler + headless Story-runner  `[ ]`  (major infra — lets the agent measure itself)
There is no CLI compiler today; compilation is the in-app Lies pipeline, and the Story runner is
driven by `story_drive` via `setTimeout` chains + the GUI (`Story.svelte:1366`+). Goal: a headless
entry that (a) compiles a `.g` by path and (b) runs a Book to completion, emitting the per-step snap,
so changes can be verified outside the browser. Surface to assemble from: `story_drive`/`do_step`/
`snap_step`/`advance` (`Story.svelte:1366-1680`), `Run.main()`/`beliefs`/`all_clear`
(`Housing.svelte.ts:811-860`), `Story_subHouse` (`Story.svelte:1034`). GUI-bound bits to stub: Cyto
waves, Storui buttons. Until this lands, verification is in-app on :9091.

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

### L — LangTiles gaps to close  `[ ]`  (so more of this lives in `.g`, not raw JS)
Each is a place the spine dropped to raw JS:
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
