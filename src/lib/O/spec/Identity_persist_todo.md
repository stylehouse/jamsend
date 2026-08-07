# Identity_persist_todo.md — Identity ↔ Thing/Thang ↔ `.jamsend` persistence

The "big deal" thread (the human, 2026-07-27): *"getting Identity to be persisted in the .jamsend dir
 per Identity, and knowing which is the 'main one' if a browser with no Thang (dexie) state inits with
  FSA that does persist state."* This doc is the state-of-the-world (two code surveys, 2026-07-27) +
   the build plan. Parallel to the compact-invite cut (`Swarm_compact_invite_todo.md`), touching none
    of its seams.

## 0. State — BUILT + GREEN (2026-07-27) · SEAM CUT (2026-08-04) · **FOUR GAPS FOUND, §6 (2026-08-07)**

> **START AT §6.** A node daemon booted on this identity path, headless, against a real filesystem
>  nav, and the seam does not work end to end yet. Four gaps, all app glue, none needing a rethink:
>  **(1)** nothing in the app ever calls the write side, so the boot-seed reads a file that is never
>   written; **(2)** the disk read is skipped — straight to ARREST — when the Swarm ghost hasn't
>    deposited yet, which on a cold boot is always; **(3)** a *successful* seed never clears
>     `identity_pending`, so a boot that found its key on disk stays held forever with the key in
>      hand; **(4)** a role-filed identity (`sound`/`word`/`daemon`) is invisible to its own
>       `?I=<prepub>` in Dexie, which is also the answer to audit item 2's open DECIDE.
> **Order matters: 2 and 3, then 4, then 1** — gap 1 alone makes it worse (§6.5). None were made;
>  `Auto.svelte` is shared ground. **Re-verified unfixed in the tree 2026-08-08.**
>
> **Gap 4 is the one that touches every user** (§6.4, promoted 2026-08-07): a real client never sets
>  `?I=`, so *every* client is a role-filed identity and the role path IS the app.

> **RULED, 2026-08-07 (the owner) — the daemon never provisions; an arrest is an ERROR EXIT.**
>  *"all the management happens in sessions of the account running in a browser, configuring
>   Invites the usual way etc, then runs in the Daemon"* — the browser is the management surface,
>    the share's `.jamsend/account/<prepub>/` is the hand-off, and a daemon boots `I=<prepub>` to
>     RESUME, never to mint. A `?I=` with no account in the share *"should exit with error"* — no
>      hatch, no substitute mint. **§7 is the flow this makes canonical**; the §6 gaps are exactly
>       what block it. The exit half is daemon-local and LANDED (`scripts/daemon/main.ts`
>        `arrest_watch`: exit 2 = no account in the share, exit 3 = account on disk but the seed
>         failed).
>
> **REVISED the same day — self-collision is a FEDERATION, not an exit (§7.4).** Running into
>  yourself is not theft: **serial-number the extras and connect all nodes of one Identity
>   together**, with **disconnect / overthrow / reinstate** to take turns at the canonical address
>    while the key never moves. It fits the box we already have — `Swarm.g #region places`, *"one
>     key, N addresses"* — and `reinstate` is the only new primitive. Ruled with it: the incumbent
>      **holds until told** (no auto-yield), and the surface is **DoorFace swelling**, never the
>       IdHatch. The error exit stays as the fallback for when there is nobody to negotiate with.

> **UPDATE, 2026-08-04 (later the same day) — the seam below is now WIRED.** Auto
>  `Clustation_ensure_identity` no longer arrests straight off a Dexie miss: it tries the disk first
>   via `Swarm_boot_seed(nav, '', vault, param)`, and on a hit concretes the identity AND mirrors the
>    row back into Dexie so the next boot is a plain Dexie hit. The arrest is now the LAST resort it
>     was always meant to be. Three guards, each load-bearing — read them in the code comment before
>      touching this:
>  - **nav not up yet → retry, don't arrest** (`A:Wormhole/c.nav` is null until the disk stands up),
>     bounded by `SEED_WAIT_MS = 5000` so a browser with no share still reaches the hatch;
>  - **remote nav → refused.** `.jamsend` cannot cross the wire (so a remote nav *cannot* answer this
>     read), and awaiting an `atime_async` nav here would deadlock under the beliefs mutex anyway —
>      `Crate_nav`'s own caveat. Do not "fix" a failing seed by relaxing either half;
>  - **attempted once**, not once per boot pass — an arrest returns false and Auto re-enters every
>     pass, so an un-guarded read would hammer the disk forever (`identity_seed_tried`).
>
> **What is proven and what is not.** Type-clean (svelte-check 3408/123, the standing baseline) and
>  the disk layer's own Book is unaffected — but `SwarmDisk` exercises `Swarm_boot_seed` against an
>   IN-MEMORY nav double (`SwarmDisk_memnav`), so *nothing yet proves the real FSA path*. **This still
>    needs the two-tab fingers-test with a human**: mint on one tab, clear IndexedDB on another,
>     reload with the same `?I=`, and watch for `🪪 Identity RESTORED from disk`. That is the one
>      thing a Book cannot buy.
>
> **Known gap, deliberately not closed here.** The seed grafts into a DETACHED vault (an unattached
>  `_C` snaps nothing), so only the KEYPAIR is adopted — the identity's piers/grants are not.
>   `Swarm_piers_rehydrate` owns that rail and reads Dexie, which is empty in exactly this scenario,
>    so a disk-restored owner comes back friendless. The key is what the arrest is about; the friends
>     are a follow-on (`Swarm_restash_piers` is the converse half and already exists).

> **Escalation, 2026-08-04 — do this seam next.** The editor lost its identity **twice in one
>  session**: `?I=49dee91d61a9de64` (resolved by minting a new one through the IdHatch arrest) and
>   then again a few hours later, now booting as `?I=cdbe098c044e6806`. The human: *"editor lost its
>    crypto again!? weird. we really need to get our shit together."*
>
> This is exactly the failure `Swarm_boot_seed` exists to prevent, and the only reason it still
>  happens is that the wiring below was never cut. Dexie is currently the SOLE home of a browser's
>   keypair, so anything that clears site data — a profile wipe, an origin change, a quota eviction,
>    a hand-cleared IndexedDB — destroys an identity that is already sitting safely on disk in
>     `.jamsend/account/<prepub>/toc.snap`. **The keys are persisted; nothing reads them at boot.**
>
> Two consequences that make it worse than "re-mint and move on", both seen today:
>  - a re-mint changes the tab's addressable prepub, so **cluster trust must be re-granted** (the
>     relay rejects `gen_write` from an untrusted pub) and every runner's roster entry is stale;
>  - the identity ARREST (Auto `Clustation_ensure_identity`, Cluster_spec §3.2a) correctly HOLDS the
>     boot rather than silently minting a stranger — which is right, but it means a lost key is a
>      hard stop for the tab, not a degradation. Reading disk first would make the arrest rare.
>
> Scope reminder so this doesn't sprawl: `.jamsend` is owner-local and the Wormhole REFUSES to serve
>  any path with a `.jamsend` segment over the wire (Housing `rw_op`, invariant 1) — that guard is
>   what makes an on-disk private key acceptable at all. Do NOT relax it to make boot-seed easier.

The disk layer is CUT and proven on the live runner (`SwarmDisk` green×2, runner 20e3476b). What
 stands, and the one seam still owed:

- **Keys ride the snap.** `Swarm_export`/`Swarm_import` dropped the `env.keys` sidecar (the human:
   *"doesn't need to env.keys that's silly — just put them in the snap"*): an `account` export embeds
    the keypair as two hex sc scalars on the Identity root line (`Swarm_snap_keyed`), and import THAWS
     them onto `.c.keys` + STRIPS them off sc, so every LIVE node still keeps "keys ride .c only" —
      only the on-disk/transit snap bears them. `SwarmStaple` beat 8 re-recorded green×2 (byte-identity
       holds; `bytes:1550`).
- **The two disk homes** live under `.jamsend` (owner-local — the human confirmed *"not readable via
   Repli"*): `account/<prepub>/toc.snap` (the keyed export snap = agency, Waft-editable) and
    `identities/toc.snap` (pub-only recognition roster). Everyone shares ONE FSA point, so the
     `<prepub>` segment keeps owners apart — no per-device root. Helpers in Swarm.g `#region
      portability`: `Swarm_account_dir/save/load`, `Swarm_account_list`, `Swarm_roster_open/save`,
       `Swarm_persist`, `Swarm_boot_seed`.
- **The next move (the ONE owed seam): wire `Swarm_boot_seed` into Auto's boot.** It is a PURE
   Book-provable lift today (given an empty container + a share, it enumerates `account/*`, picks the
    target, loads the owner able to sign). The app-boot GLUE — Auto `ensure_identity` ADOPTING the
     disk owner before minting a parallel self, marking it `sc.active`, and re-mirroring into Dexie so
      the NEXT boot resumes from Dexie (§4 write-through, no second-reload trap) — is not yet cut,
       because its only real proof is a live reboot: **the two-tab fingers-test** (mint on one
        Sounditron tab, reload the other with empty Dexie → the owner stands off disk). Do that wiring
         WITH the human at the two-tab test, not blind.
- **"Which is main" is a Thang (Dexie) concern**, not a disk pointer (the human): the roster is
   recognition-only. `?I=<prepub>` selects; multi-identity is deliberately weakly supported —
    `Swarm_boot_seed(want)` honours a `?I=` prepub, else the sole account, else the first.
- **NO migrator.** The old-garden Things→%Idzeug lift (was rung 5) is DROPPED — the human: *"I don't
   want any migration from the old account system — it's just for your research. I will copy the one
    account we have there manually later."* The survey below is kept as reference only.
- Naming correction to swallow: the OLD garden's persisted object is a **Thing** (`ThingIsms`,
   `src/lib/data/Things.svelte.ts`) over **raw IndexedDB** — NOT Dexie. **Thang** (`src/lib/O/Thangs.svelte`,
    Dexie DB `'thangs'`) is the NEW stack's store. Swarm.g:251 and Swarm_spec §6.2 say "Dexie" for the
     old ledger — that's wrong (reference only now that the migrator is dropped).

## 1. What EXISTS (verified against code, 2026-07-27)

- **Dexie side (BUILT)**: the identities Thang (`thang_put` under prepub + role tags — friendly,
   born, DoorFace state); `.stashed.cluster_idento` (the role key, IdHatch); `Swarm_pier_stash` /
    `Swarm_iz_stash` / `Swarm_chainroot_stash` — friendship, invite ledger, chain lineage ALL survive
     reload via top-House `.stashed` (= Dexie), rehydrated at station standup (Swarm.g:507-509).
- **Boot ladder (Swarm_spec §5)**: steps 1-2 BUILT (`?I=<tag>` resume; else Dexie-active resume);
   steps 3-4 **[want]** — disk seed (`<music>/.jamsend/account/*/toc.snap` → seed Dexie) and
    mint-fresh-then-mirror-to-disk. THIS DOC's build target.
- **Berth (BUILT, live-gate owed)**: per-identity Waft home `.jamsend/berth/<prepub>/<Waftname>/toc.snap`
   (`Heist.g #region berth` — `Berth_open/save/reset/dir`). The natural rails for the account snap.
- **Old garden (Things, raw IndexedDB `Trust` v2)**: stores `Peering|Pier|Idzeug|gizmo`; the REAL
   state is JSON blobs in **`gizmo`** keyed `F=Trusting()/Thing:<store>=<name>`; identity =
    `stashed.Id = {pub, key}` (raw ed25519 hex), **`stashed.main`** marks the main identity; invite
     ledger = `stashed.{Serial, Upper_Number, taken_n[], nRepeating, give_them_trust}`; counters
      (`PierSerial`/`IdzeugSerial`) in the TrustingModus gizmo blob. NO bridge to the new machine
       exists (verified NOT FOUND).

## 2. The design — split by SENSITIVITY (not one store for everything)

- **PUBLIC + portable → Waft on `.jamsend`**: the identity ROSTER (each identity's pub/prepub/
   friendly/born — recognition only, no main pointer) and per-identity account snaps
    (`.jamsend/account/<prepub>/toc.snap` — %Peering page, %Piers, grants, %NotGrants, %Idzeug spend
     ledger). Portable with the share, survives a fresh browser, human-editable.
- **PRIVATE keys → in the account snap** (RESOLVED — `.jamsend` is owner-local, never Repli-readable):
   keys ride the account snap inline (`Swarm_snap_keyed` embed, thawed onto `.c.keys` at import),
    proven byte-stable by SwarmStaple beat 8 + SwarmDisk. The roster stays pub-only regardless, so it
     is safe even if this ONE file's law is ever relaxed.
- **Write-through, one direction at a time (Swarm_spec §4 stream rule)**: Dexie is the working store;
   throttled re-snap Dexie→disk on Waft:Account version bump (`Swarm_persist`); disk→Dexie ONLY when
    Dexie is empty (the fresh-browser seed, `Swarm_boot_seed`). Divergence = last-write-wins on the
     snap, never a merge.
- **"Which is main" is a Thang (Dexie) concern**, decoupled from agency: the disk roster answers
   recognition (who lives here); `?I=<prepub>` / Dexie `stashed.main` answer which is active. With
    keys on disk, recognition + agency collapse into one read; multi-identity is deliberately weakly
     supported (`?I=`-explicit).

## 3. Build plan (each rung provable by a Book)

1. **Roster Waft** — **BUILT**. `.jamsend/identities/toc.snap` — `%Identity,<prepub>` rows (pub,
    friendly, born; pub-only, NO key, NO main pointer — "main" is a Thang concern). `Swarm_roster_open/save`.
     Proven by `SwarmDisk` beat 4 (`roster-pub-only` sworn: pub on disk, key never).
2. **Account snap write-through** — **BUILT**. `Swarm_account_save` (= `Swarm_export` unwrapped) →
    `account/<prepub>/toc.snap`; `Swarm_persist` mirrors both homes. Proven by `SwarmDisk` beats 4–5
     (`account-alone` + `reseed-identical`: the snap carries grant + keypair inline and re-saves byte
      for byte). The *throttle* (fire on a `Waft:Account` version bump, not every tick) is the app-glue
       gear, folded into the Auto wiring below.
3. **Boot seed** — **BUILT (pure lift), app-wiring OWED**. `Swarm_boot_seed(nav, root, container, want)`
    enumerates `account/*`, picks (`want`/sole/first), loads the owner able to SIGN. Proven by `SwarmDisk`
     beat 5 (`reseed-reborn` + `reseed-signs`: a fresh container reseeds off disk alone; the thawed key
      verifies an old grant AND signs a new one). **OWED**: the Auto `ensure_identity` seam that adopts
       this on boot before minting a parallel self, sets `sc.active`, and re-mirrors to Dexie — proof =
        the two-tab fingers-test (§0). Do it WITH the human.
4. **Boot ladder step 4** (born-today mirror): both empty → mint fresh → persist Dexie → mirror to disk
    once the share opens (the path the InvitePanel already half-exercises). Same Auto seam as rung 3.
5. **§7a migrator — DROPPED** (the human 2026-07-27: no migration; will copy the one account by hand).
    The survey in §1 stays as reference should this ever be revived; `Swarm_legacy_of_url` already
     parses the old `#`-links, but nothing lifts the old Dexie into %Idzeug records and nothing will.

## 4. Types of Invite (the human's "one only, editable on disk as Waft?")

The %Idzeug ledger records under %Peering are ALREADY the invite types/instances, and they already
 stash-persist. Once rung 2 above lands they live in the account snap on disk too — Waft-editable,
  which IS the "editable on disk only as Waft" stance: the Thang/Dexie copy is the working cache, the
   disk Waft the canonical, portable, human-editable home. No separate "invite type" object needed —
    a type is a mint recipe (Feature + params + chain|blotter flag), and the blotter sheet already
     groups instances.

## 5. The Auto wiring — the exact seam (for the two-tab session, do WITH the human)

The ONE owed seam. Verified against Auto.svelte 2026-07-27. Wire the disk-seed into the `?I=<prepub>`
 path ONLY — the primary fresh-browser path (a QR/invite lands `?I=<prepub>` or `?Iz=` rewrites to
  it). The role-default path (`Clustation_ensure_default`, /BigSoundland='sound') stays Dexie-only:
   its Thang is keyed by ROLE not prepub, and a bare page with no `?I=` names no specific owner to
    resume — so a fresh browser there mints fresh (multi-identity is weakly supported by design).

**Seam: `Clustation_ensure_identity`, the peek-MISS `else` (~line 136).** Today it mints fresh when
 Dexie has no Thang for the tag; insert a disk check FIRST:

```js
const peeked = await (H as any).thang_peek('identities', tag)
if (peeked?.pub && peeked?.key) stored = peeked
else {
    // fresh browser, empty Dexie — but the owner-local .jamsend may hold this account.
    const nav = (H as any).Crate_nav?.()
    let seeded = null
    if (nav) { try { seeded = await (H as any).Swarm_account_load(nav, '', tag, A) } catch {} }
    if (seeded?.c?.keys?.key) {
        stored = { pub: seeded.c.keys.pub, key: seeded.c.keys.key, prepub: seeded.sc.prepub }
        await (H as any).thang_add(wT, tag, stored)     // mirror to Dexie so the NEXT boot resumes from Dexie
        // OWED — the second-reload trap: Swarm_account_load grafted the Piers/Grants/Idzeugs into A
        //  in memory, but did NOT write them to the Dexie stash (Swarm_izzes/piers).  A SECOND reload
        //   then peeks the identity Thang (present) and rehydrates piers from the stash (EMPTY) → friends
        //    vanish.  Fix: after concrete sets active, mirror the loaded ledger into the stash — build
        //     `Swarm_restash_all(ident)` (walk Peering's Piers→Swarm_pier_stash, Idzeugs→Swarm_iz_stash,
        //      ChainRoots→Swarm_chainroot_stash; guarded live_self, so set active FIRST).  OR make disk
        //       authoritative: seed from disk on every boot when the account file is newer.  Decide at
        //        the two-tab test.
    } else {
        stored = await (H as any).Clustation_mint(tag)
        await (H as any).thang_add(wT, tag, stored)
    }
}
```

**Why it's safe:** `Swarm_account_load(nav, '', tag, A)` grafts `Identity:<tag>` (+ Peering/Piers/Grants)
 under A:Clustation; the very next line, `Clustation_concrete(A, tag, stored)`, does `A.oai({Identity:
  tag})` — it FINDS that grafted Identity and re-activates it (keys, active, peering), never a duplicate
   (Auto.svelte:161). And it is a pure ADD: when no share/nav or no account file exists (the common
    case), `seeded` is null and control falls through to the existing mint-fresh — behaviour unchanged.

**The write-through mirror (rung 2 in prod):** call `Swarm_persist(Crate_nav(), '', activeIdent)` on a
 `Waft:Account` version bump (throttled), so a sealed friendship / minted invite lands on disk. The
  hook site is wherever the app already reacts to account mutation (Swarm_seal / mint paths).

**The proof (why this isn't cut blind):** the two-tab fingers-test —
 1. Tab A (a Sounditron runner, `?I=<prepub>`): seal a friendship / mint an invite → `Swarm_persist`
     writes `account/<prepub>/toc.snap` on the shared FSA point.
 2. Tab B: same `?I=<prepub>`, but clear its Dexie (`identities` store) to simulate a fresh browser →
     reload → the seam fires, the owner stands off disk with the friendship intact and the key signing.
 3. Reload Tab B AGAIN → if friends vanish, that's the second-reload trap → land `Swarm_restash_all`.
 `SwarmDisk` already proves the model layer of all of this (green×2); the two-tab test proves the Auto
  glue + the real FSA backend, which no Book can (the Books use a memnav / mock carriers by design).

### Audit corrections (2026-07-27) — the recipe above has three real bugs; fold these before applying

A production-readiness audit found the §5 seam under-guarded. Land ALL of these with the wiring:
1. **nav timing** — `Crate_nav()` is null until the Wormhole ghost deposits the nav (and FSA needs a
    user gesture); `Clustation_ensure_identity` runs early and LATCHES `H.c.identity_up=true` even when
     it mints fresh. So on a real cold boot the seed sees `nav===null` → mints a STRANGER → latches →
      the disk owner is never adopted once the share mounts. FIX: do not latch until `Crate_nav()` has
       been consulted — return `false` (retry next tick) while nav is null AND a disk account exists
        for the wanted prepub; only then fall through to mint-fresh.
2. **wrong path for a fresh QR scan** — a brand-new browser scanning a QR lands on `?Iz=` with NO `?I=`,
    so `Clustation_ensure_identity` early-returns (no param) and the identity is minted by
     `Clustation_ensure_default` (the ROLE path, e.g. 'sound') — which this recipe leaves Dexie-only.
      The `?Iz`→`?I=<prepub>` rewrite happens only AFTER a successful join (InvitePanel). So disk-seed
       helps only a LATER `?I=<prepub>` reload, not the first scan. DECIDE: does the role-default path
        also need a disk peek (resume the owner at a bare URL), or is fresh-scan-resume explicitly a
         second-boot behavior? (A returning OWNER at a bare `/BigSoundland` gets a fresh self today.)
3. **second-reload trap** — as already flagged: `Swarm_account_load` grafts Piers/Grants into the live
    tree but NOT into the Dexie stash, and standup rehydrates piers ONLY from the stash. So reload #2
     (Dexie now has the identity Thang, skips disk) → empty stash → friends vanish. Land
      `Swarm_restash_all(ident)` (walk Peering's Piers→`Swarm_pier_stash`, Idzeugs→`Swarm_iz_stash`,
       ChainRoots→`Swarm_chainroot_stash`; guarded on live_self, so set active FIRST) OR make disk
        authoritative on every boot. `Swarm_restash_all` does NOT exist yet — build it here.
4. **corrupt file** — HARDENED at the model layer (2026-07-27): `Swarm_account_load` now catches a
    corrupt-snap throw → null (degrades to mint-fresh, never an unhandled boot throw), and
     `Swarm_boot_seed` tries the preferred prepub first then the rest so one bad file never strands the
      others. Still consider SURFACING the corruption (a rebuff the owner sees) rather than silently
       minting a stranger under the real owner's dir.

Confirmed clean by the audit: the private key reaches ONLY the account snap (never a frame/page/voucher/
 roster/Repli/got_snap — `Swarm_page` is hand-built pub-only, `.c.keys` never encodes); and
  `Clustation_concrete` re-activates the grafted Identity by mainkey without duplicating — PROVIDED the
   on-disk Identity mainkey equals the `?I=` prepub (true for machine-written files; a hand-edited
    "Waft-editable" file that desyncs the mainkey would duplicate — a caveat of the editable-on-disk stance).

---

## 6. Production-ready — the four gaps, in the order they must be landed (2026-08-07)

> **ALL FOUR LANDED 2026-08-08** (overnight, under `Daemon_todo` §9's work order; full log and the
>  before/after evidence table are in `Daemon_todo` §9.6). In §6.5's mandated order: **2+3** together
>   (`Auto.svelte` — the ghost-deposit retry, and the arrest lifted in `Clustation_concrete`), then
>    **4** (`Clustation_ensure_default` now pins under the prepub too), then **1** last
>     (`Clustation_mirror_account`, the write side that never existed). Each was verified on the
>      daemon against a real fs nav, and the round trip closes: Auto WRITES the account, a wiped
>       Dexie RESTORES from it, exit 0 with `w:Story` standing where baseline exits 3.
>
> **Three things in this section were wrong, and cost real time — corrections are inline below:**
> `Swarm_restash_piers` already existed (§6.6 and §5 audit item 3 both say build it); `%ChainRoot`
>  hangs off the `%Identity`, not the `%Peering`; and the restash recipe contradicted itself about
>   the live-self guard (§6.6). Plus one live bug found in passing: **`Clustation_pin` had never
>    worked** — it asked `Clustation_active_identity` (which returns `{pub,key}`, no `.c`) and then
>     guarded on `ident.c.keys`, so it returned false at its first line, always. The door's ?Iz→?I
>      swap has been silently not pinning this whole time. Fixed with gap 4, since gap 4 needs it.
>
> **Still owed and NOT done:** §6.6's list (the two-writers problem has teeth now that gap 1 writes),
>  and the two-tab fingers-test — §6.7's stated gate for the FSA backend — which no daemon run can
>   stand in for. Everything below is proven on the node nav only.

**Where this evidence came from.** A node daemon (`scripts/daemon/`, `Daemon_todo.md` §4.1) was booted
 on this exact identity path: the same three `boot_qualand` stamps `/BigSoundland` uses, headless, and
  **against a real filesystem nav** — the one thing `SwarmDisk` cannot do (it runs on the in-memory
   `SwarmDisk_memnav` by design, §5's own caveat). Everything below was **observed in a run**, not
    inferred from reading. It is not the two-tab fingers-test — a browser is still the only proof of
     the FSA backend — but it is the same seam, exercised end to end, in about 60 seconds, repeatably.

### 6.0 The constraint that shapes all of it: no disk read on a healthy boot

The owner, 2026-08-07: *"I want it only checking disk if it's not in Dexie of course, don't add a
 round trip to every startup."* **That is already the built behaviour and nothing below changes it.**
  `Clustation_ensure_identity` peeks Dexie first and returns on a hit; the disk branch is reached only
   on a miss, and `identity_seed_tried` caps it at one attempt per boot. So a normal boot does **zero**
    disk reads for identity. Two things to hold onto while landing the fixes:

- **Gap 4's fix raises the Dexie hit rate**, so it *removes* disk reads rather than adding any.
- **Gap 1's write must not read back.** Mirror on a version bump of an identity you already hold —
   never a "is the disk still right?" check. Write-through, one direction (§2's stream rule), and the
    seed direction stays disk→Dexie **only when Dexie is empty**.

### 6.1 Gap 1 — nothing calls the write side

`Auto.svelte:176` states *"Swarm_account_save has been writing the whole account (keypair embedded) to
 `.jamsend/account/<prepub>/toc.snap` all along"*. It has not. Every caller of `Swarm_persist` /
  `Swarm_account_save` / `Swarm_roster_save` in the tree is inside the `SwarmDisk` Book. **Rung 2
   (§3) is BUILT at the model layer and has no app caller** — so the read side, wired 2026-08-04,
    arrests next to an account dir that was never created. That is the whole of *"editor lost its
     crypto again!?"*.

Fix: call `Swarm_persist(nav, root, ident)` from Auto once an identity is active with `.c.keys` and
 the nav is up. Guards, the same two the read already carries and for the same reasons: **refuse a
  remote nav** (`.jamsend` never crosses the wire, and an `atime_async` nav awaited under the beliefs
   mutex deadlocks), and never per-tick — §3 rung 2's own words, *"fire on a `Waft:Account` version
    bump, not every tick"*, because the write is an `enWaft` of the whole account.

Reference implementation exists and runs: the daemon does exactly this (`main.ts`, `persist_account`,
 `ACCOUNT=0` opts out) with a once-per-identity-per-boot throttle. That is the floor, not the target —
  a tab that renames itself or takes a grant wants the bump-driven version.

### 6.2 Gap 2 — the disk read is skipped when its ghost hasn't deposited yet

The disk branch is guarded `typeof Swarm_boot_seed === 'function' && typeof Crate_nav === 'function'
 && !identity_seed_tried` (`Auto.svelte:200`). The nav-not-up case correctly **retries**
  (`SEED_WAIT_MS`, and deliberately does not stamp `identity_seed_tried` — *"that is the one case
   where waiting genuinely changes the answer"*). **Ghost-not-deposited has no such branch**: the
    block is skipped whole and execution falls straight through to the ARREST. Ghosts arrive via the
     Creduler, i.e. always later than the first boot pass — so on a cold boot this fires every time.

Observed, with a valid account sitting on disk:

```
[15.4s] 🪪⚠ identity ARRESTED — no key for ea5c82505cfc50ff is stored in this browser.
```

Fix: it is the same idiom already at the top of the function — the `thang_add`/`thang_peek` mount
 guard returns `false` (retry next pass, don't latch). Return `false` when `Swarm_boot_seed` isn't
  deposited, bounded by the same `SEED_WAIT_MS` so a build where the ghost genuinely never lands still
   reaches the hatch rather than hanging. **This is a THIRD case of audit item 1's shape** (§ Audit
    corrections) — that item caught nav timing; the ghost-deposit timing is its sibling and was missed.

### 6.3 Gap 3 — a successful seed never clears the arrest

`identity_pending` is cleared in exactly two places: `Clustation_generate_for_pending` and the IdHatch
 paste (`Auto.svelte:370`). Both are human gestures. So the later pass **does** find the key on disk
  and concrete it — and the boot stays held anyway, because `if (top.c.identity_pending) return`
   (`Auto.svelte:630`) runs before everything downstream. Observed: an active identity, keys present,
    the account re-mirrored at 24s — and `w:Story` never standing up across the full 60s run.

```
[24.2s] 🪪 account mirrored → .jamsend/account/ea5c82505cfc50ff/toc.snap
[54.2s] ♥ 🪪ea5c82505cfc  worlds=Blank Wormhole Auto Lies Clustation/Thangs      ← no Story. ever.
```

Fix: clear `identity_pending` + `identity_pending_why` in **`Clustation_concrete`** — the single
 chokepoint every resume path funnels through (`?I=` Dexie hit, disk seed, legacy adopt, mint). The
  two existing manual clears then become redundant rather than wrong. Anywhere else and the next
   resume path added will re-open this.

### 6.4 Gap 4 — a role-filed identity is invisible to its own `?I=<prepub>`

`Clustation_ensure_default` files the identity in the identities Thang under the **role** name
 (`sound`, `word`, `daemon`); `Clustation_ensure_identity` looks up by the **tag** and requires
  `peeked.prepub === param` to accept a row. So `/BigSoundland`'s own identity cannot be resumed by
   its own prepub out of Dexie — it misses, falls to disk, and therefore into gaps 1–3.

**This decides the open question in audit item 2** (*"DECIDE: does the role-default path also need a
 disk peek…"*): it does not. The role path needs to be **findable by prepub in Dexie**, and then the
  disk peek is only ever the genuinely-empty-browser case it was designed for.

> **PROMOTED, 2026-08-07: this is the gap that affects EVERY user, not an edge case.** A real client
>  never sets `?I=` or `?B=` — `/BigSoundland` stamps `book`+`role` in code via `boot_qualand`, so
>   **every client is a role-filed identity**. Which means the role path *is* the app, and its
>    invisibility to its own prepub is the normal case rather than a corner. Land 4 with 2 and 3, not
>     after them if that ever slips.

The precedent is already in the file: `Clustation_friendly` persists *"under BOTH homes the identity
 answers to — its prepub tag and this page's role tag (a role-resumed boot must find the name too)"*.
  Make the role mint do the same at mint time (`thang_add` under `stored.prepub` as well as the role).
   A `?I=<prepub>` boot of a role identity then becomes a plain Dexie hit that never touches disk —
    which is 6.0's constraint, satisfied harder.

### 6.5 Ordering — and why gap 1 goes LAST

**2 and 3, then 4, then 1.** Gaps 2 and 3 are *inert today*: with no write side there is never a file
 to find, so fixing them changes no observable behaviour and cannot regress anything. Gap 4 is
  Dexie-local and equally safe. **Gap 1 alone makes things strictly worse** — it creates the very file
   the broken read then arrests on, turning today's honest *"no key stored"* into
    *"restored from disk and held forever"*. Land it only once 2 and 3 are in.

### 6.6 Still owed beyond the four (production, not correctness)

- **A restored owner comes back friendless.** Already §0 and audit item 3. The account snap *does*
   carry piers + grants + the iz ledger (rungs 1–2, proven by `SwarmDisk`), so the missing move is
    grafting the seeded vault's piers into the live tree and re-stashing them — `Swarm_restash_all`,
     which still does not exist. The seed deliberately lands in a DETACHED vault and takes only the
      keypair. Reload #2 is the trap: Dexie now has the identity, skips disk, and the stash is empty.
- **Headless has no hatch — RULED 2026-08-07, and LANDED for the daemon (§7.2).** The policy is
   **exit with error**, not a knob: no `ARREST=halt|mint`, because a daemon has exactly one ruled
    behaviour and a knob would only re-open it. `arrest_watch` in `scripts/daemon/main.ts` exits 2
     (config: no account in the share — provision from a browser first) or 3 (bug: account on disk,
      seed failed — the §6 gaps until they land). Other unattended instances (CI runners, kiosks)
       still hang and want the same treatment when one exists.
- **A remote-wormhole tab can never restore**, by law — `.jamsend` doesn't cross the wire. That is
   correct and must not be relaxed, but it means "clear your site data" is unrecoverable for that
    whole class of tab, and it currently degrades to a `console.warn`. Make it a legible refusal.
- **Cross-machine "two of me" is theft, not siblinghood.** The `%Sibling` roster is a Dexie-liveQuery
   of *this browser's* tabs, so a daemon and a laptop on one `?I=` contest instead of cooperating;
    `Swarm_contest` raises `stolen` and `Swarm_steal_back` concedes the bare name for `<prepub>_1`,
     **same key**, so Piers still verify. There is no timeout and no negotiation — flag plus an
      explicit call. Adequate for v1, but say so out loud before someone runs two boxes.
   **RULED 2026-08-07 (§7.4): it IS siblinghood — the roster is just scoped wrong.** Serial-number
    the extras and connect every place of one Identity (§7.4d); the relay's signed `hello` is what
     finally makes the sibling-vs-thief call honest across machines, so theft narrows to *"cannot
      prove the key"*. Disconnect / overthrow / reinstate take turns at the canonical address, the
       incumbent holds until told, and DoorFace swells to show it. Blocked on `Daemon_todo` §4 (the
        daemon has no address of its own to collide WITH yet).
- **Two writers, one file, no merge — CLOSED in principle by §7.4f (2026-08-07).** §2 is explicit
   that divergence is last-write-wins on the snap, and an always-up daemon plus a tab that renames
    itself meant one of them lost silently. The ruling: **the canonical address IS the write lock** —
     only the place holding bare `<prepub>` may write `.jamsend/account/<prepub>/`, serials are
      readers. No new mechanism; the token is an address that already exists and that the arriving
       session wants anyway. Two things it still owes: the gate itself
        (`Swarm_persist` only when `Swarm_address(ident) === ident.sc.prepub`), and the
         **re-read at reinstate** (§7.4f/§7.4g) — without which a returning holder writes back a
          stale copy over the very changes the borrow existed to make. The lock is advisory: every
           place here is the owner, so it is honoured by the code, not enforced against a modified
            client.

### 6.7 How each of these gets proven

- **The two-tab fingers-test stays the gate** for the FSA backend (§0): mint on one tab, clear
   IndexedDB on another, reload with the same `?I=`, watch for `🪪 Identity RESTORED from disk`.
- **The daemon is the fast repeatable twin** — a real fs nav, no browser, ~60s, and it is what found
   gaps 2–4:
   ```
   B=Sounditron ROLE=daemon KEYED=0 OVERLAY=<dir> node scripts/daemon/run.mjs   # mint + mirror
   rm -rf <DAEMON_STATE>                                                        # the "cleared browser"
   I=<prepub> B=Sounditron OVERLAY=<dir> node scripts/daemon/run.mjs            # must NOT arrest
   ```
   Green = `w:Story` stands up and the heartbeat shows the same 🪪 prepub. Today it arrests.
- **`SwarmDisk` stays the unit proof of the lift** (the model layer, memnav). It is not a gate on any
   of the four above — every one of them is app glue it deliberately does not touch.

---

## 7. The production flow — browser provisions, share carries, daemon resumes (RULED 2026-08-07)

The owner, closing §6.6's open policy questions in one breath: *"it should exit with error if the
 given ?I hasn't been set up in the share by a browser client first. I think all the management
  happens in sessions of the account running in a browser, configuring Invites the usual way etc,
   then runs in the Daemon… it has to run into itself on the network, that's probably an error exit
    situation."*

Three rulings in that sentence, and together they make one flow canonical:

- **The browser is the management surface.** Minting, naming, Invites, grants — the existing
   surfaces, in a browser session of the account. Nothing new to build there.
- **The share is the hand-off.** `.jamsend/account/<prepub>/toc.snap` — which **recasts gap 1**:
   the write-through mirror is not robustness plumbing, it IS the provisioning channel. A daemon's
    identity comes into being *only* by a browser session having mirrored it.
- **The daemon only resumes.** `I=<prepub>` against the same share (or a copied account dir). It
   never mints, never hatches, never substitutes a stranger. Failure is an ERROR EXIT, not a hang.

### 7.1 The flow end to end, and which gap blocks each arrow

> **The client never types a `?I=`, and that decides which gap matters most (owner, 2026-08-07):**
>  *"the app itself, on most clients, will not know their ?I or ever use a ?B, it'll Book:Sounditron
>   under the hood."* Verified — `boot_qualand({book:'Sounditron', role:'sound'})`
>    (`BigQualand.svelte.ts:47-71`) stamps `book`, `boot_role:'runner'`, `id_role:'sound'`,
>     `assume_identity`, and derives `humdinger` from the role *"so no call site can forget it"*.
>      So **every real user is on the ROLE path**, which makes **gap 4 (§6.4) the one that bites
>       everyone**, not an edge case: a role-filed identity is invisible to its own `?I=<prepub>`.
>        `?I=` is a daemon/dev shape. The human reads the prepub off **DoorFace** (nick · prepub8) to
>         hand it to the daemon — which is another reason DoorFace is the identity surface (§7.4h).

1. **Provision** — a browser session mints and configures the identity (Invites, grants, friendly
    name) exactly as today.
2. **Mirror** — `Swarm_persist` writes the account into the share on a `Waft:Account` version bump.
    **This is gap 1** (§6.1): until it lands, no browser has ever created the file the daemon
     needs, and the flow has no first arrow.
3. **Resume** — the daemon boots `I=<prepub>`; `Swarm_boot_seed` adopts the keypair. **Blocked by
    gaps 2+3** (§6.2/§6.3): today this arrests even with a perfect account on disk.
4. **Stand the relationships up** — the piers/grants graft (§7.3). Without it step 3 yields a peer
    that can serve nobody.
5. **Run** — the daemon is the always-up twin of the browser session: same prepub, same Piers,
    answering heists and carrying radio while the laptop sleeps (`Daemon_todo`'s arc, "a
     Sounditron that can't be closed").

### 7.2 The arrest is an exit — LANDED (daemon-local, 2026-08-07)

`scripts/daemon/main.ts` `arrest_watch`: when `identity_pending` stands for >10s on an `I=` boot,
 the daemon fs-checks the account file directly (it is node; a diagnostic needs no nav) and exits:

- **exit 2 — config.** `.jamsend/account/<I>/toc.snap` absent in both overlay and share: no
   account here. *Provision it from a browser session first.* The operator's error, said plainly.
- **exit 3 — bug.** The account IS on disk and the seed still could not adopt it. Until gaps 2/3
   land this is the EXPECTED outcome of every `I=` daemon boot, and the message names this doc so
    nobody re-diagnoses a known hole.

The 10s grace matters for the post-gap-3 world: a *successful* seed will clear `identity_pending`
 in `Clustation_concrete`, so a slow disk read must not race the exit. Note what this does to
  §6.7's repeatable test: the red case is no longer "hangs with no Story" but a clean nonzero exit
   in ~25s, so it scripts.

### 7.3 What the ruling PROMOTES: the friendless restore is on the critical path now

For a browser recovering its key, keypair-only adoption is livable — the human re-invites. For the
 ruled daemon flow it is not: **grants gate `repli_allow`, so a daemon with the key but no %Piers
  serves nobody** — a peer with no relationships is not the Radiobuddies box the arc wants. The
   account snap already CARRIES piers + grants + the iz ledger (rungs 1–2, SwarmDisk-proven); the
    missing move is grafting the seeded vault's relationship tree into the live one and re-stashing
     it (`Swarm_restash_all`, which still does not exist — §6.6). So it moves from "beyond the
      four" to **step 4 of the flow**: land it right after gap 1, before calling any daemon
       production-ready.

### 7.4 Self-collision is a NEGOTIATION, not an exit — borrowing the identity (owner, 2026-08-07)

> **⚠ An adversarial pass (2026-08-08, five reviewers, every finding hand-verified) left the DESIGN
>  intact and the SIZING wrong in three places. Read these before planning any of it:**
>  - **§7.4b** — "the code already does this move" for a live address hop was FALSE. `Socket_real`
>     reads `sc.name`, not `Swarm_address`, and the signed relay layer structurally cannot express
>      `_N`. This is the largest piece, not plumbing.
>  - **§7.4d** — `%Sibling`/theft is **dead code with zero app-path callers**, not a mis-scoped
>     roster. Build-from-scratch, not lift-and-widen.
>  - **§7.4f/§7.4g** — the write lock gates the *file* and misses two live divergences above it; and
>     dormancy's latches sit on the **surviving root**, so a drop-the-tree teardown yields a
>      convincing zombie. Dormancy is `stop()`-then-reset, not a drop.
>
>  Nothing here says the architecture is wrong. `Daemon_todo` §8 is the full ledger.

The first ruling was *"it has to run into itself on the network, that's probably an error exit
 situation."* The owner then opened it up, and the better shape fell out: *"perhaps self-collision
  can just have a **disconnect** option? and then it waits on another suffixed address for us to
   come back… after using the actual address (and its Identity, on the network) to do something.
    so it's negotiating **borrowing the identity**"* — plus an *"**overthrow** option… which becomes
     **reinstate**"*.

So the collision is not an error. It is the daemon and a browser session **taking turns at the
 canonical address**, which is exactly what the flow needs: management happens in the browser
  (§7), and management means being reachable where your peers actually write — the bare `<prepub>`.
   An error exit stays as the fallback for when nobody is there to negotiate with (§7.2), and the
    unattended box still must never hang.

**And it fits the box we already have.** `Swarm.g #region places` is titled *"one key, N
 addresses"* and models precisely this split: `ident.sc.prepub` is the immutable key-derived NAME,
  `peering.sc.address` is the session address, bare is primary and `<prepub>_N` is a non-first
   place. `Swarm_steal_back` already *"concedes the contested name and re-presents at the next free
    suffix, SAME key, so your Piers still verify you (a page's `pub` is the truth; the address is
     only where you're reachable this session)"*. The three verbs are that one primitive at three
      polarities:

| verb | who moves | primitive |
|---|---|---|
| **disconnect** | the incumbent yields, asked politely | `Swarm_steal_back` shape, on request rather than on alarm |
| **overthrow** | the arriver takes bare; the incumbent is pushed to a suffix | same jump, forced rather than consented |
| **reinstate** | the borrower hands bare back | **MISSING** — see below |

**`reinstate` is the one genuinely new primitive, and it is small.** `Swarm_steal_back` is
 *monotonic*: `Swarm_next_suffix` only ever walks FORWARD to the next free `_N`, so nothing in the
  tree ever returns to the canonical address. But `Swarm_address` reads
   `peering?.sc?.address ?? peering?.sc?.name` — so reinstating IS dropping `sc.address` and
    letting it fall back to the name. Use a C method rather than a raw `delete` (CLAUDE.md's
     snap-consistency rule) and it is a handful of lines. That the UI verb flips overthrow →
      reinstate is the right read: they are the same control, and the second is the undo of the
       first.

**Two properties this inherits for free, both load-bearing.** The key never moves, so Piers verify
 throughout — a borrow is reachability, never agency. And the whole address layer is already
  SESSION-LOCAL: `stolen`/`address`/`role` and the `%Sibling`/`%Stolen` husks are omitted from
   every export (`Swarm_protocol`, Swarm.g:2048), so a borrow arrangement can never leak into the
    account snap. *"A backup is the canonical identity, never a moment's reachability."*

**What is NOT built: any of it is wired.** `Swarm_address`, `Swarm_next_suffix`, `Swarm_sibling`,
 `Swarm_is_sibling`, `Swarm_note_theft`, `Swarm_stolen`, `Swarm_steal_back` have **zero callers
  outside `Swarm.g` itself and the `SwarmSteal` Book** (verified 2026-08-07). It is a designed,
   Book-proven, entirely unwired mechanism — **the same shape as gap 1**: the model layer is right
    and nothing calls it.

#### 7.4a Can the relay mediate this? — ingredients yes, mechanism no

**It has the hard part.** `handleHello` (`relay.ts:381`) verifies a self-signature over the hello
 header and binds `prepubOf(pub)` only for the real key-holder — so **the relay is the one place
  that can tell "another instance of me" from "a thief" across machines.** That is the
   discriminator `Swarm_is_sibling` structurally cannot be: `%Sibling` comes from a Dexie
    liveQuery of *this browser's* tabs, so a daemon on another box is a thief by construction. The
     relay can prove co-identity cryptographically. It also has `sendControlTo(addr, …)` — the
      channel to say *"you have been asked to disconnect"* — and it already implements
       exclusive-name refusal for multicast channels (`claim_error`, `reason:'taken'`, `:323`).
        The pattern is written; it is just pointed at `@channel`s and not at addresses.

**What it lacks is exclusivity itself.** `bind(addr, ws)` is `Map<addr, Set<WebSocket>>` — purely
 additive, no refusal, no notice to the incumbent — and `deliverLocal` fans out to **every** socket
  in the set. Two claimants on one address therefore both bind and both receive every frame. That
   is the collision, and it is silent; it is also the mechanism behind the daemon's observed
    `channel DEAD — 20s silent` twice (`Daemon_todo` §4). Note `prepubOf(pub)` is *derived*, so a
     second honest instance lands on the same addr by construction — the authenticated layer
      duplicates rather than collides.

Three more gaps to carry in before designing the frames:
- **`?addr=` is unauthenticated by the relay's own admission** (*"any socket can open ?addr=BOB"*),
   so a disconnect/overthrow request must ride the signed `hello` layer. An unsigned "please step
    aside" is an eviction primitive for anyone who can reach the relay.
- **No unbind-on-request** — `unbind` fires only on socket close.
- **`locals` is per-relay, and there is an r2r bridge.** `routeFromBrowser` tries local first and
   only then the bridge, so two instances on *different* relays may never collide at all: they
    silently split the traffic, each serving its own side. Cross-machine detection cannot be one
     relay's map alone.

#### 7.4b Does the socket survive an address change? — the RELAY can; the CLIENT cannot ask

The owner: *"it can hold on to the same websocket connection per Pier while they change address
 hopefully?"*

**Relay side: yes.** The address is a label attached to a socket, never the socket's identity — a
 socket already tracks a SET of addresses it answers to
  (`((ws as any).bound ??= new Set<string>()).add(addr)`), and the multicast `subscribe` path
   re-binds a *live* socket to new names at runtime: *"bind() into `locals` IS the subscription —
    deliverLocal then reaches us on every publish, no routing change."* So `bind`/`unbind` are map
     ops and a hop need not tear down a channel. Without that the idea would be unaffordable.

> **⚠ CORRECTION (2026-08-08, adversarial pass — found independently by two reviewers). This
>  section previously said "and the code already does this move." That was WRONG** and it
>   understated the work by a lot:
>
> - **`Socket_real` reads the wrong field and captures it.** `Ghost/N/Tribunal.g:63`:
>    `let addr = (peering && peering.sc.name) || ''` — `sc.name`, the canonical name, **never**
>     `Swarm_address()`/`sc.address`. The URL is built once from it, and every auto-reconnect
>      re-dials that same stale URL. A `steal_back`/`reinstate` mutation is invisible to the wire.
> - **`unbind` is never called to MOVE a socket** — only from `unsubscribe` and close cleanup. The
>    subscribe precedent is *additive*, not a move. There is no live re-bind primitive either side.
> - **`handleHello` can only ever bind bare `prepubOf(pub)`** (`relay.ts:388`) — and that is not an
>    oversight, it is the security property: the addr being a deterministic function of the *proven*
>     key is exactly what stops a captured hello claiming someone else's address. So the signed
>      layer **structurally cannot express `<prepub>_N`**, and making it session-aware needs a NEW
>       signed "I am now at `_N`" primitive the relay verifies — not a field swap. `Lies_self`
>        (`LiesLies.svelte:649`) derives from the pub the same way and feeds advertise/ping/pong.
>
> **So "reinstate is a handful of lines" is true of `Swarm.g` and false of the system.** §7.4c
>  item 5 undersold this; it is the largest piece of the borrow, not plumbing.

**And a hazard this section missed: the address is the mailbox, so replies chase the address, not
 the asker.** Routing is keyed to the bare canonical name with no session token, so an ask issued
  just before a hop has its **reply delivered to whoever holds bare when the reply lands** — a heist
   pick or a Repli page answer straddling a hop ends at `Peeroleum.g:617`'s *"no Pier for … —
    DROPPED"*. `Repli.g:498` makes it concrete: it caches `p.c.reply_to`/`reply_from` off an inbound
     header for later `repli_parked`/`repli_missed` replies. Any hop needs a quiesce-in-flight step,
      or an accepted loss window. This is a property of the addressing model, not a bug to sweep up.

**The catch is not the socket, it is the peers' outbound `to:`.** Frames route by `header.to`, so a
 Pier that still writes `to:<bare>` reaches whoever holds bare *now*. During a borrow that is the
  borrower — **which is the entire point**: the browser takes the actual address precisely so the
   Invite redeems and pings land on it. The daemon at `_1` keeps every live socket and every sealed
    channel, and only new inbound-addressed-to-bare goes to the session. So the mechanism does the
     right thing almost by construction; what it still owes is **telling the Piers**, signed, when a
      place moves — otherwise a hop is only correct for peers who happen to re-resolve.

#### 7.4c What is owed, in order

1. **`Daemon_todo` §4 first** — none of this is reachable while the daemon claims `addr=runner` and
    collides at the *role* layer before the identity layer is ever consulted.
2. **Relay: make an address exclusive and say so** — refuse-or-notify a second bind, reusing the
    `claim_error`/`taken` pattern, on the `hello` (signed) layer only. Shared ground, with the human.
3. **`Swarm_reinstate`** (drop `sc.address` via a C method) + a `Swarm_yield`/`Swarm_overthrow` pair
    naming the two polarities of the existing jump. Model layer, cheap, and `SwarmSteal` is the
     Book to extend — it already proves the suffix ladder in 6 beats.
4. **The cross-machine sibling roster** (§7.4d) — `%Sibling` fed by the relay's verified `hello`
    instead of the Dexie tab liveQuery, so a serial-numbered place JOINS rather than contests.
     Do this before the control: it decides how much of the control is even needed.
5. **Wire the address layer at all** — it has no callers today, so `Swarm_address` needs to become
    what `Socket_real`/`LiesLies` actually dials, and a signed place-moved frame needs to reach
     Piers.
6. **The write lock** (§7.4f) — gate `Swarm_persist` on holding the canonical address, and make a
    reinstate re-read from disk before it may write. Small, and it is what closes two-writers.
7. **Daemon dormancy** (§7.4g) — teardown to `H:Mundo` and back, with an era guard and a named
    latch-reset list. The biggest single piece here, and the one `reinstate` cannot do without.
8. **The UI** — DoorFace swells with the places list + the disconnect / overthrow / reinstate
    control (§7.4h). Not the IdHatch. Wants the owner's eye; a snap cannot carry it.

#### 7.4d The extras are SERIALS, and every place of one Identity is connected (owner, 2026-08-07)

*"we could just serial number the extras and connect all nodes of one Identity together."* This
 reframes the whole thing and simplifies it: `_1`/`_2` stop being **exile** (where `Swarm_steal_back`
  sends a victim) and become **serials** — the extras of one federated self, all linked. The
   canonical address is the front door, not a throne.

**Which collapses "theft" into cross-machine siblinghood.** `%Sibling` already models cooperative
 co-holders that *split the work* — `Swarm_take_role` (music | encode | serve), Book-proven at
  `SwarmSteal` beat 3 (*"sibling tabs of one key cooperate — no theft alarm — and split the work"*).
   The design: the roster becomes **relay-verified rather than local** — the signed `hello` (§7.4a)
    proves same-key, so a place either can prove the key (sibling, gets a serial, joins the
     federation) or cannot (genuine theft, `Swarm_note_theft` and the banner). **The discriminator
      becomes cryptographic instead of local-storage-shaped**, which is the honest version of the
       call the existing code wants to make.

> **⚠ CORRECTION (2026-08-08). This section said "it IS siblinghood — the roster is just scoped
>  wrong." That is not right: the roster was never wired AT ALL.** `Swarm_sibling`,
>   `Swarm_is_sibling`, `Swarm_note_theft`, `Swarm_stolen` (`Swarm.g:2279-2315`) have callers only
>    inside `Swarm.g` itself and the Story Books — **zero app-path callers**. So today no tab ever
>     registers as anyone's sibling, and a genuine stolen-key collision raises **no alarm in the
>      running app**: `Swarm_note_theft` is invoked nowhere but a fixture, so `Swarm_stolen`'s banner
>       gate is permanently false in production. The Dexie-liveQuery-of-this-browser's-tabs framing
>        (`Swarm.g:2254`) is a *comment describing an intent*, not a running mechanism. **There is no
>         local behaviour to widen — this is build-from-scratch, not lift-and-widen.** The design is
>          unchanged and still right; the sizing was wrong.

Roles then distribute across machines for free, which is the point of the daemon: the box takes
 `serve`, the session takes management. That is `Swarm_take_role` doing what it was written for,
  one address ladder wider.

**Open, and possibly a simplification worth having:** if every place is connected, does an arriving
 session still *need* the bare address? An Invite redeem landing at bare could be handed to whoever
  currently holds the management role. If the federation routes internally, **overthrow becomes rare
   rather than routine** — the borrow stays for the cases where a peer must genuinely reach *this*
    place. Do not design this until the roster is real; noting it because it may shrink §7.4c.

#### 7.4f THE CANONICAL ADDRESS IS THE WRITE LOCK — and it closes the two-writers hole

The owner, seeing it: *"more to the point this acts as a **lock on the persisted Identity** etc
 we're trying to change! lovely."* **Yes — and this is the thing that makes the whole design pay.**

**The rule: only the place holding the bare `<prepub>` may write `.jamsend/account/<prepub>/`.**
 Serials are readers. That closes §6.6's *"two writers, one file, no merge"* — which nothing else
  in this doc closed, and which I had written up as still open one revision ago. It costs no new
   mechanism: the token is an address that already exists, is already exclusive-by-intent, and is
    already the thing the arriving session wants for reachability anyway. Reachability and write
     authority turn out to be the same claim, which is why *"management happens in the browser"*
      (§7) and *"the browser takes bare"* were always the same sentence.

It also explains the *third* address the owner names: daemon at bare, session arrives at `_1`, and
 on disconnect the daemon must jump past `_1` to `_2` before the session can move up to bare. That
  is exactly `Swarm_next_suffix(prepub, taken)` — *"jump past all of them"* — and `SwarmSteal` beat
   5 already proves precisely this hop (past thief + siblings `_1`/`_3` → `_2`).

**Does the daemon have to shut down? No — and not needing to is the point of having an address
 layer at all.** Three graded releases, of which shutdown is only the crudest:

1. **Hop only (the design).** The daemon keeps running, keeps every open socket and sealed channel
    (§7.4b), keeps serving radio and heist off its shelf — it just sits at `_2`, stops taking new
     inbound at bare, and **stops being allowed to write the account.** It remains a useful peer
      throughout. The gate is one condition on the existing call:
      `Swarm_persist` only when `Swarm_address(ident) === ident.sc.prepub`.
2. **Hop + quiesce.** If the daemon has anything account-mutating in flight, it finishes or drops
    it before conceding. Nothing today does — see below.
3. **Dormancy — down to `H:Mundo`, chucking out everything** (the owner's *"quite totally shut
    down"*, clarified: *"like down to only H:Mundo, drastically chucking out everything… and later
     bringing it back"*). The strongest release short of dying, and §7.4g is why it is probably the
      one to build.
4. **Process exit.** The only option available *until* the address layer is wired at all (§7.4c),
    so it is what the human does today — and `arrest_watch` already gives a daemon a clean way to
     go. But see §7.4g: **exit is incompatible with `reinstate`.**

**The daemon is nearly a read-only holder already**, which makes gate 1 small: `persist_account`
 (`main.ts`) is throttled by a `persisted` Set to **once per identity per boot** — the daemon writes
  the account at startup and never again. So the lock it holds is today almost nominal. Note the
   direction of travel though: gap 1 wants the app's mirror to be *bump-driven*, and an invite
    redeemed **at** the daemon (redeems land at whatever address the peer wrote to) would mutate its
     account — which is itself the argument for the session taking bare before doing management.

**The one real hazard the hop does NOT solve: a stale reader reclaiming.** The daemon and the
 browser hold separate caches (its `dexie-node` state dir, the browser's Dexie) over one disk
  record. While the session holds bare and changes the account, the daemon's in-memory copy goes
   stale. If it later reinstates and writes, it clobbers exactly the changes the borrow existed to
    make. **So reinstate must RE-READ from disk before it may write again.** This resolves the
     long-standing DECIDE in §5 audit item 3 (*"OR make disk authoritative … Decide at the two-tab
      test"*): at a reinstate, **disk wins** — not as a general policy, but because a borrow is a
       declaration that someone else changed it. Everywhere else the §2 stream rule stands
        (disk→Dexie only when Dexie is empty).

**Say out loud that the lock is advisory.** `.jamsend` is owner-local and every place here IS the
 owner, so nothing physically prevents a serial from writing the file — the discipline lives in the
  code that honours it. That is acceptable for one person's own boxes and should not be mistaken
   for a guarantee against a modified client.

> **⚠ THE LOCK GATES THE FILE, AND TWO DIVERGENCES HAPPEN ABOVE IT (2026-08-08).** Both are real
>  today and neither is covered by §7.4f as written:
>
> - **The Dexie `stashed` race — live NOW, no daemon required.** `Swarm_pier_stash`
>    (`Swarm.g:1315-1337`) does an unguarded read-modify-write of
>     `top_House().stashed.Swarm_piers`; `Housing.svelte.ts:423-437` throttle-saves the **entire**
>      `stashed` blob to one Dexie row keyed by House name; and the cross-tab liveQuery subscriber
>       (`:449-477`) does a hard **full-object replace** on any foreign write — no merge, no per-key
>        CRDT. Two tabs of one identity each sealing a different Pier inside one throttle window:
>         the loser's Pier vanishes silently when the winner's write round-trips. This is upstream of
>          any file write and ungated by anything. **It is the oldest two-writers bug in the system
>           and it predates the daemon entirely.**
> - **The invite spend ledger gets a second writer** the moment the daemon answers redemptions
>    (which is the owner's stated purpose for it — *"minting Grants for the clients that come along
>     with them"*). `%Idzeug` records carry `sc.spent`, `Swarm_hello` spends the nonce and refuses
>      the replay, and those records live under the `%Peering` — **so they ride the account snap.**
>       A browser that minted the invites never sees the daemon's `spent` flags, and last-write-wins
>        can **un-spend a spent invite**. Single-use is a security property. See `Daemon_todo` §8.1.
>
> So the write lock is necessary and not sufficient. What it buys is that the *file* has one writer;
>  what still diverges is each place's *live tree*. Either the ledger becomes single-writer by
>   construction (only the bare-holder answers redemptions — which the lock already implies, if
>    honoured) or it needs a real merge. Decide before the daemon answers its first invite.

#### 7.4g Dormancy — down to `H:Mundo`, and later bringing it back

*"the Daemon would have to quite totally shut down…? like down to only H:Mundo, drastically
 chucking out everything… and later bringing it back."*

**The design forces this, it is not merely the tidiest option: a dead process cannot be
 reinstated.** `reinstate` is a handshake, and a handshake needs a listener — if the daemon exits
  on conceding, nothing is there to hand the address back to and a human must go and restart the
   box, which is exactly the manual step the whole daemon exists to remove. So *hold until told*
    (§7.4h) plus *reinstate* (§7.4) together imply the daemon must **survive its own concession**.
     Dormant-but-listening is the only shape that satisfies both.

**What stays up:** the crank loop, the status port (so a dormant daemon can still be asked what it
 is — the diagnostic that does not share a failure mode with its subject, `Daemon_todo` §1), and
  enough presence at its serial to hear "reinstate". **What goes:** everything above the root — the
   worlds, the actors, the ghosts' deposited state, the whole standing machine.

**What the teardown buys, and it is the answer to §7.4f's hazard:** with no in-memory account left,
 there is nothing stale to clobber with. The re-standup *is* the re-read. That is a much better
  property than trying to invalidate a live tree in place.

**What it does NOT buy, and this is the trap:** `H:Mundo` going bare does not clear **Dexie**. The
 shim's state dir (and a browser's IndexedDB) survives any teardown short of deleting it — and
  §6.0's *designed* behaviour is peek-Dexie-first, return on a hit, disk only on a miss. So a
   re-standup would resume the **stale cached identity from its own cache and never look at
    disk** — the borrow's changes silently lost, by the book. **The reinstate re-read must therefore
     be explicit**, not a consequence of the teardown: drop the `identities` Thang row for this
      prepub as part of conceding, or take §7.4f's disk-wins-at-reinstate rule directly. This is the
       same shape as every bug in this doc — the cache-first read is correct for a normal boot and
        exactly wrong for this one moment.

**The cost is the latch surface, and it is the real work.** The machine is built to stand up once,
 so its "don't re-scan" one-shots are everywhere and every one of them is correct for a boot and
  wrong for a second standup. In `Auto.svelte` alone: `identity_up`, `identity_adopted`,
   `identity_default`, `identity_seed_tried`, `identity_seed_since`, `identity_pending`,
    `creduler_up`, `ac_hooked`, `boot_role`, `keep_awake_shown`. Daemon-side: `began`, `keyed_done`,
     `persisted`, `wrapped`, `_daemon_nocyto`. A re-standup needs an explicit reset list, several
      entries of which live in shared code — so this is a with-the-human job, and the list wants to
       be derived once and *named in one place* rather than rediscovered each time something fails
        to come back.

> **⚠ WORSE THAN THAT, AND IT DECIDES THE SHAPE (2026-08-08).** Two findings that turn the latch
>  list from a chore into the design constraint:
>
> - **The latches live on the surviving root.** `H.c.creduler_up`, `H.c.identity_up`,
>    `H.c.identity_adopted`, `H.c.identity_default`, `identity_pending` are all stamped on the **top
>     House's own `.c`** — which by definition survives "chuck out everything under H:Mundo", since
>      `.c` belongs to Mundo, not its children. A rebuild that recreates `A:Auto`/`A:Clustation`
>       fresh finds every latch already true and **skips every bootstrap step against the now-empty
>        tree**: the daemon comes back crank-running and HTTP-answering, permanently identity-less
>         and Story-less. Daemon-side `began` and `keyed_done` are module-level `let`s with no reset
>          path at all, so `may_begin` would never fire again either. **A dormancy that only drops
>           the tree produces a convincing zombie.**
> - **Dropping references is not teardown — it leaks a timer per House per cycle.** Every
>    `Housing` (including every subHouse) owns an `$effect.root(() => this.start())`
>     (`Housing.svelte.ts:204`), and `start()` (`:557-570`) registers a literal
>      `setInterval(stuffing_heartbeat, 3000)` plus a Dexie `liveQuery` subscription (`:449-477`),
>       both released **only** when that root is disposed via `stop()` (`:189-195`, propagated to
>        children at `:575`). **Nothing in `scripts/daemon/` ever calls `.stop()`.** So the obvious
>         implementation — drop the C-tree references — leaves each discarded House's 3s interval
>          ticking forever (un-GC-able: the closure holds `this`) with its subscriber pinned in
>           `dexie-node`'s module-level set. N dormancy cycles = N live-forever timers on dead
>            Houses.
>
> **So dormancy is `stop()`-then-reset, in that order, with a named latch list — not a drop.** The
>  good news is `stop()` already exists and already propagates; the work is calling it, and owning
>   the reset list. `unwatch_owner`'s `dead` era guard (`:1678`) remains the right pattern for
>    keeping an in-flight pass from writing into the new tree.

**Two things in our favour.** There is precedent for owner-scoped teardown — `unwatch_owner`
 (`Housing.svelte.ts:1678`, *"tear down every handler this owner placed — the owed
  teardown-on-decommission"*) — and it carries the pattern that matters: a **`dead` era guard set at
   teardown**, so an in-flight pass from the old era cannot write into the new tree. And the daemon
    owns its own pass boundary (its crank IS the pump, `Daemon_todo` §3.3), so it can tear down
     *between* drains rather than out from under a held beliefs mutex — which a tab, driven by
      svelte's scheduler, cannot do. Tearing the tree out mid-pass is the classic way to
       manufacture a wedge; the daemon is the one place with a clean seam to do it at.

**Bonus worth measuring, not assuming:** a dormant→standing cycle should be far cheaper than a cold
 boot, because the ~12s of vite transform (`Daemon_todo` §5.3) is already paid and the module graph
  stays warm. That would make reinstate feel instant next to a restart. Unmeasured.

#### 7.4i The lock is a DISTRIBUTED lock — what it covers, and its three bounds (2026-08-08)

The owner, naming it: *"they effectively lock writes to the shared disk via asking who of themselves
 is online right?"* — **yes, and that is the whole of it.** "Who holds the canonical address" is a
  question you ask the **relay**, so this is not a filesystem lock; it is a liveness query against the
   federation, and **the relay is the lock manager.**

**Why it is sound rather than bolted on.** An invite token names `<prepub>`, so a `pier_hello` routes
 to whoever holds bare. **Whoever receives redemptions is necessarily whoever must write the spend.**
  The lock is not an added rule — it is the observation that those two are the same place. Any design
   where they differ is already broken. Same for a rename, a grant, a sealed Pier: the mail and the
    write follow one address.

Three bounds, none fatal, all better written down than discovered:

1. **It only means anything where the places SHARE A FILESYSTEM.** Daemon and browser on one box over
    one share: the lock does real work. Daemon on a **different box** holding a copied
     `account/<prepub>/` dir: there is no shared file, so "last-write-wins on the snap" does not even
      apply — they are two divergent ledgers **by construction**, and no address-based lock can reach
       that. The invite spend ledger (§7.4f) is the worst case of it. **Rule the cross-box case out
        explicitly, or give it a real sync; do not let the lock imply a safety it cannot provide.**
2. **There is no fencing token.** A place whose relay connection has died without it noticing (the
    half-open socket this repo already knows well) still believes it holds bare, and can still write
     local disk — the relay cannot stop it. The standard cure is a monotonic epoch issued by the lock
      manager and checked at the write; the design has none today. Cheap to add later, cheaper to
       design in now.
3. **Relay-down freezes the lock where it stands.** With "hold until told" (§7.4h) nobody can take
    the address from an incumbent that cannot hear, which fails **safe** (no new writer). But the
     converse: a **first** boot with no relay never acquires bare, so it may never mirror its account
      — which for a daemon whose job includes mirroring is a real case wanting an answer.

**Are we safe today? Yes, structurally, and for a reason worth recording:** the r2r bridge is
 runner-dev-server (`:9091`) ↔ editor-dev-server (`:9092`) — a *development* pairing, not a
  peer-serving mesh. Every player tab is on one relay, so the lock manager's view of an identity's
   places is complete. §7.4a's cross-relay hazard is **latent**: it becomes real the day a second
    peer-serving relay exists, and it aims at the LOCK (two places each believing they hold it), not
     merely at routing. That is the sentence to remember when someone proposes a second relay.

#### 7.4h Ruled: hold until told, and DoorFace is the surface (owner, 2026-08-07)

**The incumbent HOLDS.** *"holds until told to disconnect, I think."* No auto-yield on a verified
 self-claim. So an unattended daemon can never be silently displaced — the right property for a
  server, and it means an arriving session gets a serial and works from there rather than
   interrupting anything. The burden lands on the arriver to ask, which is also where the human is.
    Overthrow is therefore **always an explicit gesture**, never a race.

**The surface is `DoorFace`, NOT `IdHatch`.** *"the Identity|share panel should swell up about the
 situation (not the Id hatch — that's not going to be regular app user's experience)."* The split is
  already in the code and this ruling just holds it: `IdHatch` is a Lens `Panel` Funkcion popped by
   the identity ARREST — a recovery/dev surface a normal user should never meet — while
    `DoorFace.svelte`'s own header calls it *"WHO AM I and WHO'S WITH ME, floating in the glass: the
     identity + front-door arc as the **prioritised, for-the-user's-eyes** face"*. Two places of one
      identity is precisely a new kind of *who's with me*, so it belongs beside the self / door /
       friends it already shows — a fourth part: **places**.

**"Swell" is the house idiom, and it is the right one.** The glass grows a cell to communicate
 rather than confessing a count or popping a modal (Voro's *"swell the cane"*; the growth spell
  *"heal by GROWING, not by confessing a count"*). So DoorFace **grows** when the identity has more
   than one place — showing each place, its serial, which holds the canonical address, and the
    disconnect / overthrow / reinstate control — and shrinks back when there is only one. No modal,
     no badge, no arrest. Face work, so it is pixels-or-it-didn't-land and wants the owner's eye.

### 7.5 The sittings — the carry-out, in §6.5's order

1. **Auto.svelte, one sitting, with the human** — gaps 2+3+4 (§6.2–6.4). Three small edits in one
    file, all inert-or-safe today; gap 3's fix site (`Clustation_concrete`) is the same chokepoint
     gap 4 touches, and gap 2's fix is the retry idiom already at the top of the same function.
      Proof: §6.7's daemon test — the `I=<prepub>` reboot stands `w:Story` with the same 🪪
       prepub, exit 0.
2. **Gap 1, with the human** (§6.1) — the bump-driven `Swarm_persist` call from Auto: refuse a
    remote nav, never per-tick, fire on a `Waft:Account` version bump. Proof: the two-tab
     fingers-test (the FSA gate no Book can buy) — and from then on the daemon test runs on a
      BROWSER-provisioned account, which is the ruled flow itself.
3. **The piers graft** (§7.3) — `Swarm_restash_all`, or disk-authoritative-when-newer (the §5
    audit item 3 DECIDE; decide at the two-tab test). Proof: reload #2 keeps friends; the daemon
     serves a granted Pier.
4. **The borrow** (§7.4) — after `Daemon_todo` §4, in §7.4c's order: relay exclusivity on the
    signed layer, then `Swarm_reinstate` + the two polarities, then wiring the address layer up at
     all, then the control. Shared ground (`relay.ts`), with the human. Note this one is a v1.1:
      nothing in §7.1's flow needs it, it makes the flow *pleasant* rather than possible.

Already landed, daemon-local, no human needed: the arrest exit (§7.2).
