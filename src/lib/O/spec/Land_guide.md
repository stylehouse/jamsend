# The land page — a guide

`/Desk?G=Land` — the code as a place you assemble views of.  This is the manual for what is BUILT (2026-11-10); the plans and
 rulings behind it are in `Wordland_todo.md` §0 ("ANSWERED", "THE WEAVE").  The code: `Ghost/L/LandPage.g` (the think, the `pane`
  and `slice` verbs), `src/lib/L/LandFace.svelte` (the page), `LandMember.svelte` (a doc as its objects), `LandPane.svelte` (a doc
   as CodeMirror).

## 0. Before you start

- **Open it on a tab with your folder** (FSA granted).  Without one, Atlas has nothing to read: the Atlas card says
   *"no A:Wormhole nav — grant FSA on this tab"* and every pane verb answers *"no repo on this tab"*.
- **Wait for the census.**  The Atlas card reads `mapped / docs`; panes and wires come from that map.  If it sits short of
   full, type `:atlas_refresh` in the command line.
- It is **read-only** (role hacker): nothing here writes your code.  It also forgets: panes and slices are rows on the page and
   are gone on reload (a private store is planned — §6).

## 1. The page, top to bottom

**The map** (the top two lines) is the system top down, and it is two front doors joined (`src/lib/L/land_map.ts`):
- **Waft:Everything** (`wormhole/Ghost/Everything`) is the CODE's front door: one What per area of the program, each pointing at
   its area Waft (which lists the area's ghosts, their main functions as Points, its specs and Books) and tagged with the
    **Ground** it loads as (`ground:Wire`…).
- **DocIndex** (`spec/DocIndex.md`) is the PROSE's front door: four sections (I metaphysics and the code · II the app foundation ·
   III jamsend · IV the visual end), a topic per row, each with its front-door doc.
- **The join is by doc**: an area Waft cites its specs, so a topic whose doc an area cites belongs to that area, and the area sits
   in the section most of its topics are in.  So the first line is the areas, in DocIndex's sections, each in its own hue — the
    hue every doc that area cites wears as the left edge of its pane.

| part | what it is |
|---|---|
| the area chips | press one: it opens OVER the page (nothing moves) — its desc, **⌂ aim at** its Ground, **open its ghosts** (its Ground's .g as members), its page (`/Desk?G=…` if it has a Main), **read** (its DocIndex topics — a spec opens as a member: its headings), **main functions** (its Points — press one to open it), **Books** (⇄ = weave by its kept Exercise) |
| **Ground** line | the Ground in view (`%Aim`, default Land) and what it stands on (`Land ← Glass ← Core`); its .g count; the **build** (plain, or the electrode flavour — and whether a measuring twin `Hacky/<Name>` exists); the **tap** (Electrode armed or not); the **census** (Atlas mapped/docs); the reader.  An area wearing a Ground in the chain is ringed; a pane whose doc that Ground loads shows **⌂** |
| **Exercise** | every Book whose run was measured and kept.  The name runs `lagoon join --book` (declared vs measured, as text); **⇄** weaves it into the wires (§3) |
| the command line | `:verb args`, Enter or **run**.  `:verbs` lists every verb this tab has |
| the seek box | a method, a phrase, or `doc:Heist` — hits list as you type |
| **slices** | the record of your looking (§4) |
| the weave bar | which Book colours the wires, and the tally |
| the panes | the docs you hold, with wires between them |

The quickest view: **press an area** — its busiest docs open as members, its main functions in focus (bold; beads without one
 fold to a line — press to open) and each member scrolls to them.  Then **press a def**: its REACH shows over the member — who calls
  it and what it calls, by file; press a file or a method there to pull it in as a member aimed at it, or **{ } read** for the code.
   ✺ erupts a whole member's neighbourhood; ⇄ weaves a Book.

## 2. Putting a view together — the recipe

1. **Get one doc in.**  Either type in the seek box and press a hit, or type `:pane open <method>` (Atlas finds where it is
    defined, a `.g` first) or `:pane open Ghost/L/Atlas.g` (a path; `:120` for a line).  Several at once:
     `:pane open Lagoon_join Atlas_nav Land_tell`.
2. **It arrives as a MEMBER** (pressing one of its defs shows that def's reach — §1) — the doc as a list of its objects, not its text: its `//#region` beads in file order, each bead's
    methods laid as a hive (names sharing a stem grouped — `Atlas` + `_plan`, `_nav`…).  The method you asked for is lit.
3. **Erupt to bring its neighbours.**  Press **✺** on the member's bar (or `:pane erupt <n>` / `:pane erupt <method>`): it opens
    the docs at the other ends of its calls — the ones it calls and the ones calling it — busiest first, three of them.  `.ts`
     files (the House's own `o`/`i`/`oai`) are skipped; `--all` includes them, `--k=5` takes more.
4. **The wires appear by themselves** — one curve per call the code declares from a method in one pane to a method in another,
    arrowhead at the callee, thicker for more call sites.  Hover a wire for `caller → callee · n call site(s)`.
5. **Weave a Book** (⇄ beside it in Exercise, or `:pane weave <Book>`): the wires take that run's word —
    **green** ran · **amber dashed** never ran (declared, not measured) · **pink** undeclared (measured, not declared) ·
     faint blue: no Book woven.  `:pane weave off` clears it.
6. **Read the code where it matters.**  Press a method in a member (or **{ }** on its bar, or `:pane code <n> <method>`): that
    pane becomes CodeMirror at it.  **▤** folds it back to the member.
7. **Arrange**: `:pane arrange grid|row|column`.  **Align** several CodeMirror panes on one method: `:pane align <method>` —
    each pane holding it scrolls it to the top.  Close with **×** or `:pane close <n>|all`.

A worked example: `:pane open Ghost/L/LandPage.g` → ✺ on pane 1 (LiesFunk, Atlas, Electrode arrive) → ⇄ beside AtlasStaple →
 read the wires → press `Atlas_nav` in the Atlas member to read it.

## 2b. Where to start — patches the one kept Exercise points at

AtlasStaple's run (397 flows) is mostly NOT Atlas: it is a Book booting and standing its Ground.  The busiest cross-doc traffic:
 `LiesLies → LiesFunk` 4 · `Lies → LiesLies` 4 · `LiesLies → Peeroleum` 3 · `Stuffica → Theory` 3 · `Supervisor → Ground` 2 ·
  `Ground → Theory` 2 · `Auto → Supervisor` 2 · `Hovercraft → Text` 2.  Most-called docs: LiesLies 49, LiesFunk 44, Theory 38,
   Supervisor 36, Atlas 30, Hovercraft 28.  Three patches worth a view:
- **How a Book stands its Ground** — `:pane open Ghost/A/Ground.g Ghost/A/Theory.g Ghost/O/Supervisor.g`, ⇄ AtlasStaple.  The Atheory
   rows you built, and which of them a real run touched.
- **The Lies knot** — `:pane open src/lib/O/Lies.svelte src/lib/O/LiesLies.svelte src/lib/O/LiesFunk.svelte`, ✺ on LiesLies.  The
   biggest knot in the run (the include door, the channel, Peeroleum) — the machinery the Lies|Lang analysis decided not to carry.
- **The req machine under it all** — `:pane open src/lib/O/Hovercraft.svelte src/lib/O/Text.svelte`, ✺ on Hovercraft.

## 3. Reading the wires honestly

- A wire is drawn only **between panes** (a doc calling itself is not drawn yet) and only where Atlas recorded the call.
- **Only AtlasStaple has a kept Exercise** today.  Others need `runner_sweep --exercise <Book>` on a runner.
- **Missing wires are often the measure's limit, not the code's**: a Book's test code usually reaches a ghost through the Story
   machinery, so the Exercise records the call with no caller (`Flow,of:Atlas_pass`) and no wire can be drawn.  That gap is
    Electrode's queue (1), call-site ids.
- `.svelte` ghosts are measured, but lose their caller after an `await` (only compiled `.g` has the measuring build); plain `.ts`
   is never measured.  Inspection (members, declared wires) covers all of `src/lib`.

## 4. Slices — the record of your looking

- Every deliberate act (open, close, align, weave, erupt) joins the **current slice**: its acts in order are the slice's
   *reason*, the docs it held are its *matter*.  Hover a slice chip for both.
- **✂ cut** — your next act begins a new slice.  A quiet of two minutes cuts one by itself, drawn **dashed**: a suggestion.
- **⊕** on a chip merges it into the slice before it (undoing a wrong cut).  The **✂ menu** on a chip splits it before one of
   its acts.
- **Press a chip** to go back: the panes become that slice's docs.  Acting from there starts a **branch** — the new chip shows
   **⑂k**.
- Verbs: `:slice cut` · `:slice merge <k>` · `:slice split <k> <i>` · `:slice go <k>`.

## 5. The verbs, in one table

| verb | does |
|---|---|
| `:pane open <path[:line]\|method> …` | add panes (members); `--code` opens as CodeMirror, `--reuse` moves the pane already on that doc |
| `:pane erupt <n\|method>` | open the docs at the other ends of its calls (`--all`, `--k=N`) |
| `:pane code <n> [method\|line]` / `:pane fold <n>` | member ⇄ CodeMirror |
| `:pane weave <Book>\|off` | colour the wires by that Book's Exercise |
| `:pane area <title>` | an area's busiest docs as members, its main functions in focus (`--k=N`) |
| `:pane aim <Ground>` · `:pane ghosts [Ground]` | the Ground in view · open a Ground's own .g as members |
| `:pane align <method>` · `:pane arrange grid\|row\|column` · `:pane close <n>\|all` | layout |
| `:slice cut\|merge\|split\|go` | §4 |
| `:lagoon join --book=<Book>` · `:lagoon oath` · `:electrode top` · `:atlas_refresh` · `:verbs` | the reader, the tap, the census |

## 6. Not built yet

- **Keeping it**: slices and panes die on reload.  Planned: a hacker-private store, `wormhole/Hacker/<who>/<session>/Trail|Aside/…`,
   written through Atlas's nav (no seat needed).
- Wires inside one doc; a slice marking which docs are new vs carried; slices into commits / a slideshow.
- The far view: the methods and flows as a map on the glass (Vyto), panes as its scopes.
- Writing: needs the page to hold the write seat over a relay channel — the same channel that would let it drive a runner.
