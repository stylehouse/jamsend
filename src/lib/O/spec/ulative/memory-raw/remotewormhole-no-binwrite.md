---
name: remotewormhole-no-binwrite
description: "the Wormhole nav contract (read_file/write_file/bin_read/bin_write/read_range/dir/dir_at) is now COMPLETE across all 4 backends — remote bin_write built, OPFS+node gaps closed; remote path live-unverified pending tab reload"
metadata: 
  node_type: memory
  type: project
  originSessionId: a060c31b-3f6c-4aa7-b1a5-fa5fe9c87f36
---

**RESOLVED 2026-07-05 (was: MusuGenerateTestsMusic "does nothing" on a &remoteWormhole runner).** Root cause:
 `RemoteWormholeNav` was a PARTIAL nav — no `bin_write` — so a WAV-writing Book surfaced it as "no writable
  share" three layers away (Robustness_plan.md Organ 5). Owner directive: **remoteWormhole must be the FULL
   Wormhole protocol — no "doesn't do this subset" cases.** See [[full-contract-no-subset-gaps]].

**The full nav contract = 7 caller-facing methods:** `read_file · write_file · bin_read · bin_write ·
 read_range · dir · dir_at` (`mkdirp` is an internal helper, not a remote op). No caller anywhere uses a
  method outside this set (grepped: no delete/rename/stat). Now implemented on ALL FOUR backends:
- **WormholeNav** (FSA, Housing.svelte.ts) — always had it.
- **RemoteWormholeNav** (remote proxy) — bin_write added by another agent: `send('bin_write',{path},bytes)`
   rides a RAW binary consumer frame (`Lies_send_binary_consumer` — bytes on frame.buffer, meta on header,
    body_hash-integrity, off-snap); editor serve `Lies_wormhole_req_recv` grew an `op:'bin_write'` branch
     (ro-guarded) → `nav.bin_write` → JSON `{ok}` reply (rides the reliable corr-matched broadcast, not the
      unaddressed replyBIN residue).
- **OpfsOverlayNav** (cloud, WormholeOpfs.svelte.ts) — bin_write added by me (scratch-layer write, raw bytes).
- **NodeWormholeNav** (harness, scripts/) — was worst (only read_file/write_file/dir); I added bin_read,
   bin_write, read_range, dir_at (node fs; read_range is a real fd window, not slurp-then-slice). tsc-clean.

**LIVE STATUS:** editor serve is a House method (HMR-remixes live); but a runner holds its `RemoteWormholeNav`
 INSTANCE from boot, so the remote bin_write round-trip is **:9091-UNVERIFIED until the runner+editor tabs
  RELOAD** (re-instantiate the nav). Confirmed: a run now still writes nothing (old instance). After reload:
   `runner_ask run MusuGenerateTestsMusic` should write 8 WAVs to the editor's disk. Also: option (a)
    nav-precedence landed — granting a LOCAL FSA share on a &remoteWormhole tab now uses WormholeNav (bin_write
     for free), Robustness_plan.md P2. Related fix (UNCOMMITTED, LiesFunk): gen budget 30→120 + bounded write.
      `testsounds/` is gitignored/generated. See [[ttlilt-in-snap-means-timeout]].

----
## merged from remotewormhole-grant-honest-durable.md

---
name: remotewormhole-grant-honest-durable
description: "remoteWormhole grant made HONEST + DURABLE 2026-07-04: badge derived from a live crypto verdict (not a sticky flag), .stashed the sole home, self-heal re-beg on invalid/absent; :9091-unverified"
metadata: 
  node_type: memory
  type: project
  originSessionId: 7d992ead-6ef2-4f82-85d7-85669ab9454f
---

The remoteWormhole **grant state was lying and undurable** — sorted 2026-07-04 (owner: "no lying… the Grant crypto is supposed to work or not work and that's an important signal to PUT SOMEWHERE"). :9091-unverified (couldn't run svelte-check — the root-owned `.svelte-kit/types/.../BigWordland/$types.d.ts` blocks sync's rimraf; [[running-check-in-container]] gotcha, now HARD — verify live).

**The two bugs found:**
- The **"🛰️ Wormhole granted" badge was sticky**: `wormhole_state` was set to `'ready'` once at first nav-install and NEVER cleared/re-checked (`is_remote` short-circuited install). So it read "granted" over a long-dead grant — beside "⚠ can't download … stuck 358s".
- The **grant had no reliable durable home**: `stashed.wormhole_grant` was written in ONE guarded spot (`if (top?.stashed)`), skipped on the registry-install path / stashed-not-ready; the `Waft:Cluster` registry copy (the other "home") gets **wiped by an empty/not_found read** (HostedIdentity rows re-mint via claim_self, the `%Grant` child does NOT → "HostedIdentity but nothing inside"). Net: grant in NO durable home, only the in-memory nav closure. Also the Housing `.stashed` save `$effect` keyed on `Object.keys(...).length`, so a value OVERWRITE (re-grant) never re-persisted.

**The fix (all in LiesFunk.svelte unless noted):**
- `Lies_wormhole_verdict(w, atom)` — LOCAL crypto verdict, 3-valued: `absent | invalid | valid` = `verify_grant` (ed25519) + `browserTrustedPubs()` (issuer is one of OUR editors — skipped if unconfigured). **IDENTITY-STABLE: it does NOT check `for`** — that's done ONCE at acceptance (`grant_offer_recv`). Re-checking `for` every heartbeat DISCARDED a good grant whenever Lies_self/Clustation_self blipped to a different/undefined prepub → "accept→discard→beg forever, never stores" (the 2026-07-04 regression, fixed same day). Reconcile must only ask "is the grant I hold still crypto-real", never "who am I this ms".
- `Lies_wormhole_status_set` — stamps `w.c.wormhole_grant_status` + `wormhole_grant_reason`, derives `wormhole_state` (`'ready'` ⇔ crypto-valid, full stop), bumps + console-logs transitions. The signal, put somewhere.
- `Lies_remote_wormhole_reconcile` (replaces `_step`, pumped from `Lies_aim` each heartbeat, async, re-entrancy-guarded + verify-cache on `wh_verified_sign`): valid→install; absent→beg; **invalid→DISCARD from .stashed + re-beg** (owner call: refuse, don't present it). `_uninstall` tears the nav down (reads PARK, no zombie 20s-timeouts). Self-heals a wiped/expired/foreign grant with no reload.
- `.stashed` is the **sole authority** — `Lies_wormhole_grant` reads it only; the `Waft:Cluster` grant copy is GONE (no more `grant_to_C`/`grant_of_C`). `grant_offer_recv` verifies-before-storing (+ `w.c.pending_grant` fallback if stashed not ready).
- Housing `.stashed` save `$effect` now deep-reads (`void JSON.stringify`) so a re-grant persists.
- **Badge = TWO AXES, never merged** (owner design call): crypto (grant_status: red "⚠ INVALID grant · re-begging" / green "granted · crypto valid") vs liveness (green if channel_live, else amber **"grant valid · editor not answering — ops stall"**). Rundar.svelte full + mini + `.rp-bad`. Runner_network.md §badge updated.

**Editor-not-replying — REAL, root-caused + FIXED 2026-07-04.** Once the flap was fixed (stable grant), the editor socklog showed it RECV every `wormhole_req` (seq 6→64) and emit ZERO `wormhole_reply`. The serve handler replies on every branch, so the reply was DROPPED IN TRANSIT: it was addressed `to: claim.for` (the identity the grant was MINTED for), but a runner has TWO identity tiers (Lies_self vs Clustation_self) and hello-binds/routes on one while the grant's `for` may be the other → `Peeroleum_send_to(claim.for)` routed to nobody. (`become_book` works because it's addressed to the LIVE roster prepub, not the frozen `claim.for`.) This is the "identity-divergence / `to:claim.for` routing" bug flagged as owed in [[remote-wormhole-built]]. FIX: `Lies_wormhole_req_recv` `replyJSON` now uses `Peeroleum_send_consumer` (consumer BROADCAST, corr-matched) — the runner matches by corr on its nav regardless of tier, other runners drop an unknown corr; same reliable path grant_offer rides. Binary replies (bin/read_range) still addressed → same latent risk (TODO: corr-route binaries); reads/lists are JSON so the Cluster toc + source reads are covered. Added DIAG logs `🛰️← wormhole_req` / `🛰️→ wormhole_reply` in the editor handler (remove once confirmed). Socklogs: `wormhole/_socklog/{editor,runner}-<pub>-*.jsonl`. See [[remotewormhole-mutex-deadlock]].

Also this session: Liesui **stuck-download alert** (a Store `%Good` whose content never lands after 5s → red "⚠ can't download <path> stuck Ns", derived off the read watchdog's `.c.asked_at`/`.c.last_error`); read-watchdog first-complaint 10s→5s. Related root smell = the [[see-is-not-a-latch]]-adjacent "unconfirmed not_found": the FSA/wormhole read conflates "absent" with "couldn't fetch"; a false not_found still resets+saves an empty registry Waft (the wipe door) — the Waft-provision path lacks the toc's `notfound_once` re-ask. Proper fix = authoritative-absence / tri-state read (present|absent|unavailable), NOT YET done.

----
## merged from remotewormhole-mutex-deadlock.md

---
name: remotewormhole-mutex-deadlock
description: "&remoteWormhole=1 (was &disk=proxy) runner self-deadlock: rw ops awaited UNDER the beliefs mutex starve their own wormhole_reply → every op 20s-timeout; FIXED via Wormhole_park (Atime-async navs run OFF Atime); :9091-unverified"
metadata: 
  node_type: memory
  type: project
  originSessionId: df518fb5-3eee-4895-a44a-b50d08a9f04f
---

The 2026-07-03 `&disk=proxy` live test hit a **mutex self-deadlock**. FIXED (:9091-unverified) — fix at the bottom.

**The loop:** the `Wormhole` actor (Housing.svelte.ts) did `await nav.read_file(...)` **inside a beliefs pass** — `_really_answer_calls` holds `H.mutex('beliefs')` around the whole elvis. Local navs resolve off-loop (disk), harmless; `RemoteWormholeNav.send()` awaits a relay round-trip whose reply arrives via Tribunal `on_message` → `Lies_deliver_soon` → `post_do` → `answer_calls` → **blocked on the very mutex the await holds**. Reply can't land; op rejects at `REQ_TIMEOUT_MS = 20_000`; mutex releases; the whole inbound batch flushes at once; the next queued rw op re-seizes for another 20s. The runner spends ~100% of its life mutex-blocked.

**Proof (socklog, twice to the ms):** first wormhole_req t=351159 → pongs seq 7,8 flushed together t=371237 (+20.08s); socklog-write req t=371388 → pong seq 13 t=391484 (+20.10s).

**All symptoms are downstream of this one cause:** Waft:Cluster never loads (each read = 20s→fail→re-dispatch) → the Brink shows "no channel" the instant you Vexpandy the MiniBrink, then eternal "silent Ns" (channel_peer stamped only by DELIVERED frames; the runner's own pings ride the off-mutex keepalive timer, so the WIRE pingpongs fine while the UI reads dead — `heard`≈0 also skips the re-dial, so no flap); become_book/rungo sit in the batch → no runs. The [[socklog-scaffold]] aggravates: a fresh 20s-blocking remote WRITE every 10s.

**THE FIX (owner's steer — "handle whether the backend is Atime-async in Wormhole()"):**
- `RemoteWormholeNav.atime_async = true` (only this nav; disk navs stay inline-awaitable — their promises settle off the disk event loop, independent of Atime).
- `Housing.Wormhole_park(queue, wrap, run_op, done)` — for an atime_async nav, LAUNCH `run_op()` fire-and-forget (its send frame goes out synchronously, inside the pass, like any emit), stash the settled reply on `wrap.c.reply` (off-snap, the `A.c.cloud_*` promise-mutates-.c pattern), `main(true)` to wake a pass, and `done(reply)` on that LATER pass — back inside Atime. One op in flight per queue (`queue.c.inflight`) preserves do()'s serial order; `wrap.c.reply` check precedes the inflight guard so a settled op finishes+drops.
- Both the wh_op (fs) and rw_op (rw) blocks refactored: the op body is now `run_op()` returning the reply value; `nav.atime_async ? Wormhole_park(...) : done(await run_op())`.
- The reply now delivers through the NORMAL batch (mutex free once the actor bows out) → `Lies_wormhole_reply_recv` → `nav._resolve` → promise settles. No `Lies_deliver_soon` short-circuit needed (I sketched one first, then removed it — the parking is the real fix).

Also done: renamed `&disk=proxy` → `&remoteWormhole=1` everywhere (Otro `h.c.remote_wormhole`, Housing/LiesFunk/Rundar reads, flock README, Cluster_spec, Runner_quality_handover). Type-clean; NOT yet run on a live :9091 runner.

Supersedes the "live-tested" claim in [[remote-wormhole-built]] — grant/serve always worked; the *runner-side delivery* was broken and is now fixed.
