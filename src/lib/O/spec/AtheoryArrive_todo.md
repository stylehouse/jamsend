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
- **v1.1 = the music page on A (owner 2026-11-09).  `/Radio` is canonical** (= `/Desk?G=Radio`; Ground/Player renamed Radio).
   Owner tried it: "done, is good".  (2) and (3) BUILT 2026-11-09, incl. the minicell edge+quiet note and `/Cells` (§6).  Left: the owner's
    look at the Yay cell + the minicells with many cells on a real page; (4) `/` and `/BigSoundland` point at `/Radio` — some day.  No Story on the
     page for v1.1: the Supervisor's Health upload is the report; Story+Supervisor synergy is later (§6 "Later").
- **Radio as a Main — slice 1 written 2026-11-07 (§5)**: `/Desk?I=…&G=Player` stands A:Radio on Mundo with no Book; its
   arrival is Ground/Player's Arrive rows; the splash is ArriveSplash reading their fold.  `/` (BigSoundland + Sounditron) untouched.
    Next: the glass (slice 2), then the Door/Link cells and friends' shelves, then `/` mounts it.
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

## 5. Radio as a Main — slice 1 (2026-11-07)

- **The Ground is `Player`, not `Music`** (renamed `Radio` 2026-11-09, served at `/Radio`; deviation from §0's wording): Ground/Music's toc is DERIVED (everything.js rewrites it); a
   composition is hand-kept and named for what runs (AtheoryNexus_todo E, "Runner, Daemon, Player").  `wormhole/Ground/Player/toc.snap`:
    `Main:Radio`, `Role:player`, `Spine:` Wire Swarm Music Cave + Supervisor.g, `Load:Ghost/M/RadioPage.g`, four Arrive rows
     (spine, who, shelf, radio — all of A:Radio but `who`, met by A:Identity's %Who), `Lift:radio`.
- **Role player** (Otro): boots as the music page does — `boot_role` runner + `humdinger` (BigQualand's 'sound'): Creduler loads the
   Spine, the wire + Supervisor stand, no runner seat, never dispatched a Book; no `H.c.book`, so no Story.
- **`Ghost/M/RadioPage.g` `Radio(A,w)`**: the organs Sounditron_glass stood inside its Book world now stand on w:Radio — Radio_ensure,
   Stoker_ensure + preheat, Radio_lineup_ensure — and it writes `%Arrived:spine|shelf|radio` (shelf moot: the stoker rests with none;
    radio is met once the shelf has said either way — a moot Lift never lifts).  Re-asks itself each 1s until `radio` arrives.
- **Faces**: `O/ui/RadioPageFace.svelte` (RadioFace + LineupFace + StokerFace in plain boxes, the cells without the glass);
   `O/ui/ArriveSplash.svelte` — the tree Splash told by Supervisor_lines' `arrive.*` rows: label = first unmet row's sentence, frac =
    settled/declared, ready = Supervisor_arrived 'arrived', urge = 'gaveup'.  Otro mounts it on a `?G=Player` page.
- **Slice 2, the glass (2026-11-07)**: Cello, as on `/` (owner: "really more port-hole looking") — RadioPageFace mounts `Cellui` on
   Mundo full-height.  No Vyto commission: with no A:Vyto world Cellui casts by its raw walk (every faced particle under an A's w),
    so the cast is w:Radio's organs + a %Door RadioPage now stands; Cellui keeps the Stoker off (`keep_cell`, Sounditron's lean set);
     Supervisor shows only when amiss.  Minicells no longer drag-roll or wheel-resize (owner: "don't need to be draggable") — on `/`
      too; a tap still promotes.  Otro on a player page folds every other UI behind ▦ (still mounted — the spine shims must be).
       The raw walk also met Mine|Mag|Transfer (never cells on /, owner) — so RadioPageFace names the CAST (Cellui's new `cast` prop,
        which wins over mirror + walk): %Radio, %Door, and the %Supervisor row (shown only when amiss).  Seen in the eye: main Radio,
         minicells Door · Supervisor.
- **Slice 3, the page's navigation (2026-11-07)**: the glass is FULLSCREEN over Otro (owner: "I want the fullscreen glass"; ▦ in
   its corner lets it back into the page).  The verbs a face uses to move the main cell were Sounditron's — a Book that watched the
    radio start (owner: "we're likely to renovate that given new Story+Supervisor capabilities").  They are now the page's: `Page_focus`,
     `Page_link_open|done|close`, `Page_pier_open|close` in RadioPage.g, the focus a `%Focus,cell` row on w:Radio (Radio = absence).
      Faces call `O/ui/page_nav.ts` (Page_* first, else Sounditron_* — so `/` is unchanged); Swarm's ferry phase surfaces the Link the
       same way.  Cellui takes `focus`/`onfocus` props beside `cast`; the cast adds %Link while focused or a link is in flight, and
        %PierView while focused.  Eye: Door minicell → main; named, "link a device" → the Link cell main.  The ceremony itself is unseen.
- **Sounditron, renovated (talk):** what is left in it that a page needs (Screen_decide, the supervise registrations, the wiki cell,
   the keeps' belly ladder) moves to the page the same way; what it was FOR — watching an arrival — is now Ground Arrive rows + the
    Supervisor, so the Book shrinks to a Story about a Player page (Desk Stands:Player), not the thing that runs one.
- **Not yet**: the Uptime cell, friends' %Theirs shelves (the trickle), the
   ▦ guts, the BootGate share grant, `%Reloading` (§1.7), the lingering watches (§0).  Then `/` and `/BigSoundland` mount this.

## 6. v1.1 — the rest of the port (owner 2026-11-09)

**Where things are.**  `/Radio` (src/routes/Radio, `boot_default('G','Radio')` in $lib/boot) mounts Otro on Ground/Radio
 (`wormhole/Ground/Radio/toc.snap`, hand-kept, shipped in the bundle).  Otro maps the name Radio → role player (`BOOT_ROLE_OF`) because it
  boots before any toc is read.  The H** layout: everything is on Mundo — A:Auto, A:Identity, A:Lies (the Creduler, humdinger), A:Wormhole,
   A:Clustation/w:Swarm, A:Supervisor (its %Watch roster incl. the four arrive.* rows), A:Radio/w:Radio (the Main: %Radio %Stoker
    %Mag:Lineup %Door %Link %PierView %Focus %Arrived:*); no sub-House, no Story.  The glass is Cellui fullscreen with an explicit cast.

**The shelves, as they are** (for the next reader — owner asked "a shelf is full of Mag which are full of Records?" — not quite): on the radio's w,
 `%Mine,pub:<me>` is my home and `%Theirs,pub:<them>` a friend's as I hold it; each home has shelves — `stock` (records ready to play),
  `shop` (what is mid-transfer: my %Caper pulls, %Heist keeps), `radiostocking` — and the shelves hold `%Record`s.  The Mags are elsewhere:
   Heard's `%Mag:heard,pub:<me>` > %Cloud,page > %Card,id,pub — what I heard of whom and what I took (♥) — the ledger of love.

**(2) Friends + the Yay cell — the design talked 2026-11-09 (owner's words, to build):**
- Friends' shelves: their %Theirs crates reach the dial (Sounditron did it by re-commissioning when the Theirs set grew — the trickle);
   on /Radio the cast is RadioPageFace's, so it only has to see them.
- **The heist takes the main cell** when the Door's "ask to heist" option is on and a keep is a FORM (primed|wanted|asking|choosing — the
   folder ticks, a section to type, ▶); a running keep is a progress bar and rides as a minicell (Sounditron_belly_keep's rule: a form beats
    a run, the one touched last wins, a pressed bud beats a form).
- **No FSA (no folder) ⇒ every heist goes to their other device** (a Cave, the crew), keeping the given folder structure — or, with no
   other device yet, the yay just waits as "what we liked" data.  A fused bundle of options governs it — gather them in one place.
- **Cell:Yay — new.**  A ♥ (yay|like|love) is a data point; show what becomes of it.  When the first one is made, a Yay minicell APPEARS
   and the ♥ animatedly flies from the like button into it.  It tracks every Yay and Nay (👎) and what became of each (heisted here,
    sent to the other device, waiting).  From it: untick "autoheist when yayed", untick the Door's "ask to heist"; a list of what to
     download later, with an introduction to Link Devices; review a non-autoheisted yay and heist it.  It SYNCS between both devices
      (the Heard Mag crew mirror already carries ♥ — Heard_haul_beat / RemoteHeist R4).  "It's nearly how it is" — most rows exist.
- Organs maybe retired (owner: "I'm not sure I ever want to see Hauls"): `%Hauls` = albums that actually landed, newest first;
   `%Uptime` = seconds since page load (a "did my reload land" tell, 2026-07).  Neither is in /Radio's cast.

**(2) BUILT 2026-11-09** (headless eye: Wikipedia cell taps into the reading room on /Radio; the ♥ path + Yay cell are UNSEEN — they need a
 real track and a heart, i.e. the owner's page):
- **The pulse** — `RadioPage_pump` (RadioPage.g): every 2.5s, Swarm_pulse_all + Peeroleum retx/liveness/cull every other beat.  It was
   Sounditron_trickle's job and /Radio had NONE of it: friends never saw us "here", a lost pier_accept was never re-sent.
- **The cast moved into the ghost** — `Page_cast()` (read-only; it runs inside Cellui's derive) and `RadioPage_organs` (the think mints the
   anchors).  Radio, Door, the keeps, Wikipedia, the Riffle at ≥2 sealed piers, Pooling at ≥1, Yay once a reaction exists, the Supervisor row,
    Link|PierView while focused.  Cellui seats everything a `cast` names (no extras cap).
- **The keeps** — a FORM (primed|wanted|asking|choosing, not carried) wears `.c.stage_want` → Cellui's insistent main (its "no" refuses);
   one asks: the pinned (`Page_focus_keep`, HaulFace's press via page_nav) else the last touched; a running keep is a minicell.  Naming any
    cell drops the pin.  The Door's "ask to heist" is the existing `Heist_take_asks` (`Heist_defaults.ask`).
- **Cell:Yay** — `%Yay,face:Yay,dontSnap` on w:Radio, minted at the first heart|nay; YayFace reads `Page_yays` (Heard's card union — mine +
   my devices' mirrors, so both devices list the same): every ♥|👎 and its fate (heisted here|on X, sent to X, being heisted by X, saved for
    later, waiting for X, already had it, couldn't land, "kept — what we liked" with no folder).  Two switches: **autoheist when yayed**
     (`Heard_autoheist`, `Heist_defaults.auto`) and ask-before-heisting.  The download-later list with ⇊ (`Page_yay_go` → `Heard_go`), and a
      Link Devices intro when there is no folder and no linked device.  The ♥ flies (RadioFace throws `jam-yay`; RadioPageFace animates into
       `.cello-sat[data-mk=Yay]`).
- **Later, as stamps** (Heard.g): autoheist off ⇒ `Heard_take` stamps `later_at`; `Heard_go` stamps a newer `go_at`; `Heard_later(card)`
   gates the haul beat (says "saved for later").  Both ride the crew mirror (`Heard_mirror_stamp_keys`), so the hauling body honours the
    presser's word.  The SWITCHES are per device (Heist_defaults lives in the stash) — syncing them is open.
- **The Wikipedia cell** — `Ghost/M/Wiki.g` (Sounditron_wiki_* copied as Wiki_*; a `Load:` row on Ground/Radio); WikipediaFace asks Wiki_*
   first.  Sounditron keeps its copy for / until (4).
- Radio_focus_tell's Vyto proposal is a `vaguely_ponder` now (the "no House has A:Vyto" warning on every play).
- ⚠ A Ground toc edit reaches a FOLDERLESS page (the eye, a phone) only after a dev-server restart — vite caches the `?raw` toc module and
   ignores wormhole/ (`touch vite.config.ts`, then 3 green pings).
- Open: the Yay cell's look on a real page; whether a sealed-friend's shelf reaches the dial on /Radio as on / (the Repli fill is Swarm's own
   share loop, so it should); the switches' sync; Haul (`%Hauls`) is not cast — the Yay cell covers "what became of it".

**Owner's first look, 2026-11-09 — fixed same day:** the Supervisor + Riffle minicells are out of the cast (the Riffle is a forgotten
 organ — Flip does nothing); a ♥-keep with "ask" off is a haul, not a form, so it no longer grabs the main cell; the Yay cell never
  appeared because the think stops re-running once the radio has arrived — RadioPage_organs now also runs on the pulse; the ♥ flight waits
   ≤4s for its target; each Yay row's Heist is status-lined ("3 of 8 tracks", "asking Grav for the album") and links through
    (page_nav focus_keep); the fill-screen QR (InvitePanel .ip-overlay, z 60) opened invisibly UNDER the fullscreen glass (z 1000) → z 1500.
 **The doubled album** ("16 tracks" from 8 wavs, each landed twice — Heist.g): a ♥ keep went pulling on its BLAGGED picks (the mirror
  guess) before the source answered; Heist_wire_supersede only ran while a keep was a form, so the wire's picks were added beside the
   blag's.  Now Heist_keep_take_go waits for a pick the source named, and the pulling branch runs the supersede too (a ▶ pressed early).
    Probably as old as the blag on /; Books MusuHeist/MusuHeard/MusuPool*/Heistation green after.

**(3) Every cell kind** — **`/Cells` BUILT 2026-11-09** (src/routes/Cells): every face in GLASS_KINDS on a bare particle and a ghostless House, at minicell and main size, each behind a boundary — so their EMPTY states, and which can't stand alone (all 16 draw).  Seen in the eye.  Their full look needs /Radio.  The registry lives in `src/lib/O/glass_kinds.ts` (mainkey → Face component, 27 of them) and `glass_faces.ts` (FACE_MAINKEYS).
 Owner: "we must have all these Cells defined somewhere I can eye them all?" — a page (or a Book) that stands one of each, for a look; then
  "furthering their artifice" after 1.1.  Sounditron's left-overs to move out the same way as Page_* (§5 slice 3): Screen_decide, the
   supervise registrations, the wiki cell, the keeps' belly ladder, the Theirs trickle.

**Owner's look 2026-11-09, for the Radios agent:** the Yay toggles are nice (they work since YayFace re-armed pointer-events).  The
 minicells get a bit numerous: the older or quieter ones (Wikipedia, Pooling) should shrink a bit more, and the minicells should sit
  ALONG THE EDGE of the big cell (the off-edge belly already perches them on its bulge — make that the resting layout too).  Cellui's
   satellite strip: `satellites` derive + `.cello-satellites` CSS.
 **DONE 2026-11-09:** `QUIET` (Wikipedia, Pooling, Supervisor) wear `.cello-sat.quiet`, about 70% of a minicell, in all three layouts.  Along the
  edge: `arc_nudge(i, n)` pulls each minicell toward the main's wall by the square of its distance from the strip's middle (`--nudge-x`,
   or `--nudge-y` on a narrow page, where the strip is a row under the main), so a long strip follows the curve instead of a straight
    column.  Seen in the eye with two minicells (wide and narrow), not yet with five.  "Older" is not done: nothing knows a cell's age yet.

**Owner, later 2026-11-09 — fixed same day:**
- **The hover glow** stayed where the minicell was before the edge arc moved it: app.css's global `button:hover` box-shadow.  Off for
   `.cello-sat`, and the arc rides the button's own `translate` (not the inner wrapper), so the whole minicell moves.
- **Swapping primacy orbits**: Cellui's `flight` bows each body sideways off its path (always turning the same way), so the two in a
   swap pass on opposite sides and swing round each other; the one rising to main passes in front, with a little spin.  Seen landing
    in the eye, never mid-flight (its shots are too slow) — the owner's eye is the test.
- **"waiting on Vingas's music" stayed after Vingas came**: /Radio had no Sounditron beats, so the crossover was reached only per
   landed chunk (never, when a friend's records were already warm) and `Radio_autopress` leans on Sounditron_* (absent).
    `RadioPage_listen` on the pulse: playing on a stopgap ⇒ `Radio_crossover` each beat; off and nothing playable at first ⇒ the
     first time a friend's track is playable, `Radio_go` (once a sitting, never after a play).  `Radio_crossover`'s latch now
      re-arms when a friend's track opens (once a stopgap, not once a sitting).  Untested live.

**(3) The cell inventory, by relevance (2026-11-09 — from who mints|casts each, Books aside):**
- **In service on /Radio:** Radio · Door · Wikipedia · Yay · Pooling (≥1 friend) · Heist (a keep; its minicell is an icon now) · Link · PierView (both while focused).
- **Only on / (Sounditron's glass), retire with it unless wanted:** Hauls (Yay covers "what became of it") · Caper (the flow organ, no-keep only) ·
   Riffle + Riff (crate picker — owner: forgotten, Flip dead) · the plain glass + Junk (`w.c.plain`) · the Pose parts Float|Pull|Serve.
- **Developer-only (`show_diag`):** Supervisor · Tree.  (On /Radio the ▦ guts show the Supervisor.)
- **Fallen out of service — rows minted, never cast:** Beat · Uptime · Diag · Tuner · Stoker · Zine · Shuffle (Books only) · Transfer.
- **Nothing mints them at all:** Lineup (`%Mag:Lineup` exists, never cast) · Crate (Mine|Theirs by mainkey — off the glass since 2026-07-28).
- **Vyto's nested glass only (Cello doesn't nest):** HeistBar · Pick.  **Story Books only:** Errlog.
- **TRIMMED 2026-11-09 (owner: "drop all those dead cells"):** the ten faces Beat · Uptime · Diag · Tuner · Stoker · Zine · Shuffle · Transfer ·
   Lineup · Crate — the .svelte and their glass_kinds rows.  All were read-only views (no model logic); ideas worth keeping live in git:
    ShuffleFace (reach vs playable pips), TransferFace (the live rx/tx HUD), LineupFace (a friend's starve as a red line).  KEPT on purpose:
     the rows the ghosts mint (the Sounditron witness swears on %Beat/%Uptime) and glass_faces.ts FACE_MAINKEYS (Cyto's model reads it —
      a snap could move); a kind with no component draws as its label in every glass.  OWED: everything.js still names Lineup|Tuner|Stoker|
       Crate|Zine Face as Docs, so the generated Wafts (Ghost/Music/*, Ghost/Rest/Unsorted, Ground/Music|Cave Beside: rows) list missing
        files — DONE 2026-11-09 with the everything.js sublation (the rows were dropped from the hand-kept tocs).

**(4) Some day:** `/` and `/BigSoundland` point at `/Radio` — MOUNT, not redirect (routes/+page.svelte: an invite URL must stay as scanned),
 carrying BigSoundland's pocket-player duties (the service worker's `music_page`, `navigator.storage.persist`).  Then Sounditron leaves the
  music page and becomes a Story about one.

**Later:** Story + Supervisor are one job at two tenses — the Supervisor holds standing questions now, a Story films and compares to a
 recording.  A noticing Story (a step per Supervisor fold move, the Arrive rows its oaths) is the renovated Sounditron.  Not for v1.1: the
  Supervisor already uploads Health (counts + verdicts, prod only, per-boot id — Supervisor.g "the report that travels"); /log unread so far.
