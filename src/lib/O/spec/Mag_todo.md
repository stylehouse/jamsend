# Mag — the audio-discovery protocol (working doc)

**Status: DESIGN / todo.** The lower half (§1 on) is written to read as spec; it is not blessed
 spec yet — the human preens, then promotes to `Mag_spec.md`. The upper half is the arc and the
  next move. This doc SUPERSEDES the old §2.4 "stock stays flat, Mags only refer" ruling — see §1.

---

## 0. What to get on with next

The bet, in one breath: **a Mag is the main experience.** You connect to a Pier and their
 collection EXPLODES onto the scene as Mags — bounded, curated, playing — and audio starts within a
  couple of chunks. Not an index you scroll; a set of living rooms that arrive already warm. The
   whole thing is an *optimised-for-audio-discovery web protocol*, and the Mag is its packet, its
    page, and its playhead all at once.

The systems this needs have been getting **dialled in by the Story Books** — one at a time, each
 Book proving a seam the protocol leans on. What is already proven and load-bearing:

- **Per-friend mirror keying** (SwarmShare, 2026-07-19): what I hold OF a friend lands under
   `%MusuThem,pub:<them>` — the per-friend crate, not a merged pile. The Mag layer hangs off THIS.
- **%Suggest store-and-forward** (SwarmShare): a referring pointer that survives the friend being
   offline and drains on their rebirth greeting. A Mag is the same shape at collection scale.
   RULING (2026-07-19): the `%Suggest` MAINKEY retires once Mags cross the wire — a suggestion is a
    one-card Mag `%from` the friend carrying a note. What survives is the DELIVERY PATTERN it proved
     (pier-stash durable, re-offered on every rebirth greeting until the far side confirms `got`):
      that pattern BECOMES Mag delivery, not a parallel particle family beside it.
- **The reconnect-epoch spine** (PereReborn): a reborn peer's stream heals from either side. A Mag
   stream must survive the same reload — the pull resumes, it does not restart.
- **The no-enumeration meander** (`Crate_nav_meander`): 200k-track-safe wander, `prandle`-seeded.
   The shuffle generator IS this. (§7)
- **The Repli husk/page split** (`Repli_offer` husk-first, `Repli_want_next` the pull, `%parked_want`
   the will-to-have): Mags cross the wire on exactly this machinery. (§4)
- **The culture-trace draws** (`Stoker_mag_draw` → `%Mag:'Musica' > %Cloud,randomic:'digN' > %Card`):
   the SEED of the Mag idea already exists — today ephemeral (keep-8, GC). Realitifying = promoting
    it from a passive trace to the durable, navigable, cross-wire primitive below.

**Near candidates (pick one to pull first):**
1. **The model migration** — move the radiostock in-tree shape from flat `stock/%Record` to
    `%Mag:shuffle/…/%Record` (§1). Smallest change with the biggest downstream: it gives the crush
     real structure to fold (kills the Vtuffing misrepresentation) and gives show|hide real limbs.
    **BUILT 2026-07-19.** The mint moved inside `Ra_record_from` (the one funnel build+resurrect
     share): a new holding lands in the open page of the shelf's `%Mag:shuffle > %Cloud,page:N`
      (6 a page, `Ra_page_size`). Every scanning reader rides the shape-agnostic census
       (`Ra_recs`/`Ra_rec_find` — flat + paged both) so Book scenes and mirrors that still lay flat
        keep working; no data migrator was needed (the in-tree stock rebuilds off disk each
         sitting). Sworn + declared on MusuBuddy: *the stock pages under the shuffle mag — every
          record stands in a bounded cloud page never flat on the shelf.* Re-recorded green ×2:
           MusuBuddy, MusuRaStream, MusuRaChase, MusuOgg, MusuReap; neutrality held (fixtures
            unmoved) on MusuReplica, SwarmShare, MusuHeist, MusuFreeze, MusuDoor, MusuCursor.
    OPEN RULING surfaced by the cut: the OTHER holding mints still lay flat deliberately — the
     heist census import, the heist cp-landing card, and the Jam keeper (`kept`). A landed heist is
      an ACTIVATED product (§6b), i.e. curation — its Mag home should come from the Heist's own
       naming (a landing Mag), NOT the shuffle. Wants its own ruling before those mints page.
2. **The wire shape** — a Mag as the Repli unit (§4): offer a Mag husk, pull its warm-start chunks,
    autostart. Closest to what is already loaded; a Book (`MusuMag`?) proves it end to end.
    **BUILT + PROVEN 2026-07-20.** One offer verb (`Ra_offer_stock`) stamps `repli_loc:['Cloud','page']`
     on each paged cloud (so pages upsert by page, not collapse onto the first) and offers the Mag as a
      husk; a warm primer (`Ra_mag_warm`) wants offset 0 of the first two records and turns the mirror
       Mag `warm` the moment record zero holds its opening page; a stage stamp (`Ra_stage`, gated to
        `Ra_mag_homed`) reads the pipeline position onto the record so flat scenes/heist quarantines
         never learn the key; paged-aware wire delete + `repli_skip` keep device-local furniture off the
          wire. `MusuMag` proves it end to end — green ×2, **four sworn + declared**: *the mag crosses as
           one husk*, *the warm start pulls the opening page of the first two records*, *a starved track
            wears its stage on the particle* (deep wants park at the caster), *the pipeline reads back
             end to end* (preview page pulled → decoded to real PCM).
    ~~FINDING (the twin-record split)~~ **RESOLVED 2026-07-20 — one true record (the human ruled "do B").**
     A mirrored track used to land as TWO `%Record`s under one id: the paged head (metadata + `stage`, no
      bytes) and a flat way-station holder (chunks, no metadata) — because the husk offer ships full
       `Mag>Cloud>Record` ancestry while the chunk serves ship a lean `d:0` Record fragment, and
        `Repli_merge`'s direct-child upsert could not see the paged head, so it minted a flat twin.
         **The cut**: `Repli_merge` now locates a missed `%Record` line through the census (`Ra_rec_find`
          — the exact mirror of the delete path's paged-aware find) before minting, and a census-found
           head keeps its true `c.up` (re-rooting would tear it out of its page). Chunks land under the
            head; the mirror wears the origin's own shape. Fallout, all landed: `Ra_mag_warm` reads the
             head directly; `MusuMag_deep` returns the ONE record; the head's `stage` now honestly reads
              SUPPLY (previewed/whole/decoded live in MusuMag's snaps, impossible before); `Jam_grab`
               skips the `stage` key (pipeline furniture never rides a keeper into `%Kept`).
    THE TWIN HAD DRAWN BLOOD: the split had silently frozen MusuBuddy's pull leg (the census flip to the
     total-less holder), and the 2026-07-20 sweep re-record enshrined `hear_fail:nothing pulled` +
      `jam_fail:nothing heard` in its fixtures — only one sworn claim gated the Book, so it stayed green.
       Fixed by the cut; MusuBuddy re-recorded green ×2 with the whole back half alive (pulled 38 chunks
        with park/release counts, heard at target LUFS, Spin/Like/Grab ledger, whole keeper) and TWO NEW
         sworn + declared claims binding it forever: *the browsed card pulled its record whole and
          byte-faithful…* (step 10) and *the jam ledger reads spin like grab in order…* (step 11).
    NEUTRALITY under the census landing: flat shelves hold no Mag, so the fallback never fires there —
     MusuReplica green on untouched fixtures (caveats = the known heartbeat-round drift only); no other
      Book's fixtures ever held a naked holder row. MusuMag green ×2. Earlier sweep (pre-cut, 2026-07-20,
       run singly): MusuReplica / SwarmShare / MusuFreeze / MusuSoft / MusuBay / MusuOgg green; MusuBounce
        accepted per the human (known-flaky bouncechunk body_hashes).
3. **The limbic show|hide** (§6) — retire the flat `%Tuner` mute-index for a crawlable topic-limb
    graph with attention-budget mutex. Render-side; supersedes the currently-broken `Tuner_toggle`.
    **PARKED 2026-07-19**: Radio's display side is mid-refactor (Voro+Cyto → **Vyto**, the human's
     cut) — no display-side work until it lands. The wire shape (2) proceeds data-side only, and
      explode-on-connect's PRESENTATION leg (§6) waits here too.

The docs are a bit senile — where this contradicts `Radio_todo.md`, this wins for the Mag layer.

---

## 0b. Residue — landing-Mag loose ends (verify + fix, 2026-07-21)

Small cleanups the landing-Mag cut left behind (they lived only in a task-tracker + memory before
 now). Each needs a re-record of the Book it touches; the heist-family ones pin to runner **49dee91d**.

### Origin's stock should page, not lie flat · `origin-lib-pages` — **DONE 2026-07-21**
All six flat `origin_lib`/`lib` Record mints across the Heistation scenarios now go through
 **`Ra_rec_home`**, so Origin's tape lands under `%Mag:shuffle > %Cloud,page:N` like every real stock
  shelf. The three fold-only Books (MusuVend `MusuVend_meander`, MusuDoor `MusuDoor_stock`, MusuRename
   `MusuRename_publish`) needed only the mint swap. The three **goner** Books (MusuRecast, MusuFreeze,
    MusuStanding) also paired a flat `origin_lib.rm({Record:1,id})` that a paged record is invisible to —
     so a new removal door **`Ra_rec_drop(shelf, id)`** (`Ra.g`, right after `Ra_rec_home`) finds the
      holding wherever it sits and detaches it from its actual parent; all six `rm` sites route through
       it. Downstream was already shape-agnostic (`Musica_fold`/`Musica_recast_offer`/`Musica_stand`
        all read `Ra_recs`), so the goner receipts (`gone_recs`/`gone_cl`) and every `%see` claim held —
         pure fixture-move. Re-recorded green ×2 on **49dee91d**: MusuVend, MusuDoor, MusuRename,
          MusuRecast, MusuFreeze, MusuStanding. (Commits `157f9d02` `b9a85bf9` `979e870c` `580c6a1c`.)

### A digging radio over-counts against a paged twin · `radio-stood-paged-blind` — **DONE 2026-07-21**
`Radio.g:629`'s flat `!shelf.oa({ Record: 1, id })` now reads the shape-agnostic
 `!this.Ra_rec_find(shelf, { Record: 1, id })`, so a record already sitting PAGED is seen and
  `st.sc.stood` no longer over-counts on a re-resurrection. `Ra_record_from` already deduped through
   `Ra_rec_home`, so nothing could ever DUPLICATE — the bug was purely the count. Neutral (green:
    MusuRaStream, MusuResume, MusuRaChase — no `stood` moved). Commit `2f991781`.

### A published Card stamps maybe-undefined artist/title · `heist-card-guard-stamps` — **DONE 2026-07-21**
`Musica_fold`'s card mint (`Heist.g:949`) now bare-mints `{ Card: 1, id }` and `if`-guards artist/title
 like its path/album/body_hash siblings, so a holding with no artist/title never brands the card line
  `undef`. Neutral (every test pool sets both — green: MusuVend, MusuRecast; no gated fixture moved).
   Commit `7e4bddc9`.

### `Ra_recs` is fixed-depth, and Mags may go deeper — your call · `ra-recs-recurse-question`
`Ra_recs` (`Ra.g:649`) and `Ra_rec_find` (`:661`) hard-code exactly three shapes — flat
 `shelf.o({Record:1})`, `Mag.o({Record:1})`, and `Mag > Cloud.o({Record:1})` — they do **not** recurse.
  That matches today's built model (`%Mag:shuffle > %Cloud,page:N`, one Cloud layer). But if a Mag is
   meant to nest arbitrarily deep (Cloud-in-Cloud, Mag-in-Mag), both silently drop the deeper rows.
    DECIDE: is the Mag model fixed at that one depth, or do these two become a recursive walk over
     Mag/Cloud? (the human flagged this 2026-07-21.)

---

## 1. The model — stock IS `%Mag**/%Record`

A holding does not float flat under a shelf; it lives under a **Mag**. The tree branches:

```
%MusuSelf,pub:<me>
  %Mag:shuffle,day:2026-07-19,page:1        ← the default holding — most of the radiostock is here
    %Record,id:… > %Preview,seq:0..15 > %Stream,seq:…
    %Record,id:… …                          (up to a page's worth, ~6, §5)
  %Mag:Faves                                ← durable curation
    %Record,id:… (or a %Card referring one held elsewhere)
  %Mag:Lineup                               ← the rolling programme the radio plays through
```

A **`%Mag`** is a container with a KIND (`shuffle | lineup | faves | culture`) and a coordinate
 (`day`/`page` for shuffle pages; a name for durable ones). Records branch under it. A Mag MAY hold
  a `%Record` outright (a holding) OR a `%Card,id:X` referring to one held under another Mag — the
   identity-per-shelf law (CLAUDE.md): the thing exists ONCE as its `%Record`; every other mention
    is a referring `%Card` wearing its own mainkey and carrying the join `id`. So `Faves` refers into
     `shuffle` by id; it does not duplicate the holding.

This revises the flat-stock ruling: stock branches now, because the branch IS the curation. The flat
 shelf was a way-station; the Mag is the home. **Landed 2026-07-19 (§0.1):** the real shape is
  `stock/ > %Mag:shuffle > %Cloud,page:N > %Record` — the Mag lives under the stock shelf (the
   shelf keeps its role as the holdings door; `Ra_home_self` callers never moved), pages are
    1-based `%Cloud,page` children of the ONE shuffle Mag, and `Ra_pub_of` climbs `c.up` to the
     shelf that wears `pub`. Friend mirrors stay FLAT until the wire cut carries Mag structure.

**Naming + where a Mag stores (ruled 2026-07-19).** A Mag takes after a Waft: `%Mag:<unique-name>` —
 the mainkey value IS the name, as `%Waft:<path>` does it — with pages riding INSIDE as children
  (`/1`, `/2`… the shuffle's `day`/`page` coordinate), never as sibling top-level Mags. Durable Mags
   STORE AS BERTHED WAFTS — the Berth is already exactly this seam (`Berth_dir`:
    `<root>/.jamsend/berth/<prepub>/<name>/toc.snap`, the wormhole dir-with-a-toc.snap shape homed
     under an identity, documents travelling WITH the music; `Musica_publish` and the Faves door
      berth this way today). Duration (§3) decides berthing: `faves`|authored Mags berth; `shuffle`
       pages and `culture` draws are tree-only and die by GC. Friend Mags NEVER berth (§6b).

## 2. The will above the Mag

A Mag does not appear from nowhere — a **will** produces it. Two wills, both particles:

- **will-to-have** — a `%want` (the pull already has this: `%parked_want`, `Repli_want_next`). "I
   want more like this / I want that friend's collection / I want the next shuffle page."
- **will-to-create** — a `%req` that goes and MAKES a Mag (wanders the share, draws a page, husk-casts
   a friend's crate). The will may live INSIDE the req that serves it — a `%req:mag,of:shuffle` whose
    do_fn wanders and mints `%Mag:shuffle/…/pN`, holding the want as its own arming state.

This is the belief-loop shape: a want holds, a req serves, a Mag lands, the want is satisfied (or
 re-arms for the next page). The Mag is the settled output of a will — legible, so a group can see
  what was wanted and what arrived.

## 3. The cursor and the duration

Every Mag carries a **cursor** — a playhead: which Card is current (playing / selected / next). This
 is the Lang analogy made durational and plural: a Waft's cursor marks the current What; a Mag's
  cursor marks the current track, MANY of them coexist (one per open Mag), and they persist.

Mag kinds share the cursor; they differ in **duration** (lifespan):

| kind | duration | cursor behaviour |
|---|---|---|
| `shuffle/…/pN` | ephemeral — consumed, the next page supersedes it | advances forward; page exhausts → mint p(N+1) |
| `lineup` | rolling — a sliding window ahead of the listened-to cursor | the radio's playhead; consume the head, top up the tail |
| `faves` | durable — kept forever | free selection; no auto-advance |
| `culture` | GC'd — keep the last 8 draws | read-only trace; no live cursor |

**§3b. Pointing across Mags (ruled 2026-07-19).** A Card may point INTO another Mag — "check this
 out, it sits in her Faves" — by wearing a `%Dogear` child: the cursor spine opens at the target Mag
  (`{Mag:'Faves'} → … → {Card,id:X}`) and resolves from the crate its provenance names (§6b: `%from`
   picks the crate, the cursor walks from there — O(depth), zero search). All scalar, so the pointer
    snaps, berths and replicates like anything (MusuResume proved the round-trip); C2's `%Renamed`
     heal follows the target across a reorganise through the same pipe the content came down; and a
      clean fail IS the husk texture (§4.4) — a pointer into bytes you cannot reach reads honestly as
       a promise. The bare `id` join stays the 1:1 identity (the Card IS the join); the Dogear is for
        POSITION — the thing as-it-sits in that other Mag. The one NEW convention the machinery needs
         is the root rule (resolve from the crate `%from` names); the cursor itself is proven.

## 4. Mags do Repli — the wire

The Mag is the **replication unit** — and (ruled 2026-07-19) the **default sharability**: sharing
 anything IS sharing a Mag, down to the one-card Mag as the atom (the retired `%Suggest`, §0). The
  Heist HEISTS; the Mag POINTS — "check this out" — and the pointed-at thing may sit inside another
   Mag (§3b). It crosses the wire on the existing Repli machinery, husk-first:

1. **Offer** — a `%Mag` husk crosses (`Repli_offer`-shaped): the Mag head + its `%Card`/`%Record`
    heads + each Record's `%Preview,seq` metadata, NO chunk bytes. A friend's whole shelf-of-Mags is
     a cheap catalog however much stock stands behind it.
2. **Context, when it exists** — a Mag/What/* is Records; anything ELSE found there exists to be
    GROUPED TO a Record — that is what non-Record content in a Mag is FOR (ruled 2026-07-19; no
     speculative inventory of what else might appear). A bare Record carries only its head. Some Mags
      have structure to present; some are flat sets. Do not force structure that is not there — and
       the Cursoring stays flexible + UNCONFUSIBLE over both shapes (trees AND big flat lists —
        proven in the MusuCursor Book: the C1–C3 tree scenes plus the flat/crowd scene). UI:Waft
         renders a big Mag BOUNDED: deepen chips at the edges (`/*38`, the [zS]tuffing idiom), never
          an unbounded list.
3. **Pull** — bytes are lazy: `Repli_want_next` fetches chunks on demand, `%parked_want` survives a
    reload (PereReborn's reconnect-epoch: the pull RESUMES, never restarts). No buffers ride the
     offer — but the client OPENS by asking for the first two chunks of the first two Records (the
      §5 warm start) and paces the rest off the playing head. **Starvation legibility par importo**:
       a starved track must SHOW where in its pipeline it is stuck — want parked | offered | pulling
        | chunks landing | decoded | scheduled — a legible stage on the particle, never a bare
         spinner.
4. **The unknowable** — a `%Card` that resolves to a held `%Record` is *knowable*; one that refers to
    bytes not pulled is a *husk* — a promise. The crate view must render the two textures distinctly
     (§6): honesty about how much of a room you can actually reach is a feature, not a gap.

## 5. The shuffle generator — warm-start pages

`%Mag:shuffle` is the default holding AND the discovery engine. One draw:

1. **Wander** — `Crate_nav_meander` (branch-weighted, `prandle`-seeded, no-enumeration) surfaces a
    SET of ~6 Records. Never a scan (§7).
2. **Warm-start** — eagerly fetch the first two chunks (`%Preview,seq:0..1`) of the first two Records
    of the page. Enough to begin.
3. **AUTO-START** — playback begins on Record 0 the moment its warm chunks land; Record 1 is queued;
    the `%Stream` continuation and the remaining page fetch behind the playing head.
4. **Advance** — cursor moves through the six; nearing the tail arms the will-to-create the next page
    (`p(N+1)`), so the shuffle never stalls at a page boundary.

The page size (6) and warm depth (2 records × 2 chunks) are the tuning knobs — a listening ramp, not
 a download-everything. This is the whole "you connect and it just plays" experience.

## 6. Explode-on-connect — Mag as the main experience, and the limbic show|hide

**The headline:** connecting to a Pier EXPLODES their Mags onto the scene. Their `%MusuThem,pub:<them>`
 crate is a shelf-of-Mags; the offer husks them all cheaply; the scene blooms with their curated
  rooms; a shuffle over their collection autostarts. The friend arrives as their *taste*, immediately
   audible — not a directory you then go spelunking. Ruled 2026-07-19: explode-on-connect is the
    superpostmodernist `<h1>` — if the page is a tale of what happened, this is its header. In
     practice it kicks off catching up with their collection, and it PRESENTS as a
      switch-to-this-channel affordance beside the Radio UI — an arrival, not a takeover.

**show|hide becomes navigation, not a checklist.** The current `%Tuner:'glass'` + `cyto_crew` +
 `Tuner_toggle(t.c.mute[crew])` is a flat mute-index and it is currently broken. Retire it for a
  **topic-limb graph** — and the topic tree is NOT only music (ruled 2026-07-19): it is all the
   parts of the system in play, each subsystem|perception with its particular particles and its
    particular particle pump. An ATTENTION-SHARING DOMAIN, Housing-like: a dilute top-level view
     while things get ready, then the usual state is FOCUS — one perception held close, the rest
      folded. Within the looking-at-lots-of-music perception the limbs derive from Record metadata
       + the culture trace (terms, since they confused: a *culture-trace draw* = a `Stoker_mag_draw`
        `%Cloud`, the trail of what a dig landed; *authored* = a human-made list; *blend* =
         machine-proposed limbs the human prunes|renames). The idiom: an octopus holding a bunch of
          toys — it holds one up to you for a close look, and when you tap its head it folds the arm
           away again. Rooms toggle on|off independently, BUT **mutex on space**: a space-hungry room
            yields when a heavier one opens (an attention budget — LRU-ish, not the hard [s]-style
             total mutex), and the mutex is an ATTENTION MECHANISM with a sense of navigation — view
              states the Voro grasps coherently enough to REWIND (the moments|Yore spool is the rail)
               and to PUSH BACK on: proposing a view-state change, not only obeying toggles. This is
                the "make space" ask realised as a living layout instead of a list.

**Vtuffing / the crush reads Mags.** The crush misrepresents `%MusuThem/**` today because a flat pile
 has no structure to fold and `Voro_crushable|swarmable` judge nodes in isolation. Fold the MAGS
  (real, curated groupings) and the misrepresentation dissolves — the sub-cell stuffing renders a
   Mag's Cards, honouring husk (unknowable) vs held (knowable). Same move, both problems.

## 6b. Provenance + privacy — a Mag `%from` its creator (ruled 2026-07-19)

Every Mag wears `%from:<prepub>`: curation is authored and the author rides with it. Which makes a
 friend's Mags PERSONAL DATA — their lists of tracks, their taste, sitting on my disk. The rulings:

- **Friend Mags never berth.** They arrive as husks, live in the runtime tree while the awareness
   lasts (a high-security time), and are SHAVED OFF rather than hoarded. Reconnect re-explodes them
    cheaply (§4.1), so persisting them buys nothing but liability.
- **What persists is the ACTIVATED product of the awareness**: the `%Heist` — its set of track
   titles, the folder structure it wants to save into, and that Heist's state — plus whatever bytes
    a grant actually let me pull. Acting IS the consent moment; the Heist is its durable record.
- **Listening history is the same class of data** (§8): what I heard OF whom. Keep it OBLIQUE —
   bare ids, no titles|paths — enough to never repeat a track, nothing worth stealing.
- **Tombstones are untouchable**: `%UnGrant` decision-facts never drop (the revocation law) —
   privacy shaving removes CONTENT, never decisions.
- **Provenance is a LOOKUP, never a search (ruled 2026-07-19: owned but not persisted).** Whose a
   thing is must be readable ON it immediately — the Mag's `%from` + the per-friend crate keying
    (`%MusuThem,pub:<them>`, the SwarmShare-proven mirror law) — or every "where did this come from"
     becomes an every-Pier search query. Origin picks the crate; the cursor picks the position;
      resolution is a walk.
- <posited> The same ephemerality should reach the whole `%MusuThem` mirror (the husk catalog too) —
   shaving Mags while the full catalog mirror persists beside them would be theatre. Session matter,
    re-offered on connect.

## 7. Scale discipline — 200k tracks, never a jam

The invariant: **no path materialises the whole collection.**

- **Generation** wanders, never enumerates — `Crate_nav_meander` is 200k-safe by construction
   (hop-by-hop `dir_at`/`expand`, one directory per hop, `prandle`-seeded, GIVE_UP-bounded). The
    shuffle Mag inherits this for free.
- **The filesystem explorer** stays lazy — `dir_at`-at-a-time, virtualised, expands on demand. A
   browse view that tries to render 200k rows jams; a Mag-shaped view never asks to.
- **The working set is bounded by Mags** — you hold a page (~6) plus what is pinned; the rest is
   husks (promises) until a will pulls them. Memory is O(open Mags), not O(collection).

## 8. Open questions → rulings (the human, 2026-07-19)

- **The topic tree's source** — RULED: machine proposes, human prunes|renames, and the tree spans
   the whole SYSTEM, not just music (§6 — the attention-sharing domain).
- **Friend-Mag ownership** — still open in the small (theirs cross vs derived locally over the
   mirror), but bounded by §6b: however they arrive, they never persist.
- **Migration order** — RULED "sure, whatever": the agent owns migration TESTING now (which Books,
   what re-record order, keeping the sweep green) — human eyes only where a diff genuinely needs a
    mind.
- **The mutex policy** — RULED in kind: an attention mechanism with a SENSE OF NAVIGATION — view
   states the Voro can rewind (the moments|Yore spool) and push back on (§6). The budget metric
    (cell count? viewport area? an Attractor KNOB?) stays open in the small.
- **Cursor persistence** — RULED: ABSOLUTELY durable. Keep OBLIQUE track (bare ids, §6b) of Records
   heard and then of whole Mags exhausted, so the shuffle|dial NEVER hands you a duplicate across
    sessions. The `%Dogear` C3 berth is the seam; `radio.c.heard` is the runtime germ; the
     graduation is heard-Record ids → exhausted-Mag names.

---

*This is a `_todo`: the arc and the open threads are meant to move. When the shape holds and the
 human has preened §1–§7, promote to `Mag_spec.md` and retire the todo half.*
