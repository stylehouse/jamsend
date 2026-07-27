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
2. **S1 — quiet the resident glass.** Move the Stoker and the posed Heist out of the
    resident crews so they stop leaking into the clean glass, and never mount `Storui`
     for a `humdinger`. This is what "less shite… what do I care about stoker" actually
      resolves to. Appendix has the crew one-liners.
3. **S2 — a face for the Mag/Cloud layer** so the Crate reads as collapsible per-Pier
    magazines ("open one at a time per Pier"), not a flat capped chip-pile.
4. **S3 — make heist a real action.** The engine is built and green; there is *no live
    caller*. This is the biggest gap and the one with the clearest "I don't see how to
     heist" behind it. Needs a live driver + a Book.

S5 (roster page) and S6 (legacy Dexie migrator) are lower priority — S6 degrades
 gracefully already.

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
- **Posed Heist** (`crew:'Heist'`, `Ghost/Story/Sounditron.g:411`) — a fabricated demo
   nugget, inert (no button, see S3).

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
   (primer above). But Storui mounts on every glass-stall (`BigSoundland.svelte:255`),
    and the Stoker + posed Heist leak into the clean glass.
- **Gap:** (a) a `humdinger` (role set `BigSoundland.svelte:46`) should never mount
   `run_uis`/Storui — it's a listener, not a test node; (b) Stoker & posed Heist should
    sit in `system`, not a resident crew; (c) the Tuner show/hide chrome
     (`Cyto.svelte:771-779`) and the raw Book name in the header (`BigSoundland.svelte:169`)
      are developer chrome a listener doesn't need.
- **The move (wire-side, tiny):**
  - `Ghost/M/Radio.g:621` — Stoker `crew:'Radio'` → `crew:'system'` (or gate the face on
     a non-humdinger role). Hides the telemetry face from the clean glass; snap unchanged
      *except* the crew value, so Sounditron needs a re-record (it's the resident probe —
       do this with you watching, not while you're out).
  - `Ghost/Story/Sounditron.g:411` — posed Heist `crew` → `system` (or stop seating it
     entirely once S3 lands a real one).
  - `BigSoundland.svelte:255` — guard the `run_uis`/Storui mount on `!humdinger`.
- **Risk:** the crew edits change the Sounditron snap → re-record on `★claude`, green×2.
   **Do not do this while you're using the live glass** (it churns your view). Diff in
    appendix A.

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
- **Gap — the decisive one:** an exhaustive grep shows the **only callers** of
   `Heist_wish/job/beat/land/...` are in Books (`Ghost/Story/Heistation.g`). **No live
    code mints a real `%Heist` or drives the pull.** Contrast live-share
     (`Swarm_share_up`, `Ghost/S/Swarm.g:1378`) which *is* auto-armed at
      `InvitePanel.svelte:53-58` — but that's stream/browse (friends listen via
       `RiffleFace` + `Radio_dial_pool`, `Radio.g:566`), **not** copy-into-my-Crate.
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
    (deleted when it's my own stock) — `Ghost/M/Radio.g:337-343`. Carried across the
     lineup drop (`:465-468`), and `%Card.by` is the friend crate's pub (`:560`). The
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

---

## Wire-side vs display-side (who does what, so I don't stray into the Vyto zone)

| Seam | Kind | Safe for me (wire/`.g`/Book) | Yours / Vyto glass (display face) |
|---|---|---|---|
| S1 declutter | mixed | crew one-liners in `Radio.g`/`Sounditron.g`, `!humdinger` mount guard | — |
| S2 Mag face | display | (data already there) | new `MagFace`/`CloudFace` |
| S3 live heist | wire | `Heist_wish` trigger + `Heist_beat` driver + Book | wiring the button state in `HeistFace` |
| S4 provenance | display | (data already there) | `RadioFace` reads `sc.by` |
| S5 roster | display | — | contacts face |
| S6 migrator | wire | rung-2 Dexie→`%Idzeug` migrator + Book | — |

---

## Appendix A — S1 declutter, ready to apply (do with the glass in front of you)

Stop the Stoker telemetry leaking into the clean glass — `Ghost/M/Radio.g:621`:
```
-  crew: 'Radio',
+  crew: 'system',   // provisioning telemetry — tuck it; a listener reveals it via the Tuner
```
Move the posed Heist out of the resident crew — `Ghost/Story/Sounditron.g:411`:
```
-  crew: 'Heist',
+  crew: 'system',   // demo pose, inert until S3 lands a real heist; keep it off the clean glass
```
Never mount Storui for a listener — `src/lib/V/BigSoundland.svelte` (the `run_uis` block ~`:255`):
```
   {#each run_uis as ru}
+    {#if !humdinger}
       ...the diag-tagged UI...
+    {/if}
   {/each}
```
Both `.g` edits change the Sounditron snap (the `crew` value) → re-record on `★claude`
 (49dee91d) and converge green×2. **Not while you're using the live glass.**

## Appendix B — S4 now-playing provenance, ready to apply (display-only)

Verified against the live `src/lib/O/ui/RadioFace.svelte` (124 lines).

**1.** Add `by` to the face `return {...}` (the block ends at `:42` with `stock,`):
```
             note:   sc.note as string | undefined,
+            by:     sc.by as string | undefined,   // source prepub Radio_open stamped (Radio.g:337-343)
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
+            {#if face.by}<div class="rf-from">· from {who(face.by)}</div>{/if}
```
`.rf-from` can reuse `.rf-note`'s styling (small, dim). `sc.by` is a *prepub*; `who()`
 degrades to `pub.slice(0,8)` when no `%Pier` matches (a non-friend source), so it's always
  renderable. Note `radio.sc.by` is *deleted* when the track is your own stock
   (`Radio.g:342`), so the tag simply won't render for your own music — correct.
