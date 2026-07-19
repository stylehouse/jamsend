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
2. **The wire shape** — a Mag as the Repli unit (§4): offer a Mag husk, pull its warm-start chunks,
    autostart. Closest to what is already loaded; a Book (`MusuMag`?) proves it end to end.
3. **The limbic show|hide** (§6) — retire the flat `%Tuner` mute-index for a crawlable topic-limb
    graph with attention-budget mutex. Render-side; supersedes the currently-broken `Tuner_toggle`.

The docs are a bit senile — where this contradicts `Radio_todo.md`, this wins for the Mag layer.

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
 shelf was a way-station; the Mag is the home.

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

## 4. Mags do Repli — the wire

The Mag is the **replication unit**. It crosses the wire on the existing Repli machinery, husk-first:

1. **Offer** — a `%Mag` husk crosses (`Repli_offer`-shaped): the Mag head + its `%Card`/`%Record`
    heads + each Record's `%Preview,seq` metadata, NO chunk bytes. A friend's whole shelf-of-Mags is
     a cheap catalog however much stock stands behind it.
2. **Context, when it exists** — a Mag presents "whatever is around the Record in the What": if a
    Record sits inside a What (a `%Reco` note, a `%Stream` continuation, a surrounding structure), the
     Mag carries that C** context along. A bare Record carries only its head. Some Mags have structure
      to present; some are flat sets. Do not force structure that is not there.
3. **Pull** — bytes are lazy: `Repli_want_next` fetches chunks on demand, `%parked_want` survives a
    reload (PereReborn's reconnect-epoch: the pull RESUMES, never restarts).
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
   audible — not a directory you then go spelunking.

**show|hide becomes navigation, not a checklist.** The current `%Tuner:'glass'` + `cyto_crew` +
 `Tuner_toggle(t.c.mute[crew])` is a flat mute-index and it is currently broken. Retire it for a
  **topic-limb graph**: the Mags ARE the rooms; the topic tree they hang off (genre/artist/era/mood
   — derived from Record metadata + the culture-trace, human-prunable) is the limbs you crawl.
    Rooms toggle on|off independently, BUT **mutex on space**: a space-hungry room yields when a
     heavier one opens (an attention budget — LRU-ish, not the hard [s]-style total mutex). This is
      the "make space" ask realised as a living layout instead of a list.

**Vtuffing / the crush reads Mags.** The crush misrepresents `%MusuThem/**` today because a flat pile
 has no structure to fold and `Voro_crushable|swarmable` judge nodes in isolation. Fold the MAGS
  (real, curated groupings) and the misrepresentation dissolves — the sub-cell stuffing renders a
   Mag's Cards, honouring husk (unknowable) vs held (knowable). Same move, both problems.

## 7. Scale discipline — 200k tracks, never a jam

The invariant: **no path materialises the whole collection.**

- **Generation** wanders, never enumerates — `Crate_nav_meander` is 200k-safe by construction
   (hop-by-hop `dir_at`/`expand`, one directory per hop, `prandle`-seeded, GIVE_UP-bounded). The
    shuffle Mag inherits this for free.
- **The filesystem explorer** stays lazy — `dir_at`-at-a-time, virtualised, expands on demand. A
   browse view that tries to render 200k rows jams; a Mag-shaped view never asks to.
- **The working set is bounded by Mags** — you hold a page (~6) plus what is pinned; the rest is
   husks (promises) until a will pulls them. Memory is O(open Mags), not O(collection).

## 8. Open questions (for the human to settle)

- **The topic tree's source** — derived from metadata, emergent from culture-trace draws, authored,
   or a blend? (Leaning: machine proposes, human prunes|renames.)
- **Friend-Mag ownership** — do a friend's Mags cross the wire as THEIR curation (richer than the
   ive_got count), or do I derive Mags locally over their mirrored stock? (Leaning: both — theirs
    cross, mine derive-then-optionally-share.)
- **Migration order** — flat `stock/%Record` → `%Mag:shuffle/**/%Record` touches every fixture that
   reads a shelf; which Books re-record, and in what order, to keep the sweep green?
- **The mutex policy** — what makes a room "space-hungry" (cell count? sub-cell depth? a `%want`
   weight?), and what is the budget (viewport area? an Attractor KNOB)?
- **Cursor persistence across reload** — the playhead is live state; does it ride `.c` (lost on
   reload, re-derived) or snap (durable but churny)? Probably `.c` + a durable "last heard" seam.

---

*This is a `_todo`: the arc and the open threads are meant to move. When the shape holds and the
 human has preened §1–§7, promote to `Mag_spec.md` and retire the todo half.*
