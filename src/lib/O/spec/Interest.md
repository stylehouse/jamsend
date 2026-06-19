# Interest — the Lang↔Lies attention channel

The `%Interest` cluster + Lang↔Lies `waft_roster` channel is graduated into the real `w:Lies`/`w:Lang`
 and verified live. **Interests are attention channels: the IDE escalates state *through* them.** This
  doc merges the three former Interest handovers (graduation, the real-channel reshape, the surprise
   popover) into one: **foundation → the real channel end-to-end → the implemented items & phases →
    the popover/havoc surface → the metromap future → gotchas**.

Interest is the **UItime expression** of the `%subscribe` wire (`Wire_spec.md`); Editron is its Atime
 sibling — they share the subscribe/wake vocabulary, not a merge. The general push-dual-of-pull
  destination is **Hovercraft §7 (Subscriptions)**: one `%subscribe{target,on,wake}` primitive unifying
   Stuffing / watched / `%Good/%subscribe`.

## 1. Foundation (done, verified live)

- Reducers live in **`Interest.svelte`** (`interest_*` House methods) — pure logic over plain C,
   unchanged by the graduation; they are what `interest_reconcile` / `interest_foreground` /
    `interest_sprout_sidetrack` run.
- **Real subscription:** `Lang()` holds an eternal `req:waft_roster`, reconciles `req.c.roster` into
   `Languinio`, subscribes via `e_Lies_subscribe_waft_roster`; `Lies_waft_roster_pump` re-pushes when
    `interest_roster_sig` moves.
- The editing checkout is **unified onto the foreground Trail** in `Lang_set_interest` (non-destructive;
   found by `c.LE`). Editing works through it.
- **`InterestLive` Book** (`wormhole/Story/InterestLive/`, 11 Preps) is the sole regression gate; the
   `Interesting`/`InterLies`/`InterLang` stand-ins were retired 2026-06-17.

## 2. The real channel, end to end

- **Lang** (`Lang.svelte`): `Lang_plan` seeds `w/{Languinio:1}`. On every tick it holds the eternal
   `req:waft_roster`, whose do_fn calls `interest_reconcile(languinio, req.c.roster)`, and on first run
    hands the req to Lies via `i_elvisto('Lies/Lies','Lies_subscribe_waft_roster',{req})`.
- **Lies** (`Lies.svelte`): `e_Lies_subscribe_waft_roster` stashes the req in `w.c._waft_subs` and
   pushes once; `Lies_waft_roster_pump` (called each tick) re-pushes when `interest_roster_sig` moves.
- **Foreground** is NOT a standalone call on the real wire — it is a side effect of the editing
   checkout: `req_understanding` re-arms on cursor-src change and calls `Lang_set_interest`, which locks
    the foreground Trail and sets `ActiveInterest`. So "foreground a giver" == "land the cursor on that
     giver's Point".

Real Waft **stances** (input to `interest_stance_of`):
- giver / `active` (→ Trail): a plain opened Waft, or `Lies_spawn_look_waft` + `sc.active`.
- taker / `takes` (→ Ting, presence:always): `Lies_spawn_ting_waft`.
- lister / `lists` (→ GhostList): the GhostList singleton Waft.
- tentative (→ Sidetrack): a Waft opened by a sidetrack request.

**The Crux — RESOLVED (verified live 2026-06-17).** An old `LakeNets/001.snap` recorded `Languinio`
 carrying a single `{Interest:in_Doc:…}` rather than the `Interest:Trail,…` family; that snap was simply
  **stale** (predates the Trail unification). A live `InterestLive` run confirms the real wire emits the
   full family (Ting/Trail/GhostList + `ActiveInterest`) and `interest_reconcile` mints it correctly.
    The recorded LakeNets/LakeFlush expected snaps are the intended improvement, not a regression — the
     human re-records.

## 3. Implemented items & phases (all 2026-06-17, verified live; human re-records snaps)

**Item 1 — multi-giver foreground arbitration + the InterestStrip switcher.** On checkout,
 `Lang_set_interest` binds the giver-Trail whose Waft matches `waft_key_of(armed)` — each giver
  foregrounds its OWN Trail. It moves the single LE off any other Trail (exactly one bears `c.LE` =
   foreground), demotes the giver you left to `state:pending`, records the foreground on
    `ActiveInterest.waft`. `e_Lang_foreground({kind,waft})` is the switcher click: heavy kinds
     (Trail|Sidetrack) set `ActiveInterest` eagerly then route to Lies `foreground_waft` to re-checkout;
      light kinds (GhostList) are a pure lens swap. `InterestStrip.svelte` (atop the MiniMap, mounted in
       `DocMinimap`) shows one button per **presence:active** Interest, highlights `ActiveInterest`, `×`
        dismisses (drops the Lies Waft → gone). Light kinds lock/mount their lens but do **NOT** become
         `ActiveInterest` — only Trail|Sidetrack take the stage and drive the canonical cursor
          (Waft_spec §Presence). Add-Interest dropdown still unbuilt.

**Item 3 — real Sidetrack origination (the reverse arrow).** The reducers were there; this added the
 drivers. `e_Lang_sprout_sidetrack({from})` sprouts the pending, unbound Sidetrack Lang-side (lens
  chosen, cursor off-anchor, `%from`=anchor, no `%waft` yet). `e_Lies_open_sidetrack({from})` mints the
   throwaway **tentative** Waft `<from>/side` (in-memory, session-only, modelled on the Ting); the roster
    sig moves → re-push → `interest_reconcile` binds the pending sprout by `%from`. `Lies_waft_save` is
     save-exempt for `tentative` (no disk home until it grafts back). `InterestStrip ↳` sprouts a
      Sidetrack off the foreground Trail in one gesture. Foregrounding a Sidetrack works in place (cursor
       is `off_what`, routed via `interest_foreground`).

**Phase A — dual-LE crossfade (the headliner).** *Was:* exactly one Understanding `w/{LE:1}`;
 foreground-switching re-armed it onto the new target and **discarded the previous working clone** (the
  in-flight `class:focus` edit vanished on switch and was lost on switching back). *Now:* the LE is
   **per-Interest** — each open giver carries its own `w/{LE:<waft_key>}` (keyed by the giver Waft so
    several coexist; parented under `w`, outside any `replace()`, so it survives checkouts), held on its
     Interest's `c.LE`. The foreground LE resolves via `%ActiveInterest`, not a singleton. Switching
      foreground **reuses the giver's preserved `Seem:working` clone** instead of re-pulling.
 Mechanism — **two-level arm gate:** `req.c.armed_src` gates "did the cursor move"; the per-LE
  `LE.sc.target` gates "does *this* LE need arming". On a switch, `req_understanding` calls
   `Lang_set_interest(w, want)` and **arms only if `LE.sc.target !== want`** — so switching back to an
    already-edited giver skips `LE_arm`/`LE_pull` and the working clone (with its drift) survives.
 Code map (all `Lang.svelte` unless noted):
  - `Lang_plan`: the singleton `w/{LE:1}` + `place` **removed**; workon no longer carries `LE`.
  - `Lang_active_interest(languinio)` / `Lang_active_LE(languinio)`: the foreground resolvers everything
     reads through. `active_LE` falls back to `languinio.c.active_LE` (so a light/LE-less foreground —
      GhostList, or a clone-less Sidetrack — leaves the last Trail's LE driving).
  - `Lang_set_interest(w, armed)`: **signature changed** (no LE param; returns the LE). Get-or-creates
     `interest.c.LE = w.oai({LE: waft_key})`; does NOT strip other Trails' `c.LE`; only demotes the ones
      we left `locked`→`pending`; sets `languinio.c.active_LE` + `bump_version()`. Now sync.
  - `req_understanding` / `req_workon`: drive `Lang_active_LE`, guarded for "nothing foregrounded yet".
  - `e_Lies_waft_mutated`: iterates **all** per-Interest LEs (`w.o({LE:1})` wildcards over them) and
     stales each whose target is in the mutated Waft.
  - Readers → active resolution: `LangGraft.svelte`, `Lang_Map_report`, `NaviCado.svelte` &
     `DocMinimap.svelte` LE derives (`$derived.by` on `languinio.vers`). `LE_for()` (`LiesEnd.svelte`):
      bare/`'Interest'` reason returns the active LE; named reasons (Undertaking) unchanged.
  - **Close → gone regression fixed Lang-side:** a giver whose Waft left the roster has its per-Interest
     LE retired (drop the clone + `c.LE`) so reconcile's gone-loop (which spares any `c.LE`-bearing
      Interest) marks it `gone`. Mid-bind and still-open demoted givers are spared.
 **Untouched on purpose:** the `Interest.svelte` reducers and `LE_arm/LE_pull/LE_push/Seem` mechanics.

**Phase B — lenses (item 4) — REFRAMED.** The handover premise (mount lenses Lang-side in the MiniMap,
 `ui/InterestLens.svelte`) was wrong, confirmed live (the Ting cloud in the minimap was "cool but not
  what I wanted"; the GhostList stub read "data pending" forever). The owner's model: **lenses live on the
   LIES side with their Wafts; the Lang side only switches them (InterestStrip).** `InterestLens` was
    reverted/deleted. What shipped instead: `Lies_order_wafts(w)` — the ambient taker **Ting sinks to the
     bottom** of the Waft list (`w.place({Waft:1}, sorted)`, identity no-op when ordered) so a giver and
      its Ting read top-then-bottom in one viewport.

**Phase C — polish.** Distinct doc per giver (`Interestily`→`Peeroleum.g`, `Interestily2`→
 `Peregrination.g`, so foregrounding Interestily2 visibly switches the active dock). Drop-a-gone-Interest
  one step later (the ghost row), Lang-side and **gated on a roster EPOCH, not do_fn invocation** (the
   do_fn re-drives every settle tick with the same roster; bump `languinio.c.roster_epoch` only on a real
    push, stamp `it.c.gone_epoch ??= epoch` on freshly-gone rows, drop a row whose `gone_epoch < epoch`).
     All off-snap (`.c`).

**Determinism — the remaining blocker for a byte-stable gate.** Fixed: the pure key-value timestamps
 (`Good/known…at`, `Waft…seeded`, `Funkcion…walked_at`, `Doc…noticed_at`) are munged via central
  `story_matching`. **Still non-deterministic** (mainkey-VALUE timestamps, can't mung via `these_sc`):
   the **Ting waft name** `Ting/YYYY-MM-DD/HHMMSS` (recommend teaching `Lies_spawn_ting_waft` a fixed
    name under the Story runner for real Ting coverage), and `want=<ts>` rows + `time,compile`/`Change`
     durations (tolerated re-record noise; deferred to a future general Story revamp for timing/intent
      noise — see [[story-step-lines-drive-steps]]).

## 4. The surprise_read popover & havoc — the first attention-channel inhabitant

The through-line: a surprise_read (external edit conflict on an open Doc) **pops out of the Interest
 channel** — the giver Trail that owns the Doc is the natural place for the IDE to escalate "something
  big wants your attention." The Doc/`%Good` is *acquired separately* from the Interest (Good under
   `req:Store`, Interest is a Lang-side roster row) — but the *attention escalation* belongs to the
    Interest. The popover is the first inhabitant of the pattern the metromap later generalises.

**Done — the foundation (keep it):**
- **Backend stash** — `req_LiesStore_writeCarefully` stamps `good/%surprise_read` on an external-edit
   conflict: `sr.sc.text` (mine, on-snap), `sr.sc.dige`, `sr.sc.disk_dige` (theirs'), `sr.c.disk_text`
    (theirs, off-snap, re-fetched on reload).
- **Resume legs** (`Lies.svelte`): `e_Lies_surprise_keep_mine` (`LiesStore_write(sr.sc.text)`, drop
   stash; Phase 1 re-stamps `/known` so the next auto-save sees no divergence); `e_Lies_surprise_take_theirs`
    (drop stash, `delete good.c.content`, re-land disk text in the open editor).
- **Inline UI** — `ui/DocRow.svelte` conflict row (⚠ + keep/take + diff toggle); `ui/DocDiff.svelte` is
   a plain DMP line diff (theirs→mine), deliberately NOT `H.compute_diff` (that's snap/peel-normalised; a
    Doc is opaque source). The inline row is the fallback/proof.
- **Auto-pull when there's no local divergence:** on pull-before-push, if disk diverged but the buffer
   still equals the baseline (`dige === base_dige`, no local edits), pull theirs silently instead of
    stamping a surprise_read. The popover is raised only when there ARE local edits. (Fires on a *save*;
     a standalone disk-refresh poll would be the fuller version — still a Doc-only exception vs the §7
      general push.)

**Built — the popover:**
- `ui/SurprisePopover.svelte` scans `w:Lies/req:Store` Goods for the first `good/%surprise_read` (reaches
   w:Lies via `H.ave`'s `%examining.c.w`, the seam Liesui uses, so it stays live without a parent
    re-render). Renders a Storui-flavour `Vexpandy popup={true}` (position:fixed, top of viewport, z-index
     500 — FaceSucker wasn't needed): ⚠ + path, keep/take, and an **escalate** ("go to Lies ↓") that fires
      `Dock_open` then `scroll_to_house(H)` after a 50ms layout settle (mirrors Storui's `go_to_diff`). Esc
       dismisses; resolving the conflict clears `good/%surprise_read` so the popover closes. No × kill.
- Mounted from `ui/InterestStrip.svelte`, rendered unconditionally with its own gate (pops regardless of
   whether any Interest caps show).
- **The reseat chain is the bomb** — fragile/non-obvious: Good → `LiesStore_drain_good_now` →
   `e:dock_content` → `Lang_open_dock` → **`req:Languish` never finishes** (eternal `req:text_mutated`)
    so it's never recreated → `e_Lang_dock_content` must *manually* bump `%Text.disk_rev` → Langui's
     disk-reload `$effect` → minimal-diff dispatch (`diff_to_changes`, so cursor/folds/scroll map
      through). Break any link and the open editor stops updating with no error.
- **Floating UI off the minimap MUST portal a single node** — `.lte-mm-host` (overflow:hidden) + `.lmm`
   (backdrop-filter) are containing blocks that clip/anchor `position:fixed`; portaling two Svelte-owned
    nodes corrupts the strip/minimap DOM.
- `examining.sc.active_path` is **DEAD** — active-doc truth is `H.Awo('Lang').c.active_dock_path`.

**Havoc — the drum-machine (dev test-triggers).** A **limb** is authored as content: a `%havoc`
 particle (`{havoc:<kind>}` + optional `emoji`/`hint`) dropped anywhere in a Waft tree.
  `Waft.svelte`/`waftitem` renders it inline as a strike pad (💥 + kind). The particle is pure config;
   behaviour lives in `Lies/HAVOC_LIMBS` (`kind → {run(H,w)}`), and `e_Lies_strike{kind}` runs it + wakes
    a tick. Add a limb = add a `HAVOC_LIMBS` entry. First limb `surprise_read` →
     `Lies_fabricate_surprise_on(w, path)` on the active doc. Havoc = config particle + code behaviour;
      the snap-vocab gate is parked so unknown mainkeys snap fine. See [[ballistics-drum-pad]].
- **Self-arming limbs — PARKED (known race; deprioritized).** A pad authored with `arm:1` strikes itself
   when its `What**` is looked at (`Lies_arm_engaged` climbs `src → containing What`, edge-triggers on
    `examining.c.engaged_what`, called from `Lies_i_Spotlight`). The race: firing synchronously in the
     Spotlight races the cold dock open (same cursor move opens the dock over later `req:Store` ticks), so
      `surprise_read` can fire before the `%Good` has content and silently no-op with no retry. **Run-level
       fix (deferred):** host the armed limb in the **Funkcion pump** — `req:Store` Phase 2b, after dock
        reads land, re-running every tick so it self-gates on readiness and retries; `maz`-leveled
         sequencing of those = the drum machine. See [[ballistics-drum-pad]], [[nested-req-needs-cup-stamped]].

**Still open (popover follow-ups):** move InterestStrip's `×` into `PeelInput` (a distinct UX refactor);
 tighten the escalate target from the whole Lang/Lies House header onto the Liesui sub-element.

## 5. The metromap & the lens "generalissimo" — the future picture (not now)

The popover proves the "Interest pops out big attention" mechanic. The picture the owner wants is a tiny
 **animated SVG metromap** of the two layers of Interest/Point working: (1) **Interestily sprouts the
  activeWhat** via an *obscured network*, then (2) the activeWhat **sprouts its Points**. Nodes carry
   **"elsewheres" that fold away** like a real folded metromap; the creased **horizon edges stay faintly
    readable behind the words**. No `×` (dismissal lives in PeelInput). This extends the InterestStrip
     switcher from a button strip toward a spatial channel map.

**The lens as UI-pluggability "generalissimo"** (the reverted `InterestLens` was too small):
- A **Lens is optional UI pluggability** — host the *meaning* of an Interest at Lang (or wherever), used
   only if something wants it, **driven by a property on the Waft** (`sc.lens` is the seed). Lies grows
    full UIs that strip back to the "unillusioned Waft"; via an Interest a thing offers a *tiny* UI.
- **Generalize the Lens into the placement router.** Many locations could host UI (multiple MiniMap
   slots, inline, elsewhere). The Lens system is the registry/router: an Interest declares *which slot* +
    *which tiny UI*; revive `InterestLens` as a multi-slot host, not a single mount. (The data-channel
     question returns then: ref-pipe vs ride-the-roster.)
- **Interaction:** double-click an Interest or a Point → opens its menu; build on/extend `PeelInput`
   (the controlled inline add/edit form for any keyed particle). Interest buttons read as `i`/`o`.
- **Per-kind menus** (a "DJ mixer for spraying notes around," not widgets yet): **GhostList** = a cluster
   of recent ghosts + a name search whose placeholders are **prefix boxes** for the current context (in
    `Ghost/N/` you search at `[Ghost/][N/][ ]`); **Ting** = a huge **time-trail** sorted into strata (the
     metromap); a **Pantheate controller** (the BlastPit run operation as an embeddable widget).
- **Remaining LE slice:** real **per-deck Sidetrack** LEs (a Sidetrack foreground still falls back to the
   last Trail's LE — no off-anchor clone of its own) and the true **simultaneous dual-LE push-mutex**
    (arming both a Trail and a Sidetrack at once). Both are the Sidetrack half of Waft_spec §Presence.

**Loose fancies (raised, undefined — capture when they firm up):**
- **Fold-into-chunks** — auto-cluster a method's *internals* into ~3 chunks: sub-method auto-chunking, a
   peer of the StemHive stem clustering but inside a body rather than across names. Granularity/trigger
    unspecified. (Lands as a lens/render concern over an engaged What — metromap-adjacent.)
- **"Scribbles"** — an annotation/marginalia layer over the doc. Undefined direction; a natural
   inhabitant of the attention-channel surface once it firms up.

## 6. Gotchas & code map

**Gotchas (durable):**
- **`o({k:1})` wildcards on value** — numeric `1` matches ANY value for key `k` (`n_matches_kv`). Use
   `o(exactly({k:1}))` for a literal `1`; audit every `o({key:1})` reader when promoting a value-1
    particle to a typed value. See [[o-query-wildcards-on-1]].
- **Source files round-trip through the app codec** — template-literal separators get NUL-normalized
   (`${a} ${b}` → `${a}\0${b}`), so `Edit` matches fail on those lines; anchor on NUL-free code.
- **`grep` is a wrapper** (ugrep `--ignore-files`) that silently skips ignored/binary files — use
   `command grep -a` for reliable source search. See [[grep-binary-spec-docs]].
- **svelte-check noise** — pervasive `Property X does not exist on type 'House'` is the dynamic `eatfunc`
   typing; scan for OTHER error kinds only.
- Don't hand-edit `step,dige:` / `TimeSpool` lines — the runner owns them ([[story-step-lines-drive-steps]]).
   Two agents share this tree — commit in passes, never blanket `commit -a`.

**Where the real-channel hooks live:** `e_Lang_foreground` / `e_Lang_sprout_sidetrack` (Lang.svelte);
 `e_Lies_foreground_waft` / `e_Lies_open_sidetrack` / `e_Lies_close_Waft` (Lies.svelte); `interest_*`
  reducers (Interest.svelte); switcher `ui/InterestStrip.svelte` (mounted in `ui/DocMinimap.svelte`).
   Per-Interest LE: `Lang_active_interest` / `Lang_active_LE` (Lang.svelte) are the foreground resolvers
    everything reads through; `Lang_set_interest` owns each giver's `c.LE`; `LE_for()` (LiesEnd) returns
     the active LE for the bare reason. Gate Book: `wormhole/Story/InterestLive/` (11 Preps + `step=`
      lines; fixtures Interestily→Peeroleum.g, Interestily2→Peregrination.g). Elvis names must match
       handlers verbatim ([[elvis-handler-name-verbatim]]).
