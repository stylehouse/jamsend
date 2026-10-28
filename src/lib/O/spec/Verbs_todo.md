# Verbs_todo — the terminal: every system reachable from one room, its controls pluggable and self-documenting

> *"this whole organism… needs to gather itself together. I think having separate scripts is bad design, and we want
>  some way to make all systems reachable from a terminal such as BigWordland"* — and, sharpened: *"my terminal I mean
>   the whole /BigWordland or editor instance of access to the repo, relay, and basically vite server all at once"* —
>    *"LiesFunk's op table — this is a ghastly shaped bit of code… LiesFunk is an important client of smaller bits of
>     pluggable code"* — *"having different terminals own various domains, routing writes to them. sounds good"* —
>      *"get creative and deliver what you think kids will get productive with in a week. so we need to establish some
>       place where we can build and observe a creation."*  — the owner, 2026-10-08/09

A **working `_todo`**, opened 2026-10-09.  Homethink §4 already named the disease: *"a one-off script where a Book
 should be — a stranger doing the town's work."*

---

## 0. What to get on with next

**Landed 2026-10-28 — verbs enter in Atime, and only flock members may ask.**
- `Verb_run` runs a verb's body inside `H.UItime` (the beliefs mutex): both callers — the relay's `runner_ask` and BigWordland's
   hole — forked off the inbound drain (`void`) or a keypress, so past their first await they read and wrote particles mid-tick.  `runner_ask run` (lease check, stamp,
    the drive's first stretch) and `poke` enter the same way.  Cost: a long verb (`atlas_refresh`, `everything`) now holds the tab
     for its disk walk — **next, split them**: read the disk outside, then `UItime` only to apply.
- **Received, then the answer.**  A CLI that sends `ask.acks` hears `runner_ack,phase:received` at once; the relay keeps the corr
   open; `runner_ask.mjs` then waits `RUNNER_ASK_WORK_MS` (10 min) instead of reading silence as dead and re-sending.  `ask.once`
    (stable across insisting re-sends) makes a re-send JOIN the in-flight one.  Live: received+final on da060 (the join path is
     not yet exercised by a slow op).  A tab on older code just doesn't send `received` — the CLI falls back.
- **The ask gate** (`relay.ts`): with cluster trust configured, `runner_ask` from a socket that never hello'd with a key in
   `CLUSTER_TRUSTED_PUBS` is refused (as a `runner_ack,ok:false,refused`).  `scripts/relay_hello.mjs` signs that hello with the
    claude key; runner_ask · reactap · story_repl · runner_shot call it.  `RELAY_ASK_CHECK=enforce|log|off`.  Note: a tab's own
     hello is self-signed by its identity, not a flock key — so the seat (`seat:editor`) still admits any hello'd socket.
- **Holes a fork found (2026-10-28):** `poke` and a slow verb now hold Atime across their own network|disk awaits (the
   split is the fix); a **runner_ask over the r2r bridge** (`routeFromPeer`) skips the ask gate (trusted link); the **seat** admits
    any self-signed hello, so a stranger can take a free `seat:editor` and hold the editor's saves back (owed, not lost) — gate
     `take` on something stronger than a tab key (a crew row, or refuse seat asks arriving through Caddy); **ActionButton clicks**
      (`Actions.svelte` → `a.sc.fn?.()`) run off Atime too.
- **TODO — really sign in the dev Chrome tabs.**  A tab's hello is self-signed by its own identity, so the relay can't tell your
   tabs from a stranger's.  A dev tab could read the flock key (`.env.cluster-editor`) through its FSA grant on the repo and hello
    with it — then it IS trusted, seat and asks alike.  Cost: the key sits in that browser's memory; fine for a dev box.  Until then:
     the seat allowlist (below in LiesLang §11).
- **TODO — ActionButtons through Atime, forward-escaping** (no instance changes): `Actions.svelte`'s `fire()` runs `a.sc.fn` inside
   `H.UItime`; an action MAY carry `method:` + args instead of a closure, and `fire()` elvises it — old `fn` buttons keep working.
    Watch: Pause/Stop must stay instant while a long step holds Atime (set the flag, then elvis).  Buttons, verbs and Points stay
     three things; they align by method name where they meet.
- **Owed:** a verb arrives as a named `%Verb` elvis carrying `by:<prepub>` (proven per command, not just per socket), so the
   board and tendrils see it; writing verbs gated on proof + the seat instead of `role === 'hacker'`; the rest of the op chain
    (`release`, `ghost_load --stand`, `tidy`, `crew`) entering through UItime as it moves into verbs.

**The arc**, each slice compiled, Book-gated where it can be, and left in the tree for the owner:
1. ✅ this doc + the inventory (§3).
2. ✅ **The registry** — `verbs_<Ghost>()` (§2), LiesFunk tries it before its chain; `verbs` lists them (`runner_ask verbs`).
3. ✅ **First family moved** — Atlas · Lagoon · Electrode left the chain (≈120 lines) for their own ghosts; the CLI answers
    unchanged, proven live on da060 (atlas_callers · atlas_refresh · lagoon families · electrode top; an unloaded owner says so).
    **Two traps met on the way, both now guarded in `Verbs_all`:** the `.g` compiler makes any method holding an `await` —
     even inside an arrow — `async`, so a `verbs_*` must be a plain DECLARATION TABLE whose `run`s call ordinary methods; and
      the registry is consulted on EVERY op, so one odd `verbs_*` returning a non-array once broke even `ping` on a runner —
       a non-array (or a Promise, with a warning naming the cause) is now skipped, and a registry fault falls back to the chain.
4. ✅ **The hole speaks verbs** — `:` lists the registered verbs as spine (what each does · its args · its owner and where it
    runs — the controls documented, out of the code itself); `:verb args` + Enter runs it through `Verb_run` (the one gate the
     relay dispatch shares) and answers as spine; an item naming a doc opens its method's place.  Proven headless: `:verbs`,
      `:lagoon families`, `:nonsense` (a named Error), `:make Pond` refused in the hacker room.
5. ✅ **`:everything`** — the program map is ONE source with TWO hosts: `src/lib/L/everything.js` holds the authored map
    and the coverage/validate/emit logic; `scripts/wafts_everything.mjs` is now a thin FLOOR host (node + fs, no tab), and the
     `everything_check` (read-only, any room) / `everything` (writes — editor terminal) verbs are the TERMINAL host (Atlas's
      census for the file list, the repo nav for text and writes).  Proven: both hosts count 191 of 415 with no problems, and
       the runner's `everything` wrote 9 tocs byte-identical to the floor's.  Lining the two up found two real faults — the hosts
        skipped different archives (Atlas's census skips `shelved/`; now the shared rule does too) and the floor accepted a Book
         directory with no `toc.snap` (`GhoghoDrone`, a retired Book's husk — now both require the toc, and it left the map).
6. ✅ **The Workshop** (§5) — `Ghost/L/Workshop.g` (`:play` · `:watch <Name>` · `:make <Name>`) and the starter creation
    `Ghost/Play/Garden.g`; watched live in the hole (seeds sprout, flower, grow petals, drop seeds, wilt); **Book
     `WorkshopStaple` 6/6 ok_pct 1 caveat 0 ×2, 7 sworn** (undeclared — the owner's).  What is still owed is in §5.

## 1. The terminal, and the law

**A terminal is a tab holding all three powers**: the REPO (Atlas's nav — read/write/dir/bin through the granted
 folder), the CLUSTER (its relay socket, a seat and a role), the DEV SERVER (`/__atlas/dige`, `/__gen/dige`, the docindex
  push, HMR, the served `gen/`).  Nearly everything `scripts/` does, a terminal can do.  What it cannot: spawn a process
   (git, ffmpeg, npm, chromium) — those stay **the floor** (§3.4), or become a short list of dev-server endpoints the way
    `/__atlas/dige` already is.

**THE LAW: terminals own domains, and a write is routed to the terminal that owns it.**  It is already built once, for
 the repo: a runner holds no folder, so its file ops (`read`, `write`, `bin_*`…) ride `wormhole_req` to the EDITOR, which
  checks the presented grant and runs them against its own nav (`RemoteWormholeNav` → `Lies_wormhole_req_recv`).  Every
   other write follows that shape: the verb names its owner, a terminal that is not the owner forwards it (or refuses by
    name), and only the owner touches the thing.  Reads run wherever the census stands.

**Roles stay honest without a new mechanism**: a verb that `writes` is refused by name in a HACKER room (Hackarium is
 read-only by construction — that is why it can open beside a working editor) and in a music page; it runs in an
  EDITOR-seat room (`/BigWordland?E=…`), or is routed to one.

## 2. The shape of a verb — pluggable, owned, self-describing

```
verbs_Lagoon() → [
  { name: 'lagoon', desc: 'the reader layer — seek beads defs families mentions rot rotwork callers lint join figurines errands oaths',
    args: 'verb [name] [--k=N]', where: 'terminal', writes: 0,
    run: async (w, ask) => { … return result } },
  …
]
```
- **Owned**: the ghost whose subject it is declares it (Story's verbs live with Story, Lagoon's with Lagoon).  `eatfunc`
   already merges every ghost's methods onto the House, so the registry is simply *the `verbs_*` methods the House has*
    — nothing to enrol, no manifest; a ghost that loads brings its verbs, one that is not loaded has none, and says so.
- **LiesFunk shrinks to transport**: receive · find the verb · gate (role, `writes`, the music-page read-only rule) ·
   run · reply.  The chain stays as the fallback while families move; a registered verb wins.
- **Self-documenting**: `verbs` (an op, and soon a `:verbs` in the hole) lists every registered verb with its `desc`,
   `args`, `where`, `writes`.  `runner_ask` asks the tab instead of keeping its own copy (today the op list lives in three
    places: `OPS` and `PLAYER_OPS` in runner_ask.mjs and the dispatch itself — a drift source).

## 3. The inventory

### 3.1 The ops — 51, in two dispatchers, by the ghost that should own them
| owner | ops | where |
|---|---|---|
| **the repo** (editor serves runners, grant-gated — `Lies_wormhole_req_recv`) | read · bin · read_range · list · write · bin_write · bin_append · bin_open · bin_chunk · bin_close · bin_abort | editor |
| **Story** | run · release · retain · accept · declare · state · steps · snap · diff · snaps · trace · assertions · rungos | runner |
| **the glass** (Cyto/Vyto) | shot · why · svg · face · drag | runner |
| **the tab itself** (Lies) | ping · probe · reload · ghost_load · pick · console · socklog · dump · reactap | any |
| **the land** (Atlas · Lagoon · Electrode · Stemdex) | atlas_callers · atlas_refresh · atlas_lint · lagoon · electrode · stemdex | terminal |
| **the world** (introspection) | minisnap · world · supervisor · census | any |
| **the swarm** | crew · tidy | player |
| **the music** | poke (an allowlist of human-pressable radio verbs) | player |

### 3.2 Scripts that are clients of the organism → become (or already are) verbs
`runner_ask` · `runner_shot` · `runner_eye` · `runner_watch` · `story_repl` · `story_accept` · `story_late` · `tab_watch` ·
 `tracelog` · `trace_gaps` · `door_census` · `arrival_eye`.  Most of their work already happens in a tab; the script is a
  remote control.  They stay as thin clients of the registry for when no room is open.

### 3.3 Scripts that re-derive what the land already knows → become terminal verbs
`wafts_everything` (regex-parses defs while Atlas holds the real grammar) · `vyto_search_sample` (greps what Lagoon
 answers) · `vyto_code_sketch` · `glass_sketch` · `atlas_bench` · `perf_ab`.  These are the stranger doing the town's work.

### 3.4 The floor — stays outside, deliberately
`ghost_compile` · `LocalGen` · `compile` · `FlockCompile`/`GhostCompile` · `Story_cli*` (the headless boot — never a
 verification, CLAUDE.md) · the daemon · relay tests · `chrome` / `pw_drive` · `telegram`.  **A law, not an afterthought:**
  if the room is the only door and the room wedges, there are no tools — the floor must stay sufficient to recover alone.

### 3.5 Proofs below the town — fine where they are
~30 vitest specs of pure modules (`VytoFoldLadder`, `VytoPile`, `MapEncode`, `SectResolve`…).  A few integration specs
 (`TwoFounder`, `MultiHeist`, `ReachTerminal`) are arguably Books in disguise — later.

## 4. The hole speaks verbs

BigWordland's cave is always on screen; its head is a text box.  A leading `:` turns a search into a verb: `:verbs`,
 `:lagoon lint`, `:everything`.  The answer is spine — the verb's result rows as vertebrae and ribs — and a result that
  is really text (`steps`, a lint list) reads as a transcript vertebra.  The same registry the CLI asks.

## 5. The Workshop — a place to build and observe a creation

*"get creative and deliver what you think kids will get productive with in a week."*  The machine already holds the
 three halves of a workshop and has never put them in one room:
- **make** — Lies compiles a dock into a running ghost, live, no reboot (the renovation guild, Homethink §2);
- **see** — the glass draws any world's particles as they change (a Vyto commission can grapple a REAL world, not only
   guises — Sounditron's belly is exactly that);
- **prove** — a Book swears what the creation did, in sentences.
So: a **creation** is a small ghost under `Ghost/Play/` with one world.  The Workshop stands it in the room, the glass
 grapples its world and draws it live, and editing the ghost recompiles and the creature changes in front of you.  A kid's
  week: copy the starter, change one rule, watch the creature change, write one sentence that proves it.

### 5.1 How it works (the as-built, 2026-10-09)
- **`:play`** — the creations, off Atlas's census of `Ghost/Play/`; press one to watch it.
- **`:watch Garden`** — includes the ghost (the include door Hackarium uses for Atlas/Lagoon), stands `A:Garden/w:Garden`
   on the ROOM (the cave's `face_on`), and the cave's **watch level** projects the live world: each top-level particle a
    vertebra named by kind + value and coloured by kind, its children ribs.  BigWordland re-asks twice a second; the sowing's
     signature skips still beats.
- **A creation needs a HEART.**  A room ticks only on its ambient clock (seconds apart — and not at all on a room whose run
   left it parked; measured: the Garden stood and never stepped).  `Workshop_heart` gives a WATCHED creation a targeted
    think every 300ms, addressed by its `A/w` path, and stops itself the moment the cave stops watching it.  Trap met: a world
     minted by `oai` off a House has no `c.up` chain, so a REF target cannot find its House — address by path.
- **`:make Pond`** — WRITES (editor terminal only): the starter, renamed throughout, written through the repo nav and compiled
   by `Lies_provide_dock(…, { force_compile })` (the same dock-involved compile the CLI's ghost_compile ticket ends in).
    **Unverified live** — every room I can stand is a hacker room; it needs the owner's editor.
- **The proof** — `WorkshopStaple` steps the garden BY HAND with its clock frozen between steps: the first recording caught the
   Run House ticking the creation on its own between beats (one stray step shifted every snapshot).  A kid's own creation Book
    copies that shape.
- **A watched kind change is a leave + an arrive** (tok = kind + value): Garden makes a NEW particle when a seed sprouts; a
   value-only tok tried to morph it and Vyto's mirror kept the old row's first key (the label read the dose).

- **Two starters, two ideas.**  `Garden.g` — rules over time (a seed sprouts, flowers, drops a seed, wilts).  `Pond.g` — rules
   that MEET (fish lay eggs, a heron comes when the pond is full, eats two a step, leaves when it is thin — the fish rise and fall
    and the heron comes and goes, nobody wrote "go up and down").  Its numbers were TUNED in a simulation before the file was
     written: the first draft flat-lined at the crowding cap with a heron that never left — a flat line is not a lesson.

### 5.2 Owed / next
- `:make` walked live in an editor room; then a kid's loop: `:make Pond` → edit → compile → watch it change.
- Creation Books as a one-liner (`:prove Garden`?) — the WorkshopStaple shape, generated.
- More starters (a band — music is the main spring; a crowd; a weather), each one idea a kid can read in a minute.

## 6. Open — the owner's
- Routing a write from a hacker room to the editor terminal (§1's law) vs simply refusing it there — v1 refuses by name.
- Text answers in the glass: a transcript vertebra, or a text pane beside the glass.
- Which room is the Workshop's home — a third chip in BigWordland, or its own route.
