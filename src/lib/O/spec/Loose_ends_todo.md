# Loose_ends_todo.md — what we left half done back along there

Survey requested by the owner — "what else did we leave half done back along there?" — over design work in `src/lib/O/spec` from the last month, weighted toward Radio/dial, Heist, Reach, Siphon, Portability, Presence, Cluster, and the Sounditron glass/focus model.
Compiled 2026-09-03/04 from every `*_todo.md` touched since 2026-08-01 (plus a skim of `history/` from that window); landed/retired threads are excluded; SoundPooling's own §0 (rewritten the same night) is excluded, but SoundPooling threads mentioned elsewhere are kept.

## ⚑ BOOK SWEEP 2026-09-10 — two PRE-EXISTING problems on committed code, found while regression-testing the relay work

Eight Swarm Books on the live runner. **No regression from the day's relay/Tribunal/Swarm/LiesLies
 changes** — established by swapping the committed client files back in, re-running, and comparing.
  Green and clean: `SwarmDoor` `SwarmCohort` `SwarmBody`(23) `SwarmChain` `SwarmStaple`.

| Book | reading | verdict |
|---|---|---|
| `SwarmGot` | **`ok:false, ok_pct 0.33, caveat 2`** — steps 2·4·5·7·8·9 all `ok:0` with `error:null` | **PRE-EXISTING, AND NOT A BUG — the fixtures predate three shipped changes.** Diagnosed by diffing the live snap against each fixture (below). Only the human re-swears, so this is an owner call |

**`SwarmGot` diagnosed 2026-09-10 — diffed live-vs-fixture, three causes, all "code moved on, fixture
 didn't". Nothing here is a defect.**
1. **The `Crew` shelf, in EVERY failing step.** Live carries, under each `Identity`, a
    `Crew,soul:<64-hex>` with `mate:<prepub>,role:Captain,pub:…` and a `Key,pub:…  {"mung":["secret"]}`.
     The fixtures have none — they were sworn before the cert-crew pivot made keys `/Crew` particles.
      This alone accounts for the mismatch on all six steps.
2. **Step 4 — a round counter drift.** Fixture `self,round=8`, live `self,round=7`: the world now
    settles in one round FEWER. Benign on its face, but it is a real behavioural difference and worth a
     glance before re-swearing rather than after.
3. **Step 9 — rebuffs now AGGREGATE.** Fixture has `rebuff:unvouched_ive_got,say:<pub>` twice as two
    rows; live has one row carrying `,n:2`. A deliberate tally-instead-of-duplicate change the fixture
     predates.
**⚑ `SwarmShare` — THE DIGE IS COMPUTED OVER `self,round`, WHICH IS NONDETERMINISTIC. Re-swearing cannot
 fix it, and this is a STRUCTURAL finding, not a SwarmShare one.** Measured 2026-09-10:
- Two runs of the same Book give step 3 different diges (`e27affb386a27ec2` ↔ `3e135374144ee186`).
- Forced step 3 red (bogus fixture) to make `got_snap` available — `got_snap` is null on a PASSING step,
   so a caveat alone yields no content — and captured four live snaps. **Across all four, 106 lines, the
    ONLY line that varies is `self,round=6` vs `self,round=7`.** The state is otherwise byte-identical:
     the world simply settles in six rounds or seven.
- So whichever value a fixture holds, roughly half of all runs caveat, for ever. **This also explains
   `SwarmGot` step 4's `round=8`→`7`** — same phenomenon, different Book.
- ⚠ **The tooling already disagrees with itself about this.** `story_accept`'s `FILTER` lists `self,round`
   among *"the lines a model change is allowed to move"* (`story_accept.mjs:20`) — but the DIGE that
    produces the caveat is taken over the whole snap, `self,round` included. **The accept tool forgives
     exactly what the gate punishes.**
- **The fix is one of two, and it is an owner call:** exclude `self,round` from the dige (cheap, and
   consistent with what `story_accept` already believes), or make the settle deterministic (correct, and
    much harder — cf. `Radiation_determinism_todo`'s `a_drops`).
- I patched 8 genuinely-stale toc diges and it moved caveat 8 → 1, but the runner REWRITES `toc.snap` on
   every run, so the wobble returns. **Left reverted to committed** rather than half-fixed.

ⓘ Also present and expected: the `see:` line drops (`see:each side holds a shelf the other cannot count
 yet…`). Per CLAUDE.md a `%see` OBSERVES — a drop is signal, not failure — and the `story_swear`
  migration is the live oath. Do not read that line as part of the red.
| `SwarmShare` | `ok_pct 1` but **`caveat 8`** of 9 steps | **PRE-EXISTING, and NOT fixable by re-swearing — see below.** ⚠ `ok:true` hides it: the "require caveat:0" trap |
| `SwarmWire` | `caveat` 1 *or* 0 | **FLAKY, pre-existing.** Baseline measured 3× on committed code: 0·1·0. A single caveat here is variance, not a signal |
| `MusuHeist` | `ok_pct 1` with `caveat` anywhere from **1 to 20** | **VERY NOISY, pre-existing — do not read a high count as a regression.** Measured 2026-09-10 by gen-swapping `Ra.go`: on COMMITTED code caveat **17** and **20**; with that session's `Ra.g` changes caveat **1** and **17**. Same Book, same runner, minutes apart. It is 22 beats and its caveat count is close to meaningless from one sample |

**Method worth reusing:** copy the changed files aside, `git checkout --` them, reload the runner, re-run,
 then restore. Never `git stash` (shared tree). And measure a flaky Book at least 3× on BOTH sides before
  attributing anything — `SwarmWire` would have read as a clean regression from one sample each.

## ⚑ STALE-CLAIM AUDIT (2026-09-10) — check before you build; five claims verified DEAD in one night

A pattern showed up while working this list: **a doc says "there is no live caller" and there is one**,
 because the work landed by a DIFFERENT road than the one that doc was watching, and nothing told it.
  Nineteen spec files carry a claim of this shape (`no live caller` · `NOT DONE` · `nothing calls` ·
   `zero live callers` · `never built`). Five were checked against the code tonight and **all five were
    stale.** That is not a good hit rate to build on.

| doc | the claim | what is actually true |
|---|---|---|
| `UI_seams_todo` S3 | *"the engine is built and green; there is no live caller"* (heist) | ♥ became the caller 2026-09-03 (`Radio_like`). The owner's *"I can't figure out how to Heist"* was an INVISIBLE caller, not a missing one |
| `UI_seams_todo` S4 | now-playing provenance not wired | built — the source chip, `face.by`, `Radio_friendly` |
| `Portability_todo` | *"no LOFI copy ever lands in the phone's OPFS SoundPool during real listening"* | SoundPooling lands them by another road (`Heist.g:2682` `into:'pool'` → `Heist_keep_pool_go` → `Ra_pool_fill_land`); watched live on eed. The AMBIENT press economy is still dormant — that half stands |
| `Daemon_todo:909` | *"**Verified:** `Swarm_station_up` has no callers outside `InvitePanel.svelte`"* | **64 references outside it**, across `Auto.svelte` · `Tribunal.g` · `Swarm.g` · `Radio.g` · `LinkDevice` · `SwarmStandup` |
| `Identity_persist_todo §6.1` | *"Gap 1 — nothing calls the write side"* | closed 2026-08-08. `Auto.svelte:435` says so in its own header — *"THE WRITE SIDE (2026-08-08, Identity_persist_todo §6.1 'gap 1')"* — with two live callers, and the daemon reports `mirror_at` stamped, `owed:0` |

**Why it happens, and it is structural rather than sloppy.** A fix lands in the doc of the thread that
 DID it, not the doc of the thread that was waiting. `Auto.svelte` even cites the section it closes, and
  that section never heard. The corpus has no back-edge from code to the doc that was watching.
**So the working rule:** a "not built" claim older than the last big thread in that area is a HYPOTHESIS.
 Grep for the verb before you write one. The cost of checking is a minute; the cost of not checking is
  rebuilding something that exists — twice tonight I nearly did.
**THE REST OF THE SWEEP (2026-09-10, same night).** The remaining claims were checked. Final tally
 across the corpus: **9 STALE · 5 TRUE · 0 unresolved.** Rule of thumb earned: rather more than half of
  every "not built" sentence in these docs is wrong.

| doc | the claim | verdict |
|---|---|---|
| `Siphon_todo:32` | `Ra_press`/`Ra_quarter`/`Ra_quarter_serve` *"DORMANT: no live caller"* | **STALE** — `Radio.g:421` calls `Radio_pool_steward` on the live playback tick; `:1554` calls `Ra_quarter_serve`. Its own header: *"the AMBIENT STEWARD OCCASION"* |
| `SoundPooling_todo:491` | five verbs *"All DORMANT … no live caller anywhere"* | **STALE except one** — `Ra_rec_pool` has `Heist.g:1041`; the others as above. `Ra_upgrade_scan` (`Ra.g:1910`) is genuinely Book-only |
| `Identity_persist_todo:604` | seven sibling/theft verbs have *"zero callers outside Swarm.g and the Book"* | **STALE except two** — `SwarmStandup.svelte:72`, `InvitePanel.svelte:89`, `DoorFace.svelte:295`, `scripts/daemon/main.ts:763` reach them. `Swarm_next_suffix`/`Swarm_steal_back` remain Book-only |
| `Identity_persist_todo:696` | *"wire the address layer at all — it has no callers today"* | **STALE** — `Tribunal.g:66` dials `peering.sc.address`, set from `Swarm_address` at `Swarm.g:2181` |
| `SoundPooling_todo:118` | relay's *"second map for control-plane types"* never built | **TRUE** — `relay.ts:190` promises it in a comment; `deliverLocal` implements the own-door preference instead |
| `Radio_design:127` | the Booth taste organ has *"no live caller"* | **TRUE** — `Heist.g:513` says outright it *"is UNWIRED by the human's call"* |
| `Peeroleum_spec:104/:353` | `%req:waiting` / `leave_running_until` never built | **TRUE** — absent everywhere; abandoned for `%ttlilt`, as the doc itself notes |
| `Peeroleum_handover:165` | spec-only `prepub`/`prepri` hello fields never built | **TRUE** — self-resolved in the doc |

⚠ **AND THE AUDIT CAUGHT ITS OWN AUTHOR.** The `Portability` correction above originally said the
 ambient economy *"is still dormant"* — quoting `Siphon.g`'s header rather than grepping for callers.
  **A stale COMMENT produced a stale correction to a stale doc.** Corrected within the hour, and it is
   the sharpest form of the lesson: the rule is not "trust comments less than docs", it is **verify the
    verb has callers, from the code, every time** — including when a comment right beside the code
     agrees with the doc you are fixing.

**The eight most worth picking up first (the surveyor's ranking):** 1 GhostHMR (the compile ack lies — blocks trusting any `.g` edit) · 16 Portability (the press/quarter economy has no live caller) · 2 Radio (wire-side tail-ahead want driver) · 9 UI_seams (Heist has no live caller) · 11 Reach (the cross-device byte lane) · 26 Composition (Cluster toc canonicity — live rows vanish, dead ones survive) · 28 Cello (durable refusal wiring) · 6 Sounditron (the solo-radio ruling, an owner's word).

| # | doc | thread | where it stopped | next move (per the doc) | size |
|---|---|---|---|---|---|
| 1 | `GhostHMR_todo.md` | compile ack lies — a `.go` write can silently never land | "the editor acked ✓ compiled @ <the correct NEW dige> on TWO separate rounds, and the `.go` on disk … kept the OLD Ghostmeta" | ack `done` only after the write is read back (Ghostmeta flip); demote the ack to narration, let only the dige-flip settle a ticket | S |
| 2 | `Radio_todo.md` | wire-side tail-ahead want driver for FRIEND records | "a wire record's tail still rides the playhead's own want window, so the tape-out still fires on wire finishes" | build the driver: "want the ordered record's un-held tail, gently, while comfortable" off `repli_want {id, stream, from_idx}` | M |
| 3 | `Radio_todo.md` | ✅ **DONE 2026-09-10** — distinguished NACK for a resolvable-id/unreadable-file | landed as `dead:1` on `repli_missed` (a flag, not a fourth frame): source disclaims instead of parking when `rec.c.pcm_dead`; sink stamps `ra_dead` and skips the futile re-census. Ra had been stamping that mark for weeks and nothing on the wire lane read it. 7 Books identical to baseline, caveat 0 | M |
| 4 | `Radio_todo.md` | ✅ **NOT REPRODUCIBLE 2026-09-10** — the player rail answers | re-tested live: `ping`, `supervisor` and `crew` all answered cleanly over `--player=`. Consistent with the doc's own suspicion that concurrent edits were in flight at the time — i.e. transient, not a rail defect. ⚑ One oddity seen while testing, NOT chased: `ping --player=<eed>` answered `role:"editor"`, because the player SLOT is addressed and whichever tab holds it replies — the same address-ambiguity family as the `?addr=runner` work (Social_demarcation §0) | S |
| 5 | `Radiation_determinism_todo.md` | MusuRaStream's `a_drops` is nondeterministic, blocking re-record | "the live runner gives 2 or 4, every time, on every run … that is a product regression" | chase §3, not `accept`; two candidate `.g` fixes need the human's call | M |
| 6 | `Sounditron_todo.md` | solo-radio friend-exclusive ruling still wanted | "SO THE CONTRACT AS DECLARED CANNOT LATCH ON A SOLO MACHINE — a ruling is wanted" | owner picks (a) leave contracted / (b) undeclare / (c) let the probe flip `radio.sc.own` for itself | S |
| 7 | `Phone_instrument_todo.md` | the dial itself — gesture layer, tag sync, pushed stream, knobscape | "A fresh session reads here. The overall arc is:" (nothing past the design listed as built) | §0.1: wire one tag verb (`Radio_tag_now`) behind the Media Session `previoustrack` handler, prove the particle model with zero sync machinery | L |
| 8 | `Heist_todo.md` | does the Haul list / setup-form seating / `un_n` number actually read right, live | "The three questions that decide what comes next" — Haul-list-as-home, setup-form seating, `un_n`/`un_size` correctness — all unanswered | owner looks at a live heist and answers each; `BELLY_SWELL` is the dial if seating is wrong | S |
| 9 | `UI_seams_todo.md` | Heist has no live caller | "The engine is built and green; there is *no live caller*. This is the biggest gap and the one with the clearest 'I don't see how to heist' behind it." | build the live driver + a Book (S3) — ⓘ partly answered 2026-09-03: ♥ (`Radio_like`) now starts a background heist when a share is mounted | M |
| 10 | `Backpressure_todo.md` | Tier 2/3 lossy-wire `MusuNeGrind` (real RTT/loss over the loopback bench) | "This is the FIRST thing to settle when the Book is built — it decides whether the loop is actually exercised or still inert" (the `delayAll` wall-clock-sample question) | settle whether `w.c.lossy_uno.tick()` per pump pass gives a real wall-clock RTT sample, then build Tier 2 | L |
| 11 | `Reach_todo.md` | cross-device BYTE lane (the Mag-travels doer binding) | "the cross-device BYTE lane (the Mag-travels shape below) is still the owed transport — a live fill ends Cave-side today" | wire `Swarm_reach_serve`'s doer to mint/assemble a Mag and hand it to Repli toward the booker | M |
| 12 | `Reach_todo.md` | the booking GESTURE | "where in the UI a reach is born (a heard-but-absent track's press?)" — undesigned | design the UI trigger for booking a reach | S |
| 13 | `Reach_todo.md` | §7 forks — open `for` vocabulary, `%Owed` retirement schedule, Seem-over-Reach dashboard | listed under "Still owed (the owner's seams)" | design each fork | M |
| 14 | `Reach_todo.md` | §4 migrations — charter/grant/pier-heal debts becoming reaches | "after the music slice proves live" | migrate bespoke machinery onto Reach one slice at a time; measure by "bespoke machinery REMOVED" | L |
| 15 | `Siphon_todo.md` | controllable radio + face, and the connect-up seam (rungs 5–6) | "The connect-up seam (proposed, not applied) … Write the exact patch here; the human or the resident session applies it after review" | build the source-notion radio (`local \| pool \| <friend>`) + tag-chip face, then apply the connect-up patch — ⓘ the `pool` stop exists now (`Radio_source_next`); the `<friend>` stop is still reserved | L |
| 16 | `Portability_todo.md` | ⚑ **HALF STALE 2026-09-10** — the OUTCOME landed by another road (SoundPooling: `Heist.g:2682` `into:'pool'` → `Heist_keep_pool_go` → `Ra_pool_fill_land`; watched live on eed). Lofi copies DO reach the pool while listening. Still true: the AMBIENT press/quarter economy is dormant (`Siphon.g` header) and its `lib` question is the owner's. Original wording: THE LIVE WIRING GAP — the press/quarter economy has zero live callers | "Nothing in the LIVE flow calls them … no LOFI copy ever lands in the phone's OPFS SoundPool during real listening" | wire the driver seam: a live tick handing `Ra_quarter_serve` the phone's pool nav + a `lib` source — ⓘ 2026-09-03: `Radio_pool_steward` now sits for any consented pool, and the fills follow the consent; the live walk is what proves it | L |
| 17 | `Portability_todo.md` | the pool exchange — phone↔phone LOFI swap, live, no Cave required | listed as missing item 4, "possibly the majority transport" (§0) | design §5 | L |
| 18 | `Portability_todo.md` | the phone push field verification | "concrete risk: no nav in `listen_only` … radio silently no-ops on device while dev looks green — field trip only" | verify on a real phone that a friend's stream plays in listen_only | S |
| 19 | `Portability_todo.md` | the smuggle / `%Invite:MyCave` / the Door dialogue (items 5, 6, 8) | all three still listed under "What is missing," none started | design the graft ceremony (%Invite:MyCave), the Captain→Cave backup, and the Door's invite-yourself explainer | M |
| 20 | `Presence_todo.md` | five freshness windows should collapse onto one answer | "`heard_at` is read at 20s … 20s … 30s … 12s … and 15s … Five numbers for one idea" | unify the freshness constant | S |
| 21 | `Presence_todo.md` | Seam D is ungateable by any Book (0 piers on runners) | "somebody has to seal a friendship into a runner first" to gate Seam D end-to-end | seal a runner friendship, then gate it | M |
| 22 | `Presence_todo.md` | should `Presence_ask_roster` be its own req or ride the pulse round | "Worth deciding" — undecided | decide; a req would carry its own liveness | S |
| 23 | `ClusterAddressing_todo.md` | should role addressing exist at all | "The deeper question the human parked, worth a session of its own … or should everything route by identity now that `hello` binds a real key?" (§4) | a dedicated session's ruling | L |
| 24 | `ClusterAddressing_todo.md` | `header.from` is unrouted + unverified | "the `header.from`→prepub unification is spine surgery that intersects §4/§4.5's unresolved address-model question, so it is deferred past v1.0" | resolve alongside §4's addressing question | L |
| 25 | `ClusterAddressing_todo.md` | capability advertising has no Book | "§3 is entirely untested — `fsa:1` in the beacon … asserted by comments and by nothing else" | write a Book for it | S |
| 26 | `Composition_todo.md` | `wormhole/Cluster/toc.snap` is losing live rows and keeping dead ones | "That is backwards for a reaper and exactly right for last-write-wins overwrite by a second editor with a divergent view … nothing decides which editor is canonical" | decide canonicity policy — "a mature take on who can coordinate what data changes, what's canonical" — not a reaper | L |
| 27 | `Statemap_todo.md` | sibling-sync gap — a Cave still can't learn its Captain | "This is the real 'they still don't know each other.' It wants a **sibling channel**" | design charter delivery to body addresses (`<soul>_N`), plausibly a Repli/replication job (§3) — ⓘ likely superseded by the travelling crew ledger (`Swarm_crew_gossip`, 2026-09-03): re-read before acting | M |
| 28 | `Cello_todo.md` | durable refusal wiring (Layer B `insistent`/`refuse`) | "`Cellui.svelte`'s `refuse_ask` currently adds to a view-only Set … Replace that with a call to the ghost verb above" | wire `Swarm_iz_refuse`/`Swarm_iz_refused` via elvisto; gate on a live runner with the owner | M |
| 29 | `Cello_synthesis_todo.md` | prove the residual atom — the smallest buildable slice | "This is the one experiment that decides everything; build it before any full field" | draw one particle as its DEVIATION from a per-mainkey prior (normal = near-invisible, wounded = full glyph) | M |
| 30 | `Vyto_todo.md` | button latency + phone battery cost, diagnosed not fixed | "DIAGNOSED 2026-08-08 by source reading — not yet profiled, and not yet fixed. See §0.2." | instrument the click path; profile the rAF settle knife-edge constants before touching the render — ⓘ see also the Vyto-under-Cello double mount noted in SoundPooling §0 | M |
| 31 | `Voromay_todo.md` | no picture exists yet for the multi-device/friend topology | "None of this has a legible picture … The owner wants it graphed" | settle the open Vyto-vs-Voromay renderer question (§1) | L |
| 32 | `Glass_reduction_todo.md` | a pressable cell looks identical to a stating one | "The gap is one thing: a pressable cell looks identical to a stating one. Until press is visible, 'C** all the way down' fails" | make press visually distinct (§1's plan) | S |
| 33 | `Snappy_todo.md` | the minimal cell primitive is undefined and unmeasured | "Measure the cell-switch cost and the per-bump re-render fan-out before committing to a rebuild" | instrument first, then define the minimal cell primitive Radio/Door/Link become thin renderers over | M |
| 34 | `InkSurprise_todo.md` | wire a live H / interactive resolve() / continuous geometry / tearline | prototype "currently synthesises demo particles" — none of the four next items built | wire a real `H` prop first (the island computation is already pure) | M |
| 35 | `Datalayer_todo.md` | §3.1 `resolve()` is O(N²) with a proxy multiplier | "real by construction, UNMEASURED as to whether any live container is big enough to feel it" | decide by measuring, not by taste | S |
| 36 | `Onboarding_todo.md` | move the boot/share `.c` flags onto C particles (§A) | "Not near-term; the direction" — `disk_gated`, `listen_choice`, `listen_only`, `account_mirror_owed`, `butler_up` all still plain `.c` bools | apply the ferry-rebuild move (14 flags → one `req:Ferry` particle) to onboarding's flags | L |
| 37 | `Arrival_todo.md` | fresh-incognito boot is "amazingly slowly" — undiagnosed | "Not yet diagnosed; candidates: (1) boot_gate poll start latency (2) real cold FSA/Dexie setup (3) aftermath of the eed wedge" | a real boot-cost profile, best done with the owner timing a real fresh-incognito boot | M |
| 38 | `Wander_todo.md` | no Book exercises `Crate_nav_meander` live | "every number in §6 and §7 is node against synthetic shapes … proved correct and unproved *live*" | run the five-minute live test in §7.2 | S |
| 39 | `Trust_todo.md` | restore consent + SAS to the ferry/crew ceremony | "the ferry today auto-fires on seal with no grantor approval and no emoji match — strictly weaker than the Adopt ceremony it replaced" | re-attach the grantor-consent popup and the 3-glyph SAS match — ⓘ check against LinkDevice's current SAS row before believing this is still open | M |
| 40 | `Identity_persist_todo.md` | a disk-restored identity comes back friendless | "Known gap, deliberately not closed here. The seed grafts into a DETACHED vault … only the KEYPAIR is adopted — the identity's piers/grants are not." | wire `Swarm_restash_piers` (the converse half, already exists) into the disk-restore path | M |
| 41 | `Swarm_compact_invite_todo.md` | §9 the Invite as a standing two-sided req — rung 1 unshipped | "Rung 1 is shippable today and needs no wire" | ship rung 1 | S |
| 42 | `Whitehole_todo.md` | front 1 — one Book, one toy world, one pluck — not started | "Nothing is built and nothing should be built big" | build the toy Book proving resolution, change-gating, and continuity before touching any live site | L |

## Docs whose §0 reads stale or contradicted by a later doc

- **`Statemap_todo.md`** — item 2 asks to "replace the `w.c.focused` / `link_surfaced` / … pile with ONE snappable particle," but `Statehome_todo.md`'s 2026-09-01 entry records exactly this as **LANDED** (`%Focus` particle, `Sounditron_focus_get/set` accessors). Read Statehome first.
- **`Onboard_todo.md`** — superseded in practice by the newer `Onboarding_todo.md`; its phone-arc section points at `MobilenoFSA_todo.md`, which has since been deleted from the tree.
- **`Identity_persist_todo.md`** — its whole "detached vault / keypair transplant" resume model predates the cert-crew pivot, where each device mints its **own** key and the Captain mints a `Grant:Crew` at the seal. Read alongside `Crew_todo.md` before trusting its framing.
- **`Backpressure_todo.md`** — its opening "BUILD `MusuNeGrind`" framing reads as if the Book doesn't exist yet, but `Composition_todo.md`'s §0 shows it built, run, and gated since 2026-08-08. Only the later "BUILD PLAN (2026-08-28)" section (Tier 2/3, the lossy wire) is still live work.
- **`ClusterAddressing_todo.md`** — self-flags its own top bullet as "SUPERSEDED SAME DAY"; read together with `history/Division_todo.md`'s Model B ruling, not in isolation.
