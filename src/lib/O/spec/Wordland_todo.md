# Wordland_todo.md — the new editor: find text anywhere, string it together, group it by relevance

**What the field is.** Wordland is the editor being built at `/BigWordland`: **search-first**.  The old editor (Editron)
 starts from a file tree and a Waft; Wordland starts from a box you type into, and every word in the project (code and
  prose alike) answers.  It is the one bet turned on the code itself (`Homethink §1`): the codebase kept as the same
   legible matter as everything else, so the editor is just one more reader of it.

**Editron vs Wordland.** Editron (`Editron.md`) is the current `role:editor` webapp, and it stays **stable**: it's the
 one writer and the reference compiler, on a frozen spine.  Wordland is `role:hacker`, on the live spine: it reads
  everything and writes nothing, and it reuses Editron's parts (Lies, Lang, the Waft tree, the Stemdex, the Keep).
   It will **take the write seat by wresting it** when the human is working in it.  It will **never compile itself**:
    compiles go to Editron.  The full account of the editor's powers is in `Editron.md` §8.  Wordland's future is to
     **fuse with Atheory** (§4).

## 0. What to get on with next

1. **Strings and groups (§1.2–1.3)**: the features that make Wordland more than a search box.  Neither is built.
2. **The write seat** (`Editron.md` §8.2 A): a lease at the relay, wrested by the active tab, with `Lies_holds_seat`
    replacing `=== 'editor'`.  Until then, Wordland writes nothing and Editron is the only writer.
3. **One compiler per ticket** (`Editron.md` §8.2 B): today a `ghost_compile` reaches every editor tab.
4. **The cave's rough edges** (`Glassbeast_todo.md`, the "THE CAVE" log entries): a pressed answer item still lands
    with `leave:1` and resets the query; middle-click paste is unverified.

## 1. The features — FIND, STRING, GROUP

Three verbs, in order of how built they are.  Each names what stands (✅), what's partly there (◐), and what's only
 wanted (○).

### 1.1 FIND — any text, anywhere in the project

You type; everything that mentions it answers, code and prose alike, down to the line.

- ✅ **One box** (the hole): a plain room input, drawn atop the cave's glass or, in the sprawl, atop the Vyto piece.
   `/`, the ⌕ chip and a click on the spine's head all bring you to it.  It debounces until a word is forming.
- ✅ **Every mention, per line**: `Lies_search` returns every line a word sits on (capped at 40 per doc), and the cave
   makes one hit per line, deduped by `path:line`.  The tiers are exact ▸ prefix ▸ substring over defs, then free text.
- ✅ **Code and prose in one index**: the Stemdex (stem → path → lines) over code, specs and todos alike.  A spec is a
   place: a file Atlas has no map of opens as a FLAT level (its hit lines, with the text landed beside).
- ✅ **A file's shape**: `doc:Heist` seeks a file's anatomy; a file opens to its methods in file order (`Lagoon_beads`
   gives the regions an author drew).
- ✅ **Who calls this, what it calls**: a method is a place with two doors, ⇝ calls and ⇜ callers (Atlas `call`/`elvisto`
   rows; `Lagoon_callers`).  Walking a door lands the code in the editor beside a rail.
- ✅ **Prose that names code**: Atlas holds every backticked `name` and file link in the docs.  `Lagoon_mentions` splits a
   real LINK (Atlas holds the def) from a phrase.  `Lagoon_prose_rot` finds docs naming things that are gone.
- ✅ **Verbs from the same box**: `:verb args` runs a tab's controls (`Verbs_todo.md`).
- ◐ **Ranking**: hits come in tier then file order.  Nothing yet ranks by what you've been looking at, how recent the
   file is, or how often a stem occurs.
- ○ **Phrases and near-words**: search is per stem.  There's no multi-word phrase match and no "did you mean".

### 1.2 STRING — hits tied together into a line of thought

A search answers once.  A string is what you keep: hits you've walked through, tied into a trail you can come back to,
 hand to someone, or prove.

- ✅ **The rope**: the cave's stack of steps (search › file › method › …), shown as the head's label; Escape climbs it.
   But it's a single path that goes away when you go back to rest.
- ✅ **Errands**: the Aside / Clerkdesk keeps *why* you went somewhere, by day (`Lagoon_errands`; `Clerkdesk_todo.md`),
   and marks visits whose target has gone (`gone:1`) without hiding them.
- ✅ **Pins**: a hit can be pinned into the rail at the right of the code.
- ○ **A string as a thing**: a named, ordered set of hits (`path:line` + the words that found it) that persists as a Waft
   (`What` > `Doc` > `Point` is already that shape), re-opens where you left it, and survives the code moving (re-found
    by its words when its line drifts).  The rope, the errands and the pins are three partial versions of this; **the
     feature is to make them one**, not to add a fourth.
- ○ **Strings that prove**: a string whose last knot is a sworn sentence in a Book — "this claim is tested here".
   `Lagoon_unproven` already knows which claims nothing swears.

### 1.3 GROUP — hits gathered up into groups of relevance

A hundred hits is a list; ten groups is a map.  Grouping is what makes "every mention" usable.

- ✅ **Families**: hits gather into stem families (methods sharing a stem, `Lagoon_families` / `Lagoon_cave_families`);
   at rest, the code's families stand around the hole.
- ✅ **Areas**: Waft:Everything's areas (`Lagoon_cave_areas`): one group per area of the program.
- ✅ **Files and folders, regions and sections**: the natural containers, which the glass already draws as places.
- ○ **Relevance groups**: hits clustered by how they relate, not where they sit.  By the call graph (hits that call each
   other belong together), by co-mention (docs that name the same three methods), and by the join (code that ran in the
    same Book).  Every input is already held: Atlas edges, Atlas links, Electrode flows.  **A group is a reader's
     answer, never a stored copy** (§2).
- ○ **Groups you can name**: promote a relevance group to a string (§1.2), so a cluster you found becomes a thing you keep.

## 2. The concept line — Atlas KEEPS; everything else ASKS

Ruled 2026-09-08.  Atlas has one concept: the compiler's own index of every doc, kept fresh.  For any feature, ask:
 *does it change what is HELD, or does it ask a question OF what is held?*  Finding, stringing and grouping all ASK.  So
  they live in Lagoon or in readers of their own, never in Atlas.  The tell that this is slipping: a smell given a
   *mitigation* instead of a *home*.  One generator maps code for the editor and the census alike: `Lang_map_into`
    (`src/lib/O/lang/compile.ts`, which contains NUL bytes, so use `grep -a`).

## 3. What stands

| piece | where | notes |
|---|---|---|
| the room | `src/lib/L/BigWordland.svelte`, `/BigWordland` | the H\*\* switcher, ⌐Lies, ▦ sprawl, the pin rail, the cave over all |
| its Book | `src/lib/L/Hackarium.svelte` | stands Atlas + Lagoon itself; `role:hacker` (`?E=` still boots the old `Educarium` editor) |
| the cave | `Ghost/L/Lagoon.g` THE CAVE + `Ghost/V/Vyto.g`/`Vytui.svelte` | search › file › method › area › watch; Book `LagoonCave` |
| the census | `Ghost/L/Atlas.g` | every doc's `%Map`; Book `AtlasStaple` |
| the readers | `Ghost/L/Lagoon.g` | seek, callers, mentions, families, beads, lint, rot, errands, join; Book `LagoonStaple`; `Lagoon_todo.md` |
| the word index | Stemdex + `Lies_search` (`LiesFunk.svelte`) | separate from Atlas, settled; `Stemdex_todo.md` |
| the tap | `Ghost/L/Electrode.g` | both ends of every call; **parked until Atheory** (`Electrode_todo.md`) |
| the index Waft | `vite.config.ts` digePlugin → `wormhole/Docindex/toc.snap`; `src/lib/server/watch.ts` | §5 |
| controls | `verbs_<Ghost>()`, `Ghost/L/Workshop.g`, `Ghost/Play/` | `Verbs_todo.md`; Book `WorkshopStaple` |
| the desk | `src/lib/L/Clerkdesk.svelte` | `Clerkdesk_todo.md` |
| the Waft tree | `src/lib/O/ui/Waft.svelte` (shared with Editron) | its own C sticks at the top, with a path-in breadcrumb under it |

L ghosts are not in the spine manifest: a runner gets them with `runner_ask ghost_load Ghost/L/X.g`, a reload drops
 them, and a Book's `*Testing.g` must be loaded too or the Book runs hollow.  Truth goes in particles and caches in `.c`.
  Never mint a particle per call or per line.  Bulky pictures are `dontSnap`.  No timers.

## 4. Wordland and Atheory — the fusion

Atheory (`Atheory_todo.md`) is the rebuild of how code loads onto Housing.  Wordland is where that rebuild becomes
 visible, and the two already share their irritations:
- **Load lists**: L ghosts sit outside `CREDULER_GHOSTS` and arrive by `ghost_load` or `Lies_ghost_include`, which is
   the "random lists" disease in miniature.  A declared A\*\* manifest is the cure, and Wordland is the room that would
    show it (which ghosts are loaded where, as particles).
- **Variants**: `TheA_<Name>_<Variant>_<dige>`, where an electroded build is the first variant.  The parked tap waits on
   this, and so does line-level tracing for teaching the program's flow.
- **The focus twin** (`Focus_todo.md`): "whoever is active" wrests the write seat.  Who is active is the attention
   authority's answer, so the seat and the focus coordinator should be built as one thing.
- **Not relying on itself**: when Atheory's headless compiler exists, it, not any tab, holds the compile authority
   (`Editron.md` §8.2 B).

## 5. The index the watcher writes (was `Docindex_todo`)

The dev server already watches the tree, so its plugin writes `wormhole/Docindex/toc.snap`: `%Doc:<path>,dige,mtime,size`
 for about 730 docs.  It is a Waft, and a tab opens it like any Waft.  Built on it:
- **The roster**: `Atlas_index_read`, with no walk and 0 reads paid (`IndexRoster.spec.ts`).
- **The SuperMap**: the census is one snap, decoded once (passes 12–21 → 1–2), and adopted only if the dige still matches.
- **The push**: `control:docindex` on rewrite (about 450ms from touch to heard).
- **The watch desk**: `watch.ts`, interest per socket and path, `control:changed` (`relay-test.ts`).
- **Waft retake**: a Waft that moved on disk is re-placed in one `place()`, so an armed `%Interest` survives (Book `HohoRetake`).

**Bombs:**
- The dige gate is the safety: weaken it and a stale Map serves silently.
- Only live-spine tabs hear pushes; Editron, on `pinned_stable/`, doesn't until it's re-pinned.
- Quote pass counts, never one wall clock.
- If a part seems missing, it's probably `C`/`Waft`/`Seem`/`Repli`/`req` under another name.  Three bespoke transports
   were built and retired learning that.

The destination, deliberately last: a Seem that *maintains* the Map across edits.  Which spans to re-run is a graph
 question, and the graph is already held.

**Opening a doc is not slow** (≈0.6–1.0s, measured).  The waits had two causes, both fixed:
- the room's clock was never handed back (`Story_release_clock`; a room Book must release it);
- the disk queue was queue-wide (`Wormhole_park` now runs per path, reads first).

## 6. Verify

```
node scripts/runner_ask.mjs ping --player=<code-room pub>               # role:"hacker"
node scripts/runner_ask.mjs ghost_load Ghost/L/LagoonTesting.g --runner=<addr>   # then run LagoonCave — via the Sonnet subagent
GFILES="Ghost/L/X.g" npx vitest run --config scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts   # then esbuild-parse the .go
```

History:
- `history/Wordland_todo_2026-09.md` has the 2026-09-08 overview: the measurements, the two pictures and the join, five
   UX stories, the first order of work, and the naming questions.  **Older `Wordland_todo §N` citations point there.**
- `history/Docindex_todo.md` has the index's full build log and the doc-open hunt.
