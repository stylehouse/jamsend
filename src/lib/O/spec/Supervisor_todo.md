# Supervisor — knowing when to give up and reload

*Opened 2026-08-08, from the human: "there has to be a supervisor built still, to discern all these
 moments when we should give up and reload."*

---

## 0. Get on with next

> ⚠ **This section is 1,703 lines of diary holding ~28 open decisions.** For *what is actually
>  open, what is cut, and what needs the owner's word*, read **`V1_cut_todo.md`** first — five
>   questions and a ship-blocker list, built from this section on 2026-08-11. What follows stays
>    authoritative for HOW each thing landed, and is due the same brief-not-a-log treatment
>     (diary → `spec/history/Supervisor_buildlog.md`).

> ### 2026-08-11 (night) — WHAT LANDED, WHAT WAS DISPROVEN, WHAT'S NEXT
>
> **DEFECT 1 IS SOLVED, and the answer supersedes the ":2065 leading candidate" below.** The
>  open-share tap could never appear on ANY BigQualand page, regardless of `disk_gated`:
>   `boot_gate(H, …)` captured the `H` PROP BY VALUE at component init, and on a qualand page the
>    House is assigned inside an `$effect` (the OOM-trap pattern), so both `Butler` and `BootGate`
>     mounted with `H` null and the gate polled `null?.c?.disk_gated` for the life of the tab — no
>      disk tap, no musu_gat, no AC tap. Otro constructs `H` before render, which is why the same
>       gate looked healthy on dev pages. **Fixed: `boot_gate` takes a getter** (`() => H`), both
>        call sites updated; header note in `boot_gate.svelte.ts` records the trap. VERIFIED LIVE by
>         the owner hitting the tap and granting an (empty) folder minutes later.
> **Also fixed on the same path**: `restoreDirectoryHandle` used to call `requestPermission` at BOOT
>  (no gesture → throws → the catch DELETED the stored handle — every browser restart cost the
>   remembered share). Now it re-asks only under `navigator.userActivation.isActive`, and the
>    `open_dir` action retries `fsh.start()` inside the tap's gesture first — a remembered handle
>     re-grants WITHOUT the picker; only a new user or a dead handle sees the picker.
>
> **NEW, seen live minutes after the tap went in — THE EMPTY-SHARE FAIL-NOISE.** The owner granted
>  an empty folder: `[FAILED] there is music in your share … still looking — 336 folders walked`.
>   Diagnosis (code-read, high confidence): `Radio_shelf_walked` reads `TOP.c.meander_stood`, a
>    per-SESSION counter that never resets on a mid-session share swap — the 336 belongs to the
>     PREVIOUS nav's walk. Consequences: the probe can never reach its honest empty-share branch
>      (`no music in your share — open a folder with some in it` requires walked==0), and once the
>       count stops climbing the 15s patience trips → FAILED beside a "still looking" note that is
>        no longer true. **FIXED 2026-08-11 (later), both halves as sketched**: `open_dir`'s
>         fn resets `meander_stood` on a grant (Housing.svelte.ts — the full-reload was taken while
>          the owner was away; both players re-crated in seconds via the new come-back path); the
>           registrar stamps `watch.sc.advice` and `Radio_probe_shelf`'s empty branch returns that
>            same give-up sentence ("no music found here — add some, or open a different folder") as
>             its note once `Supervisor_given_up('radio.shelf')` says so — the patience re-arms while
>              the walk advances, so an expired clock genuinely means the looking has stopped. The
>               roster lives on Mundo, so no fixture moves. NOT yet seen live (needs an empty-share
>                grant to trip it).
>
> **THE PROSTHETIC WORMHOLE is now an explicit directive** (the owner, same night): *"we still need
>  a prosthetic wormhole/ for the Invitee — and any normal user that won't be pointing this at the
>   git repo, needs to have wormhole/ remounted into .jamsend/... or something."* Shape options,
>    both rooted at the DirectoryOpener seam (`Housing.svelte.ts` w:Wormhole):
>    · **Materialise**: seed `wormhole/` INTO `<share>/.jamsend/wormhole/` from the app (the
>       OPFS-github cloud already knows how to fetch the tree), and teach the nav to serve
>        `wormhole/` from there when the share has none. Real files, everything downstream works;
>         needs a staleness story (app updates vs the copy).
>    · **Compose**: a composite nav — `wormhole/` prefix → the OPFS cloud, everything else → the
>       granted dir. No writes into their music; always current; needs a new nav class honouring
>        `WormholeNav`'s interface (`Housing.svelte.ts:2508`; `RemoteWormholeNav.svelte.ts` proves
>         a second implementation already exists, `is_remote` is the recognition idiom).
>    The `.jamsend/` remount wording suggests the owner leans MATERIALISE. Either way the empty
>     `A.c.nav = null` on grant (a granted dir REPLACES the cloud) is the line that must change —
>      see memory `a-granted-directory-replaces-the-app`.
>
> **Swarm/Radio landings tonight** (details in Radio_todo §0): the frame-reliability no-ops are
>  reverted; `repli_ready` (grant ACTIVATION, accelerator-not-gate) landed with verification OPEN;
>   `Swarm_expect_joining` + the every-rung Radio hold for `because='joining'` + the seal-time
>    `aim_wish` favour landed (SwarmInvite 5/5 green, SwarmShare exactly its 8-caveat baseline).
>
> ### 2026-08-11 (owner, in passing, away) — THE STASH: A SECOND FSA FOR THE ACCOUNT, AND THE TAP SHOWS TOO OFTEN
>
> **Two directives arrived mid-session, verbatim-close, neither built yet — both belong to this flow.**
>
> **1. THE STASH — "open share" AND "open stash".** *"if they want their .jamsend credentials stored
>  somewhere more private than their music collection, they need to open a second FSA … have an 'open
>   share' AND an 'open stash', the latter with explanation that other ways to share your music can
>    leak your jamsend account data. you have to create a MyJamsendData directory somewhere… that's a
>     bit of a naff design, yes, requiring the user to create a directory for us to own… it's also how
>      to recover your account on a new browser, from disk."*  What grounds it in the tree already:
>  · The leak is REAL and locatable: the account snap lives at `<share>/.jamsend/account/<prepub>`
>     (Swarm.g:2875) — keypair INLINE by design (the backup must be self-sufficient, Swarm.g's
>      portability header) — so anyone who syncs/shares their music folder ships their signing key.
>  · The export/import machinery EXISTS: `Swarm_export` (account C-snap, one blob) / `Swarm_import` /
>     `Swarm_boot_seed` (disk-seeded account → graft) — the stash is a WHERE, not a new mechanism.
>  · The handle store already keys by name (Dexie `Handle`, per-origin), so a second FSA handle under
>     a `stash` key is the same restore machinery run twice.
>  **The decisions this needs (owner)**: (a) the MODE — "hopefully we just switch them to that mode
>   (where? site wide but persisted…)": a pref must survive a new browser, where there is no Dexie
>    yet — so recovery order is Butler-door-first ("open stash" → `Swarm_boot_seed` from it), and the
>     mode itself can only be persisted per-origin AFTER first contact; (b) whether stash-mode STOPS
>      writing `.jamsend/account` into the share (the point of the mode) and what migrates the
>       already-written one out; (c) how this composes with the prosthetic-wormhole write-routing
>        question (design question (c) below — the stash answers its "identity" third, and is a
>         natural home for radiostock/keeps if the share goes read-only…); (d) the naff-but-honest
>          MyJamsendData creation UX.  **Fold into the six-step flow as an optional step 4b.**
>
> **2. "THE 'open share' BUTTON SHOWS UP TOO OFTEN, when we do in fact have FSA granted."**  Not
>  reproducible from this container; the diagnosis is one console read on a tab showing the tap:
>   the stored handle's `queryPermission({mode:'readwrite'})`.  The fork:
>   · **'prompt'** → browser policy, not our bug: Chromium downgrades FSA grants at browser restart
>      unless "allow on every visit" was ticked on a re-prompt.  Our restore already re-grants
>       picker-free inside the tap's gesture (the 2026-08-11 fix); making it ZERO-tap needs the
>        persistent-permission checkbox (it rides `requestPermission`'s own dialog), PWA install, or
>         possibly `navigator.storage.persist()` — measure before building.  A cheap honesty win
>          either way: when a REMEMBERED handle exists the tap should say *resume 〈dirname〉*, not
>           *open share* — same gesture, honest promise (no picker coming).
>   · **'granted'** → a real restore-ordering bug in the wormhole step (fsh created but start() not
>      reached before `disk_gated` rises?) — instrument the step's branches before touching them.
>   Note the picker and the query BOTH use `readwrite` (Directory.svelte.ts:448, Housing:2040), so a
>    read/readwrite mode mismatch is ruled out by code-read.
>
> ### 2026-08-11 (later) — THE DESIGN DECISION IS TAKEN AND THE BLANK CARD IS DEAD (landed, verification part-owed)
>
> **The one design decision below is taken: YES — the Butler shows the door whenever the person has
>  no friends yet.** The doc's own argument carried it (survives reload, the one action worth
>   offering, kills the blank card at its root); the owner was away and can reverse one line.
>    What landed, all three within the pre-roster vocabulary rule:
>  · **`H.c.door_friends`** — the friend count, stamped by **SwarmStandup** (NOT InvitePanel as first
>     sketched: the panel is a sometimes-mounted FACE now, its own header says so, and a fact the
>      Butler needs before any door is drawn cannot ride a component that mounts after it). Its own
>       key, not a field on `H.c.door` — the panel replaces that object wholesale every pass, and two
>        writers onto one state is boot_gate's lesson. **ABSENT ≠ ZERO**: stamped only once a self
>         stands and `Swarm_peering` exists, so a pre-ghost tab reads unknown and only a COUNTED zero
>          opens a door — no join-offer flash on established boots.
>  · **`stage` in Butler.svelte** — exactly one of `door | tap | arc | dark`, defect 2's fix as
>     sketched. Ladder order is the six-step flow's: unresolved token → door (the HOLD); gate.wanted
>      → tap; counted-zero friends → door (the OFFER, never a hold — it does not block the arrival
>       lift, a deliberate solo listener still arrives and the Butler goes); roster lines → arc;
>        else **dark**, the honest floor ("starting up") that makes a blank card unreachable.
>         `sealed` from the sketch is SUBSUMED: the panel's ✓ report is the sealed surface and the
>          seal flips the friend count, which advances the ladder to `tap` — step 4 of the flow now
>           exists, reached by state rather than by a screen nobody wrote.
>  · **Advice + remedy outrank the stage** (except under a landing hold): a friendless tab whose
>     radio parked on a gesture keeps "▶ start the music" reachable under the door — the one press
>      that cures the page must never hide behind the offer to make a friend.
>  **Deliberate change riding along**: the arc no longer renders under the tap (one stage at a time,
>   per the sketch). The rows are never lost — panel + `runner_ask supervisor` keep them.
>  **VERIFICATION OWED**: svelte-check clean on both files, live tabs took the HMR unharmed (both
>   players still streaming, door_friends 3/1 there is >0 so nothing changed for them) — but the
>    FRIENDLESS cases (dark floor → door offer on a fresh identity; door hold surviving a reload)
>     need a fresh-identity tab, and this container cannot launch chromium (pw_drive.mjs mode B
>      needs the host; mode A needs your CDP bridge). **Owner: one look at a fresh ?I= tab, or
>       expose CDP and any session can drive it.**
>  **NOT touched, still yours**: the prosthetic wormhole (defect 4 + defect 1 must land together —
>   design questions (a)–(d) below are unanswered and I did not guess); the per-invite dismissal
>    that must precede the stricter fulfilled=SEALED hold; the `:2065` one-line console check.
>
> ### ⇒ THE NEXT PIECE OF WORK: **THE BUTLER HAS NEVER INTRODUCED A NEW USER** (2026-08-11)
>
> *The owner, watching a freshly-invited tab: "there's nothing there in the Butler… why no action?
>  there's a bunch of Butler that has to UX the Invite process for them too. it was all in
>   Tyranny.svelte before." Then: "it just seems like we never thought of having the Butler introduce
>    a new user. lets work that flow out now."*
>
> **THE BOMB, and nothing about this flow can be designed without it: the Butler's ONLY content source
>  is the Supervisor roster, and the roster does not exist yet during onboarding.** `Supervisor_up` is
>   called from `Auto.svelte:798` guarded `if ((H as any).Supervisor_up)` — it is a GHOST method, so the
>    world only stands once the Creduler has loaded the spine. The spine loads off the wormhole. The
>     wormhole needs a share. A new user has no share. So the whole chain
>      **no share → no wormhole → no ghosts → no `w:Supervisor` → no watches → no Story → no arrival**
>       runs to completion before the Butler has one row to draw, and `Supervisor_watch` is documented
>        to be a silent no-op when there is no Supervisor. **Every onboarding state is pre-roster.**
>  Do not try to model this flow as watches. It has to come from what exists BEFORE the ghosts:
>   `boot_gate` (`H.c.disk_gated` + the gats), `H.c.door` (InvitePanel's own published state), and the
>    URL. That is the entire vocabulary available, and it is enough.
>
> **THREE DEFECTS FOUND WHILE PROVING IT.** All three fire on the same tab, which is why it looked like
>  one mystery:
>  1. **NO OPEN-SHARE BUTTON REACHES THE NEW USER — but NOT for the reason first written here.**
>      ⚠ **CORRECTION (same session).** The first diagnosis said `disk_gated` is only raised under
>       `?E=`/`?B=` and that a music room therefore never asks. **That is false and any fix built on it
>        is a no-op.** `/BigSoundland` boots through `boot_qualand({role:'sound'})`, which sets
>         `h.c.boot_role = 'runner'` (`BigQualand.svelte.ts:60`) — so `boot_role` IS set, the
>          `Housing.svelte.ts:2093` branch IS reachable, and `disk_gated` WOULD rise. A proposed
>           `if (boot_role || humdinger)` changes nothing. Recorded because the wrong version was
>            written down confidently and would waste the next session's first hour.
>      **What is actually true:** the button is drawn off `gate.wanted`, i.e. `H.c.disk_gated`, and on
>       the stuck tab it is falsy — otherwise the orange tap would be on screen. So the wormhole step
>        RETURNED BEFORE :2105, and there are exactly two ways out above it:
>        · **:2065** `fsh.started && fsh.list` — a handle was RESTORED (the FSA store is per-ORIGIN, not
>           per-identity, so a brand-new identity in the same browser profile inherits whatever
>            directory the other tabs granted) → sets `disk_gated = false` and reports a share is open.
>        · **:2099** `remote_wormhole && boot_role === 'runner'` — waiting on an editor to proxy the
>           tree; raises nothing by design.
>      **The leading candidate is :2065, and it is the SAME fact as defect 4 below**: the tab believes
>       it has a share, so it never asks — and the share it has does not contain `wormhole/`.
>      **THE ONE-LINE CHECK that settles it**, in that tab's console:
>       `H.c.disk_gated, H.c.remote_wormhole, H.o({A:'Wormhole'})[0]?.c?.fsh?.list?.name`
>       — a directory NAME that is not the repo checkout convicts :2065 and defect 4 in one read.
>  2. **THE CARD CAN RENDER COMPLETELY BLANK, and does.** The markup is a pile of INDEPENDENT `{#if}`s
>      — door · tap · headline · arc · advice — and on a reloaded invited tab every one of them is
>       false at once: `?Iz` was stripped to `?I=` so `landing_seen` never latched; `disk_gated` is
>        false (defect 1); `settled` is false because `arrived` is `'none'` not `'gaveup'`; the roster
>         is empty so there is no arc and no advice. **There is no floor state.** The fix is structural,
>          not another `{#if}`: one `stage` derived that always returns exactly one of
>           `door | sealed | tap | arc | dark`, every branch rendering something, `dark` being the
>            honest "we are up before the machine is" that the headline comment already promises and
>             the markup does not deliver.
>  3. **`landing` MEANT *PRESENT*, NOT *UNRESOLVED*** — fixed today, in the tree. It was
>      `!!boot_param('Iz')`, and the lift effect does `if (landing) return`. `strip_iz` only fires on
>       the three paths that REACH a terminal state; `join()` has two early returns that do not (the
>        ghosts-still-booting bail, the relay-did-not-answer bail) and an older identity keeps a
>         deliberate JOIN button that may never be pressed. In all of those the token stays and the
>          screen is **welded shut with no timer** — the exact trap this file exists not to be, reached
>           through the one door nobody re-checked. It now reads `H.c.door.note` for a ✓/✗ terminal.
>
>  4. **A REAL USER'S SHARE IS THEIR MUSIC, AND IT HAS NO `wormhole/` IN IT.** *(The owner: "we're
>      going to need some kind of wormhole/backend virtualiser for providing Story/Sounditron etc that
>       random users don't have on disk — they point the share at their music collections.")* This is
>        the deepest of the four and it is an ARCHITECTURE item, not a bug.
>      `A.c.nav` is ONE nav, and granting a directory **replaces** it — `Housing.svelte.ts:2081-2083`,
>       `A.c.nav = null` with the comment *"a granted local dir overrides the cloud"*. So the moment a
>        person points the picker at `~/Music`, the wormhole is rooted at `~/Music`, which contains no
>         `wormhole/Story/Sounditron/toc.snap`, no Books, no spine. Story cannot start, no watch
>          registers, no arrival is declared — **the whole chain in the bomb above, arrived at from the
>           other end.** Everything works today only because the developer's share IS the repo
>            [[the-share-is-the-repo-itself]], which is a dev accident, never a user fact.
>      **HALF THE MECHANISM ALREADY EXISTS.** The OPFS-from-github cloud (`is_opfs_github`) is exactly
>       "the app's own tree, seeded from github, with no directory picker" — the file calls it *"a
>        github-seeded shadow disk, honest for a param-less Auto demo out in the world"*. What is
>         missing is not a backend, it is **COMPOSITION**: one namespace over two roots — `wormhole/`
>          from the seeded cloud (app assets, read-only, versioned with the build) and the user's
>           granted directory for music (read-write, theirs). Today they are alternatives; they need to
>            be layers.
>      **The design questions to settle before writing any of it**, in order: (a) does the user's music
>       mount UNDER the virtual tree at a fixed point (the repo's own `/music` convention) or beside
>        it; (b) which root wins on a path collision, and is that fixed or per-prefix; (c) what writes
>         go where — a Story snap, a Heist keep and a radiostock card have three different homes and
>          only one of them is the user's; (d) how the cloud layer VERSIONS, since a stale seeded
>           `wormhole/` against a newer build is the same fixture-drift problem one level down.
>      ⚠ **THIS AND DEFECT 1 MUST LAND TOGETHER.** Making the open-share tap appear for a real user,
>       on its own, converts a blank Butler into a blank Butler with one extra tap — because the
>        directory they choose will not contain the app. Shipping half of this is worse than shipping
>         neither, since the tap teaches them the app is broken rather than unstarted.
>
> **WHAT THE FLOW ACTUALLY IS**, six steps, of which the app today implements 1–3 and 5–6:
>  `land (?Iz, "you were invited by X") → name + JOIN → sealed → ***open your music*** → spine + Story
>   → arrive`. **Step 4 does not exist**, and steps 1–3 vanish on any reload because they are keyed to a
>    single-use token that deletes itself. A person who scans, joins, and reloads gets a black card.
>
> **THE OWNER'S RULING ON WHAT "DONE WITH AN INVITE" MEANS** (2026-08-11): *"the Butler should stay on
>  every Invite it discovers until it is fulfilled, leaving them in the URL until then… certainly not
>   letting you into the app until you have sorted that out."*  Three things fall out of that sentence
>    and each is a change:
>   · **FULFILLED = SEALED, not redeemed.** `strip_iz` fires immediately after `Swarm_redeem` returns a
>      claim, BEFORE the seal watch, and `join()` has early returns that never strip at all. Moving it
>       to seal-time is what "leaving them in the URL until then" asks for — and it deliberately
>        re-introduces the stranding its own comment says it was moved to fix (*"gating the swap on an
>         8s seal window stranded ?Iz whenever the seal ran late"*). That tension is real and is
>          resolved by the dismissal below, not by picking a side.
>   · **EVERY invite it DISCOVERS — the plural is load-bearing.** The URL's `?Iz` is one. A pasted token
>      is a second. A discovered-but-unspent one is a third. Today `landing` is a single boolean over
>       `boot_param('Iz')`; the end state is a LIST the Butler holds until each entry is fulfilled or
>        explicitly given up on, which is a different data shape and should be built as one.
>   · ⚠ **THE DISMISSAL IS A PREREQUISITE, NOT A FOLLOW-UP.** Holding on a ✗ with no way out is a
>      permanent trap on a screen that has no timer by design — the same trap the `landing` fix landed
>       today was written to remove. **Do not ship the stricter hold before an explicit per-invite
>        "give up on this one" exists.** The interim in `Butler.svelte` releases on either terminal
>         (✓ or ✗): sometimes too lenient, never a trap. That ordering is the whole ruling.
>
> **THE ONE DESIGN DECISION TO MAKE FIRST** (do not build past it): should the Butler show the door
>  whenever the person **has no friends yet** — not merely when a token is in the bar? That single
>   change makes onboarding survive a reload, gives a friendless tab the one action worth offering, and
>    removes the "blank card" case at its root. It needs InvitePanel to publish its friend count on
>     `H.c.door` (it already computes `friends`, :90, and already publishes the door object, :386) so
>      the Butler can ask the door instead of reaching for `Swarm_*` — which it may not do, by its own
>       standing rule that it names no subsystem.
>
> **DO NOT PORT Tyranny.svelte.** It is the PREVIOUS generation's trust machine (Idzeug/Tyrant/invitee,
>  978 lines, mostly logic). `InvitePanel` is the current implementation of mint→parse→seal→spent and
>   is Book-proven by SwarmInvite. This is a WIRING problem — the panel is fine and is simply not
>    mounted when the new user needs it.
>
> **The transport is innocent and was checked** — Lefto pulses straight to the stuck tab with a signed
>  voucher and `saw:` set, so the station bound and the era crossed both ways. Everything failing here
>   is above the wire. Do not go looking at the relay.
>
> **In the working tree (2026-08-11, corrected later the same night):** the recap trio
>  (`Swarm_recap_ask`/`_serve`/`_offer_reset`) was REVERTED with the other frame-reliability patches
>   — the stale claim that it sat unwired in the tree cost a re-read; the tree's come-back machinery
>    is `repli_ready` + **`Swarm_offer_now`** (the immediate-offer reply, landed and verified —
>     come-back 13.6s from 65–74s, Radio_todo §0 has the closure). `Butler.svelte` carries
>      defect 3's fix. Several Vyto files in the tree belong to a concurrent agent, not this work.
>  **Added later the same night (the owner's "kinda jammed" reload):** the share-arm was queued
>   behind the WHOLE arrival Book (~13s good / ~33s jammed) — `Stoker_ensure`'s prod gate now
>    treats `top.c.humdinger` as prod so the seam arm fires at the `radio_w` stamp (beat 1, ~3s),
>     and `SwarmStandup.svelte` gained a 750ms wall-clock tick because Mundo's version holds still
>      ~10s at a stretch during the Book (its arming effects starved — measured). Come-back now
>       ~3.5–5s both directions; ring keeps marks `glass-ensure`/`radio-w-stood`/`share-armed-by`/
>        `share-ask`. Radio_todo §0 has the full diagnosis.

> **THE RELOAD HAPPENED AND ALL THREE ARE PROVEN** (2026-08-10 late — the banner that stood here said
>  they were written-but-unwatched; they are not any more). On Righto beside Lefto: the watch sentences
>   render (`swarm.station` *"you are online — friends can reach you"*, `swarm.arrival` *"Lefto"*, 11
>    watches vs 9), the boot waterfall draws, and **`Radio_crossover` fired TWICE on two independent
>     boots** — `crossover playable=2 of=Lefto`, solo ◐ → cut-in → solo ·. Details in Radio_todo §0.
>  **WHAT IS STILL OWED, and it is now the real §0:** (1) **WHY DOES A SKIP ALWAYS FIX IT** — three
>   times on live tabs, a full friend pool standing and nothing playing, cured instantly by next-track.
>    The pump reschedules on both a null dial AND a throw, so it is not a dead chain. Live suspect:
>     `Radio_pump_soon` is a bare `setTimeout` with **no visibility handling anywhere in Radio.g**, and
>      a backgrounded tab has its timers throttled. One measurement decides it — stamp the pump's wake
>       times, boot focused vs backgrounded. A recovery (auto-skip at the give-up seam) is now taken so
>        nobody has to press it, but it is scaffolding over an unknown cause and should be DELETED when
>         the cause lands, not grown. Radio_todo §0. (2) The **`Radio_source_toggle` solo fix** and its
>          RED half. (3) **(a)/(b) from the frozen-roster entry** — the Auto stamp, one electrode short.
>  **A give-up is a promise that the advice is now true**, and it was broken twice tonight in opposite
>   directions: once saying "pick something to hear" when nothing pressable would start it, once giving
>    up at all when a skip would have worked. Both are the same failure — a hardcoded sentence outliving
>     the state it was written for. The advice is live now, and carries a `remedy` word.
>  **Read `read_ago` in the header before believing any row** — a frozen roster shows its last verdicts
>   and they are usually green. That is what this whole session started as. Corroborated tonight from
>    the other side: across two HMR re-stands the rosters stayed at 0.3–0.9s while `arrived` correctly
>     fell back to `coming`. A frozen one would have kept insisting `arrived`. [[a-frozen-roster-reads-green]]

### ⇑ 2026-08-10 (latest) — A RADIO THAT SAYS 'playing' WITH NO DEVICE, AND THE ADVICE THAT CANNOT BE TAKEN

*The owner, reading Righto's own give-up sentence off the arrival screen: "the 'carry on in and pick
 something to hear' is wrong. I think we need to kick something in the Radio causality chain."*
  They were right, and the chain is four links — each one individually reasonable.

**The state, measured, not inferred.** `runner_ask probe --player=` said
 `{"state":"suspended","realtime":0,"rms":0}` while `poke Radio_skip` said
  `{"was":"playing","now":"playing","title":null}`. A radio in `'playing'` with **no record, no audio
   device and a suspended AudioContext** — and a Supervisor reading `loud:0 amiss:0` over it.

1. **`Radio_go` sets the state BEFORE it earns it** (Radio.g:129–130): `Radio_state(radio,'playing')`
    then `await this.Sound_gat()`. `Sound_gat` awaits `g.init()` (Sound.g:210–221), whose AC resume
     needs a user gesture. On a tab that never got one, the await simply never returns.
2. **The one diagnosis that names this cannot reach it.** `Sounditron_music_why` (Sounditron.g:1391+)
    already has the sentence — *"stock stands but the press never took (Radio_go awaits Sound_gat,
     which pends forever on a gestureless tab)"* — and gates it on `s === 'off' || s === 'paused'`
      (:1407). Link 1 guarantees `s === 'playing'`. **The branch is unreachable in exactly the state it
       describes**, so the advice falls through to the generic *"nothing has started playing on its own
        — carry on in and pick something to hear"*.
3. **The advice is not merely wrong, it is unfollowable.** `Radio_toggle` (:116–122) reads `'playing'`
    and calls `Radio_pause`. **The play button pauses.** There is nothing on the page a listener can
     press that starts music.
4. **And nothing will fix it in the background.** `Radio_nudge`'s pump gate (`!== 'digging'`, :1611)
    refuses to restart a radio it believes is playing. `Radio_skip` with no `c.gat` re-enters
     `Radio_go` (:177–179) and re-parks on the same await. The poke above is that loop, observed.

**Why this belongs in THIS file and not just Radio's.** Every probe was honest and the roster was
 fresh; `loud:0 amiss:0` was *correct* about the rows it had. What no row owned was the composite —
  a state where the machine is calm, the instruments agree, and the page is dead. `arrive.playing`
   eventually gave up, which is the give-up ladder working — and then handed over the one sentence
    that could not be acted on. **A give-up is a promise that the advice is now true**; that is the
     whole reason §2 lets the model speak at all, and a hardcoded string cannot keep it.

**The fixes, in the order they are worth doing** — none applied yet, all one-liners:
 (a) move `Radio_state(radio,'playing')` BELOW the `await Sound_gat()` (and set something honest —
  `'digging'` or a parked state — above it), so the flag follows the device rather than predicting it;
   (b) widen `Sounditron_music_why`'s gesture branch to test `probe.realtime` regardless of `s`, since
    a suspended AC is the fact and the state word is not; (c) make `Radio_toggle` not pause a radio
     with no `c.gat`. (a) is the cause; (b) and (c) are the two places it became invisible and
      unrecoverable. [[a-red-you-explained-away]] — every reading here was individually reassuring.

**The Butler changed while standing in front of this.** The *carry on* tap is gone (the owner: it was
 a second door onto an exit ▦ already draws better, and its loud form said "carry on in and pick
  something to hear" at precisely the moment that is unfollowable). In its place, gated on `gaveup`
   alone — the model's ruling, never the face's guess — **a reload button**, because the state above is
    genuinely unrecoverable from inside the page and a reload is the honest remedy. `IMPATIENT_MS`,
     `impatient` and `carried_on` went with the tap; ▦ (drawn by the page, z-index 999999, every room,
      unconditional) is now the ONLY dismissal, which is noted in BigSoundland so nobody removes it.
 Also: `invite a friend` finally wears `.ip-go` instead of the muted `.ip-act` chip (the owner: *"the
  Invite… needs to look more like a button"*) — the same finding InvitePanel recorded on 2026-08-08 for
   the two-step door and never applied to the mint half.

### ⇑ 2026-08-10 — THE BUTLER IS A BOOT LOG, AND THE FIRST FRIEND TRACK CUTS IN

*The owner, watching the arrival screen: "must say less junk in the meantime… perhaps just make it
 look like Linux starting up `[ OK ] friend is online: $randompick`". Then: "it should switch to
  playing from the peer's stream when their first track becomes ready."*

**The Butler is now a boot log.** One monospace column, the model's six tones rendered as
 `[  OK  ] [FAILED] [ .... ] [ SKIP ] [  ??  ]` and a blank bracket for not-yet, with the probe's own
  note on the same line after a colon — `[  OK  ] a friend is online: Righto`. It re-decides nothing:
   `tone` is `Supervisor_tone`'s word and this file maps word → appearance, which is the only half a
    face owns. Everybody already knows how to read that left margin; that is the whole argument.

**What went, and why each was junk.** The **spinner** — the `[ .... ]` bracket on the row we are
 actually waiting for says the same thing in the place the eye is already reading. The **headline** —
  it restated the row the log was already showing, one line above it (it survives for the one case the
   log cannot state: the model has given up and there is no next line coming). The **notice ring** —
    the same facts a second time, in a different order, under a second set of timestamps, so a listener
     read everything twice and had to work out which list was which. **Two lists is not more
      information, it is more reading.** Nothing is lost: the ring is still on the model, the panel
       shows all twelve, and `runner_ask supervisor` prints it.

**And `Radio_crossover`.** "A playing radio is not deaf" (2026-08-08) fixed the deafness by restaling
 the lineup — but a lineup entry is the NEXT track, so a listener sat through the rest of a stopgap
  before hearing the thing they opened the app for. Waiting is right for every later track and wrong
   for the first, because **the first friend track is the moment the app becomes what it is for.**
    Four gates keep it from being the track-cutting bug it replaces: once a sitting (`c.crossed`), only
     out of solo (never cut a friend's track to start another friend's), only when something is
      genuinely playable (`Radio_playable`, not "a card exists"), and throttled to 1.5s — `Radio_nudge`
       runs PER LANDED CHUNK and `Radio_pool_census` walks every crate, which is the 2026-08-06 burn
        this function is shaped around. It calls `Radio_skip`, which blends rather than cuts, and lets
         the dial's existing friend preference choose — rather than growing a second opinion.

**Not yet seen fire.** Both player tabs were already past solo when it landed, so the `crossover`
 mark wants a fresh boot beside a friend with music. That is the thing to look for next.

*(And a question answered while here: yes, the relay has the bulk presence op the owner remembered —
 `{control:'who', addrs:[…]}` → `who_ok {online}`, list-in-only, hello-bound askers only, `Presence.g`
  on the client with a three-valued `Presence_live`. But `sound.live` — the Butler's "a friend is
   online" — does NOT read it: it reads `pier.c.heard_at`, which is APPLICATION presence, and
    Presence.g's own contract says the two must stay separate particles. Reading both is the documented
     shape and would turn that row green a pulse-round sooner. Not done.)*

### ⇑ 2026-08-10 — THE ROSTER WAS A PHOTOGRAPH AGAIN, AND NOTHING SAID SO

**Both of the owner's player tabs had a frozen Supervisor and read all-green.** Asked to look at the
 live players, the first thing that fell out was two rosters stamped `arrived:arrived`, `loud:0`,
  `amiss:0` — and stopped dead. `read_ago` said **686s on each, to the same second**.

*What they were still saying while frozen:* `radio.solo` — *"listening alone — your own music while we
 gather"* — over a friend's **third consecutive track** in 51 seconds (`Radio:playing … by_name:Righto`,
  `solo` deleted from sc, `played` 10 → 11 → 12). `radio.shelf` — *"8 records"* — against a live
   `Stoker … stock=16`. `radio.remote` — *"3 playable of 7"* — against a crate holding 16.

**Nothing was lying. Nothing was looking.** That distinction is the whole entry.

**The near-miss worth recording.** The first two hypotheses were both wrong and both fit the evidence:
 *two same-named worlds* (a re-run leaving the roster pointed at a corpse), and *a Book hijacking the
  roster onto its own throwaway world*. Killing them cost one field — `Supervisor_where`, which prints
   the House, mainkey and `self,est` birth stamp of the world each row actually read. Every row on both
    tabs said `in:H:Sounditron/w:Sounditron#353491`. **One world. Both theories dead in one read.** It
     stays, because `orphan` only catches "the world is gone" and never "the world is not the one you
      are looking at", and that gap is invisible from every other angle.

**The real cause: `Supervisor_tick` had exactly one caller — Auto's pass — and Auto rides the belief
 drive, which is a thing that STOPS.** An HMR wedges it (a `.svelte` save reaches every live tab
  gesture-free, which is why both tabs froze on the same second and a runner with no Book did not); a
   throw upstream in the same pass skips everything below it. This is the *same* bug the heartbeat was
    added to fix six hours earlier, moved out one level — and it hid the same way, because a frozen
     roster keeps showing whatever it happened to be holding, and what it was holding was green.

**Fixed by giving the heartbeat its own wall clock** (`Supervisor_beat`, a 2s detached chain armed once
 from `Supervisor_up`). The argument is this file's own, one level further out: it already refuses to
  live inside the Run House because *"the failure a supervisor most needs to report is the one that
   kills the House it lives in"* — and **a watcher that rides the drive cannot report a stopped drive.**
    Cost is one probe pass every 2s on a tab where nothing else is happening; while the drive turns,
     Auto reaches the tick far more often and the 1s throttle collapses both callers into one read.

**And `read_ago` now rides the reply**, so `runner_ask supervisor` says `(read 0.4s ago)` or shouts
 `⚠ STALE: last read 686s ago — every row below is a photograph`. Verified live on the claude runner:
  6s stale before the change, **0.3s and 0.5s after**. *A stale instrument that looks fresh is worse
   than no instrument* — and this one had already cost an hour of theorising about worlds.

**Both frozen tabs healed on the compile, with no reload** — `read 0.0s` and `read 0.4s`, both playing
 each other's tracks, 16/16 crates each way, ~40–53 KB/s both directions. Expected them to need one; they
  did not. **Which means the cause is NOT yet settled**, and the entry above should not be read as if it
   were: two stories fit every reading taken. Either Auto's pass was wedged 21:18→21:31 and the ghost
    HMR restarted it (and *that* pass armed the beat), or Auto was turning the whole time and
     `Supervisor_tick` alone was never reaching its work, with the new beat now bypassing whatever
      blocked it. **The timing and the runner-vs-player split argue for the first. Nothing observed
       excludes the second.** The fix is right either way — a watcher wants its own clock regardless —
        but the *diagnosis* is still one electrode short, so do not quote it as settled.

**Next, in order.** (a) *Was the drive wedged at all?* One stamp on the Auto pass, the same shape as
 `read_ago`, and both stories separate on sight. Until then this is deduction, not observation — and
  §2's rule applies to me as much as to a probe. (b) *The Supervisor should WATCH the drive.* It now has
   a clock the drive cannot stop, which is exactly what is needed to notice Auto has quit — but the
    claim needs a registrar that owns it (Auto stamps, Supervisor reads), not a probe reaching into
     someone else's business. (a) is the prerequisite for (b) and they are the same stamp.

### ⇑ 2026-08-10 — THE LAST CLOCK IS OUT OF THE BUTLER, AND ▦ IS BEHIND ONE SWITCH

**The Butler now lifts on ARRIVAL and on nothing else automatic.** The owner, watching it: *"Butler
 quits very soon, only one goal is listed"*, then *"it quits right after 'friend comes online' which I
  can only just see as it fades out — we want it to wait until the Vyto is presentable. do we ascertain
   that time?"*

**Yes, we ascertain it, and we always did.** `Sounditron_probe_arrived` is a positive ladder — a frame ·
 a commission · grapples it was handed · mirror cells · nothing missing · `Radio_sound` reading `sound`
  — and it has been the declared arrival all along. The Butler simply never got to wait for it.

**"Only one goal is listed" was the entire diagnosis.** `Sounditron_supervise` registers all seven
 watches AND the arrival in **beat 2**, so until the Creduler has loaded the spine and the Book has
  started, the board holds only Radio's one row: done, still, and indistinguishable from a finished
   machine. The stillness fallback lifted right there.

**So the fallback is deleted, not retuned — the fourth impatience exit removed from this file** (1.8s,
 6s elapsed, a 40s ceiling, 6s of roster stillness). The last one measured the *right* quantity
  (progress, not time — §2) and was still wrong, which is the lesson: **a young roster is perfectly
   still.** Every version of it was one question — *is an arrival ever coming?* — being answered by a
    face that is forbidden to know.

**The model answers it now.** `Supervisor_arrived` grew a fourth answer, `'gaveup'`, off a patience the
 REGISTRAR arms on its own milestone (`Supervisor_patient` — Supervisor_expect's sibling, and it
  deliberately does NOT re-arm, because it is called from a pass that re-runs every beat and a clock
   that resets faster than it runs is not a clock). Sounditron arms 90s and stamps the advice. On
    give-up the Butler **does not lift** — it drops the spinner (a spinner over a machine that has
     stopped trying is the most dishonest thing it could draw), goes *"this is as far as it goes on its
      own"*, shows the registrar's advice, and makes the way out loud. Being told beats being timed out.

*Measured live on the owner's own player tab: `arrive.playing` counting `86s` with note "the glass has
 not drawn a frame yet" → 75s later `arrived:arrived  loud:0  amiss:0`, met and latched, patience
  disarmed. The whole path, not a claim about it.*

**AND ▦ IS THE ONLY CONTROL NOW.** The owner, in two moves: *"we want that button hidden within our
 app — that and the Butler-overlay-exiting control should be one and the same"*, then, on seeing the
  first cut: *"lose `show me the guts` and just have ▦ hidden-ish (opacity:0.2) in the top right corner
   at all times. z-index above everything!"*

So `butler.quiet` became **`guts`** — one persistent pref meaning *I want the machine* — and one button
 sets it: `.scape-guts`, **fixed top-right, always rendered, `opacity:.2`, `z-index:999999`**, outside
  `<main>` so no view switch can hide it and deliberately ABOVE every FaceSucker (BootGate hoists to
   77000, the Butler to 55000). **A button hidden by the thing it undoes is not a way out** — that hole
    was in every gated version, and 0.2 opacity costs a listener nothing while costing a stranded
     person their whole session. `?` does the same thing. The Butler now only READS the pref and owns
      no switch; two writers onto one state is `boot_gate`'s lesson, and the old *"don't wait for me"*
       was already a control a person could press without learning where the machine went.

`BigSoundland_sprawl` is **retired** — `sprawl === guts`. Two persisted booleans meaning overlapping
 things ("show the machine" / "show every UI") is exactly how ▦ ended up on a listener's page.

**One thing to know before touching Sounditron.g:** it did not compile at all until this pass —
 `for (const o of organs)` in the focus cut mangles to `for (const w.oa({of: 1}) organs)`, because `o`
  is the find VERB in this dialect. It was the only `const o of` in the whole Ghost tree. Renamed to
   `org`. Same family as the `%`-after-an-IO-verb peel collision: **a JS keyword sitting next to a verb
    name.** No regression fixture for either.

**Left for the owner:** the Butler's invite landing path has still never executed (`?Iz=`), and `guts`
 defaults OFF, which means the arrival screen is back on in that browser — that is what you want for
  the invite test, but it is a change from yesterday's state.

#### …and in the same pass: a fourth verdict, a boot waterfall, and the sentences in plain English

**`moot` — the claim does not apply, because nothing asked for it.** The owner, reading his own arc:
 *"says ✓ / sound is actually coming out — the analyser hears it / nothing playing"*. A straight
  contradiction, and it is the HUD failure this file keeps naming: a row whose mark disagrees with its
   own note teaches a person to stop believing every other row. The cause is that **`ok` was doing two
    jobs** — `Sounditron_probe_sound` graded silence `ok` because an idle tab is not a FAULT, which is
     true and is not the same as the claim being TRUE. That is dial rule 2 with a third case nobody had
      written down. `moot` marks `–`, tones `moot`, is never loud, never latches a milestone, never
       counts toward an arrival. `Sounditron_probe_glass`'s vacuous pass ("nothing drawn yet, so
        nothing can be missing" — an `ok` its own comment spent a paragraph apologising for) is the
         second taker.

**The boot waterfall.** Two write-once `.c` clocks per watch — `seen` (first read) and `won` (first
 came true) — against a zero computed as `Date.now() - performance.now()`, i.e. **true page start**, not
  plan time. That distinction is the whole value: this ghost loads seconds into a cold boot, so a zero
   taken at plan would silently subtract the slowest leg and make a slow tab look fast. Rendered as
    `+3.2s` down the Butler's arc, and as a gap-annotated waterfall in `runner_ask supervisor`, where
     **turn order** (what actually took the time) is deliberately not arc order (what depends on what).

**And the sentences are the listener's now.** *"do we need to say `bytes only flow live`"* / *"should we
 say 'original bytes'?"* — no. `Repli`, `Music grant`, `original bytes`, `organ`, `analyser`, `pier`,
  `conveyor` all left the sentences and none left the screen: they live in the `note` the probe writes,
   which is where evidence belongs and which both faces already render. **The em-dash half was the
    tell** — where it said WHY a claim matters it stayed ("somebody to play radio with"), where it said
     HOW WE DO IT it went. Free of charge: the roster stands on Mundo, so no snap holds a sentence and
      no fixture moves (checked, not assumed).

*Both of the above only appear on a FRESH BOOT — sentences are rewritten at registration and the
 clocks are stamped at first read, and an already-arrived tab skips met milestones. Reload a music tab
  before judging either.*

### ⇑ 2026-08-10 — CLOSED: THE WIRE IS FINE, IT IS JUST SLOW. AND A PROBE OF MINE MINTED

**No bug in the share wire.** Three readings, minutes apart, settled every hypothesis below:
 · **The eras do NOT churn.** Lefto's `station_era` moved exactly once — the re-stand after the reload
    I caused — and has held since; Righto's never moved. The churn theory is dead.
 · **Both sides offer continuously**, caster and rx registered, presence gate open, mark changing every
    beat (the `tour` counter rides it, so it re-offers far more often than the 60s floor).
 · **The crates fill.** Lefto went `nobody` → `2 playable of 17` → **`16 playable of 16`**. Righto
    followed: `nobody` → `knows of 7 · none ready`. Both were mid-rebuild every time I looked.

**So the whole alarm was a snapshot of a recovering machine, read twice as a settled one.** The real
 residual question is modest and worth the owner's judgement: **a reloaded tab takes MINUTES, not one
  60s floor interval, to get its friend's music back** — and the last leg is the warm window, not the
   offer (`knows of 7 · none ready` is records known but chunk 0 not warm). Whether that is acceptable
    is a product call, not a defect I can name.

*The lesson is the honest one and it is about me, not the code: I read a mid-flight state three times
 and each time reached for a structural explanation. `a-red-you-explained-away` was the right memory
  to write, but its twin is **a-green-you-panicked-at** — a system recovering looks exactly like a
   system broken if you only ever sample it once.*

**AND THE HEARTBEAT MADE A LATENT TRAP SHARP.** `Sounditron_pulled` and my own new
 `Sounditron_probe_shelf` fallback both called `Ra_home_them`, which is `oai` down to the `stock`
  shelf (Ra.g:657) — **a probe that mints**. Harmless-ish at one call per Book beat; once the
   Supervisor got a 1s heartbeat it became a write on every tick of every tab. Both now read
    `home.o({stock:1, pub})[0]`, the shape `Radio_pool_census` already uses and documents as *"A PURE
     READ: `o()[0]`-style throughout, no minting, nothing written."* **Anything reachable from a probe
      must be re-audited for purity now that the roster ticks** — that is the cost of the heartbeat and
       it is worth paying, but it is not free.

### ⇑ 2026-08-10 — CORRECTION, AND AN OFFER LEDGER TO READ IT WITH

**The entry below overstates its case and the correction matters.** "No music is crossing" was a
 snapshot, not a settled state: 30 minutes later Lefto reads `remote music — 2 playable of 17 from 1
  (Righto)` and `original bytes crossed over Repli` is **met**. So music DOES cross — the defect is
   that it took tens of minutes to rebuild after a reload, against a 60s unconditional re-offer floor,
    and that the two sides recover at wildly different rates (Righto still read `nobody` at the same
     moment). *Slow and asymmetric, not broken.* The `music-from-a-friend` assertion is still worth
      re-examining, but "a red I explained away" is the honest lesson, not "nothing works".

**THE OFFER LEDGER** — `runner_ask world` now prints, per friend, the four things that decide whether
 music moves, all of which lived on the station route's `.c` and were invisible from outside:

    ⇄ MUTUAL  Righto f5da6599b8505881  grants:[…]
        heard now · offered 9s ago · caster:1 rx:1 peer_era:1786348879600
        mark 1786348878880:1786348879600:17:11   (station_era:peer_era:stock:tour)

 It answers the question the previous entry could not: **both sides ARE offering, every ~10s, with
  caster and rx registered.** So the failure is downstream of the offer — the mirror/crate step —
   not the presence gate, not the floor, not a missing route.

**⚠ AND THE ERAS ARE FRESH — the next thing to measure.** Both `station_era`s were stamped ~2 minutes
 before the read. `Swarm_station_routes` re-mints "at standup and on every socket (re)open", and the
  offer mark is keyed `station_era:peer_era:…` — so if the sockets churn, every reopen reads as a
   REBIRTH on both sides, resets the stream state, and the crates rebuild from nothing. That would
    explain the slow rebuild, the asymmetry, and why a snapshot can catch either tab empty. **Test:
     read the era twice, minutes apart, and see whether it moves.** If it does, the bug is socket
      churn, not the share beat — and every "crate is empty" reading is a symptom of it.

*Two instrument errors caught in one hour, both by checking a claim against something already known
 to be true: a narrow grep that hid `boast-heard`/`tour`/`dial`, and an offer ledger that read the
  LIES world for routes that hang off `A:Clustation > w:Swarm` — it reported "no transport route" for
   a tab that was audibly receiving music. An instrument inventing the exact bug it was built to find
    is the worst failure available to one, and neither would have been caught by the code compiling.*

### ⇑ 2026-08-10 — THE FIRST THING THE LIVE ROSTER SAW: NO MUSIC IS CROSSING *(overstated — see above)*

One tick after the heartbeat landed, the roster said something no fixture has ever said. Both of the
 owner's music tabs, read live:

    Lefto  96d0cf88 — · remote music — nobody   ◐ listening alone — while we gather — Righto
    Righto f5da6599 — · remote music — nobody   ◐ listening alone — while we gather — Lefto
    both:  ○ original bytes crossed over Repli — the pull landed   (unmet)

**They are mutually sealed, both online, and each hears the other's boasts** — `boast-heard of=…`
 appears on both supply rings, both tour, both dial, both play their own music. What is missing on
  both sides is the CRATE: `Radio_pool_census` counts `w.o({MusuThem:1})` and gets **zero**, so there
   is no friend pool, nothing playable, nothing to pull. The seal is perfect and the music does not
    move — which is the entire point of the app.

**This is the same fact as the Book's `music-from-a-friend` assertion**, which has been ABSENT on
 every Sounditron run today and which I attributed each time to "the friend tab isn't online". It
  isn't that. Both tabs are up, sealed and talking. *An assertion dismissed as environmental for a
   whole day was reporting a real defect — the thing `mutation-test-every-claim` warns about, in the
    other direction: a red you have explained away is as dangerous as a green you never tested.*

**Where it is NOT.** Ruled out by measurement, not reasoning: the seal (`world` shows MUTUAL with
 grants both ways), liveness (`swarm.piers` = 1 sealed · 1 online on both), the boast (heard on both
  rings, `records=16`), the wander (`tour` marks on both), audio (both playing). What is absent from
   both rings is any `crate-born` / `mirror-merge` — the offer→mirror step between "I know you have
    16 records" and "I hold cards for them".

**The next probe, not a fix.** `Swarm_share_beat`'s offer loop is presence-gated
 (`heard_at` within 20s), change-marked (`station_era:peer_era:n:tour`) with a 60s unconditional
  re-offer floor under it. All three of those should be satisfied here, so the question is whether
   `Ra_offer_stock` is being CALLED and failing, or not being reached. **Do not fix this blind** — it
    is the app's core wire and the diagnosis is one measurement short. Reproduce with:

    node scripts/runner_ask.mjs supervisor --player=96d0cf8852651a73   # the dials
    node scripts/runner_ask.mjs world      --player=f5da6599b8505881   # the other side's ring

*Instrument note, my own error: grepping `world` output for a narrow pattern hid `boast-heard`, `tour`
 and `dial` and led me to call one tab deaf when it was not. Read the whole ring, then filter.*

### ⇑ 2026-08-10 — **THE SUPERVISOR HAD NO HEARTBEAT.** IT ONLY LIVED INSIDE A BOOK BEAT

The biggest thing found this week, and it was found by an edit that *refused to take effect*: I changed
 `Radio_dial_solo`, compiled it, watched it HMR into the owner's live tab — and the dial kept printing
  the old reading. Nothing was re-reading it.

**`Supervisor_read` / `_read_dials` / `_say` were called from exactly ONE place in the repo** —
 `Sounditron_supervise`, inside Book beat 2. Grep it: there is no other caller. So the whole roster
  was only alive **while a Book was running**. On a listener's tab the resident Book finishes a few
   seconds after boot, and from that moment every watch and every dial is frozen at its last reading
    for the life of the tab. **A "standing" watch that only stands during a run is a photograph**, which
     is precisely the failure this region exists to replace — and it hid because the readings it froze
      at were mostly GREEN. It is also why the Butler appeared to work: the Book is running during the
       boot, which is the only window the Butler is up for. The cell and the panel had no such luck.
 *This doc asserted the opposite as recently as the mutation-test entry below — "`Supervisor_read_dials`,
  which runs on Mundo's own tick". There was no such tick. A comment is not a measurement.*

**`Supervisor_tick(H)`**, called from `Auto.svelte` on the line after `Supervisor_up(H)` — the tick
 that survives the run, standing where the world it reads already stands. Self-throttled to 1s on a
  `.c` wall clock (never sc — a timestamp there would churn every downstream fixture), because Auto's
   tick is a hot path and a probe walks real structure. One place reads, many places register: the
    registration slope, finally completed. A Book that wants an answer at a particular beat still calls
     `Supervisor_read` itself, as Sounditron does where it swears.
 **Proof, on the owner's live tab, no Book running:** `radio.solo` moved to its new reading and
  `radio.remote` went `yes → no` as the pool emptied after a reboot. Those numbers could not move
   before this change.

**And the dial it exposed was itself lying.** `radio.solo` read `✓ listening alone — your own music
 (gathering) — Righto` beside `✓ remote music — 3 playable from Righto`: two dials flatly
  contradicting each other. `gathering` is not solitude, it is *waiting for their bytes* — so it is
   `part`, and rounding it to `yes` is the exact thing the dial region forbids (*"`part` is not a
    convenience: it is rule 3 made unfakeable"*). `alone`, `offline` and `gaveup` stay `yes`.

**Orphaning now covers dials too.** Leaving it off would have been the worse half of an asymmetry: a
 torn-down run would fall silent in the watch list while the dials went on announcing "listening
  alone" and "no remote music" — the rows a face shows when everything is FINE. The CLI shows dials
   now as well, which is how the contradiction above became visible in the first place.

**⚠ The CLI's default target can resolve to a PLAYER — someone's music page.** It did here, and
 `reload` on it interrupted the owner's music (it came back). `runners` labels them `♪player`, but the
  no-flag default picks the latest row regardless. **Pin `--runner=` for anything with a side effect.**

### ⇑ 2026-08-10 — THE LISTENER'S OWN TAB, READ AT LAST

`runner_ask supervisor --player=<pub>` reaches a MUSIC TAB. The Cluster registry lists end-user rooms
 as `role:'player'` — addressable, never dispatchable — and the `supervisor` op is in `PLAYER_OPS`, so
  for the first time there is a way to see what a listener's Butler is actually looking at instead of
   asking them. What the owner's tab says:

    supervisor: 11 watch(es) — arrived:arrived  loud:0  amiss:0  (humdinger)
      ✓ ⚑ the glass is up and music is playing — you have arrived
          3 cells and music playing

**THE ARRIVAL LADDER WORKS.** `arrive.playing` is met, with the positive rungs reporting real cells
 and real sound — on a real listener tab, which is the one place it could never be tested from a Book.
  All 11 watches green. **And `butler.quiet` is ON there.** So the arrival screen has been switched
   off in that browser for some time: every reload since has had NO Butler at all. Anything judged
    about it since then was judged about a screen that was not running — the same shape as the
     `for_a_book` discovery, one layer up. **Ask the owner to turn it back on in ▦ before the next
      round of Butler feedback.**

**Three probe fixes, all found by looking rather than reasoning:**
 · **`sound.grant` read a photograph.** It counted `w.o({Friend:1})` — rows the Book mints in a beat
    and never refreshes — while the Book's own `granted` assertion reads `Sounditron_grants` (the
     identity's %Piers and %Grants in storage). Two accessors for one fact, and they disagreed: the
      watch said *"no friend yet"* while `world` showed a mutual seal. Now it reads storage, and it is
       registered with a **null subject** because grants are machine state, not this run's fact.
 · **`sound.shelf` had the same disease**, softened rather than replaced: the %Friend row first (it
    carries the friendly name), the friend's CRATE as the fallback, so a stale row can no longer
     report "no shelf counted" while we demonstrably hold their records. Can only latch earlier or
      where the row went stale — never later, so nothing that latched before stops latching.
 · **`sound.glass` contradicted itself** — ✓ beside *"no frame published yet"*. The verdict stays `ok`
    (a permanent `unknown` counts as amiss and would make the cell furniture on every runner) but the
     note now admits the pass is vacuous: *"nothing drawn yet, so nothing can be missing"*.

**And the instrument disagreed with the screen once, which is the thing an instrument may never do.**
 `advice` is stamped when an expectation is ARMED and never cleared when the claim comes good, so the
  CLI printed *"no friend is online — you can listen to your own music"* under a green *"a friend came
   online ✓"*. The Butler gates advice on `gaveup`; the printer now applies the identical gate.

**Next:** `sound.live` and `sound.pulled` still read this-run worlds — check whether they freeze the
 same way once the resident Book finishes, using `--player=` twice a few minutes apart.

### ⇑ 2026-08-10 — THE ROSTER HAD NO INSTRUMENT, AND BOMB #1 IS NOW MEASURED

**`node scripts/runner_ask.mjs supervisor` — the Supervisor's screen, on a terminal.** This whole
 subsystem had three faces and NO READER outside the tab, and that is why every Butler bug this week
  was found by a human's eye and nothing else: the roster stands on MUNDO (deliberately — a supervisor
   inside the House it reports on cannot say "the run died"), and `snap <n>` serves the RUN House, so
    no CLI read could reach it. The op is one call to `Supervisor_lines` — same rows, same order, same
     marks the Butler draws, nothing re-decided — plus `arrived:`, the notice ring, the probe method
      name per row, and the prefs. It works with `--player=` too, which is the only way to see what a
       listener's Butler is saying. Handler: `Lies_runner_ask_recv` op `supervisor` (LiesFunk).
 *It is named `supervisor`, not `roster`: in `runner_ask` "roster" already means the Cluster runner
  registry, and that file says so out loud.*

**It paid for itself in the first two calls.**
 1. **`butler.quiet` is ON in this browser's stash** — the arrival screen has been switched off, and
    since the stash is Dexie (per ORIGIN, not per tab) pressing "don't wait for me" once silences the
     Butler in EVERY tab of that browser, permanently, with the only way back in the ▦ panel. From
      outside, "it never shows" and "it lifts too early" look identical — so the op prints prefs first.
 2. **BOMB #1, measured rather than argued.** `release` tears H:Story down; `sound.glass` flipped
    ✓ → `? no A:Vyto in any of 1 House(s)` and `amiss` went 0 → 1. Every Book watch keeps being
     re-read against a corpse after its run ends, and each probe dutifully reports what it can no
      longer find. On a listener's tab that is the diagnostic cell appearing over their music to
       announce the glass is missing, because a run they never asked about finished.

**THE FIX, and what it deliberately is NOT.** `Supervisor_alive(subject)` walks the subject's `.c.up`
 chain and asks MUNDO whether the House it lands on is still attached — never `top_House()`, which a
  dropped House can still answer from a stale link. A detached subject stamps `unknown` + *"the world
   it watched is gone — that run was torn down"*, sets `sc.orphan`, and `Supervisor_speaking` skips it:
    an orphan is legible in the panel and on the CLI, and never loud. **It fails safe** — the only
     answer that accuses is "I climbed to a House and that House is not in the live tree"; an
      unfamiliar topology, a missing top House, a chain that never reaches a House all read ALIVE.
       Orphaning the whole roster in one tick would be a far worse bug than the one being fixed.
 **This is not the persistence ruling.** Whether a torn-down Book's watches should be DROPPED (the
  `eternal` flag + a `Supervisor_teardown` hook off `auto_teardown_story`) is still the owner's call
   and is untouched. This only stops the roster stating facts about a world that is gone.
 **Verified live:** before a teardown, 8 watches, `loud:3 amiss:0`, no orphans — so no false positives
  during a run. After it, six watches ORPHAN and the roster reads `loud:0 amiss:0` — honestly quiet
   instead of shouting. `the-supervisor-stood` and `every-registered-watch-found` both still green.

**Two things the instrument showed that are NOT fixed, on purpose:**
 · `sound.glass` answers **ok** with the note *"no frame published yet"* — a ✓ beside a note saying
    nothing was judged. It is a deliberate trade (`unknown` counts as amiss, so a permanent unknown on
     a runner would make the cell permanent furniture) and it is documented at the probe, but the
      sentence and its note contradict each other and that is worth the owner's eye.
 · `sound.grant` reads *"no friend yet"* off `%Friend` rows in the RUN world while the identity's
    piers say otherwise — two different accessors for one fact (`Sounditron_grants` vs `w.o({Friend})`).

*Also re-confirmed the hard way: **the default runner address switches tabs.** Mid-sweep it moved
 `96d0cf88` → `58517b48` and three friend-dependent assertions went ABSENT with nothing having
  changed. Check `world`'s `self` before attributing any red.*

### ⇑ 2026-08-10 — AN EMPTY BOARD IS NOT AN ANSWER, AND THE DOOR MOVED IN

Three things landed after the stillness fix below, all of them the same shape: *something that did not
 know yet was being read as something that had answered.*

**The stillness fallback still busted open on a cold boot — because an EMPTY roster is perfectly
 still.** `still_since` measures "has anything advanced", which is right, but on this page the
  Supervisor world is minted BY its registrar: before `Sounditron_machine` reaches its registration
   beat there are no lines, no notices and no arrival at all. A board with nothing on it never changes,
    so six seconds of spine-loading read as six seconds of nothing-to-wait-for and the screen lifted
     mid-boot for the third time. The fallback now also requires `view.lines.length` — *somebody has
      spoken and none of them declared a finish line* — which is what it always meant. Holding on an
       empty board cannot strand anybody who is booting: the Butler mounts on exactly one page and that
        page's Book declares an arrival in beat 2, and if the board never fills the machine never
         started, which the grown carry-on tap says out loud by then.

**The latch was the component's, not the tab's.** `done` was a `$state`, so it promised "never up again
 for this component instance". Any future `{#if}`/`{#key}` around the mount hands back a fresh `false`
  and the loading screen drops over somebody's music — the thing this file's own header calls its worst
   bug. It now stamps `H.c.butler_done`: new on every reload, shared by every mount within one tab.

**THE INVITE DOOR IS IN THE BUTLER NOW** — the owner: *"is this going to contain all the Invite
 onboarding UI as well? it'll focus the UX of entering their username and hitting join."* Yes, and it
  stopped being a feature question the moment this screen started holding until arrival: the join door
   lives in `BigSoundland.svelte`'s strip, and a fullscreen arrival screen over it **hides the invite
    funnel behind news about a machine the person has not met yet.** The strip's own comment already
     argued the funnel must not depend on a successful boot; the Butler had quietly made it depend on
      one. So: `?Iz=` present ⇒ the Butler mounts the EXISTING `InvitePanel` (never a second join door —
       the `boot_gate` lesson), it is the only thing on the card while it is open (the arc is noise to
        somebody typing their name), and it is permission-shaped: **no automatic lift while the token is
         unspent.** `boot_param('Iz')` reads `location` live and `strip_iz()` removes the token when it
          is redeemed or refused, so the URL *is* the state and nothing here copies the panel's machine.
 **The trap this rests on:** two mounted `InvitePanel`s both auto-join a scan landing (`landed_url &&
  !auto_fired`, latched per instance) and a single-use `?Iz` redeemed twice comes back a rebuff — *the
   invite refusing itself.* So the strip now stands down while `butler_up`, the same handshake BootGate
    already makes. `DoorFace`'s in-glass panel is behind an `inviting` toggle a human must press, so it
     cannot join the race by itself — but it is the third mount, and anything that ever opens it
      automatically inherits this problem.

**Next:** none of the above is witnessed by a Book — the Butler is a face and its inputs are `.c` and
 the URL. The honest gate for it is a `%see` on the model side: `Supervisor_arrived` returning
  `coming` while the glass is bare, and `arrived` only once cells and sound stand. That is one step in
   `Sounditron` and it would have caught two of the three lifts above.

### ⇑ 2026-08-10 — §2 WAS BEING BROKEN BY §2's OWN FILES, IN THREE PLACES

The owner, after the "hold until arrival" change: ***"bust open at the wrong time still."*** It was
 still lifting mid-boot, and the reason is the one this doc is named for, wearing a third disguise.

**The exit had one clock left in it.** The no-arrival fallback read `view.since > GRACE_MS &&
 !view.holding` — elapsed time since mount. A booting tab passes through a moment where the roster is
  *half-registered*: every watch that has arrived so far reads ok, the arrival milestone is not
   commissioned yet (`Sounditron_supervise` gets there on a later beat), so `arrived === 'none'` and
    `holding` is false — **and any elapsed-time reading lifts right there.** 1.8s did it, 6s did it;
     60s would have done it on a cold disk. The fix is §2 applied to the Butler itself: a coarse
      signature of the roster (`lines / done / notices / arrived`), a `still_since` stamp when it
       changes, and a lift only after `STILL_MS` of **nothing moving**. While registrations land,
        watches turn or notices arrive, this is a machine coming up, whatever the clock says.
 *The signature is deliberately COARSE — a note churning under a line ("37 folders walked") must not
  count as progress, or nothing would ever be still and the fallback would never fire at all.*

**And the progress counter I had just built was itself a lie on a warm page.** `Radio_shelf_walked`
 read `Object.keys(meander_learn).length` — but **Census.svelte RESTORES that map at boot**, thousands
  of entries off disk. So a warm tab claimed to have walked its whole share in the first tick, and
   `moving` could never see it climb (a revisit adds no key), so the patience never re-armed. The very
    memory that makes the search fast made the progress bar lie about it. Crate.g now bumps
     `TOP.c.meander_stood` at the visit itself — O(1), counts revisits (which is right: re-treading
      known ground is still a wander working), not persisted.

**"We can insta-remember where it is aye?" — yes, and most of it was already built.** The census
 (`Census.svelte` + `census_codec.ts`) persists `{audio, open, subs, z, n}` per directory to a Berth
  Waft under the share, restores up to 24000 of them, and Crate.g folds them into `meander_stat` so
   the wander is steered at the music from the first hop (measured: 22.4 vs 3.2 tracks in 20 tours).
    What was missing was *saying so*. `Hh.c.census_music` is now stamped at restore (count of restored
     directories holding audio) and `Radio_probe_shelf` reads it: an empty shelf on a warm page says
      **"fetching — 412 folders of music remembered here, 9 walked"** instead of "no music in your
       share", which is the same wait wearing an accusation.
 **Still true and not yet built:** we remember *where* the music is, never *which tracks* — every boot
  re-lists and re-mints the Records. Remembering those is a real design decision (a second Berth
   beside Newlyadded), not a tweak; nobody has asked for it yet.

**`.git` / `.jamsend` — already safe, all three walks.** `Crate_nav_ls` (Crate.g:210), `Crate_nav_meander`
 (Crate.g:486) and `Riffle_deal_dir` (Radio.g:2714) each skip `nm[0] === '.' || nm === 'node_modules'`.
  Crate.g:210 names the reason: `.jamsend` holds owner-private account snaps carrying the identity key
   in the clear. This is the enforced half of the .jamsend law, not tidiness.

**Next:** the Invite onboarding question is still open — the owner: *"is this going to contain all the
 Invite onboarding UI as well? it'll focus the UX of entering their username and hitting join."* The
  Butler is the right home (it is the only surface that owns the screen before the machine is up, and
   `BigSoundland.svelte` already records why the invite funnel cannot live in a cell), **on the
    condition it mounts the existing `InvitePanel` rather than growing a second join door** — the
     `boot_gate` lesson — and that a pending join is treated like `gate.wanted`: uncapped, above the
      progress news, because it is the thing blocking everything rather than news about it.

### ⇑ 2026-08-10 — THE BUTLER HAD NEVER RUN, AND THE THREE SURFACES ARE RE-AIMED

**THE BUTLER HAS NEVER ONCE DONE ITS JOB — since it was written.** The owner, watching a reload:
 *"the Butler closes when the interface is still at 'nothing mounted yet'"*. Root cause found and it
  is not in any of today's work: `for_a_book = !!H?.c?.book`. **`BigQualand.svelte.ts:57` stamps
   `h.c.book = opts.book` on EVERY qualand page** — /BigSoundland's resident Book *is* Sounditron — so
    `c.book` has been set on every listener tab there has ever been. And the reason it LOOKED like a
     flash rather than an absence: `boot_qualand` assigns `H` inside an `$effect`, so the Butler mounts
      with `H` **null**, reads `for_a_book` false for a frame or two, shows — then latches shut the
       instant H arrives. Every exit rule, the arc, the cap, arrival: all unreachable, always.
 **The honest tell is `humdinger`** (BigQualand stamps it for role word|sound = "an end-user room" —
  the same flag the arrival milestone and the /log reporter already gate on), plus an explicit `?B=`,
   because someone deliberately driving a Book from their own music page is asking to watch the
    machine. A null `H` now reads FALSE and the Butler **holds** — "we do not know yet" is the one
     answer that must not latch a gate shut. **This is the single most important line in the diff.**
 *The general shape, worth carrying: a boolean that gates a whole surface, read off a key some other
  layer stamps for its own reasons, fails silently and looks exactly like the feature not being built
   yet. It was in the "never verified by a human eye" list for a day and the list was right.*

**THE THREE SURFACES, RE-AIMED BY THE OWNER** (*"I kind of want that as the mid-complexity,
 log-looking version of the Supervisor business, whereas the Supervisor cell is smaller and simpler,
  perhaps not even there if nothing is out of line, and the Supervisor UI itself is the bull
   bollocking"*):

| surface | size | now |
|---|---|---|
| `SupervisorFace` (Vyto cell) | smallest | **not on the glass at all unless something is amiss** |
| `Butler` | **mid — and it should LOOK LIKE A LOG** | arc *with its notes* + the notice ring, left-aligned, elapsed stamps |
| `SupervisorPanel` (▦) | the whole bollocking | unchanged: probe names, kinds, patience, prefs, the ladder |

**`amiss` IS A NEW READING, AND IT HAD TO BE.** The cell can only vanish if something decides "out of
 line", and `loud` (= `Supervisor_speaking`) is the wrong number: it counts everything worth SAYING,
  outstanding milestones included — so on a tab with no friends `sound.grant`/`sound.shelf`/`sound.pulled`
   are unmet **forever** with nothing wrong at all, and a cell keyed on `loud` would be permanent on
    exactly the machine it was meant to leave alone. `Supervisor_amiss(w)` is the narrower ruling —
     a **standing** watch reading wrong, or **anything** reading unknown (a blind spot is its own kind
      of wrong); a milestone not yet met is deliberately not in it. It snaps as `%Supervisor,amiss`
       beside `loud` (both deleted when zero), and `Sounditron_glass` grapples the row on `amiss`, or
        under `show_diag` where a developer is asking to see the machinery anyway.
 **Both numbers stay, because two surfaces genuinely ask different questions**: `loud` = how much is
  worth saying (the Butler's arc, the cell's dose), `amiss` = is anything actually wrong (whether a
   cell should exist).

**AND THE CELL WAS CARRYING A SECOND OPINION.** `SupervisorFace` had its own `mark()`/`tone()` pair
 while its header claimed *"IT IS DUMB ON PURPOSE"* — two copies of one judgement, in the one surface
  whose entire value is being trusted at a glance. `Supervisor_say` now stashes `c.amiss_lines`
   (flattened through `Supervisor_line`, already marked and toned) and the face renders them. It also
    shows **three** rows, not six: a cell that lists six failures has become the panel in a smaller
     font, and ▦ is where you go to read them.

**Verified:** both ghosts compile; `svelte-check` clean on all three faces; a full `Sounditron` run
 (8 steps, **every step `error:null`**) with `the-supervisor-stood` and `every-registered-watch-found`
  green at step 2. **Not verified: still no eye on any of it** — and note the runner default address
   moved again mid-session (`58517b48` → `a67a5d04`), the standing hazard.

**THE BLIND-SPOT GATE HAS NOW BEEN SEEN TO GO RED — the first mutation test in this doc that was
 actually performed.** Method, so it can be repeated: rename a probe by one letter, compile, reload
  the runner, run, watch the claim fail; revert, and watch it come back. Three cycles:
 1. `Sounditron_probe_glass` → `…glasss`. **`every-registered-watch-found` went ABSENT**, and the
     `%log` row named `why:sound.glass`. That sentence had never once failed before today.
 2. `Radio_dial_solo` → `…soloo`. **It did NOT go red** — and that was the finding. A dial is stamped
     only by `Supervisor_read_dials`, which runs on Mundo's own tick, so at the step where the gate
      swears a dial can still be **unread and therefore indistinguishable from a healthy one**. The
       roster covered dials; the ASSERTION did not. Fixed by calling `Supervisor_read_dials(sup)`
        beside the existing `Supervisor_read`/`Supervisor_say` in `Sounditron_supervise` — the same
         registering-and-being-read-are-different-events reasoning already written above those lines.
          Re-run with the fix: **red, naming `why:radio.solo`.**
 3. Both reverted → **green again**, no log row. `Ghost/M/Radio.g` byte-identical to HEAD (dige back to
     `887c9fd4701fc1f4`).
 **This is the shape the doc has been demanding all day and it paid immediately**: the gap was
  invisible while everything was green, and no amount of reading would have found it. `sound.glass`
   and `radio.solo` are now the two probes in this repo known to fail correctly. **Eight watches and
    four dials still owe this.**
 *Operational note, cost two wasted cycles:* a `.g` HMR can leave the Story drive unscheduled — `run`
  returns `{run:null}` with zero steps and the tab still pings fine ([[svelte-hmr-wedges-a-book-drive]]
   in its `.g` form). `runner_ask reload` cures it, but **the run right after a reload also lands
    empty** — release and run again. Budget three commands per cycle, not one.

**What the reload itself showed, and it was good news:** both player tabs (`96d0cf88`, `f5da6599`)
 came up clean with 1 mutually sealed pier each — `✓ radio.shelf · ✓ sound.shelf · ✓ sound.pulled ·
  ✓ radio.remote — 12 playable of 15 from 1 (Righto) · · radio.solo — with Righto · ✓ radio.fresh`.
   `f5da`'s shelf took 3.7s to go ✓ and the 15s grace absorbed it with no red flash, which is the
    earlier shelf-grace fix working in the wild.

### ⇑ 2026-08-10 (late) — THE BUTLER'S BRIEF IS BUILT: arrival, the give-up sentence, the switch

**All three of the owner's named gaps (a)(b)(c) landed.** Read the night handover below for the
 destination and the bombs — this section is only what changed since, and what it is owed.

**(a) THE BUTLER NOW LIFTS ON ARRIVAL, and the clock is the apology.** The whole point of the entry
 below was that the screen's three exits were all *impatience*: nothing waiting, a 12s cap, a tap.
  Now the model owns a finish line — `Supervisor_arrival(w, key)` **declares** one, `Supervisor_arrived(w)`
   **rules** on it, and the Butler asks that one question. Three answers on purpose, and the third is
    load-bearing: **`none`** (nobody declared an arrival) is not `no` — a bare tab or a half-loaded
     spine falls back to the old reading, because holding a listener behind a finish line nobody will
      ever cross is the only failure worse than lifting early.
 **A FACE MAY NOT NAME THE ARRIVAL EITHER.** The obvious cut was `lines.find(l => l.key === 'arrive.playing')`,
  and it is the same disease one layer up — the hand-written headline in the loading screen, and a tab
   that declared a different arrival would hold forever. So the REGISTRAR flags its own claim and every
    face asks the model. Same law that keeps `Supervisor.g` free of subsystem names.
 **The claim itself is the commissioner's**: `arrive.playing` — *'the glass is up and music is playing
  — you have arrived'*, milestone, probe `Sounditron_probe_arrived`, registered in `Sounditron_supervise`.
   It refuses to reuse `Sounditron_probe_glass`, and the reason is worth keeping: that probe answers
    **`ok — no frame published yet`**, which is right for "is the glass drawing what it was handed"
     (nothing judged, nothing wrong) and quite wrong for "is there a glass in front of a person". Same
      reading, two questions. Likewise it asks `Radio_sound` for `sound` and nothing else — `quiet` is
       graded ok by `Sounditron_probe_sound` (an idle tab making no noise is not a fault) and an idle tab
        has plainly not arrived. Folding those two would let every silent boot claim arrival, which is
         the posed-milestone failure this roster replaced.
 **PLAYER TABS ONLY**, and that is what the claim MEANS rather than caution: `vw_frame` is stamped only
  by a humdinger tab's `publish_frame`, so on a runner this milestone can never be met and would sit
   `wrong` forever, keeping the roster permanently loud about a listener who is not there. Same
    `c.humdinger` test the reporter already uses. **Verified on the runner**: `arrive.playing` never
     turned on the trace, which is exactly right and is how the gate got found.
 **The numbers moved and they are tuning constants, not rulings.** `GIVEUP_MS` 40s (was `CAP_MS` 12s —
  at 12s the clock beat every real boot, so arrival could never be the exit and the change would have
   been decorative), `IMPATIENT_MS` 12s, past which the carry-on tap **grows and names itself**
    (*"this is taking a while — carry on →"*). Holding a fullscreen surface silently for forty seconds
     is the trap; saying so is not. **Both want an eye on them.**
 **And `GRACE_MS` went 1.8s → 6s**, which is subtler and would have quietly undone the whole change:
  that grace guards the **no-arrival fallback**, and 1.8s is enough for the station to arm its
   expectation but NOT enough for the resident Book to reach the beat where the arrival gets declared.
    On a warm tab whose first two watches both read ok, the screen would have lifted before the finish
     line existed — the impatience exit wearing the new code.

**(b) THE GIVE-UP SPEAKS, and the sentence is the registrar's.** A watch may now carry `sc.advice` —
 *what to tell a listener once we have given up on this claim* — beside the `sc.because` that was
  already there, and for the same reason: only the process that armed the expectation knows what a
   person could do instead. `Supervisor_line` carries `advice` + `gaveup`, and the Butler renders the
    advice of anything given-up in a calm block (not red: it is not a fault, it is the machine being
     honest about what it settled for).
 The two `swarm.arrival` arming sites now stamp it — `Swarm_expect_friends` → **'no friend is online —
  you can listen to your own music'**, `Swarm_invite_url` → **'nobody has answered your invite yet —
   your own music plays in the meantime'**. Two facts, two sentences; guessing between them is the
    exact lie `because` was added to stop. **Scope, as the owner drew it: WORDS, NOT BEHAVIOUR.** Nothing
     new plays anything — the radio's own local rung already runs the moment that expectation expires.
      All this does is stop the give-up from being a silent nothing.

**(c) THE SEMI-HIDDEN SWITCH — `butler.quiet`, a particle AND the House stash.** `Supervisor_pref` /
 `Supervisor_pref_set` / `Supervisor_prefmem`. Both halves are load-bearing and neither alone is
  enough: a particle so the choice can be snapped, asserted, bumped and compared between tabs
   ([[derived-in-a-face-is-a-fact-thrown-away]]); `H.imem('Supervisor')` (Dexie-backed `H.stashed`,
    exactly what the old `quit_fullscreen` used at `Cytoscape.svelte:380`) because **the C tree on
     Mundo does not outlive a reload** and persistence was the entire ask.
 **OFF COSTS NO ROW**: a pref that is off mints no particle and writes no snap line — the snapped-boolean
  law, and it also means a Book that never touches a pref sees no new furniture.
 The off-switch is on the Butler (*"don't wait for me"*, the quietest thing on the card — it costs a
  listener their arrival screen forever, so it must never be the easiest thing to hit); the **on-switch
   is in `SupervisorPanel`**, because a switch that can only ever be turned off is a trap. Read through
    an `$effect`, never the `$derived` — the first read MINTS, and a derived that mutates is a derived
     that will one day loop.

**ALSO, and it was a real defect for (a): SIX WATCHES WERE UNPLACED.** `sound.grant|live|shelf|pulled|glass|audible`
 registered with no `stage`, and unplaced sorts LAST by design — so on the Butler's arc they landed
  *after* the arrival milestone that is composed of them, and the loading screen read as a machine
   finishing before it started. Now staged `friend`/`sound`, arrival at `sound + 5` (the gap-of-ten the
    stage list leaves for exactly this). **The roster does not appear in the Run House snap** (checked:
     `snap 8` carries no `Watch:` rows — it lives on Mundo), so none of this churns a fixture.

**Small tidy that paid for itself twice:** `Sounditron_vyto()` — the walk-every-House hunt for the live
 glass, extracted from `Sounditron_probe_glass` the moment a second reader needed the same answer. Two
  copies of that walk is how the second reader ends up looking in a different set of Houses and
   disagreeing about whether the glass exists.

**VERIFIED — and read the "not" list, it is longer than the "yes" list.**
- ✓ All four `.g` files compile through the editor chain; `svelte-check` clean on both edited faces
   (grepped by filename against the ~3.4k baseline).
- ✓ Two live `Sounditron` runs on `58517b48`: **no thrown steps**, `the-supervisor-stood` and
   `every-registered-watch-found` **green at step 2** both times — so `Sounditron_probe_arrived`
    resolves by name and the blind-spot gate covers it.
- ✓ `arrive.playing` correctly never latched on the runner (no `vw_frame`) — which is what sent it
   behind the `humdinger` gate.
- ✗ **THE BUTLER HAS STILL NEVER BEEN SEEN.** Not by me and not by an eye: `runner_shot` captures the
   Vyto canvas and the Butler is a FaceSucker over the whole page. Arrival, the advice block, the
    grown tap and the switch are all **type-checked and unwitnessed**.
- ✗ **The advice has never been seen to fire** — it needs a 5s expectation to actually expire, and
   `poke` cannot mint an invite. That is the same unfired 5s hold the overnight entry records; it is
    now the hole for two features rather than one, and one ten-second manual test closes both.
- ✗ **Still no mutation test on any watch or dial**, and now there is one more of each to owe it to.
- ✗ `music-from-a-friend` still ABSENT; **fixtures still not re-recorded** (every step dige-mismatches,
   unchanged from before these edits).

**THE NEXT MOVES, re-aimed:**
1. **Look at it.** One boot of `/BigSoundland` with the console open: does the Butler hold to arrival,
    does the arc read in arc order, does the advice show when a friendless boot gives up at 5s, does
     "don't wait for me" survive a reload, and is 40s intolerable? Every one of those is a ten-second
      answer for someone with a browser and a guess for me. **`GIVEUP_MS`/`IMPATIENT_MS` are the two
       numbers most likely to be wrong.**
2. ~~**Mutation-test one watch and one dial**~~ — **DONE** (see the 2026-08-10 latest section: one
    watch and one dial forced wrong, both seen red, both seen to recover, and the exercise found a
     real hole in the gate). The remaining eight watches and four dials still owe it; the method is
      written down now, so each is three commands.
3. **Decide BOMB #1** (below): the stale-roster split is now slightly worse, because `arrive.playing`
    is a milestone that latches — a tab that arrived once carries `met` into the next Book.
4. BOMB #2, BOMB #3, and the §10.3 ruling — all unchanged.

### ⇑ HANDOVER 2026-08-10 (night) — the destination, the bombs, and the next moves

**THE DESTINATION.** Supervisor went from "a summary row nobody reads" to a real three-part
 instrument in one day: a **registration-only roster** (watches + dials, never a hardcoded list of
  subsystems), a **model-judges-faces-render** split (`Supervisor_lines`/`Supervisor_dials` are the
   one authority on order/mark/tone; three faces — the quiet Vyto cell, the arriving-listener
    `Butler`, the everything `SupervisorPanel` — render it, never re-decide it), a **notice ring +
     supply-trace hook** (any watch/dial that CHANGES ITS MIND shows up on `runner_ask world`'s
      timeline for free), and a **TimeSpool-style happy fraction** riding every `/log` report. Read
       today's dated sections below for the receipts; this entry is where to start, not where to dig.

**BOMB #1 — WATCHES OUTLIVE THE BOOK THAT REGISTERED THEM, and nothing tells them apart.**
 `w:Supervisor` stands on Mundo, above `H:Story`, on purpose (§ the header: a Supervisor inside the
  House it reports on cannot say "the run died"). But `auto_teardown_story` (`Auto.svelte:1096`)
   only drops `H:Story` — it never touches Supervisor's roster. So on a tab that runs Book A then
    Book B, **B inherits every watch A ever registered**, stale, forever, with no owner left to
     refresh or clear them. Caught live tonight: the owner ran Sounditron then VytoNest on the same
      runner and VytoNest's Butler showed Sounditron's `swarm.arrival`/`sound.*` watches as unfinished
       noise. **Not a uniform bug** — `swarm.station`/`swarm.piers` (registered from `Swarm_station_up`,
        not from any Book) are correctly machine-level and SHOULD persist across a Book switch; the
         Sounditron/Radio watches are Book-specific and should not. **Proposed, not built**: an
          `eternal` flag on `Supervisor_watch`/`Supervisor_dial` (machine-level callers pass it), plus
           a `Supervisor_teardown(H)` hook called from `auto_teardown_story` that drops every
            non-eternal watch/dial. Needs the owner's sign-off before touching `Auto.svelte` — this is
             a persistence-semantics call, not a bug fix with one right answer.

**BOMB #2 — the beliefs mutex is held 2–3s by `fn:handle_inbound` right when a track starts.**
 Found for free reading the supply-trace: `drain-lag` marks show `Vyto_focus`, `swarm_share_beat` and
  more all gated for ~2.7–3s in the same window `Radio_open` fires. Traced as far as: it's the
   COALESCED inbound-frame batch drain (`Tribunal.g`'s `Lies_deliver_soon`, deliberately built to
    replace a worse per-frame post_do death-spiral), not the PCM read (which is fire-and-forget, not
     awaited under the mutex). **Not yet known**: whether a 2-3s batch is the accepted cost of that
      design or a regression worth chasing. This is plausibly WHY `music-from-a-friend` goes red on a
       20s Book budget — the mutex stall eats straight into it. The owner's own read on that assertion
        tonight: *"that's just the canonical did it get done in time thing… no big deal… another
         improvable metric"* — so this is a metric to chase, not a fire to put out.

**BOMB #3 — the Tree cell (`show_diag`'s pure-C-tree instrument) had never rendered, ever, since
 2026-08-07** — `Tree` was missing from `FACE_MAINKEYS` (fixed, `glass_faces.ts`). Re-shot after the
  fix and it proved the REAL open question: six diag organs compete for one glass and three vanish
   entirely ("1 with no room"). **Undecided**: pick ONE tree cell at a time (toggle between
    underworld/Supervisor rather than minting both), or accept `show_diag` as a deliberately crowded
     dev trade. Both cells are diag-gated so this costs nothing live today.

**THE BUTLER'S UNFINISHED BRIEF — three things the owner named 2026-08-10 (night), none built.**
 The Butler as it stands is an ARRIVAL screen: it carries the boot permission tap plus the Supervisor
  arc, then latches down at the first of {nothing waiting, `CAP_MS` 12s, a "carry on" tap}. The owner's
   actual design is bigger, and the gap is the point of this section:
 - **(a) It should carry you ALL THE WAY** — *"the Butler is supposed to carry you all the way, letting
    you know what's happening, until the Vyto glass is up and running AND playing the thing you want."*
     Today's three exits are all *impatience* exits; none of them is **arrival**. The real
      lift-condition is a milestone that doesn't exist yet: glass commissioned **and** audio actually
       sounding. Both halves are already knowable — the Vyto side from the commissioned glass, the
        audio side from whatever `Radio_open`/first-PCM already proves — so this is a `Supervisor_watch`
         to register (`arrive.playing`?) and a lift-rule to point at it, not new plumbing. Keep `CAP_MS`
          as the *give-up* path, not the *success* path — the distinction the whole doc is about.
 - **(b) It must SAY "no friend is online — you can play your own music."** Right now a friendless boot
    just shows a wait that quietly expires. The owner: *"it should also explain clearly that no friend
     is online and you can play local music instead. that should be part of its programming for
      Butlering this type of Jamsend party… it doesn't DO anything with your local music yet, but you
       can listen to it of course, as its what this machine does."* Note the scope: **words, not
        behaviour** — no new local-playback path, just the honest sentence at the give-up moment. The
         material is all present: `Supervisor_given_up('swarm.arrival')` + `Supervisor_because` (which
          exists precisely so a give-up doesn't lie about an invite that was never minted) + the
           `radio.solo` dial. This is the "programming for this type of party" — the first hint that
            Butler wants **per-party scripts**, not one hardcoded arc.
 - **(c) One semi-hidden persistent-state toggle**, *"like we used to have, quit_fullscreen or so"* —
    i.e. a small, deliberately unobtrusive control whose state SURVIVES a reload. Grep the prototype
     for the old `quit_fullscreen` idiom before inventing one. Persistent state means a particle, not
      a component `$state` (see [[derived-in-a-face-is-a-fact-thrown-away]]) — and a snapped boolean
       rides as `1` or ABSENT.

**THE NEXT MOVES, in the order they're likely cheapest:**
1. **Build the Butler brief above** — (b) is the cheapest and the most user-visible; (a) is the one
    that makes the screen mean what its name says. *(The shelf-grace fix from earlier tonight is
     CONFIRMED FIXED by the owner — `radio.shelf` no longer flashes red on a boot-empty shelf.)*
2. **Decide BOMB #1** and build the `eternal`/`Supervisor_teardown` split if the owner wants it —
    small, mechanical, but needs the persistence-semantics call first.
3. **Mutation-test at least one watch and one dial** — still true from every earlier note today: *"a
    green dial gates nothing until it has been seen to go red on purpose."* None of the ten
     watches/dials built today has been forced wrong and watched recover. Do it on a runner nobody
      else is using — tonight's `steps`/`release` mix-up (turned out to be the owner's own VytoNest
       run landing on the same runner, not a stranger) is the standing hazard: always check `run.book`
        matches before trusting or releasing anything.
4. **Chase BOMB #2** properly, or decide it's accepted cost — either answer moves `music-from-a-friend`
    from "flaky" to "understood."
5. **Decide BOMB #3** — one tree cell or accept the crowd.
6. **Never verified by a human eye**: the fancy `Butler` pass (aurora/glass-card/glint — type-checks
    clean, never seen live), the happy-spool's actual `/log` line shape (dev can never exercise
     `/log` — prod only), and the notice ring's on-screen appearance in `SupervisorPanel`.

**Untouched from earlier in the day, still real**: the runner/player role mess (Cluster_spec §3.2b
 territory), and the §10.3 provenance ruling the owner still owes (gates the What Heisted ledger too).

### ⇑ 2026-08-10 (evening) — THE TRACE, THE TREE CELL'S BUG, AND WHAT IT COST

**Supervisor is in the trace.** Every watch/dial turn now also lands on `M.c.supply_trace`
 (`Supervisor_supply_trace`, guarded `typeof this.Radio_trace === 'function'` — the same cross-ghost
  idiom Repli.g and Swarm.g already use, silent on a world with no Radio). Verified live on `f5da`:
   `radio.shelf → ✓` right after a fresh boot's stoker filled the shelf, then `sound.audible → ✗ → ✓`
    and `radio.solo → ✓ "your own music (gathering)"` four ms apart at the exact moment `Radio_open`
     cut over — **a live instance of the race this session's Supervisor work exists to catch**: this
      boot had a mutually-sealed pier but dialed before Righto's chunks landed, and the reading is
       correctly `gathering`, not a bare "alone".

**THE TREE CELL HAS NEVER RENDERED — since 2026-08-07, not since today.** Chasing the owner's ask to
 compare the Supervisor-as-pure-C-tree against the bespoke faces (`runner_shot --svg` with `show_diag`
  on), the capture showed **4 molds where 6 were minted** and neither Tree was one of them. Root
   cause: `cyto_face_kind` (`Cyto.svelte:746`) resolves a face by `sc.face` (worn) or `FACE_MAINKEYS`
    (imposed) — and **`Tree` was never added to `FACE_MAINKEYS`**, nor does either `%Tree` mint set
     `sc.face`. So the ORIGINAL underworld tree (`show_diag`'s "the machinery leading up to the radio")
      has been dark this entire time; nobody had looked at a capture of it before. Fixed — one entry
       added to `glass_faces.ts`. **Not yet re-verified after the fix settled** (see below).

**RE-SHOT AFTER THE FIX, AND IT PROVED RULE 5 THE HARD WAY.** With the registration in place: `Tree:1`
 appeared at **fit 0.407** (17% of its natural area, crushed), `Supervisor:watching` at **0.937**
  (88%, no complaint), `Radio:playing` pushed down to **0.581** — and **the Supervisor tree, Door and
   Shuffle molds vanished entirely** ("5 cells (2 crushed) · 1 with no room"). Six organs competing for
    a fixed glass is exactly the 2026-07-28 friend-Crate ruling in miniature: *"two more cells made
     every jewel unreadably tiny."* **This is not a small tuning nit — it's the answer to the
      comparison the owner asked for**, and the answer is nuanced: the pure-tree instrument is legible
       when it has room and disappears when it doesn't, which the bespoke faces mostly don't do (they
        shrink, they don't vanish). Both are diag-gated so it costs nothing today, but "alongside, not
         instead" cannot be the end state — a decision is owed: pick ONE tree cell at a time (toggle
          between underworld/Supervisor rather than minting both), or accept that `show_diag` is a
           trade a developer makes deliberately and never meant to look tidy.

**STILL UNPROVEN, still true from the midday note:** no dial reading has been seen by an eye that
 wasn't a runner_shot capture; **no dial or watch is mutation-tested**. That is still the next honest
  job, and it now has a channel to prove it in — a forced-wrong probe should show up on the SAME
   `world` trace timeline within one Supervisor tick.

**A LIVE PERFORMANCE FINDING, unrelated to Supervisor, surfaced for free by reading the same trace:**
 `Radio_open`/`Vyto_focus` firing holds the **beliefs mutex for 1–3s**, and everything else queues
  behind it — `drain-lag` marks show `fn:handle_inbound` waiting 2744ms with 49 gated calls,
   `Vyto_focus/Vyto/Vyto` waiting 2730ms across 349 tries, `fn:swarm_share_beat` waiting 2464ms — all
    inside the same ~3s window, right when the track actually starts playing. This is plausibly the
     "not go quite perfectly" the owner named. Not yet traced to a cause.

### ⇑ 2026-08-10 (afternoon) — DIALS, THE RADIO'S AIM, AND THE TREE CELL

**`Radio_dial_pool` was one flat bag.** Every `%MusuThem` shelf walked, every record that passes
 `Radio_playable` and isn't in `radio.c.heard` thrown into one array, uniform random pick. So a second
  friend arriving **silently diluted the first mid-session** — you were listening *with somebody*, and
   then with no event and no notice you were listening with a crowd. A defensible shuffle and an
    indefensible social act.
 **The aim** (`radio.sc.aim` / `aim_by`) locks on the first friend we actually **play**, not the first
  %Pier that exists — playing somebody's record is when a session with them starts; a sealed contact
   from weeks ago isn't. It **re-aims only when the aimed friend yields nothing this dial**, so a
    friend going offline hands the radio on rather than stranding it and nobody has to clear it. The
     fallback pool is exactly the old behaviour, so this can only narrow a choice that was already
      arbitrary. `rec.c.from_pub` carries which shelf a record came off — `.c`, since a pub in the
       record's own sc would be a second particle impersonating the holding.

**DIALS — the overall states, as particles.** The owner: *"I want it to contain the overall states
 like 'we have Pier', 'have remote music' — it needs some more reliable dials to read."*
 These facts already existed, **and that is the defect**: "we have Pier" was computed inside
  `DoorFace.svelte`, "we have remote music" was scattered across a deletion in `Radio_open`, a `by`
   key on some Cards, and a name lookup. Derived in a face, used once, thrown away at the face
    boundary. A number in a `$derived` cannot be snapped, asserted by a Book, bumped for another face,
     or compared between two tabs. A particle buys all four.
 `%Dial` is a sibling of `%Watch`, not a variant: a watch answers *is this ok* in three words and
  exists to go loud; a dial answers *what is the state* and exists to be read when all is well.
  **The five rules, each already paid for here** — in `Supervisor.g`'s dial region with its receipts:
   ① a dial may not mutate (`Ra_stock_standing` deleted files two calls down) · ② `unknown` is
    first-class, never folded into no (the FSA guards no-opped and answered) · ③ a composite shows its
     parts, never an AND — hence `state:'part'` exists so a face **cannot** round a half-seal ·
      ④ if it matters it rides `sc` (`pier.c.heard_at` never snaps and resets on reload) · ⑤ a
       monotone number is not coverage.

| dial | owner | reading |
|---|---|---|
| `swarm.piers` | Swarm | `2 sealed · 1 sealing · 1 online (Righto)` — rule ③, the half-seal that cost a live evening |
| `radio.remote` | Radio | the owner's ladder, three rungs never collapsed |
| `radio.solo` | Radio | `radio.sc.solo` was a **deletion nobody could watch**; now a reading |
| `radio.fresh` | Radio | `round again — 0 fresh of 14 · replay 3` — rule ⑤ made concrete |

**"Remote music" is a LADDER, and collapsing it is the trap** (*"remote exists, has heard of music,
 and then has music ready to play"*). Three rungs, three different things to do about it: no friend →
  `no`; a friend with nothing counted → `part`; **records known but none warm → `part`** ← the rung a
   boolean answers *yes* to; playable → `yes` with the count that would actually be drawn.
 `Radio_pool_census` is the one honest counter, and it exists because counting friend `%Cards` says
  yes while the radio has nothing to play: a record is only reachable if **chunk 0 is in the warm
   window**, and `radio.c.heard` is keyed by **bare id**, so your own listening drains the friend pool
    and two tabs on one box share ids.

**THE SUPERVISOR AS A PURE C TREE — done, and it cost one grapple.** Nothing was built: the roster is
 already pure scalars, `TreeFace` (GLASS_KINDS `Tree`) already draws any particle recursively, and
  Matstyle auto-swatches new mainkeys. `Sounditron_commission` now pushes a second `%Tree` organ with
   `c.tree_root = supw`, under `show_diag` — **the one branch where a cell costs no fixture**.
 The case for it is a measurement, not taste: `SupervisorFace` rendered at fit **0.552** and **0.782**
  on two live tabs — 30% and 61% of its natural box — because a bespoke HTML face *has* a natural size
   it must win from the layout and usually doesn't. A C tree has no natural box; it fills its cell,
    and the face-size fight ends by construction.
 **Alongside, not instead.** Cell, panel and tree all stand. Next: `runner_shot --svg` both tabs with
  `show_diag` on and compare molds / fit / crushed counts. **If the tree reads better in the capture,
   delete the bespoke faces and take the rest of the tree the same way.**

**Verified:** the blind-spot gate now covers **dials as well as watches** (one line in
 `Sounditron_supervisor_blind`) and went **green on `58517b48` with all four dials registered** — so
  every dial probe resolves by name on a live runner. No thrown errors, 8/8 steps. `music-from-a-
   friend` remains ABSENT and every step's dige mismatched; **fixtures not re-recorded**.
 **Not verified:** no dial *reading* has been seen by an eye, and per the brief none of them is
  mutation-tested — a green dial gates nothing until it has been seen to go red on purpose. That is
   the next honest job, and a `%see` per dial is how it gets paid for.

### ⇑ 2026-08-10 (midday) — "is all this being architected nice?" — no, and here is the fix

**It was starting to be spaghetti, and the shape of it is worth naming.** Three faces had each grown
 their **own copy of one judgement**: the panel had its own `rank`/`mark`/`tone`, the Butler its own
  filters, the model its own again. Three opinions about which row is worst and what glyph it wears,
   drifting one edit at a time. Radio.g already carries the sentence for this disease — *"two copies
    of one judgement is how a face starts lying"* — written after a page told a listener the opposite
     of the truth for exactly this reason.

**The rule now: the MODEL judges, the FACES render.** `Supervisor_lines(w)` returns every row already
 ordered, marked and toned. A face chooses **what to show** (the cell takes one row, the Butler the
  arc, the panel everything) and **how it looks**. It does not decide what a row means. *If a face
   needs to know something, the fix is a field on `Supervisor_line`, not a second opinion over there.*

**SEVERITY ORDER ≠ ARC ORDER** (the owner: *"the list of goals it has is badly ordered — the first one
 comes last, could do with more structure"*). The cell has room for one line, so it wants the worst
  thing (`Supervisor_speaking`). A **list** is the story of a machine coming up, so it wants the arc,
   done rows and all (`Supervisor_lines`). Sorting a list by severity is what put the finished first
    step at the bottom. Structure comes from a **`stage`** the *registrar* declares —
     `Supervisor_stage('self'|'door'|'share'|'friend'|'sound'|'story')`, gaps of ten, **unplaced sorts
      last** so a watch whose owner never said where it belongs can't wedge into someone else's arc.

**ONE ARRIVAL, NOT TWO GATES** (*"a from-page-load FaceSucker that says 'starting up', then it
 vanishes but then another FaceSucker comes for 'one tap to open the music'… the second needs keeping
  out of happening by the first"*). The mechanics moved to **`boot_gate.svelte.ts`** — one
   implementation of the permission tap, including the load-bearing rule that the FSA picker and the
    AC resume must each be **initiated inside the click's gesture**. BootGate stands down while
     `H.c.butler_up`. The Butler shows **one big orange `open share`** button while a permission is
      pending, and that hold is the **one thing not capped**: a permission is not progress news, and
       timing out of it would just hand the screen back to BootGate — two gates in the other order.

**"SUPERVISOR SHOULD NOTICE ANY INTERESTING THING HAPPEN"** — `Supervisor_notice` + a 12-deep ring,
 and it is general rather than a list of call sites because **`Supervisor_stamp` notices every watch
  that CHANGES ITS MIND**. Nothing opts in; the healthy majority that reads the same thing forever
   says nothing, ever. A first read is a registration, not an event, so it is silent.
 The ring lives **entirely on `.c`** — a new row per interesting event, each carrying a wall clock, is
  the churniest thing there could be in `sc`, and it would rewrite every downstream fixture forever.
   Notices are for a human watching a live machine. *If a Book ever needs to gate on an event, the
    answer is a `%see` assertion at the moment it happens — that is what assertions ARE.*
 A notice is genuinely a **third kind**, not a watch in a hat: a watch is a standing question we
  re-ask and can answer wrongly then rightly; a notice is a moment, true forever, answering nothing.
   Modelling "a friend just arrived" as a watch is how you get the posed heist back.

**THE CELL NOW NARRATES THE WAIT** (*"it should be talking about a Pier coming online while we're
 waiting for it"*). Quiet-when-healthy was reading too broadly: a watch inside its patience is not a
  fault — it stays out of `loud`, so the cell doesn't swell or redden — but it is the most interesting
   thing on the machine at that moment. Order is now **faults → the wait → all-well**. **No countdown
    in `say`**: a number that changes every second is a key that churns every fixture forever; the
     sentence is stable for the whole wait and a face reads `left` off `Supervisor_lines` and polls.

**STILL OPEN — RADIO INTENTION.** The owner: *"it plays radio with the first Pier to connect anyway.
 but then subsequent Piers that connect, we don't aim the Radio at. perhaps there's more Radio backend
  modelling to do about intention like that."* **Not built.** Today the friend pool draws from every
   sealed pier, so a second arrival silently joins the lineup. The shape this wants is an **aim** —
    the pub the radio locked onto, set once at first live pier, with the pool preferring it and
     falling back only when it goes dry or offline. That is a real change to `Radio_dial_pool` and
      deserves its own pass rather than being smuggled in beside a UI change.

**⚠ THE DEFAULT `runner` ADDRESS MOVED MID-SESSION.** The 11:52 Sounditron run landed on
 `58517b48…`; the 12:29 run landed on **`96d0cf88…`** — the music tab the owner had just loaded (the
  snap's `MusuSelf,pub:` is the tell, and `runner_ask ping` confirms `self`). So **those two runs are
   not comparable** and the second one's better assertion count proves nothing about the edits. Both
    were released. Address a specific tab with `--runner=` when a comparison is the point.

### ⇑ 2026-08-10 (morning) — THREE SURFACES, TWO REACTIVITY BUGS, AND THE BOOT WAIT

**The owner killed a peer (Lefto) to produce the case, and it produced three findings.**

**1. `sc` IS NOT REACTIVE. Only `version` is.** `TheC.sc` is a plain object; `X.serial_i` is the
 `$state`. So `Supervisor_stamp` and `Supervisor_say` — which wrote `sc` every tick and bumped
  nothing — were invisible to every face: **the model read the world each tick and showed you a
   photograph of its first one.** Radio.g's `radio.sc.note = note; radio.bump()` is the standing
    idiom and it is not decoration. Both writers now funnel through one place (`Supervisor_stamp`,
     `Supervisor_summary`) and **bump only on change** — an unconditional bump would put the whole
      roster into every consumer's churn forever.
 *The general shape*: if a face is stale and the model looks right, check for the bump before you
  check anything else. Related: `spec/` has no doc on this and probably should.

**2. A face gets `H` AND NOTHING ELSE.** BigSoundland mounts registered UIs as
 `<svelte:component this={ui.sc.component} H={house} />`. `SupervisorPanel` asked for an `n` prop
  that is never passed, so `n.c.up` was undefined and it printed **"nothing registered — nothing is
   watched"** over a full roster. It now resolves the world the way `Supervisor_w` does (top House →
    `A:Supervisor` → `w:Supervisor`) and distinguishes **"no world"** from **"empty roster"** — two
     diagnoses pointing at opposite halves of the machine, and conflating them cost a round.

**3. THE THREE SURFACES** (the owner: *"the one in the cell must be very simple and small and have
 anything we want in the UX, the UIs:Supervisor can have all the rest of the guts of it, for devs"*):

| surface | who for | rule |
|---|---|---|
| `SupervisorFace` (Vyto cell) | the listener | tiny, and **silent while well** |
| `Butler` (FaceSucker) | the listener | the only one that seizes the screen, **at boot, once** |
| `SupervisorPanel` (`UIs:'Supervisor'`) | devs | everything: probe NAMES, latches, patience, log ladder |

**THE BUTLER — the loading screen, and the three ways out.** A gate over the whole app is a promise
 that it will lift, so: nothing left waiting (the normal exit), a **12s cap**, or the *carry on* tap
  — and once lifted it **latches down for the tab**. That latch is the important part: minting an
   invite mid-session arms an expectation too, and a fullscreen gate dropping over somebody's music
    because they showed a friend a QR code would be the worst bug in that file. It knows the
     Supervisor and nothing else — no subsystem is named in it, so a watch registered tomorrow
      appears on the loading screen tomorrow with no edit there. Altitude **55, under BootGate's 77**:
       a permission the listener must grant outranks news about work in progress. Never over a Book.

**THE BOOT WAIT — the owner's actual ask** (*"this is that start-playing-our-own-music situation…
 which happens anyway, I actually want it to WAIT, and start playing local music when peer given up
  on"*). A **second event** now arms the same 5s expectation: `Swarm_expect_friends`, at the bottom
   of `Swarm_station_up`. Still event-driven, not the ambient hoping §the-expect-header warns off —
    the event is *this boot*, it fires once per standup (inside the `station_up` guard, so it cannot
     restart its own clock forever), and **no piers ⇒ no hope** (five seconds of silence bought with
      nothing). Each arming stamps `sc.because`, because the give-up sentence depends on it:
       *"nobody answered your invite"* is a lie on a tab that never minted one, and that lie was in
        the radio's mouth on every friendless boot.

**TWO NEW WATCHES, both registered from idempotent verbs that are re-entered until they take** — the
 pattern worth copying, because registering *after* success latches a milestone met on its first read
  and it never says anything:
- `swarm.station` (milestone, `Swarm_watch_station` at the TOP of `Swarm_station_up`) — *"this
   machine is on the relay — friends can reach you"*. The highest-level task there is; a tab that
    never gets it looks like a slow start rather than a dead relay.
- `radio.shelf` (**standing**, `Radio_watch_shelf` in `Stoker_ensure`) — *"there is music in your
   share — records to play"* (the owner: *"we also need to notice when there's no music at all in
    their share"*). Standing and **not** a milestone on purpose: a share is opened, closed and
     re-opened, and a milestone would latch on the first record ever seen and go quiet — the posed-
      heist failure in miniature. Three answers, not two: *no shelf yet* (`unknown`, still booting)
       is not *empty share* (`wrong`).
 Both probes read with `o()[0]` and never `Ra_home_self`/`Swarm_station_world`, which are `oai`
  chains that would **mint the thing they were asked about** on every tick — the "a probe that
   collects" trap the file header names.

**WHAT IS UNPROVEN.** The Butler has never been seen (no browser here). The 5s hold has still never
 fired end-to-end. `Sounditron` on the runner went all-red **with the peer deliberately killed** —
  `the-supervisor-stood` and `every-registered-watch-found` both went **green** (so the roster and
   both new probes resolve), and the three ABSENT assertions are all peer-dependent (`granted`,
    `a-friend-counted-their`, `music-from-a-friend`). **Fixtures were NOT re-recorded**: a Book that
     measures a two-peer story must not have a one-peer world baked into its gate.

### ⇑ OVERNIGHT 2026-08-10 — patience, the give-up, and the report that travels

**THE BOMB IS DEFUSED.** The three sensors that had landed with no reader now have one, and the
 roster is *proved* to have no blind spots:

| sensor | reader | probe |
|---|---|---|
| `Swarm_beat_health` (08-08) | `swarm.beat` | `Swarm_probe_beat` — `slow` is deliberately NOT wrong |
| `Vyto_normal` (08-09) | `sound.glass` | `Sounditron_probe_glass` — reads its findings, never calls it |
| `Radio_sound` (08-09) | `sound.audible` | `Sounditron_probe_sound` — grades three silences apart |

`Vyto_normal` is **not a probe** and must never be registered as one: it POKES (re-seeds cells,
 stirs). The watch reads `normal_said`, the findings it leaves behind. And the probe lives in
  **Sounditron, not Vyto** — the commissioner asks whether its commission is honoured; a subsystem
   reporting on itself is the weakest possible witness.

**The blind-spot gate, and why it had to exist.** A probe is resolved by NAME, so a typo or a rename
 leaves a watch that reads `unknown` forever and is indistinguishable from a healthy one. Declared and
  green: `%see:'every registered watch found its probe — no blind spots in the roster'`, plus a `%log`
   row naming the offending keys when it fails (only present when broken, so a healthy fixture never
    churns).

**PATIENCE — the primitive this doc's title was always about.** `Supervisor_expect(...secs)` arms an
 expectation; `Supervisor_hoping` / `Supervisor_given_up` rule on it. Two details are load-bearing:
  the deadline rides `.c` (a wall clock in `sc` churns every downstream fixture forever) while only
   the GRADE snaps; and **the rulings read the deadline, not the grade**, because the grade only
    refreshes on the Supervisor's tick and a caller asking between ticks would give up late.
 A watch still inside its patience is **not loud** — shouting during the seconds a thing is working
  is the HUD failure in a new hat.

**EXPECTATION IS EVENT-DRIVEN, NEVER AMBIENT** (the owner: *"the cases when we'd expect a Pier are
 just right after an Invite… essentially just saying 'come here', in a QR code"*). Armed at
  `Swarm_invite_url` — including a re-invite to a Pier+Grant already held. **Not** at
   `Swarm_mint_idzeug`: the blotter mints 126 serials there for a sheet to be printed, which is not
    "come here", and arming there would stall the radio 5s every time somebody prepared one.
 Radio holds for those 5s and then falls through exactly as before. `Supervisor_hoping` answers 0
  when nothing is armed, so every existing path is byte-identical — only the seconds after an invite
   differ.

**`Radio_alone_why` — the owner's "looks like bad code" was right, and the reason is precise:** it
 answers *"who is around"* when the question that matters is *"who did we just invite"*. `anyPier`
  treats any stored %Pier as an expectation, so it says "your friends are offline" about a contact
   from weeks ago. Repaired narrowly with a `gaveup` tag ahead of the stored-pier cases.

**THE REPORT THAT TRAVELS — and `/log` IS NOT OURS.** It is **leproxy's `handle_path` in front of the
 perl `tyrant-logger`** (`docker-compose.prod.yml:61`, commented out in dev), and
  **`Cred_report_wild`** (`Auto.svelte:1242`) has been posting Book outcomes to it all along. So the
   contract was already set and this reporter matches it rather than inventing a second one:
    newline-joined **JSON lines** (not a JSON object), `?stream=<name>-<self8>`, and **skipped on
     localhost** — a dev tab would only 404-spam, which is why `Cred_report_wild` takes the same exit.
 **A first draft got this wrong and it is worth recording why.** It shipped a `src/routes/log/+server.ts`
  and posted a JSON object. Both were mistakes: the route **shadowed a real service** (harmless while
   leproxy peels the path first — a telemetry-stealing bug the day it does not), and the body was a
    format nothing at the other end parses. The dev 404 that seemed to prove the endpoint "off" was
     really just proof that `/log` does not live in this app at all. **Route deleted.**
 What is genuinely new is the **ladder**, which the existing rail does not have — it only `.catch`es
  and warns: `2xx` ok · `404` dormant, silently · `401|403` stop and SAY so · `429|5xx` back off,
   capped at an hour · unknown status retryable.
 Lines: one `health` line ALWAYS (a census needs its denominator) plus one `watch` line per unhealthy
  watch. A healthy tab costs one short line every five minutes.

**PAYLOAD: COUNTS AND VERDICTS ONLY, and this is a §10.3 matter, not a style choice.** A report that
 named a friend, a pub, a track or a path would be *answering* the owner's unruled question about
  whether the provenance ban is privacy or convenience — a privacy decision arriving disguised as a
   telemetry feature, which §10.3 explicitly warns against. Sentences travel (every one is a string
    literal in this repo); `note` does not (notes carry friendly names and shelf counts). Identity is
     **per-boot only**, held on `.c`, so it never follows a person across sessions.

**Verified / not verified — read this before trusting any of it.**
- ✓ Roster blind-free; both supervisor assertions green at step 2 on a cold runner, no throws.
- ✗ **NO rung of the log ladder has ever been exercised for real.** `/log` is prod-only, so every dev
   tab takes the localhost exit and the reporter goes dormant without sending. The ladder is
    unproven code until it runs somewhere with leproxy in front. Treat it as such.
- ✗ **The 5s invite hold has never been seen to fire.** `poke` exposes only
   `Radio_toggle|Radio_skip|Radio_source_toggle|Sounditron_diag_toggle`, so an invite cannot be minted
    from the CLI. Ten-second manual test: hit the invite QR — the radio should read *"waiting for
     someone to answer your invite"* for 5s, then *"nobody answered your invite — playing your own
      music"*.
- ✗ **Sounditron was not re-run on `f5da6599` after the last changes** — that tab is a `♪player` and
   `run` is refused on players (see below). Last real run there was 5/8 before the log/watch work.

**THE TRAP THAT COST AN HOUR, recorded here because it will recur.** `runner_ask` with no address
 targets the relay's `runner` role, and that binding is additive fan-out — a *different tab* started
  answering mid-session, turning Sounditron all-red in a way that looked exactly like a regression in
   `Radio.g`. Worse: `--player=<pub>` addresses the right tab but **cannot run a Book** (`run`,
    `release`, `accept` are refused), while `state`/`steps`/`assertions` still answer *from that tab's
     last real run* — so a refused run followed by `steps` returns a plausible, stale, entirely
      convincing result. **Never send `run` output to /dev/null.**

**TWO INSTRUMENTS, NOT TWO SIZES OF ONE** (the owner: *"it needs a UI outside of the Vyto as well, as
 that one is very very minimalist"*). `SupervisorFace` (the glass cell) answers *"is anything wrong"*
  at a glance and **must stay silent when the answer is no** — that silence is the entire reason it
   replaced the idle HUDs, so it can never also be the place you go to READ the roster.
    `SupervisorPanel` shows **everything, including the healthy rows**, because when nothing is wrong
     the interesting content is precisely the list of what was checked. Registered as `UI:'Supervisor'`
      by `Supervisor_plan` using the `Vyto_plan` idiom, so BigSoundland mounts it through the UI
       surface it already has — no change over there. Reach it with **▦** (or `?`).

**THE `?` BUG — three cuts, and the lesson is the third one.** `Sounditron_probe_glass` reported
 `unknown` forever. A probe runs inside the *Supervisor's* read pass, so `this` is Mundo, not the
  Book's House. Cut 1 copied `Sounditron_glass`'s `this.up ?? this.top_House()`; cut 2 "fixed" it by
   climbing from the subject to the Run House — but that House's snap carries `A:Sounditron` and **no
    `A:Vyto`**, so cut 2 would have turned a visible `?` into a confident wrong answer.
 **There is no fixed home to hardcode.** BigSoundland's own `vyto_trace` walks EVERY House, and it is
  authoritative because it is the code that finds the live glass for the badge. The probe now walks
   too (`Sounditron_houses` = Mundo + every `H:` under it) **and names where it looked** — "no A:Vyto
    in any of N House(s)", or the House it found. A verdict that says only "I could not find it" costs
     a person the whole diagnosis; that is §5 in one line.

**Owed by the owner, unchanged:** `%Caper` vs `%Pull`; the §10.3 provenance ruling (which also gates
 the What Heisted ledger); and whether `music-from-a-friend` should stay declared when it can only
  hold while a friend is actively streaming.

---

### ⇑ IT STANDS — 2026-08-09, later the same day

`w:Supervisor` is **built, live, and witnessed**. `Ghost/O/Supervisor.g` (new ghost, new `Ghost/O/`
 shelf, in `CREDULER_GHOSTS`), the world stood on **Mundo** by `Auto.svelte` beside the Creduler
  Lies, a `%Supervisor` summary row faced by `SupervisorFace.svelte`, grappled onto the glass by
   `Sounditron_glass`. The fake posed heist is **deleted** and its four honest readings are the first
    four registered watches.

**The generalisation the owner asked for, and the law that makes it work:** *"processes can host
 things for it to watch."* Supervisor **never names what it watches** — there is no list of
  subsystems in that file and there must never be one, or it becomes the posed heist again. Every
   watch ARRIVES via `Supervisor_watch(w, key, sentence, kind, fn, subject)`. The probe rides as a
    METHOD NAME, resolved off the House at read time, so it snaps, greps, and survives a ghost
     reload; an unresolvable name reads `unknown`, never a throw.

**Slope of ownership — settled.** Supervisor knows nothing about Vyto; Vyto knows nothing about
 Supervisor; the COMMISSIONER knows both (`e_Vyto_commission` already takes `client_w`/`grapples`
  off the req, so this was granted, not built). Consequence that matters: Supervisor works with **no
   glass at all** — a watcher that needs the UI up cannot report that the UI is down, the exact trap
    `Radio_sound` sits in.

**Two kinds of watch**, because both were asked for in one breath: `milestone` latches `met:1` and
 goes quiet forever (an invite answered); `standing` never latches and may go wrong again (there is
  sound, the peer is up). The old posed Needs latched all four alike — so a friend who went offline
   read `met` permanently. That bug is gone by construction.

**Proof, not a green file.** Every call into the Supervisor is guarded, so one that never stood up
 and one that works perfectly look identical from outside ([[a-quiet-file-proves-nothing]]). So the
  Book witnesses it: `%see:'the supervisor stood — a roster of registered watches is being read'`,
   gated on `Sounditron_supervisor_reading(w)` — a count of watches carrying an actual **verdict**,
    which only `Supervisor_read` stamps. Non-zero proves the whole chain: ghost loaded → world stood
     on Mundo → worker ticked → roster walked → probes resolved by name and answered. It swore at
      **step 2**, from a roster the PREVIOUS run registered at beat 5 — the first observed proof that
       the roster outlives the run, which is the whole reason it lives on Mundo.

**Where it is red.** Sounditron now runs 5/8 green (1–5, on spayers). Steps 6–8 are red **by
 construction**, not by this change: two identical back-to-back runs re-dige every step, because
  6–8 snapshot whichever track the radio happens to be playing. Do not chase them with `accept`.

**Next moves, in order.**
1. **Provoke the sensors.** Still four sensors with no reader and no proof (table below). Registering
    `Swarm_beat_health` / `Vyto_normal` / `Radio_sound` as watches is now a one-line call each — and
     THEN each must be seen to go red. That is the work; the roster just made it cheap.
2. **The reload BUTTON** (constraint 3). Deliberately not built: a cure is a req, and half a cure is
    worse than none. It hangs off the watch that diagnosed the fault.
3. **The Invite narrator** — the owner wants to be *talked through* the invite arc. That is a
    different organ from a watcher (it has opinions about what you should do next); a `milestone`
     roster is its substrate, not its implementation.
4. **Its own pop-up glass.** `A:Vyto` is one-per-House, so Supervisor-on-Mundo + app-glass-on-Run
    already means two staple points and two coexisting glasses, no new machinery. Unverified — check
     which House the live BigSoundland glass staples to before relying on it.

**Still owed by the owner:** `%Caper` vs `%Pull` (they said *"I don't get it"*; unchanged, four Books
 to re-record if it moves).

---

### ⇑ HANDOVER 2026-08-09 — the destination, the bomb, and the next move
*(kept: this is the reasoning that produced the build above, and the sensor table is still live)*

**Destination.** ONE sanity cell on the glass that is silent when the app is healthy and speaks up
 when it is not, with a reload BUTTON and no auto-anything. The owner has asked for it three times in
  different words (`Sounditron.g:296` — *"ONE sanity cell that speaks up when something is actually
   wrong, rather than a rank of idle HUDs each saying nothing at full volume"*; §8's consent split;
    §9's normalcy roster). It does not exist. Everything else in this doc is substrate for it.

**THE BOMB — three sensors are built and NOT ONE HAS EVER BEEN SEEN TO FIRE.**

| species | sensor | landed | fired? |
|---|---|---|---|
| STUCK — a machine that stopped | `Swarm_beat_health(w)` (`Swarm.g`) | 08-08 | **never** |
| WRONG-LOOKING — running, bad result | `Vyto_normal(w)` (`Vyto.g`, §9) | 08-09 | **never** |
| SILENT — no sound coming out | `Radio_sound(radio)` (`Radio.g`, §10.1) | 08-09 | **never** |

Plus a fourth that is finished and **has no reader at all**: `Swarm_watch_loop` (`Swarm.g:2009`) —
 a plain `setTimeout` sensor, correctly OUTSIDE the belief loop, stamping `w.c.watch` every 2s.
  Nothing anywhere reads `w.c.watch`.

So the honest state is: **four sensors, zero readers, zero proof.** Do not add a fifth. A green
 sensor gates nothing until it has been seen to go red ([[mutation-test-every-claim]]) — one claim
  in this repo was already found to be pure theatre that way. Provoking each of the three on purpose
   IS the work, not a follow-up to it.

**Next move — delete the fake and build the cell in its place; they are the same move.**

`Sounditron_heist(w)` (`Sounditron.g:1227`) mints a POSED cell — `%Caper:'the one they played last
 night', posed:1, from:'a friend to be'` — design scaffolding from before the machinery existed. Its
  guard (`if (w.o({Caper:1})[0]) return`) was meant to retire it once a real Caper stood, but **no
   live path ever mints one** (every `Heist_wish` caller is in `Heistation.g`, i.e. Books), so on a
    player tab it is permanent, and `Sounditron.g:306` puts it on the glass whenever there are no
     keeps — a fresh tab. The owner 2026-08-09: *"it's time to delete the fake"*.

**Salvage before deleting.** `Sounditron_heist_met` (`:1240`) keeps four of its `%Need` rows HONEST
 every pass — `met:1` only rides a Need the world actually satisfies:

  · a sealed Music grant · the friend online · their shelf counted · real bytes crossed
   (`Sounditron_pulled`, `:1258` — first chunk present on any friend record)

Those are live readings, not decoration. They answer **"can this tab receive music?"** — a readiness
 ladder. The three sensors above answer **"is this tab working right now?"**. The sanity cell is one
  place where all seven stand. Delete the fake headline, keep the readings.

**Four constraints the build must honour** (each is a lesson already paid for):
1. **Quiet when healthy** — one calm ✓, expanding only on a real fault. The reason the old HUDs were
    taken off the glass was that they were loud and said nothing.
2. **Sensor outside the belief loop, verdict inside.** §4's ruling. A watchdog under the beliefs mutex
    queues behind the wedge it exists to detect. `Swarm_watch_loop` already has this right.
3. **A reload BUTTON, never a reload** (§6 anti-goal; the owner: *"may suggest reload — but doesn't
    actually, yet"*). A reload on a bad guess destroys the evidence of the bug it misdiagnosed.
4. **The verdict belongs in a req** ([[req-is-where-state-belongs]]) — but only the verdict. The req is
    right for the response and wrong for the sensor.

**One open question for the owner, unanswered:** the owner's sketch was a `w:Supervisor` world beside
 `w:Story`, gated on a Book opt. A world is the honest home if the roster is going to grow; a single
  `%Supervisor` cell on `w` is a tenth of the work and is visible today. Recommendation: build the
   cell, promote it to a world when the roster earns it. **Not decided — ask.**

**Vocabulary note (2026-08-09).** `%Haul` → `%Heist` (one nab of one album), old `%Heist` → `%Caper`
 (the pull operation; `%Heistlet` → `%Caperlet`). See `Heist_todo.md`. The owner does not like
  "Caper" (*"what the heck is a Caper? I don't get it"*) — `%Pull` was offered as the plainer name and
   is **not yet decided**. If it changes, the cost is re-recording MusuHeist · MusuBay · MusuSoft ·
    MusuBreach, which is mechanical and now well-rehearsed (diff every red step, filter the spayed
     `round=`, then `runner_ask accept`).

---

Nothing is built. Read §1 for why it must exist, then §3 — the substrate already landed today and is
 sitting unused, so step 1 is cheap:

1. **LANDED 2026-08-08 — `Swarm_beat_health(w)`** (`Swarm.g`, `4ba90e192f2bf1df`). A pure read
    returning `{state:'ok'|'slow'|'stuck', phase, for_ms, why}`, with `Swarm_beat_note(w)` folding each
     completed beat's phase costs into per-phase rolling centres and moving the `phase_at` cursor
      (called from the beat loop, after the busy-guard reset and try-wrapped — a watchdog that can
       wedge the thing it watches is worse than none). `Swarm_detached_health(w)` covers §4b.
   - Self-calibrated per phase (`phase_avg` EWMA × `beat_stuck_k`, floored at `beat_stuck_floor_ms`),
      because `keep` and `cull` differ by three orders of magnitude and one constant would either cry
       wolf at the cull or never fire for the rest.
   - **Nobody has seen it fire.** It is written and compiled, not proven. Its first real job is to have
      called the `Stoker_tour` wedge that a human found by pasting a console — replaying that from the
       fixtures, or provoking a wedge on purpose, is how it earns trust. Do that before step 4.
2. **A `%Watch` req** that runs it and carries the verdict (§4). Not a status string —
    [[req-is-where-state-belongs]].
3. **The Brink badge** reads the req (§5). Still no auto-anything.
4. **Only then** the give-up ladder (§6), and only with the human's say-so on where consent sits.

**Do not start at step 4.** A reload button that fires on a bad guess is worse than no supervisor: it
 destroys the evidence of the bug it mis-diagnosed, and it trains everyone to reload reflexively.

**§9 landed 2026-08-09** — the first NORMALCY customer: `Vyto_normal` checks presence + visibility at
 every settle and pokes the layout. A different species from the wedge-watching above — read §9.

**§10 added 2026-08-09** — three threads from the owner, in ascending cost:
 - **Sound (§10.1) — the READ LANDED, `Radio_sound(radio)`.** The analyser rig already existed and was
    built to read correctly through a mute; the live radio simply never tapped it. Now it does, as a
     pure read with no cure attached. **Nobody has seen it fire** — provoking a dry timeline on
      purpose is the next move, and it must happen before any skip is wired to it.
 - **Assertions (§10.2)** — the roster can only assert over the SNAP, so claim the CURE
    (`%see:'…went dry and skipped…'`), never the RMS. Audio is the first roster member a Book can
     witness at all, because it is not `vw_frame`-gated the way `Vyto_normal` is.
 - **Traffickers (§10.3)** — the liveness half is free and mostly a re-read of `c.xfer`. The history
    half is **blocked on an owner ruling** about whether the provenance ban is privacy or
     convenience, and that same ruling gates the What Heisted ledger in `Heist_todo.md`. Ask it as
      one question; do not decide it by building.

**READ §8 FIRST (added 2026-08-09).** The owner answered §7 Q1: consent splits by **who is in front of
 the tab**. A *runner* is categorically non-recoverable (a Book is one linear journey; a healed wedge
  produces green steps over a world that took a detour) and so is the right first customer for the
   `act` rung; a *player* tab gets notice→badge→offer and never a surprise reload. §8 re-aims this
    list without replacing it.

---

## 1. Why — three wedges in one day, all found by a human pasting a console

| what wedged | how it presented | how it was actually found |
|---|---|---|
| `Swarm_share_beat` stuck in `Stoker_tour` | relay healthy, tabs sealed, **neither peer took the other's stream**; `×241` skipped ticks | the human said "they aren't sharing music" and pasted a console |
| the Story drive, after a `.svelte` HMR | `run --watch` polls `phase:"begun"` forever; Story action buttons missing from the H header | the human noticed the missing buttons ([[svelte-hmr-wedges-a-book-drive]]) |
| a runner tab | advertises, won't answer pings | the human hit F5 |
| a runner's **run slot**, holding a `ghost_compile` | `running.book: "Ghost/M/Ra.g"`, `phase:"begun"`, forever — the runner looks BUSY, refuses every Book, and self-heals never | a subagent read the `.book` value and recognised a `.g` path where a Book name belongs |

**⚠ THE RUN SLOT MUST NOT BE ABLE TO HOLD A COMPILE** (the human, 2026-08-08: *"`stuck in its run slot` ew, can we push a TODO about making that impossible or something?"*).

> **NOT RADIOS' TO FIX** — the human, same sitting: *"the `run slot` problem is outside of Radios I
>  guess."* Correct. `running.book` belongs to the Story/Lies runner machinery, not the supply path,
>   and it is recorded here only because this doc is where wedges are catalogued and it would
>    otherwise be lost. **Whoever owns the runner side should take it.** The diagnosis below is a
>     handoff, not a plan of mine.

This is not a
 detection problem like the others — it is a **type error wearing a state machine**. `running.book`
  holds either a Book name or a `.g` path, and only one of those can ever finish; a compile has no
   steps, emits no `run_phase`, and so can never clear the slot it occupies. The fix is upstream of
    any supervisor:
- **Preferred: separate the slots.** A compile and a Book run are different jobs; they should not
   contend for one field. A compile that cannot enter the run slot cannot wedge it.
- **Failing that: make the slot self-clearing.** A `running` entry needs an owner and a deadline — if
   the thing occupying it emits no progress within its own expected window, it is released. That is
    §4a's monotonic-progress rule applied to the job slot instead of the beat.
- **Cheap immediate guard, worth having regardless:** refuse to accept a `.g` path as a Book name at
   the door. The value is structurally wrong and the code can see that without any timing.
 Until then the tell is exactly what caught it here: a `.g` path in `running.book` is a compile in the
  run slot, **not a stuck Book** — do not go looking for a Book bug.

Every one was a **silent** stop inside a machine whose job is to keep moving, and in every case the
 detector was a person reading a log. That is the gap. The app already knows more than enough to have
  said so itself — it simply never asks itself the question.

**The deeper reason this keeps happening** is `Composition_todo` §2: each part is individually correct,
 and correctness-in-isolation has no opinion about *liveness*. A verb that returns is correct. A verb
  that never returns is also, locally, not wrong — it just hasn't finished yet. Only something watching
   from outside the verb can call it.

---

## 2. The two failure modes a supervisor must tell apart

This is the whole design problem, and getting it wrong is what makes watchdogs hated.

- **SLOW** — making progress, just not fast enough. `Ra_shuffle_cull` legitimately takes **70 seconds**
   on a 543-directory crate. Killing or reloading through that destroys real work.
- **STUCK** — not making progress at all, and never will without intervention.

**Elapsed time cannot distinguish them.** A 30s cull and a permanent hang look identical at t=30s. This
 is exactly the trap already recorded as [[a-hopeless-serve-looks-exactly-like-a-slow-one]] — 1087
  decode-starts against 2 decode-dones, invisible to every rate reading — and
   [[a-throttle-bounds-frequency-not-duration]].

**The distinguisher is monotonic progress**: some counter that must climb if the thing is alive.
 Not "how long has it been", but "has *anything* advanced since I last looked". Every check in this doc
  must be phrased that way or it will produce false reloads.

---

## 3. The substrate — `w.c.beat_split`, and the reading that was hiding in it

`Swarm_share_beat` writes a per-phase split (`Swarm.g`, `c399bb22e9593fb6`):

    cull → tour → flush → peers (pump, warm) → keep

**It is a PROGRESS BAR, not a cost table**, and I misread my own instrument for hours before seeing it.
 The object is zeroed at the top of each beat and each field is stamped **only when that phase
  completes**. Therefore:

- a field with a number = that phase finished, and that is its cost
- a field still at 0 = **the beat never got there**
- **all fields 0 while the skip counter climbs = wedged in phase 1**, not "the beat is fast"

That last line is the one that found the tour stall. `cull=0 tour=0 peers=0 keep=0` with `×241` reads
 like health and means the opposite. The log line now says so in words, but the real fix is that
  **something other than a human should be reading it.**

**What the split cannot see, and must be covered separately (§4b):** a *detached* verb. Since today the
 cull and tour fly detached with `cull_flying`/`tour_flying` start stamps and `cull_bg`/`tour_bg`
  durations. A detached verb that never settles leaves `flying` set forever and the beat sails past it
   looking perfectly healthy. **The detach traded a visible stall for an invisible one** — that is an
    honest trade only if something watches the latch.

---

## 4. The shape — TWO TIERS, and the first draft of this doc got it wrong

> **CORRECTION (2026-08-08), and it is the load-bearing one.** This section originally said *"a
>  `%Watch` req, not a status string"*, reasoning from [[req-is-where-state-belongs]]. **That is
>   wrong here.** A req runs in `reqy(w).do()` → the belief pass → **under the beliefs mutex**. So a
>    req-based supervisor is *queued behind the very wedge it exists to detect*. The daemon session
>     caught it and had the receipt already in hand:
>
>        "drain_why": "beliefs mutex held 8s by H:Mundo fn:swarm_share_beat"
>        "queued": ["fn:handle_inbound", "think"]
>
> `think` **is** the belief pass. §4a's check was in that queue with it. This doc worried about a
>  watchdog *causing* a wedge and never about one *being* wedged. The req idiom is right for state
>   that must persist and be seen; it is wrong for the detector itself.

**What makes escape possible:** a stuck `await` still lets timers fire — only a stuck `while(true)`
 would not — and **every wedge in §1 is await-shaped**. `Swarm_share_loop` already demonstrates the
  seam: its `setTimeout(tick, 600)` fires regardless of the mutex; only the `post_do` *inside* it
   queues. So a plain timer that never calls `post_do`, never bumps, and never writes `sc` — reading
    `.c` counters, which are plain JS objects needing no mutex — cannot be blocked by the machine it
     watches. It would have caught all three of §1.

### Tier 1 — in-tab, outside the belief loop. **LANDED 2026-08-08** (`Swarm.g`, `f0d81e693d075cd7`)

`Swarm_watch_loop(w)` — a 2s era-guarded `setTimeout` chain started beside `Swarm_share_loop`, calling
 `Swarm_watch_look` → `Swarm_beat_health` + `Swarm_detached_health`, stamping `w.c.watch` and logging
  **on transition only** (a supervisor that reprints every 2s trains people to filter it out, which is
   exactly what happened to the `⏳` skip line). Notice-only: no reload, no user-visible action.
 **Names the organ**, because every finding of that session came from phase attribution:

    👁 SoundSupervisor: tour has not completed in 94s (typical 400ms) — the beat has not advanced past this phase.

**Resolution.** Tier 1 detects and stamps `.c`. If a verdict later needs to persist or be *seen*, a req
 may carry it — but detection must never depend on that req running.

### Tier 2 — the daemon, and this is the real "above". **NOT BUILT.**

**§5's original external answer was also wrong**: it proposed a `runner_ask health` op so a session
 could ask a tab "are you wedged, and where". But a tab wedged badly enough to matter **cannot answer
  that either** — §1 row 3 is literally *"advertises, won't answer pings"*. An external tier that asks
   inherits the failure it is meant to detect. **It has to watch without asking.**

The daemon already receives exactly the signal §2 demands, with **zero cooperation from the wedged
 tab**: every peer's frames carry a monotonic per-peer `seq`.

    🛰 ws RECV ive_got seq=661 ← 65ae23ea1cdabd11
    🛰 ws RECV ive_got seq=670 ← 65ae23ea1cdabd11

**A socket that stays open while `seq` stops climbing is the §2 distinguisher.** Not `heard_at`, which
 only measures the transport — "has that peer *advanced* since I last looked". A wedged Sounditron
  keeps its websocket open; that is precisely why it looks healthy.

It became suitable only on 2026-08-08: before that afternoon the daemon restarted every 15 minutes, so
 it could not hold a judgement about anything longer-lived than that.

**THE TRAP, if this goes to the daemon:** it must **not** live in the daemon's own belief loop — the
 daemon's `Swarm_share_beat` is the thing that held the mutex for 8s. It belongs in the hand-cranked
  loop in `scripts/daemon/main.ts`, which is plain node, already ticks every pass, and already runs
   `stats()` and the heartbeat. A `peers_state()` beside `serve_state()`/`stock_state()` tracking
    per-peer `seq` deltas: no ghost edit, no compile, and in the one process that is not the one being
     watched.

**The two tiers do not subsume each other, and that is the design point:**
| tier | says | resolution | survives |
|---|---|---|---|
| in-tab `Swarm_watch_loop` | **the organ** — "wedged in `Stoker_tour` 94s (median 0.4s)" | high | only while the belief loop still turns |
| daemon `peers_state()` | **the tab** — "65ae23ea: socket open, seq flat at 670 for 94s" | low | the belief loop stopping entirely |

**This also softens §7 Q1.** The consent question only bites at the `act` rung. The daemon tier stops
 at *notice and tell* — a log line, a `/status` field, a Telegram — without touching a player at all.
  Most of the value of "discern", without deciding whether a surprise silence is acceptable.

**4a. Beat progress.** Stamp `w.c.phase_at = {phase, at}` whenever the furthest-reached phase advances.
 Then the check is pure:

- `furthest phase` unchanged for `> K × rolling_median(that phase's own duration)` ⇒ **stuck at `phase`**
- **Per-phase, self-calibrated.** A fixed constant is wrong by construction: `keep` and `cull` differ by
   three orders of magnitude. The median must be learned per phase per session — and note
    [[learns-over-time-on-c-never-does]]: on `.c` it resets each reload, which here is *correct* (a
     fresh tab should re-learn), but say so rather than letting someone later "fix" it into a snap.

**4b. Detached-verb liveness.** `flying` set with no settle for `> K × rolling_median(bg)` ⇒ **stuck in a
 detached verb**, named. This is the failure mode §3 warns the detaches introduced.

**4c. The drive.** A Story run whose `phase` has not advanced and whose `n` has not climbed. The healthy
 start signature is known and recorded: a *second* `story_analysis` followed by `⏭ schedule
  driving=true` + `▶ Story: drive started`. Its absence is the tell ([[svelte-hmr-wedges-a-book-drive]]).

**4d. The socket.** Advertising but not answering — the runner case. Already partly visible through the
 Brink badges (`Cluster_spec` §3.3); this should read them rather than mint a second opinion.

---

## 5. What it says — attribution before action

**A supervisor that says "something is wrong, reload" is worse than nothing.** It hides the bug, and it
 spends the one thing today proved valuable: *which phase*. Every finding of this session came from
  phase attribution, not from knowing that a stall existed.

So the verdict must always name the organ: **"beat wedged in `Stoker_tour` for 94s (median 0.4s)"**.
 That sentence is simultaneously the user-facing badge, the log line, and the bug report — and it is
  what would have replaced today's entire console-paste loop.

Two consumers, same req:
- **In-tab** — the Brink badge / `DiagFace`. What a real user gets, and it must be reassuring rather
   than alarming: a `slow` verdict is *information*, only `stuck` is a problem.
- **External** — a `runner_ask` op (`health`), so a session can ask a tab "are you wedged, and where"
   without a human transcribing a console. This is the one that changes how the next session works.

---

## 6. The give-up ladder — the human's actual ask, and the last thing to build

    notice → badge → offer → act

- **notice**: the req holds `stuck` + the named phase. Nothing visible.
- **badge**: the Brink says it, with the organ named.
- **offer**: "this tab is wedged in X — reload?" A button. **The human's word was "discern", and a
   discerned verdict handed to a person is already most of the value.**
- **act**: automatic reload. Only for cases proven repeatedly, only where a reload is known to fix it,
   and never while a Book run or a heist is mid-flight — a reload there destroys exactly the state
    someone is trying to diagnose.

**Anti-goal, stated because it is the tempting shortcut:** do not "fix" a wedge by widening the 600ms
 skip threshold or by lengthening a timeout. That converts a loud stall into a quiet one. The skip
  counter is a *symptom readout* and must stay honest.

---

## 7. Open questions for the human

1. **Where does consent sit?** Auto-reload a wedged *player* tab silently, or always ask? (A player is
    someone listening to music; a surprise reload is a surprise silence.)
2. **Does the supervisor live in its own ghost, or on Diag?** `Diag_trouble` already does adjacent work
    and a second opinion-holder risks the two disagreeing.
3. **Should a wedge be loud in the snap?** A `%Watch` verdict that snaps would make wedges visible to
    Books — which is either exactly right (MusuNeGrind could assert on it) or fixture churn. My lean:
     the *verdict* snaps, the timings do not (a raw `ms` in `sc` makes a Book unrecordable).

---

## 8. WHO decides, and the answer the owner handed us: it depends on who is watching (2026-08-09)

> *"the Supervisor, who decides Sounditron has failed and to reload the page to try again (or are
>  things recoverable? Story isn't, it wants to read one linear journey straight in there with
>   everything working immediately|normally)"*

That parenthesis is the answer to **§7 Q1** (*"where does consent sit?"*), which had been sitting open
 because it was being asked as one question. It is two, and they split on **who is in front of the
  tab**:

| the tab | recoverable? | who consents | the act |
|---|---|---|---|
| a **runner** (`?B=<Book>`) | **no, and never was** | nobody — no human is watching | reload, unasked |
| a **player** / Sounditron | often | the listener | notice → badge → **offer** (§6), never a surprise |

**Why a runner is categorically non-recoverable, in the owner's own terms.** A Book is *one linear
 journey read straight through, with everything working normally*. Its verdict is a `dige` chain over
  a world that quiesced a particular way (`a-books-length-is-its-recorded-toc`,
   `a-caveat-green-is-a-fixture-mismatch`). So a runner that wedged and then *healed* is **worse than
    one that stayed wedged**: it produces a run whose steps are green but whose world took a detour,
     and every fixture downstream of the stall is a lie about a journey nobody made. There is no
      "resume" for a Book — there is a fresh boot or there is nothing. Every §1 runner wedge was in
       fact cured by exactly one act, a human hitting F5.

This makes the **runner the right first customer for the `act` rung**, and it inverts the order §6
 implies. §6 says `act` is the last thing to build because a wrong reload destroys evidence and trains
  reflexive reloading — both true **of a player**. Of a runner, neither is: the evidence a wedged
   runner holds is worth less than the run it is failing to produce, and there is no one there to
    train. So:

- **A wedged runner may reload itself**, and the two guards §6 asks for are already available:
   `running.book` says whether a Book is mid-flight, and the run is deterministic, so re-running it
    from the top costs only time.
- **The one thing it must do first is SAY SO** — stamp the verdict where `runner_ask` can read it
   *after* the reload (the tab that reloads forgets; the session driving it must not). Otherwise a
    self-reloading runner is a runner that silently retries, which is how a real bug becomes a flaky
     Book. See `controlled-revert-to-attribute-a-red-book`.
- **A player tab never auto-reloads on this rung.** A surprise reload is a surprise silence, and
   §5's badge — the organ named — is most of the value without spending anyone's music.

**But note the trap this walks into, and §4's correction is the receipt.** The obvious place to hang
 "is this runner wedged" is the Story drive itself (§4c), and the Story drive is *in* the belief loop —
  the very thing that stops. A runner supervisor has to ride the same escape hatch tier 1 uses: a plain
   `setTimeout` reading `.c` counters, outside `post_do`, outside the mutex. `Swarm_watch_loop` already
    is that loop; §4c's drive check wants to be a second reading inside it, not a new machine.

**Order this suggests** (it does not replace §0, it aims it):
1. §0 step 1's outstanding debt is still first: **nobody has seen tier 1 fire.** Provoke it or replay
    the `Stoker_tour` wedge from the fixtures. An unfired watchdog is a claim, not a supervisor —
     `mutation-test-every-claim`.
2. Add **§4c (the drive)** to `Swarm_watch_look`'s reading, since the runner is now the first customer
    and the drive is what wedges on it.
3. Surface `w.c.watch` in the glass (§5, the Brink/DiagFace badge) and through `runner_ask`, so the
    verdict is legible before anything acts on it.
4. **Only then** the runner-only `act` rung, with the "say so durably first" rule above.

---

## 9. Keep Vyto NORMAL — the glass is a visible player (2026-08-09, first customer LANDED)

> The owner, same day: *"this might be a good time to think about how the Supervisor_todo is going
>  to be able to help Vyto objectively over time. certainly if there's no %Radio:4"* … *"pop into
>   Supervisor whatever we need to do to keep Vyto normal, which is a visible player"* … *"it seems
>    like a SUpervisory list of things to see happened, but also like a phase of development
>     reporting what it got done."*

Everything above watches for STUCK — a machine that stopped moving. Vyto adds the second species of
 abnormal, and it is the one a **visible player** suffers most: the machine is running perfectly and
  the RESULT is wrong. The Radio cell off the side of the screen. A grappled %Radio with no cell at
   all ("it's vanished again"). A crushed Door reduced to a floating glyph. No wedge, no mutex, every
    verb returning — and a user looking at a broken player. Liveness checks can never catch this;
     only **normalcy claims** can: objective statements about what the glass must LOOK like, checked
      against the model, with a cure attached.

### 9.1 What landed — `Vyto_normal(w)` (Vyto.g, rides `Vyto_settle`)

Runs at every settle — the world just stopped moving, so "is anything missing or off screen" is a
 fair question there and only there (mid-flight it is noise). Two claims, each with its cure:

- **PRESENCE** — every grapple the commission holds has a live (non-departing) mirror row. Missing ⇒
   one `see` row naming the mainkey (`⚕ Vyto normal: grappled %Radio has no cell — poking a rescan`)
    + one stir. ONCE per offence — the grapple watch re-stirs by itself when the organ actually
     changes, and a poke per settle would stir→settle→stir forever (the §6 anti-goal, applied to
      ourselves). The latch clears when the organ returns, so a second vanishing is said again.
- **VISIBILITY** — every unstaged, unfolded, unloose body's centre inside the frame. Off ⇒ drop its
   seed and stir (the newcomer law re-enters it at the rim and the relax pulls it into the pile).
    At most 2 pokes per cell, then ONE see row (`sits off screen and two pokes did not cure it`).
     The STAGED cell is exempt — off the edges is its whole job.

Gated on `w.c.vw_frame`, which only a humdinger tab ever stamps — a driven Book world is
 unreachable by construction, so every recorded fixture stands to the byte.

**Note the deliberate §4 exception:** Vyto_normal lives INSIDE the belief loop (it rides the settle,
 which rides a `clear()`), where §4 forbade the wedge-detector to live. That is correct here because
  it watches the LAYOUT, not the loop — if the belief loop wedges, the glass never settles and this
   never runs, and that pathology belongs to tier 1/2, which already exist for it. A normalcy claim
    only makes sense over a world that is still turning.

### 9.2 The arc — the normalcy ROSTER, and the owner's "phase of development" reading

The owner saw two things in one shape, and both are right:

- **"a Supervisory list of things to see happened"** — the claims should accumulate the way a Book's
   `%see` assertions do: each new invariant the glass earns (organs present · bodies on screen ·
    nothing renders un-bodied — "everything should be a cell or a sub-cell or a label. we need
     consistency" · a faced cell is never priced below its measured box · the staged cell alone may
      overflow) becomes one more line the settle checks forever. The roster IS the definition of
       "normal", and it only ever grows.
- **"a phase of development reporting what it got done"** — the `⚕` see rows double as a ledger: a
   session's normalcy violations are its work-list, and a quiet settle is the report that the phase
    landed. Future rung: surface the roster + its current verdicts in the glass itself (one sanity
     cell — the owner has already asked for "some overall sanity checking thing" while hiding the
      rest of the chrome), and through `runner_ask`, so a session reads the glass's own opinion of
       itself instead of asking a human what it looks like.

Known holes the roster does not cover yet: crowd-out (a row the cut refused a seat — render-side
 fact, model-blind; Vytui counts it in the corner note and the pearl gives crushed cells a body, but
  no claim FAILS on it), and the pre-%Radio boot race (the glass can commission before the organ
   exists — said now, but the honest fix is Radio_todo §0 2026-08-09's boot cells).

---

## 10. Three threads the owner handed over (2026-08-09) — sound, assertions, traffickers

> *"it'd be interested in Assertions, and really maturing the representation of peers joining and
>  being traffickers of stuff to you. also the Radio should be making sound! that's another thing we
>   can measure to see if it's overall working, and skipping to next track is usually what to do
>    about it."*

Three rungs of very different cost. One is nearly built, one is a wording problem, one is a **ruling
 the owner has to make** and cannot be coded around.

### 10.1 The radio must be MAKING SOUND — the third species of abnormal

§9 named two species: STUCK (a machine that stopped) and WRONG-LOOKING (a machine running perfectly
 with a broken result). Audio is the third and the most honest of all, because it is the actual
  product: **the app either makes noise or it does not, and nothing else is a proxy for it.**

**The meter already exists and already works muted.** `Audiolet.tap()`
 (`src/lib/p2p/ftp/Audio.svelte.ts:161`) hangs an AnalyserNode off `gainNode`, which sits UPSTREAM of
  the `gainNode2` that `mute()` zeroes. That is deliberate and the file says so at `:175` — *"the
   analyser taps gainNode (upstream), so zeroing gainNode would silence the tap and a muted
    measurement would read 0 — every analyser-based witness would break."* `sample()` returns real
     time-domain PCM. **So a muted runner can witness sound.** The rig was built for exactly this.

Its users were `Sound.g:254` (the synthetic stream rig) and `Musuation.g:1212/2395/2398` (Books). The
 live radio never tapped at all.

**The plumbing is already proven on a real runner.** `runner_ask probe` → `Lies_audio_probe()`
 (`LiesFunk.svelte:2403`) is a capability one-shot that plays a tone and reads the analyser back;
  on a live runner 2026-08-09 it returned `{state:'running', realtime:1, rms:0.709, heard:1,
   sampleRate:48000}`. That is not the radio — it is a test tone — but it settles the question of
    whether an analyser reading survives the trip out to a runner tab and back. It does. So
     `Radio_sound` is reading through a path already known to work, and a `runner_ask` verb exposing
      it is a small follow-on rather than new plumbing.

**LANDED 2026-08-09 — `Radio_sound(radio)`** (`Radio.g`, end of the controls region,
 `e0753311c0537b18`). A **pure read**, exactly the shape `Swarm_beat_health` set: returns
  `{verdict:'sound'|'dry'|'deaf'|'starved'|'quiet', rms, ac, state}` and changes nothing. No cure, no
   skip — §0's ladder forbids acting before a reading has been seen to fire.

Two things it gets right that a naive version would not:

- **The analyser is PER-AUDIOLET, and a skip replaces `radio.c.aud` wholesale** (`Radio_skip` →
   `new_audiolet()`, `Radio.g:212`). So `tap()` is called on every read rather than once at setup —
    it is idempotent per Audiolet, so it re-arms itself for free after every skip. Tapping once at
     startup would silently read a dead analyser from the first skip onward.
- **It is instantaneous by design.** One 2048-sample frame is ~43ms at 48k, so a single `dry` means
   nothing — an inter-track gap or a quiet passage reads dry and is perfectly healthy. Accumulating N
    consecutive `dry` reads before believing it is the CALLER's job, and that caller does not exist
     yet. **Nobody has seen this fire** — same standing as `Swarm_beat_health` at §0 step 1, and it
      earns trust the same way: provoke a dry timeline on purpose ([[mutation-test-every-claim]]).

**Then the design, which is all in telling two silences apart:**

| what is wrong | how it reads | the cure | if you get it wrong |
|---|---|---|---|
| **dry timeline** — `sc.Radio === 'playing'`, AC running, RMS ≈ 0 across N settles | the machine believes it is playing and no sound is being made | `Radio_skip(radio)` (`Radio.g:176` — blends, does not cut). The owner's *"skipping to next track is usually what to do about it"* | — |
| **AC never resumed** — no user gesture, `AC.state === 'suspended'` | RMS ≈ 0 for a completely different reason | a tap-to-unmute gate. **Never a skip** | skipping loops forever — every track is silent, so the supervisor burns the whole queue |
| **starved** — `sc.Radio === 'starved'` | no bytes to play | **none — do not fire.** `Radio.g:434-459` already owns this: it states itself starved, grants 6s grace, splices | you fight a machine that is already saying the true thing |

So the claim's first read is `AC.state`, not the RMS. Silence is not a diagnosis; it is a symptom with
 three causes and only one of them is skippable. §6's anti-goal applies at full force here — a skip
  fired on a bad guess destroys the evidence of the bug it mis-diagnosed.

### 10.2 Assertions — and the wall the roster hits

§9.2 wants the roster to grow the way a Book's `%see` claims do. There is a wall in the way, and it
 is worth stating before someone spends a day on it.

**A `%see` assertion is a claim over the SNAP.** `radio.sc.Radio` snaps. `radio.c.end`,
 `AC.currentTime` and an analyser RMS **do not** — `.c` is never encoded, by the law at the top of
  CLAUDE.md. So *"the radio is making sound"* cannot be asserted directly. Two honest routes:

1. **Land the reading as `sc`** — the supervisor stamps a COARSE, quantised verdict (`sc.sound =
    'yes'|'dry'`), never a float. A raw RMS would churn the dige every run and no spayer can rescue
     it: [[spayers-cannot-stabilise-a-dige]] — forgiveness is compare-time, only encode-time munging
      changes the hash.
2. **Assert the CURE, not the reading** — `%see:'the radio went dry and skipped to the next track'`.
    An event, once-noticed, no number in it at all.

**(2) is the better one** and it is how the rest of the Books already work. It also fails safe: if
 the detector never fires, the sentence never appears, and an absent `%see` is a visible hole rather
  than a green lie.

Two properties worth noticing:

- **Audio is the first normalcy claim a Book can witness at all.** `Vyto_normal` is gated on
   `w.c.vw_frame`, which only a humdinger tab stamps — a driven Book world is unreachable by
    construction (§9). Audio is the opposite: a Book runner has a real, muted AudioContext, so it can
     genuinely hear. The roster gets a testable member for the first time.
- **[[mutation-test-every-claim]] applies before any of this is believed.** A green claim gates
   nothing until it has been SEEN to go red — so provoking a dry timeline on purpose is part of
    building it, not a follow-up.

### 10.3 Peers as traffickers — one rung is free, one is a ruling

Split this in two before touching it, because the halves cost wildly different amounts.

**Liveness — free.** Who is here now, are they moving bytes, when did they last speak. All `.c`, no
 snap byte, no Book affected. `top_House().c.xfer` already carries the numbers: Sounditron keeps the
  `%Transfer` row and `TransferFace` minted and current, and merely took the cell off the glass
   (*"stop spending a permanent cell on it"*, `Sounditron.g:296`). A trafficker view is a re-read of
    data that is already being collected — and it is a much better use of that row than an idle HUD.

**History — collides, and needs the owner.** *"they gave me these 12 tracks"* is **provenance**, and
 provenance is forbidden by standing law: `Heist.g:12` — *"PROVENANCE IS NOT PERSISTED — dedup is by
  CATALOG identity (artist+title), never by source; the newlyadded log never names where music came
   from"*. It is not just a comment: it is **enforced** (`Heistation.g:459`) and **asserted in a
    recorded fixture** (`Heistation.g:635`, `%see:'newlyadded logs each arrival with a fresh feeling
     — and never a word about the source'`). Persisting a trafficker's history turns MusuHeist red
      on purpose.

So the question is narrow, and it is the owner's alone:

> **Is the ban on provenance a privacy property, or an implementation convenience?**

- **Privacy** ⇒ the trafficker view can only ever show LIVE traffic. No ledger, ever. `Heistation.g`
   stands as written and this rung is finished the day 10.3's liveness half lands.
- **Convenience** ⇒ `Heistation.g:635` gets rewritten, and sources become nameable.

**And that is the same question as the What Heisted ledger** (`Heist_todo.md` — a finished `%Caper`
 graduating into `%Haul` instead of being flattened away). Both features are blocked on one ruling.
  Answer it once and two things unblock; answer it wrong and a privacy property is quietly deleted by
   a feature nobody framed as a privacy decision. **Do not infer it from the fact that a ledger would
    be useful.**
