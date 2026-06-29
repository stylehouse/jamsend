# Backbone build plan — Keep · Interest · Lens, as one spine

> **The fourth doc of the attention layer.** `Interest.md` is the channel, `Keeping_spec.md`
> the persistence, `Lang_handover.md` the editor surface, and the medium they act on (the
> Waft) is documented atop `Waft.svelte`. This is the **build order** that fuses the three:
> it extends `Keeping_spec.md`'s `## Phasing` (which covers only the four `req:Keeping`
> phases) outward to the resolver, the layout service, and the Interest/Lens thin clients.

**The spine in one line.** Make the Keep the single durable home of *where I am + how it's
laid out*, then re-found Interest's view and Lens's UI as **thin clients** that read that
home — building the foundation *beside* the old machine, proving each step with a headless
Book, cutting over once.

**Why these three move together.** They are not three backlogs; they are one mesh with a
handful of shared seams — the unified resolver, loose locators, the layout service,
per-(Interest, Waft) cursor-memory, the excitement dial. Build the seams once and the
Interest pop-back, the Lens layout clients, and per-Waft minimise all land as thin clients
on a proven base instead of three diverging persistence hacks.

## Two rails — do not violate

- **Stand new beside old, inert-check parity, *then* delete.** Never change the spine and
  rip out the old path in one step (the `c.up`-in-`i()` lesson, `Keeping_spec.md` §Phasing).
- **`%Spotlight` dissolution is a separate, later cut (P7).** Fold it into Keeping and you
  invert noun/projection — the *view* ends up owning the cursor. `Keeping_spec.md`
  §"dissolving Spotlight" scopes it as Phase 5+.

## Dependency graph

```
P0 ─┐
P1 ─┼─► P3 ─► P4 ─► P5 ─► P6 ─► (P7, later, separate)
P2 ─┘
        P0 + P2 run alongside P1; P2 is required before P3-resume and P6.
        Critical path: P1 → P3 → P4 → P5 → P6.
```

The discipline that makes it safe: **one `LakeKeep` Book that grows a phase at a time** —
the spine is *shown off* headless (the `Story_cli` / CredRunner family), never eyeballed,
and any regression bisects to a single phase. A `LakeKeep`-style Book is the gate, authored
*alongside* each phase, not after.

---

## P0 — clear the snags *(parallel, zero spine risk)*

- **Defuse Lens bomb 1.** Runner/Brink panels get a local `setInterval`→`now` `$state`
  (`onDestroy` cleanup) so liveness doesn't freeze off the `w` heartbeat. Unblocks every
  hoisted panel. (`Lens_handover.md` §Bombs 1.)
- **Delete the dead Sidetrack code** — `e_Lang_sprout_sidetrack` / `e_Lies_open_sidetrack`
  / `interest_sprout_sidetrack` + the `tentative` save-exemption — *before* we touch
  `interest_*`. (`Interest.md` top block.)
- **Gate:** LakeSurprise stays green; eyeball a Runner panel ageing past a run.

## P1 — the kind foundation *(finish + verify — `Keeping_spec.md` Phase 1 + gap 1)*

- **Goal:** a Waft knows its kind at load, **before any focus** — so background kinds
  (Keep, Cluster) get a carrier they'd otherwise never get (Keeping is attention-only).
- **Build:** the `Lies_waft_kind` un-blind is built (2026-06-28) but unverified and kind is
  still *inferred*. Make **`kind` a snapped sc field** + add the **w-level on-load
  kind-sweep**. Route the Keep (`kind:Keep`, line-shows) and the focus filter through the
  table. No req touched yet.
- **Gate:** `LakeKeep` asserts kind-classification + Keep `/**` in the snap, headless;
  `:9091` shows focus unchanged.

## P2 — the one resolver + loose locators *(keystone; standalone, parallel with P1)*

- **Goal:** stop three locator forks drifting before the Keep's makes a fourth.
- **Build:** one `resolve(locator)→particle` subsuming `Lies_locate_in_waft`
  (`what:What:<name>`), `%FromWhat` (`Waft:<key>/<mainkey>:<value>`), and the Text-Point
  `text:<word>` bridge (`Keeping_spec.md` rideable #7). **Loose / path-tolerant** — match by
  value, not hard path/ref — so a Waft rename never *blocks* a stored locator (the cheap
  half of rename-caretaking; the full caretaking pass is its own later work, #8). Repoint
  the three existing forks at it.
- **Gate:** a `LakeLocate` micro-Book round-trips each locator form *plus a rename*, headless.

## P3 — `req:Keeping` beside the old reqs *(parity, no cut — `Keeping_spec.md` Phase 2)*

- **Build:** stand the driver up deriving focus + convergence from the kind-table (P1) and
  resolver (P2). Leave `desire`/`acquire`/`timemachine`/`workon` present but
  **inert-checked** — assert Keeping reaches the *same* focus + convergence as today, every
  tick. App boots all pages. Introduce **`%Lango`** (the "move the show here" push, today
  `e_Lang_workon_update` — `Keeping_spec.md` D3) as Keeping's input term.
- **Gate:** `LakeKeep` grows a parity assertion (`old-focus == Keeping-focus`) across a
  focus-switch + cursor-resume, headless.

**The Lango channel — the form of `%Lango`.** `%Lango` generalises from the click-push to
the **universal attention-event**, sub-typed (`%Lango/%Cursor`, `%Lango/%Lens`,
`%Lango/%mode`) — so every editor move is one auditable event. One universal setter
`H.lango(target, what)` is the single funnel — a **homing helper over `i_elvis`**: where
`i_elvis_req` homes a *req* (the handle a reply rides back on), `H.lango` homes the
*`%Lango`* itself, **one-way, no reply handle** — the only "answer" is the show actually
moving, read back off the roster/Keep state. Every Lango originates **against a Waft**, and a
Waft has exactly **one carrier req** (next §) — so the source is always that carrier: a
Funkcion mints onto its Waft's carrier; a `req:Keeping**` stage onto the carrier of the Waft
it acts on; the **bare UI:Waft click** onto the same carrier (no special case — it's the
carrier's plainest use). All of them home to
**one sink: `req:Langoer` — `req:Keeping` wearing its receiver hat** (the noun below, *not* a
separate organ). That single convergence is where pull-policy lives — which Interest wins,
what the displaced focus does — and it hands the **levels** down to the Keep. Delivery rides
the **one-way** machinery (the `req:waft_roster` pattern — `i_elvisto` + `reqyoncile`, no
reply); the request/reply path (`o_elvis_req.finish` → `req.sc.reply` → `think{reqturn}`,
`Housing.svelte.ts:645`) is the rare Lango that needs an ack (e.g. the concentric-resume
content-wait). The Keep persists the **levels** (on-off standing state: foregrounded
Waft/What, plugged Lenses, layout) and resumes them; **impulses** (scroll, glance, one-shot
navigate) are consumed and forgotten — the discriminator is the Waft-vs-Interest border
(*"still true with no one looking?"*). The top of all Interests stays the **noun**
(`Languinio` → `LangCurse`'s) — `req:Langoer` is its driver; keep the noun/driver split. *(There is no separate "Tide" organ: the live
in-flight Langos + excitement are just the Keep's off-snap side — Keep↔Interest + the
channel is the whole machine.)*

> **Open — decide at build.** The *receiver* is never in question: it's always a held req,
> the convergence — `req:Langoer` = `req:Keeping`'s intake. What's open is the **residue**:
> does the *source* keep its emitted Langos as an origin trace (mint into its req's `.c`,
> off-snap) or fire and forget, and is there a Keep-side ledger of past Langos at all?
> *Lean:* source mints into `.c` (cheap origin trace), receiver consumes, **levels copy to
> the Keep, impulses drop** — the durable residue is the Keep's level state, no separate held
> "Lango set." And: does the channel ride the *same* Lang-side standing req as `waft_roster`
> (one wire, two payloads) or its own?

**The carrier — and most Funkcions need no req at all.** Today every Funkcion with a `run`
mints its *own* eternal `req:Funkcion,funk_id:<Waft>/<dip>` into `w/Funkcions`
(`Lies_register_funkcion`, `LiesFunk.svelte:154`) — so Credence snaps **48** of them, and each
one's pump (`storying_run`) re-scans *all* `run_result`s every tick only to bail unchanged
(`Storying.svelte:27`). That is a poll standing in for an event. Three buckets fix it, by what
a Funkcion actually needs:
- **No req — event/click-driven (the majority).** `Funkcion:Storying` is a verdict *mirror*:
  its value moves only when a run lands. Push it at the landing site (`Lies_run_result_recv` /
  `Lies_report_result`, `LiesFunk.svelte:921`/`916`) — find the Storying cells bound to that
  `book`/`path`, restamp `funk.c.verdict`; a click already re-runs the Book. → **zero reqs**
  for Credence's 48, and 48 fewer full scans per tick. (Ballistics, Ting, IdHatch already have
  no `run` — same bucket.) This is just [[req-not-mandatory]]: plain synchronous reflection is
  not a req.
- **`req:Waftica,waft:<path>` — one per Waft.** The base carrier: **owns** the Waft's `%Lango`
  (clicks + Funkcion intentions — the source the channel needs, present for *every* Waft
  including Funkcion-less ones), is the manual-pump entry for the bucket above, and **carries**
  the dominant-Funkcion identity `main:<kind>` (the `%Funkcion,main` child, or inferred by
  matching `Funkcion:<K>` against the Waft's snapped `kind` — that's "check `Funkcion:*`
  against projected-on properties", the property is `kind`). Cheap, mostly idle. Its
  once-a-tick walk also runs the *throttled pollers* that want a tick but no handshake —
  Shelver's 5-min walk, StoryTimes' sweep, CreduFunk — so they need no own req either.
- **`req:Liesica,funk_id` — only genuine handshake monitors.** Runner/Relay's peer pings
  actually use req finish/ttlilt/deps machinery, so they stay real per-Funkcion reqs. Few, and
  they live in the cluster Waft, not the test boards.

**Net for Credence: 48 → 1** (`req:Waftica,waft:Credence`; the board's Storying cells
event-driven, its Shelver/StoryTimes stations walked by Waftica, no Runner/Relay there). `c.up`
is free — `Funkcions.c.up = w` already stamped (`:159`). The one non-Waft host (the Seem-borne
`trail`) keeps a host-keyed `req:Waftica,host:<id>`. **Cost:** every `toc.snap` `Funkcions`
block re-shapes → a Story-snap re-record at landing (its own commit), and the Storying
event-push touches the verdict wire (`Editron` Phase 1) so it wants a green Credence run after.
Independent of `req:Keeping` → landable at P0/P1; drawn here because P3 is where the Lango
source needs it. *(Names `Waftica`/`Liesica` still soft.)*

**What `waft_roster` keeps vs sheds** *(rideable #6 made concrete)*. The wire stays; the
reducer hollows out. `interest_reconcile` lives at `Interest.svelte:111`, mixed in via
`M.eatfunc` — invisible to grep / `svelte-check` (the "does not exist on type House" noise),
**not** dead.
- **Keep (the set-sync core):** `interest_roster` / `interest_roster_sig` / `interest_push`
  — "paths + kinds of non-`equip` Wafts." `interest_roster` stops calling
  `interest_stance_of` (reads the snapped `kind`) and drops the `from` field.
- **Drop → the kind-table:** `interest_stance_of`, `interest_kind_from_stance`,
  `interest_face_for`, `interest_presence_for` (derivation the P1 table now owns; face is in
  `FUNK_KINDS`).
- **Delete → P0:** `interest_sprout_sidetrack` + the reverse-arrow bind inside
  `interest_reconcile` (the `Sidetrack && from` branch, the unbound-sprout skip) — ~half its body.
- **Migrate → the Lango channel:** `interest_cursor_for` (cursor placement *is* a
  `%Lango/%Cursor`) and `interest_foreground` (a `%Lango/%foreground` resolved by the
  Keeping convergence).
- **Migrate → the Keep:** the gone-epoch dance + per-Interest LE retirement
  (`Lang.svelte:1224–1262`) — Interest lifecycle is the Keep's now.
- **Net:** `interest_reconcile` collapses from a 48-line mint/bind/gone reducer to a thin
  membership sync.

## P4 — cut over + the one rename *(`Keeping_spec.md` Phase 3 + D7)*

- **Build:** delete `timemachine`'s playback (D1), fold land into step 3, retire the
  `desire`/`acquire` wrappers into Keeping — the Keep ledger is now the focus/cursor
  authority. Land the D7 renames in **one mechanical move**: new `LiesKeep` (the
  `Lies_keep_*` migrate in), `LiesHold→LangHold`, `Interest.svelte→LangCurse` (twin of
  `LiesCurse`).
- **Gate:** human re-records the Story snaps that asserted the old req shape; `LakeKeep`
  green on the new spine.

## P5 — the layout service *(the Keep↔Lens weld — `Lens_posable_TODO.md`)*

- **Build:** `(scope, key)→get/set` backed by the Keep, **hosted by the Keep's own
  Funkcion** — at hoist it reads layout → suggests the Lens with it; on a user gesture it
  writes back + re-suggests. **Coalesce / write-only-on-user-change** so the `ave`(live) ↔
  Keep(snap) loop doesn't feed back (the `Lies_keep_push_cursor` discipline). Three scopes:
  per-Waft→`WaftTimes`; per-Lens→`Keep/Layout,of_Lens:<id>`; global chrome→Keep
  top-level / `stashed`. **No clients yet** — prove the service shape first (the user defer).
- **Gate:** `LakeKeep` asserts a `set → snap → reopen → get` round-trip for one of each
  scope, headless.

## P6 — the thin clients *(the payoff — each small on the proven base)*

- **per-Waft minimise / scroll** (`Keeping_spec.md` rideable #3) — first net-new client,
  proves the service end-to-end.
- **Interest pop-back**: `%FromWhat` click-through + **per-(Interest, Waft) cursor-memory**
  (now trivial on resolver + Keep). Fixes nav friction **3a** (stance-aware Doc-open holds
  `active`) and **3b** (no more land-on-`wafts[0]`). (`Interest.md` "Rejoin the stack
  frame"; `Lens_posable_TODO.md` §3.)
- **What↔Doc-last** tracking → the **Interest-Docs mini-GhostList** in the Brink, gated by
  the **excitement dial** (`Lens_posable_TODO.md` §2).
- **Lens layout clients**: Brink pose, Waft capped/sidebyside, Langui minimap_open, DocTing
  open/sort, MiniWaft orbed, InterestStrip show_cold — bind to P5 instead of vanishing on
  reload.
- **Gate:** each client adds one step to `LakeKeep` / `LakeSurprise`; the growing set *is*
  the regression wall.

## P7 — dissolve `%Spotlight` *(separate, deferred — only after the Keep is the proven cursor-truth)*

- Make the Keep ledger head the cursor's durable truth; `%Spotlight` and Interest
  `in_Doc`/`in_Point` degrade to ephemeral projections (resolve address→ref on demand via
  P2). Touches every Spotlight reader (`Lies_focus_waft`, the want-land seam, havoc's
  `engaged_what`) — its own build, its own gate. Sketch now, cut last.
  (`Keeping_spec.md` §"dissolving Spotlight", Phase 5+.)

---

## Open decisions & deferred-by-design

**Decide before / during the build (small forks, near-term):**
- **Lango residue** — the *receiver* (`req:Langoer` = `req:Keeping`'s intake) is always held;
  open is whether the *source* keeps an origin trace + whether there's a Keep-side Lango
  ledger (lean: source mints into `.c`, levels copy to the Keep, impulses drop), and whether
  the channel rides the same wire as `req:waft_roster`. (P3, above.)
- **The carrier / de-req-ifying the pump** *(resolved — Storying & mirrors event-driven, zero
  reqs; one `req:Waftica,waft:<path>` per Waft owns `%Lango` + walks the throttled pollers;
  `req:Liesica,funk_id` only for handshake monitors → Credence 48→1)*. Open sub-bits: the names
  (`Waftica`/`Liesica`), and it re-shapes every `Funkcions` snap block + touches the verdict
  wire → a Story-snap re-record + green Credence run at landing (own commit). (P3 — landable at
  P0/P1.)
- **The Shelver ledger** *(resolved — `%shelved` tombstones dropped; presence is the
  `Funkcion:Storying,of_Book` cells on the board)*. Trade: a hand-deleted Book re-files on the
  next sweep. Done in `Funk/Shelver.svelte`.
- **`Languinio` under the rename** — does the noun keep its name (owned by `LangCurse`) or
  rename too? D7 names the *files*, not this particle. (P4.)

**Deferred by design — parked, not gaps (don't build until pulled forward):**
- **Excitement / awakeness levels** — the gradient math (rise, the MRU budget on the awake
  set, the escalation threshold) is black-boxed; it's numbers on the active Interests/Langos
  off the Keep, read by the convergence. Slots into P6's excitement dial. (`Lens_handover.md`,
  `Lens_posable_TODO.md` §2.)
- **Escalation policy** — when a backgrounded Funkcion raises its own tide, badge vs pop vs
  steal-focus, scaled to budget; `surprise_read` is the one built instance. (`Interest.md` §4.)
- **Full rename-caretaking** — P2's loose locators are the *stopgap* (match by value, never
  blocked); the reference-caretaking pass that survives a Waft/What rename is its own later
  work serving cursor-memory + the Aside home + the layout service. (`Keeping_spec.md` #8.)
- **Per-deck Aside LEs + the dual-LE push-mutex** — a true simultaneous two-deck push is
  undesigned. (`Interest.md` "Per-deck Aside LEs".)
- **The posable-torus layout grammar** (Decor / Brink / Mapping poses) — explicitly
  *needs cooking*; design the pose/anchor model before any build. (`Lens_posable_TODO.md`.)

Everything else in P0–P7 is designed to the depth the phase needs; the gate Book per phase
is the proof it stayed honest.
