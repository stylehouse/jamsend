# Radiobuddies — the regroup handover

A continuation brief, not a changelog. The destination, the one bomb that ruins it if the next
 fork lacks it, and the next move. Written 2026-07-05 against the live tree; correct anything drifted.

Companions: `Radio_todo.md` (the M-cluster living doc), `Radio_spec.md` (the 9 platform stages),
 `Swarm_spec.md` / `Cluster_spec.md` (identity + coordination). This doc sits *above* all of them —
  it is about the seam between the product and the test machine, which no single one of them owns.

---

## 0 — The name

The system has never had a name. The triad in the memory is `Cluster` (how runs coordinate) /
 `Radio` (streams) / `Swarm` (who's on), and the whole — **run a music node, share by identity** —
  was the un-named shebang. The owner keeps calling it **Radiobuddies**, so that is the word we
   believe in now. Working name, rename-freely (as `Radiola` was), but a named thing can be a
    *destination*; an un-named one stays a pile of Books. Naming it is the first act of the regroup.

---

## 1 — Destination

**Radiobuddies must exist and run with `Ghost/Story/*` deleted.** That is the whole test. Story
 ghosts are *test simulation helpers* — scenarios that stand up a world, drive it beat by beat, and
  witness it. They are scaffolding. Today the scaffolding is load-bearing: real product software
   lives *inside* it and the product would not boot without the test file. That is the inversion to
    correct.

Concretely, `Ghost/Story/Musuation.g` (3812 lines) contains two slabs its own comments mark as
 **real, shared, not-scaffolding** software:

- `//#region reality` (L28–299) — the **audio engine**: `Musu_synth` / `Musu_silence` /
   `Musu_radiostock` / `Musu_stock_chunk` / `Musu_synth_tone` / `Musu_synth_records` /
    `Musu_measure` / `Musu_gat` / `Musu_real_stream` / `Musu_float`. Synth PCM, the measure/entropy
     readout, and the rate-driven live-stream pump that actually starves. The header says it plainly:
      *"shared, real software; NO test scaffolding here, NO per-Book scenario."*
- `//#region repli` (L2839–3266) — the **paginated streaming C\*\* replication protocol**
   (`Repli_*`, `%Sent_Tree` / `%Crush_Tree`, `%emit` / `%unemit`, `body_hash`). Header: *"shared
    real software, first user below"* — the first user being the `MusuReplica` / `MusuReco` Books
     further down the same file.

The destination is: **those two slabs in family homes, `Musuation.g` reduced to pure scenarios, and
 the spine composable into the real app without loading a single Book.** The precedent already
  happened once and proves it works — `Voro_crush_scan` / `_walk` / `_crushable` moved *out* of
   `Musuation.g` into `Ghost/V/Voro.g` (Radio_spec §8), and the Books that use it now call it
    cross-ghost. We are finishing that same migration for the two slabs that are still trapped.

---

## 2 — The bomb

**Nothing at runtime forces this split, so if you don't do it deliberately it never happens.**
 Methods mix onto `H` regardless of which `.g` file they were authored in — so a `Musu_synth` that
  lives in a Story ghost runs *exactly as well* as one in `Ghost/M/`. The tangle is invisible while
   the machine is green. That is the trap: the only thing wrong is *coherence*, and coherence never
    shows up in a red run. The file boundary must be dragged to match the boundary the comments
     already drew, by hand, on purpose.

Two mechanical bombs guard the move (both from `Radio_todo.md §2`, both real):

- **gen `.go` before enrollment.** `Creduler_ensure` loads each `CREDULER_GHOSTS` entry's *compiled*
   `.go` and waits on `%Creduler_pending` until every `Ghostmeta_*` reports live. **A gen `.go` that
    does not yet exist hangs the runner boot.** So a new `Ghost/M/Sound.g` must be ghost-compiled
     (browser editor on `:9091`, `npm run ghost-compile -- Ghost/M/Sound.g` — there is no headless
      `.g→.go` for enrollment; `LocalGen` writes the byte for byte gen but the *enrollment* still
       wants the live HMR) **before** its `CREDULER_GHOSTS` line is added.
- **world-name dispatch is ghost-agnostic, but verb calls are by name.** A Book's per-beat handler is
   dispatched by `w.sc.w` (world name = Book name), so which file the handler lives in does not
    matter — Voro proved a `VoroMitosis(A,w)` in `Voro.g` just runs. **But** the reality/repli verbs
     are *called* by name across ghosts (`this.Musu_synth`, `this.Repli_emit`). They mix onto `H`, so
      the call resolves — *only if both ghosts are enrolled and compiled*. Move a verb, forget to
       enroll its new home, and the caller silently hits `undefined` at run time, not compile time.

Corollary for how to touch it: this is a **prove-in-isolation** change (`fight-back-on-core-changes`).
 Extract one slab, gen-compile it, enroll it, re-point callers, **re-run the affected Books on a LIVE
  `:9091` runner via `runner_ask.mjs`** — never headless, never all-at-once. The audio slab and the
   repli slab are two separate, independently-reversible moves.

---

## 3 — The words to believe in

The regroup is mostly a *renaming*, and the rename carries the whole design. The rule:

> **`Musu_` is the scenario prefix — it stays in `Ghost/Story/`.** A real verb loses `Musu_` and
>  takes its **family** prefix. `%witnessed` / `%see` are scenario vocabulary; they do not follow the
>   verb into the spine.

The families — the nouns the product is built from, each a home:

| family | home | the words (mainkeys / verbs) | what it is |
|---|---|---|---|
| **Sound** | `Ghost/M/Sound.g` *(new — from `//#region reality`)* | `%Caster %Terminal %Chunk %cursor %Stock %Record`; `Sound_synth` `Sound_measure` `Sound_radiostock` `Sound_stream` | the audio engine: synth PCM, measure/entropy, the starving stream pump |
| **Radio** | `Ghost/M/Radiola.g` *(exists)* | `req_cast` `req_streamability` `req_restock` + the window/keep-ahead knobs | the node that streams — the cursor/backpressure spine |
| **Crate** | `Ghost/M/Crate.g` *(exists)* | `%Crate %dir %blob %record`; the FSA walk → radiostock override | the real collection source |
| **Mixer** | `Ghost/M/Mixer.g` *(exists)* | `%Cell`; `Mix_tempo` `Mix_beatmatch` `Mix_render` `Mix_crossfade` | live-voice mixing, beatmatch (real algorithms) |
| **Mesh** | `Ghost/M/Mesh.g` *(exists)* | `%edge` (peer/relay, cost); Dijkstra + min-cost broadcast tree | routing content along cheap edges, multicast stretch |
| **Repli** | `Ghost/N/Repli.g` *(new — from `//#region repli`)* | `Repli_*`; `%Sent_Tree %Crush_Tree %emit %unemit`; `body_hash` | generic paginated C\*\* replication over the wire |
| **Pier** | `Ghost/N/Peeroleum.g` `Reliable.g` *(exist)* | `%Pier %Peering`; frames, inseq/retx | the transport — the synapse |
| **Swarm** | `Ghost/S/Swarm.g` *(exists)* | `%Peer %Share`; prepub, `${pub}_N` blocks | who's on, and who shares what — *by identity* |
| **Cluster** | (Keeping — `Keeping_spec.md`) | `%Keep`; claim / lease / accept | how runs coordinate: attention × crypto × acceptance |
| **Voro** | `Ghost/V/Voro.g` *(exists)* | `Voro_crush_scan`; `c.stuff` / `c.stuffy` | the stained-glass view fold (the migration precedent) |

Open call on **Repli's home**: it is a *generic* C\*\* protocol whose first user is music, so it could
 live in its own family. It rides *on* the transport (Peeroleum/Reliable) and shares their concerns,
  so `Ghost/N/` beside them is the coherent first cut — but if a second, non-music user appears,
   promote it to `Ghost/R/Repli.g` (its own family). Named `Repli_` either way.

---

## 4 — The arena of invention — how to draw it up

Three layers. Ideas enter at the top and *graduate* down; the product is the bottom.

- **Layer 2 — the scenario (a Book).** Where an idea is born, because it is the cheapest place:
   `Story_subHouse` stands up a world, a `%req:wrangle` drives beats, a witness asserts each one, and
    Cyto draws it for free. One Book proves **one rung**. This is `Ghost/Story/Musuation.g` and its
     siblings. Cheap, watchable, disposable.
- **Layer 1 — the spine (a family ghost).** When a rung is proven, its *mechanism* graduates into
   `Ghost/M|N|S|V/*` as pure verbs — no `%req` self-install, no scenario, no `%witnessed`. The Book
    stays behind as the regression witness and now *composes the spine from outside*. This is the
     `Musu_ → family_` rename of §3.
- **Layer 0 — the product (the app).** `BigSoundland` / `Sounditron` (Radio_spec §8) assembles the
   graduated spine into the real thing, driven by real audio + real identity + real network, **with
    no Book loaded at all.** This is where the "trivial Books" converge — *not* by merging twenty
     Books into one mega-Book, but by the app composing what each Book proved. The Books remain the
      per-rung tests; the app is the ladder climbed.

**This is the answer to "bring it all into a cohesive whole."** The whole is not a bigger Book. The
 whole is Layer 0 — the app that stands on the spine. The Books stay small and many *on purpose* (one
  falsifiable claim each); cohesion lives one layer down, in the spine they all call, and one layer
   up, in the app that assembles it. Consolidation = (a) graduate proven mechanisms out of Story, (b)
    retire the redundant probes (`musu-test-consolidation`: MusuCrate already deleted, MusuSignal was
     theatre, many Musu\* are retirable scaffolding once one real integration Book covers the aspect),
      (c) keep the mature integration Books as the live gate.

---

## 5 — The next move (the regroup itself, ordered, each isolated)

1. **Sound.** Cut `//#region reality` → `Ghost/M/Sound.g`; rename `Musu_synth`→`Sound_synth` etc.;
    ghost-compile on `:9091`; add the `CREDULER_GHOSTS` line; re-point every `this.Musu_synth` caller
     in `Musuation.g` (and `Mixer.g`, which reuses the synth-with-a-beat); **re-run the real-audio
      Books live** (MusuSignal/Glide/Tune/Radio/Mix/Edge/Pier). Reversible; do it alone.
2. **Repli.** Cut `//#region repli` → `Ghost/N/Repli.g` (see §3 open call); same compile→enroll→
    re-point dance; **re-run MusuReco + MusuReplica live** — these are the integrity/paging Books, so
     watch the `body_hash` gate specifically (it is the correctness contract, per the last session's
      MusuReco diff — the recent-ring *view* slimmed, but the hash is still stamped and verified;
       don't let the move drop the verification).
3. **Reduce.** `Musuation.g` is now pure scenarios. Retire the redundant probes; leave the mature
    integration Books. Register `Sound.g` + `Repli.g` on the Credence board (`Funkcion:Storying` is
     for Books — these are *spine*, so they belong under the `Waft:Ghost/Music/Ality` overlay map, not
      Credence's Book list) and Point the Ality map at their verbs.

Each step is one commit-point. None of them makes anything *new* work — they make the file boundary
 honest. Do not batch them; the whole value is that a red run after step 1 blames step 1.

---

## 6 — What next, besides the code-file regroup

The regroup is bookkeeping — it is the *precondition* for the real work, not the work. "The entire
 Radiobuddies system exists functionally" is not a file layout; it is the **live end-to-end** that no
  Book can prove because it needs real plumbing (Radio_spec §7):

- **Audio actually plays across the wire.** Reconstruct the listener's received `%audiochunk` bytes
   into PCM and feed the Player/Glide — closes *"the synapse carries music,"* not just bytes. The
    single most product-defining missing rung.
- **Two real runners, real Pier, real multicast.** `@channel` fan-out (Stretch/Mesh) needs 2+ live
   runners; the routing/cost model is already the spec for it. This is the "cafe end to end" MVP.
- **Share by identity — the half with the least code.** `Swarm.g` has the `${pub}_N` blocks but
   **no friend-facing discovery** (`radiobuddies-shebang-unnamed`): "who is online and what are they
    sharing" is the *social* product and barely exists. Cluster/Keep (claim/lease/accept) is the
     coordination substrate under it (`Cluster_spec.md §2-7`).
- **Real collection, off the static symlink.** Wormhole `bin_read` / a real library / proper tags
   feeding the radiostock override, replacing `testsounds/`.
- **Sounditron** — the app becomes a live diagnostic probe ("is a track playing? are my people
   online?"), a real gather in place of the seeded Book, turning the user into a reporting test-probe
    (Radio_spec §8). This is where Layer 0 and the identity side meet.

Order them by "does the product exist for a stranger": audio-plays-across-the-wire and
 share-by-identity-discovery are the two that make Radiobuddies a thing a second person can use. The
  regroup clears the desk so those two have a clean spine to stand on.
