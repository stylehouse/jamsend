# Radio_buildlog.md — dated session diaries moved out of Radio_todo.md §0

HISTORICITY: these are the "on this day" build-diary entries that used to accrete in
 Radio_todo.md §0 (moved here 2026-07-12 on the human's ruling: §0 stays a brief, not a log).
  The living state, roadmap and design are in Radio_todo.md — read THAT; come here only for
   the archaeology of how a thing landed. Newest first.

**2026-07-14 (later, autonomous) — THE SNAP READS LIKE THE SESSION: N1-N5 snap-hygiene + the Card rename + the
 Jam ledger. Code landed compile-clean; fleet re-record OWED (runners were flaky, work was done blind).** The
  human read MusuBuddy's fresh snaps and named the smells: fake-looking `%Record` cards that impersonate the
   audio holdings ("there's only one of anything"), an `{"undef":["path"]}` brand, 38 dead `req:awaitbuf` rows,
    and a browse with no structure ("I should be able to glance and see what they played to each other, what
     each liked, what each heisted — I say get there"). Five moves, all coded this session, none yet re-gated
      on a runner:
- **N1** guarded three unconditional `k: rec.sc.k` mints (Musica_fold card, heist-landing, reflect) → the
   `undef` brand gone. **N3** made `Repli_attach_page` `drop()` the holding req once bytes land (`finish()` only
    marks `%finished`, never detaches — the 38 rows) — an unlanded awaitbuf stays; MusuReplica's `warns_missing`
     reads only the unlanded set. **Adversarial review (opus): SAFE** — `o({req:1})` is a fresh snapshot so the
      mid-sweep drop can't corrupt iteration, the re-entry is idempotent, and the withheld-bytes awaitbuf still
       latches `warns_missing`. **N5** distilled three rulings into CLAUDE.md (identity-per-shelf + referring
      particles; no maybe-undef sc; drop finished transient reqs).
- **N2 — the card stops impersonating `%Record`.** Cards under a `%Cloud` → `%Card`; holdings under a `%Library`
   stay `%Record`. Chosen shape **`Card,id:<id>` (Option B — KEEP the id scalar)**, NOT mainkey-value `Card:<id>`:
    `Repli_loc_keys` gives `['Card','id']` (id-ish) = byte-identical wire behavior to the old `Record,id`, no
     `repli_loc` hint, and ZERO `.sc.id` reader ripple — so N2 was a near-pure mainkey-WORD swap on the
      Cloud-child sites, and the finder helpers + the browse survived untouched. `%Card` is not a new coinage —
       it REUSES MusuBerth's existing `Card` (a saved track-reference; the magazine card is a full listing, the
        Berth toy a degenerate `Card,tune,verdict` — same family, MusuBerth unaffected). Both files audited (every
         remaining `Record:1` is a holding). **Adversarial review (opus subagent) returned VERDICT: SOUND** —
          confirmed the one direct mainkey reader (`Repli.g:461 if c.sc.Record`, the audio-pull breadcrumb) is
           correctly Record-only (cards never pull audio), cursors + goner-delete loc all correct; it flagged
            the `%Card`/Berth reuse for a human eyeball (I hold it a legit unification, not the sin) and two
             stale comments (fixed).
- **N4 — the Jam ledger (the browse gets structure).** New family ghost **`Ghost/M/Jam.g`** (enrolled in
   CREDULER_GHOSTS): a `Jam,with:<dj>` session under the listener's shelf holding ordered **`Spin,of:<id>,title,at`
    / `Like,of:<id>,at` / `Grab,of:<id>,at`** facts — `Grab`, NOT `Heist` (that mainkey is the reserved operation
     `%Heist,at:<pier>`); `of:` is the N:1 referring form. `Jam_grab` also copies the pulled holding (scalars +
      chunk children, bytes shared) into a caller-supplied `kept` shelf. Wired into MusuBuddy: `MusuBuddy_jam` at
       the tail of HEAR (beat 10) spins/likes/grabs the browsed track into the mirror `%Jam` + a keeper in a
        distinct `%Kept,pier:<lis>` shelf (grabbing into the mirror would just re-find the husk). Two new sees
         (beat 11): the ledger reads Spin→Like→Grab in `at` order (reads the real rows), and the keeper stands
          WHOLE in `%Kept` while the husk still stands in the mirror (copy-not-move). 13 sees. Adversarial review
           (opus): both sees SOUND — live-data reads with verified one-line breaks, no blocking bug.
- **LIVE-RECORDED GREEN (the human said "run all the tests").** All 14 affected Books re-recorded green on the
   :9091 runner: N2 — MusuBuddy/Cursor/Recast/Rename/Heal/Standing/Resume/Vend/Door/Heist (each verified by its
    OWN claims: cursor resolves on Card cards, the goner-delete is surgical with no orphan, the rename-heal
     fires through %Renamed, forget drops old Card clouds, the sabotage stays inert, the census→magazine holds);
      N3 — MusuBuddy/Heist/RaStream/RaChase/Reco/Replica (zero landed-awaitbuf rows; MusuReplica keeps its ONE
       unlanded `warned:buffer_late` row so `warns_missing` still latches — the missing-buffer proof survived).
        VoroTest turned out NOT in the union (its `awaitbuf` is a static Voro fold-test leaf, not Repli — the N3
         reviewer's catch, confirmed). Non-union sanity green: MusuStaple (music, %Record), PereStaple (non-music
          Repli spine) — the changes are cleanly scoped to music. **TWO real bugs the live runner caught that the
           static reviews could NOT:** (1) the jam ran a beat too early — `MusuBuddy_jam` at hear's tail fired
            BEFORE `expecting()` resolved `w.c.term` (expecting DEFERS; `await` returns after ARMING, not
             resolving) → moved it to beat 11, gated on the resolved term (the "wake ≠ hold" trap); (2)
              `Jam_ledger`'s `jam.o({at:1})` returned NOTHING — a mainkey-LESS query finds no bucket in the o()
               index → gather by the three event mainkeys then sort by `at`. Both fixed, re-delivered, re-verified
                green. The runner gate earned its keep. (Gen delivery via `ghost-compile` was intermittently
                 half-open — retry worked each time; LocalGen kept the disk gen honest in parallel.)
- **Plus a UI bit (graph legibility):** `Matstyle.matstyle_seed_known` gained semantic swatches for the whole
   Radio particle family — `%Record` heavy teal (the audio holding) vs `%Card` light bordered (the listing),
    both title-labelled; `%Spin`/`%Like`/`%Grab` one ellipse family with distinct hues (green played / warm
     liked / amber heisted); `%Jam`/`%Kept`/`%Mag`/`%Cloud` the containers — so the Cyto/Voro graph reads the
      session the way the snap now does, instead of arbitrary auto-palette blobs. Non-contended, type-clean.

**2026-07-14 — the Ra pipeline RE-DRAW: MusuBuddy consolidates stock|cast|play under the magazine; the three
 standalone Ra* Books RETIRED. LIVE-GREEN ×2.** The human challenged the reflex to write yet another Book:
  "do MusuRaStock|Cast|Term really stay relevant once we have the magazine, or is that the same job twice?"
   and "you can totally mutate tests that already exist." The honest split (grounded in §3.6's real-vs-mock
    ledger): the magazine is the CATALOG (identity leaves — "the magazine is the catalog not the payload"),
     the Ra pipeline is the PAYLOAD (real `OfflineAudioContext`→LUFS→Opus→`.jam`→decode PCM); orthogonal axes
      that MEET. But the three standalone Ra* Books proved stock|cast|play in a config the destination never
       runs — a stream with no catalog naming it. So the move was NOT another test: build the integrated Book,
        stand it green, THEN delete the oldies (they stay green as the safety net during the hop — §3.5's
         "nothing deleted until its re-draw stands"). New Book **MusuBuddy** (`Ghost/Story/Radiation.g`, after
          MusuRaChase): 14 beats — stock two real tracks + wire (2), idempotent restock (3), seal (4), then
           flow legs fire on preconditions — `Musica_stand` publishes the `%Musica` magazine + husks over the
            granted wire; a title-pinned `%Dogear` browses the follower MIRROR to a card; the browsed card's
             id = its Record id, so it PULLS ITS OWN audio whole (park|ignite on demand) while the unbrowsed
              husk stays unspent; HEAR (10) decodes the PULLED bytes; REVOKE (12) — a fresh origin draw meets
               the closed gate, zero frames. 11 sees absorbing RaStock (opposite-gains + idempotent restock),
                RaCast (seal + husk + park/serve + byte-faithful pull + revoke silence), RaTerm (LUFS survives
                 the opus trip + honest starve + gapless), plus three NEW: browse-by-meaning, unbrowsed-husk-
                  unspent (the economy), stale-magazine-after-revoke. CHECK run gave the real numbers with big
                   margins (lufs −14.02 vs −14; healthy 0 / starved 280) — NO tuning. Adversarial review (opus)
                    returned all 11 SOUND, each with a verified one-line break, all four false-green suspects
                     defused. It ALSO surfaced a real latent consent-gap (`Repli_send_lines` bypasses
                      `repli_allow` → goner deletes leak to a revoked follower) — NOT MusuBuddy's claim, parked
                       in Radio_todo §0.9 (the low-priority lot), not fixed here. Recorded + warm-verified
                        green ×2 (steps 4–14 ride benign `AudibleEntropy` ≈ — a sealed real-audio Book, caveat:0
                         unreachable by design). Then RETIRED MusuRaStock/RaCast/RaTerm — deleted the three Book
                          regions (`Radiation.g` shrank ~530 lines, gen 106975c→73814c), their `wormhole/Story/`
                           fixtures, and their Credence + Ality rows; `Ghost/M/Ra.g` untouched; RaStream/RaChase
                            + the real-audio lowlevels + the seeder stay. GOTCHA: the post-delete gen re-compile
                             HMR-wedged the sole runner (begun-wedge — heals on a tab reload); MusuBuddy's green
                              is banked from before the delete, its Credulate re-pins to the trimmed gen on the
                               next clean run — benign gen-pin churn, not a re-gate.

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


---

# 2026-07-19 — the whole Radio_todo §0 rolling brief, moved here on the trim

The human (2026-07-19): the todo carried too much noisy detail.  Everything below is the §0
 body as it stood — the robusticise marathon blocks (uncommitted work) AND the landed dated
  rungs (2026-07-13..17, all DONE/green — their remainders live on as the §0 owed ledger).
   Verbatim, nothing rewritten.

**THE ROBUSTICISE ROUND (2026-07-19 morning, post-dawn — UNCOMMITTED).**  The human's sweep:
 "sanity check and make good allllll things" + hours of budget.  What landed (all compiled:
  LocalGen ×6 ghosts, bundle-proof ×8 faces; Swarmation GREEN 1.0 post-change):

 - **THE SHARE IS WIRED LIVE** (the dawn brief's "one remaining seam").  `Swarm_share_up/`
    `_beat/_loop` (Swarm.g share region): after station standup + radio world standing
     (`top.c.radio_w`, stamped by Stoker_ensure), Repli arms on w:Swarm — my stock casts husks
      to every Music-granted friend (offer on stock-growth|rebirth, presence-gated), their
       casts fill **per-friend %MusuThem crates IN THE RADIO WORLD** (`repli_mirror_by_from`
        + `repli_mirror_w`, opt-in Repli extensions — Books byte-identical), previews warm
         via Ra_restock_beat, parked wants feed Ra_transcode_pump.  The pump is a 600ms
          era-guarded post_do loop (the carrier's own mutex seam).  InvitePanel arms it.
     The radio DIALS THE POOL: Radio_dial_pool joins friend-crate records (first chunk landed)
      into the dial, coin-flip vs my fresh pick; RadioFace says "plays the pool — N of yours
       + M from friends" honestly.  BUG FIXED under it: Radio_pub read c.keys.prepub (ALWAYS
        undefined — c.keys is {pub,key}); now sc.prepub, so the live shelf keys by identity.
 - **RECONNECT ROBUSTICISED** (the "either end refresh" complaint).  Two-layer fix:
    (1) `Swarm_station_routes` re-mints the transport %Pier (+%Ud) for every sealed friendship
     at standup + every socket (re)open — the route was minted ONLY at invite time, so a
      reloaded tab could neither send (route miss) nor hear (no-pier drop) forever.
    (2) **swarm_hi, the rebirth greeting**: a new EPHEMERAL frame kind (Peeroleum send+deliver
     lanes — collision-immune by construction) carrying my station era.  A changed era at the
      hearer = the peer restarted → `Peeroleum_reset_handshake` on the route (inbox unemit
       history gone — the (seq,type)-collision silent mute killed; %Ud kept) + `ra_wanted`
        cursors cleared (lost pulls re-askable).  Sent at (re)open + whenever a pulse pass
         finds a friend silent >15s — self-healing from EITHER side, no epoch ceremony.
 - **%Suggest — async recommendation** ("suggest a track, async to them being online").
    Durable referring particle (enid + title/artist/note) under the friendship %Pier BOTH
     sides + a `suggests` lane in the pier stash (reload-proof).  Delivery: booked lane now +
      re-offered on every arriving hi until their `suggest_got` retires it — store-and-forward
       by construction.  DoorFace: ♪→ per friend suggests the PLAYING track; an arrived
        suggestion shows under the friend row with ▶ once the share's mirror carries the enid.
 - **Mags: the pocket zine.**  `Musica_pop` (Heist.g) — append-only hand-curated %Card into a
    named Berth mag under %Cloud,randomic:'chosen'; `Radio_mag_pop` wraps it live ('Faves',
     berthed at .jamsend/berth/<me>/Faves).  ★ on RadioFace (playing) + RiffFace (standing rec).
 - **RIFFLE REWORKED as the display system** ("split the sprawl across things that become
    nodes").  %Riff cards now wear their OWN face (RiffFace, glass_kinds 'Riff') — the deck
     face (RiffleFace) shrank to crates + location + deal/sweep, plain words (no 'blat' in
      UI).  MY crate walks the REAL share BY FOLDER on the nav contract (one dir_at/expand
       per level, dirs+files split — thousands-safe): '..' + dir cards (alphabetical, cap 12,
        sc.folders honest total, dot/node_modules skipped) + a 6-track random hand; ▶ on an
         unstocked path = Riffle_tune → Ra_stock_one → Radio_tune (the (base,rest) split
          matches the stoker's discipline so enids agree).  Friend crates stay flat mirror
           hands.
 - **NAMING FIXED + MOVED TO THE DOOR.**  Root cause of "never closes/never persists":
    `thang_add` THROWS on an existing tag; Clustation_friendly/pin/adopt re-added under
     already-stored tags → the save rejected mid-await.  New `thang_put` upsert (Thangs.svelte);
      all three switched.  The ?Iz→?I swap now fires the moment redeem lands (was gated on an
       8s seal-watch — a late seal stranded ?Iz and a reload re-presented a spent blob).
        InvitePanel now ASKS THE NAME FIRST (namer snippet at the identity line + the landing
         face; auto-join GATES on named — the newborn answers one question, then the door
          handles the invite by itself).  DoorFace ✎ stays as rename, with honest error notes.
 - **TUNER FIXED** ("no crews yet"): Cyto.svelte:376 looked for the %Tuner only under
    w.c.client_w — a Story-railed commission points that at w:Story while Tuner_ensure mints
     under the RUN world, so the census computed every scan and was thrown away.  Lookup
      widened to the Scannable + its worlds; census/mute/cyto_w all heal from the one seam.

 **GATES STILL OWED (fingers-proofs — two live tabs, one human):** name-at-door round-trip;
  QR seal → stock husks appear in the friend's riffle crate → preview plays → radio pool
   dials it; refresh EITHER tab mid-session → dots re-green within ~15s (the hi exchange) →
    crates refill; suggest while the friend's tab is CLOSED → their reload shows it.
 **Sounditron fixtures**: still awaiting the human's accept (dawn note) — now additionally
  drifted by Riff faces + Radio_pub shelf keying.  Re-record AFTER the fingers-proofs.
 **THE SECOND WAVE (same morning, the human's follow-ups — UNCOMMITTED):**
  - **Relay spoof ANSWERED**: relay.ts routeFromBrowser routes on header.to ONLY — from is
     never checked against the hello-bound addr, so spoofing was real.  The human's ruling
      ("validate their key against the Pier we trust every time; the relay needn't be
       trusting") → the per-era VOUCHER: identity-signed {prepub, pub, era} attached to every
        swarm frame (Swarm_deliver), verified at the hear funnel against the SEALED pier's
         stored pub (cached per sign; sealed-only — pier_hello keeps its Idzeug credential),
          spoofed frames rebuffed BEFORE heard_at.  (Built by the delegated agent this round.)
  - **Editor↔runner epoch FIXED + RE-PINNED (authorized)**: ping frames now carry `boot`
     (SOCKCAP_BOOT, both roles — an incarnation, not an identity, enrolls nothing);
      Lies_pong compares per-Pier peer_boot and Peeroleum_reset_handshake's a reborn peer's
       stream.  The spine adds re-ack on a reused-seq finished-unemit collision (loud warn,
        never silent again).  p2p/pinned_stable/Peeroleum.go promoted from fresh gen per the
         documented procedure (diff was small + additive: CLI by-type dispatch, pier_hello
          first-contact, swarm_hi lane, the re-ack); Tribunal.go unchanged.  OWED: the
           PereProof asymmetric-reconnect Book step (the 2026-07-05 decision said build it
            when the spine re-pins — that is now).
  - **Riffle reimagined** (the human: "deal|sweep is feckin weird"; "see the whole
     testsounds/"): crate chips open, ONE ⟳ flip REPLACES the hand, ✕ closes; my crate deals
      DEEP from the whole subtree below the current path (bounded BFS, noise dirs skipped,
       honest totals + clipped note) so a 4-deep album is one flip away.  (Delegated agent.)
  - **Name input focus fix**: InvitePanel's `self` was a $derived off H.version whose
     transient null collapsed the input's branch (reactivity_docs' form-closing disease) —
      now LATCHED $state (assign only truthy+changed).  (Delegated agent.)
  - **Presence dot honest**: DoorFace three rungs off heard_at (here <15s · fading <45s ·
     away) + a tooltip naming the pulse heartbeat; the 12s window flickered on one lost pulse.
  - **Rundar wording**: a Big*land page labels itself `app` (id_role stamped), never
     'runner'; editor stays editor.
  - **The ZINE cell**: %Zine,name referring cell (never impersonating the disk %Mag) +
     ZineFace — the Faves Berth listed in the glass, ▶ auditions by enid across shelves,
      ★ refreshes it live.  Musica_zine_ensure rides Sounditron_glass.

 **THE THIRD WAVE (the human's pre-absence sweep — UNCOMMITTED, all compiled green):**
  - **Meander starvation KILLED** (Crate_nav_meander): local audio is now ONE branch beside
     each subdir, drawn uniformly — the old audio-first return stopped at the first level with
      any audio, so testsounds' root wavs starved every deep album below (the human's Charif
       Megarbane / Deadfly Ensemble listing).  Flat shares walk exactly as before; noise dirs
        (dot, node_modules) never draw.
  - **ONE BootGate** (kid-friendly): "one tap to open the music" — never names needAC/needFSA,
     proactive on BigSoundland (the gate stands until the AC grant), the tap harvests the
      gesture (keep_awake_acquire) and fires the folder picker ONLY when disk_gated.
  - **The glass de-junked**: CREW_MAINKEYS grew a debug shelf (Dogear — "the one they played
     last night" — Storyrun, Sent_Tree, Crush_Tree → 'system'); a fresh %Tuner defaults the
      system crew MUTED (the boiler-room starts tucked); TunerFace renders NOTHING when bare
       and titles itself "show / hide" (nobody knows what a "tuner" is).
  - **Friends read at full size** (DoorFace 13px + weight; three-rung presence dot here <15s ·
     fading <45s · away, tooltip names the pulse heartbeat).  Rundar's single-pair panel calls
      a Big*land page "app", never 'runner'.
  - **Full-length friend listens**: Swarm_share_beat's keep-ahead leg (see the second wave note
     in [[live-share-wired]] / the share region) — wants ride the REAL playhead ~32s ahead.
  - **Books DELEGATED** (in flight as this brief writes): PereReborn (asymmetric reconnect —
     the collision re-ack + epoch reset teeth) + SwarmShare (per-friend mirror keying,
      %Suggest store-and-forward, hi rebirth reset), then the authorized Sounditron re-record.

 **THE FOURTH WAVE (mid-absence, the human's drive-bys):**
  - **Starvation VERDICT (probed, not guessed):** a headless probe ran the (transcribed)
     branch-weighted meander ×200 over the REAL testsounds tree — 58 distinct tracks, 50 of
      them deep: every album the human listed surfaces (Marzipan, Tayyara Warak, Deadfly
       Ensemble, Resonating Earth), and the nav lists every level cleanly.  The machine is
        cured; the live tab was still running pre-fix gen — the cure arrives with the hard
         reload.  (Probe was a transient scripts/ spec, deleted after the run.)
  - **THE LINEUP** (the human: "constantly producing Mag, up to 20 tracks further than the
     listened-to cursor... any time there's a Pier it should automatically start listening
      to their music... can't get any across should be an ERROR"): %Mag:'Lineup' in the
       radio world — a rolling queue of %Card referring rows the dial consumes head-first
        (playing IS the cursor); Radio_lineup_fill tops it to 20 round-robin across MY crate
         + every granted friend's playable mirror records (friend cards wear by:<prepub>);
          fills at every stoker look + every dial.  STARVE = a real %error row on the lineup
           per granted+present friend contributing nothing playable (self-clearing when
            their first track lands).  LineupFace ("up next · N", friend tags, errors RED)
             in glass_kinds.  Old dial ladder kept as the empty-crates fallback.

 **Posited unknowns (the final figure-out):**
  - Voucher replay: a frame-capturing third party could replay a friend's voucher within its
     era to spoof presence (not grants).  Per-frame header-sign at the Peeroleum seam (the
      spec's designed spot, req_unemit) is the full cure — next spine round.
  - The proactive BootGate on a tab whose gat the browser refuses to init (no audio device?):
     the gate would stand forever — needs a fingers-check on one odd device.
  - Watch_c reactivity for the deeper-state derivations (the human: "it's a little involved")
     — the faces poll H.version + a 1s tick today; the watch_c channel migration is the
      inspiringly-architected version, not yet designed.
  - Full-length friend listens: the pool plays PREVIEW windows (32×2s); the term-stream leg
     (Ra_term_stream_beat at the radio's demand) is proven on Books but not wired to the live
      pump — next rung, small.
  - FSA `expand()` costs a getFile() per file (a 3000-file dir = 3000 awaits on first listing);
     a names-only expand is owed for the riffle at scale.
  - The share offers the WHOLE stock as husks per rebirth (bounded by Stoker_cull ≈24 +
     mirrors excluded) — fine now, wants Repli_sent_se's neu/goner Selection once stocks grow.
  - `pier.c.seq`/unemit rows on the live channel still never cull (whittle is Book-armed);
     the hi-reset bounds the damage but a standing-session sweep is owed.

**THE DAWN SESSION (2026-07-19 5:20am — COMMITTED, 8 commits).**  Everything below through the
 pulse round is in history now (9636136f..03b6eb96); the tree was swept clean in coherent
  stories.  On top: **FIRST-TIME-MODE** — `Clustation_friendly` (name yourself from the
   DoorFace ✎; persists into the identities Thang under prepub AND role tags, rehydrates in
    Clustation_concrete, rides Clustation_pin) and TEACH empty-states on every face (Door,
     Radio off the stoker census, Stoker, Riffle quoting the friend's ive_got boast, InvitePanel
      spelling out the trick to a born-today self).  **THE ONE REMAINING SEAM in the user story**
       (fresh page → … → riffle THEIR crate → their track on my radio): nothing LIVE starts the
        Repli pull that fills %MusuThem after a seal — the mirror machinery is PROVEN on the
         Book wire (Radiation: Repli deL/enL → MusuThem/stock) but the live station wire never
          starts a session.  That is the next rung: seal (or grant-gossip) → Repli_follow over
           the relay → %MusuThem fills → the Riffle's friend crate goes live → Radio_tune plays
            their track.  The Riffle + boast already point users at exactly this door.
 NOTE for the human: Sounditron fixtures committed at dawn predate the Riffle row — the Book
  runs RED on dige until you re-record (accept); all 7 steps run clean live, world rows stand
   (Radio|Stoker stood=4|Riffle|Door).

**THE RIFFLE + DURABLE FRIENDSHIP + THE DIG ROTATION (2026-07-19 latest — uncommitted).**
 The human: "flac in testsounds not appearing… rifle through either collection, blatting out Voro
  cells… the Grant and|or friendship gets lost very easily — how is that not robust as?"
 · **testsounds starvation FIXED** (Radio.g Stoker_dig): flac was never the problem (Crate_is_audio
    has it; decodeAudioData handles it) — the music-first FIRST-BASE-WINS ladder starved testsounds
     entirely.  The starting base now ROTATES per dig (st.c.dig_i through music|''|testsounds);
      music still leads the cycle, a dry base falls through.
 · **FRIENDSHIP SURVIVES RELOAD** (Swarm.g — the iz-ledger disease, second organ): Swarm_seal
    built %Pier|%Grant|%NotGrant as RUNTIME particles; the r2r redial quietly re-sealed only when
     the friend was online — a lone reload LOST the friendship.  `Swarm_pier_stash` (raw grant
      atoms + page + every revocation atom, keyed my-prepub → their-prepub on top-House stashed)
       + `Swarm_piers_rehydrate` at station standup THROUGH idempotent Swarm_seal; `since` no
        longer resets on re-seal; Swarm_revoke stashes its tombstone IMMEDIATELY (a forgotten
         revoke would re-grant on rehydrate — never).  Swarm{Invite,Policy,Staple} headless green.
 · **THE RIFFLE** (Radio.g region riffle + RiffleFace + glass_kinds + Sounditron_glass mint):
    %Riffle face, crew:'Riffle'.  Riffle_homes = my crate + every %MusuThem crate standing
     (friendly names off the sealed Pier).  BLAT deals 6 random %Riff cards — REFERRING
      particles (id + title|artist, stuff:1 → a CELL each; rec ref rides c.rec) — reshuffles on
       exhaustion, sweeps on crate-switch; Riffle_clear shrinks the glass back in one wave.
        `Radio_tune(radio, rec)` = the audition: the card ▶ plays THAT record now (c.tune_rec
         outranks the dial at the pump's next pick, cold radio included).
 · Live gate: Sounditron on 49de ran all 7 steps clean; reds are pure dige drift against
    pre-this-round fixtures (the Book is FIXTURE-CHECKED now — Opt/wild dead) — the human's
     accept re-records.  Live snap 7: `Stoker:idle,stood=4,stock=4,fresh=4` (preheat resurrected
      the shelf at commission — instant-on PROVEN live) + `Riffle:shut` standing.

**INSTANT-ON + THE OLD GHOST'S GEMS (2026-07-19 later — uncommitted).**
 The human: "pre-empt 'digging in the crates' where possible, and have the first bit load and
  play immediately. check the Radios.svelte for more functionality."  Radio.g grew four moves:
 · **Stoker_preheat** — one churn at glass-commission time (Sounditron_glass opts in), while
    the radio is still off: the crates are dug before anyone presses ▶.  LIVE-PROVEN: snap 7
     shows `Stoker:churning` with `Radio:off` — impossible on the old parked-with-the-radio code.
 · **Radio_nudge** — the stoker's landing announcement: first landing of a churn (and a
    resurrection that stood records) pumps a `digging` radio NOW instead of letting it poll out
     its 3s look.  Fresh era so the pending timer chain dies (two chains would double-pump).
 · **Gapless pre-advance** — the dial turns at `end - 2.0s` (was −0.05): the next record dials,
    opens and decodes while the current one plays out, landing AT the frontier (Radio_open never
     resets c.end; Radio_place chains at max(end, now)).  No more ~400ms boundary hole.
 · **Mined from `src/lib/ghost/Radios.svelte`** (legacy quarry, mounts only via lib/mostly):
    **Media Session** (Radio_media_now|pause|off — lockscreen now-playing card, next|pause|play
     handlers, feature-detected; pause KEEPS the card so lockscreen play resumes) and
      **Stoker_cull** (the recordWear death circuitry, simplified: shelf cap 24, HEARD non-playing
       records wear out oldest-first, sc.worn counts — bytes still stand in radiostock, one
        resurrection away).  NOT ported (noted for later rungs): live-edge melt/playbackRate
         flow control (needs a remote broadcaster — §9's leg), ack_seq STAY_AHEAD spooling (same),
          the disk-side 200-item radiostock cache whittle.  Also fixed: an unconsumed
           churn_asked with no disk share held the stoker out of its park forever (headless tell).
 · OPEN EYE for the soak tab: live snap 7 showed `stock=0` beside `last:Query E` mid-churn —
    `last` stamps on a re-found standing record while `dug` counts only shelf-count DELTA, so a
     re-find explains it; but if ▶ on a real tab still waits, look at Radio_pub drift ('me' →
      prepub) re-keying Ra_home_self mid-sitting, stranding stock under the old shelf.

**THE DOOR + /system/ + THE PULSE (2026-07-19 — uncommitted; the "hardly anything is happening" fix).**
 The human: "once the ?Iz is claimed it should change to ?I=$pub… auto-join if their Identity was
  born today… another UI thing floating in the VoroCyto… a /system/ subcellularity… I'm reloading
   one client, I should be able to see that in the other client."  Four organs:
 · **The claim arc** (`Auto.svelte` + `InvitePanel.svelte`): identities now carry `born`
    (Clustation_mint stamps epoch into the Thang; concrete stamps sc.born yyyy-mm-dd — adopted
     legacy keys stay honestly birthless).  A SEALED ?Iz claim rewrites the address bar to
      `?I=<my prepub>` — but PINS first (`Clustation_pin`: the role-tagged default self is stored
       only under 'sound'; an unpinned ?I=<prepub> reload would MINT A STRANGER and orphan the
        friendship).  A self BORN TODAY auto-joins a landed invite (the scan was the intent;
         older identities keep the deliberate button).  InvitePanel shares its landing state as
          `H.c.door` (runtime beacon) for the glass.
 · **The %Door face** (`DoorFace.svelte`, imposed-priority sparkle): who am I (nick · prepub8 ·
    born, ✨ badge on born-today) · a landed invite joining · sealed friends each with grant,
     records boast, and the PULSE DOT.
 · **/system/** (`glass_faces.ts CREW_MAINKEYS`): req/Machine/Relay/Census/Possibility/Session/
    Tally/Audio tessellate under ONE 'system' crew — one tuner toggle tucks the boiler-room away.
     Viewer-side like FACE_MAINKEYS; explicit sc.crew still wins.  NOTE: faces are now GATED by
      the commission's `useFaces` (a concurrent hand's refinement — wired here into the
       Sounditron toc Opt, the Story-rail commission pass-through, and Sounditron_glass's own).
 · **The PULSE + the trickle** (`Swarm.g` + `Sounditron.g`): ANY inbound frame from a sealed pier
    stamps `pier.c.heard_at` (c-side, Books untouched; strangers stamp nothing — the ive_got
     law), and a new no-payload `pulse` frame kind exists only to generate that traffic
      (`Swarm_pulse_all`).  `Sounditron_trickle` — a detached era-guarded loop (era on the TOP
       House, one per tab; each run re-hands it the new w) — pulses every ~5s and re-reads the
        %Friend rows (grant · records · `here:1` within a 12s window), bumping w ONLY on a real
         delta.  So: reload one client and its dot dims in the other's glass within ~12s, and
          returns when it's back.  This is the first thread of the "model driven at some fps" —
           the full curated model world stays designed-not-built (§3's chooser + a %Buddy shape).
 **GATED:** LocalGen (Swarm/Sounditron/Radio/Ra), bundle-fetch ×7 clean, headless Sounditron
  stands `Door:open,face:Door` in snap 7.  **OWED:** the live-tab gate (the soak tabs dropped off
   the roster mid-verify — re-run + `--svg` when one returns); FINGERS: scan a QR with a fresh
    phone (born-today auto-join end-to-end), watch the address bar become ?I=; a muted Book for
     the pulse/heard_at loop (two-identity, SwarmGot-shaped).

**THE STOKER + CREWS + THE PIRATING FACES (2026-07-18 late — uncommitted; the C-and-D fix).**
 The human: "it's only playing DJ Oscillo's C and D… all the things in the Voro UI need grouping…
  I want to see the provisioning system cranking along… exhausting the set should churn radiostock
   extra fast."  Three organs landed:
 · **The %Stoker** (`Radio.g //#region stoker`, face:'Stoker', crew:'Radio'): provisioning is now
    its OWN visible loop — the radio's dial never digs.  It parks with the radio, resurrects
     standing radiostock once, counts `stock`/`fresh` (unheard-this-sitting vs `radio.c.heard`)
      every 3s, and DIGS when fresh drops under 2 or the dial poked `Stoker_churn` (exhaustion =
       dial found nothing unheard → churn back-to-back to 4 fresh or a dry pass → `spent`).
        Dig order is **music-first** — the old testsounds-first first-base-wins wander IS why only
         DJ Oscillo's C and D ever played.  The dial (`Ra_dial_next` gained `opts.skip_ids`,
          default-off so every sealed Book is untouched) prefers FRESH and replays honestly when
           exhausted (`radio.sc.replays` counts it, stops climbing as fresh stock lands).
 · **CREWS + the %Tuner** (`Cyto.svelte`): every cell-holder tessellates under a CREW (sc.crew ||
    its face kind || stuffed mainkey); cyto_scan writes the census to the %Tuner's `.c.crews`
     and DROPS muted crews at classify — cells vanish, space returns.  TunerFace lists crews with
      ▣/☐ toggles → `Tuner_toggle` → mute flip + the unfold-idiom absolute rescan.  Mute + census
       ride `.c` ONLY (viewer preference — Books stay Voro-blind, snap rows constant).  Minted
        opt-in by the commissioner (Sounditron_glass) so Leaf* fixtures never move.
 · **The Pirating face** (`HeistFace.svelte` + `glass_faces.ts`): `FACE_MAINKEYS` imposes a face
    BY MAINKEY, viewer-side — no %Heist ever wears sc.face, sealed Musu fixtures untouched.
     Renders both shapes: POSED (Sounditron's nugget — sentence + %Need met:1) and SOFT (wish +
      %Lead answers, a `take` button per Lead → `Heist_condense`).  `glass_faces.ts` is the
       component-free half Cyto imports (headless spine has no DOM; glass_kinds.ts keeps the
        component map for Cytui).
 **GATED:** Sounditron 7/7 live on 77d2; `Stoker:idle,face:Stoker,crew:Radio` + `Tuner:glass,
  face:Tuner` + the posed Heist in snap 7 headless AND live; SVG tessellation grew 11→14 paths
   (one cell per new face — a cell only seeds off a successful mount).  **OWED:** fingers on the
    live buttons (churn ⛏ · a crew toggle · a Lead take — remote shots can't click); a live
     soft-Heist wish in a radio world once the remote dial leg lands; the pull driver behind
      `take` (condense stamps at/chose; nothing drives Heist_beat live yet).

**THE RADIO IS BUILT (2026-07-18 — `Ghost/M/Radio.g`, uncommitted, live-gate owed a tab reload).**
 The one wire the pipeline never had: chunk particles decoded and laid on the REAL AudioContext
  timeline, continuously — the human: "continuously playing music, like a radio, starts going from
   the start (via %Stream) after the first track you leave playing."  The shape: `Radio_ensure(w)`
    stands a `%Radio` face particle (mainkey value = state off|digging|playing|paused|starved;
     sc.face:'Radio' mounts RadioFace in the glass — see Sounditron_todo §4e); ▶ = `Radio_go` (the
      click IS the AudioContext gesture) → a detached era-guarded pump (`Radio_pump`, setTimeout
       chain — NOTHING under beliefs, the Sounditron mutex law) feeds ONE persistent AudioDecoder
        per encode run (reset only at a `head` chunk — flush() resets WebCodecs state, so flush only
         at run end), spills harvested PCM onto the timeline at the frontier (`aud.schedule(buf,
          max(end, now))` — the Sound_real_stream idiom; a late landing = a counted gap), and when
           the timeline reaches the end the DIAL turns itself (`Ra_dial_next` → next track chains at
            the frontier, seamless).  %Stream comes into being BEHIND the 32s preview: a supply loop
             runs `Ra_transcode_ensure|advance` while the preview plays (self-served, no Repli);
              source unreadable ⇒ cap at preview and move on.  An empty shelf DIGS: resurrect
               standing radiostock (cheap), then ONE `Crate_nav_meander` wander + `Ra_stock_one`
                (never a scan — the 200k law).  Starve ⇒ 6s grace then SPLICE (honest drop, decoder
                 re-opens dirty).  Pause rewinds to the heard chunk; skip cuts the voice.
 **GATED so far (2026-07-18 late):** `%Radio,face:Radio` stands in snap 7 on BOTH a fresh headless
  spine and the live runner 56fb (Sounditron 7/7), and the face's CELL stands in the live SVG
   tessellation (11 paths — a cell only seeds off a successful component mount).  Two bombs were
    defused en route: cross-ghost calls MUST ride `top_House()` (`this.Radio_ensure` on the run
     House is silently undefined — the M. convention), and a mint must sit ABOVE `Sounditron_glass`'s
      `!this.c.up` bail (headless run Houses have no up).
 **OWED:** EARS — press ▶ on a /BigSoundland tab (the click is the autoplay gesture; only the human
  can) and leave it playing; the remote leg (dial across granted `%MusuThem` mirrors — want-paging
   exists in `Ra_term_stream_beat`, not yet worn by the radio); a muted Radio Book
    (`Radio_go(radio, {mute:1})` is Book-ready); volume/fade on the face.

**DESTINATION MOVED — read `Radio_spec.md` §1-5 first (rebuilt 2026-07-15).** The spec is now the
 destination doc, reshaped into **two planes** (descriptor/culture floods · content/bytes routes),
  **two spines** (culture: identity→magazine→browse→heist→persist→swarm · audio: the nine stages), and
   **two itemised ladders** (spec §5A culture · §5B audio). **The live culture worklist is spec §5A** —
    its rung 0 is the keystone **[P0] per-chunk content-addressing** (a per-chunk sha256 in the
     origin-signed card; `Ra_enid` is whole-file today), which gates BOTH the swarm (rung 7) AND
      demoting the unconditional disk read-back. This todo is now being **drained into the spec**: as a
       section here lands or is superseded by a spec rung, collapse it to a one-line pointer or retire the
        WHOLE file's dead parts to `history/`. The multicast slog moved to its own doc
         `Radio_multicast_todo.md` (= spec §5A rung 7). Map of this file → spec: §9 Pier reality → §2.1
          homing law + §5A r1; §10 klepto/heist → §5A r4; §11.7 Berth → §5A r5; §12 magazine/stimuli →
           §2.3 + §5A r2; §12.4 jobs ladder → §5A r3/r6.

**2026-07-17 — §2 RE-DRAWN with the human: the Musu homes (spec §2.2-§2.4 + rungs 1/3/6 carry it).**
 `%Library` + the `Ray` dissolve into `%MusuSelf|%MusuThem,pub` homes, each with `radiostocking/ | the/ |
  shop/` shelves; `%Original/%Chunk` is the master standing BESIDE (never above) `%Record/%Preview|Stream`
   (a pull lands a Record — derived, never a master); `%Blob,grade:ogg128` export grades (Android plays
    `.ogg` happier than `.opus`); `%Grasp` → `%Heist` = wishlist → its actively-downloading leg (both
     Mag-shaped, Waft-based, `What/` anywhere; a Grasp is also the abuse-report shape — *what of their
      share is naughty*). The shop is FLAT: bytes in ONE place, every meaning a Mag|Grasp referring in by
       id; GC roots = the Mags|Grasps. **Tonight (authorized hours, opus subagents): `[RUNG7-WIRE]` DONE
        (2026-07-17, green ×2 — see below) + the ogg128 export DONE (2026-07-17, green ×2): `Ghost/M/Orig.g`
         (`Orig_ogg_export`/`_mux`/`_parse`) writes a real RFC-7845 Ogg/Opus file + mints `%Blob,grade:ogg128`
          (path, never bytes); Book **MusuOgg** proves it live (stock→transcode-to-end→export→page-CRC +
           OpusHead re-read→real decodeAudioData round-trip). **The r3 CONTAINER DISSOLVE also DONE
            (2026-07-17, green ×2): `%Library,pier:` → `Ra_home_self`/`Ra_home_them` (`Ghost/M/Ra.g`) minting
             `%MusuSelf|%MusuThem,pub` homes + a `stock` shelf that replaces the flat lib node one-for-one;
              ~35 sites converted by side-judgment (origin/own→self, mirror→them) across Ra/Heist(ation)/
               Radiation/Musuation/Swarmation/Repli + the `Swarm_music_census` walk; green ×2 on the core six
                (Vend/Heist/Breach/Ogg/Reap/Buddy) + Reco/Replica, fixture diff = ONLY the re-shelving.** The
                 `%Original` master itself + re-homing the `%Blob` into the shop stay OWED (eyes-on).**

**2026-07-17 — the `shop/` SHELF DONE + the `%Heist` re-homed (green ×2: MusuHeist 22 · MusuBreach 10 ·
 MusuSoft 6): the Heist no longer floats on `w` (spec §2.4 shop block + §2.1/§5A r1).** `Ra_home_shop(w, <me>)`
  (`Ghost/M/Ra.g`, beside `Ra_home_self`/`_them` — `Ra_home_shelf` generalized to a shelf-name param) mints the
   `shop/` shelf under the asker's `%MusuSelf,pub` home; `Heist_job(w, at, filings, {home})` + `Heist_wish(w,
    home, …)` hang the `%Heist` there (soft wish AND hard job alike), `Heist_flatten` removes from `job.c.up`
     not `w`. Call sites converted: MusuHeist_job (asker `b.mine`'s shop), the two Breach job seams + the two
      wire jobs (each own's shop), both MusuSoft wishes (`Ra_home_shop(w, 'Seeker')`); the two `w.o({Heist:1})`
       readers in Heistation resolve against the asker shops. Fixture diff was ONLY `Heist,` moving from the floor
        to `MusuSelf,pub:<asker>` > `shop,pub:<asker>` (records/Leads/filings/took unchanged). **Still owed:** the
         per-Pier `bay,pub:<them>` sub-part + `%Heistlet` (the travelling ask), and the wet `%Original`/`%Record`
          quarantine moving UNDER the `%Heist` in the shop.

**2026-07-17 — the SOFT `%Heist` DONE (green ×2, Book MusuSoft): the search that hardens into a pull (spec
 §2.4 soft block + §5A r4).** `Ghost/M/Heist.g //#region soft` — `Heist_wish` mints `%Heist,wish:<sentence>`
  (soft = a `wish` + NO `at`); `Heist_ask` crosses it as a chunkless husk over the granted wire; `Heist_match`
   walks `Musica_cards` and stamps `%Lead,pier:,id:,tune:` per LITERAL contains-hit (title|artist|genre|album)
    under the soft Heist (no hit → no Lead); `Heist_condense` hardens the chosen wish (stamps `at` + the filing)
     and the EXISTING pull (`Heist_beat`/`Heist_land`/vouch door — untouched) lands the one record. MusuSoft
      loopback: 3 real tracks + a `%Mag` cross → one-word wish finds exactly ONE Lead → a nothing-wish finds
       ZERO → condense pulls that ONE card whole while the two decoys stay UNSPENT husks. **HOMING GAP CLOSED
        (2026-07-17):** the `shop/` shelf now exists (`Ra_home_shop`) — the soft Heist homes under the seeker's
         `%MusuSelf,pub:Seeker > shop/`, not `w` (see the shop-shelf entry above). NEXT: the Stemdex/%Seem
          by-meaning rung (swap `Heist_words` for the stem index) and `%Lead` accumulation across MANY far Mags.

**2026-07-17 — the BAY + `%Heistlet` TRAVELLING ASK DONE (green ×2, Book MusuBay 9/9 ×2 on 49dee91d): the
 per-Pier corner of the shop + the ask that travels (spec §2.4 bay block — [built] stamp carries the detail).**
  `Ra_home_bay(w, me, them)` mints `bay,pub:<them>` under MY shop; `Heist_let_mint/ask/answer/adopt`
   (`Ghost/M/Heist.g //#region soft`) run the round trip: mint `%Heistlet,of:<hid>,pier:` with scalar `ask,id:`
    children → Repli_offer over the granted wire (BOTH directions granted — the return leg needs it) → the far
     side stamps `have:1`|`held:1`|NOTHING in place on its mirror → the annotated copy crosses back → adopt
      copies the marks onto MY bay original (mirror = landing zone, never the home). A `%Heist` gained an
       optional `hid` ident (`opts.hid`, stamped only when supplied) — the Heistlet's `of:` join key. MusuBay
        also proved the **multi-source `%Lead` fan-in** (one wish → two piers → 4 Leads from both under the one
         soft Heist) + negative control (a fabricated ask id stays UNMARKED both sides) + the pull economy
          (only the had card spends). GOTCHA baked into the Book: a frame settles over post_do BETWEEN beats —
           send and answer must be SEPARATE steps or the mirror copy isn't there yet. Pre-existing Books
            byte-stable (MusuSoft 6/6 · MusuHeist 22/22 c20 · MusuBreach 10/10 — no per-step dige drift).
             OWED: Heistlet `cursor · backoff` leg fields; a true two-runner return leg; prod `hid` derivation
              (rides with the prod signer-setter).

**2026-07-17 — the MAG SHELVES DONE (green ×2 on 49dee91d, 12 Books re-recorded): every world-side `%Mag`
 re-homed onto the owner's `radiostocking/` — ALL FOUR §2.2 shelves are now real.** `Ra_home_radiostocking(w,
  pub)` + `Ra_home_the(w, pub)` (`Ghost/M/Ra.g`, via `Ra_home_shelf`). All ~12 mint sites judged SELF (every
   site publishes the owner's OWN draw — no site holds a mag about another pier; the mirror-side `mir.o({Mag})`
    copies are the wire's landing zone, untouched). MusuCursor/MusuHeal needed their Dogear spines re-rooted at
     the shelf (`Cursor_resolve(cursor, w.c.mag_root)` — cursor verdicts byte-preserved). Fixture diff =
      re-shelving ONLY (verified side-by-side on Soft/Vend/Bay/Heist); control MusuReplica stayed green with no
       re-record (mints no world-side Mag). Re-recorded: Soft 6 · Vend 11 · Door 9 · Cursor 6 · Heal 7 · Resume 7
        · Rename 9 · Recast 12 · Standing 12 · Bay 9 · Heist 22 (c20 band) · Buddy 14 (c11 band). `the/` shelf =
         door only; first resident arrives with the written-zine rung.

**2026-07-17 — the GONER-DELETE CONSENT GAP CLOSED (green ×2, Book MusuFreeze 9/9 c0 on 49dee91d): a revoked
 follower's mirror is FROZEN — the wire refused to ADD to a revoked peer but would still DELETE from their
  mirror (found by the 2026-07-14 adversarial review; no Book exercised delete-AFTER-revoke, so the leak sat
   un-asserted).** The surgical guard: `Musica_recast_offer` (Heist.g ~1032) consults `Repli_allowed(w, to,
    from)` and both goner loops skip the send when the gate is closed — receipts still populate (the origin's
     census diff stays honest); `Repli_send_lines` itself untouched. Sabotage-proven: guard neutralised → the
      revoked mirror LOST the track + `leaked` fired + only the revoke-sees went red (real discrimination);
       guard in → `quiet_wire` (zero frames) + `frozen` (the mirror keeps the copy the origin dropped).
        MusuRecast re-verified byte-identical (no-op under a live grant). **EYES-ON: `Repli_retire`
         (Repli.g:292) is the same raw-send pattern with NO gate** — unreached by Musica today but the same
          class of leak; the standing choice (gate it too | move the gate INTO `Repli_send_lines`, the core
           primitive) is the human's. Full caller survey in the [[repli-send-lines-consent-gap]] memory.

**2026-07-17 — the RADIOSTOCK CASCADE GC DONE (green ×2): `Musica_forget` now reaps the derived disk cache.**
 An era forget (`Musica_forget(nav, mag, cutoff, pub)`) drops the old `%Cloud`s AND unlinks every
  `.jamsend_radiostock` file whose track left the magazine — the human's "delete including radiostock". The
   join is `Card.id === stock enid` (both `Ra_enid`), so no map: gather the ids before/after the fold and hand
    the goners to the new **`Ra_stock_cascade(nav, pub, gone, keep)`** (Ghost/M/Ra.g), which is **BIAS-TO-KEEP**
     — an id still referenced by ANY survivor keeps its stock (the cache re-derives; a wrong drop costs one
      re-encode). `pub` (== stocking `lib.sc.pier`) is threaded in by the caller; graceful no-op when there is
       no disk stock (MusuVend still rides `Musica_forget_fold` direct, byte-identical). `Musica_forget` now
        returns `{ dropped, cascaded }`. Book **MusuReap** proves it live (two eras stocked → forget the old →
         the dropped track's stock file GONE while the kept track's STANDS — the bias-to-keep discriminator).
          Still `// <` on forget: the WIRE goner (fold `Musica_recast_offer`'s op:delete into the Berth path so
           a forget also retires over enrolled followers) — M4's remainder.

**2026-07-15 — RUNG 0 (per-chunk content-addressing) BUILT + RE-RECORDED LIVE-GREEN; signing + Ra-path + breach-Book OWED.**
 Every chunk now carries a durable **`cid`** = full sha256 of its bytes — minted at all three chunk-mint
  sites (`Ra_record_from` %Preview, `Ra_chunk_mint` %Stream, `Heist_census` %Body), carried in the `.jam`
   header as a `cids[]` manifest (parallel to `sizes[]`, filled in `Ra_pack`), and **verified per-chunk in
    `Heist_land`** (both the stream and the fallback path) as a localized breach ahead of the whole-file
     `body_hash` gate. Files: `Ghost/M/Ra.g` (+ a `Hashly.ts` IMPORT), `Ghost/M/Heist.g`; gen written via
      LocalGen (`src/lib/gen/M/{Ra,Heist}.go`). **Compiles clean** through the real in-app translator.
 **Live proof (HMR hot-loaded the gen; the editor was down):** `runner_ask run MusuHeist` → the census
  mints a `cid` on every `%Body` (39 in step-2's snap), zero step errors, the phase machine runs to `deny`.
   The run goes RED ONLY because the recorded fixtures lack the new `cid` rows — an additive-snap diff, not a
    logic failure (per-chunk verify is a no-op on honest bytes: same bytes → same hash → pass; it only fires
     on real corruption the wire/body_hash gates already exclude).
 **RE-RECORD — DONE (2026-07-15, night shift).** `run → accept → re-run` on the :9091 runner: MusuHeist is
  **22/22 GREEN** (caveat 20 = the AudibleEntropy fuzz-tolerance, benign ≈). Fixtures `002.snap`–`022.snap` now
   carry the `cid:` rows (39 in step-2), step count stable (no toc collapse), zero encode smells. The FIXTURES
    changed, not the code — HEAD (`4afe3965`) already had the gen; only the wormhole snaps were owed.
  **BOMB the night cost an hour on:** the fleet has FOUR runners advertising and an un-addressed `run`/`steps`/
   `state` round-robins across them, so a `steps` query lands on a runner that never ran the Book (stale
    `done:6`) and reads as a truncated/false result. **Pin the WHOLE sequence to ONE runner** —
     `--runner=<self-id>` on run AND steps AND state (list them with `runner_ask runners`; the `★claude`
      favourite is the safe pick). This is the [[pere-books-total-1]] / "always --runner=" law, re-learned.
 **BREACH BOOK — DONE (2026-07-15, night shift). `MusuBreach` LIVE-GREEN ×2 (7/7, caveat 0) — proves BOTH trust
  gates.** The adversarial twin of MusuHeist proves the gate FIRES: it censuses two artists off testsounds, lands one HONEST record clean
   (the control — proves the gate discriminates not a blanket refusal: `honest,landed,no_breach,on_disk,dropped`),
    then flips ONE byte of a MIDDLE chunk's buf LEAVING its cid and lands again — `poison,seq:2,breached,no_new_land,
     gone,retained,gate_named`. Four `%see` truths latch. Authored in `Ghost/Story/Heistation.g` (a sibling Book,
      dispatched by `w.sc.w`); registered in `wormhole/Credence` (`needsFSA:1,needMusic:1`). **The rigor upgrade:** a
       whole-file `body_hash` would ALSO catch this corruption, so to prove the PER-CHUNK gate's real value —
        *localization* — `Heist_land` now records `job.sc.breach_seq` (the code finally does what its own comment
         claimed: "names the seq"), and the Book asserts the GATE's own report matched the poisoned seq (`gate_named`).
          body_hash can only say "the file is wrong" AFTER assembling it all; the cid says "chunk 2 is wrong" first.
   **Bootstrap gotcha (cost time):** a NEW Book runs 1 step until its `toc.snap` carries `step=2..N,dige:lie*` lines;
    a wedged runner ACCEPTS become_book but never steps (`run:null` forever) — `runners` + run a known Book to find a
     HEALTHY one, ALWAYS pin `--runner=`. (49dee91d + 3c5238c6 wedged this night; 20e3476b stayed clean.)
  **The SECOND gate — ORIGIN-SIGNATURE (rung 7), proven in isolation same night.** MusuBreach step 6 (`vouch`):
   the cid catches corruption but NOT a lying peer who recomputes a cid over bad bytes, so the origin SIGNS the
    cids manifest (ed25519 over `id | cid0.cid1…` via the `Idento` primitive Swarm.g uses — DETERMINISTIC so the
     vouch snaps stable: `vouch,by:434ced…,vouched,forgery_caught,imposter_caught`). Three probes: honest vouch
      verifies; a FORGED manifest (swap one cid) fails; an IMPOSTER (wrong key) is rejected. Helpers live in
       Heistation.g as `MusuBreach_sign/verify/manifest` (GOTCHA: the Idento sign method is `.sig()` NOT
        `.signhex()`; verify is `.ver()`). *The two gates together: cid keeps an honest peer honest; the
         signature keeps a dishonest peer out.*
  **RA-PATH cids — DONE (2026-07-15). `MusuRaStream` (40/40) + `MusuRaChase` (56/56) re-recorded GREEN ×2.** The
   `%Preview`/`%Stream` chunks now carry cids in the fixtures (they ride the snap round-trip — the resurrect
    proof), same additive re-record as MusuHeist. **Rung-0 fixture debt is now 4/4 CLEARED** (every Book with
     chunk particles green with cids: MusuHeist(22) ✓ · MusuRaStream(40) ✓ · MusuRaChase(56) ✓ · MusuBuddy(14) ✓ —
      MusuBuddy re-recorded green ×2 once the fleet stabilized; the earlier stalls were the runner wedging under
       load not the Book, so a two-probe stability gate before the heavy run cleared it). **BIG FINDING for the signing layer:** the Ra-path cids ride the ENTROPY BAND (37-38
     of 40 steps caveated ≈) because the transcode is NOT bit-reproducible — the same source encoded twice gives
      slightly different bytes → different cids.  Heist-path cids (original file bytes) are EXACT; Ra-path cids
       are per-transcode.  CONSEQUENCE: two peers who independently transcode the same track get DIFFERENT cids →
        different manifests → different signatures, so a swarm cannot dedup/verify across independent transcodes.
         The content-address that a signature vouches for must be the ORIGINAL master's cids (deterministic), not
          each grade's — fold this into the rung-7 wiring design (the `%Original` of §2.4 rung 3 is the anchor).
 **2026-07-17 — `[RUNG7-WIRE]` DONE (green ×2).** The origin-signature is now WIRED into the live trust path.
  **The ONE implementation** lives in `Ghost/M/Ra.g //#region trust` — `Ra_manifest`/`Ra_sign`/`Ra_verify`; the
   isolation-proof helpers `MusuBreach_sign/verify/manifest` (Heistation.g) now DELEGATE to them, so the crypto
    test exercises the live-path code (steps 2-6 unchanged, byte-identical diges — the delegation was transparent).
  **Seam A — the `.jam` at rest:** `Ra_vouch_header(info, bufs, signer)` stamps `by`+`sig` over the cids manifest
   onto the header before `Ra_pack`; `Ra_stock_standing` REFUSES a header that claims a `by` but fails verify
    (unsigned headers pass untouched — old jams still load). Signer threads off `lib.c.signer` (absent for every
     current Book → byte-identical old shape; no fixture churn). `Ra.g:544` (pack) + `589–644` (`//#region trust`)
      + `Ra_vouch_header` at `569` + the `Ra_stock_one` vouch call at `801` + the `Ra_stock_standing` gate at `668`.
  **Seam B — the offer door (the keystone):** `Heist_offer_all(w,tx,from,to,lib,signer)` → `Heist_offer_vouch`
   stamps `by`/`vouch_sig`/`vouch_cids` on the Record head (three scalar keys — they ride the chunkless husk; the
    `%Body` cids do NOT, so the manifest rides the head). `Heist_beat` verifies (`Heist_vouch_ok`) BEFORE
     `Ra_pull_beat` — a signed-but-failing offer is REFUSED: zero wants, zero lands, `job.sc.unvouched`+ a legible
      `unvouched,tune:` marker; an unsigned offer passes. Gate ONLY at the Heist call — the generic Repli path is
       untouched (**MusuHeist 22/22 GREEN, caveat 20 benign**). `Heist.g:214` (`Heist_offer_all`) + `229`
        (`Heist_offer_vouch`) + `251` (`Heist_vouch_ok`) + `285` (the door gate inside `Heist_beat`).
  **Proof:** `MusuBreach` grew from 7→10 steps (`Ghost/Story/Heistation.g`) — steps 7-10 wire steps: honest signed
   offer flows through the door and lands (`door_ok,landed,no_refusal,flowed`); a FORGED manifest (origin sig
    replayed over a swapped `vouch_cids`) refused at the door (`real_verified,door_refused,unvouched_bumped,
     no_new_land,no_wants,dropped,gate_named`). Two new `%see` truths. **Green ×2** on runner `49dee91d61a9de64`.
  **Still owed (rung 7, not this wire):** an APP path that actually SETS a signer (`lib.c.signer` / the `signer`
   arg) in production stock/offer — today only a Book would; and the swarm ROUTING (have-bitmap beacon + cheapest-
    source chooser, `Radio_multicast_todo.md`). The whole rung-0 fixture debt is CLEARED. See spec §2.4 + §5A rung 0 + rung 7.

**THE SNAP READS LIKE THE SESSION — N1-N5 + the Jam ledger + the Card rename: LANDED and LIVE-GREEN (2026-07-14).**
 The human read MusuBuddy's snaps and named four smells + one growth; all are coded, adversarially reviewed, and
  RE-RECORDED GREEN on the :9091 runner (all 14 affected Books — see `history/Radio_buildlog.md`). The live runner
   caught TWO bugs the static reviews could not (the jam ran a beat before `expecting()` resolved `w.c.term`; a
    mainkey-less `o({at:1})` in `Jam_ledger` returned nothing) — both fixed and re-verified. What landed:

- **N1 — no maybe-undefined sc mints. DONE.** Guarded the three unconditional `k: rec.sc.k` mints (`Heist.g`
   Musica_fold card + heist-landing, `Heistation.g` reflect card) the way `album` already was. Kills the
    `{"undef":["path"]}` brand. Blast: MusuBuddy fixtures only (the pathless Ra-stocked cards; the seeded
     cursor Books already carried paths). `undef` also appears in Engage/LakeSurfer/Peeringinst from UNRELATED
      mints — out of scope, untouched.
- **N3 — drop the finished awaitbuf. DONE.** `finish()` marks `%finished` but never detaches, so 38
   landed+finished `awaitbuf` rows piled up per pulled track. Fix in `Repli_attach_page`: once bytes land,
    `pier.drop(req)` the holding req (+ `delete pier.c.bufs[id]`) — an UNLANDED awaitbuf still stands (real
     in-flight pull + the warn-if-late reconciler). Safe because the req sweep iterates a fresh `o()` snapshot,
      and MusuReplica's `warns_missing` reads only the unlanded set. Blast: MusuBuddy, MusuHeist, MusuRaStream,
       MusuRaChase, MusuReco, MusuReplica, **VoroTest** (its canned scape carries awaitbuf rows — check how it
        regenerates before re-recording).
- **N2 — the card stops impersonating %Record. DONE (code), UNDER ADVERSARIAL REVIEW, re-record owed.**
   Cards under a `%Cloud` are now `%Card`; holdings under a `%Library` stay `%Record`. **Chosen shape:
    `Card,id:<id>,artist,title[,album,body_hash,path]` (Option B — KEEP the `id` scalar), NOT `Card:<id>`
     (mainkey-value).** Why: `Repli_loc_keys` gives `['Card','id']` (id is id-ish) — byte-identical wire
      behavior to the old `Record,id`, no `repli_loc` hint, and **zero `.sc.id` reader ripple** (the finder
       helpers `Musica_cards`/`Musu*_card` and MusuBuddy's browse read `.sc.id`/`.sc.title` unchanged), so N2
        was a near-pure mainkey-WORD swap on the Cloud-child sites only. **`Card` is NOT a new collision — it
         REUSES MusuBerth's existing `Card` mainkey** (a saved track-reference; the magazine card is a full
          listing, the Berth toy a degenerate `Card,tune,verdict` — same family "a reference to a track", the
           human's own prior coinage). MusuBerth is UNAFFECTED (its cards live in a Berth Waft, never mixed;
            `o()` is direct-children-only). Sites: `Heist.g` fold/cards/recast goner-emit (`{Card:1,id}` loc
             `['Card','id']`); `Heistation.g` every Cloud-child query/mint/rm + cursor leaves (anchored on the
              `}])` array-close so `origin_lib.rm({Record:1,id:'t1'})` holdings stayed put) + the finder
               helpers unchanged; `Radiation.g` the ONE browse cursor leaf. Both files audited (every remaining
                `Record:1` is a holding; every `Card:1` a Cloud child). Blast (fixture ripple, all magazine
                 Books): MusuBuddy, MusuHeist, MusuVend, MusuDoor, MusuReco, MusuCursor, MusuHeal, MusuResume,
                  MusuRename, MusuRecast, **MusuStanding**.
- **N5 — distilled into CLAUDE.md. DONE.** Three rulings in the C-objects section: identity-is-per-shelf +
   referring particles wear their own mainkey (1:1 → mainkey may carry the identity beside the join key; N:1 →
    an `of:` pointer); never stamp a maybe-undefined sc (an `undef` marker = a mint bug); an owner drops its
     finished transient reqs (scaffolding, not snap furniture).
- **N4 — the Jam ledger. GHOST + MusuBuddy WIRING LANDED (compile-clean), sees under adversarial review,
   re-record OWED.** New family ghost `Ghost/M/Jam.g` (enrolled in CREDULER_GHOSTS after Heist.g): under the
    listener's shelf a `Jam,with:<dj>` session of ordered **`Spin,of:<id>,title,at`** / **`Like,of:<id>,at`** /
     **`Grab,of:<id>,at`** facts (`Grab`, NOT `Heist` — that mainkey is the reserved operation `%Heist,at:<pier>`;
      `of:` is the N:1 referring form). Verbs `Jam_home/seq/event/spin/like/grab/ledger/tally`; `Jam_grab` also
       copies the pulled holding — scalars + chunk children (bytes shared) — into a caller-supplied `kept` shelf.
        MusuBuddy wiring: `MusuBuddy_jam(w)` runs at the tail of `MusuBuddy_hear` (beat 10, once, after `w.c.term`)
         — spins/likes/grabs the browsed track into the mirror's `%Jam` session + a keeper copy in a distinct
          `%Kept,pier:<lis>` shelf (grabbing into the mirror would just re-find the husk). TWO new sees at beat 11:
           the ledger reads Spin→Like→Grab in `at` order (reads the real rows, not a flag), and the keeper stands
            WHOLE in `%Kept` while the husk still stands in the mirror (copy-not-move). 13 sees total. **Adversarial
             review (opus): both sees SOUND** (live-data reads, verified one-line breaks, no blocking bug; `vmag`
              is near-vacuous decoration, the load-bearing conjuncts carry it). STILL OWED: the fleet re-record
               includes MusuBuddy for the jam rows (already in the N2 union).

**Graph-density follow-up (low priority, decide on a live look):** `Jam_grab` copies the browsed track's ~38
 chunk particles into `%Kept` (required — the `kept_whole` see reads them), so MusuBuddy's Cyto graph now holds
  the mirror record's chunks AND the keeper's. If that reads cluttered on a live render, stuff-fold them (`%stuff`
   / the `Repli_crush_scan` path → `no_further` suppresses Cyto descent while the particles stay for the see) —
    ideally the mirror record too. Not a correctness issue; the Matstyle swatches already give them semantic color.

**RE-RECORD DONE (2026-07-14).** All 14 affected Books re-recorded GREEN on the live :9091 runner, including
 **MusuStanding** (now `%Card`, superseding any `Record`-card version). The sealed real-audio Books keep their
  benign `AudibleEntropy` ≈ (MusuBuddy caveat:11; the Ra Books caveat:37/53 — all ok_pct:1; caveat:0 is
   unreachable by design, not chased). Working-tree note: running each Book also refreshed its
    `Credulate`/`Credulation` gen-pins to the new gen bundle (now including `Ghost_M_Jam`) and its toc
     timing-stats — benign bookkeeping churn across the run set, expected in the diff. Gen reached the runner
      via `ghost-compile` (intermittently half-open — a retry cleared it each time; LocalGen kept the disk gen
       honest in parallel).

**THE RA PIPELINE RE-DRAW — MusuBuddy consolidates stock|cast|play UNDER the magazine, and the three
 standalone Ra* Books RETIRED: LIVE-GREEN ×2 (2026-07-14; 14/14 green — a sealed real-audio Book, so
  steps 4–14 ride benign `AudibleEntropy` ≈; caveat:0 is unreachable by design, not chased).** The human's
   push (2026-07-14): "do MusuRaStock|Cast|Term really stay relevant once we have the magazine — or is that
    proving the same job twice?" The honest answer split — the magazine is the CATALOG (identity leaves), the
     Ra pipeline is the PAYLOAD (the real PCM), orthogonal axes that MEET — but the three standalone Ra* Books
      proved stock|cast|play in a configuration **the destination never runs**: a stream with no catalog
       naming it. The magazine arriving IS the higher-level re-draw §3.5 always promised. New Book **MusuBuddy**
        (`Ghost/Story/Radiation.g`) runs the pipeline WITH its front door: `Musica_stand` publishes the
         collection as a `%Musica` magazine over the granted wire, a title-pinned `%Dogear` browses the
          follower's MIRROR down to a card, and **the browsed card fetches its OWN audio** — card id = Record
           id (the catalog and the stream identity are ONE), so the pull parks|ignites on demand, the terminal
            decodes THE PULLED bytes (LUFS −14.02 at target, an honest starve, gapless when whole), and a
             revoke leaves the magazine STALE (a fresh origin draw meets the closed gate — zero frames, the
              MusuStanding seq discriminator). It ABSORBS every claim of the three (RaStock: opposite-direction
               gains toward one target + idempotent restock; RaCast: seal + husk promise + park/serve demand +
                byte-faithful whole pull + revoke silence; RaTerm: LUFS survives the opus trip + honest starve
                 + gapless), and adds three the standalone configs could not make: the browse-by-meaning join,
                  the **unbrowsed husk kept unspent** (the economy — pull is per-card, never broadcast), and
                   the stale-magazine-after-revoke. 11 sees; **adversarial review (opus) returned all 11 SOUND**
                    (each with a verified one-line break; the four hunted false-green suspects all defused —
                     origin transcode mints on the origin record so the mirror husk stays empty, a wrong cursor
                      landing fails the title equality, `o()` is direct-children-only so husks and cards never
                       collide, the sorted testsounds give genuinely opposite gains). RETIRED once green ×2:
                        MusuRaStock/RaCast/RaTerm deleted (Book code in `Radiation.g`, fixtures, Credence, Ality)
                         — `Ghost/M/Ra.g`'s spine verbs are UNTOUCHED (MusuBuddy + RaStream + RaChase ride them);
                          RaStream/RaChase (the streaming-race + village-dial residue the magazine can't express)
                           and the real-audio lowlevels + `MusuGenerateTestsMusic` all STAY. (Live note: the gen
                            re-compile after the delete HMR-wedged the sole runner — MusuBuddy's green is banked
                             from BEFORE the delete; its Credulate re-pins to the trimmed gen on the next clean
                              run after a tab reload — benign gen-pin churn, not a re-gate.)

**M4 (second rung) — CENSUS BECOMES THE STANDING PUBLISH (a diff-watcher pass, idempotent on a quiet census):
 LIVE-GREEN ×2 (2026-07-14; 12/12, caveat:0).** New Book **MusuStanding** (`Ghost/Story/Heistation.g`, after
  MusuStanding) makes the census itself the TRIGGER: MusuRecast crossed a diff when `Musica_recast_offer` was
   CALLED; this makes a *change to the collection* drive it. New verb **`Musica_stand(w, tx, from, to, mag, lib,
    randomic, created_at)`** (`Ghost/M/Heist.g`) fingerprints the collection (its sorted id set) and — if UNCHANGED
     since `mag.c.last_census` — does NOTHING (no fold, no offer, no frame); on a change it recast-offers the delta
      and remembers the new fingerprint. **The idempotence is the load-bearing claim** — it makes the pass a real
       diff-watcher, not a blind every-beat re-offer that would spam the wire and defeat the husk economy. The Book
        seeds {t0,t1,t2}, stands (publish), stands again on the unchanged census (QUIET — zero frames), grows (+t3)
         and stands (propagates), shrinks (−t1) and stands (goner crosses), stands again (QUIET). 5 sees. The
          idempotence discriminator reads the **origin Pier frame counter** (`Pier_next_seq` → `tx.c.seq`): a quiet
           stand must send zero frames — remove the fingerprint gate (the one-line regression) and every stand
            re-offers, `sent>0`, red. (The mirror-content sees would MISS that — a redundant husk re-offer upserts
             the same cards and changes nothing visible; only the frame count witnesses a wasted republish.)
              Adversarial review (opus subagent) returned all 5 SOUND, confirming the unconditional `Repli_offer` on
               a granted non-empty mag always burns one seq and nothing else touches `tx.c.seq`. Deterministic +
                in-memory; registered Credence (`brand_new:1`) + Ality. **M4's standing publish is proven; the last
                 M4 piece is the roster FAN-OUT — standing over N enrolled followers (needs per-follower mirror
                  routing; `// <` in `Musica_stand`).**

**M4 (first rung) — THE CENSUS-DIFF RE-PUBLISH (a goner crosses the wire and leaves no orphan): LIVE-GREEN ×2
 (2026-07-14; 12/12, caveat:0).** New Book **MusuRecast** (`Ghost/Story/Heistation.g`, after MusuRecast) wires the
  retire to the fold — the gap MusuVend's forget scene left explicitly open (its forget was a LOCAL GC; "the follower
   keeps the cloud until a Repli_retire propagates"). New verb **`Musica_recast_offer(w, tx, from, to, mag, lib,
    randomic, created_at)`** (`Ghost/M/Heist.g`): re-fold the magazine, re-offer the whole thing (husk — neus + in-place
     updates ride an upsert), then cross an explicit **path-carrying `op:delete`** per goner — because a streamy merge
      never removes what an offer OMITS (by design), so a re-offer alone can never withdraw a lost card. TWO
       granularities, mirroring the fold's own reconcile: a card lost from a SURVIVING cloud (`Mag>Cloud>del Record`)
        and a whole cloud EMPTIED (`Mag>del Cloud` — the whole-era drop in one line). `Repli_retire` stays the FLAT
         depth-0 goner for a record off a mirror lib (MusuReplica); a magazine card is three levels down, so the delete
          carries its Mag/Cloud ancestry as plain upsert lines the merge already walks — **no Repli wire-core change**.
    The Book publishes two clouds, loses one record (t1 — cloud survives) then a whole draw (t3+t4 — cloud empties), and
     proves the follower's mirror drops EXACTLY what the origin lost, no orphan and no empty husk, survivors intact.
      5 sees. **Adversarial review (opus subagent) caught see #5 as a FALSE-GREEN** — its claimed break (broaden the
       record-delete to a `Record:1` wildcard) transiently nukes the survivors but scene 3's re-offer re-adds them
        before the witness samples any settled pass, so it latched green anyway. FIXED by pinning the survivor state in
         a frozen `after_record` note the instant the record goner drains (before scene 3 can heal it), where the
          broadened delete leaves `s0=0 s2=0` and can never un-write — now the break genuinely flips it red. Registered
           Credence (`brand_new:1`) + Ality. (Live note: the first accept caught a `self,round=5` heartbeat wobble →
            caveat:1; a fresh warm re-record settled it to `round=4`/caveat:0 — a benign quiescence margin, not data.)
             **M4's census-diff heart is proven; the remaining M4 is rename-as-standing-Upkeep + revolving service pacing.**

**M3 — THE RENAME MISSION (a `%Renamed` redirect rides the wire and a stale cursor heals through it): LIVE-GREEN ×2
 (2026-07-14; 9/9, caveat:0).** New Book **MusuRename** (`Ghost/Story/Heistation.g`, after MusuResume) closes the
  loop C2 (MusuHeal) proved only in-memory: C2 healed a cursor through HAND-AUTHORED markers; M3 mints the marker
   from a real reorganise gesture and crosses it Pier-to-Pier. New verb **`Musica_rename(mag, id, key, to, at)`**
    (`Ghost/M/Heist.g`) is ONE gesture — it applies the retitle AND mints the `%Renamed` beside the card in the same
     stroke, so the magazine never shows a rename without its redirect. On MusuVend's proven two-Pier loopback the
      origin retitles two cards, re-offers the whole magazine, and the follower's cards update IN PLACE (the card
       locates on the wire by `['Record','id']`; `title` is a merge PROP, so no fork) while the two markers arrive as
        fresh facts. Two title-pinned `%Dogear` cursors that were `fresh` (zero heals) before the mission then HEAL
         through the REPLICATED markers, landing on the retitled records and noting from→to. **`Renamed_mint` gained a
          `repli_loc:['Renamed','key','from']` stamp** so two markers stay DISTINCT on the wire (the default `['Renamed']`
           loc would upsert the second onto the first and blur both redirects into one) — see #5 pins exactly that seam.
            5 sees, each with a named one-line break; adversarial review returned all 5 SOUND (no tautology, no
             false-green path — the `{Renamed:1}` numeric-1 wildcard survives the peel round-trip, verified). Deterministic
              + in-memory (no FSA / audio / Berth / entropy): runs on ANY runner. Registered Credence (`brand_new:1`) +
               Ality. **M3 is done; the M-rung's next natural step is M4** (census-diff re-publish + rename missions as a
                standing Upkeep pass — needs M1 ✓ + M3 ✓); **U** (the magazine reader) is also unblocked.

**C3 — THE RESUME (berthed `%Dogear` survives a reload): LIVE-GREEN ×2 (2026-07-14; 7/7, caveat:0).** New Book
 **MusuResume** (`Ghost/Story/Heistation.g`, after MusuHeal): a `%Dogear` homed inside a magazine survives a full
  `enWaft`→`deWaft` round-trip (the disk-less core of Berth save+open — MusuBerth owns the real disk) and still
   resolves to the record it named — the resumable browse. Needs no FSA, runs on ANY runner, deterministic.
    DISCRIMINATION: a second bookmark is live-only under `%testing`; only the berthed one rides the snap (re-decoded
     magazine carries EXACTLY one Dogear — `dogear_count:1`, `kept_present`, `live_absent`). Adversarial review
      caught the `independent` leg as near-tautological (`deWaft` structurally can't alias, so `!old.ok` was forced
       by our own rename) → re-gated on the re-decoded cloud being a DISTINCT node object, which a hypothetical
        aliasing `deWaft` would actually flip red. En route it corrected **CLAUDE.md**: the enWaft vocabulary gate
         is PARKED (`all_knowing` — any mainkey rides; the old "unknown mainkey = fatal encode skip" was stale — the
          only encode-fatal is an object/function in `.sc`). Credence regrouped (`What:mostly` → pipeline / magazine
           / replication; the cursor trio homed under `magazine → the cursor`). **The cursor arc C1·C2·C3 is complete.**

**C2 — THE HEAL (`%Renamed` redirect): LIVE-GREEN ×2 (2026-07-14; 7/7 steps, caveat:0).** New Book
 **MusuHeal** (`Ghost/Story/Heistation.g`, after MusuCursor) grows C1's clean-fail verdict into a HEAL:
  when a cursor's named level is gone, `Cursor_resolve` consults recent `%Renamed,key,from,to` markers beside
   the last node reached and retries with the redirect (`Cursor_heal` in `Ghost/M/Heist.g`), landing on the
    moved node and NOTING what it healed (`heals:[{key,from,to}]`). The marker rides IN the magazine beside the
     renamed node (a positive, window-able cousin of `%Tombstone`/`%UnGrant`), so a follower heals through the
      same pipe the content came down. `Renamed_mint(parent,key,from,to,at)` mints one. THE DISCRIMINATION
       (non-vacuity baked in): the Book renames two records identically, ONE with a marker and ONE without — the
        marked cursor heals to `t1b` noting `from:t1→to:t1b`, the unmarked one fails cleanly (`missing t2`). So
         the heal is provably the marker's doing — the one-line regression (drop the `Renamed_mint`) flips the
          heal sees red while the control stays green. Adversarial review confirmed SOUND + falsifiable; it flagged
           steps 3/5 lacked `reached:` markers (silent-un-latch risk) → both added. The heal is TRANSPARENT to an
            un-renamed cursor (MusuCursor re-ran green, caveat:0, after the `Cursor_resolve` change). Registered
             Credence + Ality. `Credulate` pins the fresh gen (`Heist~g1 @f52331c1`, `Heistation~g1 @b80b9c7a`).

**C1 — CURSORS (`%Dogear`): LIVE-GREEN ×2 (2026-07-13; 6/6 steps, caveat:0).** New Book **MusuCursor**
  (`Ghost/Story/Heistation.g`, after MusuDoor) + the cursor primitive (`Cursor_*` in `Ghost/M/Heist.g`).
   The human's steer was to **model the cursor on `%lematch`**: a `%Dogear` is a linear spine of `%curs`
    match-segments, each storing ONE `o()`-query; `Cursor_resolve(dog, root)` re-finds each level from a
     root down, LANDING on the leaf or returning a CLEAN fail verdict `{ok:false, depth, missing, at}` —
      no throw (the seam C2 heals through: consult recent `%Renamed` for `missing`, retry with the
       redirect). **KEY-AGNOSTIC** by design — a level pins by whatever keys its node wears
        (`id`/`randomic`/`shuffle`), so the Cloud-model redirect below slides under it untouched. Snap-safe:
         the wildcard TYPE rides as a `wild:<Type>` VALUE (re-inflated to `{Type:1}` at resolve) so it dodges
          the `Cloud:"1"` exactly() footgun; literal pins ride flat. Three sees: RESOLVE (lands on the exact
           record, depth 3), PARTIAL (names a level not a leaf — lands on the cloud, depth 2), CLEAN FAIL
            (knock the record out → fails at that level, reports the missing query). Adversarial review found +
             fixed a real soft spot — see #3's "no crash" degraded to a SILENT un-latch on an upstream throw,
              so a `reached:step_4` marker now gives the recorded snap-diff teeth (RED, not silent); see #2 also
               tightened to assert the landed node is a `%Cloud`. Compiles byte-clean (LocalGen 88271c +
                ghost-compile `@bbc3c8cc` accepted). Registered Credence + Ality. **LIVE-GREEN ×2 on the
                 reloaded 49de runner** (6/6, `caveat:0`) — the snap shows both `%Dogear` spines
                  (`Dogear,of:record-t1 → curs,Mag:Musica → curs,wild:Cloud,randomic:draw_one → curs,wild:Record,id:t1`),
                   the knockout genuinely removed t1 from its cloud, and all three sees + `reached:step_2`/`step_4`
                    latched. `Credulate` pins the fresh gen (`Heistation~g1 @bbc3c8cc`, `Heist~g1`). (The runners had
                     wedged mid-session — 49de post-HMR think-stall, 3c52 begun-wedge — until a tab reload; lesson: an
                      in-session `ghost-compile` HMR of a big ghost can stall a live runner's think loop.)

**D1, re-posed (the human asked "what's it all for?" — and yes, it IS Invites & Grants).** "The door" is
 the SERVING side of a follow: your machine hands a follower content over Repli; the door is the per-pull
  consent check. Part b (MusuDoor, done) proved the door only lets DATA through, never live machinery.
   Part a (owed) is the WHO-check: swap the demo's Book-owned `w.c.grants` boolean for the REAL verdict
    `Swarm_pier_live(pier, 'Music')` — does this Pier hold a live, signed, un-revoked grant (minted by an
     invite, redeemable, revocable by a `%NotGrant`)? **MusuHeist ALREADY runs that exact verdict live**
      (`Heistation.g:258`); the ONLY unproven composition is revoke-mid-relationship → next-draw-refused
       OVER the magazine pipe. So part a is one small SCENE (best folded into MusuHeist), not a fresh Book —
        it just needs the `AudibleEntropy` profile (real grants carry a wall-clock `time:`/`sign:` that must
         be fuzzed) + a warming re-accept, hence attended.

**CLOUD MODEL redirect (the human, 2026-07-13):** drop `randomic`; have the REAL rastock lay Records
 ordered by an axis — `shuffle | ctime | mtime` — PARTITIONED every ~20, so a 400-track collection becomes
  ~20 Clouds of 20 (`Cloud,shuffle:0 … 19`). The Cloud key becomes its partition position along that
   ordering, not a random draw-id. An M-family data-model change (touches `Musica_fold`'s batching, the
    `repli_loc` → `['Cloud','shuffle']`, and the real `Ra_stock` generator that today stocks a `%Library`
     but publishes no magazine) — folds in at the M3/M4 real-rastock→magazine seam. Does NOT block C1 (the
      cursor is key-agnostic). (Read "20 magazines = 400 Records" as 20 Clouds/partitions × 20; confirm if
       something else was meant.)

**M2 — MAGAZINE REPLICATION: LIVE-GREEN ×2 (2026-07-13 pm; 11/11 steps, caveat:0).** New Book
 **MusuVend** (`Ghost/Story/Heistation.g`, appended after MusuHeist) proves the magazine TRAVELS: two
  Piers over a Lake_link loopback, an in-memory magazine folded at the origin and `Repli_offer`ed whole
   (husk — a magazine card is a payload-less leaf, so no wants: the tree crosses in ONE frame), the
    follower mirrors it. The GATE is the point — draw A crosses (granted) → draw B REFUSED + noted
     (revoked) → draw B catches up (re-granted); the gate is consulted live, cached nowhere. Then a FORGET
      scene GCs the older cloud (the `%Cloud` layer's raison d'être — an era dropped at once). 6 `%see`.
       Deterministic + in-memory (no FSA / no audio / no Berth / no AudibleEntropy) so it runs on ANY
        runner and its fixture is jitter-free. Both `.g` LocalGen-green; toc seeded (11 lie steps);
         registered in Credence (`brand_new:1`) + Ality.
 - **The MusuRa question, answered honestly (the human asked "do MusuRa* use the magazine?").** NO —
    the MusuRaStock/Cast/Term/Stream/Chase family stocks a real `%Library` but never publishes a
     magazine from it (zero `Musica`/`%Cloud` refs). They ARE otherwise fully current-era (no tombstone,
      no `%Tune`, no genre tag-tree). The shapes already FIT — `Musica_fold` consumes exactly what
       `Ra_library` builds (`%Library,pier > %Record`) — nobody had wired them. MusuVend is the first
        wiring (folds a magazine from a `%Library`); wiring the REAL Ra stock → magazine into the MusuRa
         Books is a follow-up (needs an FSA runner; owed).
 - **`Musica_publish` split into the "one brain" (§12.1):** the pure reconcile-then-add is now
    `Musica_fold(mag, lib, randomic, created_at)` (in-memory, no disk); `Musica_publish` is the Berth
     wrap (open → fold → save). So ONE magazine-building brain serves the disk publish AND the wire — no
      duplicated reconcile. The fold stamps `cloud.c.repli_loc = ['Cloud','randomic']` so a Cloud
       reconciles by its draw-fingerprint on the wire (without it the default `['Cloud']` loc collapses
        every batch to one blur at the follower).
 - **`randomic` = a RANDOM DRAW (the human's clarification):** a `%Cloud` is a handful MEANDERED out of a
    collection NEVER fully enumerated (`Crate_meander` random-walks the crate — Crate.g); the magazine is
     random samples accreting over time, not a full census. `randomic` is the draw's fingerprint. Folded
      into the fold's doc + MusuVend's framing.
 - **ADVERSARIAL review PASSED (in-session code review, not a live run):** no RED-causing bug; all 5 sees
    fire; 4 of 5 are breakable by a named one-line change (#1 corrupt a fold scalar, #3 allow-all, #4 cache
     the revoke, #5 drop `repli_loc` → `{Cloud:1}` numeric-wildcard collapses both clouds). #2 (catalog-not-
      payload) is honest but semi-tautological ON THE WIRE — its leaf property is the FOLD's sublimation, not
       the husk (husk is a no-op for a payload-less magazine; the husk path is proven on MusuReplica/Reco/
        Heist). Commented at the site. Value/string wire round-trip type-stable; all 6 mainkeys snap
         (vs MusuHeist/022.snap); the `reliable:true` mock drains inline in post_do (the rx.do() pumps are
          belt-and-braces).
 - **LIVE-GREEN ×2 (2026-07-13, runner 49de):** recorded 11/11 steps, `caveat:0` (deterministic — no
    entropy jitter), all 6 sees latched, both clouds distinct at the follower, forget dropped the older
     cloud. The runner was FROZEN on first dispatch (total:1 Prep bubble — the freeze problem) and SELF-
      HEALED on the second run (frozen-boot: the first run is a sacrificial thaw), then accept → green ×2.
       Fixtures committed. `Credulate/toc.snap` confirms the fresh gen (`Heistation~g1`, `Heist~g1`).

**NIGHTSHIFT 2026-07-13 — DONE (all four jobs cleared; committed as the human by licence).** The
 blow-by-blow is in `history/Radio_buildlog.md` (2026-07-13 nightshift entry). In brief, on the
  recovered `49de` runner: **Job 1** MusuHeist re-recorded 15/15 over the franken-fixtures, green ×2
   (`caveat:28` benign), committed `1c2e7e12`. **Job 2** MusuBerth's first live record + reset-with-Story,
    green ×2 (`caveat:0`), committed `03c2e1cd`. **Job 3 (M1)** `Musica_publish` verb + the new
     **MusuMagazine** Book authored/registered/LocalGen-green (`683d00a6`), then live-recorded +
      accepted, green ×2, all four `%seen` + four markers present, Credence dropped `brand_new`,
       fixtures committed `c05e66d8`. **Job 4** both MusuHeist sabotage-proofs demonstrated the sees
        are load-bearing — (a) `Heist_tombstoned→false` dropped see #11 (retomb read `holds=8,fresh`);
         (b) a corrupt census `body_hash` stamped `breached,landed=2` and dropped see #4 — both
          CHECK-only, reverted, runner left green on pristine gen `39558c`.

**NEXT (2026-07-13 night): the whole heist+magazine wave is BUILT — M2 leads next.** DONE today
 (all committed, live green ×2): the tombstone RIP; test music TAGGED-BY-DEFAULT; the magazine as
  `%Cloud/%Record` on the observable plane; the Ra family re-record over the tagged bytes; then the
   blessed wave — **cp-LANDING** (a heist is a cp: `<dest-root>/<source-path>`, whole-dir pickup, no
    rename, `Heist_cp_path` sanitizes `..`, kid-safe non-audio-siblings + dedup bias-to-keep captured
     as `// <`) and **the FOLD** (MusuHeist publishes Uno's REAL collection via `Musica_publish` and
      reflects it into w/%Mag — real ids/hashes/cp-paths on the snap; the existing deny gives a RECAST
       on real data; 14→16 sees, 19→22 steps). The magazine is now proven on the real machinery, the
        data as data.
 - **MusuMagazine DELETED (2026-07-13):** the fold made MusuHeist the real-data magazine proof, so the
    `%Cloud` toy was retired (Berthation.g flow + Credence/Ality registration + fixtures all gone; the
     `Musica_*` verbs stay in Heist.g). Its two OWED-coverage items are now BOTH ABSORBED BY MusuVend
      (M2): **multi-cloud grow** — draw A + draw B form two distinct `%Cloud`s (see #5); and
       **`Musica_forget`** — `Musica_forget_fold` extracted (the pure GC twin of `Musica_fold`) and
        exercised by MusuVend's forget scene (see #6: origin drops the older cloud by its stamp, keeps
         the fresher). The radiostock cascade is now BUILT (2026-07-17, MusuReap green ×2 — `Musica_forget`
          reaps the derived `.jamsend_radiostock` off disk via `Ra_stock_cascade`, bias-to-keep). The only
           remaining `// <` on forget: the WIRE goner. (The follower-propagation via Repli_retire is BUILT —
            M4/MusuRecast crosses the goner at record + cloud level; folding it into Musica_forget's Berth path
             so a forget ALSO retires over enrolled followers is the standing-loop remainder.)
 - **M2 LIVE-GREEN; D1 part b LIVE-GREEN (MusuDoor, 2026-07-13) — NEXT build is D1 part a.**
    D1 was split: **part b (the SABOTAGE wall) LANDED** as the `MusuDoor` Book (fork of MusuVend,
     9/9 caveat:0 ×2 on runner 49de, commit `f76b3d7e`). A malicious origin grafts a `%req:sabotage,eternal`
      under a magazine card; it merges deep in the follower mirror as DATA and lands **INERT** — `reqdo_sweep`
       pumps only w's IMMEDIATE reqs, so a req buried below the mirror is never enumerated. The canary is
        DYNAMIC (a `req_sabotage` handler flips `w.c.pwned` IF ever pumped; an adversarial review killed the
         first immediate-child draft as a false-green) so BOTH a promoting merge AND a deep-walking sweep go
          red. 3 sees: wall + gate (revoked peer refused) + containment. Deterministic (no crypto/entropy).
    **D1 part a (OWED, the crypto door):** swap MusuDoor's Book-owned grant toggle for the live
     `Swarm_pier_live` verdict (the MusuHeist `repli_allow` shape) — reintroduces seal wall-clock →
      an EntropyProfile + a warming re-accept, so best done ATTENDED (§12.4 D1 recipe (a)). The sabotage
       wall does not depend on WHO the peer is, so it landed cleanly without the crypto.
    Then C1 cursors. Corner-cases for when cp-landing meets real disk (all `// <`): audio-probe the bytes,
     the album-art/kid-safe oracle, dedup album+disc+track-else-path, landing-path clash.

**NOW (2026-07-13, post-push): three §10.2 gears LANDED compile-clean (live-gate owed on all);
 the Booth/Ban thread is VETOED-and-parked; persistence is ruled — §11.7 (the Berth).**
 - **Landed in the working tree** (opus-agent waves; every .g LocalGen-green): **#1
    stream-to-disk** — `Heist_land` streams each %Body via a new `nav.bin_append`
     (Housing.svelte.ts:2260) behind a capability probe (FSA streams; OPFS/remote/node fall back
      whole-buffer, `<`), verify-after-write vs body_hash, breach → delete + tally. **#2
       metadata + the real tree** — the census feeds its body_hash bytes to
        `Crate_meta_from_tags` (WAV INFO + ID3v2.3/2.4) and lands at
         `<genre>/<Artist>/<Album>/<Title>.<ext>` (album-less drops the level; genre stays the
          top folder — that fork is still the human's). **#3 partial** — `held,tune:` surfacing
           on the job per already-held skip + `Heist_manifest(job, mir, lib)` → [{path, verdict}]
            (the look-before-you-commit; resume side `<`).
 - **VETOED**: the %Tombstone→%Ban rename (host checkout reverted Heist.g/Heistation.g/LiesLies
    to the tombstone baseline — LEAVE IT). `Booth.g` exists unwired/unenrolled — read §11's
     STATUS block before touching anything taste-shaped.
 - **FRANKEN-FIXTURES (urgent, 2026-07-13 late)**: the accepted MusuHeist fixtures record a
    CROSS-WIRED HUNG run — the tab ran the stale `encore` Book gen (HMR'd in before the host's
     checkout) against the `tombstone` engine gen: the flow's completion read `banned` (never
      written) while the engine tallied `tombstoned` → the retomb job hung at skipped=7 from step
       ~19 to 42. Proof in the fixtures: `offered:encore` + `reached:job_encore` present;
        `heisted:retomb`/`flattened` ABSENT — see #11 silently vanished from the roster. Recipe:
         RELOAD the tab (kills stale gen) → clean run → TRIM the toc to last-edge + ~3 headroom
          (the 42-seed leaves ~18 dead steps — the human: "just sitting there from step 20") →
           re-record + accept + confirm the see roster. Also landed meanwhile: `bin_append` is a
            FULL 4-backend contract (the host built OPFS/node/remote + the serve op; agent-audited
             correct, old-editor degrade honest) and @noble/hashes rides `Heist_land` as an early
              wire-hash tripwire (`Hashly.ts`; the read-back stays the unconditional
               bytes-on-disk gate).
 - **THE LIBRARY CATCH** (the human: "didn't we have a library for that?"): package.json ships
    **music-metadata@11** — the hand-rolled tag parser in Crate.g duplicates it. Swap
     `Crate_meta_from_tags`' internals to an IMPORT() of music-metadata (parseBuffer; the
      .g-imports-ts pattern exists for exactly this). KEEP `Crate_wav_with_tags` — the WRITER —
       music-metadata cannot write tags and tests must synthesize tagged files.
 - **OWED, in order (the next fork's fleet)**: (1) **Book scenes** for the landed gears —
    manifest-counts scene, held_named on the reuno row, the tagged-WAV tags-beat-filenames scene
     (synthesize via Crate_wav_with_tags into the share at census + delete at flat; count cascade
      uno 2→3 / reuno+retomb 8→9 / skipped 7→8 / no_reland 7→8 / newlyadded uno 2→3 — TRACE ALL),
       a `streamed:1` telemetry marker on the uno row iff nav.bin_append existed; a first attempt
        died at the session limit mid-edit and was REVERTED — re-run clean. Steps grow ~42→~52:
         re-seed the toc THEN reload the runner (total:1 bomb). (2) the music-metadata swap.
          (3) **the Berth** (§11.7) — build + a Book scene proving reset-with-Story. (4) **the
           live gate**: LocalGen sweep → CHECK on 49de → accept (pre-pin the 11 sees; expect big
            path churn — every landing deepens by Artist[/Album]) → sabotage-proofs (tombstone
             door → false must drop see #11; a wrong body_hash must breach not land). (5) then
              §10.2 #4 the single-track/want-driven session (the anti-klepto front door +
               Waft:Map advice, §11.7), #5 repointable, similarity-upgrade.

 **Bombs a fresh fork must hold** (durable homes: §2 wiring bombs, §1.5 Book discipline):
  LocalGen for spine `.g` edits, never ghost-compile Ra.g against a live editor (§2);
   new Book = seed the toc THEN reload the runner + register in Credence (§2);
    always `--runner=<prefix>`; pre-pin the `%see` set before any accept and confirm after (§1.5);
     sealing Books show PERMANENT benign ≈ on grafted seal fields — do not chase caveat:0 (§1.5);
      the host commits mid-session — re-check the tree after HEAD moves.

**Captured idea (the human, 2026-07-14) — the CUE as the DJ metaphor for an invite.** The `Idzeug`/`Invite`
 tokens "can be got from a place in the DJ equipment to plug in the monitor for headphone-ing to the next
  track." So the invite/grant isn't only a door — it's the DJ's CUE: an Idzeug redeemed at the deck lets you
   MONITOR (headphone-preview) the next track before it plays out loud, the way a real DJ cues the incoming
    record in their cans. Ties the Swarm invite (SwarmDoor / §1.0 Invite) to the deck's cue channel (MusuCue,
     §1.0 `multi-stream: decks, cue, crossfade`). Design seam for when the deck UI + invite meet — a redeemed
      grant surfaces a "cue the next track" affordance, distinct from the out-loud play.
