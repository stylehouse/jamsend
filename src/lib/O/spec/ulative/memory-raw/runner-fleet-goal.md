---
name: runner-fleet-goal
description: "The long-term runner-fleet/grid goal (forkable Ids, owned runner, quorum docker restart, Id hop-over) — where the plan lives and the spine-first sequencing"
metadata: 
  node_type: memory
  type: project
  originSessionId: b8ab9686-3dd3-4168-8290-097a1dd463c8
---

Long-term goal AFTER the Peeroleum spine, BEFORE the audio-streaming-platform endgame: a self-driving
**grid of runners** — a Selenium/KVM fleet of Chrome app-servers, a `Cluster/**` of **forkable Ids**, a runner
an editor *owns* (so `%Rungo` is handed to a runner that **focuses on us**, not a random shared one), a
crash-**quorum** docker/libvirt restart, two grids, and an **Id hop-over**.

**Where it's written — NOW CONSOLIDATED 2026-06-29 into `spec/Cluster_spec.md`** (renamed+expanded from the old
`ClusterTrust_handover.md`): the WHOLE cluster — §2 trust substrate (signing, the privileged-frame table) + §3 the
runner flock OPERATIONS (`?I=<tag>` tab-fork vs `ty/`'s OS-profile-per-Chrome; the `Lies%runner` Lens:Runner/Brink
UI; the restart service lifted from `ty/` — `virtreset.py`/`watchdog.js`/KVM-snapshot-revert, NOW succeeded by
*dockerised Chrome*; the relay-as-quorum-counter) + §4 the **dockerised-Chrome real-isolation testbed** (little
dockers each a real-WebRTC peer — closes the in-process-transport ceiling the 2026-06-29 adversarial pass pinned) +
§5 distributed Story (parts run in unison across the flock) + §6 the **delivery-coverage metric** ("how much of the
news got through" = the fitness function for the reliability code; audio variant = stream continuity) + §7 the MVP
**build order to remote `%Rungo`** (1 `to:<pub>` → 2 `?I=` → 3 one daemonised docker runner = remote %Rungo minimal
→ 4 flock+claim/lease+UI → 5 quorum-restart → 6 distributed-Story+coverage → 7 audio sims).
- **`spec/Peeroleum_handover.md` → "The runner fleet — the spine primitives to invent NOW"** = the SPINE half.

**2026-06-29 DESIGN TURN — push coordination APP-LEVEL, keep the relay/spine dumb** (Cluster_spec §2.8/§3.0/§5):
- **Third-party trust = a TYRANT pubkey root + capability CERTS**, resolved by reading a SHALLOW chain (one hop,
  "just the one other") back to the tyrant; cap that matters = **`can:run-code`** (the old trust|trusted gate).
  Checked OFFLINE against the baked tyrant pub; tyrant contacted only to MINT, never to check. This is **app-level
  protocol, explicitly NOT a new privileged frame** — rides opaque in routed-envelope payload like this-dock-updated.
  Frame-signing (§2.1-2.7) answers *who sent this*; capability (*what an Id may do*) is the separate app-level layer.
  Flat `CLUSTER_TRUSTED_PUBS` = the degenerate one-level form of this.
- **`?Runner[=name]`** = new boot role (successor to becoming-a-runner-via-`?B=`); named runners **self-assemble
  into a pool**, idle awaiting allocation. **Only runners dial the tyrant** (not all peers). Runner is an **app-level
  STOWAGE** in an ordinary tab — starts most of the app, hosts the EntropyProfiles; trust-not-privilege separates it.
- **Provisioning baked into the base Book**: a multi-runner Story musters its cast (all remotes check in online) or
  **fails fast** (cloud-host/boot/cert fail), THEN runs sub-books at remotes in unison, each CLI-interrogable.
- **claim/lease DEMOTED**: with pool self-assembly + certs, affinity/ownership may be an app-level lease (no relay
  arbitration). Reserve relay first-come for a GENUINELY contended mutex only. (Earlier "ONE relay-arbitrated spine
  primitive in three hats" framing is now contested — see Cluster_spec §3.5/§8.) Signing layer still = [[cluster-trust]].
- **TYRANT LIVES ON STAGING (old computer), via the relay over an ssh REVERSE PROXY** — online-for-minting, checking
  stays offline vs the baked tyrant pub. Proxy is fragile (acknowledged).
- **TRUSTED-COMMAND RUNNER** (Cluster_spec §3.7) = the general host-control primitive to build, on EITHER host: a
  **systemd unit** + a tiny **signed webservice** (verifies a `can:restart` cert FAIL-CLOSED before acting) + an
  **allowlist shell script** (`restart-docker <svc>`/`restart-proxy`/`snapshot-revert` — the script IS the whole
  privileged surface, caller picks a NAME never a command). Host twin of the in-app `restart_request`; generalises
  ty/'s virtreset.py. BOOTSTRAP WRINKLE: it must restart the very ssh proxy it may sit behind → recovery channel must
  be INDEPENDENT of the thing recovered (direct port / 2nd ssh / self-healing tunnel). Flagged **buildable NOW,
  app-independent, candidate for the FIRST concrete build** (stabilises the topology everything rides on).
- **`w:Wormhole` REMOTE BACKING** (Cluster_spec §3.8) = another robust-build-and-test piece: abstract Wormhole's
  repo-filesystem IO behind two backends by role — **FSA directory handle BANISHED to user-facing editor Chromes
  only** (fragile, dies on restart, needs human Allow), **runners use a network backend** (an "ftp server" loosely —
  browser can't do raw FTP → WebDAV/SFTP-proxy/bespoke ws|http file svc, generalising gen_write/ghost_update). All
  runners open the repo at Wormhole `/` (one shared root) → filesystem no longer distinguishes them → **identity
  must come from `?I=`** (or in-browser trace), not from which-folder-opened. OPEN: writer problem (shared `/` →
  per-?I= namespacing+coord, OR read-only with output via verdict-wire+Storyrun pins — leaning read-only).

**2026-06-29 — cert detour BUILT then REVERSED (the human: "we don't need new cluster certs, obvious"):**
- **MODEL (final, simple):** the existing **`CLUSTER_TRUSTED_PUBS` flock IS the authority** — a sender whose pub is
  in it may do EVERYTHING (run code / allocate / honour %Rungo / ask host restart). Knowing the sender (verified
  frame sig via cluster_trust.ts `verifyHeader`) IS the permission check. NO tyrant, NO certs, NO trust tokens.
  Direction: "real Cluster soon, still no tokens — just know-the-sender + verify their unemits." Finer per-action
  grants IF ever = app-level particles in **`Ghost/N/Tyrant.g`** (already models trust as `%trust,grants` +
  maz-`%req:policy` leaves proven/trusted→`%member,signed`, crypto deferred; Book=PereTyrant) — NOT a frame, NOT certs.
- **KEPT:** the relay `to:<pub>` AUTHENTICATED signed-`hello` bind (`relay.ts handleHello`: peer signs
  `{control:hello,from,pub,ts}`, relay verifies self-sig + ts-fresh ±30s, binds `prepubOf(pub)`→socket; `?addr=`
  still works). That's "knowing the sender"/spine addressing, aligned. Proven in `relay-test.ts`. CLIENT half (peer
  emits hello on connect, Tribunal.g Socket_real, keyed by `?I=`) still TODO — folds into the `?Runner`/`?I=` step.
- **HOST-EXEC = the `chrome_launcher.sock` lineage** (NOT a cert/http daemon): `ty/launcher.py` = a unix-socket cmd
  server (`/tmp/jamsend-supervisor/chrome_launcher.sock`, `RESTART:<profile>`), `ty/virtreset.py` = virsh
  snapshot-revert, `ty/jamsend-launcher.service`. Trust boundary = the SOCKET (host-local, chmod 666 for docker
  bridge). To build: extend its cmd vocab (restart-docker/restart-proxy) + a relay→socket bridge for quorum
  `restart_request`; recovery channel independent of the ssh proxy it may restart. Documented Cluster_spec §3.7.
- **REMOVED in working tree** (I built it; the human committed it in **"the boomerang" 20f4c0f9** mid-session; then
  directed removal — [[host-commits-midsession]] again): cluster_trust.ts cert block (reverted to frame-sign-only),
  `scripts/mint-cluster-cert.ts`, `scripts/trusted-command-runner.ts`, `scripts/cluster-cert-test.ts`, `deploy/*`
  (all unstaged deletions for the human to commit).
- **Trusted-pubs system now carefully documented** — Cluster_spec §2.2 `.env*` inventory: `.env.cluster-pubs` PUBLIC
  =`CLUSTER_TRUSTED_PUBS`; `.env.cluster-<role>` SECRET per role (editor 214f8a4e / runner 9d2498e3 / claude e63cdcca);
  `gen-cluster-identos.ts` mints+splits; browser key via 🪪 IdHatch→Dexie `.stashed.cluster_idento`; vite bakes VITE_*.

**Sequencing (the human, 2026-06-29):** get on with the SPINE now (claim/lease + `?I=` + `to:<pub>` addressing are
buildable on what we have — `scripts/relay-test.ts` proves headless ws round-trips); stand up the
bunches-of-runners grid only at the natural time. The grid doubles as the **Tier-3 two-origin harness** the
[[peeroleum-bootstrap]] handover's PENCILED WORRY says we still owe (headless gives false confidence on
timing/persistence). Lifecycle vocabulary to PORT, not reinvent: the legacy garden
(`src/lib/ghost/Gardening.svelte`) — `Idzeugnation` (Id birth), `Ringing` (contact attempt), `OverPiering`/`%Hath`
(who-exists directory), `Ping` onlinity, trust grants, active-terminal migration, whittling.
