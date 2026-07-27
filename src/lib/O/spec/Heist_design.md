# Heist_design.md — keeping a copy of what you're hearing (2026-07-27)

Heist = **you're listening to a track, and you want to keep it** (and probably the rest
 of the directory it came from). This assembles the design so you can read + preen before
  a build. Not self-blessed spec.

**Two scopes, and the doc had them backwards.** The near, production thing is the **simple
 directory heist** — grab the folder the currently-playing track came from, the way the old
  `ghost/Pirate` did. The far thing is **klepto** — point at a whole Pier and take everything,
   "communist-minding" a collection. This rewrite promotes the simple heist and **parks klepto
    until after production** (human ruling, 2026-07-27: "needing to actively seek the music is
     good for now").

**Verification basis:** `[LIVE]` = real caller in shipped `.g`/`.svelte`; `[BOOK]` = green in
 `Heistation` only, no live caller; `[OWED]` = not built.

---

## HUMAN — what's ruled, what's still yours

**Ruled 2026-07-27:**
1. **klepto → after production.** The production heist is the **simple directory grab** of where
    the playing track came from (scope A). The point-at-a-Pier / take-everything engine (scope B)
     stays built-but-parked. "klepto was for communist-minding it, but needing to actively seek
      the music is good for now."
2. **`%Tombstone` is GONE.** Remembered-denials are struck, not just condemned. **Mag cursors move
    us past needing them** (a heist re-digs from source and the cursor/`Heist_held` catalog-identity
     skip already dedups); and there are **no liked/disliked artists|tracks yet** for a tombstone to
      encode. Tidy every mention out (this doc done; `Radio_todo`/`Radio_spec`/`Mag_todo`/
       `Sharing_design`/`Radio_multicast_todo`/`Follow_todo`/`Radio_lowlevel` still name it — a
        sweep offered, not yet run; `history/` left as record).
3. **Present the directory-structure chooser.** The simple heist MUST show the source folder tree
    and let you pick (the old Pirating `%places` chooser). The current doc/engine had no mention.

**Still yours to call:**
- **Naming (open).** Is the simple heist its own thing — **`RaHeist`** (it's Radio-scoped: it acts
   on whatever the radio is playing) — or a **sub-What / sub-region** carved beside the klepto arcs
    in `Heist.g`? *Recommend:* a named `//#region raheist` (call it `RaHeist`) so the parked klepto
     regions don't entangle the production path; promote to its own `.g` only if it grows.
- **Landing-tree fork** (was ruling #2, still live): does **genre stay a top folder** above the
   chooser's `$directory/...` structure, or does the chosen source structure land as-is? The old
    Pirating let the user *disbelieve* directories/categories per-checkbox — that flexibility is the
     answer, not a fixed tree. Confirm we keep the chooser's per-level toggles.
- **Stream-to-disk proven live** (was ruling #7, still live): landing re-hashes the whole assembled
   file in memory; incremental sha256 + per-page landing must be **proven on a real wire**, not built
    blind. In scope for the first build, or deferred to the crossing?
- **recently-added tracking (a want, not built).** "We have no mechanism for tracking what you've
   been chucking in your collection recently… we want that." *Seed exists:* the probation
    `newlyadded` log (below). Grow it into a real "lately added" surface — but that's its own thread.

---

## Scope A — the simple directory heist (production) — "RaHeist?"

**The gesture:** while the radio plays a track, one control says *keep this* — and keeping it means
 grabbing the **directory it came from** into your own collection, with a chooser so you take what
  you want and skip what you don't.

**The precedent is real and worked:** `src/lib/ghost/Pirating.svelte` (legacy `lib/ghost`, the old
 🏴 replication station — **reference behaviour, not code to revive**; production lives in `.g` now).
  Its shape, to port:
1. **Point at the playing track's source uri.** The currently-playing track carries a provenance (the
    `by:`/`via` we stamp on a radio pick — `radio.sc.by`, `Radio.g:316`). That resolves to a source
     Pier + a uri in their share.
2. **Inflate the directory** around that uri — `cytotermi_pirating_descripted` walked the source's
    directory tree into `%places` (`%place,bit,uri` per path segment; children marked
     `collection`/`directory`/`blob`, a per-file `suggested_rename`).
3. **The directory-structure chooser** (`[OWED]` as a `.g` face — the one genuinely missing UI). The
    old one was a checkbox tree: keep/skip each **directory**, each **collection/category**, the single
     **blob**, an optional **rename**, and the two meta-toggles `disbelieve_directories` /
      `only_categories` (collect loose tracks into one place vs. mirror the source's folders). This is
       "present quite simply… a few controls" applied to *what to pull*.
4. **Pull the chosen blobs** — the old flow's `o_pull`/`i_pull` backpressured spool is exactly today's
    `Ra_pull_beat` want-loop; the chosen `%place`s become a directory-scoped job.
5. **Land byte-faithful into your FSA collection**, resumable — `Heist_land` re-hashes, verifies
    `body_hash`, `bin_write`s under the chosen path, catalogues via `Ra_rec_home`. Resume/partial-file
     handling was in the old `check_existing_downloads`; the new landing side is `[LIVE]`-ready.

**What's already built vs. owed for scope A:**
- *Built (`[BOOK]`/`[LIVE]`):* the pull want-loop (`Ra_pull_beat`), landing (`Heist_land` — re-hash,
   verify, `bin_write`, catalogue, kid-safe non-audio skip `Crate.g:389`, FSA stale-handle self-heal),
    dedup-at-door (`Heist_held`), the Berth persistence.
- *Owed (`[OWED]`):* (a) the **directory-inflate** step in `.g` (the `descripted` walk of a source
   folder — the old `rapiracy_descripted` drift), (b) the **chooser face** (the `%places` checkbox
    tree), (c) the **wiring from the playing track's provenance** to a directory-scoped job, (d) the
     **live pull driver** (see Frontier — Heist has no `Heist_share_up` analogue yet).

**The caveat that dominates all of it:** the source folder lives on *someone else's machine*, so real
 bytes crossing is blocked on the **same `Socket_real` crossing as streaming** (`Frontier.md §1`). Over
  loopback the whole scope-A flow can be made real and demoed; crossing two machines is the gate.

---

## Scope B — klepto / point-at-a-Pier (BUILT, PARKED until after production)

The heavier engine already green in `Heistation`. Kept here as the map for later; **not the near build.**

**Hard arc** (`Ghost/M/Heist.g`, engine): `Heist_census` (source walks files → `%Record` + `%Body,seq`,
 full-file `body_hash`) → `Heist_job(w, at:<pier>, filings)` (mint the job, artist→genre believe/disbelieve)
  → `Heist_offer_all` (source casts its catalog as chunkless husks; `Heist_offer_vouch` stamps an
   ed25519 origin sig — **retires at M2** into a plain Repli pull) → `Heist_vouch_ok` gate → **`Heist_beat`**
    (the pull pass every beat while the job stands: dedup, vouch, `Ra_pull_beat` wants missing pages, a
     complete record → `Heist_land`) → `Heist_manifest` (pure-read look-before-commit; resume side `[OWED]`)
      → probation (`newlyadded` log; `Heist_feel` love/drop) → `Heist_flatten` (job + mirror delete,
       collection stays). All `[BOOK]`.

**Soft arc** (`Heist.g //#region soft`): `Heist_wish(sentence, no at)` → `Heist_ask` (wish crosses a
 granted wire as a husk) → `Heist_match` (far side contains-matches title|artist|genre|album, stamps a
  `%Lead` per hit) → `Heist_leads` → **`Heist_condense`** `[LIVE]` (choosing a Lead hardens the wish:
   stamps `at`+`chose`, mints the `%filing`). This is the **only live klepto caller**
    (`HeistFace.svelte:43`, and `Pirating.svelte`).

**HeistFace** (`src/lib/O/ui/HeistFace.svelte`, since you don't remember it): the glass face for a
 `%Heist` node, imposed by mainkey (never wears `sc.face`, so sealed Books stay Voro-blind). It renders
  one of two shapes — **POSED** (a needs-nugget, `%Need` children ticking `met` as the world provides)
   or **SOFT** (the wish sentence + accumulating `%Lead` rows, each with a **take** button gated
    `soft = sc.wish && !sc.at`). `take()` calls only `Heist_condense` today — it stamps the choice and
     stops; **no pull is kicked** (the "pull machinery takes over" comment is aspirational). This is the
      **klepto** UI — it is *not* the scope-A directory chooser, which is still owed.

---

## Decided rulings (kept)

- **cp-landing** (`Radio_spec §4`, ~L453): offer → manifest → pull → land; whole-file `body_hash`
   verified at land; **copy not rename; non-audio siblings never copy** (kid-safe, `Crate.g:389`);
    **dedup bias-to-keep** (`Heist_held`, catalog identity — the only load-bearing skip). Open sub-ruling
     (`Mag_todo` ~L51): a landed card's Mag home should come from the heist's own naming (a landing Mag),
      not the shuffle.
- **The Berth** (`Radio_todo §11.7`): where a Pier's documents persist —
   `<root>/.jamsend/berth/<prepub>/<Waftname>/toc.snap`. **✔ BUILT** (`Heist.g //#region berth`), LocalGen-green;
    the `MusuBerth` Book is live-gate `[OWED]`. Holds `Waft:Listening/Taste/Filings/Map`.
- **M2-retire**: `Heist_offer_all` is the first thing to retire at M2 into a plain Repli pull (M2 itself
   live-green×2). A provisional seam — don't build the scope-A driver *on* it.

**Struck:** `%Tombstone` (remembered denials) — gone per ruling #2; Mag cursors + `Heist_held` cover dedup,
 and there are no like/dislike facts yet for it to hold.

---

## The recently-added want (seed → thread)

"No mechanism for tracking what you've been chucking in your collection recently — we want that." The
 **seed already exists**: heist landing logs each arrival to a probation `newlyadded` file
  (`.jamsend/.../newlyadded`, `Heist_newlyadded_note`), and `Heist_feel` graduates (`love`) or denies
   (`drop`). That's a per-heist arrival log, not a collection-wide "lately added" view. Growing it into a
    real surface — everything that entered your collection this week, however it arrived (heist, direct
     add, FSA drop) — is its own thread; noted here so it isn't lost, not folded into the first build.

---

## The frontier — what a scope-A build actually needs

The engine verbs it would call all **exist**; three things must be **written**, plus one chooser face:

1. `[OWED]` **The directory-inflate step in `.g`.** Port the old `descripted` walk: given the playing
    track's source uri, ask the source to describe the surrounding folder → `%places` tree. (Old ref:
     `Pirating.svelte` `rapiracy_descripted` + `cytotermi_pirating_descripted`.)
2. `[OWED]` **The chooser face** — a `.g` glass face over the `%places` tree with the per-level
    keep/skip/rename/`only_categories` toggles. The single genuinely-missing UI. *(Not HeistFace — that's
     the klepto wish UI.)*
3. `[OWED]` **The live pull driver** — Heist's missing analogue of `Swarm_share_loop`. Nothing arms
    Repli, builds the quarantine mirror, and beats `Heist_beat → Heist_land` until the directory-job
     drains, then `Heist_flatten`. In `Heistation` this is hand-driven (`Heist_drive`/`Heist_flow`,
      Book-only). *Exists:* `Heist_beat`, `Heist_land`, `Heist_flatten`, `Ra_pull_beat`, `Repli_offer`.
       *Write:* the loop driver + the gesture that mints the directory-scoped job from the chooser.
4. **And the gate:** all of the above over loopback proves nothing about the wire; real bytes from a
    friend's folder are blocked on the same `Socket_real` crossing as streaming (`Frontier.md §1`).

---

## Where the design content lived (provenance)

- `src/lib/ghost/Pirating.svelte` + `lib/mostly/Pirate.svelte` — **the legacy directory-heist** (the
   scope-A precedent: `%io:radiopiracy`, `%places` chooser, backpressured `o_pull`/`i_pull` spool,
    resumable). Reference behaviour; production is `.g`.
- `Radio_todo.md` — §9 (Pier reality ~L754), §10 (Klepto ~L886), §10.1 (honest wire ledger ~L929),
   §10.2 (as-built ~L942), §11.7 (the Berth ~L1295), §12.5 (~L1621), cp-landing ~L1459.
- `Radio_spec.md` — §4 Heist (built/gate-owed + cp-landing ~L453), §5A culture ladder, §5 Pier.
- `Ghost/M/Heist.g` (engine + `//#region soft`/`//#region berth`), `Ghost/Story/Heistation.g`
   (`MusuHeist`/`MusuSoft`/`MusuBerth`/`MusuBreach`/`MusuBay`/`MusuLossy`), `src/lib/O/ui/HeistFace.svelte`
    + `glass_kinds.ts:25`, `Ghost/M/Ra.g` (landing), `Ghost/M/Crate.g` (kid-safe census),
     `Ghost/S/Swarm.g` (`Swarm_share_*`, the live share analogue).
