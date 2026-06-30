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
   of-the-cluster, KEEP. Maybe it wants its own visual group (or its own Waft) so it doesn't read as a
    directory row. STILL OPEN: the visual grouping.
- **`Funkcion:Runner` (singleton) — RETIRED (2026-06-30).** It was the proto `%Aim` leftover; "Runner" is a
   FACET of a per-peer `%HostedIdentity` (role:runner), not a cluster singleton. `Lies_cluster_decorate`
    (LiesFunk ~361) now mints ONLY `Funkcion:Relay`, and actively DROPS a stale `Funkcion:Runner` a prior
     build left (self-healing migration — the watch_c save then drops its snap line; the live editor's HMR
      already cleaned `wormhole/Cluster/toc.snap`). The two `Lies_aim` funk lookups
       (`cluster.o({Funkcion:'Runner'})`, runner-side single face + editor empty-roster fallback) are gone —
        those faces now hoist with no singleton funk, reading liveness straight off `w:Lies` (they lose only
         the fade-out transition toast `funk.c.latest`, which §1's real `%Aim` rebuild will restore).
- **STILL OPEN:** the editor's multiplied Runner faces already derive from the `%Runner` roster
   (`lens.c.runner`); the directory→faces wiring is otherwise complete. What remains is the Relay visual
    grouping and any "describe the latest event" `%Aim` caption — owner-supervised at the live Brink.

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
   entry (`Lies_aim` ~411-434, `lens.c.runner` = the `%Runner`). Needs a clean stacked layout — the Lens
    posable/altitude work, see [Lens_posable_TODO.md](Lens_posable_TODO.md).
- **Boot-race re-read (DONE 2026-06-30).** `Lies_advertise_recv` (LiesLies) now kicks
   `Lies_open_Waft{path:'Cluster'}` when the registry isn't loaded yet — an advertise that beats the Good
    pipeline at boot no longer silently drops the runner; the snap loads (a returning runner is already in
     it) and the next ~15s beacon mirrors a fresh one.

### 3. Cursor not resuming (bug — built but not firing)
The machinery is all there: `Lies_keep_mark_focus` records the Keep's latest `%Cursor` (`Lies.svelte:222,
 982`); `Lies_keep_resume_what` returns it on foreground as a `kind:'cold'` want (`Lies.svelte:228-229`);
  the Langoer boomerang arbiter (`Lies_focus_waft` / req:Langoer, ~1054-1077) lets a DELIBERATE move
   outrank a cold resume but is meant to LET the remembered spot win at boot. **Next move:** trace a boot/
    foreground and find where the cold want dies — is `mark_focus` recording the right What? does
     `keep_resume_what` resolve the locator (or has the What moved/renamed)? is the cold Cursor being
      out-competed when it shouldn't be (the boot case, not mid-session)?

### 4. Save CodeMirror scroll as a line target (new want)
Persist the scroll position of the latest Cursor's editor as a **LINE number** (NOT pixels/Q-factor — so it
 survives a different zoom/wrap), on the Keep's `%Cursor` beside the per-Waft cursor (the cursor model near
  `Lies.svelte:1000`). Reopening then restores What + scroll-line. Read the top visible line on blur/cursor-
   record from the CodeMirror view (Lang side); restore via a line `scrollIntoView` on open.

## Carried (not this thread, but on the board)
- **Shortfall A — generic-C** Waft view** (→ another agent). `ui/Waft.svelte` renders only the `ITEM_TYPES`
   schema (Waft/What/Doc/Point) + Funkcion; unknown mainkeys (WaftTimes, Cursor, HostedIdentity) render
    NOTHING (no `{:else}` fallback in `waftitem`, ~770-806). That's why Keep/Cluster show no `/*` though
     Stuffing shows the tree. Fix = a generic fallback branch, or register the kinds.
- **C3 — StoryTimes fleet fan-out** (Engage_integration §C3): `Lies_storytimes_width` ADDRESSABLE 1→
   `Lies_runner_count`, lease-aware allocator, per-runner inflight, verdict→(runner,book) correlation.
- **favourite_client SET path** (owner-open): editor blesses a runner / runner self-claims into its
   `%HostedIdentity,favourite_client`. The READ (`Lies_favoured_runner`) is built.
