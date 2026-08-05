# Heist_todo.md — hauling music off a friend

You hear a track on a friend's radio, you press ⇊, and the original file lands in your collection
 under a folder you chose. That is the whole feature. This doc states how it works now, straight —
  the dated build strata it replaces are at `spec/history/Heist_todo_strata.md`, kept for the
   reasoning (the census rewrite, the `music/` teardown, the seven-bug adversarial review, the
    %Stream starve) rather than for anything current.

**Vocabulary changed 2026-08-05.** The intent particle was `%Keep`; the human ruled it "too weak a
 word". It is **`%Haul`** now, and its pier field is **`pub:`**, not `at:`. `%Heist` could not take
  the name — it is already the JOB particle a haul condenses into, and two shapes under one mainkey
   is the tell CLAUDE.md warns about. The arrangement the human named — `Haul,pub / Heist` — is
    therefore just what the tree already looks like. Method names are still `Heist_keep_*`: a
     cosmetic follow-on, cross-file, not worth a churn on its own.

---

## 0. Next move (read first)

1. **Live-test the 2026-08-05 batch** (all compiled, none verified on a real tab): the `%Haul`
    rename, the resume fix in §7, the `- `→`0 ` land rule in §5, and the four HaulFace fixes in §6.
     Two piers hauling from each other is the test the human has set up.
2. **`%pub` standardisation, part 2.** `%pub` means a pier's prepub — true everywhere except four
    identity carriers that put a FULL key under `pub`: the roster `%Identity` row (`Swarm.g:1946`),
     `%Peering` (`Swarm.g:1171`), `%HostedIdentity` and `%Runner` (`LiesLies.svelte:1593/1607`).
      Those want `fullpub`. Deliberately NOT in the same batch as the haul rename: it lands in the
       grant-verification path (`prepubOf(pub) === the HostedIdentity key`) and churns the Cluster
        fixtures, so a red there would have two suspects. Reads must fall back to `pub` for
         migration; the WIRE `page.pub` should stay as-is (renaming it breaks an older peer).
3. **The inter-track rest** (§4) — the pre-ask is supposed to hide the source's materialise behind
    the tail of the current track, and observably doesn't always. The `ev:'pulls'` electrode was
     added to show `cap` vs `drove` per haul; it needs a run with the trace armed (§9).
4. **A general `Dexie/$somewhere ↔ .jamsend/$somewhere` sync.** Haul persistence (§7) is one bespoke
    pipe; identity has its own bespoke half (`Identity_persist_todo.md` steps 3-4, `Swarm_spec.md
     §171`, both `[want]`). The human's read: these want to be ONE named-store-each-side mechanism.
      Not started, likely the next drift.
5. **`marrauding` is a typo** (double-r) living in the on-disk dir name, the verb, and literals in
    `Heistation.g` / `Berthation.g`. No recorded fixture contains the string, so the rename is safe
     whenever wanted — left alone only because those Book files are open in another thread.

---

## 1. The arc — ⇊ to bytes on disk

`RadioFace.svelte:84` → `Radio_keep` (`Radio.g:1477`) mints
 `%Haul:<title>,seed:<content-id>,pub:<their prepub>,state:'primed'` under my own loading zone
  (`Ra_home_shop`). Idempotent: a second press on the same seed no-ops. Own tracks are already held,
   so ⇊ only shows on a friend's track.

The states:

- **primed** — the seed is still the track you are listening to. LINGER: describe the folder
   (metadata heads only, cheap, no reads) so the face can show a track tree to tweak, default-keep
    the whole described folder, and dose the cell up so it is space-favoured in the clutter. Never
     ask for bytes while the seed is playing — that fights the live stream for the same wire.
- **wanted / asking** — legacy entry points, route into the same branch as primed.
- **pulling** — the seed stopped playing. Fold down (dose deleted), then materialise + pull + land
   every `%Pick` through the window in §4.
- **done** — the ✓ lingers ~8s, the Berth entry is forgotten immediately, then the haul drops
   itself. A finished haul is scaffolding, not ledger.
- **choosing / committing** — the dormant `HeistSetup.svelte` chooser path. See the landmine in §4.

## 2. The particles

    %Haul:<title>,seed:<content-id>,pub:<their prepub>,state:…   the standing intent, under Ra_home_shop
      %HaulBar,dontSnap                                          the controls cell (HaulBarFace)
      %Pick,ref:<id>[,artist,title,genre,landed]                 one track, one chip
      %Heist,at:<their prepub>                                   the JOB — filing decision + landing
    %Rummage                                                     an ask, in the mirror of whoever asked
    %Record,husk:1,rummage:<seed>                                a described folder track, not yet materialised

`%Haul` is imposed a face by mainkey (`glass_faces.ts`), so no snap ever changes because the glass
 chose to dress it. Under the nested glass a `%Haul` goes BARE and tessellates into its `%HaulBar`
  plus one `%Pick` chip per track.

A **haul-id** (`Heist_keep_id(me, base, path)`, sha256 of pub+path) is deliberately DISTINCT from the
 streaming content-id, so a materialised original can never upsert onto the seed's opus record.

## 3. The pump — there is no req pile

The heist is **not** driven by the req machine. No ttlilt, no maz level, no todo gate. It rides
 `Swarm_share_loop` (`Swarm.g:1578`): a plain detached `setTimeout` chain at **~600ms**,
  era-guarded, and **busy-guarded** — if the previous beat is still running the tick is SKIPPED, not
   overlapped (added 2026-07-30 after two concurrent steps double-wrote a landing).

Each tick: `post_do` → `Swarm_share_beat` → `Heist_keep_beat` (`Swarm.g:1742`, typeof-guarded and
 try-wrapped so a heist bug cannot break the radio share) → `Heist_keep_step` per haul.

**600ms is the heartbeat of the whole feature.** Every state transition costs at least one tick, and
 a beat that overruns costs more than one.

`Heist_keep_beat` also does the source-side housekeeping each beat: prune the `%Transfer` HUD's stale
 entries, sweep aged serve-libs (30min TTL, DETACHED so their `%Body` bytes GC), release
  after-serve any rec whose every page has crossed and whose last want is idle, and a ~256MB
   byte-cap belt that releases oldest-served-first. Those three together are what killed the 3GB
    source-side cliff.

## 4. The window — backpressure, and the rest between tracks

In the `pulling` branch (`Heist.g:~1528`):

- `heist_inflight` = **2** — at most two picks being worked at once.
- `heist_overlap` = **24** — open the second slot when the active track is within 24 chunks of done,
   so the next track's materialise starts while the current one finishes.
- A pick whose husk has no `total` fires `Heist_rummage_ask`, **throttled 4s**, and shuts the window
   (a pending materialise is one whole source-side file read).
- 45s bench watchdog, 5s breach cooldown.

**Why it still rests between tracks.** Three costs, each at least one 600ms tick apart:

1. The landing runs INSIDE the beat. A big track's land (read-back + hash) overruns 600ms, and the
    busy guard then skips ticks — so the beat that should have pre-asked track N+1 is the beat still
     finishing track N.
2. N+1 then has no `total`, so it must ask and wait for the source to materialise. That is the
    "filehandle takes time to start retrieving".
3. That ask is throttled 4s, so a mistimed one costs four seconds flat.

The fix is not a bigger `OVERLAP` — it is making the pre-ask independent of the landing beat.

**LANDMINE.** There are two pulling loops. `state:'pulling'` uses the gated one above.
 `state:'committing'` (`Heist.g:1670`) calls `Heist_keep_pull` — the legacy **ungated** loop that
  drives `Ra_pull_beat` for every un-landed pick every beat, which is the all-parallel behaviour
   that ate 3GB on the source. Only reachable from `HeistSetup.svelte:139`, the chooser path the
    code itself calls dormant. If every progress bar ever advances at once, that is where you are.

## 5. Landing

`Heist_land` → `Heist_land_stream`, per chunk: cid gate, `bin_write`/`bin_append`, release the buf.
 Then the wire digest, then a whole-file read-back + hash against `body_hash`. A mismatch lands
  nothing and stamps the breach.

**Paths.** A heist is a **cp**: the source's own filename and folder layout survive unchanged — tags
 catalog and display a track but never rename the file. `Heist_rel_for` picks the dest-root from the
  filing decision and the source's relative path rides underneath. If the haul carries a frozen
   `dirs`/`dirs_auto` pair, `dirs_auto` → `dirs` is substituted at the FRONT of the cp path **only
    when that record's own leading segments still match** — never a blind rename, so a multi-disc
     haul's CD1/CD2 divergence below the shared prefix survives.

**Segment safety** (`Heist_safe_seg`, directory levels only — `Heist_cp_path` does not come through
 it, per the cp ruling): `/` and NUL become `-`; everything else — spaces, punctuation, unicode,
  mixed case — is KEPT, because the tree should read like a record shelf. And since 2026-08-05, a
   **leading dash becomes `0 `**: a file or folder whose name starts with `-` cannot be handed to a
    shell command as a non-flag. `- chill` lands as `0 chill`, matching what the face already shows.

There is no `music/` prefix and no per-job root. Landing is the true FSA root, unconditionally, in
 dev and prod — except for the mardir seam in §8.

**Categories** sort topward with the same `0 ` marker (`Heist_cat_path`, nests via `/`). Both `-`
 and `0` still READ as a category everywhere, so nothing on disk needs touching; a collection
  migrates one touched category at a time.

## 6. The face

`HaulFace.svelte` (was `KeepFace.svelte`). Two separate, never-merged, never-enclosing hierarchies:

- **section** — mine. The category. Stamps its marker automatically, never typed.
- **directories** — theirs. The shared source-folder prefix across the described tracks. Wired into
   landing via `Heist_keep_set_dirs`, which freezes BOTH the override and the auto-detected value at
    edit time.

At rest each is a calm `/segment/segment/` breadcrumb. Click to edit: a row of chips, one per
 segment, each with its own × and now **editable in place**; a "+" gap before/between/after every
  chip (N segments ⇒ N+1 gaps) inserts at exactly that position. The ✓ **commits whatever is in the
   boxes** — it used to only close the editor, silently dropping typed-but-not-ENTERed text.
    Directories chunks word-break inside a name so one long source folder cannot set the cell's
     width. Group labels in the track tree no longer restate the directories row: the prefix match
      is MARKER-BLIND, so `- chill` / `0 chill` / `chill` are one directory.

`Heist_known_categories` / `Heist_known_dirs` scan the library's own `%Record.sc.path` to feed each
 breadcrumb's datalist, so a near-duplicate folder is a visible choice rather than an accident.

Global remembered defaults (`Heist_defaults_get/_set/_rehydrate`): the category a haul is set to
 becomes the next haul's default, dual-homed in `H.stashed` (Dexie) and a `HeistDefaults` Berth
  Waft. `directories` deliberately does not feed this — it is source-specific and means nothing for
   a different friend's structure.

A folder group of more than 5 tracks collapses by default (a real `<details>`).

**The face used to snap shut, and that was never a heist bug.** `replace()` publishes the empty half
 of its own transaction, and `agency_officing` (`Hovercraft.svelte:133`) replaces every actor's `w:`
  children every tick — so Vytui's `{#each vyto_worlds() as w (w)}` got a 0-length list once per
   tick and destroyed every face in the glass. Fixed at the READER: `ui/micro/hold.ts` plus both
    Vytui structural gates. Full chain and the three cures: `reactivity_docs.md`, first section.
     Confirmed live by the human 2026-08-05.

## 7. Persistence and resume

`Heist_keep_persist` writes `%HeistSeed,seed:` with real `%Pick` CHILDREN into the Berth at
 `.jamsend/berth/<prepub>/Heists`. `Heist_keep_rehydrate` replays them on boot straight into
  `pulling` (the human already confirmed the haul, before whatever reloaded), then
   `Heist_resume_sync` does the honest work of finding what is already correctly on disk. Resume is
    at the LIST level, never inside a file.

**The 2026-08-05 resume bug, and why it matters beyond itself.** Rehydrate ran once per radio-world
 life, and burnt that one shot on its FIRST LINE — before the Berth read. `nav` comes from
  `Crate_nav()`, and on the first beat after a reload it is null: the FSA handle restore is async and
   a fresh grant waits on a human click. So the first beat spent the single shot against a null nav
    and resume was dead for the entire page life, silently. Now: `if (!nav) return` without burning
     the gate, the gate burns only after the shelf is actually READ, and a throwing `Berth_open`
      counts to 10 rather than latching. Same treatment for the caller's `catch`, which had the
       identical shape.

The general lesson: **a one-shot gate must be spent on success, not on attempt.** Anything gated
 `if (x) return; x = 1` at the top of an async boot-order-sensitive function has this bug latent.

Berth entries write `pub` from 2026-08-05 and READ `pub || at`, so a heist already persisted under
 the old key still resumes.

## 8. The test namespace — mardir and sweep

`Heist_mardir(w)` returns `w.c.mardir` or `''`. **`''` means the collection root** — production, and
 every existing path. Every live landing / newlyadded / resume-sync call routes through it.

This is a seam, not machinery. There are three small things and nothing schedules any of them:
 `Heist_meta_dir()` (returns `'.jamsend'`), `Heist_marrauding(runid, nick)` (builds
  `.jamsend/test-marrauding-of-<runid>/<nick>`), and `Heist_sweep()` (14 lines: recurse,
   `deleteEntry` every file, keep the dir skeleton). Books hand-call the sweep at start and end.

Until 2026-08-05 the marauding header claimed the app passed a real run uid. It did not — both live
 landing calls passed a literal `''`, so a heist from a live tab landed indistinguishably in the real
  collection, unsweepable. Setting one runtime knob now buys a sweepable namespace with landing,
   newlyadded and sweep all unchanged. Runtime-only (`.c`), so no snap moves and production is
    byte-identical.

`Heist_spawn_swap(job, rel)` rides alongside for the human's own app-testing: any path segment equal
 to `spawn` (marker-blind, so `- spawn` / `0 spawn` / `spawn` all match) is rewritten to
  `0 heisted-<from8>-<to8>`.

**Sweeps do not delete directories, on purpose.** A deleted-then-recreated directory strands the
 nav's cached FSA handle — "the landing that never lands". Aborted runs therefore leave an empty
  skeleton. Changing this means chasing the handle cache first; it is a real ask, not a one-liner.

## 9. Verifying

Books, always on a LIVE runner (`scripts/runner_ask.mjs`), never `Story_cli_run.mjs`: **MusuHeist**
 is the end-to-end haul, **Sounditron** the resident-session picture, **MusuLossy** the sweep. The
  snap-fixture diff is the gate; when a run goes red, diff the actual mismatch with
   `story_repl.mjs diff` rather than stopping at "red" — the last two reds were both pure fixture
    staleness.

The supply/heist trace ring (`Radio_trace` → `M.c.supply_trace`, capped 300, ~1 Hz `dial` mark, so
 only ~4.5 min of history) carries `land` and `pulls` marks for this feature. It flushes to
  `wormhole/_trace/` via `Lies_dump_supply`, armed by the **same** `socklog_armed()` flag as socklog
   (the 🪪 hatch toggle / `?socklog` / `?watch`), no reload needed.

**Caveat that will waste your afternoon:** both dumps early-return unless `Lies_role(w)` is `editor`
 or `runner`, and a plain app tab has no role. Marks pile up in memory and never reach disk. Heist
  in a runner-booted tab, or drop the role gate on the supply dump.

`scripts/runner_shot.mjs` is the only way to see the render — pixels never round-trip a fixture.

## 10. Performance, as of 2026-08-05

Two real fixes landed after the human reported the downloader burning CPU and the uploader holding
 comparable memory:

- **O(N²) gone.** `Heist_land_stream` called `Ra_chunk_map(rec)[s]` per chunk — rebuilding the whole
   map for every chunk of every file. Now `Repli_chunk_bytes(ch)` off the chunk directly. Two
    sibling probes in `Radio_play_id` went to `Repli_chunk_at(x, 0)` for the same reason. (Still
     open elsewhere: `Radio.g:1299` has an `Ra_chunk_map(r)[0]` probe inside a loop over every
      record in `Riffle_deal_shelf` — flagged for that thread, not touched here.)
- **Native hashing.** `Heist_hash` and the per-chunk cid gate use `sha256_hex_fast` (crypto.subtle)
   rather than the pure-JS noble path that was 51.8% of the frame. The FORMAT CONTRACT is
    byte-identical between the two — see `Hashly.ts`. There is no native STREAMING api, so the
     incremental wire digest is still the one pure-JS pass; whether to drop it is an owed ruling.

## 11. Parked

The klepto engine (scope B, `Heist_design.md`) stays BUILT and PARKED. Production is scope A, above.
 `HeistSetup.svelte` — the fullscreen chooser Lens — is orphaned; nothing raises it, and the
  `choosing`/`committing` states exist only to serve it. Retire both together, mind the §4 landmine.
