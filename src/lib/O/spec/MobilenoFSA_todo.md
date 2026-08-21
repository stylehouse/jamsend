# MobilenoFSA_todo — the phone arc: listener terminal, likes-before-heists, LinkDevice

Split out of `Onboard_todo.md` 2026-08-15 (the owner: *"I'd like to handover most of this to
 something like MobilenoFSA_todo"*). Onboard keeps the first-run funnel (namer bubble, welcome,
  invite landing); THIS doc owns everything downstream of the one hard fact: **`showDirectoryPicker`
   is desktop-Chromium-only — never mobile, no flag** — so the phone is a listener terminal, and
    wanting-on-the-phone must become having-on-a-station.

## 0. Get on with next

**TO PRODUCTION — radio-only on Android (the owner, 2026-08-19: "at least it does radio").** The
 wire is done (below): a phone visitor hits no folder wall, taps once for audio, is in. The push
  needs three things, in order:
  1. **THE release gate — verify on a real phone that a friend's stream actually PLAYS in
     `listen_only`.** Unverified still. The concrete risk: no nav in this mode, so `rw-ops stay
      "nav not ready"` — if any tune-in / jam-join path needs a nav WRITE, radio silently no-ops on
       device while dev looks green. Field trip only; not settleable headless.
  2. **Request persistent storage at boot** (`navigator.storage.persist()`) — one line, cheap
     mitigation for "clear browsing data = identity death" before Linked Devices lands. Auto-granted
      once PWA-installed.
  3. **🎧 badge in Door + the mortal-identity whisper** — `H.c.listen_only` is read NOWHERE in the
     UI today; the badge makes the mode legible and is where to warn the identity is mortal.

**LANDED 2026-08-15 — listening-only mode, the wire half.** `Housing.svelte.ts` (the boot_role
 branch, `🎧 LISTENING-ONLY` comment): a plain Big*land visitor with no directory picker and no
  `c.book` gets `disk_gated` cleared, `H.c.listen_only = true`, and NO mount — the 83244ad6 shadow-
   disk guard holds because nothing is mounted at all. Dev/daemon/CredRunner boots carry `c.book`
    and keep the gate (their jsdom lacks the picker too — capability alone was never the test).
     The tap remains as pure AC courtship (`boot_gate` already handles disk-less wanting), and
      no-FSA browsers see the one honest sentence (`fsa_advice`, BootGateNoFSA.spec.ts).
  **NOT yet verified on a real phone** — the owner's next field trip is the gate: expect no
   FaceSucker wall, one tap for audio, music from a friend playing. The 🎧 badge in Door is display
    work, unbuilt (reads `H.c.listen_only`).

**NEXT — the %Like record ("a record of what would be Heisted", the owner 2026-08-14).** No heist
 setup on phones; instead a like that a linked desktop can later action. See §2 — most of the
  machinery already exists and is only ever called by a Book today.

**THEN — Linked Devices** (§3, design ruled 2026-08-14; "Linked Devices" is Signal/WhatsApp's term
 for it, adopted 2026-08-19): the live self-Invite ceremony that makes the wants actionable. Stays
  PARKED below the radio push — the like-record is deliberately buildable BEFORE it (likes accrue
   locally now, travel later).

## 1. Listening-only — what stands and what is owed

- Wire: landed (above). Storage posture: identity in Dexie (`Swarm_boot_seed`'s first look); no nav,
   every rw-op stays "nav not ready"; bundle ghosts, no Books — the consciously-noted 83244ad6 cost,
    unchanged.
- **Owed, display**: the 🎧 badge on Door's self line (tap → the fsa_advice sentence), so the mode is
   legible rather than merely un-broken.
- **Owed, honesty**: "clear browsing data" is key death for a shareless identity. Until LinkDevice
   lands, a phone identity is mortal — the Door badge is the right place to whisper that too.
- OPFS (`navigator.storage.getDirectory()`) DOES work on phones and is the eventual audio-cache
   home; v1 needs none of it.

## 2. The %Like record — like now, heist elsewhere later

**Recon (verified 2026-08-15): `Ghost/M/Jam.g` already IS the ledger.** `%Jam,with:<dj>` under the
 listener's shelf; `%Spin/%Like/%Grab,of:<id>,title,at` as ordered referring particles;
  `Jam_home`/`Jam_like` are pure verbs, idempotent per (kind, track). **Nothing in the live app
   calls them** — only `Radiation.g` (a Book). So "provide some way to like tracks" is:

- **A button (display, Vyto's zone)**: on the playing face, `Jam_like(Jam_home(shelf, dj), rec)` —
   the dj's prepub and the mirror shelf are both already in reach (DoorFace resolves
    `%MusuThem,pub` → stock today).
- **Durability (wire, the real gap)**: a %Jam minted on a live tab dies on reload — TODAY, even on
   desktop; only Books ever witness one. A like that is "a record of what would be Heisted" must
    outlive the tab ([[a-ledger-must-outlive-its-subject]]): on a share, a Berth
     (`.jamsend/berth/<prepub>/Jams`) like every other ledger; shareless, a Dexie row (the
      thang_put shape). Same particle either way — the store is the only fork. Carry enough to
       heist blind later: `of` (enid), `title`, the dj's prepub (the %Jam's `with`), and `at`.
- **No heist setup, ruled**: the phone never grows heist UI. The like IS the want; the actioning
   station (desktop chrome via LinkDevice, or the daemon) turns wants into heists with the gears
    that already exist.

**The far arc, the owner's musing 2026-08-15, kept verbatim so it isn't flattened**: *"I suppose
 that becomes a multiplicity thing later... lots of sections merged already to look at, if at all.
  having one's entire life+times with some piece of music."* — %Jam is already the seed of that: a
   per-relationship ledger of events over tracks. Multi-device merge (post-LinkDevice) makes it
    per-LIFE rather than per-session. Nothing to build yet; don't let a v1 like-row shape preclude
     merging (append-only events with `at` + device provenance merge trivially; a mutable
      "liked: yes/no" flag would not).

## 3. Linked Devices — the self-Invite (design ruled 2026-08-14, moved from Onboard_todo)

*Named "Linked Devices" after Signal/WhatsApp (2026-08-19); "LinkDevice" below is the same thing.*

Multi-device is EMBRACED; the transport is a live ceremony on the invite rails, never a static blob.

- **The grain: an invite whose redemption makes you, not befriends you.** Same machinery as any
   invite (compact code, relay addressing, voucher verify) with one inversion of consequence — so a
    LinkDevice invite is **high-entropy, single-use, short-lived (minutes), never posted**: whoever
     redeems it IS you. Both devices online is a feature: the account travels as relay frames
      **encrypted under a code-derived key** (the relay is an unauthenticated forwarder —
       [[relay-locals-additive-bind-fanout]] — assume an eavesdropper), and liveness lets both
        screens show a **matching confirm** (same emoji pair) before key material moves.
- **The carry, two postures**: (a) desktop shows its beacon (addr + ephemeral pub) as QR, the PHONE
   scans — the holder issues after scanning; the secret never touches a third party, the camera does
    the carry. (b) the phone mints a code the human types into the desktop — tolerable only because
     single-use + short-lived. Build (a); keep (b) as the no-camera fallback.
- **What moves**: the account Waft — `Identity:…,key` + `Peering` — but `%Idzeug` issuer state
   splits by **block lease**, not travel: each linked device gets its own serial range, the old
    garden's `IdzeugNumberLeap` +800 trick (Onboard_todo §0 2026-08-12 — the design solved this
     five years ago). No shared counter, no double-spend, no "primary" device.
- **The funnel this buys**: phone is the FIRST TOUCH. Cold arrival → listening only → likes accrue
   (§2) → LinkDevice → the same identity on a capable station actions the wants. Phone wants,
    station executes — the daemon's shape, the same ledger machinery underneath.

## 4. What "manage my music from my phone" becomes

The phone can't hold the share, but poke verbs + `PLAYER_OPS` + the always-on daemon already mean
 *phone commands, station executes*. That arc belongs to Daemon_todo; this doc only owes it the
  wants-ledger (§2) it will act on.
