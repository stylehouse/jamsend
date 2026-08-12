# Onboard_todo.md — first-run identity, open-share, and the BigSoundland welcome

The one living doc for the first-run funnel (commissioned 2026-07-22). When a NEW `%Identity`
 arrives — brought by an invite OR stumbling onto the webapp cold — a friendly speech-bubble UX
  should: solicit a **username**, offer **open-share** (with a hard "no sharing without FSA → use
   Chrome" warning), and offer to **join someone**. BigSoundland should treat first-timers nicely by
    REFRAMING the raw FSA permission prompt (the "FaceSucker" that Auto fires) into that bubble,
     invite-or-not. The invite-accept screen becomes the universal first-run place.

**Posture: this is a DISPLAY job (Vyto's zone, [[vyto-refactor-avoid-display]]).** The pieces already
 exist as Svelte; the work is orchestration + copy, not new wire. This doc is a SEAM MAP + handoff so
  Vyto isn't re-deriving it, plus the one thin wire contract that would help the UI. I do not touch the
   UI myself.

---

## 0. Get on with next

### 2026-08-12 (latest) — %Idzeug BECOMES THE ISSUER, and one invite stops being one particle

The owner, reading his own `.jamsend/account/f5da6599b8505881/toc.snap` and finding **279 `%Idzeug`
 rows** in it: *"issuing an Invite just winds up a number of the Idzeug that issued the invite"*, and
  *"the Idzeug has a number that we omit from the invite datagram if it is one"*. And on the sheet:
   *"the %Blotter doesn't hang around at all, the Serial is simply wound past them all, and their
    Invites wander off into the world. we have no idea they're a group, ongoingly."*

**The renaming that unlocks it.** `%Idzeug` is not an invite. It is **the scheme behind an invite —
 its class**. An Invite is an *instance*: a serial drawn off an Idzeug, which then wanders off into
  the world carrying nothing but its number and a MAC.

**Why this is free, cryptographically.** `Swarm_presig` is a deterministic ed25519 **MAC, not a
 third-party signature** — only the issuer's key makes it, and regenerating it IS the door's check.
  So verification stores nothing. The per-invite record was only ever doing three jobs, and the
   issuer does all three without a row each:

| the record's job | today | as an issuer |
|---|---|---|
| "we issued this" | the row exists (`refuse('unknown')`) | `i < next` |
| params for the presig + the grant | `Swarm_record_params(record)` | the Idzeug's own `to` + params |
| spend state | `spent` on the row | the `claimed` run-list |

**Shape.**

    Idzeug:1,to:Music,next:280,claimed:3-5~9~14

**`next` IS the issuer tell — there is no marker key.** An issuer always carries `next`; no legacy row
 can (a per-invite record wears only `to`/`ttl`/`chain`/`holder`/`spent`/`blotter` + Feature params,
  and no Feature has a `next` param — 0 of the owner's 279 rows have one). A first cut stamped a
   separate `scheme:1` and the owner caught it on sight: a marker asserting what the real data already
    said, landing in every production account file for nothing. Do NOT instead infer it from "the
     mainkey looks like a small integer" — a legacy 12-hex nonce is all-digits ~0.5% of the time,
      which over a few hundred rows is a coin-flip.

`next` is the wound-up high-water; a mint returns `next` and winds it. A **blotter is a range mint** —
 wind `next` past N and hand out N tokens. Nothing records the group. (Labelling a group: the owner
  looked at it and said *"almost but not quite for v1.0"* — so **not now**, and when it comes it is a
   label on a range, never a resurrected `%Blotter` with 126 members.)

**⚠ `~`, never `,`, in the run-list.** `encode_stringies` (Text.svelte:606) forces the WHOLE line to a
 JSON blob if any value contains `, \t \n`. `claimed:3-5,9,14` would encode as
  `{"Idzeug":"1","to":"Music","claimed":"3-5,9,14"}` — legal, and it defeats the entire point of the
   change, which is that the file becomes readable by eye again. Verified by reading the encoder, not
    assumed.

**The token, unchanged except its serial leg.** `<prepub16>*<serial>*<n>*<presig16>`, where
 `serial = <i>` when `z == 1`, else `<z>.<i>`. **The presig signs the CANONICAL `z.i` always**, and
  the parse re-expands the omitted `1.` before regenerating. Sign the wire form instead and the day
   some path emits the long form for `z=1` every such invite dies `forged` — one crypto domain, one
    spelling. Guessable serials cost nothing: the 48-bit random nonce was never the secret, the
     64-bit presig always was.

**THE FORK — chain invites cannot fold, and the owner's steer was not taken literally.** He said
 chain invites *"probably should just be numbers checked off as we have them designed here"*, with
  chain itself **on hold**. It cannot be done: a `chain:1` invite (§6.3a) tracks a **moving holder**,
   mutable per-invite state that no counter represents, and `Swarm_reinvite_ok` rewrites it every
    hop. Folding it would DELETE the feature, not shrink it. So: **plain invites fold into the
     issuer**; **a chain keeps its record**, untouched, with SwarmChain still green over it. On hold
      is not deleted, there are zero chain invites in the wild, and nothing is lost if it comes back.
       When it does, holder-state is the thing to revisit — not now.

**LANDED 2026-08-12 — the whole redesign, green.**
 New verbs: `Swarm_iz_issuer` (find-or-create) / **`Swarm_iz_issuer_of`** (find only) / `Swarm_iz_wire`
  / `Swarm_iz_find` / `Swarm_claimed_has` / `Swarm_claimed_add` / `Swarm_iz_spent` / `Swarm_iz_claim`
   / `Swarm_mint_invite` / `Swarm_issued`. Gone: `Swarm_blotter_claimed`, and `%Blotter` is never
    written again. `Swarm_invite_url` lost its `nonce` parameter. `Swarm_mint_idzeug` **survives** as
     the chain mint plus the fourteen Books that pin named nonces — which is why the Book cost came in
      at **two** re-records, not the five feared: only `SwarmInvite` and `SwarmBlotter` actually moved.

 **⚠ A READ VERB THAT MINTED BY ASKING — the bug this build actually hit.** `Swarm_issued` called
  `Swarm_iz_issuer`, which is find-or-**create**. The SwarmBlotter witness calls `Swarm_issued` every
   pass, so an `Idzeug:1,next:1` appeared at **beat 2** — before the sheet was printed, in the
    one Book whose subject is *when issuing happens*. Split into `Swarm_iz_issuer_of` (returns null).
     The general shape is in CLAUDE.md already (`oa` is a probe, `oai` creates); the specific trap is
      that a **read helper one call deep** inherits the creation, and a witness runs it every pass.

 **Proof.** `SwarmBlotter` 5/5 `caveat:0` no gaps, `SwarmInvite` 5/5 `caveat:0`, and eight regression
  Books (`SwarmStaple SwarmWire SwarmDoor SwarmPolicy SwarmChain SwarmShare SwarmSpoof SwarmDisk`) all
   `ok_pct 1` with **zero `step=N,dige` lines moved** — their churn is the ghost manifest, which moves
    whenever Swarm.g recompiles. The run-list codec was separately unit-tested against the EMITTED
     `gen/S/Swarm.go` text (40 assertions incl. a scrambled 126-claim sheet coalescing to `1-126`),
      and the harness mutation-checked so a wrong answer really does go red.
 The blotter Book's whole account is now one line: `Idzeug:1,to:Music,genre:Jazz,next:4,claimed:1` (that Book scopes its Feature to a genre; production mints a bare `{ Music: 1 }`, so a real account reads `Idzeug:1,to:Music,next:N`).
  A live invite token fell from ~54 to **41 characters** — a smaller QR, for free.

**STILL OPEN — the owner's own file does not shrink by itself.** Of his 279 rows only **2 are spent**;
 277 are outstanding invites someone could still walk in with, so `Swarm_iz_find` tries the legacy row
  FIRST and they keep working forever. That is deliberate and it means **coexistence cannot compact
   them**. Realistically 252 are two printed test sheets and the rest is testing junk — but voiding
    live invites is the owner's call. When he says so, dropping the unspent legacy rows (keeping every
     `spent` one, or the ledger un-spends them) is a one-liner. Until then his account stays 279 rows
      and every NEW invite is a number.

**LANDED ALREADY (2026-08-12), separable and worth keeping either way — `Swarm_iz_mark`.**
 A claim reached Dexie instantly (`Swarm_iz_stash`) but reached **disk only by luck**.
  `Clustation_mirror_account` (Auto.svelte:483) throttles on the mark
   `prepub:ident.version:peering.version` and confesses its own gap: *"a mutation that bumps NEITHER
    would not re-mirror until the next boot."* A spend is a bare `sc` write, and `bump()` is **local**
     (Stuff.svelte.ts:259 — it moves this particle's serial, never its parent's), so a claim moved no
      version. It reached disk only because `Swarm_seal` creates a `%Pier` straight after and creation
       bumps the Peering. Luck runs out where no seal follows: a **re-seal** finds rather than creates,
        and **both chain-holder moves never seal at all**. Losing a spend mark un-spends an invite on
         the next disk-seeded boot — a security fact, not a nicety. `Swarm_iz_mark(ident, record,
          patch)` now writes all three homes (sc, stash, bump) so no future caller can write two.
   Proven by run: SwarmInvite 5/5, SwarmBlotter 5/5, SwarmChain 5/5, all `caveat:0`. Proven by
    reading, NOT by run: that the bump reaches the mirror — the mirror is app-layer, called every boot
     tick and throttled only by that mark, so the chain is complete but no Book can witness it.

### 2026-08-12 — "IS THE INVITE TOTALLY ROBUST?" — the audit, and the two holes it found

The owner asked. The honest answer is **the happy path is proven and the edges were not** — three
 defects, all in the same shape: *a real invite that the door failed to recognise as one*.

**Fixed today.**
1. **A relic was invisible to anyone who already had a friend.** An old-garden invite lives in the URL
    *fragment*, so `boot_param` cannot see it and `landing` (which reads `?Iz=`) is false for one. A
     brand-new person got the door anyway — by the accident of being friendless. Everyone else followed
      an old link and the app said *nothing at all*. `SwarmStandup` now stamps `door_relic` (same
       publisher as `door_friends`, so the Butler still names no subsystem) and the Butler shows the
        door at the **offer** rung.
    - **Never at `landing`'s hold rung**, and this is the load-bearing bit: a relic *cannot* resolve
       here yet, so a hold on one would never end. Offer, not gate.
2. **Pasting an old link said "that link's invite did not parse — ask for a fresh one"** — which reads
    as "you mistyped it" about a perfectly well-formed link. `paste_load`/`paste_try` now fall through
     to the legacy parser and name the sender.
3. **`Swarm_iz_of_url` got two real link shapes wrong**: `…?Iz=<tok>#anything` returned the token with
    the fragment glued on (messengers append them), and `…#frag?Iz=x` read a `?Iz=` living *inside* a
     fragment as a query param. `location.search` — what the live door reads — has neither problem, so
      this function carried both alone while its own comment called it "the boot handler's core".

**What is now proven, and by what.** SwarmInvite 5/5 and SwarmPolicy 6/6 green on a live runner
 (`caveat:0`) — the mint→scan→redeem→seal arc and the door policy including the legacy parse. The
  README's own demo link was checked against the real regex and parses: `prepub=7950f300faa8a4f9`,
   `advice=ope.n~0`, `sign=729547c09f15f29f`.

**What is NOT proven, and say so rather than imply otherwise.** The **render** of the new relic door
 and of the dismissal control has been reasoned about, not seen. This container has no browser libs
  (`pw_drive` mode B dies on `libglib-2.0.so.0`), so UI verification needs the human or a CDP bridge.
   The dismissal's *logic* is exercised (12 cases, including "a second invite still holds" and
    corrupt-store recovery); its *pixels* are not.

**The per-invite dismissal has landed, alone and on purpose.** `dismiss_invite`/`invite_dismissed` in
 `boot.ts`, keyed by token, localStorage, bounded at 20. It is the prerequisite `Butler.svelte:246`
  names as blocking the owner's stricter hold (*"stay on every Invite it discovers until it is
   fulfilled"*). **The stricter hold is still NOT shipped** — that remains the next move, and it may
    only ship once the dismissal has been seen working in a real tab.

- **It is offered ONLY to someone who already has friends** (the owner, on the first version:
   *"shouldn't offer them that if they have no other friends, are a new account"*). For a friendless
    person this invite is not one demand among several, it is the only thing they have, and a way past
     it is a way to an empty app. They still have ▦ — the difference is that ▦ is an exit they choose
      rather than one we suggest.
- **"To the side" is literal, not a euphemism.** Dismissing releases the *fullscreen* hold; the invite
   stays on the page's own glass door (`DoorFace` mounts the same panel) with its JOIN button intact.
    Had it actually discarded the token, the control would have been the worst thing on the card.

**What the private key unblocks — legacy rung 2.** Today the old door is parse-only: `granted:'ftp'`,
 never a Music Feature, no verification, because the signing key and spend ledger are still in the old
  garden's Dexie. Rung 2 is lifting them into `%Idzeug` records so an old link can actually be
   *honoured* rather than merely named. Until then every relic honestly ends at "ask for a fresh QR".

The recon (2026-07-22) found the funnel is ~80% already built as components — the job is to make the
 new-here flow UNIVERSAL (fire invite-or-not) and fold in open-share + the FSA/Chrome warning. Order:
1. **LANDED 2026-08-08 — and the clock is gone.** The cold trigger already existed: `namer` renders on
    `{#if !named && !iz}`, where `named` is backed by `self.sc.friendly` — durable, persisted, a real
     first-run state, not a sniff. What was wrong was the welcome note beside the mint button, gated
      `born_today && !friends.length && !iz`. `born_today` means "identity minted today", which is a
       CLOCK, and it silently withheld the welcome from precisely the person who most needs it: someone
        who minted an identity yesterday, never got a friend, and came back today. Now `!friends.length
         && !iz` — the note explains what the button does, and the moment that explanation is worth
          having is "you have no friends yet".
   - Correcting an overstatement written earlier the same day: I claimed this also mis-fired at a
      *returning* same-day visitor. It did not — `!friends.length` was always required too, and someone
       with no friends is someone the note should reach whatever the date. Only one of the two failure
        modes was real. The fix stands; the diagnosis was half wrong.
   - Item 4's wire contract is therefore **not needed for this**, though it may still be worth having for
      the open-share offer in item 2.
2. **DONE 2026-08-08 — the FSA/Chrome warning.** `InvitePanel` had no capability warning at all: someone
    landing in Safari or Firefox got the friendly welcome and an "invite a friend" button, and would only
     discover sharing was impossible after a friend had scanned their QR. Now reads the SAME predicate the
      sharing layer uses (`!('showDirectoryPicker' in window)`, per `Shares.svelte:22`) rather than a fresh
       sniff, so panel and machine cannot disagree. Two placements, deliberately different in weight: on the
        mint face it sits BEFORE the button (the point is to stop a QR being minted for nothing); on the
         landing face it sits AFTER the join button and quieter (a joiner came to hear someone else's music,
          which FSA does not gate — do not put a warning between them and the act they arrived for).
   - Set in an `$effect`, not at init: `/BigSoundland` server-renders, and reading `window` at init would
      make the SSR and hydration passes disagree about whether to draw it.
   - **Copy states only what is certain** — no folder ⇒ no sharing. It does NOT promise that listening
      still works; `Directory.svelte:37` suggests the share layer degrades rather than dies in
       `compat_mode`, but nobody has run this on a real Safari, and a welcome screen is the wrong place
        to guess. **If someone verifies listening works without FSA, the copy should say so** — that is a
         much kinder message than the one there now.
   - Still open from this item: the **open-share offer** itself was not folded in, only the warning.
3. **(Vyto)** Reframe the `BootGate`/`FaceSucker` first-FSA prompt on BigSoundland so it reads as the
    same friendly bubble, not a bare hoister.
   - **LANDED 2026-08-09 — the funnel moved INTO the glass** (the owner: "shake out the UI outside of
      Vyto, ie fullscreen the latter, with Invite management in there").  `%Door` left the `show_diag`
       branch and joined Sounditron's always-on organ set, DoorFace grew a folded **invite door**
        hosting `InvitePanel` in a new `inglass` dress (one implementation — the arc Book SwarmInvite
         proves — with the identity title and friends list suppressed because DoorFace already says
          both), and BigSoundland's resident glass view lost its header and strip entirely.  The
           sprawl and boot-diagnostic rooms keep every scrap of chrome; `▦` and the `?` key are the
            way back.
   - **The trap this had to solve, worth knowing before moving any other panel into a cell:** a face
      mounts only while its cell is roomy enough to draw one, so anything load-bearing that hangs off
       a panel's `$effect`s becomes conditional on the tessellation.  InvitePanel's effects were
        standing the swarm STATION and arming the SHARE.  Left where they were, a crushed Door cell
         would have meant nobody could dial you — with every local reading healthy and the only tell
          a friend's scan timing out.  They now live in `ui/SwarmStandup.svelte`, mounted hidden
           beside the spine shims under BigSoundland's own doctrine ("outside the view switch so the
            view choice can't starve the boot").
   - The strip mount **stays** on the non-glass rooms, deliberately: someone opening a scanned `?Iz`
      lands there *before* any world has commissioned a glass.  A join button that only exists inside
       a cell would make the whole invite funnel depend on a successful boot — precisely the thing an
        invite is most likely to arrive in the middle of.
   - Item 3 proper (the FSA bubble) is **still open**; this changed where the door lives, not how the
      first FSA prompt reads.
4. **(me, if wanted)** The thin wire contract below — a first-run "needs-onboarding" state + a clean
    capability read — so the bubble renders STATE instead of sniffing conditions inline.

---

## The arc

Nothing new needs minting for the happy path — the identity, the username store, the FSA gate, and the
 Chrome detection all exist. What's missing is (a) the trigger to run the welcome on a COLD first run,
  not just an invite landing, and (b) one bubble that carries all three offers (name / share / join)
   with the FSA caveat, wrapping the currently-bare FSA prompt. That's presentation glue.

---

## What already exists (recon map — don't rebuild; verify line #s on contact)

**The cold first-run mint** (`src/lib/O/Auto.svelte`, WIRE on the House/C model):
- `Clustation_ensure_default` (~:309) — "this page always has an identity"; `/BigSoundland` is always the
   `'sound'` role identity, minted/resumed by role. This is the COLD-arrival mint (no invite).
- `Clustation_ensure_identity` (~:115) resolves `?I=` (`?I=new` mints, `?I=<tag>` resumes, absent ⇒ inert).

**The username store** (WIRE): `Clustation_friendly(name)` (`Auto.svelte` ~:190) stamps `friendly` on
 `%Identity`+`%Peering`, persists via `thang_put`. `cluster_name(prepub)` (`src/lib/cluster_name.ts:23`)
  is the deterministic default nick before a friendly is chosen.

**The username-ask UI** (DISPLAY, `src/lib/O/ui/InvitePanel.svelte`): the `namer` snippet (~:250),
 `name_save` → `Clustation_friendly` (~:157), "what do friends call you?" (~:273), "✨ you are new here"
  (~:292). Also the join door: `?Iz` landing verify + `join()` → `Swarm_redeem`, born-today auto-join,
   `?Iz`→`?I=<prepub>` swap. **This is the existing speech-bubble-shaped seam — grow the welcome here.**

**The FSA gate / FaceSucker** (DISPLAY over WIRE):
- `src/lib/O/ui/BootGate.svelte` — renders the FaceSucker ("one tap to open the music", ~:92) when
   `H.c.disk_gated` or an audio demand; `open_share()` (~:67) fires the FSA folder picker + AC resume
    inside the click gesture. `proactive` mode for music toplevels.
- `src/lib/p2p/ui/FaceSucker.svelte` — the fullscreen hoister SHELL; copy comes from BootGate's snippet.
   THIS is the "FaceSucker" the human named.
- `H.c.disk_gated` raised/cleared in `src/lib/O/Housing.svelte.ts` (~:1799 clear on real share, ~:1829
   raise under `?E=`/`?B=` where OPFS-from-github is illegal); the raw FSA call is
    `requestDirectoryAccess()` → `window.showDirectoryPicker` (`src/lib/p2p/ftp/Directory.svelte.ts` ~:445).

**The "use Chrome" seam** (DISPLAY): `src/lib/p2p/ftp/Shares.svelte:22` —
 `compat_mode = !('showDirectoryPicker' in window)`. The warning belongs beside this flag.

**BigSoundland wiring** (`src/lib/V/BigSoundland.svelte`, DISPLAY): boots via `boot_qualand({role:'sound'})`
 (~:41); already mounts `<BootGate proactive audio_fullscreen>` (~:164) and `<InvitePanel>` (~:197). Both
  reframe points are already on the page — this is why the job is orchestration, not plumbing.

**Red herring:** `SurprisePopover.svelte` is an IDE editor artifact, NOT onboarding — do not attach the
 welcome bubble there.

---

## The thin wire contract (mine, if the human wants it)

To keep the bubble rendering STATE rather than sniffing conditions inline, the wire side could expose:
- a first-run **`needs_onboarding`** read on the active identity (true until a `friendly` has been chosen
   AND the share/decline choice has been made) — so the bubble's steps are data, not `if`-soup;
- an **open-share decision fact** stored on `%Identity`/`%Peering` (chose-to-share / declined / unsupported)
   — a durable scalar, `1`-or-absent per the boolean rule, so "already answered" survives reload;
- the **capability** (`compat_mode`) surfaced as a read the bubble consumes, so the "use Chrome" warning
   and the share offer are the same source of truth.
None of this is required for Vyto to build the UI against the existing hooks — it's ergonomics. Build only
 on the human's say-so; otherwise the UI can read the existing `friendly`/`disk_gated`/`compat_mode` directly.

---

## HUMAN decision

How far do I go on this? RECOMMEND: I write **only the thin wire contract above** (if you even want it),
 and hand the whole UI job to Vyto with this map. The alternative — I touch `InvitePanel`/`BootGate`/
  BigSoundland myself — collides with the display refactor and I'd advise against it. Say the word if you
   want the wire contract built; otherwise this stays a handoff.
