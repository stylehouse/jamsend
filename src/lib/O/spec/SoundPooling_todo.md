# SoundPooling_todo.md — the pool: whole tracks kept near you, chosen by listening

*(Front door, rewritten 2026-11-10 from the 2,200-line evening trail now at `history/SoundPooling_evenings_todo.md`. It describes
 the field; the trail holds the reasons. How the pool sits between the two roads music moves by is `Radio_todo.md` §0.f; read
  that first.)*

*A citation elsewhere of `SoundPooling_todo` §0.0, §0.2a, §0.5–§0.8 or §1–§2 means the HISTORY file: those section numbers live
 there.*

## 0. What SoundPooling is

**For a person:** a phone browser can't keep a music folder, so SoundPooling keeps a rolling handful of whole tracks inside the
 browser (OPFS), within a budget in MB you set in the 🏊 cell, from your crew (your own devices), your friends, or both. Something to
  play with no signal, topped up and turned over whenever a source is on. **Off until you switch it on.** On a laptop with a folder,
   the same feature backs onto the folder instead (*"SoundPooling is ALWAYS the one thing, only its backing varies"*).

**For the machine:** a steward on the radio world decides what the pool should hold (a goal), compares it with what it holds (a diff),
 and sends work: **press** (copy from my own library), **pull** (fetch from a holder, crew first, over a `%Reach`), **evict** (over
  the cap). It is a keeping road (Road 2 in `Radio_todo.md` §0.f), so a pooled track is a whole file, not radio chunks.

## 0.a The direction (owner, 2026-11-10)

*"we only FOUND the track via %Preview, we Pool the %Lofi!"*

1. **Found by listening, kept as a %Lofi.** A track enters the pool because it came by on the radio in the ordinary way, through its
    `%Preview`, and was not Nay'd. The pool then keeps the WHOLE track as a **%Lofi**: one Ogg file in OPFS. Not the preview chunks.
2. **One %Record, its renditions as chunk kinds** (owner, 2026-11-10): `Mag**/%Record/(%Original|%Preview|%Stream|%Lofi)`.  The
    `%Record` IS the track; each child kind is a seq of chunks of ONE rendition's bytes: `%Original` = the file as given (whatever
     its codec), `%Preview`/`%Stream` = the Opus radio encode (one seq space, as now), `%Lofi` = the small whole Ogg.  A body may
      hold any subset; the pool is a Mag of Records that hold `%Lofi`.  This replaces: the pool's `%Record,lofi:1,grade:ogg128`
       (a Record that IS a lofi file rather than HAVING one — the 08-27 ruling, now superseded), the spec's top-level `%Original`
        master and `%Blob,grade:` (Radio_spec §2.4 "the settled trio" — never built beyond Orig's `%Blob`), and Heist's `%Lossy`
         (an already-compressed original is just `%Original`; lossless-ness is a scalar on the Record).
    **In transit: the Heistway, so Repli stays rendition-blind.**  Repli addresses a chunk by `id` + `seq` only (mainkey-blind, so
     `%Preview`→`%Stream` read as one run), and two renditions on one id would collide at seq 0.  They never share an id in flight:
      a whole-file rendition travels as a HEIST, which the holder materialises under its own temporary rummage id
       (`Heist_materialise_one`, `lofi` flag ⇒ the Vorbis transcode), pulled by Repli on that id, landed by `Heist_catalog_land`.
        **SoundPooling already rides it**: a fill mints `%Heist,into:'pool',why:'fill'` in the shop (Pool.g ~1543).  So the change is
         only the shape AT REST — on landing, the track's `%Record` gains a `%Lofi` (the file under `pool/`), instead of the pool
          minting a second `%Record` that is the file.  Radio's want stays "Record/Preview|Stream"; a heist's stays "this id's bytes".
3. **The radio plays files.** The radio should learn to play a local file directly, starting mid-track: your own originals (today
    they're always transcoded to Opus first) AND pool %Lofis. That retires the two contortions below (the carry, the pocket encode).
4. **A close-enough source IS the %Lofi.** If the original is already an Ogg near the lofi bitrate (≲150k), keep it whole and call
    it the %Lofi; don't re-encode.
5. **Candidate: a heard track already is a %Lofi.** A track heard to its end has crossed as Opus chunks (`%Preview` then `%Stream`).
    `Orig_ogg_export` (Orig.g) muxes a Record's chunks into a real Ogg Opus file with no re-encode. So "keep what I just heard" could
     cost no second fetch. Gaps: the intro before the preview's 30–70% cut point (the `%Prehead` run covers 0:00 only if it was
      pulled), and very old phones lack Opus-in-Ogg in their own player (ours decodes Opus itself, so only an exported file is at
       risk). Today's lofi is **Vorbis** 128k (the daemon's ffmpeg) for exactly that reason.

6. **The holder's Pooling Mag** (owner 2026-11-11, proposed: *"a Mag of radiostock and a separate Mag of Pooling tracks, which
    starts empty but a cursor into it starts the process of generation"*).  Today a pooled copy is a second `%Record` on MY
     `%SoundPooling/stock` shelf, joined to the friend's mirror only by `of:`, and its bytes cross under a per-client temporary rummage
      id — so a lofi made for one client can never feed another.  Instead the holder publishes a **Pooling Mag** beside radiostock:
       `%Card`s naming Records that have, or will have, a `%Lofi`.  Clients' cursors into it (the listeners'-cursor idiom, `Mag:Listening`)
        decide what the holder transcodes next; a lofi with a STABLE id is pulled by any number of sinks (Repli addresses id+seq), so many
         vague wants cost one transcode, and a sharp want jumps the queue.  Retires the rummage id for pool fills, the pool's own catalog
          (my pool = a mirror of their Pooling Mag + the files I kept) and the `of:` join; the radio and the pool read the holder's two
           Mags, and either hunger raises the same server-side cursor (§0.d 1b).  At rest, still §0.a.2: one `%Record` with a `%Lofi`.
    **Widened (owner 2026-11-11): TWO STREAMS, each a Mag at both ends** — radiostock = the Preview stream, Pooling = the Lofi
     stream.  *"a client reading a Mag, then wanting more Mag because of where its eyes have got down to, then more comes across,
      which might involve further iterating the generator of some %Records."*  What came through: radiostock IS a paged Mag
       (`%Cloud` pages) that Repli mirrors into `%Theirs/stock` (`Ra_offer_stock`), and the Stoker digs more when listeners run
        low (`Stoker_hunger`).  What didn't: the eyes are a per-track `listened` side-message (`Stoker_tell_listened` →
         `Mag:Listening/%Listener/%Heard`), not a cursor whose reach IS a Repli want for the next page; the shelf is a rolling pool
          (dig/cull ~44), not a stream generated ahead of its furthest reader; and the pool has no Mag at all.  Build order: the
           Lofi stream first (empty today, nothing to break), then move radiostock onto the same page-want-as-cursor.
    **The pages scroll forever** (owner): a stream is an endless run of pages, never a capped shelf that culls — one Mag** space
     that scrolls forever is the ideal, pages are the fine-grained form of it.  **NEXT SESSION STARTS HERE**, with §0.a.7 below:
      the same design worked through as a Seem (fog Regards, an ahead sphere, wants as rows) and its build order.
    **The plain statement (owner 2026-11-11):** *"it doesn't take them from the random radio Mag, it takes it from the Mine/Pooling to
     give to Their/Pooling, which is the one that gets stored on this tab."*  So:
     | holder | → Repli → | this tab |
     |---|---|---|
     | `Mine/stock/Mag:shuffle` — the Preview stream (radiostock) | | `Theirs/stock/Mag:shuffle` — the radio dials it; nothing kept |
     | `Mine/…/Mag:Pooling` — the Lofi stream | | `Theirs/…/Mag:Pooling` — **this IS the pool**; its lofis kept in OPFS |
     "From friends" = mirror their Pooling Mag; the budget = how far down its pages this tab reads and keeps.  No `Mag:Pooling`
      exists yet: today every shelf pages into one `Mag:shuffle` (`Ra.g` ~835), and the pool is MY `%SoundPooling/stock/Mag:shuffle`,
       filled by my steward drawing random ids off the friend's RADIO mirror and heisting each under a rummage id (`of:` join).
        All of that goes; consent and budget stay.
    **What goes on the Pooling pages — the holder's cursor** (owner 2026-11-11: *"a SP quota half-liked and half-random … do we keep tracks
     they liked in there for a month or something? it's a light cone wandering around their music collection"*).  Today's Cell:Pooling
      splits the budget between compartments: `rolling` (random) and `recent` (my landed takes, the "recent" tickbox), 50/50 by
       `share`; a `tally` compartment (liked/kept) exists in `Pool_goal` but switch-on never declares it, and nothing keeps by age —
        the roll evicts only over cap.  The Pooling Mag should carry the cursor's picks: part LIKED (stays a while — "a month or something",
         unruled), part a random WANDER through the collection that moves on; minus what this listener Nay'd.  Which side the cursor
          lives on (the holder's pages, or this tab's reading of them) is the open design question.

    **The liked half — BUILT 2026-11-11, this tab's side** (owner: *"that's a good feature, have that switched on... be working
     with Yay|Nay data"*).  Cell:Pooling's new tickbox "keeping [x] what you Yay (for a month)" declares a third compartment,
      `%Pool,name:liked,take:liked,share:50,keep_days:30,lends` (`Ra_pool_liked_set`; poke `Ra_pool_liked_toggle`).  It is on at
       the first yes like recent, then the human's.  Rules (`Pool_draw_tally`, `Pool_goal`):
     - **Draw:** a CURRENT Yay (a later Nay or Meh ends it; barred ids skip as ever), hearted in the last 30 days, that can
        arrive (held = press, or a mirror holds it).  Newest first.  The window needs `now_s`, which is only set on live pages, so
         Books draw as before.
     - **Picks first:** a lending compartment goes before the declared order, so a Yay'd track is kept as liked, not
        drawn as "circulating" and then rolled away.
     - **Lends:** whatever room it leaves goes to the random draws, and comes back as Yays arrive (the roll trims the wander).
     - **Ages out:** past 30 days the track leaves the goal, and the roll lets it go like any other.
     - **Recent off** now gives its share to rolling (`Ra_pool_drop_to_rolling`) instead of setting rolling to 100, which
        squashed liked to nothing.
    **And a real bug, found on the way:** a live page's heard Mag hangs on the Identity (`Heard_home_find`), but
     `Heard_tally`/`Heard_latest` climbed from the Mine shelf.  So the pool read `tally:0 latest:0` on every live page:
      no Yay, keep or played-through ever reached its taste.  The live steward and `Pool_facts` now hand in `Heard_mags(w, me)`.
       On eed it went to `tally:179 latest:56`.  eed has 0 real Yays yet: its 9 hearted Cards are `for:pool` machine presses,
        which the tally rightly ignores.  So the liked half reads empty and lends everything.  **Owed:** a real ♥ on a friend's
         track, then watch it land as `pool:liked` (the Provisions `Want` says which compartment).
    **Heard moves on — BUILT 2026-11-11** (owner: *"on a SP endpoint meeting, everything that's been heard can go, I suppose"*).
     `Radio_pool_heard` stamps `heard:1` on a pool card when the radio lets go of it (played out or skipped).  It's done at the
      let-go, so the steward never evicts the card that's playing.  Live only, no bump.  Then:
     - **The wander drops it:** `Pool_draw_random` neither counts it as sediment nor redraws its original from the mirror.
     - **The liked half still keeps a Yay'd one:** it draws first.
     - **Swapped out when a friend is met:** `Pool_diff` marks the evict `heard` ("heard — making room").  `Pool_roll` lets one
        replacement pull per heard card at once instead of one per 10 minutes, and the evict still waits for the arrival (the one law).
     - `Pool_facts.pooled.heard` counts them.  Verified on eed (`heard:1` after the first let-go).
    **Two more found on eed the same evening:**
     - **No ♥/👎 on some pool tracks.** The face showed them only for `by` or `of:`.  A friend's file that was already a
        close-enough Ogg is pooled whole under the original's id (no `of`), so it read as MY record (7 of eed's 24 cards).
        `Ra_rec_pooled` (`of` | `lofi` | under %SoundPooling | `rec.c.pooled`, which Radio_open sets from `Radio_pool_card`)
         now drives the face, `Heard_take_pub` (the original, no holder — same as an `of:` card), `Radio_like`'s mine-test and
          `Radio_keep`.
     - **A landing dropped as a husk.** The fileless-card drop (built earlier today) fired 8s after Guaracha landed.  The disk
        listing predated the write, so the card was dropped and the track pulled again.  Live, a card now has to be missing from
         two listings at least 60s apart (`rw.c.pool_husk_seen`).
     - Holder side, not chased: Vingas often leaves 90 materialise-asks unanswered for a FLAC lofi ("the SOURCE cannot serve
        it"), so a fill can take three or four bookings.

**Built 2026-11-11 — items 3 and 4 (live pages only):**
- **The file road** (Radio.g's `file` region): `Radio_file_road` says whether a record plays from a file here — `'lofi'` for a pooled
   card whose file is under `pool/` (`Ra_pool_file_plays`), `'own'` for my own original (through `Ra_source_pcm`). The file is
    decoded whole into `rec.c.pcm` (the PCM registry, so the belt frees it), gained to the previews' loudness, and laid on the
     timeline in 2s slices by `Radio_file_tick`. `Radio_open` takes it when the PCM stands (the prime decodes the next track
      ahead) or when there are no chunks to play. A pooled track opens at 0:00; an own track lands where the chunk road's needle
       would. No wire supply for a file-road track. **Opt-in** (`top.c.file_road`, poke `Radio_file_road_toggle`; a reload turns
        it off): its first live run leaked eed to 6GB — every skipped-to pool track kicked a decode, none landed (the loudness
         meter `Ra_lufs` waits on a worker; it now times out in 15s), each held its whole decode. Now one decode at a time, abandoned
          at 25s, a stage on every line (`📻 file road: … decoded in Nms`, `… stuck at <stage>`), let go when the listener leaves the
           track, no copy of the decode, an RMS gain instead of a second render. Re-run 17:07: a pool track decoded in 2.8s.
- **The dial counts it**: `Ra_dial_next` takes a `playable` predicate, so a pooled card with its file needs no preview. The
   census, `Ra_pool_whys` and `Ra_pool_report` agree (eed went "0/38 dialable" → "38 playable").
- **The pocket encode is deleted** from `Ra_pool_previews_heal`. The carry stays, for Books: they play chunks.
- **A close-enough source is the %Lofi** (`Heist_lofi_near`): an Ogg Vorbis|Opus at ≤160k is served whole on a lofi ask.
   `Crate_meta_from_tags` now returns `codec` and `kbps`.
- **Not yet:** item 2's at-rest reshape (the pool still mints its own `%Record,lofi`), and an own track's FIRST open after
   switch-on still plays chunks (no prime ran for it). Unverified on a phone: whether iOS Safari's `decodeAudioData` takes Ogg
    Vorbis — a failed decode marks `rec.c.file_dead` and the card falls back to needing a preview.
- **A behaviour change to rule on:** the 2026-10-04 line "a never-heard circulation fill is not radio material" no longer
   holds by accident of missing previews — every pooled file is now dialable wherever the dial reaches the pool (the pocket,
    the stopgap before a friend plays). The file road writes nothing under radiostock, which was the 10-04 harm.

## 0.a.7 Advice — Seem the cursor: a shrouded landscape revealed ahead of the eye (2026-11-11, from the land/Atheory session)

*Owner: "improve the cursoring into a remote Mag model … a shrouded landscape we can surf around easily and it's all revealed well
 ahead of where it thinks we're going."*  Advice, not built.  The Seem words are `Atheory_design.md` §0 and §1.12; the fog is
  `Radio_future.md` (*"two kinds of fog: unwalked and unnamed"*).  The internet's name for this is a slippy map's tiles plus a video
   player's buffer-ahead: an outline you can pan over at once, bodies fetched in a ring round where you're headed.

**1. The landscape is a Seem over the holder's OUTLINE, not over its cards.**  Have the holder publish each Mag's page index first
 — `%Cloud,page:N` with a count and a dige, a few lines per Mag.  A client Seem holds one Trace point per page (and, once a page is
  mirrored, per card), with rows read from elsewhere (`seem.c.from` → the `%Theirs` mirror, `AthePondGlass`).  So the whole
   landscape exists at once as points, and only some have bodies.  The fog is a Regard on each point, `%TheARegard:fog`, in one of
    four states:
   - `unborn`: the holder hasn't generated this page. This is §0.a.6's "starts empty", Radio_future's *unwalked*.
   - `far`: it exists there, not here. Radio_future's *unnamed* fog.
   - `near`: wanted.
   - `here`: mirrored.

  Because the fog is a Regard, it lives and dies with the point, and nobody tidies it.

**2. The cursor is a point with an `ahead` sphere.**  The eye already exists as a sphere in the toy (`TheARegard:eye,seen`).  Add a
 declared `%TheASphere:ahead,tense:Regard`.  A pure island function (the `Pool_goal` style) writes on each point near the cursor
  `ahead,d:<distance>,p:<likelihood>`.
   - **Distance** is pages along the path.
   - **Likelihood** comes from how the cursor has moved: sequential vs jumping, the skip rate, pages per minute of listening.
   - **The horizon** is every point with `p` above a line.
   - **The want** is horizon minus `here`: the `Pool_goal → Pool_diff` shape again, now over pages.

  Run it BESIDE the live path first and log the disagreements (`Pool_policy_compare` is the precedent), then let it rule.

**3. The want is a row; the holder sums them.**  §0.a.6 already says a cursor's reach IS a Repli want for the next page.  Make it a
 `%Want` row: the W1/W2 middleware exists, and rows are the rule, not signals.  On the holder, the readers' wants are pulses on a
  synapse that hears every reader (`sum:max` per page).  The holder then generates ahead of the FURTHEST reader, the transcode
   queue being the union of the horizons, so two overlapping horizons cost one generation.  A sharp want (a play now) jumps that
    queue.  So there are two horizons, one law:
   - the holder generates ahead of everyone (the generation horizon);
   - the client mirrors ahead of itself (the reveal horizon).

  `Mag:Listening`/`Stoker_hunger` is the first, done by hand.

**4. Churn must not re-fog what you've seen.**  When the Stoker culls or digs, pages re-form.
   - The client Seem **re-seats** (`AthePondReseat`): points pair by observed identity (the card id), the face keyed by them moves
      nothing, and only what really changed glows.
   - A card that changed page is **moved**, not gone-then-new: `%TheALimbo,keep:n` gives `%TheAMoved` (`AthePondMoves`). Use it,
      because `resolve()` pairs only siblings and pages ARE siblings' parents.
   - Your own opinions of a card (heard, Nay'd, kept) are Regards on its point, so they ride every re-seat.
   - What crosses the wire uses the Stamp/Rides policy (`AthePondStampMerge`, the heard mirror's cartoon in three particles).

  This is the same retirement §0.a.6 wants for the `of:` join: the join becomes the pairing.

**5. Reload keeps the map.**  `TheA_persist`/`TheA_thaw` bring back Trace points and their Regards (`AthePondReload`), so a phone
 reopened offline still shows the whole shroud. The `here` region is exactly the pool, and the rest shows as the fog it is.

**6. It's available on the music pages already.**  Every Ground's closure includes Core (`Theory.g`, `Stuffica.g`, `Ground.g`), and
 `/Radio` stands on a Ground, so `TheA_seem_walk` and `Stuffica_view` (a face that commits only when its sheet changes) are loaded
  there today.

**Progress (2026-11-11 night):**
- **1 BUILT** — `AthePondFog` (Ghost/A/AtheTesting.g, 5 steps, 4 oaths, green).  A holder's Mag:Pooling starts empty; two readers
   (pace 0.8 / 0.6, line 0.3).  The pure `AthePondFog_ahead` gives pace^d per page ahead; wants = horizon − here; the holder sums
    them by max (`AthePondFog_sum`) and generates two pages a beat; each reader's map is %Page rows under a Seem whose points wear
     `fog` (unborn|far|near|here), `ahead` (d, p) and `heard` Regards.  A cull re-mints every page and Page row and every Regard
      rides the re-seat.  A first draft regenerated pages 1–2 every beat (`Gen n=3`); the one-generation oath caught it.
- **2 BUILT** — the holder publishes the outline: `Mine/stock/Mag:Pooling`, empty (`Ra_pooling_publish`, minted by the live share
   beat in Swarm.g, so no Book grows one).  It sits on the SAME stock shelf as `Mag:shuffle`, so the wire carries it unchanged:
    `Ra_offer_stock` offers every Mag, and `Repli_mirror_lib` lands every fragment in `Theirs,pub/stock`.  This supersedes the
     `Mine/Pooling` placement first proposed.  `Ra_recs` (the radio's census) and `Ra_mag_warm` skip it (`Ra_mag_is_pooling`); `Ra_rec_find`
      still searches it, because a Pooling record will be served by its own id.  Verified live: eed's Mine/stock and eed's mirror of
       Vingas both hold `Mag:Pooling`.  Mixed fleet: an old peer mirrors the empty Mag harmlessly, but once it holds records an
        old peer's Ra_recs would count them as radio (a lofi card has no preview, so its dial skips it).
- **The stream runs, both ends — BUILT 2026-11-11 night** (jumps ahead of 3–4, which have nothing to show on an empty Mag).
   - **The reader asks** (`Ra_pooling_want_beat`, from the share beat's per-friend mirror loop; live pages with consent only).
      Its cursor is the first page holding a card this tab hasn't taken: pooled, barred by a Nay/Meh, or **Passed**.  The
       horizon is the cursor plus enough pages to fill every compartment (cap sum ÷ 4, at least 2).  Wanting past `born` sends a
        **page want**: a plain `repli_want` with `stream:'page'`, id `Pooling`, `from_idx` = the page.  At most one per holder per 30s.
   - **The holder generates** (`Repli_serve_want` branch → `Ra_pooling_wanted`).  It keeps each reader's furthest want on
      `mag.c.readers` (runtime — a cursor is nobody else's business, and the Mag crosses to every friend), takes the max, and makes
       up to 2 pages per want (`Ra_pooling_generate`).  A page is `Cloud,page:N` of 4 `%Card:<id>,title,artist,seconds`: its own
        stock records no page names yet, hash-ranked by page.  It keeps 25 pages (older ones scroll off) and stales every
         caster's offer mark, so the next beat carries the page.  An old holder answers "no record for id", which is harmless.
   - **The pool draws from it**: `Pool_shared_rows` marks a paging holder's rows `pages` and the carded ones `paged` (plus rows for
      cards the radio shelf already rolled past); `Pool_draw_random` takes only `paged` rows from such a holder.  Every row still
       resolves holders, so a liked track that came by on the radio has a road.  The fill heists by id exactly as before.
   - **Passed** (`Ra_pool_passed_mark`, from `Radio_pool_heard`): `%Passed:<original id>` on the SoundPooling home, the last 1000,
      bumped at most every 10 min.  The card's own `heard` stamp dies with an eviction or a reload; Passed is what remembers.
       The wander and the cursor both skip passed ids.
   - **Verified live:** eed asked Vingas, Vingas made 11 pages (cursor 1 + ⌈37/4⌉), they crossed, and eed's Provisions turned to
      `circulating from b8bc9a68` wants naming exactly the page-1/2 cards.
   - **Owed, in order:**
     (a) **Holding lofi bodies for paged cards.** Correction to §0.a.6: the fill's id is NOT per-client.  `Heist_keep_id(me, base,
      path)` is deterministic, and `Heist_materialise_one` is idempotent per mode, so two sinks asking for one card share one
       transcode while the body is held.  What's lost is the RELEASE-after-serve: a later sink re-transcodes.  So owed: hold the lofi
        body of a card on a page some reader hasn't passed, within a memory budget (a browser holder can't hold 100 × 6 MB).
       **BUILT 2026-11-11 23:06** (Heist_keep_beat's release sweep + Pool.g `Ra_pooling_hold_ids`/`Ra_pooling_hold_cap`): a served lofi
        whose card (`rec.sc.re || rec.sc.id`) is on one of my current-era pages is not released; the candidates are kept newest page
         first (the pages are made just ahead of the furthest reader) within 64MB in a browser / 512MB under node
          (`w.c.pooling_hold_cap`), the rest release as before.  The share beat hands the sweep its shelf (`w.c.pooling_shelf`).
           Logs `🏊⇉ holding N paged lofi(s), xMB of yMB` when N changes.  Limits: the serve-lib TTL (30 min) still drops a whole lib;
            the holder doesn't know a reader's cursor (a want carries the horizon), so "unpassed" is approximated by page age.
            **Live check owed:** a second reader of a page pulls its card with no `⇊♪ lofi: … → ogg128` line on the holder.
     (b) **A holder reload — eras, BUILT 2026-11-11 night.**  `Mag:Pooling,era:<6 chars>`, minted per holder life
      (`Ra_pooling_publish`; a Mag published before eras gets one and drops its pages).  Pages are `Cloud,page:<era>-<n>,n:<n>`, so
       a reloaded holder's fresh page 1 never merges into the old page 1 at a mirror (Repli locates a page by its name).  The reader
        reads only the current era (`Ra_pooling_pages`), drops the old (`Ra_pooling_shed`), counts `born` off its current pages
         (a merge never deletes the old `born`), and re-asks at once.  What it pooled from the old life stays pooled.
         **LIVE 2026-11-11 22:20** (after the relay restart reloaded every tab): eed's mirror of Vingas (b8bc9a68) reads
          `Mag:Pooling,era:zd53ou,born:5` with pages `zd53ou-1…5` holding Cards; eed's own Mine Mag is `era:1oh5h0`, empty (nothing lent).
     (c) **The holder's cursor choosing the cards — BUILT 2026-11-11 night** (named so by the owner: "light cone" belongs elsewhere).
      `Ra_pooling_cursor_picks` fills page N: **half liked** (my current Yays found on my stock shelf, newest heart first —
       `Ra_pooling_liked_recs`), then **the wander** (`Ra_pooling_wander_beat`, detached off the share beat while anyone reads my
        pages: `Crate_nav_meander` over bases music|'', a two-page queue on `mag.c.wander`), then the rolling radio shelf as before.
         A wander card is named by its keep id `Heist_keep_id(me, base, path)` and carries `path` (+ `base`, + `why:wander|liked`).
          The road for a track the holder never stocked: the sink's fill finds the card (`Ra_pooling_card_of`) and puts
           `seed_path`/`seed_base` on its keep → the describe ask carries them (`Heist_rummage_ask`'s seedHint) → the holder's
            `Heist_rummage_folder` self-certifies the seed by the same equation the want side uses → census, pick, materialise unchanged.
             **Owed:** a landed take keeps no path on its Card, so a Yay held only in the collection proper can't be paged yet (stamp
              the landed path at landing).  **Live check owed:** a Pooling page on Vingas carrying `why:wander` cards, and eed pooling one.
     (d) The fog view (build order 3) over `Theirs/stock/Mag:Pooling`.
     (e) Radiostock onto the same road.
**Build order, smallest real thing first:**
1. **A Pond cartoon Book**, say `AthePondFog`: one holder A with a paged Mag, two reader As with cursors. Its oaths:
   - nothing is wanted beyond a horizon;
   - a page inside the horizon is `here` before the cursor arrives;
   - two overlapping horizons cost one generation;
   - a re-seat after a cull keeps every Regard.
2. **The holder publishes the Pooling Mag's outline**, which is empty today, so nothing breaks.
3. **The client Seem with fog Regards**, shown by a Stuffica view, read only.
4. **The `ahead` island beside the live path**, then ruling.
5. **The holder sums wants into the transcode queue.**
6. **Radiostock moves onto the same road** (§0.a.6's order).

⚠ **Traps the toy already found:**
- Selection wasn't reload-safe until `AthePondReload` fixed it.
- `resolve()` pairs siblings only.
- A `%TheAMark` that doesn't persist folds, and rolling back to it is refused.
- `new` is a session key the encoder strips (use another word for a fresh mark).

## 0.b What stands today (the code)

`Ghost/M/Pool.g`, three regions (its header): **the island** `Pool_*` (pure policy: `Pool_facts` → `Pool_goal` → `Pool_diff` →
 `Pool_roll`; `Pool_policy_compare` runs it BESIDE the real pipeline and logs disagreements — it rules nothing yet), **the
  quartermaster** `Ra_quarter_*`/`Ra_pool_*` (the steward that rules today: consent, budget, compartments, press/evict), **the fill
   reach** `Ra_pool_fill_*` (a standing `%Reach` per pull, the holder's serve, the landing tail, the heals, `Ra_pool_fill_pump`).
    The `Ra_` prefix is history; rename to `Pool_` when the island takes over, one sweep.
- **Switching on** (`Ra_pool_start`): consent + budget (MB) + one compartment `rolling`, take `random`, from `crew` by default.
   Compartments draw by `random` (friends' mirrored catalogs — the same Mags the radio dials), `radio` (caught off the radio),
    `recent`, `latest`, or a tally (liked/kept). `Ra_pool_off` removes cards and files.
- **The home**: `%SoundPooling` on the identity (`Ra_pool_home`), pool cards as `%Record` on its stock, files under `pool/` in OPFS.
- **Landing**: every pull lands through `Heist_catalog_land`'s pool branch into `Ra_rec_pool` (the one catalog door).
- **The steward** runs from `Radio_pool_steward` (Radio.g, ~once a minute, latched 120s); the fill pump rides the Reach pump (~5s).
- **The face**: `PoolFace.svelte` (the 🏊 cell): on/off, MB, friends/crew, recent; a report of dialable / why not / files on disk.
- **The pocket** (`Radio_pocket_why`, Radio.g): no folder (`listen_only`) or the relay down >5s ⇒ the dial's last rung plays the
   pool (as files, through the file road, since 2026-11-11; the on-device preview encode is gone). A rename is owed: "pocket"
    says nothing.
- **Books:** `MusuPoolPolicy`, `MusuPoolFill`, `MusuPoolRadio`, `MusuPoolRandom`, `MusuPoolBytes`, `MusuQuarter`, `MusuSteward`,
   `MusuPress` (and `MusuHandoff`/`MusuHeard` for the ♥ lane beside it).

## 0.c Rulings in force

- **2026-09-07** — the daemon holds **no** SoundPooling ("the daemon also wants no SP"); it serves from its library.
- **2026-09-15** — there is no unlove; a second ♥ re-affirms.
- **2026-09-17** — an un-consented body may serve from a TINY, eagerly-evicted stash; consent gates only the pool a person keeps.
   Shape not built.
- **2026-09-17 evening** — the roll's one law: nothing is evicted unless the pool holds more than its cap.
- **2026-09-23** — when every granted friend has nothing new, the radio falls back to the pool (`lu.sc.exhausted`, a "puff of
   exhaustion").
- **2026-10-04** — the pool is not a radio source (♪ SOUNDPOOL left the chooser); the off-pocket encode rung was deleted (it wrote
   lofi re-encodes to radiostock under MY pub and friends' tracks went back out as mine).
- **2026-10-17** — the pocket: no relay or no FSA ⇒ the pool is the music.
- **2026-11-10** — §0.a: found via %Preview, kept as %Lofi; the radio should play files.

## 0.d Owed

1. **Owner's walk of the file road** (built 2026-11-11, §0.a): on eed, toggle the source to own and let two tracks pass (the
    second should log `file-open` in the radio ring); then a pool track (the pocket, or the stopgap). Then build §0.a.2, the
     at-rest `%Lofi` under the track's `%Record`, and retire the carry once a Book plays the file road.
1b. **One stream of friend tracks, not two** (owner 2026-11-11: *"if there's one stream of random tracks from a friend, we might
    as well not peer-Radio play what's also pooling-Radio playable"* + *"needing more Pooling would cause the same 'send more random
     track Mags' want of the server"*).  BUILT: a friend's record already in my pool (by id or `of:`, `Radio_pool_card`) plays from my
      disk through the file road, the share beat stops wanting its chunks, and `Radio_pool_catch` won't re-keep it.  OWED: the pool's
       hunger — when its random compartment has drawn the friend mirror dry it must raise the SAME want the radio does (the listeners'
        cursor, `Stoker_tell_listened` → the holder stocks more random Mags), not a demand path of its own.  And the open ruling: does
         "from friends" mean random-from-their-catalog (09-03) or keep-what-the-radio-played (`take:'radio'`, 11-10)?
2. **The field trip** (owed since 10-17): install on a phone, play friends' tracks until the pool fills, airplane mode, reopen.
3. **Self-circulation** (2026-09-23 analysis, history §0.0): a friend whose pool is mostly MY music offers me nothing new; option 1
    (say so in the Lineup's error) is cheap and unbuilt.
4. **The tiny serving stash** (09-17 ruling) — shape it.
5. **The island takes over** from the quartermaster (`Pool_policy` rules; `Ra_` → `Pool_` rename; fixtures re-sworn).

The trail, evening by evening, with every reason: `history/SoundPooling_evenings_todo.md`.
