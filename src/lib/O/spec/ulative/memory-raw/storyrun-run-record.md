---
name: storyrun-run-record
description: Storyrun:<ident> — the durable on-snap run-record on w:Lies that both rungo (dock) and become_book (Book) runs now land on; the runner-side noun the two under-designed triggers were missing
metadata:
  node_type: memory
  type: project
  originSessionId: 5856ad5e-04a8-49ab-af3f-c1f5d9b62cc5
---

The runner had a verb but no noun: `rungo` (editor→runner GO command, dock-keyed by path+dige,
LiesLies `Lies_send_rungo`/`req:rungo`) and its Book sibling `become_book` both drove a Story run
but tracked it only off-snap (`w.c.awaiting_verdict`) + fire-and-forget `run_phase` blips. So
`Lies%runner/*` showed the compile machinery (Cortex/Codebit/Rundown) but nothing saying "running
PereStaple, step 4/9." The human's word: *"it's a bit under-designed feeling."*

**Built (LiesFunk.svelte + LiesLies.svelte):** a durable particle **`Storyrun:<ident>` directly on
w:Lies** (sibling to req:Cortex — NOT inside it; NOT a %req: a tracker has no do_fn, and an
un-finished req under w would halt Cortex's pump via `level.some(needs_work)`). ident = Book (become_book)
or dock path (rungo). Phase lifecycle `begun → stepping → done|failed`, with `n`/`total` filled in as
steps land. Three write points, all in LiesFunk:
- `Lies_runner_begin(w, ident)` — mints fresh + keeps a bounded HISTORY (last 3 finished, drops stale
  begun/stepping); stamps a short `uid` + `w.c.active_rungo`; called from `Lies_become_book_drive` AND the
  rungo FIRE in `req_rungo` (LiesLies ~608, beside awaiting_verdict). (Was: dropped ALL prior — see uid §.)
- `Lies_runner_track(w, phase, extra)` — called FIRST in `Lies_runner_phase` (role-agnostic, before the
  runner/channel gate) so the record fills even with channel down / bare-dev Lies. Maps the blip arc
  (rungo_ack|story_begun→begun, step_done|step_stall→stepping, all_done→all_done) onto the record's phase.
- verdict stamp in `Lies_runner_verdict` — phase done|failed + done + caveat, wins over the all_done blip.

`Storyrun` is a fine new mainkey on w:Lies (snaps generically, exactly like the existing `run_result`
mainkey child there — NOT a protocol-gated wire mainkey). Runner-only state so no fixture pollution;
if a test ever snaps it, an EntropyArrest Entcase handles the `at`/n drift (cf [[trope-entropy-profile-sharing]]).

**Type-clean** (only baseline ghost-method/any noise). **Uncommitted, run-UNVERIFIED on :9091.**

**uid / "hangs in there" hold (2026-06-27, the human's design):** each Storyrun now carries a short
`uid` (8-hex of crypto.randomUUID) = the addressable handle; the run "hangs in there" after landing
because `Lies_runner_verdict` PINS each produced step `{n,ok,caveat,dige,got_snap,exp_snap,trace}` into
`sr.c.pins` — **off-snap** (`.c`, never encoded, so NO snap bloat), surviving the live This churn + the
5-step trim. SHAPE GOTCHA: `sr.c.pins` is a plain **Record keyed by step n** (like `w.c.exp_snaps`), NOT
`Step:` child particles — conceptually `Storyrun(uid)/Step:n→{got,exp?}` but don't grep for the particles.
A pin holds the snap-string by **reference, not copy** (just extends its lifetime past the churn). **1c
(exp over the wire) DONE 2026-06-27:** exp source = `Step.sc.exp_snap` (UI lazy) ?? **`w:Story.c.exp_snaps[n]`**
(the check-mode preload — EVERY step's expected in memory at run start, Story.svelte:1451; every fixture Book
runs check-mode). Folded into `Lies_rungo_steps` (live) + pinned at verdict (exp_snaps is wiped at the next
toc-load, L1409, so pin or lose it). Cuts the CLI loose from `wormhole/` disk; CLI falls back to the fixture
only when exp is null. NOT via the planned `fetch_snap` drive — that's a multi-round reactive Wormhole pump,
not awaitable in a request/reply handler. Memory: bounded ≤3 runs (`KEEP`), freed by FIFO eviction on the next
begin (`w.drop`→GC) or tab reload, NOT on CLI exit. Lives on the browser runner, ~low MBs. Two helpers in LiesFunk: `Lies_rungo_record(w, uid?)` (uid PREFIX-matched → that held run;
else active/latest via `w.c.active_rungo`) and `Lies_rungo_steps(w, ask)` (uniform per-step view: pins
when `ask.uid`, else live This). All `runner_ask` READ ops (steps/snap/snaps/diff/trace) take an optional
`ask.uid` → served from the pinned record; `run` hands back the new uid; new `rungos` op lists held runs.
CLI (`scripts/story_repl.mjs` + `runner_ask.mjs`): `run` prints uid, `rungos`/`rg` lists, append `@<uid>`
(bare `@` = last run) to any read to target a held run. Pin captures whatever survived the trim — pair
with `retain on` BEFORE a long run to pin every step. NEXT/owed: live `:9091` uid round-trip; real 1c
(force the fetch_snap exp read in the diff branch so a diskless CLI needs no wormhole fixture). Lives in
the `spec/Runner_talk_TODO.md` family (this is the durable hold the §1b "retain/hold" item wanted).

**NAMING GOTCHA:** "**Rungo**" the word already = the run-AUTHORITY token (`req:rungo,seq`,
`Lies_send_rungo`/`Lies_rungo_recv`/`req_rungo` in LiesLies) — the editor's GO permission, transient,
one-shot, superseded by higher seq. It is NOT the run-record. The human asked for "a %Rungo particle";
the addressable run-hold was built on the existing **`Storyrun`** record (give it a uid) to avoid a second
clashing "Rungo" meaning. uid = the noun you "talk to," whatever the particle is named.

Diagnostic bonus: this also answers the original "why doesn't the runner get on with the job anymore?"
— I found NO actual breakage (become_book arrives per relay logs; recv→drive→resetStory→auto_reset_story
→think chain intact; the old `throw "forgot A"` landmine is FIXED at Auto.svelte:320-326; our BlatDo fix
[[blatdo-drive-rundown]] is committed in `ab35e729` and lives off the become_book path). The Storyrun
record now makes a stall self-evident: a frozen `phase:begun` = resetStory/think never landed; a frozen
`stepping` n/total = a step wedged. NEXT = a Liesui/Brink face reading Storyrun (the [[upkeep-errand-brink]]
%Errand pattern); maybe fold awaiting_verdict's path/dige onto the record too. Note LiesFunk is in flux
([[lieswaft-dynamic-web-home]], renamed from LiesWaft 2026-06-25, untracked).
