# Tend — the land's one substance

`Tend` is a **placeholder name** (attend + care for + lean toward; and one tends land). Rename while
 it is still cheap — that is the whole reason the vocabulary is particles.

The land is `L/`. Today it holds two files: `BigWordland.svelte` (the room) and `Educarium.svelte`
 (its editor Book). This doc is the design for what stands beside them.

Distilled 2026-09-05 from a long design conversation. The scratchpad sketches
 (`Tend.g` / `Tendation.g` / `Tendland.svelte`) are **superseded by §9 here** — they carried the
  `aim` fault §4 removes.

---

## 0. What to get on with next

- **Stand `Ghost/L/`** — a `gen/L/` beside it and a `GFILES` entry (`scripts/LocalGen.spec.ts:23`).
   Pure plumbing, but it does not exist yet.
- **Get `TendSeed` green on a REAL runner** (`/Otro ?B=TendSeed`). That is the first thing this whole
   thread would have *proven* rather than argued. Never headless `Story_cli`; never the BigWordland
    room (it boots `role:'word'` ⇒ a humdinger, never a dispatch target).
- **Decide the open choices in §11** — the name, the object mainkey, the `day` stamp.
- **Do NOT yet**: write anything outside the tree (no file writes — this cut is derivations only),
   mount CodeMirror, or touch a line of `O/`.

The arc, in one sentence: **the bet, finally pointed at the work of building it** — code, docs, LLM
 threads and proofs all one legible living matter, held where you can see it, prove it, and rewrite
  it while it runs.

---

## 1. Where this came from, so it is not re-litigated

Three frontiers (Seem/Voro, Vyto, a focused editor) collapsed into one thing when the human named
 the missing pole. The machine already had *"the way it is"* (origin). It had no word for **the way
  it should be** — the centre you dwell in, that things are accorded into.

- **periphery** — everything as found: files, docs, a peer's copy, an LLM's proposal.
- **dwelling** — the one seat. Not a viewport on the periphery; the place accord happens.
- **order** — Mundo's tree. To *accord* is to give a thing its one particle at its right shelf.
- **qua** — a C\*\* offered as a version of another C\*\*. Not a lens: a rival reality with a claim.
- **accord / discord** — the decision, and the state where the order moved under the candidate.
- **unfoldment** — nothing exists before it is attended, and only at the grain attended.

`aufheben` was exact and is already in the boot layer (`BigQualand.svelte.ts`): accord **cancels** the
 candidate as a separate thing, **preserves** it in the canonical, **lifts** it into the order.

---

## 2. The one substance

One shelf. A `%Tend` is many:1 on both axes, so its **holding is under the subject** and it points at
 its object with `of:` — the `%Spin,of:X` idiom, and `Ra_home_self`/`Ra_home_them` (`Ra.g:674`,`:682`)
  is the existing precedent for keying a shelf by whose it is.

```
w:Tend
  %Mine,pub:<me>
    %Tend,of:<obj tok>,qua:<q>     kind grain state reason? by? other? when?
      %Offer,derivation|proposal   (c.C = the candidate C**)
  %Theirs,pub:<them>
    %Tend,…                        someone else's attention — visible, never reshaping my field
  %Obj,<tok>                       the field node (a stand-in when truth is outside)
    %Sec,<tok>#<slug>              minted only by an unfold
  %Qua,… %Kind,… %Grain,…          the vocabulary, as rows (§4)
```

**Four axes**, and they are genuinely different, not one dimmer:

| axis | what it says | values |
|---|---|---|
| **kind** | what the subject is doing | glance · hold · work · receive · watch · settled |
| **qua** | in what capacity the object is taken | text · cites · thread · … |
| **arity** | how many objects | one · two (`other:`) · many |
| **grain** | how finely | whole · section · point · word |

`kind` maps onto the req machine's own lifetimes — glance/transient, hold/permanent, watch/eternal.
 The seam is already cut in `O/`: `Ting`/`GhostList` are LE-**less** Interests (attention with no
  candidate); `Trail`/`Aside`/`Sidetrack` bear one (`LangCurse.svelte:75`).

**subject vs by.** A subject is a **key-holder** (me, a pier pub, an LLM peer — the Claude CLI already
 joins as a signed cluster peer, `LiesLies.svelte:479`). A wire holds no key, so it is never a subject:
  it is the **mechanism**, recorded in `by`. A wire is *delegated attention*, and the diary reads
   *"me, by wire:cites, accorded X"* — accountability on the key, mechanism named.

---

## 3. Unfoldment is the rule that keeps it small

Nothing is derived ahead of being looked at. A doc at whole-grain is **one particle**; sections exist
 after the first unfold, points after the second, words after the third. The tree stays the size of
  your attention — which is the size that snaps cleanly.

Same rule for the field itself: **a node is in the field iff something attends to it.** Follow a cite
 → a tend is minted → the node appears. Let go → it fades. There is no add/remove API because there is
  no maintained membership.

---

## 4. The no-aim law  ⟵ the correction, 2026-09-05

The first sketch had `Tend_tend(w, aim)` with `aim = { tok, qua, kind, grain, subject, by, other }`.
 **That was a second substrate** — the one thing the bet forbids ("there is no second substrate hiding
  in a class hierarchy or an ad-hoc store"). Every field of it was either a C that already existed or
   a vocabulary word.

> **No JS object literal may carry vocabulary.** A word that carries behaviour becomes a **particle
>  row**; a pure enum with no per-value behaviour stays a scalar. Local accumulators are fine.

So the aim dies, and with it every lookup literal (`{whole:'section',…}`, `pose_of`, `rank`). The
 vocabulary is minted at plan time exactly the way `Vyto_board` mints its organs and bar words
  (`Vyto.g:63-85`) — *"so the vocabulary is VISIBLE before any cell is ever drawn"* and *"gets worn in
   while it is still cheap to rename."*

```
Tend_words(w):
    w.oai({ Qua: 'text',    sort: 'derivation', face: 'Text',   grain_max: 'word' })
    w.oai({ Qua: 'cites',   sort: 'derivation', face: 'Cites',  auto_safe: 1 })
    w.oai({ Qua: 'thread',  sort: 'proposal',   face: 'Thread' })
    w.oai({ Kind: 'glance',  lifetime: 'transient' })
    w.oai({ Kind: 'hold',    lifetime: 'permanent' })
    w.oai({ Kind: 'work',    lifetime: 'permanent', candidate: 'proposal' })
    w.oai({ Kind: 'receive', lifetime: 'permanent', candidate: 'proposal' })
    w.oai({ Kind: 'watch',   lifetime: 'eternal',   candidate: 'derivation' })
    w.oai({ Kind: 'settled', lifetime: 'past' })
    w.oai({ Grain: 'whole',   rank: '0', next: 'section' })
    w.oai({ Grain: 'section', rank: '1', next: 'point', pose: 'small' })
    w.oai({ Grain: 'point',   rank: '2', next: 'word',  pose: 'big' })
    w.oai({ Grain: 'word',    rank: '3',                pose: 'stretched' })
```

Two payoffs. Adding a qua is **minting a row, not editing a switch**. And the vocabulary is *in the
 field* — you can fall into `%Qua,cites` and see what it does. The land describes itself in its own
  matter.

(`sort` is the candidate's direction, §6. `auto_safe` is what makes the auto-accord knob principled
 rather than arbitrary — see §6.)

---

## 5. Five readings, nothing stored

The field, the terrain, what is owed, the wiring and the diary are five `o()` walks over the one
 shelf. There is no second structure to keep in step, so there is no sync code anywhere — which is
  where the ugliness in a five-feature system always lives.

| reading | query | is |
|---|---|---|
| **field** | by `of:` , kind ≠ settled | which nodes exist |
| **terrain** (squish) | by deepest grain + kind | `c.pose` per object; `%Flow` per two-object tend |
| **owed** | `state:'open'` | the accord queue |
| **wiring** | `kind:'watch'` | the dataflows |
| **diary** | `kind:'settled'`, by `when` | the day |

**Grain is a conserved budget** — that is *why* the field squishes rather than zooms. Fall into a word
 and everything else must coarsen. `VytoFold` already implements exactly this ladder ("budget scales,
  roomy stays OPEN, least-dominant folds first, focus path shielded, coherence floor"), and `HEAT_BUY`
   (`Vyto.g:35`) already made attention a spendable currency in the glass. Grain names it model-side.

The terrain reading needs **no glass change**: stamp `c.pose` per object (Vyto reads it per source —
 `VytoOrchestra`), and write a `%Flow` for a two-object tend so the foam pulls the pair adjacent
  (`VytoBunch` proves joined kin rest at 234 vs severed at 247). **A comparison physically brings its
   two objects together.**

**The diary is a sort order, not a log** — and, weighted by grain, it is a *spend*: where the attention
 went. `when` is the monotonic **yore** counter (the Spool's clock), never wall time, so fixtures are
  byte-stable across run dates. Retention has a precedent too: `VytoFreeze` — green trims to cap, a
   failure freezes every evidence moment. Exactly what a good diary does.

---

## 6. Two laws, and the two sorts of candidate

**Law 1 — refusals snap.** Verified 2026-09-04: across fourteen accept-like mechanisms in the
 codebase, *every* refusal is off-snap. `U%unaccepted` lives on `C.c.U` where `Seem_toString:1398`
  states it must never reach `.sc`; the D-sphere is `r()`-replaced whole on every `o_Seem` walk
   (`LangHold:985`), so the vote is written on a surface that gets wiped. `mirror.c.breach`,
    `ra_missed`, `ra_no_idspace` — all `.c`. Only Story's Accept reaches disk.

> The machine snaps what it accepted and forgets what it refused.

Against *"if it matters, it snaps"* that is a verdict. A forgotten refusal is re-offered forever — the
 exact failure a peer's version or an LLM's suggestion hits on day one. And **a refusal carries its
  reason or it is not a decision** (the rebuff precedent, `Swarm.g:2811`). Three of the five readings
   depend on this law.

**Law 2 — identity is declared, not inferred.** A tok is minted by whoever mints the object
 (`file:<path>`, `file:<path>#<slug>`), never derived from content. `resolve()` pairs by unambiguity
  scoring; infer identity from heading text and a rename reads as goner+neu, duplicates go ambiguous,
   and every re-parse churns the whole field — the diary fills with phantom births, the squish
    flickers. `c.vyto_tok` (`Vyto.g:336`) is the existing escape hatch and the precedent.

**Two sorts of candidate**, and they are not symmetric:

- **proposal** — wants to *become* the canonical. Candidate → canonical. Accord = replace.
- **derivation** — computed *from* the canonical. Canonical → candidate. Cannot disagree; can only be
   stale. Accord = bless as current.

This is why auto-accord is principled: derivations carry no opinion and may land themselves;
 proposals must always be able to ask. Wires make derivations; people and peers make proposals.

**And "reference or copy" was the wrong question** — it is *where truth lives*. For a doc, the disk
 file is truth and the tree holds a derivation; accord re-blesses, and writing back is a separate,
  heavier act. For a `%Grant` or a Story step, truth is in the tree and accord replaces in place. It
   is a property of the node's sort, not a global choice — and the first cut is deliberately the
    regime with **no write-back at all**.

---

## 7. Why not LE, why not Repli

Both were scouted in full 2026-09-04. Recorded here so nobody re-opens it.

**Shared, and worth keeping:** LE and Repli both stand a `Selection` and bottom out in the *same*
 `resolve()` pairing (`Stuff.svelte.ts:1097`); both hit the `est_D_T` footgun and dodge it the same
  way; both independently chose to omit `resolve_strict`. `Repli_design.md:15` says outright Repli
   *should* be rewritten onto LE's `i_Seem`/`o_Seem`. **Use `Selection`/`resolve()` — that part is
    twice-validated.**

**Why not reuse LE itself:** `LE_encode_compare → Seem_toString → enWaft` (`LangHold:1421`) and
 `enWaft` **faults on any mainkey outside `%What`/`%Doc`/`%Point`**. It runs every tick of
  `req_understanding` and inside `LE_push`'s gate — so a foreign-mainkey aim gives not a crash but a
   *silent* corruption of the accord gate (`changey` latches wrong, `%push_dirty` flaps). Also: the
    clone extent is hard-coded depth-1 in two independent places (`LangHold:942`, `:1034`). A new
     substance snaps its own way and holds any mainkey.

**Why not reuse Repli:** it has no candidate at all. Arriving foreign data goes straight into the live
 `%Theirs` shelf (`Repli_recv_lines:1163` → `Repli_merge:356`); `%Sent_Tree` holds counters, not
  content; and its soundness rests on a **sole-writer axiom** (`Repli.g:311`) that makes "whose version
   wins" definitionally unaskable. **Repli is missing the qua** — and `Repli_design.md:232-268` is
    literally a written request for LE's D→U sphere stitch, blocked on an unmade ruling.

Note also: LE has **no Book** (only Svelte rigs — `test/Understandium.svelte`, `Understandication.svelte`)
 while Repli has eleven. If these ever converge that asymmetry is a debt.

---

## 8. The test this design keeps passing

**It has not required a single change to `O/`.** Everything it needs already exists: `Selection`/
 `resolve()`, Vyto's `pose`/`%Flow`/fold-budget/`grapples`/`vyto_tok`, `presence`, the req lifetimes,
  and `?E=` booting. Five passes of design and the `O/` surface held. That is the strongest available
   evidence that the "O is rounding out" reading is real.

**The layering rule:** `L/` depends on the ground (`TheC`, `Selection`, `House`) and on Vyto as a
 *reader*. Never on Lies or Lang. And the substance must stand **without** Vyto, so a Book can swear
  it on a runner — the glass is a reading, not its home.

---

## 9. The shape

`Ghost/L/Tend.g` — sketch. Everything is a C; there is no parameter bag. `obj` and `subject` are
 particles; the words are read off their rows.

```
// attend — find-or-create under the subject, pointing at the object
Tend_tend(w, subject, obj, qua, kind):
    let t = subject.oai({ Tend: obj.sc.Obj, qua: qua })
    if (!t.sc.kind)  { t.sc.kind  = kind ?? 'glance' }
    if (!t.sc.grain) { t.sc.grain = 'whole' }
    return t

// unfold — one grain step; the parse is minted HERE, one level, only now
Tend_unfold(w, t):
    let g = w.o({ Grain: t.sc.grain })[0]
    if (!g || !g.sc.next) { return t }
    t.sc.grain = g.sc.next
    this.Tend_parse_level(w, t.sc.Tend, g.sc.next)
    return t

// the two decisions — BOTH snap; a refusal without a reason is not a decision
Tend_accord(w, subject, t):
    t.sc.state = 'accorded'
    this.Tend_settle(w, t)

Tend_refuse(w, subject, t, reason):
    if (!reason) { return w.i({ rebuff: 'a refusal without a reason is not a decision' }) }
    t.sc.state  = 'refused'
    t.sc.reason = reason
    this.Tend_settle(w, t)

Tend_settle(w, t):
    w.c.yore = (w.c.yore ?? 0) + 1
    t.sc.kind = 'settled'
    t.sc.when = '' + w.c.yore          // string — a bare number wildcards in a query

// a wire is a tend that mints tends.  by names the mechanism; subject stays the wirer.
Tend_wire(w, subject, from, to, qua):
    let t = this.Tend_tend(w, subject, to, qua, 'watch')
    t.sc.watch = from.sc.Obj
    t.sc.by    = 'wire:' + from.sc.Obj
    if (w.o({ Qua: qua })[0]?.sc.auto_safe) { t.sc.auto = 1 }
    return t

// the drive — one pass over the watches.  No closures: the .g compiler parse-storms on them.
Tend_stir(w, subject):
    for (const t of subject.o({ Tend: 1, kind: 'watch' })) {
        let src = w.o({ Obj: t.sc.watch })[0]
        if (!src) { continue }
        if (t.c.saw === src.version) { continue }
        t.c.saw = src.version
        this.Tend_offer(w, t, 'derivation', this.Tend_derive(w, src, t.sc.qua))
        if (t.sc.auto) { this.Tend_accord(w, subject, t) }
    }

// terrain — pose read off the Grain row, never a JS map
Tend_terrain(w, subject):
    for (const obj of w.o({ Obj: 1 })) {
        let deepest = this.Tend_deepest(w, subject, obj)
        let pose = w.o({ Grain: deepest })[0]?.sc.pose
        if (pose) { obj.c.pose = pose } else { delete obj.c.pose }
    }
```

Braced both arms everywhere — the `.g` dialect refuses braceless `if/else` across lines.

---

## 10. How it gets proven

`Ghost/L/Tendation.g` — Book **`TendSeed`**, the `VytoStaple` beat-dispatch mould, seven beats,
 read-only, derivations only:

1. seed five docs as declared-tok objects (fixed text in the Book — byte-stable on any runner)
2. glance at all five → the field unfolds to exactly five
3. wire `text→cites` with `auto_safe` + stir → offered **and** accorded, `subject:me by:wire:…`
4. fall into a word (three unfolds) → one belly; the others stay unposed
5. refuse a proposal without a reason → rebuffed; then with one → snaps with its reason
6. re-parse unchanged text → **nothing new is minted** (Law 2)
7. the diary holds exactly the settles, in yore order

Each assertion is a `%see:'sentence'` — no commas (the peel parser splits on them; use an em-dash).
 Run it `/Otro ?B=TendSeed` on a **live runner**, several times (a race shows as flip-flopping
  `ok_pct`; robustly green across N is the gate). Never `Story_cli` — its greens are a bubble.

`src/lib/L/Tendland.svelte` — the room's sibling recipe, booted `?E=Tendland`. **BigWordland does not
 change.** It stands `A:Tend`/`w:Tend`, seeds from real spec docs, wires `text→cites`, and commissions
  Vyto over the field's objects via `Vyto_commission_on`. It is the human surface, never a proof — the
   room is a humdinger.

**Seed graph** (richest links, per the 2026-09-03 census): `Radio_todo.md` (16 wikilinks / 69
 `file:line` / 174 mentions), `Daemon_todo.md`, `Download_stall_handover.md`, `Mag_todo.md`, and
  `Vyto_todo.md` — the glass looking at its own spec. Hub files they share: `Ra.g Heist.g Swarm.g
   Repli.g Peeroleum.g Radio.g` (Swarm/Radio read-only — another agent's live files).
 Free edges nobody reads yet: source files already cite memory-raw slugs **in comments**
  (`HaulFace.svelte:129`, `LiesLies.svelte:1079`, `Heistation.g` ×12). `[[slug]]` → `memory-raw/<slug>.md`
   resolves exactly (name ≡ stem, 205 files, 192 with onward links). No wikilink parser exists anywhere;
    nearest hook is `LiesFunk.svelte:1485`, whose `is_md` indexer already walks lines with numbers.

---

## 11. Open choices — the human's, not the model's

- **The name.** `Tend` is a placeholder. So are `%Obj`, `%Offer`, `%Qua`/`%Kind`/`%Grain`.
- **The object mainkey.** `%Doc` is taken (Waft). Verify whatever replaces `%Obj` is **unclaimed
   fleet-wide** before minting (the `Rig|Cog` discipline).
- **`day`.** `when` is yore and stable; a human diary also wants a date, and a date churns a fixture.
   Left to the caller so a Book can pin it — a wrinkle, not a solution.
- **Grain steps.** Four named structural rungs, chosen over a continuum because a continuous grain
   would be a stringified float that churns the snap every time the foam settles. Continuous lives in
    the render only.

## 12. Debts named now, so they are not surprises

- `Tend_parse_level` beyond sections needs a real tokenizer **and collision rules** — two identical
   headings collide on `#slug` today. This is where `resolve()` earns its place.
- Five readings as linear `o()` scans are right at hundreds of tends; tens of thousands wants an index.
   Vyto's mirror is the same shape at the same scale, so the cliff is known and far.
- Truth-outside **writes** are entirely absent by design. The day a proposal accords onto a file,
   `Tend_accord` grows a push-outside branch (`Lies_source_write` is the precedent, deliberately not
    reached for here).
- A wire that mints a tend that fires a wire is a **loop** with no guard yet. Cheapest guard: a wire
   never fires within its own stir.
