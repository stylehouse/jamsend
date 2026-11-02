# AtheoryNexus_todo.md — the open concepts, in one place, as few as they reduce to

*Started 2026-11-01 from the owner's overnight read of the threads ("keep it all well rounded and aware of what's proto and how").
 Atheory's record of what is BUILT stays `Atheory_design.md` (and its ledger §2); the order of the main works stays THE MAP
  (`Atheory_todo.md` §0.0).  This doc holds what is still a CONCEPT, reduced over four rounds with the owner (2026-11-01/02): each
   thread says what it is, what is ruled, and the lean.  When a thread is built it leaves here for `Atheory_design.md`; when it is
    parked it leaves for the doc named.  Older lists it gathers: `Atheory_design.md` §1.15 "Remaining conceptualisations" and §3
     "Where it's heading".*

## 0. What to get on with next

**Built 2026-11-02** (THE MAP item 4, the scheduler for real, §3.5): Theory's scheduler addresses As, not names (`AthePondTwoClocks`);
 the run loop in `beliefs()` — an A marked `%TheAAttend:run` has its As moved by pulse (`AthePondAttend`); one R3 resolver
  (`Housing._A_near` with opts; `TheA_nearest` calls it); `TheA_near` renamed `TheA_seek_out`; an A or H is its object — `resolve()`'s
   veto (`AthePondIdentity`).  Ledger rows in `Atheory_design.md` §2.

**Evening 2026-11-02 — read this first.**
- **Aip BUILT** (§3.10): `Housing.Aip_claim` → `n.c.Aip` (Dip path, never reused, never snapped); `attend` and Theory `TheA_tree`
   claim; `TheA_by`/`TheA_aip`/`TheA_say`; `TheA_at`/`TheA_io`/`TheA_tape`/`TheA_refs` take an A, an Aip or a name.  Book
    `AthePondAip` accepted, green ×3; AthePond* + AtheStoryInStory/Walk swept green.  Left: `e%Aw` → Aip (Housing's elvis path).
- **One attention mark BUILT, recorded, NOT yet swept** (§3.2): Housing `attends(n)` — `%TheAAttend:think` (= `%TheABelieves`, still
   read) all four legs; `%TheAAttend:run` = findable + watched.  Book `AthePondAttendMark` accepted (3 oaths).
- **Storica's strip pocket — BROKEN, fixture deleted.**  Ground.g `Desk_pick` stands `A:Desk/A:Hand(%TheAAttend:run)/A:Strip/w:Desk_Strip`
   and pokes it; `Desk_Strip_woken` keeps `%Picked:n` and elvises `story_sel` to the inner Story.  Storica's `pick` calls `Desk_pick`
    first.  **Live: the pulses land and are never moved** (the recorded 003.snap showed both `TheAPulse,open_at` still waiting; 0
     oaths — the agent accepted it anyway; deleted).  Suspect: the Desk's sub-House never runs `TheA_attend_runs` (its beliefs
      run on a non-think e, or it never thinks after `TheA_poke`'s `feebly_ponder`).  Owner's live clicks then showed steps 1+2
       "failed" in Storica (§3.12).  Storica's `Desk_pick` call is COMMENTED OUT (live clicks take the old
        `story_sel` road again); FIRST fix the Desk House's run leg, re-record AtheStoryPick (its Credence row stands), then re-enable.
- **Hollow runs were a missing `Stands:CoreTesting`**, not stale code: a new Book's toc is born without it, so no runner loads
   AtheTesting.g for it (my `--swap` advice was a misdiagnosis; the swap only loaded it by hand).  Added to the 8 Books since
    AthePondNear.  AtheStoryPick's toc must get it when re-recorded.  Want: StoryFu inferring a missing Stands from the Credence
     row's ghost, so a new Book can't forget it.
- **A hollow first run saves itself (bug, 2026-11-02 night).**  AtheStoryPick dispatched with no toc and no Stands ran one empty
   step (its method never loaded) and wrote a 1-step toc + 001.snap — a blank Book, silently.  A new-mode run whose Book method
    is absent should refuse to save (and say so), not record nothing as the truth.  Its dir is now a bare toc with `Stands:CoreTesting`.
- **ReactiveWaft kept**: the only guard on the gated-vs-ungated read that once tore down KeepFace for weeks (subagent stopped
   short of deleting).  Re-record its fixtures, don't delete — owner to confirm.

**Next, in order:**
1. **Aip on `A.c.Aip`** (§3.10, ruled) — a Dip-path id claimed when an A stands, never snapped.  Then the by-name readers
    (`TheA_at`, `TheA_io`, `TheA_tape`, tendril addresses) look up by it — the tendril-printing Books re-record.
2. **One attention mark** (§3.2) — `%TheAAttend:think` (= today's `%TheABelieves`: thought, pumped, findable, watched) and
    `%TheAAttend:run` (findable + watched only).
3. **Storica's step strip, the first run-loop duty** (§6 DECISION A, ruled) — a click is one arrival through the door (Stuffica's
    "Out"), a pulse on the strip's compartment; the views commit after the run.

*Open for the owner:* §6 DECISION B (what a turf lease names).  *Side thread, any time:* IOexpr's `%ioing` rows (§3.3).
*Tooling:* `scripts/runner_sweep.mjs` runs Books one line each, skipping Credence's `unusual:` rows.  A new Book needs `Stands:<Ground>` in its toc (memory new-book-hollow-first-runs).

## 1. How real each part is

| how real | what | so |
|---|---|---|
| **Foundation** (keep; a ledger row per change) | As in As by mark (`%TheABelieves`); addressing R1–R3 (`_A_near` — the one resolver, `e.c.to_A`, `A.c.up` = holder); an A or H is its object (`resolve()` veto); code kept aside + `TheA_as`; `ghost_versions`, CodePush; Ground loading; the Atime ring | built to last |
| **Working proto** (real, thin — grows when a use asks) | StoryFu in a Desk: the leash (ready · step · red), Storica's hand, `Desk_reset`; the sabotage Book; Stuffica views | more debugger controls (run to N, rerun with a variant, break on an oath) whenever we actually need them — not before |
| **Toy, proven by hand** | the scheduler: `TheA_run`, move, batch, boundary, Turn, synapse, tape, hold (`%TheAWait`), tendrils | runs on ponds, Books and `/Pondland` — and, since 2026-11-02, inside `beliefs()` for any A marked `%TheAAttend:run` (no real duty marked yet: §0 item 3) |
| **Sketch** | the door, IO as compartments, `%J`, `@name`, spheres beyond Trace/Regard, turfs, the Believer, migrations riding code | words |
| **Tax** (paid while the old generation lives) | two Storys (every Story fix twice); everything.js; `%InnerRun`; a `Self_round` Entcase in every nested Book | ends when everything moves into the new tube-ways (§3.1) |

## 2. Words, pinned

- **compartment** — an addressable chunk of the belief-scape: an A's w today (`A:K_P/w:Athe_Tank`).  It has an address (R3 finds it
   by name, a ref reaches it by handle) and holds rows.  *Owner 2026-11-02:* w stays the compartment — "a nice round piece of work";
    an A is a more flexible container that divides space more incidentally, and may stand inside a w.
- **seam** — the edge between two compartments.  News crosses a seam only as a **pulse** (sent on an axon, landed at the boundary on
   a synapse that hears it).  A write that stays inside a compartment crosses no seam.
- **move** — one compartment's go: it eats its inbox, writes only its own rows, sends only into its outbox (`TheA_move`).
- **Turn** — the RECORD of one synapse's part in a move: what it ate (`%TheAAte`), the code it ran under, rows new and gone
   (`%TheANeu`, `%TheAGoner`), what it sent (`%TheASent`).  So **a write inside a move is not a Turn of its own — it is a Neu or Goner
    on the move's Turn.**
- **version** (of a compartment) — `(era, n)`: n counts its moves (the Turn number); era is its birth, or the code era, so a count
   compared across a reload or a `Desk_reset` reads as "everything changed", never "nothing did".  *Ruled 2026-11-02.*  (Not Stuff's
    `C.version`: that bumps on every C at every level and doesn't roll up.)
- **tendril** — the thread between two events: **back** is a pulse's `from:` (the address of the move that sent it, or `/Heard<n>`
   from outside); **forward** is the `%TheAAte` rows that name you (`TheA_led_to`).  Two particles on a Turn, opt-in per House
    (`%TheATendrils`), kept only while a `%TheAReader` follows them.  Built 2026-10-28 (Book `AthePondTendril`; the board on
     `/Pondland`).  Why: "event after event can be traced back or forward … consistent eventing" (owner).
- **elvis vs pulse** — an elvis is sender-addressed ("you, do this"); a pulse is receiver-declared (the synapse says whom it hears).
   Housing runs on elvises; Theory on pulses.  The door (§3.4) is where an elvis from outside becomes a Heard pulse.
- **loop** — a compartment with an axon: its beats are pulses, and to want its attention is to hear it.  `think` (Housing's walk),
   a clock, the door, a Story step, `TheA_run`'s rounds are all loops (§3.2).

**One shape at every zoom.**  Pass ⊂ move ⊂ batch ⊂ round ⊂ era; Sunpit ⊂ J ⊂ A\*\* ⊂ House ⊂ tab ⊂ flock.  The owner (2026-11-02):
 the spreading of words for one shape is the thing to watch.  The reduction: one kind seen at different magnifications, told apart
  by qualities (hosted more than once, attends which loop, declares its API), not species.

## 3. The threads

### 3.1 The tube-ways — everything moves into the new fabric
*Ruled (owner 2026-11-01): "everything has to move within the new tube-ways."*  The Desk becomes the page (`/Desk?B=`), the spine
 becomes `Ground/Runner`, everything.js is sublated, Story.svelte/Otro/Auto retire once StoryFu has their greens.  THE MAP item 1.
  Mostly porting, but it is what ends the tax in §1.  Waits on: Lies (the relay seat) standable by a Ground.

### 3.2 Attention — each level says which loop it wants
*Ruled (owner 2026-11-01/02):* every level asks for attention by a mark; depth stops meaning anything.  **Absent means the `think`
 loop** — today's default, so every Book keeps working.  Other loops are named.  An A that names another loop is that loop's; an
  A\*\* pond is `TheA_run`'s.  Then the ponds and the Housing walk are one tree with several drivers, and the scheduler-in-beliefs is
   one more loop on it.
- *Shape (lean):* `%TheAAttend:<loop>` on the A; `%TheABelieves` becomes "my As attend my loop".
- **What `%TheABelieves` bundles today** (Housing, read 2026-11-02) — four things, and a loop mark must say which it carries:
  1. **thought** — organise/attend walk into the A's As and call their w's method each tick (`get_next_levels`);
  2. **pumped** — the req sweep tugs their reqs (`reqdo_sweep`);
  3. **findable** — `_A_near` walks into them, so a name from outside reaches them;
  4. **watched** — their w's `%watched` channels enrol for the UI (`enroll_watched`).
  The run mark (`%TheAAttend:run`, built) takes **none** of them today.  Lean: a run-marked A's As are **findable** and **watched**
   (an address and a screen need them), never **thought** or **pumped** (that is the think loop's; a run-loop A's reqs wake by pulse,
    §3.5 "reqs woken by pulse").  So the unified mark is `%TheAAttend:think` = all four (today's believing), `%TheAAttend:run` = 3+4.
- **The door, clocks, time and Story's steps are one thing** (owner: "indeed") — loops, each named by `@` (§3.9).

### 3.3 IO — boring `i|o`, reactive `S`, the two ends related
*Owner 2026-11-01:* "we have non-reactive i|o, and more plausibly reactive S i|o … something that meaningful not in the code is
 fundamentally discordant."
- **`i %X` stays boring** — `w.i({X:…})`, no runtime cost.  Inside a move it is a Neu on the Turn.
- **`S` is how an IOexpr is reactive, and what it reacts to is written in it** (*ruled 2026-11-02*): a `@name` mentioned in an `S`
   expression is a loose reference to another thing's version that should notify this one — the expression's `@`s ARE its watch
    list.  `S o @Clock/%Tick` reads and subscribes.  The compiler knows every `@` statically, so Atlas can draw the wire and check it
     (each `@` resolves; the `S` sits where a Sunpit may home, §3.8).  Svelte's runes track reads at runtime; here it is lexical, so
      an editor and an LLM see it without running anything.  (Syntax beyond that — play with it once the basics roll.)
- **Tendrils, extended: declared sensitivity against observed** (owner: "tendrils … extended to doing the inter-IO sensitivity").
   A tendril is OBSERVED — what a Turn ate, from whom.  An `S` expression's `@`s are the same thread DECLARED — "this read wakes on
    that"; at runtime the declaration stands a synapse and the Ates say whether it fired.  Three views of one wire, each checking the
     others: **static** (Atlas: this line reads X, made by those lines), **declared** (the `@`s), **observed** (the tendril).  A read
      that keeps seeing changes with no declaration = missing reactivity; a declaration never eaten = dead.  That is the dialectic an
       LLM can contribute inside: propose a declaration, and the three views agree or show where they don't.
- **The i end and the o end, related in the editor** — code-graph knowing.  Atlas's `%Map` has make rows (`%mint`, `%probe`, m16);
   missing are READ rows (raw `.o({` is 3080 sites) and the per-mainkey join (the shape census, IOexpr_todo §3–4).  The side thread
    in §0.

### 3.4 The door — one shape for every arrival
Every arrival (a frame, a key, a click, a verb, a timer, a `runner_ask`) is one shape `{what, by, from, corr, at}`, through the
 inbound batcher (which exists: Tribunal → `Lies_deliver_soon`), into a compartment as a taped `TheA_io` pulse.  Replay, audit,
  security and Story read one tape.  A click is one of these — Storica's hand calls `Desk_leash_on` directly today because the Desk
   is driven by Housing, not the scheduler.  THE MAP item 3; design `Atheory_design.md` §3 "The patch".
- **Writes into someone else's compartment become sends** (*ruled 2026-11-02: yes, eventually*).  Today a Book's drive writes
   `%DeskLeash` onto `w:Desk` and Storica writes `%StoryLeash` onto the inner w.  The rule: you send the compartment something and it
    changes itself; a click is one more sender; **turf** (a region someone holds the right to write — `seat:editor` on the relay is the
     one built) is checked on the send, in one place.

### 3.5 The scheduler for real — steps 1 and 2 BUILT 2026-11-02
`TheA_run` inside `beliefs()` for a believed tree first (the Desk); unwatched work costs nothing; reqs woken by pulse; every call
 through its A.  THE MAP item 4.  Its ground is laid: addressing R1–R3 (2026-10-30, Housing's elvis side).  **Step 1 — the same in
 Theory — BUILT 2026-11-02** (`Atheory_design.md` §1.15, Book `AthePondTwoClocks`; tendril addresses, `TheA_io` and `TheA_tape`
  still read by name).  What it was: a synapse hears `from:` when `synapse.sc.from === A.sc.A` — any
  A of that name anywhere in the House (`TheA_boundary`); `TheA_run`'s ready set and `TheA_boundary(names)` are sets of names, so two
   As of one name (a Story in a Story, two ponds each with a `Clock_A`) are one to the scheduler.  So: the ready set and the batch
    become As (refs), names accepted only at the edge and resolved once; a synapse's `from:` binds to the NEAREST A of that name from
     the synapse's own A (up through its holders, then down — R3's walk over the A\*\* tree), kept on `synapse.c`.  Proof: a pond Book —
      two ponds each holding a `Clock_A` and a tank; each tank hears only its own pond's clock (today each hears both).  **Step 2 — BUILT 2026-11-02** (Book `AthePondAttend`; Housing ledger row):
       an A marked `%TheAAttend:run`, found through believing As, has its As run by the House's own think whenever one has a pulse waiting
        (`TheA_attend_runs`, scoped `TheA_run`, `TheA_poke`); `beliefs()` is the abdomen the duties get racked in.  Was: `TheA_run` inside `beliefs()` for the Desk — shaped by §3.2.  Writes from the `think` loop stay gapped (no Turn, no pulse) — fine: we are moving into the new fabric,
   not bridging the old one (owner 2026-11-02).

### 3.6 Toc rows are programmatic; advice about a Book goes in Credence
*Ruled (owner 2026-11-01):* the declared sabotage **stays** in `wormhole/Story/AthePondRounds/toc.snap` — `AtheStorySabotage` reads
 it off the inner Story's The.  The rule: **a toc row is something a run reads; a note about a Book that no run reads goes in
  Credence**, as a child of its `Funkcion:Storying,of_Book:…` row.  The hand sabotages S1–S6 (`Atheory_design.md` §1.10) become toc
   rows when a Book runs them.

### 3.7 Addressing — built; one habit left
R1 holding, R2 refs, R3 nearness are built (`Atheory_design.md` §1.15, Book `AthePondNear`).  R4 — names only at a boundary (the
 wire, a toc, a Credence row, a person typing) — is a habit: a string `i_elvisto` becomes a ref the day a second one of its target
  stands.

### 3.8 `%J` — a hostable organism, its Sunpits its API
*Owner 2026-11-01:* "Sunpits should kinda hoist out of their context, as closures, so one blob of code can define some
 ExoticObject() it abstracts, and the Sunpit create an API of sorts to play with that object … register that whole thing as some
  named hostable computation … most like the %w methods, how they're the nexus of reality for that topic … Sunpit couples to our
   A|w|J things, rather than appearing in random lower level methods.  It implies more of a stately organism."  And: "%J is like a
    more particular, clearly named A, which we might end up modelling everything as, in the large."
- **J is an A that has said what it is** — *ruled 2026-11-02: a quality on A first* (one tree walk, one resolver, one ledger; a
   mainkey only if reading snaps shows it needs one).  Its code declares its rows and its Sunpits; it has a name a reader recognises;
    it can be hosted more than once.  A bare A is a J that hasn't said yet.
- **Its Sunpits are its API**: each an `S` read (what it watches, §3.3) with a body.  You reach a J by poking one; a Sunpit with a
   known watch list can be dispatched to directly, without waking a whole method.
- **Homed.**  Plain `i|o` sits anywhere, in any helper; a Sunpit belongs to an A, w or J — so it can be addressed, watched, moved and
   replayed.  "Coherent rules about when it'll be homed to what" (owner): a Sunpit homes to the nearest A|w|J enclosing its
    definition; an `S` outside one is an error Atlas reports.
- **Reqs.**  A Sunpit could be an eternal req on its J whose wake is its synapses — the req machine keeps doing, the Sunpit says
   when.  To test, not assume.
- *First build (when it's time):* a toy J on a pond — one kind, two instances on one tank, one Sunpit each, poked directly; a Book
   swears only the poked instance moved.

### 3.9 One tree for names and attention
*Owner 2026-11-01:* "the recursive name-space and attention-space are very similar … one also wants to look for some data anywhere
 above, or in some @namething that we resolve at editortime … runtime looking for names is likely ok, but has to be fast … maybe some
  loops should be accessible via @namething, which brings attention from that time|loop into those S i|o expressions."
- **They are one tree.**  Names are found by walking it (R3, nearness from the asker); attention flows down it (§3.2).
- **`@name`** — a reference in code to the nearest thing called name.  Lean: **check at editor time** (against what the Grounds
   declare stands where), **bind at stand time** (R3 once, when the A|w|J holding the code is stood; a ref on `.c`), **re-bind when the
    tree under the binding changes** (an A stood or dropped).  R3's cost goes to stand time; a call costs a property read.  `@` is free
     in stho (reserved as a Sigil; only `$` is used).
- **`@Loop` in an `S` expression** brings that loop's attention to the line: `S o @Clock/%Tick` wakes on the nearest Clock's beats.

### 3.10 Aip — every standing A has an id of its own
*Owner 2026-11-02:* "perhaps we should have a Dip for the A that exist?  maybe call it Aip … I've been inventing the A in waves for a long
 time now."  Then: "it's just to have a unique id for all the A … yeah to A.c.Aip."
- **The want.**  A name is what you SAY (R3 finds the nearest A called it); a ref is what you HOLD (R2, dies with the tab).  Neither can be
   written down and read back exactly: `Aw` (`Desk/Story/Story`) is long and says nothing when two of a name stand; a tendril address
    (`Clock_A/Athe_Clock/Turn3`) points at whichever `Clock_A` comes first.  An Aip is a short id for one standing A.
- **RULED — it is a Dip, on `A.c.Aip`, never snapped.**  The value is the slot path (`Dip_assign`'s shape): `1.1.4.6` = the first H, its
   first H, its fourth A, that A's sixth A.  The holder (House or A) keeps the slot counter on its `.c`; never reused, so a dropped A's id
    can't turn up on a stranger.  The name is printed beside it for reading (`1.1.4.6 Clock_A`) and is never part of it.  Not in any
     snap, so no Book re-records for it; after a reload the tree re-stands in the same order and the ids come out the same.
- **H and w carry one too** (owner: "H is basically a type of A, and w a type of A, very loosely … having storage is via H") — one
   scheme for every standing thing; an Aip path says where the thing's storage lives (the H in it).
- **Identity, not resemblance — BUILT 2026-11-02.**  Se's `resolve()` paired a new D with an old one by what their particles look like,
   so a lookalike A could inherit another's D (and anything riding it).  Owner: "a total negation if !==, if %A or %H."  Now
    `Stuff.resolve()` takes `q.resolve_veto`; `Selection.process` passes `Se_veto_A_H` by default (`Se.c.resolve_veto` overrides, `false`
     = none); a w keeps resemblance (agency_officing re-adds the same w objects).  Book `AthePondIdentity`.
- **What it replaces (next):** `e%Aw` stamped as the target's Aip; tendril addresses `<Aip>/<w>/Turn<n>` — so `TheA_at`, `TheA_io`,
   `TheA_tape` look up the id, never the first A of a name; a board's places and a Stuffica point's key for an A.
- **Ties (owner):** "a tie is likely some warn|error situation.  Ground should advise if not to warn perhaps."  Warn by default (now); a
   Ground may advise per name — `%TieIs:error` refuses, `%TieIs:fine` stays quiet.  With Aips a tied name can always be said exactly.
- **Not yet:** ids unique across Houses beyond the path; Aips across the network (§3.11).

### 3.11 Turf — where an arrival is let in
*Owner 2026-11-02:* turf "should be where authorisation to do things is checked at the door, eg the %Grant:Music"; a synapse across the
 network "seems similar to the turf idea allowing some stuff to 'arrive' somewhere that matters."
- **One thought, three faces:** an arrival (§3.4) reaches a compartment; the door checks the turf it enters (who holds the lease, and
   whether the arrival's `by:` holds the Grant the turf asks for); a pulse to another body is the same arrival, routed to the lease's
    holder.  Today's one lease is `seat:editor` (relay.ts); the general one is `seat:<address>` — the address an Aip (§3.10).
- **Leases nest like As:** holding a compartment covers what stands in it unless something deeper is leased; who holds a thing is
   found by nearness.  A lease changing hands starts a new era of that compartment's version (§2), so readers see "everything changed".
- **Across the network:** the relay is the arbiter of record, the holder mirrors it, renews by heartbeat, writes locally while it
   holds; on a partition both sides' leases lapse, the side without it holds its sends as waits, and the tapes explain the merge.
    Authority beyond one relay is the crew's: a lease the Captain signs.  The pulse that crosses is the `%Remote` over Reach layer
     (RemoteHeist_todo) seen as a synapse — join the two rather than build a third.
- **Open for the owner:** a lease names a compartment or a whole A subtree; a relay-held lease is enough until the crew signs.

### 3.12 Stuffica's showroom — tracked, not yet a page
*Owner 2026-11-02:* "keep tracking all that … we'll rebuild those *ui at some point, when we have the core more worked out … the Editron
 has seemed quite sluggish and does want refactoring with the new model."
- **Where it is today:** `/Pondland` (every figure a view), Storica (the step strip on views, beside Storui in StoryFu), and Books
   AthePondView, Glass, Seem, Reseat.  The shape is `Atheory_design.md` "Stuffica, the shape": **Show** built; **In** (a backend pile
    swapped whole through the door) and **Out** (a click as one arrival) not.
- **`reactivity_docs.md`** is demoted, not retired: its hazards (`replace()` publishes its empty middle; the per-tick
   `agency_officing`) still bite every legacy UI — Cytui, Vytui, Langui, Editron.  When those move onto views, it goes to `history/`.
- **Owed:** a Book gating renders-per-commit; the first In/Out subject (a Book explorer, or Editron's slow paths).
- **Bug seen live (owner 2026-11-02, "Stuffica is buggy!"):** on the runner's Desk, Storica stood at step 0 (inner Story held at
   ready); a click on a step showed steps 1+2 failed.  Not yet told apart from the new click path (Ground.g `Desk_pick`, same day).
    Wants: what Storica draws for a step of a HELD Story (never run ≠ failed), checked against the old direct `story_sel`.

### 3.13 The UI arena — pieces of screen declared, then arranged
*Owner 2026-11-02:* "we need to standardise the to-UI channel … we send it some C to read stuff off, like %Languinio, but bringing the UI
 svelte component itself to some shared arena where they are all arranged … how to declare pieces of the UI and start doing some kind of
  window managing … each UI might be a tapestry of stuff with lots of layout options that might all join across with everything else on
   the screen.  the Otro list of each H with a list of their UIs, is just the basic first way."
- **Today:** a ghost puts `%UI:<Name>,component` on its House (`watched:UIs`); Otro lists each House and mounts its UIs in a column;
   what a UI reads comes on a C it is handed (`%Languinio`, a `%watched` channel).  Placement is the list's order — nobody declares more.
- **The want, in this paradigm:** a piece of UI is a declared thing — what it shows (a Stuffica view: compartment + kinds), what it
   wants of the screen (size, priority, which other pieces it sits beside), and its arrivals (clicks into the door, §3.4).  An **arena**
    holds every declared piece from every House and lays them out — first by rule, later computed — so pieces can join across Houses.
- **The channel:** the to-UI channel is the view's commit (one counter per view, Stuffica) — the arena only places components; it never
   carries data.  `%watched` channels are the legacy road (the believing bundle's 4th part, §3.2).
- *Next when it's time:* Storica as the first declared piece (it already reads only views); Otro's column as the first arena rule.
- **Pockets (owner 2026-11-02, a wild take to grow):** "perhaps some A are defined to be the interchangeable pockets that read|write
   the front|back end."  An A whose whole job is the seam: a run-loop compartment the screen pokes (clicks in, as pulses) and reads
    (its rows, as a view), and that speaks to the back end only by sending.  Interchangeable because the seam is its synapses and
     axons, not its code: swap a pocket (another layout, a test puppet, a remote screen) and nothing behind it changes.  Storica's
      `A:Strip` (§0 item 3) is the first pocket; the arena would hold pockets, not components.  Open: is a pocket a kind of A (a mark,
       `%TheAPocket`?) or just any A that a UI reads; does one pocket serve many screens (a turf question, §3.11).

## 4. Parked — moved out, with where
- **A Story's runs as a collection** → `Story_future.md` "Open / deferred".  Owner: "might be useful eventually but is Story_future."
- **A step pointing at part of attention, snapping a subset** (a whole snap still at regular intervals); **Story as a reader / a step
   as a Sunpit**; **a warnings|errors layer for StoryFu** (a cut, a spill, an ambiguous name, a hold run out — warned so Story sees
    them) → AtheoryStory_todo §2's table.  Owner: stays on the todo "until we can see it's really time to build it".
- **More debugger controls** → AtheoryStory_todo §6, built when a use asks.
- **The loopy shadow's name, `%InnerRun`'s retirement, AtheStoryCode's own Ground** → AtheoryStory_todo §0 (small).
- **Spheres beyond Trace/Regard, merge on the wire, the Believer, migrations** → Atheory_todo §0.0 "Vaguer".

## 5. Notes kept from the rounds

- **Glitch-freedom from the boundary — the diamond.**  A changes; B and C both read A; D reads B and C.  A naive push system can run D
   after B and before C — D sees the new B with the old C (a "glitch"), then runs again.  In rounds: round 1 A moves and the boundary
    lands its pulse on B and C; round 2 B and C move (neither sees the other) and the boundary lands both on D; round 3 D moves ONCE,
     seeing both new.  *Honest limit:* rounds are not a topological order — if D also reads A directly (A→D and A→B→D), D moves in
      round 2 off A and again in round 3 off B.  A Turn records what it ate, so it shows; the fix, when one is needed, is D summing
       over the run (`sum` on its synapse) or a lag.
- **Coarse versions over-wake** — a Sunpit on `@Pond/%Fish` wakes when the heron moves.  Lean: wake coarse, land fine (a Sunpit's
   find-or-create lands only real changes).  Figure it out when one over-wakes.
- **A reactive loop** (P reads @Q, Q reads @P) is handled by rounds and capped by `TheA_run`'s `most` — silently today; the cap is
   one of the malfunctions to warn (§4).

## 6. Open, for when a build needs them
- **DECISION A — which duty gets the `run` mark first** (owner 2026-11-02: "I don't know.  perhaps you can present it for me
   better").  The mark moves a compartment off the `think` loop onto pulses.  The first real one should be small, already
   pulse-shaped, and seen by a Book:
  | candidate | what moves | for | against |
  |---|---|---|---|
  | **Storica's step strip** | a click → a pulse on the strip's compartment; the views commit after the run | already Stuffica views; StoryFu's debugger hand is where clicks land wrongly today (the AtheStoryWalk bug was a click) | Storui still beside it; two Storys |
  | **the Desk's leash** | ready · step · red as pulses into A:Story | the Desk is the believed tree §3.5 named; the leash is already rows | the inner Story is legacy `think` code — the run would only carry the leash, not the steps |
  | **the Atime ring / a clock** | a timer's beat → `TheA_io` → a Host, as /Pondland does | proven shape (AthePondTape); costs nothing when idle | no user-facing gain |
  | **a verb** | `e:Verb` arrival → the owner's compartment, taped | §3.4's one arrival shape; verbs already enter through UItime | touches every `verbs_*` owner |
  *RULED 2026-11-02 (owner: "should be fine doing it in Storica"):* **Storica's step strip** first — the frontend→backend vector: a click is one arrival through the door, a pulse on the strip's compartment.  Was the lean — clicks are the IO Stuffica's "Out" movement is missing, and a click that lands on the right Story
   by pulse is exactly what addressing and identity were built for.
- **DECISION B — what a turf lease names** (§3.11).  Three shapes:
  1. **a compartment** (`seat:<Aip>/<w>`) — finest; a flock of editors can each hold one doc.  Many leases, many heartbeats.
  2. **an A subtree** (`seat:<Aip>`) — holding the A covers every w and A standing in it unless something deeper is leased (nested,
     like R3).  Fewer leases; matches "authorisation at the door" — a Grant names an A (`%Grant:Music` ≈ the Music A).
  3. **a wormhole path** (`seat:wormhole/<path>`) — what FSA writes need, independent of the A tree.
  *Lean:* **2, with 3 as the disk's own case** — the door checks the nearest leased A above the target; files keep path leases since
   the disk is not an A tree.  A relay-held lease is enough until the crew signs (then the Captain signs the lease).
- **An A inside a w** (owner 2026-11-02, §2): what it means for the walk, the address (`A/w/A/w`) and R3.
- **What a stand-time `@name` binding listens to** — the House keeping a tree version (bumped on A stand/drop), one integer compare
   per use?
- **Three ways to say "not done yet"** — a req (ttlilt, needs_work), a Sunpit (wakes on change), a `%TheAWait` (holds for an answer).
   A Sunpit as an eternal req is the test of whether they collapse to one.
