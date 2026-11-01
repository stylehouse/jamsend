# AtheoryNexus_todo.md — the open concepts, in one place, as few as they reduce to

*Started 2026-11-01 from the owner's overnight read of the threads ("keep it all well rounded and aware of what's proto and how").
 Atheory's record of what is BUILT stays `Atheory_design.md` (and its ledger §2); the order of the main works stays THE MAP
  (`Atheory_todo.md` §0.0).  This doc holds what is still a CONCEPT, reduced over four rounds with the owner (2026-11-01/02): each
   thread says what it is, what is ruled, and the lean.  When a thread is built it leaves here for `Atheory_design.md`; when it is
    parked it leaves for the doc named.  Older lists it gathers: `Atheory_design.md` §1.15 "Remaining conceptualisations" and §3
     "Where it's heading".*

## 0. What to get on with next

**The next build is THE MAP item 4, the scheduler for real (§3.5):** step 1, Theory's scheduler off names — the ready set as As, a
 synapse's `from:` by nearness (Book: two ponds, each tank hears only its own clock); step 2, `TheA_run` inside `beliefs()` for the Desk.  The rounds below were thinking, not a change of course.
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
 Theory, whose scheduler still addresses by NAME** (read 2026-11-02): a synapse hears `from:` when `synapse.sc.from === A.sc.A` — any
  A of that name anywhere in the House (`TheA_boundary`); `TheA_run`'s ready set and `TheA_boundary(names)` are sets of names, so two
   As of one name (a Story in a Story, two ponds each with a `Clock_A`) are one to the scheduler.  So: the ready set and the batch
    become As (refs), names accepted only at the edge and resolved once; a synapse's `from:` binds to the NEAREST A of that name from
     the synapse's own A (up through its holders, then down — R3's walk over the A\*\* tree), kept on `synapse.c`.  Proof: a pond Book —
      two ponds each holding a `Clock_A` and a tank; each tank hears only its own pond's clock (today each hears both).  **Step 2:**
       `TheA_run` inside `beliefs()` for the Desk — shaped by §3.2.  Writes from the `think` loop stay gapped (no Turn, no pulse) — fine: we are moving into the new fabric,
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
- **An A inside a w** (owner 2026-11-02, §2): what it means for the walk, the address (`A/w/A/w`) and R3.
- **What a stand-time `@name` binding listens to** — the House keeping a tree version (bumped on A stand/drop), one integer compare
   per use?
- **Three ways to say "not done yet"** — a req (ttlilt, needs_work), a Sunpit (wakes on change), a `%TheAWait` (holds for an answer).
   A Sunpit as an eternal req is the test of whether they collapse to one.
