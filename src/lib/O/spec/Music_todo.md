# Music_todo.md — the music-piracy cluster, reborn on Housing+req

The one living doc for a narrow, multi-session mini-project: reimplement the music-piracy
 machine (`src/lib/ghost/Radios.svelte` and its `src/lib/ghost/` neighbours) as a new `.g`
  ghost cluster, `Ghost/M/*`, written in stho/LangTiles and standing on Housing+req — the
   generation of machinery that the *shortfalls* of the old `Modus.eatfunc` streaming code
    inspired in the first place. We pull the old workings into view one **instance** at a
     time, model each as a pure particle **simulation** (no audio, no WebRTC — just the
      cursor arithmetic), watch it **animate** in the live Cyto graph, and pin it with a
       `Musu*` Book in the `Pere*` mould.

This file is the destination + the bombs + the next move. Keep it current; it is the memory
 the next fork would otherwise re-derive.

---

## 1. Destination

`Radios.svelte` is 1500 lines of pre-Housing machinery: a hand-rolled spin loop over
 `Modus`, cursors smeared across `.sc`/`.c`, backpressure as an inline `if … cool it`, the
  whole streaming algorithm tangled with real `MediaRecorder`/WebAudio/disk I/O so you can
   never *watch* the algorithm — only hear its output (or its silence). The new tech exists
    precisely because that hurt:

- **a req that bows out IS backpressure** — no spin guard, no `waits`/`see`/`satisfied`
   bookkeeping; the spool req simply finds no chunk it may send and makes no progress.
- **particles are legible** — `%Caster`/`%Terminal`/`%Chunk`/`%cursor` snap, so Cyto draws
   them and Matstyle swatches them with zero new view code; the algorithm becomes a picture.
- **simulatable** — divorced from codecs and the wire, the seq/ack model runs headless and
   deterministic, so a Book can drive it beat by beat and a witness can assert each beat.

The end state is not "port every line." It is: the *interesting* behaviours of music piracy,
 each lifted into a runnable, watchable, witnessed simulation on the new machine — and the
  old `Radios.svelte` left to do only the irreducibly-real part (transcode bytes, push them
   over WebRTC) if anything at all.

---

## 2. The cluster — layout, names, and the wiring bombs

```
Ghost/M/Radiola.g              spine — the reusable mechanism (req_cast, the window)
Ghost/Story/Musuation.g        the Musu* Books (Story ghosts are grouped under Ghost/Story/,
                                like Peregrination.g — the file is the artifact, MusuStaple is
                                 the Book identity)
wormhole/Ghost/Music/Ality/toc.snap   the overlay Waft (Musicality) — curates the cluster,
                                        the twin of wormhole/Ghost/Net/Easy
wormhole/Story/MusuStaple/toc.snap     the Book's step fixtures (lie diges till a real run)
src/lib/O/spec/Music_todo.md           this doc
```

Names mirror the `Pere*`/`N`/`Net/Easy` family so the parallel reads at a glance:

| network (the template) | music (this project) |
|---|---|
| `Ghost/N/Peeroleum.g` (spine) | `Ghost/M/Radiola.g` (spine) — *working name; rename freely* |
| `Ghost/Story/Peregrination.g` | `Ghost/Story/Musuation.g` |
| Book `PereStaple` | Book `MusuStaple` |
| `Waft:Ghost/Net/Easy` | `Waft:Ghost/Music/Ality` |
| `Lake_*` (the scenario verbs) | `Musu_*` (the scenario verbs) |

**BOMB — registration order.** A ghost is enrolled in `CREDULER_GHOSTS`
 (`src/lib/O/LiesLies.svelte`, ~line 51). The runner's `Creduler_ensure` loads each entry's
  *gen* `.go` and waits on `%Creduler_pending` until every `Ghostmeta_*()` reports live. **A
   gen `.go` that does not yet exist hangs the runner boot.** So the M cluster is NOT in
    `CREDULER_GHOSTS` yet, and must not be until each `.g` has been ghost-compiled. That edit
     is the one unavoidable touch *outside* `Ghost/M/`; it is deferred to the human and listed
      as the next move (§7). Until then nothing in `Ghost/M/*` is live; the source is inert.

**BOMB — ghost-compile needs a live editor.** There is no standalone `.g→.go` CLI.
 `npm run ghost-compile -- <file.g>` signs a ticket to the in-app editor on `:9091`, which
  force-loads the dock, compiles, writes `src/lib/gen/<cluster>/<File>.go`, and HMRs it.
   `Ghost/M/Radiola.g → src/lib/gen/M/Radiola.go`; `Ghost/Story/Musuation.g →
    src/lib/gen/Story/Musuation.go`. `scripts/LakeRace.*` exercises an *already-compiled*
     spine headless — it is not a compiler. So: author here, compile in the browser.

**BOMB — don't bump outside the cluster.** Cyto and Matstyle auto-discover by mainkey
 (`cyto_scan` + `cytyle_classify`; Matstyle autovivifies a `matstyle:<key>`), so new
  particle types appear in the graph with swatches and *no* view-code edits. That is the lever
   that keeps this project inside `Ghost/M/` + `Ghost/Story/Musuation.g` + the two snaps + this
    doc, plus the single deferred `CREDULER_GHOSTS` line.

---

## 3. The old workings → what we pull into view

The instances to lift, roughly in dependency order. Each becomes a slice (§4). Constants are
 the real `Radios.svelte` numbers — keep them so a sim reads true.

| # | old instance (Radios.svelte) | the behaviour | new shape (sketch) |
|---|---|---|---|
| 1 | **ACK-backpressure spool** — `racaster`/`transmit_record`, `STAY_AHEAD_OF_ACK_SEQ=7`, `not_too_far_ahead = ack + 7`, `if pr.seq > … cool it` | caster spools chunks ahead of the listener's ack, bounded by a window; stalls when too far ahead | `%req:cast` on a `%Caster`: deliver while `next ≤ ack+window`, else bow out **← SLICE 1 (this session)** |
| 2 | **two-tier preview→stream** — `radiopreview`/`rastream`, `PREVIEW_DURATION=33`, `streamability`, `MIN_LEFT_TO_WANT_STREAMING=22`, `want_streaming` | every track streams a free fixed preview; when it runs low the listener asks for the full continuation | `%Chunk,kind:preview|stream`; a `%req:streamability` arms `%want:stream` when preview tail < 22 |
| 3 | **radiostock cursor inventory** — `radiostock`/`radiostock()`/`io:radiostock`, `consumers,of=radiostock`, `KEEP_AHEAD=5` | one stock, a per-listener cursor serving the next unheard record, refill when low | `%Stock` + `%cursor,client:…` per terminal; `%req:restock` when `least_left < 5` |
| 4 | **live-edge playback chain** — `listening`/`progress`/`enqueue`, "stay 3s back from live edge" | decode-ahead linked list, hop on ended, stay just behind the live edge | `%aud` linked list as `%Chunk` refs; a `%req:progress` that decodes ahead of the playhead |
| 5 | **record wear / GC** — `recordWear`, `LISTENING_FOR_LONG_ENOUGH=3`, `…_DELAY=19`, wore_out tombstones | listened records age, wear out, get reaped | `%Wear` accreting on a `%Record`; a sweep req tombstoning `%wore_out` |
| 6 | **skip-track** — `turn_knob`/`do_skip_track_fn` | listener jumps to the next record mid-stream | a `%Knob` strike that advances the terminal's record cursor |
| 7 | **record encoding/segmentation** — `radiopreview`/`rastream` MediaRecorder loop, LUFS, metadata | transcode a source file into seq'd webm/opus chunks | *probably stays in Radios.svelte* — the irreducibly-real codec work; we simulate the SEQ model (a `%Record` of N `%Chunk`s), not the bytes |
| 8 | **disk cache** — `radiostock_caching`, `.jamsend/radiostock/*.webms`, `RADIOSTOCK_CACHE_LIMIT=200` | warm/evict records to/from OPFS | likely out of scope (real I/O); model only the count pressure if a sim needs it |

Items 7–8 are the seam where the new machine hands back to the old one for real bytes/disk.
 Everything 1–6 is pure cursor/state and belongs fully in `Ghost/M/*`.

---

## 4. The slices (the narrow stream)

One slice at a time; each is: a spine mechanism + a `Musu*` beat or two + a witness + (from
 slice 2 on) a Cyto read. Land it, compile it, run it, accept the snap, then the next.

- **Slice 1 — ACK-backpressure spool.** `req_cast` + `Radiola_window`; Book `MusuStaple`
   beats 2–5 (link → fill-to-window → slide-on-ack → drain). **Status: compiled, run, ACCEPTED
    (§7) — green.** This is the heartbeat; everything else spools on top of it.
- **Slice 2 — preview→stream handoff.** `req_cast` grows an opt-in preview/stream gate +
   `req_streamability`; Book `MusuStream` (own world/verbs, slice 1 untouched) beats 2–5
    (link-with-preview → preview-and-HOLD → want+stream → drain). `%Chunk,kind:preview|stream`,
     `%want:stream` on the terminal, `want_left` floor on `w`. Cursor moves now `.bump()` so the
      Cyto wave rides them (the first animation target: the inbox holding at the preview gate, then
       the continuation pouring in on the want). **Status: compiled, run, ACCEPTED — green** (§7;
        baked headless via CredRunner).
- **Slice 3 — radiostock cursor / multi-listener fan-out.** `req_restock` + `Radiola_keep_ahead` on
   a `%Stock` (a finite `cap`-record source, `%Record` frontier) feeding two `%cursor` consumers; Book
    `MusuStock` (own world/verbs) beats 2–5 (stock+two-cursors → prime-the-buffer → serve-the-leader →
     source-spent). Restock keys off the LEADING cursor (KEEP_AHEAD=5 ahead of the fastest), so the
      lagging listener visibly trails — the first genuinely graph-shaped picture (one stock → two
       cursors, a growing `%Record` pile). **Status: compiled, run, ACCEPTED — green** (§7).
- **Slices 4–6 — DONE, ACCEPTED — green** (§7; baked headless via CredRunner, 5/5 exact each). Each
   a faithful mechanism in `Radiola.g` carrying the real `Radios.svelte` constants, plus a focused Book:
  - **4 live-edge playback** — `req_progress` + `Radiola_live_back(3)`; Book `MusuLive` beats 2–5
     (wired → buffered → followed → caughtup). A `%Player` decodes delivered `%Chunk` into an `%aud`
      **linked list** (chained on `player.c.tail`) ahead of its playhead but stays `live_back` behind
       the live edge; once the stream `ended` the margin drops and it drains through. The aud chain is
        the first non-star Cyto shape (a chain, not a hub).
  - **5 record wear / GC** — `req_reap` + `Radiola_wear_enough(2)`/`Radiola_wear_delay(3)` (shrunk for
     a tight Book); Book `MusuWear` beats 2–5 (stockpiled → heardenough → reaped → floored). A
      heard-enough, long-idle `%Record` is tombstoned in place with `%wore_out` (a legible husk, not a
       delete); a running floor counter holds ≥5 live, so the last eligibles are KEPT (floored).
  - **6 skip-track** — `Radiola_skip`; Book `MusuSkip` beats 2–5 (cued → spinning → skipped → resumed).
     A `%Knob` strike advances the terminal's `record` cursor and resets the player; the abandoned
      `%aud` chain is marked `%stale`, fresh auds re-decode on the new record beside the husks.

Keep `MusuStaple` as the staple end-to-end book; spin out focused books (`MusuStock`,
 `MusuWear`, …) under the same `Ghost/Story/Musuation.g` as slices land, exactly as the
  `Pere*` family piles books into one file.

---

## 5. Simulation & animation

The point of the rewrite is to *see* the algorithm, so every sim particle is built to be
 Cyto-legible:

- **snap-reachable** — `%Caster`/`%Terminal`/`%Chunk`/`%cursor` live under `w:MusuStaple` in the
   Run tree, so they snap and `cyto_scan` finds them. No `dontSnap`, no off-pump stashing of
    anything the eye should follow.
- **version-bumped on change** — the wave (`cyto_update_wave` + grawave) animates off version
   bumps. Cursor moves that the eye should catch (a chunk delivered, an ack advancing) should
    go through a tracked C method so the bump fires. Slice 1 mutates `.sc` scalars directly
     (fine for witness/headless); **when wiring animation, route those through `replace`/`r`
      so the wave has something to ride** — that's the slice-2 todo, not slice-1.
- **generic graph first** — start with the auto-swatched Cyto view; only build a bespoke
   "spool lane" view if the generic graph can't show the window breathing. Don't pre-build
    viz.

The simulation is deterministic and headless-friendly: no clocks, no randomness in the model
 (vary only by step). The window (`7`), preview (`33`/`22`), keep-ahead (`5`) are the
  `Radios.svelte` constants, read off `w.sc.*` so a Book can shrink them for a tighter snap.

---

## 6. Tests — the Musu* Books

Built exactly like `Pere*` (read `Ghost/Story/Peregrination.g` as the canon):

- `Run_A_MusuStaple()` wires the Run (`H i A:MusuStaple/w:MusuStaple`); `MusuStaple(A,w)` installs
   the eternal `%req:wrangle` whose do_fn `Musu_drive` dispatches per **inner step** off
    `this.c.run.c.step_n` (tracked on `req.c.did_step`, immune to `on_step`'s H-global).
- **BOMB — the world is named after the Book.** The per-beat handler is dispatched by the WORLD
   NAME (`do_fn_for` reads `w.sc.w`, `Housing.svelte.ts`), so `w:MusuStaple → MusuStaple(A,w)`. Name
    the world anything else (`w:Musu`, …) and the handler silently never fires — nothing seeds the
     wrangle, the Book no-ops with no error. Each future Musu\* book lays its own `w:<Book>`. (The
      live `Peregrination.g` was mid-rename `w:Peers → w:PereStaple` during this session — re-read it
       before copying, host/runner edits land underfoot.)
- `Musu_witness(w)` polls every pass and stamps idempotent `%witnessed:<beat>` markers — the
   beat rides in the VALUE (`witnessed:filled`, not a key), since the snap reads them. The
    assertions are *structural state reads*, not bool polls: "the spool held at the window",
     "an ack let new chunks through", "the stock drained".
- `wormhole/Story/MusuStaple/toc.snap` carries one `step=N` line per inner beat — those lines
   DRIVE how many steps run. Lie diges until a real run with ACCEPT records them.
- `Musu_order(w)` floats `A:MusuStaple` to the front of `H/*` so the Run snap stays readable.

Headless — **the run AND accept loop is closed in node**, no `:9091` required for the Musu books.
 `scripts/CredRunner.spec.ts` is the harness: it mounts the runner shell, runs `Creduler_ensure` to
  load `CREDULER_GHOSTS` (so `Run_A_<Book>` + the spine come up live from the acquired gen), drives
   the Story, and piles the snaps — exactly like `Story_cli` but for Creduler-acquired Books. So:

```
BOOK=MusuStock node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/CredRunner.spec.ts
BOOK=MusuStock ACCEPT=1 …    # re-records wormhole/Story/MusuStock/*.snap + the toc diges, headless
```

`ACCEPT=1` writes the real fixtures (`NodeWormholeNav` passes `wormhole/` writes through to the repo
 only while recording; `gen/`+`Ghost/` writes sandbox to `/tmp`, so nothing else in the tree is
  touched). **The flow is: edit `.g` → `ghost-compile` each (writes the live gen `.go`) → `CredRunner`
   (acquires the fresh gen) → dry-run to eyeball the beats → `ACCEPT=1` to bake.** The diges no longer
    wait on a browser accept. (The browser `:9091` runner is still the path for the Cyto animation
     read — CredRunner is headless, no graph.) A plain `Story_cli` boot can't acquire the spine (no
      Creduler crank) and can't mount CodeMirror, so it's only a compile/parse gate, not a Musu runner.

### 6.1 The integration layer — real time, real audio, muted (`MusuSignal`)

The `Musu*` Books are deterministic *tick*-snaps: no clock, no signal, they witness the **cursor
 arithmetic** (§5 keeps the model clock-free and random-free on purpose). `scripts/MusuSignal.spec.ts`
  is the **orthogonal** layer — the question the snap Books can't ask: *does a real signal actually
   traverse the pipe?* It drives the **same acquired spine** (the `req_cast` spool feeding a
    `req_progress` decode-ahead chain off one shared `%inbox`) but:

- **real time** — the listener's `ack`/`playhead` advance on the **wall clock** (`Date.now()`), not a
   tick counter, so both spine reqs do *incremental* work over ~1–2 s of actual elapsed time; the
    window (7) and live-edge margin (3) breathe against a real clock.
- **real audio API** — a `%Chunk`'s PCM rides on `.c` (a `Float32Array` is an object → `.c`, never
   `.sc`), is `decodeAudioData`'d into a buffer, played through a `createBufferSource → gain → capture`
    graph — the exact surface `src/lib/p2p/ftp/Audio.svelte.ts` uses. (jsdom has no Web Audio, so the
     file stands in a faithful **muted offline** context; a `:9091` run swaps the platform `AudioContext`
      + an `AnalyserNode` tap in unchanged.)
- **muted** — the app's own mute: the capture replaces `AC.destination`, so it renders to a buffer and
   never to a device — `setupRecorder`'s `gainNode2.disconnect()  // don't hear it`.
- **measured, not snapped** — real time + real audio is non-deterministic, so the witness is **entropy**,
   not a byte-exact snap. Quantize the rendered PCM to int16 and assert the byte histogram clears a floor
    (Shannon `bits_per_byte > 4`, RMS, unique-bytes, longest-run). A **negative control** (same pipeline,
     payload zeroed) must collapse to ~0 entropy — that is what gives the gate teeth: a dropped payload,
      the "stream of `\x00`", *fails*. Observed: **7.62 bits/byte** signal vs **0** silence, 48/48 chunks.

The codec seam (Radios item 7 — opus/webm) stays out of scope: the payload is uncompressed PCM, so
 `decodeAudioData` is identity. What is exercised for real is the **wall clock**, the **audio graph**, and
  the **real compiled spine** — not the codec.

```
node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/MusuSignal.spec.ts
```

---

### 6.2 The Story-runner interface — request runs + examine, in a real browser (`runner_ask`)

`scripts/MusuSignal.spec.ts` is out of place: it stands the whole machine up in node (jsdom, **no Web
 Audio**) just to fake a muted offline context. The real home for a real-audio/real-time test is a
  **live browser runner** — and we already have the wire to drive one. The `become_book` channel
   (editor → runner over the `/relay` websocket) already makes a browser runner run a Book; what was
    missing was a way for **the CLI** (me) to drive + examine it, the way the headless runner let me read
     its file-writings. So: a small request/reply RPC over the *same* relay, the real-time twin of the
      headless CredRunner.

It is the exact mirror of `scripts/ghost_compile.ts` (the addr-less-CLI → editor round-trip), pointed at
 the **runner** instead:
- **`src/lib/server/relay.ts`** — additive. The corr-remembering that lets a browser's `…_ack` route
   back to an addr-less CLI now also catches `header.type==='runner_ask'`; a new `runner_ack` control
    verb routes the reply back by corr. Nothing else in the relay (`gen_write`/`become`/`ghost_compile`)
     changes. Proven node-side by **`scripts/runner-ask-test.ts`** (real relay + fake runner + fake CLI,
      6/6 green: corr round-trip, op dispatch, `undeliverable`, no crosstalk).
- **`src/lib/O/LiesLies.svelte`** — registers `on('runner_ask', …)` on the runner role.
- **`src/lib/O/LiesFunk.svelte`** — `Lies_runner_ask_recv(w, frame)` dispatches a fixed op set and
   replies `{control:'runner_ack',corr,…}` down the socket (the exact `Lies_ghost_compile_ack` idiom):
   - `ping` → `{role, channel, running}`
   - `run <Book>` → drives `Lies_become_book_drive` on the wall clock → `{accepted, book}`
   - `state` → `Cred_run_outcome()` (`{ok,ok_pct,done,caveat}`) + the `Storyrun` phase/n/total
   - `steps` → per-`Step` `{n, ok, caveat, dige}`
   - `snap <n>` → one `Step`'s `got_snap` (the live world serialisation — the "examine the writings" read)
   - `diff <n>` → `got_snap` + `exp_snap` (the diff-panel's expected, *if* already loaded — it is fetched
      lazily for the UI, Story.svelte:1470) + the `book`, so the explorer can diff live-vs-expected
- **`scripts/runner_ask.mjs`** — the one-shot sender. Addr-less, corr-settled (runner_ack / `undeliverable` /
   timeout), `--watch` polls `state` until the run settles done|failed, exit code carries the verdict.
- **`scripts/story_repl.mjs`** — the **readline explorer** (§16 "agent as test driver", pointed at the LIVE
   runner). One persistent socket, a `story›` prompt: `ping` / `run <Book> [--watch]` / `watch` / `state` /
    `steps` / `snap <n>` / `diff <n>` / `books` / `book <Book>`. `diff` is a colourised LCS line-diff of the
     live `got_snap` against the expected — the runner's `exp_snap` when the UI loaded it, else the
      shared-disk fixture `wormhole/Story/<Book>/<NNN>.snap` — with a `-del +add` surprise count. Line
       handling is serialised so a piped/scripted session runs in order.

```
node scripts/runner_ask.mjs run MusuLive --watch     # one-shot: kick + poll to verdict, real browser
node scripts/story_repl.mjs                           # interactive explorer
  story› run PortPlan --watch
  story› diff 2                                        # ⇒ "(identical — no surprise)"
  story› run MusuLive --watch
  story› diff 2                                        # ⇒ the self,round counter drift (stale bake), nothing else
RUNNER_URL=http://172.17.0.1:9091   # default; the runner dev server as seen from the claude container
```

**The diff over the socket EARNED ITS KEEP first use:** MusuLive runs red live, but `diff 2`/`diff 4` showed
 the *only* divergence is `self,round` off by a constant +6 (baked `8`/`10` vs live `2`/`4`) — every other
  line identical. That is the prep-tick-count shift from the `Run_A` cleanup (a stale bake / counter fuzz,
   §4.2), not a behavioural regression; EntropyArrest already forgives most of it (the `caveat` counts).
    UPDATE 2026-06-27: it was a CODE fix, not a rebake — the `self,round` spay re only matched the `=N` form,
     so whenever a step landed at round 1 (which `depeel` serialises as the BARE key `round`, value-1 → no
      `=N`) the graft's match-count check bailed and the drift survived as a hard `Dif:change`.  The re is now
       `\bround(?:=\d+)?\b` (whole-token, optional `=N`, no capture group → grafts capture-0), so the bare↔=N
        flip forgives too; no rebake needed.  NOTE: `got_snap` is fully over the socket; `exp_snap`
     currently rides the disk fixture (the runner only holds it once the UI panel loaded it) — making the
      expected travel over the socket too (drive the `fetch_snap` Wormhole read in the handler) is the §16.1
       "diff channels in the pile" follow-up.

**v1 is unsigned/trust-everything** (like `gen_write` when `CLUSTER_TRUSTED_PUBS` is unset): a run
 executes already-compiled gen, dev-only on localhost. Signing mirrors `ghost_compile` once the cluster
  flock deploys.

**The delivery path is not a new hop — it's the production `become_book` path.** The CLI's frame carries a
 foreign `from` (its own ephemeral addr, not `editor`), but that does not matter: the live runner's `w:Lies`
  is a **single-identity node** (one `Peering:runner`, one Ud-stamped `Pier:editor` — LiesLies.svelte:202-206),
   so `Peeroleum_route`'s **"ONE Peering / ONE Pier ⇒ use it"** short-circuit (Peeroleum.g:258,262) resolves a
    CLI frame to that sole Pier *regardless of its `from`* — the swarm-refactor short-circuit, already in the
     live gen, **no new `.go`**. The reliable relay carrier then books it straight (no inseq — Peeroleum.g:357),
      the Ud gate passes (the gate checks only `%Ud`, never `from` — Peeroleum.g:420), and it dispatches to
       `on('runner_ask')`. (Note: `ghost_compile` actually settles on its dige-**poll**, not this consumer
        hop — so it is *not* the proof here; the single-Peering short-circuit is.)

**Status:** relay + CLI proven green browserless; `Lies_runner_ask_recv` type-clean; the delivery path is the
 same one prod `become_book` rides. A `:9091` `runner_ask ping` (boot `?B=MusuStaple`) is the smoke test, not
  a risk-closer.

**Two follow-ons this unlocks (not yet built):**
1. **`H.SECONDS_IN_SECONDS`** — a time-scale constant so the real-time tests run at ~3× (audio shorter,
    `beliefs()`/ttlilt/heartbeat faster). It threads through load-bearing core (`now_in_seconds_with_ms`
     in `Peerily.svelte.ts`, the tick constants in `Housing.svelte.ts`, `Audio.svelte.ts` durations), so
      it gets **proved in isolation first** (app still boots, suite stays green) before anything leans on
       it — not bundled with this channel.
2. **Relocate `MusuSignal` into a real browser Story Book** — the entropy witness becomes a step the
    runner computes against a live `AudioContext`, surfaced through `runner_ask snap`/`state` instead of
     a `scripts/` vitest. That is what finally moves it out of `scripts/`.

---

## 7. Status & next move

**Slice 1 — DONE, ACCEPTED, green.**
- `Ghost/M/Radiola.g` — `Radiola_window`, `req_cast` (the spool with backpressure). Compiled →
   `src/lib/gen/M/Radiola.go`.
- `Ghost/Story/Musuation.g` — `Run_A_MusuStaple`, `MusuStaple`, `Musu_drive`, `Musu_sides_up`,
   `Musu_go_live`, `Musu_play`, `Musu_pump`, `Musu_witness`, `Musu_order`. Compiled →
    `src/lib/gen/Story/Musuation.go`.
- **Registered** in `CREDULER_GHOSTS` (`src/lib/O/LiesLies.svelte`): `'Ghost/M/Radiola.g'` +
   `'Ghost/Story/Musuation.g'`. **On the Credence board** beside `What:Pere`. Overlay
    `Waft:Ghost/Music/Ality` resolves.
- `wormhole/Story/MusuStaple/toc.snap` — real beat diges recorded, `TimeSpool` samples present.
   The four beats ran clean (link → fill-to-window hold@7 → slide-on-ack@10 → drain@12, all four
    `witnessed:` markers in order). Snap quirk noted: value-1 `seq` rides bare (`Chunk,seq`),
     decodes to `seq:1`.

**Slice 2 — DONE, ACCEPTED, green.** The preview→stream handoff, all inside the cluster + the one
 (already-present) Credence/overlay touch — no new `CREDULER_GHOSTS` line (the book is new methods in
  the already-enrolled `Musuation.g`). Both gen `.go` recompiled and HMR'd live; a 5-step run
   reproduced every beat below to the chunk — `previewed` HELD at the gate (window had room, preview
    withheld 4..6), `wanted`+`streamed` landed TOGETHER in beat 4 (pump order took), `streamdrained`
     at 12. **Baked headless via `BOOK=MusuStream ACCEPT=1 … CredRunner` — 5/5 exact** (`toc.snap`
      diges real, e.g. `step=5,dige:b697de52…`); `001..005.snap` recorded.
- `Ghost/M/Radiola.g` — `req_cast` grew an **opt-in** preview/stream gate (a `%Caster` with
   `.sc.preview` spools the free preview, withholds `kind:stream` chunks until `term.sc.want`); new
    `req_streamability` (the listener arms `%want:stream` when the un-played preview tail drops to
     the `want_left` floor). The gate is inert without `preview`, so slice 1's `req_cast` path is
      byte-identical (no `kind`, no `bump`).
- `Ghost/Story/Musuation.g` — Book `MusuStream` (`Run_A_MusuStream`, `MusuStream`,
   `MusuStream_drive`/`_sides_up`/`_go_live`/`_play`/`_pump`/`_witness`/`_order`). Own world
    `w:MusuStream`, own witness names (`linked`/`previewed`/`wanted`/`streamed`/`streamdrained`) — no
     overlap with the staple. `MusuStream_pump` pumps the **terminal first** (streamability decides),
      then the caster (the spool honours it) so the want→stream causality settles in one pass.
- `wormhole/Story/MusuStream/toc.snap` — 5 step lines, lie diges. `wormhole/Credence/toc.snap` —
   `Funkcion:Storying,of_Book:MusuStream` under `What:Musu`. `wormhole/Ghost/Music/Ality/toc.snap`
    — `What:the preview->stream handoff` + `What:the handoff test`.

**Slice 3 — DONE, ACCEPTED, green.** The radiostock fan-out (the first one-source→many-listeners
 picture), all inside the cluster + the one Credence/overlay touch — again no new `CREDULER_GHOSTS`
  line. Both gen `.go` recompiled (Radiola `@ 6754c58b…`, Musuation `@ 8436381a…`) and HMR'd live;
   parse-checked headless first, then **baked via `BOOK=MusuStock ACCEPT=1 … CredRunner` — 5/5 exact**
    (`toc.snap` diges real, e.g. `step=5,dige:be088b85…`); `001..005.snap` recorded.
- `Ghost/M/Radiola.g` — `Radiola_keep_ahead` (the KEEP_AHEAD=5 knob) + `req_restock`: rides a
   `%Stock` (finite `cap`-record source, `%Record` children seq 0..`made`-1), keeps `keep_ahead`
    records produced ahead of the LEADING `%cursor` consumer, capped by the source. Minting nothing
     once the lead is satisfied or `made===cap` IS the backpressure. Independent of the slice-1/2
      caster path (its own mainkeys), so those accepted snaps are untouched.
- `Ghost/Story/Musuation.g` — Book `MusuStock` (`Run_A_MusuStock`, `MusuStock`, `MusuStock_drive`/
   `_sides_up`/`_go_live`/`_serve`/`_drain`/`_advance`/`_pump`/`_witness`/`_order`). Own world
    `w:MusuStock`, own witness names (`stocked`/`primed`/`served`/`sourced`). One `%Stock` (12-record
     source) with two `%cursor` children (`fast`/`slow`) — the consumers,of=radiostock fan-out.
- `wormhole/Story/MusuStock/toc.snap` (+ `001..005.snap`) — baked. `wormhole/Credence/toc.snap` —
   `Funkcion:Storying,of_Book:MusuStock` under `What:Musu`. `wormhole/Ghost/Music/Ality/toc.snap` —
    `What:the radiostock fan-out` + `What:the fan-out test`.

**The slice-3 beats — VERIFIED+ACCEPTED by run (2026-06-25)** (`cap=12`, `keep_ahead=5`, two cursors):
- beat 2 — **stocked**: `%Stock` (made=0, not live) + two `%cursor` (fast/slow at 0) + `%req:restock`
   stand up; nothing produced → `witnessed:stocked`.
- beat 3 — **primed**: stock goes live → restock fills the buffer to `keep_ahead` (made 0→5, Records
   0..4) and HOLDS, both cursors still at 0 → `witnessed:primed`.
- beat 4 — **served**: fast plays 3 (at 0→3) → restock tops up to stay 5 ahead of the LEADER (made
   5→8) while slow still sits at 0 (`lag < lead` proves it tracks the fastest) → `witnessed:served`.
- beat 5 — **sourced**: fast plays out (at 3→12=cap), slow plays 6 → restock runs the stock to the
   cap (made 8→12) and can make no more — the finite-source backpressure — while slow still trails at
    6 with records 6..11 in hand → `witnessed:sourced`.

If a beat mismatches: restock keys off the **leading** (highest) cursor, not the lagging one — if
 `served` doesn't fire (or `made` tracks the slow cursor), the lead/lag pick in `req_restock` /
  `MusuStock_witness` is inverted. `made===cap` with a cursor short of cap is the intended endpoint
   (source spent, listener still draining), not a bug.

**All six instances 1–6 are now spine + Book + accepted.** `Radios.svelte` items 7–8 (codec
 segmentation, disk cache) stay out of scope — the irreducibly-real bytes/disk seam (§3).

**Integration layer — real time + real audio + entropy, MUTED — DONE, green** (§6.1).
 `scripts/MusuSignal.spec.ts` acquires the spine like CredRunner, then drives `req_cast`→`req_progress`
  on the wall clock with REAL PCM on `.c` through a muted audio graph, and asserts the rendered signal's
   entropy (7.62 bits/byte) against a silent negative control (0). One new file, nothing else touched —
    the spine + Books are untouched (the snap fixtures are unaffected). It needs no `:9091` and no
     `ACCEPT` (it measures entropy, it does not bake a snap).

**Story-runner interface — request runs + examine a LIVE browser runner — DONE browserless, owes a
 `:9091` verify** (§6.2). `runner_ask`/`runner_ack` corr-routed over the existing `/relay`, mirroring
  `ghost_compile`: `scripts/runner_ask.mjs <ping|run <Book>|state|steps|snap n>` drives a real-browser
   runner and reads its live verdict/snap. Additive relay change proven green by `scripts/runner-ask-test.ts`
    (6/6); the CLI proven end-to-end against a node relay; `Lies_runner_ask_recv` (LiesFunk) +
     `on('runner_ask')` (LiesLies) type-clean. This is the seam the two follow-ons in §6.2 hang off
      (`H.SECONDS_IN_SECONDS` 3× time-scale, prove-in-isolation; and relocating `MusuSignal` into a
       browser Story Book read through `runner_ask`).

**The next move:**
1. Watch the machine in Cyto on `:9091` (the headless CredRunner has no graph): the spool window
    breathing, the preview gate holding then surging, the `%Stock` fan-out, the `%aud` **chain**
     decode-ahead hugging the live edge, records going `%wore_out`, the skip rewinding the chain — all
      `.bump()`-fed so the wave rides each move.
2. Verify the `Waft:Ality` map + the substrate bridges on `:9091` (§8 — owed a browser pass: the
    `Point,text:` click-through, the bridge lighting the same token across all three Docs).
3. Beyond the slices: a live bridge auto-minter (§8), spaced-phrase Points, or fold a real source file
    into a sim if a 7–8 behaviour ever wants watching.

---

## 8. The presentation map — `Waft:Ality` + substrate bridges

`wormhole/Ghost/Music/Ality/toc.snap` is now a *navigable map of the whole machine* — open it in the
 editor and every piece is a `What` you can jump into:

- **the machine** — slices 1–6, each `What` Pointing at its spine method(s) in `Ghost/M/Radiola.g`
   (`req_cast`/`req_streamability`/`req_restock`/`req_progress`/`req_reap`/`Radiola_skip` + the knobs).
- **the tests** — the three `Musu*` Books (`MusuStaple`/`MusuStream`/`MusuStock`), each Pointing at its
   `_drive`/`_witness`.
- **the source it reimagines** — `src/lib/ghost/Radios.svelte`, Pointed at the original functions
   (`listening`/`progress`/`enqueue`/`raterminal_recordWear`/`turn_knob`).
- **the spec** — this file.
- **bridges** — the new part (below).

**Fine-grained text Points bridge the substrates.** A new Point kind, `Point,text:<str>`, resolves to
 a literal occurrence in the Doc itself (a word or phrase) rather than a named def/region. Mechanism:
 `Lang_resolve_point` (`LangRegions.svelte`) grew a `text:` branch — word-boundary exact, then
  substring, then loose case-insensitive — needing only `state.doc`, so it resolves even before a
   compile; `Lang_point_spec` (+ the two inline twins in `Lang.svelte`/`LangHold.svelte`) carry a
    `sc.text` as a `"text:"`-prefixed spec. (Headless-verified: `keep_ahead`/`want` (word-boundary,
     not inside `wanted`)/`STAY_AHEAD_OF_ACK_SEQ` resolve, a miss returns null. Browser click-through
      on `:9091` still owed.)

Because the SAME `text:` string lands on its own occurrence in each Doc, a `What:bridges` entry puts
 one shared token across two or three substrates at once — the editor lights it up in each. The tokens
  were *discovered in common* (a token-intersection over the three Docs), so they're real overlaps:

| bridge token | spec | `Radiola.g` (new) | `Radios.svelte` (old) |
|---|---|---|---|
| `STAY_AHEAD_OF_ACK_SEQ` | ✓ | ✓ (comment) | ✓ (the const) |
| `KEEP_AHEAD` → `keep_ahead` | ✓ | `keep_ahead` | `KEEP_AHEAD` |
| `MIN_LEFT_TO_WANT_STREAMING` → `want_left` | ✓ | `want_left` | the const |
| `streamability` → `req_streamability` | ✓ | ✓ | ✓ |
| `radiostock` | ✓ | ✓ | ✓ |
| `preview` → `radiopreview` | ✓ | ✓ | old name |
| `playhead` | ✓ | ✓ | ✓ |
| `not_too_far_ahead` | ✓ | — | ✓ |

The rename rows (`KEEP_AHEAD`→`keep_ahead`, `preview`→`radiopreview`) are the most telling: the bridge
 shows the SAME idea wearing different names across the substrates, which a name-only Point can't.
  Next layer: spaced phrases (the snap value needs quoting/escaping — single tokens are robust today)
   and an in-app *auto-discovery* that mints bridge Points from a live two-Doc token-intersection
    (done here at author-time by a script; the live minter is the follow-up).

---

## 9. Pier reality — taking Repli from the loopback to the world

The replication protocol is real (Repli_* + the Se, §6/MusuReplica — live-green 2026-07-03), but its
 world is a demo: two Piers in one w, three synthetic Records, a beat-loop pull. This section is the
  idea set for making Piers REAL — each idea grows from a seam that already exists, named so a session
   can pick one up and go. The oldest statement of the destination sits at the top of
    `src/lib/mostly/Selection.svelte.ts` ("Selections are then sendable to particular Piers. So it
     mostly moves whole folders... replicate the meaningful folder structure above the selected
      stuff") — written before the Se existed; now the %Sent_Tree IS a Selection, so the sentence can
       finally mean something executable.

**9.1 The real library.** A's `%Library` today is `Musu_synth` output; reality is the `/music` mount
 (read-only) arriving through the FSA share gate (`H.c.disk_gated` + `open_dir` — the granted-share
  path, since ?E=/?B= boots forbid the OPFS shadow disk). A walk mints `%Record`s from files (id =
   path-hash, title/artist off tags or path parts) with `%Stream` handles that decode lazily —
    `MusuReco` (via `Crate_transcode_*`) already fetch+decodes real audio, so the decode seam exists; what's new is the
     LIBRARY as a Se over a folder tree ("hierarchise FileLists"), whose neus|goners are files
      appearing|vanishing on disk. The same `repli_on_neu` hook then offers REAL music with zero new
       protocol.

**9.2 Selections sendable to Piers.** The share unit is not the library, it's a SELECTION of it — a
 genre, an artist folder, an occasion. Concretely: a `%Share,label:<name>` particle holding a match
  (what subset) and a to (which Pier|channel), whose own Se runs over just that subset — its neus
   offer, its goners retire (unshare without delete: the record leaves the SELECTION, not the
    library). `Repli_lines_of` already recurses a subtree, so the meaningful folder structure above
     the selected stuff replicates for free — the mirror sees `genre/artist/album/track`, not a flat
      pile.

**9.3 The pull rides the playhead.** MusuReplica pulls on a beat loop; a real listener pulls because
 they are LISTENING. Radiola already has the exact shape — `req_streamability` arms `%want:stream`
  when the un-played tail drops to the `want_left` floor — so the want-cursor should key off the
   playhead + keep_ahead, making replication rate = listening rate (the anti-hoard: you fetch what
    you play, plus a safe margin — the same live-edge margin MusuEdge holds).

**9.4 Catalog gossip over multicast.** Offers today are unicast `to:'Crowd'`; the relay already fans
 out `to:@channel` topics (Peeroleum multicast, PereProof step 29). An offer published once to
  `@<cluster>` reaches every subscriber; a Pier arriving late gets the current catalog as its
   subscribe baseline and live neus after — the Se's noticing becomes the cluster's noticing.

**9.5 A %Sent_Tree per peer — the availability map.** In the demo, one tree per side. In a swarm, A
 keeps a tree PER KNOWN PEER (`Sent_Tree,pier:<pub>`): "how much of each Record is where" becomes the
  routing table. `Mesh_route` (cheapest-route, MusuMesh) can then answer "who do I want page N from"
   — multi-source pulls, different pages from different holders, the torrent shape grown from parts
    we already run.

**9.6 Wear makes the mirror a cache.** MusuWear reaps worn records; applied to a mirror, `got`
 REGRESSES when pages are reaped — and the Se's pairing already carries continuity (bD), so a
  regression is visible history, not a fresh unknown. Replication stops meaning "copy forever" and
   starts meaning "lease-shaped cache": re-pullable, wearable, honest about what is actually held.

**9.7 The Keep gates what enters.** Repli verifies bytes (sha256 per frame) but not INTENT. The
 cluster-trust layer (signed frames, the cluster Idento) says who a Pier IS; the Keep (attention ×
  crypto × acceptance) decides what it ACCEPTS: a mirror is quarantine until kept. Swarm.g already
   mints|verifies grants — a `want` without a grant for that Share is refused; an offer is an
    invitation, not an obligation. This is where music-sharing stops being promiscuous replication
     and becomes consent all the way down.

**9.8 The tree is the resume.** A reconnecting Pier must not re-pull from zero. The %Sent_Tree
 persists (it is C**, it can snap — dontSnap is per-fixture hygiene, not a persistence ban), so
  `want from:have` resumes where the wire broke — the same baseline-adoption shape that fixed the
   inseq reload. The D** with continuity IS the cursor state; no separate bookkeeping to invent.

**9.9 Retire as a first-class social act.** op:delete crossing the wire (MusuReplica beat 13) means
 a shared thing can be WITHDRAWN — mistakes, rights, dedup, moderation. Generalised: a goner in a
  Share retires at subscribers of that Share only; a goner in the library retires everywhere. The
   un-replication path is tested and symmetric with the offer — keep it that way as the semantics
    grow.

**9.10 The audio-proof cherry.** Deferred from MusuReplica deliberately: B PLAYS its replicated
 copy on its own (muted, tapped) context — MusuBounce already runs two contexts. The first full
  end-to-end: a real file picked on A (9.1), offered through a Share (9.2), pulled at listening rate
   (9.3), heard at B. That demo IS the app; everything above it is how it stays honest at swarm
    scale.

The order that suggests itself: 9.1 (real library) → 9.10's spine (offer→pull→play with one real
 file) → 9.2 (Shares) → 9.4 (multicast) → then 9.5–9.8 as the swarm grows peers. 9.7 (Keep) tracks
  `spec/Backbone_plan.md` — don't fork its design here.

## 10. Klepto mode — the heist points at a Pier

Today the unit of want is a Record: offer → want → pages, pulled at listening rate (9.3). **Klepto
 inverts the aim: point the heist at the Pier itself** — "everything you have" — and the mirror is
  the destination. The catalog is already the offer set (9.4's subscribe baseline); klepto walks it
   and pulls at HEIST rate — what the wire and disk afford, not the playhead — `Repli_want_next`
    grown a second gear. `Repli_mirror_lib` is the seed; mirror-everything is its grown-up form.

**Many kleptos, one read.** A Pier heisted by N must not do N disk sweeps. The host serves the heist
 as a BROADCAST: one sequential sweep of the library, each page read ONCE and published to a heist
  `@channel` (`Peeroleum_offer_stream` — the established 1:1 Pier hands each arriving klepto the
   stream pointer; bulk rides multicast, spec §18). Everyone present rides the same bow wave — the
    shape MusuReco already proves (stream off the transcoder's bow wave) — and a latecomer tunes in
     live, then backfills the pages it missed with ordinary 1:1 wants (the per-peer %Sent_Tree, 9.5,
      knows exactly which). The host is a radio station whose playlist is "my library, in order"; a
       klepto is a tuner with a backfill cursor. Disk IO is O(library), not O(library × N).

**The cafe tree.** Kleptos co-located on a LAN (the coffeeshop) should cost the WAN one copy: the
 source sends into the LAN once; the receiver relays to two, who relay to two. `Mesh_broadcast_stretch`
  IS this tree (minimum-cost broadcast rooted at the source) and `Mesh_cafe_spec` is the canonical
   scenario, already written — the missing rung is DETECTION: how do Piers learn they're co-located?
    The honest first answer is the relay's-eye view — two Piers behind the same public IP share a NAT,
     and the relay already sees every address; it stamps same-origin groups. (Finer, later: RTT
      clustering — sub-5ms neighbours; ICE local candidates are mDNS-obfuscated and need a real
       probe.) Same-origin → cheap LAN edges in the Mesh graph → stretch computes the tree → pages
        route down it.

**Klepto is not exempt from consent.** The heist takes everything OFFERED, not everything held —
 grants (9.7) bound the catalog a klepto even sees, and wear (9.6) makes the mirror a cache, not a
  hoard. The name is cheeky; the Keep still gates.

**The rungs, in order:**

1. **Heist v1, loopback** — a Book: point the heist at the DJ Pier, mirror everything at heist rate,
    assert the whole-library mirror byte-faithful (`body_hash` per Record). Extends MusuReplica's
     world; no new wire.
2. **The cohort** — 2+ kleptos on one host: one page-stream on a heist @channel; assert the host
    emitted each page ONCE while every mirror completes. This is the rung that finally forces the
     wire real (§10.1): the first Book whose claim is ABOUT shared delivery, so a by-reference mock
      flatters it — run it over 2+ real runners with real Piers (brief §6's milestone).
3. **The cafe** — same-public-IP detection at the relay + stretch routing; assert the WAN edge
    carried one copy while every LAN klepto completes.

### 10.1 How real is the wire today (honest ledger)

The PROTOCOL is real — frames, seq, inseq/retransmit, sha256 `body_hash` per page, paging,
 park/serve, op:delete — the same verbs the product will run. The WIRE under the Books is not:
  `Lake_link` pairs two in-process ports (`porta.partner = portb`) and the mock carries
   `frame.buffer` BY REFERENCE — no serialization, no real loss (adversaries INJECT loss:
    whittle/perturb), no congestion, no NAT. Peeroleum's own comments name the deferred seam:
     serialization is "the carrier's job — `Socket_real/relay`". Meanwhile the machinery itself
      (dispatch, r2r, gen_write) DOES run the real `/relay` websocket all day — real reconnects,
       real seq gaps (the inseq baseline bug was real networking pain). So: real protocol, tame
        wire; the WebRTC datachannel path the streaming app uses is untested by any Book. Rung 2
         above is the designated forcing function.
