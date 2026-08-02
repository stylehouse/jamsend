---
name: editron-verdict-phase2
description: "Editron→runner Phase 1 verdict wire landed (green now honest); .ls-health step badge landed (2/5 Book); Phase 2 Funkcion red|green / Credence matrix spec'd, not built"
metadata: 
  node_type: memory
  type: project
  originSessionId: c67a2909-19bd-48ca-8f50-78a33a99ae82
---

> **Editron WATCHES THE OWNER'S LIVE Lies%editor (owner, 2026-07-01).** It is not a synthetic
> world — its got_snap mirrors the REAL editor state (which Waft/Doc is focused, cursor position,
> content) as the owner actually uses it. So content/focus **drift is EXPECTED**, and **ONLY the
> owner can Accept it** (at a known editor state). **Do NOT auto-re-record it** — an agent/headless
> `runner_ask accept` bakes a transient and it re-fails instantly (confirmed 2026-07-01: a re-record
> went red again in one run — 14 lines, all un-munged nondeterminism: `Credulate finished_at=<ts>`,
> `want=<ts>` accumulator keys [the P3 Lango feed], `compile/secs/all` wall-clock timings). That
> pure-timestamp nondeterminism IS a real separate gap (worth munging via story_matching or a Trope
> entropy profile); the focus/content delta is just the live-editor nature. [[verify-via-live-runner]]

The Editron→runner channel ("assure the editor a whole Story ran remotely") is the
live front. As of 2026-06-19:

**Phase 1 — DONE (verdict wire).** Editor↔runner transport + acquire-then-poll
handshake + run fire + run_result return all work two-tab (NOT headless — the UIless
include problem blocks node; v1 = second browser tab). The keystone (`active_transport`)
is live. The fix this session: run_result was a provisional `ok:true` sent at rungo
FIRE (= "launched", not "passed"). Now FIRE stashes `w.c.awaiting_verdict={path,dige}`
and the REAL verdict goes back from `storyFinished` via new `Lies_runner_verdict(w)` →
`Cred_run_outcome()` {ok,ok_pct,done}. Files: LiesLies.svelte (FIRE, Lies_report_result,
Lies_runner_verdict, Lies_run_result_recv all thread ok_pct/done), Auto.svelte
(storyFinished runner branch calls it on the Creduler Lies `H.o({A:'Lies'})[0].o({w:'Lies'})[0]`),
Langui.svelte badge shows P/N steps. **Catch:** green now means really-passed, so the
editor reads RED until the stale `toc.snap`s (Editron, Peregrination) are re-recorded —
snap re-record is now the thing that turns it green, not optional. Two-tab test is the
only validation (mine can't run it).

**Also fixed this session: Story_reset on a runner.** The `resetStory` elvis handler was
nested inside `if (Li)` in Auto.svelte, so a `?B=` runner (no Library) never consumed it —
the 🔄 button did nothing. Lifted `resetStory` out (activateBook stays Library-gated); bname
off the event, else active Library Book, else `H.c.book`. This is the ENABLER for the
Credence Book-remote-control below.

**`.ls-health` step badge — LANDED (the at-a-glance verdict).** `Liesui.svelte`'s bottom-right
health card is now the "this test passes" headline: step-level `{passed}/{total} {Book}` (e.g.
`2/5 Peregrination` when 3 of 5 steps !ok'd), GREEN only when every step passed, **open by default**
(`health_open = $state(true)`). Why "0/1 docks green" was the mystery: the old badge showed the
dock-level all-or-nothing `ok` (`ok===done`), so a partial pass collapsed to a red 0/1 — it was
hiding the step proportion the verdict already carried. Step view = `Math.round(ok_pct*done)/done`,
mirroring the tlog. The `book` field now rides the run_result wire: Auto `Lies_runner_verdict(liesW,
bname)` → `Lies_report_result({...,book})` → frame → `Lies_run_result_recv` stamps `book` on the
`%run_result`. Top `ls-cred` strip realigned to the same step counts (no more contradiction). This
badge IS the reusable Funkcion/matrix cell decoration (§5e "matrix IS a Waft"). Files: Liesui.svelte,
LiesLies.svelte, Auto.svelte. Still two-tab-only to validate.

**Credence cell — LANDED, as a partitioned Funkcion KIND (build-order (a)+(b)).** A `%Funkcion`'s mainkey
value is its KIND (`Funkcion:Storying,of_Book:PortPlan`). Architecture (owner's steer: keep Waft generic —
it "mounts the entire editable web", knows nothing of Stories):
- **`O/Funk/kinds.ts`** — registry `{Storying:{run,component}}`. Add a kind = one `O/Funk/<Kind>.svelte` +
  one line here. Ballistics (havoc pad, today hardwired in Waft.svelte) is the next migration into this shape.
- **`O/Funk/Storying.svelte`** — owns BOTH halves: `storying_run` (module-script export; the behaviour,
  finds %run_result by `book` for %of_Book / `path` for %of_dock, stamps off-snap `funk.c.verdict=
  {phase,pass,total,dige}`, NOT req.sc.ok) + the default component (the ✓/✗/◴ light, click→run).
- **`O/Funk/FunkHost.svelte`** — generic dispatcher: `FUNK_KINDS[kind].component`, bare fallback. Aliases
  legacy `%havoc` particles → the `Ballistics` kind (no re-author).
- **Monitor vs action taxonomy**: `FunkKind = {run?, component}`. `run` present = MONITOR (pumped every tick:
  Storying, dirlist); `run` absent = ACTION (struck on demand: Ballistics). `Lies_instantiate_funkcions` only
  registers a pumped run `if (kind?.run)`. **Ballistics MIGRATED** (`O/Funk/Ballistics.svelte`) — the havoc
  drum-pad UI/armed-glow/CSS moved out of Waft.svelte into the kind module; strike still fires `e_Lies_strike`
  (HAVOC_LIMBS stays in Lies). Waft now has ONE embed branch (`%Funkcion`||`%havoc` → `<FunkHost/>`), zero
  applet specifics. Canonical doc: Waft_spec §201 (updated with the taxonomy + instantiation-done).
- **`%havoc` FOLDED → `Funkcion:Ballistics,kind:<limb>`**: `%havoc` lived in exactly ONE test, **InterestLive**
  (one limb, `surprise_read` = fabricate a disk-diverged-under-edit on the active dock; authored at
  `wormhole/Story/InterestLive/Interestily/toc.snap`, no `arm` so struck not self-armed). Folded across all 12
  InterestLive snaps (authored Waft + 001-011 recorded — uniform in 3 forms: Waft copy, LE Demonstration
  clones, and the surprise_read snapshot JSON, so the encode-compare still matches → no re-record needed).
  `Lies_arm_engaged` self-arm scan now matches folded OR legacy (`Funkcion==='Ballistics' || sc.havoc`), limb
  kind = `sc.kind ?? sc.havoc`. FunkHost keeps the `%havoc`→Ballistics alias as back-compat (no live snap uses
  it now). Limb behaviour (HAVOC_LIMBS, dispatched by kind name) unchanged in Lies.svelte.
- **Waft.svelte** `%Funkcion` branch is now just `<FunkHost {H} {w} funk={C} {raw}/>` — all verdict/Story
  specifics removed from it.
- **`Lies_instantiate_funkcions`** (LiesStore) binds `funk.c.run=FUNK_KINDS[kind].run` (load + watch_c).
  **`Lies_register_funkcion` funk_id** keys on the funk's structural **`c.Dip`** (waftid slot stamped by
  `Waft_dip`, which runs right before instantiate on load AND UI-add — so reliably present), falling back to
  kind+binding for a non-Waft host (trail funk on a Seem). This is generic (no of_Book/of_dock leak into the
  register) and gives sibling cells distinct reqs. CAVEAT: the dirlist's GhostList Waft is also dipped, so its
  funk_id moved `GhostList/dirlist`→`GhostList/<dip>` — **InterestLive + Editron snaps record the old form (13
  files) → need a re-record** (didn't hand-edit: the Dip is a runtime value, unlike the havoc literal).
  `Lies_verdict_read` DELETED (→ storying_run).
- **Become-Book WIRED** (LiesLies): Book cell click → `e_Lies_become_book` → editor `Lies_send_become_book`
  ships a `become_book` frame; runner `Lies_become_book_recv`→`Lies_become_book_drive` stashes
  `awaiting_verdict{book}` + `resetStory{Book}`; the storyFinished→Lies_runner_verdict→run_result loop reports
  back Book-keyed (`Lies_run_result_recv` accepts no-path results as `Book:<name>`). Dock cell still →
  `Lies_run_arm{of_dock}`. **Re-activation landmine FIXED: `Auto.auto_reset_story` no longer `throw`s "forgot A"**
  — teardown now walks `A → w → run` (it had iterated `existing.o({w:1})` directly, found no w, threw on every
  Book-switch). Repeated Book-switching is safe; StoryTimes unblocked.
- `wormhole/Credence/toc.snap` = `Waft:Credence`, Book-bound + What-grouped: Peregrination | Lake* | Leaf* |
  Port{Plan,Planet,Plant} | Stuff{Flipping,Resolving} | LangTiles ([[story-books-catalog]]). Open via Liesui
  `+Waft → Credence`; fresh cell `◴ working` at once (single-tab), greens/reds when its Book's run_result lands.
  `run_when` DROPPED (cells are buttons; it was never read by code). **The pump is ours**: req:Funkcion live in
  a `%Funkcions` container (funks.c.up=w hand-stamped), driven by explicit `Lies_pump_funkcions`→`funks.do()`
  in req_Store Phase 2b — separated from w's main req tree.
- **`Funkcion:StoryTimes` — LANDED** (Editron §5f): the run-all station. `O/Funk/StoryTimes.svelte` +
  `Lies_storytimes_drive`/`_books`/`_scope_c`/`_dispatch`/`_width` + `Lies_runner_count` in LiesWaft, registered
  in kinds.ts. A MONITOR kind (not action): click only ARMS (`funk.c.sweep={phase:'arm'}`), the central Funkcions
  pump ticks `storytimes_run`→`Lies_storytimes_drive` which builds the queue from scope (containing What, or whole
  Waft for `%all`/root), dispatches become_book, advances on each book-keyed run_result (newer-than-dispatch; 60s
  timeout fails-and-advances so a stall can't wedge). State off-snap on `funk.c.sweep`. Credence toc now has a
  per-What station + a board-wide `Funkcion:StoryTimes,all:1`. **Multi-runner ("however many on the phone"):**
  `Lies_runner_count` reports connected runner Piers (`⌥N` on the cell); width = `Lies_storytimes_width`, capped
  `ADDRESSABLE=1` today (become_book is single-address — no per-runner `to`). FAN-OUT SEAM = lift ADDRESSABLE to
  runner_count once the frame carries a runner address (Editron §7). Two-tab-only to validate.
- **Vision (Editron §5f)**: Funkcions = public-sphere infra — embedded buttons in a shared doc that switch
  SERVER functionality on (people voting to activate a capability); "who may strike which Funkcion" → a
  permissions question as the channel hardens (trust/addressing). An action-that-acts-on-the-server = the franchise.
Pump = req_Store Phase 2b (`Lies_pump_funkcions`), every tick on w:Lies. Files: O/Funk/{kinds.ts,Storying.svelte,
FunkHost.svelte}, LiesStore/Lies/LiesEnd/LiesLies.svelte, ui/Waft.svelte, wormhole/Credence/toc.snap. Ref: Waft_spec §201.

**Still SPEC'D, not built.** spec/Editron.md (NOT forked — house rule): §5e "matrix IS a Waft — don't
build a grid widget" (a cell = a `%run_result` grouped by `(book,path)`, a `$derived`, coloured by this
same cell badge; one Funkcion per row IS the cell — no table). Remaining: per-row group-by into the
`book × dock` matrix; build-order (b) editor→runner "become Book" remote control (resetStory enabler
already landed) + localStorage persist; (c) start==end version guard; (d) run_phase progress relay.
§5d Funkcions go red|green; §5e Credence (the editor-side admirer); §6 nondeterminism guard.
- Funkcion model = Waft_spec §201 (embed `Waft/Funkcion:<name>` + central `req:Funkcion` host,
  LiesEnd Lies_register_funkcion/Lies_pump_funkcions). Triggering solved (ballistics drum-pad,
  [[ballistics-drum-pad]]). Bind needs `%of_dock` + a separate `%verdict` (NOT req.sc.ok);
  decoration via §201 reply-UI reusing Langui good/bad/working.
- **Credence** = editor's opposite of the Creduler: the board that READS the Credulations the
  Creduler spools write-only today. A plain Waft (NOT an Interest), above the doc under test;
  tests = Library Books (Port*) as Funkcions; click one/group on one shared version-set. The
  artifact is a MATRIX (rows=Books, cols=Docs, cell={relevant?,version,verdict}) — NOT a hoard
  of Story/This; snaps stay on the runner, pulled on demand. Relevancy observed (GhostInclude +
  rungo demands) + declared seed. Nondeterminism = a cell ✓&✗ at the SAME version-set; guard =
  capture version-set at start AND end (start≠end = HMR drift, discard; not nondeterminism).
- **Book becomes runtime/persisted/remotely-set** (retire `?B=`-only): editor→runner "become
  Book X" → runner `resetStory{Book:X}` (enabled by the fix above); persist current Book to
  localStorage (NOT OPFS — [[opfs-illegal-under-dev-boot]]); precedence persisted > `?B=` seed,
  so refresh resumes a remote-controlled shared runner tab.
- Build order: (a) Funkcion→Book/dock bind; (b) become-Book frame + localStorage persist;
  (c) start==end version guard → matrix; (d) optional run_phase progress relay.
Still open in Phase 1: wire `mode` across the channel; re-record stale snaps. See
[[creduler-runner-architecture]].
