# Sharing_design.md — identity, invite, friendship, trust (2026-07-27)

Consolidates the scattered sharing-spine todos — `Swarm_spec.md` (the canonical spine),
 the settled halves of `Swarm_compact_invite_todo.md`, `Identity_persist_todo.md`, and
  `Trust_audit_handover.md`, plus the two spine sections of `Cluster_spec.md` (§2 trust
   substrate, §3.2a identity model) — into one settled statement. Written for read +
    preen; **not self-blessed spec.** The forward working docs stay where they are (doc
     map at the end).

**Verification basis (read this).** `[LIVE]` = a real caller exists in shipped `.g`/`.svelte`
 (not a def, a comment, or a gen `.go`). `[BOOK]` = built and green in a Story Book but with
  **no live caller**. `[OWED]` = not built. The honesty rule this whole spine keeps hitting:
   every "green" here is **either** a Story Book (mock carrier / memnav by design) **or** two
    tabs on **one** machine over the relay (loopback — one process, one clock, one localhost).
     No edge has yet crossed between two physically separate machines, and the transport crypto
      under the society layer is a placeholder regardless of machine count.

---

## What it is

The sharing spine is the **identity → friendship** path that lets a music room say *"here is
 my music, scan to join."* A tab mints an **ed25519 identity** (`%Identity`, whose `%Peering`
  is the pub-derived routing address) under `A:Clustation` on the top House, persists it to the
   browser store and mirrors it to owner-local `.jamsend` disk (the keypair rides the snap **in
    clear, owner-local, never Repli-served**). That identity mints a **single-use compact
     invite** — `prepub16*serial*n*presig16`, ~45 chars — worn as a QR. A friend scans it, dials
      the issuer over a real own-origin `/relay` websocket addressed by `prepub`, and runs a
       **3-frame seal** (`pier_hello → pier_accept → pier_confirm`) that exchanges two bound
        `%Grant` atoms and plants a mutual durable `%Pier` on each side.

Trust after the seal is **grant-gated**: a music frame crosses only on a held grant; unfriending
 is a signed `%NotGrant` tombstone; every routed frame carries a **per-era voucher** so a sealed
  friend re-verifies the sender's key the relay never checks. The **society layer** (identity,
   invite, grant, reinvite, voucher) is **real ed25519**; the **transport layer** beneath it
    (Peeroleum / Tyrant / Tribunal) is a **deliberate mock pipe** awaiting its crypto port. Live
     code: `Ghost/S/Swarm.g` (society) + `src/lib/O/Auto.svelte` (Clustation identity boot) +
      `InvitePanel.svelte` / `DoorFace.svelte` (door UI). Green in the **Swarmation** Book and
       exercised as two tabs on one machine over the relay — **never yet between two real
        machines.**

---

## Settled design

- **Identity mint + resume** `[LIVE]` — the Clustation family in `Auto.svelte:101-326`
   (`Clustation_mint/ensure_identity/concrete/ensure_default/friendly/pin/adopt`), driven each
    boot tick from the ladder at `Auto.svelte:471-496`. `?I=new` mints then rewrites the URL to
     `?I=<prepub>`; `?I=<tag>` resumes that owner; a bare `/BigSoundland` gets the role-default
      identity (Dexie-only, keyed by role not prepub). Keys ride `.c.keys` only, **never `sc`**.
- **Browser persistence** `[LIVE]` — identities stored as a Thang (`thang_put` under prepub +
   role); `Swarm_iz_stash` / `pier_stash` / `chainroot_stash` rehydrate at station standup
    (`Swarm.g:587-589`). *(Naming caveat: `Swarm.g:251` + `Swarm_spec §6.2` call the OLD store
     "Dexie"; it is actually Things over raw IndexedDB — Trust v2. The Thang/Dexie stack is the
      NEW one. The doc says "Dexie" for the store loosely; the live persister is Thang.)*
- **Disk persistence to `.jamsend`** `[BOOK]` — `Swarm_account_save`/`_load`,
   `Swarm_roster_open`/`_save`, `Swarm_persist` (`Swarm.g:1610-1695`); the keypair folds onto the
    account snap's Identity root via `Swarm_snap_keyed` (`Swarm.g:1547-1554`); the roster is
     **pub-only**. Green×2 in **SwarmDisk**, but the ONLY callers are `Swarmation.g` + internal —
      **no `.svelte` writes disk live.**
- **Compact invite + presig** `[LIVE]` — token codec `Swarm_token`/`_token_parse` + issuer-MAC
   `Swarm_presig` (`Swarm.g:122-147`); `Swarm_mint_idzeug` (`Swarm.g:177-196`) reached live via
    `InvitePanel.mint()` → `Swarm_invite_url` (`InvitePanel.svelte:121-133`). The full signed atom
     rides `.c.iz` for chain lineage; the QR wears only the compact token.
- **3-frame seal + dispatch** `[LIVE for wiring / BOOK for the compact form's proof]` —
   `Swarm_hello`/`_accept`/`_confirmed` (`Swarm.g:751-846`), dispatched by the live station's
    `Swarm_arm` `hear()` registry (`Swarm.g:428-456`); the reciprocal grant is deferred to frame
     3. **Contradiction flagged:** "compact invite is live-proven two-tabs" is **overstated** —
      `Swarm_compact_invite_todo §0` lists the live two-tab fingers-proof of the compact QR as
       still **remaining**; only the older **full-atom** seal has live two-tab history.
- **`?Iz` scan-to-join + born-today + pin** `[LIVE]` — `InvitePanel` LAND/`join()` (`:167-251`)
   → `Swarm_redeem` (`Swarm.g:732-743`) → `Swarm_station_up`. A `born_today` `$derived` +
    `$effect` (`:188-202`) auto-fires the join when the identity was minted today and is named.
     `Clustation_pin` runs immediately on redeem (`:232-240`) and swaps `?Iz`→`?I=<prepub>`, so a
      reload resumes the joined identity, not a stranger.
- **Friendship seal + grants + revocation** `[LIVE seal / BOOK revoke]` — `Swarm_seal`
   (`Swarm.g:1029`) mints/keeps the mutual `%Pier` keyed by prepub with both `%Grant` atoms;
    `Swarm_page_bound` (`Swarm.g:68`) gates all five seal entries (the SwarmSpoof fix); the real
     ed25519 voucher gate `Swarm_voucher_ok` (`Swarm.g:475-484`) runs on `station_up`. Revocation
      `Swarm_revoke` → signed `%NotGrant` tombstone (`Swarm.g:1483-1494`); `Swarm_pier_live`
       (`Swarm.g:1496`) re-checks tombstones at every use. The revoke gate is live-reachable but
        has **no live UI** — `DoorFace` has no revoke button; the only unfriend button in any
         `.svelte` is the legacy `p2p/` prototype.
- **Roster** `[LIVE friends / BOOK disk roster]` — `DoorFace.svelte:27-72` reads
   `Swarm_peering(self).o({Pier:1})` and renders sealed friends + grant/boast/pulse + the self
    name-box → `Clustation_friendly`. The **disk recognition roster** (`identities/toc.snap`,
     pub-only) `Swarm_roster_*` is green in SwarmDisk but never written or read live.
- **Boot-seed / disk-adopt** `[OWED]` — `Swarm_boot_seed(nav, root, container, want)`
   (`Swarm.g:1707-1719`) is a pure, Book-provable lift (SwarmDisk green×2), but its ONLY callers
    are `Swarmation.g:1769/1810/1828` + gen — **confirmed NOT wired into
     `Clustation_ensure_identity`.** The Auto glue (adopt the disk owner before minting a parallel
      self, set `sc.active`, re-mirror to Dexie) is **the one owed identity seam** (frontier #4).

### Trust status — the society layer is real, the transport under it is mock

The single most load-bearing fact, from `Trust_audit_handover`'s split-personality finding
 (verified file:line, 2026-07-26):

- `Ghost/S/Swarm.g` — **society layer** — **REAL ed25519.** Invites, grants, reinvites, and
   per-era vouchers all sign + verify; forgery throws; single-use spend + blotter + chain are
    Book-green. Meets or exceeds the Peerily reference.
- `Ghost/N/Peeroleum.g` / `Tyrant.g` / `Tribunal.g` — **transport layer** — **MOCK (v1, on
   purpose).** `header.sign` is `[OWED]`; `body_hash` is unkeyed sha256; `hear_hello` =
    `startsWith(pub)`; `hear_trust` = no-op. The wire is a raw pipe.

Audit each half on its own terms. The society voucher is real per-**era** link-auth, but the wire
 carrying it signs nothing per-**frame** — so the per-connect trust rebuild (structurally correct,
  even preserving `%Ud`) proves little until the transport signatures land.

---

## Remaining frontier (ranked)

All five are `[OWED]`. Everything green above is either a Book or two tabs on one machine over
 the relay; the relay path IS exercised on loopback (signed hello-bind, per-era voucher gate,
  3-frame seal all run there), but no edge has crossed two physical machines.

1. **Two real machines over a real carrier — never run.** Loopback two-tabs share one relay
    process, one clock, one localhost. Unproven across a real network: NAT/relay routing to
     `to:<prepub>`, real-latency frame ordering, whether the voucher and the hello-bind survive a
      real reconnect. **The load-bearing unknown** — every item below is a facet of this crossing.
2. **Transport per-frame crypto is a mock** (`Trust_audit` job A). `Peeroleum.g` has no
    `header.sign`, `hear_hello` = `startsWith(pub)`, `hear_trust` = no-op. Owed: land
     `header.sign` + real `hear_hello`/`hear_trust` so the per-connect trust rebuild (which keeps
      `%Ud` correctly) becomes **cryptographic**. It "unblocks the moment any flow crosses the
       relay."
3. **`pier_confirm` (frame 3) has no re-drive on reconnect** — the "fingers-proof" owed. The
    issuer seals one-sided at `pier_hello`; the reciprocal grant rides only frame 3 (fire-once
     `Swarm_deliver`). A reconnect / era-change mid-seal drops it **permanently** → an asymmetric
      friend record (music still flows off each side's own grant; the backup/SocialGraph goes
       lopsided). Fix: on a vouched reconnect from a pier missing its reciprocal, re-drive the
        deferred confirm.
4. **Boot-seed wiring + its 3 audit bugs** (`Identity_persist_todo §5`): (a) **nav-timing latch**
    — `ensure_identity` latches `identity_up` before `Crate_nav()` exists, minting a stranger on
     cold boot; (b) **wrong path for a fresh QR scan** — the first scan lands `?Iz` with no `?I=`,
      so `ensure_default` (the role path, Dexie-only) mints, not the disk-seed path; (c)
       **second-reload trap** — `Swarm_account_load` grafts Piers into the live tree but not the
        Dexie stash, so reload #2 rehydrates from an empty stash and friends vanish
         (`Swarm_restash_all` does not exist yet). Also `Swarm_persist` has no live write hook —
          **disk is never written live.**
5. **Two hard-coded timing guesses + unknown-serial ambiguity** — `join()`'s `sleep(400)` "for the
    hello-bind to land" (`InvitePanel.svelte:223`); `mint()` opening the QR even when
     `Swarm_station_up` returned null; `refuse('unknown')` sending no reply **by design**, so a
      stale QR looks identical to a live seal-in-flight. All mock-invisible, all real-relay hazards.

---

## What this absorbs (doc map)

**Merged into this doc** (retire-candidates — recommendation only, nothing moved here):

- `Swarm_spec.md` (50 KB, the canonical spine: particle model, addressing, storage, the Auto
   ladder, the Idzeug invite, the 3-frame handshake, ReInvite, revocation, privacy) → **the base
    of the body above.** Its §5 boot-ladder marks steps 3-4 `[want]` while `Identity_persist_todo
     §3` marks them BUILT-pure-lift. **Resolved:** the model is green in SwarmDisk, the **Auto
      wiring is unbuilt** — frontier #4.
- `Swarm_compact_invite_todo.md` (invite chapter) → the compact-token + 3-frame settled design
   above. Its §0 correctly holds the live two-tab compact-QR proof as **remaining**; §7's two big
    threads (rung-2 key/spend migrator; identity-on-`.jamsend`) stay as forward items there.
- `Identity_persist_todo.md` → the persistence design above. **Keep §5 (the exact Auto seam) +
   its 3 audit bugs** as the owed-seam appendix — it is the precise, verified two-tab wiring
    recipe and must survive intact.
- `Trust_audit_handover.md` → the **Trust status** subsection above (society-real / transport-mock
   split, the Peerily checklist). It owns the crypto status; job A is frontier #2.
- `Cluster_spec.md` §2 (trust substrate — the signing layer, already built) + §3.2a (identity
   model — one key, one derived address, the 9→2 collapse) → **extracted** as the trust substrate
    + identity-model spine. `Cluster_spec.md` is 80 KB and mostly runner-flock / testbed — **leave
     that body as a separate runner doc**; only §2 + §3.2a are sharing-spine.

**Kept separate (do NOT merge):**

- `Onboard_todo.md` — the first-run funnel + the display handoff to Vyto. **Deferred**; ~80% of
   the components exist, the orchestration is unbuilt. Stays a working todo.
- `Follow_todo.md` — the DJ-monitor `%Follow` follower mode ("enslave a client to my stream").
   **Not built at all**, deliberately deferred to post-production. Stays a working todo.

**⚠ Flagged — a parallel trust architecture, NOT the shipping spine:**

- `Covenant_design.md` (`Tyrant.g` + `Garden.g`) is a **parallel** trust design: admission via a
   policy-gated `%req:join` whose `finished` is the conjunction of policy leaves. `Tyrant.g`
    exists (M1 + M2) but its ONLY callers are itself + the Idzeuzia test Book + the legacy
     `p2p/Tyranny.svelte`; `Garden.g` is unbuilt. **The live sharing spine does not use Tyrant's
      admission at all** — it uses `Swarm.g` one-shot grants + per-era vouchers. This is an
       **unreconciled fork** in the trust story. **Do not read Covenant as the shipping design.**
        Recommendation: **retire-candidate, or re-label as parallel/experimental** — the human's
         call.

**Retirement recommendation (recommendation only — nothing moved, no other file edited):** once
 this doc is read + preened, retire to `spec/history/` the four merged docs whose durable content
  now lives here — `Swarm_spec.md`, `Swarm_compact_invite_todo.md`, `Identity_persist_todo.md`
   (carrying its §5 appendix forward into this doc first), `Trust_audit_handover.md` — and extract
    §2 + §3.2a out of `Cluster_spec.md`, leaving the rest as the runner-flock doc. Keep
     `Onboard_todo.md` and `Follow_todo.md` live. Re-label or retire `Covenant_design.md` as the
      parallel arch it is. **One caveat:** `Swarm_spec.md` is a **blessed `_spec`**, so retiring it
       is the heaviest move here and most squarely yours to bless — until then treat this doc as
        its *companion*, not its replacement.
