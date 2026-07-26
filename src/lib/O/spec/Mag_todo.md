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

### `Ra_recs`/`Ra_rec_find` now recurse over `Mag**` · `ra-recs-recurse-question` — **RULED + BUILT 2026-07-26**
The human ruled it: **`Mag**` recurses.** "we'll just look for Record, figure out what the rest of the
 Mag is to be later." The census reads (`Ra_recs`, `Ra_rec_find`, and the `Ra_mag_warm` row-collect) now
  walk a Mag's whole subtree — `shelf|Record` first (the flat/way-station leg), then `Mag**/Record` at
   any depth: `Mag/Record`, `Mag/Cloud/Record`, and Cloud-in-Cloud / Mag-in-Mag when they come. A shared
    recursive engine (`Ra_recs_deep` / `Ra_rec_find_deep`, `Ra.g`) collects **holdings-first at each
     level** (a container's direct `%Record` rows before any nested container's) so the census ORDER is
      byte-identical to the old fixed three-level walk on every shape that exists today — pure neutrality,
       no fixture should move — while deeper shapes are now found instead of silently dropped. A `%Record`
        is a leaf (its children are chunk particles, never Records) so the walk prunes at it. Notation
         corrected throughout to `shelf|Record` and `Mag/Cloud/Record` (the human's, over the old
          `.o({Record:1})` prose). LocalGen CHECK=1 clean; runner-verify owed (spine ghost — the
           neutrality sweep is the gate: every Mag-reading Book must stay green with fixtures unmoved).
    ONE remaining fixed-depth spot, noted in-code: `Ra_offer_stock`'s `repli_loc = Cloud,page` wire-stamp
     is still depth-1 (only a Mag's own `%Cloud` pages). The husk itself crosses at any depth (`Repli_offer`
      walks the subtree); only the page-upsert key is depth-1, and nested pages don't exist yet, so nothing
       is stranded. Generalise that stamp WITH the deeper Mag shape when it is designed (see §9).

---

## 9. A Mag is writeable — tagging + share-as-Invite (ruled 2026-07-26, design)

The recurse ruling came paired with two forward directions. Neither is built; both are the shape the
 "figure out what the rest of the Mag is later" answer will grow into. Recorded here so the next pull
  starts from the human's words, not a guess.

- **A Mag can be WRITTEN — lightly.** "some kind of writing must be possible… `%note`? probably not too
   much." The steer is AGAINST a heavy authored-document Mag. The concrete germ the human reached for:
    **users go around tagging music, and a tag FAVOURS it slightly** — tags are a light, additive signal
     that nudges the shuffle/dial weighting (the `prandle` meander already has the branch-weight seam,
      §5/§7), not a rigid folder taxonomy. So Mag-writing ≈ *tags on Records* (and maybe a thin Mag-level
       note), feeding the culture-trace weighting — NOT a rich-text limb. Open in the small: does a tag
        ride the `%Record` (`%Tag,term:…` child) or a Mag-level index; how "slightly" the favour weights.
- **Sharing a Mag IS a kind of Invite (§4 default-sharability made concrete).** "when you share it
   specifically (we want this as a type of Invite as well) that cataloguing should be visible via the Mag
    medium." Two things fuse: the [[invite-front-door]] flow (QR/`?I=` scan-to-join, sealed prepub) and
     Mag delivery (§4 husk-first). **Sharing a Mag = minting an Invite whose payload is that Mag** — the
      recipient joins AND the shared Mag's cataloguing (its Records, tags, structure) explodes onto their
       scene through the Mag medium (§6 explode-on-connect), husk-first so it's cheap. The Invite is the
        will, the Mag is what arrives. This supersedes ad-hoc "send a link"; a shared collection travels
         as a first-class, catalogued, joinable thing. Next move: an Invite variant carrying `%Mag,of:…`
          (or the Mag berthed under the invite), proven by a Book crossing it two-tab.

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

## 10. The heisted body carries its quality — `%Original | %Lossy` (CODE APPLIED + canary-verified 2026-07-26)

The human floated it, then blessed it ("pat and say good"): **instead of `%Record/%Body` for the whole files
 we download, `%Record/%Original|%Lossy`** — the whole-file chunk particle's mainkey encodes the source
  quality, so a holding wears on its face whether it's a lossless master or a lossy copy. Scope (the human
   tightened it): this is JUST the downloaded/compressed WHOLE file — NOT multi-Pier sourcing of the "same"
    track. Then the format-upgrade dedup (Radio_todo "same track better format") becomes tractable — a
     `%Lossy` holding meeting an `%Original` offer is a legible upgrade — and a Mag can prefer the master.

**`%Original` is NOT a new name — it REALISES Orig.g's reserved master.** `Orig.g` header: "%Original master
 (rung 3 — the flac source that encodes DOWN to any grade) is later work" — no code minted it yet. A heisted
  FLAC *is* that master, so minting the lossless body as `%Original` fills the reserved concept; a heisted
   MP3 is `%Lossy` (never a master). Orig.g's export reads `%Preview|%Stream` (not `%Body`), so **Orig.g's
    code is untouched** by the rename. The names align by design — a good sign the model is coherent.

**CODE STATUS: applied (uncommitted) + LocalGen-clean + live-canary-verified — fixture re-record OWED.**
- The signal: `md.format.lossless` via `Crate_meta_from_tags` (Crate.g — added, with a `Crate_ext_lossless`
   allowlist fallback). Additive (unstamped) → neutral.
- The mint: Heist.g:122 routes through `Heist_body_new(rec, meta.lossless, s)`; reads through `Heist_body_at`
   (offer manifest) and `Heist_has_body` (the Heistation husk-probes). Transport unchanged (Repli keys chunks
    by binary VALUE + seq, mainkey-blind) — grep-confirmed zero other `{Body:1}` readers.
- **CANARY on the live runner (MusuHeist):** ran RED with `error:null` on every step (pure snap-diff, no
   exception), and the diff is EXACTLY `Body,seq:N,cid:X → Original,seq:N,cid:X` — **same cid, same seq, same
    buf** (cid = sha256 of the bytes, unchanged by a type-tag rename). Surgical. The WAV test tracks are
     lossless → all `%Original` (so `%Lossy` is UNPROVEN by fixtures — see below).

**Fixture re-record STILL OWED — blocked on a clean runner.** `%Body` snaps in ~1602 lines across **MusuBay,
 MusuHeist, MusuSoft** (+ **MusuBreach** = security/RaBreach territory, coordinate with that agent). The
  re-record could NOT run tonight: `49dee91d` (★claude) doubles as a live /BigSoundland tab whose **resident
   Sounditron probe bleeds** — it displaced the held MusuHeist and an `accept` grabbed Sounditron instead
    (reverted clean; see [[shared-runner-bleed]]). Needs a DEDICATED, non-BigSoundland, FSA-live runner. The
     accept is then a paste job: run each Book → verify `book`+uid are yours → confirm the diff is only
      `Body→Original`/`Lossy` → `accept` → rerun green.

**RE-RECORDED GREEN 2026-07-26** on dedicated runner `3c5238c6` (guarded book+uid before each accept —
 no bleed): **MusuHeist, MusuBay, MusuSoft** all green×1, `Body→Original` (WAV sources = lossless). OWED:
  **MusuBreach** (RaBreach/security territory — coordinate with that agent before moving its fixtures).

**TWO follow-ups the canary surfaced:**
1. **`%Lossy` is unproven** — every heist test track is WAV (lossless → `%Original`). To exercise the
    `%Lossy` branch WITHOUT a lossy encoder in the repo: build a minimal **Ogg/Opus** source with
     `Orig_ogg_mux` (Opus IS lossy → music-metadata `format.lossless=false` → `%Lossy`), and stamp its
      `OpusTags` (via `Orig_opus_tags`) with artist/title. Heisting it proves BOTH at once: the `%Lossy`
       mainkey AND that a lossy file's tags read back (`Crate_meta_from_tags` → `%Record` artist/title in
        the snap) — the human's "does our %Lossy encoder tag good" answered in the same fixture. Note: the
         SNAP is the proof (mainkey + tags captured mid-run); you do NOT need to leave the file on disk.
          The human's "leave the downloaded file" would only be for manual byte-inspection, and it fights
           `Heist_sweep` (the Book-start sweep of `.jamsend/test-marrauding-of-bookrun` — that IS the
            "cleans even after abort/crash, on next resume" mechanism); to persist it, land OUTSIDE that
             swept namespace.
2. **The `%Lossy` tag-writer gap (the human's "check our %Lossy encoder does tags good").** There is NO lossy
    whole-file encoder today: `Crate_wav_with_tags` writes tags but only for WAV (lossless); `Ra_encode_*`
     (WebCodecs Opus) makes untagged STREAM chunks for playback, not a file. So a `%Lossy` holding is only
      ever a *downloaded* already-lossy source (tags live in the pulled bytes, read back by
       `Crate_meta_from_tags`) — tags are fine there. The concern only bites IF we add a "compress-it-whole
        to save space" path; that encoder MUST write tags (ID3/VorbisComment), and none exists yet.

**The change is SMALL — the transport is already mainkey-blind.** Repli identifies a chunk by its *bytes*,
 never its mainkey: `Repli_is_binary(v)` tests `v instanceof Uint8Array`, `Repli_chunk_at(rec,s)` iterates
  `{seq:…}` across any mainkey, and the husk-skip is `Repli_chunk_bytes(child) != null` (Repli.g). So the
   husk, the pull, the seq-space (`%Preview`/`%Stream` share it), `Radio_map`, `Ra_chunk_map` — **all need
    zero change.** Only the 4 literal `{Body:1}` sites move:

1. **The signal — `md.format.lossless`, NOT the extension.** `Crate_meta_from_tags` (Crate.g:383) already
    `parseBuffer`s the bytes; `md.format.lossless` (and `md.format.codec`) sit right beside the `md.common`
     it reads. Return it: `lossless: !!(md.format && md.format.lossless)` (one line, additive — the return
      isn't snapped). The extension LIES (`.m4a` is ALAC-lossless OR AAC-lossy; `.ogg` is Vorbis OR FLAC),
       so classify off the parsed codec; fall back to an ext allowlist (`wav flac aiff aif alac ape wv tta
        dsf dff`) only when parse gives nothing.
2. **The mint — Heist.g:122.** `ext`/`meta` are in scope (`rec.sc.ext = ext` at :115). Pick the mainkey:
    `let bk = meta.lossless ? 'Original' : 'Lossy'` then `rec.i({ [bk]:1, seq:''+s })` — but stho may not
     take a computed key; use a two-branch `rec.i({ Original:1, … }) / rec.i({ Lossy:1, … })` or a helper
      `Heist_body_new(rec, bk, s)`. A record is ALL one quality, so one decision per record, not per chunk.
3. **The offer manifest — Heist.g:250.** `rec.o({ Body:1, seq })[0]` must read the WHOLE-FILE chunk
    specifically (it shares seq-space with `%Preview`/`%Stream`, so the generic `Repli_chunk_at` could grab
     the wrong one). Add `Heist_body_at(rec,s)` = `rec.o({Original:1,seq:''+s})[0] || rec.o({Lossy:1,seq:''+s})[0]`
      and route :250 through it.
4. **The Book husk-empty probes — Heistation.g:3573, 3916.** `!card.o({ Body:1 }).length` ("no bytes yet =
    unspent husk") → `!card.o({Original:1}).length && !card.o({Lossy:1}).length`, or a shared
     `Heist_has_body(card)` helper. These re-record with their Books anyway.

**Fixture re-record list (attended, runner-pinned 49dee91d):** MusuBay · MusuHeist · MusuSoft — straight
 re-record. **MusuBreach** — this is breach/RaBreach territory; **coordinate with the security agent** (the
  R1 owner) before moving its fixtures, since it may be mid-flight there.

**The paired question — "will it know all the autogen Mags as one cursor?" → YES, and it's BUILT.** The
 heard-memory is ONE shared set (`radio.c.heard`, now **bounded to 100** — §8's runtime germ, `Radio_heard_add`),
  so "have I heard this" is unified across every Mag. Per-Mag *position* is DERIVED, never stored:
   **`Radio_mag_cursor(radio, mag)`** (Radio.g, built 2026-07-26) walks the recursive census (`Ra_recs_deep`,
    §0b `Mag**`) and returns the last of the Mag's records that sits in the heard set — how far through THIS
     Mag you've got. Shape-agnostic, so all the autogen `%Mag:shuffle` pages read through the same one cursor
      logic off the same one heard-memory. The human's ruling stuck: browsing-history store DROPPED; the
       cursor is a pure read that can never rot. Graduation to durable (heard-ids → exhausted-Mag names,
        §8) is still the `%Dogear` berth seam when durable taste earns a home.

---

*This is a `_todo`: the arc and the open threads are meant to move. When the shape holds and the
 human has preened §1–§7, promote to `Mag_spec.md` and retire the todo half.*
