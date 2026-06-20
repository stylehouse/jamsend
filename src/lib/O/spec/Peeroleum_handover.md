# Peeroleum handover

The living checklist for retiring `Peerily`/`MachPeerily` and growing `Peeroleum` against
`Peeroleum_spec.md`. Each heading is meant to shrink as it is solved. This file is the memory the
work would otherwise re-type into each session — keep it current, correct anything stale.

Notation: `[x]` done · `[~]` started/scaffolded · `[ ]` not begun · `// <` a deliberate hole.

---

## Status — start here

**Proven in-app, rungs 0–3 (clean quiescent snap, no timeout):** the loader compiles+includes both
`.g` docks and calls `LakeNetherland`; the mock transport carries frames A↔B (heading 2); and at
**step 3 the full hello+trust handshake completes** — both Piers `%req:handshake,finished` (all four
leaves), `protocol/{hello,trust}/{said,heard}`, `%Ud,publicKey`, inbox/outbox pairs,
`%witnessed:step_3`. Heading 0/1a/2/3/4 ✓, LangTiles wins (L) ✓. **Heading 4 (full outbox/inbox
lifecycle + acks + whittle) is PROVEN in-app at step 3** — monotone seq (noop=1/hello=2/trust=3 on
Alice, hello=1/trust=2 on Bob), every `%outbox/emit,sent,acked` + `protocol/%said,acked`, inbox
`%unemit,verified,done,to:<type>`, the step-2 noop culled to `%inbox/recent`/`%outbox/recent`, no
`%faulty`. Record the diges (Accept/Resnapture) to make it a regression gate.

### → START HERE: real websocket transport (heading 10) — editor↔runner is its first customer

**Active direction (settled with the human).** The editor↔runner channel is NOT new construction — it is
the first real customer of heading 10's websocket transport, so the music-app peers and Lies (editor/runner)
become two consumers of ONE envelope/transport/ack/faulty machinery. Full settled design under **heading 10**
below. The determinism worry is moot: a cross-socket wait wraps in a `%req` with `i_req_ttlilt(req,secs,
{waiting})`, so the step holds open until the ack lands (req finishes) or it times out — the waiting-req is
the quiescence gate, the in-process `post_do` shortcut is not load-bearing. (The *live* editor↔runner channel
isn't Story-snapped at all, so it self-drives on `feebly_ponder`; the ttlilt is just the no-ack give-up timer.)

**Build progress (this session):**
- **[x] (1) Real `/relay` WS server — PROVEN.** `src/lib/server/relay.ts` (`attachRelay`) + a `configureServer`
   vite plugin in `vite.config.ts`. Two-AP routing, structural loop-safety, set-once browser-commanded role
    (errorific), single r2r bridge. Proven node-side by `scripts/relay-test.ts` (10/10: same-origin, cross-relay
     both ways, set-once conflict errors, unknown-addr drop, no loopback) AND live on `vite dev :9091`
      (`/relay` routed a frame, HTTP 200, HMR intact). `ws` 8.18.2 = vite's existing dep, no new package.
- **[x] (2) Real WS carrier port — COMPILES.** `Socket_real(w)` + `Tribunal_activate_websocket(w)` in
   `Ghost/N/Tribunal.g`: a native `WebSocket` to own-origin `/relay?addr=<Peering name>`, send-buffered-until-open,
    inbound delivery wrapped in `post_do` → `Peeroleum_deliver`. The mock `Socket`/pairing is UNTOUCHED so the
     Peregrination test keeps its determinism; this is the production path. `lang-compile` clean; not yet run in-app.
- **[x] (3) Consumer dispatch seam — COMPILES.** `Peeroleum_on(w,type,fn)` (per-w `w.c.on` registry),
   `Peeroleum_send_consumer(w,type,body)`, `Peeroleum_peer_ready(pier)` in `Ghost/N/Peeroleum.g`;
    `Peeroleum_pump_inbox` now dispatches non-hello/trust types to the registered handler inside the same
     inbox/ack/faulty lifecycle. `lang-compile` clean; not yet run in-app.
- **[ ] (4) Lies as first consumer — NEXT, needs in-app.** Editor emits `dock_push` (the `.go` bytes) on
   `write_finished`+`w%editor`; runner registers `Peeroleum_on(w,'dock_push',…)` landing via
    `LiesStore_land_good→drain_good`; `run_result` flows back. Depends on the Editron compile-without-mounting
     split (gate `Ghost_update_notify` on `!w%editor`). Deliberately NOT written blind — the full House/Story
      machine has no UIless runner yet (heading 1b), so this must be built against a live browser. Precise
       plan in the session handoff. **The committed `gen/**.go` are stale vs the new `.g`; the loader's dige
        gate regenerates them on the next in-app run (do not hand-edit gen).**

**Test status (transport trial, steps 2–6):** steps 2–5 proven in-app; **step 6 was BROKEN, now FIXED.**
`Lake_trial_confirm` re-checked `probe.sc.acked` on the relay-probe emit, but the step-5→6 boundary cull
had moved it to `%outbox/recent`, which STRIPS `%acked` — so it bailed and never stamped
`%reputation:good`/`%witnessed:step_6`. Fix (`Ghost/Story/Peregrination.g`): presence in `%recent` IS the
ack proof (the cull moves ONLY acked emits there); a still-live emit must still carry `%acked`. `lang-compile`
clean. **Re-run to confirm step 6 goes green, then Accept/Resnapture steps 2–6** to make the diges real
regression gates. Then heading 6 (corruption tests).

**Prerequisite unblocked (compiler robustness — why the editor wrote uncompiled `.go`):** task (4) needs
the editor to compile cleanly, and that was gated by a real bug — a compile firing before the language
parser landed on the dock's `EditorState` emitted raw `.g` passthrough and WROTE it as the `.go`, with
nothing validating. Fixed: `req_compile` now waits for the parser (`waiting:'parser'` ttlilt) + a
`Lang_has_lang_parser` guard in `Lang_compile_dock`; `lang-compile` now syntax-gates its output (esbuild).
Full write-up in `LangCompiler_TODO.md` ("validating the compile output"). Both in-app fixes still want a
browser re-run to confirm.

**The webrtc→websocket transport trial (steps 4–6) works in-app** — mocked, step-paced, in
`Ghost/N/Tribunal.g` (details under **heading 9/10** below). Proven on :9091 through step 5: step 4 hands
the carrier to webrtc and probes it (black-holed, un-acked); step 5 is no-ack-then-give-up — both fall to
`%transport,type:webrtc,faulty,reason:no-ack` + `%active_transport,type:websocket` and the relay *carries*
(`emit=5,…,acked` / `unemit=5,…,verified,done`); step 6 stamps `%reputation:good`. `witnessed:step_4/5`
seen. **Next: eyeball step 6, then Accept/Resnapture steps 2–6** so the diges become regression gates
(every step reshaped — step 4/5/6 are brand new). Then **heading 6** (corruption tests). No wall-clock /
`ttlilt` in the trial anymore — it's paced by steps, so UIless `Story_cli` should no longer time out on it.

Heading 4 — outbox/inbox lifecycle + acks + whittle (spec rung 3, §7 + §12) — ran clean in-app at
step 3 (the diff matched the expected shape below exactly; the loader regenerated both `.go`). The only
loose end is **recording the true diges**: Accept/Resnapture so steps 2–5 become regression gates (every
step snap reshaped — step 2 shows the noop live pre-cull, step 3 the full handshake lifecycle, the
boundary empties outbox/inbox into `%recent`, step 4 the transport trial). After that, **heading 6**
(corruption tests) — heading 5 (per-req demand) is CLOSED: `ttlilt` is the waiting-req, tune its seconds
if it ever times out, don't build §13 (see heading 5 below). What landed in heading 4 (detail + bombs
under **heading 4** below):
- **Per-Pier monotone `seq`** (`Pier_next_seq`, a `Pier.c.seq` counter): each real outbound frame
   allocates the next; acks consume none. So Alice's frames are noop=1, hello=2, trust=3; Bob's
    hello=1, trust=2 — all distinct emits.
- **Outbox `created→sent→acked`**: `Peeroleum_send` books a `%outbox/emit,sent` for non-ack frames;
   an inbound ack (`Peeroleum_take_ack`) stamps the matching `%emit` (and protocol `%said`) `%acked`.
- **Acks**: every verified non-ack inbound frame triggers `e:ack%ack:<seq>` back; `Peeroleum_deliver`
   has an `h.type==='ack'` branch distinct from the inbox, and acks are never themselves acked.
- **Serial inbox** (`Peeroleum_pump_inbox`): `%unemit` walks `queued→handling→verified→done`, at most
   one `%handling` at a time, pre-`%Ud` gate (hello|noop only), `%error→%faulty` on failure.
- **Step-boundary whittle** (`Peeroleum_runstepped`, armed via self-re-arming `Runstepped`): acked
   emits → `%outbox/recent`, done unemits → `%inbox/recent` (both whittle 20), `%faulty` rebuilt.
- **Duplicate A→B hello dissolved**: step 2's scaffold frame is now `type:noop` (a pure carrier+ack
   ping that still stamps `%witnessed:step_2`), so the real hello is sent exactly once, at step 3.

**The in-app run will reshape every step snap** (outbox/inbox now carry the full lifecycle, and the
boundary culls acked/done items into `%recent` after each step). So the `toc.snap` step diges — already
lies — are doubly stale now. Run the `Peregrination` Story on :9091, eyeball the lifecycle against
**heading 4** below, then Accept/Resnapture so the diges become real regression gates. (`Story_cli`
produces a Peregrination pile too — read `witnessed:*`/`A:Peregrination`, the `A:Lang` AST blob is
noise on every step; see the `peregrination-pile-reading` memory + `Story_cli_docs.md`.)

### Standing asks (apply to every heading)

- **Write the spine in the DSL, not raw JS.** Heading L covers a lot — `%` optional on peels, `H`
   receiver for actor-laying, multi-assign two-leg row-capture (`let {AB,wB} = H i A:..$AB/w:..$wB`),
    drilled-`o` captures (`pier o protocol/hello/said$:said`), `&name,a,b` calls. Reach for a LangTiles
     extension before dropping to raw JS; only object/`.c` seams (mock-port pairing, frame objects off
      the wire, dynamic-value writes) stay raw. Check every `.g` edit with `npm run lang-compile -- <file>`.
- **The c.up rule (bit me in heading 3).** A `%req` hosted below `w` (under Pier/Peering) silently
   never pumps unless you stamp the host chain's `c.up` — the belief walk wires `A`/`w` only. So
    heading 4's new reqs (e.g. `%req:send` under a Pier, §11.3) need the same `Pier.c.up=Peering` etc.
- **Working tree left uncommitted for the human.**

## How the loop works (heading 0)

A `.g` ghost's methods exist on `H` only once the dock is compiled + included (compile →
`src/lib/gen/**.go` → Pantheate `import()` → Otro mount → `eatfunc`). So the top of the test regime
is hand-written `src/lib/O/test/Peregrination.svelte` (mounted in `Machinery.svelte`), not a `.g`.
`Run_A_Peregrination` lays `A:Peregrination` and plonks `A:Lies/A:Lang/A:Pantheate` into the Story Run
(those workers must live in the Run so its own `think`/`reqdo_sweep` pumps the compile chain). Each
tick `Peregrination(A,w)` runs a `%req:ensure_compiled` per `.g` that:
1. reads the source — `H.LiesStore_read_good(wLies,'text/Doc',path)`;
2. mints+wires the dock under `w:Lang/docks` and stamps a **UIless** `EditorState.create({doc,
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
under `w:Lang/docks`, stamp a **UIless** `EditorState.create({doc, extensions: await
lang(lang_for_path(path))})` (lang registry — `lang/lang.ts`, NOT legacy `O/stho.ts`), then
`H.Lang_compile_dock(wLang, dock)` — the real collect→render→write→Codebit→Pantheate→include chain,
**no editor/cursor**.

Things learned / dead ends:
- Dock-minting is **cursor-driven** — `dock_askies`/`Dock_open` only furnish the doc the editor's
  Interest cursor is parked on; a bare pull reads the file but mints no dock. The self-sufficient
  path above sidesteps that entirely.
- The compiler reads the stho parser from the EditorState facet line-by-line
  (`LangCompiling.svelte:339,478`), so a UIless `EditorState` (no view) is enough — the
  `e_Lang_editorBegins`/`waiting:cm_mount` editor gate is bypassed.
- Include does NOT need a special UIless step — Pantheate `import()`s the gen module and Otro
  mounts it (its `eatfunc` runs, Ghostmeta confirms). **Fixed a real bug**: Pantheate keyed every
  include under one `UI:Pantheate-include` slot (`LiesCortex.svelte:271`), so two simultaneous
  includes collided and only one mounted — now keyed by `gen_path` (`LiesCortex.svelte:271`).

Currency gate (done): the loader reads the source, computes `dig(text)`, and **skips the recompile
when `H.Ghostmeta_<name>() === that dige`** — so a `.g` already compiled+included by a prior test
reset is reused, while a drifted dige (edited `.g`) recompiles, never masked by a stale prior compile.

Note on "UIless": this means **editor-less / cursor-less** compile (no CodeMirror view, no Interest
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
NB: this also means the loader's UIless `dock.c.state` stamp (heading 0) could instead call this
extracted compile directly — but the in-app **include** still needs the render (1b), so the loader
keeps driving the real pipeline for now.

### 1b — UIless Story-runner  `[ ]`  (the bigger half)
Include is NOT a blocker — it works in-app (Pantheate import + Otro mount; the slot-collision bug is
fixed). What remains for a *fully UIless* run (no browser) is the Story runner itself, driven by
`story_drive` via `setTimeout` + GUI (`Story.svelte:1366`+), and the Otro render that mounts gen
components (a UIless run would need to evaluate the gen module's `eatfunc` without a DOM, or drive
a minimal Otro over the Run's `UIs`). Goal: run a Book to completion UIlessly, emitting the
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
frame to the active transport; `Peeroleum_deliver` lands `%inbox/unemit:N,done` and `feebly_ponder`s
so a watching do_fn reacts the same run. (Both heading-2 minimal — acks + the rest of the §7 serial
states are heading 4.)

**Step-driven now (inner steps start at 2).** Step 1 is the bootstrap (compile+include), owned by the
loader. `LakeNetherland` (`Ghost/Story/Peregrination.g`) shrank to: install `%req:wrangle,eternal` whose
do_fn calls `Lake_drive(w, req)` each pass. The work lives in flat helpers: `Lake_sides_up(w)` (step 2 —
stand up `A:Alice`/`A:Bob`, each `w:Peeroleum` with a `%Peering`/`%Pier` named by the *peer's*
identity + a mock transport; pair the ports; `Peeroleum_send` one A→B frame; stamps `%reached:step_2`),
`Lake_handshake(w)` (step 3 — seed+pump `%req:handshake` on each Pier; stands the four-leaf tree up but
not to `finished`, since the leaf do_fns are heading 3), steps 4/5 stamp `%reached:step_N` placeholders.
`Lake_witness` stamps `%witnessed:step_2` once Bob's inbox shows a handled (`%done`) frame (step in the
*value* — `step` is the Story mainkey, so it can't be a key). All raw JS: H-receiver actor-laying,
objects-on-`.c`, drilled paths — tracked seams.

`wormhole/Story/Peregrination/toc.snap` carries one `step,…` line per inner step (`step,dige:…` =1, then
`step=2…5,dige:…`); the diges are **lie diges** (real seq, fake hash) until a run records the true ones.

**Why NOT `H.on_step` (a real bug, fixed):** `on_step` keys off one H-global `did_on_step_n`. When the
cold-compile/include spills into step 2, the loader's step-1 path still runs and claims step 2 (its table
has no key 2) → the wrangle's step-2 setup is **starved**. The tell was a step-3 snap with `%reached:step_3`
present but no `A:Alice`/`A:Bob` and no `%witnessed:step_2` (step 3 fired, step 2 didn't). Fix:
`Lake_drive` keeps a **req-local `req.c.did_step`** (read `H.c.run.c.step_n` the way `on_step` does), immune
to any other caller; and the loader dropped `on_step` entirely, seeding `ensure_compiled` directly
(idempotent via `doai`). Two-dock include also tripped a latent render crash — `each_key_duplicate` on
`UI:Pantheate-include` (both includes share that name) — fixed by keying Otro's UI `{#each}` on
`keyser(uiC.sc)` (full identity incl. `gen_path`), not `uiC.sc.UI` (`Otro.svelte:110`).

**Proven in-app (step 2 ✓):** the step-2 snap shows `A:Alice/%Peering/%Pier/%outbox/%emit,…,sent`,
`A:Bob/%Peering/%Pier/%inbox/%unemit,…,done`, and `w:Peregrination/%reached:step_2 +
%witnessed:step_2`. The frame crossed the mock transport and was handled (`%done`). (`%see` lines sweep at the
step boundary.) Both `.g` compile clean via `lang-compile`; their generated modules parse as valid JS.

**Runner-snap fold (`%dontSnap`):** step 2's snap was still drowned by the compile apparatus — `A:Lies`
(the GhostList dirlist of every source file) and `A:Lang` (the *entire* generated `.go` text, twice,
under `dock/Compile/Output/source`). New snap-only knob: a node carrying `%dontSnap` emits its own line
but the walk descends no further (`Story.svelte` `snap_H` each_fn sets `T.sc.more = []`; `[]` is truthy so
it short-circuits the child query in `Selection.dive_middle:142`). It's **orthogonal to pump** — the
folded w keeps thinking, so an edited `.g` still recompiles. The loader stamps `w:Lies.sc.dontSnap` +
`w:Lang.sc.dontSnap` at call-through (apparatus ready); **Pantheate stays** (its `%req:include,finished`
is the runner-state that makes `LakeNetherland`'s methods exist). To fold the `A:Lies` `self,round`
age-line too, stamp the `A:` instead of the `w:`.

**Runner-flavoured Lies (`w%runner`) — done:** `%dontSnap` only *hid* GhostList; the dirlist Funkcion
still walked `/src` every 8s. So the loader now stamps `w:Lies.sc.runner` + `w:Lang.sc.runner` at Run
wiring, and `Lies.svelte` (the Waft-settle phase, ~line 704) skips provisioning GhostList when
`w%runner` — the index never seeds, the Funkcion never walks, the `Interest:GhostList` never appears.
A runner's commission to Lies is read→compile→include only. The Prep's `Lies_open_Waft Ghost/Net/Easy`
opens the overlay *in the editor*, which pulls the navigation apparatus (`Interest:Trail`, an active
`dock:…Peregrination.svelte`, `Navicade`/`Pmirrors`) into `watched:ave` — and `%dontSnap` on
`w:Lies/w:Lang` doesn't reach `ave`. **Folded:** the `Languinio` (Lang's ave-enrolled focus object that
holds all that) gets `%dontSnap` stamped on creation when `w:Lang%runner` (`Lang.svelte:332`), so it
collapses to one line. (Snap-only — the editor still runs; a true runner that opens no editor Trail is
the deeper version, when wanted.) `UI:Ballistics` in the snap is unrelated parallel work.

**Peers-first ordering:** `Lake_order` floats `A:Alice`/`A:Bob` (the subject under test) above the
apparatus actors via `H.place({A:1}, sorted)` (the `Lies_order_wafts` idiom — re-enters the same C's in
order, no-ops once sorted). Called each pass from `Lake_drive`, so the snap reads peers-first.

**NB:** the committed `gen/N/Peeroleum.go` + `gen/Story/Peregrination.go` track the `.g`; the loader's
dige gate recompiles + rewrites them on the next in-app run if they drift — no hand-edit needed.

### 3 — hello+trust under mock → `%req:handshake,finished`  `[x]`  PROVEN in-app at step 3  (rung 2)
The four leaf do_fns + the say/hear exchange + frame dispatch (`Ghost/N/Peeroleum.g`), plus the
wrangler's per-pass re-pump + step-3 witness (`Ghost/Story/Peregrination.g`). Confirmed at step 3:
both Piers `%req:handshake,finished`, full `protocol/{hello,trust}/{said,heard}`, `%Ud,publicKey`,
inbox/outbox pairs, `%witnessed:step_3`. The shape:

**Duplicate A→B hello — RESOLVED in heading 4.** The step-3 snap used to show TWO
`outbox/emit,type:hello` on Alice: step 2's scaffold frame + step 3's real `say_hello`. Heading 4
made step 2's scaffold a `type:noop` (a pure carrier+ack ping; spec §7.3 sanctions `noop` pre-Ud and
`Peeroleum_pump_inbox` dispatches it to no hear_*), so step 2 still proves the carrier and stamps
`%witnessed:step_2`, and the hello is now sent exactly once (at step 3).

**Spine (`Peeroleum.g`):**
- `req_said_hello/heard_hello/said_trust/heard_trust` — each finishes the instant its protocol
   particle exists (`pier o protocol/hello/said` … via a drilled-`o` capture, clean DSL). The
   `said_*` leaves also *perform* the say (idempotent on the protocol particle); the `heard_*` are
   pure existence checks, fed by the far side. maz 4→3→2→1 with the `do()` `some(needs_work)` gate
   means trust never precedes hello.
- `say_hello/say_trust(w,pier)` — write `Pier/protocol/<kind>/%said,seq` (DSL) and emit one
   `e:hello`/`e:trust` frame via `Peeroleum_send` (frame object stays raw — JS off the wire).
   Identity in the mock: Peering `%name` = our address, Pier `%pub` = the peer it faces, `publicKey`
   we send IS our name → `hear_*` verifies `startsWith(pub)`.
- `hear_hello/hear_trust(w,pier,frame)` — raw (frame is a JS object, writes carry dynamic values):
   verify, write `%heard,publicKey` + set `%Ud` (their identity, survives resets — §6); `hear_hello`
   says back if `!said` (the single-init path; a no-op under the symmetric dual-init).
- `Peeroleum_deliver` now dispatches the inbound frame to `hear_hello`/`hear_trust` by `header.type`.

**Wrangler (`Peregrination.g`):** `Lake_pump_handshakes(w)` re-pumps each Pier's `%req:handshake`
every pass (called from `Lake_drive` before the witness); `Lake_witness` stamps `%witnessed:step_3`
once both Piers' `%req:handshake` are `finished`.

**The bombs (what detonates if the next reader doesn't have it):**
- **Nested reqs below `w` need `c.up` stamped by hand — the walk only wires `A`/`w`.** First
   in-app run of step 3 showed `req:handshake` standing up on both Piers but with *no leaves, no
   error* — the classic silent no-handler. Cause: the belief walk wires `A.c.up` (Housing ~992) and
   `w.c.up` (~1021) but nothing wires domain particles under `w` (`Peering`/`Pier`), so `pier.do()` →
   `_req_do_one` climbs `pier.c.up` (undefined) and never reaches the House to resolve `req_handshake`
   — the req just stays `needs_work` and is skipped, no throw. Fix (in `Lake_sides_up`): stamp
   `Peering.c.up=w; Pier.c.up=Peering` (the migration idiom — cf `examining.c.up=w`, `funks.c.up=w`).
   Heading 2 never hit this — it only ever walked *down* (`w.o({Peering})…o({Pier})`); heading 3 is
   the first to pump a Pier-hosted req. **In production the spine must do the same when `req_p2paddy`
   ensures a `%Pier`** (§11.2): a Pier built without a `c.up` to its w is a Pier whose handshake never
   pumps. (`req.oai/doai` DO set `req.c.up=host` — line 551 — so the req tree itself is fine; it's the
   non-req host chain `Pier→Peering→w` that the walk leaves unwired.)
- **Re-pump lives in the wrangler, NOT reqdo_sweep.** The handshake is nested (`Pier/Peering/w`),
   below reqdo_sweep's w-level reach, so nothing auto-pumps it. `Lake_pump_handshakes` (each pass)
   is the driver; delete it and the leaves freeze after step-3 seeding. (Production will pump via the
   spine's per-Pier worker once `req_p2paddy` seeds the handshake — §11.2/§11.3 — but the test
   wrangler lays sides directly and drives them itself.)
- **The step holds open via the `post_do`/`feebly_ponder` chain — no ttlilt needed.** Each
   `Peeroleum_send` `post_do`s a delivery (keeps `Run.todo` non-empty → `poll_step` not quiescent);
   each `Peeroleum_deliver` `feebly_ponder`s (→ `think` → `reqdo_sweep` → `Lake_drive` →
   `Lake_pump_handshakes` → `pier.do()`), so the say→hear→say_trust→hear_trust round-trip self-drives
   to completion inside one step, exactly as heading 2's single delivery did. If an in-app run snaps
   mid-handshake, the spec-aligned fix is a waiting ttlilt on the handshake req (`H.i_req_ttlilt`)
   **plus** `H.i_scheme_req(w,[{Peering:1},{Pier:1}])` so `i_Story_o_req_ttlilt` can reach the nested
   req — but bet on the chain first.
- **Symmetric dual-init.** Both sides run all four leaves, so both `say_hello` immediately and both
   `say_trust` once they've heard hello; the `say_*` idempotency + the `if !said` guard in `hear_hello`
   make the cross-side short-circuit (§8) fall out — a corrupt/never-arriving hello just leaves the
   far `heard_*` unfinished, which is the test passing (heading 6).

**Expected step-3 snap (to record the true dige):** each side's `Pier/%protocol/{hello,trust}/%said,seq`
+ `%heard[,publicKey]`, `Pier/%Ud,publicKey`, the `%outbox/%emit` (hello + trust) and `%inbox/%unemit`
(hello + trust) pairs, both `%req:handshake,finished` (four leaves gone, rolled up), and
`w:Peregrination/%witnessed:step_3`. The `toc.snap` step-3 dige is still a lie until this run records it.

### 4 — outbox/inbox lifecycle + acks + whittle  `[x]`  PROVEN in-app at step 3  (rung 3, spec §7 + §12)
Written into `Ghost/N/Peeroleum.g` + `Ghost/Story/Peregrination.g`; both `lang-compile` clean and the
in-app step-3 diff matched the expected shape (below) exactly. What each piece is + where:

- **Outbox `created→sent→acked` (§7.1):** `Pier_next_seq(pier)` is the monotone per-Pier counter on
   `pier.c.seq` (off-snap; the seq it hands out lands on the `%outbox/emit`, which IS snapped). Acks
    consume no seq. `Peeroleum_send` books `%outbox/emit:seq,type,seq,sent` for every non-ack frame
     (created→sent collapsed — the mock hands off instantly); only an ack stamps it `%acked` later.
- **Acks (§7.2):** `Peeroleum_pump_inbox` sends `e:ack%ack:<their seq>` after every verified non-ack
   frame. `Peeroleum_deliver` routes `h.type==='ack'` to `Peeroleum_take_ack` — which stamps the
    `%outbox/emit` (and the matching protocol `%said`, spec §6) `%acked` — *bypassing* the inbox and
     all hear_* dispatch. Acks are never themselves acked (`Peeroleum_send` books no emit for them).
- **Inbox serial handling (§7.3):** `Peeroleum_deliver` lands `%unemit:seq,…,queued` (stashing the raw
   frame on `unemit.c.frame`) and calls `Peeroleum_pump_inbox`, which walks one frame
    `queued→handling→verified→done`: the serial lock is a query (`some(handling && !done && !error)` →
     bow out), the pre-`%Ud` gate allows only hello|noop, verify passes under the mock (a real
      header-sign check is heading 6), deliver calls the hear_* (which now **return false on reject**),
       then it stamps `%done,to:<type>`, drops the transient `%queued`/`%handling`, acks, and recurses
        to drain the next `%queued`. A verify/deliver failure stamps `%error` (no `%done`) →
         `Peeroleum_rollup_faulty`.
- **Whittle / step boundary (§7.4, §12.1):** `Peeroleum_arm_whittle(w)` registers a **self-re-arming**
   `Runstepped` callback (the logger idiom — `_runstepped_q` is drained every boundary, so a standing
    callback must re-push). `Peeroleum_runstepped(w)`, per Pier: acked `%outbox/emit` → `%outbox/recent`
     (whittle 20), `%done` `%inbox/unemit` → `%inbox/recent` (whittle 20), `%faulty` rebuilt from
      remaining errors. `%recent` items carry only `emit|unemit/type/seq` — no flags, no time. Armed in
       `Lake_sides_up` for the test; a production `Peeroleum(A,w)` worker should arm it too.

**Confirmed in-app (the step-3 diff matched this):** step 2 — Alice `%outbox/emit:1,noop,seq,sent,acked`,
Bob `%inbox/unemit:1,noop,seq,verified,done,to:noop` (then both culled to `%recent` at the step-2
boundary); `%witnessed:step_2`. Step 3 — each side's hello+trust `%outbox/emit,sent,acked` +
`%inbox/unemit,verified,done`, `protocol/{hello,trust}/{said[,acked],heard}`, `%Ud`, the noop in
`%inbox/recent`/`%outbox/recent`, both `%req:handshake,finished`, `%witnessed:step_3`. After each step
boundary the live outbox/inbox empty into `%recent`. Record the true diges once this checks out.

**Bombs / things the next reader needs:**
- **`delete unemit.sc.queued/handling` at `%done` is intentional** — the spec's terminal is a clean
   `verified,done,to:<type>` (§7.3), and the serial lock query (`handling && !done`) needs the flag
    gone. `delete`+query is sound: `n_matches_kv` checks `hasOwnProperty` (`Stuff.svelte.ts:422`) and the
     encoder reads `sc` directly, so the dropped key vanishes from both queries and the snap even though
      the stale X index still lists it (the post-filter rejects it).
- **The cull runs AFTER the snap commits** (`_resolve_runstepped`, called by Story `advance`), and the
   witness (`Lake_witness`) runs DURING the step — so the pre-boundary snap always shows the step's
    traffic and the witness stamps before anything is culled. Don't move the cull earlier.
- **monotone seq is per-Pier and on `.c`** (survives across steps in the live tree, never snaps). The
   noop takes Alice's seq 1, so the handshake hello/trust are seq 2/3 on Alice, 1/2 on Bob.
- **the serial `%handling` lock is particle state, not a JS flag** — under the mock delivery is
   synchronous so a frame is `queued→…→done` within one `Peeroleum_deliver`, and backlog rarely
    survives into a snap; but it's expressed as a query so a real (async-verify) transport gets the
     same guarantee. That's the whole point of the rewrite.
- **`%req:send` (§11.3), still unbuilt, is a new Pier-hosted req** — when production adds it, it hits
   the **c.up rule** (stamp `Pier.c.up=Peering; Peering.c.up=w`, as `Lake_sides_up` does) or its do_fn
    silently never runs.

Still open in heading 4 (deferred, not blocking the rung): the production wiring of acks/sends through
`%req:send` + `want_savepoint` (§12.4) — under the mock the post_do chain drives the round-trip without
a waiting-req, so the snap-visibility guarantee `want_savepoint` buys isn't needed yet. Exports hoisting
(§12.2) is also deferred — no consumer needs the Peering-level summary until p2pman is real (heading 11).

### 5 — per-req demand for time  `[x]`  CLOSED — `ttlilt` is the realised waiting-req
Decided: keep `%ttlilt` (`Hovercraft.svelte:163-352`); it already IS §13's per-req owned demand
(dropped on `finish()`, polled-not-mutated, so no write-write race) and the live system runs on it
(LiesStore/Lang/LiesCortex/Diffmatication + this bootstrap). Spec §13's `%req:waiting` + computed-max
global exist in **no** code; the old `demand_time_to_think`/`leave_running_until` global is
MachPeerily-only and retires with it (heading 12). Don't build §13 — it'd churn every step snap for no
p2p gain. The only thing that ever bites is a ttlilt expiring before its work finishes; the fix is the
seconds knob, e.g. `Peregrination.svelte:93` `i_req_ttlilt(req, 2.5, …)` — bump it if UIless compile
times out. Don't re-open this rabbit hole.

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

### 9/10 — transport trial: webrtc → websocket fallback (mocked)  `[~]`  PROVEN in-app thru step 5
The mocked selection landed in its own flavour dock **`Ghost/N/Tribunal.g`** ("a peer connection's
reputation, constantly on trial") — the carriers + mechanics moved out of `Peeroleum.g` (now just the
mock carrier + envelope). It runs as **steps 4–6** of the Peregrination wrangler, paced by Story STEPS,
not a wall-clock window (the earlier `ttlilt`+`setTimeout` version raced the snap and the demotion lost
— a step boundary is already a quiescence point, so each phase gets a clean snap):
- **webrtc mock = black hole**: `.c.port.send` drops the frame (no partner, no recv) → no ack ever.
   **websocket mock = working**: rides the shared in-process queue, ports paired by `Tribunal_pair_websocket`.
- **step 4 `Lake_trial_arm`**: install both carriers, hand `%active_transport` to webrtc, probe A→B over
   it. Black hole → un-acked emit lingers in Alice's outbox (the visible no-ack). Witness: both
    `active_transport,type:webrtc`.
- **step 5 `Lake_trial_fallback`**: the step-4 probe is still un-acked → no-ack-then-give-up. Fall BOTH
   sides to websocket FIRST (`Tribunal_fall_to_websocket`: `%transport,type:webrtc,faulty,reason:no-ack` +
    repoint active), THEN probe the relay A→B — so the ack can ride back (demoting both before probing
     kills the cross-side race). Witness: both webrtc `faulty` + `active_transport,type:websocket`.
- **step 6 `Lake_trial_confirm`**: the relay probe came back acked → `Tribunal_reputation_good` blesses
   both websocket carriers `%reputation:good` (the acked emit may be in `%outbox/recent` after the step-5
    whittle — confirm looks in both). Witness: both `reputation:good`.
- **Proven on :9091 thru step 5** (the hard part): webrtc faulty, active→websocket, relay carried
   (`emit=5,…,acked` on Alice, `unemit=5,…,verified,done` on Bob), `witnessed:step_4/5`. Step 6
    (reputation:good) follows from the acked emit. No `ttlilt`/`setTimeout`/race anywhere now. Record the
     step 4/5/6 diges (Accept/Resnapture) to make it a gate. `req_transport_select` is GONE — the trial is
      wrangler-driven (the req-as-particle version is for real peers, §11.2). `req_p2paddy` no longer
       auto-seeds it (that nested it under p2paddy and broke the req.c.up→Peering navigation).

**Remaining = the real transports** (still `[ ]`):
- **9 — real webrtc**: replace the black-hole port with the real PeerJS DataChannel (relocated from old
   Peerily); it tries and may go `%faulty,reason` visibly. Note the app-level no-ack timeout built here
    stays needed — PeerJS reports connection-level errors for free, not a channel that opens then goes
     silent. Spec §4.1.
- **10 — real websocket** `[~]` ACTIVE: a `/relay` WS endpoint that forwards a signed frame by
   `header.to` without parsing `body`; client `.c.port` → real WS. Spec §4.1, §11.2, §17. Full settled
    design ↓.

#### Heading 10 settled design — the editor↔runner channel as Peeroleum's first real customer

**Topology (both servers on localhost, two ports).** Browsers talk only to their **own-origin** `/relay`
(same-origin WS — sidesteps CORS, mixed-content, Origin checks). The two node relays **bridge each other
server-to-server** (no CORS at that layer) over **plain ws** to the one with a reachable domain — that is
the **editor**. One relay dials the other at a **hardcoded** editor endpoint; not a mesh, just a pair.

```
editor browser ──ws──▶ editor /relay ◀──relay↔relay (plain ws)──▶ staging /relay ◀──ws── staging browser
   (same origin)         (node)              (no CORS)                (node)         (same origin)
```

**Routing = two-AP, no ARP / no discovery / no clue-queue.** The 802.11g picture: your relay is the
**AP**, `header.to` is the **destination address**. A relay reads `header.to`; local socket → deliver;
else hand it **once** to the peer relay. With exactly two APs, "not local → the other one" is the whole
routing table. **No-local-socket → drop** (the sender's no-ack `ttlilt` retries); the 5s "ask for clues"
hold died with ARP.

**Loop-safety is structural, not a flag.** A frame arriving from a **browser** socket may be forwarded
once to the peer relay; a frame arriving over the **relay↔relay** link is **deliver-local-or-drop, never
re-forwarded**. Two relays, single hop, asymmetric rule ⇒ a frame cannot go around.

**Role is runtime, browser-commanded, set-once — NO docker/env role config.** `Lies%runner` sends a
control frame to *its own* server: *become runner-server.* The server locks `role=runner` and opens
**exactly one** r2r ws-client to the editor's hardcoded domain. The editor is the dial target; `Lies%editor`
locks it `editor`. A second, conflicting role assignment **throws** (errorific). Decided once, immutable.
The whole flow is **initiated from the browser by Lies** — the servers are dumb pipes that wake on browser
traffic, and the r2r link comes up lazily on the first remote-bound frame.

**The four asks to Peeroleum (this spine):**
1. **App-frame dispatch seam (`Peeroleum_on`)** — generalize `Peeroleum_pump_inbox` so non-protocol
   `header.type`s route to a per-`w` registered consumer handler (`Peeroleum_on(w,type,fn)` → `w.c.on[type]`,
    a `.c` seam), keeping the inbox/ack/faulty lifecycle + pre-Ud gate. This is what lets Lies own
     `dock_push`/`run_result` without editing the spine.
2. **Consumer emit via `Peeroleum_send` / `%req:send`** — already books the outbox emit + seq for any
   non-ack frame; a consumer just calls it. If promoted to a Pier-hosted `%req:send`, it hits the **c.up
    rule** (stamp `Pier.c.up=Peering; Peering.c.up=w` or it silently never pumps).
3. **Peer-ready signal** — already present: both Piers' `%req:handshake,finished` / `%Ud`. Surface a thin
   `Peeroleum_peer_ready(pier)` for Lies to `$effect` off; app frames are gated behind it anyway (pre-Ud
    inbox gate rejects non-hello/noop until handshake completes).
4. **Real WS on the editor's server** — attach via a `configureServer` vite plugin on the dev `httpServer`
   (`ws` 8.18.2 is already vite's transitive dep, no new package). **AVOID the phantom**: `vite.config.server.js`
    points at a `server.ts` that does NOT exist and lists `socket.io` external — half-removed scaffold; do
     not build on it.

**Where frames originate/land (the Lies side):** editor emit hook = `write_finished` + `w%editor`; runner
receiver = `LiesStore_good → land_good → drain_good` (the "inotify backend" the comments anticipate). No
shared OPFS across origins, so the channel carries the `.go` bytes.

**Security / v1 reality.** The runner HAS an Id (it is a peer; `%Peering`/`%Pier` are keyed by it) — identity
is present, trust *enforcement* is deferred. v1 = **trust-everything**: accept the one runner that connects,
handshake completes implicitly; hardcoded editor+runner Ids so there is *some* identity to tighten later.
`%Ud` verification, per-runner authorization, Thangs persistence = future. Runner = a **dev browser tab**
for v1 (a UIless runner still can't mount a fresh `.go` — heading 1b).

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
- **`H`-receiver actor-laying** — `H i A:Alice` lays a sibling actor on the House. `H` normalises to
  `this` (the gen method has no `H` in scope) in `Lang_io_before_split` (`compile.ts`). The same split now
  also captures a receiver in the **assignment form** `let bw = bA i w:Peeroleum` (a lone bareword between
  `=` and the verb) — previously it fell to verbatim and dropped to the default `w`. So a method whose
  every `H` is a DSL form needs no `const H = this` (but raw-JS `H.x` and closures like `transport()`'s
  mock-port still do).
- **`$` row-capture on a valued leg** — `A:Bob$AN` captures that leg's C into `AN`; two legs →
  `let {AB, wB} = this._i_drill_caps(this, […])`, a one-line **multi-assigning two-leg**. Fix was one
  char: the `PathVal` value token now breaks on `$` (`io_tokens.ts`), so the trailing `$cap` is left for
  the capture token instead of being swallowed into the value. `%` is now optional on peels — `i A:Alice`
  works, prefer it.
- **NB regen:** editing `stho.grammar` makes the generated `stho.grammar.ts` artifact stale — the
  registry `resolve()` falls back to a live `buildParser` (correct, just flagged stale). Regen the
  artifact via the in-app gen action when convenient. (Editing `io_tokens.ts` needs no regen — the
  generated parser imports it at runtime.)

Still open — each a place the spine dropped to raw JS:
- auto-`async` on a method whose body has a bare `await`-verb (`r/rm/roai`/`await x.do()`).
- `drop`/`empty`/`oa` verbs; deep/wildcard `drop Pier/protocol/**`.
- drilled paths on `oai/r/rm` (seed a `%req` under a nested host without pre-resolving it).
- object/`.c` payloads (`c.connection`, `stashed:{…}`).
- list fan-out (one `%req:dial` per peer over a thang list).
Corpus + compiler: `Ghost/test/Story/Lake/LakeTiles.g`, `src/lib/O/LangCompiling.svelte`, `LangCompiler_TODO.md`.

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
