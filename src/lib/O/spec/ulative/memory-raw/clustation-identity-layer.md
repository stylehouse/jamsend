---
name: clustation-identity-layer
description: "The cluster Identity layer (%Identity→%Peering, ?I= selector + ?I=runner-on-grid + advertise) in Auto, feeding relay hello — toward remote %Rungo"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

Toward remote `%Rungo` ([[runner-fleet-goal]]), the cluster identity/grid layer, built **in Auto** (the
user's "becoming who it is automatically IS Auto's job — merge Clustation into Auto"). Model the user settled:
**`%Identity`** (the per-`?I` self; OWNS trust) **→ `%Peering`** (our real pub address; 1:1 usually) **→ `%Pier`** (remote peers).
Persistence = **Thangs** (Dexie ghost, was BUILT-but-DORMANT; generic `[table+name]`). The model was
pre-spec'd in Peeroleum_spec §10-11 (`thangs:identities`, `%req:p2pman`) — `%Identity` is its concretion.

**THE BORDER (user asked for it):** GRID layer (Auto: `?I=`→identity→on-the-grid→advertise→hold channel)
⟂ LangLies machine (Lies+Lang: receive `become_book`/`rungo`→run Story→`run_result`). Only 2 frames cross,
both keyed by the %Identity addr: inbound work-assignment, outbound verdict. Handlers already exist
(`Peeroleum_on('become_book'|'rungo')` in, `Lies_report_result`→`run_result` out). Grid knows nothing of
Stories; LangLies nothing of how it got on the grid.

**Identity layer (in Auto.svelte, `//#region identity`):** `Clustation_mint` (fresh ed25519 via Idento);
`Clustation_ensure_identity` (resolves `?I=`, stands up `A:Clustation`/`w:Thangs,thangs:identities`,
mint|peek, then `Clustation_concrete`); `Clustation_concrete(A,tag,stored)` (the SHARED concretion — both
ensure + adopt funnel through: `%Identity` with **keys on .c** owning `%Peering,name:<prepub>`, `active:1`,
stamps `H.c.active_identity`); `Clustation_active_identity`→{pub,key}; `Clustation_self`→{prepub,friendly}
(the advertise/display face); `Clustation_adopt(keypair,friendly)` (external .env key → first-class
%Identity); `Clustation_clear` (deactivate, keep the saved Thang). `?I=new`=mint fresh, `?I=<tag>`=resume,
absent=inert (Lies_cluster_idento falls back to legacy `.stashed.cluster_idento`). Build 1 hello lives in
`Lies_channel_up` (signed `{control:hello,...}` beside `become`, signs `Lies_cluster_idento` read live).

**BUILT 2026-06-30 — the grid on-ramp (type-clean, :9091-UNVERIFIED):**
- **`?I=` ALONE = runner-on-the-grid** (Otro.svelte): `?I` with no `?E`/`?B` → `boot_role='runner'` but NO
  `H.c.book` — same runner role/Creduler/channel as `?B=`, but idles connected (no Story) until a
  `become_book` assigns one. `/Otro?I=new` is the whole on-ramp. (Still trips the existing disk-gate
  FaceSucker — a runner genuinely needs the wormhole for Book fixtures; that's `?B=` behaviour, not new.)
- **`?I=new` rewrites its own URL** (Clustation_ensure_identity, after concrete): `history.replaceState`
  → `?I=<prepub>` so the tab BECOMES that minted identity — a reload RESUMES it (peek finds the just-stored
  Thang) instead of minting yet another fresh one. `?I=<tag>` already resumes, so only 'new' rewrites.
- **advertise → roster** (LiesLies): runner emits `advertise{from prepub,friendly,ready,book}` from the
  IN-THINK heartbeat (`Lies_advertise`, ~15s throttle); editor `Lies_advertise_recv` stamps `%Runner,<prepub>`
  (dontSnap) on w:Lies. Role-addressed to 'editor' (relay fans every runner→editor to the one editor; `from`
  says who) so it works for N runners BEFORE per-pub to:<pub> dispatch lands.
- **Multiplied Runner Brink** (LiesFunk `Lies_aim`): editor hoists ONE `Lens:Brink,of_Funkcion:Runner,pub:<X>`
  per roster entry (lens.c.runner=the %Runner); `Funk/Runner.svelte` renders from the roster entry when
  `lens.c.runner` set (pub-titled, ready/free|running, last_heard age, 45s live-window). Runner-side keeps its
  single →EDITOR face. `ui/Lens.svelte` each-key now folds `pub` so duplicate of_Funkcion don't clash.
- **IdHatch migrated** (`Funk/IdHatch.svelte`): pasting a `.env.cluster-<role>` now calls `Clustation_adopt`
  (via post_do, tick-safe) → a first-class %Identity, NOT the bare `stashed.cluster_idento` slot. Polls
  `Clustation_self` for the active id; copy = full pub; clear = `Clustation_clear`.

**FIX 2026-06-30 — advertise is now EPHEMERAL + off-think (the "in-think" claim below is SUPERSEDED).** The
"must run IN-THINK" constraint had a sharp bug: a quiesced/IDLE runner stopped beaconing (advertise rode the
in-think heartbeat) and DROPPED OFF the editor's `%Runner` roster though it kept PINGING (off-think keepalive)
→ editor showed "connected but empty roster" (the `Funk/Runner.svelte` no-identity fallback row; the symptom
that looked like a rack/reactivity bug but was transport). FIX: add `advertise` to the ephemeral set in BOTH
`Peeroleum_send` (outbound, books no `%outbox/emit`) and `Peeroleum_route` (inbound straight-dispatch, no
ack-back, no inseq booking) — `Ghost/N/Peeroleum.g`, gen recompiled via LocalGen (`GFILES=… Story_cli.vitest.config.mjs`)
— then MOVE the `Lies_advertise(w)` call out of `Lies_heartbeat` into `Lies_keepalive` (off-think). A beacon is
self-healing (relay ws is reliable+ordered: first-contact lands, a lost beat returns ~15s later), so app-level
acks bought nothing; bonus, the per-beacon outbox leak below is gone for advertise. :9091 LIVE-VERIFY OWED —
reload runners AND editor to re-acquire the recompiled Peeroleum gen. Also done same pass: the editor now shows
ONE titled "RUNNER" rack (`Lens:Brink,of_Funkcion:Runner,rack:'all'` — STRING discriminator; a numeric `1` is a
query wildcard that never persisted → is_rack false → fell through to the single-pair "editor →RUNNER" face) +
Relay collapsed to one line; the per-pub `lens.c.runner` panels are RETIRED.

**GOTCHA (run_result|rungo|become_book still ride this) — the ambient channel isn't whittled.** Those stay
non-ephemeral (ephemeral set = ack|ping|pong|run_phase|advertise), so each books a `%outbox/emit` → must run
IN-THINK (snap-tree mutation under the mutex). The §7.4 whittle (`Peeroleum_runstepped`: acked emits → `%outbox/recent`
capped 20) DOES exist — but it fires at STORY step boundaries and is armed ONLY in the Peeroleum test Book
(`Peregrination.go` calls `Peeroleum_arm_whittle`); the LIVE editor↔runner channel is outside any Story
(`Runstepped`→no Run, `_resolve_runstepped` never called on w:Lies), so it's NOT whittled at all — run_result/
rungo/become_book ALREADY accumulate there slowly. advertise just rides the same path, faster (15s). So this
is a PRE-EXISTING ambient-channel thing, not new. Ephemeral-promotion idea DROPPED (over-reach). FIXED instead:
`Lies_channel_cull` (in Lies_heartbeat, in-think) drives `Peeroleum_runstepped(w)` once the acked|done backlog
> 12 — archives acked %outbox/emit → %recent + done %inbox/unemit → %recent (cap 20), for ALL ambient frames
(run_result/rungo/become_book/advertise), no spine work. Peeroleum_runstepped has no Story dependency; the only
reason it didn't fire is the ambient channel has no `sc.Run` (the Story-Run marker, Story.svelte:1233) → no
`_resolve_runstepped`. ("pinned_stable promotion" = re-copy gen→frozen editor spine; unrelated, NOT needed —
nothing here changed the spine; advertise rides the generic `Peeroleum_on` path.)

**BUILT 2026-06-30 — favourite_client + the engagement lease (the "don't run into each other's runners"
gate; type-clean, :9091-UNVERIFIED):**
- **`favourite_client`** = a sticky SOFT prefer ("this runner is Claude's"), a client pub.  Lives on the
  runner's Mundo (`top.c.favourite_client`), rides the advertise beacon (`Lies_advertise`), editor captures it
   onto the `%Runner` roster (`Lies_advertise_recv`) for the Brink.  Set-path (editor→runner `favour` frame +
    persist to identity Thang) NOT yet built — the beacon reads top.c, empty until set.
- **engagement lease** = the HARD don't-steal, on Mundo (`top.c.engagement = {client,status,at,book}`), so it
  SURVIVES Story_reset (representation outlives the run).  status active|released|timed_out; timeout is LAZY
   (TTL 10min — Claude's think-between-runs window, `Lies_engage_ttl`).  Methods in LiesFunk beside the
    runner_ask handler: `Lies_engagement` (timed_out folded in), `_check` (refuse if ANOTHER client's lease is
     live), `_engage` (stamp + GC prior client's runs on client-change), `_touch` (any op from the holder
      refreshes the clock), `_release` (released + GC + quitStory), `_engage_gc` (drop Storyrun records + stamp
       `top.c.last_gc`).
- **runner_ask wiring** (`Lies_runner_ask_recv`): `client` = `ask.client ?? header.from`; touch at top of every
  op; `run` engages (refuses-if-busy); new `release` op; ping/state report engagement+favourite_client; `@uid`
   on a reaped run now says "garbage-collected by <who> <age>" (reads last_gc), not a bare miss.
- **clean hang-up → H:Mundo**: `Auto.auto_teardown_story()` (extracted from auto_reset_story) + a `quitStory`
  elvis (IDLE teardown, NO rebuild — unlike resetStory, which reruns on a ?B= runner with H.c.book).
- **CLI** (`runner_ask.mjs`): sends a STABLE `ask.client` (claude prepub from .env.cluster-claude
  `CLUSTER_IDENTO_CLAUDE_PUB`[:16], or RUNNER_CLIENT) so "was it you?" answers; `release` op; refuse/GC errors
   surface on stderr (`✗ <op>: <reason>` + lease line).

**DEFERRED:** editor→SPECIFIC-runner dispatch via `to:<pub>` (relay ALREADY routes it post-hello — proven in
relay-test.ts; depth is editor-side: a Pier-per-prepub w/ own seq/inseq, since Peeroleum_send_consumer is
hardwired to ONE role-Pier.  CLI needs NONE of this — raw relay client, just sets header.to=prepub).  Then
StoryTimes PARALLEL (`Lies_storytimes_width` ADDRESSABLE=1→runner_count, inflight keyed per-runner — comment
at the cap already says how).  The favourite_client SET-path (editor `favour` frame + Thang persist).
Relay-roster discovery DROPPED (user: runner just announces to the editor; CLI works with KNOWN runners, no
server-side state).  Multicast→v1.1.

**HANDOFF 2026-06-30 — the editor half goes to the Lies/editor agent, not sidearmed onto Peeroleum:**
`spec/Engage_integration.md` (pointer from Cluster_spec §7 step 2) = a self-contained integration brief for
 whoever owns the Lies/editor machine.  Critical path: **C2 first** — `Peeroleum_send_consumer` is hardwired
  to Pier[0] (gen Peeroleum.go:240); needs `Peeroleum_send_to(w,prepub,…)` + **roster→Pier promotion** (the
   %Runner roster is N role-broadcast entries but a Pier is a HANDSHAKEN peer — promote on first dispatch) +
    **per-Pier inseq baseline** ([[inseq-reload-baseline]] cold-cursor bug multiplies across N Piers).  C3
     (StoryTimes parallel) sits on C2; **C1 (favourite_client) is SEPARATE** — not a frame dependency.

OWNER DESIGN CALLS (2026-06-30, fold into the runner side too):
- **Engagement is a PARTICLE, not a `.c` blob** — `top/Engagement,client,status,at,of_Book` on Mundo,
   snapped/VISIBLE ("why hide it?"); `of_$k` convention = a prop naming a thing of another C-type.  DONE +
    **:9091 live-verified 2026-06-30** (`Lies_engage_c` finder + 5 methods reworked; full lifecycle green on
     a real runner via runner_ask: engage→run→state→refuse-other-client→release→GC'd-run error→idle; of_Book
      round-trips, touch is holder-only).  `last_gc` left a transient `.c` breadcrumb.  NIT: GC'd-run msg says
       "re-engaged by" even on self-release (last_gc records no reason) — 1-line tweak deferred.
- **Lease = loose exclusive, app-level** — exclusive by *visibility* (others know whose a runner is), not a
   hard lock; easy to break out of, the completed `Storyrun` objects are the durable truth, orchestrator
    handles contention.  No relay arbitration.
- **favourite_client lives in `Waft:Cluster`/`%HostedIdentity,favourite_client`** (NOT %Identity/%Peering/a
   Thang) — a registry tracking ALL known objects (claude/editor/runners), auto-vivifying; purpose = same tab
    runs the same Story every time (sticky tab↔Story affinity).  Registry work = the Lies agent's.
Runner-side `Waft:Cluster` stamp + the engage-particle flip held till the owner shapes the registry/frame.

**BUILT 2026-06-30 — `Waft:Cluster` stood up as the persisted `/%HostedIdentity` registry (the C1 home;
type-clean, :9091-UNVERIFIED).** ROOT BUG found: `Lies_aim_setup` MINTED `Waft:Cluster` directly
(`w.oai`) — no `%Good`, no `watch_c` — while the Keep had noted it (`WaftTimes,of_Waft:Cluster`) so
`keep_reopen`→`Lies_open_Waft` ALSO opened it through the Good pipeline, whose not_found `w.place` of a
fresh-empty Cluster **clobbered** equip + the `%HostedIdentity` children, and the direct copy never saved
(no watch_c) → nothing on disk, not equip, no `/*`. FIX = ONE creation path: `Lies_aim_setup` now just
`i_elvisto Lies_open_Waft{path:'Cluster'}` (like GhostList/Keep — Good pipeline loads or creates-empty +
registers the watch_c save); decoration moved to `Lies_cluster_decorate(w,cluster)` (idempotent per-tick
from `Lies_aim`): `equip??='Cluster'` (survives the place(), persists) + mints `Funkcion:Runner|Relay`
dontSnap (the live overlay; only the registry persists — spec §C1 split) + binds on mint. `Lies_cluster_claim_self`
adds `%HostedIdentity,<self-prepub>,self,friendly`; `Lies_advertise_recv` mirrors peers' `%HostedIdentity`
(dontSnap DROPPED — durable directory now). Plus **create-from-nothing** in `LiesPersist` (Lies.svelte): a
not_found Waft writes its initial snap immediately — but **EDITOR-ROLE + `!Lies_nowriting` gated** (Lake*
Books run on a runner under `nowriting`, where a save→snapped `%log:waft_save` would redden the whole fleet).
Stale proto `wormhole/Cluster/toc.snap` (equip+2 Funkcions, NO registry) DELETED to renew. Leak check: only
the Editron Book fixture carries `Waft:Cluster` (already M); Lake/Pere/Musu fleet unaffected. Verify on :9091:
reload editor → `wormhole/Cluster/toc.snap` regenerates clean (equip, `/%HostedIdentity:self`+peers).

**:9091-VERIFIED 2026-06-30 + 3-bug fix.** Registry confirmed correct: `HostedIdentity:<editor-prepub>,role:editor`
+ `HostedIdentity:<runner-prepub>,role:runner` (claude's runner, found via runner_ask too). Three bugs the first
cut had, now fixed: (1) **spurious `HostedIdentity:runner|editor`** — the Pier-mirror keyed on `pier.sc.pub`,
which is the peer ROLE in the local mock (`LiesLies:207 oai({Pier:1,pub:peer})`), not a prepub → REMOVED the
mirror; peers come from advertise (real prepubs). (2) **"everyone thinks they're self"** — `self` is viewer-
relative (one SHARED registry file; two identities/tabs each wrote self) → `self` is now DERIVED not stored
(`entry.HostedIdentity === Lies_self(w).prepub`), claim_self SCRUBS stale ones. Couldn't session-strip `self` —
it's a load-bearing req-machine key (`{self:1,round:1}`). (3) **no role** → `role:editor|runner` stamped
(claim_self = our `Lies_role`; advertise_recv = runner, since advertisers are runners). New `Lies_self(w)`
(LiesLies) = self across ALL identity tiers (?I= %Identity → legacy stashed key). **NOW HANDED OFF** to
`spec/Cluster_runner_handover.md`: (1) Relay-is-another-thing structural split + Runner-singleton→per-
HostedIdentity Brink (touches live Lens hoisting, `Lies_aim` ~387-434); (2) the runner RACK — activation
ladder (flat 45s window today, `Funk/Runner.svelte:138`), Pier culling (none today; advert ~15s, want ~120s→
cull Pier 180s; cull TRANSPORT not the durable HostedIdentity), server-rack Brink layout; (3) Cursor-not-
resuming bug (machinery built: keep_mark_focus/keep_resume_what + Langoer boomerang, trace where the cold want
dies); (4) save CodeMirror scroll as a LINE target on the Keep %Cursor. Carried: Shortfall A (generic-C** Waft
view, other agent), C3, favourite_client SET.

**BUILT 2026-07-01 — `Lies/Runner` is now a SNAPPED particle, 1:1 with `%HostedIdentity` + the `Rundar`
rename (type-clean, :9091-UNVERIFIED).** Owner's framing: "I see no representation of a roster besides
%HostedIdentity? we need a bunch of Lies/Runner which 1:1 to %HostedIdentity." ROOT: the `%Runner` roster
on w:Lies was `dontSnap` (invisible in the snap) AND only existed for live advertisers — the editor's whole
view of its runners was the one oblique `channel_peer:runner` line. FIX — the split is now beacon(off-think,
.c) → projection(in-think, snapped): (a) `Lies_advertise_recv` does ONLY a lock-safe park onto `w.c.beacons`
(pure .c, NO snap mutation — it lands on the EPHEMERAL route, off-mutex; the old version mutated snapped
HostedIdentity off-think, a latent hazard now closed); (b) new `Lies_runner_roster(w,cluster)` runs IN-THINK
from `Lies_aim` (editor) and projects ONE **snapped** `w:Lies/%Runner,<pub>` per `%HostedIdentity(role:runner)`
— 1:1 with the registry — mirroring durable identity (friendly/favourite_client) + folding the beacon. Volatile
timing (`last_heard`, the ☎ `sent`/`sent_at`) rides `.c` OFF-snap so the ~15s beacon doesn't churn the snap;
the PROVEN facets (`ready`/`book`/`engaged`) ride snapped, flip only on a real transition. **Whittle semantics
(the owner's "only grants are lost if they are"):** going silent past 45s CLEARS the live grant (ready/book/
engaged) but KEEPS the snapped identity row; a Runner LEAVES only when its registry entry is forgotten (the
directory is authority). Readers repointed to `.c` (`Lies_dispatch_target` live+busy, `Lies_send_become_book`
☎, the Brink rack). Bump on a last_heard ADVANCE too (it's .c → wakes the rack $effect, adds nothing to the
snap) else a steadily-live runner falsely flips "silent". **RENAME `Funk/Runner.svelte`→`Funk/Rundar.svelte`
+ kind `Runner`→`Rundar`** (owner: "rename to give it the multiplicity — we sludged in from a point-point
protocol"): `kinds.ts` import+registration, `Lies_aim` `of_Funkcion:'Rundar'` + a self-migrating drop of any
legacy `of_Funkcion:'Runner'` lens. The rack template now renders every roster row (multiplicity) PLUS the
anonymous single-pair peer as a real row showing its run-phase ("● anon — connected" / "▶ anon — running X"),
no more "peer connected — no identity". **WHY the box still shows one anon row for the owner:** their connected
runner is `?B=` (self:null, advertising:false — confirmed via `runner_ask ping`) → no identity → no
HostedIdentity → no snapped Runner; the relay collapses ALL anonymous `?B=` runners onto the ONE
`channel_peer`, so identity (`?I=`) is the ONLY discriminator for multiplicity. VERIFY: reload editor+runner
tabs (kinds.ts registry swap), boot `?I=new` runner(s) → each advertises → a snapped `Runner:<pub>` row in the
editor's Brink AND in the w:Lies snap. All `.svelte`/kinds.ts (eatfunc HMR + component swap), NO `.g`/gen
touched. Supersedes the dontSnap-roster + per-pub-panel notes above.

**DIAGNOSED 2026-07-01 — "two real runners read OFFLINE + a phantom anon row running Radiola.g."** NOT a roster
bug. ROOT = the **editor's relay socket flapping** (`relay.ts` log: `browser DISCONNECTED addr=editor code=1005`
→ rebound, over and over) × the fact that **per-runner liveness rides ONLY the sparse ~15s advertise beacon**
while ping/pong is ~1s: a flapping socket drops the sparse beacon (→ rows go offline, last_heard never refreshes)
but the frequent ping slips through (→ channel_peer:runner reads live → my code invented an "anon" row). The
flapping was almost certainly MY OWN churn — the Funk/Runner→Rundar **rename + kinds.ts registry edit are
structural** (Vite can't hot-accept → forces editor FULL-RELOAD → socket 1005). Settles once restructuring stops
+ reload. The "running Radiola.g" = the anon row borrowed the editor's ONE collapsed `w.c.run_phase` blip, which
was a StoryTimes-sweep Doc/compile of a ghost source (`Runner_talk_TODO.md §1b` documents this exact `This`-churn
flip), NOT a Story %w. FIXED the anon row (`Funk/Rundar.svelte`): no longer borrows run_phase; appears ONLY when
the roster is genuinely empty; when identified runners exist-but-stale, shows an honest `◍ channel live · beacons
stale` line instead of a phantom. **HANDED OFF (owner: "hand the networky refactoring to a networking agent, I
get back to Keeping") — `Cluster_runner_handover.md §5` "The per-runner CHANNEL":** the real fix = each runner a
promoted Pier pinged individually (`to:<pub>`), pong carries `from:<pub>`, editor stamps liveness onto the
`%Runner` row — so liveness is REAL per-runner ping, advertise demotes to a directory announce. Audit: only
`become_book` uses `to:<pub>` (C2); ping/pong/rungo/run_phase/run_result/advertise/ghost_compile/wormhole_* all
ride the collapsed role-`Pier[0]` via `Peeroleum_send_consumer` (no literal `to:'runner'` — collapse is
structural: send_consumer→Pier[0] + inbound `channel_peer:<role>` demux). Stage (a) per-runner ping ALONE kills
the symptom. The Rundar rack already reads `%Runner.c.last_heard` so it needs ZERO further UI work once (a) lands.

**DESIGN DIRECTION 2026-07-01 — `spec/Swarm_spec.md` (was Swarm_doc, RENAMED): the p2p social side, the triad's middle (Cluster=how-it-runs /
Swarm=who's-on-it / Radio=what-streams).** Captures the identity substrate as a **[want]**, not built: (1) identity should be
a PORTABLE PARTICLE, not a Dexie/localStorage blob — Dexie is exactly as origin-bound as localStorage; the axis is
ENCODABILITY (enLine/snap/copy), not storage locality. Persist it as a snapped tree on the user's own disk via the Wormhole:
`<music>/.jamsend/account/<prepub>/toc.snap`. (2) **identity ≠ address**: a portable identity open in N places → N sockets
hello the same prepub → `to:<prepub>` fans to all = the double-delivery bug one layer up. Fix = per-SESSION address vouched by
the durable identity (`to:<session>`=one place, `to:<identity>`=all my sessions) — the runner role-bucket vs prepub split again.
(3) capability (audio) = a `%Identity` flag advertised as a `caps` MAP on the beacon (collapses the hand-kept advertise field
list) → durable `%HostedIdentity.caps` vs live `%Runner` ready-now; gesture handled at the boundary (`--autoplay-policy` flag
headless / ambient interaction human), never per-load. §6 scaffolds follow/feed/acceptance (→ [[cluster-first-class-object]]'s Keep/Interest). Cross-linked from Cluster_spec + Radio_spec.

**BUILT 2026-07-05 — the "two runners, like before" fix = EPHEMERAL-IDENTITY GC (the durable-registry side of
the accumulation; the 2026-07-01 anon-row fix above was only the DISPLAY side).** ROOT confirmed empirically:
`wormhole/Cluster/toc.snap` held THREE `HostedIdentity,role:runner` but only one live — the other two bare
`role:runner`, NO `favourite_client`: anonymous ghosts from prior boots minting a fresh cluster identity
(`?I=new` rewrites its own URL, but a NEW `?I=new` / a re-minted stashed key each session = a new prepub). The
"never forgotten" registry kept them, `Lies_runner_roster` mints a `%Runner` per role:runner, and `Rundar`
shows heard:0 rows as durable 'offline' → dead ghosts beside the live one. FIX (`Lies_runner_roster`, in the
`!live` branch): an anonymous (no `favourite_client`) role:runner that isn't live and has no ☎ in flight
(`r.c.sent`) is FORGOTTEN — `cluster.drop(hi)` + `known.delete(pub)` + drop its `%Runner` row. A BOUND runner
(favourite_client) is KEPT as 'offline' (the binding is the reason to remember). Self-heals: a live runner
re-advertises ~15s and re-registers; a dead one never returns. TRADEOFF (stated to owner): an *anonymous*
offline runner is now indistinguishable from a dead one → pruned (matches the "advertise non-ephemeral" GOTCHA).
Self-applies to the RUNNING editor (roster runs every tick) + the persisted Cluster snap rewrites clean — no
hand-edit. This is the LEAK-STOP; the CURE is the directory/session split (**task #8**): `%HostedIdentity`
conflates a durable DIRECTORY (bindings; few, stable) with a live SESSION roster (churns per boot) — writing
every advertised pub into the durable store is the category error; project live runners from beacons, persist
only bound identities. :9091 — the live editor should drop the rack 3→1 after HMR (owner watching).
Also this session: **task #12 DONE** — the hand-kept advertise field list (`ready|book|engaged|ac|fsa`, threaded
through five sites) collapsed into ONE ordered `RUNNER_FACETS` table in `LiesLies.svelte` (advertise build+sig,
advertise_recv unpack, roster live-fold+dead-clear, going_cold all derive from it). Byte-identical refactor;
`ready` excluded from the sig; ORDER load-bearing (the encoder walks `sc` in insertion order, so a fresh
`%Runner` snaps identically). This is the "caps MAP collapses the hand-kept advertise field list" want (item 3
above) landed for the CURRENT facets.
