# Waft:Cluster — the first-class object where attention, crypto & acceptance converge

Captured from a design stream (owner's). Today `Waft:Cluster` is a **thin runtime fixture**:
 `Lies_aim_setup` (`LiesFunk` ~276) mints `Waft:Cluster,Aim`, stamps `dontSnap` on the whole
  Waft (~279), and hangs two watcher Funkcions off it hoisted as `Lens:Brink` (Runner / Relay
   peer-ping). Reconstructed each boot, never persisted.

The vision grows it into a **first-class object** — one roof over three faces of the same thing:
  - **attention** — which Wafts are open, where the cursor last sat, what was minimised (the
     *scrunch-Waft*, below).
  - **crypto** — the cluster Idento that signs `gen_write`/frames and the trusted flock it's
     verified against (already half-built; see §5).
  - **acceptance** — a *test* (or a gate, a snap re-record, a signed `gen_write`) **accepted**
     into the cluster by an identity, born with the attention it was looked at in (§6).

The owner's phrase for the whole: *"accepting-of-tests becomes a first-class object that people
 birth with attention in and crypto."* This doc is where that lands.

---

## 0. The floor — what exists today (verified anchors)

- **`Waft:Cluster,Aim`** — `Lies_aim_setup` (`LiesFunk` ~276): `w.oai({Waft:'Cluster'},{Aim:1})`,
   `cluster.sc.dontSnap ??= 1` (~279). Holds the two %Aim watcher Funkcions, hoisted as
    `Lens:Brink` into the Liesui-pinned dock. A runtime fixture, rebuilt each boot.
- **The cluster Idento already rides `House.stashed`.** `Lies_cluster_idento` (`LiesLies` ~365)
   reads `{pub,key}` from `stashed.cluster_idento` (pasted via the 🪪 Id hatch, `ui/IdHatch.svelte`
    — *"stashed's autosave persists it across reloads"*). It signs `gen_write` (`LiesLies` ~330),
     verified relay-side (`ClusterTrust_handover.md`). **`stashed` autosaves across reload** — this
      is the persistence keystone of §5.
- **The ephemera boundary.** `Lies_waft_save` (`LiesStore` 335) short-circuits on
   `waft.sc.takes || waft.sc.tentative` (344) — those are session-only sinks. *Everything else is
    durable-ish.* (`takes` = a globulation taker; `tentative` = a sprouted Sidetrack throwaway.)
- **The switcher already exists.** `InterestStrip` renders **one nib per `presence:active`
   Interest** (~57/63). With one Interest per Waft, **the nibs ARE the Waft switcher** — no new UI.
- **Boot focuses ONE Waft, doesn't reopen a set.** `Lies.svelte` ~832: the one-shot
   `req:acquire,maz:9` seed calls `Lies_focus_waft` (939) = `boring`-filtered
    `.sc.active ?? cursor's-waft ?? wafts[0]`, locks `desire/{Waft}`, `desire.finish(acquire)`.
     It picks a single Waft to land; it does **not** restore a remembered open-set.

---

## 1. The scrunch-Waft reframe (correcting the last pass)

- **Snap is not the persistence story.** `toc.snap` is a vague debug serialization of the editor;
   real reactive read/write rides the **edit+autosave path** (Langui dock autosave) and
    **`House.stashed`** (what the Idento uses). So **no `dontSnap` surgery** — `dontSnap` stays on
     `Waft:Cluster,Aim` exactly where it is. Cluster's memory persists through stashed/autosave,
      *not* by being in the snap. (This drops the earlier "split the cluster Waft / Option A" plan
       in `Lens_posable_TODO.md` §"Near TODO 1".)
- **`Waft:Cluster` becomes a *scrunch* Waft** — a new kind that **gathers the other durable Wafts
   under one roof**, not a flat layout-ledger.
- **Boundary unchanged:** ephemera = `takes | tentative` (`Lies_waft_save` 344). Everything else —
   the `Ghost/*` overlays, Aside, listers — is durable and **known to Cluster**.
- **All `Ghost/*` open at once** (no one-at-a-time). Cluster remembers each one's **minimised** flag.

## 2. Core idea — per-Waft `LastCursored`, switched by nibs

- For each `%otherWaft` it knows, Cluster holds a **`LastCursored`**: an Entcase-style `%lematch`
   **locator** to the What it was last on — rename/edit-surviving, **not** a hard ref or a brittle
    index (the same caretaking that `Interest.md` keeps flagging).
- One Interest per Waft → the InterestStrip nibs already switch. Clicking a nib **foregrounds that
   Waft and re-lands on its `LastCursored`** — working immediately after startup, because the
    locator persisted.
- *Within* a session this is mostly already true: per-Interest `in_Doc`/`alpha_doc` memory restores
   the Doc (`Lang_set_interest`; [[multidocwhat-chosen-doc]]). **The new part is surviving reload.**
- **+ CodeMirror scroll resume.** Capture viewport / `scrollTop` against the Interest; restore on
   re-foreground / reload. The dock hung off the cursor resumes where you left it.

## 3. A Lens is a hole, not a property — a wrangler fills it with a face

*(Corrects an earlier framing in this doc: an Interest does NOT "own a durable `%Lens`". A `%Lens`
 is ephemeral real-estate, not a place to store durability.)*

The vocabulary the code **already uses**:
  - **`%Lens` = a hole** — presentation real-estate things compete to be shown in
     (`Lens:<Kind>,of_Funkcion`, mounted by `ui/Lens.svelte`; the KIND = *where / how big*: Brink /
      Panel / InterestSmall|Big).
  - **a `face` = what fills the hole** — the `comp_<LensKind>` component a Funkcion projects in.
     `LensHost` already picks it (`Face = funkKind → comp_<lensKind>`; `Funk/kinds.ts` calls them
      "hoisted **faces**"). **"face" is already the established term** — not new vocabulary (see §"the
       lens → face rename" below).

So durability lives in the **Funkcion** that takes a hole over and projects a face, **never in the
 Lens**. The owner's shape:
  - an **`InterestWrangle`** Funkcion (a `Cluster/Funkcion`) **takes over the InterestStrip Lens**
     and presents the Interests in it — talking to them, arranging them;
  - **each presented thing carries its own `%Lens`** to host tinier bits of UI in a standard way —
     *recursive holdering*, projecting the Lens-as-hole pattern across the UI we already have.
  - Half-built already: `Funk/kinds.ts` maps a FunkKind → `comp_InterestSmall|Big` (faces that pop
     in the strip). InterestWrangle **generalises** that — one Funkcion owning the strip hole and
      arranging many things, instead of per-Funkcion pop-outs.

### the lens → face rename (just applied — is it sensible?)

**Yes, and it's *correcting* the vocabulary rather than inventing it:** a Lens is the hole, so the
 string an Interest carried was never naming a lens — it was naming the *face* to show. Renaming
  `Interest.sc.lens` → `sc.face` aligns the particle with `comp_<LensKind>` (= the faces in
   `kinds.ts`). Other live uses of "face", none a hard collision:
  - `Runner.svelte`'s local `face` = "the peer this instance **faces**" (verb sense, different
     scope) — soft, fine.
  - `FaceSucker` (`Housing`/`IdHatch`/`Lens`) = the OPFS / screen-share gate — a different domain.

**But the rename is a *waypoint*, not the destination** (→ §3b): the deeper fix is to **derive the
 face from the kind**, not store *any* presentation string on the Interest. A stored `sc.face`
  reintroduces the exact smell `sc.lens` had — the Interest naming its own presentation.

### 3b. Interest sheds historical facts — staying alive as a *document*

The `%Interest` particle accreted presentation cruft it should drop, so it can be a lean, editable
 **document** (identity + state) — *the grapple, not the gripped*. **Decided (2026-06-25):**
  - **`sc.face` — dropped entirely.** Nothing reads it but a debug tooltip (`InterestStrip:172`); no
     component mounts from it (the trail renders via `%ActiveInterest` + `%LE`, never a face string —
      `NaviCado` is hard-mounted in `DocMinimap:699`). *Which* World-A face a kind mounts (§3) is the
       **InterestWrangle's** job, picked by kind at mount-time — never a stored per-particle fact.
        (`sc.lens` was already 0-refs; the `lens → face` rename swept it. Now both are gone.)
  - **`sc.presence`** (`active`/`always`) — derived from kind (Ting = always, the rest = active),
     not stored.
  - **`sc.from`** — was the Sidetrack sprout-binding posture; with Sidetrack folded into Aside
     (below) the sprout-origin is **transient, not stored**, so this goes too.

So the kind set collapses **5 → 4**: `Trail · Ting · GhostList · Aside` (**Sidetrack merged into
 Aside**). A kind's looks/behaviour live in the declarative **`INTEREST_KINDS` table** (`{stance,
  presence, hasLE, cursor}` keyed by kind — [[interest-switch-active-fix]]); the particle keeps only
   its **durable identity + state** — `waft`, `state` (locked), cursor-memory (`in_Doc` /
    `LastCursored`). Lean enough to persist and edit as a document.

**Aside, specifically** — Waft-first, *open-or-create*. A "sprout off a What" is a **transient
 gesture**: the origin (`%fromWhat`) is not storable (a hard What-ref doesn't belong in `sc`) and
  doesn't need to be — what persists is the **Docs you write inside it**, as ordinary content under
   the Aside Waft. So the old Sidetrack `%from` reverse-arrow binding in `interest_reconcile`
    (~116-137) simply deletes. An Aside is therefore **durable but not eternal**: persisted across
     reload, then **GC'd** once its notes are vacuumed into permanent homes (lifecycle TODO — wants a
      last-touched / emptied signal to reap safely).

## 4. Phases (revised)

0. *(dropped — no `dontSnap` split; persist via stashed/autosave.)*
1. **Cluster knows the durable set.** Register every non-ephemera Waft into the scrunch-Waft on
    load/create; **seed `Ghost/*` once** by scanning `wormhole/Ghost/*` so they're reachable without
     typing a path.
2. **Minimised + reopen-all on boot.** Persist `minimised` per Waft; boot **reopens the whole set**
    (all `Ghost/*`) instead of focus-one (`Lies.svelte` ~832). Two pieces: **(1)** write the
     open/closed set on open/close/active-change; **(2)** drive the acquire/open path from that list,
      not just focus one. **Piece (2) needs the acquire/open model mapped first — that is the real
       work.**
3. **`LastCursored` locators + scroll resume.** Per known Waft, an Entcase `%lematch` to the last
    What; restore on nib-click and on boot. Same family as `Interest.md`'s *"Per-(Interest,Waft)
     cursor-memory"* TODO — build them together (both want the rename-surviving locator caretaking).
4. **Per-Waft Interests + the `INTEREST_KINDS` table** *(behind the `InterestLive` gate)*. Re-key
    `Interest:<WaftTail>` (kind/stance ride as properties); **shed the presentation strings**
     (`sc.face` dropped outright; `sc.presence` derived from kind; `sc.from` gone with Sidetrack —
      §3b) so the Interest is a lean document, and let the **InterestWrangle** Funkcion (§3) project
       the faces by kind.
       **Riskiest** — it touches the live Lang↔Lies channel whose contract is the Story Book
        `InterestLive`, so it lands **last**. Payoff: the awkward *"find the Trail with `c.LE` and no
         waft"* probe in `interest_reconcile` (`Interest.svelte` 121-126) **dissolves** — you find by
          Waft directly.

---

## 5. The auth face — Cluster IS where the crypto already lives

This is not a new mechanism; it's a **face** for one that's half-built and currently homeless in
 the UI:
  - The **cluster Idento** rides `House.stashed.cluster_idento` (`Lies_cluster_idento` ~365), pasted
     via the 🪪 Id hatch, and **signs `gen_write`** (`LiesLies` ~330) — verified relay-side
      (`ClusterTrust_handover.md`: `signHeader`/`verifyHeader`, `body_hash` now sha256, fail-closed
       against `CLUSTER_TRUSTED_PUBS`). This closes the unauthenticated-relay RCE.
  - **`Tyrant.g`** (`Covenant_design.md`) is the **admission cabinetry** over the Peeroleum floor:
     M1 message-abstract trust over given identities, M2 the meeting leg + a policy-gated
      `%req:join` whose `finished` is the conjunction of policy leaves. (`Garden.g` = the partying /
       social cultivation, M3, later.) The single-ghost name `Covenant`/`Joinery` was **rejected** —
        keep `Tyrant.g`/`Garden.g` as the *mechanism*; **Cluster is the *face*.**

**The move:** surface that identity/trust **as Lens faces under the cluster Waft**, beside the
 `%Aim` endpoint Brinks already there — the 🪪 Idento, the trusted-flock state, the admission
  `%req:join`, the per-peer `Pier`/`Peering,%trust` tree (Covenant M1). *"All clients have and use
   the trust"* finally gets a place to live and be seen.

**Persistence symmetry (the keystone):** the Idento *already* lives in `stashed`; the layout /
 `LastCursored` memory (§1–§3) can share the **same `stashed` home**. The auth half and the
  attention half of `Waft:Cluster` are persisted the same way — one object, one channel.

## 6. The acceptance face — "accepting-of-tests, born with attention & crypto"

Today **acceptance is scattered and fire-and-forget**: `become_book` ACCEPT (a runner records a
 verdict), the **Credence board** (`Editron.md`), the EntropySamples NNN / fuzz-ok forgive loop
  ([[entropy-samples-fuzzok]]), and the Tier-1 *self-record-the-gate* (drive → diff → ACCEPT under
   control). None of it is a *thing* you can hold, sign, or trace back to who looked at it.

**The vision — ACCEPT becomes a first-class object on `Waft:Cluster`.** An acceptance carries:
  - **who** — a cluster Idento signature (crypto; the §5 signing contract, reused not reinvented);
  - **what** — the diff / `diges` / Entcase locator it ratifies (rename-surviving, like `LastCursored`);
  - **the attention it was born in** — the `%Interest` it was looked at in is its **provenance**
     (the owner's *"birth with attention"*; the Lens it filled is ephemeral, so the durable handle is
      the Interest). Recorded as a locator, **not** a hard ref, so it survives the Interest being
       dismissed.

This **unifies three threads already in flight** under one roof:
  1. the **signed `gen_write`** (crypto — §5);
  2. the **self-driving Tiers** (§7) — Tier 1's self-recorded gate needs *an authority to record
      under*, which is exactly a cluster identity;
  3. the **Credence/Editron verdict ledger** (the acceptance record itself).

So: **`Waft:Cluster` = attention(`%Interest`) × crypto(Idento/Tyrant) × acceptance(signed
 verdict).** Three faces, one object.

## 7. The self-driving Tiers, placed

The owner's ladder for *Claude driving the gate itself* — recorded here because Tier 1's ACCEPT is
 the §6 object, and each rung needs the cluster identity to act under:
  - **Tier 1 — self-record the gate.** Drive → diff → ACCEPT under control, reading the diff before
     recording. The safety contract: **a headless run produces the same `diges` a :9091 run does** —
      make that a *tested invariant, not a hope*. Then re-recording the locked 002–015 gate stops
       needing a human at :9091. (Keep the existing `round=N` ±1 age-mung; that nondeterminism is
        already handled.)
  - **Tier 2 — the compile→run round-trip.** Edit `.g` → compile → runner picks up fresh gen
     (guaranteed no stale cache) → run, **without a human HMR**. Kills the gotcha that bit the stall
      run twice (*"reload the runner so it re-acquires the committed gen"*). `ghost-compile` exists
       but needs the live editor to sign the ticket; a runner Claude drives should compile-and-load
        in one step.
  - **Tier 3 — two-origin transport** *(what the reliability thread actually needs)*. Two runner
     instances on separate origins with the real `/relay` ws between them, plus **drivable fault
      injection** — kill the relay, drop a socket, partition one side. The mock + `make_lossy_partner`
       prove the *logic* of inbound-silence-liveness / re-dial / Tribunal fallback; **only a real
        silent socket proves the transport** (those rungs landed dormant-and-unverified —
         [[peeroleum-reliability-arc]]).
  - **Tier 4 — observability I can grep.** Mostly there (`wstory.json`, the ms-timed trace). Two
     gaps: an **on-demand snap at any tick** (not just step boundaries), and the **`live_poll`
      overrun signal** (the lost-wakeup-vs-churn tell) in the pile, so a wedge reads at a glance
       instead of from a frozen browser.

---

## Open questions for the room

- **Persistence channel.** `House.stashed` (what the Idento uses; autosaves across reload) vs a
   snapped `Layout` particle vs Dexie? The reframe's *"UI:Waft"* is loose — there is no literal
    `UI:Waft` particle; pick the concrete channel. (`stashed` is the front-runner — it already
     carries the Idento, so the auth+attention symmetry of §5 is free.)
- **Name for `%Aim`** (the *outward* half of Cluster — your peers + carrier + their liveness + where
   to aim, growing to **re-dial / Tribunal fallback**). It's not pathfinding, it's
    awareness-plus-targeting that will start to *steer*. **"Navigator" proposed** (fits the steering
     trajectory + the spatial vocab — Waft/Trail/Brink/Peregrination); lighter alts: **Compass** /
      **Bearings** (orientation only, no steering) · **Lookout** / **Radar** (liveness watch only).
       Pairs with the *inward* scrunch half. UNDECIDED — owner's call.
- **Who owns `LastCursored` + scroll** — Cluster, or the Interest particle itself (as document,
   §3b), or the InterestWrangle Funkcion that fills the hole? **NOT the Lens** — a Lens is ephemeral
    real-estate (§3).
- **Aside: durable or ephemera?** *(RESOLVED)* **Durable but not eternal** — Waft-first /
   open-or-create, sprout-origin transient (not stored), Docs persist, GC'd after notes are vacuumed
    out. The lifecycle reap-signal (last-touched / emptied) is the only open bit (§3b).
- **Re-key Interests now or after?** §4 Phase 4 is the riskiest (live channel, `InterestLive` gate)
   — ship Phases 1–3 (the persistence win) first, or pull the re-key forward as the anchor?
- **Auth/acceptance scope.** Does `Waft:Cluster` **subsume** Covenant's `Tyrant.g` admission UI, or
   just **surface** it? (Keep the mechanism in `Tyrant.g`/`Garden.g`; Cluster as face. Don't revive
    the rejected single-ghost `Covenant` name.)
- **"Born with attention" binding.** Is an ACCEPT's attention-provenance a hard ref to the
   `%Interest`, or a recorded **locator** (it must survive the Interest being dismissed — argues for
    locator)?

## Companions

`Lens_posable_TODO.md` (the near layout TODOs this **absorbs** — TODO 1 layout-state, TODO 2
 Interest-Docs mini-list, TODO 3 nav frictions) · `Lens_handover.md` (the built Lens/%Aim seam) ·
  `Interest.md` (the channel + per-(Interest,Waft) cursor-memory TODO) · `ClusterTrust_handover.md`
   (the crypto wire — `signHeader`/`verifyHeader`/`body_hash`) · `Covenant_design.md`
    (`Tyrant.g`/`Garden.g` trust ghosts over the Peeroleum floor) · `Editron.md` (Credence / the
     verdict ledger that §6 makes first-class).
