# Runner_network.md — how a runner gets (and keeps) its relay connection

> **SLATED TO FOLD into `Cluster_spec.md` §3** (the runner flock). Authoritative until then; the
> consolidation plan + order live in `Robustness_plan.md` (Closeout section, top).

> **The "relay down" wedge has a named root cause: latched channel state.** `w.c.channel_up`
> (`LiesLies.svelte:319`) and `w.c.transport_up` (`:346`) are **set once and cleared nowhere** — an
> HMR remix that strips `Socket_real` leaves the latch asserting "up" while standup never re-runs.
> Fix = derive from `Socket_real` presence / clear-on-teardown. See `Robustness_plan.md` (Organ 1) for
> the full latched-flag audit and the prioritized cure.

The one-page map of the stack that took a session of logging to see. Read this FIRST when a
 runner sits at "relay down". Depth lives elsewhere: `Peeroleum_spec.md` (envelope/spine),
  `Wire_spec.md` (framing), `Cluster_spec.md` (identity/trust/grants/leases),
   `Wormhole_backends_handover.md` (disk navs), `Runner_quality_handover.md` (liveness/dispatch),
    `Cluster_runner_handover.md` (roster/rack).

## The layers, bottom-up

- **`/relay`** (`src/lib/server/relay.ts`) — the dev server's websocket hub, node-side. Routes
   envelopes by `header.to`; binds a socket to a role on `control:become` (set-once, repeat-same
    is a no-op) and to a VERIFIED identity on signed `control:hello` (`prepubOf(pub)` → socket);
     bridges relay↔relay across origins (r2r, auto-redial server-side); executes `gen_write`
      (it has fs; the browser doesn't). Restarts with the dev server.
- **`Socket_real`** (`Ghost/N/Tribunal.g` → `gen/N/Tribunal.go`) — the browser ws client. Dials
   own-origin `ws(s)://<host>/relay?addr=<role>`, auto-reconnects with backoff, buffers real
    frames while down (drops ephemerals: ping/pong/ack/run_phase), speaks the
     `[header JSON]\n[raw buffer]` binary framing. `port.on_open(cb)` hooks re-fire on EVERY
      (re)connect — that's how become/hello survive a reconnect.
- **Peeroleum** (`Ghost/N/Peeroleum.g`) — the envelope spine: `%Peering`/`%Pier` particles,
   seq/inbox/outbox, `Peeroleum_on` / `Peeroleum_send_consumer` / `Peeroleum_deliver`.
    `Reliable.g` (inseq/retx) and `Tyrant.g` (admission) ride this layer.
- **Lies, the consumer** (`LiesLies.svelte` `Lies_channel_up`) — lays the Peering/Pier on
   `w:Lies`, calls `Socket_real`, piggybacks `become` + signed `hello` on each open, registers
    the app frame handlers by role (runner: rungo/become_book/runner_ask/grant_offer/
     wormhole_reply; editor: run_result/run_phase/ghost_compile/advertise/wormhole_beg/
      wormhole_req; both: ping/pong), stamps `w.c.channel_up`, and starts the OFF-think
       keepalive timer (liveness must not ride the belief loop).
- **Above that** — advertise beacons → the editor's `%Runner` roster (Rundar rack);
   engage/dispatch (`to:<prepub>`); and the remote Wormhole, which is just another consumer
    frame pair (`wormhole_req`/`wormhole_reply`) carrying a signed `%Grant` per op.

## Who dials, exactly when

- **The runner rides the LIVE gen** (`CREDULER_GHOSTS` → `gen/N/*.go`); **the editor rides the
   FROZEN copy** (`p2p/pinned_stable/*.go` — it can't ride the spine it's actively editing;
    re-copy gen → pinned by hand to promote). Consequence, worth tattooing: **a broken
     `gen/N/Tribunal.go` breaks EVERY runner while the editor stays green** — the asymmetry is
      the tell.
- `Lies_channel_up` is called every tick from the **TOP of `LiesPersist`** (`Lies.svelte`).
   As of 2026-07-03 the standup rides ABOVE the Waft `%Good` loop — it used to sit at the tail,
    below the loop's `return false` exits, which was a deadlock for any runner whose disk needs
     the channel (failure mode 2 below). The connection layer must not wait on anything the
      connection serves.
- Its guards, in order — each early-returns; only the third now rings the Relay Brink:
   1. role not editor|runner (bare Lies: no socket, ever)
   2. `w.c.channel_up` already stamped (idempotence)
   3. `typeof H.Socket_real !== 'function'` — transport ghost not deposited (see failure mode 1)
   4. no `WebSocket` global (node/tests)
- Per (re)open, via `on_open`: `control:become` (role bind, unauthenticated) then signed
   `control:hello` (identity bind — `Lies_cluster_idento` read live each open, so an Id switch
    rebinds without a reload).
- **Announce cadence — how fast the far side learns about us** (2026-07-04). Steady state: a **ping**
   ~5s (liveness → clears "dialing"/"silent") and an **advertise** ~15s (`ready|book|engaged|ac` — the
    roster facts). Two shortcuts beat the throttle: (a) **on open**, `on_open` fires an immediate ping +
     advertise (throttles cleared, `socket_heard` stamped so the watchdog won't tear the fresh socket;
      NOT via `Lies_keepalive`, whose DEAD check would fire on stale pre-drop `heard`) → a (re)connect
       clears "dialing" in one RTT; (b) **on a facet change**, `Lies_advertise` re-beacons at once when
        `book|engaged|ac` differs from last sent (a `sig` compare) → a run start|end, lease take|release,
         or tap-for-sound reaches the editor's roster + allocator (`Lies_dispatch_target`) within a
          keepalive tick, not 15s. `Lies_ac_nudge` (from the Sound Brink) makes the AC case instant; the
           ping never carries these facets, only the advertise does.

## What each Brink badge actually asserts

- Relay face **"⚠ relay down"** / Rundar **"→EDITOR (no channel)"** — `Lies_channel_live(w)`:
   `w.c.channel_up` stamped AND the active transport holds a connection. It speaks about OUR
    socket, nothing else.
- **The remote-Wormhole badge — TWO AXES, never merged** (`Lies_remote_wormhole_reconcile`, per
   heartbeat). The badge reads `w.c.wormhole_grant_status` (the CRYPTO verdict) + `channel_live`
    (liveness), and NEVER a sticky "installed once" flag:
  - **crypto axis** `wormhole_grant_status` ∈ `absent | invalid | valid`, computed locally by
     `Lies_wormhole_verdict` — `verify_grant` (ed25519 sig) + `browserTrustedPubs` (issuer is one of
      OUR editors) + `for` pins it to this runner. `invalid` (forged / stale / foreign) is a LOUD red
       "⚠ INVALID grant", the atom is discarded from `.stashed` and the runner RE-BEGS (owner call:
        refuse, don't present it). `wormhole_state === 'ready'` is now *derived* — it means crypto-valid,
         full stop, so the badge can never say "granted" over a dead grant.
  - **liveness axis** `channel_live`: a valid grant + silent editor reads **"🛰️ grant valid · editor
     not answering — ops stall"**, not a bare "granted". Grant-held + relay-down is a real state.
  - **ONE durable home**: top-House `.stashed` (survives reload), the sole authority. There is no
     `Waft:Cluster` grant copy any more — that best-effort second home could be wiped by an empty
      registry read, making the grant "disappear" while the badge lied "granted"; it is gone.
      `Lies_wormhole_grant` reads `.stashed` only; a wiped/expired grant self-heals (re-beg → re-grant).

## Failure modes, with the diagnostic ladder

**1. Cross-wired / miscompiled gen — the "doesn't even try" wedge (2026-07-03).**
 `gen/N/Tribunal.go` was byte-identical to `Peeroleum.go` except the Ghostmeta name: Peeroleum's
  compile output, written to Tribunal's gen path, stamped with Tribunal's Ghostmeta. So
   **"Creduler ready — N ghost(s) live" only proves each Ghostmeta answers a dige, NOT that the
    right methods deposited** — `Socket_real` never landed, guard 3 returned silently forever,
     and no runner dialed while the editor (pinned copy) stayed green. The ladder:
  - Network tab: **zero** ws attempts to `/relay` → the dial never happened → walk the guards.
  - `grep -c Socket_real src/lib/gen/N/Tribunal.go` — ≥3 is healthy; 1 (a comment) = cross-wired.
  - duplicate-dige sweep (two gen files sharing a dige = one source at two paths):
    `for f in $(find src/lib/gen -name '*.go'); do echo "$f $(grep -o "return '[0-9a-f]*'" $f | head -1)"; done | sort -k2 | uniq -Df1` — eyeball for repeats.
  - fix: recompile headless, no browser needed —
    `GFILES="Ghost/N/Tribunal.g" node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts`
    — Vite HMRs the fresh `.go` into open tabs and the eatfunc re-deposits on re-mount
     (methods DO re-mix on hot update), so a wedged runner usually self-heals without a reload.
  - the upstream cause (open): the editor's ghost-compile round wrote one dock's output to
     another's gen path — suspect the compile-source-as-param seam (`lakerace-compiler-fast`)
      pairing text and `gen_path` from different docks under a multi-file round. Un-caught.

**2. Channel-after-disk deadlock (FIXED by the standup reorder; shape kept for the pattern).**
 A `&remoteWormhole=1` runner's disk ops round-trip the channel. With the standup at
  `LiesPersist`'s tail, an unlanded Waft `%Good` returned false ABOVE it every tick: the read
   gums the tick → the standup never runs → the ws never dials → the read can never land. It
    "escaped" only via failure mode 3's lie, 20s at a time. The rule the reorder encodes:
     **connection first; disk settles through it.**

**3. Error-lands-as-empty (OPEN — the registry lie).**
 `LiesStore_land_good` maps a reply of `{error}` (nav not ready, remoteWormhole timeout…) to
  `content: ''` — a failed read is indistinguishable from an empty file. That's the
   "🗂 Waft:Cluster empty — starting empty" you see on a broken disk: the identity registry
    silently starts over. Ought to park-and-retry (leave `c.content` undefined) instead of
     landing. Related: `Wormhole_park`'s queue is serial — one in-flight op per queue — so with
      the channel down every remote op holds the slot its full `REQ_TIMEOUT_MS` (20s): the disk
       degrades to a 20s-per-op crawl, and a queued write error surfaces minutes late.

**4. Begun-wedge (memory: `runner-wedge-begun`).**
 `become_book` accepted, `phase:begun` forever, for EVERY Book — tab-level (a stuck
  `%Creduler_pending`, a dead Auto elvis). Differential-test with a known-green Book (MusuSkip);
   if that wedges too it's the tab, not your Book. `runner_ask` has no reload op — human reload.

**5. Relay / dev-server restart — self-healing, by design.**
 `Socket_real` re-dials with backoff; become/hello re-fire per open; the r2r bridge re-dials
  server-side. Half-open sockets are the watchdog's job (LIVE/SLUGGISH/DEAD in
   `Lies_keepalive` — only DEAD re-dials; SLUGGISH means heard-but-no-pong: do NOT tear it).

## Proving it from the CLI

`node scripts/runner_ask.mjs ping` — one green round-trip proves the whole path: relay up, the
 runner's ws bound, consumer dispatch alive. It reports `{role, channel, self, advertising}`.
  `state`/`steps`/`rungos` ride the same path. If `ping` times out but the editor works, think
   failure mode 1 (runner-only transport) before anything else.

## Hardening — four spin-outs (open, 2026-07-05)

A and B harden **liveness** (tolerate a sleepy tab / keep it warm). C and D came out of the
 2026-07-05 socklog dig (`wormhole/_socklog/`) and harden **wire correctness** and **standup**.

**A. The fatal "tab is dead" timeout belongs to the networking layer, not the CLI.**
 The layer already owns a *graded* liveness verdict, and it's a good one: `Lies_keepalive`
  (`LiesLies.svelte:1037`) reads **SLUGGISH at 9s** (`SLUGGISH_MS` — heard *something* inbound but the
   pong is late: the peer is busy / think-quiesced, and the doc's own rule is *do not tear it*) and
    **DEAD at 20s** (`DEAD_MS` — nothing inbound at all: the carrier really is gone, re-dial); the
     editor's roster then lapses a runner's live claims at **45s** (`LIVE_MS`, `:1218`) and culls its
      Pier at 5min. So "how long until dead?" is already answered — **20s of total silence** — and
       answered with a busy-but-alive band deliberately sitting beneath it. The `runner_ask --watch`
        false-RED is exactly the bug of *ignoring* this: its 8s per-poll bail fires *below even
         SLUGGISH*, declaring death before the layer would call the peer merely sluggish. The cure is
          not a bigger magic number in the script — it is to make liveness **one verdict the CLI reads
           too**: factor the SLUGGISH/DEAD/LIVE thresholds into a single place (a `Lies_liveness(w)`
            verdict fn, or at minimum exported constants) so the rack, the reaper, and `runner_ask`
             share one definition of dead, and `--watch` tolerates missed polls up to `DEAD_MS` before
              reporting failure. During an active run there is also *positive* evidence a raw timeout
               throws away: `run_phase` step_done blips and advancing `Storyrun` state mean alive — the
                watch loop should reset its death-clock on **progress**, not only on a poll answering.
                 Net: fatal = *20s of no answer AND no state progress*, sourced from the layer's own
                  constant, never an 8s number invented in a script.

**B. Make the runner tab less go-to-sleepy — audio-keepalive first, PWA for the fleet.**
 The root of the missed-ping / false-DEAD churn is the browser itself: a backgrounded tab gets its
  timers throttled (the off-think keepalive `setInterval` clamped), then the Page Lifecycle machinery
   can *freeze* and even *discard* it — a runner that is alive but hidden reads SLUGGISH→DEAD through no
    fault of the spine. Cheapest, highest-leverage lever: a **silent keepalive AudioContext node** (a
     muted oscillator → `gain(0)` → destination). A tab playing media is flagged as such by the browser
      and exempted from the worst timer-throttling and is far less likely to be frozen or discarded —
       and it aligns with what we already have, since a runner granted AC (the `needAC` gate) is
        *already* the tab we most want kept warm; the muted node costs ~nothing. Next, wire the **Page
         Lifecycle API**: on `resume` / `visibilitychange`-visible, fire the same instant re-ping +
          re-advertise the socket `on_open` already does (`LiesLies.svelte:283`), so a thaw clears
           "silent" in one RTT instead of waiting a keepalive tick; and on `freeze`, emit an "I'm going
            cold" advertise so the editor marks the runner *parked* rather than lying DEAD. For a real
             runner **fleet**, promote to an **installed PWA** (manifest + a thin service worker,
              standalone window): installed PWAs are throttled less aggressively and are much less likely
               to be discarded under memory pressure, and they give a stable home for many runner
                windows; `navigator.wakeLock` only helps while visible and `periodicSync` support is
                 thin, so neither is load-bearing. The honest caveat: none of this *defeats* background
                  throttling — a hidden tab will still be slowed. That is why A and B are complementary,
                   not either/or: **A makes us tolerant of a sleepy tab (never false-red / false-dead),
                    B makes the tab less sleepy.** Ship the audio-keepalive as the cheap 80%; the PWA is
                     the fleet-grade hardening for when we run many runners at once.

**C. The reconnect-epoch seq collision — re-ack a dup + reset the Pier epoch (spine; the *real* cure is
 editor-side, so it waits on the next re-pin).**
 Wire-confirmed 2026-07-05: a runner that **reloads** restarts its per-Pier outbound seq LOW, but the
  editor's Pier for it is REUSED (the editor didn't reload) and still remembers the old high-water. The
   fresh `wormhole_req seq=6` hits an already-`%finished` `%req:unemit` at that seq (`Peeroleum_book_unemit`'s
    `oai({req:'unemit',seq,type})` *finds* it instead of creating one), `inbox.do()` skips it as done, and
     the ack is emitted *inside* `req_unemit` — so the frame is dropped with **no ack, no reply, no trace**.
      The read then dead-waited the full 20s `REQ_TIMEOUT` and only self-healed once the seq organically
       climbed past the stale high-water (observed: recovered at `seq=14`). This is the epoch gap the
        Peeroleum spec flags under heading 8: a frame's identity is `(epoch, seq)`, but only `seq` is checked.
  - **Shipped (runner-side, no re-pin):** `RemoteWormholeNav.send` now does an **ack-gated re-emit** — every
     `RETRY_MS`=4s, if the last emit's `%outbox/emit` is *not* `%acked` (the collision, or a real loss) it
      re-emits with a **fresh seq** (climbs past the high-water; same corr so the reply still matches; ops are
       idempotent so a double-land is harmless); if it *is* acked it just waits (the request landed, the reply
        is merely slow — re-sending a 400 KB `bin_write` would be waste). A 20s mute stall → a ~4-8s loud
         self-heal (`🕳↻` / `🕳…`). This already removes the user-visible symptom.
  - **Owed (editor-side, FROZEN `pinned_stable` — needs a re-pin, do NOT do blind):** (i) **re-ack a
     delivered-dup on the reliable path** — the *lossy* inseq path already re-acks a dup (`Peeroleum_deliver`,
      the `seq ≤ last` branch), but the reliable path leans on the `oai`-dedup and never re-acks, so the stale
       colliding emit also retx's forever; (ii) **reset the Pier's inbox/inseq epoch on a re-hello**, so a
        genuinely-new post-reconnect request is not mistaken for a dup — the *real* cure for the missing REPLY.
   **Gotcha — (i) and (ii) must compose:** re-ack *alone*, combined with the shipped ack-gated retry, makes the
    runner **dead-wait** (it sees "acked → landed → wait", but the reply never comes because the frame was
     still dropped as a dup). Lab it as a **PereProof** step: `Lake_reset_arm` (`Peregrination.g:500`) already
      builds the exact stale state (`inbox unemit seq:7,done:1` + `inseq.last:7`); the missing case is the
       *asymmetric* reconnect where only ONE side reset. Build the step **at** the re-pin, not before — a green
        test guarding code the editor doesn't yet run is an orphan.

**D. `channel_up` once-guard — traced 2026-07-05, verdict OVERSTATED, no action.**
 The relayed *"highest-leverage"* claim (the once-guard — `Lies_channel_up`, `LiesLies.svelte:219` — makes other
  runner fixes land unreliably) does **not** hold: frame handlers are pure dispatch to live `H.Lies_*` methods
   (`:302-334`), so a method-body fix lands on HMR via re-mix regardless of the guard. The guard blocks only
    re-**standup**, whose two real failures are already handled (`Socket_real`-vanished P1 reconcile `:214`;
     cross-wired gen note `:226`). Optional residual, if ever wanted: split the idempotent `on(...)` registration
      to run every pass so a changed handler *type* re-registers without a reload — small, bounded, not
       load-bearing. (Lies-layer, above the mock-carrier spine — so not a PereProof step.)
