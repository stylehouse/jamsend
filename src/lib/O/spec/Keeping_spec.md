# req:Keeping — consolidating the focused-and-remembered workspace

Status: **design, for review.** The **`req:Keeping` driver is unbuilt** — but the
Keep *noun* it would own is already live: `Waft:Keep` is a real snapped Waft (Persist
loads/creates it), and the `Lies_keep_*` helpers (`_boot`/`_reopen`/`_resume_waft`/
`_resume_what`/`_note`/`_mark_focus`/`_push_cursor`/`_note_cursor`, `Lies.svelte`
~1000–1140) already write and replay it — just **bolted onto the event handlers**, not
owned by any req. This doc is the *driver* that consolidates them, plus the spine
refactor that gives the focused-and-remembered workspace one owner. The Keep noun's
fuller shape lives in `Cluster_design.md`.

**This is where Lang/Interest state resumes from.** Focus, the cursor, and the open-set
are no longer session-only — they persist through the Keep ledger and replay on boot
(`Lies_keep_boot`/`_reopen`). The `Interest.md` "Rejoin the stack frame" /
"Per-(Interest, Waft) cursor-memory" TODOs are the Interest-side face of this same resume.

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

## The bigger frame — Lies ↔ Interest ↔ Lang

Keeping is the *inward* half of one channel. Three observations set the altitude:

**Interest and Keeping are the same attention channel from opposite ends.**
`%Interest` (Lang side) projects attention *outward* — the strip, the foreground
LE, the checkout. Keeping projects it *inward* — the ledger, resume, minimise. They
were built as unrelated subsystems; they are one thing. The north star both reduce
to is `%subscribe` (`Wire_spec.md` / Hovercraft §7): *"I attend to Waft X" is "I
subscribe to X."* The Keep ledger = the **persisted** subscription set (for resume);
the Interest roster = the **live** set, projected to the view.

**Two things are each computed in too many places — and they're orthogonal.**
- *Kind* ("what is this Waft") is derived **twice**: raw flags on the Lies Waft
  (`boring`/`takes`/`lists`/`aside`) AND the reconciled `%Interest` on the Lang side,
  re-derived ad-hoc in ~6 more spots (InterestStrip label+css, `Waft.svelte`
  is_taker/is_lister, `Lies_waft_save` exemption, `Lies_order_wafts` sort, the
  `boring` filters). → the **kind-table** collapses this. It lives on the **Waft**
  (the subscribable noun); `interest_reconcile` *reads* it instead of re-deriving.
- *Attention* ("am I looking at it now") is claimed **five ways**: `.sc.active`,
  `ActiveInterest`, the desire lock, the Spotlight cursor, the Keep. → **req:Keeping**
  collapses this. The cursor is the live truth; `.sc.active`/`ActiveInterest` become
  projections Keeping writes; the Keep is the durable ledger.

Kind is durable identity; attention is momentary. The flag-soup conflates them
(`active` sits in the same `.sc` as `boring`). Splitting **kind (table, on the Waft)**
from **attention (Keeping, off the cursor)** is the whole cleanup — two axes, not one.

**LiesHold is already the bridge — name it.** `Lang_set_interest` and `req:workon`'s
do_fn are *defined in LiesHold* yet *own Lang's particles* (`%Interest`, `Languinio`,
`ActiveInterest`). That code-location-vs-data-ownership mismatch **is** the leaky
boundary. The "Lies = document / Lang = view" cleave has a missing third part: the
**attention engine** that turns a cursor move into foreground + checkout +
address-publish. Renaming `workon → Keeping` is the moment to admit LiesHold *is*
that engine — the Interest channel's driver — not "more Lies."

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
  1. boot           (was req:acquire, maz:9 gate — but STAGED, not a one-shot)
        a heartbeat gated by w.c flags: open Waft:Keep (async load via req:Store), then
        once it materialises resume from the ledger (Lies_keep_boot), THEN finish.
        a naive one-shot finishes before the async Keep arrives → no resume (gap 2).
  2. focus          waft = Lies_focus_waft(w)        — the .sc.active | cursor | first-non-boring selector
        Keeping becomes the SOLE writer of .sc.active (6 sites set it today); .sc.active
        and ActiveInterest become PROJECTIONS of the resolved focus, not rival truths.
        record the snap-visible Waft lock (was desire's job; keep it honest)
  3. land           ensure the cursor sits on `waft`  (was timemachine Job A)
        SIG-GATED on focus-change — boot/reload/rename re-assert; steady-state no-op.
        (the .sc.active want-land already keeps the cursor put; this only catches
         the cases a want never fired for.)
  4. converge       understanding → ingredients → instrumentation   (workon's stages, UNCHANGED)
        on `waft`'s active dock (src). Step 2 resolves WHICH Waft (cheap); the
        understanding stage here still PROJECTS that foreground outward via
        Lang_set_interest (ActiveInterest + the per-Interest LE) — the outward half
        of the attention channel, unchanged. Keeping owns "which"; convergence owns
        "tell the view".  (foregrounding == the checkout — see The bigger frame.)
  5. record         the WANT-LAND records cursor + accessed_at → Keep ledger
        (Lies_resolve_wants → Lies_keep_note_cursor, on the event — not a tick poll;
         Keeping's tick only reads. recording stays event-driven.)

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

## What drops (D1 — the whole transport)

play/pause/step/auto-advance — the `Lies_desire_play|pause|step` gestures
`req_timemachine` drained into `%want,kind:step` — **all go**, not just the dead
play/pause but the prev/next step too. **The time dimension leaves the editing code
entirely.** Sequencing a show through a set of Wafts becomes a separate *director*
layer later — script-writer vs director: authoring the Wafts is one job, sequencing a
show through them is another — built away from the cursor engine and probably off the
code surface. NaviCado loses its transport; intended.

**Job A (per-tick cursor-land) is demoted, not deleted** — it becomes step 3,
sig-gated on focus-change. The bomb if deleted outright: boot/reload/`become_book`/
rename leave the cursor with nothing to land on → the editor opens blank or on the
wrong Waft. The `.sc.active` want-land covers *moves*, not *cold starts*. Keep step 3.

---

## Keeping ↔ Interest — the boundary (half its life)

Keeping and Interest meet at every step; here it is in detail.

- **The `%Lango` edge (inward → resolver).** A UI:Waft click is a cursor move: Lies
  fires the push-what's-focused event — call it **`%Lango`** (today
  `e_Lang_workon_update`) — a bare "look at this, move the show here" naming NO specific
  Interest. Keeping *resolves* one for it: focus (step 2) → converge (step 4), where the
  understanding stage's `Lang_set_interest` brings the foreground Interest + its LE into
  being. So `%Lango` is the inward signal; `%Interest`/`ActiveInterest` are the outward
  projection Keeping produces. Most navigation IS this — clicks inside UI:Waft — so in
  practice Keeping drives Interest far more than the reverse.
- **The roster edge (the live subscription set).** Lies owns the Waft set; each tick
  `Lies_waft_roster_pump` pushes the roster when `interest_roster_sig` moves;
  `interest_reconcile` mints/binds/drops `%Interest` rows. With the kind-table on the
  Waft (D6), reconcile READS `Lies_waft_kind` instead of re-deriving stance from flags.
- **The ledger edge (the persisted subscription set).** Step 5 records cursor +
  accessed_at + minimise to the Keep — the durable twin of the live roster. *Interest
  roster : Keep ledger :: live : persisted.* (This is the `Interest.md` "Rejoin the
  stack frame" / "Per-(Interest, Waft) cursor-memory" TODO, Lies-side.)

**Scope — editor only.** This whole apparatus is **`Lies%editor`**. The runner
(`Lies%runner`) stays lean: it acquires + runs — no Keep, no Interest, no resume. The
helpers already gate on `Lies_role(w) === 'editor'`; Keeping makes that a *stated
boundary*, not a scattered guard.

---

## The kind-table — on the Waft, realized by a Funkcion (D6)

The Waft's kind lives **on the Waft** (the subscribable noun); `%Interest` is a
projection `interest_reconcile` reads, not a parallel truth. A kind is two things:

1. **capability flags** — what the classifiers need (snap / focusable / nibbed /
   persists), replacing the ~6 scattered raw-flag reads (`interest_stance_of`,
   `Waft.svelte` is_taker/is_lister, `Lies_waft_save` exemption, `Lies_order_wafts`,
   the `boring` filters).
2. **an autovivified Funkcion** — the kind's *behaviour*, and its **pathway in at
   startup**: when the Waft loads from snap its kind's Funkcion autovivifies and wires
   it up (the Keep replays its ledger; Cluster opens its network sync). Passive kinds
   carry none — the editing checkout is their whole life.

*Nibbed* = gets a switcher **nib** (a cap in the InterestStrip you click to
foreground). Background kinds aren't nibbed — no cap, off-stage.

| pole | kind | snap | focusable | nibbed | persists | autoviv Funkcion (startup pathway) |
|---|---|---|---|---|---|---|
| **attention** | Trail | full | ✓ | ✓ | ✓ | — (the checkout is its life) |
| | Aside | full | ✓ | ✓ | ✓ | — (GC-stale-days, later) |
| | Sidetrack | — session | ✓ | ✓ | ✗ till graft | — |
| | Ting | — session | sinks | ✓ always | ✗ | the tap accumulator |
| | GhostList | line (`dontSnap`) | ✗ light | ✓ | ✓ | the ghost-index builder |
| **background** | **Keep** | **line — visible!** | ✗ | ✗ | ✓ own home | ledger replay/record (`Lies_keep_boot`) |
| | **Cluster** | vanish (`boring`) | ✗ | ✗ | ✓ | the network-stack sync |
| | Upkeep / Board | line / board | ✗ | ✗/special | ~ | the background-work runner |

`boring` stops being a flag smeared onto whatever wants to hide — it's just **one
kind** (full-vanish background: Cluster, borrowed `EntropyProfile`s). The **Keep is its
own kind** (visible background — line-shows so you watch it accumulate), so we stop
overloading `boring` onto it. That is the whole "can we lose `boring`" answer: not
lose it — stop *misusing* it.

---

## Rideable changes — "other wanting-to-happens"

You asked what else belongs in this change. Candidates, each marked
recommend-**IN** / **OUT** / **DECIDE**, for you to check:

1. **IN — the kind-table on the Waft (D6).** This *is* "centralise their properties" —
   full shape in **The kind-table** above (capability flags + an autovivified Funkcion
   per kind). `Lies_waft_kind(waft)` is the one authority; it subsumes
   `interest_stance_of` and the raw flag reads, and gives the **Keep its own visible
   kind** (line-shows) instead of overloading `boring`. **Now free:** `enWaft`'s old
   mainkey-vocabulary gate is *parked* (commented out — any mainkey encodes;
   `WAFT_PROTOCOL` only attaches `omit_sc` session-key stripping now, it does NOT gate),
   so new Waft child kinds snap with zero protocol registration.

2. **IN (rides #1) — `Waft:Cluster` as a `boring` background kind.** Cluster is just the
   full-vanish background kind (`boring`); its behaviour is an autovivified **Funkcion**
   that syncs network-stack state into itself — a bare functional `req` with Funkcions
   overlaying for persistence. `%Aim` leaving is the table absorbing it. *(Caveat: the
   sweep found no live `.sc.Aim` reader — likely vestigial; verify before counting its
   departure as work.)*

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

7. **IN (fold-in) — one locator/resolver.** The Keep's cursor-locator (`what:What:<name>`,
   via `Lies_locate_in_waft`), `%FromWhat` (Interest.md's Aside back-pop,
   `Waft:<key>/<mainkey>:<value>`), and the Text-Point bridge's `text:<word>` are the
   SAME primitive — resolve a loose mainkey/value/text locator to a live particle. Unify
   to one resolver here; the Keep just forked a third copy, and leaving it grows three
   drifting ones.

8. **DECIDE (shared blocker) — rename-caretaking.** Interest.md names it twice as the
   blocker behind the tidy in-Trail Aside home AND per-(Interest,Waft) cursor-memory; the
   Keep inherits it (`of_Waft:<path>` breaks on a Waft rename). Minimal move: commit the
   Keep to **loose, path-tolerant locators now** (match by value, not path) so it isn't
   *blocked*; the full caretaking pass is its own later work serving all three.

**My recommendation for the bundle:** the spine refactor + **#1, #3, #7**, plus
**stored/snapped `kind` + the on-load kind-sweep** (gap 1 — without it the
autoviv-Funkcion story doesn't actually run). #1 un-blinds the Keep; #3 makes it
remember; #7 stops the locator forking. #2 falls out of #1. Hold #4/#6 for a follow-on,
and #8 too — but commit the Keep to loose locators now so #8 never blocks it.

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

**Each phase ships an integration Book** that drives it headless (the `Story_cli` /
CredRunner family) — focus-switch, cursor-resume, kind-classification as steps — so the
spine is *shown off*, not eyeballed. A `LakeKeep`-style Book is the gate, authored
alongside, not after. (timemachine's hidden complexity is the argument *for* this.)

---

## Decisions (settled)

- **D1 — transport:** DROP the whole thing (play/pause/step). Time/sequencing → a later
  *director* layer, away from the editing code (see *What drops*).
- **D2 — scope:** all at once — spine + kind-table (#1) + minimise (#3).
- **D3 — the `%Lango` push (was step-4 `src`):** KEEP Lang's push. It's the bare
  "look-at-this, move the show here" signal — mostly fired from Lies on a UI:Waft click —
  naming no Interest; Keeping resolves one. **Introduce the term `%Lango`** for this
  push-what's-focused event (today `e_Lang_workon_update`), gently.
- **D4 — doc home:** standalone `Keeping_spec.md`; borders `Cluster_design.md`.
- **D5 — name:** `req:Keeping` confirmed.
- **D6 — kind-table home:** on the **Waft**, realized as `{capability flags + an
  autovivified Funkcion}` (the Funkcion is the kind's startup pathway). `%Interest` is a
  projection. `boring` becomes one kind (Cluster); the Keep gets its own visible kind.
  (see *The kind-table*).
- **D7 — name the bridge (settled):** split along the inward/outward (ownership) axis,
  and the **Curse family names the cursor's two faces**:
  - **`LiesKeep.svelte`** (new) — the Lies-side authority: `req:Keeping` driver, focus,
    the Keep ledger (the `Lies_keep_*` helpers migrate here from `Lies.svelte`). Owns
    *Lies* particles (Waft, Keep).
  - **`LangHold.svelte`** — `LiesHold` renamed. *Lies code that holds Lang's particles*:
    `Lang_set_interest`, `req_understanding`, the per-Interest LE arming, the
    ingredients/instrumentation stages. `LiesKeep`'s converge step calls into it.
  - **`LangCurse.svelte`** — `Interest.svelte` renamed. The Lang-side attention/cursor:
    the `interest_*` reducers, the roster, LE-bind, the strip projection — twin of
    **`LiesCurse.svelte`** (the substrate cursor). `LiesCurse` = where you are in the
    document (Spotlight); `LangCurse` = how the view shows it (Interest). (`LiesEnd`
    LE-mechanics fold into `LangHold` or stay.)
  - Beats "LiesHold + LiesEnd" because the cut follows ownership, not chopping. **Header
    comments now; the renames land when we cut Keeping** — one mechanical move, once.

---

## What stays Lies — and dissolving Spotlight (a later cut)

With Interest taking attention, what's left on Lies? Not a hollowing — a *resolving*.
**Lies is the substrate**:

- the **Waft document model** (Waft/What/Doc/Point — stays in `Lies.svelte`) and the
  **Waft helpers** (open/close/spawn/save/walk/`Waft_src_doc`) — the nouns + lifecycle;
- **storage** — `req:Store` (Wafts, gen, docks ↔ disk);
- **the compile/run machine** — `req:Cortex`/`Codebit`/`Rundown`/`BlatDo`
  (`LiesCortex`/`LiesRun`);
- **the Keep** (`LiesKeep`) — persisted attention;
- **the runner role** — acquire + run (Creduler/Peeroleum), lean, no attention.

What *migrates* to Lang is exactly one thing: the **cursor/attention projection**
(foreground, live position, the convergence driver) — the `LangHold` + `LangCurse`
carve. Interest takes *attention*, never the substrate. Final cleave: **Lies = nouns +
lifecycle (document, storage, compile/run, persistence, runner); Lang = attention + view.**

**Dissolving `Spotlight` — yes, but later, and anchored right.** `%examining/Spotlight`
is today a *fifth* attention claimant (a runtime cursor ref). It can go — but the trap is
moving its truth onto Interest (Lang), which inverts noun/projection (the *view* owning
the cursor; close the view, lose your place). The right anchor: **the cursor's durable
truth is the Keep ledger** (Lies, persisted — its `%Cursor` head IS "where I am"). Then
`Spotlight` (runtime ref) and Interest's `in_Doc`/`in_Point` (view projection) are both
*ephemeral projections* of the Keep head — and `Spotlight` degrades to a derived live-ref
cache, or vanishes (resolve address→ref on demand, the `Lies_locate_in_waft` path the
Keep resume already uses). The document still owns the cursor (via the Keep); the view
shows it.

**Scope:** a SEPARATE, deeper cut than Keeping — it touches every `Spotlight` reader
(`Lies_focus_waft`, the want-land seam, havoc's `engaged_what`). Do NOT fold it into the
Keeping build. Sketch now; cut after Keeping is proven and the Keep is the demonstrated
cursor-truth. (Phase 5+.)

---

## Where it could still break — second-pass gaps

Found on a critical re-read. (1) + fold-in #7 are real added scope; (2)–(5) are
corrections already folded into the shape above.

1. **The background-kind Funkcion has no carrier — the real gap.** Keeping is
   *attention-only*; a background kind (Cluster) is *never focused*, so Keeping never
   touches it — and there's no precedent (the Ting's behaviour is re-spawned each
   session, never loaded from snap). So **`kind` must be a stored, snapped sc field**
   (known at load, before any focus), and a **w-level on-load sweep** must read
   `waft.sc.kind` and ensure its Funkcion — generalize `Lies_keep_boot` (exactly this,
   hand-written for one kind) into a per-kind boot driver. That sweep is the autoviv
   "pathway in," and it lives *beside* Keeping, not inside it.
2. **Boot is staged, not one-shot** (fixed in step 1): the Keep loads async, so boot is a
   heartbeat that finishes when the resume lands — a maz:9 one-shot finishes before the
   Keep arrives.
3. **Keeping spans maz 9→1**, not flat: acquire-gate (maz:9, before Store) + converge
   (~maz:1, after Store's reads). One *owner*, maz-leveled children — the 5-step walk is
   the logic, not the maz order.
4. **Recording is event, not poll:** the want-land records into the Keep
   (`Lies_resolve_wants → Lies_keep_note_cursor`), exactly when the cursor lands;
   Keeping's tick only reads (step 5 reworded).
5. **Non-goal — in-flight edits don't resume.** The working clone is re-pulled from
   origin on reload; the Keep restores cursor *position*, not an unsaved edit. Stated, so
   it's a decision, not a silent gap.
