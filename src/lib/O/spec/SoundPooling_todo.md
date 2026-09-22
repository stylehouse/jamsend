# SoundPooling_todo.md — the pool: press + reach into it, pool-first radio out, cells over it

## 0. WHAT TO GET ON WITH NEXT (rewritten 2026-09-11 night; the older §0s are §0.6–§0.8 below, intact)

### 0.0 2026-09-21 — THE PLAN (ruled with the owner 09-20/21; the slog starts here)

**Rulings taken:** the heard Mag MAY cross the relay, crew-only (*"that I say is okay"*). A Nay removes the
 track from "whimsical locations" (the pool) but NEVER a file already heisted — already the law; artist-level
  Nay is new and later. "You liked this but hated that" is a tender case for a later listening-consciousness UX,
   a query over the stamps, not a mechanism now. We are after general patterns: (1) **stamps that only go
    forward, state derived** — a ledger that replicates with no delete; (2) **one serializer, three homes** —
     `Swarm_protocol('heard')` text is the stash, the folder mirror, and now the crew wire; (3) **the machine's
      acts are Cards too**.

**RUNGS, in order (each compiles + gates before the next; LocalGen ladder if the editor is down):**

1. **Close the lane's two silent holes** (Heard.g; gate MusuHandoff, add beats; owed re-swear 4–6 anyway).
   - `Heard_hand_beat`: `if (!targets.length) return 0` says nothing. Stamp a word on each un-handed take
     (`waiting_for:a device with a folder`) so the Haul row can say it; log once per session.
   - `Heard_haul_beat` on the trove body: a take whose holder has no `%Theirs` mirror standing is LEFT STANDING
     silently — stamp `waiting_for:<holder> to come online` on that Card; it mirrors back (rung 3) and the phone
      finally has a word between *handed* and *landed*.
   - `take_got` again on land and on gave-up (§9.7): until rung 3 makes the mirror the ack, send the frame twice
     more with `state:landed|gave_up`; `Heard_hand_got` writes `landed_at` / the verdict stamp.

   **RUNG 1 — LANDED 2026-09-21.** All three holes closed in Heard.g: `Heard_hand_beat`'s no-target branch
    now stamps `card.sc.waiting_for = 'a device with a folder'` (cleared the moment a target exists), logging
     once per session (`rw.c.hand_no_target_told`); `Heard_haul_beat`'s no-mirror branch stamps
      `waiting_for:'<name> to come online'` (cleared once the mirror stands); `Heard_word` composes
       `'waiting for ' + waiting_for` when set. The echo is a new function, `Heard_hand_ack_beat(w, rw, me,
        ident, shop)`, called from the top of `Heard_haul_beat` (now takes an optional trailing `ident` —
         every existing 5-arg Book caller is unaffected): it watches the trove body's OWN `via`/`via_addr`
          Cards for a landing (`Heard_landed`) or a verdict (`Heard_verdict`) and sends ONE more `take_got`
           frame back (`state:'landed'` or `state:'gave_up'` + the verdict key), `card.c.hand_acked` guarding
            against a resend. `Heard_hand_land` now also stashes `card.sc.via_addr` (the return address —
             it only ever had the display name before, so there was no way back). `Heard_hand_got` copies a
              `gave_up` verdict straight onto the presser's OWN card under the SAME key
               (`held`/`unvouched`/`landfail`), so `Heard_word` renders it identically to a direct ask.
    MusuHandoff grew two beats (7 WAITING, 8 ECHO; `run.sc.total` 6→8) exercising all of this, including a
     brand-new solo identity (no sibling at all) and a second DJ nobody has mirrored — both witnessed. Heist.g's
      one production call site now threads `ident` through. Verified LIVE (LocalGen ladder, editor was down;
       esbuild-ts-parse-gated; then a real headless-chromium runner tab over the actual `/relay`, since no tab
        was already up) — MusuHandoff all 8 rows green including both new ones, MusuHeard/MusuHeist/MusuPool-
         Policy/Fill/Random/Bytes unaffected. **Owed:** the MusuHandoff fixture (steps 7–8, and the toc's
          `step,dige` index) was never re-recorded — `runner_ask`/`story_accept.mjs` could not address my
           headless tab (census classified it `role UNKNOWN`; the page itself confirmed `control:role
            role=runner` in its own console, so this looks like the `supervisor`/humdinger probe getting no
             answer from a Book-only boot, not a real role problem — a plumbing question for whoever next
              needs headless-chromium Books addressable, not a rung-1 blocker). Run
               `node scripts/story_accept.mjs MusuHandoff` from a real runner tab (chrome.sh) to record it.
2. **Stamps, not flags** (Heard.g, every writer + reader; one fixture re-record across the Musu*/Swarm* Books
   that snap a Card — do the RENAMES in the same pass, one re-record). Forced by Repli's law: a key cannot be
    UN-set over the wire, and every `Heard_strip`/`Heard_seen` is a delete pretending to be a change.
   - `take:1,at` → `hearted_at` · `nay` → `nayed_at` · `meh` → `mehed_at` (newest of the three wins, derived
     `Heard_reaction(card)`) · `mire` → `played_through` (max-merges) · `via` → `pressed_on` · `handed` →
      `carried_by` + `carried_at` · NEW `landed_at` · `held`/`landfail`/`unvouched` → `already_had_at` /
       `landing_failed_at` / `offer_unsigned_at` (a later `hearted_at` outdates a verdict = "asking again") ·
        `unseen` → gone; `looked_at` stamp; news = newest event stamp > `looked_at` (`Heard_news(card)`).
   - `Heard_strip` and `Heard_seen` are deleted; `Heard_gc` unchanged (drops UNREACTED hearings by heard_ttl).
   - Readers: `Heard_tally` (hearted 3 · kept 2 · played_through), `Heard_takes` (hearted_at newer than any
     nayed_at/verdict), `Heard_barred_ids` (nayed_at newest), `Heard_word` (the §C words off the stamps),
      RadioFace/HaulFace/PoolFace read through the two derivers, never the keys.

   **RUNG 2 — LANDED 2026-09-21.** Every rename above shipped exactly as planned, plus two new derivers
    the plan implied but didn't name: `Heard_reaction(card)` (which of hearted_at/nayed_at/mehed_at is
     NEWEST — "a nay ends a yay" is a comparison now, never a delete) and `Heard_news(card)`/`Heard_news_at`
      (the `unseen` replacement — newest of carried_at/landed_at/the-three-verdicts, EXCLUDING the verdicts
       on a `pressed_on` card, since that body did the work and isn't the one waiting; `Heard_notice` the
        WRITER is gone entirely — every event already stamps its own `_at`, so news needs no separate mark).
    `Heard_verdict(card)` now returns a verdict only if its stamp is `>= hearted_at` (a fresh press outdates
     a stale verdict by comparison, per the plan). `Heard_strip` survives as `Heard_forget`, called ONLY by
      `Heard_untake` (the human's explicit ✕) — every auto writer (take/nay/meh/hand_land) stopped stripping.
    **A bug the plan didn't anticipate, found by live-running MusuHeard, not by the OK/fail status (which
     never checked the row flags — see the memory pointer):** two DIFFERENT reactions landing in the SAME
      pinned second (a Book fixture doing press→nay→press across one `w.sc.now`) tied on `Heard_reaction`'s
       comparison, and a verdict landing the same second as the press that answers it tied on `Heard_verdict`
        too — both silently kept the WRONG/stale one.  Fixed with `Heard_react_at(w, card, others)`: every
         writer floors its new stamp past every OTHER stamp already on the card (nay/meh/the-three-verdicts),
          so a genuinely later call always reads later regardless of clock resolution — "asking again" always
           wins now, exactly as intended, instead of winning only when the clock happened to tick.
    Also fixed the ACTUAL forcing mechanism the plan's opening paragraph promised but didn't name a line
     for: `Swarm_protocol('heard')`'s hardcoded `sc_has:{take:1}/{nay:1}/{meh:1}` skip-rule (Swarm.g ~5874)
      — the ONE place that decides which Cards survive the stash — renamed to the new fields.  Missing this
       would have been the worst possible silent regression (every reaction vanishing on reload) and it is
        NOT obviously reachable from Heard.g itself, so it's flagged here for whoever reads this rung later.
    `Swarm_heard_rehydrate`'s `mire = max` merge renamed too; the LEGACY row-format rehydrate (pre-dates the
     protocol-snap pillar, 2026-09-17) gets a best-effort translation — `mire`/`take`+`at`/`nay`+`at`/`handed`
      carry over, `meh`/`via`/the verdicts/`unseen` do not (no timestamp to recover in that shape; safe —
       a stale verdict just re-asks once).  External callers (HaulFace/RadioFace/Pool.g/Radio.g) all go
        through function calls, not raw fields, so NONE needed touching — confirmed by a full-codebase grep
         before editing, which is also what caught the Swarm.g protocol rule and two genuine (non-Heard.g)
          Card pokes in Sounditron.g/RaTesting.g's MusuBuddy.
    Verified LIVE the same way as rung 1 (headless-chromium runner over the real `/relay`), but this time
     with a temporary `console.log` in each Book's `_note` helper (since these Books use `story_swear`,
      not sworn+declared `Assertion:` lines, so `Cred spool: OK` alone proves nothing about the row flags —
       `req.sc.ok = 1` is unconditional).  Every row of MusuHeard (9 steps), MusuHandoff (8, rung 1's new
        beats included), and SwarmReboot (5, including the encode→decode→graft→encode byte-identical gate
         AND the full stash→wipe→rehydrate round trip of both a heart and a nay) showed every expected flag
          true — the debug lines were removed before the final compile.  Regression swept across
           Sounditron/MusuBuddy/MusuHeist/SwarmHelm/MusuPoolPolicy/Fill/Random/Bytes: all green.
    See [[heard-mag-stamps-and-crew-mirror]] for the pointer memory.
3. **The Mag mirrors over the crew — via the pillar-8 text, NOT the Repli identity table** (Swarm.g + Heard.g;
   gate: MusuHandoff loses its `take`/`take_got` frames and keeps its beats; SwarmReboot untouched).
   - On `Heard_settle` (every reaction, every landing) the body sends `kind:'heard'` with the
     `Swarm_protocol('heard')` snap of ITS OWN Mag to every crew sibling (`Swarm_sibling_reach`, store-and-
      forward like the roster: re-sent on `Swarm_roster_heard` wake). The protocol already skips every Card
       unless reacted, so bare hearings and GC'd rows never cross.
   - Receive: `Swarm_heard_mirror(w, ident, frame)` = decode + graft into `%Theirs`-shaped home
     `Mag:heard,pub:<sibling>` beside my own (NOT into my Mag — pages are sittings and don't line up),
      with `played_through = max`, every `_at` = max. `Heard_mags(w, me)` returns [mine, ...siblings'] and the
       ~8 `Heard_mag_find(w, me)` readers iterate it (Heard_takes, Heard_tally, Heard_landed_ids, Heard_latest,
        Heard_barred_ids, Heard_haul_piers, Heard_set, Radio's skip-heard).
   - The handoff lane RETIRES: a trove body hauls any hearted Card in the union it doesn't hold (own-track rule
     = "on THIS shelf", `Heard_landed`); the phone's word derives from the laptop's mirrored stamps
      (`carried_by` = which body's Card has a keep; `landed_at` mirrors back; the listing rides the Card).
       `a_folder_hands_nothing` stays true — nobody hands. MusuHandoff re-sworn to the new sentences.

   **RUNG 3 — LANDED 2026-09-21.** Shipped closer to the plan's own words than either prior rung — but the
    "own-track rule = Heard_landed" line hid a real design gap the plan didn't name: writing a verdict/keep
     onto a MIRROR home (a sibling's cached copy of someone ELSE's Mag) would never re-gossip, since only
      `Heard_mag_find(w,me)` — MY OWN Mag — ever gets sent.  So hauling a union wish now ADOPTS it first
       (`Heard_adopt`) — re-stamps the SAME (id,pub) onto my own Mag, `pressed_on` (I didn't press it,
        `Heard_news` excludes it from MY OWN nag) — and only THEN keeps it; the ordinary gossip mile,
         already firing off every `Heard_settle`, carries the outcome back with no separate ack frame at
          all.  `Heard_cards_union(w,me)` is the shared core the ~8 readers all switched to: one entry per
           (id,pub) across `Heard_mags` (mine ∪ every `%TheirHeard,pub:<sibling>` mirror), picking whichever
            copy carries the MOST outcome (landed > verdict > carried_by > bare take) — THIS is what makes
             "the phone's word derives from the laptop's mirrored stamps" literally true: the phone's own
              bare copy loses the rank contest to the laptop's richer one.
   A NEW mainkey, `TheirHeard` — NOT `Theirs` as first drafted.  `o({Theirs:1})` is a presence WILDCARD
    (matches ANY stored value), and six other ghosts (Ra/Radio/Pool/Heist/Swarm/Repli) walk it broadly for
     the MUSIC mirror; reusing it for the heard-mag mirror would have swept every one of those walks into a
      bogus shelf with no `stock` — CLAUDE.md's own "two different shapes under one mainkey" tell, caught
       by inventory before writing the mint, not by a crash after.  `TheirHeard` also joined the account/
        stash/page/crew protocols' blanket skip list — a mirror is a pure runtime cache the gossip mile
         rebuilds every session, never durable matter of its own (an owed gap: a STALE mirror entry a
          sibling has since GC'd on its own side is never purged from mine — additive-only merge has no
           delete; low-stakes, thirty-day-bounded, not solved here).
   TWO REAL BUGS the plan's prose did not anticipate, both found live (not by design review):
    (1) `landed_at`/`carried_by` had NOTHING left writing them — both were rung-1 fields fed exclusively by
     the ack frames rung 3 just retired.  Fixed with `Heard_land_beat` (stamps `landed_at` the instant
      `Heard_landed(shelf,card)` turns true — this body's own live check, for every OTHER body's benefit)
       and a `carried_by`/`carried_at` stamp at the exact `Heard_keep` mint site, using `ident.sc.friendly`
        (§9.7's "which body's Card has a keep", literally).  (2) Adoption lived AFTER the per-holder `busy`
         gate in `Heard_haul_beat`, so a SECOND wish from a holder already busy with one download (the
          Book's own t2-while-t1-still-primed) never got claimed at all — `MusuHandoff_verdict` threw
           reading `.sc` off null.  Moved the adopt line before the gate: the CLAIM is unconditional, only
            the keep-mint waits its turn.  `Heard_news_at` also needed the SAME pressed_on guard extended
             to `carried_at`/`landed_at` (they used to be presser-only fields, incapable of ever appearing
              on a `pressed_on` card at all — now they can, so the exclusion must say so or the adopting
               body nags itself about its own work).
   MusuHandoff REWRITTEN top to bottom — 9 beats now (STAND/HEART/MIRROR/CARRY/EFFECT/VERDICT/WAITING/
    RESILIENCE), the `take`/`take_got` frame assertions replaced by mirror-home reads
     (`MusuHandoff_mirror_card`) and union reads; `Heard_hand_targets` retired from the ENGINE but kept
      alive as `Heard_trove_siblings` for RadioFace's heart-settings sheet (still names who might carry a
       wish — purely informational now, nothing routes off it).  A THIRD production call site turned up
        only by grepping for the retired functions post-hoc: `Heist_keep_beat`'s per-tick pump (`!nav &&
         Heard_hand_beat`) — deliberately left UNREPLACED rather than wired to gossip every tick (the old
          per-card dedup made a retry-every-beat cheap; a whole-Mag re-encode is not) — `Heard_settle` +
           the roster-wake re-send cover the case a per-tick poll existed for.
   Verified LIVE the same way — temporary `console.log` in each Book's `_note`, every row of MusuHandoff
    (9 beats), MusuHeard (9), SwarmReboot (5) true, debug lines removed before the final compile.  Full
     regression: Sounditron/MusuBuddy/MusuHeist/SwarmHelm/MusuPoolPolicy/Fill/Random/Bytes green.
4. **The machine's acts are Cards** (Heard.g + Pool.g/Heist.g; gate MusuPoolFill + a MusuPoolPolicy scene).
   A pool press lands `Card,id:X,pub:H,for:pool` on a MACHINE page (`Cloud,page:machine` — never a sitting),
    and `Heard_clone_beat` copies a pool keep's verdict up as a stamp exactly as for a human keep (`Heist_is_pool`
     no longer skips the clone). ⚠ AUDIT FIRST: `Heard_set` (the radio's "already heard" skip) and `Heard_latest`
      must exclude `for:pool` / the machine page, or a fetch-failure becomes "you heard this". `Ra_pool_fill_wants`
       reads `landing_failed_at` newer than heard_ttl as "don't re-want" — the failure memory with its horizon.

   **RUNG 4 — LANDED 2026-09-22.** `Heard_pool_take(w, me, seed, dj, title, artist)` is the mint (Heard.g):
    find-or-create on `Heard_machine_page` (`Cloud,page:'machine'` — a non-numeric id, so `Heard_page`'s own
     next-sitting scan silently skips it and `Heard_gc`'s age-by-`created_at` never touches it, having none
      by design), stamped `for:'pool'`, `hearted_at` via `Heard_react_at` exactly like a human press.  Wired
       at BOTH mint sites — `Ra_pool_fill_land`'s live keep-mint loop (Pool.g) and `Radio_pool_catch`
        (Radio.g) — alongside their `%Heist,into:'pool'` keep, same seed/pub.  `Heard_clone_beat`'s old
         `if (!keep.sc.take) continue` widened to `if (!keep.sc.take && !this.Pool_is_machinery(keep))`, so
          a pool keep's verdict/listing rides the exact same clone a human keep does.
   The audit turned into SEVEN exclusion points, not two — `Heard_is_machine(card)` (`for:'pool'`) is the
    one predicate every one of them shares: `Heard_set` (dial dedup), `Heard_tally`/`Heard_landed_ids`
     (taste/the pool's OWN 'recent' compartment — without this a pool feeds its own sediment back into
      itself), `Heard_taken` (the ♥ glyph — nobody pressed it), `Heard_unseen` (no attention ping for a
       machine's own failed fetch), and `Heard_takes` (a machine wish must never re-mint a SECOND keep from
        the Card — its real one already exists, minted straight from the press site).  `Heard_latest`
         needed a DIFFERENT fix — not exclusion but page SELECTION: `page:'machine'` is a later CHILD than
          the currently-open sitting the instant it mints, so a naive "last page" read would show a pool
           press as "the last thing this body heard"; filtered to numeric pages before taking the last one.
   `Swarm_protocol('heard')` gained an unconditional `for:'pool'` skip — machine bookkeeping is local only,
    never gossiped (the SAME reasoning as rung 3's own `TheirHeard` skip).  `Ra_pool_fill_wants` gained the
     planned `landing_failed_at`-newer-than-`heard_ttl` throttle, resolving the Mag once outside its loop.
   Gated with a NEW beat 7 on `MusuPoolRadio`, not `MusuPoolFill` — `Ra_pool_fill_land`'s keep-mint loop
    (where `Heard_pool_take` actually lives) is gated behind `!(ident.c.fill_mw)`, and MusuPoolFill's WHOLE
     premise is standing that override (its own comment: "Siphon_pull stays as the BOOK's stand-in only …
      a live tab never takes that road again") — the Book PROVABLY never reaches the code this rung touched.
       `Radio_pool_catch` has no such branch and MusuPoolRadio already exercises it in beat 2, so the new
        beat asserts directly off that: the Card exists on the machine page, all seven readers correctly
         exclude it, and a simulated wire refusal still rides `Heard_clone_beat` to a real verdict stamp.
   **A pre-existing gap found while attributing, not introduced by this rung:** `MusuPoolRadio`'s
    `friends_crew_or_both` assertion (beat 5, `Ra_pool_sources`/`Ra_quarter_goal_pools` — code this rung
     never touches) already fails on the committed HEAD baseline, confirmed by swapping HEAD's `.go` files
      in and re-running before touching anything else — not a regression, just never noticed before because
       this Book had never been run in THIS session's regression sweeps until now.  Left alone; flagged here.
   Verified LIVE the same way (temporary `console.log`, removed before final compile): all 8 new beat-7
    flags true, all of MusuPoolRadio's 7 beats green.  Regression: MusuPoolFill/Policy/Random/Bytes,
     MusuHeard, MusuHandoff, SwarmReboot, Sounditron, MusuBuddy, MusuHeist, SwarmHelm — all green.
5. **One resolver for "who has it now"** (Pool.g): `Pool_goal` sets `from` for every draw off `f.sources_raw`
   (crew first, as `Heard_holder_of` does) — the latent gap where non-random pulls were never booked. Existing
    MusuPoolPolicy scenes give non-random draws no sources (no fixture moves); add a scene that gates it.
    Then the phone's own ♥ can be `for:pool` now + the original later: one Card, two roads (budget ruling
     still owed for a body that said no — the tiny-serving-stash shape).

   **RUNG 5 — LANDED 2026-09-22.** Shipped the resolver as planned, plus a hazard the plan's last line
    ("one Card, two roads") named but didn't yet mean literally — it turned out to be load-bearing the
     moment the resolver actually worked.
   - **`Pool_holders(sources)`** (Pool.g) is the one fold: every `{id, from, crew}` row reduced to
     `{id → holder}`, crew beating friend, then lowest name winning ties — deterministic on every sit-down.
      `Pool_goal` calls it once per pass and stamps `g.from` on ANY draw kind that resolves, not only
       `random`; `Ra_pool_sources` split into a census (`Pool_shared_rows` — every stocked, non-husk
        record on every mirror) and the pool-specific filter (`Ra_pool_nohead`) over it, so the fold has
         one walk to read, not two divergent ones.
   - **`Heard_holders(w, me)`** (Heard.g) is the SAME fold read the other way: `Heard_takes`'s no-holder
     branch and the heist's `Heard_holder_of` both call it now, replacing the old first-mirror-seen,
      non-crew-preferring walk `Heard_holder_of` used to do alone. One fold, two doors — the resolver a
       pool pull books toward and the resolver a heist reads a held take's holder from finally agree.
   - **THE HAZARD: a resolved holder let the liked/recent compartments draw a track someone had already
     ♥'d — and `Heard_pool_take` had no way to know that.** It found the (id, pub) Card by identity, saw
      an existing human Card, and would have stamped `for:'pool'` onto — and re-purposed the reaction
       clock of — somebody's own heart.  A person's ♥ would have silently become "the machine tried this",
        the glyph would go dark, and Heard_takes would stop treating it as owed.  Caught by design review,
         before any Book exercised it (rung 4's own liked/recent draws never resolved a `from` — this
          rung's resolver is what first makes a pool pull actually reach a ♥'d id).
   - **THE FIX — one Card, two roads, literally.** `Heard_road(card, via)` names where a road's stamps
     live: for a MACHINE Card (`for:'pool'`) the Card IS its own pool road, unchanged from rung 4; for a
      HUMAN Card the pool press grows a `%Road,via:'pool'` CHILD (`Heard_road_mint`) that is stamp-shaped
       exactly like a Card (`hearted_at`, `nayed_at`, `landing_failed_at`, …), so every existing reader
        (`Heard_reaction`, `Heard_verdict`, `Heard_react_at`, `Heard_word`) reads a road exactly as it
         reads a Card, no new branches. `Heard_pool_take` now mints/finds the Card by identity as before,
          then presses onto `Heard_road_mint(card, 'pool')` — the Card's OWN sitting, reaction and page
           never move. `Heard_clone_beat` mints the road for a `Pool_is_machinery` keep and writes the
            listing onto the Card (it describes the track) but the VERDICT onto the road (it describes the
             trip) — so a pool-copy refusal never overwrites, outdates, or even touches a person's own
              verdict, and `Ra_pool_fill_wants`' failure-memory throttle now reads `Heard_road(hcard,
               'pool').sc.landing_failed_at`, never the Card's.
   - **Swarm_protocol('heard')** got one more skip rule alongside rung 4's `for:'pool'` one: `sc_has:
     {Road:1}` — a Road is this body's own pool bookkeeping under someone's heart, never a taste fact a
      sibling has a use for, exactly the same reasoning as the machine page.
   - Two new fixture-recorded beats: **MusuPoolPolicy beat 6** (pure over hand-built facts — a `liked`
     draw held by both a friend and a crew body resolves crew; a `random` draw held by two friends
      resolves by name; a loved id nobody holds keeps its pull with `from` absent, a standing wish, not a
       dropped one) and **MusuPoolRadio beat 8** (live, through `Heard_take` + `Heard_pool_take` +
        `Heard_clone_beat` in sequence — ♥ r4 from friendo, pool-press the same id, refuse the pool's own
         keep: the Card stays a take on its sitting with the glyph lit, the verdict lands on the road, and
          `Heard_takes` still lists r4 as owed while the pool keep still reaches `done`).
   - **Recording note, worth keeping:** the temporary headless-chromium harness used for rungs 3–4's live
     verification takes the FSA-less "listen without a folder" boot door, which has no repo wormhole — its
      runs land in the browser's own ephemeral OPFS and never touch disk. Every "live-verified" claim in
       rungs 3 and 4 was real (the Books' own `story_swear` rows were read straight off that boot), but
        **none of it was ever diffed against the recorded fixtures or declared into the tocs** — by rung 5,
         MusuHandoff had 9 beats coded against 6 recorded, MusuPoolRadio 8 against 6, MusuPoolPolicy 6
          against 5, and every sworn sentence across all three sat undeclared. Fixed this rung by recording
           all three fresh against the owner's own runner tab (`node scripts/runner_ask.mjs run <Book>
            --watch --runner=<id>`, then `declare` each undeclared sentence) — they now gate for real, not
             just narrate true. Along the way, `MusuHandoff_witness` was still using the retired `%see`
              idiom (see-to-sworn migration, `spec/history` note) rather than `story_swear` — converted (7
               sentences, commas swapped for em-dashes per the parser's rule) so its assertions actually
                declare instead of silently asserting `gaps 0` on a Book with 0 sworn.
   - Regression, on the owner's live runner, full fixture diff (not narration): MusuPoolFill, MusuPoolRandom,
     MusuPoolBytes, MusuHeard, MusuHeist, SwarmReboot, SwarmHelm — all green, `caveat:0`, zero assertion
      gaps. Two residuals found and accepted as pre-existing (both predate this rung, confirmed by reading
       the diff content, not assumed): MusuHeard's and SwarmReboot's fixtures still carried rung-2's
        pre-rename stamps (`mire`/`take:1,at:` → `played_through`/`hearted_at`, and old row-flag names) —
         `story_accept.mjs --force`'d both onto the current shape. MusuBuddy (RaTesting.g, a streaming/
          backpressure Book that touches none of Heard/Pool/Swarm's heard machinery) sits at `ok_pct:0.86`
           with a `self,round` counter and in-flight `parked_want` indices that differ run to run — its own
            code comment says to read `ok`/`ok_pct`, never the caveat count, because it is timing-shaped by
             design; left alone, unrelated to this rung. Sounditron's tab wedged mid-sweep (role stopped
              answering after an unrelated timeout) — re-run on a second live tab, not chased further; no
               ghost this rung touched is in its path.

   **RUNG 5 FOLLOW-UP — LANDED 2026-09-22, same day.** A design review after the rung closed asked "what
    could still be wrong with this" and found the MIRROR IMAGE of the hazard rung 5 already fixed. The
     fix protected a human-first Card from a LATER pool press (one Card, two roads). It did nothing for
      the opposite order — and the `random` compartment's entire purpose is circulating tracks NOBODY has
       heard yet, so the pool routinely gets to an (id, pub) FIRST. A person later playing that exact
        track straight off the same holder (not the pool copy) and pressing ♥ would land their own
         `hearted_at` directly onto the still-`for:'pool'` Card via the ordinary `Heard_take` path — and
          since no stamp is ever cleared, `Heard_is_machine` would call it a machine act forever, silently
           hiding the person's own heart from every taste/attention reader (`Heard_set`/`tally`/`taken`/
            `unseen`/`takes`/`landed_ids`).
   - **`Heard_road_promote(w, mag, card)`** (Heard.g) closes it: the instant a human path reaches a
     machine-tagged Card, it migrates every stamp the machine already wrote onto a fresh
      `%Road,via:'pool'` (so a real fetch failure or already-had verdict is relocated, never lost), then
       RELOCATES the Card itself off the machine page onto today's open numbered sitting — a mint-and-drop
        (`dest.i(sc)` + `old_page.drop(card)`), not a `.c.up` repoint, since that is the only way this
         C-tree actually moves a child between containers — so `Heard_latest` (which reads one numbered
          page's own children, never the machine page) sees it too.
   - **Wired at the one gate every human path already shares**: `Heard_card` (`Heard_mark`/`_through`,
     `Heard_take`, `Heard_nay`, `Heard_meh` all reach a Card through it) now calls the promoter whenever
      the found Card is `Heard_is_machine`. One insertion point, no new branches at any call site.
   - **New Book coverage**: MusuPoolRadio grew a beat 9 (`MusuPoolRadio_reverse`, `run.sc.total` 8→9) —
     presses r5/friendo as a bare machine act first, confirms it sits on the machine page, then a genuine
      `Heard_take` on the identical (id, pub); asserts the promotion (off the machine page, the machine's
       own `hearted_at` riding the new road, the person's own `hearted_at` the Card's own, the heart glyph
        lit, `Heard_latest` now including it), then presses the pool a THIRD time and asserts it lands on
         the SAME road and never re-corrupts the Card. Two new `story_swear` sentences.
   - **One real iteration, not in `Heard_road_promote` itself**: the first recording came back with
     `it_counts_as_the_latest_sitting_too` false. Traced (not assumed) to the TEST: this fixture's library
      setup never mints a `stock,pub:'me'` shelf (its `_stand` beat plants a bare `%Record` straight on
       `w`), so `Heard_shelf(w, me)` — a find-ONLY door — always returned null, and `Heard_latest(null)`
        always returns `[]` regardless of where the promoted Card actually landed. Confirmed the promotion
         logic was already correct (`it_moves_off_the_machine_page` fired on the first attempt) before
          touching anything; fixed the TEST by minting the real shelf (`this.Ra_home_self(w, me)`, one
           line, additive — it links to the exact `Mine,pub:'me'` home the Heard Mag already stands on, so
            it changes nothing any earlier step reads or recorded). Second recording: all 8 flags true.
   - **Regression widened accordingly** (`Heard_card` now gates five call sites, not one): re-ran
     MusuHeard, MusuHandoff, MusuPoolPolicy, MusuPoolFill, MusuPoolRandom, MusuPoolBytes, MusuHeist,
      SwarmReboot, SwarmHelm plus MusuPoolRadio itself — all green, `ok_pct:1`, zero assertion gaps
       (MusuHeist carries its usual small caveat count, `ok_pct` still 1 — pre-existing timing noise, not
        this fix).

**Not in this plan (owed rulings, later):** artist-level Nay; the liked-vs-hated query; the album/hierarchy
 chooser in HeistSetup; the `Ra_`→`Pool_` flip.

### 0.0 2026-09-20 — ♥ ACROSS BODIES: what stands, what the LinkDevice walk tests, what needs a ruling

**The owner:** *"a LinkDevice test to check the Cave gets Heisting things based on the Captain Yaying tracks"*;
 *"I DO of course want Captain Yays → Repli or something keeps that exact data on the Cave, which there will
  react into doing the heist the Yay implies"*; on a first-♥ popup: *"only if noFSA... or when they LinkDevice?
   ... maybe it's a single track or the album with directory hierarchy chooser as well"*.

**VOCABULARY FIRST — a slip this section made twice before a doc-research pass caught it.** Captain/Cave are
 /Crew ROLES (the wielder vs a holder of the soul key — Crew_todo.md), NOT folder-vs-no-folder. *"A phone
  with no folder is the usual Captain"* (Love_todo.md). MusuHandoff's phone IS the Captain. Say "trove body" /
   "folderless body" for the folder fact (`Swarm_organ_of(b,'trove')` on a roster row, `Crate_nav()` for self).

**WHAT STANDS (verified 2026-09-20 against the code AND the rulings):**
- A ♥ is `Heard_take` → `%Card,id,pub,take,at` on MY heard Mag (durable, pillar 8; `Heard_settle` at the press).
   Taste is `Heard_tally`: take 3 · keep 2 · mire 1 · bare hearing 0. No unlove (09-15). Un-taking never travels (§C).
- **THE HANDOFF LANE IS THE OWNER'S CASE, AND IT EXISTS** (Heard.g `//#region THE HANDOFF`, ruled 2026-09-05,
   Book `MusuHandoff` HeistTesting.g:6383): a body with NO folder cannot haul, so `Heard_hand_beat` sends each take
    as `kind:'take'` over `Swarm_sibling_reach` to the first trove sibling; `Heard_hand_land` puts THE SAME CARD, taken,
     `via:<sender>`, on that body's Mag; its ordinary `Heard_haul_beat` keeps it (`Heard_keep` — the heart road,
      pulled straight, lofi if the heist defaults say so); `take_got` comes back and the presser's Card wears
       `handed:<name>`. Store-and-forward (the Card is the queue), re-offered on the sibling's roster wake.
        Phone-Captain presses ♥ → laptop-Cave heists it: **the LinkDevice walk exercises THIS. Nothing to build.**
         Never yet walked live on a real crew pair (the 09-06 measurement was eed→daemon).
- **Durability gap, FIXED 2026-09-20:** `Heard_hand_land`/`Heard_hand_got` bumped the Card but never `Heard_settle`d —
   `via`/`handed` reached the stash only when some unrelated frame settled later; a reload in that window forgot
    the handoff. Both now settle through the one seam, exactly as ♥/👎 do since 09-17. Compiled (LocalGen ladder,
     editor was down), parse-gated, MusuHandoff re-run: same 3/6 as HEAD's own .go (baseline taken by restoring
      HEAD's Heard.go and re-running) — the residual is a pre-existing `unseen:1` on the handed Card (the 09-10
       ambient-attention mark, recorded after the fixture was cut) → **owed re-swear, steps 4–6**, not this change.
- **The first-♥ sheet the owner asked about was RULED OUT by the owner on 09-15** (RadioFace: *"no unlove, no
   long-press, no sheet — the Pooling cell appears after the first ♥"*). `Heard_tip`/`Heard_hand_set` have no UI
    caller; only `Heard_hand_on` is read. And Onboarding_todo §6 rules setup questions OUT of the Link cell (the
     Door owns account setup) — a budget ask in the ceremony is the shape that ruling removed.

**WHAT IS NOT BUILT — the OTHER direction, and it needs rulings before code:** a trove body's ♥ reaching a
 folderless sibling so the PHONE ends up with a lofi copy (the pool road). Four sworn things stand in the way:
 (1) `a_folder_hands_nothing` / `laptop_hands_nothing_back` are sworn sentences in MusuHandoff — a trove body handing
  is a rule change, not a gate widening; (2) `Heard_takes` (what the hand beat iterates) drops `pub === me` (own-track
   ♥ is a taste fact — sworn in MusuHeard) and anything already on my shelf — a trove body's ♥ on ITS OWN track,
    the main case, is excluded twice, so the informational direction needs its own walk over `Heard_cards`;
     (3) the pool's `taste` draw would carry the handed take (took×3), BUT *"the yes declares exactly one
      compartment"* is sworn (MusuHeard, MusuPoolRandom: `falls_back_to_anonymous`) and PoolFace owns the default
       (*"THE DEFAULT LIVES HERE… only defaulted at a FIRST yes"*) — a folder-conditional default in `Ra_pool_defs`
        moves both; `who:` is ignored on non-random draws; (4) a non-random pull has no `from` today — only `random`
         sets `g.from`, and `Ra_pool_fill_wants` skips a pull without a holder — so `taste` pulls have never been booked
          (a latent gap regardless of this wave; `Heard_holder_of` is the existing crew-first resolver to reuse, and
           the existing MusuPoolPolicy scenarios give non-random draws no sources, so adding `from` there moves no
            fixture — a new scenario would gate it).
 Love_todo §3 already claims the answer for this direction — *"the crew's libraries merge into one Mine, so the
  phone's Heard_landed sees the Cave's holding… the fill pulls a lofi copy FROM THE CREW MIRROR"* — but no code
   merges crew Mines (`Heard_landed` reads my own `Mine,pub:me`). That claim vs the four rulings above is the
    ruling to make. Also owed here: "love is per Pier" vs the two-axis ledger (a reaction attributed to the
     track's HOST vs MY portable taste — `Heard_tally` keys by id only); the per-(track, holder) failure memory.

**WHAT COULD BE, positioned as the owner said:** *"if there's a Cave… a much more serious user… we can throw up
 more forms then."* HeistSetup today is per-track ticks off ONE rummaged folder — not yet the single-track-vs-album
  + directory-hierarchy chooser; that chooser is where a trove Cave's handed hearts could stop being auto-pulled
   singles and become a choosing moment. A later wave, UI-shaped.

### 0.0 2026-09-17 evening — THE ROLL'S ONE LAW: nothing is evicted unless the pool holds more than its cap

The owner found SP at **0 again** and named it: *"`roll` shouldn't delete if nothing can replace."* The morning's
 `Pool_roll` paired a displacement's EVICT with its PULL and let both go when the window was due — so every
  pull that never came (a friend gone offline, a want that never landed; `sources: crew 0 friend 0` on eed all
   evening) had already cost a card. One per ten minutes, all evening, to zero.

**Now (`Pool_roll(diff, barred, due, pooled_n, cap_n)`):** `over = pooled − Σcap` is the ONLY thing that
 evicts, at once (trim); a pull that fits under the cap goes at once; a pull past the cap goes ONE per window
  and its evict waits until it has landed — the next pass sees `over = 1` and trims. A Nay/Meh evict is a
   reaction, not the roll, and still always goes. The pool can never drop below its cap for a wish.
 `MusuPoolPolicy` step 5 now models the three beats (`held_back` → `pull_goes_alone` → `evict_after_it_landed`,
  plus `trim_now`); the sworn sentence changed with the law (`a displacement pulls first and evicts only once
   the replacement has landed — the pool never drops below its cap for a wish`), toc declaration updated —
    **still yours to re-swear** (4/5, the same step as before). Radio 6/6 · Fill 6/6 · Random 5/5 · Quarter 1/1.
 eed picks it up on its next reload; the disk still has the files (`recovered N pooled track(s) from disk`),
  so the pool refills from OPFS without a single pull.

**Second casualty of e42be0a0, found the same evening via MusuHeard's residual:** `Heard_keeps_cap` was
 deleted with `Heard_landed_cap` (and `Heard_thumb`, which was deliberate). Its caller in `Heard_haul_beat`
  stayed, so **every haul beat threw and no heart hauled** — MusuHeard step 7 carried
   `Err … this.Heard_keeps_cap is not a function`. Restored (3). eed's hearts haul again on its next reload.

### 0.0 2026-09-17 — HOW THE NIGHT WENT (the one to read with coffee)

**Short version: the split landed clean, three things were broken and are now fixed, and the one
 measurement I promised you turned out to be a crash wearing silence — so step 3 still has no evidence.**

1. **`Pool.g` exists and is real.** SoundPooling's policy, steward and fill machinery all live in one
    file now, moved verbatim. Every SP Book is green: `MusuPoolPolicy` 5/5 · `MusuQuarter` · `MusuSmuggle`
     · `MusuPoolRadio` 6/6 · `MusuPoolFill` 6/6 · `MusuPoolRandom` 5/5 · `MusuHeist` 22/22 caveat 0.
      eed booted through it at 01:53 (`🏊 pools rehydrated` came from `Pool.go`).
2. **Three casualties of the last two days' commits, found and fixed** (none were the split's):
    - `Common.ts` carried two `$state()` fields out of `Y.svelte.ts` in the cull → `rune_outside_svelte`
       on every `new Idento()` → every Book's identity mint red. Plain fields now. This was the whole
        `MusuHeist`/`MusuPool*` red family.
    - `e42be0a0` ("stuttering soundcard") deleted `Heard_landed_cap()` and kept its caller → **every
       steward press round on eed threw, all night, from 01:56**. Restored (returns 60). ⚠ **eed is still
        running the broken build — it needs a reload from you** to get the steward back.
    - `wafts_everything.mjs` had 5 Points naming the deleted `Heist_wish` family → validator red. Swept.
3. **The overnight "quiet agreement" read is void.** My collector only grepped for `policy differs`,
    so 2,400 `press round failed` lines went past it unseen and I reported "quiet" for nine hours.
     The lesson is already in memory (silence ≠ success; match the failure signatures too). Once eed
      is reloaded the clock starts for real — and it only runs while someone listens.
3b. **Midday: a Nay did not survive a reload.** `Swarm_restash_heard` stashed only cards with `take`
    (it predates the 09-15 reactions); a Nay strips `take`, so both of your morning Nays evaporated
     at the 12:43 reload and the pool could draw them again. Now any card carrying take|nay|meh rides
      the stash. `SwarmReboot` 5/5 · `MusuPoolRadio` 6/6. The two you pressed are gone — press again.
     Also midday: `Pool.g` was missing Ra.g's `sha256_hex` import (mine, from the split) so
      `Ra_pool_resurrect` threw every pass and eed showed 3 records for 37 files; fixed, and after your
       reload the pool recovered to 69 cards / 41 playable against a cap of 26 — the roll will trim
        it one displacement per 10 min, by design.
4. **`MusuHeard` 3/9 is the known one** — the fixture swears the old toggle law, the live run swears
    your no-unlove ruling. Yours to re-swear; nothing broken.
5. **Also gone:** the soft-Caper arc (`Heist_wish`…, %Lead, %Need, %Caperlet, CaperFace, MusuSoft/MusuBay).
    Shuffle and Tree turned out to be deliberately gated, not dead — left alone.

**Your call this morning:** (a) reload eed; (b) commit point — this is a big coherent diff;
 (c) whether the tiny-serving-stash shape is ready to rule. Step 3 waits on (a) + listening hours.

### 0.0 2026-09-17 night — MORNING BRIEF (read this one; the dated sections below it are the trail)

**Destination, unchanged:** the dial chooses, the pool KEEPS what played, ♥ is the one control, and the
 policy that decides the stash lives in ONE legible place a person can read and a Book can drive.

**Where it stands tonight:**
- **`Ghost/M/Pool.g` is that place now** (§0.2a "THE HOME EXISTS"): the pure island + the Quartermaster +
   the pool-fill reach, moved verbatim out of Ra.g (5845→4240). Gated `MusuPoolPolicy` 5/5, `MusuQuarter`,
    `MusuSmuggle`; **live-proven on eed's 01:53 reboot** (`🏊 pools rehydrated — 1 compartment survives`
     came through Pool.go). You committed the first pass mid-stream ("slowas"); the machinery move is
      in the working tree. The `Ra_` prefix on the moved verbs is history, renamed in one sweep at step 3.
- **Step 2's "quiet agreement" clock restarted at 01:53** when eed reloaded (the console ring is 41
   lines and resets on boot — every earlier differs record is gone). An overnight collector is keeping
    `🏊` lines from eed to `scratchpad/eed_pool_overnight.log` (read-only console pulls, 10-min cadence,
     hourly heartbeat). **Morning read: `grep -c 'policy differs' <that log>`** — 0 across a night of
      real listening is the evidence step 3 wants; any hit is a shape to read before flipping anything.
       ⚠ Overnight it sat at 2 facts / 0 differs from 02:00 on — `🏊 facts` only logs on a fingerprint
        change, so with nobody listening the pool never moved: that is IDLE-quiet, not evidence. The
         clock only runs while eed plays; count listening hours, not wall hours.
- **The serving-without-consent finding is RULED, not a bug** (§0.2a FOUND): an un-asked body may hold
   a tiny, eagerly-evicted serving stash; the shape (own compartment? size? eviction) is yours to
    re-think now that Pool.g exists. Nothing built.
- **The SP live Books are GREEN again** — `MusuPoolRadio` 6/6 · `MusuPoolFill` 6/6 · `MusuPoolRandom` 5/5
   (were red at the crew/identity step for a day). One line: the cull moved `IdentoCrypto` from
    `Y.svelte.ts` into `Common.ts` carrying two `$state()` class fields — legal there, a runtime
     `rune_outside_svelte` throw in a plain `.ts`, so every `new Idento()` (`Clustation_mint`) died.
      Plain fields now; nothing read them reactively. Same throw was `MusuHeist`'s red.
- **%Caper's soft arc is GONE** (Heist_wish/ask/match/leads/condense, %Lead, %Need, %Caperlet, CaperFace,
   MusuSoft+MusuBay Books + fixtures + Credence rows). `Heist_job` (the real per-pier %Caper) stands.
    Shuffle and Tree were NOT dead — deliberately gated (humdinger-cut / show_diag); left alone.

**What detonates if the next person doesn't know it:**
1. A new `.g` is registered in ONE place: `src/lib/O/LiesLies.svelte` `CREDULER_GHOSTS` (the runner's
    hand-kept include list). `wormhole/GhostList` is auto-noticed; `pinned_stable/` is editor bootstrap only.
2. `scripts/wafts_everything.mjs` VALIDATES every `Point` against the ghost's defs — a delete or move
    that skips it leaves the front door lying (the Caper rip-out did, for a day). Re-run after any of either.
3. A stale `Credence` row for a Book whose fixtures are gone 404s the runner into a reload. Sweep it.
4. Compiling an M-spine `.go` HMR-touches EVERY tab on :9091 — check `runners --live` for someone
    else's active engagement before `ghost-compile`, and never reload eed.

**Next moves, in order:**
1. Read the overnight log (above). If quiet: **step 3** — `Ra_quarter` calls `Pool_policy(Pool_facts())`
    for real, the compare goes, then the `Ra_`→`Pool_` rename sweep + fixtures re-sworn. Behaviour change:
     wants your testing time, same as the VisualCrux flip.
2. The tiny-serving-stash ruling (shape only; then it's a small build).
3. `ProtoFsaNav` — a separate fork is designing it (Love_todo §0.0); its brief lands in its own session.
4. Unchanged from 09-13: the crew (Cave) road walked live; the §9.9 rulings; the LinkDevice ambient path.

### 0.0 2026-09-13 morning — the pulse has a dog now; the glass shows the fill

- **"I reloaded and the tally went to 0" was not loss.** `Ra_pool_resurrect` re-catalogues from disk in
   passes ~35s apart (4 → 6 → 9 cards over 3 min); the owner looked between passes. Overnight it went
    10 → **26 cards / 22 playable / 25 files**. The gap was visibility, which is the next point.
- **PoolFace shows the fill live** (`src/lib/O/ui/PoolFace.svelte`): one dim line under the sentence —
   `22/26 playable · 25 file(s) on disk · N uncatalogued · N in flight` — polled every 8s off
    `Ra_pool_report(w, null, quiet=1)` (new third arg: the object without the console block) while the
     cell is big and consent stands. Nothing new in Cellui; the pool-keep-earns-no-cell ruling of 09-06 holds.
- **THE STALL (10:51:54 → 11:15+, no error).** Every pump — Swarm pulse, reach, pool fill, steward, Vyto
   scan — rides ONE async chain, `Sounditron_trickle_look` (Ghost/Story/Sounditron.g), which awaits
    `Peeroleum_runstepped` and `Sounditron_friends` then re-arms by setTimeout. One hung await = every
     pump dead for the session, silently. Now: `M.c.trickle_beat`/`trickle_at` stamps, and a 10s dog
      armed once in `Sounditron_trickle` that restarts under a new era when the beat is 30s stale and
       logs `⏳⚠ trickle stalled Ns in <await>`. Suspect: `Crate_nav_meander` (a disk walk) inside
        `Sounditron_friends` — the nav was churning at that second. NOT proven; the stamp will name it.
- **"👥 two of you" on eed was stale, not a second body.** `Swarm_note_theft` raises `peering.sc.stolen`
   and nothing but Steal Back cleared it. eed's husk was `Stolen:<its own address>,at:09:41` — one claim
    frame from a same-profile second tab, hours earlier, in the SAME page-life (the tab was never reloaded;
     the 15:47 "arrival" lines are soft re-arrivals — the console ring runs straight through them). Now
      `Swarm_stolen` reads a RUNTIME `.c.stolen_at` (stamped per claim frame) and clears the flag after
       120s without one; a real thief re-raises within a pulse. SwarmSteal 6/6.
- **The stall recurred** at ~15:18 on the same (old-build) tab: radio dialing the pool fine, zero 🏊 lines
   for 80+ min. The dog is in the tree; it needs a REAL reload of eed to be live. Two stalls in one day —
    when the dog names the await, fix the await.
- **Cell:Pooling was hidden by its own machinery**: `Sounditron.g` `anyKeep` counted `into:'pool'` keeps,
   and with the pool filling there are always ~3, so the block that mints the `%Pooling` organ never ran.
    Now excluded (Cellui's 09-06 ruling). It shows as a 🏊 bud on a music page with ≥1 pier; tap → main.
- **Cell:Pooling was ALSO cut by the focus cut** (`Sounditron_commission` ~l.895): on a live page `organs` is
   replaced by `fmain + buds`, and the bud list was hand-picked (Hauls/keeps/sanity/Door/Radio) — Pooling
    never in it, so never reachable regardless of the pier/anyKeep gates. Now budded beside Door/Radio;
     the trickle re-commissions when the FRIEND COUNT changes (at boot there are 0 piers, so a glass
      commissioned before the friends arrived never grew the pier-gated organs); Cellui seats a Pooling
       cell with the permanent cast (the extras cap of 2 competes by mint order). Verified live:
        `cells=3 [Radio,Door,Pooling]`. The owner asked for a SURVEY of this whole seat/pose policy —
         "a nice island of SP policy in the middle" — see the roster survey (doc named in its own §0).
- **The screen flapped arrival↔glass 100+/hour**: `Screen_decide` is called with w:Supervisor (Watches
   there → glass) and with w:Sounditron (no Watches → 'none' → arrival). `Supervisor_arrived` now reads
    the Supervisor world whatever world the asker holds.
- **The trickle dog is HUMDINGER-ONLY** — under a Book a pass may sit 30s+ in a stepped handshake.
- **Sounditron Book reads 8/8 red on the runner tonight** with `granted` / `a friend counted their shelf` /
   `a real AudioContext ran` ABSENT — environment after programmatic `runner_ask reload`s (no user
    gesture ⇒ no realtime audio; the runner's friendship re-courts). Not attributed to today's edits (same
     red with the dog disabled); needs a human-tapped runner tab and a baseline run before believing either way.
- **25 is the budget**: 100 MB / ~4 MB per lofi copy. `evicted 1 · deferred 1` per pass = at cap, rolling.
- **ANSWERED 2026-09-15 → `Daemon_todo.md §0.0`** (the rolling shelf being followed: head-run restock per newcomer, invisible to `live`; the pool's minute-by-minute eviction is the same roll; HEISTRANT proposed there).
- **OPEN — S streams ~24 KB/s to eed with no live serve** (`/status` serve: `live:[]`, `tx_kbps:24`;
   eed's Repli meter: 177 MB in 80 min, nothing landing, pool at cap; not over the relay ws — WebRTC).
    Suspect a `repli_lines`/page re-cast on the share beat with no change gate — the `(re×157)` waste from
     09-12 wearing a new face. Next: log inbound `repli_lines` vs `repli_page` counts on eed
      (`Repli_recv_lines`/`Repli_recv_page`, Ghost/N/Repli.g:1216/1278) for one minute and read the daemon's
       caster loop from that.
- **Loose:** a twin card for "Went to Hermes" (evicted card whose file is gone, beside its fresh re-pull) —
   the evict sweep dropped the file and not the card; one of anything. Last night's ~60KB/s Repli rx
    into eed with nothing landing came from the crew mirror, not S (S was idle) — unexplained.
- **Diagnostic cleanup 2026-09-15:** the `🏊? stuck-check` spam (fired every 15s whenever any keep was
   in flight — nearly always) is removed; its root causes were fixed and gated weeks ago and `Pool_facts`
    logging is the structured successor. `🏊 pool card:` was already superseded. `◈✗ ragged-page mirror`
     KEPT — it only fires on a genuine unrecoverable page, not on normal traffic.

**Destination.** The dial already chooses, so the pool KEEPS what played; **love** is the one control —
 press to love (into the pool, and heisted to the Cave), press again to unlove — and every pooled
  track plays from 0:00 like a remote one. The Heard Mag is the ledger of that; the Haul cell shows
   what is new; it all works ambiently in the background and across a LinkDevice.

**Where it stands:**
- ~~♥ is a toggle~~ — SUPERSEDED 2026-09-15 (`Love_todo.md §0`): no unlove anywhere; a later press
   RE-AFFIRMS the same reaction, and Nay is the separate reaction that empties SoundPool of a track.
- The pool card had no preview (`Ra_dial_next` skipped every pooled track) — carry + heal + skip fixed;
   `Ra_rec_heads_carry` / `Ra_pool_heads_heal` bring the **head run** (`%Prehead`) so a pooled track can
    start at 0:00. **Book-green, never walked live** — the one listen the owner still owes (the account: §0.8 → "THE OFFER IS THE TAIL OF THE SONG").
- ~~The offer is the TAIL of the song~~ — SUPERSEDED 2026-09-12 ("THE ACTUAL '0 playable' CAUSE" below):
   a pool card gets its OWN fresh preview encoded from its own full file with `pv_off` forced 0, never
    the radio's 30–70% tune-in cut. SoundPool tracks start at 0:00 from a whole file, always, now.
- Arrival attention: `Heard_notice`/`Heard_seen`/`Heard_unseen` — the Haul cell's `N new`.

**What detonates if the next person doesn't know it:**
1. `Ra_pool_fill_homes` sets `out.mw = radio_w` — the RADIO world. `Repli_arm`/`repli_mirror_pier` live on
    the SWARM world. Gate on the wrong world and the heal is a silent no-op (it was, for a day).
2. `'Prehead'` MUST stay in `Swarm_protocol`'s skips — buf kinds are Uint8Arrays in `.sc`, fine on the
    snap plane, FATAL at the storage/toc encoder. The preview carry's own header says the two changes
     must never be separated.
3. Any pool re-ask needs a give-up (`GIVEUP = 12`, loud) — unbounded re-asks are the disease this
    corpus keeps catching.
4. A Book beat that unloves must leave the world LOVED, or every later beat loses its ground.

**Cave → Captain, read end to end (2026-09-12, the owner: "make sure SP is going to pile up on the Captain
 from his Cave").** The chain is wired, every link by name: a crew redeem mints `Grant:Music` on the mate's pier
  ("CREW SHARES MUSIC", Swarm.g `Swarm_hello`) ⇒ `Swarm_share_granted` passes ⇒ Repli offers the Cave's catalog
   and a `%Theirs` crate of it stands in the Captain's radio world ⇒ `Ra_pool_sources` rows it `crew:1` ⇒ the
    `rolling` compartment (`who:'crew'` by default) draws top-cap by hash ⇒ `Ra_pool_fill_wants` books ONE
     reach at a time to the Cave's routing name (a named holder rides the pier) ⇒ the Cave presses lofi into its
      own pool (`Ra_pool_fill_serve`) ⇒ the Captain lands it through a `%Heist,into:pool` keep over Repli.
 What decides "lots": `budget_mb` on the Pooling cell — 0 = off, `cap = budget × share ÷ 4 MB`, the recent
  compartment takes half at the first yes. Two things to know: (1) the salt never moves live, so "rolling"
   means "holds a fixed random slice of the Cave's library", refilled only as candidates change — not churn;
    (2) the pile grows at the Cave's transcode rate, serially. Not yet walked live on a CREW pair — the
     2026-09-06 end-to-end measurement was eed→daemon (a Music friend); crew differs only in the grant's mint
      site and the roster row, which is why the reading above is a reading.

**2026-09-12, the listen happened (eed, ten pooled tracks) and it found four things, all landed:**
- **Pooled tracks opened mid-song on every skip.** `Radio_hbase` allowed the head only after a play-through
   (`went:'finish'` — the tune-in feel, right for a friend's broadcast). A pooled copy is yours on disk, so it
    now opens at 0:00 whenever its head is whole (`Radio_rec_pooled`); the skip-shape prime agrees.
- **Next was slow** — the pool rung awaited the resurrect + preview heal (up to a whole-file encode) BEFORE
   looking at the shelf; eight dial ticks queued behind one encode. Now: dial what stands, heal on the empty
    road only. And every prime was for one Lineup card the pool dial never picks: `Radio_peek_next` peeks
     the pool on the pool source and the pool rung consumes the standing order first.
- **"Delete the non-full SP"** (the owner): at the 12th unanswered head ask the copy is culled — bytes,
   card — and `%Nohead,id` on the pool home keeps the draw off it (`Ra_pool_cull_headless`,
    `Ra_pool_nohead` in `Ra_pool_sources`; `Ra_pool_off` forgives). ⚠ 12 asks ≈ 50 s is short patience
     for a holder mid-transcode — the owner chose delete over wait.
   **⚠ THE FIRST CUT EMPTIED eed's POOL (found 2026-09-12 midday: "Pool is empty again", 0 cards · 0 files).**
    `%Prehead` never survives a reload (the protocol skips it by design), so every card is head-less at boot
     until the carry re-runs — and the give-up counter ticked on every PASS, including passes where no holder
      could be asked. Twelve passes ≈ a minute; then every card went, files and all, and a durable `%Nohead`
       tombstone kept the draw off it. Fixed: the count stands on a REAL ask to a live holder (4 s apart, so
        twelve unanswered asks ≈ a minute of the holder's silence); the tombstone is session-only (`.c`), a
         reload forgives; stray durable `%Nohead` rows are dropped on sight. Lesson, again: a destructive
          give-up needs a counter that measures the thing it punishes.
- Only 10 in the pool at 100 MB: the heists from S stalled ("NO PROGRESS … 0/1 landed after 7 asks") while S
   transcoded; the pile grows at S's rate, serially, and the 60 s stuck-keep escape keeps the queue moving.

**2026-09-12 evening — three more churns under "only 1 SP", and the robustness read the owner asked for.**
- **Twin chunk sets on the holder.** `Heist_body_new` is a bare mint; the daemon re-materialises after a release
   sweep and minted a SECOND set of %Original chunks beside the first (16 under an 8-chunk lofi). `Repli_chunk_at`
    served whichever `seq` it met first → pages from two presses → the whole-file digest could never match → breach
     #124 → "re-rummage re-mints it" → re-land every 5 s. Fixed: a materialise REPLACES the body. ⚠ Daemon-side —
      needs a jamserve restart to take.
- **Ragged last page.** A lofi's last chunk (253301 B, not ÷4) hit the Float32 refusal because the page arrived
   without `bufk`; the receiver now lands a seq'd/cid'd chunk as bytes by its shape (`Repli_attach_page`).
- **Landed under the copy's id, no `of`.** The holder serves its rummage row (`re:<seed>`), so the pool card
   now takes `of` from `rec.of || rec.re || keep seed` (`Heist_catalog_land`).
- **`Heist_start_over`** (poke) — ledgers (Newlyadded ×2, Heists berth), keeps, pool copies; re-consents.
   Run on eed 21:32: 3 keeps, 2 ledgers, 4 cards. The Haul's "282 tracks kept" was the Newlyadded ledger, honest
    about a day of re-landings.

**Does Heisting/SoundPooling "always get up again"? Read 2026-09-12 — NO, and the shape of why:**
1. Every retry ladder exists (breach ×3, head asks ×12, stuck-keep 60 s/5 min, reach re-dispatch, steward
    re-book) but **none remembers a verdict across the next pass** — a permanent failure (bad hash, no head,
     id mismatch) is retried at full speed forever: 5 s re-landings, 5 MB churn per pass, 124 breaches. What is
      missing is a per-(track, holder) FAILURE MEMORY with backoff (say 1 min → 5 → 30, durable enough to survive
       a reload), consulted by the booker, the heal and the landing alike. The Nohead tombstone is the first one.
2. **Nothing is idempotent by construction.** Body chunks, pool cards, keeps and ledger rows are all minted beside
    what stands (twin chunks, twin records — the 2026-09-06 husk — twin keeps). Every mint that can re-run must be
     find-or-replace. That is the single biggest source of "it ran, then it lied".
3. **Give-ups that don't terminate.** "Breach gave up after 3 — a re-rummage re-mints it" re-arms itself; the head
    give-up used to count passes. A give-up must end in a REMEMBERED state, or it is a loop with a log line.
4. **Ledgers are written on landing, not on verification staying true** — a landed row outlives its eviction,
    hence 282. Ledger rows need the same eviction sweep the pool has, or the Haul should read the shelf, not the log.
5. The daemon's ghosts are the tree's but only at its start; a fix on the holder side needs a restart, and there
    is no /restart (only /stop). Worth one endpoint.
Not built tonight — the ruling needed is (1): where the failure memory lives (the %Reach row has `why`; the pool
 home could carry `%Refused,id,holder,at,why`) and how long it holds.

**Love is per Pier (the owner 2026-09-12):** "model what the user likes amongst a certain Pier's collection — the Love
 data should be per Pier". The Heard Mag already keys `%Card,id,pub` (the pub = whose track); the ruling is that the
  DRAW should read it that way (a taste compartment per holder, not one global love list). Carry into §9.9.

**2026-09-12 late — THE ACTUAL "0 playable" CAUSE, found by watching not guessing (the owner called out the
 churn: "is this effective debugging?" — this is the answer that survived).**

A lofi pool card (`card.sc.grade='ogg128'`) could NEVER get a preview, through EITHER of its two roads:
 `Ra_rec_previews_carry` (called at landing) declines whenever `rec.sc.lofi` is set — true for every fresh lofi
  press — and `Ra_pool_previews_heal`'s own loop skipped a `grade`/`lofi` card OUTRIGHT, before it ever reached
   the ENCODE rung (`Ra_stock_one` — re-read the file, decode, WebCodecs-encode a fresh local Opus preview).
 The "carry" guard is right (never steal a foreign lofi's waveform); the "skip encoding too" was the bug — an
  encode reads the card's OWN bytes and owes nobody anything. Fixed: the loop now skips carrying for a lofi/
   graded card but always falls through to encoding.  Verified live on eed: 3/3 cards went 0→playable in one
    pass, `preview=16` segments ready, `pv_off` ABSENT (see next), `total` full-length (streams the rest during
     play, same as any other record — nothing new built for that).

**And forced `pv_off:0` for every pool encode** (`Ra_stock_one`, both the cache-check and the fresh-encode
 branch) — a pool card is yours, on disk; it should never get the live 30-70% "tune in mid-song" offer cut a
  library/friend track gets.  Before this, the ENCODE rung (when it ran at all, pre-tonight, for the rare
   non-lofi fallback case) still gave pool cards a random offer cut — same "starts a third in" symptom as the
    carried case, from a second, independent cause.  Confirmed absent on all 3 live cards.

**The Opus-vs-Vorbis question, answered plainly (the owner asked directly):** it was never the blocker. Vorbis
 on the daemon's lofi press (`ra_native.ts`, deliberate, 2026-08-08, for old-phone compatibility) is INVISIBLE
  to the fix above — `Ra_stock_one`'s encode rung re-decodes the file with the browser's native codec support
   (which reads Vorbis fine) and re-encodes its OWN Opus preview locally, regardless of what the source file's
    codec is. So: no reason to touch the daemon's codec choice for playability. `level_to_ogg` already supports
     `'opus'` as an option (it's the default parameter) if the export-as-file idea below ever wants it.

**Raised, not built — "perhaps it could leave SoundPooling, as random individual files"** (the owner): today a
 pool copy never leaves the OPFS sandbox. A "save this pooled track to your Downloads" verb is a real, separate
  feature — worth its own line whenever it's wanted; Vorbis (today's daemon choice) would matter again there,
   for the same old-phone reason.

**2026-09-12, past midnight — THE REAL WALL, found live after 25 minutes of zero growth (not slow — stuck).**

Three pool keeps sat 'primed' forever, cycling: mint → 5min give-up (broken — `fill_born` reset every re-mint,
 so it never actually reached 5min the FIRST time either, see below) → cancel → re-mint the SAME seed →
  repeat, for 25+ minutes, while 20-28 OTHER 'arrived' reaches sat "queued behind 3 pool heists" untouched.

**Layer 1 — the keep truly never starts.** Every sibling in each stuck track's album arrived as a `%Pick`
 EXCEPT the keep's own seed track — the folder census discovers everything else and never this one file,
  under any name (the `re:` alias road, `Heist_keep_pool_go`'s existing 2026-09-06/07 fix for exactly this
   shape, ALSO finds nothing). `Heist_keep_solo` returns -1 forever; `Heist_keep_pool_go` returns 0 forever;
    state never leaves 'primed'. **The census/materialise-ask gap itself (why does one specific file never
     get discovered) is real, separate, and NOT fixed tonight** — it needs its own focused session.
 What IS fixed: a wall-clock timer inside `Heist_keep_pool_go` (`.c.solo_wait_since`) escalates to the fast
  no-route give-up after 45s of real waiting, instead of the slow 5-minute PRESS_PATIENCE class (meant for
   "actively transcoding", wrong class for "cannot even locate the file").

**Layer 2 — the REAL wall, one level up: `⨳🫱⚠ reach cap reached (32)`.** `Swarm_reach_book` refuses every
 NEW booking once 32 reaches stand in any state but dead/refused — and 'arrived' never left that set. Every
  give-up above cancelled the LOCAL KEEP but never told its REACH the track was unrecoverable, so the reach
   stayed 'arrived' FOREVER and permanently occupied a cap slot. Once ~28-32 reaches piled up this way (every
    circulation want the steward had ever drawn), the pool couldn't book ANY track, new or old, ever again —
     the console showed it plainly, flooding with cap-refused lines for tracks that had nothing to do with
      the 3 stuck keeps. **This is why growth looked "slow" earlier and then went to exactly zero: the cap
       fills gradually as the census gap claims more tracks, then the wall is total.**
 Fixed: when a keep's give-up was the PERMANENT kind (`no_route_ts` — Layer 1's signal, not a retriable
  mid-pull stall), `Ra_pool_fill_land` now also `Swarm_reach_refuse`s the reach that spawned it, freeing
   its cap slot. **Verified live:** three genuinely NEW tracks landed in the 90 seconds right after this
    HMR'd in (none of the four seeds that had been recycling for 25+ minutes), card count climbing again.
 A mid-pull stall (no `no_route_ts`) stays retriable — only the permanently-unlocatable class gets refused.

**The lesson, for the next person:** a give-up that frees a LOCAL resource but leaves a SHARED counter
 (the reach cap) untouched is not a give-up — it is a slow leak that reads as "fine" until the counter
  is full, at which point everything looks broken at once with no obvious connection to the actual cause.

**Next moves, in order:**
1. ✅ Heard. Next: the crew (Cave) road walked live — every measurement so far is eed→daemon.
2. The five §9.9 rulings in `Radio_circuit_todo` (unpool on unlove; a loved compartment; unlove →
    laptop; a remote running keep; listing sync-back) — the owner's, nothing moves without them.
3. Then the LinkDevice ambient path: a love on the phone reaching the laptop's Haul without a ceremony.

## 0.2a THE SP ISLAND — survey (2026-09-15)

*(§0.2 below is the older RADIO CRUX; this is the POLICY-side twin of the VisualCrux in `Cello_todo.md §0.1`.)*
The owner: *"SP being a crux of operations the user kinda configures and informs various ways … for the humans to
 have what they want to see in one place. can it be so? so if we want to change that policy it's only that area
  changing… all edges (calls in or out) nice and clear."* Answer: yes — the policy is ALREADY two regions of Ra.g
   plus five satellites; what is missing is one home, one facts table, and edges written down. 44 sites below.

### THE HOME EXISTS — `Ghost/M/Pool.g` (2026-09-17, "yes to Pool.g, definitely looks big enough")

A file move, no behaviour change, `MusuPoolPolicy` 5/5 after: the pure island (`Pool_*`, 195 lines)
 first, then the two Ra.g regions verbatim — **the Quartermaster** (`Ra_quarter_*` / `Ra_pool_*` define ·
  home · consent · excuse · budget · caps · compartments · goal→diff→roll · serve, + `Ra_upgrade_scan`)
   and **the pool-fill reach** (`Ra_pool_fill_*` / heals / cull / pump). Ra.g 5845→4240 lines and carries
    ZERO `Ra_pool_`/`Ra_quarter_` defs now; Pool.g is 1799. Registered in `LiesLies.svelte`
     `CREDULER_GHOSTS` (the runner's hand-kept include manifest — the ONE spine-manifest step; the
      `pinned_stable/` bootstrap is Peeroleum+Tribunal only and untouched); `wafts_everything.mjs`'s
       `What:the pool` now points its Doc at Pool.g with the island's three Points added.
  **The `Ra_` prefix on regions 2–3 is history, not a home.** Renaming to `Pool_` is one sweep with
   fixtures re-sworn — do it when the island TAKES OVER (step 3), not before; ~60 verbs, every caller
    is a `this.` call so the sweep is grep-mechanical. Step 3's job is now legible in one file: the
     Quartermaster's goal_pools+diff+roll become `Pool_policy(Pool_facts(...))` and the compare goes.
  Still outside, on purpose (they belong to their ghosts' policies): Radio.g's `Radio_pool_steward` +
   `Radio_meh_ms` + `top.c.pool_steward_cap`, Heard.g's `Heard_landed_cap`/reactions, Swarm's `reach_cap`,
    Heist.g's keep lane, Cellui's `into:'pool'` seat rule.

### FOUND (2026-09-17) — a never-asked identity gets auto-enrolled by serving

`Ra_pool_fill_serve` only checks `Ra_pool_excused_of` before pressing a friend's requested track
 into the HOLDER'S OWN pool (`Siphon_pull(…, homes.pool, homes.lib, …)`) — it never checks
  `Ra_pool_consent`. And `Ra_home_pool` (which resolves `homes.pool`) unconditionally MINTS a
   `%SoundPooling`/`%Pool` shelf via `Ra_pool_home_mint`. So a body that has NEVER opened the
    SoundPool sentence — no yes, no explicit excuse, just never touched it — still gets a Pool
     shelf silently created and filled the moment a friend's standing reach asks to be served,
      spending that body's own disk and (once caps apply) budget with no consent ever given.
       `excused` (explicit opt-out of both holding and serving) works exactly as intended and is
        NOT the bug; the bug is the ABSENCE of a choice defaulting to enrolled rather than to off.

**Owner's ruling (2026-09-17): this is fine, not a bug to gate shut.** *"surely people can serve
 SoundPooling to others if not consented — so I guess they just roll a very small OPFS pool and we
  try to delete it every time?"* — i.e. an un-asked body may still legitimately hold a TINY,
   aggressively-evicted serving cache rather than being blocked outright; consent gates the real,
    budgeted Pool a person KEEPS, not this reflexive small stash. Not built; owner wants to
     re-think the exact shape (size cap, eviction eagerness, whether it's a distinct compartment
      from the consented Pool) **after the `Pool.g` split**, once the SP island has its own file to
       carry the design in cleanly. Do not build the harder gate (`Ra_pool_consent_of`) — that
        reading is now superseded by this ruling.

### STEP 2 — BUGFIX (2026-09-16 morning)

The differs log was firing every ~10min on eed, growing each time (`old=[1 item]` vs `new=[10+ items]`,
 climbing) — looked like real disagreement, was actually `Pool_policy`'s own roll-mirror bug: it only
  handled the "not due" branch (drop all evicts) and fell through UNTHROTTLED when the roll was due,
   while the real pipeline (`Ra_quarter_roll`) always lets exactly ONE eviction through, due or not.
    Fixed: `dropE = evicts.slice(rollDue ? 1 : 0)`, an exact mirror. Compiled + esbuild-parsed clean;
     NOT YET Book-gated or reloaded on eed — the owner was actively in the editor when this was found,
      so gating waits for the runner to be free. **The day-long "quiet agreement" clock effectively
       restarts here** — everything logged before this fix was noise from the bug, not evidence either
        way about whether `Pool_policy` actually agrees with the real pipeline.

### STEP 2 — LANDED (2026-09-15)

`Ghost/M/Ra.g` §`THE SP ISLAND` region grows two verbs. `Pool_policy(f)` — PURE, fed only by `Pool_facts`'s
 output — reproduces `Ra_quarter_goal_pools` + `_diff` + `_roll` for **all six** declared takes (`random`
  with the 2026-09-06 sediment rule, `radio`, `recent`, `latest`, `liked`, `kept`, plus the taste-fallback)
   — the gap noted below at first landing is now closed. `Pool_policy_compare(w, f, liveDiff)` mirrors
    VisualCrux's `Sounditron_crux_compare` throttle exactly (a `w.c.pool_policy_said` map, one log line per
     distinct disagreement shape) and is wired into `Ra_quarter` right after the real diff/roll — comparing,
      never deciding.
 `Pool_facts` grew the RAW arrays the policy needs (`sources_raw`, `pooled_raw`, `recent_raw`, `barred_raw`,
  `held_raw`, `pool_roll_at`, and `salt` on each compartment — missing before, and load-bearing for the
   hash-ranked draw) — excluded from the logged/fingerprinted copy (`JSON.stringify` drops `undefined`
    keys) so `🏊 facts:` stays the summary it was and zero fixture moves.
- **CLOSED — the six-take modeling gap (2026-09-15, same day):** `Pool_facts` gained `latest_raw`
   (`Heard_latest` off the same `mine`/`lib` shelf `Ra_quarter`'s real `shelf` arg always resolves to —
    `Radio_pool_steward`'s `lib = lib || Ra_home_self(w, pub)`) and `tally_raw` (`Ra_quarter_tally` off the
     same shelf), both excluded from the fingerprint like the other raw arrays. `Pool_policy` grew the four
      missing branches (`radio` trims `pooled_raw` from the front, sediment-style; `latest` reads page
       order; `liked`/`kept` sort the tally like the real pipeline) plus the taste-fallback, and now stamps
        `score` on every goal row (previously only present in spirit). `MusuPoolPolicy` grew a 6th scene,
         `MusuPoolPolicy_more_takes`, exercising all four in one combined `Pool_policy` call (distinct id
          namespaces so the compartments' own dedup can't mask a wrong branch) — asserts `radio` evicts the
           one id its cap trims, `latest` press/pulls by page order, `liked` picks by most-recent-`at`, and
            `kept` picks by score — one sworn assertion covering all four. Gate: MusuPoolPolicy 5/5 (was
             4 scenes, now 5, still caveat 0) · MusuPoolRadio 6/6 · MusuPoolFill 6/6 · MusuPoolRandom 5/5 ·
              MusuPoolBytes 5/5 (one hollow-start retry) · MusuQuarter 1/1 · MusuSteward 1/1, all green,
               caveat 0. `wafts_everything.mjs`'s `Heard_unwant` reference (flagged below) was ALREADY FIXED
                by a concurrent edit before this pass started — verified clean, `Ghost/Music/Cave` writes.
                 Live check on eed: still inconclusive, busy the whole window — unchanged from below.
- **`MusuPoolPolicy`** (new Book, `Ghost/Story/HeistTesting.g`, beside `MusuFloor`) drives `Pool_policy`
   directly against hand-built facts — no world, no library, no Mag — four scenes: sediment survives (a
    pooled id no longer a live source still competes, and wanted-and-pooled draws no want at all), a
     barred id never enters the draw, `recent` splits press-vs-pull on what is already held, and the roll
      budget holds an eviction back inside its window then lets it through once past it. **Hit the
       documented CLI-authoring trap** ([[hollow-book-1step-green]]): a brand-new multi-beat Book's first
        `runner_ask run` fires ONE step and calls it green (`total` defaults to 1, only a human clicking
         Resume in the editor grows it) — fixed with the Book's own `if (run.sc.mode === 'new') { run.sc.total
          = 5 }` guard, `rm -rf wormhole/Story/MusuPoolPolicy` to clear the hollow fixture, and a full
           `runner_ask reload` (a bare `release` left the run wedged at `phase:'begun'` forever — not yet
            understood why, only that a full reload cleared it). Declared all 4 sworn assertions
             (`runner_ask declare '<sentence>'`) so an absence reds by name.
- **Book gate, all green, caveat 0** (two Books needed one retry each for the documented `done:0` hollow
   flake, never red): MusuPoolPolicy 5/5 · MusuPoolRadio 6/6 · MusuPoolFill 6/6 · MusuPoolRandom 5/5 ·
    MusuPoolBytes 5/5 · MusuQuarter 1/1 · MusuSteward 1/1. **MusuHeist 22/22 but now 4 caveats** (steps
     3/5/9/13, was 1 caveat at step 3 per step 1's note) — not attributed; Heist.g was untouched by this
      step, so either pre-existing flakiness widened or a concurrent edit elsewhere shook it; needs a look
       before trusting either way. `scripts/wafts_everything.mjs` gained `'MusuPoolPolicy'` in the Ality
        Book list and now finds it (the "no Book" gate reads the fixture folder, not the ghost's defs) —
         **still fails to write**, unrelated: `Ghost/Music/Cave: Ghost/M/Heard.g has no def Heard_unwant` —
          a manifest reference to a verb another concurrent edit deleted today (the no-unlove cut);
           out of my scope (I own Ra.g/Radio.g), needs that manifest line updated or the verb restored.
- **Live check on eed still inconclusive** — refused every console pull as "busy" for the whole window,
   same as step 1's note. The Book gate is step 2's proof; a live `🏊 policy differs` (or its absence) is
    still owed whenever eed is free.
- **Next — step 3, THE FLIP**, per §0.2a(c)'s migration: only once a live differs-log has run clean for a
   day (or the owner accepts the two-take modeling gap as acceptable scope for now) — `Ra_quarter`/
    `fill_wants`/`fill_land` read `Pool_policy`, the two regions move into a real `Pool.g`, the five
     `into:'pool'` ifs collapse to `Pool_is_machinery` everywhere (Cellui included), one consent resolver.

### STEP 1 — LANDED (2026-09-15)

`Ghost/M/Ra.g` §`THE SP ISLAND` region (after `Ra_quarter_serve`, ~l.1936): `Pool_knobs()` (8 knobs, one
 table, each noting where it used to live), `Pool_is_machinery(keep)` (the "pool keep is machinery" fact,
  redirected into Heard.g's clone/haul-beat skip, Heist.g's five `into:'pool'` ifs, Sounditron.g's `anyKeep`
   filter — Cellui's own copy is untouched, for step 4), and `Pool_facts(w, ident)` (the whole §0.2a(a) facts
    table, gathered once per steward pass, logged `🏊 facts:` once per fingerprint change, humdinger-only).
     `Ra_quarter` grew a 7th `facts` parameter it receives and discards (`void facts`) — every Book caller
      omits it and is unaffected. Zero behaviour change: `Ra_quarter_serve` builds the facts and hands them
       in, nothing reads them yet.
- **Book gate, all green, caveat 0**: MusuPoolRadio 6/6 · MusuPoolFill 6/6 · MusuPoolRandom 5/5 ·
   MusuPoolBytes 5/5 · MusuQuarter 1/1 · MusuSteward 1/1 · MusuHeist 22/22 (1 pre-existing caveat at step 3,
    unrelated — see §0's MusuHeist note). **MusuHeard red from step 4** — expected and unrelated to step 1:
     the no-unlove cut from earlier today changed the toggle step's row flags; the fixture is owed a re-swear.
- **Live check on eed inconclusive**: the player refused every console/ping pull as "busy" for the whole
   window (unrelated to this edit — nothing here touches eed, and it was never reloaded). Could not confirm
    the live `🏊 facts:` line or whether `consent_disagree` fires on eed's actual state; the Book gate is the
     proof for step 1, a live read is still owed.
- **Next — step 2**: a pure `Pool_policy(facts) → {wants, evicts}` beside `Ra_quarter_diff`/`_roll`, logging
   disagreements the way VisualCrux's `Sounditron_crux_compare` does, before any flip.

### (a) Every policy site — what decides what the pool keeps, from whom, how much, when, and what the person sees

`hd` = humdinger-only · `B` = Books too · IN = who calls it · OUT = what it reaches

| # | where | decides | on what facts | IN | OUT | scope |
|---|---|---|---|---|---|---|
| 1 | Ra.g:1597 `Ra_pool_start` | consent + budget + the one `rolling` random compartment (share 100), who | budget_mb, who | PoolFace, Heist_start_over, Books | consent_give, budget_set, define, share_set | B |
| 2 | Ra.g:1644 `Ra_pool_off` | 0 MB = off: drop compartments, unfile every copy | — | PoolFace | Ra_pool_unfile, drop | B |
| 3 | Ra.g:1156/1486 `Ra_pool_consent` / `_consent_of` | the yes — TWO resolvers (world→owner vs identity) | `%Consent` under `%SoundPooling` | steward, reach pump, Sounditron facts, PoolFace, report | Ra_pool_owner | B |
| 4 | Ra.g:1172–1186 `Ra_pool_excuse*` | a body that holds no pool (a daemon) | `SoundPooling%excused` | poke, report, start (refuses) | — | B |
| 5 | Ra.g:1511 `Ra_pool_budget_set` | the size (MB) | typed number | PoolFace | caps_apply | B |
| 6 | Ra.g:1518 `Ra_pool_cap_of` | MB → count at 4 MB/track (legacy) | mb | callers of the old cap | — | B |
| 7 | Ra.g:1527 `Ra_pool_track_mb` | the per-track weight off pooled `bytes` (fallback 4) | pool cards' bytes | caps_apply | Ra_pool_stock | hd |
| 8 | Ra.g:1537 `Ra_pool_caps_apply` | cap = MB × share% ÷ weight, per compartment | budget, share, weight | budget_set, share_set, **Ra_quarter every pass** | — | B |
| 9 | Ra.g:1549 `Ra_pool_share_set` | shares sum to 100; others rescale | pct | gang, start, recent_set | caps_apply | B |
| 10 | Ra.g:1075/1587/1665/1675 `define`/`gang`/`drop`/`defs` | the compartment ledger `%Pool,name,take,cap,salt,who,share` | — | start, recent_set, Books | — | B |
| 11 | Ra.g:1619 `Ra_pool_who` | crew / friends / all / none | the random compartment's `who` | PoolFace | — | B |
| 12 | Ra.g:1572 `Ra_pool_recent_on/_set` | the loved-and-landed compartment (share 50, cap 50) | `%Pool,name:recent` | PoolFace (default at FIRST yes) | gang, drop | B |
| 13 | Ra.g:1692 `Ra_pool_sources` | who a random pool may draw from + crew/friend tag | every `%Theirs` mirror, /Crew mates | steward | Ra_pool_owner | B |
| 14 | Ra.g:1684 `Ra_pool_hash` | the clockless shuffle order (name:salt:id) | salt | goal | — | B |
| 15 | Ra.g:1730 `Ra_quarter_goal_pools` | THE DRAW: per compartment ids by take (random/radio/recent/latest/liked/kept/taste), sediment survives, `barred` skipped | sources, pooled, recent, tally, barred | Ra_quarter, Ra_quarter_lone (l.1798) | tally | B |
| 16 | Ra.g:1825 `Ra_quarter_diff` | goal vs pooled(id∪of) vs held → pull / press / evict | goal, pool, lib | Ra_quarter | — | B |
| 17 | Ra.g:1873 `Ra_quarter_roll` + `Ra_pool_roll_ms` (600 s) | the ROLL RATE: one non-barred displacement per window; barred evicts always | wall clock, barred | Ra_quarter | — | hd |
| 18 | Ra.g:1888 `Ra_quarter` | one steward pass → `%Provisions > %Want,of,do` | recent (Heard_landed_ids), barred (Heard_barred_ids), defs, sources | Radio_pool_steward via Ra_quarter_serve:1935 | Heard (read), caps_apply, Ra_pool_home_mint | B |
| 19 | Ra.g:1935 `Ra_quarter_serve` | act on the wants: press (Siphon), evict (unfile + drop card, `pool_evicted`), defer | nav, lib, pool | steward | Ra_pool_unfile, Ra_rec_drop, Siphon | B |
| 20 | Ra.g:1064 `Ra_quarter_tally` | taste score per id (took/kept/why) | Heard-derived | goal | — | B |
| 21 | Ra.g:5236 `Ra_pool_fill_wants` | book a standing `%Reach,for:serve` per `do:pull`, **budget 3 fresh/pass** (`w.c.pool_fill_budget`) | wants, holder | steward | Swarm_reach_book | B |
| 22 | Ra.g:5379 `Ra_pool_fill_serve` | the CAVE presses the asked track into its pool (every `serving` reach — no queue, no budget) | serving reaches | fill_pump | Siphon_pull, Ra_stock_one | B |
| 23 | Ra.g:5419 `Ra_pool_fill_land` | the CAPTAIN: walk `arrived`, mint `%Heist,into:pool`, **K=3 parallel** (`pool_fill_parallel`), stuck give-up after `pool_press_patience_ms` 300 s or fast on `no_route_ts` → cancel keep + refuse reach | arrived reaches, keeps' .c clocks | fill_pump | Heist_keep_pool_go, Heist_keep_cancel, Swarm_reach_refuse | B |
| 24 | Ra.g:5810 `Ra_pool_fill_pump` | the tick: serve → land → resurrect → heal; steward once/60 s; 120 s expiring latch | `pool_fill_busy`, `pool_steward_at` | Swarm_reach_pump:6553 (gate: reach_on ∨ consent_of ∨ serving) | all of 19–27 | B |
| 25 | Ra.g:5654 `Ra_pool_previews_heal` | a pooled copy gets its own Opus preview (carry for hifi; ENCODE always, pv_off 0) | card.grade/lofi | fill_pump | Ra_stock_one, Ra_rec_previews_carry | B |
| 26 | Ra.g:5786/5802 `Ra_pool_cull_headless` / `_nohead` | drop a copy whose head run never came after N real asks (session `.c` tombstone) | asks to a live holder | dial (empty road) | Ra_rec_drop | B |
| 27 | Ra.g:1231 `Ra_pool_resurrect` | files on disk with no card → cards (4/pass); **card with no file → dropped** (09-15) | nav listing, `pool_evicted` | fill_pump, boot | Ra_rec_pool, Crate_meta_from_tags | B |
| 28 | Ra.g:1406 `Ra_pool_report` | THE legible dump (+ `quiet`) | everything above | poke, PoolFace (8 s), dial's dry-pool excuse | — | B |
| 29 | Ra.g:1101–1146 `Ra_pool_owner/_home*/_stock/_pub` | WHERE the pool lives: identity when `w === top.c.radio_w`, else w | `top.c.radio_w` beacon | everything | — | B |
| 30 | Heist.g:1034 `Heist_catalog_land` (pool branch, ~1075) | a landed pool press becomes `%Record,id:<lofi>,of:<orig>,lofi` on the POOL shelf, no holder | job.seed, grade | keep lane | Ra_rec_pool, Ra_home_pool | B |
| 31 | Heist.g:3388 `Heist_keep_pool_go` | a pool keep may pull only once its own `%Pick` stands; 45 s solo-wait → `no_route_ts` | rummage census | fill_land | Heist byte lane | B |
| 32 | Heist.g:109 `Heist_is_pool` + `into:'pool'` skips (Heard.g:~660 clone beat, Heard_haul_beat, Sounditron.g:342, Cellui:235) | "a pool keep is machinery, not a haul" — FIVE copies | keep.sc.into | — | — | B/hd |
| 33 | Heist.g:328 `Heist_xfer_breach` | 3rd body-digest breach: refuse the reach, cancel the pool keep | breaches | keep lane | Swarm_reach_refuse, Heist_keep_cancel | B |
| 34 | Swarm.g:6316 `Swarm_reach_book` | the transport cap **32 standing** (`w.c.reach_cap`) — refuses the pool's booking | standing reaches | fill_wants | — | B |
| 35 | Swarm.g:6535 `Swarm_reach_pump` | the pool tick rides the reach pump (5 s cadence) behind reach_on ∨ consent ∨ serving | knobs | Swarm_pulse_all ← Sounditron_trickle_look | Ra_pool_fill_pump | B |
| 36 | Radio.g:1546 `Radio_pool_steward` | consent gate; `top.c.pool_steward_cap` **24**; 120 s busy latch; books fills | consent, declared compartments | Radio_pump_tick (!rec), fill_pump (60 s) | Ra_quarter_serve, Ra_pool_fill_wants, cull_headless | B |
| 37 | Radio.g:1528 `Radio_dial_pool_local` → `Ra_dial_next` | what the pool source plays: dialable (preview + chunks), not heard, retry drops the skip set | pool shelf, Radio_heard | Radio_dial pool rung (l.2548 `Radio_dial_pool`), Radio_peek_next:749 | Ra_dial_next | B |
| 38 | Radio.g:4360 `Radio_rec_pooled` / `Radio_hbase` | a pooled track opens at 0:00 | card.lofi/of | Radio_open | — | B |
| 39 | Radio.g:217 `Radio_skip` + `Radio_meh_ms` (20 s) | an early skip writes `meh` | `radio.c.open_at` | the ⏭ | Heard_meh | hd |
| 40 | Radio.g:4149 `Radio_nay` / 4107 `Radio_like` | the reactions the pool reads; pooled ♥ names `of`, no holder | Heard_take_id/_pub | RadioFace | Heard_nay / Heard_take | B |
| 41 | Heard.g:565 `Heard_landed_ids` (+`Heard_landed_cap`) | the `recent` feed: loved AND landed, newest first | Mag take cards, Mine | Ra_quarter | Heard_landed | B |
| 42 | Heard.g:220 `Heard_barred_ids` (+ `Heard_nay`:200, `Heard_meh`:209) | what the pool never draws | Card nay/meh | Ra_quarter | — | B (meh: hd) |
| 43 | PoolFace.svelte | what the person SETS (MB, who, recent) and SEES (pooled, fill line, GB free, persistent/evictable); clamps to disk; asks `persist()` at first yes | Ra_pool_* reads | the glass | 1, 2, 5, 11, 12, 28 | hd |
| 44 | Sounditron.g:639/902/1479–1505 + Cellui:235/714 | WHEN the person sees it: Pooling organ (humdinger ∧ ≥1 pier), budded; `pool_consent`/`pool_seen` facts; pool keeps earn no cell; a Pooling cell keeps its seat | consent, any take, piers | commission / VisualCrux | Ra_pool_consent_of, Heard_cards | hd |

### (b) The five worst scatterings

1. **One yes, two resolvers, five askers.** `Ra_pool_consent(w)` finds the home only through `top.c.radio_w`; `Ra_pool_consent_of(ident)` asks the identity. Swarm_reach_pump, Radio_pool_steward, Sounditron facts, PoolFace and the report each pick one — the 09-05 "confident false NO" class is one wrong pick away.
2. **Three numbers for one budget.** `Ra_pool_cap_of` (MB÷4), `Ra_pool_caps_apply` (weighed), and `top.c.pool_steward_cap` (a bare 24 the steward hands `Ra_quarter_serve`) — plus each compartment's own `cap`. Which one bounds a pass is a reading exercise.
3. **Eviction is decided in five places.** goal-diff (16), roll rate (17), nohead cull (26), orphan drop in resurrect (27), breach cancel (33) — and `pool_evicted` (a runtime map) is the only memory any of them share.
4. **"A pool keep is machinery" is copied five times** (32) — Cellui, Sounditron, Heard's clone beat, the haul beat, catalog_land — one fact, five ifs, and the Pooling cell was hidden by one of them for a week.
5. **The knobs have four homes.** `w.c` (pool_fill_budget, pool_fill_parallel, pool_press_patience_ms, reach_cap, reach_on), `top.c` (pool_steward_cap, pool_steward_busy), `rw.c` (pool_steward_at, pool_evicted, pool_nohead, pool_roll_at), and verbs returning constants (Ra_pool_roll_ms, Radio_meh_ms, Heard_landed_cap). No page and no Book can list them.

Dead or odd on the way: `Ra_pool_cap_of` is the pre-weighed cap and should go with the flip; the steward's 24 vs the compartment's 25; ~~`Ra_quarter_lone`~~ — checked 2026-09-15, zero callers anywhere in the repo (it was `Ra_quarter_goal`, the survey's informal name), deleted.

### (c) The island — `Ghost/M/Pool.g`, one ghost, two edges

**Home: a new ghost, `Ghost/M/Pool.g`** — not a marked region of Ra.g. Ra.g is 5,841 lines and the pool is already two disjoint regions of it (the Quartermaster 1045–2003, the POOL-FILL REACH 5196–5841) plus satellites in Radio, Heard, Heist, Swarm, Sounditron, Cellui and PoolFace. A ghost file IS this repo's unit of "only that area changes": its own Ghostmeta dige, its own compile, its own Book roster in Credence, cross-ghost calls stay `this.` within the House. `Pool.g` holds the policy; the byte lanes stay where they are.

**The facts, gathered once per pass (`Pool_facts(w) → f`):**

| fact | from |
|---|---|
| `owner`, `consent`, `excused` | Ra_pool_owner → the ONE resolver (kill the world/identity split: resolve the identity once, hand it down) |
| `budget_mb`, `weight_mb`, `compartments[]` (name, take, who, share, cap) | the `%SoundPooling` home |
| `sources[]` (id, from, crew) | the `%Theirs` mirrors + /Crew |
| `pooled[]` (id, of, bytes, playable, on_disk), `held{}` | pool shelf + Mine |
| `recent[]`, `barred{}` | the Heard Mag, READ-ONLY |
| `standing` (reaches by state), `inflight` (pool keeps by state/clock) | the peering + the shop |
| `humdinger`, `now` | the top House |

**The policy, one readable table (`Pool_policy(f) → { wants[], evicts[], book[], caps }`, PURE):** rows = draw per take · sediment survives · barred never · roll ≤ 1 per 600 s (hd) · K=3 in flight · 3 fresh bookings per pass · give-up 300 s / fast on no-route · nohead after N asks · a Nay evicts now · recent = loved∧landed · a pool keep is machinery. Every row is an owner ruling with its date; every knob is a named field of `Pool_knobs()` with its default — the four `.c` homes collapse into one.

**Edges IN (may call the island):** the tick (Swarm_reach_pump → `Pool_tick`), the dial (`Pool_dial_next` for the pool rung; `Pool_dry_why` for the excuse), PoolFace (`Pool_set_budget/_who/_recent/_off`, `Pool_report`), the reactions (Radio_like/nay/skip write the Mag; the island only READS it), the report/poke, Sounditron's facts (`Pool_seen`, `Pool_consent`), Cellui (`Pool_is_machinery(keep)` — the one copy of ruling 32).
**Edges OUT (the island may reach):** transport `Swarm_reach_book/refuse` (the cap stays Swarm's); the Heist byte lane (`shop.i %Heist,into:pool`, `Heist_keep_pool_go/_cancel`); the press `Siphon_pull` + encode `Ra_stock_one`; the nav (`Ra_pool_files/unfile/bin_read`); the Heard Mag as ledger, never written.
**Stays outside:** chunk lanes (Repli), the head run, previews' encode, faces, the reach primitive, Heist's census/materialise.
**Has to move in:** Radio_pool_steward + Radio_dial_pool_local (Radio keeps only the rung that calls them), the five `into:'pool'` ifs (→ `Pool_is_machinery`), Heard_landed_ids/Heard_barred_ids stay in Heard (they are Mag reads) but are called only from `Pool_facts`.

**Migration, Book-gated (MusuPoolRadio, MusuPoolFill, MusuQuarter, MusuSteward, MusuPoolRandom, MusuPoolBytes; fixtures unmoved until step 3):**
1. `Pool_facts(w)` + `Pool_knobs()` in a new Pool.g; Ra_quarter and the steward LOG the facts (throttled) but decide as today. Zero fixture change.
2. `Pool_policy(f)` pure, run BESIDE Ra_quarter_goal_pools/diff/roll and fill_wants/land's gates; log where it differs on eed for a day; a `MusuPoolPolicy` Book drives the table with hand-made facts.
3. THE FLIP: Ra_quarter/fill_wants/fill_land read `Pool_policy`; move regions 1045–2003 and 5196–5841 into Pool.g verbatim (names unchanged — verb names are not snap matter; the poke allowlist and docs are); delete the five `into:'pool'` ifs for `Pool_is_machinery`; one consent resolver. Re-run the six Books; anything red is a fixture the owner re-swears with the diff in hand.
4. Rename `Ra_pool_*` → `Pool_*`, delete `Ra_pool_cap_of`, fold the four knob homes; update `wafts_everything.mjs` so `Ghost/Music/Pool` is a What of Everything.

## 0.8 PUT THE FEATURE IN ONE PLACE (2026-09-04, the owner's — was §0)

### ⚑⚑ 2026-09-10 — THE HEART IS NOW A TOGGLE, AND IT BREAKS ONE SWORN ASSERTION. OWNER'S CALL PENDING.

**Owner's ruling:** *"basically we love or unlove things, which includes or dis-includes them in SP and
 Heisting to our Cave."* So the ♥ is a toggle: press to love, press again to unlove, at any distance in
  time. **Built** — in `Radio_like` (the button), NOT in `Heard_take` (the ledger primitive), so every
   other caller keeps the old undo/re-affirm pair and the retry road still exists.

**⚠ THIS SUPERSEDES A PRIOR RULING OF THE OWNER'S, deliberately.** `Heard.g`'s own words: the ~10s
 `Heard_thumb` is a fat-thumb UNDO, outside it a press RE-AFFIRMS, and retiring is the ✕ on the Haul row
  — *"'you can't lose a heart' is only true if a stray tap cannot spend one"*. The trade was put to the
   owner (a stray tap can now unlove, which dis-includes from pool + heist) and the simpler model won.

**✅ RESOLVED 2026-09-10 — owner: *"we have to keep a latest love|unlove to make matter"*.** The LATEST
 press is the state, at any distance in time; nothing may quietly override it. So the toggle stands and
  the retry road moves rather than dies.
 **And it turned out to cost nothing, because the clearing was never in the button.** `Heard_take`
  strips the verdict keys on EVERY fresh take. So retry is now **unlove, then love** — two presses
   instead of one, and the love clears the failure exactly as the old single re-press did. Retry stopped
    being a hidden second meaning of one button and became the ordinary act of loving something again,
     which is what the latest-press rule wants anyway. No new control, no context-sensitive magic.
 **Book updated to match** (`HeistTesting.g`): `a_re_press_clears_the_verdict` →
  `loving_it_back_clears_the_verdict` (presses twice now), and the toggle beat gained
   `loving_it_back_restores_the_ask` — ⚠ **because the unlove test must LEAVE THE WORLD LOVED.** Ending
    that beat unloved silently rewrote every downstream beat's ground: measured in the step-9 residual,
     no `Heist` minted and the whole `landeded` row gone. An assertion that changes the state later
      beats stand on has to put it back.

*(the fork below is kept for the reasoning; it is settled)*
**⛔⛔ THE TOGGLE DESTROYS THE RETRY ROAD, WHICH IS SWORN AND LOAD-BEARING — OWNER MUST CHOOSE.**
 `HeistTesting.g:6722-6724`, verbatim: *"a re-press is the retry road: it clears the verdict and the wish
  is askable again"* → `row.a_re_press_clears_the_verdict`. Under a toggle that re-press UNLOVES, so
   `card.sc.take` goes, the `Heist` never mints, and the later beats lose their ground. Measured in the
    step-9 residual: fixture has `Card r1 take:1`, `Card r2 take:1 keep:keep2`, `Heist:Track One
     state:primed`; live has `Card r1` and `Card r2` bare, no Heist, and the whole `landeded` row gone.
 **This is why the earlier note asked "where does retry live now?" — it is not hypothetical.** The
  second press carried TWO meanings and the toggle can only keep one:
  - **on a healthy love** → "I have changed my mind" (unlove) ← the owner's ruling
  - **on a FAILED love** → "try again" (clear the verdict, re-arm the gave-up clock) ← the sworn road
 **Three ways out, and it is a design call, not a test-wording call:**
 1. **Context-sensitive press** — toggle when the wish is healthy, retry when it carries a failure
     verdict. Keeps both gestures on one button and needs no new UI. ⚠ But it is a button that means
      two things depending on invisible state, which is the "magic nobody can see" this corpus already
       rejects elsewhere.
 2. **Toggle + an explicit retry control** (on the Haul row, beside the ✕, where a failed wish is
     already visible). Honest, costs a control, and the Haul row is where a stuck wish is looked at.
 3. **Keep re-affirm** — revert the toggle. Simplest, but it is the model the owner just rejected.
 ⓘ **NOT resolved, and MusuHeard is left RED on purpose.** Accepting these fixtures would bake in "the
  heist no longer mints" as if it were intended. The oath rename (`later_it_re_affirms` →
   `later_it_unloves_too`) IS done and correct for the toggle; it is `a_re_press_clears_the_verdict`
    that has no honest new wording until the fork above is decided.

**Also: it fails the renamed assertion's neighbours — `MusuHeard` is RED at `ok_pct 0.33`, steps 4–9, `error:null`.**
 `HeistTesting.g` swears **`later_it_re_affirms`**: two presses a minute apart, then
  `String(c1.sc.take) === '1' && String(c1.sc.at) === '1788400150'`. Under the toggle the second press
   UNTAKES, so `take` is gone and the oath cannot be set. Every OTHER swear in the row still holds
    (`took`, `the_press_is_the_ask`, `the_listing_starts_at_the_act`, `the_press_mints_no_heist`,
     `pressing_again_takes_it_back`, `my_own_track_is_a_taste_fact`) — including the fat-thumb undo,
      which the toggle happens to satisfy too.
 **NOT rewritten, on purpose.** An oath is the owner's statement about what is true of the app; editing
  one to match new code is editing the testimony to fit the verdict. The owner decides the wording.
 **The mechanical change, if the ruling stands:** replace `later_it_re_affirms` with the toggle's truth
  (a second press later UNLOVES — `!c1.sc.take`), update its declaration in `MusuHeard`'s toc, and
   re-swear steps 4–9. Note the loss that oath was protecting: **the re-affirm was the RETRY ROAD** (it
    re-armed the gave-up clock and cleared a failure verdict), so with a toggle there is no longer a
     gesture that says "try again" — pressing twice now means unlove-then-love, which is not the same
      thing. Worth deciding where retry lives before re-swearing.

### ⚑ 2026-09-10 — "AND THEY SHOULD BE LOVABLE": the ♥ on a pool item went HOLLOW ON RELOAD

Owner, alongside the start-position ask: *"and they should be lovable"*.

**The write and the read-back disagreed about which pub the heart lives under.**
- **Write** — `Radio_like` (`Radio.g`): `let by = String(n.sc.by || me)`. A pool item has **no `n.sc.by`**
   (the pool is not a friend; there is nobody to name), so the take is recorded in the heard ledger
    under **ME**.
- **Read-back** — `RadioFace.svelte`'s `likedThis`: the ledger probe was **gated on `n?.sc?.by`**. For
   exactly those tracks it therefore **never ran**.

⇒ The heart lit from `n.c.liked` — a RUNTIME mirror, which the file's own note says "dies with the
 process" — and went hollow on the next reload, while the durable take sat in the ledger unread. The
  love was real and recorded; only the button forgot.

**Fixed:** the probe now mirrors the write (`n.sc.by || Radio_pub(w)`) instead of requiring `by`.
⚠ **WIDER THAN THE POOL, and worth knowing:** this affects **any** track with no `by` — one's OWN
 library tracks included, not just pooled ones. The gate looked like "only a friend's track can be
  loved", and quietly meant "only a friend's track stays loved".
ⓘ NOT verified live — it needs a ♥ pressed on a pool item and then a reload. The reasoning is
 code-traced end to end (`Radio_like` → `Heard_take` → `Heard_taken`), but no live walk has been done.

### ⚑ 2026-09-10 — POOL ITEMS START 1–2 THIRDS IN BECAUSE **THE OFFER IS THE TAIL OF THE SONG**
⚠ SUPERSEDED 2026-09-12 — see "THE ACTUAL '0 playable' CAUSE" above this section. SP no longer keeps
 the radio's truncated offer at all; it heists a whole file and encodes its own preview from byte 0.
  Read this section as the diagnosis that led there, not as current behavior.

Owner: *"I need soundpool items to be full tracks… they seem to start at 1-2 thirds of the way… they
 should start from the beginning in the same conditions a remote radio track does."*

**Diagnosed, with live numbers off the daemon (`/c?token=sheeps&depth=9`).** A real record:
`seconds=298.84, seg_secs=2, preview=16, total=58, pv_off=92`. That is ~149 segments of song;
 **`pv_off=92` puts the offer's first byte at 62% in**, and `92 + 58 = 150` — so **the offer IS the tail
  from 62% to the end**, not a whole track with a marker. `Ra_preview_offset` picks that cut in a
   30–70% band (`lo = ceil(segs*0.3)`, `hi = floor(segs*0.7)`) — precisely the reported symptom.

**So a pooled item is not mis-seeking; it is a SHORTER FILE.** The pool "keeps what played", and what
 played was the offer. Nothing is skipping the beginning — the beginning was never fetched.

**Two mechanisms live here and only one is the culprit — do not confuse them (the code says so at
 `Radio.g:699`):**
1. `Radio_start_seq` — the deliberate tune-in-mid-track feel. **NOT this.** It latches `c.tuned` and so
    fires **ONCE A SITTING**; it cannot explain every pool item starting late. It also only bites on a
     fully-held track (a remote one has too few chunks: `room < 1` ⇒ returns 0).
2. **The offer cut** — every pooled item, for ever. **This one.**

**Why a remote radio track does start at the beginning and a pool item never does.** Opening at the
 song's real start is a *different mechanism*: a **head run concatenated in FRONT of the offer**, chosen
  by `Radio_hbase`, gated on `Ra_head_whole(rec)` — which needs `rec.sc.pv_off > 0` **and** every head
   chunk `0..pv_off-1` held as `%Prehead`/`hseq` children (`Ra.g:3696-3714`).

**THE CHAIN, end to end (all code-verified):**
1. The head can be PULLED from a peer — the wire has it: want `stream:'opus_head'` → `Repli_serve_head`
    (`Repli.g:1055, :234`), which pages `[0, pv_off)` and kicks `Ra_head_ensure` on the holder.
2. There is exactly **ONE** sender of that want, `Ra.g:4947`, gated at **`Ra.g:4936`**:
    `rec.c.from && +(rec.sc.pv_off||0) > 0 && rec.c.rx && w.c.repli_mirror_pier && !Ra_head_whole(rec)`.
     A pool card meets every clause **except `pv_off > 0`**.
3. A record only makes its OWN head locally when **`!rec.c.from`** (`Ra.g:4919`) — it needs the original
    file. A pooled record has `from` set, so it can never make one either. Pull or nothing.
4. `pv_off` reaches a copied card only through **`Ra_rec_previews_carry`** (`Ra.g:2572`), which carries
    `seconds · gain · lufs · sr · br · seg_secs · nch · pv_off` — **but declines outright at `:2574` for
     `rec.sc.lofi || card.sc.lofi || card.sc.grade`.**
5. **`Heist_keep_pool_go` sets `keep.sc.lofi = 1`** (`Heist.g:3330`) — the pool takes it LOFI on purpose
    (holder-side transcode, fewer bytes on the wire).

**⇒ THE POOL IS LOFI, LOFI GETS NO CARRY, SO NO `pv_off`, SO THE HEAD IS NEVER ASKED FOR.** And the
 declining is *correct* as written — the carry's own note says a LOFI rendition is DIFFERENT bytes, so
  borrowing the original's preview would be "someone else's waveform wearing its name".

⚠⚠ **BOTH OF MY EARLIER STORIES WERE WRONG. THE MEASUREMENT REFUTED THEM — read this before the fix.**
 Walked all **167 pool %Records** on the live daemon (`/c?token=sheeps&depth=9`, parsed as JSON):

| group | count | `preview` | `pv_off` | `lofi` | `grade` | `stage` | `of` |
|---|---|---|---|---|---|---|---|
| carried | 63 | `16` | present | absent | absent | absent | absent |
| **NOT carried** | **104** | **absent** | **absent** | absent | absent | absent | absent |

1. **Story 1 — "`pv_off` is stamped nowhere in the pool path" — WRONG.** 63 pool cards have it.
2. **Story 2 — "the LOFI decline is the gate" — ALSO WRONG.** **Not one** landed pool card carries
    `lofi`, `grade`, `stage` or `of`. The lofi flag lives on the KEEP (`stage:"husk"` keeps on the
     daemon do show `lofi:1`), not on the landed record, so `Ra_rec_previews_carry`'s `:2574` decline
      cannot be what separates these two groups.
3. **What the data actually says:** `preview` and `pv_off` are stamped together by the carry
    (`Ra.g:2580-2583`), and they are present or absent together, perfectly, 167 for 167. So the split is
     simply **carried vs never carried** — and **104 of 167 (62%) never were.**
 ⇒ Those 104 have no `preview`, so `Ra_dial_next` (which needs `preview > 0`) **cannot dial them at
  all** — that is the `pool-cards-had-no-preview` bug of 2026-09-05, still true of most of the shelf.
   The 2026-09-07 "carry+heal" fix evidently did not reach them.
 ⇒ The 63 that WERE carried do have `pv_off > 0`, so for them the head question is NOT `pv_off` — it is
  whichever of `rec.c.from` / `rec.c.rx` / `w.c.repli_mirror_pier` fails at `Ra.g:4936`. **`.c` is
   runtime-only and never snapped, so the daemon dump cannot answer that** — it needs a live tab.
 ⚠ Note the two populations are probably different questions: "never carried ⇒ never playable" and
  "carried but starts mid-song". The owner reports items that DO play, so their complaint is about the
   63, not the 104. Do not let one fix be claimed for both.

**⇒ SO THERE ARE TWO SEPARATE PROBLEMS ON THIS SHELF, and the owner's complaint is only the second.**

**(1) 104 of 167 pool cards were never carried — no `preview`, so not dialable.** ⚠⚠ **BUT I MEASURED
 THE WRONG BODY, and the number should not be quoted as the owner's shelf.** Those 167 are the
  **daemon's** cards, and the daemon has `Radio:off … no web audio here` — **it never dials anything.**
   The owner's symptom lives on eed, whose shelf I could not read from this container.

**Why the daemon's cards stay dark is nevertheless understood, and it is NOT a bug.**
 `Ra_pool_previews_heal` (`Ra.g:5508`) has two rungs — borrow a preview from a standing record of the
  same id, else encode one from the file it holds — and the encode rung is gated at `:5529` on
   **`top.c.humdinger`**, i.e. music pages only. The daemon has no WebCodecs, so it genuinely cannot
    encode; the gate is right. Its dark cards can only ever be healed by borrowing, and for a body that
     never plays, being undialable costs nothing.
 ⇒ **So "62% of the shelf is dark" is true of a server that does not care.** Whether it is true of eed
  is UNMEASURED. Re-run the same walk against eed's tree before treating this as the owner's problem.
 ⓘ Worth knowing when you do: the heal is bounded at **4 carries and 1 encode per pass**, so a large
  dark shelf converges slowly even on a humdinger — a shelf that looks stuck may simply be draining.

**(2) ✅ SOLVED 2026-09-10 — MEASURED ON EED ITSELF, then closed in the code. NOTHING ASKS.**

**Measured on the owner's own body** (`runner_ask minisnap 'self>SoundPooling' --depth=5
 --player=eed831f1977c4e81`):
- All 5 pool cards carry **`preview:16` AND `pv_off`** (60 · 94 · 86 · 6 · 682) — so problem (1) is NOT
   eed's problem and a missing `pv_off` is NOT the cause.
- **80 `Preview,seq` chunks (5 × 16, every set complete) and ZERO `Prehead`/`hseq`.** The cards hold no
   head at all ⇒ `Ra_head_whole` false ⇒ `hbase` 0 ⇒ playback opens at the offer's first chunk, which
    for these five is 36% · 56% · 66% · 27% · 63% into the song. Exactly the reported symptom.

**And the reason no head is ever made or fetched: THE HEAD MACHINERY NEVER LOOKS AT POOL CARDS.** Both
 branches — the local make (`Ra.g:4919`) and the `opus_head` pull (`Ra.g:4936`, the only sender) — live
  inside **`Ra_restock_beat(w, mirror, budget)`**, whose first act is `let recs = this.Ra_recs(mirror)`
   (`Ra.g:4804`). It walks the **MIRROR** shelf — records being streamed from friends. Pool cards hang
    off the **SoundPooling** home. They are never iterated, so neither branch can ever fire for them.
 ⇒ It is not a failing gate. **Nothing asks.**

**⇒ THE OWNER'S RULING 2026-09-10: *"should be generated like LOFI is."*** The pool's LOFI rendition is
 already produced **holder-side, on demand**, and the head has exactly that shape available already:
  a want of `stream:'opus_head'` makes `Repli_serve_head` kick `Ra_head_ensure` on the holder and page
   `[0, pv_off)` back. The generator exists; only the ask is missing.

**✅ BUILT 2026-09-10 — compiled, parse-gated, and Book-verified. NOT yet walked live** (that needs a
 real pooled track whose holder is online; nothing here proves the wire round trip).
 Final suite, all on the shipped build: `MusuPoolBytes` 5/5 · `MusuPoolFill` 6/6 · `MusuPoolRadio` 6/6 ·
  `MusuPoolRandom` 5/5 · `MusuReplica` 14/14 — **every one caveat 0**, step counts checked so a hollow
   run cannot read as a pass. `MusuHeist` 22/22 caveat 15, inside its own measured baseline spread
    (17·20 on committed code, 1·17·15 on this one — see `Loose_ends_todo`; that Book is simply noisy).
 ⓘ A `MusuPoolBytes` caveat 3 appeared once and was **flake** — 0·0·0 on three re-runs. Two separate
  single-sample scares in one session; measure three times before believing a pool caveat.
 FOUR pieces, and they are ONE change — do not land them apart:
 1. **`Ra_rec_heads_carry(card, rec)`** (`Ra.g`, beside the preview carry) — carries `%Prehead`/`hseq`
     children across when a record of the same id already holds a WHOLE head. Same honesty rule as the
      preview carry: never onto a `lofi`/`grade` rendition, and all-or-nothing (a partial head is a hole
       in the song's first minute, which `Ra_head_whole` rightly refuses).
 2. **`Ra_pool_heads_heal(w, ident, homes)`** — the ask, hung off `Ra_pool_previews_heal`'s tail so it
     rides the pool pump's cadence. Two rungs, mirroring the preview heal: carry a standing run if there
      is one, else send the holder a `stream:'opus_head'` want THROUGH the standing source record (a pool
       card is a local file and carries no wire handles of its own). **ONE card a pass** — heads are a
        median 47% of a song, so this must trickle, never sweep.
     **BOUNDED, and loud when it stops** (`pool_head_giveup`, default 12): a head its holder will never
      serve — peer gone, original moved, encode failing there — would otherwise cost one frame every
       pump pass for ever, silently. It gives up and SAYS which track and which range went unserved.
        Cleared on success, so a peer that returns is asked again from zero.
     ⚠ **TWO WORLDS.** `homes.mw` is the RADIO world (shelves live there — that is what the lookup
      uses), but `Repli_arm`/`repli_mirror_pier` are on the SWARM world, which keeps only a POINTER
       (`repli_mirror_w`) to the radio one. The ask must go through the caller's `w`. Gating on
        `homes.mw.c.repli_mirror_pier` is ALWAYS falsy — written that way first, and it is a perfect
         silent no-op: no error, the feature simply never fires. **Ask which world holds a `.c` key
          before reading it.**
 3. **`'Prehead'` added to `Swarm_protocol`'s `skips`** (`Swarm.g`) — ⚠ **THE HALF THAT IS EASY TO
     FORGET.** The preview note there says these changes "must not be separated" and it means it
      literally: `%Prehead` bufs are Uint8Arrays in `.sc`, the pool shelf hangs on the `%Identity`, and
       the account snap would walk straight into them — fine on the snap plane, **fatal at the
        storage/toc encoder**. Minting head bufs onto a card without this skip breaks account export.
        (Verified `'Preview'` is named in exactly one place in the corpus, so one skip is the whole fix.)

**Where the ask belongs: `Ra_pool_previews_heal` (`Ra.g:5508`), not the restock beat.** It already
 sweeps the pool shelf, is already bounded (4 carries + 1 encode a pass), and already has precisely the
  "borrow it, else generate it" two-rung shape this needs. Add the head as a third rung: for a pool card
   with `pv_off > 0` and `!Ra_head_whole(card)`, ask its holder for `opus_head`. Extending the restock
    beat instead would put pool traffic inside the streaming budget, which is the wrong pocket.
 ⚠ **A local encode will NOT do here** — a pooled file holds the OFFER, so segments `[0, pv_off)` are
  not on this disk to transcode from. It must be the holder-side generation, which is what the ruling
   says anyway.
 ⓘ Cost, measured over 54 records: the head is a median 47% of the song, so heads roughly **1.95×** the
  pool. See the sizing note above before choosing to fetch them eagerly rather than on first play.

**ⓘ WHAT IT COSTS, measured over all 54 distinct records on the daemon (not one).** Head fraction:
 **min 27% · median 47% · mean 49% · max 69%.** Summed: **4194 head segments vs 4401 offer segments ⇒
  adding the head multiplies pool bytes by 1.95×.** So "full tracks" roughly **DOUBLES** the pool, and
   the per-track spread is wide enough that no single number describes it.
 ⚠ My first note here said "the head is the larger part" and "roughly triples" — that was extrapolated
  from ONE record (the 62% one). It is wrong: the median is 47%, i.e. the head is usually slightly
   *smaller* than the offer. Same one-sample error this corpus keeps paying for; corrected by measuring
    the whole shelf.
 ⓘ `preview=16` is constant on every record — the 16-chunk taster is a fixed size and is NOT the offer;
  don't confuse the two when sizing this.

⚠ MEASURED: the offsets, the absent `pv_off`, the two mechanisms, the 1.95× cost. INFERRED: that adding
 the head run is sufficient — not yet built or walked.

### ⚑⚑⚑ 2026-09-07 — THE LAST LINK: the holder minted TWO records under one keep-id (the pull now runs 0→52/54)

**The bytes now flow.** Walking the live daemon (`/c?token=sheeps&depth=9`) + the relay tally + eed's
 console ring against the actual code, the last link was a **holder-side twin-record bug**, not anything
  on the asker. When S materialises a track for a want, `Heist_materialise_one`'s stocked-content-id
   branch minted a **fresh** `%Record` under the deterministic keep-id in a **new** `RummageLib` — but the
    folder DESCRIBE had *already* stood that same keep-id as a chunkless husk (`total 0`) in another lib.
     Two records, one id. `Repli_find_record` returned whichever lib registered first — the husk — so
      `Repli_serve_chunks` hit `!Repli_page_ready` on a `total:0` record and **returned in silence**
       (`from < total` is `0 < 0` = false → no park, no miss, no log): the exact "silent death" its own
        `Repli_serve_miss` comment names. eed re-asked `repli_want ×35 / 10s` forever; S's `serve.live`
         stayed `[]`; 18 real chunks sat one lib over, untouched.

**Three fixes this turn (all ⌛ uncommitted; gen compiled + esbuild-gated; daemon hot-swapped them live):**
- `Heist_materialise_one` (Heist.g ~1436): materialise **onto the standing husk** when a lib already holds
   the keep-id, instead of minting a second record under it. *One id, one record.*
- `Repli_find_record` (Repli.g ~812): when several libs hold the id, **prefer the one with `total > 0`**;
   fall back to a bare husk only if nothing better exists. Belt to the braces above.
- `Repli_serve_want` (Repli.g ~1027): a want that is neither servable nor parkable now **calls
   `Repli_serve_miss`** (`chunkless husk (total 0)` / `past the end`) instead of returning silently — so
    this class can never again be invisible on the wire.
- Also **reverted the 2026-09-06 "ask by the seed" retarget** in `Heist_keep_pool_go`: a pool pick is a
   *blag* pick (`ref = seed`, `blag = 1`) and the pull binds it by `re:seed` → the lofi ogg128
    (`re:<seed>`, 18 full chunks), which is the right rolling copy. Retargeting `ref` to the seed dropped
     the blag mark and made the pull chase the seed's **opus preview** (`{id:seed}`, 54 incomplete chunks)
      — the "A BLAGGED PICK BINDS BY re" hazard the pull loop warns about, in the flesh (stalls at 52/54).

**PROVEN this turn:** after S hot-swapped, `repli_want` fell 35→10/10s, a `repli_parked` appeared, and on
 the running tab the pull climbed **16 → 52/54** (it was `0/16` before). The residual 52/54 stall is the
  OLD asker code on eed pulling the wrong record (the seed's opus preview) — it cannot be fixed remotely
   because **a music page refuses a remote reload by design** (`Lies_is_runner` gate; the listener's tab
    is theirs). **NEXT: the owner reloads eed** to pick up the reverted `Heist_keep_pool_go`; the pool pick
     will then bind `re:seed` → the 18-chunk lofi that is fully materialised and waiting on S, and land.

**THE REGRESSION NET IT NEVER HAD — `scripts/ServeResolve.spec.ts`, 6/6 green, no runner.** This class was
 unreachable by any Book (a fixture hand-mints its mirror, so a record's id IS the seed and the two
  id-spaces collapse), but the resolver is *pure*, so a unit spec over fixture particles reaches it. It
   pins the two defects separately, because they only looked like one — pick the wrong record, then say
    nothing about it:
- **the twin** — two `%Record`s under one id, and `Repli_find_record` must take the one that HAS BYTES,
   whichever lib registered first (the old bug was literally "first lib wins").
- **the silence** — `total:0` is neither servable nor parkable (`from < total` is `0 < 0`), and
   `Repli_serve_miss` now speaks there, once per id per 5s so a re-ask storm is not a log storm.
- **presence is fill state** — a promised chunk with no bytes is *not* servable, and unlike the husk it
   IS parkable (`0 < 3`). That is the whole difference between "wait, bytes are coming" and silent death.
 Writing it caught a wrong assumption of mine, not of the code: my first fixture minted byte-less chunks
  and the positive control failed — `Repli_chunk_at` requires real bytes, correctly.
```
node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/ServeResolve.spec.ts
```

**GATE (runner e747cbed, reloaded to the new gen):** MusuPoolBytes 5/5, MusuPoolFill 6/6, MusuPoolRandom
 5/5, MusuPoolRadio 6/6, MusuReplica 14/14 — all **caveat 0**. MusuHeist 22/22 ok but caveat 1 on 20 steps
  — a broad PRE-EXISTING drift (it blankets handshake steps that touch no changed code, and the four pool
   Books + MusuReplica exercise every line I touched with zero drift). Not mine; left for the human.

### ⚑⚑⚑ 2026-09-06 evening — the SUBSTRATE under the pool (the four stacked faults)

**The destination is unchanged and now close:** eed pools *from S (the daemon)*, and the daemon is a
 SOURCE, not a pooler — the owner: *"I don't want the daemon to accumulate SP."* The whole chain
  reach → serve → press → `arrived` has now run end to end from S to eed for the first time (daemon log:
   `pool-fill: served 1 reach(es) from my own library` · `lofi: … .flac → ogg128 (4021KB from 92690KB)`).
    **The one link never yet seen to complete is the last one: the Repli chunk pull landing those bytes**
     (`⇊⟲ unanswered materialise asks` on eed while S is silent about them). That is the next thing to
      look at, and the daemon's `◈` lines at the moment eed asks are the evidence nobody has caught yet.

**What actually broke — four stacked faults, none inside SP** (spec/Social_demarcation_todo.md is the
 full account; fixes ✓ committed in `quack`/`ooh` unless marked ⌛ uncommitted):
1. ✓ **A closed Incognito window was eed's crew Cave** (`Body,post:Cave` + `/Crew mate`) and
    `Ra_pool_fill_homes` asks the Cave first — every want, reach and `ws SEND` went to a ghost for 36h
     while S was never addressed. Owner ejected it from the Door.
2. ✓ **Reaches could not die** — `Swarm_reach_target_gone` (no crew row AND no live grant ⇒
    `state:dead, why:'no such body any more'`; ledger-based, never presence). Live nodes only.
3. ✓ **The serial budget was spent on standing reaches** (`if (n >= budget) break` counted a stale
    reach) — now `fresh >= budget`; the tally `n` keeps the rebook_idempotent contract.
4. ⌛ **The 32-cap counted corpses** — 11 of eed's 32 were dead/refused; cap now counts standing only.
5. ⌛ **The give-up could not see a never-started keep** and timed a started one off `last_touch`, which
    Heist.g rewinds in ten places ⇒ immortal. Now: `routeWait` 60s / `pressWait` 5 min
     (`w.c.pool_press_patience_ms`) — a 92MB FLAC → ogg takes minutes and the old 60s cancelled the first
      real fill mid-transcode — timed from `k.c.fill_born`, a clock only Ra.g winds.
6. ⌛ **Pier heal pestered 7 revoked peers** every 120s — skips a pier with no live feature.

**Then, the same evening, with the console ring finally readable (`runner_ask console --player=`) and the
 relay's own per-type tally (`📊 <to> <type> ×n bytes`, listen bound as `?addr=editor`): the last link.**
 The pool keep for "Peach, Plum, Pear" (seed `00bfacb6`, S's Mine id) sat `primed` for hours with
  **eighteen picks — the whole Owen Pallett folder** (`un_n=18`) while S sent pages at 20–50KB/s that
   never landed. `Heist_keep_pool_go` → `Heist_keep_solo(keep, seed)` looks for the pick with
    `ref === seed`, but the picks are minted by the folder census under the source's **rummage ids**
     (`64a77aae`), and the seed only appears as the mirror record's `re`. No match → `-1` → "wait for the
      seed's husk" → forever. ⌛ Fixed: resolve seed → pick through `srcmir`'s `re` (the argument that was
       passed and never read) — and then **ask by the seed**, not the rummage id: the solo pick went
        `pulling` and was BENCHED at 0/16 because the holder resolves a rummage id only through its runtime
         `w.c.rummage_libs`, wiped by every daemon restart; the seed is its Mine id, resolvable with no map,
          and its opus stock IS the pool's rolling copy (the rummage id stays on the pick as `rref`).
           A Book could not see it: a hand-minted mirror record's id IS the seed —
        **the alias only exists against a live source that was rummaged**. Owed: a Book beat that mints a
         mirror record `id:<rummage>,re:<seed>` and swears the pool keep goes `pulling` with one pick.
 And the refusal storm (17 of 18 reaches `refused not_in_library`, ~4 reaches/s): the mirror of S also
  carries the `husk,rummage` rows a folder describe left behind (a browsed folder, never stocked in S's
   Mine); `Ra_pool_sources` ranked them like tracks. ⌛ Fixed asker-side (skip husks). **Owed holder-side:
    press from a RummageLib husk** — it carries a `path` — so a browsed folder becomes servable; today the
     verdict consults Mine only. Also owed: the reach storm itself (`said_at`/`tries` are `.c`; a
      `reach_done` for a non-terminal state leaves the reach re-dispatching at the 5s base).

**The bomb for the next person:** the Books stayed green through every one of these because a driven
 world has no dead Cave, no reload, no cap, no transcode. Every fault was found in the owner's live
  console. `Story_cli`/headless is a bubble; a Book is a regression net, not discovery. Read the
   live tab or the daemon's `/c`. **A music page IS introspectable** (`runner_ask console
    --player=<pub>`; arm `localStorage.socklog='1'` once) — the day it looked sealed was the relay's
     own-door rule, not production: `deliverLocal` hands every `to:<prepub>` frame to the tab's STATION
      socket alone, and the `runner_ask` handler lives on the `?addr=player` role socket, so an addressed
       ask never arrived. Fixed CLI-side by asking the `player` SLOT with `ask.pub` (the tab filters,
        `Lies_runner_ask_recv`). The relay's own comment promises the proper repair — a second map for
         control-plane types — never built (confirmed still unbuilt 2026-09-10); `relay-test.ts` is its harness.
      ✅ **RULED 2026-09-10 — DO NOT BUILD THE SECOND MAP. The claim above is retired.** The question
       these two threads answered oppositely — *is a role socket a legitimate second door for
        control-plane traffic, or an accident being removed?* — was put to the owner directly, and the
         answer is **an accident**: the target is **one socket per tab**, bound at its prepub, with
          `?addr=` and the own-door rule deleted outright. So the second map is not "unbuilt", it is
           **cancelled** — it would invest in a door that is being closed. The live plan, including why
            the hard part is that handlers are registered PER WORLD (`w.c.on[type]`, two disjoint
             registries) and how the CLI finds runners once `to:'runner'` is gone, is
              `Social_demarcation_todo §0`. Keep the CLI's `player` SLOT + `ask.pub` workaround above:
               under the ruling it stops being a workaround and becomes the shape. (`production` is stamped only
          for `jamsend.*`/`voula*` hosts on a non-dev build; djamsend.duckdns.org is a dev tab.)

**Tooling landed this evening (⌛):** `concap` console ring installs on EVERY tab (was editor|book|grid
 only — a plain music page had no ring) and stamps each line with its true callsite (`Swarm.go:6342 …`)
  so the remote read matches DevTools; `runner_ask --unknown-ok` lets a read-only op reach a live tab
   that missed the 8s `supervisor` classify. Owner's DevTools will now blame `sockcap.ts` — one-time
    "Add script to ignore list" on it restores native attribution.

**Owed, in order:** (a) the last link above; (b) `Social_demarcation_todo.md` §0 — the `Swarm_piers`
 accessor (126 raw `o({Pier:1})` walks), `since` preserved across rehydrate (all 15 of eed's Piers carry
  one identical `since`), a presence floor for the catalog offer (eed↔S starved each other: never heard
   ⇒ never offered ⇒ never a candidate ⇒ never addressed); (c) cluster-signed `runner_ask` so
    `Lies_player_seen` can gate on *who is asking* (`signHeader`/`verifyHeader`/`browserTrustedPubs` all
     exist and are already imported in LiesLies) instead of the deployment stance — the owner's call,
      and strictly stronger than today; (d) the daemon-as-source-not-pooler fork — **RULED 2026-09-07, the
       owner: "the daemon also wants no SP."** So B: the daemon holds NO SoundPooling at all (the live `/c`
        showed it had quietly accumulated one — `SoundPooling>stock>…>Record id:8215c95f` on S; `excused`
         must be durable and default for a headless body, `Ra.g:1160` "a headless body has no taste"). It
          serves **from the library, through the materialise scratch** (`Heist_materialise_one` → a
           `RummageLib` holding the pressed lofi — exactly the path that just landed S→eed), never by pressing
            into `homes.pool`; `Ra_pool_fill_serve` must stop requiring a pool home. And the substrate-clean
             half the corpus already had and forgot: `Daemon_todo §5.2` (owner 2026-08-07) — a **serve-only
              declaration** ("I serve; do not open a radio at me"), a fact about oneself, not an inhibition
               held about another. See `Fallen_out_of_mind_todo §8`.

### ⚑⚑ 2026-09-05 (later) — THE FEATURE WAS DARK BY CONSTRUCTION: a pool card never had a `preview`

Four live gates fell (below) and the face still said **"N pooled · none playable yet"**. That sentence was
 not a transport symptom. It was literally true and it had been true of every pooled track ever landed, on
  every body, since the pool existed.

`Heist_catalog_land`'s pool branch stamps `title/artist/path/bytes/body_hash` on the pool %Record and
 **nothing that lets it play** — no `preview`, no `total`, no `%Preview,seq` chunk children. `Ra_dial_next`
  skips every record for which `preview > 0` is false. Both landing paths — the press (`Ra_press` v1) and
   the radio keep (`Radio_pool_catch` → `%Heist,into:pool`) — go through that one tail. So **nothing that
    ever entered a SoundPool could be dialled out of it.**

**How it was measured, and the method worth keeping.** eed's tab was answering intermittently and
 classifying `role:UNKNOWN`, so the tab was not the witness. The DAEMON is the other end of the same
  feature and it answers HTTP: `http://172.17.0.1:9099/c?token=<tok>&depth=9` → its own
   `%SoundPooling > stock` held **8 pressed records, every one with `preview` undefined**. When one end of
    a two-ended feature won't talk, the other end is a full witness — the code is the same code.

**Why no Book saw it.** A Book scene mints its pool source records by hand, without a stock pass, so they
 carry no `preview` either — there was nothing for a carry to carry, and the fixture that recorded a
  preview-less pool card recorded it as correct. Same disease as the four gates below, one layer deeper:
   **SP was tested as a model and never as a machine.**

**The fix (three edits that are ONE fix — never separate them):**
- `Ra_rec_previews_carry(card, rec)` (Ghost/M/Ra.g) — carries the head scalars + `%Preview` children from
   the source record onto the copy, called from `Heist_catalog_land`'s pool branch. Honest because a v1
    press and a plain keep land the ORIGINAL's bytes (the id coincides — that is exactly why
     `Ra_rec_pool` elides `of:`/`grade` for them) and an opus preview is a pure function of those bytes.
      **Declines a lofi rendition**: different bytes, so it needs its own encode, and until that exists an
       absent preview is the honest answer rather than someone else's waveform wearing its name.
- `Ra_pool_previews_heal` + `Ra_pool_source_rec` — the RETRO sweep (bounded 4 a pass, pure reads over
   records already standing in this world). A landing happens once, so without this everything pooled
    before the carry existed stays dark forever. Wired into `Ra_pool_fill_pump` **and into the dial's own
     pool rung** (`Radio_dial`) — the dial is the seam guaranteed to run the moment a listener asks for
      their pool. It also covers arrival order: a keep can land its bytes before the source mirror's own
       preview has finished crossing.
- `Swarm_protocol` skips `Preview`/`Stream` — **the pool shelf hangs on the %Identity, which DOES ride
   `.jamsend/account/<prepub>/toc.snap`**, and a Uint8Array in `.sc` is fine on the snap plane and FATAL at
    the storage/toc encoder. Without this skip the carry would break every account save.

**Then the rest of the same evening — three more organs, all in the owner's words:**

- **"empty" after every reload → the pool CATALOG was not durable.** `Swarm_restash_pools` carries the
   `%Pool` definitions + consent + budget, never the `stock` shelf; nothing re-censused `pool/`; the shelf's
    only durable home is the account snap, which a folderless tab has not got — and which, measured on the
     daemon, came back with the pool shelf EMPTY after a restart even with a folder. The files were the fact
      all along. `Ra_pool_resurrect` rebuilds the cards from `pool/` (bounded, no chunks) — from the Stoker's
       boot look (the one seam every body with a nav runs — the daemon's 8 came back), the dial's pool rung,
        and the pump.
- **"why can't you just get Story:Sounditron to take a resnap … as long as you have the relevant state
   snap-visible, which is what my griping about .c is all about."** The camera was blind to the pool
    (`Mine > stock` dontSnap; `%SoundPooling` on the Identity outside the Run). `Ra_pocket_mirror` keeps a
     `%Pocket` cell in w:Sounditron — `cards/ready/files/uncatalogued` + one `%pooled,id,title,preview,chunks,why`
      child per track — absent while nothing is pooled so poolless fixtures never move. **Anything we could
       ever want to keep an eye on should be there.** `Ra_pool_report` (also `runner_ask poke Ra_pool_report`)
        is the same facts as a console block; `Ra_pool_whys` the same facts as one line.
- **"some indications in the console about how each NEXT button click is going."** The dial's pool rung now
   says, per click: `📻 next [pool] ✓ Artist — Title (3 cards · 2 playable)` / `↻ replay …` /
    `✗ gave up — nothing the dial can play (3 cards · 0 playable · 3 no preview · 2 files on disk uncatalogued)`.
- **"there's no byte-lane because it's reusing Heist isn't it?"** — yes, and that was always the plan (§0.5:
   *the carry-out delegates to the existing Heist doer, mardir 'pool', no second lane*). `Ra_pool_fill_land`
    on `arrived` now mints a `%Heist,into:pool,seed:<of>,pub:<holder>,why:fill` keep — Radio_pool_catch's exact
     shape — and the Heist keep beat routes, pulls the %Body chunks over Repli and lands through
      `Heist_catalog_land`'s pool branch (where the preview carry lives). The reach stands with `why:heist
       <state>` until the pool card stands, then drops. `Siphon_pull` remains as MusuPoolFill's stand-in only
        (its world has no pier/Repli/relay; its lib IS local), gated by the same `fill_mw` override.

**2026-09-06 morning — the owner's "hardly anything overnight; what's owed?", and what the two live logs then said:**

- **eed's pool played, but "none from the daemon".** The log had it: `12 cards · 8 playable · 4 no preview`, and the four
   were exactly the daemon's real tracks. The carry LENDS a preview from a standing record with the same id; a track
    this body has never heard has none anywhere (a circulation mirror card is a catalog row — its chunks only cross
     when you stream it). Last rung: **the pool encodes its own preview from the file it holds** — `Ra_pool_previews_heal`
      now falls back to `Ra_stock_one` (the Stoker's per-file encoder) pointed at the pool shelf + `pool/` mount, one
       a pass, live only, only when the file is on disk; the card's path is put back pool-relative after (Ra_record_from
        stamps `base/path`). The 8 "playable" were the app's own `static/testsounds` fixtures.
- **Why the daemon never served, and why its pool held fixtures — both in ITS log.** `🛰☠ deliver: no Pier for pier_accept
   seq=938 from=631300e8 … DROPPED` every 30s for hours: Grink kept re-offering the handshake that would RESTORE the pier
    the daemon lost across a restart, and the daemon dropped it for want of the very pier it carried. Chicken and egg.
     `Peeroleum_deliver` now admits `pier_accept` pier-less exactly like `pier_hello` — it proves itself (Swarm_accept
      verifies the grant is theirs and FOR US, page key-bound; forged → rebuff). And `dig[idle] … base=testsounds
       picks=2 got=2` between real tours: the digger's three-base rotation always included testsounds and the φ-pick
        rewarded its yield. `Stoker_dig` drops it from the bases once a real base has ever yielded (live only; MusuStock's
         driven rotation untouched). The drop log is now one line per source per minute with a tally, not a scroll.
- **"LOCAL isn't in the source list."** The chooser was built from %Theirs crates only; `Radio_sources` now adds an
   `own:1` row when your own shelf has something playable, wired to `Radio_own_set` (a setter — the flip cannot serve
    a row). RadioFace renders it as ♪ LOCAL.
- **Excuse is a full lifecycle now:** serve (`Ra_pool_fill_verdict`/`_serve`), self-land (`Ra_pool_fill_land` drops stale
   arrivals), re-consent (`Ra_pool_start` refuses), and the report shows EXCUSED. Not yet fired on the daemon — its relay
    address answers nothing, even `ping`; `/stop` restarts don't clear it. Open.

- **The evict↔resurrect loop's real cause, midday:** `MountNav.bin_rm` called `nav.bin_read` (copy-paste,
   MountNav.svelte.ts:191) — every evict on the mount READ the file back and reported "removed".  eed's log with the
    self-encode in was `evicted 6 → recovered N from disk → encoded a preview → evicted 6 …` every pass.  Fixed to
     route `bin_rm`; the session-scoped `rw.c.pool_evicted` mark (resurrect skips it, a fresh landing clears it,
      `Ra_pool_off` clears all, the report says `N evicted but file lingering`) stays as belt-and-braces.
       MusuPoolBytes beat 4 had RECORDED the bug (`left_bytes=8118, rm_again:true`) — re-sworn with real removal.

- **The eviction bug is REAL-TESTED, not a live-only guess.** `Ra_quarter_diff` evicts anything not in the CURRENT sit-down goal, and the random pool draws its goal fresh from THIS SESSION's %Theirs mirrors — which rebuild one row at a time, so right after a reload a pooled track's own holder can be entirely absent from the candidate set with nothing about the track itself having changed. Fixed: a pooled id is re-added as its own ranking candidate before the goal is cut (Ra_pool_hash is a pure function of the id, so its rank never moves) — sediment only yields when a genuinely better-ranked arrival crowds it out, never merely because this session has not caught up. This is pure C-tree logic with **no live dependency** — MusuPoolRandom beat 5 proves it deterministically (Ra_pool_hash computed by hand: salt=1 ranks f4 < f3 < f2 < f1 < c1..c4 < f5 does NOT hold — f5 outranks all three, so it evicts exactly f2, the worst of the three, never f3/f4). The owner's 'shouldn't testing have caught that' was right: this bug was never live-only, nobody wrote the growing/thin-candidate scenario. Gated, declared, green.

**Owed:** a live walk of the keep road end-to-end (eed ← daemon) — the resurrect + carry + keep are each
 gated, the chain is not. And a folderless body's pool still has no durable CATALOG beyond the disk rebuild,
  which is fine as long as `pool/` is the fact.

**What `Ra_press` v1 still is:** `nav.bin_read` on the SOURCE record's path using the LOCAL nav. For a circulation fill whose `lib` is a peer's `%Theirs` mirror, that is a path which
  only exists on the peer's disk. `Ra_pool_fill_land`'s own header already admits it — *"the live byte-lane
   is the named owed seam"*. The reach lifecycle is built; the bytes it asks for have no wire under them.
    That is the next real piece, and it is a transport question, not a catalog one.

### ⚑ 2026-09-05 — THE LIVE WALK (eed → daemon), and the next move

**The arc:** every Book was green and nothing filled, because every gate was a *live-only* fact. Walked by
 Reach STATE on both ends (eed's mirror + the daemon's `/c?depth=9` tree), four silent gates fell, in order:
 1. `Swarm_reach_settle`/pump asked `Ra_pool_consent(w)` on the Swarm world → always 0. Now `Ra_pool_consent_of(ident)`.
 2. The friend hear-funnel never registered `reach`/`reach_done` (only the sibling station funnel heard them) —
    eed re-sent the same seqs every 5s for an hour and the daemon never dispatched one. Now registered.
 3. `Ra_pool_fill_homes` read `rw.c.ra_nav || null` (Book-only pin; siblings read `|| Crate_nav()`) — both live
    ends silently skipped serve/land. Now falls back like its siblings.
 4. The fill pump (serve+land) was gated on the BOOKER's consent, so a pure server never served. Now also runs
    on `station_up && Swarm_reach_serving(ident)` — a standing `serving` row is the authority for the serve half.
 Gated after each cut: SwarmBody 23 · MusuPoolFill 6 · MusuPoolRandom 4 · MusuPoolBytes 4 · MusuPoolRadio 6 ·
  SwarmReboot 5 · MusuHandoff 6 — all `ok_pct:1, caveat:0` (they can't see any of this; that is the lesson).

**Where it stands live (17:34):** eed books 25 wants → dispatches → the daemon hears, mints its pool home, presses
 → **refuses, named: `bin_read miss music/0 Cumbia/…mp3`.** The daemon's `/music` is empty on its host (boot log:
  *"no music the meander can reach under /music"*); its 31-record shelf is stash-restored, originals absent, so a
   press has nothing to read. The other six bookings target Grink (631300e8), offline. Consent/budget/compartment
    on eed are correct; the pool holds 1 record.

**Next move:** mount `/music` (with files) on the daemon host → `/stop?token=` restart → re-walk: expect the two
 daemon Reach rows `serving → arrived`, `reach_done` back to eed, `🏊 pool-fill: landed N` in eed's console.
 Then decide whether a source holding only ENCODED chunks (no original) should serve from them rather than
  press — today the design says press, so an original-less shelf can never be pooled from.
 ⚠ The account mirror is settle-driven; a landing does not rewrite it — read the far end's Reach rows instead.
 ⚠ **Re-dispatch reuses the SEQ** (seen in the daemon's docker stdout): eed re-sends a `booked` reach every 5s with the
  same seq, and the target answers `🛰⚠ reused-seq collision … re-acked, not re-dispatched`. So a reach dropped ONCE on
   the target (e.g. before its hear list knew `reach`) can never be re-heard until the target restarts — and a
    restart, not the hot-swap (`👻 reswap gen/S/Swarm.go` landed live), is what finally let the daemon hear. Either
     `Swarm_reach_dispatch` mints a fresh seq per re-send, or the target re-dispatches an idempotent kind on a reused
      seq. Also seen there: Grink (631300e8) IS live — pulsing the daemon — but the daemon holds no Pier for it.

✅ **LANDED 2026-09-05 — the unison is built** (owner: *"yeah. all good?"* — yes). One particle now holds the
 whole feature, on the live identity when `w` is the tab's radio world and on the world for a Book:
```
SoundPooling,pub:<me>,budget_mb=200
  Consent,at
  Pool,name,take,cap,salt,who,share
  Provisions > Want,of,do,why,pool,from
  stock,pub > Mag:shuffle > Cloud,page > Record,id,of,grade,path:pool/…
```
 - Mainkey **`SoundPooling`** (not the sketch's `SoundPool`): the compartments ARE underneath it now, which was
    the only objection to the -ing name. `%Pools` and `%SoundPile` are gone as mainkeys. ONE per owner — the
     probe ignores `pub` (a label, not a key), because a budget is a fact about the device.
 - The verbs (Ra.g): `Ra_pool_owner` (identity|world, the old Ra_pool_home body) · `Ra_pool_home` (PROBE,
    owner then world — the pre-hydration fallback kept) · `Ra_pool_home_mint` (a standing home anywhere wins,
     never split) · `Ra_pool_homes` (both, for drop/consent-take) · `Ra_pool_pub` · **`Ra_pool_provisions`** and
      **`Ra_pool_stock`** — the two probed READ seams every face now uses (PoolFace, RadioFace, ShuffleFace),
       so no face walks `w.o({SoundPile…})` or `w.o({Provisions})` any more. `Ra_home_pool(w, pub)` still mints
        the material shelf, under the home.
 - Stash pillar unchanged in shape: `Swarm_restash_pools` walks the home; `Swarm_pools_rehydrate` re-homes on
    `ident > SoundPooling,pub:<prepub>`.
 - ⚠ The `.g` trap that cost one compile: a loop variable named `o` is rewritten by the `.o()` sugar
    (`for (const o of [...])` → `w.o({of: 1})`). Never name a binding `o`.
 - Consequence 2 below (a declaration change does not bump the identity) is still TRUE and still owed.
 - §7.8 of Radio_circuit_todo was ruled the same day: SoundPooling is ALWAYS the one thing, only its backing
    varies (OPFS on a phone, the FSA folder on a laptop) — which this shape makes free.

*"lets move all those into unison? SoundPooling/Pool/* should have its scheme and content|state and
 everything it has?"* — yes, and it is worse than it looks. **SoundPooling lives in FOUR homes today:**

| part | where it lives now |
|---|---|
| the **declaration** | `%Identity > %Pools > %Pool,name,take,cap,salt,who,share` (`Ra_pool_home`) |
| **consent + budget** | `%Pools > %Consent,at` · `%Pools%budget_mb` |
| the **want-list** (its running state) | `w > %Provisions > %Want,of:<id>,do:press|pull|evict,why` — on the world floor |
| the **material** | `w > SoundPile,pub:<me> > stock,pub > Mag:shuffle > Cloud,page > Record,id,of,grade,path:pool/…` |

**The unison:**

```
SoundPool,pub:c0de,budget_mb=200          ← ONE home for the whole feature
  Consent,at:1788400000
  Pool,name:circulation,take:random,cap:12,salt:3,who:crew,share:50
  Pool,name:recent,take:recent,cap:50,share:50
  Provisions
    Want,of:9a3c…,do:press,why:took it — carried
  stock,pub:c0de
    Mag:shuffle > Cloud,page:N > Record,id,of,grade,path:pool/…
```

### Where it hangs is the whole decision — and the mechanics were checked, not assumed

**Hang it under `%Identity`.** Then the declaration keeps its account-snap home (the second durable home
 beside the Dexie stash) and `Swarm_restash_pools` walks it one level deeper, unchanged in shape.
The obvious fear — that pool churn now rewrites the whole account file on every press, inside the beliefs
 mutex — **does not happen**: Auto.svelte's account-write `mark` is built from `ident.version`, and
  `bump()` does NOT propagate upward (`TheX.bump_version` touches its own `serial_i` only), so a mint under
   `SoundPool > stock > Mag > Cloud` bumps that Cloud's X and nothing above it.

Two consequences, both to decide with open eyes:
1. **The pooled catalog would ride the account snap** — ~30KB at 200 tracks. Cheap, and arguably right: it
    is what is actually on this device. `dontSnap` on `stock` would prune it, at the cost of making the
     pool unreadable from a snap, which is the wrong trade for the one shelf a person might want to audit.
2. ⚠ **A latent bug this exposes, which is TRUE TODAY and not caused by the move**: a pool declaration
    change does not trigger an account write at all. Minting `%Pool` bumps `%Pools`' X, never the
     identity's, so the declaration only reaches disk when something ELSE bumps the identity. The stash
      pillar is doing all the real work; the account copy is incidental. Worth fixing (bump the identity on
       a declaration change) whether or not the unison happens.

### What it touches

`Ra_home_pool` · `Ra_pool_home` · every `Ra_pool_*` verb · `Ra_quarter`/`_diff`/`_serve` (the
 `%Provisions` home) · `Swarm_restash_pools`/`_pools_rehydrate` · SwarmReboot · PoolFace · and every pool
  fixture. **Bigger than the `Musu` rename sweep** ([[musu-prefix-rename-ruled]]: `MusuSelf`→`Mine`,
   `MusuThem`→`Theirs`, `MusuPool`→`SoundPile`) — all three landed 2026-09-04. Do them as ONE pass, since both rewrite the
    same fixtures — and note that once the feature IS one home, **`SoundPooling` becomes an honest name for
     it** (the objection to that name was only that a reader would look for the compartments underneath and
      not find them; here they are underneath).

**Ordering**: after `Radio_circuit_todo.md`'s heard circuit lands (in flight 2026-09-04), then the rename +
 unison as one sweep. See also that doc's §7.8: whether the pool should exist AT ALL on a device that has a
  folder — if the answer is no, this home only ever stands on a phone, which simplifies everything here.

---

## 0.1 THE DECISION (2026-09-03, the owner's — everything below is history or machinery)

**SoundPool is one sentence, and the sentence is the whole UI:**

> *SoundPool keeps rolling **[ 300 ] MB** of music in browser storage, sourced from **[ ] friends** (less
>  predictable) and **[x] crew** (your devices, see Door).*

Under it, the framing: *"just whether they want surprise music in their daily playlist."* And the reason the
 owner wants it at all: **the lofi transcode levels the volume** (verified: -14 LUFS, both serve paths).

**What the sentence means, in the machine (all built, all Book-green tonight):**
- **The number is the consent.** 0 = off and clean out (`Ra_pool_off`: the yes taken back, budget 0, every
   compartment dropped, every pooled card AND its file gone — `nav.bin_rm` → `Ra_pool_unfile`). A number =
    the yes (`Ra_pool_start(w, mb, now, who)`): a `%Consent` and `budget_mb` on the %Pools shelf, and ONE
     compartment, `rolling`, `take:'random'`, at 100% of the budget. Caps are derived (~4 MB a lofi track),
      never set by hand. Nothing that touches bytes — the catch, the steward's press/evict, the fills — runs
       without the yes; the yes rides the pools pillar so a phone is asked once and never wakes up pooling.
- **The two checkboxes are `who`**: friends (mirrors of non-crew sharers — new to me), crew (mirrors of
   my own crew — my collection spread across my devices), both, or neither. `Ra_pool_sources` marks each
    holder crew-or-not off /Crew; `Ra_quarter_goal_pools` filters on it.
- **"Keep what I hear" is negated** (you already heard it): random from everyone is the default draw, a
   clockless shuffle re-drawn per salt. The `take:'radio'` catch stays built and gated, not offered.
- **♥ is the heist button.** `Radio_like` stamps `take` on the track's Card in `Mag:heard` (`Heard_take`,
   `Ghost/M/Heard.g:216`) — durable the instant it lands, and mints nothing else; with a share mounted the
    share beat (`Heard_haul_beat`) turns the oldest take per holder into one live keep, pulling in the
     background (no form, no glass seize); without one the take stands for the crew or the pool to live
      out. (Before 2026-09-04 this minted a `%Like` under a `%Jam` ledger and a `%Heist` right here — both
       gone, see `Radio_circuit_todo.md`.) A pool keep starts itself, takes ONE track not the album,
        forced lofi (`Heist_keep_pool_go`).
- **The seam is one scalar**: `into:'pool'` on the keep → `Heist_keep_mardir` → the same Heist transport and
   the same landing tail (`Heist_catalog_land`'s pool branch). No second lane.

**Gates:** MusuPoolRadio (6 beats, 11 sworn — the catch, the guards, the goal, the one sentence, the who,
 off), MusuPoolBytes (4 beats — a keep's bytes land under pool/ and off takes them back), MusuPoolRandom,
  MusuPoolFill, SwarmReboot (the pools pillar). `Ra_pool_defs` now lists a 0-share pool (declared but inert).

**What is deliberately NOT in the sentence, and why:**
- Several compartments with fractions "in a gang" (shares, `Ra_pool_share_set`, `Ra_pool_caps_apply`) — built
   and Book-proven, then set aside: the fair-share question it raises (an unfillable pool must not hold the
    others back, yet should reclaim its space one day — water-filling) is real and unsolved, and one pool makes
     it moot. It comes back on the day of *"20% chill, for your entire music collection"* — composition by
      specifics of a remote collection.
- Knobs (steward/fills/sit-down), want lists, ids on the face — internals. The yes IS the fills switch.

**Comms on the Radio are minimal by ruling** (owner 2026-09-03: "SOUNDPOOL / setup / is empty — just the most minimal effective comms"): the chip is the word; under it one word of state — `setup` (a button to the cell) or `empty`; the dial's pool note is `empty`. A table of the app's wordier speeches is in `Speeches_todo.md` for the owner to chop.

⚠ **Not understood yet, do not "fix"**: a Sounditron mounts BOTH UI:Vyto and UI:Cello (Otro mounts every registered UI; "show guts" reveals the Vyto under the Cello). Whether that is a cost, a design, or an accident is an open question — investigate before touching.

**THE LIVE WALK (the one thing only the owner can do — once, after the overnight pass):**
1. On the Cave: open the SoundPool cell (the `setup` word under SOUNDPOOL on the Radio), type 300, tick crew. Expect one console line: `🏊 SoundPool keeps rolling 300 MB from crew`.
2. Listen to the Captain for a few tracks. Expect `🏊 steward: booked N circulation fill(s)` at a track advance, then `⇊` lines as keeps pull, then `🏊` cards landing. If nothing after ~2 min: paste the console.
3. Press ♥ on a track. Expect `♥ liked … — no share here; the crew or the pool lives it out` on a Cave, or `— heisting in the background` on a body with a share.
4. Flip the Radio source to SOUNDPOOL. Expect play from pool copies (levelled). If it says `empty`, step 2 did not land — paste the console.
5. Reload the Cave. The sentence must still read 300 / crew (the pillar). Type 0. Expect the off line with pools/cards/files counts and the pool/ folder gone.

See also **** — likes → heists → batch per holder, what berth is actually for, and the `take:'recent'` acquisitions input the owner asked for.

See also **`Acquisition_todo.md`** — likes → heists → batch per holder, what berth is actually for (three caches, one of them the music-tree Census), and the `take:'recent'` acquisitions input.

**Next (in order):** the live walk on the Cave (declare 300 MB from crew, listen, watch `🏊` lines, flip the
 source chip to pool, hear it play offline); the "later" half of the Like (a Cave with a disk reading the
  crew's Likes and hauling them); "how full is it" on the sentence; the aim on the source chip as the day-one
   "point it places"; the Radio busy-loop's cousin, Stoker_churn resetting on every dry pass.

## 0.2 THE RADIO CRUX (owner, 2026-09-03 night — kept verbatim-ish; the design in §0 came out of it)

- **The unit of consent is SPACE, not a track count.** "Aim for 3GB… or less than 1/3rd of what Chrome thinks
   it can use." The first visit sets a byte budget; the same control must go back to **0 = off, and clean it
    all out**. Explained in **20 words max** — "splash-with-simple-buttons", and the splash PERSISTS as the
     top of the Pooling UI proper, it is not a one-time modal. Reached by a **separate button**, never by
      pressing the source switcher again.
- **"Keep what I hear" is negated.** You already heard it; the pool exists to give you what you have NOT.
   So the default is **random**, on by default once consented — "take another random bunch of Records".
- **The one real decision to present**: should the pool be (a) **random friends' tracks, to hear for the first
   time**, (b) **sourced from your Crew** — your own collection, possibly spread across several devices —
    or (c) **both**. That is the whole setup UI: budget + this choice.
- **There is no LIKE button — it is download or nothing.** The shape it wants: a Like is a DURABLE INTENT on
   the ledger (`%Like` under `%Jam`, which the taste tally already reads). If the liker has FSA, the Heist
    happens on the spot into the library (lossless). If not — a Captain "with no FSA but an ear for the
     music" — it happens LATER, when a Cave of the crew looks for things to do with ITS FSA. The crew's
      disk fulfils the crew's ear. **Built the same night**: the ⇊ button IS the ♥ now — `Radio_like` mints the
       Like and, with a share mounted, flips the same keep straight to pulling (dose off, no form, no glass
        seize — the Haul cell is a folded row while it lands); without a share the Like stands on the ledger.
         Owed: the "later" half — a Cave with a disk reading the crew's Likes and hauling them. (`%Like`
          and the `%Jam` ledger were deleted entire 2026-09-04; `Radio_like` now stamps `take` on
           `Mag:heard`'s Card instead — see `Radio_circuit_todo.md`. The "later" half is still owed.)

### (origin: the OPFS pocket cache — from ambient press to pool-first radio)

**What SoundPooling is.** When you stream a friend's track over Radio today, chunks land in
 memory and are immediately played — nothing persists past the session. SoundPooling is the
  act of pressing those played bytes (or deliberately siphoning chosen tracks) into your
   phone's OPFS so they are there OFFLINE: small LOFI copies, replayable without a peer,
    tradable phone-to-phone. The pool is a cache with a ledger — not a second library.

**THE HEIST/POOL BOUNDARY (owner, 2026-09-02) — two different acts, do not conflate:**
 - **Heist** = a CONCISE, usually-LOSSLESS acquisition between two different IDENTITIES (keeps a whole
    album together — a deliberate, structured grab). See [[ferry-cave-model]] for identity terms.
 - **SoundPooling** = a LIQUID approach to music piracy: lofi, casual, ambient, expendable — music
    kept MOVING and filling space, not a curated transaction.
 They share the Heist byte-DOER (§0.5: a pool Reach delegates carry-out to `Heist_materialise_one`),
  but they are opposite in DIGNITY — lossless-album-per-Identity vs liquid-lofi-circulation. The
   boundary law: bytes+doing belong to Heist/Repli; standing intent belongs to Reach; the POOL is the
    liquid destination, the LIBRARY is the lossless one.

**THE FORMULAS ARE THE CONTROL SURFACE (owner, 2026-09-02).** SoundPooling's character is DIALLED by
 the two formula sites in `Ghost/M/Ra.g`, and these are what we tune (not the plumbing): (1) the taste
  score, now `take×3 + keep×2 + mire×1` (`Ra_quarter_tally` ~1060, delegating to `Heard_tally`,
   `Ghost/M/Heard.g:290` — was `likes×3 + grabs×2 + spins×1` before 2026-09-04), (2) the `%Pool`
    composition + take-policies + declaration-order priority (`Ra_pool_define`/`Ra_quarter_goal_pools`
     ~1071–1309).
    ⚠ **WATCH THE HEARD SCHEMA (owner's explicit ask, formerly "the Jam schema"):** the taste score
     reads `take`/`keep`/`mire` off `%Card` rows under `Mag:heard` — that schema is LOAD-BEARING for
      the whole economy; a drift there silently changes what gets pooled. `Jam.g` and its `%Spin`/
       `%Like`/`%Grab` events under `%Jam` sessions were deleted entire 2026-09-04 — see
        `Radio_circuit_todo.md`. Any Heard-schema change must be checked against `Ra_quarter_tally`'s
         reads.

**What already exists** (audited 2026-08-28 / Portability_todo §0 §3):
- `Ghost/M/Ra.g` — `Ra_press` (v1 byte-copy, v2 ogg128), `Ra_quarter` (steward goal/diff),
   `Ra_quarter_serve` (dispose loop: press + evict), `Ra_rec_pool` (catalog door), `Ra_upgrade_scan`
    (Cave upgrade queue). All DORMANT — Book-proven (MusuPress/MusuQuarter/MusuSteward/MusuSmuggle),
     no live caller anywhere.
- `Ghost/M/Siphon.g` — the DELIBERATE SoundPool act: `Siphon_pull`, `Siphon_tag_def/apply/unapply`,
   `Siphon_playlist`. Built 2026-08-28 (see Siphon_todo.md). Its proposed P2 connect-up seam (the
    RadioFace source-chip becoming local|pool|friend) names `Radio_source_next(n)` which does not exist.
- `src/lib/O/Housing.svelte.ts` `Wormhole_mount_pool` — the `pool/…` OPFS mount stands; a path like
   `pool/A/B/track.flac` resolves to OPFS exactly as `music/A/B/track.flac` resolves to FSA.
- `Ghost/M/Heist.g` `Heist_catalog_land` — ONE landing door for every arriving record: its pool branch
   (behind `Heist_is_pool`) fires when `mardir='pool'` + `lofi:1` + `body_hash`. Both triggers are unlit
    in live flow today. The branch is proven inert.

**The live wiring gap (the load-bearing open seam):** the press economy is model-complete. What is
 missing is the DRIVER — a live tick that hands `Ra_quarter_serve` the phone's pool nav, a lib (the
  streaming source), the pool shelf, and a cap. The `lib` mapping for a streaming phone (press what you
   stream vs press from a held library) is the delicate §3/§4 question Portability_todo holds open.
    Do NOT wire blind; the Siphon's explicit-lib choice was exactly what kept Siphon_todo out of that area.

---

## 0.7 Where to start, and the arc (the 2026-08 front, kept)

**The destination.** Stream a friend's track; a small LOFI copy quietly lands on your phone.
 Next session, no friend online: the radio plays from the pool. Two phones meet: they swap
  pool material without a Cave. A Cave comes online: it fills pool copies out into Originals.
   The pool is the PEOPLE'S music — expendable, portable, honest about what it is.

**LANDED 2026-08-30 (this session — the ambient economy + its glass):**
- **Pools of defined size** (Ra.g → Ra.go): `Ra_pool_define(w,name,take,cap)` + `Ra_pool_defs` +
   `Ra_quarter_goal_pools` — the goal composes from `%Pool,name,take,cap` compartments (declaration
    order = priority, dedup across pools); take-policies `taste|liked|kept|latest`, all clockless.
     No %Pool declared = the old single anonymous goal (byte-identical, gate stayed green).
- **The source chip + pool rung** (Radio.g → Radio.go): `Radio_source_next(n)` cycles `'' ⇄ 'pool'`
   on `%Radio,source`; `Radio_dial_pool_local` is the SoundPool dial rung (own OPFS shelf via
    `Ra_home_pool`); `Radio_dial` obeys `source==='pool'` EXCLUSIVELY.  RadioFace's provenance badge
     is now the tappable source chip (P2 applied).
- **The ambient steward occasion**: `Radio_autopress(w,radio)` fires at a track advance, DEFAULT-OFF
   behind `top.c.pool_steward` (+`pool_steward_cap`, default 24), humdinger-gated, own-library-only
    (the §3/§4 lib-mapping tripwire respected — a shareless phone still uses the explicit Siphon).
- **The glass** (ShuffleFace.svelte): pool-mode shows YOUR pocket copies (probe-first `Ra_home_pool`),
   plus the steward want-list "what your phone wants next and why" grouped by pool compartment (§5.4).
- **Siphonation is a real gate** now (P1 registered + P3 recorded live, 6/6).
- **The pool economy Books are gates now** — MusuPress / MusuQuarter / MusuSteward / MusuSmuggle
  were authored-but-never-recorded (no wormhole dir); all four recorded live + verified green in
  check mode (each %see-asserted, single-beat).  The press/steward/upgrade model is now regression-
  fenced, not just smoke-green.
- **P1 registered**: Siphon.g + Siphonation.g in LiesLies CREDULER_GHOSTS.

**Owner-testable NOW (reload both tabs for the 388834c+ build):** tap the source chip under the
 player → it flips to "♪ SOUNDPOOL"; the ShuffleFace shows your pool (empty until pressed) + the
  steward's want-list.  Flip `H.top_House().c.pool_steward = 1` on a Cave/FSA tab and let a track
   advance → `🏊 steward: pressed N` presses `%Record,path:pool/…` rows you can snap.

**LANDED 2026-09-03 — the FIRST LIVE SOUNDPOOLING INCREMENT: the pool-fill reach, Book-gated.**
 The §0.5 realisation made real: a Captain's pool fills FROM its crew Cave by BOOKING, not calling.
- **The booking seam** — `Ra_pool_fill_book(w, ident, origId)` (Ghost/M/Ra.g, POOL-FILL REACH region):
   books `%Reach,to:Cave,of:<id>,for:serve` toward the rostered crew Cave (role-addressed so it
    survives re-keying; no Cave on the roster → no intent faked; idempotent; stands while away).
- **The live doer binding** (Reach_todo §0 "still owed" — now bound for `for:serve`): `Swarm_reach_pump`
   invokes `Ra_pool_fill_pump` (knob-gated `w.c.reach_on`, default-off) → `Ra_pool_fill_serve` presses
    the asked track from the Cave's OWN library into its own pool (`Siphon_pull` → `Ra_press` v1 →
     `Heist_catalog_land` — the one door; the §3/§4 lib tripwire honoured) and answers the sync
      tri-state verdict (`Ra_pool_fill_verdict`: arrived | not-yet | refused,'not_in_library'); then
       reports terminals once and graduates.  Foreign `for:` verbs return FALSY (left for their own
        doer — never refused by this layer).
- **The landing** — `Ra_pool_fill_land`: an outbound fill acked 'arrived' siphons the artifact out of
   the crew mirror into MY pool through the same one door (the pool branch lights, byte-faithful,
    body_hash); no mirror / no readable nav → the reach STANDS 'arrived' as visible awaiting-transport
     state, never a fake landing.
- **Book-gated** — MusuPoolFill (Ghost/Story/Heistation.g, 6 beats, recorded live, 2× green, 4 %see):
   book → road → live-doer serve → ack → byte-faithful pool %Record on the Captain → graduate — plus
    the honest refusal receipt standing on both sides.
- **What stays live-only (the named owed seam):** the real cross-device BYTE transport.  Live, the
   Captain's crew mirror has no byte-readable nav yet (the Repli/Mag lane — Reach_todo's "the Mag is
    what travels"), so a live fill today walks the whole reach + presses the artifact CAVE-side and
     the Captain sees 'arrived'; the Captain-side OPFS landing runs the moment a mirror nav stands.
      The booking GESTURE (where in the glass a fill is born) also stays owner-gated (Reach_todo §0).

**THE START (owner 2026-09-03: "it needs a lot of Book testing it moving noise around, unit testing style…
 and a quick UI for resnapping and seeking to the SoundPooling datastructure") — the ladder, then the glass:**

*The seek UI is LANDED (Storui.svelte):* the 📸 resnap popup and the main diff header carry **🏊 pool** and
 **🏴 crew** seek buttons — each press jumps the diff body to the NEXT line naming that structure (pool
  `%Record,path:pool/`, `%Pool,name`, `%Reach`, steward/siphon/pocket/trove; or /Crew, Grant:Crew, %Body,
   %Pier), highlights it, and says `pool 2/7`. Pure DOM over the rendered rows; scoped to whichever diff body
    the button lives in. Resnap a step, press 🏊, watch the noise move.

*The noise ladder — one Book per move, single-beat where possible, ONE %see each, seeded (no Date.now /
 Math.random on the Book path), noise = generated PCM under the Book's marrauding root (the Siphonation /
  MusuPress idiom). Existing gates in [brackets]; NEW ones are the work:*
1. [MusuPress] press one own-library track → a pool `%Record` (lofi v1, body_hash).
2. [MusuQuarter / MusuSteward] the goal composes from `%Pool` compartments; the steward wants the right next.
3. [MusuPoolFill] Captain books `%Reach,for:serve` → Cave serves from its own library → 'arrived' + refusal receipt.
4. **MusuPoolBytes** — THE OWED LANE: the served artifact's BYTES cross to the Captain's OPFS (the "Mag travels"
   transport over the crew mirror / Repli lane). Today's fill ends Cave-side with 'arrived' standing; this Book
    is red until bytes land Captain-side (`%Record,path:pool/…` with the same body_hash on BOTH identities).
     Author it first — it is the Book that forces the transport to exist.
5. **MusuPoolSwap** — Flow 3, phone↔phone: two FRIENDS (no crew), A holds a pool copy, B books a reach for it,
   A serves it from its POOL (not its library — the pool is the people's music), B's pool gains it. The
    tripwire: a shareless phone still serves pool copies.
6. **MusuPoolEvict** — cap + take policy: fill past `%Pool cap` → the lowest-priority compartment's oldest
   copy evicts; declaration order = priority; `taste|liked|kept|latest` each proven by one arrangement.
7. **MusuPoolRadio** — `%Radio,source:pool` with no friend online dials from the pool; source '' ignores it.
8. **MusuPoolUpgrade** — a Cave online fills a lofi pool copy out into an Original (§2.5 queue): pool → Originals,
   the copy retired, the Original wearing the pool's provenance.
9. **MusuPoolDaemon** — the same ceremony with the daemon as the Cave (Crew_todo §0.3): a headless crew member
   serving reaches while the phone sleeps. Needs the %Ferry-only ceremony state (Crew_todo §0.0 "half-spined").
Each: Heistation.g (the Musu* home), recorded on the LIVE runner, wormhole dir committed with toc + snaps.
 Verify a fill by `runner_ask snap <n>` + the 🏊 seek, never by log lines.

**A BOOKING NOW SURVIVES A RELOAD (2026-09-03).** `%Reach` became the sixth stash pillar
 (`Swarm_restash_reaches` + `Swarm_reaches_rehydrate`, gated by the SwarmReboot Book). Until then a
  standing booking lived only in the account snap — which a PHONE never writes (no folder ⇒ no nav), so
   every booked fill died at the next boot and "book it and walk away" was false on exactly the device
    SoundPooling is for. Terminal reaches are deliberately NOT carried: a settled fill is history.

**LANDED 2026-09-03 NIGHT — THE RANDOM POOL, POOL CRUD, THE POOL CELL (owner: "take SoundPooling all the way
 through CRUD if you like, of Pools, start with one that just acquires random whole LOFI tracks from all
  Piers|Crewmates" · "perhaps just another cell when there's any Crew").**
- **`take:random`** (Ra.g `Ra_quarter_goal_pools(shelf, pools, sources)`): the CIRCULATION fill. Draws from
   `Ra_pool_sources(w)` — every %Theirs mirror's stock shelf (a crate stands only for a body that shared with
    me, so crew and friends alike) — in a CLOCKLESS shuffle: `Ra_pool_hash` (FNV-1a over `name:salt:id`) orders
     the draw, so it is the same every sit-down and in every fixture; `%Pool,salt` is the human's "shuffle again".
      Each want names its holder (`Want,from:<name>`; the goal row carries `from`).
- **The bridge** `Ra_pool_fill_wants(w, ident)`: every pull-want that names a holder books `%Reach,to:<holder>,
   of,for:serve` (`Ra_pool_fill_book(w, ident, id, to)` — a ROLE target must stand on my roster; a NAMED holder is
    the address itself). Declaring the pool IS the consent. Live: `Radio_pool_steward` passes the sources and,
     under `w.c.reach_on`, books the fills. The reach road/report/dispatch now admit a **Music-granted FRIEND** as
      they admit kin (the people's music — a shareless phone still serves pool copies); a stranger is refused.
- **CRUD**: `Ra_pool_define` (C+U, resize in place) · `Ra_pool_defs` (R, declaration order) · `Ra_pool_drop` (D; its
   wants fall out at the next sit-down, pooled copies become evict wants). `Ra_pool_home(w)`: on the LIVE radio
    world the %Pools shelf lives on the live self's IDENTITY (the account snap carries it; a phone: OWED a pools
     stash pillar — the seventh — until then a folderless device loses its pool definitions at reload); a Book /
      lone world keeps them on the world.
- **The Pool cell** (`%Pooling,face:'Pooling'` on the radio world, `PoolFace.svelte`, grappled on live tabs once
   anyone shares with me — humdinger-gated so every Sounditron fixture stays byte-identical): the compartments
    (name · take · cap · wanted · 🔀 reshuffle · ✕), the wants per pool with their holders, "＋ random from
     everyone" / "＋ what I liked" presets, a define form, and the two knobs (steward · fills) + "sit down".
- **Gate: MusuPoolRandom** (Heistation.g, 4 beats, 5 sworn): 8 reachable from 2 holders → 3 pull-wants naming
   holders, never my own shelf · the same draw twice, a new salt a new draw · the wants book toward their
    holders (crewmate at its body name, friend at its pier), idempotent · the friend road admits Cap, refuses a
     stranger, reports back over the pier · resize / list / drop / fall back to the anonymous pool.
- **A REVIEW PASS RAN OVER IT THE SAME NIGHT** (an opus agent, code-read). Fixed: the landing read only the
   crew Cave's mirror, so a FRIEND-served circulation fill could never land (`Ra_pool_fill_from` now resolves
    the holder off the reach's `to:`, probe-first — on a phone with friends and no Cave every fill used to
     stall at 'arrived'); a re-used `%Want` kept a stale `pool`/`from` (both are deleted when the fresh diff
      row has none); `Ra_pool_defs`/`_drop` now read and drop from BOTH homes, so a pool minted before the
       live self hydrated is not orphaned on the world; bookings are BUDGETED (4 per pass) so a cap-12 pool
        cannot crowd the shared %Reach cap; a holder name must look like a key-derived prepub, so a Repli
         placeholder ('Crowd') can no longer vivify a station %Pier; PoolFace probes the pool home instead of
          minting it in a render effect, and its "sit down" cannot latch the steward on.
   ✅ **CLOSED 2026-09-08 night — `by` is now bound to the frame's actual sender.** `by` is a CLAIM carried
    in the frame body; the voucher gate above the road proves the sender is *someone we trust* and proves
     nothing about *who they said they were*, so a sealed peer could book work on me in a SIBLING's name and
      the ledger would record the sibling as the booker. The wire lane (`Swarm.g:1582`) now passes
       `frame.header.from` as an optional 4th argument to `Swarm_reach_road`, which refuses when claim and
        sender disagree, naming both: `⨳🫱⚠ a reach CLAIMED to be from … but arrived from … — ignored`.
    **The full-name demand applies to BOTH sides.** `same()` matches when either string prefixes the other,
     so a one-character `from` would wave everything through — the identical footgun the friend arm was
      hardened against in the line above, trivially reintroduced on the other side of the same compare.
       Both `by` and `from` must look like a key-derived prepub before the compare is even attempted.
    **ADDITIVE BY CONSTRUCTION, and measured.** The mail lane (`Swarm_pump`) and every hand-fed Book frame
     pass no sender and keep exactly today's behaviour. Gate: SwarmBody 23/23, MusuPoolFill 6/6,
      MusuPoolRandom 5/5, MusuPoolBytes 5/5, MusuPoolRadio 6/6 — all caveat 0, and the refusal line appears
       in **none** of them, including MusuPoolFill which hand-feeds `Swarm_reach_road` directly. Unit:
        ReachTerminal 5/5, MembershipDoor 7/7, TwoFounder 1/1.
    ⚑ Still owed on this shape: `reach_done` is guarded differently (`Swarm_reach_vouched`, a real signature
     check) and was already sound; `runner_ask` asks remain unsigned entirely (Social_demarcation §3.4.3).
- **Gate RECORDED + check-green** (2026-09-03 night): MusuPoolRandom 4 beats, 5/5 sworn, caveat 0 on a second
   run against its own fixtures.
- ✅ **THE POOLS STASH PILLAR (the seventh) LANDED** the same night: `Swarm_restash_pools` +
   `Swarm_pools_rehydrate`, in `Swarm_restash_all` and the `Swarm_station_up` ladder. A %Pool is a
    DECLARATION and it homed on the identity, which rides the account snap — and a phone never writes one,
     so every compartment a phone declared died at its next boot and the circulation stream stopped
      silently on exactly the device this is for. Gated by SwarmReboot (declare two → wipe → rehydrate →
       swear them back IN DECLARATION ORDER, since order is priority, with policy, cap and salt intact).
- NEXT on this thread: **MusuPoolBytes** (the byte lane — still the Book that forces the transport to exist);
   the pools stash pillar; the location pool (`take:dir`, Crew_todo §0 A½.3); the Pool cell on a real phone.

**What to get on with next (fresh session reads here):**
1. **Wire the ambient steward** — `Radio_source_next(n)` + `Radio_autopress` (the press driver that
    lights `Ra_quarter_serve` at a natural play-session seam). This is the ambient economy proper
     and the one thing Siphon_todo deliberately deferred. Start here only after the §3/§4 lib
      question is resolved (read Portability_todo §3 first; do not guess the lib mapping).
2. **Record the pending Books** — MusuPress/MusuSteward/MusuSmuggle/MusuQuarter are smoke-green but
    unrecorded. These are Lane-A recording passes (runner_ask.mjs), not code work.
3. **Apply Siphon_todo P1** — register Siphon.g + Siphonation.g with the Creduler (LiesLies.svelte),
    then P3 (the recording pass for Siphonation).
4. **Apply Siphon_todo P2** — the RadioFace source chip — only after `Radio_source_next` exists (§4 below).
5. **The pool-source Radio rung** — the dial consulting pool records when `sc.source === 'pool'`.
6. **Phone↔phone exchange (Flow 3)** — a heist whose mardir is `'pool'`, destination OPFS.

**The bet to hold.** Pool↔pool exchange between phones may be the MAJORITY way music actually
 moves (Portability_todo §0). Design pool paths as PRIMARY, not as a nicety on top of the library.

**THE ECONOMY'S CHARACTER (owner, 2026-09-02) — two fills, and a gift-shaped transaction.**
 *"Not just 'stream → copy lands' — you have to LIKE it, I think? but also another bunch of stuff
  comes across whether you like it or not, just because we want to fill up the space and keep
   things moving. That's a new concept for software — everything has been paywall and static and
    transaction-driven. We want to give the user transactions like 'enjoy what you can of all this
     music' that then affect how we SoundPool for them later. And it's likely how they keep random
      music on their phone from their computer as well."*
 Unpacked, this rules the press economy's shape:
 - **Two fills, distinct in dignity:** the CHOSEN fill (liked/taste — tracks you engaged with) and
    the **CIRCULATION fill** (unchosen — music that arrives to fill spare space and keep the music
     MOVING through the mesh; expendable by design, first-evicted, no ask). Circulation is not a
      cache-miss optimisation — it is the point: the pool is how music travels.
 - **The transaction is a GIFT with a feedback loop, not a purchase:** "enjoy what you can of all
    this" (the Music grant already has this shape) — and what you then PLAY/LIKE out of the
     circulation stream shapes what gets pooled for you next (circulation → engagement → the taste
      compartment). Anti-paywall, anti-static: the ledger records enjoyment, not entitlement.
 - **Same machinery, one mapping (sketch):** %Pool compartments already carry take-policies and
    declaration-order priority — a `liked`/`taste` compartment (high priority, kept) beside a
     `circulation` compartment (fills remaining cap, evict-first, generous take); engagement
      GRADUATES a track from circulation into taste. No new machinery smell — a policy expression
       over `Ra_pool_define`.
 - **The everyday corollary:** Cave→Captain fill (Flow 4) IS the circulation stream between your
    own bodies — "random music on their phone from their computer," unasked, space-permitting.

---

## 0.5 THE REACH CHAPTER (2026-09-01) — the cross-body procedure layer this doc was hand-rolling

*(Reconciliation note: a near-duplicate doc for the multi-body music environment was drafted this day
 before this one was found, then FOLDED IN HERE and removed — one topic, one todo. They COMPLEMENT (see
  below); the generic cross-body primitive lives in `Reach_todo.md`.)*

**They do not conflict — they are two mechanisms filling ONE pool, plus the surface over both:**
 - **PRESS** (this doc, §3–§4.2) — the pool fills PASSIVELY: bytes that stream through you are pressed to
    OPFS; the ambient steward + Siphon. "What flows through me sticks."
 - **REACH** (`Reach_todo`, LANDED — SwarmBody beats 10–14) — the pool fills ACTIVELY: a body BOOKS a
    durable, addressed intent ("get me this here") that stands as legible matter, routes off the family
     charter, survives the target being offline (settles on the presence edge), and drops when served.

**The load-bearing realisation: Flow 3 (§4.3, phone↔phone) and Flow 4 (§4.4, Cave→Captain) ARE reaches.**
 Both are "move pool material from one body/peer to another, whenever they overlap." §4.4 even names the
  hand-rolled version — "steward occasions: Cave came online / library grew / Captain pool is thin … the
   daemon's digger tour→rest→tour." That per-flow occasion+resume logic is EXACTLY the Reach settle loop
    (`Swarm_reach_settle`, the 60s trickle, presence-edge re-dispatch). So:
     - a pool Heist to another body becomes `%Reach,of:<content-id>,to:<body|friend>,for:serve` — the
        booking STANDS, dispatches when reachable, and the carry-out DELEGATES to the existing Heist doer
         (`Heist_materialise_one`, `mardir='pool'`, the §4.3 landing shape — UNCHANGED). Reach adds the
          durability + addressing + offline-tolerance; the byte-transport + landing stay as they are.
     - the "Captain pool is thin → fill it" occasion becomes a reach the Captain BOOKS (or the Cave books
        on the Captain's behalf), instead of a bespoke daemon occasion per flow.
   The measure (Homethink §4): Reach REMOVES the per-flow occasion/resume machinery, replacing it with one
    primitive Flow 3/Flow 4 both ride. **Do NOT rip out the flows yet** — bind them to Reach after the
     live doer-binding proves (Reach_todo §0 "still owed"), same isolation-first discipline as everything.

**§5.4 "Door — pool legibility (future)" is now data-ready.** That deferred pool-legibility surface is the
 **cells** the owner named ("bunch of new cells to make up"), and their DATA landed this day:
  - **`%Organ`** (SwarmBody beat 14) — a body describing the organ it grows: `pocket` (ready set) vs
     `trove` (collection), as quantities on its own `%Body` row. `Swarm_organ_take` / `Swarm_organ_of`.
      This is the pocket/trove readout §5.4 + the Organ cell want. (Cross-body organ visibility — the
       phone seeing the laptop's trove — is the next data brick: organ rides the charter mile like the
        family grants do.)
  - **the crew read** (`Swarm_reach_crew`, beat 13) — the standing reaches in one legible glance, tallied
     by state. The Crew cell's data.
  - **the cells** (Crew · Pool · Organ) — belly cells alongside Door/Radio/Link, reading the above; the
     Pool cell's "pull here" gesture calls `Swarm_reach_book`. Svelte/humdinger → un-Book-provable, so
      built WITH the owner at a tab (the standing law); the data beneath is Book-gated and safe.

**So the arc, unified:** the pool is filled by PRESS (passive) and REACH (active, cross-body); the cells
 make it legible and drivable; pool-first radio (§0 LANDED) plays it back. Press and pool-first radio are
  the owner-testable NOW; Reach + cells are the new frontier this chapter opens.

## 1. What Radio does today and where SoundPooling plugs in

**The dial ladder** (Radio_dial, `Ghost/M/Radio.g`): friend-first by default (`Radio_dial_pool`
 walks `%Theirs` mirrors), falls through to own stock only when friend pool dry OR listener
  flipped `radio.sc.own`. The dial reads `radio.c.heard` (heard-this-sitting) to avoid repeats.
   `Radio_pool_census` counts friends/known/playable/fresh honestly — the ShuffleFace reads these
    same pools visually (one pip per reachable %Record, fill = preview fraction landed).

**What the pool IS in Radio terms today:** the "pool" Radio uses is the IN-MEMORY mirror of friends'
 stocks (`%Theirs` shelves). That is the radio-pool / shuffle-pool — a volatile runtime thing.
  The SoundPool is DIFFERENT: a durable OPFS store of pressed copies. These two uses of "pool" must
   be held clearly separate. Going forward:
- **Radio-pool / shuffle pool** = friend-mirror records in `%Theirs`, volatile, play-over-wire.
- **SoundPool** = the OPFS `pool/…` shelf, durable, play-offline.

**Where SoundPooling plugs in:** a third source rung between "friends" and "own":

```
dial ladder:
  1. friends (Theirs mirrors, live wire)        ← today: default
  2. SoundPool  (OPFS pool shelf, offline-ok)     ← NEW RUNG: sc.source === 'pool'
  3. own stock  (local library, sc.source === '' + sc.own)  ← today: explicit toggle
```

The source selector (`sc.source` on the %Radio particle) is already sketched in Siphon_todo P2.

---

## 2. The C-particles involved

### 2.1 The pool shelf — where pool records live

The pool is an existing concept with an existing mount, not a new container shape. Pool records
 wear **`%Record`** (the 2026-08-27 ruling, Portability_todo §3 "mainkey question BURNED") on the
  pool's own shelf — a `%Mine`-shaped home standing in the radio world alongside the library
   home, but rooted at `pool/…` paths. The identity law (CLAUDE.md "identity is per-shelf") is
    satisfied because the pool SHELF is distinct: a pool %Record at `id:X,path:pool/A/B/t.wav` is
     a different holding from the library %Record at `id:X,path:music/A/B/t.wav`, even if X
      coincides (v1 byte-copy = same bytes). A v2 ogg128 press has a NEW id (different bytes →
       different enid), `of:<origId>` the cross-fidelity join, `grade:'ogg128'`.

**The catalog door** is `Ra_rec_pool(shelf, origId, lofiId, path, grade)` in `Ghost/M/Ra.g:895`.
 One door for every landing, whatever verb brought the bytes — never a parallel minter.

**The pool home particle** (to be stood):
```
%Mine (or a new name — call it %SoundPile to avoid ambiguity with the library home)
  pub: <my-prepub>
  pool: 1           ← 1-or-absent; distinguishes from the library home
  stock: 1  (the shuffle Mag shelf — same paged-Mag structure Ra_rec_home uses)
```
Or: re-use the library home with the `pool` mount already standing; `Ra_home_self` returns the
 library home — the pool would want its own `Ra_home_pool(w, pub)` find-or-create. This is a
  naming call (a few lines of code); pick when the steward driver is wired.

### 2.2 Press ledger particles — transient scaffolding

`%press,of:<origId>` — the visible scaffolding Ra_press mints on `w` per press attempt (exists in
 `Ghost/M/Ra.g:980`). Transient; the pool-steward sweep is the natural drop seam. A failed
  press stays standing with the fail reason (the same discipline Siphon_pull uses for `%Siphon`).

### 2.3 Quartermaster (steward) particles

`%Provisions` — the steward's want-list container under `w`:
```
%Provisions
  %Want,of:<origId>,do:press|pull|evict,why:<tally sentence>
```
`Ra_quarter` mints/drops these idempotently. `Ra_quarter_serve` enacts them.

### 2.4 Siphon particles (deliberate act — already built)

See Siphon_todo.md §0 "the model":
```
%Tags (on the radio world)
  %Tag,name:<word>
    %Tagged,of:<origId>       ← a referring particle; many per tag
%Siphons (on the radio world)
  %Siphon,of:<origId>,phase:<asked|pulling|landed|fail:<why>>  ← transient, dropped on land
```

### 2.5 Upgrade queue (Cave-side, existing)

`%Upgrades → %Upgrade,of:<origId>` — `Ra_upgrade_scan` (`Ghost/M/Ra.g:1113`) mints these on the
 Cave's world when a smuggled LOFI copy has no Original in the Cave's library. The heist flow
  serves them (Flow 1, Portability_todo §5). No new particles needed.

### 2.6 Source control on the %Radio particle

`radio.sc.source` — a new scalar on the `%Radio` particle: `''` (default, friends first) |
 `'pool'` (SoundPool rung) | `<friend-pub>` (aimed at one friend). This is what Siphon_todo P2
  stamps via the proposed `Radio_source_next(n)` verb. The 1-or-absent rule does not apply here
   because an empty string is the valid default; the three-way enum is clean as a string.

**Identity rule check (CLAUDE.md):** `%Radio` is already a face particle (one per world, its
 mainkey = state), and `sc.source` is a scalar on it. No new mainkeys needed; no identity violation.

---

## 3. The req-machine wiring

### 3.1 The ambient steward (what to build)

The steward is SCHEDULEY (Portability_todo §3): it does not run on every play, only on OCCASIONS.
 The right occasions: a play-session ends, a jam session concludes, the Cave becomes reachable,
  the tab has been idle for a while.

**Proposed shape — a permanent req that re-arms on occasions:**

```
req:PoolSteward (permanent, one-per-ghost in the radio world)
  on_occasion():
    Ra_quarter_serve(w, nav, shelf, pool, lib, cap)
  finished when: the round completes (a single oai-idempotent sweep — fast)
  re-armed by: play-session-end, jam-end, Cave-reachable tick
```

The steward is NOT reactive (not a wake-per-event) and NOT a timer. The right trigger for the
 first version is a seam already fired by Radio: when `Radio_state(radio, 'off')` or when a
  track finishes (`tape-out` path). `Ra_quarter_serve` is already idempotent; calling it at a
   session boundary is safe and cheap (it computes the diff and presses only what changed).

**The lib mapping question (the delicate gap, Portability_todo §3 ⚠):** `Ra_quarter_serve`'s
 `lib` arg is "where to read Original bytes from." For a phone-with-no-library this is the
  friend's share (the streaming source). That mapping is the open §3/§4 question. Until it is
   resolved, wire the steward only for the case where `lib` is the OWN library (a Cave or a tab
    with FSA granted). A shareless phone gets the Siphon's EXPLICIT lib instead (Siphon_todo rung
     3). This is a deliberate non-wiring, not a TODO to ignore.

**Req lifetimes:**
- `req:PoolSteward` — `permanent` (one owner per radio world, holds its occasion write)
- `req:PoolPress,of:<origId>` — `transient`, minted per `Ra_press` attempt, dropped on land
   or fail (the `%press` scaffolding is the visible form; this req is the hold)
- `req:PoolEvict,of:<id>` — `transient`, minted per eviction, dropped on completion

### 3.2 The source rung in Radio_dial

`Radio_source_next(n)` — the cycle verb (Siphon_todo P2 names it): stamps `radio.sc.source` on
 the %Radio particle, cycling `''` → `'pool'` → `<friend>` → `''`. The dial consults
  `sc.source` at the top of Radio_dial and dispatches:
```
if sc.source === 'pool':   Radio_dial_pool_local(w, radio)  ← new: reads the OPFS pool shelf
elif sc.source is a pub:   Radio_dial_aimed(w, radio, pub)   ← aim-locked to that friend
else:                      current ladder (friend-first, fallback own)
```
`Radio_dial_pool_local` is a thin read over `Ra_home_pool(w, pub)` — the same Ra_recs walk
 `Radio_dial_pool` does over Theirs, but against the OPFS pool shelf. No new machinery; new
  two-liner.

### 3.3 ShuffleFace extension

ShuffleFace already shows the "radio-pool" (friend mirror records). When `sc.source === 'pool'`
 it should show the SoundPool instead — same pip idiom, same presence gate (does the pool
  record have bytes on the OPFS mount?). The source switch makes ShuffleFace polymorphic over
   the active source. This is a view-layer change, no new particles.

---

## 4. How peers contribute and draw from the pool

### 4.1 The ambient press (local-library → OPFS)

Source: your own library (a Cave or FSA tab) copies a track into OPFS.
Verb: `Ra_press` (v1 byte-copy, deterministic, already built).
Driver: `Ra_quarter_serve` at the steward occasion (§3.1).
Wire: none — this is PURELY LOCAL. No peer exchange.

### 4.2 The Siphon (deliberate pull from a friend's share → OPFS)

Source: a friend's share you are browsing (explicit lib, not ambient).
Verb: `Siphon_pull(w, shelf, pool, lib, origId, nav)` in `Ghost/M/Siphon.g:92`.
Wire: uses the existing radio/Repli chunk machinery (the track is already streamable; the siphon
 reads the bytes that would have played and writes them to OPFS instead).
State: `%Siphon,of:<origId>,phase` — legible, transient.

### 4.3 Flow 3 — phone↔phone pool exchange (the majority transport)

Two phones in a room swap SoundPool material directly: LOFI only, no Cave required.

**Mechanism (the Portability_todo §5 ruling):** a Heist whose `mardir = 'pool'` and whose
 destination nav is the OPFS pool nav. The Heist machinery is already parameterised over any
  nav (the loosened landing head); what is missing is the UI gesture and the pool-destination
   wiring in the Heist setup path.

**The exchange is a Heist, not a new protocol frame.** The existing Repli machinery moves the
 chunks; consent rides the existing Swarm grant (`%Invite:Music` or a new pool-exchange feature
  flag if the policy needs separating). The landing catalogues through `Heist_catalog_land` with
   `mardir='pool'`, which lights the EXISTING pool branch.

**Particles involved:** the same Heist ledger (`%Caper,at:<pier>`, `%Pick,ref:<id>`) plus the
 pool branch's landing shape (`%Record,of:<origId>,grade:ogg128,lofi:1,path:pool/…`). The
  `of:` join is what makes a received pool copy simultaneously listenable (LOFI, now) and an
   INTRODUCTION: the receiving Cave can later fetch the Original (Flow 1, `Ra_upgrade_scan`).

**Network exchange:** rides existing Swarm gossip + Repli — no new frame kind. The pool exchange
 is a NEW OCCASION for a Heist, not a new wire protocol.

### 4.4 Flow 2 — Cave → Captain pool fill

A Cave that holds a library presses LOFI copies and sends them to the Captain's OPFS pool over
 the wire. Mechanically: `Ra_quarter_serve` on the Cave side, `mardir='pool'`, the Captain's
  address as destination. The Heist send path already exists; the pool destination needs the
   `pool/…` mount wired on the RECEIVING (Captain) side, which already stands (`poolmount`).

The steward occasions for this are Cave-side: "Cave came online", "library grew", "Captain pool is
 thin". These are daemon-level occasions; the daemon's `digger` pattern (tour→rest→tour) is the
  standing precedent.

---

## 5. How it surfaces in the glass

### 5.1 RadioFace source chip (Siphon_todo P2 — proposed, not applied)

The `{#if face.by}…{/if}` provenance block in `src/lib/O/ui/RadioFace.svelte` becomes the
 **source selector**: tap it to cycle `''` → `'pool'` → `<friend>` → `''` via
  `Radio_source_next(n)`. The chip names the live source and flips between what stands.

The exact patch is written in Siphon_todo §"proposed patches" P2 — apply by hand after
 `Radio_source_next` exists.

### 5.2 ShuffleFace — pool mode

When `radio.sc.source === 'pool'`, ShuffleFace shows the OPFS pool shelf pips instead of the
 friend-mirror pips. One toggle in the derived computation (same `Ra_recs` walk, different
  shelf). The presence gate stays the same (`Radio_playable` checks chunk 0 — which, for an
   OPFS pool record, means the bytes are locally present, never a latency question).

### 5.3 SiphonFace (rung 5 of Siphon_todo — not yet built)

A new face (`Ghost/M/SiphonFace.svelte` or inline in `Siphon.g`) listing pooled tracks with
 tag chips and a define-a-tag affordance. Hidden behind the RadioFace source chip. Props {n, H}
  per the glass convention. Reads `%Tags` and the pool shelf; calls `Siphon_tag_def/apply/unapply`.

This face does NOT exist yet. It is rung 5 of Siphon_todo. Design it there; point here for
 the SoundPooling arc context.

### 5.4 Door — pool legibility (future)

`%Provisions → %Want,of,do,why` is already the legible want-list. A Door section showing
 "what your phone wants next and why" is a pure read over these particles — no new model
  work. Defer until the steward is live and the list has something to show.

### 5.5 The cross-body cells (the Reach chapter's surface — data landed 2026-09-01)

Three belly cells alongside Door/Radio/Link (the Sounditron organ ladder + Cellui), each reading a
 Book-gated data verb; Svelte/humdinger so built WITH the owner at a tab (the standing law). Spec'd here
  so the build is a fill-in, not an invention:
- **Crew** (`CrewFace.svelte`) — the soul across its machines. READS `Swarm_reach_crew` +
   `Swarm_body_roster` (roles + presence off `sc.heard`) + `Swarm_organ_of` (sizes). SHOWS a row per body
    (mine dimmed): role badge · presence dot (here/fading/away) · organ size ("214 ready" / "38k trove");
     beneath, the reaches in flight with state glyphs (booked ⋯ / serving ↯ / arrived ✓ / refused ⚠).
      This is DoorFace's family box grown into the full crew view. DRIVES: away-body forget ✕ (built);
       refused-reach dismiss.
- **Pool** (`PoolFace.svelte`) — SoundPooling proper: the union trove across the roster, deduped by
   content-id, each track tagged with which body/bodies HOLD it. A track not on THIS body shows "pull
    here" → `Swarm_reach_book(w, self, {to:<this body>, of:<content-id>, for:'serve'})`; the fill
     progresses as the reach serves (its state shown inline, the crew read filtered to the track).
- **Organ** (`OrganFace.svelte`, or a strip in Crew) — pocket vs trove as quantities + top tags +
   offline/served, per body. "A body describing the organ it grows."

---

## 6. The smallest demonstrable first slice

**Do this first to prove it works:** apply Siphon_todo P1 (register Siphon.g + Siphonation.g),
 do the P3 recording pass, then wire `Radio_source_next(n)` as a three-state cycle and test it
  live: with a friend's share open, tap the source chip, confirm `radio.sc.source` flips in the
   snap (`runner_ask snap 1`), and confirm `Radio_dial_pool_local` returns records from the pool
    shelf (even if empty, it must not throw). That is the end-to-end cycle proved.

The FIRST LIVE PRESS to verify bytes actually land: run `Ra_quarter_serve` manually from a story
 step or a runner_ask one-shot, with a known lib, pool nav, and cap=1. Inspect `runner_ask snap`
  for the `%Record,path:pool/…,body_hash:…` row in the pool shelf. No face needed; the snap is
   the proof.

**Build order:**
1. Record pending Books (Lane A — editor passes, no code).
2. Apply Siphon P1 + P3 (register, record).
3. `Radio_source_next(n)` verb + `Radio_dial_pool_local(w, radio)` (new rung, ~20 lines).
4. Apply Siphon P2 (source chip).
5. `Radio_autopress` — the ambient press at play-session end (resolve §3/§4 lib first).
6. ShuffleFace pool-mode extension.
7. SiphonFace (Siphon_todo rung 5).
8. Flow 3 — phone↔phone exchange (the Heist-to-pool seam).

---

## 7. The bombs (what detonates if the next fork doesn't know)

- **The lib mapping is the live tripwire.** `Ra_quarter_serve`'s `lib` for a streaming phone is
   NOT its library (it has none). Guessing it = undefined behaviour. Read Portability_todo §3 ⚠
    before touching `Radio_autopress`.
- **Pool records must route through `Heist_catalog_land` — never a parallel minter.**
   `Ra_holding_keys()` is the one authority; a bespoke press-minter re-opens the forty-five-seams
    flaw. One door, always.
- **v2 (ogg128) press is not bit-reproducible** — two presses of one Original yield different bytes.
   A Book asserting the real v2 press cannot be a byte-exact fixture. Use the pinned-stub shape-Book
    pattern (Portability_todo §3 "determinism trap"). v1 (byte-copy) IS reproducible — book it normally.
- **Snapped booleans: `pool:1` not `pool:false`.** Every presence flag on new particles rides as
   `1` or ABSENT. Never `false`, never `0` in sc.
- **Objects and functions only in `.c`, never `.sc`.** The pool nav is `.c.ra_nav` (the existing
   pattern, `Ghost/M/Ra.g:884`); never store it in `sc`.
- **A cold tab runs no beats.** Live pool behaviour is humdinger-gated (the same law Radio_autopress
   would follow). A Book that exercises the pool model must stub the nav and press synchronously.
- **OPFS is evictable.** The pool is designed expendable; a re-press from its Original is always the
   recovery path. `navigator.storage.persist()` is the cheap mitigation (Portability §0.9b).
- **ShuffleFace is read-only.** It must never write; a render that calls `Ra_home_pool` (an oai)
   would mint a home on a mere poll. Probe first (`oa`), then read.
- **The pool is NOT replicated** (Portability §2E ruling 6). Replication ignores it; pool material
   crosses as APP FLOWS (heist-rides, steward-decided). Never add the pool shelf to Repli targets.
   **→ This is exactly why REACH fits (§0.5):** a reach IS an app-flow (a booking riding a Heist doer),
    NOT replication — so Flow 3/Flow 4 riding Reach honours this ruling, they do not violate it.

**The cross-body forks (from the Reach chapter — decide when you can SEE them, not before):**
- **Auto-restock vs explicit.** Does the pocket auto-fill from the trove (the bloodstream — Division
   §PURPOSE), or only on an explicit pull? Auto is the magic but it's a policy with backpressure teeth
    (it's the Reach cousin of the §7 lib-mapping tripwire). Decide when the Pool cell is real and you can
     watch it fill.
- **Ear bodies** (a phone with NO library, all reach). A first-class role, or a Captain with an empty
   pocket? Affects the roster/organ shape.
- **Cross-SOUL pooling** (a friend's trove in your pool, by grant) vs only your own bodies. Reach
   `to:<friendpub>` already addresses it; the policy (whose music appears in MY pool) is the open question.

---

## 8. Reference — existing file locations

| thing | file | lines |
|---|---|---|
| `Ra_rec_pool` — catalog door | `Ghost/M/Ra.g` | ~895 |
| `Ra_press` — byte-copy + ogg128 driver | `Ghost/M/Ra.g` | ~925 |
| `Ra_quarter / Ra_quarter_serve` — steward | `Ghost/M/Ra.g` | ~1060 |
| `Ra_upgrade_scan` — Cave upgrade queue | `Ghost/M/Ra.g` | ~1113 |
| `Heist_catalog_land` — one landing door | `Ghost/M/Heist.g` | ~950 |
| `Siphon_pull` + tag model | `Ghost/M/Siphon.g` | ~109, ~1 |
| `Radio_dial_pool` — friend-mirror rung | `Ghost/M/Radio.g` | ~2061 |
| `Radio_pool_census` — honest count | `Ghost/M/Radio.g` | ~2109 |
| `Wormhole_mount_pool` — OPFS mount | `src/lib/O/Housing.svelte.ts` | ~2550 |
| ShuffleFace | `src/lib/O/ui/ShuffleFace.svelte` | 1 |
| RadioFace + source chip (proposed P2) | `src/lib/O/ui/RadioFace.svelte` | ~150 |
| Portability_todo §3 (lib mapping ⚠) | `src/lib/O/spec/Portability_todo.md` | ~869 |
| Siphon_todo (rungs, proposed patches) | `src/lib/O/spec/Siphon_todo.md` | 1 |
