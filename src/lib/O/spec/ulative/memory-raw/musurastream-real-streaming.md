---
name: musurastream-real-streaming
description: Ra CHUNK-PARTICLE rebuild + 2026-07-10-late rulings (preview const 32, radiostock <ts>-<pub>-<enid> naming, no friend cache, dead-source drop) — re-record DONE 2026-07-11, family GREEN
metadata:
  node_type: memory
  type: project
  originSessionId: 99e62ec8-06cf-4c57-990a-57905ed6dffa
---

**The chunk-particle rebuild BUILT 2026-07-10** (forks ruled: FLAT shape, raw u16-length-prefixed packets — Ogg mux DELETED, DEMAND-DRIVEN). *What snaps, replicates*: chunks are REAL children `%Preview,seq`/`%Stream,seq` (ONE seq space, seq rides as STRING), bytes on `.sc.buf` (snaps as muted `Uint8Array()`; NEVER toc-persist a subtree with sc-bufs), `head`+`preskip` on the two chunks where a decoder opens. `rec.c.segs`/`have=`/`racast_*` DEAD. ONE ENCODE PER SIDE; a PARKED want ignites the stream transcode, runs to completion (no rate flag). Decode: one AudioDecoder per contiguous run, split at `head` chunks, preskip dropped there.

**2026-07-10-late owner rulings (all BUILT + LIVE-CHECKED same night, full detail = Radio_todo.md §0):**
- `Ra_preview_secs()` = **hard constant 32, no w param** ("not something a Book decides"). 32 not 33: P must be EVEN (want-page grid seg2s×PAGE2) or "first stream want == seg P" is unmintable. MusuRaStream's 12s window died; same knobs, longer cycle, fits the 40 steps.
- Radiostock = `<ts>-<pub>-<enid>.jamsend_radiostock`: ts so old ones DELETE (find GCs older twins; `Ra_stock_gc` drops superseded same-path renders), pub = owning Peering's pier key (many-Pier-one-.jamsend filter via `Ra_stock_ls`), **enid = sha256(whole source bytes) first 16 hex** — content id, never pub/path-locked. `Ra_id`/`Ra_bytes_hash`/`src_hash` DEAD. One-shot `*.jam` migration sweep in `Ra_stock` (remove when clean).
- **NO friend-download cache**: `Ra_term_stash` + downloads/<friend> DELETED — pulled chunks are ephemera, radiostock is for one's OWN collection speedy run-around; moving music is a later economy.
- **Dead-source rule**: source unreadable at `Ra_source_pcm` ⇒ drop the radiostock file (`rec.c.card_file` from `Ra_card`) — no source, no Stream, no stock.
- PRESKIP has its canonical statement at `Ra_encode_open`: encoder convergence ramp (312@48k) the decoder drops at each fresh open; rides card + head chunks because we deleted the OpusHead container; NOT a time offset (time-in = seq × seg_secs).

**GOTCHAS:** LocalGen for Ra.g (spine-BOMB — never ghost-compile it vs a live editor). Session-see gates ride `n >= K`. Books gate on AudioDecoder + bin_write (needsFSA).

**LIVE 2026-07-10 late:** all four green-shaped on the live runner — 24/24 %see (Stock 6 `stood=3` re-pass, Cast 6 `chunks=39 parked=12`, Term 5 `healthy=0/starved=320/lufs=-14.03` preview=16, Stream 7 ask@14→want=16==P→fed@18→switch@20 `a_drops=0 b_heard=0 lufs=-14.01`). Reds = pure fixture drift (16-hex enids, preview=16, no src_hash, no stash rows).

**Re-record DONE 2026-07-11, family GREEN:** Stock/Cast/Term by the owner; Stream via `runner_ask accept` (7/7 %see pre-pinned + confirmed present post-accept). Verify re-runs: Stock 5/5 ≈2, Cast 12/12 ≈9, Term 12/12 **≈0**, Stream 40/40 ≈37 — the ≈ pattern is PERMANENT and benign: exactly the AudibleEntropy-grafted seal fields (Pier since / Grant time+sign / Edge at); Term seals nothing ⇒ 0. Session gotcha: immediate redispatch after accept hit the engaged **begun-wedge** (phase begun, n:null, watch dies ~25s) — `release` + ~8s wait + redispatch cleared it, NO tab reload needed; a second runner answered broadcast ping mid-session, so ALWAYS `--runner=<prefix>`. Related: [[musu-ra-book-entropy-reaccept]], [[see-is-not-a-latch]], [[verify-via-live-runner]], [[pere-books-total-1]].
