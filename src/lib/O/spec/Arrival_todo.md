# Arrival_todo — the toplevel arrival state machine, as intelligible C structures

Started 2026-08-31. The owner, after a run of boot bugs (refuse-hangs, name asked in the wrong place,
 the OPEN-SHARE tailspin, "two clouds of state that want to unison"): *"it seems like you're missing a
  nice toplevel state machine for this that would make all these things easy and reliable to do"* +
   *"be sure to create intelligible C** structures for reality."*

This is that machine. It is NOT a new page/toplevel — it is one **arrival authority**, expressed as
 legible C particles, that every boot surface (Splash, BootGate, Butler, LinkDevice, BigSoundland)
  READS instead of each deriving its own truth from a pile of `.c` flags.

## 0. What to get on with next

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

## 6. LAWS TO HOLD (so this doesn't become a 7th mirror)
- **State → particle; ref → `.c`.** `%Arrival`/`%Share` are state (SEE them). World refs, DOM handles, the
   poll counters, `req.c.secret` stay `.c`. (Onboarding §A.)
- **Snapped boolean = 1 or ABSENT.** `mode`/`phase` are scalars, not bools; a `%want` row is presence.
- **Merged-in-place, never replace()-churned** (the Vytui childless-window class) and never one-row-per-state.
- **Humdinger-gated + Book-inert** where the old flags were — a runner/Book must see no new furniture unless
   the Book is about arrival. `Screen_decide` already self-gates on humdinger; keep that.
- **Unknown-is-first-class**: `none`/`coming` must never read as "will never arrive" (Supervisor_arrived's
   own dial-rule-2 warning — got wrong three times already).
