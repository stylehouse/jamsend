# Emotion_todo — the will that drives the land, and how sure it is of each leg

> *"there's something hefty we should do with scheduling of Lies|Langui motives on this side of things… shall we
>  call it… emotion? we track how sure we are of each leg we're going down into. and basically our will to go
>   somewhere constantly drives the %w to do work, moving around on these proteins, sorting them into relevance to
>    something, building clusterings of sense — which should be what code is adapted to, and can be born out of…
>     simple ideas about the names of particles and how they relate."*  — the owner, 2026-10-03, walking the cave
>
> *"feel free to burn lots of tokens pursuing what seems to be light. this must be worked on truthfully."*

A **working `_todo`**, newly opened.  Nothing here is built or ruled except where it says so.  The one sentence:

**Every world works toward where we are going, in proportion to how unsure we are of the way there.**

---

## 0. What to get on with next

1. **The owner rules the names** (§6): `Emotion` as the concept, and the particles — `%Will` / `%Leg,sure` are this
    doc's working coinage, nothing more.
2. **The first slice** (§5) — legs that know how sure they are, one `%Will` the cave stands, and the Stemdex spending
    its read budget nearest that will instead of in set-insertion order.  It is measurable before and after
    (docs read before the first relevant one), it touches one census, and it is Book-gateable.
3. **Then the jostle joins it** — Glassbeast's "Layer 2" (nodes moving when the document changes, *"so we remain
    animal aware"*) is the same idea seen from the glass: **motion is unsureness and news.**  A settled thing holds
     still; a leg being resolved trembles; a dige move is a kick.  It waits on 2, because a tremble needs a sureness
      to be proportional to.

---

## 1. The idea, unpacked

- **A will** is a standing *where-we-are-going*: a search, a dive down the cave's rope, a cursor resting in a method,
   a Book's step waiting on a truth.  It is not a one-shot request; it stands until it is satisfied or dropped.
- **Legs** are the steps a will took to get where it is (search › file › method › ⇝ callee), and **each leg knows how
   sure it is** — an exact def name is sure; a mention, a freetext line, a callee guessed by name are less so; a file
    the census never mapped is barely a guess.  A rope is as strong as the evidence for each of its legs.
- **Work goes where the will is strong and unsure.**  Every world with a budget (the Stemdex's reads, Atlas's maps,
   Lagoon's anatomy, the glass's attention) spends it nearest the will first, weighted by how much is still unknown
    there.  A sure leg needs no work.  An unsure one pulls it.
- **Sorting into relevance IS the clustering of sense.**  What the work produces is the land re-ordered around the
   will — and the order it can find is exactly as good as the names let it be: stems (`VytoSpine_*`), mainkeys (what a
    thing IS), calls (who reaches whom), co-occurrence.  That is the owner's last clause: code should be adapted to
     this — **naming is how code makes itself legible to the will** — and new structure can be born out of it.

## 2. It is already half there — the kin, none of which talk to each other

Each of these is a real, built mechanism, and each is a fragment of the idea.

| fragment | where | what it already is | what it lacks |
|---|---|---|---|
| **gallop confidence** | `Housing.svelte.ts:70`; `Story_future_directions.md` "the trigger isn't causality — it's gallop confidence" | momentum *felt* from queue depth: deep + sustained ⇒ "we are galloping", drain flat-out | it does not know **where** it is galloping |
| **unambiguity** | `Stuff.svelte.ts` `resolve()` (~1111) | sureness of identity, scored (`1/possible`, past and future), threshold 0.23 | the score dies inside `resolve()` |
| **the heat purse** | `Vyto.g` HEAT_BUY (~28), `Vyto_attend` (~1279) | attention earned by attending, self-taxed on everyone else, spent as size | heat changes the picture, never the work |
| **%Interest / ActiveInterest** | `Interest.md` | which channel the human's attention flows through (Trail · Aside · GhostList) | it steers the editor, not the censuses |
| **%Reach** | `Reach_todo.md` (W2) | a booked want, a doer, ONE self-throttling pump, three named endings | the shape of will-drives-work — for one network ask |
| **the req machine** | Hovercraft; `Coding_guide.md` | `needs_work`, ttlilt, maz levels — how work asks for time | no notion of *why this first* |
| **the errands** | `Lagoon.g` THE ERRANDS; the Aside's `%What,about,FromWhat` | a record of what you went in there to look at | a record, read afterwards — not a pull |
| **the cave's rope** | `Lagoon.g` THE CAVE | legs, literally: `⌕ q › file › method › ⇝ callee` | no leg knows how it got there or how sure it is |
| **the budgets** | Stemdex `READ_BUDGET 24` (`LiesFunk.svelte` e_Lies_stemdex_scan), Atlas's pass budget | polite, bounded, convergent work | spent in roster order — indifferent to what anyone wants |

**What is missing is the wire between them.**  Gallop does not know where; heat does not drive work; Interest does not
 steer the censuses; resolve's sureness never leaves resolve; the budgets are spent blind.  Emotion is that wire.

## 3. The shape — a proposal, not a ruling

- **`%Will`** — one standing particle per seeker, snap-visible (Homethink §6: *situatedness is speech* — a will is a
   fact the group would SEE, so it stands as matter, never as a `.c` flag).  Its children are **`%Leg`** rows, each with
    `sure` and `why` (`exact` · `mention` · `text` · `call` · `guess` · `unmapped`).
- **Where wills come from**: the human (the cave's rope, a search, the cursor's Point via `ActiveInterest`), a Book (its
   step's `expecting` — a Book waiting on a truth is a will), the machine (upkeep).
- **Who reads them**: every world with a budget.  The rule is one line — **spend where `strength × (1 − sure)` is
   largest**.  The Stemdex reads the will's files first, then their callees' files, then the same stem families, then
    the rest.  Atlas maps an unmapped doc the will touches before one nobody wants.  Lagoon asks the anatomy of the
     likely next legs (the callees of the method you are on) before you press.  The glass's heat follows the will.
- **Pace**: gallop confidence becomes *will pressure*.  A strong unsure will may let the House gallop; when every will is
   sure, the House rests — idle ticking is a sign of an unowned will, which is a bug you can now name.
- **Precedence**: the human's will outranks every machine will (whittled law 8, "a machine defers to the human's tab").
- **Visibility**: unsureness is motion (§0.3).  Sureness is size/brightness (`dose` — the Glassbeast ruling: confidence
   rides dose, `loose` means off-the-pile).

## 4. Laws it must keep (already ruled elsewhere — do not re-derive)

- **Serial by default; pacing is policy** (`Fallen_out_of_mind §10.1` #4).  A will re-orders a queue; it does not
   multiply it.
- **A machine defers to the human's tab** (#8).
- **Wake ≠ hold; a ttlilt is not a keepalive** (`Coding_guide.md`).  A will is a PRIORITY, never a reason to stay
   awake — a House whose wills are all sure must go quiet.
- **New state is snap-visible** (#7) — `%Will` / `%Leg` are particles.
- **No wall clock in `.sc`** — sureness is derived from EVIDENCE, deterministically; any decay-over-time rides `.c`.
- **ATLAS KEEPS, LAGOON ASKS** — the will is asked over; it holds no index.  Workers read it; it stores nothing of theirs.
- **The producer owns its causes; Vyto only draws** — a tremble is a cause the producer states, not an animation the
   glass invents.

## 5. The first slice, concretely

1. **Legs that know.**  Each cave step records `sure` + `why` from the evidence that took it there:
    an exact def hit → `exact` 1 · a hit inside a mapped method → `mention|text` 0.6 · a walk over Atlas's own call row →
     `call` 0.9 · a callee resolved by name to a different file → `guess` 0.5 · a file Atlas never mapped → `unmapped` 0.2.
      The rope's sureness is its weakest leg (a chain is as strong as its weakest link — to be argued in §6).
2. **One `%Will`** on the Lagoon world while the cave is open, mirroring the rope's frontier (replaced with `r()`, so it
    is tracked and snaps consistently).
3. **The Stemdex spends nearest the will.**  `e_Lies_stemdex_scan` orders its roster by relevance to the standing will
    instead of set order.  **Measure first** (no baseline, no attribution): in the hacker room, for a fixed query, how
     many docs are read before the first one that yields a text hit, before and after.
4. **A Book**, `LagoonWill`, on a frozen corpus bigger than `Sample.g` (it needs at least two files that call each other,
    or the ordering has nothing to choose between).

## 6. Open — the owner's to rule

- **Names.**  `Emotion` for the concept is the owner's ("shall we call it… emotion?").  The particles — `%Will`, `%Leg`,
   `sure` — are working coinage.  (`%Want` is taken by the Arrival begs and the `%Want` middleware; `%Interest` by the
    attention channel; don't reuse either.)
- **How sureness composes along a rope** — the weakest leg, or the product?  The weakest is honest about a single bad
   guess; the product is honest about many small ones.
- **Does a Book get a will?**  If a Book's waiting step IS a will, then hold-vs-gallop and expecting become one mechanism.
- **A group's will** (Homethink §5, the community's computer) — a crew searching together, a friend's interest pulling
   your Stemdex.  Later, but the shape should not forbid it.
