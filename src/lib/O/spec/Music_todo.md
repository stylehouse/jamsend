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
   compile; `Lang_point_spec` (+ the two inline twins in `Lang.svelte`/`LiesHold.svelte`) carry a
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
