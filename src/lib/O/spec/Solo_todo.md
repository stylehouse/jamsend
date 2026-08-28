# Solo_todo.md — the lonely Radio: a nobody who stumbles in gets music

The working doc for the PEERLESS EXPERIENCE — everything between "a stranger opens the URL" and
 "their own music is playing and an invite is one press away."  Split out of the 2026-08-28 session
  (the owner: *"maybe split some of these experimental new features, they need plotting on their own
   and piecemeal connected to the wider playland"*) — Radio_todo keeps the piracy cluster (friends'
    libraries flowing), Onboard_todo keeps the invite funnel; THIS doc owns the tab with nobody on it.

---

## 0. Where to start, and the arc

**The destination.**  A first-visit, no-invite, no-friends tab is a WORKING RADIO in under 15
 seconds: glass up, own shelf stocked, radio playing itself (silent until first touch wakes the
  AudioContext), and the door to friends worded as a fact with a link in it ("no peers ever,
   invite some").  Nothing begs, nothing waits on a friend, nothing goes hard enough to promise
    what isn't coming.

**What landed 2026-08-28 (all live-verified on a cold Incognito via `runner_ask supervisor`):**
- The cold-boot chain, three layers of one disease (a cold 1-step toc means NO BEATS EVER RUN —
   anything living in beat N does not exist for a stranger):
    · roster/arrival registers from the Sounditron drive heartbeat, not beat 2
    · peerless arrival decides on MACHINE facts (`vw.c.commission` + `grapples`), hoisted ABOVE the
       `vw_frame` gate — `vw_frame` is render-only and a static glass never publishes it
    · the glass's first scan unstarved at the COMMISSION seam (`e_Vyto_commission` stamps the default
       800×450 + stirs when humdinger && frameless) — the drive dies before the deferred commission
        pumps, so no heartbeat outside that verb reliably sees it land
- `Radio_autopress` (Radio.g, off `Radio_nudge`'s radio-is-off path): the peerless radio starts
   itself.  Gates: humdinger · !ever_played · !auto_pressed (both `.c`, once-a-sitting) · radio off ·
    stock>0 · `Sounditron_peerless()===1`.  SwarmStandup pokes one nudge when the counted-zero first
     settles (covers the dig-finished-before-count-settled race).
- The stroll dig: an ALONE humdinger tab digs at 1.2s/pass after the first landing (the vibe rule —
   *"don't go hard only if they're alone, so they don't get a vibe like something might happen"*);
    peered tabs and Books keep the 250ms rhythm.
- Name-before-invite as a JAMMED UI PROCESS (InvitePanel `mint_wanted`): pressing invite unnamed
   spawns the mint jammed on the namer; the name landing resumes it — no throw, no dead button, the
    ghost mint stays clean (*"the throw is bad… it should be UI process spawning, and jam the Invite
     before it begins"* / *"just self-apply the rule"*).
- Link cell: scope bug fixed (`link` was referenced from a sibling verb's scope — pressing Link
   Device killed the whole commission), label "Link Device", peerless invite line under ♪ LOCAL.

**What landed 2026-08-28 (afternoon — the Link Device wreck + ASAP pass):**
- **The Link Device wreck fixed** (owner: *"we zoom off to the Shuffle cell… no way back to the
   Radio… MEASURE THE THING"*). Root cause: `Sounditron_focus` (the face-nav seam) resolved the
    GLASS world and re-commissioned it, but the organs (%Radio/%Door/%Link) live on the RUN world —
     the glass world had no organ rows, so the one `oai` organ (%Shuffle, find-or-CREATE) minted
      bare and dispatched a one-cell dead-end over the good glass, on both tabs. Fix: hand on
       `vw.c.client_w` (the run world, stamped at every commission); a **way-back ensure** refuses
        any live commission whose organ set carries neither Radio nor Door (humdinger-gated —
         Book-fixture-neutral); the tuck ring dropped to `['Radio','Door']`.
- **Shuffle cell cut** (owner: *"'0/0 the dial can reach' … don't need that"*) — grapple gone on the
   live glass, HUMDINGER-GATED so Book fixtures stay byte-identical (the row + face stay; one line
    restores it). Sounditron.go 207028c, LocalGen + esbuild clean.
- **Self-radio ASAP** (owner: *"self-radio should play itself ASAP"*). The autopress's only reliable
   trigger was SwarmStandup's **5s** counted-zero settle-edge (the boot dig stops nudging once
    preheat fills the shelf, `dug=0`). Added an **early poke** effect in SwarmStandup that pokes
     Radio_nudge the instant `Sounditron_peerless`'s live fallback holds (self stood + no
      Music-granted pier), no door-latch wait; autopress re-checks every gate so early+often is safe,
       bows out on a granted friend or radio-left-off (also what keeps it inert on runner Books).
- **UI polish batch**: restored the owner's *"sloshway of cooperation"* blurb (LinkDevice); swept the
   leftover `⚯` glyph from TunerFace + InvitePanel friend rows (RadioFace was done earlier); added the
    `navigator.storage.persist()` one-liner at boot in SwarmStandup (Portability §0.9b — clear-data =
     identity-death mitigation).

**Next moves (vague candidates, pick by appetite):**
1. **Direct file play / SoundPool whole-things** (the owner: *"local radio could just play files
    directly a lot of the time, or it means play from the SoundPool, whole things"*).  The self
     Radio doesn't need the chunked-Record pipeline for most of what it does — a local file (FSA)
      or a whole LOFI copy (OPFS SoundPool) can feed the element directly.  Piecemeal connections
       waiting: `Ra_press`/`Ra_quarter`/`Ra_quarter_serve` are built + Book-proven with NO live
        callers (Portability_todo), and the listen-only MountNav pool mount stands.  Plot this as
         its own rung ladder before touching Radio_supply — it is the §3/§4-delicate area.
2. **Verify the deaf→sound handover feels right**: autopress rolls the pipeline silently; the first
    touch resumes the AC via the keep-awake tumble.  Watch a real first-touch — does sound arrive
     mid-track (good) or restart (bad)?  The roster read "playing but silent — analyser reads 0"
      (`dry`, not `deaf`) — check that verdict is honest on a gestureless tab.
3. **LinkDevice quality pass** (the owner's loop: *"working out why they don't LinkDevice too
    good"*): live two-device ferry test; the `_1` relay-suffix race on reload (a reloaded tab's old
     socket family holds the bare addr — mirror ownership defers) may bite the ceremony.
4. **The orphan-identity cull**: 12 souls in one Incognito `.jamsend/account/`, no `active` marker,
    fresh mint per early reload (the no-time-to-wait-for-FSA race).  Rule: cull identities with
     nothing to them (no piers, no grants, no content) when noticed.  Cheap sweep, someday.

**The bombs (what detonates if the next fork doesn't know):**
- A cold tab RUNS NO BEATS.  `step_n` stays `1` forever after the 1-step check — `n == null` guards
   in the drive don't fire either.  The seams that DO run for a stranger: the commission landing,
    `Radio_nudge`'s callers (per stood record), SwarmStandup's settle-edge, and the Supervisor 2s
     heartbeat (READ-ONLY — probes must never mutate; an autopress from a probe is a firing offence).
- `vw_frame` is a render-only fact with one writer (Vytui `publish_frame`).  Model logic must never
   wait on it; the machine stamps its own default at the commission seam.
- Every live-tab behaviour rides the HUMDINGER gate; Books record on runner tabs without it, so
   recorded fixtures stay byte-identical by construction.  Break that discipline and the Vyto* /
    MusuRa* fixture set goes red.
