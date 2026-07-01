# Cluster_runner_handover.md — the live registry, the runner rack, and two cursor wants

A handoff brief, not a changelog. Destination first, then the knowledge that bites if you don't have it,
 then the next move per thread. Sits beside [Engage_integration.md](Engage_integration.md) (the dispatch/
  engagement half) and the `clustation-identity-layer` memory (the identity/grid arc).

## Destination

`Waft:Cluster` is a **persisted identity directory** (who exists on the cluster) that now needs to grow a
 **live runner rack**: list the runners we've been advertised, with honest activation/liveness states, cull
  dead transport, and stack the per-runner Brink faces "like a server rack." Two editor-side cursor wants
   ride alongside (resume-last, and scroll-as-line). The directory feeds the engagement/dispatch layer
    (favourite_client → `to:<prepub>`).

**→ Networking agent: read §5.** The load-bearing fix — making runners individually *pingable* (per-runner
 channel, `to:role`→`to:<pub>` migration) instead of faking per-runner liveness off a sparse 15s beacon — is
  its own self-contained brief at §5. The rack UI is already built to consume it.

## DONE — the arc to here (load-bearing, not exhaustive)

- **Cluster is a first-class PERSISTED Waft.** Opened ONLY through the Good pipeline (`Lies_aim_setup` →
   `Lies_open_Waft{path:'Cluster'}`), exactly like GhostList/Keep — loads `wormhole/Cluster/toc.snap` or
    creates-from-nothing, and registers the `watch_c` save. `equip:'Cluster'` (backstage, no focus). **The
     bomb that was here:** a second creation path (`Lies_aim_setup` used to `w.oai` Cluster directly — no
      Good, no watch_c) raced the Good-pipeline `w.place`, which clobbered equip + the registry and never
       saved. ONE creation path now. Decoration (equip + the watcher Funkcions) is idempotent per-tick in
        `Lies_cluster_decorate` on the LOADED Waft.
- **The directory ≠ the live presence (the split):**
  - `%HostedIdentity,<prepub>` = the **durable directory** — `role` (editor|runner), `friendly`,
     `favourite_client`. Persists. Keyed by REAL prepub.
  - `%Runner,<prepub>` = **live presence** — dontSnap, rebuilt from advertise beacons (`last_heard`,
     ready/book/engaged). Never persists.
- **Population (all verified-correct on :9091 — editor + runner, right roles, no junk):**
  - `Lies_self(w)` (LiesLies) — WHO WE ARE, across ALL identity tiers: the `?I=` `%Identity`
     (`Clustation_self`, carries friendly) else the legacy `.stashed.cluster_idento` behind
      `Lies_cluster_idento`, reduced to its prepub. The same identity we sign the relay hello with.
  - `Lies_cluster_claim_self` (LiesFunk) — names US (`role: Lies_role(w)` + friendly). **`self` is DERIVED,
     never stored:** the registry is one SHARED file, so who-is-me is viewer-relative — a reader computes
      `entry.HostedIdentity === Lies_self(w).prepub`. claim_self also SCRUBS any stale persisted `self`.
       (`self` could not be session-stripped — it's a load-bearing req-machine key, `{self:1,round:1}`.)
  - `Lies_advertise_recv` (LiesLies) — mirrors advertisers into the directory; an advertiser IS a runner,
     so it stamps `role:runner`.
  - **Removed:** the Pier-mirror. A Pier is keyed by the peer ROLE in the local mock (`LiesLies:207
     oai({Pier:1, pub: peer})`, peer = the opposite role string), NOT a prepub — mirroring Piers minted the
      spurious `HostedIdentity:runner|editor`. Peers come from advertise (real prepubs), not Piers.

## OPEN — the next moves

### 1. "The Relay is another thing" — the structural split + Runner→per-HostedIdentity
The container interleaves two KINDS: the `%HostedIdentity` directory and the cluster-service watcher
 Funkcions (`Funkcion:Relay`, `Funkcion:Runner`). They are not the same thing.
- **`Funkcion:Relay`** = a cluster-wide singleton service (the relay carrier's own health) — legitimately
   of-the-cluster, KEEP. The Brink want (owner, 2026-06-30): collapse it to ONE LINE — `🛰 relay up` — not
    the verbose endpoint panel; it's a carrier-health pilot light, not a directory row.
- **`Funkcion:Runner` (singleton) — RETIRED (2026-06-30).** It was a proto leftover; "Runner" is a FACET of
   a per-peer `%HostedIdentity` (role:runner), not a cluster singleton. `Lies_cluster_decorate` (LiesFunk
    ~361) now mints ONLY `Funkcion:Relay`, and actively DROPS a stale `Funkcion:Runner` a prior build left
     (self-healing migration — the watch_c save then drops its snap line; the live editor's HMR already
      cleaned `wormhole/Cluster/toc.snap`). The two `Lies_aim` funk lookups (`cluster.o({Funkcion:'Runner'})`,
       runner-side single face + editor empty-roster fallback) are gone — those faces hoist with no singleton
        funk, reading liveness straight off `w:Lies` (they lose only the fade-out transition toast
         `funk.c.latest`; bringing a per-runner "last event" caption back is optional polish, NOT a planned
          layer — "%Aim" is a retired word, don't reach for it).
- **STILL OPEN — the editor's Runner rack layout.** The multiplied Runner faces already derive from the
   `%Runner` roster (`lens.c.runner`). The Brink want: stack them TOGETHER inside one "RUNNER"-titled box
    (not N inline panels), each row keyed by `pub` + its job state (see §2a) — drop the banal single-pair
     `→RUNNER (live)` line on the editor side. Touches the per-pub lens hoisting (`Lies_aim` ~439-453) →
      one rack lens reading the whole roster. Owner-supervised at the live Brink.

### 2. The live runner rack — activation states, Pier culling, server-rack Brink
- **Activation ladder.** Today liveness is a FLAT window: advertised runners `r_live = now - last_heard <
   45000` (`Funk/Runner.svelte:138`, ~2 missed 15s adverts); the single-pair channel uses 7s
    (`Runner.svelte:96`). The want: a real ladder — *advert-seen → ready → talking-regularly* — instead of
     one cutoff. States already drawn: dialing → silent → live(running|engaged|free).
- **Pier culling.** No reaper exists. Advert cadence ~15s (`LiesLies:829`). Your frame: advert ~120s → cull
   the **Pier** at ~180s (1.5×). KEY distinction: a Pier is the handshaken TRANSPORT (promoted on dispatch,
    `Lies_runner_pier`); culling a dead Pier is NOT removing the durable `%HostedIdentity`. The directory
     entry outlives the connection; only the transport + the `%Runner` live-presence get reaped.
- **Server-rack Brink.** The editor multiplies one `Lens:Brink,of_Funkcion:Runner,pub:<X>` per roster
   entry (`Lies_aim` ~439-453, `lens.c.runner` = the `%Runner`). Needs a clean stacked layout — see §1's
    "RUNNER box" want + the Lens posable/altitude work, [Lens_posable_TODO.md](Lens_posable_TODO.md).
- **Boot-race re-read — REVERTED 2026-06-30.** An earlier pass kicked `Lies_open_Waft{Cluster}` from
   `advertise_recv` when the registry wasn't loaded. It was DEAD in the live case (the editor always has
    Cluster loaded by the time an advertise lands) and redundant (the vivify branch populates + persists —
     three `HostedIdentity` rows on disk prove it). Removed; the boot-race self-heals on the next ~15s beacon.

### 2a. Per-prepub dispatch + the job board (☎→▶) — DONE 2026-06-30; rungo + the advertise ROOT fixed + LIVE-VERIFIED 2026-07-01
> **2026-07-01 — the regression & its real root.** Dispatch silently fell back to BROADCAST again because
>  `Lies_advertise` gated WHO-we-are on `Clustation_self` (the `?I=` %Identity), which is **null for a runner
>   booted `?B=` with only a stashed/env cluster key** (no `?I=`). Such a runner hello-binds + is fully
>    addressable, but never advertised → empty `%Runner` roster → `Lies_dispatch_target` returns `{}` → broadcast.
>  **Fix:** advertise (and a new ping-borne liveness refresh) now use `Lies_self` (falls back to
>   `prepubOf(cluster_idento.pub)` = the exact hello-bind prepub). This SOLVES the identity-divergence (§5 below)
>    for dispatch. Plus `Lies_send_rungo` now individuates (next bullet). Live-verified via the socklog scaffold:
>     `↑ to:runner rungo` → `↑ to:<pub> rungo` sticking to one runner; 0 broadcasts in steady state.
**The real "two runners both ran it" root:** EVERY dispatch was role-addressed BROADCAST — `e_Lies_become_book`
 → `Lies_send_become_book(w, book)` with no `to` → the single `Pier:runner` → the relay fans it to ALL runner
  sockets. The `to:<prepub>` primitive (C2: `Lies_runner_pier` + `Peeroleum_send_to`) existed but no caller used it.
- **`Lies_dispatch_target(w)`** (LiesLies) picks ONE runner, walking the `Waft:Cluster` directory (trusted
   identities, role:runner) and reading live busy/favour off the `%Runner` roster. Owner's policy: the LATEST
    trusted, NOT-busy runner, preferring one not reserved as another client's favourite. Tiers among FREE:
     mine ▸ unclaimed ▸ other-client's-favourite; a fresh ☎ (just-dispatched, no ack) counts as busy so a
      burst SPREADS. Returns `{to}` (ring it) · `{}` (nobody live → caller broadcasts, fine for a lone runner) ·
       **`{exhausted}`** (runners exist but ALL busy → **HOLD, never steal a running one** — the no-tailspin rule).
- **Exhausted-runners backstop:** `Lies_queue_run` holds the book on `w.c.pending_runs`; `Lies_advertise_recv`
   calls `Lies_drain_runs` when a runner's beacon shows it freed, shipping the oldest held job. No clobber, no
    spin. **Per-client best-effort only** — two editors racing for the last free runner can double-book in the
     ~15s advertise window; true cross-client fairness wants the relay-arbitrated LEASE (Cluster_spec §2/§5,
      seeded by the `engaged` field), NOT built.
- **Threaded `to`** into `e_Lies_become_book` + `Lies_storytimes_dispatch` (LiesFunk) — the Book-cell click
   path (`Storying.svelte` `of_Book` → `Lies_become_book`). **rungo now individuates too (2026-07-01):**
    `Lies_send_rungo` routes via `Lies_rungo_target` (STICKY — manual aim ▸ `w.c.rungo_runner` ▸ deterministic
     latest-in-directory) + `Peeroleum_send_to` (which allocates the seq on the runner's Pier — authority
      preserved), BROADCAST fallback only when no runner is live (surfaced, never silent). `become_book` sets
       `w.c.rungo_runner=to` so a recompile-rungo follows the runner the book was started on. A rungo FIRES the
        run (`req_rungo`→`Lies_drive_run`), so a broadcast rungo made EVERY runner fire — this was the dominant
         double-run carrier for compile-driven runs, now closed. Benign edge: a one-time consumer-seq→Pier-seq
          jump at the switch can transient-double-fire on the ONE runner; self-heals on reload.
- **The job board:** `Lies_send_become_book`'s `to` branch stamps `r.sc.sent`/`sent_at` on the runner's
   `%Runner` slot (the ☎); `Lies_advertise_recv` clears `sent` when that runner advertises a `book` (→ ▶). The
    face (`Funk/Runner.svelte` roster mode) shows `▶ playing X` ▸ `☎ calling X` (30s ring) ▸ dialing/free/engaged/silent.
- **`scripts/runner_ask.mjs` courts via the registry:** new `runners` op LISTS the registry (it deLines
   `wormhole/Cluster/toc.snap` directly — no eatfunc to import); `--runner=<prepub|prefix|friendly>` addresses
    ONE runner (`to:<prepub>` not `to:'runner'`) and **INSISTS** (retries IT on busy/silence, never failover —
     the OPPOSITE of the editor allocator, for repeatable targeted testing). No flag ⇒ legacy role broadcast.
- **LIVE-VERIFIED 2026-07-01** (socklog scaffold, two real runners): rungos route `↑ to:<pub>` to ONE runner
   (relay forwards `→ <pub>`, not `→ runner`), sticky across recompiles; 0 broadcasts steady-state; advertise
    flows from BOTH runner prepubs. Still owed by hand on :9091: the ☎→▶ job-board UI transitions + the
     3rd-click-held/drain path (the dispatch ADDRESSING is proven; the board PRESENTATION isn't).
- **STILL TO BUILD — the RUNNER box (§1):** the editor still hoists N per-pub `Lens:Brink` panels (`Lies_aim`
   ~444-458). Want: ONE rack lens reading the whole roster → a titled "RUNNER" box, a row per pub. Relay
    one-liner is DONE (`Funk/Relay.svelte` — header dropped, `🛰 relay up` at rest).

### 3. Cursor not resuming (bug — built but not firing)
The machinery is all there: `Lies_keep_mark_focus` records the Keep's latest `%Cursor` (`Lies.svelte:222,
 982`); `Lies_keep_resume_what` returns it on foreground as a `kind:'cold'` want (`Lies.svelte:228-229`);
  the Langoer boomerang arbiter (`Lies_focus_waft` / req:Langoer, ~1054-1077) lets a DELIBERATE move
   outrank a cold resume but is meant to LET the remembered spot win at boot. **Next move:** trace a boot/
    foreground and find where the cold want dies — is `mark_focus` recording the right What? does
     `keep_resume_what` resolve the locator (or has the What moved/renamed)? is the cold Cursor being
      out-competed when it shouldn't be (the boot case, not mid-session)?

**DIAGNOSED + FIXED 2026-07-01 (type-clean, :9091-verify owed — editor-boot behaviour).** It was the third
 hypothesis, but the out-competitor wasn't a persisted Lango (those don't survive a live boot — `w:Lies` is
  rebuilt fresh, Wafts re-open from the Keep ledger). It was the **per-tick timemachine**: `Waft_cursor_first`
   (`LiesCurse.svelte:475`) — the seam `req_timemachine`→`Lies_desire_land_cursor` lands through every tick —
    emitted its land-on-**first** as a `kind:'cold'` want, and `Lies_resolve_wants` is pure newest-`sc.want`-
     timestamp-wins with NO kind priority (`Lies.svelte:954`). So in the window after the boot/foreground
      resume emits its cold want (remembered What) but before it lands, the timemachine emits a NEWER cold
       land-on-first want → it wins → the cursor sticks on the first leaf and the resume "dies." The locator
        resolver and the recording were both fine. **Fix:** made `Waft_cursor_first` resume-aware — it now
         targets `Lies_keep_resume_what(w,waft,key) ?? first`, so the timemachine and the foreground resume
          want the SAME What and the race is harmless. **Editor-gated** (`Lies_role==='editor'`) so a runner
           keeps deterministic land-on-first — a Story's cursor/snap must never depend on a Keep. `else`
            (fresh Waft | unresolvable locator) ⇒ first, unchanged. Verify: reload editor with NO `?W=` → the
             cursor lands on the last-focused What, not the Waft's first leaf. **Owner verified live 2026-07-01.**

**OPEN follow-up (2026-07-01, overnight) — LakeSurfer red + a cleaner Story-safe variant.** Running the
 editor-machine fleet on the live runner to check this fix for fixture regressions: **LakeKeep ✓ and LakeLango
  ✓ green** with the fix, but **LakeSurfer is RED** (2/2 steps, `step1 dige 492278e76281af70` vs fixture
   `ca76a2a729a99cf6`). Could NOT pin a clean baseline — the runner auto-resumes its own Book between requests,
    rolling the held runs (`@uid`) out of the bounded-3 history before they can be diffed, AND a parallel agent
     was live-editing the advertise/dispatch path (§2a) so the runner's code was a moving target. Evidence it's
      **NOT this cursor fix**: it's red with BOTH the resume-aware variant AND a trial skip-variant, while the
       two SIBLING editor-machine books (which also land cursors through this seam) stay green — a generic
        cursor-landing regression would redden all three. Most likely pre-existing or from the parallel
         advertise work. **TODO (owner): establish the baseline** — `git stash` the `LiesCurse.svelte` hunk,
          run LakeSurfer; if green, this fix moved it (then re-record or adopt the variant); if red, pre-existing.
   The **cleaner Story-safe variant** (a NOTE in `Waft_cursor_first`): instead of reading the Keep in the land
    seam, SKIP the seam while an unresolved `%want` already targets this Waft — the boot/foreground resume want
     (or a click) lands the cursor itself, so the redundant land-on-first that out-competed it is simply never
      emitted. No Keep read ⇒ provably can't touch a Story's land-on-first. Not shipped overnight (it'd swap a
       user-VERIFIED fix for an unverified one), but it's the better long-term shape if the Keep-read-in-land
        path ever bites.

### 4. Save CodeMirror scroll as a line target (new want)
Persist the scroll position of the latest Cursor's editor as a **LINE number** (NOT pixels/Q-factor — so it
 survives a different zoom/wrap), on the Keep's `%Cursor` beside the per-Waft cursor (the cursor model near
  `Lies.svelte:1000`). Reopening then restores What + scroll-line. Read the top visible line on blur/cursor-
   record from the CodeMirror view (Lang side); restore via a line `scrollIntoView` on open.

**BUILT 2026-07-01 (type-clean, :9091-verify owed — editor scroll behaviour).** Keyed per-DOC (not on the
 per-Waft `%Cursor`, which it sketched): a doc remembers its OWN scroll, race-free (Langui has the doc path
  for both capture and restore), and it slots cleanly into the **P5 layout service** as a fourth scope —
   `Lies_keep_layout_*(w, 'doc', <doc-path>, 'scroll_line', …)` → `Keep/DocScroll,of_Doc:<path>` (`Lies.svelte`
    ~1227). The line resumes "What + scroll" all the same (cursor-resume opens the doc, this scrolls it).
     Langui (`Langui.svelte`): `top_visible_line` via `posAtCoords` at the scroll viewport's top edge;
      `save_scroll_line` (debounced 400ms on a new `scroll` domEventHandler + eager on doc-departure in the
       switch `$effect`, coalesced, line-1 = absent); restore via `arm_scroll_restore`/`try_apply_pending` on a
        FIRST-visit open (no in-memory `scrollCache` snapshot = the reload case), `pending_scroll` deferred
         until the doc text lands (disk-reload `$effect`) and the `scrollIntoView` fired in a `requestAnimationFrame`
          to clear CM's post-`setState` measure race (the same race that makes scrollCache use `scrollSnapshot`).
           The in-memory `scrollCache` still owns pixel-exact within-session switches; this is its durable,
            line-grained twin. Verify: scroll a doc, reload → it reopens at that line. Minor TODO: no prune of
             `DocScroll` entries for docs dropped from the Keep ledger (bounded, low; a sweep is future).

### 5. The per-runner CHANNEL — make runners individually pingable (THE networking refactor, → networking agent)
This is the load-bearing fix the rack has been faking around. Owner's review (2026-07-01): *"the beacon is
 the only per-runner signal — this sounds totally insane, refactor it."* Correct. It is a band-aid bolted onto
  a transport that was built **point-to-point** (one editor ↔ one runner) and never grew up to N runners.

**The bomb (why it's like this).** Two collapse points, both keyed by ROLE not prepub:
- **Outbound:** `Peeroleum_send_consumer(w,type,body)` (gen `Peeroleum.go:240`) hardwires to `Pier[0]` — the
   single `Pier:1,pub:'runner'` (the role string, `LiesLies:207`). The relay then FANS that one frame to every
    runner socket. The C2 work (`Peeroleum_send_to(w,pub,…)` gen:256 + `Lies_runner_pier(w,pub)` LiesFunk:918,
     find-or-promote a Pier keyed by real prepub) added per-runner addressing — but **only `become_book` uses it.**
- **Inbound:** any runner frame stamps ONE `channel_peer:runner` slot (`Lies_heard`/`Lies_pong_recv`,
   `LiesLies:729/825/838`), keyed by the role string. So N runners' pongs/phases/results all land on the SAME
    liveness reading; the editor cannot tell which runner spoke. There is no literal `to:'runner'` to grep —
     the collapse is structural (send_consumer→Pier[0], demux→channel_peer:role).

**Consequence (the symptom that sent us here):** per-runner liveness has exactly ONE source — the **advertise
 beacon** (`Lies_advertise`, ~15s, `LiesLies:842`). Everything per-runner (the roster rows, busy/free, dispatch
  eligibility) rides that sparse beacon. So under any socket wobble the 15s beacon is the first frame dropped
   while the 1s ping survives → rows read **offline** while the channel reads **live** (the "offline + phantom
    anon" the rack showed). Liveness must NOT live on a directory announce.

**The frame audit** (`E→R` editor→runner, `R→E` runner→editor):

| frame | dir | today | target |
| --- | --- | --- | --- |
| `become_book` | E→R | `to:<pub>` ✓ (C2) | keep |
| `ping`/`pong` | E↔R | send_consumer (ONE ping, ONE channel_peer) | **`to:<pub>` per runner**; pong carries `from:<pub>` → editor stamps THAT runner's liveness. The core change. |
| `rungo` | E→R | send_consumer | `to:<pub>` — carries a SEQ (run-authority), so allocate the seq **on the runner's Pier**, carefully (`LiesLies:351`) |
| `run_phase` | R→E | send_consumer | `to:'editor'` is fine (one editor) BUT add `from:<pub>` + editor **demux per runner** |
| `run_result` | R→E | send_consumer | `from:<pub>` + correlate verdict→(runner,book) (feeds C3) |
| `advertise` | R→E | `to:'editor'` | keep — but **DEMOTE to a pure directory announce** (I exist + friendly/book/engaged), NOT the liveness heartbeat |
| `ghost_compile`/`grant_offer`/`wormhole_*` | E↔R | send_consumer | decide per frame: compile is for whoever-edits (broadcast OK); grant/wormhole_reply → `to:<pub>`; begs → `from:<pub>` demux |

**The asymmetry to hold in your head:** `E→R` needs per-pub **addressing** (`to:<pub>`); `R→E` needs per-pub
 **attribution** (`from:<pub>` + editor demux). The single editor is fine as a target; the rot is that inbound
  frames neither carry nor are demuxed by `from`, and outbound pings hit one collapsed address.

**The target model.** Each roster runner gets a promoted Pier (`Lies_runner_pier`); the editor pings each Pier
 individually on the keepalive cadence; the pong returns `from:<pub>` and the editor stamps that runner's
  liveness **straight onto its `%Runner` row** (`.c.last_heard`/rtt — the snapped 1:1 roster built 2026-07-01 is
   already the home; `Funk/Rundar.svelte` reads it). Now liveness is REAL per-runner ping, advertise is demoted
    to directory+job-state, and the sparse-beacon fragility is gone.

**Staged next moves (smallest-first; (a) alone kills the symptom):**
- **(a) per-runner ping/pong.** Editor pings each promoted Pier `to:<pub>`; pong carries `from`; editor writes
   the sender's `%Runner.c.last_heard`+rtt. The roster goes live off real pings; the beacon stops being
    load-bearing. *This is the whole user complaint, fixed.*
- **(b) `from:<pub>` on `run_phase`/`run_result` + editor demux** → per-runner progress + (runner,book) verdict.
- **(c) `rungo` per-pub** with the seq allocated on the runner's Pier (run-authority — do carefully).
- **(d) Pier culling + per-Pier inseq baseline** — §2's cull (dead transport, keep the durable HostedIdentity)
   and the `inseq-reload-baseline` cold-cursor fix, which multiplies across N Piers (each Pier its own cursor).
- **(e) demote `advertise`** to a directory announce once (a) carries liveness.

**The UI is already waiting on this, not the other way round.** `Funk/Rundar.svelte`'s rack reads each runner's
 liveness off its `%Runner` row; the moment (a) feeds real per-runner ping liveness into those rows, the rack is
  correct with **zero** further UI work. Don't gold-plate the rack against the broken model — fix the model.

**Confirming field data (2026-07-01, stable socket — the flap was unrelated HMR churn).** With the editor
 socket steady, two roster runners STILL read `offline` — proving it's the model, not the flap. Probed each
  prepub directly with `runner_ask --runner=<pub>` (which sends `to:<pub>`):
- `to:49dee91d` → **answered** (`self:null, advertising:false`). REACHABLE — `to:<pub>` routing works — but it
   reports no identity and never advertises, so its row sits `offline` though it's live. **A real sub-bug:** it's
    hello-bound at the relay as `49dee91d` (the editor can reach that prepub) yet runtime `Clustation_self`
     returns null → advertise suppressed. The hello-bind identity (`Lies_cluster_idento`, signs hello) and the
      advertise/display identity (`Clustation_self` → `active_identity`/`%Identity,active`) are resolved by
       DIFFERENT paths and have DIVERGED. Reconcile them, or §5(a) sidesteps it entirely (ping liveness doesn't
        need the runner to self-identify — the relay already knows the prepub from hello).
- `to:77e2fe94` → **no answer** (timed out). NOT connected — a stale directory entry.
So the beacon model renders "gone" (77e2fe94) and "here but quiet" (49dee91d) IDENTICALLY as `offline`; a
 per-runner ping (§5a) tells them apart in one round-trip. And `to:<pub>` already routing to a live socket is
  the proof the foundation for (a) is sound — it's wiring the ping/pong onto it, not inventing transport.

## Carried (not this thread, but on the board)
- **Shortfall A — generic-C** Waft view** (→ another agent). `ui/Waft.svelte` renders only the `ITEM_TYPES`
   schema (Waft/What/Doc/Point) + Funkcion; unknown mainkeys (WaftTimes, Cursor, HostedIdentity) render
    NOTHING (no `{:else}` fallback in `waftitem`, ~770-806). That's why Keep/Cluster show no `/*` though
     Stuffing shows the tree. Fix = a generic fallback branch, or register the kinds.
- **C3 — StoryTimes fleet fan-out** (Engage_integration §C3): `Lies_storytimes_width` ADDRESSABLE 1→
   `Lies_runner_count`, lease-aware allocator, per-runner inflight, verdict→(runner,book) correlation.
- **favourite_client SET path** (owner-open): editor blesses a runner / runner self-claims into its
   `%HostedIdentity,favourite_client`. The READ (`Lies_favoured_runner`) is built.
