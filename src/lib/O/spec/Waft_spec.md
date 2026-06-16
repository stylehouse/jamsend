# Waft spec

---

## Goal

Gain decoration powers before gaining fuzzy-matching powers.

The existing system can already route Points from Lies→Lang, resolve them against the
compiled methods index, fold the doc to reveal them via `Lang_apply_openness`, and
scroll the view.  What it cannot do is express *how* a Point should be presented —
enlarged, glowing, surrounded by squished crumbs of non-ancestor regions.  And it has
no time-domain concept: all Points on a Doc are equally present, equally now.

This spec covers:

- `What` — the universal container replacing both the old flat `What` heading and the
  old `Flock` time-slice; the whole Waft tree is now `Waft/What**/Doc/What**/Point`
- The `...` leading-lines squish convention for non-ancestor regions
- `pause | rwnd | +time` transport navigating the What tree
- Ghost-decay: prior-What Points that quietly shrink unless rescued
- Active-What tracking (session state, not persisted) and breadcrumb navigation
- Minimap engagement: concurrently focused Points
- CM decoration infrastructure: what coordinates need updating, what's already there
- Encoder / decoder generalised with Travel + mainkey(), throttled writes

Fuzzy matching, multi-Lang-per-Lies, Cyto animations, and Matstyle wiring onto Points
remain out of scope.  Everything here is achievable in a single-Doc codemirror show.

---

## Interests — Lang's locks onto Wafts

Everything below this section — the `What` tree, the squish/decoration layer, the
`pause | rwnd | +time` transport — is the **interior of one Interest**.  This section is
the frame around it: how Lang comes to be looking at a Waft at all, and how more than
one Waft can hold Lang's attention at once.

### The duality

A Waft lives on `w:Lies`.  Lang lives in `w:Lang`.  Between them runs one wire:
`i_elvis_req`.  An **Interest** is Lang's end of that wire — the standing lock that
says *"I am attending this Waft, in this way, through this lens."*

```
   w:Lies                         wire                     w:Lang
   ──────                         ────                     ──────
   Waft + cursor    ── i_elvis_req (o What | o Doc) ──▶    %Interest + lens
   (the subject)    ◀─ i_elvis_req (openity verdict) ──    (the lock)
        ▲                                                       │
        └────────── i  (everything you do)  ◀── Ting ──────────┘
```

The subject (a Waft + where its cursor sits) is Lies-side.  The lock (`%Interest`, its
cursor, its lens, its presence) is Lang-side.  Neither half is the Interest alone — the
Interest **is the channel**, named from Lang's end because Lang is who renders it.

**Most of `%Interest` is shared.**  Every kind has a `c.waft` subject, a `%cursor` into
it, a lens, a presence, and a `pending|locked` state.  Only the LE-bearing kinds
(`Trail`, `Sidetrack`) add the heavy organ — an `%LE` checkout, armed only on
foreground.  The point of the family is *sameness*: a `Ting` and a `Trail`
differ in a few fields, not in kind-of-thing.  Even `Ting` has a cursor — it just points
at the latest thing.

Today there is exactly one Interest, `w/{Languinio:1}/{Interest:1}` (Lang.svelte), and
it is the navigation+edit checkout: `sc.src` clone root, `c.LE` handle, `c.What`,
`sc.in_Doc|in_Point` mirroring Lies' `%Spotlight`.  We promote it from *the* Interest to
**one kind**, `%Interest,Trail`.  The value moves from `1` to the kind, so
`o({Interest:1})` still wildcards them all and `o({Interest:'Ting'})` picks one.

### The family

`%Interest,<kind>` — kind is the value (the `%Spotlight,src` form).  Each kind fixes a
subject-stance, a lens, and a presence; the two heavy kinds carry an `%LE`.

| `%Interest`   | subject Waft (stance)        | wire carries                     | lens                   | presence          | LE? |
| ------------- | ---------------------------- | -------------------------------- | ---------------------- | ----------------- | --- |
| `Trail`       | the giver (`active`)         | `o What` (anchored, depth grows) | NaviCado + this spec   | active            | on fg¹ |
| `Sidetrack`   | a spawned `Waft,tentative`   | `o Doc` (`off_what`)             | light NaviCado         | active            | on fg¹ |
| `Ting`        | the taker (`takes`)          | `i` — everything you do          | DocTing (heat)         | always            | —      |
| `GhostList`   | the lister (`lists`)         | `o Doc` (`off_what`)             | DocGhostList           | active            | —      |
| `Testing`     | a Story Waft                 | (its own)                        | a test panel           | active or always  | —      |

¹ The LE-bearing kinds arm only when **foregrounded** — `Trail` first (it foregrounds at
start), a `Sidetrack` when you switch to it.  Live LEs are bounded by the decks you've
crossfaded into, never by roster size.  A `Sidetrack` keeps its LE until it settles and
grafts back into `Trail` (a time-domain concern).

The three Waft flags `active | takes | lists` stop being the typing — **the Interest
kind is the typing**, and the flag is just the Waft-stance a kind locks onto.  (This
folds the Waft-taxonomy open thread shut: a kind is a relation, not a flag.)

`Trail` and `Sidetrack` are the heavy locks.  Their `%LE` (armed/clean/changey/stale/
dirty — see `LiesEnd_spec`) is the *interior state* of an LE-bearing Interest.  The light
kinds lock with no clone and no push — they only ferry a cursor and mount a lens.

### How an Interest comes to be — the Lies/Waft subscription

The duality leaves a gap an earlier draft hand-waved: *how does Lang learn what Wafts
exist, and come to hold an Interest in each?*  Not by reaching into Lies' pile through
`languinio` — a Waft roster is Lies' to know; Lang reading it across the world is a
domain leak (does Lies even put Wafts into `languinio`?  unclear, and we shouldn't
depend on it).  Lang **subscribes**:

1.  **Subscribe.**  Lang holds one standing, eternal `i_elvis_req` — `Lies_waft_roster`.
    It never `finish`es (that would set `finished:1` and close it).  Instead Lies
    **re-delivers to the held req by ref** each time the set changes — the `e.c.target`
    ref-targeting that only reqs get (`i_elvisto(req, …)`, Housing.svelte:536), so a fresh
    roster lands on the *same* req without closing it.  ⛑️ *unbuilt — the first thing to
    lay down.*

2.  **Take up — `pending`.**  Each Waft in the roster mints a Lang-side
    `%Interest,<kind>` carrying `sc.pending` — kind inferred from the Waft's own stance
    properties (below).  Pending = known, lens chosen, *no traffic yet*.

3.  **Lock — lazily, on foreground.**  `sc.pending` clears when the Interest is engaged.
    The light kinds engage cheaply: start the cursor traffic, mount the lens.  The
    LE-bearing kinds (`Trail`, `Sidetrack`) `LE_arm` + `LE_pull` only when **foregrounded**
    — so noticing N giver Wafts arms *zero* LEs; you pay one only for a deck you actually
    crossfade into.

4.  **Remove.**  A Waft leaving the roster drops its Interest (and, for `Trail`, releases
    the `%LE`).

```
roster announces Waft → %Interest,kind +pending → lock → live → (Waft gone) → removed
```

By default a freshly-noticed Waft is a **`Trail`** — the writing/authoring stance, the
one we keep good and readable and document things in — unless its properties say
otherwise (`takes`→Ting, `lists`→GhostList, `tentative`→Sidetrack).

The arrow runs backwards too: Lang can sprout an Interest *before* its Waft exists.  A
`Sidetrack` starts Lang-side and asks Lies to open a fresh **`tentative`** Waft — a
throwaway exploration Waft, often time-division-named, peer of the Ting — which returns
through the roster and the pending Interest binds to.  The **main** Waft, conversely, is
handed into Lang by the test suite via elvis, like an argument, not discovered.  Either
way `pending` covers the gap.

### Waft vs Interest — the border

The two must not blur.  Sort every property by which side of the wire owns it:

**The Waft** is a thing in the world — it exists on `w:Lies` whether or not anyone
attends it.  It owns:
- its identity and content — `Waft:<path>`, the `What/Doc/Point` tree;
- its **stance properties** — how it wants to be attended (`takes | lists | tentative`,
  else Trail).  Durable `%`-properties *on the Waft*, the source of an Interest's kind —
  not the kind itself;
- its **embedded Funkcions** — behaviour hosted *in* the document (next section).

**The Interest** is Lang's stance toward that Waft — ephemeral, one per attender.  It
owns:
- `c.waft` — which Waft;
- `%cursor` — where *this* attention points;
- lens + presence + `pending|locked`;
- `c.LE` — the LE-bearing kinds only.  The LE *and its working `/C` clone tree* are
  Lang-side **on the Interest**; the Waft's `C**` stays Lies-side and the origin `Seem`
  reads across to it.  (So a `Sidetrack`'s second LE sits on its own Interest — only the
  read reaches the Lies Waft.)

Rule of thumb: **if it would still be true with no one looking, it's on the Waft; if it
only means anything to Lang looking now, it's on the Interest.**

### The cursor the wire carries

Every Interest carries a `%cursor` — a small particle saying where this attention points:

```
%cursor
  what:     <What ref>     the anchor — head of the What/What/What path
  doc:      <Doc ref>      where the cursor sits (may be off the anchor)
  depth:    <n>            how deep in the path
  off_what: 1              doc ∉ what
```

The kinds populate it differently — and that *is* their character:

| kind        | `%cursor`                                          | driven by                       |
| ----------- | -------------------------------------------------- | ------------------------------- |
| `Trail`     | `what` + `doc` + `depth`, anchored                 | the user (the old `%Spotlight`) |
| `Sidetrack` | `what`s like Ting, but `off_what` and **no heat**  | the user, flying off            |
| `Ting`      | points at the **latest** thing; `what`s + heatmap  | the `i` push — even backgrounded |
| `GhostList` | `doc` only, **no `what`**                          | the pick                        |

`Trail`'s cursor is the successor to the single Lies-side `%Spotlight` — **the Spotlight
goes**, replaced by one cursor per Interest.  Moving any of them is the *same* operation:
walk the Waft's `C**`, select a chunk.  That walk-and-select engine — today **LiesCurse**
— is general: it is the way to walk any `C**` and select chunks of it, not `Trail`'s
alone and arguably not Lies' alone.  ⛑️ *its name and home want reconsidering once a
second kind drives a cursor through it.*  `depth` is what an over-deep cursor spends
against Se's `%openity` — left to the time-domain section; here it is only **carried**.

`Ting`'s cursor binds to whatever was last entered into it: the `i` push mutates it, and
that push keeps arriving across a *backgrounded* `Interest:Ting`, so the cursor stays
current with no foreground.  Clicking back through Ting's heat or a prior `What` is not a
back-channel and not travelling back in time on ourselves — the time dimension you click
through is just *accessing space*, reading stored `What`s, never an `o` out of the taker.
`Ting` stays purely `i`.

### Funkcions — the Waft's embedded applets

A Waft is a document; a **Funkcion is an applet embedded in it** — the way old HTML
embedded an SWF with `<object>` / `<embed>`.  Two halves, like any plugin:

- **The embed** — `Waft/Funkcion:<name>` — a persisted mount-point in the document's
  `C**`.  It rides in the snap; it is *declaration*, not behaviour (an `<embed src>` tag,
  not the binary).
- **The runtime** — the behaviour on `funk.c.run`, off-snap, hosted **centrally** in
  `Lies/Funkcions` as an eternal `req:Funkcion` (one per Funkcion), pumped once a tick.
  The plugin host — separate from the page, like the browser's Flash runtime was separate
  from the HTML.

Loading a Waft **instantiates** its embeds: each `Waft/Funkcion:<name>` is bound to a
`run` and registered into the central host (today `GhostList_funkcion` does exactly this
for `dirlist`).  The embed persists; the runtime is re-bound on each load.  ⛑️
*generalise instantiation so any Waft's Funkcions auto-bind on load — today only
GhostList's is wired by hand.*

**Who turns an applet on.**  `%run_when` on the embed sets a floor — `loaded` (run
whenever the Waft is loaded; GhostList's `dirlist`, warm even off-stage) or `locked`
(only while attended) — but the live control is the Interest: it reads the Funkcions in
its **cursored region** (as `Seem:origin` reads that region) and fires a further
`i_elvis_req` to Lies to set their runstate — start, pause, poke.  Runstate stays
Lies-side; the Interest drives it from across the wire, never mirrored onto the Waft.  A
Funkcion may **reply with UI**, popping a panel over the lens — so an Interest becomes a
control surface for whatever runs in its cursor.  ⛑️ *unbuilt and large; first slice =
one Funkcion with start/pause/reply-UI.*

Why central, not under the Waft's own `C**`?  Because behaviour is off-snap and
`w`-spine-less; one host keeps the pump in one place and the snap clean — and keeps the
w-agnostic IO pump from growing Waft-specific applets (the GhostList-in-`req_Store` fix).

### Presence — which lens is on stage, and the switcher

`presence:active` Interests compete for one **foreground**, `ave/{ActiveInterest}`
(session state, beside `active_what`).  The foreground Interest's lens holds the primary
stage — *that* is "NaviCado switches to whatever Interest is active," generalised:
NaviCado is simply `Trail`'s lens; foreground a `Testing` Interest and its panel takes
the stage instead.  `presence:always` Interests (the `Ting` heat) render in their own
persistent slot regardless — ambient, never stealing the stage.

**The canonical cursor** — what NaviCado and `%openity` read — is whichever of `Trail` |
`Sidetrack` is foregrounded; those two are the *social* Interests, wired deep into Lang
where the human works Points.  `Ting` and `GhostList` are less social — they pop UI over
from Lies and stay out of the Point-play.  But both decks can show NaviCados **at once**:
stumble around a `Sidetrack` while keeping the `Trail` you came in on in view — a ropeway
through dense bush, the way back always strung up.

The switch is a **horizontal strip of Interest buttons atop the MiniMap**, above the
current Point and the NaviCado breadcrumb — one button per Interest, click to foreground.
`%ActiveInterest` drives it.  The strip also carries an **add button** → a dropdown to
bring an Interest into being or dismiss one (whether a `GhostList` exists at all, say) —
the user's hand on the roster.  Dismiss acts Lies-side — drop `Lies/Waft` — and lets the
Lang startup req that opened it come to rest, *done with it*, so nothing re-uptakes it
next tick: no suppress-list to keep.  ⛑️ *unbuilt.*

Rendering needs no bespoke subscription: an Interest hands its lens a `C` (the Waft, the
cursor's `doc`, the Ting roster…) and **object-ref change is the signal** — when the C is
replaced the `$effect`/`watch_c` reactivity re-renders, and we do the rest.  For `Trail`,
remote change arrives the same way: the `%LE`'s origin `Seem` *is* the Waft's
subscription-to-the-remote — its goners/neus pull hands back a changed C.

Switching between the two LE-bearing decks (`Trail` ↔ `Sidetrack`) is a **crossfade** —
like a DJ choosing where to jam sound from and to.  Both can be armed, but **only the
foreground LE pushes** — a simple write-mutex; no clobber-merge or rebase to handle (two
decks editing one region at once just won't happen).  A `Cyto` graph may float above to
make the movement legible — the elvis arrows firing, the `/C` clone trees spawning under
an `LE_arm` — then dismiss.

(How the foreground arbitrates, how `depth` debits `%openity`, and how a `Sidetrack`
settles and grafts back into `Trail`, are time-domain concerns — the next sections.)

---

## What — the universal container

`What` replaces both the old section-heading `What` and the old `Flock`.  It is a
named attention-seeker that can contain other `What`s, `Doc`s, and `Point`s in any
combination.  The tree grammar:

```
Waft → (What | Doc)*
What → (What | Doc | Point)*
Doc → (What | Point)*
Point → (nothing — leaf)
```

`What` cannot appear inside `Point`.  `Point` is always a leaf.

Because `What` is polymorph it means different things at different depths:

- At the top of a Waft it is a section heading (`setup`, `language`).
- Nested inside a Doc it is a time-slice — the old `Flock` role.  Sibling `What`s
  under one `Doc` are successive moments; `rwnd` and `+time` step between them.
- Nested inside another `What` it is a subsection, possibly one that doesn't involve
  any particular Doc (a global search site — deferred to a later phase).

### Snap shape

```
Waft:Ghost/LakeNets,Ghost/LakeNets
  What:foundationss
    What:story
      Doc:Ghost/test/Story/Peeroleum.g
      Point,method:LakeNetherland
    What:peer
      Doc:Ghost/test/Peeroleum.g
      Point,method:Peeroleum
  What:transport
    What:first look
      Doc:Ghost/test/Peeroleum.g
      Point,method:transport
      Point,method:PeerJS
```

---

## Point class

A Point can carry `class` in its sc alongside `method` (or `label`):

```
Point:1, method:'e_Dock_open', class:'focus'
Point:1, method:'Lang_plan', class:'ghost'
Point:1, method:'Lang_compile'           — no class; defaults apply
```

A small fixed set of pre-defined classes, statically defined in component CSS — not
runtime-configurable.  Avoiding the Matstyle path keeps the decoration system stable
enough to actually use:

| class     | CM decoration                                | minimap dot |
| --------- | -------------------------------------------- | ----------- |
| (default) | enlarge ×1.4, lavender glow                  | gold        |
| `focus`   | enlarge ×2.0, brighter glow, context bar     | bright gold |
| `caution` | amber glow                                   | amber       |
| `dim`     | no enlarge, faint glow                       | grey        |
| `ghost`   | 18% opacity, 40% height scale                | faint grey  |

`ghost` is stamped automatically on Points that belong to prior-What siblings (the
old-Flock role); it is not usually set by hand.  Clicking a ghost rescues it: `class`
is cleared and it moves into the active What's Doc as a live Point.

---

## The squish convention: `...`

Non-ancestor regions in CM are not fully hidden — they are **squished**: the region
header and its first two lines stay visible, and the CM fold hides the rest.  The fold
widget renders `·····` rather than the default `···`.

```
//#region e
async e_Lang_editorBegins(A, w, e) {
  .....
//#region doc routing helpers
Lang_doc_from_event(w: TheC, e: TheC): TheC {
  .....
//#region w:Lang
async Lang(A: TheC, w: TheC) {
  .....
  if (thing) {
     .....selected = line + what(was, on_it)   ← target line, enlarged + glowing
```

`Lang_apply_openness` currently folds from `header_line.to` (hiding everything after
the header).  The squish variant folds from `header_line.to + leading_char_count`,
where `leading_char_count` is the character span of the first two lines after the
header.  Two leading lines is a system constant — not configurable per-Point.

The `·····` widget needs a CSS override.  `codeFolding()` in CM accepts a
`placeholderDOM` factory; we supply one that returns
`<span class="cm-squish">·····</span>`.  The host stylesheet gives `.cm-squish` a
muted colour.  ⛑️ (Langui.svelte needs the extension wired in.)

---

## `pause | rwnd | +time` transport

The Waft UI gains a transport bar that operates on the **sibling What list** of the
active What.  It sits at the bottom of the minimap strip:

```
  ◀◀ rwnd   ‖ pause   ＋time
```

### rwnd

Steps the active What backward among its siblings (same parent).  Un-engages Points in
the current What, re-engages those in the prior sibling.  Stops at the first sibling.

Useful for finding "the start of a trail": scan backward through sibling What slices
looking for where a given method first appeared.

### pause

Stops any automatic audience-paced advance.  Not implemented yet — button renders;
advance is manual-only in this phase.

### +time (cell-division)

Creates a new sibling `What` immediately after the current active one, which becomes
the new active:

1.  A new `What:1,label:''` (empty label; user names it) is inserted after the current
    What in the parent's child list.

2.  Points from the current What that are presumed to carry forward (see heuristic
    below) are **copied** into the new What.  The current What is left intact.

3.  Points in the prior What that were not copied receive `class:'ghost'` stamped on
    their sc.  The minimap and CM decoration layer render them at 18% opacity.

4.  Ghost Points not clicked within 10 s (wall-clock timer in Waft.svelte `$state`)
    shrink further and are eventually dropped from the prior What's in-memory state
    (omitted from next snap write).  A clicked ghost is rescued: `class` is cleared and
    it moves into the active What's Doc as a live Point.

### Carry-over heuristic

When +time fires: Points that were **engaged** in the old What are copied into the new
one.  Points added within the last ~30 s (`created_at` in Point sc) are treated as
belonging to the new What — they move rather than copy and are not ghosted.  Everything
else ghosts in the old What.

`created_at` is a session-only sc field — stripped from snap writes (see encoder).

---

## Minimap engagement

Engagement is which Points are currently driving the fold layout and CM decorations.
Session state: `let engaged: Set<string> = $state(new Set())` in DocMinimap.

Multiple Points can be concurrently engaged (soft cap 3; a constant, not a setting).
A small lock glyph on an engaged minimap row prevents MRU eviction.

When engagement changes, DocMinimap fires `e:Lang_point_navigate` for newly engaged
Points and `e:Lang_point_deactivate` for newly disengaged ones.

`Lang_apply_openness` is extended to accept an array of `point_from` offsets.  The
union of their ancestor chains determines which regions stay open; everything else
squishes.  Where Points have conflicting fold preferences the more-open one wins.

---

## Encoder / decoder

is enWaft() etc. uses Lies_waft_save with a per-waft JS throttle() closure on w.c, posting via post_do.

---

## CM decoration infrastructure

### What already exists

- `foldEffect` / `unfoldEffect` dispatch (`Lang_apply_openness` in LangRegions)
- Bookmark `StateField` — CM remaps `from/to` via `RangeSet.map` on every doc change
- `EditorView.scrollIntoView` for navigation

### What needs adding

**Line enlarge + glow**

`Decoration.line({ attributes: { class: 'cm-point-engaged cm-point-focus' } })` adds
a CSS class to the whole line's DOM element.  The class drives enlargement and glow via
static stylesheet rules — no per-Point CSS variable needed since the classes are a
fixed set.

```css
.cm-point-engaged {
    box-shadow: inset 0 0 12px #c4aaee33;
    font-size: 1.4em; line-height: 1.96em;
    transition: font-size 0.15s, line-height 0.15s;
}
.cm-point-focus {
    box-shadow: inset 0 0 20px #c4aaee66;
    font-size: 2em; line-height: 2.8em;
}
.cm-point-ghost {
    opacity: 0.18;
    transform: scaleY(0.4);
    transition: opacity 1s, transform 1s;
}
```

A `StateField<DecorationSet>` (`pointDecorationField`) holds the current engaged-Point
decorations; a `StateEffect` replaces them atomically on each engage/disengage cycle.
Ghost decorations live in a second `StateField` at lower precedence so engaged Points
always paint over ghosts.

**Context bar**

A `Decoration.widget` with `side: -1` at the line's `from` offset renders a narrow
`<div class="cm-point-ctx">` floating above the target line — the Point's `label` or
`method` name as a dim annotation.  `WidgetType` subclass, rendered only when the
`focus` class is in effect.

**Squish fold widget** — see squish section above.

### Coordinates

- **Bookmark from/to**: tracked by CM's `RangeSet.map`; `e_Lang_update_bookmarks`
  pushes positions back to `bm.sc` on each debounce.  Points backed by bookmarks
  (`bm.sc.point_serial`) inherit this for free.
- **Method-name Points**: no stored `from/to` — resolved fresh from the compile index
  at navigation time.  Stale until recompile; flagged as unresolved in the minimap.
- **Ghost decorations**: resolved at render time.  No persistent coordinates.
- **Line glow**: `decos.map(tr.changes)` inside `pointDecorationField.update` remaps
  line-from offsets automatically when lines are inserted or deleted above the target.

No new coordinate-sync infrastructure is needed.

### Selection.process() and Dip

`Selection.process()` (from the `regroup()` note in Lang.svelte) is the planned
Map-building pass — collecting function calls, IO expressions, and type names into a
Dexie-backed index.  `Dip` (from `caving()`) is a depth-and-position address scheme
for dive targets.  Neither has been written.  Neither is needed for the decoration
system: method-name resolution and bookmark coordinates are sufficient.  Both belong to
the later Map-building phase.

---

## What we can show now

With a single Doc and one working codemirror:

- Open a Waft pointing at `Ghost/Lang.svelte`.
- Add a `What:1,label:setup` with Points for `Lang_plan`, `Lang_compile`.
- Add a sibling `What:1,label:routing` with Points for `e_Dock_open`,
  `Lang_doc_from_event`.
- Click `e_Dock_open` in the minimap → CM folds to show only the `e` region, squishing
  everything above to 2-line crumbs, with the target line enlarged and lavender-glowing.
- Press +time → a new sibling What appears; `routing` Points ghost to 18% opacity.
  Add `Lang_apply_openness` and `Lang_build_regions` to the new What.
- Press rwnd → `routing` Points come back; new Points ghost.
- Click a ghost → it rescues into the active What.
- Multi-engage two Points → CM holds both their regions open simultaneously; the
  minimap shows both lit.

Drifting through a doc's architecture with time-layered annotations and fold-based
dramatic framing — no multi-Lang or fuzzy matching required.

---

## Particle layout summary

```
// Persisted (snap) — encoder uses Travel + mainkey(), SESSION_KEYS stripped
w/{Waft:'Ghost/Tour'}
  /{What:1, label}                      — section / time-slice / subsection; unlimited nesting
    /{What:1, label}
      /{Doc:1, path}
        /{Point:1, method, class?}      — leaf; class in static set above
      /{Point:1, method, class?}        — Point in a What (global search site; deferred)
    /{Doc:1, path}
      /{What:1, label}                  — time-slice Whats under a Doc
        /{Point:1, method, class?}
      /{Point:1, method, class?}        — Points directly on Doc

// Not persisted — session state
ave/{active_what:1}
  sc.path: string                       — Waft sc.Waft
  c.what: TheC                          — direct ref to the active What particle

// CM state (not particles)
pointDecorationField                    — StateField<DecorationSet>: engaged Point glows
ghostDecorationField                    — StateField<DecorationSet>: prior-What ghost decorations
setPointDecorationsEffect               — StateEffect<DecorationSet>: full replace
setGhostDecorationsEffect               — StateEffect<DecorationSet>: full replace

// Minimap (Svelte $state — session only)
engaged: Set<string>                    — engaged Point method specs
locked:  Set<string>                    — Points locked against MRU eviction
ghost_timers: Map<string, number>       — setInterval ids for 10 s shrink per ghost spec
```

---

## Open questions

- **Squish fold widget DOM**: `codeFolding({ placeholderDOM })` needs wiring in
  Langui.svelte's extension list.  ⛑️

- **`C.children()` order**: the encoder calls `C.children()`.  Confirm TheC exposes an
  ordered child iterator that preserves insertion order (or use `o({})` with a mainkey
  filter).  ⛑️

- **Ghost cleanup on save**: ghost Points that have decayed (timer elapsed, dropped from
  in-memory state) are omitted from the next snap write because `encode_waft` walks
  live in-memory state.  If the user saves immediately after +time the ghosts are still
  present; they'll decay next session.  Acceptable — but worth noting.  ⛑️

- **Global Points (no Doc ancestor)**: schema accepted, resolution deferred.  Minimap
  renders them as unresolved red dots.

- **Multi-Lang per Lies**: not in scope.  Path is clear (each Doc maps to a Lang
  instance by path) but wiring is not done.
