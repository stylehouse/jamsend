# RemoteHeist_todo — the Captain forms a Heist, the Cave runs it

Commissioned 2026-09-30 (owner, after Inco became Lump's Cave and a carried-over ♥ popped a Heist setup on an
 unattended laptop): *"make the Heist setup remote-able, so Captain on the phone can operate it for the Cave over
  there … the cheap|safe version requires talking to the Cave live, like it's the server handling the Heist
   request from the Captain … remote Heist-forming would probably beat publishes a read-only view of its shop to
    the crew, because it would know the destination files already exist … it's a background operation on the
     Cave as far as UI goes, the Captain does everything backended over to the Cave … avoids the multimaster
      problem."*

Read with: `Heist_todo.md` (what a Heist is, the `%Heist` keep, the cost line), `Reach_todo.md` (the
 cross-body procedure layer this rides), `Crew_todo.md` (who the Cave and the Captain are),
  `LinkDevice_leak_todo.md` §0.1 (the evening this came out of).

---

## 0. What to get on with next

### ✅ 2026-10-04 — TWO SEATS + A PINNED AIM (live walk: Lump/Inko/Grav)

Owner's walk: Lump aimed at Grav kept playing Inko, and heard Inko's own tracks "from Grav". Two fixes, both
 compiled; **SwarmBorrow 5/5 and MusuRadioAim 3/3 on e747, caveat 0**. Not walked live yet.
- **§4.1 BUILT: a friendship seats its Captain AND one Cave.** `Swarm_pier_seats(pier)` = the soul's own address always +
   the unexpired loan's Cave. Used by `Swarm_slot_granted`, `Swarm_offer_now`, `Swarm_share_beat` (which now casts to
    every seat). `Swarm_pier_slot` still exists and means only "where the loan points". `Swarm_borrow_heard` tracks the
     CAVE seat: a newer Cave still logs the previous Cave out (`seat_lost`); the Captain is never told and never loses its
      seat. `Swarm_borrow_use` on the Captain no longer lends to itself to "take back" — it just returns `'own'`.
       SwarmBorrow's oaths were RE-SWORN (step 4 `a-friendship-seats-its`, `a-lapsed-loan-frees`; step 5
        `the-captain-is-never`), not just re-recorded.
- **A chosen aim is PINNED** (Radio.g). `Radio_aim_set` sets `radio.c.pinned` (.c, so no snap moves; `Swarm_radio_rehydrate`
   re-pins a stashed aim). Pinned: `Radio_aim_at` won't roam to another holder, `Radio_lineup_fill` keeps only the aimed pool
    even when dry, `Radio_dial_pool` returns nothing rather than another holder's track. RadioFace shows a dry pin as a dashed
     amber `⚠ <name>` chip, with the reason in its title (not a source here / needs the Captain / nothing playable yet).
- ✗ **NOT the cause: a `pool/` folder on disk.** A browser's SoundPool is OPFS, mounted at `pool/` by MountNav
   (Housing `Wormhole_mount_pool`). The mount root lists only the FSA, so no music walk can reach it. Only the daemon
    keeps a real `pool/` dir, and it walks that as an explicit base on purpose. A walk-skip was built on the wrong
     premise and reverted the same day. The real cause of "Inko's tracks from Grav" was found live
      the same day: the pool's preview heal wrote into radiostock under Grav's pub and the Stoker resurrect stood them on
       Mine. Fixed + ruled in SoundPooling_todo §0 (the pool is not a radio source).
- **Sounditron is red on a peerless runner** (5 peer-dependent gaps, `ok:0` every step) — environmental, same as before.
**Owner to walk:** Lump aimed at Grav → only Grav's tracks, or the ⚠ chip if Grav has nothing for this body; Captain + Cave
 both pulling from one friend at once.

### ⇄ HAND-BACK 2026-10-03 (the 🧲 sidetrack, forked off the main session — read this first)

**Where it stands:** R1 (Captain ▶/✕ on a Cave's Heists from the Haul cell), the 🧲 (where hearts are hauled) and
 R4 (a carried ♥ never takes the Cave's screen) are BUILT and Book-gated; **none is walked live yet — the owner is
  testing.**  Book **MusuMagnet** (HeistTesting.g, 7 steps, 5 oaths) gates the 🧲 + R4; SwarmCall still gates G0/G1.
**The bombs:**
- **The 🧲 is live-only by design.** `Heard_magnet(w)` returns '' unless `w === top.c.radio_w && !w.c.Run` — a Book's
   world CAN be radio_w on a runner, and the runner tab's own identity has a crew: without the guard Book takes got a
    foreign `to` and MusuHeard/MusuHandoff went red.  Books pass `to` explicitly (`Heard_take(..., to0)`).
- **The R4 root cause was an id alias, not focus.** `Heist_keep_take_go` soloed a ♥ keep by the HEARD id while the
   folder census mints picks under RUMMAGE ids → -1 forever → the keep sat primed holding the whole album = the setup
    form on Inco.  `Heist_keep_seed_ref` (shared with pool_go, which had the same fix inline) resolves it.  Then
     Sounditron: a keep marked `.c.carried` (Heard_haul_beat, card has `pressed_on`) is neither a setup nor the
      insistent stager; a pin (clicking its Haul row) still opens it.
- **A shared runner:** another session uses da06; this work ran on **e747** (`--runner=e747cbed6a9ca919`).
- ~~Owner said item 3 may already be done~~ — it wasn't; BUILT 2026-10-04 (entry above).
**Next:** owner's live walk (R1 + 🧲, steps in the 🧲 entry below) → then G2 → R2 (R2 = ⇊/♥ on the Captain becomes a
 `create` call to the 🧲 body; the 🧲 already decides WHERE, R2 makes the Captain's ⇊ go there).

### ✅ G0 + G1 LANDED 2026-09-30 — the general layer, Book-gated

Built in `Ghost/S/Swarm.g` (the transport + the `#region Remote`), proven by the new two-body Book
 **SwarmCall** (`Ghost/Story/SwarmTesting.g`, stub kind `Remote_kind_counter`): 4 steps, **8/8 declared +
  sworn, green ×2 in check mode, caveat 0**.
- **G0 (transport):** `Swarm_reach_wire` / `Swarm_reach_done_frame` carry the optional envelope (`args`,
   `until`, `answer` — URI-encoded JSON, byte-identical for every pre-call reach); `Swarm_reach_heard` copies it;
    T-1 settle gate (knob gates `for:serve` only); T-3 doer table `Swarm_reach_doer`; T-4 `for:call` kin-only in
     the road; T-5 `until` expiry in settle; T-6 call rows dropped once reported (backend) / acked (frontend).
- **G1 (the layer):** `Remote_open` (the `%Remote,<kind>,on,of` handle, on the station world — never the
   identity), `Remote_call` (local → the kind's op + view; remote → book + dispatch at once + `.c.wish`),
    `Remote_serve` (the `for:call` doer, quiet ops, free `get`/`list`/`create`), `Swarm_call_serve_now`
     (served ON HEAR, T-2), `Remote_landed` (view → sc, `_`keys → .c, why, wish retires).
- **What SwarmCall swears:** round trip lands the view (volatile keys off the snap) · a refusal names its why
   and changes nothing · both envelopes drop and the wish retires · a stranger's call lands nothing · an
    unanswered call expires as `nobody-answered` · the same verb runs locally and remotely · `list` names the
     targets · a throwing doer stays serving and is logged.
- **Not yet proven on a live wire** — the Book carries frames by hand (no station). The first live proof is R1.

**NEXT (owner said go, 2026-09-30): R1 FIRST with a small summary view, G2 (the full HeistFace view-model)
 after** — prove the live wire before the big face refactor. The R1 build, concretely:
1. **`Remote_kind_heist()` in `Ghost/M/Heist.g`** — `find(ident, of)`: the keep on the backend's shop
    (`Ra_home_shop(radio_w, <own body prepub>)` — PROBE, it mints; `top.c.radio_w` is the radio world) by
     `seed`; `list`: the shop's live keeps' seeds; `ops.start` → `Heist_keep_start(keep)` (async — fire it,
      return 1), `ops.cancel` → `Heist_keep_cancel(rw, keep)`, `ops.lofi` → `Heist_keep_set_lofi(keep, !!args.on)`;
       `view` → `Heist_keep_gist(keep)` + title/artist/from_name/un_n/un_size/landed_n/state (flat scalars; the
        running rate/progress as `_`-keys). `create` is R2 — refuse it for now (`not_yet`).
2. **R-8 QUIET:** `Heist_keep_start` re-commissions the glass (≈3270, humdinger-gated) and several verbs
    stamp `c.last_touch` (1969/1977/2009/3617) — which is what steals the belly. Thread `cx.quiet` so a remote
     start skips both. Check every verb the ops call.
3. **Frontend in the Haul cell (`HaulFace.svelte`):** when this body has a Cave online (Door's family rows /
    `Swarm_crew_view`), open `Remote_open(sw, self, 'heist', <cave prepub>, '*')` + `list`, then one `%Remote`
     per seed with `get`; render a section "on <Cave name>" — title · gist word · landed/total · ▶ start
      (primed) · ✕ cancel — calling `Remote_call`. Poll `get` only while the cell is mounted (R-3 wish shows
       at once). Station world = `Swarm_station_world()`.
4. **Live proof:** 940f (Captain, Lump) + Inco (Cave): a Heist left primed on Inco is started from 940f's Haul
    cell; Inco's glass does not move; 940f shows it running then landed. Then cancel one. Watch for `⨳🫱⚠`
     lines (road refusals) on Inco and `🦑`/`⨳` on 940f.
5. **Book:** extend SwarmCall with a heist beat only if a keep can be stood headless cheaply (MusuHeist has the
    shapes); otherwise the live walk IS R1's gate, and say so.

**R1 BUILT 2026-09-30 — live walk owed (the gate).**  `Remote_kind_heist` (Heist.g, beside Heist_live_rows): find PROBES
 via Heist_shop_find, create refused (no make), ops start/cancel/lofi, view = gist + every flag every time (`''` clears — Remote_landed
  now deletes a key sent as `''`), `_pct` volatile.  Quiet: `Heist_keep_set_lofi(keep, on, quiet)` skips the last_touch stamp and the
   global default.  Start still calls Sounditron_keeps_look on the Cave — that RELEASES a belly (leaving direction), so it stays.
    Swarm.g: target URI-encoded in `of` (Remote_undo), call reaches never restashed, and the generic pair `Remote_watch` (asks —
     timer only, one outstanding call per target, drops rows whose id left the list) / `Remote_rows` (pure read).  HaulFace: an
      "on <Cave>" section per crew Cave that is here, ▶ on a form keep, two-press ✕, "asking…" while a wish is out.  SwarmCall 4/4
       green after.  No heist Book (a keep needs a radio world + shop; the live walk is the gate).

**🧲 BUILT 2026-10-03 — live walk owed.**  The magnet had a job the day it landed: every body with a folder hauled
 every take in the crew union (Heard_takes reads own + sibling mirrors), so a Captain-with-folder and its Cave would BOTH haul
  one heart.  Now `Heard_take` stamps `to:<prepub>` = `Heard_magnet()` at the press (newest press decides; `to` rides the
   mirror as a listing key, Heard_adopt copies it), and `Heard_haul_beat` skips a card whose `to` is another body
    (`Heard_for_me`) — no `to` = anyone's, as before (no crew, Books).  `Heard_magnet`: the pick (`Heist_defaults.to`) while
     still a candidate, else me-if-Cave-with-folder, else a Cave that's here, else me-with-folder, else an away Cave.  Candidates =
      my crew's Caves + me iff `Crate_has_folder()` (A:Wormhole `c.DL`).  Door: a 🧲 on each candidate row + the instance badge,
       only at ≥2 candidates; click = `Heard_magnet_set`.  Haul's wish word says "for Inco" (`Heard_to_name`) until carried_by
        gossips back.  ⚠ Moving the 🧲 does NOT re-route hearts already pressed — their `to` stands (a re-press re-decides).

**Then G2 → R2 → R3 → R4** (§3). G2 = the view-model seam for a real kind (HeistFace onto `Remote_kind_heist().view`, R-1/R-9);
 R1 = start + cancel a Cave's Heist from the Captain, live. Owner rulings in §4 apply (1 Captain + 1 Cave seat).

### the design

The destination in one sentence: **the Cave is a Heist SERVER for its own crew — the Captain's Heist cell is a
 remote form whose every edit is a request the Cave answers, and the Cave's own screen never sees it.**

Three rules carry the whole design; everything below serves them:
1. **One writer.** The `%Heist` keep lives on the Cave's shop and only the Cave ever writes it. The Captain
   holds no copy — it holds a *view* of the Cave's last answer. No multimaster, nothing to merge.
2. **The Cave answers with what only it knows.** Which destination files already exist, what its disk says
   about size and format, whether a track is already held under another id. That is why a remote FORM beats a
   published read-only VIEW: the form is priced and checked where the disk is.
3. **Background on the Cave.** A remotely formed Heist never takes the Cave's belly, never pops a setup,
   never waits on a human there. It runs like any started keep (the Haul cell lists it), and it answers.

---

## 1. Why now — what the live walk showed (2026-09-29/30)

- **A ♥ carried across a crew join hauled an album the Cave already had.** Joining Lump's crew gave Inco
   Lump's heard Mag; a heart on "I'll Be Seeing You" became a `take` Heist on Inco for a folder already on its
    disk. The Picks carried Lump's ids, Inco's shelf held its own ids, `Heard_landed` matched only ids. Fixed
     the same day (path → song key fallback, `Heard_shelf_index`) — but the SHAPE is the point: the Cave is the
      only one that can answer "do I already have this", so the Cave must be the one that forms.
- **An unattended Cave grabbed focus for a Heist setup nobody was there to fill in.** A laptop left running
   as a Cave is a server; a setup form popping on it is a question asked of an empty room.
- **LOFI was offered for files that were already ~128k ogg** (7 tracks · ~42:55 · 41.6 MB is ~16 KB/s).
   Fixed in HeistFace (ghost-ticked "already", originals taken) — and again it is a fact about the SOURCE
    that the side holding the picks knows best.

---

## 2. The shape

```
Captain (phone)                                 Cave (laptop, background)
───────────────                                 ─────────────────────────
Heist cell (remote)  ── Reach for:heist ──────▶ Heist_serve_* doer
  shows the Cave's      {op, keep, args…}         applies op to ITS %Heist keep
  last answer                                      (Heist_keep_* — the same verbs its own face calls)
                     ◀── reach_done ────────────   answers the keep's state as scalars:
                          {state, n, size,          picks, sizes, `exists` counts, lofi verdict,
                           secs, exists, lofi…}      progress, landed_n, why-refused
```

- **Transport: Reach.** A `%Reach,to:<Cave body>,of:<keep id>,for:heist` on the Captain's %Peering, served
   by the ONE reach pump, auth'd on the crew road (a crewmate's soul-signed voucher — the pier-less lane
    already requires it, `Swarm_reach_vouched`). `reach_done` already carries a wire copy of the reach's sc back
     (Swarm.g ~7180, `reach: wire`), so the answer rides home as scalars without a new frame type. **Check
      first:** that the settled row's sc survives to the Captain's face (Reach receipts age out — the view needs
       the LAST answer, not the receipt).
- **Doer: the Cave's existing keep verbs.** `Heist_keep_start / cancel / set_lofi / pause / resume / first`
   and the dir/pick editors are what HeistFace already calls. The doer is a thin dispatcher onto them, so the
    Cave's own face and the remote face drive ONE code path. No second Heist implementation.
- **The view on the Captain: a referring particle, not a twin.** `%RemoteHeist,of:<keep id>,on:<cave
   prepub>` (a many:1 reference wearing `of:`, per CLAUDE.md's identity rule — never a second `%Heist`),
    holding the last answered scalars. HeistFace can render it if the answer carries the same field names the
     keep does; the buttons call a `RemoteHeist_*` verb that books the reach instead of the local keep verb.

---

## 2½. THE GENERAL SPLIT — a Cell whose backend is another body (owner 2026-09-30: "making that
##  frontend-backend split really nice and generalisable")

Heist is the first customer, not the design. Any organ a crew body holds — a Heist keep, its SoundPool, its
 Radio, its Stoker — is the same situation: **the state lives on one body (the BACKEND), a human on another body
  wants a Cell for it (the FRONTEND)**. Build the split once; Heist is R1 of it.

### What exists, and the three gaps (read in Swarm.g, 2026-09-30)

Reach is already 80% of an RPC: a booked intent, a pump, auth on the crew road (`Swarm_reach_road`: kin by
 roster, full-prepub claims, `by` must equal the sender), a tri-state doer contract (`Swarm_reach_serve`:
  truthy → arrived, falsy → not yet, `{refuse}` → named refusal, a throw → loud but not terminal), and a report
   home (`Swarm_reach_report` → `reach_done` → `Swarm_reach_ack`, first-terminal-wins). What it lacks:
1. **No arguments cross.** `Swarm_reach_heard` rebuilds the inbound row from `to / of / for / by` only.
2. **No answer comes back.** `reach_done` carries `state` and `why`, nothing the frontend could render.
3. **Identity is (to, of, for) and idempotent.** Good for "fetch this track" (one intent, re-asked until it
    lands); wrong for a stream of commands to one keep (start, then lofi, then cancel would collapse into one
     row). A call needs its own sequence in `of`.

### The shape — three particles, one verb each side

```
FRONTEND body                                           BACKEND body
%Remote,kind:heist,of:<keep id>,on:<body prepub>        %Heist …  (the ONE writer — untouched)
  ├ scalars = the backend's LAST ANSWER                  Serve registry: kind → { ops, answer }
  └ %Reach,for:call,of:heist|<keep>|<op>|<seq>  ───▶    Swarm_reach_serve → Remote_serve(reach)
        args:<json>                                         op(target, args) → the local verb
        state/why/answer ◀── reach_done ──────────          answer(target) → {scalars}
```

- **`%Remote,kind,of,on`** — the frontend's REFERRING particle (a many:1 reference wearing `of:`, per
   CLAUDE.md's identity law — never a second `%Heist`). Its scalars are the backend's last answer, verbatim.
    ⚠ SUPERSEDED BY §2¾ R-1: faces do NOT render it "exactly as the real thing" — they render a VIEW-MODEL that
     both the local particle and the `%Remote` produce. The answer time rides `.c`, never `sc` (wall clock).
- **Serve registry (backend)** — `Remote_kinds[kind] = { find(ident, of) → target, ops: { start, cancel, … },
   answer(target) → plain scalars, refuse(ident, op, args) → why|null }`. Registered by the owning ghost (Heist.g
    registers `heist`), so Swarm stays verb-agnostic — the rule Reach_todo already keeps for the pool doer.
- **`Remote_call(n, op, args)` (frontend)** — the ONE verb a face calls. If `n` is the real particle (local),
   it calls the local op directly; if `n` is a `%Remote`, it books `%Reach,for:call,of:<kind>|<of>|<op>|<seq>`
    with `args` as a JSON string scalar, and returns. **Faces never branch on local-vs-remote** — HeistFace swaps
     `A.Heist_keep_start(n)` for `A.Remote_call(n, 'start')` and works on both.
- **`Remote_serve(reach)` (backend doer)** — rides the one pump beside `Swarm_ferry_verdict` (a doer
   dispatch by `for`). Parse `of`, find the target, check `refuse`, run the op, write `answer` as a JSON
    string scalar onto the reach, return truthy. The existing report carries it home.
- **Plumbing for gaps 1–2:** `Swarm_reach_heard` copies `args` if present; `Swarm_reach_report` puts
   `answer` on the `reach_done` (guarded, like `why`); `Swarm_reach_ack` lands it on the booker's reach AND
    onto the `%Remote` it belongs to, then the booker's reach graduates as today. Additive: a reach without
     `args`/`answer` is byte-identical on the wire, so no existing Book moves.
- **A `get` op for free** — every kind answers `get` with `answer(target)` and no side effect: the
   frontend's refresh, polled by the `%Remote`'s own cadence ONLY while a face is mounted on it (the owner's
    "stops when nobody is looking" — the `.c.watched` stamp a face sets on mount). `list` answers the kind's
     targets on that body (the Captain's "what is Inco heisting?").

### The laws this must keep

- **One writer per particle.** The frontend never writes backend state; it only asks. A `%Remote` is a cache
   of answers, droppable at any time, rebuilt by one `get`.
- **Auth is the crew road, not the kind.** `for:call` is admitted for KIN only (roster/Crew), never a friend's
   Music grant — a friend may ask me to press a track (`for:serve`), not drive my Heists. The kind's `refuse`
    is for domain no's (disk full, already held), never for identity.
- **Background on the backend.** A call never focuses the backend's glass, never raises a form there. The Cell
   layer's focus authority sees no `stage_want` from a remote call.
- **Answers are scalars.** JSON-in-a-string for the envelope (`args`, `answer`), but what lands on the
   `%Remote` is flat `sc` — snap-legible, diffable, the same shape the backend particle wears. Nested state
    (a keep's Picks) answers as a count + a summary line, never a copied subtree — a full form is R2's job, and
     it asks `get` with a `detail` arg.
- **Book first.** The whole loop is provable on the mail wire (`Swarm_pump`): two bodies of one soul, a stub
   kind (`kind:counter`, ops `inc`/`get`), the frontend calls, the backend answers, the `%Remote` shows the
    count, a stranger's call is ignored, a refused op carries its why. SwarmBody's beats are the template.

### §2¾ Is this a mature take? — the review (owner 2026-09-30: "not going to bleed side-effects?")

**The transport half is sound; the face half, as first written above, was naive.** Nine places it would have
 bled, each with the rule that stops it. Everything below is binding on G0–G2.

- **R-1 · Faces read far more than scalars.** HeistFace's `face` derivation reads the keep's CHILDREN (Picks,
   HeistBar), husks off the friend's mirror, `.c` runtime refs, and a dozen `A.*` probes. A flat `%Remote` has
    none of that, so "the backend's face renders it unchanged" would render a broken form. **Rule: a kind
     exposes a VIEW-MODEL** — `kind.view(target) → plain object` — computed where the state lives. The local
      face renders `kind.view(particle)`; the remote face renders the `%Remote`'s last answered view. ONE render
       path, and the view-model is exactly what `get` answers. This is the UI|UX standard the owner sees
        emerging: **a Cell = render(view-model) + actions(op)**, and it holds whether the backend is here or on
         another body. Kinds adopt it one at a time; nothing forces a rewrite of faces that stay local.
- **R-2 · Stale view, live action.** The Captain presses ✕ on a keep that finished a second ago. **Rule: ops are
   INTENTS, idempotent against the current state** (start a started keep = no-op; cancel a finished one =
    `{refuse:'already_done'}` with the fresh view). Optionally a call carries `seen:<view version>` and a
     destructive op refuses `stale` if the target moved since — the Captain's face then shows the new state.
- **R-3 · Latency.** The reach pump's cadence is 3–5s; a click that takes 5s to show is broken UX. **Rule:
   `Remote_call` dispatches AT ONCE** (book + an immediate pump nudge, the `fire_ask(true)` shape), and the face
    shows the WISH optimistically until the answer lands (HeistFace's `lofiWish` pattern, generalised: a
     `%Remote` carries `c.wish` per op; the answer retires it).
- **R-4 · A queued command firing hours later.** Reach is built for DURABLE intents (re-asked until they
   land). A "start" pressed while the Cave was offline must not fire tomorrow by surprise. **Rule: two
    lifetimes.** `for:call` rows carry a short TTL (the ceremony's 45s idea) and go `dead` visibly ("Inco
     didn't answer"); only WANTS persist — see the owner's answer 3 in §4 (a Love stays unfulfilled, which is
      a heart on the heard Mag, not a standing call).
- **R-5 · Reach's identity is (to, of, for) and capped at 32 standing.** A burst of calls would collide or
   starve real work. **Rule:** `of` carries a per-call seq (`<kind>|<target>|<op>|<seq>`); `for:call` rows are
    dropped at report (they are transient reqs — CLAUDE.md's "an owner drops its finished transient reqs"), so
     they never sit against the cap.
- **R-6 · Wall clock and churn in snaps.** `%Remote` + call reaches are snapped; an `at` or a changing
   answer in `sc` reds every fixture that holds one (memory: wall clock in .sc reds every fixture). **Rule:**
    answer time on `.c`; the view-model's volatile parts (progress %, rate) on `.c` too; only the durable
     view (state, n, size, why) in `sc`.
- **R-7 · Args are an attack surface.** "Choose folders" remotely means a path string from the wire writing on
   the Cave's disk. **Rule:** every op validates its args on the backend; dest paths are resolved INSIDE the
    collection root (the same sanitiser HeistFace's `dest` uses) and refuse anything that escapes it. A
     crewmate is trusted as a person, not trusted to send well-formed paths.
- **R-8 · Backend focus side-effects.** `Heist_keep_*` verbs stamp `last_touch` / call `Heist_keep_touch`,
   which is exactly what steals the belly. **Rule:** ops run with a `quiet` flag the verbs honour (no touch,
    no stage_want, no feebly_ponder); the Cell layer never sees a remote call.
- **R-9 · Two answers to one question.** If the local face keeps its own derivation AND the kind has a view(),
   they drift. **Rule:** when a kind goes remote-able, its face moves onto `kind.view()` in the same commit.

#### The transport, checked against the code (2026-09-30, owner: "check more the remote-able part is going to work")

Walked end to end in Swarm.g: book → dispatch → road → heard → serve → report → ack. It works in outline; six
 things would have stopped or hurt it, one of them a live bug in shipping code.

- **T-1 · FIXED: the settle loop only ran for pool consent.** `Swarm_reach_settle` (dispatch + deadline) returned
   0 unless `w.c.reach_on` or SoundPool consent — a gate written when `for:serve` was the only kind. Measured
    on Inco: its W2 `Reach,for:ferry` ("I want linkage") sat `state:booked` for a day, never sent (the link
     worked only because the Captain also reacts to the knock itself). Every `for:call` from a Captain without
      pool consent would have died the same way. Now the knob skips `for:serve` rows only (SwarmBody's
       `knob_off_observes` books `for:serve`, so it still reads 0). Side effect to expect once: Inco's stale
        ferry row now dispatches, 940f's verdict refuses it (`no_offer`), the receipt ages out in an hour.
- **T-2 · Latency: the backend serves only on its pump pass.** The pump rides the Sounditron trickle (every
   2nd tick, ~10s) behind a 5s cadence, so a call sits `serving` for up to ~10s before the doer sees it. **Rule:
    serve `for:call` IN the hear funnel** — synchronously, the way `Swarm_ferry_verdict` already runs — and
     report at once. The pump stays the retry path, not the fast path. Same on the frontend: `Remote_call`
      dispatches directly (book → `Swarm_reach_dispatch`), never waiting for the next pump.
- **T-3 · One doer for every kind.** `Swarm_reach_serve(w, ident, doer)` is called with the ferry verdict only;
   every other serving row just waits (pool fills are served elsewhere, by `Ra_pool_fill_pump`). **Rule:** a
    doer TABLE keyed by `for` (`ferry` → the verdict, `call` → `Remote_serve`), unknown `for` → `no_handler`
     as the contract already says. `for:serve` stays with the pool pump.
- **T-4 · The road admits friends for ANY `for`.** `Swarm_reach_road`'s friend arm lets a pier with live
   Music book work on me — right for `for:serve`, wrong for `for:call`. **Rule:** `for:call` is kin-only
    (roster/Crew), enforced in the road, not left to each kind's refuse().
- **T-5 · A deadline that dies on reload.** Deadlines live on `.c` (volatile), so a reloaded frontend keeps
   an unanswered call standing with no deadline, forever (the stale ferry row is exactly this). **Rule:** a call
    carries its expiry in `sc` as `until:<Swarm_now + 60>` (Swarm_now seconds — the world clock a Book pins, so
     no fixture wobble), and the settle loop kills `for:call` rows past `until`.
- **T-6 · Target rows and the cap.** The backend's inbound copy is minted by `Swarm_reach_book` (cap 32
   standing). A `for:call` copy must be dropped as soon as it is reported (`arrived` graduates already;
    `refused` would otherwise stand an hour as a receipt — for a call the receipt belongs on the FRONTEND's
     row, not the backend's).

Checked and fine: routing a reach to one specific body (`to` = the Cave's prepub → `Swarm_body_for` → its
 key-derived address; sibling lane, soul-voucher auth), the report home (`by` → the booker's roster row →
  `Swarm_sibling_send`), the booker's ack (matched on `(to, of, for)` — unique once `of` carries a seq,
   first-terminal-wins latch), payload size (no relay frame cap found; a view-model is a few KB).

What it deliberately does NOT try to be: a general RPC for arbitrary ghost methods. Only registered kinds,
 only their declared ops, only kin. Anything else is a Reach `for:` of its own, as today.

### Rungs of the general layer (before Heist's R1)

- **G0 — the envelope + the transport fixes.** T-1 (done 2026-09-30), T-3, T-4, T-5, T-6; then `args` across (heard), `answer` back (report → ack), both optional + guarded. Book:
   an existing SwarmBody reach round-trips unchanged; a new one round-trips a payload.
- **G1 — Remote_call / Remote_serve / the registry / `%Remote`** (R-2..R-8 in from the start), with the stub `counter` kind. Book:
   `SwarmCall` (two bodies, call → answer → view; stranger ignored; refusal named; `get` refreshes).
- **G2 — the view-model seam (R-1, R-9).** `kind.view()`; the face renders a view-model whether local or
   remote; `Remote_call` local-or-remote with an optimistic wish. First real kind: `heist` (R1 below).

## 3. Rungs

- **R1 — start and cancel a Heist the Cave already has.** The Captain sees the Cave's keeps (answer to a
   `list` op), presses ▶ or ✕, the Cave applies it, answers. Smallest real slice; proves transport, doer,
    auth, the view, and "background on the Cave". Book: two bodies, a keep on the Cave, the Captain starts it,
     the Cave's keep goes `started`, the Cave's focus never moved (sworn).
- **R2 — form a new Heist remotely.** The Captain presses ⇊ on a track while aimed at the Cave's shelf (or on
   a friend's track, asking the CAVE to fetch it). The Cave mints the keep in the background, answers the
    priced form — including **`exists`: how many picks already land on files it has** (path, then song key —
     the `Heard_shelf_index` join). Edits (dirs, picks, lofi) are ops; ▶ start is an op.
- **R3 — progress.** The Captain's cell shows a running Heist's progress. Either a `status` op polled by the
   Captain's pump while the cell is open, or the Cave pushing a `reach_done` per landed track. Poll first —
    it needs nothing new and stops when nobody is looking.
- **R4 — the unattended-Cave rule for local takes.** A `take` born from a CARRIED heart (crew join, sibling
   Mag) starts in the background instead of raising a setup. The Cave's own gesture (a ♥ pressed HERE) keeps
    today's behaviour. Independent of R1–R3; could go first.

---

## 4. The owner's answers (2026-09-30) — and what each commits us to

1. **Whose music — the Captain decides; the Cave fetches.** Captain → Cave → the music's origin. The snag is
    GrantBorrowing's one-seat rule (only one crew body per friend at a time). **Ruling: widen the seat to ONE
     CAPTAIN + ONE CAVE simultaneously** at the friend (`Swarm_pier_slot` becomes two slots: the soul's own + one
      loan), and **don't** restrict the Cave's loan to heist traffic by protocol — not worth the complexity. On
       an access rejection, show a UI message **under the source button in Cell:Radio** (the `radio.sc.note`
        seam `Radio_aim_set` already uses for "your Captain needs to come online"). Touches SwarmBorrow's oaths
         (the "one seat" sentences) — re-swear, don't just re-record. **BUILT 2026-10-04** (`Swarm_pier_seats`, §0).
2. **Which Cave — the online one; a picker only when it matters.** Default to the one online. When there are
    **two or more Caves** and it's the first remote act this session, ask once: a **targeted-Cave control in
     Door** (the family list gains a "heists go here" mark). Fewer than two Caves: never shown.
   **RULED + BUILT 2026-10-03 ("it must be the place to put it if it's on the Crew structure") — the mark is a 🧲
    magnet, and "here instead" is just moving it.**  Big pile =
    trove = the body wearing the 🧲 (where originals land); small pile = pocket = the pool, configured by PoolFace's
     sentence.  ONE 🧲 per presser, on one row of Door's crew list (rows already show each body's organs); tap another
      row's slot to move it.  Candidates = my Caves + me if I have a folder; shown only at ≥2 candidates (so §4.2's
       "fewer than two: never shown" still holds for a no-folder phone with one Cave).  Default: the online Cave, else
        me-with-folder, else nobody → hearts wait (§4.3).  A per-Heist override rides the R2 form as "to [Inco ▾]" for the
         laptop-on-the-train case.  Stored as `Heist_defaults.to` (Dexie + Berth mirror, as lofi is).  Rejected: a cog
          or settings cell — a setting hides where things go; the magnet on the row SHOWS it.  Yay (what ♥ means) is a
           separate question from where it lands; don't fold them.
3. **Offline Cave — the Love stays unfulfilled.** No standing command (R-4): the heart on the heard Mag IS the
    durable want; a later "more of what you liked" exploration mode can review the unheisted pile. Rejected:
     LOFI-ing it all into the Captain's SP/OPFS meanwhile — correct but too hard to explain. The owner's hope,
      noted as a direction: visualised mechanisms (Cells showing the machinery) should make these cases legible
       without prose.
4. **Refusals — no disk-space question here.** Heisting lands in the collection, not the SP, so there's no
    budget to consult. Same-folder heuristics come later. **New idea recorded: "upgrade from LOFI"** — the Cave
     holds a lofi copy, the Captain asks for the original; a natural op once `exists` knows the format.
5. **Cancel vs delete.** Correction to §2's framing: Haul DOES have a disk delete — `wipe` on a landed album
    (`Heist_haul_wipe`, HaulFace), separate from the heist row's ✕ (which drops the keep and deletes nothing).
     **Ruling: remotely, a delete is a LOG, not an act** — the Cave records "Captain asked to delete X" and does
      nothing, until "the next level of music piracy business is presented as cellular machinery" (a Cell the
       Cave's own human can see and confirm).

---

## 5. What not to build

- **No shared/merged keep.** Both-sides-edit means conflict resolution, stale forms, and a remote ▶ racing the
   Cave's "leaving the cell starts it" rule. The whole point of rule 1 is never having to.
- **No read-only shop broadcast as the primary road.** It would be stale by construction and could not answer
   `exists`. (A glance-level "Inco is heisting 2 albums" on the Door can ride the organ wire later — that is
    presence, not control.)
- **No new frame type** unless the reach_done payload proves too small (check R1 first).

---

## 6. Touch points (read before building)

- `Ghost/S/Swarm.g` — `Swarm_reach_book` (~6776), the reach pump, `Swarm_reach_vouched`, `reach_done` build
   (~7180), `Swarm_reach_ack`; `Swarm_sibling_reach` (~7494) for body-addressed reaches.
- `Ghost/M/Heist.g` — the `Heist_keep_*` verbs (the doer's targets); `Heist_keep_born`; the leave-starts-it path
   (`Sounditron_leave_keep`, Sounditron.g) that R4 must not fight.
- `Ghost/M/Heard.g` — `Heard_keep` (the take mint R4 changes), `Heard_landed` + `Heard_shelf_index` (the
   `exists` join).
- `src/lib/O/ui/HeistFace.svelte` — the face R2's view reuses; `alreadyLofi` (2026-09-30) is the first fact it
   already derives from the source.
- `Ghost/Story/SwarmTesting.g` — where the two-body Books live (SwarmBorrow is the nearest template).
