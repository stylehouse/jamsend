---
name: one-off-utilities-are-books
description: "every one-off/utility/setup task is a Story Book (tracked in Credence), NEVER a one-shot node script"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

Owner BANNED one-shot node scripts (`scripts/*.mjs` written for a task). Every one-off utility, setup
 step, or generator from now on must be a **Story Book** — so it's tracked in Credence, run/understood
  in-machine, and re-runnable like any Book.

**Why:** a node script is invisible to the machine (not in Credence, no verdict, no shared understanding);
 a Book is a first-class, catalogued, inspectable unit. The whole point of the authored machine.

**How to apply:** build a `.g` Book (Musu convention: no Run_A_, Story_subHouse stands up A:<Book>/w:<Book>,
 dispatched by world name) + register it in `wormhole/Credence/toc.snap` (a `Funkcion:Storying,of_Book:<X>`
  cell under the right What) + `CREDULER_GHOSTS` if it's a new ghost. Heavy/DSL-unfriendly logic (binary
   encode, FSA writes, closures) lives in a `.svelte` H-method the `.g` beat calls — the `.g` orchestrates.
    Binary files reach disk via FSA on the granted dev-instance share (the text wormhole rw_op is text-only,
     but `bin_write`/`bin_read`/`read_range` on the nav carry bytes). Gesture-free READ is now via the
      **Wormhole nav** (`nav.dir_at(path).expand()`→{directories,files} + `nav.bin_read`), backend-agnostic
       across FSA-share / OPFS-cloud / editor-proxied runner — NOT `static/` + `manifest.json` + `fetch`
        anymore ([[music-real-audio-pivot]]).

First case, BUILT: the `MusuGenerateTestsMusic` Book (in Musuation.g, Credence cell under What:Musu) —
 the deterministic test-music generator: synth 8 pure musical tones (freq = the track's label, ≥110Hz
  apart) → `testsounds/` as JUST `Artist - Title.wav` files (NO manifest.json/tones.json anymore — a real
   collection is a folder of files; the freq↔track map lives in code = `TEST_TONES`).  Engine =
    `Musu_gen_testsounds` (LiesFunk) via `Housing.bin_write`.  Write to the REAL `testsounds/`, NOT the
     `static/testsounds` symlink (FSA won't follow it).  Run ONCE on a dev instance with a share granted.

**2026-07-02 pivot — Crate DISCOVERS via the Wormhole nav (no manifest).**  Owner: "we DO have to discover
 a filesystem full of music, via Wormhole."  Killed Crate's served-fetch+manifest path (deleted
  `Crate_manifest`/`Crate_fetch_record`/`Crate_fetch_some`/`Crate_fetch_payload`/`Crate_enc_path`).  New:
   `Crate_nav()` (A:Wormhole/c.nav), `Crate_nav_paths(nav,base)` (BFS walk `dir_at().expand()`, sorted rel
    paths — the track list, discovered), `Crate_nav_payload(nav,base,path)` (`bin_read`→OfflineAudioContext
     decode).  `Crate_rastock_start`/`_issue`/`_read_into` rewired to nav (nav rides `ra.c.nav`).  Added
      `dir_at(path)` to all 3 nav backends (WormholeNav/OpfsOverlayNav/RemoteWormholeNav) to avoid a spread-
       call in `.g`.  MusuCrate base `'/testsounds'`→`'testsounds'`, fetch-guard dropped.  Deleted the stale
        testsounds/manifest.json+tones.json off disk.  Type-clean + both `.go` recompiled (LocalGen).
         UNVERIFIED: a LIVE runner must RELOAD (re-acquire fresh Crate.go) before MusuCrate passes — the
          running one has stale gen + I removed the manifest it depended on.

**Phase 2 — MusuBounce Book BUILT 2026-07-02 (:9091-UNVERIFIED, needs live-runner record).**  First Book to
 fuse the transport spine with TWO live AudioContexts (one per Pier).  In Musuation.g `//#region bounce`:
  MusuBounce(A,w)/_drive(step 2-5)/_setup/_bounce/_witness + engine `Musu_bounce_run` (two-context real-time
   pump) + helpers Musu_bounce_send/_chunk_bytes/_bytes_pcm/_peak(getFloatFrequencyData argmax)/_tone_of
    (quantise to nearest known tone ±30Hz)/_argmax_key; `Musu_test_tones()` added to LiesFunk (=TEST_TONES
     freqs, single source).  Pier A `Lake_link`s to B (mock loopback, as MusuPier), plays 3 real nav-discovered
      tracks (~1s each) on ITS SoundSystem + dribbles bytes over %bouncechunk frames (ack-gated STAY≤7); B's
       recv handler schedules un-skipped tracks on ITS OWN SoundSystem (NOT the shared Musu_gat — that cache is
        the only thing fighting 2 contexts); both analysers sampled @50ms.  STABLE-SNAP via determinism: sorted
         tracks + SEEDED skip schedule + tone LABELS not raw Hz + heard/not booleans not durations.  Witnesses:
          two_contexts/crossed/heard/matched/skip_observed.  Credence cell `MusuBounce,needAC:1` (under
           What:the network) → rides the pre-flight AC gate.  toc.snap = 5 lie-dige steps.  Both .go compiled,
            type-clean.  Owner must: grant AC + run on a reloaded runner; first run RECORDS the fixture (accept).
             Real-time is genuinely non-det under the hood — expect to iterate the snap once on live hardware.
 Owner (2026-07-03) MOVED the Credence cell to top-level What:Musu + DROPPED needAC (so it self-secures via
  SoundSystem.init()/resume — the run-click gesture — and skips 'no_audio' if none, rather than begging).
   Hardening pass (read-review, no runner): crossed-count made deterministic (break waits acked>=plan.length,
    else a skipped LAST track's in-flight frames race it low); clean 'no_tracks' skip when the collection is
     empty; w.c.acked/crossed reset per run.  KNOWN latent (documented in Crate.g Crate_nav + Radio_spec §1):
      Crate discovery awaits the nav INLINE — fine for local FSA/OPFS (disk-loop resolved), but a REMOTE
       atime_async nav would DEADLOCK under the beliefs mutex; the fleet path must route via the rw_op actor
        (Wormhole_park runs it off-Atime) — a TODO, not built (untestable without a remote runner).

