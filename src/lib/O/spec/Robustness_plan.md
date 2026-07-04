# Robustness_plan.md — assert vs derive, trust vs confirm

> Distilled from the 2026-07-04 remote-Wormhole grant saga, which turned out to be a *catalogue*
> of the same few structural mistakes repeated across the codebase. Four parallel audits
> (latched state · silent failure · no-single-source-of-truth · identity model) converged on
> **one disease**. This is the plan of record for curing it. Owner said "we'll do whatever it takes."

## The disease (one sentence)

**State is *asserted* instead of *derived*, and boundaries are *trusted* instead of *confirmed*.**

Every bug in the grant saga was a special case:
- the badge *asserted* "granted" (a set-once flag) instead of *deriving* it from a live crypto verdict;
- the runner *trusted* an unconfirmed `not_found` and wiped the registry instead of *confirming* absence;
- the editor *trusted* `claim.for` as a routable address instead of *deriving* the address at send;
- the reconcile *re-asserted* an identity invariant on a hot path and discarded a good grant on a blip.

The cure is always the same shape: **derive from the live source of truth at point of use, or reconcile
against it every tick; and make every boundary answer a *three-valued* question (yes / no / couldn't-tell)
so "couldn't-tell" can never masquerade as "no".**

Five organs, worst-first. Each finding is `file:line` — the concrete specimen — then the cure.

---

## Organ 1 — Latched flags that never reconcile

A fact is stored as a boolean, set once, and never cleared or re-checked. It keeps asserting a dead truth.

| # | flag | set / never-cleared | drift (what becomes a lie) |
|---|------|---------------------|----------------------------|
| 1 | `w.c.channel_up` | `LiesLies.svelte:319` (guard `:202`) | HMR strips `Socket_real` → latch says "up", standup never re-runs → **the "relay down" wedge** |
| 2 | `w.c.transport_up` | `LiesLies.svelte:346` (guard `:342`) | frozen transport-ghost deposit; remix → `Socket_real undefined` warning can't self-heal |
| 3 | `Runner.sc.granted_wormhole` | `LiesFunk.svelte:516` | editor rack shows a runner "granted" **and** "begging" at once after it re-begs — the badge bug, one hop over |
| 4 | `H.c.creduler_up` | `Auto.svelte:265` | Creduler actor torn down → latch blocks re-erection |
| 5 | `run.c.toc_loaded` | `Story.svelte:1505` | `The` read once; a toc.snap changed on disk (re-record / host commit) is never re-read |
| 6 | `sub.sc.subscribed` | `Lang.svelte:1279` | **snapped** latch survives reload but the runtime subscription doesn't → roster silently never updates |
| 7 | `w.c.plan_done` / `w.c.aim_setup` / `w.c.thangs_subscribed` / `w.c.keep_booted` | `Cyto.svelte:98` / `LiesFunk.svelte:720` / `Thangs.svelte:87` / `LiesKeep.svelte:247` | UI/subscription built once; a teardown leaves the latch asserting it's still up |

**Cure.** Derive-or-reconcile against the live source each heartbeat, or clear-on-teardown — never a one-way
set-once latch. The **template already exists**: `wormhole_state` is now derived downstream of the crypto
verdict every heartbeat (`Lies_remote_wormhole_reconcile`, `LiesFunk.svelte`). Correct existing pattern to
copy: `Auto.svelte:285` `identity_up` latches *only on success* and retries until it works.
Top three to fix (map to documented wedges): `channel_up`, `transport_up`, `granted_wormhole`.

---

## Organ 2 — Silent success over dropped work (the "lies upward" class)

A thing fails and nothing surfaces — worse, the caller is told it *succeeded*.

- **`Ghost/N/Peeroleum.g:538`** — an **unregistered frame type is ACKed as handled** (`ok=true` → `done` → ack).
  A typo'd handler / editor-vs-runner registry mismatch → sender believes it was processed, no retry, no trace.
- **`Ghost/N/Peeroleum.g:393`** — a transport drop is `console.log`-only but the caller still gets a **"sent" seq**,
  so `Lies_send_rungo` (`LiesLies.svelte:392`) clears `pending_rungo` and reports "sent" over a dead socket.
- **`Ghost/N/Peeroleum.g:426`** — inbound frame for an unrouteable Pier `return`s silently (the sibling inseq
  path *screams*; this one is mute).
- **`LiesLies.svelte:291,294,305,312`** — async handlers (`grant_offer`, `runner_ask`, `ghost_compile`,
  `wormhole_req`) are acked `true` synchronously; a rejection vanishes as an unhandled promise.
- **`Housing.svelte.ts:1228`** — a w whose `method` names no function is a silent no-op unless `targeting===2`.
- **`RemoteWormholeNav.svelte.ts:78`** — a reply for an unknown/late `corr` is dropped with no trace (hides
  "the reply DID arrive, just slow" — indistinguishable from truly lost).
- **`relay.ts:269,285`** — a frame with no parseable `to` header is dropped without a `warnDrop`.
- swallowed catches: `LiesLies.svelte:491` (`catch { return false }`), `Story.svelte:783` (bad `cap_json` → silent no-op).

**Cure.** Never ack undelivered/unhandled; never return a "sent" seq on a dead transport; surface every drop.
Three good "surface it" templates already in-tree — copy them to the sites above:
`LiesStore.svelte:894-911` (stuck-read watchdog, escalate-and-nag + `w.i({see})`),
`LiesStore.svelte:934-944` (`land_good` refuses to land an `{error}` reply),
`relay.ts:256-261` (`warnDrop` escalation).

---

## Organ 3 — No single source of truth + empty-overwrites-real  ← **P0 (data-loss, still open)**

The same fact lives in multiple divergable homes, and/or a transient/empty read overwrites durable data.

- **`Lies.svelte:772-829`** — the shared Waft-provision loop has **no `notfound_once` guard**. A single
  transient `not_found` for **Cluster, Keep, GhostList, the Library, or the shared EntropyProfile** resets the
  in-memory Waft to empty and (on an editor, `:829`) saves it back — **the original grant-registry wipe**.
  Only the Story toc (`Story.svelte:1490`) re-confirms an absence before accepting it.
- **`RemoteWormholeNav.svelte.ts:83`** — the remote proxy forwards `not_found` verbatim; only the *local* FSA
  path re-lists (`Housing.svelte.ts:2093`, comment: *"a false 'no' here is DESTRUCTIVE"*). The `&remoteWormhole`
  runner — the exact env of the original wipe — has zero defense.
- **`LiesStore.svelte:930-957`** (root choke point) — `land_good` models `undefined|null|string` but `null`
  **conflates "genuinely absent" with "couldn't fetch"**. It already special-cases `{error}` (our first fix);
  it just needs the same for `not_found`.
- **`Auto.svelte:314-355`** — Library load: `{error}` guarded, but `not_found`/empty → autovivify defaults +
  save → real Library overwritten by `DEFAULT_BOOKS`.
- **`LiesFunk.svelte:1826`** vs `%HostedIdentity.favourite_client` — a `.c` home nothing writes; the beacon
  always reports `''` regardless of the registry truth (spec `Engage_integration.md:50` admits it).

**Cure (the P0).** Give the read a **fourth state** at the one choke point (`land_good`): a *confirmed-absent*
vs *unconfirmed / unavailable* distinction (a tri-state read: `present(content) | absent | unavailable(reason)`).
Then every consumer inherits authoritative-absence and the per-caller `notfound_once` band-aids disappear.
Push the "re-confirm before answering not_found" into the shared reader contract (a flag on the reply), not
bolted onto one backend. Gate the `Lies.svelte:829` auto-save on a *confirmed* absence.
Good pattern to copy: `LiesKeep.svelte:94-116` (one authoritative snapped home + a coalesced mirror that
can't feed a write loop).

---

## Organ 4 — The identity model: 9 divergable tiers → collapse to 2  ← the deep fix

Root of **three** separate bugs this session (reply-routing drop, grant for-check flap, duplicate roster rows).
A peer has ~9 notions of "who am I", and everything re-samples a two-tier fork (`Clustation ?? stashed`) *at the
moment it runs* — except the grant's `for`, **frozen at mint against a tier that can drift**.

The tiers (name — where — used for): `?I=` (`Auto.svelte:113`, gate) · `%Identity`+`.c.keys`
(`Auto.svelte:155`, the switchable signing self) · `%Peering.name=prepub` (`Auto.svelte:162`, routing container)
· `stashed.cluster_idento` (`LiesLies.svelte:506`, legacy fallback) · env `CLUSTER_IDENTO_*` (`IdHatch.svelte:41`,
node key) · `CLUSTER_TRUSTED_PUBS` (`cluster_trust.ts:29`, **trust flock — orthogonal**) · `Lies_cluster_idento`
(`LiesLies.svelte:499`, active signing key: signs hello/gen_write; grant `by`) · `Clustation_self`
(`Auto.svelte:215`) · **`Lies_self`** (`LiesLies.svelte:522`, the intended single answer =
`Clustation_self ?? prepubOf(cluster_idento.pub)`) · relay **hello-bind** = `prepubOf(idento.pub)`
(`relay.ts:388`, **the routing address**) · relay **become** role addr (`relay.ts:303`, a *separate* namespace)
· advertise `from` (`LiesLies.svelte:1118`) · `%Runner` key (`LiesLies.svelte:1200`) · `%HostedIdentity` key
(`LiesFunk.svelte:445` self / `LiesLies.svelte:1191` roster) · **grant `by` (full pub) / `for` (16-hex prepub,
frozen)** (`Grant.ts:68`, `LiesFunk.svelte:514`).

**Divergence hazards (ranked):**
- **H1** — grant `for` (frozen prepub) ≠ live hello-bind prepub → `to:claim.for` routes to nobody → the 20s
  stall. *JSON replies now sidestep via consumer-broadcast + corr-match; residue:* `replyBIN`
  (`LiesFunk.svelte:586`) still routes on the frozen tier.
- **H2** — `for` is a **16-hex prepub, never cryptographically verifiable** (a truncated pub can't check a sig),
  so authorization is a bare matching string, not an identity — the property that let it silently drift.
- **H3** — `Lies_self` two-tier fork (`Clustation ?? stashed`) not collapsed; the for-check has to "tolerate both
  tiers" (`LiesFunk.svelte:532`) — a workaround, not a fix.
- **H4** — `%HostedIdentity` written by two authorities under possibly-different prepubs → **duplicate directory
  rows** → dispatch picks the stale one → "both runners ran it".
- **H5** — advertise `from` (Lies_self) vs hello-bind (cluster_idento) can disagree at bootstrap; documented as a
  requirement (`LiesLies.svelte:1094`) but **nothing asserts it**.
- **H6** — two relay namespaces (role addr vs prepub addr) never cross-checked; a socket can be role-bound but
  hello-*rejected* and look "half-alive".

**Collapse (9 → 2).**
1. **Kill the two-tier fork** (fixes H3/H5, root of H1/H4): at boot, auto-`Clustation_adopt` a legacy
   `stashed.cluster_idento` (the migration exists, `Auto.svelte:173`). Then
   `Lies_self ≡ Clustation_self ≡ prepubOf(Lies_cluster_idento.pub)` by construction; drop the `?? legacy`
   branches and the "tolerate both tiers" union.
2. **`prepub` = a pure derivation, asserted once.** `peer_addr(H) = prepubOf(active_identity.pub)` is the *sole*
   source for hello-bind, advertise `from`, `%Runner` key, `%HostedIdentity` key, `favourite_client`. Add a
   `channel_up` assertion that advertise prepub == hello-bound prepub (closes H5/H6 **loudly**).
3. **Grant `for` = grantee's FULL pub; address derived at send** (fixes H1/H2). `for` becomes verifiable
   (form-matches `by`); routing derives `to = prepubOf(claim.for)` at serve time so a frozen atom can't drift.
   Apply to `replyBIN` (removes the H1 residue). Keep the corr-match belt for identity-switch resilience.
4. **Keep the trust flock (`CLUSTER_TRUSTED_PUBS`) explicitly separate** — "may this pub issue gen_write / be a
   grant issuer" is a *different question* from "which socket is this peer". Don't merge.

Net: ~9 divergable tiers → **2** (a signing `{pub,key}` per peer; `prepub = pub[:16]` for *all* routing/roster/
grant-`for`; trust flock orthogonal). Load-bearing files: `LiesLies.svelte`, `Auto.svelte`, `LiesFunk.svelte`,
`Funk/Grant.ts`, `cluster_trust.ts`, `relay.ts`. (See also `Cluster_spec.md`.)

---

## Organ 5 — Lying errors & partial interfaces

- the badge that said "granted" over a dead grant; the DIAG log that printed "ok" *before* the send
  (`LiesFunk.svelte` — remove once confirmed); the `wormhole_reply … ok` printed even when the send dropped.
- **`RemoteWormholeNav`** is a *partial* implementation of the nav contract — **no `bin_write`** — with no
  capability probe, so a WAV-writing Book surfaced it as "no writable share — grant one" three layers away
  (`LiesFunk.svelte`, now made honest). See the wormhole bin_write item below.

**Cure.** Errors name the *real* cause; a backend either implements the full nav contract or is explicitly
capability-probed at the seam (and the seam says which capability is missing, not "grant a share").

---

## The prioritized plan (execute in this order)

> **Landed 2026-07-04** (this session, all parse/compile-clean; `:9091`-unverified — verify each on a live
> runner via `runner_ask`): ✅ P0 land_good · ✅ P1 latches · ✅ P1 ack-surface (warn only) · ✅ P2 nav-precedence
> · ✅ Organ 4 / H5 assertion (diagnostic). **Remaining:** the identity collapse's *behavioral* core (Organ 4
> parts 1-3) — staged deliberately, see the note under it.

- **P0 — authoritative-absence at `land_good`** ✅ **DONE** (Organ 3). `LiesStore_land_good` now takes the read
  req and re-asks ONCE before trusting a `not_found` (deduped per-req across the Phase-2 + read_good land sites);
  a single transient `not_found` for a registry Waft never lands as absence, so it can't wipe the durable snap.
  Docs (`text/Doc`) are exempt (a not_found doc = "new blank file", and a one-shot cold subscribe must not hang).
  `Auto.svelte` Library got the same re-confirm on its own `rw` queue. *Acceptance met.* **This is the thread that
  started the whole session.**
- **P1 — Peeroleum never acks unhandled/undelivered** ⚠️ **PARTIAL** (Organ 2). Done: an unregistered frame type
  now **warns loudly** (`Peeroleum.g` req_unemit; gen recompiled via LocalGen). *Deferred:* the "mark `%faulty`,
  don't-ack" escalation — it would **retx-wedge** the conditionally-registered handlers (`test_*`, `repli_*`,
  `audiochunk`, `stream_offer`) if any legit send-without-handler type exists, so it needs a live run to prove
  safe first. The drop-returns-seq case turned out already-covered (`Lies_send_rungo` gates on `channel_live`
  and rungo is booked → Reliable.g retx redelivers), so no change there.
- **P1 — clear the `channel_up`/`transport_up` latches** ✅ **DONE** (Organ 1). `Lies_channel_up` / `Lies_transport_up`
  now reconcile the latch against the live transport ghost: if `Socket_real` has vanished (a remix the socket's own
  auto-reconnect can't fix), CLEAR the latch and re-stand-up (idempotent — `Peeroleum_on` is keyed by type, enroll
  is `oa`-guarded, keepalive timer guarded). A merely-disconnected ws does NOT flap it. *Acceptance met.*
- **P2 — identity collapse 9 → 2** 🔶 **STAGED** (Organ 4, the deep fix). Done: the H5 **assertion** — `Lies_self`
  now warns when the advertised prepub ≠ the signing-key prepub (diagnostic, non-behavioral). **NOT yet done and
  deliberately held:** parts 1-3 (auto-adopt the legacy tier + delete the `?? legacy` forks; `prepub` as a pure
  derivation; `grant.for` = full pub with `prepubOf` derived at send; apply to `replyBIN`). These are a *coherent
  set* that only makes sense done together, and they rewrite load-bearing routing/identity — a blind pass risks
  re-breaking the wormhole/routing just made to work. **Do them as one focused pass WITH a live runner in the
  loop: after each stage, `runner_ask ping` (routing intact) + a grant round-trip (wormhole intact).** Retires
  H1-H6 by construction.
- **P2 — wormhole nav precedence** ✅ **DONE** (Organ 5). `Lies_remote_wormhole_install` + `_reconcile` now PREFER
  a granted local share (`A.c.DL`) over the editor proxy — the heartbeat no longer clobbers a just-granted
  `WormholeNav(DL)`; the badge shows a third `local` state honestly (Rundar). Granting FSA on a `&remoteWormhole=1`
  tab now "just works" and unlocks `bin_write` for free. *Acceptance met.*
- **P2 — wormhole `bin_write` over the proxy** ✅ **DONE 2026-07-05** (Organ 5, option **b**). A genuinely-headless
  `&remoteWormhole=1` runner (no local share) can now write binary over the wormhole:
    - `RemoteWormholeNav.bin_write` → `send('bin_write', {dir_path,filename}, bytes)` (a new buffer-carrying `send`).
    - `Lies_send_binary_consumer` (LiesFunk) — the runner→editor CONSUMER twin of `Lies_send_binary_to`: raw bytes
      on `frame.buffer` (body_hash-integrity, OFF-snap — no base64 tax, no bloated snapped emit), app meta on the header.
    - `Lies_wormhole_req_recv` now reads meta from the header (binary) OR top-level (JSON), and has an `op:'bin_write'`
      branch that lays `frame.buffer` on the editor's disk via its own `nav.bin_write`; reply is a tiny JSON `{ok}`.
  Reuses the PROVEN symmetric binary path (the editor's frozen `pinned_stable` spine already body_hash-verifies inbound
  binaries + dispatches to the registered handler — same path the runner receives `wormhole_reply` binaries on). NO `.g`
  change (all live O/ modules). **`:9091`-UNVERIFIED** — needs the runner tab + editor tab reloaded to instantiate the new
  nav class + serve branch, then `runner_ask run MusuGenerateTestsMusic --watch`. The binary-*reply* corr-route (H1 residue)
  is still a TODO; unaffected here (bin_write's reply is JSON).
- **QA + full-contract parity** ✅ **DONE 2026-07-05** (Organ 5, "no partial nav"). QA of the above found the SAME
  subset gap in the *other* backends and closed them, so the 7-method contract (`read_file · write_file · bin_read ·
  bin_write · read_range · dir · dir_at`) is now uniform across **all four** navs, not just remote:
  `OpfsOverlayNav` (cloud) gained `bin_write`; `NodeWormholeNav` (harness) gained `bin_read` / `bin_write` /
  `read_range` (a real fd window, not slurp-then-slice) / `dir_at`. Grep-confirmed no caller invokes any method
  outside the seven. Browser navs svelte-check-clean, node backend tsc-clean.

---

## Wormhole `bin_write` + nav precedence (the live specimen)

**The gap.** Binary writes don't exist over the wormhole: `RemoteWormholeNav` has `read_file`/`write_file`(text)/
`bin_read`/`read_range`/`dir` but **no `bin_write`**; the editor serve (`Lies_wormhole_req_recv`) has ops
`read|bin|read_range|list|write` but **no `bin_write`**. So a `&remoteWormhole=1` runner can't run a Book that
writes binary (e.g. `MusuGenerateTestsMusic` → WAVs). (Not urgent: `testsounds/` already exists on disk from a
prior FSA run; and the Book runs fine on a plain-FSA runner.)

**Nav precedence bug (observed 2026-07-04).** On a `&remoteWormhole=1` tab, **granting a local FSA share does
nothing** — the runner keeps the remote nav (no `bin_write`). A granted local share is *strictly more capable*
(direct disk, full contract, lower latency) yet is ignored because the DirectoryOpener/reconcile re-installs the
remote nav. Two ways to fix (pick one; they're different semantics):
- **(a) prefer a granted local share over the remote proxy** — if a local DL is open on a remoteWormhole runner,
  build `WormholeNav(DL)` and use it, stop re-installing the remote nav. Simplest; makes granting FSA on the tab
  "just work" (and unlocks `bin_write` for free). Changes remoteWormhole semantics when FSA is also granted.
- **(b) wire `bin_write` through the wormhole** — a runner→editor binary frame (mirror `Lies_send_binary_to` in
  reverse) + a `bin_write` op on the serve + `RemoteWormholeNav.bin_write`. Keeps the remote path pure; the
  complete fix for genuinely-headless runners. Also corr-route the binary *replies* (the H1 residue).

Recommendation: do **(a)** now (cheap, unblocks, matches the existing "a granted local dir overrides the cloud"
intent at `Housing.svelte.ts:1747`), and schedule **(b)** as part of the P2 identity/wormhole work (binary
frames both directions, corr-matched).

---

## Cross-references

- `Runner_network.md` — the `channel_up`/`transport_up` latch is the root of the "relay down / runners dead" wedge documented there.
- `Cluster_spec.md` — the identity collapse (Organ 4) and remote-Wormhole `bin_write` are cluster/wormhole surface.
- `Wormhole_backends_handover.md` — the nav contract, the read authoritative-absence, the `bin_write` gap.
- `Peeroleum_spec.md` — the ack-unhandled / drop-returns-seq silent failures (Organ 2) live in `Ghost/N/Peeroleum.g`.
