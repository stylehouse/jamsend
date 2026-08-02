---
name: radiostock-disk-cap
description: "radiostock/ disk now bounded by a plain per-pub age-cap (Ra_stock_gc, cap 256); NO reference-tracing — a dropped byte-cache re-digs from source"
metadata:
  node_type: memory
  type: project
  originSessionId: 2f2e32df-77de-4509-9ea4-3454f9ecd5a7
---

**radiostock (`.jamsend/radiostock/<ts>-<pub>-<enid>`) is now zombie-proofed by a plain per-pub disk cap
 (2026-07-26, BUILT + green).** It was the ONE monotonic disk leak: `Stoker_cull` bounds the in-memory
  SHELF (44 live) and `Ra_stock_find` culls same-enid TWINS, but nothing bounded the DIR — one file per
   distinct track ever dug, forever.

- **`Ra_stock_gc(nav, pub)`** (`Ghost/M/Ra.g`, beside `Ra_stock_find`) keeps only this pub's newest
   **`Ra_stock_cap()` = 256** files, wears the oldest off (`Ra_stock_ls` is newest-first → `slice(cap)` is
    the oldest tail). Called once per **landed churn** in `Radio.g` beside `Stoker_mag_draw` (gated
     `landed > 0 && nav`), never per look.
- **The human's ruling made it SIMPLE: NO Mag-reference-tracing.** A `%Card` refers by id and the byte-cache
   REGENERATES — a dropped file is one re-dig from source (`Ra_stock_one` is idempotent, Radio.g:832; "a worn
    record is one resurrection away", Radio.g:777) — so keep-what's-referenced would be needless bookkeeping.
- Per-pub (a shared `.jamsend` never lets one identity evict another's shelf); best-effort (`Ra_stock_drop`
   no-ops on a read-only proxy); **NO sc telemetry** (a gone-count is disk-history-dependent = fixture noise).
- Proven: MusuStock green×2, MusuWear + MusuStanding green — the cap is a **no-op below 256** so no test that
   digs <256 tracks is perturbed.

**Two distinct levers, don't conflate:** this cap bounds PRODUCTION disk but is a no-op in tests (they never
 reach 256), so it does NOT make tests deterministic — that's the [[story-hygiene-hook]]'s job. And the ruling
  is we TOLERATE radiostock in tests: it is the **ONLY timestamped disk filename in the whole codebase**
   (verified — every other disk write is deterministic-named + overwrite-idempotent, e.g. `Heistation.g`
    wav/opus/mp3), non-colliding, already absorbed by the Sounditron EntropyArrest Entcases. So do NOT reflex
     a `Reset:radiostock` into meander Books. See [[radio-pipeline-opus]], [[musurastream-real-streaming]].
