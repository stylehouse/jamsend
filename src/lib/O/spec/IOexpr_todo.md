# IOexpr_todo — where particles are made and read

**What the field is.**  An IOexpr is a `.g` line like `i %Fish:minnow`, `oa %see:'…'` or `oai %Ticks`: the sugar the stho
 grammar turns into `w.i({…})` / `w.oa({…})` / `w.oai({…})`.  Together with the raw `.o({…})` calls around it, these are the
  places where particles are **made, probed and read**.  News pumps between things at these sites, so each one is a synapse
   end, the place a tendril starts or lands.  This doc is about making those ends visible, deriving what they agree on (a
    schema nobody wrote), tracing where their results flow, and seeing what falls on the floor (`%TheASpilled`).

**The arc.**
1. Every site is a row on the Atlas `%Map`.
2. The rows yield a derived schema per mainkey, whose output is its contradictions.
3. Results are traced through variables, as conduits.
4. The editor uses all of it to style a ghost by kind, and eventually writes new code already classified (genesis,
    LiesLang_todo §11).

What falls on the floor, an unheard pulse, is an Atheory row that lives here because it is the same question asked at
 runtime: who reads what this made?

## 0. What to get on with next (smallest first)

**Landed 2026-10-28 (late), Atlas mapper m16:** items 1 and 3 below, and most of 2.  `.g` sugar `i|oai|roai %k` → `%mint,sugar,mainkey`;
 `oa %k` and raw `.oa({k` → `%probe,mainkey`; `o_elvis|o_elvis_req(w,'t')` → `%o_elvis:t`; every `%def` carries
  `kind:e|verbs|req|recipe|w|helper`; all with `via`.  Line regexes in the independent sweep (compile.ts), not tree reads yet.
   **Not done:** renaming `%elvisto` rows to `%i_elvis` (Lagoon/Electrode read `elvisto`; rename with them).  HohoFlush, Nets, Retake, Surfer, Surprise
    re-recorded for the new rows; HohoTiles re-recorded 2026-10-29 (owner-approved: new rows + stale pre-09-17 import paths) — on a WARM runner: a cold first run bakes in `log:source_write`, see `Story_hygiene_todo.md` §0 "cold entropy profile".

1. **`%mint` must see the sugar.**  `compile.ts` finds mints with a line regex over raw JS: `MINT_RE = /\.(?:i|oai)\(\{\s*([A-Z]…/`
    (`src/lib/O/lang/compile.ts` ~704).  So the `.g` sugar is invisible to Atlas: 491 `i %X` and 158 `oai %X` sites (Ghost/*.g,
     by grep), and every lowercase mainkey with them.  The stho branch already parses each IOing into legs (`Lang_compile_Leg` →
      `sc_src`).  Push a word from the tree: `%mint,mainkey` for `i`/`oai`/`roai`, and `%probe,mainkey` for `oa`.  This is an
       Atlas m9 bump.  Note: `compile.ts` holds a NUL byte, so grep it with `-a`.
2. **`%i_elvis` / `%o_elvis` rows** (the owner, 2026-10-28): name a row by the prefix, not by the argument form.
    - `ELVISTO_RE` (~703) catches only `i_elvisto`, `i_elvistwo` and `vaguely_ponder`, and nothing collects `o_elvis*` at all
       (28 `o_elvis` + 3 `o_elvis_req` sites).
    - Rows: `%i_elvis:<target method>,via:<method>` and `%o_elvis:<type>,via:<method>`, one per site.
    - A method's set is the rows whose `via` is that method.
    - Same bump as 1: `kind:` on `%def` (w|e|req|verb|helper; LiesLang_todo §11).
3. **`%TheASpilled` in Theory** (§5): a count row where `TheA_boundary` drops an unheard pulse today.  This is the smallest
    Atheory change, and Book-provable on the toy.
4. **Shape census v0.**  A read-only CLI over the Atlas `%Map` rows from 1 and 2: per mainkey, its makers, probers and readers,
    and the key sets each maker writes.  It prints contradictions only (§3).  No schema is written down yet.
5. *Later:* conduits (§4); the editor styling a ghost by `kind:` and site rows; genesis.

## 1. What exists

- **Grammar.**  `src/lib/O/lang/grammars/stho/stho.grammar` ~61:
  - `IOness`: `i o oa ob o1 oa1 bo boa bo1 boa1 drop empty`.
  - `IOness2`: `oai roai r rm`, which may carry a second path after `...`.
  - `io_tokens.ts` decides `/ , : %` by parse context.
  - A trailing `$name` **captures** (`o foo$` → `let foo = w.o({foo:1})[0]`): the variable is named at compile time, so a conduit's
     start is known.
  - `S o a/b` (Sunpit) iterates.
  - Rules: `LangCompiling.svelte` ~30–57; what an IOing becomes: `LangSolver_report.md`; the primer table: `stho_primer.md` ~42.
- **The `%Map`.**  `Lang_map_into` (`compile.ts` ~213) is the one generator, shared by the dock compile and Atlas.
  - Words: `def call region controlflow elvisto mint proves`, with `via` attributed by a post-pass ("last top-level def at or
     before this line").
  - `elvisto`, `mint` and `proves` are per-line regexes, not tree reads.
- **Share of traffic** (Ghost/*.g, grep, 2026-10-28).  The sugar appears in 22 of 46 files: 491 `i`, 277 `oa`, 158 `oai`, and almost
   no `o`.  Raw JS: 3080 `.o({`, 949 `.i({`, 386 `.oai({`, 226 `.oa({`.  **So the sugar is how things are made and probed; reading
    is raw JS.**  Every census must read both: the tsstho/JS tree has the object literals, and their keys are literal almost
     everywhere.

## 2. A site is a synapse end, not an A

The owner mused that "each one is an A".  The lean is no: an A owns compartments and state, and ~900 sugar sites plus ~4600 raw
 ones would be As with nothing of their own.  A site is an **end**: a maker sends, a reader hears.  The A is the method or w that
  hosts it, and the `via` already says which.  The Atheory picture follows from that.  A maker under `via:M` with readers under
   `via:N` is a wire M→N, the static twin of a runtime tendril (`%TheAAte,from:`).  The board can draw both, what the code SAYS
    against what it DID (Electrode is that other half for calls).

## 3. The shape census (derived, never authored first)

- **Per mainkey:** the key sets each maker writes, the leg it sits under (the receiver chain), and its makers, probers and
   readers by `via`.
- **Cardinality from the consuming form.**  The IO verb says some of it itself:
  - `oai` means exactly one, made if missing.
  - A `$` capture means the first.
  - Sunpit means many.

  On raw JS:
  - `[0]` means at most one.
  - Iterating means many.
  - An unguarded `[0].sc…` means **null-fatal** (the reader crashes when it's absent).
  - (`o1`/`oa1`/`bo1` are one-column reads, `Stuff.svelte.ts` ~419, not "exactly one".)
- **The yield is contradictions:**
  - two makers writing different key sets under one mainkey (CLAUDE.md's "two shapes under one mainkey" tell);
  - a read key no maker writes;
  - a null-fatal read with no maker that can run first;
  - a lowercase/uppercase near-twin.
- **Authored parameters come only as corrections:** `%lematch` rows on a Ground, saying `%seen`, `%kept` and `%known`
   (LiesLang_todo §12).  The census proposes, a row corrects.

## 4. Conduits (later)

A capture (`$x`) or `let x = …o(…)` names where a result goes.  Its uses inside the method are a conduit:
- a field read (`x.sc.k`);
- a pass into a call (`this.F(w, x)`, which crosses into F's param);
- a store (`w.c.x = x`, where it leaves the method).

Resolving that needs **whole-document scope from the Lezer tree**.  The per-line sweep `compile.ts` mostly runs can't do it.
 First cut: stop at the method boundary, and record only the crossing (`%conduit,var:x,into:F`).

## 5. `%TheASpilled` — a pulse nobody heard (moved here from Atheory_design §3)

- **Today:** `TheA_boundary` (`Ghost/A/Theory.g` ~491–516) lands each outbox pulse on every synapse that hears it, then
   `w.drop(box)`.  A pulse matching no hearer lands nowhere and vanishes with the box, with no row and no count.
- **Plug-hole vs error.**  A synapse nobody hears is a **plug-hole**: a declared socket, fine to leave open.  A pulse sent **into**
   one is news nobody took.  That's not an error, but it's not nothing either.
- **The row:** `%TheASpilled:<synapse>,n:` on the sender's w, counting.
  - It's snapped with the other `%TheA*` rows, so a Book sees it, and the board draws it as a dangling wire from the sender.
  - When the sender keeps Turns, the spill of that move goes on the Turn too, so a tendril reader sees what a Turn sent into
     nothing.
- **Unconditional, not under `%TheATendrils`:** it is a fact about delivery, not tracing.  Expect AthePond fixtures whose toys send
   unheard pulses to change; budget one re-record sweep.
- **Egress is the other half.**  An outlet (`%TheAOutlet:<synapse>`) is a hearer that stands for the outside, which is how a verb or
   a `runner_ask` gets answered.
  - The answer carries the asker's `corr` **on `.c`, never sc**: a corr is per-run volatile and would red every fixture (as a
     wall clock does).
  - With an outlet, a spill can mean "nobody, not even the outside".
- **Open:**
  - Does a spill ever want to fail a run (`%TheARun,spilled:`)?  The lean is no: report it, let a sworn sentence decide.
  - Should a plug-hole declare itself (`%TheASynapse:x,open:1`) so a spill into a *declared* hole reads differently from a typo?
     The lean is yes, later.
