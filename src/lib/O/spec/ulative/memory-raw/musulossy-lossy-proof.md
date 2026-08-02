---
name: musulossy-lossy-proof
description: "MusuLossy Book PROVES the %Original|%Lossy grade split at census (green×2) — 3-way synthetic sources (WAV→Original, Opus+MP3→Lossy) + tags read-back + file left on disk; the gen-staleness-on-reload gotcha it exposed"
metadata: 
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**`MusuLossy` (Ghost/Story/Heistation.g) — BUILT + green×2 on dedicated runner `3c5238c6`, 2026-07-26.**
Proves the `%Record/%Original|%Lossy` split (Mag_todo §10) — the OTHER fork from the WAV→`%Original` the
 3 heist Books already show. **Census-only** (no two-Pier heist — the grade decision lives in the
  `Heist_census` mint via `Heist_body_new(rec, meta.lossless, s)`): plants THREE synthetic deterministic
   sources into `Heist_marrauding('lossy','shop')`, censuses them together (`artists=null`), each a DISTINCT
    grade road:
- **WAV** (`Crate_wav_with_tags`) → `%Original` via the ext allowlist.
- **Opus** (a real minimal Ogg/Opus from `this.Orig_ogg_page`/`_opus_head`/`_opus_tags` — OpusHead + OpusTags
   + one tiny audio page) → `%Lossy`. **music-metadata@11 gives Opus `format.lossless:undefined`** (NOT
    false), so opus lands `%Lossy` via the EXTENSION fallback — and that IS the real production road (a real
     `/music` `.opus` reads `undefined` too). Needs the audio page AFTER the tags or mm won't surface them.
- **MP3** (hand-built ID3v2.3 `TIT2/TPE1/TALB` + MPEG1-L3 frame headers `FF FB 90 00`) → `%Lossy` off
   `md.format.lossless===false`, the AUTHORITATIVE codec signal Crate.g prefers.
Snap shows `%Record>%Lossy,seq:0` + `title`/`artist` read from the compressed headers → split AND tag
 read-back proven in ONE fixture. 4th beat reassembles the opus `%Lossy` chunks and LEAVES the file on disk
  at `.jamsend/lossy-proof/` (OUTSIDE any `test-marrauding-of-*` namespace → the Book-start sweep never
   touches it — the human's "leave the downloaded file" ask) proving `sha256==body_hash`.

**THE GEN-STALENESS GOTCHA (cost a full run cycle):** a runner loads its code from the :9091 dev-server
 bundle built from `gen/*.go`, and **committed `gen/*.go` LAGS committed `.g` source** (gen is ephemeral,
  regenerated on build, NOT committed fresh). So `gen/M/Heist.go` at HEAD still minted `{Body:1}` even though
   `Heist.g` source had the split — the first MusuLossy run landed `%Body`. FIX: `LocalGen` (write mode, no
    CHECK) must regenerate the gen for **EVERY .g in the Book's live code path** (here Crate.g + Heist.g +
     Heistation.g), THEN reload the runner. Not just the file you edited. Revert gen to HEAD when done
      (`git checkout HEAD -- src/lib/gen/...`) — the sibling Books commit with stale gen too. See
       [[localgen-browserless-compile]], [[verify-via-live-runner]].

**`sha256_hex` is M-ghost scope only** — bare `sha256_hex(bytes)` throws in a Story ghost (Heistation);
 hash via `await this.Heist_hash(bytes)` (the cross-ghost wrapper). The throw was SILENT (step `error:null`,
  the note just never stamped) — diagnose a missing witness note by bisecting where the method died, not by
   trusting the error field.

**New-Book recipe confirmed** ([[new-book-cli-record-recipe]]): green is driven by SNAP-FIXTURE match, NOT
 declared assertions — MusuBay's `Credulate/toc.snap` is only a GhostInclude footprint + `last_ok`, no
  sworn contract. So: write .g → register in Credence (`brand_new:1`, desc no commas) → hand-author
   `toc.snap` with `step,dige:lie` lines → LocalGen gen → reload → run (red vs lie) → INSPECT snaps prove
    the truth → `accept` (generates numbered snaps + real diges + Credulate/Credulation) → rerun green×2.
     Dispatch is by convention (world named after Book; `do_fn_for` on `w.sc.w`) — no `Run_A_` recipe.
