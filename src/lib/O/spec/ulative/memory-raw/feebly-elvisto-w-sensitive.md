---
name: elvis-target-may-not-exist
description: "feebly_i_elvisto stamps `feebly:1` on the elvis; deferred targeting silently drops a flagged miss (distributed-mind sync), unflagged stays loud"
metadata:
  type: project
  originSessionId: 589b8f0b-32c5-427d-9aab-2e790bee64c1
---

`i_elvisto(target, method, extra)` (Housing.svelte.ts) defers targeting to Runtime:
 `e.c.targeting = this.clear(async () => { _find_house(target); _expand_Aw; _push_todo })` — `clear`
  = `await all_clear()` then run, i.e. the Atime→UItime/Runtime gate. So the elvis LAUNCHES when called
   but RESOLVES later; by then the target ghost/world may be gone.

**The human's frame:** these are best-effort pokes pinning together a **distributed mind** — "try to keep
 things in sync, but we've no idea if now is the moment or if the other side even exists" (a runner with no
  editor, a sibling glass — Vyto not Cyto, a torn-down view). A "keep Cyto in the loop of this activity" ping.

**Why the old `feebly` couldn't save it:** it did a SYNC `_find_house` probe then fired. The probe passes
 (A:Cyto exists THIS instant) → elvis launches → deferred targeting resolves AFTER the run/view tore A:Cyto
  down → `_find_house` throws `no House has A:Cyto`. The old `.catch(err => { throw err })` made that an
   UNHANDLED REJECTION → with devtools "pause on exceptions" it PAUSED the tab and **halted the editor's
    compile loop** ("nothing recompiled for ages" wedge). feebly's sync gate is blind to this race.

**FIX (2026-07-29):** target-may-not-exist modulation lives ON the elvis.
 - `feebly_i_elvisto = i_elvisto(target, method, { ...extra, feebly: 1 })` — no sync probe; just stamp it.
 - i_elvisto's deferred catch: `if (e.sc.feebly) return; throw err`. A flagged miss silently drops at
    resolve-time (closes the race); an UNflagged miss still rethrows loud (a real mis-target = insanity, stays
     fatal). Any call can pass `feebly:1` in extra to opt a single poke into tolerance.
 So: CLIENT/optional Cyto|Lang pokes → feebly (Storui seeks, Lang commission/anim 224/1386, Lies→Lang
  299/339, InterestStrip 116). OWNER commissions stay non-feeble but gated + self-create the world (Story
   1574/2354 behind useCyto, mints A:Cyto+w:Cyto as a PAIR ~1553). Direct `Awo('Cyto')` reads must be
    try/catch (Cytui already; Story snap_H ~1416 guarded this session).

Superseded a brief w-sensitive-probe attempt (feebly calling `Awo(A,w)`) — reverted: the probe is still a
 sync snapshot, the FLAG is the real fix. Requires an editor HARD-RELOAD to land (wedged tab won't pick up
  the .ts). See [[elvis-handler-name-verbatim]], [[hmr-socket-dead-tell]], [[drop-leaves-index-giant-stuff]].
