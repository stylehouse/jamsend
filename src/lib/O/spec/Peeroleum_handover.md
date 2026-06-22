# Peeroleum handover

The living checklist for retiring `Peerily`/`MachPeerily` and growing `Peeroleum` against
`Peeroleum_spec.md`. Each heading is meant to shrink as it is solved. This file is the memory the
work would otherwise re-type into each session — keep it current, correct anything stale.

Notation: `[x]` done · `[~]` started/scaffolded · `[ ]` not begun · `// <` a deliberate hole.

**Two-frequency pair (read before editing either).** This is the HIGH-frequency half: live status,
proofs, next moves, bombs, and the forward look — it changes every session. `Peeroleum_spec.md` is the
LOW-frequency half: the settled design of the "linoleum floor" (particle layouts, frame envelope,
lifecycle, handshake-as-`%req`, the realised relay topology §5). **Rule of thumb:** "how the floor IS
designed, settled" → spec; "what's DONE / BROKEN / NEXT / proven-at-step-N" → here. When something here
settles into design, promote it to the spec and leave a one-line gravestone — no silent caps. (Several
engine-facts, the heading-10 settled design, and the §7/§8 lifecycle bombs were promoted this pass.)

---

## Status — start here

**Proven in-app, rungs 0–4 (clean quiescent snap, no timeout):** the Creduler acquires the live spine
(`Ghost/N/Peeroleum.g` + `Ghost/N/Tribunal.g`) before the Story begins; the mock transport carries frames
A↔B (heading 2); and at **step 3 the full hello+trust handshake completes** — both Piers
`%req:handshake,finished` (all four leaves), `protocol/{hello,trust}/{said,heard}`, `%Ud,publicKey`,
inbox/outbox pairs, `%witnessed:step_3`. **Heading 4 (full outbox/inbox lifecycle + acks + whittle) is
PROVEN in-app at step 3** — monotone seq (noop=1/hello=2/trust=3 on Alice, hello=1/trust=2 on Bob), every
`%outbox/emit,sent,acked` + `protocol/%said,acked`, inbox `%unemit,verified,done,to:<type>`, the step-2
noop culled to `%recent`, no `%faulty`. (Mechanism is in spec §7/§8 now.) **Standing ask: record the diges
(Accept/Resnapture)** to make these a regression gate.

**Step 6 caveat:** the `toc.snap` step lines run only through `step=5`. Step 6 (`Lake_trial_confirm` →
`%reputation:good`) is in code and was green in the older `006.snap` (Jun 18) but is **not a current
recorded gate** — re-run + Accept/Resnapture steps 2–6. (Step 7, the binary exercise, also needs re-adding
to `toc.snap` to run; its `body_hash` is now sha256, so the old step-7 dige is stale either way.)

**This session — the delivery path went async all the way.** `Peeroleum_pump_inbox` is now an async serial
drain, `Peeroleum_deliver` + carrier `recv` await it, and the body digest is `crypto.subtle` **sha256**
(was a sync FNV hack that only existed to keep the inbox synchronous). The sha256 makes `body_hash` signable
(trust layer). All three `.g` compile clean, gen `.go` regenerated, and the Story driver boots+runs to
completion headless — but **PereStartuppity's headless fixtures are blank right now**, so the dige gate can't
confirm it; verify on **:9091**. Spec §4.2 + §7.3 updated. The endorsed next move — folding the inbox into the
`%req` engine (`%req:unemit` drained by `inbox.do()`, `Peeroleum_pump_inbox` deleted) — is now **BUILT in `.g`
source, compile-verified, with regen/refreeze HELD** so it doesn't disturb the live reconnect check; see heading 4.

### → START HERE: real websocket transport (heading 10) — editor↔runner is its first customer

**Active direction (settled with the human).** The editor↔runner channel is NOT new construction — it is
the first real customer of heading 10's websocket transport, so the music-app peers and Lies (editor/runner)
become two consumers of ONE envelope/transport/ack/faulty machinery. **The settled design now lives in
spec §5** ("Realised transport topology — the 'heading 10' design"); this is the live build log against it.

**Build progress (this session):**
- **[x] (1) Real `/relay` WS server — PROVEN.** `src/lib/server/relay.ts` (`attachRelay`) + a `configureServer`
   vite plugin in `vite.config.ts`. Two-AP routing, structural loop-safety, set-once browser-commanded role,
    single r2r bridge. Proven node-side by `scripts/relay-test.ts` (10/10) AND live on `vite dev :9091`
     (`/relay` routed a frame, HTTP 200, HMR intact). `ws` 8.18.2 = vite's existing dep, no new package.
- **[x] (2) Real WS carrier port — COMPILES.** `Socket_real(w)` + `Tribunal_activate_websocket(w)` in
   `Ghost/N/Tribunal.g`: a native `WebSocket` to own-origin `/relay?addr=<Peering name>`, send-buffered-until-open,
    inbound delivery wrapped in `post_do` → `Peeroleum_deliver`. The mock `Socket`/pairing is UNTOUCHED so the
     PereStaple test keeps its determinism. `lang-compile` clean; not yet run in-app.
- **[x] (3) Consumer dispatch seam — COMPILES.** `Peeroleum_on(w,type,fn)` (per-w `w.c.on` registry),
   `Peeroleum_send_consumer(w,type,body)`, `Peeroleum_peer_ready(pier)` in `Ghost/N/Peeroleum.g`;
    `Peeroleum_pump_inbox` now dispatches non-hello/trust types to the registered handler inside the same
     inbox/ack/faulty lifecycle. `lang-compile` clean; not yet run in-app.
- **[ ] (4) Lies as first consumer — NEXT, needs in-app.** Editor emits `dock_push` (the `.go` bytes) on
   `write_finished`+`w%editor`; runner registers `Peeroleum_on(w,'dock_push',…)` landing via
    `LiesStore_land_good→drain_good`; `run_result` flows back. Depends on the Editron compile-without-mounting
     split (gate `Ghost_update_notify` on `!w%editor`). Deliberately NOT written blind — no UIless runner yet
      (heading 1b), so build it against a live browser. **The committed `gen/**.go` are stale vs the new `.g`;
       the dige gate regenerates them on the next in-app run (do not hand-edit gen).**
- **[~] (5) The bridged channel RUNS live (runner ⇄ editor) — mind the run_phase wedge (FIXED).** First real
   bridged run: the runner Creduler-acquires the spine, the WS relay bridges runner↔editor, the Story drives
    over it. **Bomb (fixed):** `run_phase` (the transient progress blip the runner sends the editor) was a
     NON-ephemeral frame, so the editor acked each one; the ack hit the runner's `Peeroleum_deliver` →
      `feebly_ponder()` → re-woke the Story drive so the step never quiesced → `step_stall` fired → another
       `run_phase` → another ack → an endless wedge (a 5-step run took 48s). Fix: `run_phase` is now ephemeral
        like ping/pong (`Peeroleum.g` — no booked emit, no ack-back). **That alone did NOT fix it** — the
         runner's gen recompiled fine, but the **editor still ACKs each run_phase** (the editor rides a
          *separate frozen bootstrap* Peeroleum, not the live `CREDULER_GHOSTS` gen the runner re-acquires, so
           it never got the fix), and the runner's ack branch `feebly_ponder`ed on that spurious ack →
            re-wedge (`poll_step` spinning at the 50ms `TICK_MS`, ~18fps; run_phase seq climbed past 390). **The
             robust fix (runner-side, peer-agnostic):** `Peeroleum_take_ack` now returns whether it actually
              stamped an outbox emit / protocol `%said`, and the ack branch only `feebly_ponder`s on a *hit* —
               so an ack for an untracked (ephemeral run_phase) frame is ignored, no matter what the peer does.
                The heartbeat ping rate was halved to 6s (`LiesLies.svelte` `Lies_heartbeat`) but was never the
                 dominant cause (6s ≪ 18fps). The editor still acks run_phase = harmless channel chatter until
                  its bootstrap regenerates.
- **[~] (6) The wedge underneath — a beliefs-drain LOST WAKEUP, now NETTED (verify on :9091).** Confirmed
   *what* it is: NOT churn — a **lost wakeup**. The House goes **idle out of Atime** (`finished_run` set, no
    cycle running) with `Run.todo` **still non-empty** (a `fn:?` = the mock `partner.recv` delivery + a
     `think`), and `poll_step` — which only ever *waited* on quiescence — waits **forever**; its `setTimeout`
      "comes back infinitely" but the machine is FROZEN, not spinning. **Tell:** a STATIC trace while the step
       clock climbs is this lost wakeup; a GROWING one would be the other failure (infinite re-enqueue / churn).
        The drain path is lossy in three spots: `answer_calls` fires `_really_answer_calls()` **async-unawaited**
         behind a 50ms throttle decoupled from work completion; `i_elvisto` defers its `_push_todo` into a
          `clear()` (mutex re-acquire); `feebly_ponder→main` routes through a `throttle()` that can coalesce away
           the kick. (The `Story_cli` harness already works around all this — it manually loops
            `while(todo.length) _really_answer_calls()` + trickles think — which is *why* it never reproduces the
             wedge.) **Net (landed, browser-unverified):** a watchdog in `poll_step` — when
              `not_in_Atime && Run.todo.length` it drives the drain itself (`Run.answer_calls()`), self-healing a
               dropped wakeup on the next 50ms tick; a throttled **`rekick` trace** marks each intervention
                (rekick-then-lands = lost wakeup; rekick-forever = churn, now loud instead of a silent
                 forever-wait). Design write-up: `Story_next_level_spec.md` **§15.5**. **Verify on :9091:** the
                  wedged step should now COMPLETE. Deeper follow-up (optional): root-harden (await `_really`,
                   de-throttle the event-driven think) or the §15 **req\*\*** recast (wake becomes ttlilt-owned,
                    so the whole class dissolves rather than being netted).

**Instruments + open latency thread (this session).** The old brutal *console* trace-tail is GONE — replaced by
 an in-UI **overrun monitor** in Storui: a `⏱` button arms at >5s on a wedged step and opens a live trace ticker
  (batches the latest ≤30 unshown events every 3s) plus an **idle Xs** counter — *idle climbing while the step
   clock runs is the static-trace tell* that reads lost-wakeup-not-churn at a glance. Its signal rides an
    ave-held `live_poll` particle bumped directly (the reactivity_docs "lever"), so it updates even while a wedge
     keeps beliefs from flushing ave. **Open thread — editor↔runner channel RTT is ~400–900ms** (two tabs ↔ two
      node relays), far too slow: applied `socket.setNoDelay(true)` (Nagle off) to the relay sockets (`relay.ts`
       onUpgrade + the r2r bridge) — the multi-hop r2r path can stack ~100ms of Nagle per hop — but the dominant
        cost is likely the app round-trip threading the same throttled belief/think machinery on both ends (cf.
         the boomerang-latency memory). **Instrument the actual ping path next.** Runner-panel stall readout
          matured to a coarse `>2s/>5s/…` band (no per-second count).

**Prerequisite unblocked (compiler robustness — why the editor wrote uncompiled `.go`):** task (4) needs the
editor to compile cleanly, gated by a real bug — a compile firing before the language parser landed emitted
raw `.g` passthrough and WROTE it as the `.go`, with nothing validating. Fixed: `req_compile` waits for the
parser (`waiting:'parser'` ttlilt) + a `Lang_has_lang_parser` guard in `Lang_compile_dock`; `lang-compile`
syntax-gates its output (esbuild). Write-up in `LangCompiler_TODO.md`. Both fixes still want a browser re-run.

**Test status (transport trial, steps 2–6):** steps 2–5 proven in-app; **step 6 was BROKEN, now FIXED.**
`Lake_trial_confirm` re-checked `probe.sc.acked` on the relay-probe emit, but the step-5→6 boundary cull had
moved it to `%outbox/recent`, which STRIPS `%acked` — so it bailed and never stamped
`%reputation:good`/`%witnessed:step_6`. Fix (`Ghost/Story/Peregrination.g`): presence in `%recent` IS the ack
proof (the cull moves ONLY acked emits there); a still-live emit must still carry `%acked`. `lang-compile`
clean. **Re-run to confirm step 6 goes green, then Accept/Resnapture steps 2–6.** Then heading 6 (corruption).
`req_transport_select` is GONE for the test — the trial is wrangler-driven (`Tribunal.g`); the req version is
for real peers (spec §11.2). No wall-clock `ttlilt` in the trial anymore — it's step-paced.

**The in-app run reshapes every step snap** (outbox/inbox carry the full lifecycle; the boundary culls
acked/done into `%recent` after each step), so the `toc.snap` step diges — already lies — are doubly stale.
Run the `PereStaple` Story on :9091, eyeball the lifecycle, then Accept/Resnapture. (`Story_cli` produces a
PereStaple pile too — read `witnessed:*`/`A:PereStaple`; the `A:Lang` AST blob is per-step noise; see the
`peregrination-pile-reading` memory + `Story_cli_docs.md`.)

### Standing asks (apply to every heading)

- **Write the spine in the DSL, not raw JS.** Heading L covers a lot — `%` optional on peels, `H` receiver
   for actor-laying, multi-assign two-leg row-capture, drilled-`o` captures, `&name,a,b` calls. Reach for a
    LangTiles extension before raw JS; only object/`.c` seams (mock-port pairing, frame objects off the wire,
     dynamic-value writes) stay raw. Check every `.g` edit with `npm run lang-compile -- <file>`.
- **The c.up rule (bit me in heading 3, now spec §8).** A `%req` hosted below `w` (under Pier/Peering)
   silently never pumps unless you stamp the host chain's `c.up` — the belief walk wires `A`/`w` only. So any
    new Pier-hosted req (e.g. `%req:send`, spec §11.3) needs `Pier.c.up=Peering` etc.
- **Working tree left uncommitted for the human.**

## How the loop works (heading 0)

A `.g` ghost's methods exist on `H` only once the dock is compiled + included (compile → `gen/**.go` →
Pantheate `import()` → Otro mount → `eatfunc`). The hand-written `src/lib/O/test/Peregrination.svelte` loader
is **GONE** — the runner now **ACQUIRES the live spine via the Creduler**: `Creduler_ensure(w)` (gated by a
`%Creduler_pending` flag on H, set in `Auto.svelte`) loads every ghost in the `CREDULER_GHOSTS` manifest
(`LiesLies.svelte`) live, compiling+including each before the Story is allowed to start. The `.g` IS the Book.

- `Run_A_PereStaple` (in `Ghost/Story/Peregrination.g`) is the Run recipe — lays `A:PereStaple/
   w:PereStaple` and guards the `runner` role. (Mirrored by `Run_A_Editron`.)
- per beat, `PereStaple(A,w)` installs `%req:wrangle,eternal` whose do_fn `await`s `Lake_drive(w, req)`.
- `Lake_drive` is the inner-step dispatch (step 2 `Lake_sides_up`, 3 `Lake_handshake`, 4/5/6 `Lake_trial_*`),
   off a req-local `req.c.did_step` — explicitly NOT `H.on_step` (see "Why NOT on_step" under heading 2).
- `Lake_witness` polls each pass and stamps `%witnessed:step_N` by structural query.

Driven by the **PereStaple Story** (`wormhole/Story/PereStaple/toc.snap`), whose Prep opens the
**Ghost/Net/Easy** Waft overlay (`wormhole/Ghost/Net/Easy/toc.snap`) — its `.g` Docs are the manifest.

> (`LakeNetherland` is NOT this wrangler — it is an unrelated 3-line fixture in
>  `Ghost/test/Story/Lake/LakeAmeliorations.g`, surfaced in the LakeNets editor-machine Book. The
>   PereStaple wrangler is `PereStaple(A,w)`/`Lake_drive`. Earlier notes confusing the two were wrong.)

---

## Engine facts (the rest promoted to the spec)

The two engine-facts that corrected the spec's aspirational prose are now **in the spec** (reqy→C-native →
spec §3; the never-built `%req:waiting`/`%exports`/`waits_savepoint` were dropped from the spec — waiting is spec §3.2). What stays here, live:

- **LangTiles gaps** (→ raw-JS passthrough, flag `// <`): no auto-`async` (hand-write it), no
  `oa`/`drop`/`empty` verbs, no drilled paths on `oai/r/rm`, no object/`.c` payloads in `sc`, no list
  fan-out. See heading L.
- One-liner reminder of what moved: `reqy()` is deleted (live API `oai/doai/do/finish/all_finished`,
  `Stuff.svelte.ts`); waiting today = `H.i_req_ttlilt(req,secs,{waiting})` (`Hovercraft.svelte:380`) +
  eternal-foreman `req.sc.ok=1`. Both detailed in spec §3/§3.2.

---

## Headings

### 0 — Bootstrap / Creduler acquire  `[x]`  DONE
The loader is gone; the Creduler acquires the spine (see "How the loop works"). Proven in-app with a clean
quiescent snap. Things learned / kept:
- **Include needs no special UIless step** — Pantheate `import()`s the gen module and Otro mounts it (its
   `eatfunc` runs, Ghostmeta confirms). **Fixed bug**: Pantheate keyed every include under one
    `UI:Pantheate-include` slot, so two simultaneous includes collided — now keyed by `gen_path`.
- **Currency gate**: a `.g` already compiled+included by a prior reset is reused (skip recompile when
   `Ghostmeta_<name>() === dig(text)`); a drifted dige recompiles, never masked by a stale prior compile.
- **"UIless" here = editor-less / cursor-less compile, still in-browser** (Otro must mount the gen so
   `eatfunc` runs). A genuinely no-browser run is heading 1b.

### 0b — Net/Easy Waft overlay  `[x]`
`wormhole/Ghost/Net/Easy/toc.snap` — the annotation-overlay on-ramp; `What→Doc→Point` situating the test /
peer / transport / spec. Its `.g` Docs double as the compile manifest. Next: when heading W lands, the
acquire reads this list instead of a hardcoded manifest.

### 1a — CLI compiler  `[x]`  (lets the agent self-check `.g` files)
The pure translator was extracted verbatim from `LangCompiling.svelte` into `src/lib/O/lang/compile.ts`
(`export const LANG_COMPILE`); the ghost spreads `...LANG_COMPILE` into its eatfunc, so the in-app path is
behaviour-identical. The CLI `scripts/lang-compile.ts` (`npm run lang-compile -- <file.g>`) builds the real
stho parser, runs the translator over a tiny C-shaped stub, prints the generated module or the first compile
error. Already caught real bugs (a hyphen in a bareword peel value). **Use it to check every `.g` edit.**

### 1b — UIless Story-runner  `[ ]`  (the bigger half)
Include works in-app; what remains for a *fully UIless* (no-browser) run is the Story runner itself, driven by
`story_drive` via `setTimeout` + GUI (`Story.svelte`), and the Otro render that mounts gen components (a UIless
run would evaluate the gen module's `eatfunc` without a DOM, or drive a minimal Otro over the Run's `UIs`).
Goal: run a Book to completion UIlessly, emitting the per-step snap. Surface: `story_drive`/`do_step`/
`snap_step`/`advance`, `Run.main()`/`beliefs`/`all_clear`, `Story_subHouse`. Partial supersession: the
`Story_cli` boot (vitest+jsdom) runs the machine headless. Until a true UIless render lands, Story
verification is in-app on :9091. (Cited as **heading 1b** by Editron.md + Everything_todo.md — keep the token.)

### 2 — Mock transport spine  `[x]` PROVEN in-app  (spec rung 1)
`transport()` (`Ghost/N/Peeroleum.g`) declares `%transport,type:mock` + `%active_transport,type:mock,open` and
wires a mock-port on `at.c.connection` (raw JS): `send` → `post_do(() => partner?.recv(frame))`, `recv` →
`Peeroleum_deliver`. The wrangler pairs the two ports. `Peeroleum_send`/`Peeroleum_deliver` carry the one
envelope (mechanism: spec §4/§7). Step-driven (inner steps start at 2): `Lake_sides_up(w)` (step 2 — stand up
`A:Alice`/`A:Bob`, each `w:Peeroleum` with a `%Peering`/`%Pier` + mock transport, pair ports, send one A→B
`noop`), `Lake_handshake(w)` (step 3), `Lake_trial_*` (4–6). `Lake_witness` stamps `%witnessed:step_N` (step
in the *value*). The `toc.snap` carries one `step,…` line per inner step; the diges are **lie diges** until a
run records them.

- **Why NOT `H.on_step` (a real bug, fixed):** `on_step` keys off one H-global `did_on_step_n`. When
   cold-compile/include spills into step 2, the step-1 path still runs and claims step 2 → the wrangle's
    step-2 setup is **starved** (tell: a step-3 snap with `%reached:step_3` but no `A:Alice`/`A:Bob`). Fix:
     `Lake_drive` keeps a req-local `req.c.did_step`, immune to any other caller.
- **Snap-fold knobs:** `%dontSnap` (a node emits its line but the walk descends no further — orthogonal to
   pump, so an edited `.g` still recompiles) folds the compile apparatus (`A:Lies` GhostList, `A:Lang` gen
    text); `w%runner` makes `Lies.svelte` skip provisioning GhostList entirely (the dirlist Funkcion never
     walks). `Lake_order` floats `A:Alice`/`A:Bob` above the apparatus actors (peers-first snap).

### 3 — hello+trust under mock → `%req:handshake,finished`  `[x]`  PROVEN in-app at step 3  (rung 2)
The four leaf do_fns + say/hear exchange + frame dispatch (`Peeroleum.g`), plus the wrangler's per-pass
re-pump + step-3 witness (`Peregrination.g`). Mechanism (leaf existence-checks, say/hear, dual-init,
cross-side short-circuit) is **spec §8**; the c.up bomb is **spec §8**. Status-only bombs that stay here:
- **Re-pump lives in the wrangler, NOT reqdo_sweep.** The handshake is nested (`Pier/Peering/w`), below
   reqdo_sweep's w-level reach, so `Lake_pump_handshakes` (each pass) drives it; delete it and the leaves
    freeze after step-3 seeding. (Production will pump via the per-Pier worker once `req_p2paddy` seeds the
     handshake — spec §11.2/§11.3 — but the test wrangler lays sides directly and drives them.)
- **The step holds open via `post_do`/`feebly_ponder` — no ttlilt needed.** Each `Peeroleum_send` `post_do`s
   a delivery; each `Peeroleum_deliver` `feebly_ponder`s → think → `Lake_drive` → `Lake_pump_handshakes` →
    `pier.do()`, so the round-trip self-drives to completion in one step. If an in-app run ever snaps
     mid-handshake, the fix is a waiting ttlilt on the handshake req + `H.i_scheme_req(w,[{Peering:1},
      {Pier:1}])` so `i_Story_o_req_ttlilt` can reach the nested req — but bet on the chain first.
- **Duplicate A→B hello — RESOLVED.** Step 2's scaffold frame is a `type:noop` (carrier+ack ping; spec §7.3
   sanctions `noop` pre-Ud), so the hello is sent exactly once, at step 3.

### 4 — outbox/inbox lifecycle + acks + whittle  `[x]`  PROVEN in-app at step 3  (rung 3)
Written into `Peeroleum.g` + `Peregrination.g`; both `lang-compile` clean, the in-app step-3 diff matched the
expected shape exactly. **Mechanism is now spec §7** (outbox `created→sent→acked`, light acks, serial inbox
`queued→handling→verified→done`, whittle to `%recent`; the query-safe-delete invariant; cull-after-snap). The
realised helpers: `Pier_next_seq` (monotone per-Pier on `.c`), `Peeroleum_send`/`_pump_inbox`/`_take_ack`/
`_rollup_faulty`/`_runstepped`/`_arm_whittle`. Status: confirmed in-app at step 2 (noop) and step 3 (hello+
trust lifecycle, both `%req:handshake,finished`). Still open (deferred, not blocking): production wiring of
acks/sends through `%req:send` (spec §11.3) — under the mock the `post_do` chain drives the round-trip, so the
deferred `want_savepoint`/exports (voided, dropped from the spec) aren't needed yet.
- **The inbox is the `%req` engine now — BUILT in `.g` source, compile-verified, regen/refreeze HELD.**
   `Peeroleum_pump_inbox` is GONE. Each inbound frame is booked as `%req:unemit,seq:N,type` under the inbox
    (`Peeroleum_deliver`) and drained by **`inbox.do()`**, which runs the new **`req_unemit(req)`** do_fn one at a
     time, in arrival order, awaiting each — that IS the serial async drain. The realisations:
  - **The `%handling`/`%queued` lock is GONE.** `do()`'s `for (…) await _req_do_one` serialises within a pass,
     and the beliefs mutex (the carrier's `post_do` is awaited across the whole delivery) means no two `do()`
      drains ever overlap — so there's no re-entrancy to guard. This is exactly the thesis: ordering is a property
       of the reconciler (the engine), not a sync-execution constraint.
  - **`req_unemit`** does the per-frame logic only: pre-`%Ud` gate → awaited sha256 body-hash → `hear_*`/handler
     → on success `req.sc.done`+`%to`, `inbox.finish(req)`, ack; on failure `req.sc.error`, finish, roll up
      `%faulty`. `w`/`pier`/`frame` ride the req's `.c` (stashed at booking — avoids a deep `c.up` walk).
  - **c.up:** `oai` auto-wires `ureq.c.up = inbox`; `Peeroleum_deliver` stamps `inbox.c.up = pier` (one line) so
     `do()`'s climb reaches the House to resolve `req_unemit`. The Pier→Peering→w→Mundo chain the handshake reqs
      already rely on does the rest. (Pier itself is NOT yet a `%req:1,Pier,prepub` — not needed for the fold;
       still endorsed as a follow-up.)
  - `rollup_faulty`/`runstepped` now read `inbox.o({req:'unemit'})` (was `{unemit:1}`); recent records keep the
     readable `%unemit:seq` shape.
  - **NOT regen'd / refrozen** (so live reconnect verification isn't disturbed) and **browser-unverified** —
     `lang-compile` PASS only proves valid JS. Re-shapes the inbox snaps (`%unemit:N` → `%req:unemit,seq:N`), so
      re-record after verifying on :9091. Promote spec §7.3 from the `%unemit` description once proven.

### 5 — per-req demand for time  `[x]`  CLOSED — `ttlilt` is the realised waiting-req
`%ttlilt` (`Hovercraft.svelte:380`) IS spec §3.2's per-req owned demand (dropped on `finish()`,
polled-not-mutated, no write-write race), and the live system runs on it (LiesStore/Lang/LiesCortex). The never-built
`%req:waiting` + computed-max global exist in **no** code (spec §13 now redirects to §3.2). Don't rebuild it — it'd
churn every step snap for no p2p gain. The only thing that bites is a ttlilt expiring before its work
finishes; the fix is the seconds knob (bump `i_req_ttlilt(req, 2.5, …)`). Don't re-open this rabbit hole.

### 6 — corruption tests  `[ ]`  (NEXT after step-6 Accept)
`meddle_fn` on an eternal `%req:emit_corruption`, wrap installed on `%active_transport` (not `Pier.emit`), so
it's transport-agnostic. `publicKey`→not-them; `sign`→invalid-signature; `%faulty,claim:step_N`. The receive
side is **already realised** (`hear_*` return false → `%error` → `Peeroleum_rollup_faulty`); the only new
machinery is the meddle wrap. Re-applies `MachPeerily.svelte:725-794`. Spec §14 / §14.1.

### 7 — binary frames  `[~]`
`body` + `body_hash` folded into the one envelope; `test_binary` as just-another-frame; corruption identical to
a tweaked hello-sign. Spec §4.2, §15.
- **Wire form = text header line then raw buffer (spec §4.2), NOT base64.** A buffer-carrying frame is
   `[header JSON]\n[raw buffer]` — one atomic message, "text first" (header human-readable at the front;
    JSON.stringify never emits a raw \n so the first 0x0A is the delimiter), raw bytes (binary is the bulk; no
    33% base64 tax). One message ⇒ no per-frame assembly queue (the receiver splits on the first \n: header = a
     JSON view, buffer = a near-zero-copy byte-tail). Beats Peerily's three-message crypto→data→buffer reassembly;
      the reassembly that IS needed (a transfer split into ~50kB frames) moves UP to the chunk layer (Phase 3). The
       buffer rides to PeerJS as one ArrayBuffer (whole-buffer efficiency). **Hybrid**: no-buffer frames (hello/
        trust/ack/noop/control) stay text JSON; only buffer frames go binary. The **mock** serialises nothing —
         it carries `{header, buffer:Uint8Array}` by reference. Buffer off-snap; only `body_hash`+`body_len` snap.
- **Digest is sha256, async all the way (was sync FNV).** The whole delivery path is now awaited end to end:
   the carrier `recv` awaits `Peeroleum_deliver` awaits `Peeroleum_pump_inbox` (an async serial drain) awaits
    `Peeroleum_body_digest` (await `crypto.subtle.digest('SHA-256', …)`). Because the carrier's `post_do`
     callback (`async () => { await partner.recv(frame) }`) is awaited inside the beliefs mutex
      (`_really_answer_calls` holds it across `await e.sc.fn(e)`), the digest resolves **within** Atime — the
       reason the FNV sync hack existed is gone. Mismatch → `%error:bad-body-hash` → `%faulty`, same path as a
        bad sign (no bifurcated error paths). sha256 makes `body_hash` **signable** — one-sig signing (header
         commits to the buffer via body_hash) now drops in with the trust layer, no second hash. Matches
          `cluster_trust.ts` `sha256hex` in strength (string-body vs raw-buffer is the only difference).
- **`test_binary` dispatches via the `Peeroleum_on` consumer registry** (§5 ask 1), not a hardcoded branch in
   pump_inbox; the harness registers it. Sent only AFTER handshake (the pre-Ud gate rejects non-hello/noop).
- **Carriers grow a binary branch.** `Socket_real` (Tribunal.g) encodes/decodes the `[header]\n[buffer]`
   message (`binaryType='arraybuffer'`); the relay (relay.ts) routes a binary message by reading the header
    line's `to` and forwards it whole (buffer opaque) — covered by `scripts/relay-test.ts` (local + cross-relay,
     buffer-intact). The mock/in-process carrier is by-reference, unchanged.
- **Exercise:** `Lake_exercise_binary` (Peregrination.g) runs as wrangler step 7, witnessed
   `%witnessed:send_binary`. The first of the transport-agnostic exercise set (same body runs over mock or the
    real-ws carrier). Built; lang-compile clean; **browser-unverified** — run on :9091, eyeball the lifecycle,
     Accept/Resnapture steps 2–7.

### 8 — disconnect + reset_handshake  `[~]`  transport reconnect BUILT; protocol reset still TODO
`%active_transport e:close` → `o_elvis:reset_handshake` on the Pier: drop protocol/outbox/inbox/faulty, keep
`%Ud`; p2paddy re-dials. Spec §9. **Protocol-level reset is still TODO** (the Lies channel is trust-everything
 v1 — it stamps `%Ud` and runs no hello/trust — so it didn't need it yet).
- **Transport-level auto-reconnect IS built** (the "no ping on both ends" bug — a dev-server/relay restart
   dropped both browsers at once and v1 had no reconnect). Three parts:
  - **`Socket_real` (Tribunal.g)** re-dials on `onclose` with capped backoff+jitter; `ws` is reassigned per
     reconnect (wire/send read it live, `port.ws` tracks it). New `port.on_open(cb)` re-fires consumer open-work
      on *every* (re)connect; `port.reconnect()` force-drops a half-open socket; ephemeral frames are dropped
       (not buffered) while down so `pending` can't bloat.
  - **`LiesLies` (`Lies_channel_up`)** registers the relay `become` via `port.on_open` (so a returning socket
     re-binds its role/addr), and `Lies_heartbeat` force-reconnects when a once-proven channel goes silent >20s
      (catches a half-open socket whose `onclose` never fired).
  - **Relay (`relay.ts`)** — fixed the bridge "state stuckness": a stale half-open `peerLink` is non-null but
     dead, and the `!peerLink` re-dial guards skipped it forever (only a server restart cleared it). Now a
      non-OPEN `peerLink` counts as down — closed and re-dialed on the next runner browser (re)connect.
  - **Editor needs the re-freeze**: it runs the FROZEN `p2p/transport/*.go`, so reconnect only reaches it after
     `cp src/lib/gen/N/*.go src/lib/p2p/transport/` (done this session). A runner-only fix leaves the editor's
      socket dead — the channel needs BOTH ends reconnecting. Browser-unverified; confirm two-origin on :9091/:9092.

### 9/10 — transport trial: webrtc → websocket fallback (mocked)  `[~]`  PROVEN in-app thru step 5
The mocked selection lives in `Ghost/N/Tribunal.g` ("a peer connection's reputation, constantly on trial") —
the carriers moved out of `Peeroleum.g` (now just the mock carrier + envelope). It runs as **steps 4–6** of
the wrangler, paced by Story STEPS, not a wall-clock window (a step boundary is already a quiescence point):
- **webrtc mock = black hole** (`.c.port.send` drops the frame → no ack); **websocket mock = working** (rides
   the shared in-process queue, ports paired by `Tribunal_pair_websocket`).
- **step 4 `Lake_trial_arm`**: install both carriers, hand `%active_transport` to webrtc, probe A→B; black hole
   → un-acked emit lingers (the visible no-ack). Witness: both `active_transport,type:webrtc`.
- **step 5 `Lake_trial_fallback`**: probe still un-acked → fall BOTH sides to websocket FIRST
   (`%transport,type:webrtc,faulty,reason:no-ack` + repoint active), THEN probe the relay (so the ack rides
    back; demoting both before probing kills the cross-side race). Witness: both webrtc `faulty` +
     `active_transport,type:websocket`.
- **step 6 `Lake_trial_confirm`**: relay probe acked → `Tribunal_reputation_good` blesses both carriers
   `%reputation:good`. (Fixed this session — see Test status.)
- **Proven on :9091 thru step 5** (the hard part): webrtc faulty, active→websocket, relay carried
   (`emit=5,acked` / `unemit=5,verified,done`), `witnessed:step_4/5`. Step 6 follows from the acked emit.

**Remaining = the real transports** (still `[ ]`):
- **9 — real webrtc**: replace the black-hole port with the real PeerJS DataChannel (relocated from old
   Peerily); note the app-level no-ack timeout built here STAYS needed (PeerJS reports connection-level errors
    for free, not a channel that opens then goes silent). Spec §4.1.
- **10 — real websocket** `[~]` ACTIVE: a `/relay` WS endpoint forwarding a signed frame by `header.to`
   without parsing `body`; client `.c.port` → real WS. **Settled design = spec §5.** Live build log under
    "START HERE" above.

### 11 — Thangs persistence  `[ ]`
`w:Thangs,thangs:peerings` / `thangs:identities` (Dexie) drive `req:p2pman` (online identities) and
`req:p2paddy` (known peers + `transport.last_good`). Spec §10.

### 12 — migrate Otro, delete Peerily, rename  `[ ]`
Move Otro onto Peeroleum; delete `Peerily.svelte.ts` + `MachPeerily.svelte`; rename Peeroleum → Peerily. This
completes the void of the legacy Mach layer. Spec §16.

### L — LangTiles gaps to close  `[~]`  (so more of this lives in `.g`, not raw JS)
Done so far (all verified with `npm run lang-compile`, corpus output unchanged): loose peel values
(`reason:no-direct-route`); `n%such → n.sc.such` (tight `%` only); `H`-receiver actor-laying (`H i A:Alice`);
`$` row-capture on a valued leg + multi-assigning two-leg (`%` now optional on peels). NB: editing
`stho.grammar` makes `stho.grammar.ts` stale (registry falls back to live `buildParser` — correct, just
flagged); regen via the in-app gen action. Still open — each a place the spine drops to raw JS:
- auto-`async` on a method with a bare `await`-verb; `drop`/`empty`/`oa` verbs + deep/wildcard `drop
  Pier/protocol/**`; drilled paths on `oai/r/rm`; object/`.c` payloads (`c.connection`, `stashed:{…}`); list
  fan-out (one `%req:dial` per peer over a thang list).
Corpus + compiler: `Ghost/test/Story/Lake/LakeTiles.g`, `src/lib/O/LangCompiling.svelte`, `LangCompiler_TODO.md`.
Prose orientation (verbs/peels/captures/`%req`+`doai`, how a `.g` goes live, how to change the language):
`src/lib/O/spec/stho_primer.md`. (PathVal value-token mechanics live in `io_tokens.ts`, covered there.)

### W — Hide compilation behind Waft architecture  `[ ]`
Make opening a Waft auto-compile its `.g` Docs, so the explicit `Dock_open` loop (and a hardcoded manifest)
disappears — the Net/Easy overlay's Docs become the manifest directly. (Verify it's still meaningful under the
Creduler acquire, which already loads a `CREDULER_GHOSTS` manifest.)

---

## Forward look — the cabinetry+party over the floor: Garden.g + Tyrant.g

**Peeroleum is the linoleum on the floor; the cabinetry and partying go over the top.** Over the transport
floor sits the social platform, reborn clean-room in stho as **two** new ghosts (legacy `ghost/Gardening.svelte`
+ `ghost/Tyranny.svelte` are the conceptual ancestors):
- **Tyrant.g** — the *cabinetry*: identity & trust (ex-Tyranny). **BUILT (`Ghost/N/Tyrant.g`, M1+M2,
   `lang-compile` clean).** M1 = trust over GIVEN identities (`%Ud` pre-stamped, a bidirectional `vouch`
    exchange over the Pier settling on acks → `%trust,grants:full`); M2 = policy-gated admission (`%req:join`
     whose `finished` is the AND of maz-ordered policy leaves `proven`∧`trusted`, above an `admit` leaf →
      `w/%member,signed` — "you're not on the network until the req is signed finished", the LiesStore
       phased-`%req` shape). Wired into `CREDULER_GHOSTS` (LiesLies) + the Net/Easy overlay (open
        "What:the cabinetry" to compile). **Not yet runnable** — needs a `wormhole/Story/Tyrant/toc.snap` Book
         (step=2/step=3 lines); held pending the "make step 1 neat" rethink. Meet+prove (earning `%Ud`) is the
          deferred deeper M2.
- **Garden.g** — the *partying*: social cultivation (ex-Gardening). Introductions, engagements, tending many
   Piers, pruning dead ones. **Net-new, unbuilt.**

Both ride the Peeroleum floor via the **reused transport seam** — they emit through `&Peeroleum_send` →
`Peeroleum_deliver` → `Peeroleum_take_ack` (the outbox/inbox lifecycle, `rollup_faulty`, whittle) and plug new
`hear_<verb>` receive handlers into the inbox dispatch exactly like `hear_hello`/`hear_trust`. No carrier code.
The attach point is heading 10's v1 **trust-everything** seam (spec §5: the runner has an Id, enforcement
deferred) — exactly where Tyrant.g's identity/trust bolts on. Design sketch (M0 reused / M1 trust over given
Alice+Bob / M2 meeting + policy admission) in `Covenant_design.md` (being realigned from the rejected "Joinery"
name to the Garden.g/Tyrant.g split). The earlier `Joinery`/`Covenant` single-ghost name is **rejected** — two
ghosts, Garden.g + Tyrant.g.

---

## Files in play
- `Ghost/N/Peeroleum.g` — the spine (compiled; the mock carrier + envelope + lifecycle).
- `Ghost/N/Tribunal.g` — the transport-trial carriers (webrtc/websocket mocks + `Socket_real`/relay client).
- `Ghost/Story/Peregrination.g` — the Book + wrangler: `Run_A_PereStaple`, `PereStaple(A,w)` installs
   `%req:wrangle`, `Lake_drive`/`Lake_witness`/`Lake_sides_up`/`Lake_trial_*`. (Acquired by the Creduler —
    `Creduler_ensure` / `CREDULER_GHOSTS` in `Lies.svelte`/`LiesLies.svelte`; no hand-written loader.)
- `src/lib/server/relay.ts` — the real `/relay` WS server (`attachRelay`) + its `configureServer` vite plugin.
- `wormhole/Ghost/Net/Easy/toc.snap` — annotation overlay / compile manifest.
- `wormhole/Story/PereStaple/toc.snap` — the Story that drives the Book (step lines run through `step=5`).
- `src/lib/O/spec/Peeroleum_spec.md` — the pinned design (the floor). This file — the living progress.
- `src/lib/O/spec/Covenant_design.md` — the cabinetry+party design sketch (Garden.g/Tyrant.g).
