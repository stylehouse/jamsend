---
name: new-book-cli-record-recipe
description: "Recording a BRAND-NEW Story Book green from the CLI (no interactive app): 'new' mode is interactive-only (total starts at 1), so hand-author toc.snap with dige:lie step lines AND byte-identical Assertion lines, run→accept→re-run green; and a NEW/modified .g method needs a runner RELOAD (HMR won't re-mix it)"
metadata: 
  node_type: memory
  type: reference
  originSessionId: e43c7849-f21f-4d35-a0f0-d8fec18a4fa2
---

Learned 2026-07-22 building the SwarmChain Book. Two non-obvious gates when standing up a
 BRAND-NEW Book (a new ghost in an already-enrolled `.g` file) and gating it via `runner_ask`:

**1. 'new' mode is INTERACTIVE-only — the CLI can't drive it.** `run.sc.total` starts at **1**
 (Story.svelte ~1522) and 'new' mode stops at `n > (total ?? 30)` — it's the app's "build up
  step-by-step via Resume" path. So a CLI `run` on a Book with no toc records only step 1
   (`total:1`, trivial green) — the SAME signature as a stale-gen empty run, so don't confuse them.
    The non-interactive record path (the [[force-clean-rerecord]] shape, made concrete):
  - **Hand-author `wormhole/Story/<Book>/toc.snap`**: header (`story:<Book>` / Styles / Plan /
    Opt / For) + `step,dige:lie` (step 1) + `step=2,dige:lie` … one per beat. Under each step that
     swears, add `    Assertion:<slug>,sentence:<full sworn text>` (4-space indent). The `<slug>` is
      cosmetic — the match is by **sentence, byte-identical** to the `story_swear(w, '…')` call
       (em-dash `—` as UTF-8, NO commas — the peel splits on them).
  - `run <Book> --watch` → RED (every dige ≠ 'lie') but the outcome has **no `gaps`** if the
    assertions all sworn+declared (`assertions` shows `declared N, sworn N, gaps 0`). Gaps present =
     a real functional bug (a truth didn't hold), NOT a fixture issue — inspect `snap <n>`.
  - `accept` → records real diges + `NNN.snap` fixtures, preserves the declared Assertion lines.
  - `run --watch` again → GREEN. Re-run a 2nd time for [[shared-runner-bleed]] safety (uid-consistent).
  - Register the Book on `wormhole/Credence/toc.snap` under its `What:` group:
    `Funkcion:Storying,of_Book:<Book>,born:<date>,brand_new:1,desc:<no-commas>` — `brand_new` auto-strips
     on first green (LiesFunk.svelte). No `CREDULER_GHOSTS` edit if the `.g` FILE is already listed;
      dispatch + toc are automatic (Story_subHouse world-name `do_fn_for`).

**2. A NEW or MODIFIED `.g` method needs the runner RELOADED to take effect.** `ghost-compile`
 writes gen to disk, but the live runner tab bound its methods at acquisition — HMR does NOT re-mix a
  brand-new method (nor reliably a changed body) into the live House. `node scripts/runner_ask.mjs
   reload --runner=<prepub>` then poll `ping` for `channel:up` before re-running. (Tell: a brand-new
    Book runs `total:1` trivially green until you reload — see [[gen-crosswire-runner-dead]].)
  Two gotchas re-learned 2026-07-27 (VytoWeb): (a) `ghost-compile` can report "no response in 12s /
   0 compiled" and genuinely NOT have compiled — retry until it says `1 compiled`, then VERIFY with a
    grep on the gen `.go` for the new symbol before reloading (a stale-gen run reds with `sworn 0`);
     (b) `reload` (and every op) WITHOUT `--runner=` hits the DEFAULT runner — someone else's live
      tab on the shared fleet. ALWAYS `--runner=`; a reload also mints a fresh runner self-id.
       And the `--watch` tail's RED banner can be stale — `state`/`assertions` are authoritative.

**3. Multi-hop mail drains ~1-2 frames PER BEAT** ([[transport-frames-post-do]]): a Book beat that
 fires a >2-frame exchange (e.g. a 6-frame ReInvite chain) leaves the witness reading a half-settled
  world → assertions absent. Fix in the Book's pump: DRAIN to a fixed point in a **bounded** loop
   (`while guard<24 { pump all accounts; break when no undone frame }`) so the whole exchange completes
    in the beat that starts it — never an unbounded await in a beat ([[sounditron-wild-book]]).
