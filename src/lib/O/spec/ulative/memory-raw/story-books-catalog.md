---
name: story-books-catalog
description: "What each Story Book in the Library (wormhole/Present) tests — families (incl. the Lake editor-machine family), husks, real-vs-fixture includes; informs the Credence board"
metadata: 
  node_type: memory
  type: reference
  originSessionId: dc62107d-01fe-4c0b-a98b-7945459762a0
---

The Library (`wormhole/Present/toc.snap`) lists the Story Books; each is recorded at
`wormhole/Story/<Book>/`. Intent fingerprinted by toc.snap `Styles` (matstyle:<key>) +
step `see:`/`section:` narration + the `Doc:`/`Waft:` it references. Only Peregrination
has a `.g` (the `.g` IS the Book); the rest are older recorded Stories. **Dispatch is by
name**: `story:<Book>` → `Run_A_<Book>` in test/Machinery.svelte (Story.svelte:1142).
Renaming a Book ⇒ rename its dir + Library `Book:` entry + `story:` line + `Run_A_` method
+ any hardcoded path (e.g. Diffmatication `WH_PATH`). Library is live-rewritten by the app.

**Real-code Books** (subject = production code; include Ghost/N/* + Ghost/Story/Peregrination.g):
- **Peregrination** — p2p transport Book (real Peeroleum/Tribunal; PeerJS/Socket/ws fallback,
  the LakeNetherland trial). Declares w:Peregrination + w:Peeroleum. TODO (deferred phase):
  → Book:NetActivities / w:NetActivities.
- **Editron** — NOT a real regression test: uses the Story machinery to *host the app* for
  self-analysis + restartability. Includes the real trio.

**The Musu\*/Ra\* family** (the Radiobuddies music-piracy Books — the MAIN spring; all `.g`, in
`Ghost/Story/{Musuation,Radiation,Heistation,Berthation,Swarmation}.g`). **Dispatch is by WORLD
NAME, not `Run_A_`**: the world MUST be named after the Book (`do_fn_for` reads `w.sc.w` →
`MusuHeist(A,w)`), so a sibling Book is just another `Musu*(A,w)` entry in the same `.g` — no new
ghost/registration. Register in `wormhole/Credence` (`Funkcion:Storying,of_Book:X`) or it's invisible.
Heistation.g holds MusuHeist (heist→magazine, needsFSA), MusuVend/MusuDoor (grant-gated), MusuCursor/
Heal/Resume/Rename (the `%Dogear` cursor arc), MusuRecast/Standing, and **MusuBreach** (2026-07-15 —
the rung-0 per-chunk-cid gate PROVEN adversarially: honest land vs one poisoned chunk → localized breach,
[[rung0-per-chunk-cid]]).

**The Swarm\* family** (`Ghost/Story/Swarmation.g`, world-name dispatch, seeded keys + pinned clock —
total determinism). The social/identity side: SwarmStaple (identity+grant crypto, model layer),
SwarmWire/Door/Got/Policy/Share (handshake+door over loopback/mock), SwarmSteal (one key many places),
SwarmInvite (QR redeem), SwarmChain (re-assignable ReInvite chain), SwarmBlotter (one-time serial sheet),
SwarmSpoof (the prepub-forgery security gate), and **SwarmDisk** (2026-07-27, 7 beats green×2 — identity
persisted to owner-local `.jamsend`: seal→persist(keypair embedded)→fresh-browser reseed→multi-owner ?I=
pick→write-through update + %NotGrant tombstone across disk; uses an in-memory nav double, no FSA needed).
See [[identity-thing-jamsend-track]], [[compact-invite-cut-built]].

**The Lake\* family** (editor/LE-machine tests — they edit fake fixtures; an old note
mislabelled them "p2p net scenarios", wrong). Renamed 2026-06-20 so the editor family sorts
together; all five now pending re-record:
- **LakeSurfer** — opens a Waft, surfs it.
- **LakeNets** — LE mark/operate: add a focus Point, mark specs.
- **LakeFlush** — cursor + LE mark + push-back (flush).
- **LakeTiles** (was **LangTiles**) — LangTiles DSL/peel-syntax compiler
  ([[langtiles-peel-syntax]]); own Cyto game; heaviest. (The DSL stays "LangTiles"; only the
  Book renamed.)
- **LakeSurprise** (was **InterestLive**) — the live **Interest channel** gate
  ([[interest-channel-graduated]]): Lang_foreground per Waft + GhostList, Lang_sprout_sidetrack,
  Trail/Sidetrack/GhostList/Ting coexisting across the wire, NaviCado lens-switching. UItime
  sibling of Editron (Atime); both ride %subscribe (Waft_spec §201). Its apparent N/* includes
  were GhostList-listing noise, not real includes.
- Shared fixtures at **Ghost/test/Story/Lake/**: LakeAntecedents.g (infra stub, was
  test/Peeroleum.g), LakeAmeliorations.g (test-layer stub, was test/Story/Peregrination.g),
  LakeTiles.g (was test/LangTiles.g), Idzeuzia.g. Deliberate minimal stubs, NOT copies of
  production (test/Peeroleum.g was a 1-liner vs N/Peeroleum.g's full ghost).

**Other substantive Books (the Credence board, [[editron-verdict-phase2]]):**
- **Leaf\*** (LeafFarm, LeafJuggle) — the DEFAULT_BOOKS (Auto.svelte); Cyto/useCyto users
  ([[cyto-opt-in-usecyto]]).
- **Port\*** (PortPlan, PortPlanet, PortPlant) — req/De machinery scenarios.
- **Stuff\*** (StuffFlipping, StuffResolving) — the C/particle data-model core (Stuff.svelte/TheC).
- **Understand\*** (Understandium/-ication/-ity) — Understanding/LE Seem spheres (arm/pull/
  repull/fork/encode-compare; wander/Sidetrack + push-back). -ication is most advanced.
- **Mundane\*** (MundaneStation: req determinism + ttl over a media tree
  [[mundanestation-ttlilt-determinism]]; MundaneStaying: persistence across ticks).
- **TextInca** — enLine encode + mainkey_match primitives. **Snaptesting** — Lines codec
  round-trip. **Snapmigrating** — snap migration. **ReactiveWaft** — Waft reactivity + loopy/hid.
- **Diffmatication** — doc diff/match engine; reads the LakeTiles Book snaps as its fixture
  (`WH_PATH='Story/LakeTiles'`).
- **VytoStaple** (`Ghost/V/Vytonation.g`, GREEN ×2 2026-07-20) — the new glass's first Book
  ([[yore-moment-spool]]): commission Vyto beside a run → grapple-watch stir → mirror
  morph-in-place + two-stir departure grace → settle moment with a snap_H payload on Vyto's
  own Se. World named after the Book; on the Credence board. Gotcha it proved: a Story-run
  House quiesces under ttlilt hold, so Books driving the watch must nudge `main()` while
  polling.
- **VytoCell** (Vytonation.g sibling, GREEN ×2 2026-07-20) — the M3 gate: three dosed cogs
  grappled INDIVIDUALLY (each grapple = one top-level mirror row = one cell) cut into
  distinct cells; express orders sizes by dose; unchanged world grants no motion (T
  byte-identical, EPS=0.5); pointer-pin holds a seat while the world rearranges; released
  hold eases free and retires. Beat 5 calls `Vyto_stir` DIRECTLY (the watch chain is
  quiescent under ttlilt).
- **VytoMitosis / VytoRadio** (Vytonation.g siblings, GREEN ×2 2026-07-20) — the main two
  Voro Books ported as client-shaped TEACHING examples for the Radio display-refactor
  agent (a commented Vyto client kit rides beside them in the .g). Mitosis: a dosed flora
  grows (lone newcomer + batch rim-spread), a genus goes extinct (departing escort +
  re-seat), fixed point. Radio: the six-genus tuner flora drifts its doses (express
  re-sizes, solve re-seats) and the hand pins one cell mid-drift then eases it free — the
  tenant rehearsal. Client onboarding doc: `spec/vyto_workingouts/client.md`.
- **VytoTandem / VytoFreeze / VytoSeek** (Vytonation.g siblings, GREEN ×2 2026-07-20) — the
  owed-engineering trio's proof Books. **VytoTandem**: watch_c isolation — two watchers
  (a plain hand owner + a Vyto grapple = glass world) ride one C; one bump fires both (the
  old (House,C) dedup dropped the second), then Vyto_decommission tears down BY OWNER and
  only the survivor fires (asserts reading Housing.watched directly). **VytoFreeze**:
  spool freeze-on-run-fail — a green run culls to the ~60 cap, a mock Run lands
  `Run.c.run.sc.failed_at` and a further cull FREEZES so all 66 evidence moments survive.
  **VytoSeek**: Storui step→yore_n shim — a step-tagged moment seek lands the right yore
  (step 4 → yore 20), an unmatched step + a scrubber-only moment (no step_n) stay
  unreachable. All three drive `Vyto_stir`/cull/seek DIRECTLY (Story-run House quiescent
  under ttlilt). See [[yore-moment-spool]].

**Husks / R&D:** Interesting (empty-Plan precursor to LakeSurprise), Pot*/Por*/PortPain
(gardening R&D, several not in Library), PeeringLive/Peeringinst (p2p handshake protos,
"fatally not written in stho"), ReactiveVers (no dir on disk).
