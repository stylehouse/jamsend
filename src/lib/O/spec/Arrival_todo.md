# Arrival_todo — the toplevel arrival state machine, as intelligible C structures

Started 2026-08-31. The owner, after a run of boot bugs (refuse-hangs, name asked in the wrong place,
 the OPEN-SHARE tailspin, "two clouds of state that want to unison"): *"it seems like you're missing a
  nice toplevel state machine for this that would make all these things easy and reliable to do"* +
   *"be sure to create intelligible C** structures for reality."*

This is that machine. It is NOT a new page/toplevel — it is one **arrival authority**, expressed as
 legible C particles, that every boot surface (Splash, BootGate, Butler, LinkDevice, BigSoundland)
  READS instead of each deriving its own truth from a pile of `.c` flags.

## NEXT LIVE TEST — the Crew ceremony, briefed (2026-08-31, late — read this before testing)

The owner: *"if I do a Link ceremony again, will they actually know each other as Crew? that's at least
 where I want to be next time I have to test."* **Yes — that is now the wired outcome**, and this is the
  whole brief:

**What you're testing, in one sentence:** one Link ceremony (laptop eed = soul, phone/incognito = Linkee,
 refuse-FSA is fine) should end with BOTH devices showing the family in the Door — and still showing it
  after you reload each device.

**What was missing until tonight** (why last time looked like "no work at all"): three welds, found by
 tracing, each now landed:
 1. Captain half (landed previous session): at `ferry_got` the Captain rosters both bodies, SIGNS the
     %Charter, gossips it — including over the still-standing ceremony pier to the not-yet-reloaded Cave.
 2. Cave half (landed previous session): `Swarm_charter_heard`'s sibling-absorb lands the Captain's row +
     charter onto the imported soul's own %Peering, pre-reload.
 3. **THE ONE FOUND TONIGHT: none of it survived a reload on EITHER side.** `Swarm_restash_all` carried
     piers|izzes|chainroots and NOT the own division — the family formed live and evaporated at the next
      boot, every time. The roster is now the FOURTH stash pillar (`Swarm_restash_roster` /
       `Swarm_roster_rehydrate`, settled at `ferry_got` and at sibling-absorb; the charter re-enters
        through the same signature-checked absorb a gossiped one takes).

**What you should SEE, step by step:**
 - Ceremony as before (OPEN SHARE → link → consent → emoji → done). At the Captain's console:
    `🪪 family roster — I am Captain <name>, linked to Cave <name>`.
 - At the Cave's console, BEFORE its reload: `🪪 sibling charter absorbed — my family roster now lists 2
    bodies of this soul`. ← this line is weld 2+3 working; if it's missing, the gossip never reached the
     ceremony pier — grab the console.
 - After the Cave reloads as eed_1: `🪪 roster rehydrated — 2 bodies of this soul survive the reload
    (charter era 1)`, and the **Door shows the family on both devices** (Captain badge + both rows).
     A Cave that hasn't heard its Captain yet still shows its own "CAVE <name>" badge (ungated tonight).
 - Reload the LAPTOP too — the family must still be there (that's pillar-four; before tonight this is
    exactly where it silently vanished).

**Explicitly NOT in this test:** %Owed settling (`w.c.owed_settle` stays off — it needs an offline
 friend-with-music to be worth anything; parked until a batch test), music flowing between bodies (the
  sibling reach channel — the SoundPooling arc — is the NEXT build, and lands on top of exactly this
   roster+charter ground).

## HANDOVER — THE CIRCLE FOUND (2026-08-31, evening, the two-device live session)

**Read this first; the older handover below still holds for the machine's shape.** The owner ran the real
 thing: incognito cave (refuse FSA, MyCave link) + eed the soul. Two separate diseases surfaced, one on
  each device, and the cave one is now FIXED IN THE TREE (needs the owner's live confirm):

**1. THE CAVE FIRST-BOOT SPLASH HANG WAS A LITERAL CIRCULAR WAIT.** `Swarm_link_fresh`'s offer-seizure
 held until `!top.c.butler_up`; the Butler's own ceremony-lift consulted `Swarm_link_fresh` — each waiting
  on the other, escaped only by the 120s valve. Worse, the Butler called `link_fresh(null)` while
   `Screen_decide` called `link_fresh(w)` — two computations of one truth that could disagree. And the
    reload "fix" was a road-change, not a fix: the stashed `share/mode:'thin'` made boot 2 take the thin
     path from t=0 (the owner: *"needing to refresh incogni to get it to not hang sounds like needing to
      kick in the noFSA mode before we know we need to"* — exactly right, see THE LAW below).
 **The fix (landed, compiled, gate-green):**
 - `Swarm_link_fresh` offer-hold now reads **machine facts**: `glass_wanted`/`glass_stood`, mirrored onto
    top.c by BigSoundland (the ac_wanted mirror pattern). No surface flag in the ghost's read path.
 - The Butler's ceremony-lift now READS THE AUTHORITY (`c.screen.dominant === 'ceremony'`) instead of
    recomputing it. One decision, one reader discipline — the whole point of the machine.
 - `Screen_decide` now **bumps top on a changed decision** (changed-gated, so no loop): a phase flip is
    rare and load-bearing, and a `.c` write announces nothing — surfaces only saw it by luck of unrelated
     bumps before.
 - ▦ raised ABOVE the splash (z 2.2M) and `boot_ready` lifts on `sprawl` — the owner's "show guts"
    escape hatch atop a wedged splash, real now.
 GATE: SwarmStaple 8/8, InvFerry 6/6, InvWalk 8/8, InvSeal 5/5 all ok_pct 1 caveat 0 IN CHECK MODE
  (= diges matched committed fixtures = byte-inert), PROVEN on the new code (the Credulate spool bakes
   `Ghost_S_Swarm,dige:138ea0db…` / `Ghost_Story_Sounditron,dige:7973f222…`). The 8-step Sounditron
    fleet Book is red — and its Credulation shows it was IDENTICALLY red before this diff (ok_pct 0 at
     the prior diges): environmental (it needs live peers; eed was wedged — see 2).

**2. EED (THE SOUL) HAD ITS BELIEFS MUTEX HELD 10+ MINUTES — this, not the cave, is why the ceremony
 never crossed.** The log: `⏳ Swarm_share_beat busy — QUEUED 609s behind the beliefs mutex (×1011)`.
  QUEUED-not-running = a mutex jam: some OTHER fn held the top House's beliefs mutex the whole time, so
   NOTHING drained — the incogni's `pier_hello seq=1` arrived repeatedly and was never processed (hence
    "no trace of the new incogni as a Pier of any kind" on eed), presence never warmed (hence "eed is
     offline" on the cave), and the ~180-deep `pier_accept` retransmit storm to `7f86cafc` (the OLD dead
      incogni body) ground on. The wedge DID self-report — but only into %Errlog/`drain_why` (the todo
       popover), invisible in a console paste. **Landed: the wedge now also `console.error`s once per
        episode, naming the holder** (`🧱 beliefs mutex held Ns by <who>…`). NEXT TIME IT HAPPENS: the
         console names the fn; paste that. **PRIME SUSPECT, now DEFUSED:** `Clustation_mirror_account`
          runs inside the beliefs-mutex chain (the cave's own stack trace showed it) and `Swarm_persist
           → Swarm_account_save` awaits RAW FSA writes with no timeout (wormhole ops get WH_OP_TIMEOUT;
            this path never did) — and FSA handles went bad on this rig the same evening (the editor tab
             lost its FSA live). One wedged write = the mutex held forever. **Landed: the mirror is
              timeboxed at 15s** (Auto.svelte) — on overrun it logs `🪪🧱`, leaves the mark set (no
               concurrent re-enWaft), and RELEASES the belief loop; durability stays owed, the machine
                stays alive. Other suspects if the 🧱 line names something else: a Heist/Repli await
                 against the dead old body, a Dexie transaction. FOLLOW-UP owed: bound the reliable
                  outbox to a peer that never acks (~180 buffered frames to a dead body is its own
                   disease).

**THE LAW THIS SESSION EARNED — first boot must equal second boot.** Any state that only becomes correct
 after a reload (the stashed thin choice, the re-acquired FSA handle, the re-parked offer) is a bug
  wearing persistence as a bandage. Every decision the reload "unlocks" must be reachable on boot one:
   the `#Iz` fact is in the URL at t=0 (no ghost needed), the glass facts are machine facts, the share
    default for a ceremony tab can be thin-until-decided (folder = upgrade, offered from the Door after —
     Onboarding §3/§4). Test any boot change by asking "does boot 1 take the same road as boot 2?"

## HANDOVER — FRESH EYES (2026-08-31, after a long reactive-patching session)

**Read this first.** The owner called the boot/splash work "whack-a-mole" and asked for fresh eyes — correctly.
 The arrival MACHINE (below) is solid; the SPLASH-LIFT LAYER on top of it is not, and here's the honest arc.

**Destination:** device-link onboarding + boot that Just Works, with the arrival state as legible C particles
 (`%Arrival`/`%Share`) — and the Captain/Cave "organs" teleology in `Division_todo`.

**SOLID (compiled + Book-green; humdinger-gated so SwarmStaple 8/8 stays green; likely correct):**
- **The arrival authority** — `Screen_decide` mints `%Arrival,phase,reason,%want` + `%Share,mode` under
   w:Supervisor, driven Book-INDEPENDENTLY off the Supervisor heartbeat (`Supervisor_tick`). `phase`:
    ceremony ▸ coming/arrival ▸ gaveup ▸ thin ▸ glass. This is the good bones.
- **Refuse tailspin fix** (`Housing.svelte.ts`): `listen_choice` overrides the `book` gate (BigQualand stamps
   `book` on every page, which broke the old `!book` guards). Same footgun bit §3.
- **§3 persist choice** (Housing + boot_gate): stash `share/mode:'thin'`, restore it — `!book` guard REMOVED.
- **name→Link whisk** (`InvitePanel.svelte`) + **§6 Door-first** (`Sounditron.g` surface: unnamed→Door,
   named→Link, `l_named` folded into the `link_decided` key).

**⚠ THE LANDMINE — the splash-lift layer in `BigSoundland.svelte` (`boot_ready` / `boot_share_hold`).**
 These are `$derived` booleans over SIX interacting flags — `glass_full, screen.dominant, butler_up,
  disk_gated, listen_only, ac_wanted` — PLUS the Splash's own `hold`→defer-fade logic (`Splash.svelte:63`).
   Every patch to one flips another: I fixed the device-link "splash never lifts" (added `ceremony`), then
    broke **eed** ("splash doesn't reveal") by holding on `ac_wanted` (reverted that one edit already).
     **You CANNOT verify any of this headlessly** — it's humdinger browser UX; the runner can't boot it. So
      reactive patching without the owner at a tab is doomed to whack-a-mole. That's the bomb.

**THE NEXT MOVE (the clean redesign, do WITH the owner testing):** collapse the splash-lift decision into ONE
 read of `%Arrival.phase` — the whole point of building the particle. The splash should lift iff
  `phase ∈ {glass, thin, ceremony, gaveup}` and hold on `{coming}`; the AC/folder begs ride as `%want` shown
   OVER the tree (BootGate is already z-2.1M above the splash), never by holding the fade. Kill the six-flag
    `$derived` soup in BigSoundland and read the phase. Add the owner's **"show guts" escape hatch atop the
     splash** (a robustness valve so a wedged splash is always escapable — they asked for it). THEN re-run the
      6-row test checklist (in the chat / §0 below) at a real tab, one pass, batch the fails.

**Also open:** `Division_todo` SwarmSpread beat-5 is a STALE FIXTURE not a bug (5/5 assertions sworn) —
 re-record when ready. The owner had "not even got a new Link made yet" — the actual device-link crossing
  works (SwarmStaple/snap-proven); it's the boot SURFACE around it that's been in the way.

---

## THE ARRIVAL, FROM THE USER'S CHAIR (the lovely end goal — owner asked 2026-08-31: "what sort of
##  lovely end goal do we get to?")

The destination, stated so no session re-derives it and every brick can be checked against it:

**One calm tree, from first paint to music.** The splash covers the whole boot and is NEVER interrupted —
 no "bare Supervisor glass", no machine-room flash, no second full-screen takeover. Slow boots stay calm
  under the tree; the tree yields only to the real thing (the glass with music, the listen-only landing, or
   the become-a-body ceremony), never to the plumbing.

**One button, one word: OPEN SHARE.** The single affordance of the whole pirate app. Whenever the boot wants
 a human gesture — wake audio, open a folder, or both — the SAME orange button appears in the SAME place
  over the tree with the SAME word. The user learns exactly one thing: *when the app wants something, click
   OPEN SHARE.* Sometimes that click is silent and instant (audio woke); sometimes a folder dialog opens; the
    user never has to know or care which. No second label ("▶ open sound" is gone), no "?" or cancel clutter
     on the bare-click case — the "?" and the "listen without a folder" escape appear ONLY in the folder case,
      where there is a genuine choice to explain.

**One escape, one glyph: ▦.** The machine room — the Supervisor glass, diagnostics, every House's UI — lives
 behind exactly ONE deliberate control, ▦, sitting above everything (even a wedged splash). A boot is never a
  dead tree: if you WANT the guts you can always reach them, and a genuinely hung boot (>45s, no arrival) still
   falls through to the Butler's progress/gaveup as a last-ditch. But you go to the machine room; it never comes
    to you.

**The user answers ONE question, ONCE, up front, and never gets surprised later.** Folder-or-listen-only is
 asked at OPEN SHARE and remembered (a decliner is never re-nagged; the folder is an UPGRADE offered from the
  Door later, never a mid-feature surprise picker — Onboarding §3/§4). A device-link cave becomes-a-body through
   the same calm surface, the folder question folded in, not stacked on top.

Structurally this is the RETOPLEVEL (§5d): splash + OPEN SHARE + ▦ are PLATFORM chrome mounted once at the
 root above every page, driven by the ONE arrival authority (`%Arrival.phase` + `%Share.mode` + `%want` begs).
  The pages underneath just say "which glass". Every flag a surface stops cross-reading, and every
   differently-labelled button that collapses into OPEN SHARE, is a step down that ladder.

**Checkable tells the bet is being kept:** the tree never flashes to the machine room on a slow boot; OPEN
 SHARE appears the instant a gesture is wanted (not "ages later, when ▦ shows up"); there is exactly one
  button label; boot 1 takes the same road as boot 2 (no reload-to-fix — see THE LAW in the top handover).

## 0. What to get on with next

**FIRST (owner, live): the circle-fix confirm + the eed wedge.** (a) Fresh incognito + MyCave link +
 refuse FSA, FIRST boot: the splash should now yield to the ceremony without a reload (the circle is
  broken — see the top handover). (b) On eed: reload the wedged tab; if the jam recurs the console now
   names the holder (`🧱 beliefs mutex held Ns by <who>`) — paste that line, it's the whole diagnosis.
    (c) Re-run the 8-step Sounditron fleet Book once eed is back — it was red only because eed was wedged.

**LANDED 2026-08-31 (eve, all .svelte → HMR, no compile) — the ONE OPEN SHARE button (owner's live gripe
 "eed has an AC OPENSHARE icon in a bare Supervisor glass interrupting the splash / takes ages to turn up /
  two labels annoy users"):** the label is now ALWAYS "OPEN SHARE" (▶ open sound gone); the ? / explainer /
   listen-escape show ONLY in the folder case; the `!butler_up` suppression is GONE so the button appears the
    instant a gesture is wanted (BootGate is the single visible host, z 2.1M above splash AND Butler); the
     Splash last-ditch cap is 7s → 45s so a slow-but-progressing boot no longer fades the tree into the bare
      Supervisor glass (▦ above the splash is the real escape now). See "THE ARRIVAL, FROM THE USER'S CHAIR".

**LANDED 2026-08-31 (later) — THE CEREMONY NOW AUTO-DRAGS THE TAB TO DOOR→LINK (owner: fresh incogni
 "plops into the Radio … should've been dragged into Door then Link … if I nav to Door it's ready to grab my
  name, then proceeds with Link"; same with FSA: "I have to go into Door to get it on").** ROOT: the belly
   SURFACE (`w.c.focused = Door|Link`) is set by `Sounditron_commission`, which re-runs only on the Book drive
    (STOPS when the cold resident toc completes at n=2) or a manual nav — so a ceremony that becomes
     surfaceable only AFTER the glass stands (`link_fresh` flips on `glass_stood`) never got a re-run to
      surface it; the tab committed to the Radio focus and sat. FIX (`Screen_decide`, Sounditron.g): the
       Supervisor heartbeat runs `Screen_decide` every tick (Book-independent) and already knows the ceremony
        is fresh — so when a link is in flight on a humdinger tab it now re-runs the resident glass commission
         (the `Radio_pop_glass` handles `sounditron_run`/`radio_w`), whose surface logic is latched per
          phase@named (a no-op until the phase or the name changes). Re-entrancy-guarded by `rw !== w` (the
           commission calls Screen_decide with the glass world; the heartbeat with the Supervisor world).
            GATE: SwarmStaple 8/8 + InvWalk 8/8 byte-identical on the new code (`Sounditron.go` a6cc1250) —
             inert by construction (every Screen_decide edit sits after the `!humdinger → return 0` gate).
              ⚠ needs the owner's live confirm: fresh incogni (± FSA) should now walk splash → Door(name) →
               Link(become) with NO manual nav. Reload the tab to pick up the new .go (LocalGen wrote disk;
                no editor was on the relay to HMR).

**STILL SECONDARY — the AC "OPEN SHARE" is deferred DURING a ceremony (by design).** During the Adopt the
 audio beg is suppressed (`ac_wanted && !link_active`, owner's 2026-08-29 rule "AC can wait til after this
  compulsory Adopt") — so the button "goes away until I make a gesture" is that deferral: once the ceremony
   completes, `link_active` falls and OPEN SHARE returns for the audio tap. If the owner wants audio to wake
    from a ceremony click instead, that's a keep_awake-on-ceremony-buttons change, not the auto-drag.

**STILL OPEN — the fresh-incognito boot is SLOW ("amazingly slowly … ages to go … chaos").** Not yet
 diagnosed; candidates: (1) the boot_gate poll doesn't start until BigSoundland assigns H inside an $effect
  (late), so ac_wanted/OPEN SHARE has inherent first-paint latency; (2) a fresh incognito with no Dexie/OPFS
   does real cold setup; (3) aftermath of the eed wedge (the cave was talking to a jammed soul). The 45s cap +
    always-visible OPEN SHARE make the slowness CALM (tree stays, button floats) rather than a machine-room
     dump, but the underlying "ages" wants a real look — likely a boot-cost profile, best done with the owner
      timing a real fresh-incognito boot (headless can't see this). This is where the retoplevel (§5d/§5b) pays
       off: a root-mounted splash + platform OPEN SHARE stop every page re-racing the boot.
**THEN:** the remaining §5 bricks — retire the `.c` flags (readers → `%Arrival`/`%Share`), the phase-walk
 Book, and the ceremony-tab share default (thin-until-decided, folder-as-upgrade — the first-boot law).

**Confirmed direction (owner 2026-08-31): "go straight to the state machine".** Build order below (§5).

**LANDED so far (2026-08-31, needs the owner's LIVE refuse-test to confirm):**
- **Brick 1 ✓** — `Screen_decide` mints the legible **`%Arrival,phase,reason` + `%want`** particle under
   w:Supervisor, dual-written beside `MH.c.screen`. Humdinger-gated → Book-inert. `Sounditron.go`.
- **Brick 2 b1 ✓** — the authority is DECOUPLED from the Book: `Supervisor_tick` (the 2s Book-independent
   heartbeat) now calls `this.Screen_decide(w)`, so a listen-only tab (no Book) still gets a phase. Added the
    **`thin`** phase: `arr==='none' && MH.c.listen_only → phase:thin`. BigSoundland's `boot_ready` lifts on
     `thin`, and a **listen-only landing** ("🎧 listening only — open a folder / paste a link", `reopen_share`)
      shows instead of the machine room. **This is the refuse-hang fix.** Compiled clean (`Supervisor.go`
       93125c, `Sounditron.go` 228081c), `.go` diffs localized, svelte-check clean on BigSoundland.

- **`%Share` particle ✓** — `Screen_decide` also mints **`%Share,mode:folder|held|thin|impossible`** under
   w:Supervisor, reflected from the `.c` flags. Both halves of the arrival state are now legible C structures.
    Compiled (`Sounditron.go` 229182c). (⚠ `.g` gotcha hit + fixed: `} else {` MUST be same-line — a newline
     before `else` generates unparseable JS.)
- **§3 persist the choice ✓** — `boot_gate.listen_only` stashes `share/mode:'thin'` (Dexie, survives reload);
   Housing's boot_role branch restores `listen_choice` from it (guarded `!listen_choice && !book`); `reopen_share`
    clears it to `'folder'`. A decliner is no longer re-nagged; folder users bypass the restore (local-share path
     returns first), so a stale choice can't trap anyone. svelte-check clean (Housing/boot_gate/BigSoundland).
- **`name → link` whisk ✓** (§4) — InvitePanel focuses the Link cell once named on a MyCave landing.

**NEXT (all need the owner's LIVE eyes — not safe to build blind while away):** brick 2 **b2** (stand a
 Book-less glass world → a real empty glass, replacing the thin landing), **retire the `.c` flags** (switch every
  reader to `%Arrival`/`%Share`, then delete `.c.screen`/disk_gated/listen_*), and a **Book** asserting the phase
   walk (forces humdinger, calls Screen_decide, swears `%Arrival.phase`/`%Share.mode`). See §5 build order.

## 1. WHY — the fragmentation we're replacing

Today "am I arrived?" is answered in several disagreeing places:
- `Screen_decide` (Sounditron.g:1148) writes **`MH.c.screen = {dominant, reason, wants, yields_to}`** — a
   `.c` OBJECT. Ranked ladder `ceremony ▸ arrival ▸ gaveup ▸ glass`. Right idea, wrong home: invisible to
    the snap, the mesh, Cyto, `/c`, and every Book fixture. **This is the anti-pattern the owner named.**
- BigSoundland derives its OWN `boot_ready = glass_full && !butler_up` (V/BigSoundland.svelte:226) —
   a SECOND authority that doesn't even read `c.screen` (only peeks `screen.dominant==='gaveup'`).
- The share decision is **three `.c` bools** — `disk_gated`, `listen_choice`, `listen_only` (+ `no_fsa`
   capability + `ac_wanted` beg) — set/cleared across Housing and boot_gate, forgotten on reload.
- `butler_up`, `account_mirror_owed` — more `.c` bools the surfaces cross-read.

The symptoms are all one disease — no single legible authority:
- **refuse-hang**: refuse FSA → listen-only → no Book → no glass commissions → `glass_full` never true →
   splash has nothing to reveal → hangs. (There is no phase that says "arrived THIN".)
- **name in the wrong place**: the Link cell still solicits a name because nothing sequences name-before-link.
- **the tailspin** (fixed 2026-08-31 in Housing): `disk_gated` re-raised each tick because the choice
   wasn't a durable, honored state.
- **"two clouds that want to unison"** (the ferry): two ends each guessing at `.c` flags.

## 2. THE C STRUCTURES (the whole point)

**WHERE THEY LIVE — the crux.** Particles live under a **WORLD**, not on the House `.c`. `%Watch,arrival`
 and `%Pref` already live under the **Supervisor world** (`A:Supervisor → w:Supervisor`), snapped and
  mesh-visible; `Screen_decide`/`Supervisor` are the ghosts that HOLD that world and mint into it. That is
   exactly why the boot flags cheated onto `MH.c.*` — `.c` is the easy cross-cutting spot reachable from
    Housing/boot_gate/any face, but it is the INVISIBLE one. **The machine's job is to do that plumbing
     ONCE, in the ghost that owns the world**, so `%Arrival`/`%Share` are minted there and every surface
      just READS them. Housing/boot_gate keep setting the raw `.c` INPUTS (disk_gated, ac_wanted, the picker
       probe) only until §5 brick 1 migrates them; the authority reflects those inputs into the particle
        meanwhile. Legible, snappable, Book-assertable. Renameable coinage.

### `%Arrival` — the one toplevel phase authority (replaces `MH.c.screen`)
```
/Arrival,phase:<P>,reason:'…'/          ← one row under MH, merged-in-place (never replace()-churned)
   %want:open-share                      ← child rows: attention-BEGS the dominant surface SERVICES
   %want:…                                 (open-share = a folder/audio tap wanting a home, not seizing)
```
`phase` (the old `dominant`, now a legible scalar), highest-rank first:
- `ceremony`  — a FRESH device-link is in flight (`Swarm_link_fresh`). Yields to nothing.
- `coming`    — still starting up; a declared `%Watch,arrival` is unmet & inside patience. (splash holds)
- `gaveup`    — a declared arrival expired (no fault; show the registrar's advice).
- `thin`      — **NEW.** Listen-only has SETTLED: no library/Book, but this IS a complete arrival. The
                 splash lifts to an honest listen-only landing (not the machine room). The fix for refuse-hang.
- `glass`     — the app is up (a commissioned glass). The steady state.

`%Arrival` is written by `Screen_decide` (rewired to mint the particle instead of the `.c` object) and
 read by everyone. `yields_to` need not be stored — it's `phase==='ceremony' ? [] : ['ceremony']`, a pure
  function of phase; keep it derived, not a field (state vs ref discipline).

### `%Share` — the storage decision (replaces disk_gated + listen_choice + listen_only + no_fsa)
```
/Share,mode:<M>/                         ← one row under MH, particle+STASH (survives reload — §3 of Onboarding)
```
`mode`:
- `folder`     — a folder is WANTED and not yet open (today's `disk_gated`). The gate is up as a `%want`.
- `held`       — a folder is open (granted). (today: disk_gated cleared by a real share)
- `thin`       — listen-only, by CHOICE (today's `listen_choice`/`listen_only`). Drives `Arrival:thin`.
- `impossible` — no picker in this browser (today's `no_fsa`); listen-only by construction. Also → `thin` arrival.

Persist `mode` via the **`Supervisor_pref` stash pattern** (particle + `H.stashed`, minted-from-stash at
 boot) so a decliner is never re-nagged and a granter re-acquires silently. `off costs no row` — an
  undecided boot mints nothing and `folder` is the honest default gate.

### Kept as-is (already good C structures)
- **`%Watch,arrival`** (Supervisor) — declared arrivals + `met`/`deadline`. `Supervisor_arrived` reads them
   → none|coming|gaveup|arrived. This is ALREADY particle-driven; the `thin` phase just adds a fourth road
    (a listen-only settle DECLARES a thin arrival that is met the moment the pool mounts).
- **`req:Ferry`** — the ceremony is already a legible req; `Arrival:ceremony` just reflects it.

### Migration map (the flags that die)
| today (`.c` flag / object) | becomes |
|---|---|
| `MH.c.screen = {dominant,…}` | `%Arrival,phase,reason` + `%want` children |
| `disk_gated` | `%Share,mode:folder` (+ an `%Arrival` `%want:open-share`) |
| `ac_wanted` | an `%Arrival` `%want:open-share` (audio half) |
| `listen_choice` / `listen_only` | `%Share,mode:thin` |
| `no_fsa` (capability) | `%Share,mode:impossible` (probed once at boot) |
| `butler_up` | derive from `%Arrival` (`phase` in coming/… ) or keep as a Butler-local ref |
| `account_mirror_owed` | a legible `%Arrival` sub-fact or an owed `%Watch` |

## 3. WHAT READS IT (the surfaces, after)

- **Splash** (`boot_ready`) ← `%Arrival.phase ∈ {glass, thin, gaveup}` lifts; `{ceremony, coming}` holds.
   The refuse-hang dies here: `thin` is a lift.
- **BootGate** ← `%Arrival` `%want:open-share` decides whether to show OPEN SHARE / ▶ open sound; the
   button writes `%Share,mode`.
- **Butler** ← `%Arrival.phase` (no separate `butler_up` cross-read).
- **LinkDevice / the whisk** ← when `%Share,mode` is decided (named) and a ferry offer is pending,
   `Arrival` sequences `name → link` and Sounditron_focus('Link') fires (see §4).
- **BigSoundland** ← drops its own `glass_full`/`boot_share_hold` derivations; reads `%Arrival`.
- The **listen-only landing** (new small face) ← shown on `phase:thin`: "listening only — no library yet ·
   open a folder / paste a link", reusing `boot_gate.open_share`. NOT the machine room.

## 4. THE `name → link` WHISK (folds in — owner's live gripe) — ✓ LANDED 2026-08-31

**Done (.svelte-only, svelte-check clean, needs live confirm):** `InvitePanel.svelte` now fires a once-only
 `$effect` that calls `H.Sounditron_link_open()` (self-resolving world, the SAME verb the Door's "link a
  device" button uses) the moment a **MyCave** link has landed AND the self is **named** AND the run stood.
   So the card's old "opening in the Link panel" PROMISE (which leaned on a ghost-side auto-surface that
    didn't fire after the name-gate) becomes a real whisk. Idempotent with any auto-surface (both focus the
     same %Link cell). Still owed: drop the Link cell's own inline name input (Onboarding §6) now the name
      is guaranteed set before the cell shows.

Original design note (still the model):

Owner 2026-08-31: naming at the Door works (nice form), but it "leads to the usual Door" with the text
 *"device link from eed… — opening in the Link panel — you can become them there"* and does **not** whisk
  to the Link. In the machine this is just a phase transition: once `%Share`/identity has a **name** AND a
   ferry offer is pending (`Swarm_ferry_facts` has an offer / `ferry_awaiting`), `%Arrival` advances to
    `ceremony` and the authority calls `Sounditron_focus('Link')` — the same nav seam `Sounditron_link_open`
     already uses. So the Door's "opening in the Link panel" line becomes true: the machine performs the whisk
      instead of printing a promise. Then drop the Link cell's own inline name input (Onboarding §6).

## 5. BUILD ORDER (each brick compiles + keeps Books green + verifies live)

1. **`%Share` particle + stash** (Supervisor-style) — write it where the three `.c` flags are set today
    (Housing listen-only branch, `boot_gate.listen_only`, the no_fsa probe). DUAL-WRITE the old `.c` flags
     for one step so nothing downstream breaks yet. Persist `mode` across reload (fixes Onboarding §3 too).
2. **`thin` arrival** — a listen-only settle DECLARES a thin `%Watch,arrival` that is met when the OPFS pool
    mounts; `Supervisor_arrived` returns `arrived`, `Screen_decide` → `phase:thin`. **Fixes the refuse-hang.**
3. **`%Arrival` particle** — rewire `Screen_decide` to mint `/Arrival,phase,reason/ + %want` instead of the
    `.c.screen` object; point Splash/Butler/BigSoundland at it; delete the parallel `glass_full` authority.
4. **The listen-only landing face** — shown on `phase:thin`; open-a-folder / paste-a-link, no machine room.
5. **`name → link` whisk** (§4) + drop the Link inline name input (Onboarding §6).
6. **Retire the `.c` flags** — once every reader is on the particles, delete `disk_gated`/`listen_choice`/
    `listen_only`/`c.screen`/`account_mirror_owed` dual-writes. Grep-clean.
7. **A Book** — `Arrival` (or extend a boot Book): assert the phase walk booting→share→thin and
    booting→…→glass, and name→ceremony. Fixtured on the live runner = the regression gate.

## 5b. WE'RE FREE TO ABANDON BigQualand's BOOT (owner 2026-08-31)

Owner: *"I don't care if we abandon BigQualand even, we escaped Vyto pretty well — perhaps we just keep
 going?"* So this is NOT a careful retrofit of the existing boot; we may REPLACE the parts that fight us.
  Two things BigQualand does that caused live bugs and are fair game to cut:
- **`book = boot_param('B') || 'Sounditron'` stamped on every page** — the default `book` is what made
   `!book` false for every real listener (the refuse tailspin) and it conflates "a dev `?B=` run needs the
    real tree" with "an end-user page has a resident Book". The arrival authority should decide the glass
     from the MACHINE (humdinger), not from a `book` string.
- **`boot_ready = glass_full && !butler_up`** — the SECOND authority. Delete it; read `%Arrival`.

**The upgrade this unlocks: listen-only gets a REAL (empty) glass, not a `thin` dead-end.** The glass is
 already commissioned by `Sounditron_glass`, which the humdinger fallback (Sounditron.g:70, `n==null &&
  humdinger`) runs WITHOUT a beat — the only thing missing in listen-only is that no world is stood for it
   (no Book loaded → no `A:Story/Sounditron` world → the drive never pumps). If the **arrival authority
    stands a bare glass world itself** (the "escaped Vyto" move — decouple the glass from the Book drive),
     a listen-only tab commissions Vyto with an EMPTY pool: the real app, no library yet, a Radio you can
      point at a folder or a paste-link. That is Onboarding §3's "listen-only is a COMPLETE life" made true.
       So `phase:thin` becomes either (a) unnecessary — listen-only just reaches `phase:glass` empty — or
        (b) a brief honest interim while the empty glass stands. **Preferred: aim for a real empty glass;**
         keep `thin` only as the fallback if standing a Book-less glass world proves deep. Decide at brick 2.

## 5c. THE LOAD-BEARING FINDING (brick 1 uncovered it) — the authority is BOOK-DOWNSTREAM

`Screen_decide` lives in **Sounditron.g** and is called from the **Sounditron Book's drive**
 (Sounditron.g:481). So the WHOLE toplevel arrival authority only runs when the Sounditron Book is loaded.
  In listen-only there is NO Book (no wormhole) → the drive never pumps → `Screen_decide` is never called →
   no `%Arrival`, no phase, and nothing to lift the splash. **This is the real root of the refuse-hang** —
    deeper than "no glass": the arrival AUTHORITY itself is downstream of the Book.

So brick 2 is a DECOUPLING, and there are two clean ways (decide live):
- **(b1) Drive the authority from w:Supervisor's OWN Mundo tick.** `w:Supervisor` stands on Mundo at boot
   (Supervisor.g:13, `Supervisor_up`) and ticks INDEPENDENT of any Book (Sounditron.g:2376 notes its "own
    tick on Mundo"). Move/also-call the arrival decision from there so it runs with or without a Book. Then
     listen-only gets a real phase (`thin`), the splash lifts to the listen-only landing. Smallest change.
- **(b2) Stand a Book-less glass world (the "escaped Vyto" move).** Have the authority stand a bare
   `A:Vyto→w:Vyto` and run `Sounditron_glass` on it (the humdinger `n==null` fallback already commissions
    without a beat) so listen-only reaches a REAL empty glass (`phase:glass`, empty Radio). Best UX, deeper.

Recommend **b1 first** (cheap, unblocks the hang via `thin` + a landing face), then **b2** as the upgrade
 to a real empty glass. Both need the `%Arrival` phase logic to gain `thin` and read the `%Share` decision.

## 5d. THE RETOPLEVEL — the meaning, captured (owner 2026-08-31: "that's probably a lot though…
##      damn, we need to capture the meaning somewhere… but make it available")

**Decision: NOT now.** The owner's lean is right — it's a lot, and the phase-authority work is the
 ladder to it, not a detour from it. But the destination deserves stating once, so no session
  re-derives it:

**The meaning:** BigQualand and Auto are today PAGE plumbing — each Big*land re-hosts the boot (book
 stamping, identity-by-role, splash-in-the-page, gate wiring) as if arrival were a page concern. The
  retoplevel says arrival is a PLATFORM concern: ONE toplevel arrival surface that owns splash + gates +
   phase for every page, with the pages underneath reduced to "which glass to stand". Concretely:
- **The splash mounts at the ROOT above all toplevels** (Splash.svelte's own NOTE already says this),
   not inside BigSoundland — so every boot path is covered and OPEN SHARE punches through by design.
- **`book = boot_param('B') || 'Sounditron'` dies** (§5b) — the arrival authority decides the glass from
   machine facts (humdinger), not a string stamped on every page; `?B=` stays the explicit dev ask.
- **Auto's role-identity + account-mirror become platform services** the arrival machine sequences,
   instead of per-page wiring racing the boot.
- **Listen-only stands a REAL empty glass** (§5b b2 — the "escaped Vyto" move): the glass decouples from
   the Book drive, so `thin` dissolves into `glass` with an empty pool.
**Why the current work is the ladder:** every brick that moves a surface from cross-read flags to
 READING `%Arrival`/`%Share` shrinks the retoplevel to a relocation — once nothing derives its own
  boot-truth, hoisting the one authority (and the splash) above the pages is mechanical. Do not start
   the hoist until the flag-retirement brick (§5 item 6) is done.

## 6. LAWS TO HOLD (so this doesn't become a 7th mirror)
- **State → particle; ref → `.c`.** `%Arrival`/`%Share` are state (SEE them). World refs, DOM handles, the
   poll counters, `req.c.secret` stay `.c`. (Onboarding §A.)
- **Snapped boolean = 1 or ABSENT.** `mode`/`phase` are scalars, not bools; a `%want` row is presence.
- **Merged-in-place, never replace()-churned** (the Vytui childless-window class) and never one-row-per-state.
- **Humdinger-gated + Book-inert** where the old flags were — a runner/Book must see no new furniture unless
   the Book is about arrival. `Screen_decide` already self-gates on humdinger; keep that.
- **Unknown-is-first-class**: `none`/`coming` must never read as "will never arrive" (Supervisor_arrived's
   own dial-rule-2 warning — got wrong three times already).
