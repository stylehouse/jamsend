---
name: shared-runner-bleed
description: "On a SHARED/contended runner, back-to-back runner_ask sweeps BLEED (other agents' books' output interleaves) → false-reds/empty verdicts; resolve with clean SOLO re-runs + uid-consistency checks"
metadata:
  node_type: memory
  type: project
  originSessionId: 334456e9-f1e5-4e61-a0c4-7b0aaa37eec7
---

The ★claude runner (`49dee91d61a9de64`) is often **shared** — other agents run their Books on it
 concurrently (2026-07-21: the Vyto agent's `VoroTest`/`Stuffing` runs bled into my Musu\* sweeps).
  Under that contention `runner_ask run <B> --watch` misbehaves:

- **Output bleed:** a capture for Book B contains `"book":"VoroTest"` / another uid's lines; the
   kickoff line can even echo a *different* running Book's uid. `grep | tail -1` then reports the
    WRONG Book's verdict (a green looked empty, a neighbour's `0.09` looked like B's red).
- **False-reds:** `runner_ask` exits 1 (or shows `rc=1` beside `ok:true`) when it hits "runner
   refused (busy) — insisting N/5" retries or a DEAD_MS-ish stall — NOT a real Book red. Heavy
    real-audio Books (MusuRadio/MusuTune) are most prone.

**How to get a trustworthy verdict:** re-run the Book **SOLO**, and confirm (a) the kickoff `"book"`
 matches your target, (b) only that book's labels appear, (c) the FINAL `phase:done/failed` line's
  uid == a real run with `total>1` (total:1 = a wedge/no-real-run tell), (d) `ok_pct`. A batch sweep
   is fine for a first pass, but every RED or empty it reports must be re-checked solo before you
    believe it. ALWAYS `--runner=<full-prepub>`. Related: [[runner-watch-false-red]],
     [[runner-wedge-begun]], [[verify-via-live-runner]], [[musuheist-preexisting-red]].

**Scripted-sweep lessons (2026-07-23, night-2 leg — burned two attempts + a wedge-heal):**
- **NEVER wrap a sweep driver in a tight `timeout N`** (e.g. `timeout 560 node sweep.mjs`). If it fires
   mid-run it SIGTERMs node while a Book is stepping → leaves the tab **begun-wedged**: ping then reads
    `running:null` (looks idle!) but every subsequent `run --watch` hangs with ZERO done frames (a whole
     `0/15 NO-DONE-FRAME` sweep). Heal = `runner_ask reload` → poll `running:null` → burn a cheap green
      (Stuffing done ok_pct 1). Give the driver its OWN time budget (run_in_background, no wrapper) with a
       per-book `execFileSync` timeout instead.
- **A scripted driver MUST verify uid-consistency, not just the `book` field.** On the shared runner a
   `run Stuffing` accepted as uid `0474ed20` can return a done frame for uid `a6628189` (a *neighbour's*
    Stuffing) — book matches, uid doesn't. Capture the accepted uid from the `run:{...}` kickoff line and
     require the `phase:done` frame's uid to equal it; else it's bleed, re-run solo.
- **Print results INCREMENTALLY** (append per-book to a file + stdout) so a kill keeps partial progress;
   a driver that only prints its table at the end loses everything on SIGTERM.
- Tell that the Vyto agent is actively sharing: `run --watch` prints `runner quiet Ns/20s (busy?)` and
   times out on quiet. That's contention, not a Book red — defer the automated sweep to a quiet window.

**`accept` BLEED — the dangerous one (2026-07-26, burned a Sounditron re-record):** `runner_ask accept`
 re-records **whatever run the runner CURRENTLY holds**, NOT the one you ran. On `49dee91d`, which doubles
  as a **live /BigSoundland tab running Sounditron as a RESIDENT wild probe**, the resident Sounditron run
   DISPLACED my held MusuHeist between my `run` and my `accept` — so `accept` re-recorded **Sounditron**
    (`accepting:6, book:"Sounditron"`), splattering live-environment noise (`Machine:56fbce44/Righto`, a
     materialised MusuThem crate) into `Sounditron/002-007.snap` + `Credulate/toc.snap`. A run displaces;
      accept grabs the current holder — so on a resident-probe runner, accept is a loaded gun.
 **RULES:** (1) IMMEDIATELY before `accept`, run `state`/`steps` and confirm `book` == your target AND the
  uid == your run's uid; a mismatch means it bled — do NOT accept. (2) NEVER `accept` on a runner that runs
   a resident probe (a /BigSoundland tab; Sounditron is one) — it will re-arm between your steps. Re-record
    needs a DEDICATED, non-BigSoundland, FSA-live runner. (3) If you DO splatter a foreign Book: it's
     recoverable IFF HEAD holds a clean copy — `git checkout HEAD -- wormhole/Story/<Book>/` restores it
      (the human had just committed a clean Sounditron in `ddc575fb`, so zero work lost). Verify the foreign
       Book's numbered `.snap` were clean at your session start before trusting the revert. See
        [[never-stash-shared-tree]], [[host-commits-midsession]].
