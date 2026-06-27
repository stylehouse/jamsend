# The Keep — the workspace-that-remembers (and where acceptance is born)

> **Glossary (the split this doc rests on).** **Keep** = the *inward* workspace-that-remembers — it
>  gathers your durable Wafts and restores where-you-were; **this doc's subject.** **Cluster** = the
>   *networking* peer-stack (peers / relay / trust / Idento / the Aim endpoints) — a **neighbor**, not
>    the subject. They share one `stashed` home, and *acceptance* is born of both. (Historical note:
>     this all started as one overloaded `Waft:Cluster`; the owner split the role out as **the Keep**.)

Captured from a design stream (owner's). Today there is only a **thin networking fixture**:
 `Lies_aim_setup` (`LiesFunk` ~276) mints `Waft:Cluster,Aim`, stamps `dontSnap` on the whole Waft
  (~279), and hangs two watcher Funkcions off it hoisted as `Lens:Brink` (Runner / Relay peer-ping).
   Reconstructed each boot, never persisted — fine for ephemeral endpoints, wrong for a workspace.

The vision grows a **new first-class object — the Keep** — the inward workspace, plus its
 relationship to the Cluster neighbor:
  - **attention (the Keep)** — which Wafts are open, where the cursor last sat, what was minimised
     (the *scrunch object*, below).
  - **crypto (the Cluster neighbor)** — the cluster Idento that signs `gen_write`/frames and the
     trusted flock it's verified against (already half-built; see §5).
  - **acceptance (born of both)** — a *test* (or a gate, a snap re-record, a signed `gen_write`)
     **accepted** by an identity (Cluster's crypto), born with the attention it was looked at in
      (the Keep) — §6.

The owner's phrase for the offspring: *"accepting-of-tests becomes a first-class object that people
 birth with attention in and crypto."* Attention is the Keep; crypto is Cluster; this doc is where
  that lands.

---

## 0. The floor — what exists today (verified anchors)

- **`Waft:Cluster,Aim`** *(the Cluster fixture)* — `Lies_aim_setup` (`LiesFunk` ~276):
   `w.oai({Waft:'Cluster'},{Aim:1})`, `cluster.sc.dontSnap ??= 1` (~279). Holds the two %Aim watcher
    Funkcions, hoisted as `Lens:Brink` into the Liesui-pinned dock. A runtime fixture, rebuilt each
     boot. **This stays Cluster** — the Keep is a separate, durable object.
- **The cluster Idento already rides `House.stashed`.** `Lies_cluster_idento` (`LiesLies` ~365)
   reads `{pub,key}` from `stashed.cluster_idento` (pasted via the 🪪 Id hatch, `ui/IdHatch.svelte`
    — *"stashed's autosave persists it across reloads"*). It signs `gen_write` (`LiesLies` ~330),
     verified relay-side (`ClusterTrust_handover.md`). **`stashed` autosaves across reload** — this
      is the persistence keystone of §5 (the Keep can share the same home).
- **The ephemera boundary.** `Lies_waft_save` (`LiesStore` 335) short-circuits on
   `waft.sc.takes || waft.sc.tentative` (344) — those are session-only sinks. *Everything else is
    durable-ish* — i.e. eligible for the Keep's set.
- **The switcher already exists.** `InterestStrip` renders **one nib per `presence:active`
   Interest** (~57/63). With one Interest per Waft, **the nibs ARE the Waft switcher** — no new UI.
- **Boot focuses ONE Waft, doesn't reopen a set.** `Lies.svelte` ~832: the one-shot
   `req:acquire,maz:9` seed calls `Lies_focus_waft` (939) = `boring`-filtered
    `.sc.active ?? cursor's-waft ?? wafts[0]`, locks `desire/{Waft}`, `desire.finish(acquire)`.
     It picks a single Waft to land; it does **not** restore a remembered open-set.

---

## 0b. How a Waft is born — and the bootstrap the Keep should follow

*"Where does the first Waft come from?"* — **a Plan/Prep declares it; the Store/Persist pump
 materialises it.** The Editron Book is the clean example (`wormhole/Story/Editron/toc.snap`):

```
story:Editron
  Plan
    Prep
      i_elvisto:Lies, e:Lies_open_Waft
        esc: path = Credence          ← the Prep *declares* "open the Credence Waft"
```

The chain (`Lies.svelte:159`):
  - `e_Lies_open_Waft(path)` does **not** create the `Waft:` particle — it mints a
     **`Good,type:'text/Waft'`** slot under `req:Store` keyed by the snap_path, annotates
      `good.sc.waft_path`, and kicks `think`.
  - **LiesPersist / `LiesStore_read_good`** then reads that Good and **materialises the Waft**
     (`w.oai({Waft:key})`, `LiesStore` ~259/276) — loaded from its disk snap, or born fresh if there
      is no home.
  - the roster sig moves → `interest_reconcile` (Lang) sprouts the `Interest:<kind>` (§"Where
     Interests come from").

This same `Lies_open_Waft(path)` is the **general open-or-create primitive** — Books open Wafts in a
 Prep, `Liesui` (`:129`) opens one when you open a dock, `LiesStore` (`:324`) auto-loads the
  GhostList. **It is exactly the "acquire/open model" Phase 2 deferred:** to *reopen a durable set*
   on boot, fire `Lies_open_Waft` per remembered path.

**Why exactly one Waft loads in the editor today (the "why does Easy load?" answer).** The editor
 Book opens a **single** boot Waft — `Editron.svelte:30/66`: `EDITOR_WAFT = boot_param('W') ||
  'Ghost/Net/Easy'`, opened once via `Lies_open_Waft(EDITOR_WAFT)` (idempotent on
   `w.c.Editron_opened`). So "Easy" is just the tail-name of the **default `?W=`** overlay
    (`Ghost/Net/Easy` — the Peeroleum/Peregrination `.g` docks the runner shares); nothing else is
     loaded, so the `Lies.svelte:832` acquire focuses it by default. (You can point the browser at
      `?W=Ghost/Music/Ality` to boot on a different one.) **This single-open is what the Keep
       generalises:** it opens a *remembered set* (loop `Lies_open_Waft`), and `?W=` degrades from
        "the one Waft" to merely "which one is **focused** at boot." (A Book-level `boot_set` stop-gap
         that co-loaded `Ghost/Music/Ality` was tried and **yanked** — the owner wants the Keep, not
          the Book, to own the set.)

**Two birth mechanisms — and which one the Keep takes.** Credence (a durable board) is born the
 clean way: a Prep opens it, Persist loads it, it has a disk home, it snaps. `Waft:Cluster,Aim` is
  born the *other* way — minted directly in `Lies_aim_setup` (`dontSnap`, rebuilt each boot, no Good,
   no Persist, no disk). That mint is **correct for Cluster** (ephemeral networking endpoints), but
    it is the **thin-fixture** pattern — and a thing rebuilt-from-nothing each boot **can't "remember
     where you were."** So the Keep must follow **Credence's** bootstrap, not Cluster's: a real home
      that opens-and-persists. (The exact channel — a snapped home vs `stashed` — is the bootstrap
       open question.)

---

## 1. The Keep is a *scrunch* object (correcting the last pass)

- **Snap is not the persistence story.** `toc.snap` is a vague debug serialization of the editor;
   real reactive read/write rides the **edit+autosave path** (Langui dock autosave) and
    **`House.stashed`** (what the Idento uses). So **no `dontSnap` surgery** — `dontSnap` stays on
     `Waft:Cluster,Aim` exactly where it is. The Keep's memory persists through stashed/autosave,
      *not* by being in the snap. (This drops the earlier "split the cluster Waft / Option A" plan in
       `Lens_posable_TODO.md` §"Near TODO 1".)
- **The Keep is a *scrunch* object** (`Waft:Keep`, a new kind) — it **gathers the other durable
   Wafts under one roof**, not a flat layout-ledger. `Waft:Cluster,Aim` is just one tenant it can
    surface, like any other durable Waft.
- **Boundary unchanged:** ephemera = `takes | tentative` (`Lies_waft_save` 344). Everything else —
   the `Ghost/*` overlays, Aside, listers — is durable and **known to the Keep**.
- **All `Ghost/*` open at once** (no one-at-a-time). The Keep remembers each one's **minimised** flag.

## 2. Core idea — per-Waft `LastCursored`, switched by nibs

- For each `%otherWaft` it knows, the Keep holds a **`LastCursored`**: an Entcase-style `%lematch`
   **locator** to the What it was last on — rename/edit-surviving, **not** a hard ref or a brittle
    index (the same caretaking that `Interest.md` keeps flagging).
- One Interest per Waft → the InterestStrip nibs already switch. Clicking a nib **foregrounds that
   Waft and re-lands on its `LastCursored`** — working immediately after startup, because the
    locator persisted.
- *Within* a session this is mostly already true: per-Interest `in_Doc`/`alpha_doc` memory restores
   the Doc (`Lang_set_interest`; [[multidocwhat-chosen-doc]]). **The new part is surviving reload.**
- **+ CodeMirror scroll resume.** Capture viewport / `scrollTop` against the Interest; restore on
   re-foreground / reload. The dock hung off the cursor resumes where you left it.
- **The Keep drives `?W=` — two resumability channels, don't conflate them.** Today `?W=` is
   *read-only at boot* (`boot.ts:13`, `boot_param('W')`); the app never writes the URL. The Keep can
    **drive it** — `history.replaceState` the `W` param on each focus switch (the same moment it
     claims `.sc.active` / foregrounds), leaving `?E=`/`?B=` intact. Then:
     - **`?W=` (URL)** = a thin, **shareable / bookmarkable** pointer to the **focus** (one Waft) —
        send someone `?W=Ghost/Music/Ality` and they boot focused there.
     - **`House.stashed`** = the **rich resumable state** — the open *set* + per-Waft `minimised` /
        `LastCursored` / scroll. *"Resumes stuff"* lives here; the URL is just the address.
     - **Boot precedence:** an explicit `?W=` wins the focus seed (deep-link / share); else
        restore last-focus from `stashed`; the **set** always comes from `stashed` (the URL can't
         carry it).
     - *(Fork — see Open questions: `replaceState` = honest URL, no history (default) vs `pushState`
        = browser Back walks your Waft history ("navigate"), but Back can exit the overlay.)*

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
  - an **`InterestWrangle`** Funkcion (a `Keep/Funkcion`) **takes over the InterestStrip Lens** and
     presents the Interests in it — talking to them, arranging them;
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

**Aside, specifically** — Waft-first, *open-or-create* (`Waft:Aside/YMD`, today's scratch). A
 "sprout off a What" rides as a **loose string back-ref**: `e_Lies_ghost_pick` (`Lies.svelte` ~239)
  already stamps `%FromWhat` on the moment-`%What` — *"the stringy cheese, deliberately not a hard C
   ref"* — severable from the Aside. So the origin **is** persisted, but as a detachable string, not
    a ref; the Aside and its **Docs** persist independently of it. The old Sidetrack `%from`
     *reverse-arrow binding* in `interest_reconcile` (~116-137) — a different thing, the
      Lang-sprouts-ahead-of-Waft path — simply deletes once Aside is uniformly Waft-first. An Aside
       is therefore **durable but not eternal**: persisted across reload, then **GC'd** once its
        notes are vacuumed into permanent homes (lifecycle TODO — wants a last-touched / emptied
         signal to reap safely).

## 4. Phases (revised)

0. *(dropped — no `dontSnap` split; persist via stashed/autosave.)*
1. **Keep knows the durable set.** *(MODEL landed as the `Waft:Keep` PARTICLE — `Lies_keep*` in
    `Lies.svelte`; see the Handover "Code this session". Boot driver + persistence still owed.)*
     Accumulate every Waft found into the ledger (`Lies_keep_note` on open/foreground); `Waft:Keep`
      seeds `{Ghost/Net/Easy, Ghost/Music/Ality}` on a fresh ledger. `?W=` then just marks which is
       **focused** at boot — and **when `?W=` is absent, the Keep's own latest `%Cursor` auto-resumes
        the last Waft** (`Lies_keep_resume_waft`).
2. **Minimised + reopen-all on boot.** Persist `minimised` per Waft; boot **reopens the whole set**
    (all `Ghost/*`) instead of focus-one (`Lies.svelte` ~832). Two pieces: **(1)** write the
     open/closed set on open/close/active-change; **(2)** on boot, fire **`Lies_open_Waft(path)` per
      remembered path** (the open-or-create primitive — §0b), instead of focus-one. *(Phase 2's
       "acquire/open model" is no longer unmapped — §0b names it; the work is now just wiring the
        remembered set into a loop of `Lies_open_Waft` calls.)*
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

## 5. The Cluster neighbor — where the crypto lives, and why the Keep sits beside it

The crypto is **Cluster's**, not the Keep's — but it's half-built and currently homeless in the UI,
 and the Keep is the natural place to *surface* it and to *borrow* it (for signing acceptances, §6):
  - The **cluster Idento** rides `House.stashed.cluster_idento` (`Lies_cluster_idento` ~365), pasted
     via the 🪪 Id hatch, and **signs `gen_write`** (`LiesLies` ~330) — verified relay-side
      (`ClusterTrust_handover.md`: `signHeader`/`verifyHeader`, `body_hash` now sha256, fail-closed
       against `CLUSTER_TRUSTED_PUBS`). This closes the unauthenticated-relay RCE.
  - **`Tyrant.g`** (`Covenant_design.md`) is the **admission cabinetry** over the Peeroleum floor:
     M1 message-abstract trust over given identities, M2 the meeting leg + a policy-gated
      `%req:join` whose `finished` is the conjunction of policy leaves. (`Garden.g` = the partying /
       social cultivation, M3, later.) The single-ghost name `Covenant`/`Joinery` was **rejected** —
        keep `Tyrant.g`/`Garden.g` as the *mechanism*.

**The move:** surface Cluster's identity/trust **as Lens faces in the Keep**, beside the `%Aim`
 endpoint Brinks already there — the 🪪 Idento, the trusted-flock state, the admission `%req:join`,
  the per-peer `Pier`/`Peering,%trust` tree (Covenant M1). *"All clients have and use the trust"*
   finally gets a place to live and be seen.

**Persistence symmetry (the keystone):** the Idento *already* lives in `stashed`; the Keep's layout
 / `LastCursored` memory (§1–§3) can share the **same `stashed` home**. Cluster's crypto and the
  Keep's attention are persisted the same way — one channel, two neighbors.

## 6. Acceptance — "accepting-of-tests, born with attention & crypto"

Today **acceptance is scattered and fire-and-forget**: `become_book` ACCEPT (a runner records a
 verdict), the **Credence board** (`Editron.md`), the EntropySamples NNN / fuzz-ok forgive loop
  ([[entropy-samples-fuzzok]]), and the Tier-1 *self-record-the-gate* (drive → diff → ACCEPT under
   control). None of it is a *thing* you can hold, sign, or trace back to who looked at it.

**The vision — ACCEPT becomes a first-class object, born at the Keep × Cluster intersection.** An
 acceptance carries:
  - **who** — a cluster Idento signature (crypto; Cluster's §5 signing contract, reused not
     reinvented);
  - **what** — the diff / `diges` / Entcase locator it ratifies (rename-surviving, like `LastCursored`);
  - **the attention it was born in** — the `%Interest` (a Keep concern) it was looked at in is its
     **provenance** (the owner's *"birth with attention"*; the Lens it filled is ephemeral, so the
      durable handle is the Interest). Recorded as a locator, **not** a hard ref, so it survives the
       Interest being dismissed.

So acceptance is the **offspring of the two neighbors** — Cluster's crypto signs it, the Keep's
 attention bears it — and it **unifies three threads already in flight**:
  1. the **signed `gen_write`** (Cluster's crypto — §5);
  2. the **self-driving Tiers** (§7) — Tier 1's self-recorded gate needs *an authority to record
      under*, which is exactly a cluster identity;
  3. the **Credence/Editron verdict ledger** (the acceptance record itself).

So: **acceptance = attention (the Keep, `%Interest`) × crypto (Cluster, Idento/Tyrant).** Two
 neighbors, one offspring — and the Keep is where that offspring lives.

## 7. The self-driving Tiers, placed

The owner's ladder for *Claude driving the gate itself* — recorded here because Tier 1's ACCEPT is
 the §6 object, and each rung needs the **cluster identity** (Cluster's crypto) to act under. *(In
  flight already: [[headless-creduler-runner]] = Tier 0/1, [[localgen-browserless-compile]] = the
   Tier-2 compile half.)*
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

**The LIVE realisation of these Tiers** — driving a runner in a real browser over the relay (not just the
 headless CredRunner) — now has a built RPC (`runner_ask`/`story_repl`) and its own concrete TODO:
  **`Runner_talk_TODO.md`** (diff-over-socket = Tier 1, trace/stack + hold/retain = Tier 4, signed ACCEPT =
   Tier 1 × §6). Point the agent there for the live interface; this section is the headless framing it mirrors.

---

## Open questions for the room

- **The Keep's bootstrap (§0b).** Does the Keep get a **real home that opens-and-persists** (a
   snapped board opened via `Lies_open_Waft`, like Credence), or a **runtime mint + `stashed`** for
    its durable half? (It must NOT inherit `Waft:Cluster,Aim`'s thin-fixture mint — that can't
     remember.) Couples tightly to the persistence-channel question below.
- **Persistence channel.** `House.stashed` (what the Idento uses; autosaves across reload) vs a
   snapped `Layout` particle (only if the Keep graduates to a snapped home, above) vs Dexie? The
    reframe's *"UI:Waft"* is loose — there is no literal `UI:Waft` particle; pick the concrete
     channel. (`stashed` is the front-runner — it already carries the Idento, so the Keep+Cluster
      persistence symmetry of §5 is free.)
- **URL `?W=` — `replaceState` or `pushState`?** The Keep mirrors the focus into the URL on switch
   (§2). `replaceState` keeps the URL honest with **no** history entries (resumable + shareable — the
    safe default); `pushState` makes the browser **Back button walk your Waft-focus history**
     (genuinely "navigate"), but Back can eventually exit the overlay. Default `replaceState`; offer
      `pushState` only if Waft-history navigation is wanted.
- **Name for `%Aim`** (Cluster's *outward* half — your peers + carrier + their liveness + where to
   aim, growing to **re-dial / Tribunal fallback**). It's not pathfinding, it's
    awareness-plus-targeting that will start to *steer*. **"Navigator" proposed** (fits the steering
     trajectory + the spatial vocab — Waft/Trail/Brink/Peregrination); lighter alts: **Compass** /
      **Bearings** (orientation only, no steering) · **Lookout** / **Radar** (liveness watch only).
       Pairs with the Keep (the *inward* workspace). UNDECIDED — owner's call.
- **Who owns `LastCursored` + scroll** — the Keep, or the Interest particle itself (as document,
   §3b), or the InterestWrangle Funkcion that fills the hole? **NOT the Lens** — a Lens is ephemeral
    real-estate (§3).
- **Aside: durable or ephemera?** *(RESOLVED)* **Durable but not eternal** — Waft-first /
   open-or-create, sprout-origin transient (not stored), Docs persist, GC'd after notes are vacuumed
    out. The lifecycle reap-signal (last-touched / emptied) is the only open bit (§3b).
- **Re-key Interests now or after?** §4 Phase 4 is the riskiest (live channel, `InterestLive` gate)
   — ship Phases 1–3 (the persistence win) first, or pull the re-key forward as the anchor?
- **Acceptance/admission scope.** Does the Keep **surface** Cluster's `Tyrant.g` admission UI (faces
   only), or also **drive** it? (Keep the mechanism in `Tyrant.g`/`Garden.g`; the Keep is a face onto
    it. Don't revive the rejected single-ghost `Covenant` name.)
- **"Born with attention" binding.** Is an ACCEPT's attention-provenance a hard ref to the
   `%Interest`, or a recorded **locator** (it must survive the Interest being dismissed — argues for
    locator)?

## Handover — status & next move (2026-06-25)

**Destination.** A new first-class object — **the Keep** — the inward *workspace-that-remembers*
 (gathers your durable Wafts; restores where-you-were across reload). It owns **attention** (open
  set, `LastCursored`, scroll, layout) and **acceptance** (born with attention). Its neighbor
   **Cluster** owns **crypto/networking** (peers / relay / trust / Idento / the Aim endpoints);
    *acceptance* is born of both (Cluster signs, the Keep bears). They share one `stashed` home.

**Bombs — know these or you'll go wrong:**
- **Keep vs Cluster is a hard split.** Role → **Keep**; the networking sense stays **Cluster**
   (`Waft:Cluster,Aim`, `cluster Idento`, `CLUSTER_TRUSTED_PUBS`, cluster-trust, `Lies_aim_setup`).
    Crypto is Cluster's; the Keep only *surfaces/borrows* it.
- **A `%Lens` is a HOLE; a `face` (`comp_<LensKind>`) fills it.** Durability lives in the Funkcion
   that projects the face, **never in the Lens**. `Interest.sc.face` is **dropped** (§3, §3b).
- **Persistence channel is now an OPEN fork** (an earlier pass wrote "stashed, not snap" — but
   `Waft:Keep` being a real particle reopens it; see Next move §1). Either way `dontSnap` stays on
    `Waft:Cluster,Aim`, and the cluster Idento keeps riding `stashed` (the crypto keystone, §5).
- **`Waft:Keep` is a first-class PARTICLE, not a flat list.** (A `stashed.Keep.wafts` string-array
   was the first try — **scrapped per owner**: *"Waft:Keep is an entire thing unto itself."*) It is a
    **ledger**: one `/%WaftTimes,of_Waft:<path>,discovered_at,accessed_at` per Waft ever found, each
     with a `/%Cursor` history (last several positions — resume the cursor *inside* the Waft). The
      Keep **also keeps its OWN `/%Cursor`** history (the last Wafts focused) → boot **auto-resumes the
       last one when `?W=` is absent**. Marked `%boring` → never a switcher nib (`interest_roster`
        skip) nor a focus candidate (`Lies_focus_waft`).
- **`Cluster_design.md` keeps its filename** even though the doc is titled "The Keep" — still
   referenced from the GhostList snap (`Doc:…/Cluster_design.md`); renaming = a snap re-record, not
    worth it.
- **PERSISTENCE DECIDED (owner): the Keep SNAPS to its own home** — a real Waft, reusing
   `Lies_open_Waft`/Persist/`Lies_waft_save` like every overlay (`wormhole/…/Keep/toc.snap`). `%boring`
    does double duty: out of the editor's aggregate snap (`Lies.svelte:728` carries it to the Good) +
     out of nibs/focus, **while still saving to its own home** (`Lies_waft_save` only skips
      `takes|tentative`, not `boring`). The Idento keeps riding `stashed` (crypto) — attention snaps,
       crypto stashed: a clean split.
- **Code this session (MODEL + BOOT DRIVER — LANDED, type-clean, `:9091`-unverified, uncommitted).**
   All in `Lies.svelte` unless noted:
   - **Model:** `Lies_keep(w)` read-only getter (Persist is the sole creator — no lazy race);
      `Lies_keep_note(w,path)` accumulates a `WaftTimes` (discovered_at once / accessed_at now, no-op
       till the Keep loads); `Lies_keep_mark_focus`; `Lies_keep_push_cursor(host,key,val)` (capped
        last-10, coalescing); `Lies_keep_resume_waft(w)`; `Lies_keep_reopen(w)` (seeds `{Easy,
         Music/Ality}` on a fresh Keep).
   - **Boot driver:** `Lies_keep_boot(w)` from `Lies_heartbeat` (editor-only, staged & self-gated by
      `w.c.keep_opened|booted|resumed`): (1) open `Waft:Keep` so Persist loads/creates it; (2) once
       materialised → stamp `boring` + reopen the ledger; (3) when no `?W=`, foreground
        `Lies_keep_resume_waft` (canonical `e_Lies_foreground_waft` = focus + land). `?W=`, when
         present, still wins (Editron opens it first).
   - **Hooks:** `e_Lies_open_Waft` → `note`; `e_Lies_foreground_waft` → `mark_focus` (both
      editor-only, skip `Keep`). `Interest.svelte interest_roster` skips `%boring` → no Keep nib.
   - **Editron unchanged** — its `?W= || Easy` open is the safe default; the Keep *overrides* the
      focus to the resumed Waft when `?W=` is absent (a brief Easy→resume flicker — acceptable).
   - **Known wrinkle:** ~1-tick window on the *very first* boot where the fresh Keep isn't `boring`
      yet (could blip a nib) — gone on every later boot (it loads `boring:1` from its snap).

**Next move (in order):**
1. **Verify on `:9091`.** Fresh editor → Easy + Music/Ality co-load. Focus Music, reload (no `?W=`)
    → auto-resumes Music. Set `?W=Ghost/Net/Easy` → focus stays Easy. Check `Waft:Keep` snap appears
     at its home with `WaftTimes` + `%Cursor`, and is **absent** from the editor's aggregate snap.
2. **Per-Waft cursor resume** — record a `%Cursor` (rename-surviving locator, the `FromWhat`
    `Waft:<key>/<mainkey>:<value>` pattern) under the `WaftTimes` on cursor-land; resume it on
     foreground/boot via `Lies_keep_push_cursor`. (Touches the hot cursor machinery — do carefully.)
3. **Phase 4** `INTEREST_KINDS` table (behind `InterestLive`, lands last).

**Open forks (owner's calls — see Open questions):** ~~persistence channel~~ **DECIDED: snap to own
 home** · `%Aim` → **Navigator** name · who owns `LastCursored`+scroll · re-key timing ·
  Keep-surfaces-vs-drives Tyrant · ACCEPT provenance (locator vs ref).

## Companions

`Lens_posable_TODO.md` (the near layout TODOs this **absorbs** — TODO 1 layout-state, TODO 2
 Interest-Docs mini-list, TODO 3 nav frictions) · `Lens_handover.md` (the built Lens/%Aim seam) ·
  `Interest.md` (the channel + per-(Interest,Waft) cursor-memory TODO) · `ClusterTrust_handover.md`
   (the crypto wire — `signHeader`/`verifyHeader`/`body_hash`) · `Covenant_design.md`
    (`Tyrant.g`/`Garden.g` trust ghosts over the Peeroleum floor) · `Editron.md` (Credence / the
     verdict ledger that §6 makes first-class).
