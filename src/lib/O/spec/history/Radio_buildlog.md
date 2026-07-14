# Radio_buildlog.md — dated session diaries moved out of Radio_todo.md §0

HISTORICITY: these are the "on this day" build-diary entries that used to accrete in
 Radio_todo.md §0 (moved here 2026-07-12 on the human's ruling: §0 stays a brief, not a log).
  The living state, roadmap and design are in Radio_todo.md — read THAT; come here only for
   the archaeology of how a thing landed. Newest first.

**2026-07-14 — M4 (second rung): census becomes the STANDING publish — a diff-watcher pass, idempotent on a quiet
 census (MusuStanding), LIVE-GREEN ×2.** MusuRecast crossed a census DIFF when `Musica_recast_offer` was CALLED;
  this rung makes the census itself the TRIGGER — "a landing that changes the collection re-publishes the magazine"
   (§12.5). New verb `Musica_stand(w, tx, from, to, mag, lib, randomic, created_at)` (`Ghost/M/Heist.g`, after
    `Musica_recast_offer`): fingerprint the collection (its sorted id set); if UNCHANGED since `mag.c.last_census`,
     return `{changed:false}` doing NOTHING (no fold, no offer, no frame); else recast-offer the delta and remember
      the new fingerprint. The idempotence is the whole point — it makes the pass a real diff-watcher, not a blind
       every-beat re-offer that would spam the wire and defeat the husk economy. The Book **MusuStanding**
        (`Heistation.g`, after MusuRecast) drives the pass per beat and mutates the collection between beats to
         stand in for landings/removals: seed {t0,t1,t2}, stand (publish), stand on the unchanged census (QUIET),
          grow (+t3) + stand (propagates), shrink (−t1) + stand (goner crosses), stand (QUIET). Final: origin and
           follower agree on {t0,t2,t3} across two clouds. 5 sees. The load-bearing discriminator is the ORIGIN
            Pier frame counter — `MusuStanding_stand` reads `tx.c.seq` (via `Pier_next_seq`) before/after each stand
             and pins `sent`; a quiet stand pins `sent=0`+`quiet:1`. Remove the fingerprint gate (the one-line
              regression) and every stand re-offers → `sent>0` on a quiet stand → red; the mirror-content sees would
               MISS that (a redundant husk re-offer upserts the same cards and changes nothing visible), so the
                frame count is the only witness of a wasted republish. The adversarial review (opus subagent)
                 returned all 5 sees SOUND — confirming `tx = w.c.tx` is the only pier any frame touches (the setup
                  stamps `%Ud` directly with no handshake, acks book no seq, `Musu_float` is pure layout), so the
                   `sent` receipt is pristine and the idempotence gate genuinely flips red. Live on `49de`: thaw
                    MusuCursor green, CHECK RED vs lie, accept 12/12, two confirm runs 12/12 `caveat:0` (warm/warm,
                     no round-wobble this time). MusuRecast re-ran green after the shared-`Heist.g` addition
                      (non-regressive). Deterministic + in-memory. Registered Credence (`brand_new:1`) + Ality. The
                       last M4 piece is the roster FAN-OUT (standing over N enrolled followers — needs per-follower
                        mirror routing, since `Repli_mirror_lib` keys off one `w.c.repli_mirror_pier` today).

**2026-07-14 — M4 (first rung): the census-diff re-publish — a goner crosses the wire and leaves no orphan
 (MusuRecast), LIVE-GREEN ×2.** MusuVend (M2) proved a magazine and its NEUS travel but its forget scene was a
  LOCAL GC — the witness said so outright (it asserted on the ORIGIN only, because "the follower keeps a dropped
   cloud until a Repli_retire propagates"). M4 wires that retire to the fold. New verb `Musica_recast_offer`
    (`Ghost/M/Heist.g`, after `Musica_forget`): snapshot the published (id→cloud) and cloud sets, `Musica_fold`
     the magazine, snapshot again, re-offer the whole magazine (husk — neus + in-place updates ride the upsert),
      then cross an explicit **path-carrying op:delete** per goner. The gap is real because `Repli_merge` is an
       UPSERT — it never removes what an offer OMITS (by design) — so a re-offer alone can never withdraw a lost
        card; the withdrawal must be an explicit delete. TWO granularities mirror `Musica_fold`'s own two-level
         reconcile: a card lost from a SURVIVING cloud rides `Mag>Cloud>del Record`, a whole cloud EMPTIED rides
          `Mag>del Cloud` (the whole-era drop in one line, guarded so an emptied cloud's records don't also emit
           stray record-deletes). `Repli_retire` stays the FLAT depth-0 goner for a record off a mirror lib
            (MusuReplica); a magazine card is three levels down, so the delete carries its Mag/Cloud ancestry as
             plain upsert lines the merge already walks — **no Repli wire-core change**, proven by tracing
              `Repli_recv_lines` always merging into the one `Repli_mirror_lib`. The Book **MusuRecast**
               (`Heistation.g`, after MusuRename) forks MusuVend's two-Pier loopback: publish draw A (t0 t1 t2)
                and draw B (t3 t4) into two clouds, lose t1 (record goner, cloud survives), then lose t3+t4 (whole
                 draw B → cloud goner). Final state: origin AND follower both hold only t0 t2, draw B's cloud gone
                  from both — no orphan, no empty husk, survivors intact. 5 sees. **The adversarial review (opus
                   subagent) caught see #5 as a FALSE-GREEN and it was fixed before recording:** #5's claimed break
                    (broaden the record-delete to a `Record:1` wildcard) transiently empties the survivors' whole
                     cloud, but scene 3's re-offer re-adds t0 t2 before the witness ever samples a settled
                      `both_ran` pass — so #5 latched green anyway. The fix pins the survivor state in a frozen
                       `after_record` note the INSTANT the record goner drains (step 9, before scene 3 can heal it),
                        where the broadened delete leaves `s0=0 s2=0` and can never un-write — now the break
                         genuinely flips it red. `.g` gotcha en route: `for (const i of slice)` mangled to
                          `w.i({of:1})` (the compiler read `i` as the create verb) → renamed the loop var to `ix`.
                           Live sequence on runner `49de`: warm-up MusuCursor green (thaw), CHECK RED vs lie diges,
                            first accept caught a `self,round=5` heartbeat wobble (caveat:1 vs a warm `round=4`) — a
                             benign quiescence margin the `mung:age` mask does not cover — so a full warm re-record
                              (reset toc→lie, clear snaps, re-run, accept 12/12) settled the fixture to `round=4` and
                               two confirm runs came back 12/12 `caveat:0`, GREEN ×2. Deterministic + in-memory (no
                                FSA / audio / Berth / entropy). Registered Credence (`brand_new:1`) + Ality. M4's
                                 census-diff wire heart is proven; the remaining M4 is rename-as-standing-Upkeep +
                                  the revolving service pacing (the standing-loop shell around this primitive).

**2026-07-14 — M3: a rename mission mints `%Renamed` and the redirect rides the wire (MusuRename), LIVE-GREEN ×2.**
 The magazine rung that closes C2's loop. C2 (MusuHeal) proved the heal MECHANISM with HAND-AUTHORED markers and no
  wire; M3 mints the marker from a real reorganise gesture and crosses it Pier-to-Pier, so a follower's stale cursor
   heals through a marker whose ONLY source is the replication pipe. New verb `Musica_rename(mag, id, key, to, at)`
    (`Ghost/M/Heist.g`, beside `Musica_forget` in the magazine region): find the card by id across the clouds, mint
     the `%Renamed` redirect BESIDE it (same cloud — where `Cursor_heal` looks), then apply the new value — apply +
      mint are ONE gesture, so the magazine never shows a rename without its redirect. `Renamed_mint` gained
       `m.c.repli_loc = ['Renamed','key','from']` so two markers stay DISTINCT on the wire (the default `['Renamed']`
        loc — `key` is not id-ish per `Repli_loc_keys` — would upsert the second marker onto the first and blur both
         redirects; a same-`(key,from)` supersede still upserts `to` in place, so newest-wins survives the wire too).
    The Book **MusuRename** (`Heistation.g`, after MusuResume) forks MusuVend's two-Pier loopback: origin publishes a
     3-card magazine, follower makes two TITLE-pinned `%Dogear` cursors into its OWN mirror (both `fresh` — zero heals),
      origin runs two rename missions (`Low Draw`→`Low Tide`, `High Draw`→`High Tide`), re-offers the whole magazine.
       The cards update IN PLACE at the follower (loc `['Record','id']`; `title` a merge PROP — no fork) and the two
        markers arrive as fresh facts; both stale cursors then heal through the replicated markers, landing on the
         retitled records and noting from→to. 9 steps, 5 sees. Adversarial review (opus subagent) returned all 5
          SOUND: every claimed one-line break flips its see red, none tautological, and the `{Renamed:1}` numeric-1
           presence-wildcard survives the peel round-trip (decodes back to number 1, so `o({Renamed:1})` still
            wildcards on the mirror — the `"1"` literal footgun does NOT bite because the queries never pass through
             `exactly()`). Live sequence on runner `49de`: warm-up MusuCursor green (thaw), MusuRename CHECK RED vs the
              lie diges (expected), accept recorded 001–009 + real toc diges + Credulate pin, then a second run came
               back 9/9 `caveat:0` matching the fixtures — GREEN ×2. Deterministic + in-memory (no FSA / audio / Berth
                / entropy profile). Registered Credence (`brand_new:1`) + Ality. The M-rung's next natural step is M4
                 (census-diff re-publish + rename missions as a standing Upkeep pass); U (the magazine reader) is also
                  unblocked now the whole cursor stack under it is green.

**2026-07-14 — C3: a berthed `%Dogear` resumes a browse across a reload (MusuResume), LIVE-GREEN ×2.** The cursor
 arc's last rung. Book **MusuResume** (`Heistation.g`, after MusuHeal): a `%Dogear` homed INSIDE a magazine survives
  a full `enWaft`→`deWaft` round-trip and still resolves to the record it named — the resumable browse. Isolates the
   ENCODE|DECODE (MusuBerth owns the real FSA disk), so it needs no FSA and runs on ANY runner, deterministic (7/7,
    caveat:0). Two proofs baked in: (1) a live-only bookmark under `%testing` does NOT ride the snap, so the re-decoded
     magazine carries EXACTLY one Dogear (`dogear_count:1`, `kept_present`, `live_absent`) — the "berth vs session"
      discrimination; (2) independence — the original tree is mutated after the round-trip (t1→t9, no redirect) and the
       resume still lands. Adversarial review verdict: SOUND, no hard bug (depth===2 right, the `wild`-split saves the
        post-decode string match, `created_at` stripping harmless) — but it caught the `independent` leg as NEAR-
         TAUTOLOGICAL (`deWaft` structurally cannot alias — it parses text into a fresh tree — so `!old.ok` was forced
          by our own rename, making `independent === res.ok`). Fix with teeth: re-gate independence on the re-decoded
           cloud being a DISTINCT node object, a check a hypothetical aliasing `deWaft` would actually flip red. LESSON
            re-confirmed: the post-`ghost-compile` HMR re-froze the runner's boot — the FIRST MusuResume run came back
             `total:1` (Prep-only, vacuous green) and its `story_save` clobbered the toc.snap to a 1-step skeleton; the
              SECOND run thawed to full 7 steps (frozen-boot-empty-first-run + toc-collapse, both self-heal). En route
               it corrected **CLAUDE.md**: the enWaft vocabulary gate is PARKED (`all_knowing` — any mainkey encodes;
                the old "unknown mainkey = fatal skip" was stale, the only encode-fatal is an object/function in `.sc`),
                 and regrouped **Credence** (`What:mostly` → pipeline / magazine / replication; the cursor trio homed
                  under `magazine → the cursor`, ending the organiser's bare-orphan churn). Commits `a28f480f` (C3) +
                   `8b3b14a4` (Credence regroup). **C1·C2·C3 done — the cursor is a first-class, durable, self-healing
                    position over a magazine.**

**2026-07-14 — C2: the cursor HEAL via `%Renamed` redirect-facts (MusuHeal), LIVE-GREEN ×2.** Straight on from
 C1: grew `Cursor_resolve`'s clean-fail verdict into a HEAL. When a named level is gone, `Cursor_heal` (new,
  `Ghost/M/Heist.g`) looks beside the last node reached for a `%Renamed,key,from,to` marker and retries the query
   with the pin remapped to `to`, recording `heals:[{key,from,to}]` — "noting what it healed" (§12.3). The marker
    rides IN the magazine beside the renamed node — a POSITIVE, window-able (`at:`-stamped, newest-wins) cousin of
     the `%Tombstone`/`%UnGrant` decision-facts — so a follower heals through the same pipe the content came down.
      `Renamed_mint(parent,key,from,to,at)` lays one. Book **MusuHeal** (`Heistation.g`, after MusuCursor) proves it
       with a marked/unmarked TWIN: rename t1→t1b WITH a marker and t2→t2b WITHOUT, then re-resolve — the marked
        cursor heals to t1b noting from:t1→to:t1b, the unmarked one fails cleanly (missing t2). So the heal is
         provably the marker's doing (the one-line regression = drop the mint → heal sees go red, control stays
          green). Adversarial review: SOUND + falsifiable; it caught steps 3/5 missing a `reached:` marker
           (silent-un-latch risk) → both added. The heal is TRANSPARENT to an un-renamed cursor — MusuCursor
            re-ran green (caveat:0) after the `Cursor_resolve` change, no re-record needed. Recorded 7/7 caveat:0
             on the reloaded 49de (which survived the ghost-compile HMR this time — the earlier wedge was a
              one-off), accept, green ×2. NEXT on the C track: C3 (berth a `%Dogear` as follow-progress). The
               `%Renamed` fact-shape landing here also tees up M3 (mint the same marker from a real rename mission).

**2026-07-13 (late evening) — C1: cursors (`%Dogear`), LIVE-GREEN ×2.** The human's steer: `%Cursor`/`%cursor`
 are taken (LiesKeep focus-history + LangCurse Interest), so "try `%lematch` — make it like that." A `%Dogear`
  is a linear spine of `%curs` match-segments, each storing ONE `o()`-query; `Cursor_resolve(dog, root)` re-finds
   each level from a root down and lands on the leaf OR returns a CLEAN-fail verdict `{ok:false, depth, missing, at}`
    — no throw (the seam C2's `%Renamed` heal plugs into). Primitive `Cursor_*` in `Ghost/M/Heist.g`; Book
     **MusuCursor** in `Heistation.g`. Two design wins: (1) KEY-AGNOSTIC — a level pins by whatever keys its node
      wears (`id`/`randomic`/`shuffle`), so the human's same-turn Cloud-model redirect (drop `randomic`, partition
       by `shuffle|ctime|mtime` every ~20) slides under it untouched; (2) snap-safe wildcard — the presence TYPE
        rides as a `wild:<Type>` value (re-inflated to `{Type:1}` at resolve), literal pins flat, dodging the
         `Cloud:"1"` exactly() footgun. Three sees: lands-on-leaf (depth 3), lands-on-a-level (depth 2, partial),
          clean-fail (knock the record out → fails at that level, reports the missing query). ADVERSARIAL review
           found + fixed a real soft spot: see #3's "no crash" degraded to a SILENT un-latch on an upstream throw
            (a `%see` cannot detect its own absence) → a `reached:step_4` marker gives the recorded snap-diff teeth;
             see #2 tightened to assert the landed node is a `%Cloud`. RUNNER-WEDGE DETOUR: an in-session
              `ghost-compile` HMR of the big `Heistation.g` stalled 49de's think loop (it engaged a Book but never
               minted a Run — `run:null`, confirmed by a known-green MusuDoor control also going null) and 3c52 was
                begun-wedged; both cleared only on a browser-tab reload (human action), after which a thaw run + the
                 real run recorded green (6/6, `caveat:0`), accept, green ×2. `Credulate` pins `Heistation~g1
                  @bbc3c8cc` + `Heist~g1`. D1 was ALSO re-posed for the human this session (it IS Invites & Grants —
                   part a swaps the demo grant-toggle for the live `Swarm_pier_live` verdict MusuHeist already runs;
                    one revoke scene, attended) — captured in Radio_todo §0.

**2026-07-13 (evening) — D1 part b: the anti-klepto SABOTAGE wall (MusuDoor), LIVE-GREEN ×2.** With M2
 live-gated, split D1 and built **part b** — the §12 heart, the door the recipient stands. Book **MusuDoor**
  (fork of MusuVend, appended to `Ghost/Story/Heistation.g`): a malicious origin HAND-CRAFTS a magazine card
   carrying a grafted `%req:sabotage,eternal,arm:pwn` — a standing request dressed as catalog data. It rides
    the husk (`Repli_lines_of` ships every non-chunk child), merges deep under the follower mirror via plain
     `i()` (not `oai`, so no req-machine), and lands **INERT**: `reqdo`/`reqdo_sweep` pump only w's IMMEDIATE
      reqs (`w.o({req:1})`), and merged content lands strictly below the mirror lib. The step-9 snap SHOWS the
       trojan sitting harmless in both the origin mag and the follower mirror.
 THE BUG THE REVIEW CAUGHT: my first draft asserted "the grafted req is not among `w.o({req:1})`" — an
  adversarial reviewer proved it a **false-green**: it watched the wrong shape (`sc.sabotage` key vs the
   attack's `req:'sabotage'` value) AND only caught a promoting merge, not the deep-walking-sweep regression
    the §12.1 BOMB actually names. Rewrote the canary DYNAMIC: a `req_sabotage` handler (`do_fn_for` resolves
     `H.req_<value>`) flips `w.c.pwned` if the buried req is EVER pumped; a positive control pumps an identical
      req through a throwaway holder world's `.do()` and watches pwned flip (non-vacuity via the exact dispatch
       path). Now BOTH promotion and a deep-walking sweep go red. A second reviewer verified the fix and
        (correctly) insisted the lie-dige Book gates nothing until live-recorded — which is exactly the gate.
 3 sees (wall + gate-refusal + containment). Deterministic — no FSA/audio/Berth/entropy, so it ran on any
  runner, `caveat:0`. **LIVE-GREEN ×2** (runner 49de: 9/9, `caveat:0`, all 3 sees latched, Credulate confirms
   fresh gen `ca0695eb~g1`), commit `f76b3d7e`. Registered Credence + Ality. **D1 part a** (the crypto door —
    swap the toggle for the live `Swarm_pier_live` verdict, reintroducing seal entropy) is the remaining rung,
     best done attended. Corrected [[musu-ra-magazine-m2]]'s "NEXT = D1" and Radio_todo §0/§12.4/deps.

**2026-07-13 (pm) — M2: magazine replication (MusuVend), compile-clean + the "one brain" split.** After
 the fold made the magazine real on MusuHeist, the human asked whether the MusuRa* family uses the magazine
  "and otherwise reflect the current era". An Explore mapped it honestly: **NO** — MusuRaStock/Cast/Term/
   Stream/Chase stock a real `%Library` but publish no magazine (zero `Musica`/`%Cloud` refs); they ARE
    otherwise current-era clean (no tombstone / `%Tune` / genre tag-tree). The shapes already FIT
     (`Musica_fold` consumes exactly `Ra_library`'s `%Library,pier > %Record`) — nobody wired them.
 **Built M2** — Book **MusuVend** (appended to `Ghost/Story/Heistation.g`): two Piers over a Lake_link
  loopback, an in-memory magazine folded at the origin and `Repli_offer`ed WHOLE (husk — a magazine card
   is a payload-less leaf, so no wants: the tree crosses in ONE frame; `Repli_merge` upserts it under the
    follower's mirror lib). The GATE is the point — a Book-owned `w.c.grants.Follower` toggle read by
     `w.c.repli_allow`: draw A crosses (granted) → draw B REFUSED + noted (revoked) → draw B catches up
      (re-granted, gate consulted live) → a FORGET scene GCs the older cloud (`Musica_forget_fold`, the
       %Cloud layer's raison d'être). 6 `%see` — absorbing BOTH owed-coverage items from the deleted
        MusuMagazine (multi-cloud grow = see #5, Musica_forget = see #6). DETERMINISTIC + in-memory: no FSA
         / no audio / no Berth / no AudibleEntropy → runs on ANY runner, jitter-free fixture.
 **The "one brain" split (§12.1):** `Musica_publish` factored so the pure reconcile-then-add is
  `Musica_fold(mag, lib, randomic, created_at)` (no disk) and `Musica_publish` is the Berth wrap
   (open→fold→save). ONE magazine builder now serves the disk publish AND the wire — no duplicated
    reconcile. The fold stamps `cloud.c.repli_loc = ['Cloud','randomic']` (else `Repli_loc_keys` defaults
     to `['Cloud']` and a second draw collapses onto the first at the follower — the wire-fix that makes
      the Cloud layer survive replication).
 **`randomic` clarified (the human):** a `%Cloud` is a RANDOM DRAW meandered out of a collection NEVER
  fully enumerated (`Crate_meander`), not "the whole lib this tick" — the magazine is random samples over
   time; `randomic` is the draw-fingerprint. Folded into `Musica_fold`'s doc + §12.2 + MusuVend's framing.
 **State:** both `.g` LocalGen-green; toc seeded (11 lie steps); registered in Credence (`brand_new:1`) +
  Ality. **ADVERSARIAL code review PASSED** (in-session, not a live run): no RED-causing bug, all 5 sees
   fire, 4 of 5 breakable by a named one-line change; #2 (catalog-not-payload) is honest but semi-taut on
    the wire (its leaf property is the FOLD's sublimation, not the husk — husk is a no-op for a payload-less
     magazine; commented at the site). Confirmed independently: value/string wire round-trip type-stable,
      `{Cloud:1}` is a numeric wildcard so `repli_loc` is load-bearing for see #5, all 6 mainkeys snap (vs
       MusuHeist/022.snap), and the `reliable:true` Lake_link mock drains inline in post_do (the rx.do()
        pumps are belt-and-braces). **LIVE-GREEN ×2** (2026-07-13, runner 49de): 11/11 steps, `caveat:0`,
         all 6 sees latched, both clouds distinct at the follower, forget dropped the older cloud. The
          runner FROZE on the first dispatch (total:1 Prep bubble — the freeze problem the human flagged)
           and SELF-HEALED on the second run (frozen-boot: the first dispatch is a sacrificial thaw), then
            accept → green ×2. Fixtures committed; `Credulate` confirms the fresh gen (`Heistation~g1`).

**2026-07-13 (night) — the blessed wave: cp-landing + the fold ("build it!").** The human blessed the
 cp-landing + magazine-fold wave, and it landed live green ×2 (on runner 3c52 — 49de and 20e3 both
  froze mid-session: backgrounded browser tabs freeze via Page Lifecycle, so a runner only steps while
   its tab is FOREGROUNDED; 20e3 worked only while the human was briefly looking, 3c52 while they
    were back). **cp-landing:** a heist is now a COPY — `Heist_rel_for` lands at
     `<dest-root>/<source-relative-path>`, the source's own filename+subdirs survive, tags catalog but
      never rename (`Heist_cp_path` sanitizes `..` for kid-safe security); `Heist_land_rel` (the old
       `<genre>/<Artist>/<Album>/<Title>` tag-tree) deleted; the mislabeled-plant see INVERTED (the
        file keeps its bogus name on disk, the catalog knows the truth from the tags). **The fold:**
         MusuHeist now publishes Uno's REAL collection via `Musica_publish` and reflects it into
          w/%Mag — real ids, body_hashes, cp paths ON the snap (the human's "detail is data" after
           "MusuMagazine tests not much"); the existing deny gives a RECAST on real data for free
            (publish 9, deny drops one, republish → 8, the denied track vanishes from the magazine, no
             orphan). 14→16 sees, 19→22 steps. Two cold-timestamp steps needed the usual
              entropy-warming re-accept. MusuMagazine (the %Cloud toy) KEPT as the multi-cloud-grow +
               forget unit-test; retire-vs-keep surfaced to the human. Corner-cases (weird tag text
                clamp, non-audio/album-art oracle, dedup album+disc+track, landing clash) captured as
                 `// <` for when cp-landing meets real disk at M2.

**2026-07-13 (afternoon) — tags-by-default, the %Cloud magazine on the plane, and the Ra re-record
 sweep.** Three things, all live-recorded on 49de + committed. (1) **The tombstone RIP** landed
  first (MusuHeist 30→19, green ×2; see the day entry's ruling) — then the human caught the
   MusuMagazine fixtures "snapping the judgement of some data not actually seeing the data itself":
    the berth Waft was disk-homed and never reachable in the H** tree, so the snap carried only
     `published,records=2` count rows the drive grades itself on. Probe confirmed it (album=genre,
      mangled join — one-liners that should break it but couldn't). (2) **Test music is
       tagged-by-default**: the subagent traced that Crate_wav_with_tags (the RIFF INFO writer) was
        built but called ONCE (MusuHeist's plant) — the general generator (wav_bytes) stayed bare,
         so every testsounds file was tagless (ffprobe confirmed). Fix: wav_bytes→pcm_sine (synth
          only), the container now comes from the tag writer; every file carries IART/INAM agreeing
           with its filename (the lone disagreeing file stays the plant, sharpened). Empirical gate:
            the seeder reads one file back and stamps `tagged` iff the fourccs are on disk.
             (3) **The magazine rebuilt as %Cloud/%Record** (§12.2): still census %Records (no
              fabricated `genre` — no census mints one), now grouped under a %Cloud,randomic,created_at
               ARRIVAL BATCH (the human's layer — every Record wears its join time, whole eras
                forgotten via Musica_forget). Musica_publish is reconcile-then-add. The Book REFLECTS
                 the disk-read tree into w/%Mag so the fixture diff shows the data change on camera —
                  a second Cloud arriving at t=2000, ae-rae vanishing with its emptied cloud. 4 %seen
                   on the reflected data, green ×2 caveat:0. (4) The tag change shifted every source
                    WAV's bytes → census enid → every Ra shelf key; **re-recorded the whole Ra family**
                     (RaStock/Cast/Term/Stream/Chase) over the tagged collection, green ×2 each (the
                      caveats are AudibleEntropy ≈ over real muted-audio lufs/ms, identity churn
                       deterministic). OWED + blessing-needed: the FOLD (publish off MusuHeist's real
                        census, retire the minted lib) + the cp-LANDING (whole-dir pickup, no rename) —
                         one fixture-churn wave once blessed.

**2026-07-13 (day) — two rulings: the metaphor reset and the tombstone condemned.** (1) The
 kitchen/counter language failed the human ("counter" reads as a tally in count-land; K1 would not
  parse). §12.1 reset: **for-oneself is not an instance — it is the House** doing its own work
   (the M-rungs + an Upkeep-shaped standing republish, now M4); the only new construct is **THE
    DOOR** — the narrow per-relationship handler a foreign want meets (scalars in, grant asked at
     every leg, read-only over the magazine, streaming legs or a noted refusal out; hostile trees
      land INERT because nothing arriving is minted into a swept space). "Door" is the codebase's
       own admission word (SwarmDoor, "refused at the door"). K1→D1 (door-hardening Book, needs
        M2), K2→M4. (2) **`%Tombstone` CONDEMNED** — the human: "I never asked for tombstoned";
         provenance traced honestly: it was the one gear SAFE to build blind overnight (§10.2's own
          words — "additive to fixtures, no design fork"), never a ruling, and the Booth had
           already vetoed its %Ban rebirth. Kill reasons: the only load-bearing skip is
            `Heist_held`; the deny ceremony has no real populator (an out-of-band delete never
             mints one); `%UnGrant`'s never-drop durability is earned by SECURITY, not taste; and
              the coming world is PULL-shaped (wants/cursors) — a blacklist defends against a push
               that stops happening. Re-homes: manifest poke-out (per-heist MOMENT) / §9.2 `%Share`
                match (durable narrowing) / Booth IF ever surfaced. §11.5's migration checklist
                 re-purposed as the rip checklist (delete, not rename); the rip batches with M2 +
                  the music-metadata swap into one reload + re-record session. Standing discipline
                   minted alongside: Heist_* realities are PROVISIONAL until M2 is real — no
                    durable facts accrete heist-side (§12.5 re-homes every gear).

**2026-07-13 (nightshift) — the four owed live-gates all clear + the §12 magazine's first rung.**
 The human left four sequenced jobs and a "you may commit as me" licence; a recovered `49de` runner
  (the wedged tab from 07-12 came back — likely a host reload) took every gate live. **(1) MusuHeist
   re-recorded to 15/15.** The committed fixtures were the 13/15 buggy-gen record (the manifest
    wildcard-leak); a clean re-record over them read `15/15` see, green ×2 (`ok_pct:1, caveat:28` — the
     benign AudibleEntropy ≈), accepted and committed (`1c2e7e12`). **(2) MusuBerth's first live
      record** — the disk round-trip + reset-with-Story Book that was authored-but-live-gate-owed on
       07-12 ran, accepted, green ×2 (deterministic, `caveat:0`), committed (`03c2e1cd`). **(3) The M1
        magazine rung.** New verb `Musica_publish(nav, root, prepub, lib)` in `Ghost/M/Heist.g` beside
         the berth region: it opens the Pier's `Waft:Musica` berth, WIPES its old `%Tune` children (a
          republish is a whole re-cast, not an append — a dropped Record must vanish here too), then
           lays one `Tune:<Artist — Title>` handle per Record carrying album|genre|id (the §12.3
            metadata cursors will anchor on), each field guarded so an absent one is omitted. No crush,
             no wire at v1 — a plain Berth Waft moves like any C** once M2 lands. Its Book **MusuMagazine**
              (flow in `Ghost/Story/Berthation.g`) mints a small in-C catalog (the magazine sublimes the
               CATALOG, not disk bytes), publishes, re-opens a fresh handle and counts one tune per
                record; probes a tune's metadata; grows the catalog + republishes to watch it grow; then
                 drops a record + republishes to prove the recast leaves no orphan. Authored + seeded toc
                  + registered (Credence + Ghost/Music/Ality) + LocalGen-green, committed authoring-first
                   (`683d00a6`) with dispatch marked OWED (the wedged runner). Then the recovered runner
                    took it: RED against the lie diges as expected, accept recorded seven step snaps,
                     green ×2 (`caveat:0`), all four latched `%seen` present + the four markers
                      (`published,records=2,tunes=2` / `probed,has_album,has_genre,has_id` /
                       `regrew,before=2,after=3,grew` / `recast,after=2,orphan=0`). Credulate pins
                        `Ghost_M_Heist~g1` + `Ghost_Story_Berthation~g1` (the record is the live LocalGen
                         spine); Credence dropped `brand_new` now the Book is green. Fixtures committed
                          (`c05e66d8`). **(4) MusuHeist sabotage-proofs** (both CHECK-only, never
                           accepted, reverted via `git checkout` + LocalGen + re-run green, runner left
                            green on pristine gen `39558c`). **(a) `Heist_tombstoned→false`**: a denied
                             track stops being remembered, so the retomb manifest read `holds=8,fresh`
                              (should be `denied`), the track re-lands, and see #11 (`tombstoned===1 &&
                               no_reland`) DROPPED — absent from the live snap where the fixture has it.
                                **(b) corrupt one census `body_hash`** (`built===0 ? hash+'ff' : hash` —
                                 pin wrong, chunks + `id` still real): the landing stamped `breached,
                                  landed=2` (should be `landed=3`, no breach), faithful fell below 3, and
                                   see #4 (`!breached && faithful===3`) DROPPED. Both sees are
                                    load-bearing, not theatre. All commits authored as Steve per the
                                     licence, each footed with the Claude co-author line.

**2026-07-12 — the manifest wildcard-leak fix + the Berth verbs land.** Two things this session.
 (1) The MusuHeist manifest scene was silently losing both denied `%see`s: the note rows carried
  `held`/`denied`/`new` count keys, but `held`/`denied` are now row MAINKEYS (`held,tune:` /
   `denied,tune:`), and the deny scene reads `T.o({denied:1})` — the numeric-1 presence wildcard
    (the o-query footgun, bit again) matched a manifest row instead of the deny note, so `dn.sc.gone`
     came back undefined and both sentences never fired (13/15). Fix: rename the manifest counts to
      `holds`/`refuses`/`fresh`, OMIT zero counts (house rule: absent over 0), update the `man_ok`
       gate to match. Landed clean (LocalGen 44303c), committed by the human in `Seen_split 2`. The
        committed MusuHeist fixtures are still the 13/15 buggy-gen record — the host's in-flight
         `Seen_split` re-record will pick up the fixed gen and reach 15/15 for free (the two missing
          sentences reappear; manifest rows read `uno,fresh=3` / `retomb,holds=8,refuses=1`).
 (2) The **Berth** (§11.7) verbs are BUILT in `Ghost/M/Heist.g` (region `//#region berth`,
  LocalGen-green 38174c): `Berth_dir`/`Berth_open`/`Berth_save`/`Berth_reset`, bound to `enWaft`/
   `deWaft` + the nav contract only, zero Lies. Two refinements from the §11.7 sketch — the on-disk
    dir rides home on `waft.c.berth_dir` (runtime-only) so `Berth_save(nav, waft)` needs only the
     waft, and the save uses `write_file` (the toc.snap is TEXT) not `bin_write`. Reset-with-Story
      falls out of homing under the marrauding root: `Heist_sweep` already empties it. The MusuBerth
       Book proving the disk round-trip + reset was authored + registered same session; live-gate
        OWED (the only runner was wedged — total:1 on every dispatch until a tab reload).

**2026-07-12 (night) — the Booth (§11) vetting blow-by-blow.** Round 1 (five Opus critics):
 Strike→Ban (`%Knob strike` is live skip vocabulary, Radiola.g:252); Rota.g+Tune.g→one Booth.g
  (two-file litter, Rota one letter from rotation:); Ident→Marquee + parked (Idento collision +
   "ident" = the on-air sting); flat twelve-organ list recast as calls/evidence/parked with the
    story first (half the organs had no door — the headline model didn't cover the family);
     Rest's "self-cleaning" was FALSE as written (doors are demand-driven; sweeping in a read-probe
      is a side-effecting query) → read-as-absent + sweep-at-next-Booth-write; Ban at: resolved NO
       (fixture churn, the newlyadded seq lesson); Hunch re-classed as mechanism and moved last;
        Liner+Marquee parked; charts demoted to a function; the "one re-record" migration honesty
         fixed (26 fixture files + both see sentences + the enrollment-order bomb). Round 2 (three
          fresh critics): SHIP-WITH-FIXES — Booth_banned→Booth_bans (probe as question), Hunch
           enum killed (act-as-key + waved_off:), until:→back:, want_only:→raid:, airplay ts
            dropped, Cut decided over Slot/Track, Musuation {tune:1} namesake flagged, two see
             sentences drafted + pinned. Checklist verified against live code: zero line drift.

**2026-07-12 (night) — MusuHeist live-gate CLEARED + sabotage-proven; the %Tombstone gear BUILT
 (roadmap §10.2 #6), live-gate owed for morning.** The prior entry's owed live-gate is DONE: on a
  focused runner tab (a backgrounded tab freezes mid-run — Page Lifecycle, not a Book bug, so the
   honest recipe stays "installed PWA left visible") MusuHeist ran PACED (30 deterministic steps, one
    edge per snap), green ×2 (`ok_pct:1, caveat:28` — the benign AudibleEntropy ≈ signature), all 10
     %see present, then the seal assertion (#2) was SABOTAGE-PROVEN: neuter `w.c.repli_allow` to
      allow-all (the exact tautology the `both_live` gate names) → the run went RED (`ok_pct:0.1`) and
       the live step-4 snap carried ZERO occurrences of the see #2 sentence — it DROPS the instant the
        consent gate is neutered — then green again on restore. The gate is load-bearing, not theatre.
         Runner released; fixtures committed by the host ("cooking the books"). Two map corrections
          this cleared: **§10.2 #7 (FSA `bin_write` self-heal) is BUILT** — `bin_write` catches a
           stale-handle `NotFoundError`, force-re-walks via `mkdirp_fresh`, retries once (Housing.svelte.ts);
            a runner is leave-up-able. And the design/test split + one-edge-per-snap pacing held under
             the adversarial probe.
 **Then, build-only overnight (no live verify — the tab freezes unfocused): the remembered-denials
  tombstone (§10.2 #6) is BUILT and compile-clean, live-gate OWED.** A dropped identity used to
   silently re-offer on a later heist (dedup skips only what is HELD). Now `Heist_feel`'s drop mints a
    durable **`%Tombstone,artist,title`** on the collection (the `%UnGrant` negative-fact PATTERN reused
     for a track — catalog identity, never source; it outlives the card and every flatten), and
      `Heist_beat` consults `Heist_tombstoned` at the door beside `Heist_held` — HELD = already have it,
       TOMBSTONED = chose against it, both drop the husk, tallied apart (`job.sc.tombstoned`). MusuHeist
        grew a **`retomb`** phase after `deny` (seal→uno→duo→reuno→deny→**retomb**→flat→done): Uno
         re-offers Duo's whole 8-shelf ONCE MORE after dropping one Fourier Four track — expected
          `tombstoned=1, landed=0, skipped=7` (the 1 denied identity refused, the 7 still-held skip),
           an 11th %see pinning it. The see was ADVERSARIALLY HARDENED before recording (an audit agent
            found the wildcard `{Tombstone:1}` count didn't verify identity, and `!landed` leaned on
             branch-ordering vs the shared ra_wanted cursor): it now checks the %Tombstone is keyed to the
              DENIED identity (`dn.sc.drop_artist/title`, captured in `MusuHeist_deny` before the card
               retires) AND `uno_lib` still holds exactly 7 Records (an explicit no-reland invariant). Both
                `.g` LocalGen-compiled (gen written, symbols confirmed); toc seeded to 42 steps (comfortable
                 headroom over the ~35 the retomb scene needs); `.jamsend` stays gitignored.
 **A SECOND audit hardened five MORE sees while the Book is open for re-record (free — the whole thing
  re-records anyway).** The un-audited witnesses had real holes: **#1** checked "whole original bytes" for
   Duo's 2 tracks only — 6 of 8 unwitnessed (now both libs run the chunk-completeness loop); **#8** the
    "never a word about the source" invariant only forbade the two run-specific prepub STRINGS — any other
     provenance form (a nick, a source path, an appended `from:`) passed (now every log entry must EXACTLY
      equal a held card's path, space-safe, so any extra token drops the see); **#10** "nothing attributes"
       was unasserted (now no surviving collection card may carry a `source`/`from` key — provenance lives
        on the mirror cards' `.c` only, never snapped); **#6** the chillwave/bangers split wasn't per-artist
         (a genre swap kept 3+3 and passed — now each count is artist-scoped); **#5** matched a bare
          `-mathrock/` substring (now the full `pfx`-prefixed genre). Sees #2/#9/#11 were already hardened;
           #3/#4/#7 were judged tight (the #3 "filing===2" idea CONFLICTS with its own "nothing landed yet"
            clause — job uno lands before a 2-filing job exists — so it was NOT applied). All five honest-case
             traced + LocalGen-recompiled clean.
 **THE NEXT MOVE (morning, live — this is the owed gate):** reload the runner tab (a fresh handle),
  `runner_ask.mjs run MusuHeist --watch --runner=<prefix>`, expect RED at the tail first pass (the new
   `%Tombstone` line perturbs every post-deny snap + the retomb scene is unrecorded) → re-dispatch,
    confirm `state` shows MusuHeist active, `accept` (records the tombstone perturbation + steps 31-3x),
     re-run green ×2, CONFIRM all **11** %see present (pre-pin then grep the fixtures — a dropped see is
      the silent failure), then SABOTAGE-PROOF the new gear: neuter `Heist_tombstoned` to `=> false`,
       LocalGen-recompile → the denied track re-heists (`landed=1, tombstoned=0`) → see #11 DROPS → red,
        then restore + recompile so disk is clean. If ANY hardened see drops (the retomb counts, or a newly
         tightened #1/#5/#6/#8/#10 that traced-but-wasn't-run), it is a threshold to tune at accept time, not
          a redesign — the honest-case was reasoned, not executed, so one may be off by a genre-prefix or a
           count. A dropped see is a loud, specific red; fix the clause and re-run.

**2026-07-12 — MusuHeist paced + design/test-split + swept both ends; live-gate STILL owed.** Three
 fixes on rung 1's Book after the owner watched it run: (1) PACING — the phase machine advances ONE EDGE
  PER SNAP (gated on `step_n` / `w.c.acted_step`); a self-advancing machine drained the whole heist into
   one 22s snap, or a nondeterministic 1-vs-15 spread. `expecting()`/ttlilt is the OTHER tool (hold one
    snap for the slow census disk-walk, off the mutex) — not the pacer. (2) The %testing SPLIT — every
     test observation now hangs under `w/%testing` (the `heisted:<nick>` node + `on_disk` monitoring,
      census/sealed/newlyadded_shape/denied/flattened, the 10 %see); the design (Piers/Grants/Libraries/
       %Heist) stays clean on `w`, and `Ghost/M/Heist.g` is now the PURE engine — it stamps NO test
        markers on the world (that was the non-deterministic `heist_land_fail` bug). (3) start + END
         sweep, files-only + snap-invisible (the repo never keeps WAV bytes; `.jamsend` gitignored). Book
          is 30 steps now. Metadata is FILENAME-derived — the test tones carry no tags. **The full
           what's-real map + the `<` unbuilt roadmap is now §10.2** (supersedes the "BUILD STATUS" bullet
            below, which is pre-pacing). Live-gate owed: reload the tab (a dead FSA dir handle in
             `WormholeNav._cache` poisons landings), CHECK -> accept -> green x2, adversarial probe.

**2026-07-11 (day) — the HEIST design decided (owner Q&A): the rest of Radio+Piracy is an
 rsync job creator.** Prior art re-read on owner's pointer: `src/lib/ghost/Pirating.svelte`
  (heist req → local-dir prep BEFORE the wire → spool → resume-by-rematching) and its merge
   model — the remote path inflates into `%place,bit,uri` particles (collection|directory|blob)
    and the user BELIEVES or DISBELIEVES each layer (`disbelieve_directories`, `only_categories`,
     per-file rename), the surviving bits joining into `destination_directories`. The decisions:
 - **Payload = ORIGINAL file bytes** — new body chunk-particles beside `%Preview`/`%Stream`,
    byte-faithful (`body_hash` vs the source file). Consequence: the source side must walk REAL
     files, so a slice of §9.1 rides the first Book. Deferred: a "nicely transcoded send" mode
      (IDv3 tagging + album-art embedding) — later, subagented.
 - **Job = `%Heist,at:<pier>`** (+ optional match; absent = everything = klepto v1). A saved
    match graduates into §9.2's `%Share` later. Sibling (speculative): a **%TreasureMap** — a
     Pier pointing at things, maybe a music micro-blog form. Pier|TreasureMap|Heist exist FOR AS
      LITTLE TIME AS POSSIBLE then flatten off — scaffolding, not ledger. While a Heist RUNS you
       can see who's whatting; afterwards nothing attributes.
 - **Landing = STRAIGHT INTO THE COLLECTION at download time** (no staging dir); the merge
    decision (believe/disbelieve layers, remembered defaults) is therefore made at
     heist-creation — exactly the old step-2→step-4 flow. Probation is purely metadata:
      **`.jamsend/newlyadded`** (`.jamsend` is ALL meta, never bytes) logs what arrived recently
       + how the listener feels about it so far; deny = delete from the collection. The log's
        purpose: shuffle new music into the listening diet coherently for the first week or two —
         grow to love it (→ the koha list, things to give back for) or drop it completely. It
          NEVER shows where music came from; graduation later feeds blog-writing and freer
           classification|appreciation systems.
 - **Provenance: NOT persisted.** Dedup is by CATALOG identity, not source — cataloguing notices
    an Artist-Album is already held and skips, or UPGRADES it (e.g. to flac) if policy allows.
 - **BUILD STATUS (same day, night): rung 1 is BUILT + wired, live-gate PENDING.** `Ghost/M/Heist.g`
    (census/job/beat/land/newlyadded/feel/sweep — %Body,seq original-byte chunks on %Record cards, the
     generic Repli want/park/serve moving them unchanged; quarantine mirror = a `<prepub>.heist` shelf
      key) + `Ghost/Story/Heistation.g` (Book **MusuHeist**, 18 seeded steps, 10 %see: divided census →
       seal → job-pinned filings → byte-faithful DISK-verified landings both ways → re-heist dedup →
        unsourced newlyadded → deny-drops-file → flatten). Both LocalGen-compiled, enrolled in
         CREDULER_GHOSTS, registered in Credence (+brand_new) + the Ality overlay; toc seeded
          (UNTRACKED — no dispatch before a runner tab reload). Deferred within rung 1: the
           remembered-denials tombstone (a denied identity re-offers on a later heist — the %UnGrant
            shape wants reusing) and the same-identity format-upgrade path.
 - **First Book = rung 1** (loopback, needsFSA), home a NEW **`Ghost/M/Heist.g`** riding Repli:
    TWO Piers share the SAME `testsounds/` FSA dir (the existing 8-WAV flat share — barely any
     directory structure at first, and that's fine). The dedup trap (each Pier already "has"
      everything the other offers) is dissolved by a **test mode that DIVIDES THE ARTISTS between
       the Piers** — a whittled-down census so each seems to hold different music: Uno offers
        "The Sines" + "DJ Oscillo", Duo offers "Fourier Four", etc. Each files what it heists
         under DIFFERENT genre categories at its end. A per-Pier
          **`.jamsend/test-marrauding-of-<runid>`** override (they share one FSA location)
           namespaces meta + `newlyadded` + landing categories per Pier per run, so the run's
            work deletes cleanly (one `rm -r` per marrauding dir). The believe/disbelieve merge
             (old Pirating steps 2+4) is pinned as DATA in the Book — UI comes later. Assert:
              byte-faithful `body_hash` per landed file + the `newlyadded` log shape.

**2026-07-11 (night) — MusuRaChase FIRST-LIT + RECORDED; the whole family green.**
 The CHECK run (all 56 steps, real audio, ~4min) needed NO threshold tuning — every gate passed
  with slack: `chased,at_head=20,warm=16` and `skip:B,at_head=10,warm=16` (gate ≥6),
   `b_heard=0` (gate ≤3, zero drops), decoded `lufs=-14` dead on target. Accepted with the
    %see pre-pin discipline: all 15 Chase sentences survived into the fixtures (verified against
     the pre-pinned set — none fuzz-swallowed). Verify re-runs 56/56 green twice (≈53/≈54 —
      the predicted two-seal AudibleEntropy signature; the ±1 is round= wobble). The owed
       float32-compat runs also green: MusuReplica 14/14 (≈10), MusuReco 11/11 (≈3).
 **Assertion upgrades LANDED + SABOTAGE-PROVEN (same day, eve).** The three audit upgrades are in
  the recorded fixtures (committed in `e2bef100 tests`): `src`+`cands` on the chased AND skip rows
   (Radiation.g — kills both PRNG-luck slip channels; `cands` reads the runtime-only
    `w.c.ra_dial_cands` stamp in Ra_dial_next), and the post-dark `fanout_dark,of,warm` row (of=1
     post-dark). Verified on a warm runner: green ×2 (56/56, the stable ≈54 signature; rows match
      the fixtures verbatim — `chased,…,src:Duo,cands=2`), all 15 %see sentences re-confirmed
       present, and the sabotage KILL: deleting the `ra_source_live` gate in Ra_restock_beat went
        RED from step 20 (ok_pct 0.34, 37 reds; live `fanout_dark,of=3,warm=3` vs the pinned of=1 —
         the formerly-dead-weight gate now has its line to die on; the untouched dial gate's
          `skip:B,…,src:Duo` still matched, so the kill is surgically the restock's), then green
           again on revert. Deliberately NOT done, still owed: the `keep_ahead=2` pin (with a
            3-candidate catalog it would falsify the fan-out sentence "kept EVERY other preview
             warm" — it belongs in a single-source Book) and the mid-run revoke variant (a new
              scene) so `repli_allow` refuses at least once in-Book.

 **Adversarial audit (agent + one live sabotage).** The live probe: gate the chase %see on
  `warm >= 99` (Radiation.g:1232 via LocalGen) → the run went RED from exactly step 15 (its landing
   step), then green again on revert — the Book catches its own regression, and a LocalGen disk
    write DOES hot-load into live tabs.  The audit's structural verdict: NO see or marker sits in a
     fuzz-tolerated zone (the ≈53 come entirely from `since:`/`time:`/`sign:`/`round` churn on
      society lines), and a missing/moved line is never swallowable (positional line-zip; length
       mismatch = hard red).  The REAL weakness class: presence gates already satisfied (or never
        challenged) by the time the fixtures were cut — four named slips: (1) `Ra_keep_ahead`'s
         `w.sc.keep_ahead` pin is untested (catalog-minus-playing == the pin, the clamp never
          bites); (2) the restock fan-out's `ra_source_live` gate is dead weight post-dark (every
           preview already whole — deleting it changes nothing); (3) `repli_allow` never refuses
            during a Chase run (consent enforcement rides MusuRaCast's revoke arm alone); (4) the
             chase pick's cross-Pier-ness is enforced by the pinned PRNG, not an assertion
              (deleting the `skip_src` gate can slip if the pinned rand re-picks the same record).
   One-line upgrades (owed, cheap): stamp `src` on the `chased` row; stamp candidate-count on the
    `skip` row; a post-dark `fanout_dark,of=N` row; pin `keep_ahead=2` (below catalog-1) so the
     clamp bites; a mid-run revoke variant so `repli_allow` refuses at least once in-Book.
 Operational lessons of the night (memory: frozen-boot-empty-first-run, editor-think-quiesce-decay):
  a tab that froze right after boot runs its FIRST dispatched Book with EMPTY steps (Creduler
   acquire incomplete — step 1 green, rest red, no `reached:step_N`; self-heals on thaw, so burn
    a cheap green Book first), and the editor's "● connected — no identity / beacons stale" +
     held become_book = idle think-quiesce freezing the in-think roster fold, NOT a transport
      failure (beacons park unfolded on `w.c.beacons`; any think heals; a beacon-driven keepalive
       nudge is BUILT in LiesLies, live-proven over 20 idle minutes).  A SECOND, harder disease
        showed at 09:11: a brief system freeze thaw-WEDGED the editor's belief loop permanently
         (pings alive, thinks dead, no self-heal in 13 min; both runners survived the same freeze)
          — editor-only in-think path, needs the tab console; the wedged tab is a live specimen,
           root-cause in DevTools BEFORE reloading.  Full trail in memory
            editor-think-quiesce-decay.

**2026-07-11 (later) — the proto-VILLAGE: multi-caster Repli + KEEP_AHEAD + the entropy seam +
 skip-by-who-is-online.**
 The restock fan-out (the "natural next" below) landed, and it landed SOCIAL: the new Book
  **MusuRaChase** (Radiation.g — the FIFTH Ra* Book, 15 `%see`; Credence row needsFSA+needMusic,
   brand_new; toc seeded 56 lie steps) is MusuRaStream grown into a little village.  Uno and Duo
    each stock a DISJOINT testsounds slice (`Ra_stock` grew a `from` offset) on their own
     prepub-keyed radiostock; each GENERATES a single-use Idzeug and the Listener REDEEMS both over
      two Lake_links — the real front door, never a promotion shortcut — and the mutual Music grant
       gates every Radio leg.  The listen runs on Uno track A while `Ra_restock_beat` keeps every
        OTHER preview warm across BOTH wires; the dial CHASES to a Duo record (instant start on the
         warm preview, continuation from the SECOND caster's demand-driven transcode); then the
          VILLAGE EVENT — Uno goes DARK (its carrier falls; the presence hook `w.c.ra_source_live`
           = grants + carriers turns false) and the owner SKIPS the playing track mid-cycle:
            `Ra_dial_next` turns the dial ONLY among sources still online, so the pick is forced to
             Duo's remaining record — a track can always be skipped, and the next one comes from
              whoever is really there.  `Ra_dial_next(w, mirror, opts)` is the ONE dial verb:
               opts.skip_src (chase to the other Pier), opts.id (the later "pick one deliberately"
                seam), else the seeded|stirred entropy dial; the same presence hook gates the
                 restock fan-out, so a dark Pier neither warms nor wins.

 **What changed in the engines (all backwards-compatible; the four old Books re-ran green
  first — Cast 12/12 ≈9, Stream 40/40 ≈37, signatures untouched):**
 - **Repli is multi-caster now** (Repli.g): `Repli_register_caster(w, pier, lib)` /
    `Repli_register_rx(w, pier)` + `Repli_src_for`/`Repli_rx_ok` replace the single `w.c.tx`/`w.c.rx`
     identity guards (those remain the legacy default).  The consent hook grew a second argument —
      `w.c.repli_allow(peer, at)`, `at` = the SERVING prepub — so ONE hook answers per-relationship
       (Uno revoking silences Uno's legs and leaves Duo casting).  Mirror %Records get `.c.from`/`.c.rx`
        source breadcrumbs at `Repli_recv_lines` (runtime-only, nothing snaps): the wire follows the
         track.  `Ra_transcode_pump` now serves EVERY registered caster off its own shelf.
 - **The entropy seam** (Ra.g `//#region entropy`): `Ra_rand(w, n)` picks off a per-w PRNG that
    crypto-seeds lazily (the live default), `Ra_seed(w, str)` REPLACES the state (a Book pins the whole
     dial), and `Ra_entropy(w, vals)` STIRS live values in — the way to inject entropy into instances
      that are supposed to be random, without a Book losing determinism.  MusuRaChase probes it mid-run:
       the same pinned state picks differently after a fixed stir, and the fixture reads both picks.
 - **KEEP_AHEAD** = `Ra_keep_ahead(w)` (default 4; `w.sc.keep_ahead` pins) — records-ahead ACROSS the
    catalog; `Ra_restock_beat(w, mirror, budget)` wants the missing preview pages of the next K records
     (want-once, budgeted per beat so it shares the wire, CLAMPED to each preview window — a prefetch
      can never park a want or ignite a transcode).
 - **radiostock pub is a PREPUB, always** (standardised 2026-07-11): MusuRaStock/MusuRaTerm mint
    deterministic identities for their shelf keys — the `'DJ'`/`'raterm.player'` literals retired, and
     the one-time `Ra_stock` sweep now drops old literal-key files in passing.

 **Lifecycle verdict (owner asked: is the old coming-and-going worth keeping?).**  The old
  Radios/Directory lifecycle (random `load_random_records` + FIFO `whittle_stock` + setTimeout magic)
   does NOT come back.  In the new economy the shelf IS one's own collection — no count-bound whittle;
    GC is newest-ts twin supersession + the dead-source drop, both standing (§1.4) — and the listener
     side holds NO cache at all (pulled chunks are ephemera), so ITS coming-and-going is pure
      want-pacing: the session window + the restock fan-out.  The KEEP_AHEAD chase was the old
       machine's last live idea; it now rides Repli offers.  Nothing else there is owed a re-draw.

 **Verification state + next moves:**
 - MusuRaStock re-recorded 5/5 green on the prepub shelf key.  MusuRaTerm re-record and the
    MusuRaChase first CHECK run are IN FLIGHT this session — if you are the next fork: MusuRaChase is
     seeded (56 lie steps + the AudibleEntropy Wref) and registered (Credence + Ality), and needs a
      RUNNER TAB RELOAD before its first dispatch (the total:1 bomb, §2 — and the seeded toc is
       UNTRACKED: a premature dispatch clobbers it; re-seed from the loop in the session notes);
        then a CHECK run tunes the thresholds (warm >= 6 at chase AND at skip, b_heard <= 3, LUFS ±2)
         and the accept follows the %see pre-pin discipline (§1.5 — 15 Chase sentences).  Expect a
          new benign ≈ signature (TWO seals graft double the AudibleEntropy fields).  Float32-path
           compat (MusuReplica/MusuReco re-run) is also still owed.
 - **real `/music`** (§9.1) — point `Ra_stock` at the real library; the ONE mock §3.6 names.
 - **Klepto rung 10.2** (§10) — 2+ real runners; kills the tame in-process wire, the OTHER mock.
 - **§9.2 Shares / §9.4 multicast live edge / §9.5 Sent_Tree** — the live edge is a THIRD encode
    mode (chained, no seek — §1.2's orthogonal cousin); Sent_Se is half-built.

**2026-07-11 — the chunk-particle machine STANDS; nothing in the pipeline is owed.**
 The design is distilled at **§1.1–§1.5** (read those first — they are the machine as it IS).
  All four `MusuRa*` are live-green and re-recorded: Stock 5/5, Cast 12/12, Term 12/12 (≈0,
   deterministic), Stream 40/40. The arc that got here, one line: the preview economy was first
    built as a hand-rolled wire (`rec.c.segs`, `have=` counters) → owner overruled ("how will
     Repli be generic with some .c.bollocks array to manage?") → rebuilt same day on REAL chunk
      particles + generic Repli → four owner rulings folded (preview CONST 32, radiostock
       `<ts>-<pub>-<enid>`, no friend cache, dead-source drop) → re-recorded 2026-07-11.
        Session-level history lives in git (`d26ce069` "Ra Repli", `4add5244`), not here.
