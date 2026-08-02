---
name: engage-c2-dispatch
description: "Engage_integration C2 (to:<prepub> addressed dispatch) BUILT+verified headless; the live-path insight that collapsed the brief's handshake/inseq fear"
metadata:
  node_type: memory
  type: project
  originSessionId: f0479bcc-815c-423c-b7b3-65406dfb41f5
---

2026-06-30. `src/lib/O/spec/Engage_integration.md` = the Peeroleum/runner agent's handoff TO the Lies/editor machine: an "editor reserves a runner for a client, that client drives it offline" scheme. Three editor pieces (C1 favourite_client set-path, **C2 `to:<prepub>` dispatch**, C3 StoryTimes fleet fan-out); **C1+C3 both sit on C2** = the load-bearing one.

**C2 BUILT + verified headless, uncommitted:**
- `Peeroleum_send_to(w, to, type, body)` in `Ghost/N/Peeroleum.g` (compiled to `src/lib/gen/N/Peeroleum.go` via [[localgen-browserless-compile]]) — addressed twin of `Peeroleum_send_consumer`: picks the Pier by `peering.o({Pier:1}).find(p => p.sc.pub === to)` instead of `[0]`, allocates ITS seq, sends `to:to`. Absent Pier → undefined.
- `Lies_runner_pier(w, pub)` in `LiesFunk.svelte` — find-or-PROMOTE the editor's Pier to a runner prepub (mirrors `Lies_channel_up` seed LiesLies:205-209: `oai Pier` + `c.up` + `Ud`).
- addressed `Lies_send_become_book(w, book, to?)` — `to` set → promote + `send_to`; absent → legacy role-broadcast `send_consumer`.

**THE INSIGHT that collapsed the brief's feared complexity** (handshake + per-Pier inseq baseline): the LIVE editor↔runner relay path is **trust-everything-v1 over the RELIABLE relay**. `Lies_channel_up` mints the Pier and stamps `Ud` directly — NO handshake (hello/trust). And a reliable carrier books STRAIGHT (`Peeroleum_deliver` Peeroleum.g:443, `reliable = conn?.reliable !== false`), skipping inseq entirely — the comment at :438 is explicit (reconnect dedup is the epoch handshake, "not a cold-start re-baseline smeared on deliver"). So the inseq-per-Pier-baseline worry ([[inseq-reload-baseline]]) is the test-swarm/Tyrant model, NOT the live relay; promotion = `oai Pier + c.up + Ud`, nothing more. Today's single Pier is keyed `pub:'runner'` (a ROLE string, relay routes by `become role`); per-runner = key by the runner's **prepub** — the relay already routes `to:<prepub>` (the signed `control:hello` LiesLies:232 binds `prepubOf(idento.pub)`→socket). Roster = `%Runner,<prepub>` (`Lies_advertise_recv`, keyed off advertise body `from: self.prepub`); the multiplied Runner Brink (`Lies_aim` LiesFunk:392-406) mints one `Lens:Brink,of_Funkcion:Runner,pub:<X>` per entry, `lens.c.runner`=the entry — the C1 gesture surface.

**VERIFIED:** `scripts/SendTo.spec.ts` (Creduler-acquire boot like [[creduler-runner-architecture]]/CredulerProbe → mint PRODUCTION topology = 1 Peering + 2 Piers → assert `send_to(B)` books emit+seq on B/A untouched/unknown→undefined + `Lies_runner_pier` promotes Ud-stamped idempotent). GREEN. NB the `.find` pub-select branch is **production-only** — the co-resident swarm runs 1 Pier per Peering so `Peeroleum_route`'s length===1 shortcut never hits `.find`; this spec is the ONLY coverage. Type-clean (LiesFunk diagnostics in-range are all baseline House-noise).

**C1 — CORRECTED by owner + BUILT (uncommitted).** NOT the brief's set-path (no `favour` frame, no runner receiver). It's a pure READ: the client looks up the `Waft:Cluster/%HostedIdentity` that favours its own Identity. Built in LiesLies: `Lies_advertise_recv` now auto-vivifies `%HostedIdentity,<pub>` (dontSnap, under the Cluster Waft) mirroring the beacon's `favourite_client`; `Lies_favoured_runner(w, client?)` = find the HostedIdentity favouring `client` (default `Clustation_self.prepub`), return its pub = the `to:<prepub>` dispatch target. Verified in `SendTo.spec.ts` (favours CLIENTY→RUNX; unfavoured→undefined). The SET (a runner declaring its `favourite_client`) is the identity-hosting layer's (Clustation/Auto + other agent), NOT the editor's.

**C3 — display half BUILT (owner-directed), allocator half PENDING.** Built: the runner advertises `engaged` (the live-lease client pub, from `Lies_engagement` status==='active') → `Lies_advertise_recv` captures it onto `%Runner` (+ feeds the allocator later) → `Funk/Runner.svelte` Brink shows **running ▸ engaged ▸ free** (new `.rp-engaged` ◑, title shows engaged-by). Type-clean; **browser-verify the Brink**. STILL PENDING (the live-sweep-touching part, browser-verify WITH owner): lift `Lies_storytimes_width` ADDRESSABLE 1→`Lies_runner_count`; allocator picks a free runner (skip `engaged` ≠ me, prefer `Lies_favoured_runner`); per-runner `inflight`; verdict→(runner,book) correlation. Live two-tab editor→specific-runner dispatch is owner :9091 territory.

Uncommitted C-work surface: `Ghost/N/Peeroleum.g` + `gen/N/Peeroleum.go`, `LiesFunk.svelte`, `LiesLies.svelte`, `Funk/Runner.svelte`, `scripts/SendTo.spec.ts`.
