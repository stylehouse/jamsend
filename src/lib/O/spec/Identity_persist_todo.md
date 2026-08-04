# Identity_persist_todo.md — Identity ↔ Thing/Thang ↔ `.jamsend` persistence

The "big deal" thread (the human, 2026-07-27): *"getting Identity to be persisted in the .jamsend dir
 per Identity, and knowing which is the 'main one' if a browser with no Thang (dexie) state inits with
  FSA that does persist state."* This doc is the state-of-the-world (two code surveys, 2026-07-27) +
   the build plan. Parallel to the compact-invite cut (`Swarm_compact_invite_todo.md`), touching none
    of its seams.

## 0. State — BUILT + GREEN (2026-07-27) · SEAM CUT, AWAITING ITS LIVE PROOF (2026-08-04)

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
