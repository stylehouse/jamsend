---
name: cluster-first-class-object
description: "The KEEP built-code knowledge (Lies_keep* model, WAFT_PROTOCOL/watch_c bombs, per-Waft cursor-resume). NB: spec/Cluster_design.md was DELETED 2026-06-29 — Keep design now lives in Keeping_spec.md + Backbone_plan.md."
metadata: 
  node_type: memory
  type: project
  originSessionId: 9e3dbb8f-9bbc-47ee-ac57-34c8fb9daac7
---

**DOC DELETED 2026-06-29 (owner):** `spec/Cluster_design.md` is GONE — owner judged the §5-§7 acceptance×crypto thesis (ACCEPT = attention × crypto = who/what/Interest-provenance, the run-authority/"%Rungo" perspective) cheap to re-invent after the attention arc lands; the §0-§4 Keep design was already superseded by `Keeping_spec.md` + `Backbone_plan.md`. Everything BELOW about the BUILT `Lies_keep*` code still holds; ignore the "destination doc" framing. Dangling `Cluster_design` refs left in Keeping_spec/Lens_posable_TODO/Runner_talk_TODO (harmless).

NAME (owner, 2026-06-25): the ROLE is **the Keep** (workspace-that-remembers; "to keep"=retain);
 **"Cluster" reserved for the NETWORKING peer-stack** (peers/relay/trust/Idento/Aim-endpoints).
  Rename DONE (full retitle "The Keep"; networking sense KEPT as Cluster; filename
   `Cluster_design.md` KEPT — ref'd by the GhostList snap, not worth a re-record).
    FACES REFRAME: Keep = attention+acceptance, Cluster = crypto/networking, **acceptance = offspring
     born at their intersection** (Cluster signs, Keep bears). Doc carries a "## Handover" section.
      WHY-EASY-LOADS: `Editron.svelte:30/66` = the `?W=` boot Waft (default `Ghost/Net/Easy`). CODE
       THIS SESSION: a Book-level `boot_set` stop-gap (co-load Music/Ality) was added then **YANKED**
        per owner — `Editron` back to the single `?W=` open; net SPEC-ONLY. The Keep (Phase 1) owns
         the multi-load, NOT the Book. Prior Interest-switch 4-edit fix still uncommitted+unverified.

`spec/Cluster_design.md` (written 2026-06-25) is the destination doc for growing `Waft:Cluster`
 from today's thin runtime fixture (`Lies_aim_setup` `LiesFunk`~276 mints `Waft:Cluster,Aim`,
  `dontSnap` on the whole Waft, holds %Aim watcher Funkcions hoisted as `Lens:Brink`) into a
   **first-class object with three faces of one thing**:

- **attention** — the *scrunch-Waft*: gathers durable Wafts under one roof, remembers per-Waft
   `minimised` + `LastCursored` (Entcase `%lematch` locator, rename-surviving) + CodeMirror scroll,
    switched by the InterestStrip nibs (one nib per `presence:active` Interest already = the Waft
     switcher). Reframe correction: **no `dontSnap` surgery** (drops Lens_posable_TODO §"Near TODO 1"
      Option-A split) — persist via `House.stashed`, not the snap. Boundary unchanged: ephemera =
       `takes|tentative` (`Lies_waft_save` `LiesStore`:344).
- **crypto** — the cluster Idento ALREADY rides `House.stashed.cluster_idento` (`Lies_cluster_idento`
   `LiesLies`~365, 🪪 IdHatch) and signs `gen_write` ([[cluster-trust]], `Cluster_spec.md` §2).
    Tyrant.g = admission ([[peeroleum-bootstrap]], `Covenant_design.md`). The KEYSTONE: auth half +
     attention half share the SAME stashed home.
- **acceptance** — "accepting-of-tests becomes a first-class object people birth with attention &
   crypto": ACCEPT (become_book / Credence / [[entropy-samples-fuzzok]] / Tier-1 self-record-the-gate)
    becomes an object carrying who (Idento sig) + what (diff/diges locator) + the %Interest/%Lens it
     was born in (provenance). Unifies signed gen_write + the self-driving Tiers 1-4 + Editron verdict.

CORRECTED MODEL (owner, 2nd pass): a `%Lens` is a HOLE (presentation real-estate), NOT a durable
 property — a `face` (`comp_<LensKind>`, ALREADY the codebase term: `LensHost.Face`, `Funk/kinds.ts`
  "hoisted faces") is what fills it; durability lives in the FUNKCION that projects the face. So an
   Interest does NOT own a durable %Lens (earlier framing was backwards). Owner's `InterestWrangle`
    = a Cluster/Funkcion that takes over the InterestStrip Lens + arranges the Interests, each with
     its own sub-%Lens = recursive holdering. DECIDED 2026-06-25: `face` DROPPED
      ENTIRELY (not derived/stored) — nothing reads it but a debug tooltip (`InterestStrip:172`); the
       trail renders via `%ActiveInterest`+`%LE` (NaviCado hard-mounted `DocMinimap:699`), never a
        face string. The two presentation worlds are UNCONNECTED today: World A = real Lenses
         (Funkcion→`Lies_lens_suggest`→`Lens:<Kind>,of_Funkcion`→LensHost mounts `comp_<LensKind>`),
          World B = Interest.sc.face = an inert string. Convergence = InterestWrangle routes per-kind
           faces through World A. KIND SET 5→4: Sidetrack MERGED into Aside (`Trail·Ting·GhostList·
            Aside`); Aside = Waft-first/open-or-create, sprout-origin (`%fromWhat`) TRANSIENT (not
             stored — hard What-ref barred from sc), Docs persist, durable-but-GC'd after notes
              vacuumed (old Sidetrack `%from` reverse-arrow in `interest_reconcile`~116-137 deletes).
               Particle keeps only waft/state/in_Doc/LastCursored. INTEREST_KINDS table = fuse the 4
                existing switches (`interest_kind_from_stance`/`_face_for`/`_presence_for`/`_cursor_for`).
%Aim = the OUTWARD half of Cluster (peers+carrier liveness, traffic-light, where-to-aim, →re-dial/
 Tribunal); rename UNDECIDED — Navigator proposed (steers) vs Compass/Bearings/Lookout.
BOOTSTRAP SEAM (§0b): a Waft is born when a Plan/Prep (or Liesui dock-open, or GhostList auto-load)
 fires `e_Lies_open_Waft(path)` → mints a `Good,type:'text/Waft'` slot under req:Store (NOT the Waft
  particle) → LiesPersist/`LiesStore_read_good` materialises `w.oai({Waft:key})` from disk-or-fresh.
   Editron Book Prep opens `Credence` this way. ODDNESS: Cluster (a board, like Credence) is NOT
    opened this way — it's minted directly in `Lies_aim_setup` (dontSnap, rebuilt each boot), the
     thin-fixture pattern that fights durability. DECISION owed: graduate Cluster to open_Waft+home
      (like Credence) OR keep mint + ride stashed. `Lies_open_Waft(path)` IS Phase 2's "acquire/open
       model" — reopen set = loop it per remembered path. Aside-origin = `%FromWhat` loose string
        ("stringy cheese", not a ref) already in `e_Lies_ghost_pick`.
RESUMABILITY = TWO channels (don't conflate): **`?W=` URL** = thin SHAREABLE/bookmarkable pointer to
 the FOCUS (one Waft) — Keep drives it via `history.replaceState` on switch (today READ-ONLY at boot,
  `boot.ts:13` `boot_param('W')`; app never writes URL) — vs **`House.stashed`** = the RICH resume
   (open set + per-Waft LastCursored/scroll/minimised; "resumes stuff" lives here). Boot precedence:
    explicit `?W=` wins focus (deep-link/share), else last-focus from stashed; the SET always from
     stashed (URL can't carry it). Fork: `replaceState` (honest URL, no history, default) vs
      `pushState` (browser Back walks Waft-focus history = "navigate", but Back can exit overlay).
Phases: 1 know-the-durable-set, 2 reopen-all-on-boot (boot focuses ONE today: `Lies.svelte`~832
 acquire→`Lies_focus_waft`), 3 LastCursored+scroll, 4 re-key `Interest:<WaftTail>` + shed
  presentation strings (riskiest, behind InterestLive). Open Qs in the doc (persistence channel,
   who owns LastCursored, Aside durable?, re-key timing, Cluster-subsumes-Tyrant scope, Aim name).
    Companion to [[interest-channel-graduated]] / [[lens-posable-layout]].

**MODEL = Waft:Keep is a PARTICLE, not a flat list** (owner correction 2026-06-26 — first try was a
 `stashed.Keep.wafts` string-array, SCRAPPED: "an entire thing unto itself"). Shape: `Waft:Keep`
  (`%boring` → no nib/no focus) = a LEDGER of `/%WaftTimes,of_Waft:<path>,discovered_at,accessed_at`
   (one per Waft ever found), each with a `/%Cursor` history (last ~10, resume the cursor INSIDE the
    Waft); the Keep ALSO keeps its OWN `/%Cursor` history (last Wafts focused) → boot AUTO-RESUMES the
     last when `?W=` absent. PERSISTENCE DECIDED (owner 2026-06-26) = **SNAP to its own home** (real Waft, reuses Lies_open_Waft/
 Persist/Lies_waft_save → `wormhole/…/Keep/toc.snap`). `%boring` does double duty: out of the editor
  AGGREGATE snap (Lies.svelte:728 carries it to the Good) + out of nibs/focus, BUT still saves to its
   OWN home (Lies_waft_save skips only takes|tentative, NOT boring). Idento stays in stashed (crypto);
    attention snaps. LANDED type-clean (`Lies.svelte`): MODEL = `Lies_keep` (READ-ONLY getter — Persist
     is sole creator, no lazy race) / `_note` (no-op till loaded) / `_mark_focus` / `_push_cursor`
      (capped-10+coalescing) / `_resume_waft` / `_reopen` (seeds Easy+Music/Ality). BOOT DRIVER =
       `Lies_keep_boot(w)` from Lies_heartbeat (editor-only, staged via w.c.keep_opened|booted|resumed):
        (1) open Waft:Keep→Persist loads/creates; (2) once materialised→stamp boring+reopen ledger;
         (3) no-?W=→foreground `_resume_waft` (canonical e_Lies_foreground_waft). ?W= still wins (Editron
          opens first; Editron UNCHANGED, Keep overrides focus → brief Easy→resume flicker). Hooks:
           e_Lies_open_Waft→note, e_Lies_foreground_waft→mark_focus. interest_roster skips %boring.
            WRINKLE: ~1-tick non-boring window on FIRST boot only (loads boring:1 after).

**EMPTY-KEEP BUG FOUND+FIXED (2026-06-26):** the Keep persisted EMPTY because `WAFT_PROTOCOL`
 (`Text.svelte:354`) only listed `['Waft','What','Doc','Point']` — `WaftTimes`/`Cursor` mainkeys were
  NOT in it → enWaft hit a fatal "mainkey not in protocol" error → `Lies_waft_save` ABORTS the whole
   save (subtree skipped). GOTCHA: any NEW child mainkey under a snapped Waft MUST be added to
    WAFT_PROTOCOL or the Waft silently won't save. Fixed: added `WaftTimes`,`Cursor`. (means.skip /
     means.dontSnap exist as rule-level encode controls — Text.svelte:666/697 — `means:{skip:true}`
      omits a particle entirely; this is how a runtime `Funkcion` child can coexist with a snapping
       Waft, since per-particle `sc.dontSnap` is NOT honored by enWaft, only rule-level means.)

**OWNER DESIGN (2026-06-26, NOT yet built):** (1) the Keep should AUTO-HAVE a `/Funkcion` for its
 agency (like Cluster's Runner/Relay) → add `Keep` to FUNK_KINDS (`Funk/kinds.ts`) with a `run`
  (reopen/resume/maintain on the pump), re-add `Funkcion:Keep` cell at load (Lies_instantiate_funkcions
   binds it), skip `Funkcion` in WAFT_PROTOCOL encode so it coexists with the snap; open the Keep via a
    Prep (like Credence) → retires the heartbeat `Lies_keep_boot` poke. (2) the Keep holds per-`%Waft`
     LAYOUT status (minimise + Langui Vexpandys + scroll) as sc on each WaftTimes — encodes now.
      RECOMMENDATION on Vexpandy fork (owner unsure Keep-vs-mem): per-dock/per-Waft Vexpandy → Keep
       WaftTimes; truly-global editor chrome (Liesui run-card) → `mem()`/House.stashed. (Vexpandy =
        generic bindable `expanded` toggle, parent owns state; persistence = bind to the chosen store.)
         OWED: build (1)+(2) + :9091 verify.

**PER-WAFT CURSOR-RESUME — BUILT (2026-06-26, type-clean, :9091-unverified, uncommitted)** — the
 freshest owed piece, done together with the focus-bounce fix (see [[interest-switch-active-fix]]):
  RECORD on every want-land (`Lies_resolve_wants`, reusing the `landed` waft the bounce-fix computes)
   → `Lies_keep_note_cursor` pushes a `%Cursor,what:<mainkey:value>` (within-Waft tail of the FromWhat
    locator) onto the Waft's `WaftTimes` (consumer-read, no oai churn; coalesced/cap-10). RESTORE in
     `e_Lies_foreground_waft` (the canonical foreground used by BOTH nib-click AND `Lies_keep_boot`
      resume) → `Lies_keep_resume_what` resolves the latest `%Cursor` back to a live particle via
       `Lies_locate_in_waft` (DFS %What-any-depth then %Doc, String-match) and emits a `Lies_want{cold}`
        that wins over land-on-first; falls back to `Lies_desire_land_cursor` when nothing's remembered
         or the locator no longer resolves (anonymous `What:1` degrades to land-on-first, never worse
          than before). Survives reload because `WaftTimes`/`Cursor` are in `WAFT_PROTOCOL` + the Keep
           snaps to its own home. So a nib | boot re-lands where you were INSIDE the Waft, not its first What.

**WHERE THE KEEP LIVES (the "can't find boring in the snap" confusion, 2026-06-26):** the Keep is
 NOT in the editor AGGREGATE snap (`story:Editron` exp/actual, the big toc.snap) — `%boring` makes
  `Lies.svelte:734` stamp `good.sc.boring=1`, dropping it from the aggregate BY DESIGN. It lives in its
   OWN home **`wormhole/Keep/toc.snap`** (`Waft:Keep,boring` + one `WaftTimes,of_Waft:<path>` per Waft).
    To verify the Keep, `cat wormhole/Keep/toc.snap`, NOT the aggregate.
**FOCUS-SEED GAP FOUND+FIXED (2026-06-26):** the Keep-own `%Cursor` (auto-resume-last source) was only
 seeded by `Lies_keep_mark_focus` on an EXPLICIT nib-foreground (`e_Lies_foreground_waft`) — passive
  focus (tree-click | boot land | gesture) never seeded it, so auto-resume stayed empty across reloads
   (Keep snap had WaftTimes but ZERO Cursor). Fixed: the want-land's active-SWITCH block (`Lies_resolve_wants`,
    the same `if (landed && !landed.sc.active...)` that the bounce-fix added) now also calls `mark_focus`,
     so EVERY focus change seeds the Keep-own %Cursor. Separation: mark_focus=which-Waft (Keep %Cursor),
      note_cursor=where-in-Waft (WaftTimes %Cursor).
**THE BOMB — Keep accumulation never persisted (found+fixed 2026-06-27):** `watch_c` (the per-Waft
 save-watcher, `Housing.svelte.ts:1438/1451`) compares **the ROOT node's `C.version` ONLY** — it does
  NOT descend the subtree. So `Lies_waft_save(Keep)` fires only when `keep.version` bumps. The seed
   (`keep.oai`) and a manual top-atom edit (`alrighteo`) bump the Keep → saved; but `Lies_keep_note`
    (set `wt.sc.accessed_at`, NO bump) and `Lies_keep_push_cursor` (bumps the WaftTimes/Cursor CHILD,
     not the Keep) never bumped the root → **accessed_at froze + %Cursor never reached disk** (Keep
      looked frozen/empty though the WaftTimes were live in RAM). FIX: `keep.bump_version()` after every
       accumulation (`Lies_keep_note`, `Lies_keep_note_cursor`; `mark_focus` already covered via
        push_cursor(keep)). GENERAL RULE: a deep mutation under a watch_c'd Waft must bump the WAFT ROOT
         or it won't save — normal Doc/Point edits already do (replace/LE_pull bump the root); Keep-style
          descendant accumulation did not. VISIBILITY (separate, still open): `%boring` makes the Keep
           VANISH from snaps+inspector — `Story.svelte:1047` boring = hide LINE+subtree (`not=true`),
            vs `:1052` dontSnap = hide subtree, KEEP line (that's Keep-vs-Cluster sitting adjacent). So
             the Keep is uninspectable in-editor; verify via `cat wormhole/Keep/toc.snap`. boring is
              shared (EntropyProfiles, focus-filter Lies:979, nib roster) so decoupling visibility from
               exclusion is a real change — don't swap boring→dontSnap (loses focus/nib exclusion).
**DESIGN PRINCIPLE (owner, while reviewing `req:workon,w:%w:Lang`):** worlds (`w:Lang`/`w:Lies`) are
 globally-unique singletons the snap doesn't type-check; don't STORE a ref to them (findable directly) —
  "perhaps req:workon doesn't need `w` at all" (a separate Lang-core cleanup, NOT done; would touch the
   workon pump's backlink). The Keep cursor already heeds this: a STRING locator (`What:<value>`), not a C ref.

----
## merged from keeping-phase1-kindtable.md

---
name: keeping-phase1-kindtable
description: req:Keeping refactor — kind-table deleted → one %equip flag + stored %minimised; un-blinds the Keep
metadata: 
  node_type: memory
  type: project
  originSessionId: ce9a058e-b2c4-4be7-8772-57abeb9cc55d
---

The `req:Keeping` refactor (consolidate focus/attention/cursor into one driver) — spec is `src/lib/O/spec/Keeping_spec.md` (reviewed twice; D1-D7 settled; borders [[cluster-first-class-object]]). Two axes the old `%boring` flag conflated: **KIND** (what is this Waft, durable → now the one **`%equip`** flag on the Waft, NOT a kind-table) vs **ATTENTION** (am I looking at it → req:Keeping, off the cursor).

**The kind-table (`LIES_KIND_CAPS` + `Lies_waft_kind`) was BUILT then DELETED 2026-06-28** — owner found the 4-boolean projection silly and collapsed it to ONE property. Final shape (`:9091`-UNVERIFIED; full `svelte-check` won't run here — 2GB cgroup OOM, verify on host):
- **Two layers, only the near one on the Waft.** A Waft carries thin config flags; the face|lens layer (what UI shows) is NOT on the Waft — it rides the Funkcions inside it (each projects a `comp_` into a Lens hole: inline UI:Waft = close-up Lens, hoisted dock = far Lens). So the Waft needs only: **`%equip`** (out of the cursor's way — no focus, no nib, load-Good backstage-hides, subtree folds from snap) + **`%minimised`** (UI:Waft starts collapsed; STORED on the Waft, toggled in `ui/Waft.svelte`, persists; absent=open).
- The old 4 booleans collapsed losslessly: focusable|nibbed|backstage were all just `!equip`. 6 consumers now read `!wf.sc.equip` directly (focus filter, want-land ×2, `interest_roster`, Waft count, load-Good `if(equip)`).
- **`%minimised` is Keep-BACKED, not a Waft flag** (owner: "projected onto it via Keep"). General per-Waft config store `Lies_keep_cfg_get/_set(w, path, key)` on the Keep's `WaftTimes,of_Waft:<path>` record (so it persists even for the dontSnap Cluster; the Keep owns attention state — Cluster_design §1-2). `Waft.svelte` minimised = `$derived` projecting `cfg_get` (tracks `keep.version ?? w.version`); toggle = `cfg_set(... minimised ? undefined : 1)`. get uses a RAW Keep lookup (no migrate/bump → safe in $derived). Cluster born-collapsed = `Lies_aim` seeds `cfg_set('Cluster','minimised',1)` ONCE, gated on `WaftTimes`-absence (so a later session honours a user expand). minimised default = open (absent). This is the first tenant of the general get/set; scroll/LastCursored ride it next.
- **equip stamped:** `Lies_keep` → `equip:Keep` (migrates off old `boring`|`kind`); `LiesFunk.Lies_aim_setup` → cluster gets `equip:Cluster` + `minimised:1` (born collapsed) — keeps `dontSnap` too (spec/Cluster_design §0: rebuilt-each-boot, never persisted). On-disk `wormhole/Keep/toc.snap` hand-set to `equip:Keep` (its HOME snap keeps the full timestamp ledger — that's persistence; the equip fold only bites the ENCLOSING/Story snap).
- **Snap fold for equip:** ONE hardcoded `Story.svelte` story_matching rule `{ sc_has:{Waft:1,equip:1} } → means:{dontSnap:true}` (emit header, fold subtree). Hardcoded NOT a stored `%lematch` Entcase — owner rule: `%lematch` only when the rule is C** you want enWaft-able. + a fold TRACE: `story_process_node` appends `/* subtree omitted (dontSnap) */` to any dontSnap line (no count — would churn). The 3 NormalEntropy timestamp Entcases REVERTED (equip folds them away, nothing to tame). See [[trope-entropy-profile-sharing]].
- **OPEN fork:** GhostList — spec calls it a content Interest kind (Trail·Ting·GhostList·Aside); owner leans equip-that-pushes. Credence|GhostList NOT yet stamped equip (only Keep+Cluster). The face refactor proper (drop `Interest.sc.face`, derive from kind via a wrangler Funkcion — Cluster_design §3b) still ahead.

**NEXT (do NOT before :9091 confirms Phase 1):** Phase 2 = stand up `req:Keeping` beside desire/acquire/timemachine/workon (assert same focus+converge), App still boots. Phase 3 = cutover (drop timemachine playback — only NaviCado consumes it; fold land→step3; retire desire/acquire into Keeping). Phase 4 = rideable #3 (per-Waft minimise/scroll). Renames deferred to cutover: LiesHold→LangHold, Interest.svelte→LangCurse, new LiesKeep. `enWaft` mainkey gate is PARKED so child kinds snap free. Spec gap 1 (real added scope): a background-kind Funkcion has no carrier — needs the on-load kind-sweep generalizing Lies_keep_boot (deferred till Cluster's sync exists).

**2026-06-29 — the full backbone is now planned in `spec/Backbone_plan.md`** (the phased Keep+Interest+Lens build, the 4th doc of the **attention-layer trio**: Interest=channel, Keeping=persistence, Lang=editor; the Waft medium documented atop `Waft.svelte`, old `Waft_spec.md` GUTTED to a pointer; the three Funkcion faces DocTing/DocGhostList/IdHatch moved `ui/`→`Funk/`). Phases P0(clear snags: defuse Lens Runner-reactivity bomb, delete dead Sidetrack) · P1(snapped `kind` + on-load sweep = gap 1) · P2(one resolver + loose locators, keystone) · P3(req:Keeping beside) · P4(cutover+rename) · P5(layout service = Keep↔Lens weld) · P6(thin clients) · P7(dissolve %Spotlight, separate/later). **The Lango channel (P3):** `%Lango` generalises to the universal attention-event, sub-typed (`%Lango/%Cursor|%Lens|%mode`). One setter `H.lango(target,what)` = a **homing helper over `i_elvis`** (homes the `%Lango` particle the way `i_elvis_req` homes a *req* for its reply — but **one-way, no reply handle**; the "answer" is the show moving, read off roster/Keep state). **Source** = the req *already in the machine* (Funkcion's own / `req:Keeping**` stage's own / for a **bare UI:Waft click**, the one emitter outside the machine, "the req on top of its Waft" = a thin per-Waft base carrier in Lies). **Receiver** = ONE sink, **`req:Langoer` = `req:Keeping` wearing its receiver hat** (NOT a separate organ; = the noun "top of all Interests" `Languinio`→`LangCurse`'s) — holds pull-policy (which Interest wins / displaced-focus fate) + hands **levels** to the Keep. Delivery on the `waft_roster` one-way pattern (`i_elvisto`+`reqyoncile`); `o_elvis_req.finish` reserved for the rare ack. Keep persists **levels** (standing) not **impulses** (one-shot). NO "Tide" organ — Keep↔Interest + channel IS the whole machine. `waft_roster` keeps roster/sig/push set-sync but **sheds**: stance/kind/face/presence→kind-table, cursor/foreground→Lango, lifecycle→Keep, Sidetrack→deleted; `interest_reconcile` (live `Interest.svelte:111`, **eatfunc-mixed** → invisible to grep/svelte-check, NOT dead) collapses to thin membership sync (rideable #6). Open forks (narrowed): **Lango residue** (source-origin-trace + Keep-ledger? lean: source mints into `.c`, levels→Keep, impulses drop) · ride same wire as `waft_roster`? · `Languinio` rename.

**De-req-ifying the Funkcion pump (Backbone_plan.md P3; split into 2 chunks):** today every Funkcion w/ a `run` minted its OWN eternal `req:Funkcion,funk_id` (`Lies_register_funkcion`) → Credence snapped **48**, each pumping `storying_run` which re-scans ALL run_results every tick to bail unchanged (`Storying.svelte:27`) = a poll faking an event. **CHUNK 1 BUILT 2026-06-29 (uncommitted, :9091-UNVERIFIED, full typecheck OOMs here):** `Lies_ensure_waftica(w,waft)` REPLACED `Lies_register_funkcion` — **one `req:Waftica,waft:<path>` per Waft** in `w/Funkcions`; its do_fn walks the Waft subtree once/tick running every `funk.c.run` (behavior-preserving — same runs incl Storying's poll, just consolidated); a migration drops stale `req:Funkcion` on first ensure; stamps `main:<kind>` (=`%Funkcion,main` child OR match `Funkcion:<K>` vs the Waft's snapped `kind` = "check Funkcion:* vs projected-on properties"); reserves the %Lango/excitement socket (latent). Callers rewired: `Lies_instantiate_funkcions` (binds run then ensures ONE carrier) + `GhostList_funkcion`; cluster `Lies_aim_setup` inherits. **`req:Liesica` proved UNNECESSARY** — checked: NO run uses req machinery (Runner/Relay are plain `(host,funk,ww)` like storying_run, no finish/ttlilt/doai), so every Funkcion just rides its Waft's Waftica walk; no per-Funkcion req survives. Trail Funkcion is NOT in this pump (run directly via `LE_host_funkcion`, rides a Seem). **Net Credence 48→1.** **CHUNK 2 BUILT 2026-06-29 (uncommitted, :9091-UNVERIFIED):** Storying → event-driven. Dropped `run` from `FUNK_KINDS.Storying` (no longer pumped, no `funk.c.run`); `Lies_reflect_storying(w,sel?)` walks `w.o({Waft:1})` deep, restamps matching Storying cells via the unchanged `storying_run`. Wired at the **ONE** landing site `Lies_run_result_recv` (run_result is created NOWHERE ELSE — `Lies_report_result` is the runner-EMIT, stamps nothing; my earlier "2 sites" was wrong) `{path, book:frame.book}` + a load-time pass in `Lies_instantiate_funkcions` (reuses its `all` walk → a freshly-loaded/edited board lights from results already present). Kills the 48 Storying scans/tick. CreduFunk/StoryTimes STAY pumped (read run_result directly, independent of the poll; scope kept tight to Storying). Touches the Editron verdict wire → green Credence run is the gate. Both chunks Svelte-compile clean. User CONFIRMED Storying|StoryTimes works fine = the baseline to preserve. Each chunk re-shapes the `Funkcions` snap → own commit. Name Waftica soft.

**P0 dissolved + P2 keystone BUILT (2026-06-29, uncommitted, :9091-unverified):** P0 audit found BOTH snags moot — Lens "bomb 1" ALREADY fixed (Runner.svelte:50-53 / Relay.svelte:31-33 have the `now=$state`+`setInterval(1s)`+`onDestroy` ticker, Relay comments "the Runner-bomb fix"); and the "dead Sidetrack code" is NOT dead — `interest_sprout_sidetrack` is genuinely undefined BUT `LakeSurprise` still drives `e_Lang_sprout_sidetrack`(Prep7)+`e_Lies_open_sidetrack`(Prep8, mints the `/side` tentative Waft)+foreground(Prep9), so deleting needs scrubbing those Preps + re-recording the Book (own chunk, host green-run tail; Interest.md §14-15/§82-86 mis-call it dead). User picked **P2 over the Sidetrack chunk**. P2 = `Lies_resolve_locator(w,locator,scope?)` in Lies.svelte beside `Lies_locate_in_waft` — ONE loose resolver subsuming the 3 forks: `<mainkey>:<value>` in scope (→Lies_locate_in_waft) · `Waft:<key>[/tail]` (Waft by value, recurse) · `text:<word>` (loose substring; ranked def/call search stays future). NEVER throws → undefined (caller lands on first), so a rename DEGRADES not blocks (full rename-caretaking = Keeping #8, later). Only Fork1 (`Lies_keep_resume_what`) was a LIVE repoint; `%FromWhat` was WRITE-ONLY (Lies.svelte:305) so the resolver is its waiting reader; `text:` born here. Gate = **`Story:LakeLocate`** — a REAL in-system Story Book (NOT a scratch spec; owner: "everything inside the system, do it with the Lies%runner"): `Run_A_LakeLocate` + `e_Lies_locate_selftest` Prep handler in `test/Machinery.svelte`, recorded via `node scripts/Story_cli_run.mjs LakeLocate --accept`. Drives all 3 forms + rename, witnesses each passing claim as a DURABLE marker under `LocateGate` (a `see` particle is the transient Lies status line — gets SWEPT; a plain child snaps). Folds the GhostList (volatile) + equips the test Wafts. GREEN match 1/1, 73-line snap. The scrapped `scripts/LakeLocate.spec.ts` was the scattered-.ts anti-pattern.

**P1 RECONCILED + VERIFIED (2026-06-29, uncommitted):** P1 also largely SUPERSEDED (like P0). `Lies_waft_kind`/`LIES_KIND_CAPS` are GONE (kind-table collapsed to `%equip` 2026-06-28); the focus filter/Waft-count/load-Good-fold/want-land already route through `!wf.sc.equip` (Lies:648/752/960/998), and P1's GOAL ("background kinds get a carrier they'd otherwise never get, before focus") is already MET by Chunk 1 — EVERY Waft gets a `req:Waftica` carrier at load (`Lies_instantiate_funkcions`→`ensure_waftica`, from Lies:755). What's genuinely LEFT = an OWNER FORK, not a safe build: a snapped **`kind`** field (type-name for foreground Wafts too, distinct from the `%equip` attention-flag) would add a `kind:` key to EVERY Waft in EVERY Book's toc.snap = a fleet-wide re-record — owner's call, deferred (it's the face-wrangler's input, not P3-blocking). Dead remnant: `main:<kind>` at LiesFunk:171 reads `waft.sc.kind` (never set) → inert till the fork. VERIFY half DONE = **`Story:LakeKeep`** (in-system, `Run_A_LakeKeep`+`e_Lies_keep_selftest` in Machinery) GREEN match 1/1, KeepGate markers: `background_Waft_gets_a_carrier`(the goal, via real instantiate path)/`loaded_Waft_gets_a_carrier`/`equip_out_plain_in_focus`. NEXT = P3 (req:Keeping + Lango channel — needs owner design decisions, don't build unsupervised) OR the snapped-kind fork (owner) OR the Sidetrack-deletion chunk (needs LakeSurprise re-record). NEXT backbone = P1 (snapped `kind`+on-load sweep) or P3 (req:Keeping beside, the Lango channel — the resolver's first big caller).

**P3 DESIGNED (2026-06-29, owner-driven, in `Backbone_plan.md`; no code yet):** owner cooked the P3 §end-to-end with me. **Channel:** a `%Lango` = "an intent to do something with a piece of the source, tracked over time"; born+held on the causing Waft's `req:Waftica` carrier as a **source terminal** (`i_elvis_req`-shaped — terminal hangs the `%Lango` the way i_elvis_req hangs the reply-`req`), lifecycle = **yoink · Ctrl-Z(filed TODO, minimap/Lens-focus-gated) · out-compete** (newest-wins same-Interest / cross-Interest→Langoer). One-way by default; an ack-needing Lango grows a child **`/landing,req`** the remote drives + **reqyonciles** back ("how I landed") = `o_elvis_req`'s reply in the maz stack. **Residue: NO Keep ledger of Langos** — only the **level** persists (the `%Cursor` resurrects "the first bit", the rest is wild). **`req:Langoer` convergence DECIDED** (= `req:Keeping` steps 2→4, NOT a new organ; embryo already exists): (1) which-Interest-wins = **newest focus-Lango**, foregroundables only, `Lies_focus_waft` IS the selector (`.sc.active`→cursor→first-non-`equip`); `equip` excluded so background never steals foreground (Upkeep/Errand=Brink pole); non-pull sub-types (`%Lens`/`%mode`) set a level w/o moving. (2) displaced-focus = **demote-warm** (`Lang_set_interest` already: `locked→pending`, keeps its `%LE` for crossfade-back, level→Keep). (3) one-wire-vs-two = **dissolved**: one req (Keeping) owns BOTH the Lango-event intake AND the roster-sig intake = two faces of one walk. Parked seed = "algebra of where-to-do-what" if a landing gets shared across too many parties. **Build split:** (a) channel = decided + LOW-RISK (no live-focus touch till read) → buildable, gate w/ own Book; (b) parity driver (cut `req:Keeping` in beside desire/acquire/workon, inert-checked) = OWNER-SUPERVISED. **Step (a) CHANNEL BUILT 2026-06-29 (uncommitted, in-system-green), KEPT MINIMAL:** just `H.lango(w,source,what)` in `LiesFunk.svelte` beside `Lies_ensure_waftica` — mints `%Lango,<kind>` (with `what.to` locator) on the source Waft's `req:Waftica` carrier (the terminal), out-competes same-kind prior (newest-wins). READS NO FOCUS (carrier walk steps over a %Lango = no `funk.c.run`) → pure additive scaffold till `req:Langoer` reads it. Gate = **`Story:LakeLango`** (`Run_A_LakeLango`+`e_Lies_lango_selftest` in Machinery, recorded `node scripts/Story_cli_run.mjs LakeLango --accept`): GREEN 1/1, 3 markers under `LangoGate` (mint/out-compete/coexist), `001.snap` terminal end-state is the gate. **`lango_land`(the `/landing,req,maz:7` ack reqyoncile) + `lango_yoink` BUILT THEN STRIPPED same day** — owner: "I was just posturing, wait until something needs it"; most %Lango is fire-and-forget so the ack is the RARE exception (one-way by default), yoink's consumer is a future close-button-on-an-Interest. Both stay DESIGNED in Backbone_plan, unbuilt in code. **Cursor seam RENAMED 2026-06-29:** `e_Lang_workon_update`→**`e_Lang_lango`** (the cursor `%Lango/%Cursor` arriving at Lang, `Lies_i_Spotlight` feebly-fires it → seeds `workon.c.src` → wakes `req:workon`=the Langoer hat); 6 code sites (LiesHold handler+hdr, LiesCurse call+cmt, Lang.svelte×2, LiesFunk cmt) + 6 spec refs (Keeping_spec×4, Backbone_plan×2), grep-clean. This is just the RENAME — it does NOT yet *call* `H.lango` (the minter); that's still the 1st hot-path touch (NOT yet: `e_Lang_lango`→`H.lango` caller, + step (b) parity driver, owner). Now FOUR in-system Lake* gates: LakeLocate(P2)/LakeKeep(P1)/LakeFunk(Chunk2)/LakeLango(P3 channel). **NB all 4 Lake* Books share a flaky `known,dige…kind:read` line** = the GhostList `dirlist` Good-read content fingerprint (NOT folded by `dontSnapGhostList`, which only folds the Waft subtree); drifts whenever wormhole gains dirs (e.g. TextInca/Credulate) → was a 1-line red unrelated to any code change. **FIXED 2026-06-29 (Story.svelte, no re-record):** a GhostList-SCOPED spay rule (`{sc_has:{Good:1,waft_path:'GhostList'}}` → thence the `known,kind:read` child → `spay:{re:'dige:[0-9a-f]+',tol:'any'}` + at-mung) forgives the dirlist read's churning dige VALUE while keeping the line — purely additive to the COMPARE (fixtures untouched), so it greens EVERY dontSnapGhostList Book. Scoped by parent Good's waft_path so LakeSurprise's REAL content reads still gate (the real-IO rule deliberately keeps every other read's dige). All 4 owned Lake* (Lango/Keep/Funk/Locate) went 1/1 **but ONLY in the headless Story_cli bubble** — and that's the trap: owner ran them on the REAL Lies%runner and they're ALL-RED for a DIFFERENT reason (the real runner quiesces at `round=4` with NO GhostList loaded + acquire unfinished; my headless boot reads the wormhole off disk → loads GhostList → `round=8`; fixtures baked the bubble). So this dige-spay is a **band-aid on a headless-only symptom** (dige DRIFT) — irrelevant to the real problem (whole GhostList footprint ABSENT). DROP it once the gate is real. The fix = make the Book env-independent (fold the WHOLE GhostList footprint: Good+dirlist-Funkcion+desire-Waft+o_elvis, normalize acquire-finished/Waft-count) OR re-record from the live runner. **VERIFY VIA `scripts/runner_ask.mjs`, NEVER Story_cli** — see [[verify-via-live-runner]] (now canonical in CLAUDE.md). NB the `self,round=N` flake WAS a red herring (already spay-handled at Story.svelte:900, tol:any; raw shell diff shows it but the runner's compare forgives it).

**The focus-BOOMERANG (owner-reported 2026-06-29) + write-chokepoint seeded:** live symptom = "focus switches back to Radiola.g when I look at anything else, boomerangs back for one think() in ten." DIAGNOSED static: focus = `Lies_focus_waft` leg-1 `.sc.active`, re-landed on the cursor EVERY tick by `req_timemachine`→`Lies_desire_land_cursor`; `.sc.active` was written from **5 scattered sites, NO arbiter** (open/Aside/+Now/want-land/Liesui list), leg-3 fallback `wafts[0]`. So a stray re-assertion (the Keep resume-`want` at `Lies_open_Waft` re-minting `cold` into a re-opened Waft) OR a 1-tick active-gap→`wafts[0]` snaps focus back. **NOT a Funkcion** — grep confirms NOTHING in `Funk/`/`gen/` touches want/Spotlight/active, so Radiola's caster isn't grabbing focus; it's purely the no-arbiter free-for-all = exactly what `req:Langoer` kills. **BUILT (behavior-preserving):** `Lies_set_active_waft(w, waft)` in Lies.svelte (write twin of `Lies_focus_waft`) — the 5 `delete-all-then-set` sites now funnel through it (the ONE place Langoer will govern; kills any active-GAP boomerang since clear+set is atomic). Pure extraction, LakeLango byte-identical bar the 2 known flakies; callers keep own `bump_version()`. Does NOT yet fix the boomerang behaviorally — it's the chokepoint the fix (Langoer governing WHO claims active) sits on. **Boomerang = step (b)'s acceptance test:** focus once moved to B stays B across ticks, never falls to `wafts[0]`, never out-competed by a background re-open. **FEED = OBSERVABLE snapped %Lango (corrected 2026-06-29, owner: "things should be observable, the architecture showing in snaps ISN'T noise pollution").** The cursor move mints a NORMAL snapped `%Lango/%Cursor` via `H.lango` AS-BUILT; **out-compete bounds it** (1 Cursor/Waft, newest-wins, never accumulates); the ordering `seq` is the ONE nondeterministic field → MUNG it in fixtures (age/at pattern) = structure visible + snap deterministic. Re-recording fixtures to show Langos = real focus state becoming VISIBLE (a feature) — esp. since today's `.sc.active` is a `SESSION_KEY` (Text.svelte) OMITTED from snap, which is WHY the boomerang is slippery (no snap line shows the flicker). `req:Langoer` arbitrates off the observable Langos (highest seq wins, foregroundables only). "Impulses drop" = the KEEP not hoarding every twitch (persists the cursor LEVEL/resume-point), NOT hiding the live intent. `.c` is for refs/backlinks that can't encode (`lango.c.source`), NOT for keeping state out of view. **NET: no `.c`/`dontSnap` — just call `H.lango` from the seam (with a seq); the '.c fork' DISSOLVES** (my earlier '.c/impulse-drop' note treated observable state as noise = backwards). OPEN (the better Q): make focus itself a VISIBLE particle Langoer derives (drop session-only invisible `.sc.active`)? = heart of step (b).

**Shelver `%shelved` DROPPED (BUILT 2026-06-29, `Funk/Shelver.svelte`):** the per-Book tombstone ledger gone; presence is now ONLY `on_board` (the `Funkcion:Storying,of_Book` cells). `shelver_plan` lost its `filed` param; one-shot migration drops legacy `%shelved` children on walk; face shows `funk.c.board_count` ("N on board") not the filed count. TRADE: a hand-deleted Book re-files next sweep (≤5min) — accepted for a zero-footprint Shelver. Uncommitted, :9091-unverified.
