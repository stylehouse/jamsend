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
   beats 2–5 (link → fill-to-window → slide-on-ack → drain). **Status: authored, uncompiled
    (§7).** This is the heartbeat; everything else spools on top of it.
- **Slice 2 — preview→stream handoff.** Add `%Chunk,kind`, the `streamability` arm, the
   `%want:stream` request. New `Musu*` beats; first real animation target (the preview bar
    draining, the request firing, the continuation joining).
- **Slice 3 — radiostock cursor / multi-listener fan-out.** Two terminals, one stock, per-
   client cursors, refill pressure. The fan-out is the first genuinely graph-shaped picture.
- **Slice 4+** — live-edge decode-ahead, wear/GC, skip-track — as appetite holds.

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

Headless: `Story_cli` can boot the machine in node (vitest+jsdom) but cannot mount CodeMirror,
 so a Musu book that needs no editor runs there; the browser runner on `:9091` is the full
  path. (Mirror `scripts/Story_cli.spec.ts` if a headless Musu harness is wanted.)

---

## 7. Status & next move

**Done — slice 1 is wired into the machine:**
- `Ghost/M/Radiola.g` — `Radiola_window`, `req_cast` (the spool with backpressure). Compiled →
   `src/lib/gen/M/Radiola.go`.
- `Ghost/Story/Musuation.g` — `Run_A_MusuStaple`, `MusuStaple`, `Musu_drive`, `Musu_sides_up`,
   `Musu_go_live`, `Musu_play`, `Musu_pump`, `Musu_witness`, `Musu_order`. Compiled →
    `src/lib/gen/Story/Musuation.go`.
- **Registered** in `CREDULER_GHOSTS` (`src/lib/O/LiesLies.svelte`): `'Ghost/M/Radiola.g'` +
   `'Ghost/Story/Musuation.g'` — the runner acquires them live like the Pere\* cluster.
- **On the Credence board** (`wormhole/Credence/toc.snap`): a `What:Musu` group with
   `Funkcion:Storying,of_Book:MusuStaple`, beside `What:Pere`.
- `wormhole/Ghost/Music/Ality/toc.snap` — overlay skeleton.
- `wormhole/Story/MusuStaple/toc.snap` — has run (TimeSpool samples present); step diges still
   lie placeholders.

**The next move:**
1. Become `MusuStaple` and **accept the snaps** — the step diges are still lies
    (`0000000000000001…`); accepting records the real beat diges and turns the Credence cell green.
2. Watch the four beats hold (below). If a beat mismatches, the witness or the spool wiring is
    off — the `%req:cast` pump (`caster.do()` reaching the child req) is the first suspect.
3. Open `Waft:Ghost/Music/Ality` to confirm the overlay resolves and navigates the cluster.
4. Then slice 2 (preview→stream) — §4.

**The beat to verify (slice 1):** with `total=12`, `window=7` —
 beat 2 link up; beat 3 caster goes live → spools seq 0..6 and **HOLDS** (5 chunks withheld
  though they exist) → `witnessed:filled`; beat 4 terminal plays 3 (ack→2) → window slides,
   7..9 delivered → `witnessed:slid`; beat 5 terminal drains (ack→11) → 10..11 delivered,
    `next===total` → `witnessed:drained`. If the hold at beat 3 doesn't happen, the spool isn't
     reading the ack/window — that's the bomb to look at first.
