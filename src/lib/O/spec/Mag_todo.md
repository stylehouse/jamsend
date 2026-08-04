# Mag — the audio-discovery protocol (working doc)

**Status: DESIGN / todo.** The lower half (§1 on) is written to read as spec; it is not blessed
 spec yet — the human preens, then promotes to `Mag_spec.md`. The upper half is the arc and the
  next move. This doc SUPERSEDES the old §2.4 "stock stays flat, Mags only refer" ruling — see §1.

---

## 0. What to get on with next

### 0.0 RULINGS 2026-08-05 — the v1.0 simplification (the human)

Read this first; it overrides anything below it that disagrees, and several things below are now
 dead letters. The shape of the ruling is one sentence: **there is ONE Mag kind, `%Mag:shuffle`,
  and everything else was vocabulary pretending to be structure.**

- **`%Grasp` is DROPPED — remove every mention.** It was the wishlist-persist/resume coinage
   (Radio_spec §5A rung 6, re-coined 2026-07-17 from `Ray,self/Mag:marauding`) — "the chosen handful
    of remote tracks|directories". It has **zero occurrences in code**; it existed only in prose.
     A want is a `%Heist`. Resume, when it comes, resumes a Heist.
- **`%Cloud` STAYS, and is documented by its lineage: `Mag : Waft :: Cloud : What`.** The Mag was
   *based on the idea of the Waft* — that is the whole derivation, and it should be stated that way
    rather than re-explained from scratch. A Waft is one identifiable document holding `%What`
     sections; a Mag is one identifiable publication holding `%Cloud` sections. So a Cloud IS a What
      that happens to carry a coordinate (`page:N`, `created_at`), and everything already true of
       Whats — they nest, they carry prose, they are the unit you fold and open — is true of Clouds
        for free. A Cloud is **not** a subtype of Mag and never was; it is the section layer, one
         rung down. Corollary worth keeping in view: `%Mag:<unique-name>` follows `%Waft:<path>`
          (§1's 2026-07-19 naming ruling) — the mainkey value is the NAME, which is exactly the
           identity the wire is currently missing (see the `%from` work).
- **`%randomic` is DROPPED.** A Cloud under `%Mag:shuffle` is machine-drawn *by where it sits* —
   `Mag:shuffle**` is known as such, so a key asserting it is redundant. (`created_at` stays: it is
    what the era-GC sorts on. `page:N` stays: it is a real coordinate.)
- **The Mag KIND VOCABULARY is DROPPED — no `faves | lineup | culture`.** §3's duration table is
   retired (see the strikethrough note there). `%Mag:shuffle` is **the stuff we play to the other
    Pier**. `faves` was the only one that read as real, and it is incoherent anyway: a fave lives in
     *someone else's* collection, so it is a pointer, not a holding. **v1.0 keeps it simple — if you
      want a thing, you make a `%Heist` for it.** Favouriting is not in v1.0.
- **`%Crate` (the particle tree) is DROPPED; `Crate.g`'s VERBS survive and want a truer home.**
   The `%Crate > %dir > %blob` tree is a second, parallel model of "a collection" that no caller
    outside `Crate.g` ever reads (verified 2026-08-05: zero external mints or queries). It is where
     the do-it-as-a-Mag discipline silently lapsed. What is load-bearing is the *verbs* — 82 calls
      across 12 files, dominated by `Crate_nav` (48), which is merely an accessor for the Wormhole
       nav and is not about crates at all. **The disk becomes a Mag at the point it is read**, so it
        arrives at the downloader already Mag-shaped and the wire shape is the only shape.
- **Remote-Pier cursors are IN, and they are a v1.0 need, not a nicety.** The listeners' positions
   are what winds `%Mag:shuffle` forward, and — critically — what makes the era-GC safe: today a
    Cloud can age off the top **while a peer is mid-stream on it**, because nothing anywhere tracks
     another peer's position (verified: cursors are local-only). The picture to build to is **a flock
      of Piers wandering through a meadow** — presented, not merely accounted. A straggler may be
       skipped forward to catch up.
   OPEN (needs a ruling): *whose* feature is the skip? Proposal — the cursor REPORT is a Pier fact
    (it rides the per-Pier state that already crosses), and the SKIP is a Repli scheduling policy
     (it decides what to offer next). Splitting it that way keeps Repli ignorant of identity.
- **`%Seem` is NOT the answer here, and `Seemables_todo.md` is not relevant to it.** Checked
   2026-08-05: that doc says nothing about Radio, Mags, Piers or cursors — it is a survey of the
    Seem *technique* and its campaign is parked. If the flock wants a Seem, build a small purpose-made
     one; do not go looking for guidance in Seemables.

### 0.1 SETTLED 2026-08-05 (later the same day) — the questions §0.0 left open

§0.0 is the human's rulings. This section closes the design questions those rulings *opened*, in
 conversation. Item 1 is ruled by the human; items 2–4 are recommendations with their reasoning
  exposed, so a nod or a veto is cheap — but each one is **already implied** by something §0.0 ruled,
   so leaving them open leaves §0.0 self-contradictory.

**1. `%PCM` — the decoded-samples particle. RULED (the human).**

The survey found `%record` naming THREE things, of which only two are actually one:

- **`%Record`** (Ra, modern) — the encoded-opus holding, `%Preview|%Stream` seq packets.
- **`%record,enid`** (`Radios.svelte`, under an Actor `A`) — the SAME concept one generation older.
   `Crate.g:317` says so: *"the modern form of the old Radios %record/*%preview set"*. **This is the
    PROTOTYPE** — the new system is all `.g` (the human, 2026-08-05); the `.svelte` ghosts
     (`Radios`, `Pirating`, `Cytoscaping`) are the old stack, still reachable behind `use_Radios`
      but not the thing being designed. **Do not sweep the rename through them; do not read them for
       the current shape either.**
- **`%record`** (`Crate.g:123` under a `%blob`; `Sound.g:137` under the world) — decoded|synth PCM,
   `c.chunks = [Float32Array]`, `sc.artist|title|loudness|seconds|nchunks`, consumed by
    `Crate_radiostock` → `{kind:'records', chunks}` → `Sound_stock_chunk`. **This is the genuine
     outlier: it names the OPPOSITE of `%Record` in the same casing.**

That third one becomes **`%PCM`**. The vocabulary then reads with no case-only distinctions left:

| mainkey | what it is | travels? | where the bytes are |
|---|---|---|---|
| `%Original` | the master | never | on disk |
| `%Record` | encoded opus, the streaming materialisation | yes, as `%Preview`\|`%Stream` pages | derived, may never see a master |
| `%PCM` | decoded samples, ready for the ear | no — re-decoding is cheaper than shipping | `.c.chunks`, off-snap |
| `%Blob,grade:` | whole-file export | yes | `sc.path` |

It stays a **particle**, not `.c` payload: its sc (artist|title|loudness|seconds|nchunks) is exactly
 the observable plane the chunk-particle principle wants snapping while the weight sits on `.c`, and
  two Books already assert on it (`Musuation.g:1345,1391`).

Its **home moves with the `%Crate` drop.** Today `blob.oai({record:1})` hangs it off a `%blob`; once
 the disk becomes a Mag at the point it is read, that blob IS a `%Record` in a `%Cloud`, so **`%PCM`
  hangs off its `%Record`** — a sibling of that Record's `%Stream` packets, which is what it always
   was underneath. Loose end: `Sound.g`'s synth mint has no file and no Record — either give it a
    synthetic `%Record` parent or leave it world-level as the explicit no-source case.

Mechanically small, and entirely inside `.g`: 3 mint|consume sites (`Crate.g:123`,
 `Crate_radiostock` :145-148, `Sound.g:137`) and 2 Book queries (`Musuation.g:1345,1391`). Ignore
  `Cytoscaping.svelte:106` — prototype.

**Where `enid` went, since the question comes up:** `enid` is alive in the new system as the
 *content hash* — `Ra_enid`, sha256 over the source bytes, first 16 hex (`Ra.g:440`: *"it contains
  no timestamp, no author, no name"*) — but it is **no longer an sc key**. The particle wears it as
   **`id`**: `Ra_record_from` stamps `%Record,id:<enid16>`, and `Musica_fold` copies the same value
    onto the `%Card`, so `Card.id === stock enid` IS the join (`Heist.g:2420`). The word `enid`
     survives in function names and in the on-disk stock filename
      `<ts>-<pub>-<enid>.jamsend_radiostock` (`Ra_stock_name`, `Ra.g:445`). Only the prototype
       `.svelte` stack carries `enid` as an sc key.

**And that is why `%Record` does not collide on the wire while `%Mag` does:** `id` is on
 `Repli_loc_keys`' allow-list, so `%Record,id:<enid>` is already correctly locatory. The Mag has
  simply never had its equivalent. Note too that the on-disk name already binds `pub` INTO record
   identity (`<ts>-<pub>-<enid>`) — so `Mag,pub` is not a new idea entering the system, it is the
    disk convention finally reaching the wire.

**2. The Mag's wire identity — the tension §0.0 created, and how it closes.**

§0.0 states two things that cannot both hold: *"`%Mag:<unique-name>` follows `%Waft:<path>` — the
 mainkey value is the NAME"*, and *"there is ONE Mag kind, `%Mag:shuffle`"*. `shuffle` is a type
  word, not a name. Under one kind, **every Pier's mag is the identical `%Mag:shuffle`.**

That is a regression hiding inside a simplification, and it must be noticed *before* the collapse
 lands in code. Today two Piers' mags happen to differ by their kind value (`Musica` vs `shuffle` vs
  `lineup`), which papers over the identity hole **by luck**. Collapse the vocabulary and the luck
   runs out: every mag crosses as pattern `{Mag:'shuffle'}`, and the only thing keeping two
    collections apart is the container they land in — which is precisely what `Ra_home_them`'s
     self-guard currently breaks (`Mag_v1_handover.md`, bomb 1).

**RULED (the human, 2026-08-05): the Mag's primary key is `Mag,pub`.** The mainkey value is the
 mag's NAME, **unique per pub, not globally**; `pub` is the **prepub of the Pier who created and
  serves it**. So: `%Mag:shuffle,pub:<prepub>`, and `loc = ['Mag','pub']`.

This supersedes the `%from:<prepub>` proposal (§6b, 2026-07-19). `from` was reaching for the same
 thing and got there worse. Why `pub` wins:

- **`pub:` is already the identity key of the whole Musu layer** — `%MusuSelf,pub:<me>`,
   `%MusuThem,pub:<them>`. The Mag joins an established vocabulary instead of opening a second one.
   A reader who knows what `pub:` means anywhere already knows what it means here.
- **It resolves the name/kind contradiction rather than dodging it.** `shuffle` may go on being the
   name, because names are namespaced by `pub` — so `%Mag:<name>` genuinely does follow
    `%Waft:<path>`, one Pier may hold several mags, and no string-mashing scheme is needed.
- **The point of the whole thing: mags MIX.** Tip every Pier's mags into one space and each keeps its
   origin — which is the v1.0 experience (a friend's collection explodes onto YOUR scene) expressed
    as a key rather than as an arrangement.

**Consequence worth stating loudly — this demotes bomb 1.** Origin currently survives only by
 CONTAINER (the per-friend `%MusuThem` crate), which is exactly what `Ra_home_them`'s self-guard
  breaks; today that guard turns into merged data. With `Mag,pub` locatory, two Piers' mags stay two
   particles **even when they land in the wrong shelf**. That turns a container fault from *data
    loss* into *misfiling* — recoverable, visible, not fatal. Defence in depth. Fix the guard anyway;
     it just stops being the only thing standing between two collections.

**`pub` vs `pier` — decide this on MEANING, because the allow-list is not a real constraint.**
 `pub` is not on `Repli_loc_keys`' list (`id|name|seq|pier|kind`) and `pier` is, so `%Mag:…,pier:X`
  would cross correctly today while `%Mag:…,pub:X` would collapse to `loc:['Mag']`. That is a
   genuine difference, and it is still **not a reason to pick `pier`**: adding `'pub'` to that array
    is a ONE-WORD, strictly additive edit that changes nothing for any particle lacking a `pub`
     second key. Choosing the mainkey's companion to fit a transport allow-list is letting a wart in
      the wire pick the data model — precisely the reflex that produced the two `.c.repli_loc`
       hand-stamps instead of a fix.

RECOMMENDED: **`pub`, plus the one-word allow-list edit.** The codebase already carries two words
 for "which peer", split by layer — `pub:` in the Musu shelf layer (`%MusuSelf,pub:`,
  `%MusuThem,pub:`), `pier:` in the Heist|Repli layer (`%Lead,pier:`, `%Heistlet,…,pier:`,
   `%Rummage,…,pier:`, `%Sent_Tree,pier:`). **A Mag lives on the Musu shelf** —
    `%MusuThem,pub:<them> > stock > %Mag` — so `%Mag:…,pub:<them>` restates the container's own
     identity one rung down, in the container's own word. `pier:` there would introduce a second
      name for the identity of the very shelf the mag is standing on.
 Second reason, sharper: **the two keys have different value domains.** `pub:` is strictly a prepub.
  `pier:` is "a prepub *or* a Book's stand-in for one" — live it is `lis.sc.prepub`
   (`Radiation.g:104`), but in Books it is the literal `'Origin1'` (`Heistation.g:3834`) or
    `'Crowd'` (`Musuation.g:2721`). An identity key whose domain includes a shared placeholder is a
     collision waiting for the day something keys off `repli_mirror_pier || 'Crowd'`.
 The case FOR `pier` (recorded so it can be overruled knowingly): a Mag *is* served by a Pier, and
  `pier:` is the established word for "the peer that answered". If the human prefers the Heist-layer
   vocabulary, `Mag,pier` works today with zero wire change — take it as a deliberate choice, not as
    a dodge.

**Either way, the wire rule is not a blocker any more.** Item 3's fuller fix is still the right
 ruling, but the Mag key no longer waits on it: one word in the allow-list unblocks `pub` today.

**Mint-order constraint, if item 3 lands as recommended** (`loc` = mainkey + `keys[1]`): the
 identity key must be minted **SECOND** — `i({ Mag: name, pub: prepub, … })`. sc key order is
  insertion order, so a stray earlier key would silently narrow identity back to `['Mag']`. Either
   mint with care or stamp `.c.repli_loc = ['Mag','pub']` and let the belt hold the braces.

**3. `Repli_loc_keys` — the wire rule. RECOMMENDED; the human rules.**

*What `loc`|`repli_loc` actually is, since it is easy to mis-picture:* **it is the UPSERT KEY — the
 line's primary key — declared per particle by the SENDER and obeyed by the receiver.** Not a cursor,
  nothing to do with position. Sending: `Repli_lines_of` stamps `objecties.loc = node.c.repli_loc ??
   Repli_loc_keys(keys)` on every line (`Repli.g:116`). Receiving: `Repli_merge` splits that line's
    sc into `pattern` (the loc keys) and `props` (all the rest), then `parent.o(pattern)[0]` — **hit
     → mutate `props` onto the particle found; miss → mint** (`Repli.g:170-176`). So `loc` answers
      *"which existing child under this parent IS this line?"*. What a hit mutates, precisely (the
       owner flagged the old wording here as misleading, 2026-08-05): **only the keys the line
        carries** are written onto the found particle — its other sc keys, its children and its
         siblings are all untouched (children merge by their own lines at their own depth). And the
          asymmetry worth knowing: **absence is not deletion** — a key cleared at the source stays
           set on the mirror forever; nothing removes one key (so the `1`-or-absent boolean idiom
            cannot be UN-set over this wire — a real gap to design away from if a crossing flag ever
             needs clearing). `op:'dupe'` forces a mint; `op:'delete'`
        locates and removes a whole particle (`Repli_retire` sends `loc:['Record','id'], op:'delete'`).

*And the detail that settles the argument below:* when `loc` is **absent**, the receiver falls back
 to **ALL keys** — `let locKeys = Array.isArray(objs.loc) ? objs.loc : keys` (`Repli.g:170`). That
  fallback splits rather than merges. **So the protocol's own default is fail-CLOSED; the narrowing
   happens entirely in `Repli_loc_keys`, and that helper is what turned a safe default into an
    unsafe one.** The fix is not new policy, it is restoring the policy already written into the
     receiver.

The principle to decide on, stated once: **merging is the dangerous direction; splitting is the safe
 one.** A too-WIDE `loc` means a changed prop mints a new row instead of updating one — churn,
  visible in a snap, recoverable. A too-NARROW `loc` means two different things **silently become
   one** — data loss, invisible, and it has now happened three times (`Cloud,page`;
    `Cloud,randomic`; `Mag,which`). The default must therefore be wide. Today it is narrow, so it
     **fails open**, which is backwards.

Recommendation: **drop the name check — `loc` = mainkey + `keys[1]` unconditionally**, keeping
 `.c.repli_loc` as the override in BOTH directions (narrow it below two, or widen it past two). That
  one-line change fixes `which`, fixes `from` in advance, and *retires* the two hand-stamped
   precedents instead of adding a fourth. Its failure mode — a genuinely mutable second key becoming
    locatory — produces loud churn, not silent loss.

Ship with it a **dev-time warn when a particle carries ≥3 sc keys and no explicit `.c.repli_loc`.**
 That is the exact shape that has bitten every time; the warn makes the fourth instance announce
  itself instead of hiding for a month.

Rejected: extending the allow-list to `[…,'which','from']` — that is the third patch of the same
 kind, and it still fails open for the fourth.

**4. The flock's skip — closing §0.0's open question.**

Keep §0.0's proposed split (cursor REPORT is a Pier fact; SKIP is a Repli scheduling policy), with
 the reason made explicit so it survives contact: **Repli must stay ignorant of identity.** Repli's
  whole job is *"this subtree, that subtree, reconcile"*. The moment it knows *whose* cursor it is
   looking at, it acquires an identity model and the mirror law leaks down into the transport.

So: a Pier publishes its position; Repli reads positions as **anonymous demand** and decides what to
 offer next. The era-GC then needs exactly one rule — **never drop a Cloud that any position sits
  on** — and the skip is what stops a straggler pinning the tail forever. That also answers *"is
   skipping a Repli feature?"*: yes, but only because it is a scheduling decision, not because Repli
    knows anything about Piers.

**The positions drive BOTH ENDS of the meander — this is the thing to see.** §5 step 4 already has
 the mechanic, written for the LOCAL playhead: *"cursor moves through the six; nearing the tail arms
  the will-to-create the next page (p(N+1)), so the shuffle never stalls at a page boundary."* The
   flock is that same mechanic with a **remote** demand source — a listener traced through Repli
    drawing near the end of MY `%Mag:shuffle` is what reveals that more `%Record` should be
     generated, on my side, for them. §5 and this section are not two features; they are one rule
      read from two sides:

> **The era-GC drops Clouds off the FRONT — bounded by "never drop a Cloud any position sits on".
>  The generator mints Clouds at the BACK — triggered by "a position nears the tail". ONE flock of
>   positions decides what dies at the head and what is born at the tail.**

That is why the cursor is not a nicety: without it the meander has no reason to move and no safe
 way to forget. Build the position first; the GC bound and the generation trigger both fall out of
  it. (Whether generation is armed by a *remote* position at all is the one live question — a Pier
   could reasonably decline to mint pages for someone else's playhead. It costs a wander per page,
    which §7 says is cheap. Ruling wanted.)

**AND THE GENERATION HALF IS ALREADY BUILT — it is the `%Stoker`.** `Radio.g`'s second face particle
 runs its own detached loop: resurrect standing radiostock, then MEANDER the share
  (`Crate_nav_meander`, the no-enumeration law) and stock what the wander found — *"the stoker
   watches the shelf while the radio plays and digs when FRESH (unheard-this-sitting) runs low;
    EXHAUSTING the set makes it churn extra fast"* (`Radio.g:11-18`). Its dig funnels through
     `Ra_record_from`, the ONE mint funnel, which stamps `Record.id` and lands the record in the open
      page of `%Mag:shuffle > %Cloud,page:N`.

So the loop closes, and it closes inside `.g`: **cursor → Stoker → `Crate_nav_meander` → encode →
 `Ra_record_from` → a new `%Cloud` page → `Radio.g` plays it → the cursor advances.** The flock does
  not need a generator; it needs to become a **second demand signal into the Stoker.** Today the
   Stoker digs when *my* fresh runs low. The flock adds: dig when *a listener nears my tail*. One
    more input on a loop that already exists, already meanders, already pre-empts (`Stoker_preheat`,
     `Radio_nudge`, the ~2s-early dial).

That is a much smaller job than "build the flock", and it is the reason to do the cursor at all
 rather than defer it with the rest of the polish.

**Two notes for whoever builds this.**

*The word `cursor` is overloaded in this codebase and the flock will collide with it.* `Keeping_spec`
 owns a `cursor` already — the **attention** cursor (focus, Spotlight, the `%LE` singleton, "the
  cursor's four roles"), and `Frontier.md:122` has an OWED `collapse-the-cursor` job against it. The
   flock's cursor is a **playback position in a Mag**, a different animal entirely. Name it
    distinctly at birth or the two will be conflated in prose within a session.

*`plantable` — the human's coinage, 2026-08-05, recorded before it is lost:* **"cursors being nice
 and reductionist, plantable was to be a nice feature we didn't get around to."** There is NO prior
  art in the tree (`plant` appears only as Story-Book test-data laying — `Botany_plant`,
   `MusuHeist_plant_tagged`), so this is a named intention, not a recoverable design. The reading it
    invites — a cursor you can *put somewhere* and leave, rather than one that merely trails your
     playhead: a durable, shareable marker in a Mag — is a GUESS and is flagged as one. Ask the human
      rather than build to it.

**5. UPSERT should announce itself; INSERT should be the default. (The human, 2026-08-05.)**

The current shape: `Repli_lines_of` stamps `objecties.loc` on **every line, unconditionally**
 (`Repli.g:116`), and merge is upsert-by-default. So the wire repeats, per particle, a fact that is
  constant per *mainkey* — `{"loc":["Record","id"]}` on every Record, forever.

Two things are wrong with that, and they are the same thing seen twice:

- **The dangerous operation is the silent one.** Upsert can destroy (locate, then overwrite every
   non-loc key); insert can only duplicate. Duplicates are LOUD — they pile up in a snap where a
    human sees them — and a merge is invisible. By the principle already agreed in item 3, the
     operation that can lose data is the one that should have to say so.
- **The declaration is on the wrong shelf.** "A `%Record` is identified by its `id`" is a fact about
   the *mainkey*, not about the line. Restating it per line is what forced
    `Repli_loc_keys` to GUESS identity from key NAMES — and that guess is the bug in item 3. Identity
     cannot be inferred from spelling; it has to be declared by whoever authored the shape.

**RULED (the human, 2026-08-05): the full protocol move is POST-1.0. For v1.0, do the small half.**
 The reasoning below stands and the destination is agreed — but "figure the protocol out fully" is a
  bigger think than a week-late release can carry, and it is the kind of change that is worse done
   hastily than not at all.

**THE v1.0 STEP — "a little smarter than listing the `.o()` columns each time":** author the
 identity table **now, sender-side and local**, and keep the resolved `loc` on the line. So:
  `Repli_lines_of` reads `%Mag → ['Mag','pub']`, `%Record → ['Record','id']`, `%Cloud → ['Cloud',
   'page']` out of one readable table instead of guessing from key spelling, and still stamps the
    answer on the wire.
 What that buys, cheaply: **the name-guessing heuristic dies** — which is the actual bug, and the
  only part of this that is losing data today. One place to read "what identifies a `%Mag`" instead
   of a heuristic plus two `.c.repli_loc` hand-stamps scattered at mint sites. And the wire stays
    **self-describing**, so nothing depends on the two sides agreeing about anything.
 What it defers: the wire stays verbose, and INSERT is still not the default. Both are real, neither
  loses music.
 **Nothing is wasted by doing it this way** — the table authored sender-side IS the artifact that
  later moves into the protocol. Same table, deployed one rung further along.

**On "it's a closed circuit, can we rely on them knowing everything we told them?"** — nominally yes,
 both ends are jamsend. **Across TIME, no**, and that is the catch: peers reload onto different
  builds mid-relationship (the whole reconnect-epoch spine exists because of it), so "both sides know
   the protocol" means "both sides know *their own build's* protocol". A shared table is a shared
    assumption that a deploy can break, and the breakage would land as identity drift — the exact
     failure class this section is about. That is a second reason to defer, independent of the
      schedule.

POST-1.0 DESTINATION: **declare identity per-mainkey in the protocol rule set, beside `omit_sc`.**
 That shelf already exists — `WAFT_PROTOCOL` &c. in `Text.svelte` are inline per-mainkey rule sets
  shared by both sides. An identity declaration is exactly the same KIND of fact as `omit_sc` and
   belongs next to it. Then:

- **A mainkey with no protocol entry INSERTS.** Default is safe and loud.
- **A mainkey that means to upsert says so ONCE**, in a table a human can read top to bottom and
   audit — instead of a heuristic firing per line.
- **The wire loses `loc` from ordinary lines entirely.** The fragment above becomes just the tree.
- **`objecties.loc` survives as the per-line EXCEPTION** — stamped only where a particle deviates
   from its mainkey's rule. That is the human's "say it as an objecties property", now genuinely
    exceptional rather than universal.
- **`.c.repli_loc` hand-stamps retire into protocol entries**, which is where they always belonged —
   `Cloud → ['Cloud','page']` and the rest stop being spooky action at the mint site.
- **The `Repli_loc_keys` name-guessing heuristic is DELETED.** It is not a helper with a bug in it;
   the guessing IS the bug.

**Honest trade to weigh before committing.** Per-line `loc` is *self-describing*: the sender's intent
 travels with the data, so two Piers on different builds cannot disagree about identity. A shared
  protocol table can skew — and skew is not hypothetical here, since peers reload onto new builds
   (the reconnect-epoch spine exists for exactly that). **Mitigation, and it is a good one:** the
    receiver's existing fallback already handles it — `loc` absent → all keys locatory
     (`Repli.g:170`) → the unknown mainkey SPLITS rather than merges. A skewed peer therefore
      produces visible duplicates, not silent loss. The failure stays in the safe direction, which
       is the whole point.

**Consequence for item 2: the `pub` vs `pier` allow-list question dissolves entirely.** With identity
 declared per mainkey, `%Mag` simply states `['Mag','pub']` and there is no list for `pub` to be
  missing from. The expedient argument for `pier` disappears; pick the word on meaning alone (and the
   human has: **`%pub`**, with prior art across the Musu shelf).

### 0.2 MEASURED 2026-08-05 (overnight) — bomb 2 is bigger than three instances

§0.1 argued the `Repli_loc_keys` fix from three known collisions (`Cloud,page`; `Cloud,randomic`;
 `Mag,which`). This section replaces that argument with a **census**: every mainkey ever observed
  inside a mirror shelf in a recorded fixture, with the `loc` today's heuristic picks for it.
   (Method: walk every `wormhole/Story/*/NNN.snap`, take every line inside a `%MusuThem`|`mirror`|
    `stock` subtree — a particle sitting there got there by crossing — and run its key list through
     `Repli_loc_keys`. The script was disposable; the finding is not.)

**The census says the collision is not a handful of cases. It is an entire vocabulary.**

| crossing mainkey | observed shape | heuristic picks | correct? |
|---|---|---|---|
| `%Record` | `Record,id,…` (39 shapes) | `[Record,id]` | ✅ |
| `%Card` | `Card,id,…` | `[Card,id]` | ✅ |
| `%Preview` \| `%Stream` \| `%Original` \| `%Lossy` | `…,seq,cid` | `[…,seq]` | ✅ |
| `%ask` | `ask,id[,have]` | `[ask,id]` | ✅ |
| **`%Blob`** | `Blob,id,grade,path` | **`[Blob,id]`** | ❌ minted `{Blob,id,grade}` (`Orig.g:261`) |
| **`%Mag`** | `Mag` · `Mag,warm` · `Mag,which` | **`[Mag]`** | ❌ every mag is one row |
| **`%Cloud`** | `Cloud,page` · `Cloud,randomic` | **`[Cloud]`** | ❌ (two hand-stamps paper it) |
| **`%Spin`** | `Spin,of,title,at` | **`[Spin]`** | ❌ |
| **`%Like`** | `Like,of,title,at` | **`[Like]`** | ❌ |
| **`%Grab`** | `Grab,of,title,at` | **`[Grab]`** | ❌ |
| **`%Heist`** | `Heist,wish,hid` | **`[Heist]`** | ❌ |
| **`%Heistlet`** | `Heistlet,of,pier` | **`[Heistlet]`** | ❌ |
| **`%Jam`** | `Jam,with` | **`[Jam]`** | ❌ |
| **`%Reco`** | `Reco,by,note` | **`[Reco]`** | ❌ minted `{Reco,by}` — one per recommender |
| **`%Renamed`** | `Renamed,key,from,to` | **`[Renamed]`** | ❌ |
| **`%stock`** | `stock,pub` | **`[stock]`** | ❌ (harmless — one per home) |

Read the failing column and the rule falls out on its own: **`of:` is this codebase's documented
 many:1 join key (CLAUDE.md: *"a `%Spin,of:X` / `%Like,of:X` / `%Heist,of:X` — a Jam ledger, many
  events per track"*) and it is NOT on `Repli_loc_keys`' allow-list.** Neither is `with`, `by`,
   `key`, `wish`, `page`, `pub`. The list is `id|name|seq|pier|kind`, which happens to cover the
    *holdings* — the things Ra mints — and covers **none of the referring particles**. So the wire
     can address what a peer HAS, and cannot address any statement a peer MAKES about it.

**The instance that proves it is not theoretical: `%Spin`.** `Jam_event` (`Ghost/M/Jam.g:50`) mints
 **one row per (kind, track)**, keyed on `of:rec.sc.id` — so one `%Jam` legitimately holds many
  `%Spin`, one per distinct track, and `Jam_tally` (`Jam.g:128`) exists precisely to COUNT them.
   The ledger crosses (`MusuBuddy/011.snap:266` — `MusuThem,pub:… > stock,pub:… > Jam,with:… > Spin,of:…`).
    On arrival every `%Spin` upserts onto the first, so **a friend's ledger lands holding at most one
     Spin, one Like and one Grab no matter how many tracks were played**, and the mirror's
      `Jam_tally` reads `{spins:1,likes:1,grabs:1}` forever. It is invisible because **every Book
       mints exactly one of each** — the fixtures show one `Spin`, one `Like`, one `Grab` under one
        `Jam`, which is the single case where a broken key still looks right.

That is the fourth instance §0.1 item 3 predicted would arrive unnoticed, and it is not in a Book —
 it is in shipped code, in the social layer the v1.0 destination is built on ("a friend's collection
  EXPLODES onto the scene"). **It also settles item 3 with data instead of principle: the heuristic
   is not a good rule with gaps, it is a rule that fits one family of particles and silently destroys
    another.**

**Consequence for the v1.0 step (item 5).** The sender-side identity table is now not merely tidier
 than the heuristic — it is the only shape that can express what the data model already contains.
  Two things the heuristic *structurally cannot* say, both turned up by the census:
- **A three-key identity.** `%Heistlet,of,pier` is one heistlet per (want, peer). `Repli_merge`
   splits by however many keys `loc` carries, so the protocol supports it — but `Repli_loc_keys` can
    only ever return one or two, so today it is unreachable except via a `.c.repli_loc` hand-stamp.
- **Two identities under one mainkey — see §0.2b.**

**LANDED 2026-08-05 overnight, and what it cost.** The table is in `Ghost/N/Repli.g` as
 `Repli_identity_keys` (the declaration) + `Repli_loc_for` (the resolution: explicit `.c.repli_loc`
  → table → all keys with a one-shot warn). `Repli_loc_keys` is gone. Verified against the whole
   green set with it in place — MusuBounce 5/5, MusuStanding, MusuRecast, MusuReap, SwarmDoor,
    SwarmDisk, MusuFreeze, SwarmShare, all `ok_pct 1`.

*Be clear about what that verification is worth.* It proves the table **breaks nothing**. It cannot
 prove the table **fixes anything**, because **every Book mints exactly one of each affected
  particle** — the single case where the old broken key still looked right. The suite is blind here
   by construction, which is the same reason the bug survived a month. A regression would be caught
    by nothing. Two three-line Book changes would fix that and they are the highest-value test work
     outstanding: a `%Jam` holding TWO `%Spin`s, and one shelf holding TWO Piers' Mags.

*And a method note that is the real lesson of authoring it.* **Every row must be read off the MINT
 SITE, never inferred from how Books query it.** Two rows were nearly shipped wrong from inference:
  `%Reco` looked 1:1 because two Books do `rec.o({Reco:1})[0]` — but it is minted
   `rec.oai({Reco:1, by})`, one per recommender, so `[Reco]` would have merged two people's
    recommendations of one track. And `%Blob` looked like `[Blob,id]` until `Orig.g:261` turned out to
     mint `{Blob:1, id, grade:'ogg128'}` — a second export grade of the same track would have upserted
      onto the first. Both are the exact bug the table exists to kill, arrived at by the exact habit
       that caused it: guessing identity from how a name reads. The old heuristic got both wrong too;
        these two are additional fixes, not just tidying.

*One knock-on worth knowing before reading a diff.* A declared `loc` is sometimes WIDER than the
 guessed one, so the repli_lines frame carrying it is a few bytes longer: MusuDoor step 6 moved
  `body_len 530 → 546` with a new `body_hash`. Only the FRAME changes — the merged mirror is
   byte-identical, which every other line of the snap asserts. Any Book whose fixture snaps a
    `repli_lines` body_hash/body_len therefore wants one re-record.

### 0.2b `%Stream` is polysemous, and it blocks the post-1.0 protocol table

Turned up by the same census, stated separately because it changes item 5's destination. `%Stream`
 names **two different things**, one in each of the two transfer paths `Repli_lines_of` documents:

- **`%Stream,seq,cid`** — a CHUNK PARTICLE, one per opus packet, minted at `Ghost/M/Ra.g:1422`
   (`rec.oai({Stream:1, seq})`). A sibling of `%Preview,seq`. Many per `%Record`. A **member**.
- **`%Stream,name:'audio',total,have[,page_from,page_to]`** — the Float32-page path's FILL COUNTER,
   minted at `Ghost/M/Crate.g:337`, sent at `Ghost/N/Repli.g:522`. One per `%Record`. A **summary**.

Same mainkey, and one of them is a member of a set while the other describes that set. This is the
 exact tell CLAUDE.md names — *two DIFFERENT shapes under one mainkey* — and the same disease §0.1
  item 1 cured one shelf over (`%record` vs `%Record` vs `%PCM`).

It survives today only by luck: `name` and `seq` are BOTH on the allow-list, so the heuristic happens
 to give each shape a correct `loc`. **A per-mainkey table cannot be that lucky.** You cannot write
  `%Stream → […]` once when `%Stream` means two things — so item 5's post-1.0 destination (identity
   declared per mainkey beside `omit_sc`) is **BLOCKED on splitting this name**. Prerequisite, not
    tidy-up.

Sharper still: the counter should not exist at all under the chunk-particle principle, whose law is
 stated at `Repli_chunk_at` — *"Presence of the particle WITH its bytes IS fill state — there is no
  have= counter to keep honest"*. `%Stream,name` **is** a `have=` counter. It is the older model
   surviving beside the newer one under a shared name, and it is confined to the PCM page path — the
    very path §0.1 item 1 renames to `%PCM`. So the two cleanups are one cleanup.

RECOMMENDED (the human names it — naming here is the human's craft): the chunk particle
 `%Stream,seq` **keeps the name** (it is a page of a Record, sibling to `%Preview,seq`); the
  Float32-path counter takes a new one and moves under `%PCM` with the rest of that path. Its whole
   content is `total`/`have`/`sr` — the fill state of a pour of samples into a Record.

UPDATE 2026-08-05 (§0.2e): the "BLOCKED" above holds only for a per-MAINKEY table. Under
 mint-declared identity — §0.2e's recommendation — each mint states its own pattern, so the
  polysemy stops blocking anything and this split reverts to what it really is: the `%PCM`
   cleanup on its own merits. Still worth doing; no longer a prerequisite.

### 0.2c Four Books are red on WALL CLOCK, and cannot ever go green as recorded

Not a Mag fault, but it has been costing every Mag session its read of the suite, so it belongs
 beside the rest. **MusuBuddy, MusuMag, MusuRaStream and MusuHeist embed absolute epoch seconds —
  and signatures computed over them — in their recorded fixtures.** Their canonicalised diffs (every
   dated ruling of §0.2 stripped from both sides) reduce to exactly this and nothing else:

```
< Pier,pub:<hash>,friendly:Listener,since:1785076033      >  …,since:1785854872
< Grant:Music,by:<hash>,for:<hash>,time:1785076033,sign:<hash>,genre:Classical
< Edge,a:<hash>,b:<hash>,at:1785076033
< NotGrant:Music,…,time:…,sign:…
```

A fixture holding a wall-clock number **can never match again**, so these four have been
 structurally red since the moment they were recorded — nothing about their subject is failing, and
  no amount of re-recording helps, because the next run stamps a new `now`. Any session reading
   "MusuBuddy 0.07" as a signal about buddies has been reading noise.

**All four fields come from ONE function.** `Swarm_now(w)` (`Ghost/S/Swarm.g:23`):

```js
Swarm_now(w):
    return +(w?.sc?.now ?? Math.floor(Date.now() / 1000))
```

and everything noisy flows through it — `pier.sc.since` (`Swarm.g:1167`), `%Edge,at` (`:1178`), and
 `mint_grant(…, this.Swarm_now(w))` at `:190, :923, :948, :1035, :1062`, whose `time` the ed25519
  `sign` is computed over. Its own comment states the contract: *"A Book pins `w.sc.now` so every
   signed `time` (and so every signature and snap byte) repeats run to run; unpinned = wall clock."*

**So the fix already exists and is already proven — it just was never applied to these Books.**
 `Swarmation.g` pins `w.sc.now` at every beat (30-odd sites) and says why in its header: *"DETERMINISM
  is total: fixed selves, a pinned clock (w.sc.now stepped per beat), a fixed nonce — ed25519 signs
   deterministically, so every signature, every grant, every snap byte repeats run to run."* And the
    Books that do it — SwarmShare, SwarmDoor, SwarmDisk — are exactly the ones that go green. The
     Radiation|Heistation Books never pin it (`Radiation.g:1455` does, for one unrelated test), so
      they run on the wall clock and record it.

RECOMMENDED: **pin `w.sc.now` in MusuBuddy / MusuMag / MusuRaStream (`Radiation.g`) and MusuHeist
 (`Heistation.g`), stepped per beat, then re-record those four once.** One line per beat. Cheap, and
  it converts four permanently-meaningless verdicts into real gates.

*The exact shape, so this is a short job.* Each of these Books has a `*_drive(w, req)` that already
 reads the beat — e.g. `MusuRaStream_drive` (`Radiation.g:77`): `let n = (this.c.run)?.c.step_n`.
  Immediately after that line, before any dispatch:

```
    // DETERMINISM: pin the swarm clock, stepped per beat — Swarmation.g's law.  Unpinned,
    //  Swarm_now falls through to the wall clock and this Book's %Pier,since / %Grant,time
    //   (+ the sign over it) / %Edge,at can never re-match a fixture.  §0.2c.
    w.sc.now = <book-base> + 10 * (+n || 0)
```

 Set it on EVERY pass, not only when the beat changes — the pumps run every pass, and a Pier or Edge
  stamped on a pass before the first dispatch would take the wall clock. Give each Book its own base
   (SwarmShare uses `1751940000`) so two Books' fixtures never read as the same session. `w.sc.now`
    has exactly ONE reader in the tree — `Swarm_now` (`Swarm.g:23`) — so the blast radius is
     precisely the signed swarm facts and nothing else. It snaps as `w:<Book>,now=…`, which is why
      the re-record touches every step; that is expected, and it is a one-time cost.

**Deferred during the night of 2026-08-05, then LANDED at the end of it** — deliberately in that
 order. While two wire changes (the self-guard and the identity table) were still unverified in the
  tree, stacking a five-Book re-record on top would have made any red impossible to attribute. Once
   those were verified and 21 Books were green, this went in as its own change, which is what the
    deferral was for.

**Landed:** the pin is in all five drives — `MusuBuddy_drive` (carrying the full reasoning),
 `MusuMag_drive`, `MusuRaStream_drive`, `MusuRaChase_drive` (`Radiation.g`) and `MusuHeist_drive`
  (`Heistation.g`), each with its own base so two Books' fixtures never read as the same session.

**Proven on MusuBuddy before the rest were touched.** Every wall-clock value moved from a recorded
 moment to one derived from the beat, exactly as intended:

```
< Pier,…,since:1785078383      → > Pier,…,since:1751960040
< Grant:Music,…,time:1785078383,sign:<a>  → > …,time:1751960040,sign:<b>
< Edge,…,at:1785078383         → > Edge,…,at:1751960040
                                 > w:MusuBuddy,now=1751960010   (new, and the point)
```

**Result: `MusuBuddy` and `MusuHeist` are GREEN** — re-recorded and re-run `ok:true, ok_pct:1`. Both
 audited: every `since`/`time`/`at`/`now` in the new fixtures is a pinned value derived from the
  beat, and **no wall-clock `1785…` value survives in either Book's numbered snaps.** Two Books that
   could never have been green are now real gates.

**Three of the five are still owed, for two different reasons — neither of them the pin:**
- **`MusuRaStream` and `MusuRaChase` need an FSA-LIVE RUNNER.** They sit at `phase:"begun"` forever
   on a proxy-only one. The `run` reply says so (`"needsFSA":true` plus an explicit notice); `state`
    does not, which is why it reads as a hang. Sixth verification trap in `Mag_v1_handover.md`. Their
     pin is in and correct — it wants a runner with a share open, then the same accept ritual.
- **`MusuMag` has a PROGRESS RACE at steps 8–10**, revealed once the clock noise was gone and quite
   separate from it. Its snap captures an in-flight pull wherever it happens to have reached: the
    fixture holds `parked_want,…,from_idx:28…38` where live holds `16…26`. Re-recording that would
     just pin one sample of a moving quantity. It wants the `Coding_guide.md` "Wake ≠ Hold" treatment
      — a HOLD that keeps the snap from landing until the transfer reaches a defined point — not an
       accept. **Note the confound before diagnosing it:** this runner had been under continuous load
        for five hours when the reading was taken, and a rate-sensitive Book reads slower on a busy
         machine than on the idle one that recorded it. Re-measure on a quiet runner first.

**One thing the pin REVEALED, which is the argument for doing it at all.** With the clock noise gone,
 MusuBuddy's `%see:'…two tracks took different gains toward one loudness target'` was seen landing at
  step 3 instead of step 2 — invisible before, because every step was red anyway. Following
   `Coding_guide.md`'s own instruction (verify timing by RE-RUNNING, not by reasoning) it landed at
    step **2** on three consecutive runs; the one late landing was the run immediately after a
     `ghost-compile`. So: a narrow real race, widened by the cold HMR reload, exactly the case that
      guide describes — and **never record a fixture from the first run after a compile.**

### 0.2d The two reds that were NOT stale — one real bug, one unfixable fixture

Sweeping the Books nobody had swept (MusuBreach, MusuCursor, MusuHeal, MusuLossy, MusuResume — all
 already green; MusuReco — stale, accepted, green) turned up two that canonicalisation could not
  explain. Both matter more than the twenty that could.

**MusuOgg — a REAL failure, and a FIFTH dated ruling, the only one that broke behaviour rather than
 a recording.** Live: `stocked,total=39,have=16` where the fixture says `have=39,whole`, then
  `export_fail,gap=16` → `structural_fail:no_file` → `decode_fail:no_file`. Not one `%Stream` chunk
   minted; only the 16 preview chunks stood. **Controlled**: re-run with the identity table bypassed
    (the old heuristic restored inline) and it fails identically, `ok_pct 0.17` either way — so it is
     not this session's change and was simply never swept.

 Root cause, and `Ra_transcode_ensure` documents it against itself (`Ghost/M/Ra.g:1461`): on
  **2026-07-28** the source-PCM decode went NON-BLOCKING — *"Kick the decode off DETACHED (never
   awaited under the beat) and bow out this beat; **a later pump** finds `rec.c.pcm` ready and opens
    the encoder."* It now returns `null` when the PCM is not ready yet. That is correct for the live
     caster, which pumps every beat.
 **But MusuOgg IS the pump.** It deliberately drives the encode itself — *"no wire, no two-Pier want
  machinery — `Ra_transcode_ensure` once, then `Ra_transcode_advance` in a loop"* — so it called
   `ensure()` exactly once, took the `null`, and `while (ra && …)` never executed a single iteration.
    The Book has been red since that day, and nothing noticed because nothing ran it.

 FIXED (`Ghost/Story/Heistation.g`, `MusuOgg_stock`): wait for the detached decode before driving —
  retry `ensure()` until it yields a transcode, bail on `rec.c.pcm_why` so a decode that THREW reports
   instead of re-kicking forever, bounded at 60s inside the beat's existing 240s `expecting()` ttlilt.
 **The sleep in that loop is load-bearing, not politeness.** `ensure()`'s null path contains no
  `await`, so a bare retry loop resolves entirely in the MICROTASK queue and starves the very
   macrotask decode it is waiting for. `await new Promise(r => setTimeout(r, 100))` — the idiom
    already used across Musuation/Radiation/Sound — is what lets the decode land.

 *The general lesson, which is worth more than the fix:* the 2026-07-28 change swapped a BLOCKING
  contract for a **"someone will call me again" contract**, and every caller that was a one-shot
   driver rather than a loop silently became a no-op. That is the same shape as the wake-vs-hold
    trap in `Coding_guide.md` — a change that is correct for the pumped path and silently wrong for
     the driven one. When a verb goes non-blocking, its one-shot callers are the bug surface.

**Sounditron — cannot be green anywhere but the machine that recorded it.** Its snap carries
 `Machine,self:56fbce44,friendly:Righto`; live it reads `Machine,self:58517b48` — **the runner's own
  id**. So the fixture is bound to the host that recorded it, the way §0.2c's four are bound to the
   moment that recorded them. Same class, different axis. Its live diff is otherwise a whole
    different world (`Radio:digging,note:nobody online yet…`, a populated `radiostocking`) so it is
     not a small drift.
 **NOT TOUCHED** — `wormhole/Story/Sounditron/toc.snap` was already modified in the working tree when
  this session began, i.e. the human is mid-work on it. Left entirely alone, not swept, not accepted.
   Recorded here only so the next session does not re-discover it and does not "fix" it blind.


REJECTED, and worth recording so it is not re-proposed: forgiving the values with a `spay` rule in
 `Story.svelte`'s `story_matching` (the mechanism is right there — `spay` accepts an array and
  `spay_normalize` runs over BOTH sides at compare time, so it would need no re-record at all). It
   is the wrong fix because it **forgives** where pinning **removes** the non-determinism: a spayed
    signature is a signature nobody checks any more, and the whole point of a fixed nonce + fixed
     keys + a pinned clock is that a real signature repeats and therefore still gates.

---

**Not a ruling, a correction of the record (2026-08-05):** the codec path IS WebCodecs already —
 `Ra_encode_*` uses `AudioEncoder`/`AudioData` (Ra.g:246-275) and `Ra_decode_packets` is "ONE
  WebCodecs AudioDecoder over a run of raw opus packets" (Ra.g:353); `Radio.g` schedules playback
   through a persistent `AudioDecoder` per encode. The remaining `OfflineAudioContext.decodeAudioData`
    calls (`Crate.g:106,262`, `Ra.g:1104,1379`) are **source-file ingest only** — arbitrary user
     WAV/FLAC/MP3 into PCM — and that is defensible: WebCodecs has no demuxer and cannot sniff a
      container. Do not "migrate" those to WebCodecs expecting a win.

**Docs these rulings contradict, for the human's preen** (not edited here — `Radio_spec.md` is
 blessed and is the human's to change):
- `Radio_spec.md:116-123` — the `%Grasp` definition and the "not music-specific / abuse-report"
   paragraph. Dropped wholesale.
- `Radio_spec.md:158` — the `shop/ %Heist,of:<grasp>` tree. The `of:<grasp>` pointer has nothing to
   point at; a Heist stands alone.
- `Radio_spec.md:255-257` — "the GC root set is exactly the Mags|Grasps". Now: the Mags.
- `Radio_spec.md:472-477` — §5A rung 6 "Marauding". Retire the rung or re-found it on `%Heist`.
- `Radio_spec.md:131-133` — `%Cloud` "with `randomic` present is machine-drawn … omit `randomic` and
   the cloud is curated". The distinction goes with the key.
- `Mag_design.md` — repeats the Mags/Grasps GC-root line (:73) and the `Stoker_mag_draw`
   `%Cloud,randomic:'digN'` shape (:60). Working doc, safe to edit once the code moves.
- `Radio_spec.md:287,292` — the `%record` definition ("a decoded track. `c.chunks =
   [Float32Array]`") and `Crate_radiostock`. **This is the particle §0.1 renames to `%PCM`.**
   And note `:530` (*"`%record` is made"*) and `:674` (*"streaming a real `%record`"*) — in a blessed
    spec, neither can be read as decoded-or-encoded without checking the code. That ambiguity, in the
     spec itself, is the argument for the rename.

---

The bet, in one breath: **a Mag is the main experience.** You connect to a Pier and their
 collection EXPLODES onto the scene as Mags — bounded, curated, playing — and audio starts within a
  couple of chunks. Not an index you scroll; a set of living rooms that arrive already warm. The
   whole thing is an *optimised-for-audio-discovery web protocol*, and the Mag is its packet, its
    page, and its playhead all at once.

The systems this needs have been getting **dialled in by the Story Books** — one at a time, each
 Book proving a seam the protocol leans on. What is already proven and load-bearing:

- **Per-friend mirror keying** (SwarmShare, 2026-07-19): what I hold OF a friend lands under
   `%MusuThem,pub:<them>` — the per-friend crate, not a merged pile. The Mag layer hangs off THIS.
- **%Suggest store-and-forward** (SwarmShare): a referring pointer that survives the friend being
   offline and drains on their rebirth greeting. A Mag is the same shape at collection scale.
   RULING (2026-07-19): the `%Suggest` MAINKEY retires once Mags cross the wire — a suggestion is a
    one-card Mag `%from` the friend carrying a note. What survives is the DELIVERY PATTERN it proved
     (pier-stash durable, re-offered on every rebirth greeting until the far side confirms `got`):
      that pattern BECOMES Mag delivery, not a parallel particle family beside it.
- **The reconnect-epoch spine** (PereReborn): a reborn peer's stream heals from either side. A Mag
   stream must survive the same reload — the pull resumes, it does not restart.
- **The no-enumeration meander** (`Crate_nav_meander`): 200k-track-safe wander, `prandle`-seeded.
   The shuffle generator IS this. (§7)
- **The Repli husk/page split** (`Repli_offer` husk-first, `Repli_want_next` the pull, `%parked_want`
   the will-to-have): Mags cross the wire on exactly this machinery. (§4)
- **The culture-trace draws** (`Stoker_mag_draw` → `%Mag:'Musica' > %Cloud,randomic:'digN' > %Card`):
   the SEED of the Mag idea already exists — today ephemeral (keep-8, GC). Realitifying = promoting
    it from a passive trace to the durable, navigable, cross-wire primitive below.

**Near candidates (pick one to pull first):**
1. **The model migration** — move the radiostock in-tree shape from flat `stock/%Record` to
    `%Mag:shuffle/…/%Record` (§1). Smallest change with the biggest downstream: it gives the crush
     real structure to fold (kills the Vtuffing misrepresentation) and gives show|hide real limbs.
    **BUILT 2026-07-19.** The mint moved inside `Ra_record_from` (the one funnel build+resurrect
     share): a new holding lands in the open page of the shelf's `%Mag:shuffle > %Cloud,page:N`
      (6 a page, `Ra_page_size`). Every scanning reader rides the shape-agnostic census
       (`Ra_recs`/`Ra_rec_find` — flat + paged both) so Book scenes and mirrors that still lay flat
        keep working; no data migrator was needed (the in-tree stock rebuilds off disk each
         sitting). Sworn + declared on MusuBuddy: *the stock pages under the shuffle mag — every
          record stands in a bounded cloud page never flat on the shelf.* Re-recorded green ×2:
           MusuBuddy, MusuRaStream, MusuRaChase, MusuOgg, MusuReap; neutrality held (fixtures
            unmoved) on MusuReplica, SwarmShare, MusuHeist, MusuFreeze, MusuDoor, MusuCursor.
    OPEN RULING surfaced by the cut: the OTHER holding mints still lay flat deliberately — the
     heist census import, the heist cp-landing card, and the Jam keeper (`kept`). A landed heist is
      an ACTIVATED product (§6b), i.e. curation — its Mag home should come from the Heist's own
       naming (a landing Mag), NOT the shuffle. Wants its own ruling before those mints page.
2. **The wire shape** — a Mag as the Repli unit (§4): offer a Mag husk, pull its warm-start chunks,
    autostart. Closest to what is already loaded; a Book (`MusuMag`?) proves it end to end.
    **BUILT + PROVEN 2026-07-20.** One offer verb (`Ra_offer_stock`) stamps `repli_loc:['Cloud','page']`
     on each paged cloud (so pages upsert by page, not collapse onto the first) and offers the Mag as a
      husk; a warm primer (`Ra_mag_warm`) wants offset 0 of the first two records and turns the mirror
       Mag `warm` the moment record zero holds its opening page; a stage stamp (`Ra_stage`, gated to
        `Ra_mag_homed`) reads the pipeline position onto the record so flat scenes/heist quarantines
         never learn the key; paged-aware wire delete + `repli_skip` keep device-local furniture off the
          wire. `MusuMag` proves it end to end — green ×2, **four sworn + declared**: *the mag crosses as
           one husk*, *the warm start pulls the opening page of the first two records*, *a starved track
            wears its stage on the particle* (deep wants park at the caster), *the pipeline reads back
             end to end* (preview page pulled → decoded to real PCM).
    ~~FINDING (the twin-record split)~~ **RESOLVED 2026-07-20 — one true record (the human ruled "do B").**
     A mirrored track used to land as TWO `%Record`s under one id: the paged head (metadata + `stage`, no
      bytes) and a flat way-station holder (chunks, no metadata) — because the husk offer ships full
       `Mag>Cloud>Record` ancestry while the chunk serves ship a lean `d:0` Record fragment, and
        `Repli_merge`'s direct-child upsert could not see the paged head, so it minted a flat twin.
         **The cut**: `Repli_merge` now locates a missed `%Record` line through the census (`Ra_rec_find`
          — the exact mirror of the delete path's paged-aware find) before minting, and a census-found
           head keeps its true `c.up` (re-rooting would tear it out of its page). Chunks land under the
            head; the mirror wears the origin's own shape. Fallout, all landed: `Ra_mag_warm` reads the
             head directly; `MusuMag_deep` returns the ONE record; the head's `stage` now honestly reads
              SUPPLY (previewed/whole/decoded live in MusuMag's snaps, impossible before); `Jam_grab`
               skips the `stage` key (pipeline furniture never rides a keeper into `%Kept`).
    THE TWIN HAD DRAWN BLOOD: the split had silently frozen MusuBuddy's pull leg (the census flip to the
     total-less holder), and the 2026-07-20 sweep re-record enshrined `hear_fail:nothing pulled` +
      `jam_fail:nothing heard` in its fixtures — only one sworn claim gated the Book, so it stayed green.
       Fixed by the cut; MusuBuddy re-recorded green ×2 with the whole back half alive (pulled 38 chunks
        with park/release counts, heard at target LUFS, Spin/Like/Grab ledger, whole keeper) and TWO NEW
         sworn + declared claims binding it forever: *the browsed card pulled its record whole and
          byte-faithful…* (step 10) and *the jam ledger reads spin like grab in order…* (step 11).
    NEUTRALITY under the census landing: flat shelves hold no Mag, so the fallback never fires there —
     MusuReplica green on untouched fixtures (caveats = the known heartbeat-round drift only); no other
      Book's fixtures ever held a naked holder row. MusuMag green ×2. Earlier sweep (pre-cut, 2026-07-20,
       run singly): MusuReplica / SwarmShare / MusuFreeze / MusuSoft / MusuBay / MusuOgg green; MusuBounce
        accepted per the human (known-flaky bouncechunk body_hashes).
3. **The limbic show|hide** (§6) — retire the flat `%Tuner` mute-index for a crawlable topic-limb
    graph with attention-budget mutex. Render-side; supersedes the currently-broken `Tuner_toggle`.
    **PARKED 2026-07-19**: Radio's display side is mid-refactor (Voro+Cyto → **Vyto**, the human's
     cut) — no display-side work until it lands. The wire shape (2) proceeds data-side only, and
      explode-on-connect's PRESENTATION leg (§6) waits here too.

The docs are a bit senile — where this contradicts `Radio_todo.md`, this wins for the Mag layer.

### 0.2e DESIGNED 2026-08-05 — reductionist Repli: the transport can forget the particles

The owner's challenge, same day the table landed: *"one way replication without knowing anything
 about the particles should be possible"* — where "knowing anything" means knowing their protocol,
  which properties are loc. A design agent audited every mint site behind every table row. Verdict:
   **the table is a census-reconstruction of information the mint sites already state.** Full
    writeup lives in this section; the table (§0.1 item 5) stays for v1.0, this is its successor.

**The core finding: find-pattern ≡ identity, at every real mint.** `Repli_merge` is find-or-create
 running on the receiver — the same algorithm as `_foc` (`Stuff.svelte.ts:577-588`), the engine
  under `oai`. And `oai(s, c = {})` already HAS the pattern/props split in its signature: `s` is
   located, `c` is merged after. A wire line is a serialized oai call whose split got flattened
    into one sc bag, then reconstructed by census. Checked per-row against the mints: every `oai`
     and every manual find-or-create (`Jam_event`'s `o(q)[0] else i(q)`, `Heist_rummage_ask`) has
      a find pattern exactly equal to its table row. The only divergers are `i()` create-only mints
       that mixed props into the creation bag — `Cloud,randomic` ×3 sites and `Renamed`
        (both ALREADY hand-stamped `.c.repli_loc`), plus `%Heist` whose `hid` joins identity
         POST-mint (`Heist.g:280,740` — needs a ruling, Q2 below). Decisive bonus: **the %Stream
          polysemy (§0.2b) does not exist per-mint** — the chunk mint (`Ra.g:1446`) and the counter
           mint (`Crate.g:337`) each state their own correct pattern, so per-PARTICLE identity has
            no per-mainkey axis and §0.2b's blocker dissolves rather than needing solving. The
             `%PCM` split reverts to a cleanup on its own merits.

**The irreducible schema is ~5 shapes.** Name the property that covers everything else:
 **self-matching resend** — absent `loc`, the receiver patterns on all keys, so a resent identical
  line locates its own prior transmission and merges to a no-op. Under at-least-once delivery
   (the 4s re-ask, whole-husk re-offers) that is strictly better than a true insert. Immutable
    particles need NO declaration at all — and that is most of the wire, per the owner's
     append-mostly read ("we mostly need to know which Mag to find and climb into"). The shapes
      that MUTATE after mint and re-cross, enumerated from the senders: **%Record** head
       (`Ra_record_from` refresh; delete+remint unusable — a mirror Record holds landed chunk
        children), **%ask** have/held (the Heistlet return leg), **%Reco** note (re-recommend),
         **%Mag** head (warm/which vary; a split duplicates the spine), **%Card** (recast
          refresh). The %Stream have-counter mutates but its loc is hardcoded in its hand-built
           sender already. Note the SPINE requirement: even pure appends must LOCATE their
            container lines (Mag > Cloud > …) — immutable heads locate fine under all-keys, so it
             costs no schema, but it is why a wire with no locate semantics at all is impossible.
 Absence-is-not-deletion audit: NO current mutator ever needs to un-set a key over the wire
  (ask marks latch 1-and-stay, warm is one-way, the counter grows, note overwrites) — true today,
   never stated as a rule (Q4).

**Options, judged:** (A) **Mint-declared identity only — RECOMMENDED.** One line in `_foc`
 stamping `c.oai_loc = Object.keys(s)` on create AND re-find (re-find matters: `.c` never
  persists, but every crossing shape re-passes its mint funnel each session, so reload heals the
   stamps). `Repli_loc_for` becomes `.c.repli_loc → .c.oai_loc → all keys` — no table, no warn,
    no mainkey knowledge in the transport. ~6 mint-site touches (Jam_event, Card ×3, ask, Heist's
     hid) + one core line. Honors "Repli must stay ignorant" literally. (B) Append+delete-only —
      rejected as stated (resends need dedupe, the spine needs locating, the mutating set exists)
       but absorbed as the default: insert-by-self-matching IS the default, loc only where
        mutation is declared. The owner's `op:front` window-advance ("the first particle in A/B/C
         is now X", §5) is orthogonal and good — generalizes the whole-cloud delete precedent
          (`Heist.g:2489-2495`). (C) Surrogate wire ids — rejected: re-invents retired `enid`
           (which already BECAME `Record.id` — "The id IS the content hash now", `Ra.g:1053`),
            contradicts identity-per-shelf, and fixture-deterministic ids just rebuild the schema
             as a hash. (D) Status quo — the transport carries a ~20-row model of the app
              vocabulary and every new crossing mainkey edits the transport file; the baseline
               being paid for.

**Migration, staged so wire bytes never change until the ruled re-record:** Stage 1 (~zero
 fixture cost): the `_foc` stamp + ~6 touches, rewrite `Repli_loc_for`, delete the table + warn;
  per-line loc stays byte-identical (verify %Spin/%Grab and %Heist,hid live before deleting);
   gate = the existing 23 green. Stage 2 (post-1.0, rides §0.1 item 5's insert-default move):
    omit `loc` for immutables; measured cost **16 Books / 218 fixture snaps** re-record once —
     consider folding into the `Mag,pub` re-record (21 Books/~250 snaps) so the suite reddens
      once, not twice (Q3). Optional: `Repli_merge` stamps merged mirrors' loc so identity
       survives multi-hop re-serves.

**Rulings only the human can make:** (1) is "the pattern I was found by" a C-level fact (one
 line in `_foc`, TheC core — the floor) or a Repli-only oai variant (re-opens forgetting)?
  (2) is `hid` part of %Heist's wire identity; can two Heists share a `wish`? (3) Stage 2
   scheduling — with item 5's move, or folded into `Mag,pub`'s re-record? (4) rule the invariant
    "a mutating crossing shape never un-sets a key over the wire", or design the clear op now?
     (5) `op:front` ruled in? (6) should the explicit-stamp path presence-filter like the table
      path did (a hand-stamped-but-absent key patterns on `undefined`)?

---

## 0b. Residue — landing-Mag loose ends (verify + fix, 2026-07-21)

Small cleanups the landing-Mag cut left behind (they lived only in a task-tracker + memory before
 now). Each needs a re-record of the Book it touches; the heist-family ones pin to runner **49dee91d**.

### Origin's stock should page, not lie flat · `origin-lib-pages` — **DONE 2026-07-21**
All six flat `origin_lib`/`lib` Record mints across the Heistation scenarios now go through
 **`Ra_rec_home`**, so Origin's tape lands under `%Mag:shuffle > %Cloud,page:N` like every real stock
  shelf. The three fold-only Books (MusuVend `MusuVend_meander`, MusuDoor `MusuDoor_stock`, MusuRename
   `MusuRename_publish`) needed only the mint swap. The three **goner** Books (MusuRecast, MusuFreeze,
    MusuStanding) also paired a flat `origin_lib.rm({Record:1,id})` that a paged record is invisible to —
     so a new removal door **`Ra_rec_drop(shelf, id)`** (`Ra.g`, right after `Ra_rec_home`) finds the
      holding wherever it sits and detaches it from its actual parent; all six `rm` sites route through
       it. Downstream was already shape-agnostic (`Musica_fold`/`Musica_recast_offer`/`Musica_stand`
        all read `Ra_recs`), so the goner receipts (`gone_recs`/`gone_cl`) and every `%see` claim held —
         pure fixture-move. Re-recorded green ×2 on **49dee91d**: MusuVend, MusuDoor, MusuRename,
          MusuRecast, MusuFreeze, MusuStanding. (Commits `157f9d02` `b9a85bf9` `979e870c` `580c6a1c`.)

### A digging radio over-counts against a paged twin · `radio-stood-paged-blind` — **DONE 2026-07-21**
`Radio.g:629`'s flat `!shelf.oa({ Record: 1, id })` now reads the shape-agnostic
 `!this.Ra_rec_find(shelf, { Record: 1, id })`, so a record already sitting PAGED is seen and
  `st.sc.stood` no longer over-counts on a re-resurrection. `Ra_record_from` already deduped through
   `Ra_rec_home`, so nothing could ever DUPLICATE — the bug was purely the count. Neutral (green:
    MusuRaStream, MusuResume, MusuRaChase — no `stood` moved). Commit `2f991781`.

### A published Card stamps maybe-undefined artist/title · `heist-card-guard-stamps` — **DONE 2026-07-21**
`Musica_fold`'s card mint (`Heist.g:949`) now bare-mints `{ Card: 1, id }` and `if`-guards artist/title
 like its path/album/body_hash siblings, so a holding with no artist/title never brands the card line
  `undef`. Neutral (every test pool sets both — green: MusuVend, MusuRecast; no gated fixture moved).
   Commit `7e4bddc9`.

### `Ra_recs`/`Ra_rec_find` now recurse over `Mag**` · `ra-recs-recurse-question` — **RULED + BUILT 2026-07-26**
The human ruled it: **`Mag**` recurses.** "we'll just look for Record, figure out what the rest of the
 Mag is to be later." The census reads (`Ra_recs`, `Ra_rec_find`, and the `Ra_mag_warm` row-collect) now
  walk a Mag's whole subtree — `shelf|Record` first (the flat/way-station leg), then `Mag**/Record` at
   any depth: `Mag/Record`, `Mag/Cloud/Record`, and Cloud-in-Cloud / Mag-in-Mag when they come. A shared
    recursive engine (`Ra_recs_deep` / `Ra_rec_find_deep`, `Ra.g`) collects **holdings-first at each
     level** (a container's direct `%Record` rows before any nested container's) so the census ORDER is
      byte-identical to the old fixed three-level walk on every shape that exists today — pure neutrality,
       no fixture should move — while deeper shapes are now found instead of silently dropped. A `%Record`
        is a leaf (its children are chunk particles, never Records) so the walk prunes at it. Notation
         corrected throughout to `shelf|Record` and `Mag/Cloud/Record` (the human's, over the old
          `.o({Record:1})` prose). LocalGen CHECK=1 clean; runner-verify owed (spine ghost — the
           neutrality sweep is the gate: every Mag-reading Book must stay green with fixtures unmoved).
    ONE remaining fixed-depth spot, noted in-code: `Ra_offer_stock`'s `repli_loc = Cloud,page` wire-stamp
     is still depth-1 (only a Mag's own `%Cloud` pages). The husk itself crosses at any depth (`Repli_offer`
      walks the subtree); only the page-upsert key is depth-1, and nested pages don't exist yet, so nothing
       is stranded. Generalise that stamp WITH the deeper Mag shape when it is designed (see §9).

---

## 9. A Mag is writeable — tagging + share-as-Invite (ruled 2026-07-26, design)

The recurse ruling came paired with two forward directions. Neither is built; both are the shape the
 "figure out what the rest of the Mag is later" answer will grow into. Recorded here so the next pull
  starts from the human's words, not a guess.

- **A Mag can be WRITTEN — lightly.** "some kind of writing must be possible… `%note`? probably not too
   much." The steer is AGAINST a heavy authored-document Mag. The concrete germ the human reached for:
    **users go around tagging music, and a tag FAVOURS it slightly** — tags are a light, additive signal
     that nudges the shuffle/dial weighting (the `prandle` meander already has the branch-weight seam,
      §5/§7), not a rigid folder taxonomy. So Mag-writing ≈ *tags on Records* (and maybe a thin Mag-level
       note), feeding the culture-trace weighting — NOT a rich-text limb. Open in the small: does a tag
        ride the `%Record` (`%Tag,term:…` child) or a Mag-level index; how "slightly" the favour weights.
- **Sharing a Mag IS a kind of Invite (§4 default-sharability made concrete).** "when you share it
   specifically (we want this as a type of Invite as well) that cataloguing should be visible via the Mag
    medium." Two things fuse: the [[invite-front-door]] flow (QR/`?I=` scan-to-join, sealed prepub) and
     Mag delivery (§4 husk-first). **Sharing a Mag = minting an Invite whose payload is that Mag** — the
      recipient joins AND the shared Mag's cataloguing (its Records, tags, structure) explodes onto their
       scene through the Mag medium (§6 explode-on-connect), husk-first so it's cheap. The Invite is the
        will, the Mag is what arrives. This supersedes ad-hoc "send a link"; a shared collection travels
         as a first-class, catalogued, joinable thing. Next move: an Invite variant carrying `%Mag,of:…`
          (or the Mag berthed under the invite), proven by a Book crossing it two-tab.

---

## 1. The model — stock IS `%Mag**/%Record`

A holding does not float flat under a shelf; it lives under a **Mag**. The tree branches:

```
%MusuSelf,pub:<me>
  %Mag:shuffle,day:2026-07-19,page:1        ← the default holding — most of the radiostock is here
    %Record,id:… > %Preview,seq:0..15 > %Stream,seq:…
    %Record,id:… …                          (up to a page's worth, ~6, §5)
  %Mag:Faves                                ← durable curation
    %Record,id:… (or a %Card referring one held elsewhere)
  %Mag:Lineup                               ← the rolling programme the radio plays through
```

A **`%Mag`** is a container with a KIND (`shuffle | lineup | faves | culture`) and a coordinate
 (`day`/`page` for shuffle pages; a name for durable ones). Records branch under it. A Mag MAY hold
  a `%Record` outright (a holding) OR a `%Card,id:X` referring to one held under another Mag — the
   identity-per-shelf law (CLAUDE.md): the thing exists ONCE as its `%Record`; every other mention
    is a referring `%Card` wearing its own mainkey and carrying the join `id`. So `Faves` refers into
     `shuffle` by id; it does not duplicate the holding.

This revises the flat-stock ruling: stock branches now, because the branch IS the curation. The flat
 shelf was a way-station; the Mag is the home. **Landed 2026-07-19 (§0.1):** the real shape is
  `stock/ > %Mag:shuffle > %Cloud,page:N > %Record` — the Mag lives under the stock shelf (the
   shelf keeps its role as the holdings door; `Ra_home_self` callers never moved), pages are
    1-based `%Cloud,page` children of the ONE shuffle Mag, and `Ra_pub_of` climbs `c.up` to the
     shelf that wears `pub`. Friend mirrors stay FLAT until the wire cut carries Mag structure.

**Naming + where a Mag stores (ruled 2026-07-19).** A Mag takes after a Waft: `%Mag:<unique-name>` —
 the mainkey value IS the name, as `%Waft:<path>` does it — with pages riding INSIDE as children
  (`/1`, `/2`… the shuffle's `day`/`page` coordinate), never as sibling top-level Mags. Durable Mags
   STORE AS BERTHED WAFTS — the Berth is already exactly this seam (`Berth_dir`:
    `<root>/.jamsend/berth/<prepub>/<name>/toc.snap`, the wormhole dir-with-a-toc.snap shape homed
     under an identity, documents travelling WITH the music; `Musica_publish` and the Faves door
      berth this way today). Duration (§3) decides berthing: `faves`|authored Mags berth; `shuffle`
       pages and `culture` draws are tree-only and die by GC. Friend Mags NEVER berth (§6b).

## 2. The will above the Mag

A Mag does not appear from nowhere — a **will** produces it. Two wills, both particles:

- **will-to-have** — a `%want` (the pull already has this: `%parked_want`, `Repli_want_next`). "I
   want more like this / I want that friend's collection / I want the next shuffle page."
- **will-to-create** — a `%req` that goes and MAKES a Mag (wanders the share, draws a page, husk-casts
   a friend's crate). The will may live INSIDE the req that serves it — a `%req:mag,of:shuffle` whose
    do_fn wanders and mints `%Mag:shuffle/…/pN`, holding the want as its own arming state.

This is the belief-loop shape: a want holds, a req serves, a Mag lands, the want is satisfied (or
 re-arms for the next page). The Mag is the settled output of a will — legible, so a group can see
  what was wanted and what arrived.

## 3. The cursor and the duration

Every Mag carries a **cursor** — a playhead: which Card is current (playing / selected / next). This
 is the Lang analogy made durational and plural: a Waft's cursor marks the current What; a Mag's
  cursor marks the current track, MANY of them coexist (one per open Mag), and they persist.

**RETIRED 2026-08-05 (§0.0) — the table below is a dead letter, kept only to show what was dropped.**
 There is ONE kind, `%Mag:shuffle`. The four "kinds" were vocabulary pretending to be structure, and
  two of them were the same thing: `shuffle` (page exhausts → mint the next) and `lineup` (consume
   the head, top up the tail) describe ONE meandering Mag with Clouds falling off the front and
    joining the back. `faves` is incoherent as a holding — a fave lives in someone else's collection,
     so it is a pointer — and v1.0 does not have favouriting: **if you want a thing, you make a
      `%Heist`.** `culture` was the keep-8 draw trace, which is just the GC acting on shuffle.
   What SURVIVES from this section is the cursor itself (above) and §3b's `%Dogear` (below) —
    positions are real; kinds were not.

| ~~kind~~ | ~~duration~~ | ~~cursor behaviour~~ |
|---|---|---|
| ~~`shuffle/…/pN`~~ | ~~ephemeral — consumed, the next page supersedes it~~ | ~~advances forward; page exhausts → mint p(N+1)~~ |
| ~~`lineup`~~ | ~~rolling — a sliding window ahead of the listened-to cursor~~ | ~~the radio's playhead; consume the head, top up the tail~~ |
| ~~`faves`~~ | ~~durable — kept forever~~ | ~~free selection; no auto-advance~~ |
| ~~`culture`~~ | ~~GC'd — keep the last 8 draws~~ | ~~read-only trace; no live cursor~~ |

**§3b. Pointing across Mags (ruled 2026-07-19).** A Card may point INTO another Mag — "check this
 out, it sits in her Faves" — by wearing a `%Dogear` child: the cursor spine opens at the target Mag
  (`{Mag:'Faves'} → … → {Card,id:X}`) and resolves from the crate its provenance names (§6b: `%from`
   picks the crate, the cursor walks from there — O(depth), zero search). All scalar, so the pointer
    snaps, berths and replicates like anything (MusuResume proved the round-trip); C2's `%Renamed`
     heal follows the target across a reorganise through the same pipe the content came down; and a
      clean fail IS the husk texture (§4.4) — a pointer into bytes you cannot reach reads honestly as
       a promise. The bare `id` join stays the 1:1 identity (the Card IS the join); the Dogear is for
        POSITION — the thing as-it-sits in that other Mag. The one NEW convention the machinery needs
         is the root rule (resolve from the crate `%from` names); the cursor itself is proven.

## 4. Mags do Repli — the wire

The Mag is the **replication unit** — and (ruled 2026-07-19) the **default sharability**: sharing
 anything IS sharing a Mag, down to the one-card Mag as the atom (the retired `%Suggest`, §0). The
  Heist HEISTS; the Mag POINTS — "check this out" — and the pointed-at thing may sit inside another
   Mag (§3b). It crosses the wire on the existing Repli machinery, husk-first:

1. **Offer** — a `%Mag` husk crosses (`Repli_offer`-shaped): the Mag head + its `%Card`/`%Record`
    heads + each Record's `%Preview,seq` metadata, NO chunk bytes. A friend's whole shelf-of-Mags is
     a cheap catalog however much stock stands behind it.
2. **Context, when it exists** — a Mag/What/* is Records; anything ELSE found there exists to be
    GROUPED TO a Record — that is what non-Record content in a Mag is FOR (ruled 2026-07-19; no
     speculative inventory of what else might appear). A bare Record carries only its head. Some Mags
      have structure to present; some are flat sets. Do not force structure that is not there — and
       the Cursoring stays flexible + UNCONFUSIBLE over both shapes (trees AND big flat lists —
        proven in the MusuCursor Book: the C1–C3 tree scenes plus the flat/crowd scene). UI:Waft
         renders a big Mag BOUNDED: deepen chips at the edges (`/*38`, the [zS]tuffing idiom), never
          an unbounded list.
3. **Pull** — bytes are lazy: `Repli_want_next` fetches chunks on demand, `%parked_want` survives a
    reload (PereReborn's reconnect-epoch: the pull RESUMES, never restarts). No buffers ride the
     offer — but the client OPENS by asking for the first two chunks of the first two Records (the
      §5 warm start) and paces the rest off the playing head. **Starvation legibility par importo**:
       a starved track must SHOW where in its pipeline it is stuck — want parked | offered | pulling
        | chunks landing | decoded | scheduled — a legible stage on the particle, never a bare
         spinner.
4. **The unknowable** — a `%Card` that resolves to a held `%Record` is *knowable*; one that refers to
    bytes not pulled is a *husk* — a promise. The crate view must render the two textures distinctly
     (§6): honesty about how much of a room you can actually reach is a feature, not a gap.

## 5. The shuffle generator — warm-start pages

`%Mag:shuffle` is the default holding AND the discovery engine. One draw:

1. **Wander** — `Crate_nav_meander` (branch-weighted, `prandle`-seeded, no-enumeration) surfaces a
    SET of ~6 Records. Never a scan (§7).
2. **Warm-start** — eagerly fetch the first two chunks (`%Preview,seq:0..1`) of the first two Records
    of the page. Enough to begin.
3. **AUTO-START** — playback begins on Record 0 the moment its warm chunks land; Record 1 is queued;
    the `%Stream` continuation and the remaining page fetch behind the playing head.
4. **Advance** — cursor moves through the six; nearing the tail arms the will-to-create the next page
    (`p(N+1)`), so the shuffle never stalls at a page boundary.

The page size (6) and warm depth (2 records × 2 chunks) are the tuning knobs — a listening ramp, not
 a download-everything. This is the whole "you connect and it just plays" experience.

Vague candidate (the owner, 2026-08-05): as the shuffle scrolls, the Mag's BEGINNING should move up
 — perhaps a wire hint of the shape *"the first particle in A/B/C is now SomeThing"* (an `op` beside
  `dupe|delete`, or a Cloud-level cursor), so a mirror can trim the window it holds without the
   sender enumerating deletions one by one. Pairs with the flock-cursor era-GC rule (§0.0): never
    trim past a position anyone sits on.

## 6. Explode-on-connect — Mag as the main experience, and the limbic show|hide

**The headline:** connecting to a Pier EXPLODES their Mags onto the scene. Their `%MusuThem,pub:<them>`
 crate is a shelf-of-Mags; the offer husks them all cheaply; the scene blooms with their curated
  rooms; a shuffle over their collection autostarts. The friend arrives as their *taste*, immediately
   audible — not a directory you then go spelunking. Ruled 2026-07-19: explode-on-connect is the
    superpostmodernist `<h1>` — if the page is a tale of what happened, this is its header. In
     practice it kicks off catching up with their collection, and it PRESENTS as a
      switch-to-this-channel affordance beside the Radio UI — an arrival, not a takeover.

**show|hide becomes navigation, not a checklist.** The current `%Tuner:'glass'` + `cyto_crew` +
 `Tuner_toggle(t.c.mute[crew])` is a flat mute-index and it is currently broken. Retire it for a
  **topic-limb graph** — and the topic tree is NOT only music (ruled 2026-07-19): it is all the
   parts of the system in play, each subsystem|perception with its particular particles and its
    particular particle pump. An ATTENTION-SHARING DOMAIN, Housing-like: a dilute top-level view
     while things get ready, then the usual state is FOCUS — one perception held close, the rest
      folded. Within the looking-at-lots-of-music perception the limbs derive from Record metadata
       + the culture trace (terms, since they confused: a *culture-trace draw* = a `Stoker_mag_draw`
        `%Cloud`, the trail of what a dig landed; *authored* = a human-made list; *blend* =
         machine-proposed limbs the human prunes|renames). The idiom: an octopus holding a bunch of
          toys — it holds one up to you for a close look, and when you tap its head it folds the arm
           away again. Rooms toggle on|off independently, BUT **mutex on space**: a space-hungry room
            yields when a heavier one opens (an attention budget — LRU-ish, not the hard [s]-style
             total mutex), and the mutex is an ATTENTION MECHANISM with a sense of navigation — view
              states the Voro grasps coherently enough to REWIND (the moments|Yore spool is the rail)
               and to PUSH BACK on: proposing a view-state change, not only obeying toggles. This is
                the "make space" ask realised as a living layout instead of a list.

**Vtuffing / the crush reads Mags.** The crush misrepresents `%MusuThem/**` today because a flat pile
 has no structure to fold and `Voro_crushable|swarmable` judge nodes in isolation. Fold the MAGS
  (real, curated groupings) and the misrepresentation dissolves — the sub-cell stuffing renders a
   Mag's Cards, honouring husk (unknowable) vs held (knowable). Same move, both problems.

## 6b. Provenance + privacy — a Mag `%from` its creator (ruled 2026-07-19)

Every Mag wears `%from:<prepub>`: curation is authored and the author rides with it. Which makes a
 friend's Mags PERSONAL DATA — their lists of tracks, their taste, sitting on my disk. The rulings:

- **Friend Mags never berth.** They arrive as husks, live in the runtime tree while the awareness
   lasts (a high-security time), and are SHAVED OFF rather than hoarded. Reconnect re-explodes them
    cheaply (§4.1), so persisting them buys nothing but liability.
- **What persists is the ACTIVATED product of the awareness**: the `%Heist` — its set of track
   titles, the folder structure it wants to save into, and that Heist's state — plus whatever bytes
    a grant actually let me pull. Acting IS the consent moment; the Heist is its durable record.
- **Listening history is the same class of data** (§8): what I heard OF whom. Keep it OBLIQUE —
   bare ids, no titles|paths — enough to never repeat a track, nothing worth stealing.
- **Tombstones are untouchable**: `%UnGrant` decision-facts never drop (the revocation law) —
   privacy shaving removes CONTENT, never decisions.
- **Provenance is a LOOKUP, never a search (ruled 2026-07-19: owned but not persisted).** Whose a
   thing is must be readable ON it immediately — the Mag's `%from` + the per-friend crate keying
    (`%MusuThem,pub:<them>`, the SwarmShare-proven mirror law) — or every "where did this come from"
     becomes an every-Pier search query. Origin picks the crate; the cursor picks the position;
      resolution is a walk.
- <posited> The same ephemerality should reach the whole `%MusuThem` mirror (the husk catalog too) —
   shaving Mags while the full catalog mirror persists beside them would be theatre. Session matter,
    re-offered on connect.

## 7. Scale discipline — 200k tracks, never a jam

The invariant: **no path materialises the whole collection.**

- **Generation** wanders, never enumerates — `Crate_nav_meander` is 200k-safe by construction
   (hop-by-hop `dir_at`/`expand`, one directory per hop, `prandle`-seeded, GIVE_UP-bounded). The
    shuffle Mag inherits this for free.
- **The filesystem explorer** stays lazy — `dir_at`-at-a-time, virtualised, expands on demand. A
   browse view that tries to render 200k rows jams; a Mag-shaped view never asks to.
- **The working set is bounded by Mags** — you hold a page (~6) plus what is pinned; the rest is
   husks (promises) until a will pulls them. Memory is O(open Mags), not O(collection).

## 8. Open questions → rulings (the human, 2026-07-19)

- **The topic tree's source** — RULED: machine proposes, human prunes|renames, and the tree spans
   the whole SYSTEM, not just music (§6 — the attention-sharing domain).
- **Friend-Mag ownership** — still open in the small (theirs cross vs derived locally over the
   mirror), but bounded by §6b: however they arrive, they never persist.
- **Migration order** — RULED "sure, whatever": the agent owns migration TESTING now (which Books,
   what re-record order, keeping the sweep green) — human eyes only where a diff genuinely needs a
    mind.
- **The mutex policy** — RULED in kind: an attention mechanism with a SENSE OF NAVIGATION — view
   states the Voro can rewind (the moments|Yore spool) and push back on (§6). The budget metric
    (cell count? viewport area? an Attractor KNOB?) stays open in the small.
- **Cursor persistence** — RULED: ABSOLUTELY durable. Keep OBLIQUE track (bare ids, §6b) of Records
   heard and then of whole Mags exhausted, so the shuffle|dial NEVER hands you a duplicate across
    sessions. The `%Dogear` C3 berth is the seam; `radio.c.heard` is the runtime germ; the
     graduation is heard-Record ids → exhausted-Mag names.

---

## 10. The heisted body carries its quality — `%Original | %Lossy` (PROVEN green×2 2026-07-26 — split + %Lossy + tags)

The human floated it, then blessed it ("pat and say good"): **instead of `%Record/%Body` for the whole files
 we download, `%Record/%Original|%Lossy`** — the whole-file chunk particle's mainkey encodes the source
  quality, so a holding wears on its face whether it's a lossless master or a lossy copy. Scope (the human
   tightened it): this is JUST the downloaded/compressed WHOLE file — NOT multi-Pier sourcing of the "same"
    track. Then the format-upgrade dedup (Radio_todo "same track better format") becomes tractable — a
     `%Lossy` holding meeting an `%Original` offer is a legible upgrade — and a Mag can prefer the master.

**`%Original` is NOT a new name — it REALISES Orig.g's reserved master.** `Orig.g` header: "%Original master
 (rung 3 — the flac source that encodes DOWN to any grade) is later work" — no code minted it yet. A heisted
  FLAC *is* that master, so minting the lossless body as `%Original` fills the reserved concept; a heisted
   MP3 is `%Lossy` (never a master). Orig.g's export reads `%Preview|%Stream` (not `%Body`), so **Orig.g's
    code is untouched** by the rename. The names align by design — a good sign the model is coherent.

**CODE STATUS: applied (uncommitted) + LocalGen-clean + live-canary-verified — fixture re-record OWED.**
- The signal: `md.format.lossless` via `Crate_meta_from_tags` (Crate.g — added, with a `Crate_ext_lossless`
   allowlist fallback). Additive (unstamped) → neutral.
- The mint: Heist.g:122 routes through `Heist_body_new(rec, meta.lossless, s)`; reads through `Heist_body_at`
   (offer manifest) and `Heist_has_body` (the Heistation husk-probes). Transport unchanged (Repli keys chunks
    by binary VALUE + seq, mainkey-blind) — grep-confirmed zero other `{Body:1}` readers.
- **CANARY on the live runner (MusuHeist):** ran RED with `error:null` on every step (pure snap-diff, no
   exception), and the diff is EXACTLY `Body,seq:N,cid:X → Original,seq:N,cid:X` — **same cid, same seq, same
    buf** (cid = sha256 of the bytes, unchanged by a type-tag rename). Surgical. The WAV test tracks are
     lossless → all `%Original` (so `%Lossy` is UNPROVEN by fixtures — see below).

**Fixture re-record STILL OWED — blocked on a clean runner.** `%Body` snaps in ~1602 lines across **MusuBay,
 MusuHeist, MusuSoft** (+ **MusuBreach** = security/RaBreach territory, coordinate with that agent). The
  re-record could NOT run tonight: `49dee91d` (★claude) doubles as a live /BigSoundland tab whose **resident
   Sounditron probe bleeds** — it displaced the held MusuHeist and an `accept` grabbed Sounditron instead
    (reverted clean; see [[shared-runner-bleed]]). Needs a DEDICATED, non-BigSoundland, FSA-live runner. The
     accept is then a paste job: run each Book → verify `book`+uid are yours → confirm the diff is only
      `Body→Original`/`Lossy` → `accept` → rerun green.

**RE-RECORDED GREEN 2026-07-26** on dedicated runner `3c5238c6` (guarded book+uid before each accept —
 no bleed): **MusuHeist, MusuBay, MusuSoft** all green (`Body→Original`, WAV sources = lossless) — since
  BANKED by the human in `4f1e659a`. OWED: **MusuBreach** (RaBreach/security territory — coordinate with
   that agent before moving its fixtures).

**`%Lossy` PROVEN — new Book `MusuLossy` green×2 2026-07-26** (`3c5238c6`, dedicated). A census-only proof
 (no two-Pier heist needed — the grade decision lives in `Heist_census`'s mint): it plants THREE synthetic,
  deterministic sources into an isolated marrauding dir and censuses them together, each exercising a DISTINCT
   grade road — **WAV** (`Crate_wav_with_tags`, RIFF tags) → `%Original` via the ext allowlist; **Opus** (a
    real minimal Ogg/Opus built from Orig.g's `Orig_ogg_page`/`_opus_head`/`_opus_tags`, carrying OpusTags) →
     `%Lossy` because music-metadata gives Opus `lossless:undefined` so the grade falls to the extension (THE
      real production road for a live `.opus` library — a real `/music` `.opus` reads `undefined` too); **MP3**
       (hand-built ID3v2.3 + MPEG1-L3 frame headers) → `%Lossy` off `md.format.lossless===false`, the
        AUTHORITATIVE codec signal. The snap shows `%Record>%Lossy,seq:0` + `title`/`artist` read straight from
         the compressed headers — so the split AND the tag read-back are proven in ONE fixture. A 4th beat
          REASSEMBLES the opus `%Lossy` chunks into a whole file **left on disk** at `.jamsend/lossy-proof/`
           (OUTSIDE any `test-marrauding-of-*` namespace, so the Book-start sweep never touches it — the
            human's "leave the downloaded file" honoured) and proves `sha256 == body_hash` (chunks
             reconstruct the source byte-faithfully). Registered in Credence (magazine group, `brand_new:1`).
              See [[story-books-catalog]], [[new-book-cli-record-recipe]].

**TWO follow-ups the canary surfaced:**
1. **`%Lossy` is unproven** — ✅ **DONE — `MusuLossy` green×2** (see the block above). One correction to the
    original plan: music-metadata@11 gives Opus `format.lossless:undefined` (NOT `false`), so the opus lands
     `%Lossy` via the EXTENSION fallback, not the codec verdict — which is the real production road anyway.
      The MP3 branch is what exercises `format.lossless===false` (the authoritative codec signal). The Book
       also LEAVES the file on disk (`.jamsend/lossy-proof/`, outside the swept namespace) per the human's
        ask, though the SNAP is the real proof. **The gen-staleness gotcha bit here:** the runner loads the
         committed `gen/*.go`, and `gen/M/Heist.go` at HEAD still minted `%Body` (the split source was
          committed but its gen never regenerated) — the first run landed `%Body` until `LocalGen` rewrote
           `gen/M/{Crate,Heist}.go` + `gen/Story/Heistation.go` and the runner reloaded. Revert gen after.
2. **The `%Lossy` tag-writer gap (the human's "check our %Lossy encoder does tags good").** There is NO lossy
    whole-file encoder today: `Crate_wav_with_tags` writes tags but only for WAV (lossless); `Ra_encode_*`
     (WebCodecs Opus) makes untagged STREAM chunks for playback, not a file. So a `%Lossy` holding is only
      ever a *downloaded* already-lossy source (tags live in the pulled bytes, read back by
       `Crate_meta_from_tags`) — tags are fine there. The concern only bites IF we add a "compress-it-whole
        to save space" path; that encoder MUST write tags (ID3/VorbisComment), and none exists yet.

**The change is SMALL — the transport is already mainkey-blind.** Repli identifies a chunk by its *bytes*,
 never its mainkey: `Repli_is_binary(v)` tests `v instanceof Uint8Array`, `Repli_chunk_at(rec,s)` iterates
  `{seq:…}` across any mainkey, and the husk-skip is `Repli_chunk_bytes(child) != null` (Repli.g). So the
   husk, the pull, the seq-space (`%Preview`/`%Stream` share it), `Radio_map`, `Ra_chunk_map` — **all need
    zero change.** Only the 4 literal `{Body:1}` sites move:

1. **The signal — `md.format.lossless`, NOT the extension.** `Crate_meta_from_tags` (Crate.g:383) already
    `parseBuffer`s the bytes; `md.format.lossless` (and `md.format.codec`) sit right beside the `md.common`
     it reads. Return it: `lossless: !!(md.format && md.format.lossless)` (one line, additive — the return
      isn't snapped). The extension LIES (`.m4a` is ALAC-lossless OR AAC-lossy; `.ogg` is Vorbis OR FLAC),
       so classify off the parsed codec; fall back to an ext allowlist (`wav flac aiff aif alac ape wv tta
        dsf dff`) only when parse gives nothing.
2. **The mint — Heist.g:122.** `ext`/`meta` are in scope (`rec.sc.ext = ext` at :115). Pick the mainkey:
    `let bk = meta.lossless ? 'Original' : 'Lossy'` then `rec.i({ [bk]:1, seq:''+s })` — but stho may not
     take a computed key; use a two-branch `rec.i({ Original:1, … }) / rec.i({ Lossy:1, … })` or a helper
      `Heist_body_new(rec, bk, s)`. A record is ALL one quality, so one decision per record, not per chunk.
3. **The offer manifest — Heist.g:250.** `rec.o({ Body:1, seq })[0]` must read the WHOLE-FILE chunk
    specifically (it shares seq-space with `%Preview`/`%Stream`, so the generic `Repli_chunk_at` could grab
     the wrong one). Add `Heist_body_at(rec,s)` = `rec.o({Original:1,seq:''+s})[0] || rec.o({Lossy:1,seq:''+s})[0]`
      and route :250 through it.
4. **The Book husk-empty probes — Heistation.g:3573, 3916.** `!card.o({ Body:1 }).length` ("no bytes yet =
    unspent husk") → `!card.o({Original:1}).length && !card.o({Lossy:1}).length`, or a shared
     `Heist_has_body(card)` helper. These re-record with their Books anyway.

**Fixture re-record list (attended, runner-pinned 49dee91d):** MusuBay · MusuHeist · MusuSoft — straight
 re-record. **MusuBreach** — this is breach/RaBreach territory; **coordinate with the security agent** (the
  R1 owner) before moving its fixtures, since it may be mid-flight there.

**The paired question — "will it know all the autogen Mags as one cursor?" → YES, and it's BUILT.** The
 heard-memory is ONE shared set (`radio.c.heard`, now **bounded to 100** — §8's runtime germ, `Radio_heard_add`),
  so "have I heard this" is unified across every Mag. Per-Mag *position* is DERIVED, never stored:
   **`Radio_mag_cursor(radio, mag)`** (Radio.g, built 2026-07-26) walks the recursive census (`Ra_recs_deep`,
    §0b `Mag**`) and returns the last of the Mag's records that sits in the heard set — how far through THIS
     Mag you've got. Shape-agnostic, so all the autogen `%Mag:shuffle` pages read through the same one cursor
      logic off the same one heard-memory. The human's ruling stuck: browsing-history store DROPPED; the
       cursor is a pure read that can never rot. Graduation to durable (heard-ids → exhausted-Mag names,
        §8) is still the `%Dogear` berth seam when durable taste earns a home.

---

*This is a `_todo`: the arc and the open threads are meant to move. When the shape holds and the
 human has preened §1–§7, promote to `Mag_spec.md` and retire the todo half.*
