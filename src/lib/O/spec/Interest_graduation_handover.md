# Interest channel — graduation handover

The `%Interest` cluster + Lang↔Lies `waft_roster` channel is now graduated from the
in-test prototype into the real `w:Lies` / `w:Lang`.  The foundation is in and
verified live; this note is mostly about **what's next**.

## Where we are (the foundation — done, verified live)

- Reducers live in **`Interest.svelte`** (`interest_*` House methods).
- **Real subscription**: `Lang()` holds an eternal `req:waft_roster`, reconciles
  `req.c.roster` into `Languinio`, subscribes via `e_Lies_subscribe_waft_roster`;
  `Lies_waft_roster_pump` pushes the roster (§7: `req.c.roster` + `reqyoncile`).
- The editing checkout is **unified onto the foreground `{Interest:'Trail'}`** in
  `Lang_set_interest` (non-destructive; found by `c.LE`).  Editing works through it.
- **`Interesting` test** (`src/lib/O/test/Interesting.svelte`, 7-step snap) is the
  regression gate for the reducers.

(Full mechanics are in the code comments — `Interest.svelte` header, the test header,
`Lang_set_interest`, `Lies_waft_roster_pump`.)

## What's next (in rough priority)

1. **Multi-giver foreground arbitration + the Interest-switcher UI.**  The headline
   feature.  With several giver Wafts open there are several `{Interest:'Trail'}`;
   today `Lang_set_interest`/the readers fall back to the single `c.LE` Trail / first
   match (correct only for one giver).  Waft_spec §"Presence" specs the switcher: a
   horizontal strip of Interest buttons atop the MiniMap, driven by `%ActiveInterest`,
   crossfading `Trail ↔ Sidetrack` (only the foreground LE pushes — a write-mutex).
   Work: make `Lang_set_interest` target the ActiveInterest's giver-Trail (match the
   active dock's Waft, not just first `c.LE`), and build the strip UI.

2. **Reshape the `Interesting` test to drive the REAL channel** (LakeNets-style
   Plan/Prep) instead of the `InterLies`/`InterLang` stand-in actors — the original
   stated end-goal.  Makes the real `w:Lies`/`w:Lang` channel the regression gate.

3. **Real Sidetrack origination.**  `interest_sprout_sidetrack` exists but only the
   test exercises the reverse arrow (Lang sprouts a Sidetrack → Lies opens a tentative
   Waft → binds on return).  Wire it into real `w:Lang` (a user action / nav gesture).

4. **Light-kind lenses actually render.**  `Ting` (presence:always, heat) and
   `GhostList` are reconciled into `Languinio` but their lenses (DocTing, DocGhostList)
   need to mount and render — the family is only useful past Trail once they do.

5. **surprise_read resume / diff UI.**  Pull-before-push *detects* an external-edit
   conflict and stashes (`good/%surprise_read`) but nothing resumes it — needs a diff
   widget + "keep mine" / "take theirs" (see `Waft-palmtree-trajectory.md`).

## Gotchas (durable, bit us this run)
- **`o({k:1})` wildcards on value** — numeric `1` matches ANY value for key `k`
  (`Stuff.svelte.ts` `n_matches_kv`).  Use `o(exactly({k:1}))` for exact value 1.
  When promoting a value-1 particle to a typed value, audit every `o({key:1})` reader.
- **Source files round-trip through the app codec** — template-literal separators get
  NUL-normalized (`${a} ${b}` → `${a}\0${b}`), so `Edit` matches fail on those lines;
  anchor on NUL-free code (or `od -c` the line).
- **`grep` is a wrapper** (ugrep `--ignore-files`) that silently skips ignored/binary
  files — use `command grep -a` for reliable source search.
- **svelte-check noise** — pervasive `Property X does not exist on type 'House'` is the
  dynamic `eatfunc` typing; ignore it, scan for OTHER error kinds only.
