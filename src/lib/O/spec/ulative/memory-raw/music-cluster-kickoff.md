---
name: music-cluster-kickoff
description: "the Ghost/M music-piracy cluster mini-project — reimplementing Radios.svelte on Housing+req, living doc + slice plan"
metadata: 
  node_type: memory
  type: project
  originSessionId: ec4d37d1-d9d4-432a-8a44-e895d203fe79
---

Narrow multi-session mini-project: reimplement the music-piracy machine
 (`src/lib/ghost/Radios.svelte` + neighbours) as a new `.g` cluster on Housing+req,
  watch it animate in Cyto, pin it with `Musu*` Books in the `Pere*` mould.

**The one living doc: `src/lib/O/spec/Radio_todo.md`** — read it first; it has the
 old→new instance map, the slice list, the wiring bombs, and the next move.

Layout (mirrors the `N`/`Pere*`/`Net/Easy` family):
- `Ghost/M/Radiola.g` — spine (working name; rename freely). Slice 1 = `req_cast`,
   the ACK-backpressure spool (Radios' `STAY_AHEAD_OF_ACK_SEQ=7`) as a pure particle sim.
- `Ghost/Story/Musuation.g` — the `MusuStaple` Book (Story ghosts grouped here, like
   Peregrination.g). 4 beats: link → fill-to-window → slide-on-ack → drain.
- `wormhole/Ghost/Music/Ality/toc.snap` — overlay Waft (Musicality), twin of Net/Easy.
- `wormhole/Story/MusuStaple/toc.snap` — step fixture, lie diges till first run.

Status (2026-06-25): slices **1, 2, 3 all DONE + ACCEPTED green**.
- slice 1 (ACK-backpressure spool, req_cast/Radiola_window; Book MusuStaple).
- slice 2 (preview→stream handoff): req_cast opt-in preview/stream gate + req_streamability; Book
   MusuStream (witness linked|previewed|wanted|streamed|streamdrained); pump terminal-before-caster
    so want→stream lands in one pass.
- slice 3 (radiostock fan-out): Radiola_keep_ahead(KEEP_AHEAD=5) + req_restock on a %Stock (finite
   `cap`-record source, %Record frontier) keeping keep_ahead ahead of the LEADING %cursor; Book
    MusuStock — ONE stock, two %cursor consumers (fast/slow), witness stocked|primed|served|sourced.
     First one-source→many-listeners graph shape. Endpoint = made===cap (source spent) with the slow
      cursor still trailing (records in hand), NOT a bug.
All in-cluster: no new CREDULER_GHOSTS line (new Books = new methods in already-enrolled Musuation.g);
 each Book = own world named after it (w:<Book> dispatch bomb), own verbs+witness-names. Cursor moves
  `.bump()` (Peeroleum idiom) so the Cyto wave rides.

**THE UNLOCK — accept loop is HEADLESS now (no :9091 needed to bake diges).** `scripts/CredRunner.spec.ts`
 = the Creduler-acquire→drive→pile harness; `BOOK=<Book> ACCEPT=1 node_modules/.bin/vitest run -c
  scripts/Story_cli.vitest.config.mjs scripts/CredRunner.spec.ts` records wormhole/Story/<Book>/*.snap +
   toc diges. NodeWormholeNav passes ONLY `wormhole/` writes through to the repo while recording
    (gen/+Ghost/ sandbox to /tmp), so nothing else is touched. **Flow: edit .g → ghost-compile each
     (live gen) → CredRunner dry-run (eyeball beats) → ACCEPT=1 (bake).** Both MusuStream + MusuStock
      baked this way, 5/5 exact. :9091 is now ONLY for the Cyto animation read, not the accept.
GOTCHAs: (1) parse-check fast via a throwaway FlockCompile-clone before ghost-compile. (2) ghost-compile
 needs the live editor tab awake — a backgrounded/throttled :9091 tab ACKs "editor compiling" then never
  writes the gen (times out @12s); a RETRY usually goes through once HMR settles, else FOREGROUND the tab.
   (3) host/runner edits Tribunal.g/PereStaple underfoot — re-check files before assuming a diff is mine.
**Slices 4-6 DONE + ACCEPTED** (full Books, baked headless via CredRunner 5/5 exact each). ALL SIX
 instances 1-6 now spine + Book + accepted (Radios items 7-8 = codec/disk, out of scope). The three:
- 4 MusuLive — live-edge playback (req_progress + Radiola_live_back=3, term.sc.ended drops the margin):
   %Player decodes %Chunk→%aud LINKED LIST (chained on player.c.tail) ahead of playhead, stays 3 behind
    the live edge, drains through on ended. Witnesses wired|buffered|followed|caughtup. First non-star
     Cyto shape (a chain).
- 5 MusuWear — wear/GC (req_reap + wear_enough/wear_delay shrunk to 2/3): %Record→%wore_out flag
   tombstone-in-place; req_reap has a RUNNING floor counter (n, break at <=5) so it never reaps below
    the floor. Witnesses stockpiled|heardenough|reaped|floored.
- 6 MusuSkip — skip-track (Radiola_skip, no req — direct strike): %Knob advances term.sc.record + resets
   player (playhead -1, %aud chain marked %stale), fresh auds re-decode beside the husks. Witnesses
    cued|spinning|skipped|resumed.
Radiola @1ddd51d2 / Musuation @ad788b2d. 6 Books on Credence (What:Musu). Bare-1 quirk: record=1 rides
 bare `record` (witness firing confirms it, grep `record=N` misses it).

INTEGRATION LAYER (2026-06-25, green): `scripts/MusuSignal.spec.ts` — the ORTHOGONAL test the tick-snap
 Books can't be (those witness cursor arithmetic, no clock/signal). Acquires the spine CredRunner-style,
  then drives `req_cast`→`req_progress` (one shared %inbox) on the WALL CLOCK (ack/playhead advance off
   Date.now, not ticks) with REAL PCM on `.c` (Float32Array = object → .c, NEVER .sc), decode→bufferSource
    →gain→capture (the real Audio.svelte.ts surface; jsdom has no Web Audio so a faithful MUTED OFFLINE
     ctx stands in — capture replaces AC.destination = the app's own `gainNode2.disconnect() //don't hear
      it`). Witness = ENTROPY not a byte-snap (real time+audio is nondeterministic): int16 the rendered
       PCM, assert Shannon bits/byte>4 + a SILENT negative control (payload zeroed → 0 entropy, the
        `\x00` stream) → gate has teeth. Observed 7.62 vs 0, 48/48 chunks over ~1.1s real. ONE new file,
         spine+Books untouched, no :9091, no ACCEPT. Codec seam (opus, Radios item7) still out of scope →
          decodeAudioData is identity (payload is uncompressed PCM). Run: `node_modules/.bin/vitest run -c
           scripts/Story_cli.vitest.config.mjs scripts/MusuSignal.spec.ts`. /music = 212 .opus (need a
            decoder we don't have → synth the source: a chord + seeded dither, deterministic no Math.random).

STORY-RUNNER INTERFACE (2026-06-26, green browserless, owes :9091 verify; spec/Radio_todo.md §6.2): a
 request/reply RPC to a LIVE BROWSER runner (booted ?B=<Book>) over the EXISTING `/relay` websocket —
  the real-time/real-audio twin of headless CredRunner, and the thing that gets MusuSignal OUT of scripts/.
   EXACT mirror of scripts/ghost_compile.ts (addr-less CLI → editor, corr-routed): here `runner_ask` →
    runner, `runner_ack` ← runner, routed back by the relay's `ackBack` map by corr. FOUR touches, ALL
     additive: (1) `src/lib/server/relay.ts` — generalised the corr-remember to also catch
      header.type==='runner_ask' + a `runner_ack` control verb (mirrors ghost_compile_ack); nothing else
       in the relay changed. (2) `LiesLies.svelte` — `on('runner_ask', …)` on the runner role. (3)
        `LiesFunk.svelte` — `Lies_runner_ask_recv(w,frame)` dispatch {ping|run <Book>|state|steps|snap n},
         replies `{control:'runner_ack',corr,…}` via the Lies_ghost_compile_ack ws idiom
          (w.o({transport:1,type:websocket})[0].c.port.ws.send). run=Lies_become_book_drive on the wall
           clock; state=Cred_run_outcome()+Storyrun phase/n/total; snap n=a This/Step's got_snap (the
            "examine the writings" read; +Lies_runner_this() helper). (4) `scripts/runner_ask.mjs` — the
             sender (addr-less, corr-settled vs runner_ack/undeliverable/timeout, --watch polls state to
              verdict, exit code carries ok). PROOF: `scripts/runner-ask-test.ts` (relay-test pattern: real
               relay + fake runner + addr-less fake CLI) 6/6 green; CLI smoked end-to-end vs a node relay
                (ping/run/state ok, exit codes right); svelte-check 0 new lines on edited files.
   KEY FACTS: runner binds relay addr = peering.sc.name = role = 'runner' (Tribunal.g:65). WHY a CLI frame
    with a FOREIGN from (cliAddr, not 'editor') reaches the consumer (the thing I first wrongly hand-waved):
     the live runner's w:Lies is SINGLE-IDENTITY (one Peering:runner, one Ud'd Pier:editor — LiesLies:202-206),
      and Peeroleum_route's "ONE Peering / ONE Pier ⇒ use it" short-circuit (Peeroleum.g:258,262) resolves ANY
       inbound frame to that sole Pier REGARDLESS of from — the swarm-refactor short-circuit, ALREADY in live
        gen, NO new .go (the user's "we fixed that near Peeroleum, no .go pin" = THIS, confirmed). Then reliable
         relay carrier books straight, no inseq (Peeroleum.g:357); the inbox gate checks only %Ud, never from,
          and Ud is set → passes (Peeroleum.g:420); dispatch to on('runner_ask'). SAME path prod become_book
           rides. DON'T cite ghost_compile as the proof — it actually settles on its dige-POLL, not this hop.
      Handlers are .svelte eatfunc, NOT .g spine → NO ghost-compile. v1 UNSIGNED/trust-everything (run =
       already-compiled gen, dev localhost); signing mirrors ghost_compile when CLUSTER_TRUSTED_PUBS deploys.
        RUNNER_URL default http://172.17.0.1:9091.
   TWO FOLLOW-ONS (NOT built, flagged in §6.2): (1) `H.SECONDS_IN_SECONDS` 3× time-scale — threads
    load-bearing core (now_in_seconds_with_ms in Peerily.svelte.ts; tick consts ANSWER_CALLS_TICK_MS=50 /
     AMBIENT_MAIN_TICK_MS=200 in Housing.svelte.ts; Audio.svelte.ts durations + ttlilt i_req_ttlilt) →
      PROVE IN ISOLATION first ([[fight-back-on-core-changes]]), don't bundle. (2) relocate MusuSignal into
       a real browser Story Book read via runner_ask snap/state. The user's "floating thing" = the
        Lens/Brink %Aim cluster Waft (Funkcion:Runner/Relay/Upkeep faces in src/lib/O/Funk/, suggested by
         Lies_aim_setup) — a Funkcion:StoryRunner face is the natural status surface, NOT yet built.
   PROVEN LIVE 2026-06-26 against a real browser runner (NOT just node): drove PortPlan (green 2/2), AwFloat
    (red BY DESIGN — lie-dige toc.snap a0a0a0a0…, never ACCEPTed), MusuLive (red live). GOTCHA caught: the
     on('runner_ask') registration is in Lies_channel_up which runs ONCE (if channel_up return) — HMR
      re-mixes the METHOD body but NOT that one-time registration, so an already-open runner tab needs a
       PAGE RELOAD to gain a newly-added consumer handler (a new OP on an existing handler DOES hot-swap,
        since dispatch is in the method body). Worth fixing: register consumer handlers outside the
         once-guard so HMR picks them up.

READLINE STORY EXPLORER + DIFF-OVER-SOCKET (2026-06-26; spec Radio_todo §6.2 + Story_next_level_spec §16.1 =
 "agent as test driver"): `scripts/story_repl.mjs` — readline shell over runner_ask, one persistent socket,
  `story›` prompt: ping/run <Book> [--watch]/watch/state/steps/snap <n>/diff <n>/books/book/help/quit; line
   handling SERIALISED (queue+drain) so piped/scripted input runs in order, doesn't exit mid-flight. New
    `diff` OP on Lies_runner_ask_recv returns {n,ok,dige,book,got_snap,exp_snap}; exp_snap is usually null
     (Story.svelte:1470 loads it LAZILY only when the UI diff panel opens), so the REPL fills expected from
      the SHARED-DISK fixture wormhole/Story/<Book>/<NNN>.snap (pad 3) and does a colourised LCS line-diff
       (±2 context, collapse unchanged, -del/+add surprise count). DIFF EARNED ITS KEEP first use: MusuLive
        red live = ONLY `self,round` off by constant +6 (baked 8/10 vs live 2/4), every other line identical
         → stale-bake COUNTER FUZZ (§4.2) from the Run_A prep-tick shift, NOT a regression; fix = re-ACCEPT,
          not code. Residual: got is fully over-socket, exp rides disk (works on shared /app); driving the
           fetch_snap Wormhole read in the handler = exp-over-socket = §16.1 follow-up. type-clean (baseline
            implicit-any noise only; check drifts run-to-run per cache).

RUNNER-TALK INTERFACE — CONSOLIDATED + EXTENDED (2026-06-26): the remote-runner Story talk-to interface
 outgrew the music cluster; its single pointable brief is now `spec/Runner_talk_TODO.md` (drive→examine→
  accept a LIVE browser runner over the relay = the LIVE realisation of Cluster_design.md §7 "self-driving
   Tiers", which were headless-framed; cross-linked from §7 + Story_next_level §16.1 + Radio_todo §6.2).
  BUILT + VERIFIED LIVE this session (all .svelte eatfunc + story_repl, HMR'd into :9091, no .g/.go):
   • 1a `snaps` op (atomic multi-step got_snap read from one This pass) → story_repl `diff <n> prev|<m>`
      temporal diff is now a coherent single read (was two racy snap calls). Showed LeafFarm step-9→10 sim
       evolution (round tick, leaf-dose conveyor, enzyme production, seen:wonder).
   • 1b1 `retain` op → sets w:Story.c.keep_snaps, which ALREADY gates Story.svelte:2008's 5-step got_snap
      trim (core flag pre-existed; just exposed it). `retain on` BEFORE a run keeps middle steps inspectable.
   • 1d `trace` op → step.sc.Run_trace (the beliefs-cycle trace, drained Story.svelte:1997): per-actor
      think + the `quiescent` label = causal-vs-TIMEOUT (the WHY). Proved LeafFarm step 5/10 red = clean
       quiescent 0.089s, NOT a wedge — red is purely the output diff, not a stall.
  story_repl commands now: ping/run [--watch]/watch/state/steps/retain/snap/trace/diff <n>/diff <n> prev|<m>/
   books/book/help/quit. DEFERRED 1c (exp-over-socket): on shared /app the runner's fetch_snap reads the SAME
    disk fixture run_path=Story/<book> the CLI already falls back to → byte-equivalent; only matters for a
     no-shared-disk remote runner. REMAIN: 1e SIGNED ACCEPT (the one WRITE op — sign under claude cluster
      Idento like ghost_compile, runner verifies w/ browserTrustedPubs, records via Resnapture; do DELIBERATELY,
       it bakes toc diges) + 1f handler-re-register (low pri — only a NEW frame TYPE needs it, new OPS HMR
        fine). GOTCHA STILL OPEN: the StoryTimes sweep CLOBBERS This between commands (runner is shared/
         churning) — retain fixes the trim WITHIN a run, but sweep-replacing-This is the separate 1b3
          sweep-quiesce (do diffs in ONE tight session right after the run). type-clean.

CLEANUP (2026-06-25): the per-Book `Run_A_<Book>` (role + `H i A:Book/w:Book`) is DELETED for all 6 —
 Story_subHouse (Story.svelte:~1189) already defaults to `Run.i({A:book}).i({w:book})` when no recipe
  exists; role comes from `Run.c.role ??= top_House().c.boot_role`, so the HEADLESS CredRunner now sets
   `H.c.boot_role ??= 'runner'` (the live runner gets it from ?B=). CredRunner SPINE_READY OR'd in
    `typeof H[BOOK]` (world-named handler) so it survives a Book with no Run_A. Browserless compile via
     `scripts/LocalGen.spec.ts` (GFILES=…) — no editor tab needed (ghost-compile kept timing out).
TWO SCARS from this cleanup: (1) the `c.up`-default-in-i() detour broke EVERYTHING — reverted, c.up stays
 hand-stamped ([[fight-back-on-core-changes]]). (2) deleting Run_A shifts the PREP (step-1) tick-count so
  `self,round` moved off baked `1`(bare, dodges spay `round={NUM}`) → re-accept the prep. (3) MusuLive
   is LOAD-FLAKY headless (captured 1/5 under 7-books-concurrent load); a flaky ACCEPT then PRUNED its
    toc to 1 step (self-perpetuating). Fix = restore toc step=2..5 + re-accept ISOLATED → 5/5. Re-accept
     books ONE AT A TIME, watch the `rewrote N snaps` count, never trust an accept that baked < the step count.
NEXT pattern-congealing (SAFE, cluster-local): the 6 identical `X_order` (→ one `Musu_float`), the 6
 identical `X_drive` dispatch skeletons (→ a declarative beat table), `X(A,w)` wrangle-install, the
  `_witness` idempotent-stamp helper, auto `reached:step_N`. NOT c.up (load-bearing → needs the
   level-uniform sweep [[aw-req-level-uniformity]], not a default).

**Waft:Ality is now a navigable MAP** (wormhole/Ghost/Music/Ality/toc.snap): the machine (slices 1-6 →
 spine methods), the tests (3 Books → _drive/_witness), the source it reimagines (Radios.svelte → orig
  fns), the spec, + **bridges**. See [[text-point-bridge]] for the new `Point,text:<word>` capability
   (fine-grained sub-line Points that land on a literal token, bridging the SAME shared token across
    spec↔new.g↔old Radios.svelte — incl rename rows KEEP_AHEAD→keep_ahead, preview→radiopreview).
NEXT = browser-verify the Ality map + bridge click-through on :9091; then Book any prototype 4-6. §7/§8.
Built tightly on [[stho-primer]] / Peregrination.g idiom; req-pump + peels are the
 likely first compile-error sites. Don't bump outside the cluster — Cyto/Matstyle
  auto-discover new mainkeys.

BOMB: the per-beat handler dispatches by WORLD NAME (do_fn_for reads w.sc.w), so the
 Run world MUST be named after the Book — `H i A:MusuStaple/w:MusuStaple`, handler
  `MusuStaple(A,w)`. A mismatched world (w:Musu) makes the handler silently never fire.
   Caught only because the live runner renamed Peregrination's world (w:Peers→w:PereStaple)
    mid-session — re-read files the host/runner also touches ([[host-commits-midsession]]).

CASCADE MIGRATION (2026-06-27/28 — COMPLETE: ALL 6 Books migrated 5/5 + MusuCrowd built 5/5): the
 domain particles become TYPED SERIAL-REQS so the ambient w-sweep pumps them and the per-Book hand-crank
  dies. Staple/Stream/Stock/Live/Wear all migrated (every X_pump DELETED, witness split out); MusuSkip
   needed NOTHING — it has no spine-req pump (hand-seeds %aud via MusuSkip_seed, synchronous in the drive,
    so its inline witness still observes correctly; its Terminal/Player carry no req → passive, untouched).
     MusuStream's ONE wrinkle: its old pump ran TERMINAL-before-caster (streamability decides want, cast
      honours it same-pass) → mint the %Terminal serial-req BEFORE the %Caster in _sides_up, so the sweep
       (creation order = sweep order for same-maz reqs) pumps req_streamability before req_cast; wanted +
        streamed survived, proving creation-order governs. The OLD framing kept below for the mechanics:
  the Peregrination Peering/Pier move applied to Musu. Radiola.g gained 4 dormant pumps
   (req_Caster/req_Terminal/req_Stock/req_Player, each just `await x&do; x%ok=1`, twins of
    req_Peering; req_Stock pumps BOTH restock+reap in one do() — the "two jobs" wrinkle evaporates).
     Per Book: installer `w.i({Caster…})` → `w.oai({Caster…,req:1})` + hand-stamp c.up (oai DEFERS
      c.up like Lake_peer), KEEP the `%req:cast` leaf mint, DELETE `Musu_pump` + its `_drive` call.
       Snap delta = Caster gains `,req=N,ok`; cursor numbers + Chunks byte-identical → re-ACCEPT once.
   **THE LOAD-BEARING LESSON — split the witness into its own swept req.** A Musu witness checks
    TRANSIENT edge state (`next === ack+win+1` = spool at the window edge). That only snapped right
     because old `Musu_pump` ran pump-THEN-witness in ONE synchronous Musu_drive pass. Decoupled (spool
      now self-swept), the wrangle (created first → swept first, carrying go_live which MUST precede the
       spool) runs its witness BEFORE the spool each pass; a Musu step is a SINGLE think→quiescence→snap,
        so the witness never observes the settled cursor → `witnessed:filled/slid/drained` VANISH. Fix:
         mint `%req:witness,eternal` (doai block calling X_witness) in `_sides_up` AFTER the casters, so
          the w-sweep order is wrangle(go_live) → Caster(spool) → witness(observe), all one think. Proven:
           restored every stamp, 5/5. This is the TEMPLATE for migrating Stream/Stock/Live/Wear/Skip (each
            still has its `_pump` + witness-in-drive). Why Peregrination DIDN'T need it: its witnesses check
             PERSISTENT particle existence (handshake said_hello), stable across its many thinks.
   MusuCrowd = the multi-client Book (one source, TWO listeners as 2 independent %Caster spools fast+slow,
    each backpressured by its own Terminal ack). beat4 DIVERGES: fast acks 4→drains next=12, slow acks
     0→holds next=8 (`witnessed:diverged`); beat5 slow catches up, both drained. Cascade-native from birth
      (no _pump, witness is its own req). Fully deterministic (exact 5/5, no round-noise). A fresh Book = a
       method-set in Musuation.g + a hand-authored `wormhole/Story/MusuCrowd/toc.snap` (story header +
        Styles/Plan/Opt/For + N `step,dige:lie` lines) → CredRunner ACCEPT bakes the real snaps. NOT yet on
         the Credence board / browser-verified. Still-identical X_order across 7 Books = a congeal target.

REAL-AUDIO FAMILY seeded (2026-06-29): `Book:MusuSignal` — a regime BESIDE the deterministic tick Books:
 drive the SAME spine (req_cast→req_progress, DIRECTLY not swept — a straight pipeline is code not a req,
  per [[req-not-mandatory]]) with GENERATED synth PCM and MEASURE the rendered signal. #1 BUILT 3/3 exact,
   deterministic, headless: MusuSignal_synth (deterministic chord+dither) → pipeline walks playhead 0..47 →
    MusuSignal_measure → `signal,bits=7.62 (noisy) / gaps=0 (no silent window) / rms`. READOUT is COARSE+
     MUTED: after measuring, `await inbox.rm({Chunk:1})` + `player.rm({aud:1})` prune the 48+48 transient
      particles → 17-line snap (was 113), leaving phase/at/of + event:buffered/drained + the signal line.
       rm = the removal verb (`w.rm({k:1})` / `w.rm(c)`, awaitable, LakeTiles canon). NOT YET (iteration 2):
        the REAL muted Web-Audio graph (browser AudioContext→gain→AnalyserNode, NEVER →destination = silent
         by construction; an IMPORT'd capability — it's a browser API), the NEGATIVE CONTROL (silence→~0 bits,
          gate-has-teeth), WALL-CLOCK pacing (3s snaps / plays-a-while / skip→live_edge events; step held open
           by an awaited run or a ttlilt). **scripts/MusuSignal.spec.ts NOT deleted yet** — it still uniquely
            covers the real muted-audio-API + the negative control; delete only when the Book subsumes them.
             EntropyArrest dontSnap/slack becomes NECESSARY at iteration 2 (timing goes nondeterministic);
              #1's deterministic synth made it exact without forgiveness.

MusuSignal MADE REAL + 3-LAYER ARCH + .ts DELETED (2026-06-29): the user rejected the first cut as fake
 ("hand-cranks straight to success, nothing can fail"). Rebuilt as a REAL streaming test: `Musu_stream`
  models a live stream at a DELIVERY rate (the wire) vs a PLAYBACK rate (the listener); req_progress
   decodes ahead staying live_back behind the live edge; when the playhead OUTRUNS the decode frontier it
    renders silence = an underrun (THE failure mode). Three runs: healthy(feed 3/play 1)→clean (gaps0,
     underran0), starved(feed 1/play 3)→HITS THE LIVE EDGE (underran 47, gaps 47), silence→gate teeth.
      5 witnesses streams/noisy/starves/silent/separable; 5/5 exact deterministic. It's a LOGICAL-TICK sim
       (~42ms compute for 48 positions), NOT real-time — wall-clock is the future browser iteration.
   ARCH (the user wanted reality / test-helpers / per-Book clearly divided, "together"): Musuation.g now
    has //#region reality (Musu_synth/Musu_silence/Musu_measure/Musu_stream — real software beneath, NO
     scaffolding) / //#region testkit (Musu_float — generic, the generalised _order off w.sc.w) / //#region
      slices|composite|realaudio (each Book separate). Spine reality stays Radiola.g.
   on_step ADOPTED for step dispatch: `await this.on_step({2:()=>…,3:()=>…})` replaces the req.c.did_step
    guard (works because ONE Book runs per CredRunner — the H-global did_on_step_n collision the Pere*
     lesson warned of only bites with multiple callers).
   **GOTCHA — rm takes a PATTERN sc, NOT a particle.** `w.rm(term)` silently matches nothing (a TheC isn't
    a sc-pattern) → the spine residue piled up ("a new Terminal every time", 300-line snap). Fix:
     `w.rm({Terminal:1,name:kind})`. rm = r(pattern,{}) — Stuff.svelte.ts:787.
   `scripts/MusuSignal.spec.ts` DELETED — the Book subsumes it (real streaming + entropy gate + silence
    negative control; the .ts's jsdom MutedAudioContext was a fake identity-copy, no real coverage lost).
   CREDENCE: `wormhole/Credence/toc.snap` What:Musu now NESTS What:slices/composite/realaudio (mirroring
    the regions), Funkcion:Storying under each. Hand-authored fixture; BROWSER-UNVERIFIED — CreduFunk reads
     `funk.o({Funkcion:"Storying"})` (direct children), so the nested What may need the renderer to recurse.
   NEXT: realistic PARTIAL stutter (mid-stream throttle: healthy→starve, not a binary cliff); then the real
    MUTED Web-Audio graph (browser AudioContext→gain→AnalyserNode, an IMPORT'd capability) + wall-clock.
