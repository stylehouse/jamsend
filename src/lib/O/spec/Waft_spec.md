# Waft spec

> **Status (2026-06-27) — own-the-state pass.** The durable part of this doc is
> the **§Interests** frame below (lines ~32–294): how Lang comes to attend a Waft,
> the Interest family, the Waft↔Interest border, the cursor, Funkcions, presence.
> Two corrections fold into it:
> - **The decks are `Trail` + `Aside`, not `Trail` + `Sidetrack`.** `Aside` is the
>   live off-Trail exploration deck (the daily scratch `Waft:Aside/<YMD>`, stance
>   `%aside`, persists, walks like a Trail). **`Sidetrack` is dormant** — the
>   tentative-throwaway-grafts-back kind; its `↳` sprout button was removed, so it
>   has *no UI entry* and lingers only as dead code (`interest_sprout_sidetrack`,
>   `tentative→Sidetrack` in `interest_stance_of`) awaiting cleanup. Read every
>   "Sidetrack" below as "Aside" for the live system. See `Interest.md`.
> - **Lang/Interest state resumes from `Waft:Keep`.** The "session state, not
>   persisted" claims in the back half are superseded: focus/cursor/open-set now
>   persist through the Keep ledger (`Lies_keep_*`, `Cluster_design.md` /
>   `Keeping_spec.md`).
>
> Everything from **§Point class onward has graduated or lapsed** — it is now a
> short ledger (see "## Graduation ledger" at the foot) pointing at where each
> piece lives in live code, not a design to build. The What-tree grammar it rests
> on is still accurate and kept. A from-scratch rewrite from a higher vantage is
> deferred until Lies+Lang settle.

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
(`Trail`, `Aside`) add the heavy organ — an `%LE` checkout, armed only on
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
| `Aside`       | the daily scratch (`aside`)  | `o What` (anchored, like Trail)  | NaviCado               | active            | on fg¹ |
| `Ting`        | the taker (`takes`)          | `i` — everything you do          | DocTing (heat)         | always            | —      |
| `GhostList`   | the lister (`lists`)         | `o Doc` (`off_what`)             | DocGhostList           | active            | —      |
| `Testing`     | a Story Waft                 | (its own)                        | a test panel           | active or always  | —      |

> *Dormant:* `Sidetrack` (stance `tentative`) — a spawned throwaway `Waft,tentative`,
> `off_what` light-NaviCado deck that kept its LE until it grafted back into a Trail.
> Superseded by `Aside`, which fills the same off-Trail-exploration role but **persists**
> (a real `Waft:Aside/<YMD>` home) instead of grafting back. The kind survives as dead
> code with no UI entry; treat the rows below that name it as describing `Aside`.

¹ The LE-bearing kinds arm only when **foregrounded** — `Trail` first (it foregrounds at
start), an `Aside` when you switch to it.  Live LEs are bounded by the decks you've
crossfaded into, never by roster size.

The Waft flags `active | takes | lists | aside` stop being the typing — **the Interest
kind is the typing**, and the flag is just the Waft-stance a kind locks onto.  (This
folds the Waft-taxonomy open thread shut: a kind is a relation, not a flag.)

`Trail` and `Aside` are the heavy locks.  Their `%LE` (armed/clean/changey/stale/
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
    LE-bearing kinds (`Trail`, `Aside`) `LE_arm` + `LE_pull` only when **foregrounded**
    — so noticing N giver Wafts arms *zero* LEs; you pay one only for a deck you actually
    crossfade into.

4.  **Remove.**  A Waft leaving the roster drops its Interest (and, for `Trail`, releases
    the `%LE`).

```
roster announces Waft → %Interest,kind +pending → lock → live → (Waft gone) → removed
```

By default a freshly-noticed Waft is a **`Trail`** — the writing/authoring stance, the
one we keep good and readable and document things in — unless its properties say
otherwise (`takes`→Ting, `lists`→GhostList, `aside`→Aside; the dead `tentative`→Sidetrack
path still resolves but nothing stamps it from the UI).

The arrow runs backwards too: Lang can sprout an Interest *before* its Waft exists.  The
live case is the **GhostList smart-click**: picking a Doc with no open home throws it into
today's persisted `Waft:Aside/<YMD>` (`Lies_spawn_aside_waft`, stance `%aside`) and lands
the cursor there.  (The older `Sidetrack` reverse arrow — sprout Lang-side, ask Lies to
open a `tentative` throwaway peer of the Ting, bind the pending Interest when it returns
through the roster — is the dormant form of the same move.)  The **main** Waft, conversely,
is handed into Lang by the test suite via elvis, like an argument, not discovered.  Either
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
  reads across to it.  (So an `Aside`'s second LE sits on its own Interest — only the
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
| `Aside`     | `what` + `doc` + `depth`, anchored (walks like a Trail) | the user, off on a thread  |
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

**Monitor vs action — the pump axis.**  A Funkcion's mainkey *value* is its **kind**
(`Funkcion:Storying`, `Funkcion:dirlist`, …).  A kind is a self-contained module under
`O/Funk/` registered in `O/Funk/kinds.ts` as `{ run?, component }`.  `run` present = a
**monitor**: pumped every tick (the verdict light `Storying`, the `dirlist` walker).  `run`
absent = an **action**: never pumped, struck on demand (the `Ballistics` drum-pad — a click
pops a Lies/Store limb via `e_Lies_strike`).  Both render through the one generic host
`FunkHost` (mounted by `Waft.svelte` for any `%Funkcion` — and the legacy `%havoc` particle,
aliased to the `Ballistics` kind); the host knows only "mount the kind's component", so Waft
stays ignorant of any applet's specifics.

Loading a Waft **instantiates** its embeds: `Lies_instantiate_funkcions` (`LiesStore`) walks
a loaded Waft's subtree and binds each monitor kind's `run` into the central host (on load and
on `watch_c` mutation).  `Lies_register_funkcion` keys each req by the funk's structural
**Dip** (`c.Dip`, the waftid slot `Waft_dip` stamps on every Waft** particle — reliably present
because `Waft_dip` runs immediately before instantiate on both the load and UI-add paths), so
sibling cells of one kind don't collide on one req; a host with no Dip (the trail Funkcion, on a
Seem) falls back to kind + binding.  The embed persists; the runtime is re-bound on each load.
*(Generalised — was GhostList-only.)*

The one test that authored `%havoc` — **LakeSurprise** (the limb `surprise_read`, which
fabricates a disk-diverged-under-edit on the active dock) — has been **folded** to
`Funkcion:Ballistics,kind:surprise_read` across its snaps; `Lies_arm_engaged`'s self-arm scan
matches both the folded form and legacy `%havoc`.  FunkHost still aliases a bare `%havoc:<kind>`
particle to the `Ballistics` kind as back-compat (no live snap uses it now).  The limb kind rides
as `kind:`; the limb *behaviour* stays in `Lies/HAVOC_LIMBS`, dispatched by that kind.

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
`Aside` is foregrounded; those two are the *social* Interests, wired deep into Lang
where the human works Points.  `Ting` and `GhostList` are less social — they have UI over
in Lies and stay out of the Point-play.  But both decks can show NaviCados **at once**:
stumble around an `Aside` while keeping the `Trail` you came in on in view — a ropeway
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

Switching between the two LE-bearing decks (`Trail` ↔ `Aside`) is a **crossfade** —
like a DJ choosing where to jam sound from and to.  Both can be armed, but **only the
foreground LE pushes** — a simple write-mutex; no clobber-merge or rebase to handle (two
decks editing one region at once just won't happen).  A `Cyto` graph may float above to
make the movement legible — the elvis arrows firing, the `/C` clone trees spawning under
an `LE_arm` — then dismiss.  *(A true simultaneous dual-LE push-mutex, and an Aside with
its own off-anchor clone rather than borrowing the last Trail's LE, are still open — see
`Interest.md` "Per-deck … LEs".)*

(How the foreground arbitrates and how `depth` debits `%openity` are time-domain
concerns.  The old `Sidetrack`-settles-and-grafts-back step is gone: an `Aside` persists
as its own Waft instead of grafting home — see "Rejoin the stack frame" in `Interest.md`.)

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
      Doc:Ghost/test/Story/Lake/LakeAntecedents.g
      Point,method:Peeroleum
  What:transport
    What:first look
      Doc:Ghost/test/Story/Lake/LakeAntecedents.g
      Point,method:transport
      Point,method:PeerJS
```

---

## Graduation ledger — the old interior (Point class · squish · transport · CM infra)

Everything below `§What` here used to be the design for **one Interest's interior** —
 Point decoration, the `...` squish, the `pause | rwnd | +time` transport, ghost-decay,
  CM `StateField` infra, the demo script. It has either **graduated into live code** or
   **lapsed**. Kept as a pointer ledger (verified 2026-06-27), not a plan; read the named
    code, not this doc, for exact behaviour. A clean rewrite from a higher vantage waits on
     Lies+Lang settling.

| piece | status | where it lives now |
| --- | --- | --- |
| **What tree** `Waft→What*→Doc/Point` | **LIVE** | the grammar + snap shape above are current; every `wormhole/Story/**/toc.snap` carries it |
| **Point `class` decoration** (default/focus/caution/dim/ghost — enlarge+glow, minimap dot) | **GRADUATED** | `Langui.svelte` — `pointDecorationField` (StateField), `.cm-point-engaged` / `.cm-point-<class>` CSS, driven via `dock.c.setPointFonts` / `LangPoint.svelte` |
| **`+time` cell-division + carry-over heuristic** | **GRADUATED** | `LiesCurse.svelte` — `Lies_what_carry_over` / `Lies_seed_what_carry_over`: copies engaged/just-added Points into a new sibling `What`, leaves the parent intact |
| **`pause \| rwnd` transport bar** | **PARTIAL — on the chopping block** | a play/pause/step transport lives in `NaviCado.svelte` (`.nvc-transport`, `Lies_desire_play\|pause`, gated on `req:desire`/`req:timemachine`); the standalone button strip atop the minimap was never built. `Keeping_spec.md` proposes **dropping playback** ("no sense of time on Lies", its decision **D1**) — don't invest here |
| **Encoder/decoder throttle** (`enWaft` + per-Waft `throttle` via `post_do`) | **LIVE** | `Lies_waft_save` |
| **Squish `...` / `cm-squish` fold widget** | **NOT BUILT** | no `cm-squish` anywhere; the lone surviving Open Question — `codeFolding({ placeholderDOM })` still unwired in `Langui` |
| **`active_what` session state** | **SUPERSEDED** | active-What truth is `ave/{ActiveInterest}` (the foreground Interest) + its per-Interest `%cursor`; no `active_what` particle exists. Focus/cursor/open-set **resume from `Waft:Keep`** (`Lies_keep_*`), not session-only state — see `Keeping_spec.md` |
| **`Selection.process()` / `Dip`** | **SPLIT** | `Dip` is **built** (`Waft_dip` → `c.Dip`, the Funkcion/Waft address space); `Selection.process()` (the Map call-graph pass) is **still unwritten**, referenced only in `Lang.svelte` / `LangSion.svelte` notes — the later Map phase |

The old draft's CSS rules, `StateField`/`StateEffect` wiring, and coordinate-sync notes
 are all folded into Langui's live implementation; the `## What we can show now` tutorial
  and the `## Particle layout summary` (which still named `active_what`) are dropped as
   served-their-purpose.
