# req:Keeping — consolidating the focused-and-remembered workspace

Status: **design, for review.** Nothing built yet. The Keep noun lives in
`Cluster_design.md`; this doc is the *driver* that writes it and the spine
refactor that gives it one owner.

Distilled from reading the live spine (`Lies.svelte` desire/acquire/timemachine/
focus_waft/keep_*, `LiesHold.svelte` req:workon). Marked **today** vs **proposed**
so the two never blur on a re-read.

---

## Destination

One per-tick driver, `req:Keeping` (one per `w`), owns *the focused workspace and
its memory*: which Waft has focus, resuming it on boot, converging its active dock,
and recording attention to the Keep ledger. It replaces a four-req smear with one
authority, and drops the one piece that never belonged on the Lies side — a sense
of time (playback). Time is the Cursor's, not Lies'.

---

## The spine **today** (what we're healing)

The "what's focused and live" job is spread across four reqs with no shared owner:

| req | host | does | lifetime |
|---|---|---|---|
| `req:desire` | `w` | the snap-visible **Waft lock** (thinned to a wrapper) + seeds the playback engine | per-tick wrapper |
| `req:acquire` | `desire` (maz:9) | the **one-shot boot gate** — holds until a Waft is present, then locks focus + seeds, `desire.finish(acquire)` | one-shot |
| `req:timemachine` | `%examining` | per-tick **cursor-land** on focus (`Lies_desire_land_cursor`, keeps lock honest) **AND** **playback** (play/pause/step/auto-advance → `%want,kind:step`) | per-tick |
| `req:workon` | `w` | the **dock-convergence pipeline**: understanding → ingredients → instrumentation, keyed on `workon.c.src` (Lang-seeded via `e_Lang_workon_update`) | per-tick, sig-gated stages |

The selector `Lies_focus_waft(w)` (`.sc.active` → cursor's-waft → first non-`%boring`)
is already the single truth for *which* Waft — both the acquire seed and the
timemachine land go through it, so they can't diverge. That selector is the seed of
this consolidation: it proves focus already has one resolver; it just lacks one
*driver*. The Keep helpers (`Lies_keep_note`, `_mark_focus`, `_note_cursor`,
`_resume_*`, `_boot`) are bolted onto the event handlers
(`e_Lies_foreground_waft`, the `Lies_resolve_wants` want-land), not owned by any req.

---

## `req:Keeping` — **proposed** shape

`req:Keeping` is `req:workon` renamed and widened. It absorbs `desire` + `acquire`,
drops `timemachine`'s playback, demotes `timemachine`'s land into a sig-gated step,
and pulls the Keep recording in off the event handlers. Per-tick walk:

```
req:Keeping  (one per w; was req:workon)
  1. acquire-once   (was req:acquire, maz:9 boot gate)
        first Waft present → Lies_keep_boot (resume from the Keep ledger) + seed.
        finishes once; never re-arms.
  2. focus          waft = Lies_focus_waft(w)        — the .sc.active | cursor | first-non-boring selector
        record the snap-visible Waft lock (was desire's job; keep it honest)
  3. land           ensure the cursor sits on `waft`  (was timemachine Job A)
        SIG-GATED on focus-change — boot/reload/rename re-assert; steady-state no-op.
        (the .sc.active want-land already keeps the cursor put; this only catches
         the cases a want never fired for.)
  4. converge       understanding → ingredients → instrumentation   (workon's stages, UNCHANGED)
        on `waft`'s active dock (src). Focus is resolved first (cheap) and fed in,
        so the convergence sigs stay exactly as they are — no entanglement.
  5. record         cursor + accessed_at → Keep ledger
        (was the bolted-on Lies_keep_note_cursor / _mark_focus on the want-land)

  DROPPED: playback — play/pause/step/auto-advance.  "No sense of time on Lies."
```

`%examining` **survives** — it's the cursor's home (the `Spotlight`); it just loses
its `req:timemachine` child. Keeping reads `examining`'s `Spotlight` for the cursor,
exactly as `Lies_focus_waft` does now.

### Step 4's `src` — one design choice inside the choice

`workon.c.src` is **Lang-seeded** today (`e_Lang_workon_update`). Once Keeping
resolves focus itself, it *could* derive `src` from the focus Waft's cursor
(`examining/Spotlight.src`) and stop depending on Lang's push — they should already
be the same particle (the active dock = the cursored dock). **Recommend: keep
accepting Lang's push for the first cut** (smaller change), note self-derivation as
a later simplification once Keeping is proven.

---

## What drops, and the bomb it detonates

**Playback (timemachine Job B)** is the only true deletion. Its consequence:
**NaviCado's transport loses its engine.** play/pause/step/auto-advance were the
`Lies_desire_play|pause|step` elvis gestures that `req_timemachine` drained into
`%want,kind:step`. Two ways to land this — **a decision for you**:
- **(a) drop the transport** — NaviCado stops offering play/step; the slideshow goes.
- **(b) re-express as gestures** — the step button emits `%want,kind:step` straight
  into `req:wants` (the accumulator already takes `kind:step`), `Waft_cursor_next_candidate`
  stays, no engine. Auto-advance (the only piece that needs a *clock*) is the only
  thing that genuinely dies.

**Job A (per-tick land)** is *demoted, not deleted* — it becomes step 3, sig-gated.
The bomb if we delete it outright: boot/reload/`become_book`/rename leave the cursor
with nothing to land on, and the editor opens blank or on the wrong Waft. The
`.sc.active` want-land covers *moves*, not *cold starts*. Keep step 3.

---

## Rideable changes — "other wanting-to-happens"

You asked what else belongs in this change. Candidates, each marked
recommend-**IN** / **OUT** / **DECIDE**, for you to check:

1. **IN — the kind-table (INTEREST_KINDS) + Keep visibility.** This *is* "centralise
   their properties." A declarative `{kind → snap, focusable, nibbed, persists,
   minimisable, lens}` table that `Lies_waft_kind(waft)` resolves from the terse
   flag-set, subsuming `interest_stance_of`. Decomposes `%boring`: **`kind:Keep`
   shows its line in the snap** (so you finally *see* the Keep's `/**`), while a
   borrowed `EntropyProfile` keeps full vanish. Step 2 (focus filter) and step 5
   (record) both consult this table — same consolidation, and it fixes the
   visibility you're staring at right now.

2. **IN (rides #1) — `%Aim` leaving `Waft:Cluster`.** Cluster's behaviour comes from
   `kind:Cluster` in the table, not a bolted `Aim` flag. The flag's departure is just
   the table absorbing it.

3. **IN (new territory) — per-Waft minimise / scroll.** This is the "does the
   minimise sync to the Keep" you asked: today it's *unbuilt*. Keeping step 5 records
   it per-`WaftTimes`; nib-foreground/boot restore it. Small, additive, and it's the
   Keep finally earning "workspace that *remembers*."

4. **DECIDE (rides #1 if cheap) — a Board kind.** `Waft:Cluster` / `Waft:Credence` are
   watch-boards mis-elected as Trails by the `else→Trail` fall-through. The table can
   give them `kind:Board` (`presence:always`, no LE, pins above the fold). Worth it
   only if #1 lands; otherwise defer.

5. **OUT (orthogonal) — `req:wants` / the want-drain cap.** The cursor-intent
   accumulator stays as Keeping's *input* via `Lies_resolve_wants` (the one
   cursor-write seam). Don't touch it here.

6. **OUT (separate doc) — the full 5-site Interest unification.**
   `interest_cursor_for` / `interest_foreground` / `InterestStrip` label+glyph /
   `Lies_waft_save` exemption all want to read the same table eventually. #1 builds the
   table and routes the Keep + focus through it; routing the *other three* is a follow-on
   so this change stays reviewable.

**My recommendation for the bundle:** the spine refactor (1–5 of `req:Keeping`) **+
rideable #1 and #3**. #1 because it's the same "centralise" instinct and it un-blinds
the Keep; #3 because it's what makes the Keep more than a cursor log. #2 falls out of
#1 for free. Hold #4/#6 for a follow-on.

---

## Phasing — prove in isolation, don't break every page

The `c.up`-in-`i()` lesson: never change the core spine *and* rip out the old
mechanism in one step. Order:

1. **Table first, behaviour-neutral.** Land `Lies_waft_kind` + the table; route the
   Keep (`kind:Keep`, line-shows) and the focus filter through it. Verify the Keep's
   `/**` appears in the snap and on `:9091`, focus unchanged. *No req touched yet.*
2. **Stand up `req:Keeping` beside the old reqs**, deriving focus + converging, with
   the old `desire`/`acquire`/`timemachine`/`workon` still present but inert-checked
   (assert Keeping reaches the same focus + same convergence as today). App still
   boots, all pages.
3. **Cut over**: delete `timemachine`'s playback, fold land into step 3, retire the
   `desire`/`acquire` wrappers into Keeping. Re-record any Story snap that asserts the
   old req shape (human records snaps).
4. **Then** rideable #3 (minimise) as net-new on the proven driver.

Each phase is independently verifiable; a regression bisects to one phase.

---

## Open decisions for you (the check-twice list)

- **D1 — NaviCado transport:** drop it (a), or re-express step as a `%want,kind:step`
  gesture and let only auto-advance die (b)? *(I lean b — cheap, keeps the button.)*
- **D2 — bundle scope:** spine + #1 + #3 as recommended, or spine-only first and the
  rideables as a second pass?
- **D3 — `src` ownership (step 4):** keep Lang's `e_Lang_workon_update` push, or have
  Keeping self-derive `src` from the cursor? *(I lean keep-the-push for cut #1.)*
- **D4 — doc home:** this as its own `Keeping_spec.md` (current), or folded into
  `Cluster_design.md` beside the Keep noun?
- **D5 — name:** `req:Keeping` confirmed, or another gerund?
