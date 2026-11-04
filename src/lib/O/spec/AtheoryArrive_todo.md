# AtheoryArrive_todo — startup, top-down, in Atheory terms

Started 2026-11-04 from the Supervisor talk (`AtheoryNexus_todo.md` E, "NEXT SESSION").  Destination: a page is an Identity
 standing on a Ground, and its whole arrival is told as ROWS — the Ground says what to expect, each Main says how far it got,
  the Supervisor folds them, and the splash is the Ground's Face reading that fold.  Nothing names a subsystem by hand.
   When `/` stands on this, Story.svelte + Auto.svelte can go (AtheoryStory_todo "The arc").  Absorbs `Arrival_todo.md`
    (its arrival authority, 2026-08-31) and the Supervisor laws (`Supervisor.g` header, `Supervisor_todo.md`); Arrival_todo
     goes to history/ once absorbed.  Slice 1 is built (§3); the rest is still talk.

## 0. What to get on with next

- **Slice 1 BUILT + LIVE on the runner (2026-11-04, §3)**, its 1U rack in Mundo (`ArriveFace`), and **Housing's 🐕 drain dog
   retired** (0 rescues over ~20 Book starts; a stopped Desk is now named by its row's stall clock).  Owner's look at the rack owed.
- **Detour done 2026-11-04: Stuffica matured first** (Aprac_todo §0 Newest — the door, Stuffmush, the rack + Storica as views).
- **Before Radio, done 2026-11-04 (owner: yes):** (a) the House stash is keyed by PLACE (Housing `stash_key()`: names from the
   top, `Mundo/…/Desk`; a new place adopts its old name-keyed row once; ledger row in Atheory_design §2) — Otro's per-ip C**
    workaround is gone; (b) a runner REFUSES a rungo whose ghosts it doesn't hold (`Lies_rungo_recv` → `%Refused_Book`), and
     `Lies_ledger_secure` gates only on pinned ghosts it HAS loaded — an editor compile of Ra.g / Peeroleum.g had held every
      become_book to `ledger_timeout` until a reload.  Rule used: not loaded here ⇒ not this runner's to wait for (whatever loads
       it later loads the shipped .go), simpler than naming the Spine + Stands.  Unseen live: an actual editor rungo.
- **With Radio:** a finished Book's watches linger on the runner roster (InvSeal's invite watch) — Radio registers watches too.
- Owner's look at Stuffmush (C** on a `?G=` page) and the 1U rack still owed.
- Then: `/`: Ground/Music with Radio as a Main, its Arrive rows replacing
    BigSoundland's `boot_progress` ladder, the splash as its Face.
- §2's open questions get settled while building.

## 1. Rulings (owner, 2026-11-04)

1. **The Ground declares what to expect.**  A Ground knows what it should have when it starts up, so the milestones are
    Ground rows, read before anything loads.  The expected roster is known from the first paint — an empty roster can no
     longer read as "all well".  The Supervisor still never names what it watches: the Ground is the owner of that list.
2. **Give up on a stall, not on elapsed time** — 20s since the last progress, not a cap from mount.  ("the 45s cap is a
    guess … annoying").  Progress = a milestone met or a count that climbs.
3. **The Supervisor is on a runner too, but not fullscreen.**  The splash is for the music page; a runner (/Desk) shows the
    Supervisor small, beside the Books.  What is there now (SupervisorPanel, the 2026-08-10 guts panel) is "pretty ugly".
4. **A skipped milestone is marked `moot` by its own A, with a reason** (listen-only has no library; a device link has a
    ceremony instead).  The Ground stays one list; it never branches per arrival kind.
5. **One Supervisor, many Faces.**  The runner's "small Supervisor" is the standard one — same rows, same fold — with a small
    Face.  No miniature second Supervisor: two opinions on one arrival is the bug the laws forbid.  The only thing before it is
     the floor reporting its own step (`spine`, as `%Creduler_pending` does today), because Supervisor.g arrives in that load.
6. **A Desk is an arrival too — a smaller page.**  A Book's Desk stands, loads its `Stands:`, runs its steps; its Ground's
    `Arrive:` rows say what it expects, the same as a page's.  The runner's Face is one line for the tab + one per live Desk,
     each with its own 20s stall clock — and that clock is what replaces the begun-wedge dog (a Desk at `begun` with no
      advance for 20s is named, not guessed at).
7. **A deliberate reload says so first.**  Before an A reloads the page on purpose it writes `%Reloading:<why>,at:<milestone>`
    into the House stash; the next load's Supervisor reads it first, the Face says "back after <why>", and the stall clock
     resumes from that milestone — so a reload loop shows as no progress.  A runner's self-reload uses the same row
      (Supervisor_todo §8, "say so durably first").

## 2. Open — for the rest of the talk

- **Row shape.**  e.g. `Arrive:wire,of:Swarm,says:opening the wire` under a Ground; met by the Main writing a row its A
   carries.  How does a Main say "I met `wire`" — a row on its A, read by nearness?  And a COUNT milestone (library 674)?
- **Lift.**  Which milestone opens the door (`Lift:radio` on the Ground?) vs. which keep going behind the open page.
- **Who watches the top.**  The Supervisor reads rows inside the belief loop; the Face has its own timer outside it and can
   say "the page has stopped talking".  The splash's motion should come from progress, not CSS (a CSS spinner spins in a
    hung tab).  Tier 2 (a daemon above) stays unbuilt.
- **Books.**  Rows are snappable, so a Book can finally see an arrival (today it is all off-snap `.c`, only `arrival_eye`).
## 3. Slice 1 — built 2026-11-04

- **Rows.**  `wormhole/Ground/Runner/toc.snap`:
  ```
  Arrive:spine,of:Runner,stage:self,says:the runner's code is loaded
  Arrive:book,of:Story,in:Desk,by:StoryAt,until:finished,moves:run,stage:story,says:the Book asked for walks to its end
  Lift:spine
  ```
  `ground.ts` reads them (`GroundRead.arrive`, `.lift`).  Keys: `of` the A (found breadth-first through As in As), `in` a
   sub-House stood per job (→ a standing watch, not latched; no such House ⇒ `moot`), `by` the row that meets it (default
    `%Arrived:<key>`; `%Arrived:<key>,moot:<why>` skips it), `until` its value when met, `moves` a row whose change also counts
     as progress, `stage` a Supervisor_stage word.
- **The Desk's rows live on Ground/Runner, not Ground/Story** (deviation from §1.6's wording): Story's toc is generated by
   everything.js and its loader reads only the bake; and it is the runner's Ground that knows its Jobs stand Desks.
- **No new rows on the Story.**  A nested Story already says where it stands (`%StoryAt` — ready / step,n / finished, StoryFu
   `Story_at`), but only moves per step when leashed; its run row's `done` climbs every step, hence `moves:run`.
- **Registrar = the Ground.**  `Ground.g Ground_arrive` turns the page Ground's rows into `Watch:arrive.<key>` on
   w:Supervisor, called from `Supervisor_tick` beside `Screen_decide` (the method if present).  One probe for all of them,
    `Ground_arrive_probe`; Supervisor_read now passes the watch as the probe's third argument.  `Lift:` → `Supervisor_arrival`.
- **The stall clock** (`GROUND_STALL_S` 20): the probe re-arms `watch.c.deadline` whenever its A or its reading changes;
   the existing `Supervisor_patience` grades waiting / given-up and clears on ok|moot.
- **A:Runner meets `spine`**: `w:Runner %Arrived:spine` once the Spine's Grounds are Firm (Runner_spine).
- **Proven live**: both watches register from the toc alone; HohoKeep / InvSeal / PortPain / SwarmGot each read
   wrong(waiting) → ok at finished; with the clock briefly at 2s, SwarmGot went waiting → **given-up** → waiting again on the
    next step → ok.  Sweep of 6 Books unchanged (InvSeal's "5/4" is its missing 002.snap).
- **The Face is a 1U rack in Mundo** (owner: "a 1u rack thing. it could list … open up and maybe explain the dependencies") —
   `O/ui/ArriveFace.svelte`, drawn by Otro on a `?G=` page in place of SupervisorPanel in Mundo's sprawl.  One line:
    `arrive ✓spine –book +N` (no countdown — "too dynamic"; a row says `stalled` only once its clock ran out).  Click lists the
     rows; a row opens to what it reads (A, sub-House, the row that meets it, the moving row) and that A's Grounds (`%TheACode`,
      `via`); ⋯ opens SupervisorPanel.  Renders from `Supervisor_lines` only.  Parse-clean; not seen by me (no DOM reach).
- **The drain dog retired** (Housing `_drain_dog`, ledger row in Atheory_design §2): 0 rescues over ~20 starts.  The 📭 hand-on
   guard in `Wormhole_park` stays — a separate rescue, not ruled on.
- **Seen in passing — the editor's `rungo` wedges the runner:** a compile of `Ghost/M/Ra.g` sent this runner a rungo; it never
   loads Ra.g, so every `become_book` then timed out on the version ledger (`Ra.g live=none≠…`) until a reload.  Not this
    slice's; FIXED 2026-11-04 (§0: refused when not loaded here).
- **Seen in passing, not mine:** a Book's own watches land on the page roster and outlive it — after InvSeal the runner's
   Supervisor says `✗ someone answered your invite — nobody has come online` (Supervisor_todo's `eternal`/teardown ruling,
    still open).  The runner's Face should show the Ground's rows apart from those.

## 4. The bridge already in (old generation, labelled)

- `O/ui/Splash.svelte` — the 45s cap from mount became `STALL_MS` 20s, re-armed on every advance (a new phase label — the
   library count rides in it — or a bigger frac).  BigSoundland's `boot_progress` ladder is unchanged and still names
    Swarm/census/glass by hand; it is what §1.1 replaces.
