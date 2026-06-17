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

**Heading 2 (mock transport spine) is PROVEN in-app:** one frame crosses the mock transport B→N and
lands `%inbox/%unemit,…,delivered`, witnessed at step 2 (see heading 2 for the snap shape). The runner
is step-driven now (inner steps start at 2, via `Lake_drive`'s own step dispatch), and the compile
scaffolding folds out of the snap with `%dontSnap` once the apparatus is ready.

**Heading 3 (hello+trust handshake) is BUILT, awaiting in-app proof at step 3.** The four leaf do_fns
+ the say/hear exchange + the inbound-frame dispatch are written (compile clean via `lang-compile`);
both sides should drive `%req:handshake` to `finished` and stamp `%witnessed:step_3`. **Next real work:
run the Peregrination Story on :9091 and confirm step 3 (snap shape + the bomb under heading 3), then
record the true step-3 dige.** NB headless `Story_cli` (see `Story_cli_handover.md`) does NOT yet boot
this Book — it mounts only `<Ghost>`, not the `Peregrination.svelte` bootstrap loader, so the wrangler
methods never compile in; wiring the loader into `Story_cli.svelte` is heading 1b's payoff, and would
finally make this verifiable headlessly. Until then, heading-3 proof is in-app.

**Write the spine in the DSL, not raw JS** (the human's standing ask): heading L now covers a lot —
`%` optional on peels (`i A:Bearing`), `H` receiver for actor-laying, `let {AB,wB} = H i
A:Bearing$AB/w:Peeroleum$wB` (multi-assign two-leg row-capture), `&name,a,b` calls. `Lake_sides_up` is
the worked example; only object/`.c` seams (the mock-port pairing) stay raw. Reach for a LangTiles
extension before dropping to raw JS. Check every `.g` edit with `npm run lang-compile -- <file>`; the
working tree is left uncommitted for the human.

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

**Step-driven now (inner steps start at 2).** Step 1 is the bootstrap (compile+include), owned by the
loader. `LakeNetherland` (`Ghost/Story/Peregrination.g`) shrank to: install `%req:wrangle,eternal` whose
do_fn calls `Lake_drive(w, req)` each pass. The work lives in flat helpers: `Lake_sides_up(w)` (step 2 —
stand up `A:Bearing`/`A:Nearing`, each `w:Peeroleum` with a `%Peering`/`%Pier` named by the *peer's*
identity + a mock transport; pair the ports; `Peeroleum_send` one B→N frame; stamps `%reached:step_2`),
`Lake_handshake(w)` (step 3 — seed+pump `%req:handshake` on each Pier; stands the four-leaf tree up but
not to `finished`, since the leaf do_fns are heading 3), steps 4/5 stamp `%reached:step_N` placeholders.
`Lake_witness` stamps `%witnessed:step_2` once Nearing's inbox shows the delivered frame (step in the
*value* — `step` is the Story mainkey, so it can't be a key). All raw JS: H-receiver actor-laying,
objects-on-`.c`, drilled paths — tracked seams.

`wormhole/Story/Peregrination/toc.snap` carries one `step,…` line per inner step (`step,dige:…` =1, then
`step=2…5,dige:…`); the diges are **lie diges** (real seq, fake hash) until a run records the true ones.

**Why NOT `H.on_step` (a real bug, fixed):** `on_step` keys off one H-global `did_on_step_n`. When the
cold-compile/include spills into step 2, the loader's step-1 path still runs and claims step 2 (its table
has no key 2) → the wrangle's step-2 setup is **starved**. The tell was a step-3 snap with `%reached:step_3`
present but no `A:Bearing`/`A:Nearing` and no `%witnessed:step_2` (step 3 fired, step 2 didn't). Fix:
`Lake_drive` keeps a **req-local `req.c.did_step`** (read `H.c.run.c.step_n` the way `on_step` does), immune
to any other caller; and the loader dropped `on_step` entirely, seeding `ensure_compiled` directly
(idempotent via `doai`). Two-dock include also tripped a latent render crash — `each_key_duplicate` on
`UI:Pantheate-include` (both includes share that name) — fixed by keying Otro's UI `{#each}` on
`keyser(uiC.sc)` (full identity incl. `gen_path`), not `uiC.sc.UI` (`Otro.svelte:110`).

**Proven in-app (step 2 ✓):** the step-2 snap shows `A:Bearing/%Peering/%Pier/%outbox/%emit,…,sent`,
`A:Nearing/%Peering/%Pier/%inbox/%unemit,…,delivered`, and `w:Peregrination/%reached:step_2 +
%witnessed:step_2`. The frame crossed the mock transport and landed delivered. (`%see` lines sweep at the
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

**Peers-first ordering:** `Lake_order` floats `A:Bearing`/`A:Nearing` (the subject under test) above the
apparatus actors via `H.place({A:1}, sorted)` (the `Lies_order_wafts` idiom — re-enters the same C's in
order, no-ops once sorted). Called each pass from `Lake_drive`, so the snap reads peers-first.

**NB:** the committed `gen/N/Peeroleum.go` + `gen/Story/Peregrination.go` track the `.g`; the loader's
dige gate recompiles + rewrites them on the next in-app run if they drift — no hand-edit needed.

### 3 — hello+trust under mock → `%req:handshake,finished`  `[~]`  BUILT, awaiting in-app proof  (rung 2)
The four leaf do_fns + the say/hear exchange + frame dispatch are written (`Ghost/N/Peeroleum.g`),
plus the wrangler's per-pass re-pump + step-3 witness (`Ghost/Story/Peregrination.g`). Both `.g`
compile clean. Not yet run (Peregrination has no headless path — see Status). The shape:

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
- **`H`-receiver actor-laying** — `H i A:Bearing` lays a sibling actor on the House. `H` normalises to
  `this` (the gen method has no `H` in scope) in `Lang_io_before_split` (`compile.ts`). The same split now
  also captures a receiver in the **assignment form** `let bw = bA i w:Peeroleum` (a lone bareword between
  `=` and the verb) — previously it fell to verbatim and dropped to the default `w`. So a method whose
  every `H` is a DSL form needs no `const H = this` (but raw-JS `H.x` and closures like `transport()`'s
  mock-port still do).
- **`$` row-capture on a valued leg** — `A:Nearing$AN` captures that leg's C into `AN`; two legs →
  `let {AB, wB} = this._i_drill_caps(this, […])`, a one-line **multi-assigning two-leg**. Fix was one
  char: the `PathVal` value token now breaks on `$` (`io_tokens.ts`), so the trailing `$cap` is left for
  the capture token instead of being swallowed into the value. `%` is now optional on peels — `i A:Bearing`
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
