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

- **Defuse Lens bomb 1.** ✅ **DONE already** (2026-06-29 audit) — `Runner.svelte:50-53` /
  `Relay.svelte:31-33` already carry the local `now = $state` + `setInterval(1s)` + `onDestroy`
  ticker (Relay comments it "the Runner-bomb fix"). Liveness no longer freezes off `w`. No work.
- **Delete the dead Sidetrack code** — ⚠️ **NOT dead** (2026-06-29 audit). `interest_sprout_sidetrack`
  *is* genuinely undefined (so `e_Lang_sprout_sidetrack` throws/no-ops), BUT **`LakeSurprise`
  drives the path**: Prep 7 `e_Lang_sprout_sidetrack`, Prep 8 `e_Lies_open_sidetrack` (mints the
  `Interestily/side` `tentative` Waft), Prep 9 foregrounds it. So this is NOT a clean removal —
  it needs the two handlers + the `tentative` save-exemption deleted **and** LakeSurprise's
  Preps 7–9 scrubbed + the Book re-recorded (the gate below is real). Own chunk; host green-run
  tail. (`Interest.md` §14-15/§82-86 still mis-call it "dead code to delete" — correct on landing.)
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

> **Status (2026-06-29) — largely SUPERSEDED, like P0.** Two findings on contact:
> (1) **`Lies_waft_kind`/`LIES_KIND_CAPS` are GONE** — the kind-table was collapsed to the one
> **`%equip`** durable flag (2026-06-28); `equip:Keep`/`equip:Cluster` carry the type-name AND mean
> "out of the cursor's way." The focus filter, Waft count, load-Good fold + want-land all already route
> through `!wf.sc.equip` (`Lies.svelte:648/752/960/998`). So "route the Keep + focus filter through the
> table" is **done** by the collapse.
> (2) **The Goal — "background kinds get a carrier they'd otherwise never get" — is already met by the
> P3-forerunner Chunk 1**: *every* Waft, background or not, gets a `req:Waftica` carrier at load
> (`Lies_instantiate_funkcions` → `Lies_ensure_waftica`, fired from `Lies.svelte:755`). The kind-sweep
> was the *means*; the goal arrived another way.
> **What's genuinely left** is a true OWNER FORK, not a safe build: a snapped **`kind`** field (the
> type-name for *foreground* Wafts too, distinct from the `%equip` attention-flag) would add a `kind:`
> key to **every Waft in every Book's `toc.snap`** — a fleet-wide snap re-record — and its shape vs the
> `%equip` collapse is the owner's call. Deferred to the owner (it's the face-wrangler's input — derive
> faces from kind — not blocking P3). One dead remnant worth noting: the Waftica carrier's
> `main:<kind>` inference reads `waft.sc.kind` (`LiesFunk.svelte:171`), which is never set today, so
> that half is inert until the fork lands. **Verify half DONE: `Story:LakeKeep`** — an in-system Story
> Book (`Run_A_LakeKeep` + `e_Lies_keep_selftest` in `test/Machinery.svelte`, recorded via
> `Story_cli_run.mjs LakeKeep --accept`) over the *existing* equip/carrier behaviour. **Green**
> (`match 1/1`), markers under `KeepGate`: `background_Waft_gets_a_carrier` (the P1 goal — a fresh
> `equip` Waft, run through the real `instantiate→ensure_waftica`, gets its `req:Waftica`),
> `loaded_Waft_gets_a_carrier` (the auto-loaded GhostList's carrier), `equip_out_plain_in_focus` (the
> `%equip` focus-classification). So P1 is **functionally done + verified** bar the owner's snapped-`kind`
> fork.

## P2 — the one resolver + loose locators *(keystone; standalone, parallel with P1)*

- **Goal:** stop three locator forks drifting before the Keep's makes a fourth.
- **Build:** one `resolve(locator)→particle` subsuming `Lies_locate_in_waft`
  (`what:What:<name>`), `%FromWhat` (`Waft:<key>/<mainkey>:<value>`), and the Text-Point
  `text:<word>` bridge (`Keeping_spec.md` rideable #7). **Loose / path-tolerant** — match by
  value, not hard path/ref — so a Waft rename never *blocks* a stored locator (the cheap
  half of rename-caretaking; the full caretaking pass is its own later work, #8). Repoint
  the three existing forks at it.
- **Gate:** a `LakeLocate` micro-Book round-trips each locator form *plus a rename*, headless.

> **Status (2026-06-29). BUILT + headless-green.** `Lies_resolve_locator(w, locator, scope?)`
> (`Lies.svelte`, beside `Lies_locate_in_waft`) is the one resolver: `<mainkey>:<value>` in a scope
> (delegates to `Lies_locate_in_waft`) · `Waft:<key>[/tail]` (Waft named by value, recurse the tail)
> · `text:<word>` (loose substring over mainkey-values; the ranked def|call|comment search stays a
> future subsystem). Loose by contract — matches by value, never throws, an unresolvable locator → undefined
> (caller lands on first), so a rename degrades not blocks. **Only Fork 1 was a live repoint** —
> `Lies_keep_resume_what` now goes through it; **`%FromWhat` was write-only** (Lies.svelte:305 writes,
> nothing read it back), so the resolver is the *reader it was waiting for*, not a replacement; **`text:`
> is born here.** Gate = **`Story:LakeLocate`** — a real in-system Story Book run by the actual runner
> (`Run_A_LakeLocate` + the `e_Lies_locate_selftest` Prep handler in `test/Machinery.svelte`; recorded
> via `node scripts/Story_cli_run.mjs LakeLocate --accept`). It drives the resolver through all three
> forms + a rename and witnesses each passing claim as a durable marker under `LocateGate` — the
> snap-fixture diff is the gate. **Green** (`match 1/1`), 73-line snap (GhostList + the equip test Wafts
> folded). *(An earlier `scripts/LakeLocate.spec.ts` was scrapped — a scratch vitest spec is the
> scattered-`.ts` anti-pattern; the gate belongs inside the machine.)* Uncommitted; `:9091`-unverified
> (the resolver has no live consumer beyond Fork 1 yet — P3's Keeping is its first big caller).

## P3 — `req:Keeping` beside the old reqs *(parity, no cut — `Keeping_spec.md` Phase 2)*

- **Build, in two steps.** *(a)* **The channel first** — the decided, low-risk piece (it
  touches no live focus path until anyone reads it): one universal setter `H.lango(target,
  what)` minting the `/%Lango` **source terminal** onto the causing Waft's carrier (`i_elvis_req`
  shape, off-snap), with the **yoink / out-compete** lifecycle (later-Lango-wins within an
  Interest; the cross-Interest race deferred to `req:Langoer`). Today's click-push
  (`e:Lang_lango` — `Keeping_spec.md` D3) becomes one caller of it, the input term.
  Gate with its own Book. *(b)* **The parity driver — owner-supervised** — stand `req:Keeping`
  up deriving focus + convergence from the kind-table (P1) and resolver (P2), `desire`/`acquire`/
  `timemachine`/`workon` left present but **inert-checked**: assert Keeping reaches the *same*
  focus + convergence as today, every tick, app boots all pages. (Touches the live focus path →
  not landed unsupervised.)
- **Gate:** the channel Book asserts mint → yoink → out-compete on the terminal; then `LakeKeep`
  grows the parity assertion (`old-focus == Keeping-focus`) across a focus-switch + cursor-resume,
  headless.

**What a `%Lango` is.** An **intent to do something with a piece of the source**, *tracked
over time* — not an instantaneous setter call but a thing with a life: minted, contended,
landed, reconciled, retired. Its **life and times play out in the KeepingInterest vortex**
(the Keep×Interest off-snap side, §below) — that vortex *is* where Langos live; the source
terminal is only where one is born and held.

**The Lango channel — the form of `%Lango`.** `%Lango` generalises from the click-push to
the **universal attention-event**, sub-typed (`%Lango/%Cursor`, `%Lango/%Lens`,
`%Lango/%mode`) — so every editor move is one auditable event. One universal setter
`H.lango(target, what)` is the single funnel — a **homing helper over `i_elvis`**: where
`i_elvis_req` homes a *req* (the handle a reply rides back on), `H.lango` homes the
*`%Lango`* itself, **one-way by default**, no reply handle — the only "answer" is the show
actually moving, read back off the roster/Keep state; a Lango that genuinely needs to know
*how* it landed grows the `/landing,req` ack below. Every Lango originates **against a Waft**, and a
Waft has exactly **one carrier req** (next §) — so the source is always that carrier: a
Funkcion mints onto its Waft's carrier; a `req:Keeping**` stage onto the carrier of the Waft
it acts on; the **bare UI:Waft click** onto the same carrier (no special case — it's the
carrier's plainest use). All of them home to
**one sink: `req:Langoer` — `req:Keeping` wearing its receiver hat** (the noun below, *not* a
separate organ). That single convergence is where pull-policy lives — which Interest wins,
what the displaced focus does — and it hands the **levels** down to the Keep. Delivery rides
the **one-way** machinery (the `req:waft_roster` pattern — `i_elvisto` + `reqyoncile`, no
reply); the request/reply path (`o_elvis_req.finish` → `req.sc.reply` → `think{reqturn}`,
`Housing.svelte.ts:645`) is the rare Lango that needs an ack — and that ack has a **shape**:
the source's `Lango,req` hosts a child **`/landing,req,maz=7`** that the *remote* side (the
receiver, doing the actual landing) drives and **reqyonciles** back up to the `Lango,req` —
*"this is how I landed."* Same handshake as `o_elvis_req`'s reply, expressed as a nested req
in the maz stack rather than a cross-ghost elvis (e.g. the concentric-resume content-wait). The Keep persists the **levels** (on-off standing state: foregrounded
Waft/What, plugged Lenses, layout) and resumes them; **impulses** (scroll, glance, one-shot
navigate) are consumed and forgotten — the discriminator is the Waft-vs-Interest border
(*"still true with no one looking?"*). The top of all Interests stays the **noun**
(`Languinio` → `LangCurse`'s) — `req:Langoer` is its driver; keep the noun/driver split. *(There is no separate "Tide" organ: the live
in-flight Langos + excitement are just the Keep's off-snap side — Keep↔Interest + the
channel is the whole machine.)*

> **Decided (2026-06-29, owner).** The *receiver* was never in question — always the held
> convergence `req:Langoer` = `req:Keeping`'s intake. The **residue** is now settled two ways:
> - **No Keep-side ledger of Langos.** The only durable Keep residue is the **level state**;
>   the Keep's own `%Cursor` resurrects the **first bit** of a `%Lango` (which Waft/What to
>   re-land on) — "the rest is wild": impulses (scroll, glance, the inner reach) are consumed
>   and forgotten, never logged.
> - **But the *source* keeps a live trace.** The causing Waft/Funkcion's `req**` (its Waftica
>   carrier, next §) **hosts** the in-flight `/%Lango` as an *object* — a **source terminal**,
>   shaped like `i_elvis_req`: where `i_elvis_req` hangs a `req` handle the reply rides back on,
>   the terminal hangs the `%Lango` itself. Not fire-and-forget — a held thing with a
>   **lifecycle**: it can be **yoinked** (the source cancels), **Ctrl-Z'd** (undo — TODO,
>   gated on the minimap/Lens having focus, not CodeMirror), or **out-competed** — by another
>   **Interest** (cross-Interest pull-policy, decided at `req:Langoer`) or by another `%Lango`
>   in the **same** Interest (intra-Interest supersede). When it loses, it leaves no ledger —
>   only whatever **level** it managed to push to the Keep.
>
> Still small-open: whether the channel rides the *same* Lang-side standing req as
> `waft_roster` (one wire, two payloads) or its own — a delivery detail, settle at build.
>
> And a deeper seed, *not yet needed*: if a single Lango's **landing gets shared across too
> many parties** (several Interests, several pieces of the source at once), there may need to
> be an **algebra of where-to-do-what** — how the landing work is placed and divided. Park it
> until a real case forces it; the maz-stack `/landing,req` is the hook it would grow on.

**`req:Langoer` — the convergence, decided (2026-06-29).** Not a new organ — `req:Keeping`'s
**receiver hat**, its steps 2→4 (`focus → land → converge`, `Keeping_spec.md`), named for the
intake. It already exists *in embryo*: today's `Lies_focus_waft` (`Lies.svelte:990`) +
`Lang_set_interest` (`LangHold.svelte:490`) + `req:workon` (`LangHold.svelte:84`) **are** it;
Langoer just hands them the `%Lango` as their one input. The three open questions resolve off
that existing machinery — the "bring forward what's most-like-it" rule, here literally:

- **Which Interest wins (pull-policy) — the newest focus-Lango, among foregroundables only.**
  `Lies_focus_waft` is *already* the sole selector: `.sc.active` (exactly one Waft bears it) →
  the cursor's own Waft → first non-`equip`. A focus-Lango (`%Lango/%Cursor`) just sets its
  target as the sole `.sc.active` (Keeping the sole writer) — so the **newest** focus-Lango
  wins, *within* an Interest (the cursor moves) or *across* one (ActiveInterest hops). `equip`
  Wafts (Keep/Cluster) are filtered out: **background never steals the foreground** (Upkeep/
  Errand contend at the Brink, a different pole — [[upkeep-errand-brink]]). And **not every
  Lango is a focus-pull**: `%Lango/%Lens` and `%Lango/%mode` set a *level on the current focus*
  without moving it — only `%Lango/%Cursor` runs this pull-policy.
- **What displaced focus does — demote-warm, never drop.** `Lang_set_interest` already does it:
  the left foreground goes `locked → pending` (its cap collapses) but **keeps its own `%LE`**
  (working clone intact) for an instant **crossfade-back**, stays in the roster (still a nib),
  and its **level** is recorded to the Keep (`%Cursor` + `accessed_at`). So a *warm* return
  re-lands off the live LE; a *cold* one off the ledger's "first bit". The loser recedes, loses
  nothing — which is exactly why there's no Lango ledger: the level *is* the memory.
- **One-wire-vs-two — dissolved: one owner, two intake faces.** The question presumed Langoer
  is a wire. It isn't: `req:Keeping` owns *both* the attention-event intake (a `%Lango` →
  focus/converge) *and* the roster-set intake (`interest_roster_sig` → `interest_reconcile`).
  Different triggers, different steps, **one walk** — so it neither "shares the roster wire" nor
  "runs its own": two faces of the one req. The source terminal's `/landing,req` ack reqyonciles
  back **up that same walk**, landing in Keeping's converge band (the maz-low end of its 9→1
  span, `Keeping_spec.md` — so the `maz=7` guess sits *between* the acquire-gate (9) and converge
  (~1); pin the exact level at build).

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
  not a req. **A Funkcion *at rest* is a mirror — no req.** The instant it has **excitement**
  (a button click, an intention to *move the show*) that excitement *is* req-shaped — but it
  still needs no req of its *own*: it hosts its `/%Lango` on the Waft's one carrier (next §),
  the source terminal. Rest → none; excited → the carrier's terminal holds the live Lango.
- **`req:Waftica,waft:<path>` — one per Waft.** The base carrier: **owns** the Waft's `%Lango`
  (clicks + Funkcion intentions — the source the channel needs, present for *every* Waft
  including Funkcion-less ones), is the manual-pump entry for the bucket above, and **carries**
  the dominant-Funkcion identity `main:<kind>` (the `%Funkcion,main` child, or inferred by
  matching `Funkcion:<K>` against the Waft's snapped `kind` — that's "check `Funkcion:*`
  against projected-on properties", the property is `kind`). Cheap, mostly idle. Its
  once-a-tick walk also runs the *throttled pollers* that want a tick but no handshake —
  Shelver's 5-min walk, StoryTimes' sweep, CreduFunk — so they need no own req either.
- **`req:Liesica` — checked, unnecessary.** Runner/Relay's runs use *no* req machinery (no
  `finish`/`ttlilt`/`doai`) — they're plain `(host,funk,ww)` like `storying_run`. So every
  Funkcion just rides its Waft's `req:Waftica` walk; *no* per-Funkcion req survives. (Name kept
  noted only in case a future monitor genuinely needs a handshake req.)

**Net for Credence: 48 → 1** (`req:Waftica,waft:Credence`; the board's Storying cells
event-driven, its Shelver/StoryTimes stations walked by Waftica, no Runner/Relay there). `c.up`
is free — `Funkcions.c.up = w` already stamped (`:159`). The one non-Waft host (the Seem-borne
`trail`) keeps a host-keyed `req:Waftica,host:<id>`. **Cost:** every `toc.snap` `Funkcions`
block re-shapes → a Story-snap re-record at landing (its own commit), and the Storying
event-push touches the verdict wire (`Editron` Phase 1) so it wants a green Credence run after.
Independent of `req:Keeping` → landable at P0/P1; drawn here because P3 is where the Lango
source needs it. *(Name `Waftica` still soft.)*

> **Status (2026-06-29).** **Chunk 1 BUILT** — `Lies_ensure_waftica` replaces
> `Lies_register_funkcion` in `LiesFunk.svelte` (per-Waft carrier + walk + stale-`req:Funkcion`
> migration + `main:<kind>`), the two callers (`Lies_instantiate_funkcions`, `GhostList_funkcion`)
> rewired, `Lies_aim_setup`'s cluster path inherits it. Behavior-preserving (same runs, same
> order; the Storying poll still runs *inside* the walk).
> **Chunk 2 BUILT** — Storying dropped from `FUNK_KINDS` `run` (no longer pumped);
> `Lies_reflect_storying(w, sel?)` walks `w`'s Wafts and restamps the matching Storying cells via
> `storying_run`. Wired at the **one** landing site `Lies_run_result_recv` (`run_result` is created
> nowhere else — `Lies_report_result` is the runner-emit, it stamps nothing) + a load-time pass in
> `Lies_instantiate_funkcions` (a freshly-loaded/edited board lights up from results already
> present). The 48 per-tick Storying scans are gone; CreduFunk/StoryTimes stay pumped (they read
> `run_result` directly, independent of the poll). Both chunks Svelte-compile clean; full typecheck
> OOMs here (verify on host) and they're `:9091`-unverified — want a green Credence run. Chunk 2
> touches the `Editron` verdict wire, so that run is the gate. User confirms Storying|StoryTimes
> works fine today (the baseline to preserve).
>
> **Channel BUILT (2026-06-29) — step (a), the decided half, kept minimal.** `H.lango(w, source,
> what)` in `LiesFunk.svelte` (beside `Lies_ensure_waftica`): mints a `%Lango,<kind>` (with `what.to`
> the target locator) onto the source Waft's `req:Waftica` carrier (the **source terminal**),
> out-competing any same-kind prior (newest-wins). **Reads no focus** — the carrier walk steps over a
> `%Lango` (no `funk.c.run`), so it's pure additive scaffold until `req:Langoer` reads it. Gated by
> **`Story:LakeLango`** (`Run_A_LakeLango` + `e_Lies_lango_selftest` in `test/Machinery.svelte`,
> recorded `node scripts/Story_cli_run.mjs LakeLango --accept`): GREEN 1/1, three markers under
> `LangoGate` (mint · same-kind out-compete · different-kind coexist), the terminal end-state in
> `001.snap` the gate. Svelte-compile clean (the green run proves it). **Deliberately NOT built — no
> consumer yet, and most `%Lango` is fire-and-forget:** the `/landing,req` ack + its `lango_land`
> reqyoncile (the *rare* ack), and `lango_yoink` (a source cancel — likely a close-button on an
> Interest). **Also pending:** the click-push (`e:Lang_lango`, renamed 2026-06-29) becoming a
> `H.lango` *caller* — minting a real `%Lango` instead of just seeding `workon.c.src` (first
> hot-path touch), and step (b) the parity driver (owner-supervised).
>
> **The boomerang — req:Langoer's acceptance test (owner-reported 2026-06-29).** Live symptom:
> focus "switches back to Radiola.g when I want to look at anything else, then boomerangs back for
> one think() in ten." **Diagnosed** (static): focus is `Lies_focus_waft` leg-1 `.sc.active`, and
> `req_timemachine` re-lands the cursor on it *every tick* (`Lies_desire_land_cursor`). `.sc.active`
> was written from **5 scattered sites with no arbiter** (open · Aside · +Now · want-land · the
> Liesui list), with a leg-3 fallback to `wafts[0]`. So a stray re-assertion (e.g. the Keep's
> resume-`want` at `Lies_open_Waft` re-minting a `cold` want into a re-opened Waft) **or** a one-tick
> active-gap → `wafts[0]` snaps focus back for a think. **NOT a Funkcion** — grep confirms nothing in
> `Funk/`/`gen/` touches `want`/`Spotlight`/`active`, so the caster isn't grabbing focus directly;
> it's purely the no-arbiter `.sc.active` free-for-all. This **is** the thing `req:Langoer` exists to
> kill: one arbitrated which-wins. Acceptance test for step (b): *focus, once moved to B, stays B
> across ticks — never falls back to `wafts[0]` and never gets out-competed by a background re-open.*
>
> **Write-chokepoint seeded (2026-06-29, behavior-preserving).** `Lies_set_active_waft(w, waft)` in
> `Lies.svelte` (the write twin of `Lies_focus_waft`): the 5 hand-rolled `delete-all-then-set` sites
> now funnel through it, so `req:Langoer` has **one** place to govern instead of a 5-site hunt (and
> any active-*gap* boomerang dies — clear+set is now atomic in one call). Pure extraction (LakeLango
> byte-identical bar the pre-existing flaky `round` + GhostList-read drift); callers keep their own
> `bump_version()`. It does **not** yet fix the boomerang behaviorally — it's the chokepoint the fix
> (Langoer governing *who* may claim active) will sit on.
>
> **Design note for the feed — the cursor `%Lango` is OBSERVABLE (snapped), NOT hidden in `.c`.**
> *(Corrected 2026-06-29 — owner: "things should be observable; we don't treat the architecture
> showing up in snaps as noise pollution." The earlier ".c / impulse-drop" lean was treating real
> focus state as noise = backwards.)* The cursor move mints a normal snapped `%Lango/%Cursor` on the
> source terminal via `H.lango` **as built** — **out-compete bounds it** (one Cursor per Waft carrier,
> newest-wins, never accumulates); its ordering `seq` is the one non-deterministic field → **mung it**
> in fixtures (the standard `age`/`at` pattern), so the structure stays visible while the snap stays
> deterministic. Re-recording fixtures to show the Langos is *real focus state becoming legible* — a
> feature, **especially since today's `.sc.active` is a `SESSION_KEY` (`Text.svelte`), omitted from
> the snap entirely**, which is exactly why the boomerang is slippery (no snap line shows the flag
> flicker). `req:Langoer` then arbitrates off the **observable** Langos (highest `seq` wins,
> foregroundables only), not a hidden free-for-all. "Impulses drop" was only ever about the **Keep**
> not hoarding every twitch (it persists the cursor *level*/resume-point) — never about hiding the
> live intent. `.c` is for refs/backlinks that can't encode (`lango.c.source`), not for keeping state
> out of view. **Net: no `.c`, no `dontSnap` — just call `H.lango` from the seam (with a `seq`); the
> '.c fork' dissolves.** Open (the better question): should focus itself stop being the invisible
> session-only `.sc.active` and become a *visible* particle Langoer derives from the Langos? — yes,
> the heart of step (b).
>
> **Handover (2026-06-29 — the way out from here).** *Arc:* this session laid the **prerequisites**
> for `req:Langoer` (the observable focus arbiter) — the `H.lango` channel, the `e:Lang_lango` rename,
> the `Lies_set_active_waft` write-chokepoint — and corrected one **value**: focus state must be
> OBSERVABLE (snapped), not hidden in `.c`. The organ itself is still ahead.
>
> **THE BOMB — our gates were green in a BUBBLE.** Every "Lake\* GREEN 1/1" above was
> `scripts/Story_cli_run.mjs`: a headless node+jsdom boot that reads the wormhole off disk, loads the
> GhostList, and quiesces at `round=8`. A **real** Lies%runner request — `scripts/runner_ask.mjs run
> LakeLango`, the live browser runner over `/relay` (owner banned the headless CLI) — quiesces at
> `round=4` with NO GhostList and `acquire` unfinished, so the same fixtures go **ALL-RED** (the
> GhostList Good/dirlist-Funkcion/desire-Waft/o_elvis + boot-progress diverge — though the test
> *markers themselves pass*). **Verify via `runner_ask.mjs`, never Story_cli** (now canonical in
> `CLAUDE.md`). The GhostList dige-spay I added to `Story.svelte` this session is a band-aid on the
> headless-only symptom — reconsider/drop it once the gate is real.
>
> **NEXT MOVES (in order):**
> 1. **Re-establish the Lake\* gates on the LIVE runner.** Either fold the WHOLE GhostList footprint
>    (Good + dirlist Funkcion + desire-Waft + o_elvis, and normalize `acquire,finished` + the Waft
>    count) so the snap is environment-independent (headless ≡ live) — better, because the GhostList
>    load is the extra work that diverges them, so folding also makes headless quiesce early like the
>    runner — OR re-record fixtures from the live runner. Until this, **no Lake\* gate is trustworthy.**
> 2. **Wire the observable cursor feed:** `Lies_i_Spotlight` → `H.lango(w, sourceWaft, {kind:'Cursor',
>    to, seq})` — snapped, out-competed, `seq` munged. The `to` is a P2 `Lies_resolve_locator` locator
>    (`Waft:<key>/<mainkey>:<value>`, built like `%FromWhat` at `Lies.svelte:302`).
> 3. **Build `req:Langoer`** = `req:Keeping`'s receiver hat: read the observable Cursor Langos, pick
>    the highest-`seq` foregroundable, drive `Lies_set_active_waft` (the chokepoint). Candidate
>    quick-win to try BEFORE the full organ: **kind-gate the want-resolver's active-claim**
>    (`Lies.svelte` ~958) so a background `cold` resume-want can't out-claim the user's foreground —
>    likely THE boomerang. (Live-focus → verify on a real runner.)
> 4. **Make focus visible:** retire the session-only `.sc.active` (a `SESSION_KEY`, `Text.svelte:349`)
>    for a snapped particle Langoer derives — the observability fix the boomerang's invisibility argues for.

> **BUILT (2026-06-30) — req:Langoer the receiver, standing BESIDE the old path; live-runner green.**
> The consumer the channel was waiting for now exists and is proven productive — a `%Lango` finally
> *becomes something*:
> - `H.lango` gains a per-`w` monotonic **`seq`** (counter off-snap on `w.c.lango_seq`, value SNAPPED
>   on each Lango) — the cross-carrier "globally-newest wins" tiebreak (out-compete only orders within
>   one carrier). Munged in fixtures via a new `Lango`→`seq` rule in `Story.svelte` `story_matching`
>   (its base churns with boot cursor activity, like `round`/`at`).
> - **`Lies_langoer_focus(w)`** (`Lies.svelte`, beside `Lies_focus_waft`) — PURE read: gather every
>   `%Lango/%Cursor` on the `req:Waftica` carriers, pick the highest-`seq` whose **source Waft is
>   foregroundable (not `%equip`)**. Reads only snapped fields (`carrier.sc.waft`, `cursor.sc.seq`), so
>   it survives reload. The two filters earn their keep: equip → *background never steals foreground*
>   (the resume-want boomerang's mechanism); `seq` orders across carriers.
> - **`req_Langoer(req)`** — `req:Keeping`'s receiver hat (string-req → name-convention do_fn): each
>   tick records the winner as its OWN snapped verdict `req:Langoer,focus:<waft>`. **It does NOT yet
>   write `.sc.active`** — stands beside the old want-resolver claim, observing, zero live-focus risk.
>   `Lies_set_active_waft`'s docstring now points at it as the arbiter.
> - **The boomerang POLICY is now IN the arbiter (proven, not yet wired).** `H.lango` learned `cold`
>   (a resume/boot Cursor, snapped flag). `Lies_langoer_focus` ranks in three tiers: equip never wins ·
>   **a deliberate (non-cold) Cursor outranks any `cold` one regardless of seq** · newest within a kind.
>   So mid-session a deliberate move outranks a later cold re-open (no boomerang); on boot only cold
>   Cursors exist → newest cold wins → the remembered spot resumes. This is the receiver's half of the
>   boomerang fix — the genuinely-hard focus policy — encoded and proven BEFORE any live-focus cut.
>   *Why not the live cut here:* a naive "cold yields to any active foreground" guard breaks boot-resume
>   (acquire sets `active` to an arbitrary first-Waft before the cold resume lands); the correct policy
>   needs the deliberate-vs-cold distinction above, and flipping it on live still wants `:9091` eyes.
> - **Gate mutated + live-runner GREEN:** `LakeLango` gained a foregroundable source (`LangoFore`) +
>   the receiver half — 4 new markers `cursor_lango_drives_focus` · `equip_source_never_focuses` (the
>   equip Cursor is *newer* yet loses) · `newest_fg_cursor_wins` · `deliberate_beats_newer_cold` (a
>   newest-of-all `cold` Cursor does NOT unseat the deliberate leader). Re-recorded via `runner_ask.mjs
>   accept` (on-disk `001.snap` matches the live got_snap byte-for-byte; step dige
>   `a692157e3cff7709`). The snap makes the **divergence legible**: the old `req:desire` locked
>   `Waft:LangoFore` (arbitrary first-Waft) while `req:Langoer` says `focus:LangoFore2` (newest intent)
>   — the boomerang in miniature, with Langoer right. Adding foregroundable Wafts also *woke* the real
>   focus machinery (acquire finished, timemachine seeded, two `Interest:Trail` in A:Lang) — state now
>   flows to Lang. Type-clean (no new svelte-check errors in the 4 edited files); uncommitted.
> - **FEED + SEED BUILT (2026-06-30) — Moves 2 + the auto-seed, still observe-only.**
>   (i) the global cursor feed is live: `Lies_resolve_wants` (the single want-land seam, where every
>      cursor move funnels) now mints a Cursor `%Lango` on the landed Waft's carrier via `H.lango(w,
>      landed, {kind:'Cursor', to, cold})`, `cold` riding straight from the want kind (`kind:'cold'`
>      resume/boot → cold Cursor). (ii) `req:Langoer` is auto-seeded on every `w:Lies` and driven right
>      after the resolver, so its verdict is fresh same-tick. **Still observe-only** — Langoer records
>      `req:Langoer,focus`; `Lies_set_active_waft` stays the authoritative `.sc.active` write. Type-clean;
>      LakeLango stays green (its synthetic `w:Lies` has no Keep/wants, so the feed no-ops there and the
>      auto-seed merges with the selftest's manual `req:Langoer` — a no-regression, not a positive proof).
>   **Owed:** the feed shifts every *real-editor* `w:Lies` snap (Cursor Langos + the `req:Langoer` line),
>      so the editor Books (Lake\*, Editron) need a re-record — the accepted "we only break snaps" cost.
>      Positive proof that the feed mints from a real want (vs. the no-op LakeLango case) wants a runner
>      free of the StoryTimes sweep, which was cycling MusuCrate/Radiola.g and overriding `become_book`.
>      *(w:MusuCrate has no w:Lies, so the Musu\* reds are unrelated — their own WIP, not this feed.)*
> - **(iii) THE CUT — BUILT (2026-06-30), conservative, in-system green; LIVE acceptance pending.**
>   `req_Langoer` now DRIVES `.sc.active` from its verdict, through the `Lies_set_active_waft`
>   chokepoint — Keeping the authoritative caller (Move 4). **Conservative guard** (not a blunt
>   sole-writer): it re-asserts `win` only when the current focus is itself Lango-backed (the
>   cold-resume boomerang case — that resume minted a cold Cursor) or nothing is focused; a focus
>   set eagerly with NO Cursor Lango (a Liesui tab-click, a `+Now` moment) is respected, so a naive
>   sole-writer's *opposite* regression (yanking a deliberate-but-Lango-less focus toward a stray
>   cold Lango) can't happen. **In-system proof:** LakeLango's `cut_drives_active` marker — the snap
>   now shows `Waft:LangoFore2,active` and the desire/acquire lock following the verdict to
>   `LangoFore2`, where before the lock froze on the arbitrary first Waft while the verdict said
>   otherwise (the boomerang-in-miniature, now resolved). Re-recorded green (dige `38679b1bef1225ee`).
>   **LIVE acceptance still owed** (`:9091`, the owner): focus moved to B *stays* B (no boomerang to
>   Radiola.g); boot still resumes the remembered Waft. **RESIDUAL — the full sole-writer:** make the
>   Lango-less deliberate sites (Liesui tab, `+Now`) emit a `click` want so they mint a deliberate
>   Cursor Lango; then the recorded verdict and live focus never diverge and the guard drops to an
>   unconditional write. **OWED — fleet re-record:** the feed (req:Langoer + Cursor Langos) AND the
>   cut (`.sc.active` + the verdict-following desire lock — snap_H keeps session keys) shift every
>   real-editor `w:Lies` snap; the editor Books (Lake\*, Editron) need re-recording. Best done after
>   the live acceptance confirms the cut behaves, to avoid a double re-record. *(Practical note: an
>   auto-sweep keeps grabbing the runner — a clean fleet re-record needs it stable/idle.)*

> **(iv) THE RESIDUAL — the emit half LANDED (2026-07-01); conservative guard KEPT; live-eyeball owed.**
> The sole-writer's substantive half — make every DELIBERATE focus mint a DELIBERATE Cursor Lango, so
> the verdict can never diverge from the eager `.sc.active` — is now cut across all the deliberate sites:
> - **nib|cap foreground** (`e_Lies_foreground_waft`) takes a `deliberate` flag; `Lang.svelte`'s
>   foreground-by-checkout passes `deliberate:1`, so a user foreground mints a `click` (non-cold) Cursor
>   that wins the verdict — it can't be out-competed by a stale Cursor elsewhere. The boot|timemachine
>   RE-LAND (`req_timemachine`→`Lies_foreground_waft`, and the per-tick `Lies_desire_land_cursor`) passes
>   NO flag → stays cold (the safe default: a cold Cursor loses, so a resume never steals a real
>   foreground). The flag threads `foreground_waft → Lies_desire_land_cursor → Waft_cursor_first`, all
>   defaulting cold.
> - **ghost-pick** (jump + throw-to-Aside) `cold`→`click` — a ghost-click is deliberate.
> - **+Now** (`e_Lies_now_Waft`) mints a deliberate Cursor DIRECTLY via `H.lango` (the fresh Look slot has
>   no What to land a want on) — it was the one genuinely Lango-LESS deliberate site.
>
> **Guard KEPT conservative** (NOT dropped to unconditional): with every deliberate focus now Lango-backed,
> the conservative guard already behaves unconditionally where converted, yet still gracefully RESPECTS any
> site left un-converted (a missed site → its focus stays, never stolen) — strictly safer than an
> unconditional write. Dropping it to unconditional is a safe follow-up ONCE the live-eyeball confirms.
> **Verified:** type-clean (the one `Lang:975` error is pre-existing, unrelated); LakeLango + LakeKeep +
> LakeSurfer GREEN on the live runner (no machine regression — these synthetic worlds don't fire the
> +Now/foreground/ghost-pick paths, so green = "didn't break the Langoer machine"). **OWED — live eyeball**
> (only the real editor fires these paths): (1) foreground a nib/cap Waft after a deliberate click
> elsewhere → it HOLDS (no pull-back); (2) +Now → the fresh slot takes+holds; (3) ghost-pick → jumps+holds;
> (4) reload still resumes the remembered Waft (cold path unchanged); (5) no boomerang to Radiola.g.

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

> **Status (2026-07-01) — Lens layout clients: FIVE view-states / FOUR components landed
> (type-clean; mechanism P5-gated).**
> The pure chrome view-states that were session-only `$state` (lost on reload) now PROJECT off the
> Keep through the P5 layout service (`Lies_keep_layout_get/set`, `'global'` scope), mirroring
> Langui's shipped `expanded`: **Langui `minimap_open`** (closed-flag `lte_minimap_closed`),
> **InterestStrip `show_cold`** (`isx_show_cold`), **DocTing `open`** (`ting_closed`) **+ `sort`**
> (`ting_sort` — a *value* not a flag; default `'time'` rides as absent so the Keep stays clean
> until you pick another), and **DocGhostList `open`** (`ghostlist_closed` — the ghost-index twin of
> DocTing's collapse; it takes `w`=w:Lies as a prop so it skips the `%examining` lookup). The idiom
> each time: convert the `$state` to a `$derived` reading
> `Lies_keep_layout_get`, and route the button(s) through a toggle that `Lies_keep_layout_set`s the
> **non-default** state (1-or-absent for a flag whose default is on → store the OFF/closed state; the
> literal value for `sort`). **No `Lies.svelte`/service touch — pure leaf-component consumers**, so
> zero risk to the focus core or the networking agent's in-flight `LiesFunk`/`LiesLies`. svelte-check
> clean (only the baseline "does not exist on type House" eatfunc noise, identical to the
> `Lies_keep_pref_*` calls sitting beside them). Browser-eyeball owed (owner); the
> set→snap→reopen→get **mechanism is already P5-gated in `LakeKeep`**, and a Story selftest can't
> mount a Svelte component, so no redundant per-client gate step was added.
>
> **NOT done — OWNER FORK: `Waft` capped/sidebyside.** The plan lists them, but `Waft.svelte:243`
> carries an explicit contrary decision — *"capped|sidebyside stay ephemeral — render-only, never
> reach the C/snap"* — made deliberately (per-Waft `minimised` persists *right beside* them, so
> ephemeral-for-these-two was a considered per-flag choice, not an oversight). Persisting them is a
> behavior change on a considered call → left for the owner to confirm before touching.
> **Also skipped:** MiniWaft `orbed` (per-instance/transient — no single Keep home, and it may not
> reach `w:Lies`) · Brink pose (the networking agent's `Rundar`). **Interest pop-back (3a/3b) stays
> parked** — it writes `.sc.active`, the contested focus core (P4 / `req:Langoer` territory,
> owner-supervised), not a pure layout client.

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
- **The carrier / de-req-ifying the pump.** **Chunk 1 BUILT** (uncommitted, host-unverified):
  one `req:Waftica,waft:<path>` per Waft; its walk runs every `funk.c.run` (behavior-preserving),
  a migration drops the stale `req:Funkcion`, it stamps `main:<kind>` — **Credence `Funkcions`
  48→1**. `req:Liesica` proved unnecessary — *no* run uses req machinery (Runner/Relay are plain
  `(host,funk,ww)`, like `storying_run`), so every Funkcion just rides its Waft's carrier walk.
  **Chunk 2 BUILT** (uncommitted, host-unverified): Storying dropped from the pumped `run`;
  `Lies_reflect_storying` restamps the bound cells at the **one** landing site
  (`Lies_run_result_recv` — `run_result` is created nowhere else) + a load-time pass on Waft load.
  The 48 per-tick scans are gone; touches the verdict wire → wants a green Credence run. Each
  chunk re-shapes the `Funkcions` snap → own commit. (P3 — landed at P0/P1.)
- **The Shelver ledger** *(resolved — `%shelved` tombstones dropped; presence is the
  `Funkcion:Storying,of_Book` cells on the board)*. Trade: a hand-deleted Book re-files on the
  next sweep. Done in `Funk/Shelver.svelte`.
- **`Languinio` under the rename** — does the noun keep its name (owned by `LangCurse`) or
  rename too? D7 names the *files*, not this particle. (P4.)

**Deferred by design — parked, not gaps (don't build until pulled forward):**
- **Excitement / awakeness levels** — the gradient math (rise, the MRU budget on the awake
  set, the escalation threshold) is black-boxed; it's numbers on the active Interests/Langos
  off the Keep, read by the convergence. Slots into P6's excitement dial. (`Lens_posable_TODO.md`
  — the excite scheme + Near TODO 2.)
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
