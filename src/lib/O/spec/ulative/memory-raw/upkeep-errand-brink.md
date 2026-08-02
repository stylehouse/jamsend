---
name: upkeep-errand-brink
description: "%Upkeep/%Errand background-work layer at the Brink + StoryTimes pass-based retry sweep"
metadata: 
  node_type: memory
  type: project
  originSessionId: 9e3dbb8f-9bbc-47ee-ac57-34c8fb9daac7
---

**%Upkeep** = the named opposite pole of **%Interest**: work the machine owes ITSELF (endpoints up, Books green, ghosts compiled), surfaced at the Brink, never courting attention. Its units are **%Errands** — transient work-items that pop up while live and fade once settled. Named this session after "Aim" was judged a mistake for orchestration (Aim/Waft:Cluster stays the clean endpoint layer = Runner/Relay; build churn does NOT go there). Built 2026-06-24, **browser-UNVERIFIED**, type-clean (modulo baseline House-noise).

Pieces:
- **Ledger** is ambient on `top_House().ave.{Upkeep}` (off-snap, like the Lenses bag — NOT in any Waft, keeps Waft:Cluster clean). Helpers in `LiesWaft.svelte`: `Upkeep_bag()`, `Upkeep_errand(key, sc)` (oai-upsert keyed `Errand:<key>`; phase running|ok|failed; non-running stamps `settled`), `Lies_upkeep(w)` (hoist/retire the Brink by live-errand presence, GC settled >8s). Called each beat from `Lies_heartbeat` right after `Lies_aim(w)`, before the channel gate.
- **Face** `O/Funk/Upkeep.svelte` = `FUNK_KINDS.Upkeep.comp_Brink` (kinds.ts), hoisted as `Lens:Brink,of_Funkcion:Upkeep` altitude 10 (atop Runner 20/Relay 25). Reads the ambient ledger directly (no funk); 1s local tick for fade (the Runner/Relay bomb-1 pattern).
- **Source 1 — ghost-compile**: `Lies_ghost_compile_recv` mints `compile:<path>` running; `Lies_ghost_compile_ack` (started/done/error) maps to running/ok/failed (above its ws gate). LiesLies uses `(H as any).Upkeep_errand`.
- **Source 2 — StoryTimes sweep** (the original ask): `Lies_storytimes_drive` mirrors to `sweep:<scope>`.

**StoryTimes sweep is now pass-based + retrying** (the multi-thing-run feature is StoryTimes's own job — NO new Funkcion:Aim, NO board change). CONFIRMED WORKING (user: "StoryTimes orchestrating a run of Storyings"). funk.c.sweep gained `books`(roster)/`scope`/`pass`/`retries:2`. Pass 0 attempts every Book once in order, never spinning on an !ok (moves on); then ≤2 retry passes over just the not-green ("try later, come back to earlier"). Q2 answer drove the pass model: "don't retry each book before the sweep completes, then retry twice."

**"Jettison runs from memory" = runner-side Story_reset, NOT dropping verdicts** (corrected — my first `w.drop(rr)` read was WRONG and is removed). Each dispatch is a `become_book` → `Lies_become_book_drive` → `Auto/resetStory` → `picks_a_book`/`auto_reset_story` which TEARS DOWN + rebuilds the runner's prior Story. So shooting the next Storying frees the last run; runs don't pile up ("tons of runner chrome tabs"). The sweep inherits this for free — nothing extra to add. The editor-side `run_result` verdicts are KEPT (Storying cells read them). `s.results` flips fail→pass for StoryTimes.svelte's tally (minor: done can read N/N mid-retry).

**Speed: self-trickle while running** (was "super slow, relies on trickle"): the sweep advances one step per Funkcions-pump tick (LiesStore Phase 2b), which when idle only re-fires on the 3s heartbeat. Fix = `w.c.sweep_trickle` setTimeout(150ms) → `H.i_elvisto(w,'think')`, one-per-w, re-armed each running tick, abandoned on settle — the creduler_trickle/req_rungo pattern. A landed verdict now reaps within ~150ms.

Relates to [[lens-primitive]] (Brink/%Aim — now stale on Runner-as-Panel), [[editron-verdict-phase2]] (run_result/become_book wire), [[entropy-samples-fuzzok]] (caveat-as-ok ⇒ green counts). Next: verify on :9091 (strike "run Lake" → Brink sweep Errand + retries; a CLI ghost_compile → compile Errand); maybe an Upkeep traffic-light aggregate; InterestSmall/Big pop-outs still unbuilt.
