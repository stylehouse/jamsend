# AtheoryNexus_todo.md — the open concepts, in one place, as few as they reduce to

*Started 2026-11-01 from the owner's overnight read of the threads ("keep it all well rounded and aware of what's proto and how").
 Atheory's record of what is BUILT stays `Atheory_design.md` (and its ledger §2); the order of the main works stays THE MAP
  (`Atheory_todo.md` §0.0).  This doc holds what is still a CONCEPT, reduced over four rounds with the owner (2026-11-01/02): each
   thread says what it is, what is ruled, and the lean.  When a thread is built it leaves here for `Atheory_design.md`; when it is
    parked it leaves for the doc named.  Older lists it gathers: `Atheory_design.md` §1.15 "Remaining conceptualisations" and §3
     "Where it's heading".*

## 0. What to get on with next

**The next build is THE MAP item 4, the scheduler for real (§3.5):** step 1, Theory's scheduler off names, is BUILT (2026-11-02, Book
 `AthePondTwoClocks`); step 2, the run loop in `beliefs()` (`%TheAAttend:run`, `TheA_attend_runs`, `TheA_poke`), is BUILT
 (2026-11-02, Book `AthePondAttend`).  Tidy DONE (one R3 resolver — `_A_near(from, name, opts)`, Theory `TheA_nearest` calls it; `TheA_near` → `TheA_seek_out`), Aip's identity half BUILT (the resolve() veto, Book `AthePondIdentity`).  **Next: Aip itself (§3.10) — RULED `A.c.Aip`** (owner 2026-11-02: "it's just to have a unique id for all the A … yeah to A.c.Aip"): claimed in tree order, never snapped, so no Book re-records; re-claimed identically after a reload when the tree is the same.  Then DECISION A (§6) — give a
  real compartment the mark — the first duty racked onto Atheory beyond the ponds.  The rounds below were thinking, not a change of course.
*Side thread, any time, static:* IOexpr's code-graph (§3.3) — one `%ioing,input|output,mainkey,via` word per IO site on Atlas's
 `%Map` (ruled 2026-11-02, IOexpr_todo §0), so the editor relates the `i` end and the `o` end of a piece of data by a query.

## 1. How real each part is

| how real | what | so |
|---|---|---|
| **Foundation** (keep; a ledger row per change) | As in As by mark (`%TheABelieves`); addressing R1–R3 (`_A_near`, `e.c.to_A`, `A.c.up` = holder); code kept aside + `TheA_as`; `ghost_versions`, CodePush; Ground loading; the Atime ring | built to last |
| **Working proto** (real, thin — grows when a use asks) | StoryFu in a Desk: the leash (ready · step · red), Storica's hand, `Desk_reset`; the sabotage Book; Stuffica views | more debugger controls (run to N, rerun with a variant, break on an oath) whenever we actually need them — not before |
| **Toy, proven by hand** | the scheduler: `TheA_run`, move, batch, boundary, Turn, synapse, tape, hold (`%TheAWait`), tendrils | runs on ponds, Books and `/Pondland` only — **Housing doesn't run it**.  The main open edge (§3.5) |
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

### 3.5 The scheduler for real — THE NEXT BUILD
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

### 3.10 Aip — every standing A has a name of its own
*Owner 2026-11-02:* "perhaps we should have a Dip for the A that exist?  maybe call it Aip.  this idea has seemed important to it in
 past conceptualisings … I've been inventing the A in waves for a long time now."
- **The want.**  A name is what you SAY (R3 finds the nearest A called it); a ref is what you HOLD (R2, identity, dies with the tab).
   Neither can be written down and read back: `Aw` (`Desk/Story/Story`) is long and says nothing when two of a name stand, and a
    tendril address (`Clock_A/Athe_Clock/Turn3`) points at whichever `Clock_A` comes first.  An **Aip** is the third thing: a short
     label for one standing A, unique in its House, stable while it stands, that a snap, a trace, a tape or a person can carry.
- **The shape: a Dip, claimed the way Stuffica's points claim theirs** (Theory `TheA_dip`, Hovercraft `Dip_assign`): an
   `%Aip:<label>` row on the A, its label a slot claimed from the nearest holder that keeps a counter — the House, or an A that
    holds As.  Never reused, so a dropped A's label can't turn up on a stranger.  Lean label: the A's name, plus `_<n>` only when its
     name is already taken under that holder (`Clock_A`, `Clock_A_2`) — a reader sees the name, and the number only when it matters.
- **It IS a Dip** (*owner 2026-11-02:* "is Aip not exactly Dip, as in eg 1.1.4.6 for the first H/H's fourth /A and sixth /A?") — yes:
   the value is the slot path (`Dip_assign`'s shape, `<parent>_<i>`), `1.1.4.6` = the first H, its first H, its fourth A, that A's
    sixth A.  The path IS the identity; the name is printed beside it for reading (`1.1.4.6 Clock_A`) and is never part of it.  (The
     `Mundo/Story_2/Pond_P/Clock_A` above was the same path read by names.)
- **Identity only — no resemblance.**  Se's `resolve()` pairs a new D with an old one by what their particles look like, and a Dip on
   a D rides that pairing (`resume_X`) — so two `A:Clock_A` side by side could swap Aips.  *Owner:* "Se must never resolve() an A to
    another A and resume its Aip there … needs a compare-objects override, and do no reductionist logic at all."  So: **the Aip lives
     on the A itself** — *ruled 2026-11-02: on `A.c.Aip`, never snapped* ("it's just to have a unique id for all the A"), not on a walk's D; the holder keeps the counter; a walk only READS it.
      Where beliefs()'s Se does pair H|A|w levels, it pairs by the particle object (`D.c.n === n`), never by sc.  A dropped and
       re-stood A is a new A with a new Aip.
- **BUILT 2026-11-02 — the identity half:** `Stuff.resolve()` takes `q.resolve_veto`; `Selection.process` passes `Se_veto_A_H` by default
   (`Se.c.resolve_veto` overrides, `false` = none).  Book `AthePondIdentity`: a lookalike A gets a fresh D, its sibling goes on; veto off,
    the lookalike takes the old D.  The Aip row itself is next.
- **Snap cost:** an `%Aip` row on every A changes every Book's snaps; fold it out of `snap_H` (as `dontSnap` does) and let a Book
   that wants it opt in.
- **What it replaces:**
  - `e%Aw` — stamped as the target's Aip (one word, not a path);
  - the tendril address — `<Aip>/<w>/Turn<n>` — so `TheA_at` (and `TheA_io`, `TheA_tape`) look up the label, never the first A of a
     name;
  - the board's places and a Stuffica point's key for an A — the same label.
- **It is stamped once, when the A stands** (`attend`, `TheA_stand`, `Desk`).  Lookup is a map on the holder (`c.aips`), rebuilt
   from the rows after a reload, since the rows are snapped.  Whether it survives a reload is the open part: as rows it does, so a
    Book's tape can name a compartment across `Desk_reset` only if the reset re-stands the same labels — or the era tells the reader
     it's another A of the same label.
- **Ties (owner):** "a tie is likely some warn|error situation.  Ground should advise if not to warn perhaps."  Two As of one name
   equally near the asker: warn by default (now); a Ground may advise per name — `%TieIs:error` refuses, `%TieIs:fine` stays quiet — the
    way it plants `%lematch` qualities.  With Aips, a name that ties can always be said exactly.
- **H and w carry one too** (*owner 2026-11-02:* "H is basically a type of A, and w a type of A, very loosely … actually having storage
   is via H").  One scheme for every standing thing: an H's Aip is claimed under the House above it, an A's under its holder, a w's
    under its A (and is just its name, since two w of one name in an A is rare).  Then an Aip **path** — `Mundo/Story_2/Pond_P/Clock_A` —
     is unique everywhere and says where the thing's storage lives (the H in it), and a label alone is unique under its holder.
- **Not yet:** the slot scheme across Houses (an Aip unique per House is enough while Houses are the seam); Aips across the network
   (§3.11).

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
