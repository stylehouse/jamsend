---
name: credence-board-desc-brandnew
description: "Credence board (wormhole/Credence/toc.snap) now carries What%desc per group + %brand_new on never-green Books; brand_new is AUTHORED (not computed) because run_result is TTL'd, stripped on first green in Lies_reflect_storying"
metadata: 
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

**The Credence board is a hand-authored dashboard** (`wormhole/Credence/toc.snap`, `Waft:Credence`) —
 it groups every Story Book into a What** taxonomy (Pere/Swarm/Musu/Lake/Leaf/Port/Stuff/Toy/Misc),
  each Book a `Funkcion:Storying,of_Book:X` test-light. Nothing machine-writes it (Editron.md calls
   keeping it current "soft — not sure how yet"); you edit the snap by hand like a fixture.

**2026-07-04 additions:**
- Every `What:` node got a one-sentence `desc:` (what that cluster tests) — grounded by reading the
   `-ation` .g sources (`Ghost/Story/{Peregrination,Swarmation,Musuation}.g`, `Ghost/test/Story/Lake/*.g`)
    and the per-Book `%witnessed`/`%see` claims. NOTE the assertion sentences live in the .g/selftest
     SOURCE, not in the Book toc.snaps (those carry only step/dige lines). desc values must have **NO
      COMMAS** (the snap splits key:value on commas — same rule as %see) — em-dashes are fine.
- `%brand_new` (rides `1`) authored on Books that have **never recorded a green run**. The durable
   signal for "never green" = **no numbered `NNN.snap` on disk** in `wormhole/Story/<Book>/` (a recorded
    green run IS the fixture). At install: SwarmWire, MusuGenerateTestsMusic, MusuMitosis, AwFloat, Educarium.

**Why brand_new is AUTHORED, not computed:** `run_result` is TTL'd (Liesui filters `rr_age < CRED_TTL`),
 so `storying_run`'s "no run_result → ◴ working" means *no RECENT run* — after a reload that's EVERY cell.
  A computed "never run" badge would light the whole board on load. So brand_new is a persisted authored flag.

**How it clears:** `Storying.svelte` renders `disp` = good✓ / bad✗ / new✦(amber NEW pill) / working◴ (a real
 red|green verdict beats NEW). The strip happens in **`Lies_reflect_storying`** (LiesFunk) right after
  `storying_run` — on the first `verdict.phase==='good'`, `delete k.sc.brand_new; k.bump_version()`. That's
   the run_result EVENT path, deliberately NOT inside `storying_run` (which is off-snap) nor the pump.
    Because the board is hand-authored, the strip clears the badge live; the human bakes the removal to
     disk on the next board commit. Related: [[story-books-catalog]], [[see-assertion-layer]], [[toc-clobber-expand-race]].

----
## merged from always-register-book-in-credence.md

---
name: always-register-book-in-credence
description: "Standing rule — every Story Book you create must be added to Waft:Credence (wormhole/Credence/toc.snap) as a Funkcion:Storying,of_Book:X under the right What group"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

**Whenever you create a new Story Book, register it in the Credence board** —
 `wormhole/Credence/toc.snap` (`Waft:Credence`) — as a `Funkcion:Storying,of_Book:<Name>` line
  under the What group it belongs to. If it has never had a green run yet, it also gets
   `,brand_new:1` (stripped on first green — see [[credence-board-desc-brandnew]]).

**Why:** the board is the hand-authored dashboard of every Book (nothing machine-writes it), so a
 Book that isn't on it is invisible to the human's at-a-glance credence view — it silently drops
  off the map. The user asked for this explicitly (2026-07-04): "make sure you always put Story you
   create into Waft:Credence."

**How to apply:** after authoring a Book (`.g`/selftest + its `Run_A_<Book>` dispatch), add its
 `Funkcion:Storying,of_Book:<Name>` line to the appropriate `What:` cluster in the Credence toc.snap
  (match the taxonomy — Pere/Swarm/Musu/Lake/Leaf/Port/Stuff/Toy/Misc); give the enclosing What a
   comma-free `desc:` if it's a new group. Related: [[story-books-catalog]], [[testing-is-story-books]].

**Placement (the music family):** the `MusuRa*` pipeline Books live under `What:Musu` → **`What:mostly`**
 ("the stuff we mostly do as jamsend the music app") alongside `MusuGenerateTestsMusic`/`MusuReco` — NOT
  loose directly under `What:Musu`. (2026-07-08: `RaStock`/`RaCast`/`RaTerm` were renamed
   `MusuRaStock`/`MusuRaCast`/`MusuRaTerm` — Books only; the shared ENGINE `Ghost/M/Ra.g` keeps its `Ra_*`
    names, the Books just drive it. Do NOT rename `Ra_*`→`MusuRa_*`.)

**THE CLOBBER GOTCHA (2026-07-08, learned the hard way — "you keep messing that up"):** a runner booted
 with a STALE Credence will, on every `story_save`, (a) REVERT your disk edit back to the pre-edit names
  and (b) auto-file any Book it ran but doesn't yet have registered into a LOOSE `of_Book:X` directly under
   the parent `What` (wrong indent, no `needsFSA`). The runner's LIVE board (Cyto/dashboard) shows that
    stale in-memory copy, so the board looks duplicated/wrong even after the FILE is correct. Do NOT keep
     re-editing disk — that just fights the clobber and reads as "you keep messing it up." Instead:
      (1) edit the disk once to the right state; (2) VERIFY with `grep -n of_Book:<Name>
       wormhole/Credence/toc.snap` — trust the FILE, not the live board; (3) tell the human to RELOAD the
        runner so it re-acquires the corrected board — only then do disk + live agree and the edit sticks.
 See [[toc-clobber-expand-race]], [[toc-collapse-orphaned-save]].

----
## merged from credence-unusual-excludes-sweep.md

---
name: credence-unusual-excludes-sweep
description: "%unusual on a Credence Book EXCLUDES it from the bulk run-all sweep — it's for deliberate-run-only utilities (migrations/seeding), NEVER a normal capability test"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 587585e3-e873-4c0a-926a-ee486cbe4df5
---

An opus agent tagged the new MusuBerth Book `unusual:persistence-round-trip` in `wormhole/Credence/toc.snap`. The human cut it: "storage is a base guarantee anyway" — don't dramatize the obvious.

**Why:** `%unusual` is not decoration. `LiesFunk.svelte:~2949` skips `unusual` Books from the bulk run-all sweep (`... && !k.sc.unusual`). It's reserved for deliberate-run-only utilities (VoroClinic crush-invariant-diagnostic, MusuGenerateTestsMusic test-data-seeding, Snapmigrating data-migration). A NORMAL regression test (MusuBerth proves persistence works) must run WITH the fleet, so `unusual` is doubly wrong on it — a taste error (base guarantees aren't novelties) AND a mechanical one (it would silence the test in the sweep).

**How to apply:** only mark a Book `unusual:` if it should NOT fire in the run-everything sweep (a migration/seeder/diagnostic run on purpose). Never on a plain capability/regression test. Echoes the [[heist-gears-berth-ruling]] Booth veto taste — don't over-elaborate/dramatize infrastructure.
