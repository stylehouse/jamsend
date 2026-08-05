# UI_seams_todo.md

The data model has run ahead of the glass. Every seam below is a place where the
 wire side landed a capability, proved it green in a Book, and the resident UI never
  caught up — or caught up only halfway. This is the "well defined list of seams
   waiting on UI" the human asked for, verified against live code (not memory) on
    2026-07-27.

## HUMAN — one decision, recommendation first

**Most of these are display-layer edits, and display is your Vyto-refactor zone.**
 My standing rule is *no blind display edits there*. So this doc is deliberately a
  **map + ready-to-apply diffs**, not applied changes. My recommendation:

- **I take the wire-side items** when you green-light them: S3's live-heist *driver*
   (`.g`, needs a Book), and the S1 crew-reassignments (`.g` authoring — one word each).
- **You (or Vyto glass work) take the face edits**: S4 (now-playing provenance),
   S2 (Crate/Mag faces), S5 (roster page). I've written the exact diffs for the two
    smallest (S4, S1) in the appendix so they're a 30-second apply when you're back at
     the glass and can watch it.

Nothing here is applied. Nothing is committed.

## 0. What to get on with next

Pick from, roughly in ascending effort:

1. **S4 — now-playing provenance.** The smallest, and you explicitly asked for it
    ("know which Pier a given track playing is coming from"). The data is already on
     `radio.sc.by`; `RadioFace` just doesn't read it. ~4-line display diff in the appendix.
2. **S1 — quiet the resident glass.** Two crew-value edits move the Stoker and the posed
    Heist off the *drawn* clean glass — that's the everyday "what do I care about stoker"
     clutter, and the whole of the ready paste. (The raw `%desc`/`%sworn`/Storui the human
      sees is a separate *stall* fallback, not the working glass; an optional `?diag` gate
       covers it — see S1/Appendix A.) Appendix has both.
3. **S2 — a face for the Mag/Cloud layer** so the Crate reads as collapsible per-Pier
    magazines ("open one at a time per Pier"), not a flat capped chip-pile.
4. **S3 — make heist a real action.** The engine is built and green; there is *no live
    caller*. This is the biggest gap and the one with the clearest "I don't see how to
     heist" behind it. Needs a live driver + a Book.

S5 (roster page) and S6 (legacy Dexie migrator) are lower priority — S6 degrades
 gracefully already.

**Explicitly DEPRIORITISED — "Sharing a Mag" (human, 2026-07-27).** Do not build a bespoke
 "share this Mag" feature. It is just an **Invite carrying extra signed data** that says
  "try this Mag first" — and that same signed-payload slot generalises to "run this code" or
   "assume this role temporarily". So the real thing (later) is a **capability invite**: one
    signed-payload mechanism on the existing invite rail, of which try-this-Mag is the
     smallest instance. Building Mag-share on its own would bake a one-off where a general
      slot belongs. Parked until the payload abstraction is designed — see the note after S6.

## The Vytui north-star (human, 2026-07-27) — the inverse allowlist

The UX bet: **Vytui is the only surface most users ever see.** It FaceSuckers you (prompts the
 FSA grant) and presents *simply* — "one huge thing and a few smaller things" (the sizing algebra
  + fold). The machinery — the chronicler/solver/governor/scribe layer, Storui, `%desc`, the
   diagnostic tables — is **hidden by default**, reachable only via a **secret FaceSucker release
    switch** (the dev/diagnostic escape). This *inverts* S1: rather than tucking machinery
     item-by-item, the simple view is an **allowlist** — only a few named user-faces draw,
      everything else defaults to `system` (already the allowlist-inversion behaviour,
       `Cyto.svelte:444-452`). "Not too much at once" + "fold a tree around as they want it" is
        already designed in the **Vyto foam study**: screen-budget `budget_for`, `fold_ladder`,
         dive/zoom/ancestor-crack, focus-warp — `Vyto_todo.md` + `vyto_workingouts/processes.md` +
          `Vyto_sizing_todo.md`, and [[vyto-foam]]. So the "fold" the human wants isn't owed — it's
           built in the foam layer, waiting to be the *default* presentation.

Concrete near-term asks under this star (all display = the human's Vyto zone; wire noted):
- **Presence first — "is the other Pier online?"** *Largely BUILT.* `pier.c.heard_at` is stamped
   on every inbound frame from a sealed pier (`Swarm.g:453`, c-side, never snapped), and
    **`DoorFace.svelte` already renders a liveness dot** — green within 12 s of their ~5 s pulse,
     dim beyond (`:10/:46/:49`). Seam = surface that dot *prominently* in the simple Vyto view.
      Display placement, **no new wiring**.
- **Self-rename in the Invite panel.** *Wire ready.* `Clustation_friendly` already re-persists a
   new name (`Auto.svelte`, `thang_put` under prepub+role); the only blocker is the InvitePanel
    **latch** that closes the name-ask once you're named ("a rename never un-names",
     `InvitePanel.svelte:151-155`). Seam = a small edit affordance that re-opens the namer →
      `Clustation_friendly(new)`. Tiny display edit; wire done. *(Reading: the Pier renames
       *itself* — its own `friendly`, which friends see. If instead you meant relabelling a
        *friend* locally, say so — that's a different `%Pier.friendly` write.)*
- **The machinery-table tuck** — the chronicler/solver/governor/scribe archetypes. No literal
   mainkeys by those four names exist in code (grep-checked); they read as the req/Story/Lang/Vyto
    machinery (`CREW_MAINKEYS` already tucks `req`/`Machine`/`Relay`/`Census`/`Session`/`Storyrun`/…
     → `system`). The tuck is the same allowlist. To hide a *specific* table precisely, point at the
      surface it shows on (a face? the diagnostic fallback? the sprawl?) — under the Vytui allowlist
       it stops drawing by default anyway.

## The arc

jamsend's bet is that every kind of state becomes the same legible living matter. The
 wire side has honoured that: stock, mags, grants, piers, heists, provenance all exist
  as particles, each proven in a Book. The **glass** is where the bet is currently
   half-kept — it renders the *contents* (record chips, a queue, faves) but not the
    *structure* (the magazine, the paging, the replication unit, the friendship ledger,
     the act of taking). Closing these seams is what turns "a test runner that happens
      to play music" into "an app you'd share a domain of music from."

---

## Render-surface primer — the one fact that reframes "far too busy"

`BigSoundland.svelte` picks exactly **one of three bodies** per render:

| Surface | file:line | Who sees it | Content |
|---|---|---|---|
| **Clean glass** (resident) | `src/lib/V/BigSoundland.svelte:230-235` | a live `?I=` listener once the graph draws | full-bleed Cyto/Vyto voronoi — **faced organs only** |
| **Diagnostic fallback** | `BigSoundland.svelte:236-261` | anyone while the glass has NOT drawn ("gathering the glass…") | `run_uis` — every non-Cyto UI, incl. **Storui** (raw `%desc`/`%sworn`/`%see`) |
| **Sprawl (▦)** | `BigSoundland.svelte:211-229` | anyone who toggles ▦ | every House's UIs dumped, Storui + Cyto included |

The clean glass is **already self-cleaning**: `Cyto.svelte:393` defaults the Tuner mute
 to `{system:1}`, and the allowlist inversion (`Cyto.svelte:444-452`) forces every
  undressed, un-crewed cell into `system` → dropped from the graph. So on the clean
   glass, `%desc` / `%sworn` / `%see` / `%log` / `%Machine` / `%req` are **tucked by
    default** (they still snap — proof intact — they just don't draw).

**So the "%desc / %sworn" the human sees is not the clean glass** — it's the diagnostic
 fallback (whenever the glass stalls) and the ▦ sprawl, both dominated by **Storui**
  (`src/lib/O/Storui.svelte:204-207` — per-step `%desc`, sworn/ghost assertion lines,
   dige diffs, verdict). A `?I=` listener has no business mounting Storui at all. That's
    S1.

Two things **do** genuinely leak into the *clean* glass, because they're dressed with a
 face and crewed to a resident crew rather than `system`:
- **Stoker** (`crew:'Radio'`, `Ghost/M/Radio.g:621`) — provisioning telemetry
   (stock/fresh/dug/stood/worn). This is the "what do I care about stoker" leak. Real.
- **Posed Heist** (`Ghost/Story/Sounditron.g:411`, `{Heist:'…',posed:1}`) — a fabricated
   demo nugget, inert (no button, see S3). It has **no `sc.crew`**; it draws because
    `cyto_crew` (`Cyto.svelte:759`) falls through to its face-kind `FACE_MAINKEYS[Heist]='Heist'`
     (`glass_faces.ts:9`) — a non-`system` crew, so it isn't tucked. The fix is therefore to
      *add* `crew:'system'`, not edit a crew line that doesn't exist.

---

## Proof freshness — which "green" is fresh, which is suspect (post-`0662da0a`)

The engines below are all proven by recorded golden fixtures. But the human's commit
 `0662da0a "get it together"` changed six ghosts — `Ra.g`, `Radio.g`, `Swarm.g`,
  `Swarmation.g`, `Vyto.g`, `Vytonation.g` — and re-recorded **some** dependent Books
   but not all (same pattern that left PereProof stale-red). So:

- **Fresh (re-recorded by the commit — trust these):** MusuMag, MusuHeist, MusuBuddy,
   MusuStock, MusuStanding, MusuWear, MusuRaChase, MusuRaStream, Sounditron, and the
    whole Swarm* / Vyto* families. My S2 anchor (MusuMag) and S3 anchor (MusuHeist) are
     both here — the capability proofs this doc leans on are on the fresh side.
- **Suspect (NOT re-recorded despite the upstream `Ra.g`/`Radio.g` churn — verify before
   trusting a live green):** MusuSoft, MusuBay, MusuBreach, MusuCursor, MusuReplica,
    MusuReco, and the Pere* family (PereProof already confirmed stale-red this session,
     PereComplain green). These sit on pre-`0662da0a` fixtures; a red on them is almost
      certainly fixture-staleness, not a regression — re-record to converge. **This is
       yours to own** (it's downstream of your in-flight ghost work; re-recording now
        would bank half-finished state).

**Live-checked on `★claude` (49dee91d), solo, 2026-07-27:**
- **MusuMag — GREEN** (`ok:true`, 10/10; the assertions latch progressively n=1→10, caveat
   settles to the entropy fuzz-tag, taken-as-ok). S2's anchor holds live.
- **MusuHeist — GREEN** (settled clean). S3's anchor holds live.
- **MusuSoft — RED at step 5**, and the absent assertion is a **Vyto foam scale/pricing
   claim** («uncoupled» — "the small cog holds a fixed base area whether or not a louder
    newcomer has joined"), i.e. a *Vyto-render* assertion downstream of the `Vyto.g` /
     `Vytonation.g` churn in `0662da0a`. This is the predicted fixture-staleness, and it
      points squarely at the in-flight Vyto work — **not** at anything on the transport /
       Swarm path. I did not run the remaining suspects (each would need a fresh reload to
        rule out shared-runner bleed, and they're all yours to re-record anyway). I did
         **not** accept MusuSoft's red — accepting would bank half-finished Vyto state.

## The seams

### S1 — Resident glass is noisier than it needs to be
*The human: "less shite… what do I care about %desc or stoker… I don't care about these %sworn bits."*

- **Built / current:** clean glass already tucks `%desc`/`%sworn` under `system`
   (primer above). The **everyday** noise on the *drawn* clean glass is just two dressed
    leaks: the **Stoker** telemetry (`crew:'Radio'`) and the **posed Heist** (crewed to
     `'Heist'` by face-kind). The raw `%desc`/`%sworn`/Storui the human sees is **not** on
      the working glass at all — it's the stall fallback (next bullet).
- **Two distinct gaps, don't conflate them:**
  - **(a) the everyday leaks** — Stoker & posed Heist draw on the *working* clean glass
     because they carry a non-`system` crew. This is the real "what do I care about stoker"
      clutter, and it's a two-value fix.
  - **(b) the stall fallback** — `run_uis` (which includes **Storui**, with its raw
     `%desc`/`%sworn`/`%see`) mounts **only** in the `{:else}` branch when the glass hasn't
      drawn (`BigSoundland.svelte:236-261`; the each-loop at `:255`). Once `cyto` draws it's
       gone. There is **no `humdinger` boolean** to gate on — every BigSoundland is role
        `'sound'` (`:46`). So a listener sees this only while the glass is stalling; a real
         gate means an opt-in (`?diag`), not a one-word guard (see Appendix A).
- **The move (wire-side, tiny — gap (a)):**
  - `Ghost/M/Radio.g:621` — Stoker mint `{Stoker:'idle',face:'Stoker',crew:'Radio'}`:
     change `crew:'Radio'` → `crew:'system'`. Hides the telemetry face from the clean glass.
  - `Ghost/Story/Sounditron.g:411` — posed Heist mint `{Heist:'…',posed:1}`: **add**
     `crew:'system'` (or stop seating it entirely once S3 lands a real one).
- **Gap (b) is a design call, not a paste:** default a plain listener to the calm
   "gathering the glass…" line and gate the verbose `run_uis`/Storui dump behind `?diag=1`.
    Optional, and it trades away debug visibility on a stall — decide with the glass in front
     of you.
- **Risk:** the two crew edits change the Sounditron snap (the `crew` value) → re-record on
   `★claude`, green×2. **Do not do this while you're using the live glass** (it churns your
    view). Diff in appendix A.

### S2 — The Mag / Cloud structure has no face
*The human: "we haven't adapted the UI at all to Mags… I should have to open the Crate, one at a time per Pier."*

- **Built (and green):** the full magazine model — `stock > %Mag:shuffle > %Cloud,page:N`
   at **6 per page** (`Ghost/M/Ra.g:622-864`: `Ra_mag_shuffle:635`, `Ra_mag_page:641`,
    `Ra_page_size:632-633`, one-door mint `Ra_rec_home:654`). The **Mag is the Repli
     unit** — it crosses as one husk (`Ra_offer_stock:743-750`). Warm start
      (`Ra_mag_warm:763`), per-record stage (`Ra_stage:826`), per-Mag cursor
       (`Radio_mag_cursor`). Proven: `MusuMag`, `MusuBuddy`, `MusuCursor`, `MusuReplica`
        (recorded golden `toc.snap`s with committed Assertions).
- **Current UI:** `CrateFace.svelte:18-25` reads the shape-agnostic census `Ra_recs` and
   **flattens every `%Record` into one capped chip spread** (`.slice(0,18)` + "+N more").
    No page numbers, no `%Cloud` grouping, no `%Mag` boundary, no warm/stage state. The
     only place `%Mag`/`%Cloud` appear *as themselves* is uninterpreted graph-node colour
      (`Matstyle.svelte:246-249`). Two *specialised* mags do have faces (`LineupFace` for
       `%Mag:'Lineup'`, `ZineFace` for `%Zine:'Faves'`) — the **core stock Mag does not**.
- **Gap:** there is **no `MagFace` / `CloudFace` / `PageFace`**. The human's "one at a
   time per Pier" maps onto: the crate is a friend's `%MusuThem` mirror → render each
    friend's crate as a collapsible magazine (its `%Mag:shuffle`), pages closed by
     default, one open at a time. The data (per-friend `%MusuThem`, paged clouds) is all
      there.
- **The move (display + a new face):** a `MagFace`/`CloudFace` in `src/lib/O/glass_kinds.ts`
   + `glass_faces.ts`, reading `%Mag:shuffle`/`%Cloud,page` instead of flattening. Medium
    effort; belongs with Vyto glass work. Not started.
- **✔ The nest-depth question is already RULED + BUILT (2026-07-26) — not a blocker.** An
   earlier draft of this seam warned that a `CloudFace` had to wait on the preen's §4 recurse
    ruling. That's stale: `Ra_recs`/`Ra_rec_find` now recurse over `Mag**` via
     `Ra_recs_deep`/`Ra_rec_find_deep` (Ra.g:679/697; DEPTH NOTE Ra.g:738; `Mag_todo.md:132`
      "RULED + BUILT"). A `%Record` is the leaf, deeper rows are **found, not dropped**. So a
       face may lean on the census walking any depth — S2 is a clean display build, not gated.
        (The one residual fixed-depth spot is `Ra_offer_stock`'s `repli_loc:['Cloud','page']`
         wire stamp, harmless until nested Mags actually exist — a wire concern, not a face one.)

### S3 — Heist has no live trigger (the engine is built and idle)
*The human: "I don't see how to heist."*

- **Built (and green):** the whole engine in `Ghost/M/Heist.g` — hard job
   (`Heist_job:229` → `Heist_offer_all:257` → `Heist_beat:305` → **`Heist_land:384`**,
    which verifies bytes and **catalogues the landed track into your own Crate via
     `Ra_rec_home` at `:520`**), and the soft wish arc (`Heist_wish:604` → `Heist_ask:635`
      → `Heist_match:648` → `Heist_condense:683`). Proven: `MusuHeist`, `MusuSoft`,
       `MusuBay`, `MusuBreach`.
- **Current UI:** the only `%Heist` a live user sees is the **posed** one
   (`Sounditron.g:407-417`, `posed:1`) — a static illustration, explicitly labelled "the
    SHAPE of the real thing so the face can be tuned before the machinery arrives here."
     `HeistFace.svelte`'s **"take" button renders only for a *soft* heist**
      (`:58-60`, `soft = sc.wish && !sc.at`, `:32`) — and the posed node has no `wish`, so
       **no button shows**. It is inert.
- **Gap — HALF-STALE, corrected 2026-08-05 (full zombie audit that day):** the claim "No
   live code mints a real `%Heist`" is now **wrong for the HARD path** — the ⇊ Keep flow
    landed 2026-07-28/30: `RadioFace.svelte:84` → `Radio_keep` (`Radio.g:1477`) →
     `Heist_keep_start` → `Swarm_share_beat` pumps `Heist_keep_beat` (`Swarm.g:1742`) →
      `Heist_job` (`Heist.g:1417`), ids-first the whole way (`at` = the friend's pub and
       `seed` = the record id from the first gesture — nothing ever resolves a name to a
        pier). It remains RIGHT for the SOFT path: `Heist_wish`/`%Lead`/`Heist_condense`
         have zero app producers (Books only — MusuSoft, MusuBay), `Heist_soft` has zero
          callers anywhere (HeistFace re-implements the predicate inline at `:32`), the
           `hid` leg of `Heist_job` (`Heist.g:280`) has never been passed by any caller,
            and a wish hardened by HeistFace's take button would be driven by NOTHING
             (`Heist_keep_beat` iterates `{Keep:1}`, not `{Heist:1}`). The owner's read
              2026-08-05 — "I think wish is dead — we have more robust paths, we already
               know for sure where it is" — is confirmed for the product as built; the
                soft arc is a half-built parallel answer the id-first Keep flow grew
                 around. Whether to retire it (2 Books, 11 fixtures, the `%Lead` face)
                  is the owner's ruling. The line numbers in the bullets above predate
                   the 07-28 rework and no longer match `Heist.g`.
- **The move (wire-side, needs a Book):** mirror the `MusuSoft` Book in live code —
   (1) a button/effect that calls `Heist_wish(w, Ra_home_shop(w, me), sentence, …)` then
    `Heist_ask`/`Heist_match` over the friend wire to populate `%Lead`s (so `HeistFace`
     lights up with real leads + the take button); (2) "take" is already wired to
      `Heist_condense` (`HeistFace.svelte:43`); (3) **the missing piece — a live driver
       looping `Heist_beat` until the mirror drains**, the analogue of `Swarm_share_loop`.
        That driver does not exist. This is the real build.

### S4 — Now-playing card drops the provenance it already has
*The human: "know which Pier a given track playing is coming from."*

- **Built:** `Radio_open` stamps the source onto the particle —
   `src = rec.c.play_by || rec.sc.from || Ra_pub_of(rec)`, then `radio.sc.by = src`
    (deleted when it's my own stock) — `Ghost/M/Radio.g:314-318`. Carried onto the
     now-playing datum as a card leaves the lineup (`:437`, `hrec.c.play_by = head.sc.by`),
      and `%Card.by` is the friend crate's pub (`:527`). The
      prepub→friendly resolver already exists and works:
       `Swarm_peering(self)?.o({Pier:1,pub})[0]?.sc?.friendly`.
- **Current UI:** `LineupFace` (up-next) **already shows** `· {who(by)}` per card
   (`LineupFace.svelte:16,26-32,41`). But `RadioFace` (the now-playing card) reads
    `title/artist/at/of/played/drops/note/pool` and **never reads `sc.by`**
     (`RadioFace.svelte:30-43`); it shows only an aggregate "⚯ N friend tracks ride the
      dial" (`:79-80`).
- **Gap:** provenance is present in the data and shown for the *queue*, dropped on the
   *now-playing* card. Display-only fix. Diff in appendix B.

### S5 — Friends / roster is thin and split across two glances
- **Built:** `Swarm_seal` builds a rich `%Pier` per friend (`Ghost/S/Swarm.g:1097-1123`):
   `friendly`, `since` (friendship-began, never reset), a nested `%Peering` with their
    full pub, **both grant atoms** (theirs *and* your copy — each with `for/time/sign`),
     a `%SocialGraph` edge, runtime `heard_at` presence. Durable across reload
      (`Swarm_pier_stash`/`_piers_rehydrate`/`_restash_piers`).
- **Current UI:** two embedded fragments — `DoorFace.svelte:46-60` (presence rungs,
   friendly, a single `♪ granted` tag, `%IveGot` boast, suggest) and the `InvitePanel`
    friends strip (`:356-367`, friendly + `⇄ Music` + count; the pub only as a hover
     `title`).
- **Gap:** no dedicated contacts page. The friend's **pub is never legible text** (only
   your own prepub8 shows); "the grants you exchanged" is **collapsed to one boolean**
    (both directions + `for/time/sign` are stored, none surfaced); `since` is stored,
     shown nowhere. Display work; belongs with Vyto glass.

### S6 — Invite legacy Dexie migrator is owed (everything else is wired)
- **Built & live:** mint + QR (`InvitePanel.svelte:121-133`, `:328/:370-384`), ?Iz
   scan-to-join (`join()` `:212-251`, LIVE-PROVEN), the recently-added paste-a-link row
    (`:258-275/:338-345`, redeems under the enclosing page's `?I` — hidden once a link is
     landed/parsed), and name-first gating.
- **Gap:** the legacy `#`-fragment / old-garden invite is **parse-only** — it names the
   inviter but says "cannot verify here yet — ask for a fresh QR" (`:292-298`), because
    the old ledger + signing key still live in the old garden's Dexie and **no rung-2
     migrator** lifts them into `%Idzeug` records (`:135-138`, `Swarm.go:356-364` —
      confirmed not built). Degrades gracefully; lowest priority.

### (deferred, not a seam yet) — the capability invite
*The human, 2026-07-27: "Sharing a Mag… it's just an Invite with some extra (signed) data
 to say 'try this Mag first', which could become 'run this code' or 'assume this role
  temporarily'."*

Not on the build list — recorded so it isn't rebuilt piecemeal. The insight: **an invite is
 already a signed capability grant** (compact token + 3-frame seal, [[invite]]); the natural
  generalisation is a **signed payload slot** on that same rail. Its instances, in ascending
   trust:
- **try-this-Mag** — a data pointer (a `%Mag`/`stock` id + "start here"). The smallest; this
   is what "sharing a Mag" collapses to. Deprioritised precisely *because* it's the trivial
    case of the slot.
- **run-this-code** — a signed `.g`/gen fragment or dock; touches the Lies compile|run rail
   and the runner-fleet's signed `%Rungo` claim/lease (`Cluster_spec §2-7`).
- **assume-this-role-temporarily** — a scoped, time-boxed role delegation; touches
   cluster-trust (sign on the crypto identity) and the C2 dispatch seam.

Design consequence: **don't bake a Mag-specific share path.** When the payload slot is
 designed (what's signed, how the receiver's trust gate scopes/expires it, how it rides the
  token vs a follow-up frame), try-this-Mag falls out for free — and the far more valuable
   run-code / assume-role land on the same tooth. Owner's call when to open it; the seams
    above come first.

---

## Wire-side vs display-side (who does what, so I don't stray into the Vyto zone)

| Seam | Kind | Safe for me (wire/`.g`/Book) | Yours / Vyto glass (display face) |
|---|---|---|---|
| S1 declutter | mixed | two crew-value edits in `Radio.g`/`Sounditron.g`; optional `?diag` stall gate | — |
| S2 Mag face | display | (data already there) | new `MagFace`/`CloudFace` |
| S3 live heist | wire | `Heist_wish` trigger + `Heist_beat` driver + Book | wiring the button state in `HeistFace` |
| S4 provenance | display | (data already there) | `RadioFace` reads `sc.by` |
| S5 roster | display | — | contacts face |
| S6 migrator | wire | rung-2 Dexie→`%Idzeug` migrator + Book | — |

---

## Appendix A — S1 declutter, ready to apply (do with the glass in front of you)

**1.** Stop the Stoker telemetry leaking into the clean glass — `Ghost/M/Radio.g:621`
 (the line reads `st = w.i({ Stoker: 'idle', face: 'Stoker', crew: 'Radio' })`):
```
-        st = w.i({ Stoker: 'idle', face: 'Stoker', crew: 'Radio' })
+        st = w.i({ Stoker: 'idle', face: 'Stoker', crew: 'system' })  // telemetry — tuck it; reveal via the Tuner
```
**2.** Tuck the posed Heist — `Ghost/Story/Sounditron.g:411`. It has no `crew` key, so
 **add** one to the mint (the line reads `let h = w.oai({ Heist: 'the one they played last night', posed: 1 })`):
```
-    let h = w.oai({ Heist: 'the one they played last night', posed: 1 })
+    let h = w.oai({ Heist: 'the one they played last night', posed: 1, crew: 'system' })  // demo pose, off the clean glass until S3
```
Both `.g` edits change the Sounditron snap (the added/changed `crew` value) → re-record on
 `★claude` (49dee91d) and converge green×2. **Not while you're using the live glass** (it
  churns your view).

**3.** *(optional, gap (b) — not a mandatory paste)* Gate the stall-fallback Storui dump
 behind an opt-in so a plain listener isn't dropped into raw `%desc`/`%sworn` when the glass
  stalls. `src/lib/V/BigSoundland.svelte` — add a boot flag near `:56`
   (`const vy = !!boot_param('VY')`):
```
+    const diag = !!boot_param('diag')   // a plain listener stays calm on a stall; ?diag=1 shows the machine
```
then wrap the each-loop at `:255` (`{#each run_uis as { house, ui } (keyser(ui.sc))}`):
```
+            {#if diag}
             {#each run_uis as { house, ui } (keyser(ui.sc))}
                 ...the diag-tagged UI...
             {/each}
+            {/if}
```
This only affects the `{:else}` stall branch — it never touches the drawn clean glass.
 There is **no `humdinger` variable** to guard on; this opt-in is the real gate. It trades
  away debug visibility on a stall, so it's your call, not an auto-apply.

## Appendix B — S4 now-playing provenance, ready to apply (display-only)

Verified against the live `src/lib/O/ui/RadioFace.svelte` (124 lines).

**1.** Add `by` to the face `return {...}` (the block ends at `:41` with `stock,`):
```
             note:   sc.note as string | undefined,
+            by:     sc.by as string | undefined,   // source prepub Radio_open stamped (Radio.g:314-318)
             first:  ((sc.Radio ?? 'off') === 'off') && !sc.title && !+(sc.played ?? 0),
             stock,
```
**2.** Copy `who()` verbatim from `LineupFace.svelte:26-32` into the `<script>` (it already
 has `H`):
```
    function who(pub: string): string {
        try {
            const self = (H as any)?.Swarm_live_self?.()
            const pier = self && (H as any)?.Swarm_peering?.(self)?.o({ Pier: 1, pub })?.[0]
            return pier?.sc?.friendly ? String(pier.sc.friendly) : pub.slice(0, 8)
        } catch { return pub.slice(0, 8) }
    }
```
**3.** Render it in `.rf-mid`, right after the note line (`:61`):
```
             {#if face.note}<div class="rf-note">{face.note}</div>{/if}
+            {#if face.by}<div class="rf-via">· via {who(face.by)}</div>{/if}
```
`.rf-via` can reuse `.rf-note`'s styling (small, dim). **The word is "via", not "from"**
 (human 2026-07-27): `sc.by` is the **Pier this copy came *through*** — the carrier — not the
  track's author; "from Steve" would wrongly imply Steve made it. Same correction applies to
   `LineupFace`'s live text if it reads "from". `sc.by` is a *prepub*; `who()`
 degrades to `pub.slice(0,8)` when no `%Pier` matches (a non-friend source), so it's always
  renderable. Note `radio.sc.by` is *deleted* when the track is your own stock
   (`Radio.g:318`), so the tag simply won't render for your own music — correct.
