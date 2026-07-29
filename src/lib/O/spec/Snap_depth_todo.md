# Snap depth limit — the silent `max_child_depth` cut

The alarm (the human, 2026-07-29): *"have we got an un-noticed depth limit to snap?
 holy shit that's low quality software."* Follow-up directive: **they never agreed to a
  snap depth limit — REMOVE it from the snap/world view, don't just make it loud.**

Done. The one snap/world view that capped is now **uncapped**. Recorded fixtures were
 **never** capped (verified in code — see the verdict). One deliberate cap survives, on a
  Lang push-state *comparator* (not a snap), flagged below for the human to rule on.

## 0. What to get on with next

- **Empirical confirm (main session):** run the **full Story suite once on a live runner**
   and diff against the recorded fixtures. The code says fixtures were never depth-capped,
    so a clean run confirms nothing silently leaned on the (now-removed) `world_snap` cap.
     No re-record is expected. If any Book goes red on content that *appears* for the first
      time, that's the tell a cap was load-bearing somewhere the grep missed — investigate,
       don't blanket-accept.
- **Human decision owed — LangHold `max_child_depth: 0`:** left in place (see below). It is
   NOT a snap and NOT a doc-preview; it's the origin-vs-working *equality* encode behind
    Lang push-state. Uncapping it WOULD change behaviour (spurious "dirty"). Recommendation:
     **keep it.** Human to confirm.

## The mechanism

`src/lib/O/Text.svelte`, `encode_wh_lines` (THE snap encoder — every `enWaft`/snap goes
 through it), pass-1 `Travel.dive`:

```
const d = T.c.path.length - 1
if (opt?.max_child_depth !== undefined && d > opt.max_child_depth) {
    T.sc.not = 1   // this node + its WHOLE subtree silently vanish from the snap
    return
}
```

It is **silent** and **only bites when a caller passes `max_child_depth`**. The parameter
 itself is a **legitimate optional feature and stays** — the fix is to ensure no snap/world
  view passes it, not to rip out the mechanism.

## What changed

- **`src/lib/O/LiesFunk.svelte` (`op === 'world'`, the `runner_ask world` diagnostic):**
   removed `max_child_depth: 6` from the `world_snap` `enWaft(stW)` call. The resident-world
    snap now encodes the **full tree, uncapped** — nothing is silently dropped. (Trade-off
     the old cap bought: a smaller reply that skipped the paged Record/Preview/Stream clouds.
      A bigger honest reply beats a silent cut — the human's call.) Comment updated to say so.
- **`src/lib/O/Text.svelte`:** reverted to HEAD. No loud-warn edit remains. The
   `max_child_depth` parameter + cut logic stay exactly as they were (a legit optional feature).

## Blast radius — every `max_child_depth` caller

Grepped `src`, `Ghost`, `scripts`, `gen`. After the change, call sites are:

1. **`src/lib/O/LiesFunk.svelte` world_snap — CAP REMOVED.** Was the only snap/world view
    that capped (depth 6). Now uncapped. Ephemeral anyway (a read-only relay reply, never
     persisted).
2. **`src/lib/O/LangHold.svelte:1420` — `max_child_depth: 0`, RETAINED (see next section).**

Nothing else passes a cap. (`gen/` has zero occurrences; `spec/*.md` mentions are prose.)

## Fixtures-were-never-capped — VERDICT: **NO, recorded fixtures were never capped.**

Verified by reading the fixture writers, not the docs:

- **`toc.snap`** ← `Story.svelte` `encode_toc_snap`: a plain `Travel.dive`, its own comment
   *"Walk The/** with Travel for **infinite depth**."* No `max_child_depth`.
- **Numbered `NNN.snap` (`got_snap`)** ← `story_snap` → `snap_H`: a *separate* encoder
   (`Selection.process` + `story_process_node` + `enL`) that never calls
    `encode_wh_lines`/`enWaft` at all, so `max_child_depth` cannot reach it. (It has its own
     snap-shaping — `dontSnap`, `boring`, `T.sc.more` — but no depth cap.)
- **`.g` snap writers** — `Berth_save` (`Ghost/M/Heist.g`), `Swarm.g`, `Heistation.g` — call
   `enWaft(waft)` with **no opt**, i.e. no cap.

**Live proof:** a `got_snap` the human pasted reached ~depth 9 (`Record > Preview`); a
 depth-6 cap would have dropped everything below d=6, so `Preview@d9` even appearing proves
  that path is uncapped. **So: no re-record needed** (the ## 0. suite run confirms empirically).

## The one judgment call — LangHold `Seem_toString` origin, `max_child_depth: 0` — KEEP

**What it feeds (precisely):** `Seem_toString(origin)` → **`LE_encode_compare`**
 (`LangHold.svelte:1437`), which returns `{ snap_origin, snap_working, dirty }` and stamps
  `%State.changey`. That is the **Lang push-state / edit-detection dirty flag** — read by
   Liesui, `NaviCado`'s reset (↩) gate, and auto-push-on-drift. It is **not DocMinimap, not
    Lang_apply_openness, not a recorded snap** — it's an in-memory equality comparator.

**Why depth-0 is deliberate and load-bearing (from the code comment + trace):** origin's
 *live* tree has deep `%Point` children that *working* (a shallow clone) never checked out.
  Encoding origin full would make two **equal-content** trees compare **structurally unequal**
   even with no edits. Depth-0 bounds origin to working's shallow extent so `dirty` reflects
    real edits, not un-checked-out depth.

**Would uncapping change anything? YES** — it would make clean docs read as permanently
 `dirty`, surfacing a spurious push affordance / firing auto-push when nothing changed. So
  **do not remove it.** Left in place; flagged here for the human to confirm.

## Pointers

- Encoder + retained mechanism: `src/lib/O/Text.svelte` `encode_wh_lines`.
- Cap removed: `src/lib/O/LiesFunk.svelte` (`op === 'world'` world_snap).
- Retained deliberate cap: `src/lib/O/LangHold.svelte:1420` (`Seem_toString` → `LE_encode_compare`).
- Fixture encoders (never capped): `Story.svelte` `encode_toc_snap`, `story_snap`/`snap_H`.
- Cross-spec index: `spec/Everything_todo.md`.
