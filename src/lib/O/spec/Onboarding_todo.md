# Onboarding_todo — OPEN SHARE, the folder question, identity, and naming

The boot→share→name→(link) arc. Consolidated 2026-08-31 during the device-ferry live-testing session,
 as the ferry finally walked end-to-end (splash → OPEN SHARE → grant → auto-reload → become → SAS → cross).
  Companions: `Crew_todo.md` (Cave|Captain bodies + the ceremony — it absorbed Division/Ferry_rebuild,
   both now `spec/history/`), `MobilenoFSA_todo.md` / `Portability_todo.md` (the listen-only life).

## 0. What to get on with next

Owner steer 2026-08-31: **plan first, pause for adjustment, THEN slog** (this doc is the plan). Confirmed:
 §3 persist the choice = yes; §6 name-via-Door = yes ("yeah to S6"); §5 refuse = the splash "listen without a
  folder" button (RESOLVED). New: §A (the `.c`-flags→C-particles jog), and §4's Door storage-mode + future Disk
   cell.  ⚠ Still PAUSED — nothing below is greenlit to build yet beyond what already landed live this session.

Roughly in order of leverage (a running theme through all of it: §A — reach for a C particle, not a `.c` bool):
1. **The identity-model preamble** (§1) — cheap, pure docs, kills the owner's "very little visibility."
2. **Persist the share CHOICE across reloads** (§3, CONFIRMED) — the "immediate, don't ask again later" fix; small.
3. **Name via the Door, then whisk to Link** (§6, CONFIRMED) — one username UI; a surface-ordering change, medium.
4. **One OPEN SHARE button, AC+FSA, labelled honestly** (§2) — mostly landed; polish + verify the label.
5. **Storage mode expressed/configurable in the Door** (§4) — "quite small"; later, a Disk cell (OPFS readout).
6. **Delete `top.c.disk_gated_boot`** (added this session, now unused — §A) + loose CSS sweep (§7).
7. **(bigger, later) Move the boot/share `.c` flags onto C particles** (§A) — the ferry-rebuild move, applied
    to onboarding. Not near-term; the direction.

## A. STATE BELONGS IN C PARTICLES, NOT `.c` FLAGS (the language jog — owner 2026-08-31)

The owner's observation, and it's the SAME lesson the ferry rebuild just taught: we've drifted into writing
 `top.c.key = value` (plain JS props on the runtime `.c` store) for things that are STATE — the kind of thing
  you'd want to SEE in the mesh, in a snap, when reading "what's up" across the systems. That is the wrong home.

The law (CLAUDE.md): **`.sc` is the snapped, legible tree; `.c` is runtime refs/backlinks, NEVER encoded — the
 stuff you should NOT see except when you're already inside one system debugging it.** So:
- **A REF (a pointer to a world/particle/object, a backlink like `c.up`, `source_n`) → `.c` is correct.**
   e.g. `req.c.secret`, `req.c.pending` (an object frame), `top.c.ferry_world` (a ref to the ceremony's world).
    These are honestly runtime — an object in `.sc` is fatal at encode anyway.
- **A boolean/scalar STATE flag → belongs as a C PARTICLE (an sc cluster), so it reads in the snap and the
   mesh as clear words.** Putting it on `.c` makes it a private, invisible flag — the "6th mirror / big fat
    system" the owner keeps catching.

The current offenders (boot/share onboarding), all `.c` flags that should become legible C clusters —
 something like `A:Clustation → w:Swarm → /Share/…` or a `%Boot` cluster, `words:about,whats:up` style:
- `top.c.disk_gated` — a folder is wanted (the gate is up)
- `top.c.listen_choice` — the human chose listen-only (should ALSO persist — §3)
- `top.c.listen_only` — running the listen-only life
- `top.c.account_mirror_owed` — Peering moved but no nav yet (the "OWED" tell)
- `top.c.butler_up` — the arrival screen holds
- `top.c.disk_gated_boot` (added this session, now unused — DELETE it)
- the retired `top.c.ferry_*` pile is already GONE (→ req:Ferry — the template to copy).

WHY IT MATTERS (for a reader with little context): the whole bet is "turn every kind of state into the same
 legible living matter, held where a group can see it." A `.c` boolean is the opposite — it's a fact hidden
  from the snap, the Cyto graph, the daemon `/c` dump, and every Story fixture. The ferry rebuild moved ~14
   such flags onto ONE `req:Ferry` particle and suddenly the whole ceremony was visible + assertable. **The
    boot/share state is the next candidate for exactly that move.** Not urgent, but it's the direction: when
     you reach for `top.c.somebool = 1`, ask "would I want to SEE this in the mesh?" — if yes, it's a particle.

DON'T over-correct: genuinely-runtime refs (secret, the parked frame object, world refs, DOM handles, the
 poll counters `Swarm_watch_loop` reads) STAY on `.c` — that IS what `.c` is for. The test is "state vs ref",
  not "move everything."

## 1. THE IDENTITY MODEL (soul key vs body key) — landed as `Crew_todo.md` §2/§5; kept here for the arc

Two keys per device; conflating them is the whole confusion.
- **Soul key** (`eed831f…`) = THE ACCOUNT. What friends see, what owns the music, what the account IS
   (`ident.c.keys` / `ident.sc.prepub`). ⚑ 2026-09-02: held by the CAPTAIN alone — a linked device no
    longer carries it (cert-crew, `Crew_todo.md`); it keeps its own key + a `Grant:Crew` minted by
     the soul at the seal, and friends trust it AS the soul via that grant.
- **Body key** (`7f86cafc` = "Garar") = THIS INSTANCE. Each device mints its OWN durable keypair
   (`ident.c.bodykey = {pub,key,prepub}`, via `Swarm_body_key_ensure`): `.c.bodykey` cache → body-local Dexie
    (`bodykey_read`, **never replicated** — physically never leaves that browser) → else freshly minted.
     **The body-pub IS the instance-unique fingerprint.** Two devices of one soul can't collide (each rolled
      its body key locally).
- **The roster** = `%Body` rows under the account's `%Peering`: `Swarm_body_take`/`Swarm_body_note` write
   `%Body,pub:<body-key-pub>` with `role: Captain | Cave`, an `address`, and the `name` typed at that device's
    name-gate (facet D — "Captain Grav, Cave Guw"). `Swarm_body_mine` = the row whose pub matches THIS device's
     body key — COMPUTED, never stored as a flag (so a friend absorbing your roster can't mistake its own body
      for your Captain).
- So "two eeds" = ONE soul, TWO bodies (original Captain + incogni-now-Cave `7f86cafc`, offline). Two live
   bodies of one soul on the wire at once → `Swarm_note_theft` contention ("close one, or Steal Back").

Key files: `Swarm.g` Swarm_body_key_ensure:4189 / Swarm_body_take:4206 / Swarm_body_mine:4218 /
 Swarm_note_theft; `$lib/O/vessel_store` (bodykey_read/write). The four bullets above landed in
  `Crew_todo.md` §2 (the words) + §5 (the substrate).

## 2. ONE "OPEN SHARE" BUTTON (AC + FSA, on the splash)

Mostly LANDED this session. `boot_gate.svelte.ts` already harvests BOTH in one click (`open_share` = AC wakes
 + folder picker in the same gesture — the gesture rule: both must be INITIATED inside the click). `BootGate`
  is now a COMPACT bar over the splash (not a fullscreen FaceSucker): `OPEN SHARE` (folder) / `▶ open sound`
   (audio) + a `?` explainer + `🎧 listen without a folder`.
- REMAINING: the label is the only "two reasons" tell left — confirm the audio-only case reads `▶ open sound`
   and the folder case `OPEN SHARE`. The owner's "it looks back to open share after listen-only" = the audio
    half still pending after the folder half is declined (right reason) — VERIFY the label distinguishes it and
     isn't a disk_gated re-raise.
- The share gate now punches THROUGH a device-link ceremony (only AC defers) — the deadlock fix (Ferry §).

## 3. SOLICITING A FOLDER LATER — impossible, or immediate; NEVER a surprise

The owner's rule: it "kinda has to be impossible (android) or immediate (to not ask again later when tripping
 over features that require it)." The design that satisfies it:
- **The folder is an UPGRADE, not a gate.** Listen-only (Dexie identity + OPFS pool) is a COMPLETE life — a
   phone's life, chosen on desktop. So NO feature should HARD-REQUIRE an FSA: everything degrades to OPFS.
    (If a feature genuinely can't fit in OPFS — a giant on-disk library — it offers the folder, it doesn't
     demand it.)
- **Ask ONCE, up front** (the splash OPEN SHARE). Capable browser → grant (folder) or decline (listen-only).
   No-picker browser (Android/Firefox/Safari/Brave-default) → folder is IMPOSSIBLE → listen-only silently, no
    button that can't succeed (fsa_advice already says so).
- **Never a surprise picker mid-feature.** If we later WANT a folder (an upgrade moment), surface the SAME
   OPEN SHARE affordance as a gentle, non-blocking nudge ("want your library on your own disk? open a folder"),
    contextually — reusing boot_gate.open_share, not a fresh raw `showDirectoryPicker`.
- **PERSIST THE CHOICE across reloads (the "don't ask again" half).** Today `listen_choice` is `.c` (forgotten
   on reload → "a fresh boot asks fresh", Housing:2289). That means a decliner is re-nagged every reload — the
    opposite of "immediate, don't ask again." FIX: persist the resolved choice (a folder handle already persists
     via IndexedDB; persist `listen_choice` in localStorage too). Then a returning listener boots straight to
      listen-only, and a returning granter re-acquires the handle silently. The ONE compulsory tap stays audio
       (AC), which genuinely must be re-gestured per load.

## 4. noFSA (Android / browser rejects it) + a DISK cell in the Door

"are we calling it that?" — in code it's `no_fsa` (no `window.showDirectoryPicker`) + `fsa_advice` (the one
 sentence). Android Chrome lacks the directory picker; Firefox/Safari/Brave-default too. On those the folder is
  IMPOSSIBLE and the flow is listen-only by construction (Housing:2291 stands the gate down). A device-link
   ADOPT on such a device → the soul lands in OPFS/Dexie (the phone-Cave life) — verify that path holds (a Cave
    with no folder is exactly the mobile case Portability_todo §0 wants).
- **EXPRESS/CONFIGURE THE noFSA SITUATION IN THE DOOR (owner 2026-08-31, "quite small though").** The share
   decision (folder | listen-only | impossible) shouldn't only live as a boot-time gate + `.c` flags — it
    should be a thing the human can SEE and change from the Door. Small: a line/toggle in DoorFace showing
     the current storage mode, with "open a folder" (reuses boot_gate.open_share) when capable. Ties to §A —
      the mode wants to be a legible particle the Door reads, not a `.c` bool.
- **FUTURE: a DISK CELL you click through to from the Door.** Shows the QUANTITIES stored in OPFS — a
   protocol/legend that says "this is the SoundPool of `tag:vio`", plus any other storage-situation-relevant
    readout (identity, pool size, per-tag breakdown, what's pinned vs evictable). i.e. make the OPFS/disk
     picture legible matter you can inspect, same spirit as everything else. Not near-term; noted so it isn't
      lost. (Owner's words: "a Disk cell as well you click through to there, where you can see the quantities
       of what's stored in OPFS, using some protocol to say it's the SoundPool of the tag:vio, or anything
        else storage situation relevant.")

## 5. THE "REFUSE" BUTTON — RESOLVED

It's the **"🎧 listen without a folder"** button on the splash OPEN SHARE bar (the compact BootGate we added
 this session). "Refuse" = decline the folder → `boot_gate.listen_only()` → `listen_choice=1`, `disk_gated=false`
  → the listen-only life (Dexie identity + OPFS pool). Sane. The only follow-up is §3: make that choice STICK
   across reloads so a refuser isn't re-nagged.

## 6. NAME VIA THE DOOR, THEN WHISK TO LINK (one username UI)

**CONFIRMED — owner 2026-08-31: "yeah to S6", do it.**
Owner: "use the Door's 'name yourself to begin' UI, THEN get whisked over to the Link for the rest, which
 depends on having a name." Today there are TWO name solicitations: the Door name-gate (task #46) AND the Link
  offer cell's own input. The name is GENERAL account setup, so one UI (the Door) should own it.
- FEASIBLE: YES. The name lives on the identity (`ident.sc.friendly`), read by both faces (`named`). If the
   Door sets it first, the Link offer's `named` gate is already satisfied → drop the Link cell's inline input.
- MECHANISM: on a fresh `#Iz` tab with no name, the surface authority should raise the **Door name-gate FIRST**
   (unnamed + a ferry offer pending → Door names → then the parked ferry offer re-surfaces the Link cell, now
    named → "become …?" → understand). The offer is durable (`#Iz` URL + stashed twin), so it survives the
     detour. Remove the `<input class="ld-name">` rows from LinkDevice's offer/confirm/receive faces and lean
      on `named` being pre-set.
- COST: a focus-ordering tweak (Door-before-Link when unnamed) + deleting the inline inputs. Medium, clean.
- INTERIM (already landed): the inline input now FILLS its box (`flex:1;min-width:0`) so it's usable until §6
   lands. So the owner can "put up with" it short-term with no layout bug.

## 7. Loose ends
- Orphaned CSS in LinkDevice: `.ld-rung`, `.ld-rung.on`, `.ld-rung.wait` (the retired three-rung wait ladder),
   and possibly others from the SAS/facelift churn — a cosmetic sweep, no template uses them.
- The un-acked "carrying it over…10s" count-up was already removed (post-send face now reads "✓ soul given /
   now say yes on your other device").
