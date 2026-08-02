---
name: story-block-step-precondition
description: real-music Books gate on a testsounds collection via a needAC-style PRE-RUN check (needMusic tag → Lies_secure_collection refuses to begin) with three EXACT reasons (no_share|stalled|no_directory)
metadata: 
  node_type: memory
  type: project
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

**Final architecture 2026-07-05 (owner: "be great to know this is like the needAC thing! it checks BEFORE the
 test — that's the proper way, since it takes a while").** A real-music Book must have its testsounds collection
  on disk. Modeled EXACTLY on `needAC`, as a PRE-RUN gate, NOT a per-beat in-Book gate:

- **Tag:** `Funkcion:Storying,of_Book:<book>,needMusic:1` on the Credence board (wormhole/Credence/toc.snap) —
   the needMusic twin of `needAC:1`. On MusuCrate / MusuReco / MusuBounce. NOT MusuGenerateTestsMusic (it MAKES
    the collection) or MusuReplica (synth PCM).
- **Read:** `Lies_book_needmusic(w, book)` (LiesFunk) walks the loaded Credence Wafts for the tag — a copy of
   `Lies_book_needac`.
- **Gate:** `Lies_become_book_drive` (the runner's run front-door), right after the needAC gate, calls
   `Lies_secure_collection(w, book, 'testsounds', 1)`; if `!ok`, `Lies_runner_phase(w,'collection_blocked')` +
    an Upkeep errand + tlog, and RETURNS before `Lies_runner_begin` — nothing tried, "couldn't run here", never
     a failure (mirrors the audio_blocked path). The walk is BOUNDED (Promise.race vs 8s) — a stalled remote
      atime_async nav never sits in a step clock.
- **THREE EXACT reasons (owner wanted them un-merged):** `no_share` (no nav/share), `stalled` (walk timed out —
   remote proxy not answering), `no_directory` (walk answered but < need tracks → run the generator).

**Supersedes the earlier in-Book gate** (Musu_require_collection / Musu_block / Musu_walk_bounded /
 Musu_collection_gate + a snapped need_generate marker) — ALL REMOVED; the 3 Books' setups reverted to original.
  That approach worked (snapped marker verified live) but the off-snap `step_blocked→untried` never landed from a
   plain drive set (needs a ttlilt-held snap like Story_demand_audio), and per-beat is the wrong shape anyway.

**LIVE STATUS — :9091-UNVERIFIED, needs a runner RELOAD to activate** (exactly like needAC/bin_write): the gate
 adds NEW House methods (Lies_secure_collection/Lies_book_needmusic) which do NOT reliably re-mix into an
  already-booted runner mid-session [[remotewormhole-no-binwrite]], and the runner must re-read Credence for the
   needMusic tags. Disk gen is compiled (LocalGen) + svelte-check clean; a reload picks up the reverted .g + the
    gate + the tags together. On the current REMOTE runner the walk stalls (editor flaky) → expect `stalled`.
     See [[full-contract-no-subset-gaps]], [[transport-frames-post-do]].
