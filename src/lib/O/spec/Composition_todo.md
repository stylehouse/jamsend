# Composition — what breaks when it all runs at once

*Opened 2026-08-06, from one evening of the human running the real thing and saying what was wrong.
 Restructured 2026-08-08, when the closed findings had grown past what a fresh reader could act on.*

This doc exists because the failures below have **no other home**. Each subsystem has a todo that
 owns its mechanism — `Backpressure_todo` the transfer control loop, `Radio_todo` the dial and the
  glass, `Cluster_spec` the relay and the boot, `Vyto_sizing_todo` the foam — and every one of those
   mechanisms was, on the evening this opened, *individually correct*. The app was still barely usable.

**The arc:** get from "each part is proven and the whole is unusable" to "the whole is proven".
 That needs a test level that does not exist yet (§3), a ledger of what actually goes wrong so we
  stop rediscovering it (§1), and a name for the mistake that keeps producing it (§2).

**How to read the numbers.** §3.5–§3.12 keep their numbers **permanently**, including where the
 finding has closed: §1's status column, §3.11's invariant table and `Supervisor_todo` all cite them,
  and a renumber would silently break every one. A closed section is compressed here to its durable
   lesson plus whatever part of it is still open; the full-length write-ups — every console paste,
    every measurement, every "NOT established" — are verbatim in
     **`spec/history/Composition_closed_2026-08.md`**.

---

## 0. Next move (read first)

### ⚠ STATE AT HANDOVER (2026-08-08, ~19:30) — read before starting

**0. RESOLVED SINCE THE EARLIER BLOCK:** the editor was identity-arrested for ~90 minutes (booted as
 `cdbe098c044e6806`, empty IndexedDB, no account snap on disk — key gone in both places). The human
  minted a new identity `3390b005fa79972b` and set up cluster trust; `ghost-compile` works again and
   the whole day's chain was recompiled through it. **Keep this in your pocket anyway:**
 - the tell is `no response in 12s (editor not connected or half-open?)` **while `runner_ask runners`
    answers normally** — the relay being fine is what makes it misleading;
 - the fallback is `scripts/LocalGen.spec.ts`, a BROWSERLESS `.g`→`.go` compiler using the real in-app
    translator and writing the real gen path:
      GFILES="Ghost/M/Ra.g" node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/LocalGen.spec.ts
    (`CHECK=1` in front = parse gate, writes nothing). It carried the whole evening.
 - **Caveat worth knowing:** `Ghostmeta_*` is `sha256(<the .g source>)[:16]`, so a matching hash proves
    the SOURCE is unchanged and says nothing about compiler agreement. `LocalGen` uses the same
     `Lang_compile_dock`; that is the basis for trusting it, not the hashes.

**1. `MusuNeGrind` RAN FOR THE FIRST TIME — and did its job on its first outing.** All 11 steps
 executed, `error: null` throughout, no fault. All three breakages §3.11 predicted (`Repli_offer`
  against a `%Mag:shuffle` root, `Repli_mirror_lib` under it, the injected nav's shape) worked first
   try. Steps 1–7 gave **byte-identical diges across two runs** despite a real clock — it is
    deterministic and therefore recordable. Every step reads `ok=0` only because the fixture still
     carries lie diges; `caveat=0`, `untried=0`. **That red is correct.**
 - **It caught a real bug in itself, via its own non-vacuity claim.** `w.c.ra_cull_floor_ms = 0` is a
    NO-OP: `Ra.g:782` reads `+(w.c.ra_cull_floor_ms || 30000)` and `0` is falsy, so setting the floor
     to zero *re-arms* the 30s throttle. Three scenes never ran, and claim #4 — the one §3.11 calls
      "the one worth having built this for" — was a **false green over a sweep that never threw**.
       Claim #5 caught it, which is exactly the job §3.11 assigns #5. Fixed in the Book (`= 1`), not
        in `Ra.g` — a Book must not edit what it tests.
 - **SECOND SIGHTING OF THE SAME FOOTGUN, and this is now a pattern worth hunting.** `SupplyGuards`
    found the identical shape hours earlier in `Repli_missed_hot`'s `ra_missed_hold_ms`. **`|| DEFAULT`
     is fine where 0 is meaningless (a count, a byte total) and a BUG wherever 0 is a legitimate
      setting** — it makes the dial unsettable and untestable. Worth a sweep of every `w.c.* || N`.
 - ~~**Still between it and being a gate:**~~ **CLOSED 2026-08-08 late — `MusuNeGrind` IS A GATE NOW,
    and every one of its six claims has been broken on purpose and watched go dark.** The witness fix
     for #2/#6, the fixture, the N runs and the mutation pass are all in; §3.11 carries the mutation
      table and the one hole it found. Headline: **claim #4 was theatre and only a mutation showed it** —
       it fired green over a sweep that never threw. It is a gate now, on different evidence.

**1b. `wormhole/Cluster/toc.snap` IS LOSING LIVE ROWS AND KEEPING DEAD ONES — a canonicity bug, not a
 missing reaper.** Row counts across today's commits oscillate 11→9→11→12→11→8, so entries *do* fall
  off. But the ones that vanished at 18:53 were `58517b`, `96d0cf88`, `a67a5d04`, `f5da6599` — **the
   live, active tabs** — while six dead editors (`0de425ee`, `c505e99b`, `9194a273`, `69659296`,
    `9b08d485`, `cdbe098c`) survived. That is backwards for a reaper and exactly right for
     **last-write-wins overwrite by a second editor with a divergent view**.
 - `Lies_runner_roster` is correctly gated `if (H.Lies_role(w) !== 'editor') return` — runners never
    write it, only beacon — and timings ride off-snap (`.c.last_heard`) so the 15s beacon does not
     churn the toc. That design is sound. **The gap is that nothing decides which editor is canonical.**
 - Live cost: `49dee91d61a9de64` carries `favourite_client:claude` and has not existed for hours, so
    subagents preferentially reach for a tab that is gone (one burned 8 minutes on it).
 - **Do not "fix" this with a reaper** — more writers churning the same file is the disease, not the
    cure. It is the human's own framing: *"a mature take on who can coordinate what data changes,
     what's canonical"*. Same family as `.jamsend/account`'s last-write-wins mirror (`Auto.svelte`
      ~:463 names it outright).
 - **The writer set is bigger than "a second editor" — read 2026-08-08 evening, from source.** Three
    gates that everyone assumes exist do not: `Lies_aim_setup` (`LiesFunk.svelte:408`) opens
     `Waft:Cluster` with **no role gate and no humdinger gate**, off every heartbeat via `Lies_aim` ←
      `Lies_heartbeat` (`LiesLies.svelte:1133`); `Lies_cluster_claim_self` (`LiesFunk.svelte:454`,
       called at `:924`) stamps `HostedIdentity:<prepub>,role:…` for **any** tab; and `watch_c` →
        `Lies_waft_save` (`Lies.svelte:808–810`, `LiesStore.svelte:336`) has **no role gate at all**
         — only `takes`/`tentative` and the `nowriting` Opt short-circuit it. So every runner, and
          every humdinger with a wormhole, rewrites the WHOLE toc on its own self-claim, from
           whatever it decoded at boot plus itself. Rows minted after its read are simply gone —
            which is exactly "live tabs vanish, dead editors survive", and needs no second editor.
 - **A humdinger is NOT absent from the registry, only from the grid.** `Lies_humdinger` gates the
    presence protocol alone — advertise (`LiesLies.svelte:1437`), going-cold (`:1541`), the `from` on
     pings (`:1311`, `:1346`) — which is why the editor never mints it a `%Runner` row. A
      `/BigSoundland` boots `boot_role:'runner'` (`BigQualand.svelte.ts:60`) and self-claims as
       `role:runner`. `f5da6599` and `96d0cf88` in the current toc are that, not editor-minted rows.
 - **Therefore the production shape and the canonicity fix are the same edit** (the human's framing:
    *"those peers are only going to be after each other, there is no editor"* — the Sounditrons
     externalise single-control-point state to the one editor). Gate `Lies_aim_setup`'s open on
      `role === 'editor'`: no read, no self-claim, no `watch_c`, no save, **one writer by
       construction**, and Cluster falls out of the published app for free. Nothing is lost — a
        runner's row is *supposed* to arrive by beacon (`Lies_advertise_recv` → `Lies_runner_roster`),
         so the self-claim is redundant for runners and is precisely what makes them writers;
          `LiesFunk.svelte:480` already says the Cluster copy of a grant is display-only and never
           read back. **Not a one-liner:** `LiesFunk.svelte:1867` and `:3391` read Cluster under
            unknown gating — check those two first.
 - **LANDED 2026-08-08 (fork D), source-verified, UNRUN.** `LiesFunk.svelte` only — `LiesLies.svelte`
    needed nothing (`Lies_advertise_recv` was already editor-gated). Two hunks: the gate itself
     (`Lies_aim_setup` returns unless `Lies_role(w) === 'editor'`), and **the latch had to move with
      it** — `Lies_aim`'s `if (!w.c.aim_setup)` now reads `if (role === 'editor' && !w.c.aim_setup)`.
       That second half is the part that isn't obvious and is the trap: `Lies_role` reads `H.c.role`
        or `w.sc.editor|runner`, either of which can still be **undefined on a booting tab's first
         heartbeat**, so a gate inside `Lies_aim_setup` alone would let the once-latch fire on the
          undefined tick and leave a **real editor with no Cluster for the life of the tab** — a
           worse bug than the one being fixed. Cost of the fix: two property reads per heartbeat on
            non-editors, and the latch now also re-arms correctly if a tab ever becomes an editor.
 - **The two flagged reads were already safe** — `:1867` and `:3391` both sit *inside*
    `if (H.Lies_is_editor(w))` branches, so an editor-only Cluster doesn't starve them. The rest of
     the reader set checked out too: `Lies_dispatch_target` self-gates on role, `Lies_rungo_target`
      already falls back to the live `%Runner` roster when there is no Cluster, and
       `Lies_favoured_runner` has **no in-app caller at all** (only `Machinery.svelte:683` and
        `scripts/SendTo.spec.ts`, both of which mint their own Cluster).
 - **Fixtures are safe, and this was worth checking rather than assuming.** Of 164 `w:Lies` rows
    across `wormhole/Story/`, exactly **one** is `w:Lies,editor` — `Story/Editron`, and it is the only
     fixture carrying real Cluster machinery (`Good …waft_path:Cluster`, `req:Waftica,waft:Cluster`,
      `Waft:Cluster`). It keeps all of it. `Story/Engage`'s `Waft:Cluster,equip:Engage` is minted by
       `Machinery.svelte:680`, not by `Lies_aim_setup`. No other fixture mentions Cluster in any form,
        so no Book's dige moves.
 - **One deliberate behaviour change on runners, and it is inert:** a runner's `Lens:Brink,Relay` now
    has no `funk` cell, because `Funkcion:Relay` lived in the Cluster it no longer opens. Nothing
     reads it — `Relay.svelte` takes `funk` as an optional prop and never touches `funk.c.latest`
      (that caption was removed; see its own `:63`). The pumped `relay_run` watcher simply stops
       running on runners. The face still paints from `lens.c.w`.
 - **HALF-MEASURED NOW (2026-08-08 late, by fork A, who held the only runner).** D could not run this;
    A could, and did — one **full runner reload** of `a67a5d04`, which is precisely the event that used
     to make a runner rewrite the whole toc from its stale boot view, and which also guarantees the tab
      is running the new code rather than an HMR patch of it. Result: `wormhole/Cluster/toc.snap`
       **byte-identical across the reload** (`fb767323852203e6f6d2636f2ddd16b2`, mtime still 19:26:30 —
        i.e. the last write predates the gate), and the runner came back and ran `MusuNeGrind` green
         11/11 first try. **A runner is no longer a writer. That half is measured.**
 - **The OTHER half is not, and the two failure modes look identical — say so out loud.** Nothing has
    observed the editor *writing* since the gate. A frozen toc is what a correct fix looks like when no
     row changed, AND what an over-gated one looks like if `Lies_role` never reads `'editor'` on the
      editor (registry frozen for good). **Do not read "the toc stopped churning" as proof it works.**
       The discriminator needs a genuine roster delta, which needs a **new** identity — a re-beacon from
        a known runner correctly writes nothing, because timings ride off-snap on `.c.last_heard` by
         design. So: **open any new tab as a runner and confirm the toc GAINS its row and loses none.**
          That is a 30-second check for whoever has a browser, and it is the last thing owed on D.
     - Trap that cost A a wrong inference, worth one line: **`runner_ask runners` reads
        `wormhole/Cluster/toc.snap` off disk** (`clusterRunners()`), not the editor's live world. Its
         output right now is just the 19:26 snapshot, so it cannot testify about the editor either way.
 - **Verification status before that: type-check only.** One new svelte-check line, `LiesFunk.svelte:432` —
    `Property 'Lies_role' does not exist on type 'House'` — which is the documented baseline class and
     is byte-identical to the pre-existing one at `:463` (`Lies_cluster_claim_self` makes the same call
      the same way). Nothing else in the file moved. **What has NOT happened: no tab has run this.**
       The proof it works is a behavioural one nobody has taken — boot a runner and an editor, confirm
        the runner's snap has no `Waft:Cluster` and its row still reaches the editor's registry by
         beacon, then watch `wormhole/Cluster/toc.snap` across a few tab lifetimes and see live rows
          stop disappearing. Until then this is source-verified, not measured.
 - ⚠ **This edit HMRs.** `LiesFunk.svelte` is `.svelte`, so saving it pushes into every live tab
    including fork A's runner — and a `.svelte` HMR is the one that wedges a Story drive without
     announcing it (the drive never re-schedules). If a `MusuNeGrind` run straddled this save, **reload
      the runner before believing its verdict**. This is fork D's cross-fork cost and §0b's "unlimited
       tier" undersells it: D was sized as read-only-plus-unit-test, but D's whole job was an edit to a
        `.svelte` file, which is not free the way a `scripts/*.spec.ts` is.

**2. There is now a runner-free test layer, and it earned its keep on the first run.**
 `scripts/SupplyGuards.spec.ts` — mount a `.go` against a **stub House** (a `.go` is a Svelte component
  whose `onMount` eatfuncs its verbs onto H) and call the predicates directly. No runner, no browser,
   no peer, ~7s. It caught a real bug immediately: `+(w.c.x || 60000)` silently ignores a configured
    **0** (falsy), so the dial could not be turned off or tested without sleeping a minute. **The
     `|| DEFAULT` idiom is everywhere in this repo — it is fine where 0 is meaningless and a bug where
      0 is a legitimate setting.** Extend this file in preference to writing a Book, wherever the thing
       under test is arithmetic rather than composition.

**3. What is compiled but has NO Book coverage** (the Book gate ran *before* these landed): the `lofi`
 recipe fix across four seams (`Heist_keep_remember` / `Heist_reheal_id` / the durable `%Keepsake` row /
  `Ra.g`'s A3 call), the durable `keep_memo` itself, `Ra_pcm_admit`'s lone-candidate floor, and the
   Vyto changes. **"Book-inert" means no regression, not covered.** Do not read the earlier green as
    covering these.

**4. Runners:** `a67a5d04` is ALIVE and is the one the human has authorised — use it. `49dee91d` is a
 **dead registry row** (see 1b) that advertises itself as claude's favourite; do not chase it.
  `65ae23ea` answers but is the human's Daemon-observation tab — a Book run takes the world over, so
   ask first. `f5da6599` / `96d0cf88` are their live music tabs: **never**.

**4b. THE `×2` ON EVERY `ws RECV` IS SOLVED — and it was never cosmetic.** A tab opens two relay
 sockets (`?addr=<prepub>` from `Swarm_station_up`, `?addr=runner` from `LiesLies`) and **both send a
  signed hello carrying the SAME active `%Identity` key**, so `handleHello` binds that prepub to two
   different sockets. `locals` is a `Map<string, Set<WebSocket>>` and `bind` **appends**, so
    `deliverLocal` fans every prepub-addressed frame to both. Refuted on the way, don't re-chase: a
     socket entering by several doors lands in the Set once — a JS Set dedupes by identity.
 - The phantom copy lands in `w:Lies`, where `Peeroleum_route`'s `peerings.length === 1` fallback
    matches it **by luck**, books a `%req:unemit` nothing there can handle, draws no ack, and
     `faulty_owed` drives a **per-frame O(inbox) `%faulty` rebuild** on an inbox growing to 2000.
 - **Proof already in the human's logs:** `inbox backstop: pier editor holds 2050 unemits — dropped
    oldest type=repli_lines`. There is no legitimate path for a MUSIC frame onto the Lies channel.
 - Confirm in 30s: count `🪪 hello bound <prepub>` per tab boot **in the dev-server terminal**.
 - The fix is authentication-vs-delivery in `relay.ts` — a hello must authenticate a socket without
    adding it to that prepub's fan-out. ⚠ **`relay.ts` is another session's active file.** Hand it over.
 - Bonus: the relay already prints `⚠ DROPPED bridge→ … that side's inbound is DEAD` when a tab goes
    deaf with its socket up. **That is a ready-made tier-two supervisor signal nobody reads** — better
     than the per-peer `seq` tracking `Supervisor_todo` §4 sketches, because it needs no new bookkeeping.

**5. Owed to the human, none of it blocking:** what they wanted true about Vyto that isn't (the
 do-over cannot start without it); whether the 32s seam *sounds* right (proven to run, not to sound);
  and the container's memory limit, so `ra_pcm_cap` can be sized under it instead of left at a default
   that could OOM the tab — the belt is now load-bearing in a way it was not this morning.

**6. THE FOUR FORKS, WRANGLED (2026-08-08 ~20:20, by A — read this before the diff).** All four landed;
 they are **not** equally proven, and the differences are the whole point of this block. Nothing is
  staged; it is one working tree for the human to review.

| fork | landed | proven by | still owed |
|---|---|---|---|
| **A** `MusuNeGrind` | `Heistation.g` + `.go` + fixture | **green ×5 + all six claims broken on purpose**; one was theatre until that pass | the disclaim `%see` (needs the scene routed through `Ra_restock_beat`) |
| **B** the two sweeps | `SupplyGuards.spec.ts` | **15/15, 6s** — dial sweep *and* the frontier-name sweep, the latter a documented NEGATIVE result | nothing |
| **C** the uncovered landings | `KeepMemoDurable.spec.ts` (**untracked — `git add` it or it is not in the commit**) | **8/8, 6s** — lofi across the seams, `keep_memo` durability, rehydrate, A3 rendition | `Ra_pcm_admit`'s floor went into **B's** file, not C's; covered once, not where §0c said |
| **D** Cluster canonicity | `LiesFunk.svelte` | **half-measured** — a runner is provably no longer a writer; the editor has not been seen to write at all | one new runner tab, 30 seconds — see §0.1b |

**Two cross-fork facts that only exist at the seam, which is exactly where nobody was looking:**
- **A's runs straddled D's HMR save.** D's `LiesFunk.svelte` landed 19:51; A's first eight runs were
   20:06+, and D's own warning says a `.svelte` HMR can wedge a Story drive without announcing it —
    *"reload the runner before believing its verdict"*. A did reload and re-ran: **green 11/11 first
     try on the fresh tab**, so every verdict above stands. Had that not been checked, A's whole
      mutation table would have been reasoning about a possibly-wedged drive.
- **The dead rows outlived the fix, and they still misroute people.** D stops the toc *churning*; it
   removes nothing. `wormhole/Cluster/toc.snap` still carries six dead editors and
    `49dee91d61a9de64,favourite_client:claude` — a runner that has not existed for hours and that
     `runner_ask runners` prints **first, with a ★**. The next subagent to trust that list burns
      minutes on a corpse (one already did). §0.1b rules out a reaper on purpose, so this is a
       **disposal-policy question for the human**, not a bug for the next session to improvise on.

---

### 0b. Working in parallel — read this BEFORE launching a second session

**Parallelism is free up to the compile, and serialises hard after it.** This is the single fact that
 decides how many sessions can usefully run at once, and it is not visible from any one file.

- **Unlimited:** read-only source work, and `scripts/SupplyGuards.spec.ts`-style unit tests. A `.go` is
   a Svelte component that eatfuncs its verbs onto a House — **mount it against a stub House and the
    real compiled verbs are callable directly.** No runner, no browser, ~7s. That is where eight
     threads actually fit, and it is why §0.2's advice ("extend that file in preference to writing a
      Book, wherever the thing under test is arithmetic rather than composition") is a throughput
       argument as much as a coverage one.
- **Effectively ONE at a time:** anything that compiles or runs a Book. A `.g` compile **HMRs into
   every live tab, runners included**, so two sessions compiling while a third runs a Book will
    corrupt that run. There is one reliably usable runner (`a67a5d04`); `49dee91d` is a dead registry
     row that advertises itself as claude's favourite and will eat eight minutes (§0.1b).

**Traps that cost real time on 2026-08-08, none of them inferable from the code:**
- **A runner answering `ping` is not the same as its Story drive being wired.** A run fired the instant
   ping returned came back as an accepted Book with **no Story world at all**. Give it ~30s after a
    reload. (Distinct from the cold-runner false-red — that one runs and reds; this one has nothing to
     run.)
- **`npm run ghost-compile` dying with `no response in 12s` while `runner_ask runners` answers fine
   means the EDITOR is identity-arrested, not that the relay is down** — the relay being healthy is
    what makes it misleading. Fallback: `scripts/LocalGen.spec.ts` (§0.0), browserless, real translator.
- **`Ghostmeta_*` is `sha256(<the .g source>)`**, so matching hashes prove the SOURCE is unchanged and
   say **nothing** about compiler agreement. Trust `LocalGen` because it uses the same
    `Lang_compile_dock`, not because the hashes line up.
- **`+(w.c.X || N)` swallows a configured `0`.** Swept across 14 time dials on 2026-08-08; check any
   new one. See §0.1 and §0.2 — two independent sightings in one day made this a pattern, not a bug.

**Territory as of the 2026-08-08 handover:** `relay.ts` / `relay-test.ts` belong to the security
 session — **do not touch, hand over rather than edit** (§0.4b's fix lives there). The handing-over
  session held `Ra.g`, `Radio.g`, `Swarm.g`, `Repli.g`, `Heist.g`, `Heistation.g`, `Vytui.svelte`,
   `Matstyle.svelte`, `scripts/` — **all at a clean stopping point, all compiled, nothing staged.**

### 0c. Four forks, with disjoint file ownership

Sized to 0b: one session holds the runner, the rest stay in the unlimited tier. Two sessions in one
 file is worse than one session doing both jobs — the interaction belongs to neither.

| fork | job | owns | where |
|---|---|---|---|
| **A** | ~~`MusuNeGrind` → a gate~~ **DONE** — witness reads, #4's vacuity killed (twice — the second hole was only visible by mutation), all six claims broken on purpose, fixture re-recorded, 6 green runs | the Book `.g` + its fixture + **runner `a67a5d04`, exclusively** | §3.11 mutation table |
| **B** | ~~the two sweeps~~ — **BOTH DONE 2026-08-08, 15/15 green in 6s.** Frontier sweep is a clean negative (§2). Dial sweep found the earlier pass was scoped to **time** dials only: 18 count/byte reads across 5 ghosts still cannot be zeroed, ledgered executably | `scripts/SupplyGuards.spec.ts` | §2's standing rule, §0.2 |
| **C** | ~~coverage for the landings no Book touches~~ — **LANDED 2026-08-08, 8 tests green** in `scripts/KeepMemoDurable.spec.ts`. Scoped to the seams B did NOT: the **durable `%Keepsake` mirror** (remember→flush→rehydrate across a restart, half-row refusal, session-precedence, cap-on-the-way-in, guarded stamps) and **Ra's A3 contract** (`Heist_materialise_one`'s `(!!lofi)` mode-aware early-out). SupplyGuards already covers the runtime `keep_memo` + `Ra_pcm_admit`'s floor, so those were NOT duplicated. | `scripts/KeepMemoDurable.spec.ts` (a **new** file, not B's) | §0.3 |
| **D** | ~~Cluster canonicity + the production shape, one edit~~ — **LANDED; half-measured 2026-08-08 late by A on the shared runner.** A runner is provably no longer a writer (a full reload left the toc byte-identical); the editor has not been seen to write at all, and a frozen toc looks the same either way. One new runner tab settles it — §0.6, §0.1b | `LiesFunk.svelte` (`LiesLies.svelte` needed nothing) | §0.1b |

**A is the only fork that may compile or run a Book.** B, C and D are read-only-plus-unit-test and may
 run concurrently with each other and with A. If B/C/D need a compile, they queue behind A — say so in
  the doc rather than compiling under it.

**Not forkable, and why:** §0.4b (`relay.ts` is the security session's), and §4.1/§4.2 — both need live
 tabs and would fight A for the runner.

---

### What landed 2026-08-08, so nobody re-finds it

| what | where | § |
|---|---|---|
| the shuffle cull **flies detached** — it had been holding the share beat for up to **29671ms** | `Swarm_cull_detached`/`Swarm_cull_done`, `Swarm.g` `fc39dd10f0a0d3c1` | §3.7 |
| **`Stoker_tour` flies detached too**, same contract (`tour_flying`, reported as `tour_bg`) | `Swarm_tour_detached`/`Swarm_tour_done`, `Swarm.g` | §3.7 |
| the **goner-diff runs live at last** — tour whittle *and* cull both ledger to `stock.c.retire_due`, flushed each beat | `Repli_retire_flush` (`Repli.g`), call in `Swarm.g` | §3.9 (1) |
| a **bounded backoff on told misses** — `ra_missed` finally has a reader on the music path | `Repli_missed_hot`, wired at `Ra_mag_warm` + `Ra_restock_beat` | §3.9 (2) |
| the **serve path reheals from disk** — a want for an un-standing id resurrects its radiostock card (own-pub, then cross-pub) and serves the same want | `Ra_reheal_id` + `Ra_stock_open` (`Ra.g`), hook in `Repli_serve_want` (`Repli.g`) | §3.13 |
| **PCM admission control** — the belt on its own livelocked every track at 0:32 | census gate in `Ra_transcode_pump`, plus `Ra_pcm_admit` at the decode kick (`Ra.g`) | §3.12 |
| **the restock gate** — deep speculative restock is held while the playhead has <16s banked | `w.c.lead_s` / `w.c.restock_held`, printed in the skip line (`Swarm.g`) | §3.12 |
| **tier-one supervisor** — notice-only; watches the beat phase *and* the two detach latches | `Swarm_watch_loop` / `Swarm_beat_health` / `Swarm_detached_health`, `Swarm.g` | `Supervisor_todo` |

**The method that produced most of that list, and it is the transferable part.** The four-way
 `beat_split` instrument cost four `Date.now()` calls and settled in one console paste a question that
  had been argued from source-reading for two days — killing §3.6's plausible story and naming §3.7's
   real one. Keep the method, not the guesses.

- **READ THE SPLIT AS A PROGRESS BAR, NOT A COST TABLE.** `beat_split` is zeroed at the top of each
   beat and each field stamped only on completion, so **the last non-zero field is how far the stuck
    beat got**, and an all-zero line with a climbing `×N` means it never finished phase 1. Misreading
     this cost hours; the log line now says it in words. This is the single most load-bearing sentence
      in this document.
- Healthy now looks like: `cull=0 tour=0 flush=0 peers=<n>` with work in `pump`/`warm`, the detached
   pair reporting `cull_bg=<big>` / `tour_bg=<big>`, and `×N` no longer climbing.
- **The detaches traded a visible stall for an invisible one**: a detached verb that never settles
   leaves `flying` set forever and the beat sails past looking healthy. `Swarm_detached_health` is now
    the thing that watches that latch (`Supervisor_todo` owns it). **Whether it has ever been seen to
     fire is that doc's business, not this one's** — do not read its existence as a verification.

### The order to work in

0. **One live pair, one reading — confirm the day's fixes on real tabs.** Everything above was
    reasoned or measured *in pieces*; nothing has watched the whole chain run since. What to look for,
     in one paste: the split walking past `cull=`/`tour=` into `pump=`/`warm=`; `×N` not climbing;
      no `park-stall` line re-reporting the same id; and the human's own test — *"neither Sounditron
       takes the other's stream"* — coming out the other way. A wedged tour is a tab that never offers
        and never transcodes while its relay looks perfectly healthy, which is exactly as it was
         reported.
1. ~~**Build `MusuNeGrind`**~~ **DONE 2026-08-08 late — it is a gate.** Green 11/11 across six runs, the
    fixture recorded, and all six claims broken on purpose and watched go dark (§3.11's mutation table).
     One of them, #4, was theatre until that pass found it. **What it gates is the janitor/wire seam and
      only that** — rung 2 (payload) and audio are still uncovered, so do not let a green here stand in
       for them. The live next move on this item is the owed disclaim `%see`, which needs the scene
        routed through `Ra_restock_beat` first; §3.11's "still owed" list has it.
2. **Then the startup wait** (§4.1) — it taxes every iteration, including the ones spent fixing the
    rest of this list. Measure before touching: the era ladder is only ~15s worst case, so it is not
     the whole story and guessing at it has already cost one wrong diagnosis.
3. **Then one-sided reload** (§4.2). Until it works, every test of everything else costs two
    coordinated reloads, which is the tax that makes the whole loop grim.
4. Then §4.3–§4.8 as the Grind Book surfaces them with evidence attached, rather than in the dark.

**Where this is all going — the arc as of 2026-08-08.** The day was one shape, over and over: *a verb
 that nobody was watching held a live path hostage, and the only detector was a human reading a
  console.* The cull, then the tour, then the Story drive, then the PCM belt. Each fix was small;
   finding each one cost a person. So the destination has two halves and they are not the same work:
 (a) **`MusuNeGrind`** (item 1) — catch this class **before** it ships, in a Book, automatically.
 (b) **`Supervisor_todo`** (opened at the human's ask: *"there has to be a supervisor built still, to
  discern all these moments when we should give up and reload"*) — catch it **after** it ships, at
   runtime, in the tab, and say WHICH ORGAN.
 Both are the same bet from opposite ends: **make liveness legible.** Until then every stall costs a
  console paste, and that tax is what makes the whole loop grim.

**Do not** treat §1's fixed rows as closed history — read §2 first. The pattern is the deliverable.

---

## 1. The ledger — every complaint of 2026-08-06, verbatim, with status

Kept verbatim on purpose: the human's own words repeatedly turned out to name the cause precisely
 ("disappeared from the uploaded side" *is* `Heist_release_rec`), and paraphrasing loses that.

| # | What the human said | What it was | Status |
|---|---|---|---|
| 1 | *"it still says we have a half-sealed link to Lefto… they BOTH say 'we never granted back'"* | `Diag_trouble` read `self.sc.pub`; an %Identity keeps its pub on `.c.keys` and only `prepub` in sc. `mine` was always `''`, so every whole %Pier reported half-sealed, forever, on both ends | **FIXED** |
| 2 | *"downloads overlap a bit much now"* | two causes: the overlap slot opened for a track *stuck* near the end rather than *finishing*; and `heist_inflight` was enforced **per %Haul**, so N Hauls gave N concurrent tracks whatever the knob said | **FIXED** (`INFLIGHT=1`, global budget, moving-gate) |
| 3 | *"120/137 downloaded side, disappeared from the uploaded side, but hasn't started turning up on disk yet! not even as a chrswap"* | the source freed bytes it had promised. `rec.c.sent >= total` is a frontier not coverage; `PARK_CEIL` and `RELEASE_IDLE` were both 20000, so the quiet a park *instructs* read as the disinterest a release *requires* | **FIXED** (`Backpressure_todo` §3.1c) |
| 4 | `◈ pull Cosmic Hweeldi 142/196 … 141 … 138 … 135 … 132` → `BENCHED 60s — frozen` | **`held` going DOWN.** `Heist_land` releases each chunk as it reaches disk; §5.4 moved the landing off the beat and never told the puller. So the sink re-asked, re-downloaded and re-hashed a file it was at that moment writing — and the bench watchdog, which wants `held` to climb, benched it for succeeding | **FIXED** — the largest single win of the evening |
| 5 | *"I can't get past that 100% cpu usage, that is shit, and probably causing all these other problems"* | correct on both counts. One real find: `o_query`'s second-and-later key filter was **O(M²)** — `M = M.filter(…)` per rejected row — in the innermost query primitive, hit per frame by `inbox.oai({req:'unemit', seq, …})` | **PARTLY** — see §4.3, and §3.12 found a second, larger consumer |
| 6 | *"likes pausing in Peeroleum_deliver / Peeroleum_book_unemit"* | a stack sample says *where*, never *how much* or *why*, and the two candidate whys want opposite fixes | **INSTRUMENTED** — `deliver` electrode, silent unless ≥10% of wall clock or a ≥50ms block |
| 7 | *"73 dropout(s) spliced — real gaps you would have heard"* | `Diag_trouble` reading `radio.sc.drops`: audible gaps the concealer spliced over. A **symptom readout**, not a cause — the audio callback missed its deadline because the thread was pinned | downstream of §4.3 |
| 8 | *"targeted e:reqyonciliation landed nowhere — target reminted\|dropped"* | `Housing.svelte.ts:1339`. An `elvisto` aimed at a %req *by reference*, delivered at Atime; the target had been dropped by then. Returns cleanly, so a warn not a fault — but it means reqs are being dropped out from under in-flight continuations, which is what a churning heist does (`w.drop(landReq)`, the awaitbuf orphan sweep, the BUFCAP sweep) | **OPEN** (§4.5) |
| 9 | `ws CLOSE code=1006` reconnect storm, *"but less than before"* | downstream of #4 and §3.1b — a pinned thread misses the relay's 15s reaper | improving; re-measure after #4 |
| 10 | `⏳ Swarm_share_beat still running past 600ms — skipping this tick (×221 so far)` | the beat permanently overrunning while the wire moved only ~60KB/s of actual music | **PARTLY** (§4.4) — §3.7 removed the two janitors that dominated it; the remainder is unmeasured, and it stays the Grind Book's load-bearing assertion |
| 11 | duplicate `ws RECV ive_got seq=321` ×4, `seq=323` ×4, ~4 fresh seqs/sec out | **NOT sender retransmits** — `ive_got` has been ephemeral on send since an earlier pass. Mis-diagnosed once; see §4.6 for the two live leads, and §3.12's unresolved `×2` for a possible shared cause | **OPEN** |
| 12 | `▣⚠ Vyto watchdog: forced settle after 240 frames of unbroken motion` (repeatedly) | a cell never stops moving, so the glass never settles and renders continuously | **OPEN** (§4.7) — cause found in §3.5, fix not shipped; a standing CPU consumer independent of the wire |
| 13 | `🗂⚠ wormhole write … toc.snap overran 5000ms — retrying (attempt 2/4)` | disk write starved behind everything else | **OPEN** |
| 14 | *"the startup time it takes to get around to trying the Heist again… way too slow! what the fuck are we waiting on?"* | unknown. The era-confirm ladder is ~15s worst case, so it is not the whole story | **OPEN** (§4.1) |
| 15 | *"we're still not having just the runner reloading working at all — the two Pier have to hit reload at the same time and arrive with fresh states for each other"* | a reborn peer restarts its per-Pier seq at 1; the survivor's inbox still holds finished %unemit rows at those seqs, so its frames are re-acked and never dispatched until the era handshake resets the route | **OPEN** (§4.2) — known as `Cluster_spec` heading 8 |
| 16 | *"☠ the radio is starved… I just feel that I do not care, it should just work out somehow"* | right instinct. A starve should dial what it *has*, not raise a badge | **OPEN** (§4.8) |
| 17 | *"all these Musu\* tests really didn't prepare us too well for the clusterfuck of them all together"* | structurally correct, and the reason this doc exists | **→ §3** |
| 18 | *"so it's pretty shit code I guess?"* / *"it has quite a few things to robusticise"* | see §2 — it is one repeated mistake, not diffuse quality | **→ §2** |
| 19 | `deliver threw ReferenceError: pub is not defined at Peeroleum_bound_inbox` + *"good software is incapable of producing this kind of autistic bollocks"* | **`${pier%pub}` inside a template literal.** The `.g` compiler leaves `%` alone in a backtick string, so it emitted the JS `pier % pub` — modulo against an undeclared name — and threw. In a **log line**, on the branch that runs **only at the 2000-unemit cap** | **FIXED** — and see §2.1, it is the sharpest case in the doc |
| 20 | `◈⚠ transcode STALLED — parked want id=… from_idx=16 waiting 1438s` ×3, climbing | 24 minutes parked, three ids, all at `from_idx=16` | **FIXED** — this was §3.12's PCM livelock, not the deliver throw (#19) it was first filed downstream of. This row already called the identical `from_idx` across unrelated tracks "its own smell" and guessed §3.1e-shaped; it took two more days and a fuller log to act on it. Attribution rests on the post-fix live reading in `Backpressure_todo` §3.1e (decode-starts to zero, serves 1→16, the stalled album landing) |
| 21 | *"failing to heist… really big dysfunctional gaps between doing anything about it… got to 3/8 without me seeing it do any"* (2026-08-08) | the PCM cap-thrash livelock: 8 parked wants stood up ~700MB of decode against the 384MB belt, the sweep shed open encodes, the pump re-kicked them (a SUCCESSFUL decode clears the backoff ladder, so nothing braked it) — 28 decode-starts of 8 records vs 2 heist serves in 136s. The sink's tell was `heist-noprogress` 60–100s/track then a 1–8s burst: the wire was never the problem | **FIXED** — `Backpressure_todo` §3.1e, admission gate in `Ra_transcode_pump`; §3.12 here |

*Also open, found while reading rather than reported:* `MusuMag` is red at 0.7 with four unfired
 `%see` claims (mag/warm-start/park pipeline). **Pre-existing** — proved by controlled revert, identical
  red with and without the evening's changes — and undiagnosed.

---

## 2. The pattern: a cheap local read standing in for the expensive true one

Every defect in §1 that was actually *fixed* is the same mistake:

| the cheap read | the true question | cost |
|---|---|---|
| `map[off] == null` | is any chunk of this page missing? | permanent invisible holes (`Backpressure_todo` §3.1b) |
| `rec.c.sent >= total` | has every page actually crossed? | source freed promised bytes (§3.1c) |
| `now - want_ts > 20s` | does the sink still want this? | a park's own enforced quiet read as disinterest |
| within 24 of done | is this track *finishing*? | a wedged track propped the window open forever |
| `rheld > bench_held` | is this track frozen? | a landing benched for succeeding |
| `self.sc.pub` | what is my pubkey? | both ends accusing each other, forever |
| a 30s throttle on a janitor | how long does it HOLD the beat? | 29.7s of a 600ms beat (§3.7) |
| an eviction belt under a cap | may this work be STARTED? | every track dead at 0:32 (§3.12) |

Each is individually reasonable, cheap, and correct *at the time it was written*. Each became wrong
 when something else changed underneath it — the relay learned to shed, the landing left the beat.
  **That is not a quality problem, it is a coupling problem**, and it is why the answer is §3 rather
   than a code-review pass.

**The standing rule:** a high-water cursor may not answer a question about coverage; a timer may not
 answer a question about consent; and an eviction bound may not answer a question about admission.
  The first two are greppable — a frontier name (`sent`, `have`, `held`, `frontier`, `last_asked`) on
   the left of a comparison against a total or a threshold.

**That sweep has now been done (2026-08-08, fork B) and the transfer spine is CLEAN.** A negative
 result, and it needs a guard more than a positive one would, because nothing else will notice it
  break. What was checked:
- `held` is a genuine **count** at every site (`if (map[s] != null) held = held + 1` — `Ra.g:897`,
   `1084`, `1122`, `2502`, `2600`), so `held >= total` is a coverage question answered by a coverage
    read. The `held` at `Ra.g:1914`/`1970` is a byte sum, also honest.
- `Repli_page_ready`'s map branch **walks the page** (`while (s < end) if (!Repli_chunk_at) return
   false`) — §3.1b's fix, correctly generalised.
- `Radio_start_seq`'s `have` **is** a frontier, and it answers a **frontier** question ("where may the
   pump start without crossing a hole"). A frontier answering a frontier is the rule satisfied, not
    violated — the counter-example that stops this becoming "never use a cursor", which would be wrong.
- The one cheap read left is `Repli_page_ready`'s **other** branch (`Repli.g:510-516`), which answers
   with `chunks.length` and inspects no element. It is correct **only because**
    `Crate_transcode_release` grows the array by contiguous `push`, so it cannot have holes — an
     unstated, load-bearing, one-line-away-from-false invariant. `SupplyGuards.spec.ts` now guards the
      **producer's density** rather than the consumer's read; the day someone lands an out-of-order
       arrival as `chunks[i] = buf`, that goes red and points at the reader trusting it.
- A second precondition fell out of the test failing on its first run: the same branch computes
   `complete = chunks.length >= +(rec.sc.nchunks || 0)`, so a record with **no promise** is vacuously
    complete and every page reports ready. Unreachable today only because `Crate_transcode_begin`
     stamps `nchunks` (`:824`) *before* it creates the array (`:826`). The safety is an **ordering in
      another ghost**, not anything the reader checks. Pinned.

Twice the surrounding comment confidently asserted the true property ("every page has crossed at
 least once") while the code computed the cheap one. **The comment is not evidence.**

### 2.1 The safety net nothing ever tests

§1 #19 deserves its own heading because it is the cleanest specimen in the doc, and because the
 human's objection to it — *"good software is incapable of producing this kind of autistic bollocks"*
  — is **correct, and the reason is structural rather than a matter of care.**

The `%` sugar had never been wrong anywhere else; a repo-wide grep found this was the only use inside
 a template literal, so the compiler gap and the one site that hit it coincided exactly once. But the
  compounding is the real lesson:

1. It sat in a **log line** — the least load-bearing code in the file.
2. On a branch that runs **only at the 2000-unemit cap** — i.e. only once the inbox is already
    melting. **No Book can reach it**, and no healthy session ever will.
3. That branch is the **structural backstop**: the thing whose entire job is to keep the pump alive
    through a flood.
4. So it threw on every visit once the flood arrived, and the one thing it exists to do — **trim** —
    was the one thing that stopped happening.

**The backstop did not merely fail to save the wire — it was disabled precisely by the emergency it
 exists for.** A safety net that runs only in the emergency is a net nothing tests, and an untested
  net is a trapdoor.

> **Correction (2026-08-06, from the 20-analyst review).** The first version of this section said the
>  throw meant *"the frame was lost"*. **That is wrong.** Both call sites (`Peeroleum.g:739`, `:768`)
>   invoke the bound **after** `await inbox.do()` and `Peeroleum_rollup_faulty`, so the frame was
>    already booked, dispatched and acked. What the throw actually cost was the trimming, the trailing
>     `feebly_ponder()` wake, and a rejected deliver promise. The consequence is still severe — untrimmed
>      is how the inbox reached 3400 unemits, and every per-frame inbox query is O(depth) — but it is a
>       **slow strangle, not frame loss**, and the distinction changes where you look next.
>  Worth recording why this matters more than the fact: **that claim was a comment asserting a property
>   the code did not support** — the exact failure §2 ends by warning about, *"the comment is not
>    evidence"* — written by the same hand, the same day, one file from the rule. The rule does not
>     exempt the person writing it, and prose is where this codebase is most confident and least checked.

Two rules out of it, both cheap and both now applied at the site:

- **Emergency paths need a test more than ordinary ones, not less.** Anything gated on a cap, a
   watchdog, a retry ceiling or a "this should never happen" is by construction unexercised. Either a
    Book drives it, or it must be assumed broken.
- **Housekeeping may not kill the work it houses.** Trimming is bookkeeping — the bound's own header
   already said *"allowed to run LATE, just never never"* — so it now runs through
    `Peeroleum_bound_safe`, a loud throttled catch. Deliberately asymmetric: `inbox.do()` and
     `Peeroleum_rollup_faulty` are NOT wrapped, because those **are** the delivery and a throw there
      must stay loud. The net goes around the housekeeping, never around the work.

This generalises §2's table. There the cheap read stood in for the expensive truth; here an
 **untested path stood in for a guarantee**. Same shape: something assumed sound because nothing had
  ever contradicted it, in a place nothing could.

### 2.2 The discovery layer has never been observable

*From a concurrent agent, 2026-08-06, and it reframes §3 — so it is recorded here rather than lost in
 a transcript:* **"the transfer's problems aren't mostly in the transfer — they're in the fact that the
  discovery layer above it has never been observable, so every bug there has had to be found by you,
   live, twice."**

The word *mostly* is too strong — the largest win of 2026-08-06 (#4, `held` going down) was pure
 transfer, as were #2 and #3. But strip that word and the claim is not only right, it is **measurable**.
  `Radio_trace` call sites, by ghost, as of 2026-08-06:

| ghost | marks |
|---|---|
| `Radio.g` | 15 |
| `Heist.g` | 11 |
| `Ra.g` | 9 |
| `Repli.g` | 4 |
| `Peeroleum.g` | 1 |
| **`Swarm.g`** | **1** |

Of the ~38 event kinds in the tree — `heist-*`, `transcode-*`, `pcm-*`, `serve-*`, `park-stall`,
 `land`, `pulls`, `starve`, `deliver` — **not one** reported a Pier going live or dark, an era change,
  an advertise, a grant, a seal, an invite redemption, a reconnect, or a rebirth. Swarm's single mark
   was `beat`, which measures the *clock*, not discovery.

**The asymmetry showed up in §1's status column, which is the real evidence:**
- transfer rows — #2 overlap, #3 released-while-promised, #4 held-going-down — **all FIXED**, each
   within a day of being reported;
- discovery rows — #11 `ive_got` storm, #14 startup wait, #15 one-sided reload — **all still OPEN**;
- #1, the half-seal, was discovery and is marked FIXED, but only after reading wrong **on both ends,
   forever**, with a badge sitting right there claiming to report it.

So the sharper statement: **the transfer's bugs get found and fixed in a day because it is instrumented;
 the discovery layer's bugs recur, stay open, and cost a live session each time.**

And the corollary, which ties this to §2.1: the discovery layer is not merely uninstrumented — its one
 instrument was **itself broken** (#1: `Diag_trouble` reading `self.sc.pub` for a key that lives on
  `.c.keys`, so `mine` was always `''`). A *wrong* instrument is worse than none, because it spends
   attention on a phantom while the real fault runs. Same shape as the backstop in §2.1: a thing whose
    whole job is to help in trouble, untested, doing harm exactly when it mattered.

**Why this reframes §3.** The missing level may be an **observability** level before it is a test level.
 A Book proves a mechanism you already understand; a trace finds the one you do not. Cheaper than
  `MusuNeGrind` and strictly prior to it.

**LANDED 2026-08-06 — `Swarm.g` 1 mark → 8** (`f8868a20f022e254`). Seven new electrodes, all `.c`-only
 (`Radio_trace` pushes to `M.c.supply_trace`, cap 1200), so no fixture byte moves:

| mark | where | the question it answers |
|---|---|---|
| `station-up` | `Swarm_station_up` | t=0 for the whole file; `era` names *this* boot; `routed` vs `piers` is the reload shortfall before a frame is sent |
| `rebirth` | `Swarm_note_era` | the peer restarted — counts `wanted`/`parked`/`retx` **before** the deletes discard them |
| `era-kick` | `Swarm_pulse_all` | the epoch backstop firing at all, and `kicks` climbing to the 60s ceiling = the stranded pair |
| `advertise` | `Swarm_gossip_music` | `piers → granted → told`: which of the three gates ate the boast |
| `seal` | `Swarm_seal` | a friendship reaching durable storage; `grants:1` is the one-way pairing at the moment it forms |
| `redeem` | `Swarm_redeem` | a pairing starting — a `redeem` with no `seal` after it is the silent issuer-side death |
| `rebuff` | `Swarm_rebuff` | every door slam, in the file rather than only in a console nobody was watching |

`advertise` is the one to read first: this verb already computed all three numbers and returned only
 `told`, to a caller that discarded it — the facts existed for one stack frame and were never once seen.
  That is §2's pattern one more time, in the discovery layer's most-complained-about path.

**What the verification runs then exposed, unprompted.** `Swarmation.g` defines exactly two Books,
 `MusuSelf` and `MusuThem`. Both ran green — and both were **vacuous**: neither had *any* recorded
  fixture in `wormhole/Story/`, and the snaps the run auto-wrote were six lines whose entire content
   was `self,round`. So the swarm layer's own two Books assert **nothing**, and a green from them is
    not a gate. (The auto-written stubs were deleted, not kept: recording a baseline while the tree is
     dirty is the one thing fixtures must never do.) Two consequences worth holding together:
- §2.2's claim was **understated**. Discovery isn't just uninstrumented — its Books are hollow, which
   is why `MusuBuddy`/`MusuHeist` carry the whole burden of a layer they only touch incidentally.
- it is a second, independent argument for stripping `self,round` via `omit_sc` (§2.3): strip it and
   these two fixtures are *empty files*, which states the truth out loud instead of dressing a hollow
    Book in a plausible-looking snap.

### 2.3 A Book's verdict is partly a function of how warm the tab is

Found 2026-08-06 while verifying an unrelated change, and it undermines the gate itself, so it belongs
 beside §2.1 and §2.2 rather than in the runner notes.

Three consecutive `MusuHeist` runs, **identical code**:

| runner state | outcome | caveats |
|---|---|---|
| just `reload`ed (cold) | **red**, `ok_pct:0.95`, step 2 | 20 |
| warming | 22/22 | 14 |
| warm | 22/22 | 1 |

The failing step's entire diff was **one missing `%see`** plus `self,round=5` where the fixture had
 recorded `self,round=6`. The Book had started before the world settled to the depth the fixture was
  recorded at, so an early claim never fired. **`self,round` is the observable** — below the fixture's
   value means the run is cold and the red is an artefact.

Two consequences, both worse than the inconvenience:

- **False reds are cheap to generate and expensive to read.** The natural response to a red is to
   suspect the change in your hand. Here the honest attribution needed three runs and a fixture diff;
    the wrong attribution was one step away and would have reverted a correct fix.
- **Caveat counts carry no signal.** 1 → 14 → 20 on unchanged code. A caveat is *forgiven* value-noise
   (EntropyArrest grafting got→exp), so a jump must never be attributed to an edit without a re-run.
    Only `ok`/`ok_pct` mean anything.

**What `self,round` actually is** (corrected after a survey — the first draft of this section called it
 a frozen boot depth, which is wrong): it is the **cumulative belief-round counter** (`Hovercraft.svelte:39`),
  stamped into every snap, climbing all through a run — `MusuHeist` records `6,8,9,12,…,38`. It appears
   in the fixtures of **~120 Books**, and *changes within the run* in at least 30. Most exposed by count
    of distinct values: `MusuRaChase` 55, `MusuRaStream` 39, `PereProof` 32, `LeafFarm`/`LakeNets` 29,
     `MusuHeist` 21.

It is **not** entropy-arrested anywhere (no `Entcase` names it). That is why Books are normally green:
 under a quiescent runner the round sequence is genuinely reproducible. It drifts only when the tab is
  doing something *else* — which makes it the one value in the whole snap that detects ambient work.

**So do not EntropyArrest it.** Forgiving it would buy determinism by blinding ~120 Books to "something
 else was running", and it would not even fix the failure that prompted this: on that cold step 2 the
  fatal diff was the **missing `%see` line**, which is structural and no value-graft can forgive.
   Arresting `round` removes a diff line and leaves the step red.

**The right cut is to strip it from the snap, not forgive it in the snap.** The mechanism already
 exists — `omit_sc` session-key stripping, `SESSION_KEYS = {active, created_at, new, not_found}` at
  `Text.svelte:362`. `round` belongs in that class: a session fact, not a fixture fact. Keep the number
   as telemetry (where drift is a *signal* worth alerting on) and out of the recorded bytes. That gets
    determinism and keeps the detector, instead of trading one for the other.

The underlying rate variation is still **§4.1's unexplained startup wait**, and `round` is now a cheap
 probe for it. It also sharpens §2.2: the instrument was not merely absent, it was *lying in the
  direction that costs the most* — exactly like `Diag_trouble` and the backstop before it.

---

## 3. The instrument: `MusuNeGrind`

Not a convenience — a **missing test level**. Every defect above lived in composition, and not one
 was reachable by any `Musu*` Book, because each of those runs one mechanism in a quiet world.

Full design, invariants, the mutation table and what is still owed: **§3.11 here** (it landed, ran
 green and had every claim broken on purpose) and `Backpressure_todo` §0 item 00 (the payload stressors, rung 2). In short — two
  runners over the **real relay** (not a loopback mock, so reconnects, sheds and one-sided reloads stay
   in scope), bulky binary Repli while the radio plays and a mag replicates, asserting **invariants not
    a snap** (the fixture will be nondeterministic like MusuBuddy, so a 500-line diff cannot be the gate).

The load-bearing claim is **the beat never overruns its cadence for a run of ticks**. Everything else
 degrades *through* the beat, so that one assertion alone would have caught the landing race, the
  park/release livelock and the `ive_got` storm. `Swarm_share_beat` already counts it
   (`skipping this tick (×221 so far)`); nothing asserts on it.

### 3.x at a glance

| § | what | state |
|---|---|---|
| §3.5 | an anti-freeze watchdog is pacing the whole machine (the 3.8s `post_do`) | **MEASURED, cause found, fix NOT shipped** → §4.7 |
| §3.6 | the music's asks queued behind the heist's work | **REFUTED** — kept on purpose as a worked example |
| §3.7 | a janitor was holding the music hostage (the cull, then the tour) | **MEASURED, FIXED**; a daemon-side residue is still unattributed |
| §3.8 | `ra_missed` had no reader on the music path | **CLOSED by §3.9 (2)**; one live free-standing finding remains (the Vyto tok) |
| §3.9 | the goner-diff never ran live | **SOURCE-VERIFIED, items 1+2 SHIPPED**; item 3 is curiosity |
| §3.10 | the transcode frontier can outrun the playhead — what remain are wedges | **SOURCE-VERIFIED**; item 1 open as an `Ra.g` handoff, item 2 superseded by §3.12 |
| §3.11 | `MusuNeGrind` — the design, and the gate it became | **GREEN + VERIFIED BY MUTATION**; §0 item 1 CLOSED. Gates the janitor/wire seam only |
| §3.12 | the PCM belt livelocks — the 32s ceiling, the pinned CPU, the dropped frames | **MEASURED, FIXED**; one lead (`×2` on every RECV) explicitly not built on |
| §3.13 | the serve path never looked at disk — 98% of the miss storm was servable | **MEASURED, SHIPPED** (`Ra_reheal_id`); live verification pending |

---

## 3.5 The metronome: an anti-freeze watchdog is pacing the whole machine (2026-08-06, MEASURED)

**`Vytui.svelte:127`, `MAX_MOTION_FRAMES = 240`, ~4s @60fps.** Its own header says it is unreachable:

> *"far beyond any real settle (<1s), so a healthy layout never trips it; a sick one can no longer peg
> the main thread → freeze the tab → kill the peer heartbeat."*

It trips on **every step of Sounditron**. The glass never settles on its own, so the watchdog is not a
backstop — it is the clock the Book runs on.

**How the account was closed.** Sounditron: 7 steps, ~7.75s each. MusuReco: 11 steps, ~1.1s each, same
runner, same minute. Five electrodes, each added because the previous one exonerated its suspect:

| span | mark | cost | verdict |
|---|---|---|---|
| the five boot waits | `boot` | **1.5s for the whole run** | innocent — every truth-fn settles at 0ms |
| `waitVyto` | `vyto-wait` | **60–180ms** | innocent (prime suspect) |
| quiescence | `quiesce` | **0.15–0.25s** | innocent |
| snap encode/compare/store | `snap-cost` | **16–103ms** | innocent |
| `advance` → next step | `advance` | **3801ms, ±7ms over 7 samples** | **the thief** |

`resolve:0` — the Runstepped callbacks are free. A dead-constant 3.8s is a *timer*, not contention.
`post_do` is documented **"Does NOT call beliefs()"**: it pushes onto `H.todo` and waits for something
ambient to drive the loop. On a world with a resident Vyto glass the only thing regularly driving it is
the 240-frame force-settle. **`post_do` is called twice per step** (once for `snap_step`, once for
`do_step`) — 2 × 3.8s = the 7.6s.

**Three consequences, in ascending order of importance.**
1. Sounditron is slow because its glass never rests, not because anything it waits for is slow. Every
   ceiling it was blamed on was settling instantly.
2. **This is very likely the unexplained 3–5s single-call block in `deliver`** (§2's open question, and
   the one thing the 20-analyst competition could not account for). A glass in continuous rAF motion
   pegs the main thread in ~4s bursts — which is precisely the failure its own comment predicts, written
   by someone who believed the branch was unreachable.
3. **Third instance of the same pattern**, and it is now the most reliable thing in this document:
   `waitVyto`'s *"the chase still converges"*, `Swarm_gossip_music` computing three numbers and returning
   one, and now *"a healthy layout never trips it"*. Each is a **comment asserting a runtime property
   nobody measured**, each was false, each cost real time. §2's rule — *the comment is not evidence* —
   should probably be promoted from an observation to the thing this document is about.

**Next move (do NOT skip to a fix).** The question is now *why does Sounditron's voronoi never reach
`SETTLE_FRAMES = 8` consecutive calm frames* — a vertex-count flicker pinning `drift`, a target chasing
itself, or a NaN, all three named as suspects at `Vytui.svelte:121`. `runner_shot --why` reads the
render telemetry film strip (gate + wave/morph/settle ring) and is the right instrument. Find the cell
whose `disp`/`drift` stays pinned. **Do not raise `MAX_MOTION_FRAMES` and do not lower it** — it is
doing its job; the layout under it is not.

---

## 3.6 The music's asks are queued behind the heist's work (2026-08-08 — HYPOTHESIS **REFUTED BY ITS OWN INSTRUMENT**; see §3.7)

> **This section is kept on purpose, as a worked example of a plausible story that was false.**
>  **Do not cite §3.6 as a finding.**
>
> **VERDICT (2026-08-08, same day):** the split was read and **`keep` was 0**. The heist driver was
>  never the cost. The beat was held by phase 1, `Ra_shuffle_cull` — see **§3.7**, which carries the
>   measurement and the fix. The chain below is left standing because the *shape* of the argument was
>    right (one serial beat sets the clock the playhead's asks run on) and only the named phase was
>     wrong; that is exactly the failure mode `comments-assert-unmeasured-properties` warns about, and
>      it took one paste to catch.
>
> **And it was closer than it was credited with being.** §3.12 later found that a heist pulling 11
>  tracks *does* destroy the radio's supply — through the PCM belt, not through the beat. The instinct
>   was sound; the mechanism was wrong; the refutation on the named mechanism was still correct. Both
>    halves of that sentence matter.

**Status matters here and this document is the reason: §3.5 above is MEASURED, this one was NOT.**
What follows was a causal chain read out of the source and matched against one console paste. It was
stated so it could be *killed*, and the instrument that killed it was already shipped.

**The chain, as argued.** All four of these lived in one serial `Swarm_share_beat`, in this order:

| # | phase | what it is |
|---|---|---|
| 1 | `Ra_shuffle_cull` | disk-touching, self-throttled to 30s inside |
| 2 | `Stoker_tour` | the collection conveyor — a dig |
| 3 | the friend loop | offers, **and the "keep the wire ahead of the playhead" `Repli_want_next` asks for the PLAYING record** |
| 4 | `Heist_keep_beat` | *the entire heist driver, awaited inline* — its own comment concedes "cheap when no keep stands" |

*(Phases 1 and 2 no longer run inline — §3.7 detached both. Phases 3 and 4 still share the beat.)*

`Swarm_share_loop` fires every 600ms but is **busy-guarded**: while a beat is still in flight the next
tick is *skipped entirely*, not queued. So the beat's true period is however long the slowest inline
phase takes — and phase 3, the music's chunk asks, only runs once per beat. That much survives the
refutation and is why §0 item 0 still asks for the split to be read.

**The test, and it was one paste.** Catch the skip line during a heist with music playing.
- `keep` dominates ⇒ the chain above is real, and the fix is structural: the playhead's asks must not
   share a serial beat with the heist driver (give phase 3 its own cadence, or bound phase 4's work per
   beat). **Do not just raise the 600ms** — that lengthens the ask period, which is the defect.
- `cull`/`tour` dominate ⇒ different problem entirely, a disk verb on the live path. **← this one.**
- all four small but the total large ⇒ the cost is *between* the phases; suspect `post_do`/the metronome
   in §3.5.

It was also, note, the *fourth* instance of §2's pattern in the making: "cheap when no keep stands" is a
comment asserting a runtime property nobody has measured. Measure it before believing either it or me.

*(That last sentence was the useful one. It was me who needed measuring. — §3.7)*

---

## 3.7 A janitor was holding the music hostage (2026-08-08, MEASURED — cause found and fixed)

*Full write-up, all three console pastes and the daemon cross-check: `history/Composition_closed_2026-08.md`.*

**The reading**, off the human's live tab, three separate beats in one paste:

    last beat: cull=8475  tour=0 peers=0 keep=0 (ms)
    last beat: cull=29671 tour=0 peers=0 keep=0 (ms)
    last beat: cull=12327 tour=0 peers=0 keep=0 (ms)

Three phases at **zero**, one at up to **29.7 seconds**, against a 600ms cadence. The split did not
 narrow the field; it collapsed it.

**The cause.** `Ra_shuffle_cull` calls `Ra_source_alive` **per record**, and that verb is an awaited FSA
 directory `expand()`. Serially, over the whole shuffle Mag, on a crate whose census is **539
  directories**. Its 30s throttle bounds how *often it starts* — it says nothing about how long it
   *holds the beat*, and at 29.7s it very nearly ran back-to-back with itself. **That is the durable
    lesson: a throttle is a frequency bound, never a duration bound**, and it now sits in §2's table.

**Why that starves music specifically.** Everything the radio eats is downstream of that one `await`:
 `Ra_transcode_pump` (so the encoder frontier stops advancing), `Ra_mag_warm`, `Ra_restock_beat` and
  the full-length lead pass. A janitor sweep was holding the entire supply chain for up to half of
   every sixty seconds.

**The fix — both janitors now fly detached.** `Swarm_cull_detached`/`Swarm_cull_done` (`Swarm.g`,
 `fc39dd10f0a0d3c1`) and its deliberate twin `Swarm_tour_detached`/`Swarm_tour_done` for `Stoker_tour`.
  Nothing in the beat read either return value. Each is single-flight on a **start stamp**
   (`cull_flying`/`tour_flying`), and the latch is cleared on **both settle and throw** — a latch left
    standing would silently retire that janitor for the life of the tab. Durations still report, as
     `cull_bg`/`tour_bg` in the same skip line: **detaching a slow thing must not also make it
      invisible.**

**Two environments, two different culprits — do not merge them.** The daemon agent measured a separate
 `beliefs mutex held 8s by fn:swarm_share_beat` on the **jamserve** box and correctly ruled the cull out
  *there*: `scripts/daemon/main.ts` `share_arm()` stamps `ra_cull_floor_ms = 1e15` unless `CULL=1`, so on
   the daemon the cull takes its early return every beat. Both readings are true of their own box. The
    daemon's remaining 8s hold is **still unattributed** (their leading suspect is `Stoker_tour` doing
     native ffmpeg stocking inline) and is **a single sample** — a strong lead, not a baseline.
- **The cheap next cut for the daemon:** `w.c.beat_split` is already populated in-process every beat.
   Read `tour` off it from `main.ts` rather than monkey-patching verbs — the instrument is already there.
    (It will not show on the `/status` port, which dumps `sc`; `beat_split` lives on `.c`.)

**What the detach did NOT do.** It did not on its own lift the 32s preview ceiling — that was §3.12's
 PCM livelock, found later the same day. The detach removed a large, measured blocker of
  `Ra_transcode_pump`; it was never the whole story, and the write-up at the time said so.

## 3.8 `ra_missed` had exactly one reader, and it was not the music path (2026-08-08 — CLOSED by §3.9 item 2)

**The headline is now historical.** `Repli_missed_hot` is that reader, wired at `Ra_mag_warm` and
 `Ra_restock_beat` — see §3.9 item 2. What is kept here is the part that outlives the fix.

**The disease this was a symptom of.** A source that cannot resolve a wanted id answers `repli_missed`;
 the sink stamped `w.c.ra_missed[id]` and nothing on the music path ever read it, so a music want for a
  disclaimed id was re-asked on the ladder interval (1.5s when dry, 4s otherwise) for the life of the
   tab. **The failure was symmetric** — each tab asking the other for ids the other could not serve —
    and *that symmetry was the tell*: it fits "both starving through one mechanism" far better than any
     one-sided bug. §3.9 names the mechanism.

**The retired one-question test, kept because the trap is live.** The test first proposed here compared
 `Radio%of` against the missed ids. It was unrunnable: **`Radio%of` is a DURATION in seconds**
 (`Radio.g:632` — *"the OFFER's length, not the file's"*), and `%Radio` carries no record id at all. The
  lifetell label `Radio:starved|of:138` is Vyto's tok recipe (`Vyto.g:248-251`: mainkey + value +
   whichever join keys exist in sc) picking up the track length. **A lifetell label is a rendering, not
    a field** — do not read an id out of one.

**Still live, and free-standing: the tok re-keys the cell.** The tok includes the mainkey VALUE and
 `of`, and Vytui's `{#each}` keys cells by tok — so every `playing↔starved` flip and every track change
  **re-keys the Radio cell and destroys/remounts the mold**. The `life mount mold` churn in the console
   is the tok recipe, not the wire. A fix would be dropping `of` from the join list at `Vyto.g:249`, but
    that re-keys cells across every Vyto Book's fixtures — a recorded-fixture change, not a patch. **Not
     done.**

## 3.9 The goner-diff never ran live — sources silently retired records and no one told the mirror (2026-08-08, SOURCE-VERIFIED; items 1+2 SHIPPED)

**This is the disease behind §3.8's symptom, and it explains the symmetry in one mechanism.**

**The protocol had a delete half, and it was wired only in Books.** `Repli_sent_se` (`Repli.g:1228`)
 resolves goners and fires `repli_on_goner` → `Repli_retire` (`Repli.g:457`, one `op:delete` line), and
  **every caller in the tree was `Ghost/Story/Musuation.g`.** Same for the heist-side
   `Musica_stand`/`Musica_recast_offer` (callers only in `Heistation.g`). The live offer path,
    `Ra_offer_stock`, is upsert-only — zero delete lines ever crossed.

**Meanwhile three live mechanisms remove records from a source's shelf:** `Stoker_tour` (the conveyor,
 every ~90s on a HEALTHY tab, dropping via `Ra_rec_drop`; its only guard is `rec.c.want_ts` freshness,
  which protects an actively-pulling sink, not a mirror that merely lists the record), `Ra_shuffle_cull`
   (source gone), and page twins (sink-side dedupe, the stale half keeps being asked). So: both tabs
    tour, both silently retire, both mirrors go stale, both answer `materialise gone` — **both starve,
     one mechanism, no second bug needed.** And `Ra_shuffle_cull`'s own comment ("lets the ordinary Se
      goner-diff tell the friend their mirror copy is dead too") asserted a mechanism that was not
       running — §2's pattern, in a comment §3.7 had quoted approvingly.

**Ids are content-stable** (sha256 of source bytes), so reloads don't re-mint the id space — verified,
 one less suspect.

**1. SHIPPED — the retire seam is wired, on both retirers.** The tour whittle ledgers every dropped id
 on `stock.c.retire_due` (`Radio.g`, `a3a7863525517496`); `Ra_shuffle_cull`'s goner loop pushes to the
  same ledger (`Ra.g`, `194a5920df997267`); the share beat flushes it right after the tour via
   `Repli_retire_flush` (`Repli.g`, `a09d8367c1d3755e`; call in `Swarm.g`, `9441de33ee8c87e9`) — one
    `op:delete` line per id per registered caster, whose receive side already handled paged mirrors
     (hardened long ago and never fed). Drain-before-send, so a mid-flush throw costs one batch of
      tells, bounded by the status quo. Trace: `{ev:'retired', id, piers}`.
 **The live tell to watch for:** the per-id `serve want … no record for id` storms should stop
  RECURRING for newly-dropped ids. **Existing stale ids only heal when their record next drops or the
   mirror is reborn** — so a first reading after this ships will still show old ones.
 **Requantified 2026-08-08 (§3.13): retirement explains ~2% of the observed miss storm** (1 of 61
  distinct ids genuinely gone; the rest were on disk and unservable only because the serve path never
   looked). This seam is still right — it is just not the storm's body.

**2. SHIPPED — the bounded backoff on told misses.** `Repli_missed_hot(w, id)` (`Repli.g`
 `b85a7196c9b5fa38`) is the shared, **self-expiring** read: disclaimed within `ra_missed_hold_ms` (60s)
  ⇒ skip; past it the key is deleted and the next ask goes through. **A backoff, never a ban** — a
   source can regain a record — and self-expiry also stops the map growing unbounded, which a blacklist
    would not. Wired at the two crate-walking sites, which is where a stale mirror becomes a storm:
- `Ra_mag_warm` — skips a disclaimed row rather than re-asking `@0` on the RTO ladder forever.
- `Ra_restock_beat` — skips **before** `considered` increments, so a dead id no longer burns one of the
   K slots per pass and crowds out records that can actually arrive.
- **The `rows[0]` single point of failure is fixed too, surgically**: `Ra_mag_warm` armed `mag.sc.warm`
   from `rows[0]` only, so an unservable id in row 0 meant the mag NEVER went warm and re-asked `@0`
    for the life of the tab — which matched the observed `@0` misses exactly. The warm gate now falls
     through to the next non-disclaimed row **only when row 0 has been disclaimed** — a state no Book
      can reach (`ra_missed` is empty there), so every recorded fixture stays bit-identical. A
       merely-slow row 0 still gates the mag exactly as before.
- **Left alone on purpose:** the `Swarm.g` lead pass (the single playing record). Gating that would
   silence a track rather than move past it; a disclaimed *playing* record wants the radio to skip on,
    which is §4.8's job, not a want gate's.

**3. Not established, and it is curiosity rather than a blocker:** WHICH path retired the two ids seen
 in the console (tour, cull, or twin — the serve-miss line can't tell them apart; the
  `source-gone`/`shuffle-cull`/tour traces carry the id and a tracelog dump would settle it). The fix
   above is right under all three.

## 3.10 The transcode frontier CAN outrun the playhead — what remains are wedges, not rates (2026-08-08, SOURCE-VERIFIED)

With the cull detached, the steady-state arithmetic is fine: the lead pass lays down up to 24s of audio
 per 600ms beat (~46× realtime at defaults; worst-case floor 4s/beat ≈ 6.7×). To starve on RATE the beat
  period would have to exceed ~28s — exactly the shape §3.7 removed. What remained were **wedges**, each
   presenting identically as "parks at 32s forever":

1. **`ra.done` is sticky and unrecoverable** (`Ra.g:2116-2125` at the time of reading): a drain failure
    sets `ra.done=1`, nulls `rec.c.pcm`, but leaves `rec.c.ra` standing — `Ra_transcode_ensure` then
     returns that dead handle forever, `Ra_transcode_advance` returns 0, and `Ra_pcm_sweep` skips the
      record (`if (!rec.c.pcm) continue`). A one-track permanent 32s ceiling. **STILL OPEN** ⚠ `Ra.g` —
       a handoff to the daemon agent, not our edit.
2. **The `still.length > 4` eviction and the 384MB PCM belt both free an OPEN encode**, so a re-ensure
    restarts at the preview boundary and re-grinds. **This one was the real story — see §3.12**, which
     measured it, named it a livelock rather than a re-grind, and fixed it.
3. **The browser path hangs off one whole-file `decodeAudioData`** (`Ra_source_pcm`, five null exits,
    each landing on a backoff that climbs to 60s) — every failure is silence to the asker. Open.
4. A parked want is **never dropped** (verified: one mint site, one removal site, no expiry) — good, but
    it means a wedged source parks a sink forever with no tell except the L3 `park-stall` bark. Open.

**Instrument shipped** (`Swarm.g`, `ef702334e372daa7`): `beat_split.peers` lumped the pump/warm/lead in
 with the offer loop, so it could not price the one verb the ceiling hangs off. The skip line now
  carries `(pump= warm=)` inside the peers bucket; `peers` keeps its old meaning.

**A correction worth keeping.** Item 1 was called "the likely cause" of the 32s ceiling off a partial
 reading of one log. The fuller log refuted that as the *dominant* one (§3.12). Item 1 is still a real
  defect; it was never the one the human was hitting.

## 3.11 `MusuNeGrind` — the design, and the gate it became (2026-08-08, **VERIFIED BY MUTATION**)

> **Read this line before anything below it.** This section used to open with a warning that nothing in
>  it had ever been executed. That is no longer true, and the replacement warning is more useful: **the
>   Book is green, its fixture is recorded, and five of its six claims are gates — because each one was
>    broken on purpose and watched go dark.** The sixth, #4, *fired green over a sweep that never threw*
>     until a mutation exposed it. That is the whole argument of §2 arriving on schedule: **a green Book
>      is not evidence about the code until you have seen its claims go red.** The mutation table below
>       is now the load-bearing part of this section; the design notes are history.

**Where it is.** `Ghost/Story/Heistation.g`, appended after `MusuDoor` — modelled line for line on
 `MusuVend`'s scaffold as §0 instructs. It went into an existing `.g` rather than a new one for one hard
  reason: a new ghost file needs a `CREDULER_GHOSTS` line in `LiesLies.svelte`, and this session was
   barred from `.svelte`. `Heistation.g` is already in that manifest, so the Book is live to a runner the
    moment it compiles. Credence row: a new top-level **`What:MusuNe`** group (the human: *"far too much
     is ending up in Musu"*) — composition Books go there, one mechanism-in-a-quiet-world Books do not.

### What it composes that no existing Book does: a **janitor** and a **wire**, in the same beat

`MusuVend` proves a magazine crosses. `MusuHeist` proves bytes land. `MusuBuddy` proves the pipeline
 plays. **Nothing anywhere proves that some subsystem's private housekeeping does not stop all three** —
  which is §3.7, verbatim and measured: `Ra_shuffle_cull` held `Swarm_share_beat` for up to **29671ms**,
   three other phases at **zero**, starving `Ra_transcode_pump` and with it the supply chain. The fix
    (`Swarm_cull_detached` / `Swarm_cull_done`) shipped the same day and **nothing tests it.**

That is the class, and it is the class §1 is made of. Re-read the ledger with it in hand: #4 (`held`
 going down — a landing that left the beat and never told the puller), #10 (the beat permanently
  overrunning), #13 (a disk write starved behind everything else), #12 (a watchdog that became the
   metronome, §3.5), #21 (a belt that livelocked the decoder, §3.12) are all one shape — **something
    that was cheap when it was written became the clock something else runs on.** No single-mechanism
     Book can see it, because the two things are never in the same world at the same time. This Book
      puts them there.

### The injection is the point — and it is what stops this being a false green

A toy in-memory crate is fast whether the cull is awaited or not, so a naive "the beat stayed under
 600ms" assertion over honest data is a **guaranteed false green** — it would have passed happily
  throughout the entire 29-second era. So the Book makes the janitor **slow on purpose**, through a hook
   that already exists and is already used in production:

- `Ra_shuffle_cull` reads `w.c.ra_nav || this.Crate_nav()` (`Ra.g:787`) — the same seam
   `scripts/daemon/main.ts` already reaches for when it stamps `ra_cull_floor_ms`.
- `Ra_source_alive` spends its whole cost in `nav.dir_at(dir)` then `dl.expand()` (`Ra.g:759–762`). A
   fake nav whose `expand()` sleeps **is** a slow disk — no FSA, no `Ra.g` edit, no real crate.
- `Ra_card` short-circuits on `rec.c.card`, so a card stamped on `.c` costs nothing and the *only* cost
   in the sweep is the injected one. The measurement has one variable.

Three nav modes, one per scene: **alive** (file present — slow and harmless), **gone** (directory lists
 nothing, so every record is dropped), **throw** (the `dl` carries no `files`, and `dl.files.find(...)`
  is the one line in `Ra_source_alive` outside a `try`, so the sweep rejects).

### The invariants it asserts

| # | `%see` | reads | the defect it would have caught |
|---|---|---|---|
| 1 | **the janitor flies instead of holding the beat** — every kick returned at once while a demonstrably slow sweep ran on | every `kick` row in the run: `started` ⇒ `quick`, ≥4 kicks, **and** `did_work` off `cull_bg_ms` | §3.7. Re-add the `await` in `Swarm_share_beat` ⇒ red |
| 2 | **the wire kept moving under the janitor** — a fresh record crossed to the mirror while the sweep was still in flight | baseline crossing **and** `mid_flight` **and** `crossed` | the composition claim itself: housekeeping and traffic are no longer one clock (§1 #10) |
| 3 | **the janitor is single flight** — a second kick while one flies is refused rather than stacked | `first_started` + `twin_refused` + `same_flight` (the start **stamp**, not merely a truthy latch) | the overlapping-writer shape — a heist double-writing a landed file, *"spastic as fuck"* |
| 4 | **a janitor that throws still clears its latch** — the next sweep starts instead of the tab retiring its janitor for good | `latch_cleared`, `restarted` **and `did_throw` off the nav's expand COUNT** (`expands=1`) — a duration cannot carry this, see the mutation table | §2.1's shape exactly: `Swarm_cull_done`'s catch arm is an **unmeasured claim in a comment** |
| 5 | **the detached sweep still does its work** — records whose source went missing were dropped by a cull nothing awaited | `swept` (9 → 0) | **non-vacuity.** Without it, every row above is satisfied by a janitor that does nothing |
| 6 | **the source told the sink it cannot resolve an id** — the miss travels | `ra_missed[id]` stamped | §3.8's *provable half* |

**#5 is not decoration.** §2.1's lesson and `MusuDoor`'s canary both say the same thing: an assertion
 that can be satisfied by the mechanism not running is worse than no assertion. "Returned quickly" is
  trivially true of a no-op, so the Book pins that the same sweep it returned instantly from was (a)
   expensive (`cull_bg_ms` over a floor) and (b) effective (it emptied the shelf). #1 reads both.

**#4 is the one worth having built this for.** `Swarm_cull_done` exists *only* so a failed sweep cannot
 leave `cull_flying` standing — and its own comment says a standing latch *"would silently retire the
  cull for the life of the tab"*. That is a runtime property nobody has measured, on a path that runs
   only in an emergency, guarding a janitor whose absence is invisible. §2.1's trapdoor, one file over.

### The step shape

| beat | scene | what it does |
|---|---|---|
| 2 | `setup` | two Piers over `Lake_link`, `Repli_arm`, origin stock shelf, grant on, `ra_cull_floor_ms=0`, 8 records minted through `Ra_rec_home` (so they land under `%Mag:shuffle > %Cloud`, which is what the cull actually walks) with cards stamped on `.c` |
| 3 | `load` | offer the whole shuffle Mag as one husk and settle it — the **control** for beat 4 |
| 4 | `janitor` | kick a slow sweep, then mint + offer + settle a fresh record **while it is still flying** |
| 5 | `settle` | hold until it lands; read `cull_bg_ms` and that nothing was dropped |
| 6 | `singleflight` | two kicks in one beat; the second must be refused |
| 7 | `thrown` | the throwing nav; latch clears; a later kick still starts |
| 8 | `goner` | the gone nav; the shelf actually empties (runs last — it destroys the stock) |
| 9 | `disclaim` | three wants for an id the source cannot resolve; record `asks` beside `told` |
| 10–11 | `pump` | settle |

Two mechanics that are load-bearing and easy to get wrong:

- **`MusuNeGrind_await_cull` is a HOLD, not a wake** (`Coding_guide.md`). The detached sweep is a bare
   promise nothing in the world waits on, so Story would quiesce and snap mid-flight and the fixture
    would record a coin toss. Awaiting it from inside the wrangle's `do_fn` keeps the req unfinished for
     the duration, and *that* is what holds the snap.
- **A row may carry a verdict, never a raw millisecond.** Every elapsed time is compared inside
   `MusuNeGrind_kick` and only its verdict (`quick`, a 1-or-absent flag) is snapped. One `ms:` in `sc`
    and this Book is permanently unrecordable.

### The disclaim scene is a scene, deliberately not a claim

The Book *drives* the disclaim scene and records `asks:3` beside `told:1` — so the snap carries the
 number — but the claim that wants writing, *"the sink stopped asking for an id the source disclaimed"*,
  is **not** authored as a `%see`. When this was written, `ra_missed` had no reader on the music path,
   so asserting it would have authored a Book **red at birth**, and a red Book gates nothing (§2.3 is
    the whole argument).
 **That precondition has only half changed, and the earlier reading of it here was wrong.** §3.9 item 2
  did land `Repli_missed_hot` — but at `Ra_mag_warm` and `Ra_restock_beat`, and this Book drives
   neither, so the `%see` is *still* red at birth. See "What is still owed here" at the end of §3.11.

### What this Book explicitly does NOT cover

The **payload** stressors named in `Backpressure_todo` §0 item 00 — punch a chunk out of the middle of a
 page (§3.1b), release a source rec while a want is parked on it (§3.1c), let a landing run while the
  puller beats, `held` never decreasing — are **rung 2** and are not in this scaffold. They need
   `MusuReplica`'s chunk-minting shape wired into this world, and none of it can be written safely by a
    session that cannot compile. The beat harness here is what they will hang on. **Do not claim this
     Book covers them.** Nor does it cover §3.12's PCM belt — a decode livelock needs real audio bytes,
      which is a third rung again.

### What it took to gate anything — steps 1–5, done 2026-08-08 late (runner `a67a5d04`)

Steps 1–2 (compile, first run) landed earlier the same evening and are recorded in §0 item 1. Steps 3–5
 are below. The result: **three consecutive `11/11, ok_pct=1, caveat=0, untried=0` runs on the final
  code**, after two green baselines on the code as it stood at handover — and, worth its own sentence,
   **`caveat=0` on every one of them.** For a Book with a real clock in it that is better than §3.11
    predicted (it expected `MusuBuddy`-shaped jitter); nothing here is timing-flaky. The fixture is
     `wormhole/Story/MusuNeGrind/{toc,001..011}.snap`, re-recorded through `runner_ask accept` (the only
      sanctioned path) after the #4 fix moved steps 7–11.

**The three numbers were never touched.** `ceil()` 120ms / `jan_ms()` 80ms / `work_floor()` 240ms all
 held first time on a loaded runner. Be careful how much that claim carries: the Book snaps **verdicts,
  never durations** (deliberately — a millisecond in sc makes it unrecordable), so what is actually
   measured is that every detached kick came in **under** 120ms and the awaited one came in **over** it.
    The ~720ms figure for the awaited shape is arithmetic (9 records × `jan_ms`), not a reading. No
     margin needed tuning, and the two sides never came close to touching.

### The mutation table — which claims are gates, and the one that was theatre

Step 3 says *"an assertion never seen to fail is not known to be an assertion"*, so **every** claim got
 the treatment, not just #1. Each mutation is a scratch edit to the Book itself (never to what it tests),
  compiled, run, reverted; a run is ~20s, so the whole pass cost four compiles and about ten minutes.
   **Reproduce any row in two minutes** — that is the point of writing them down this precisely.

| # | the mutation | what the snap said | verdict |
|---|---|---|---|
| 1 | hold the janitor kick until the sweep lands (`await MusuNeGrind_await_cull` inside `_kick`) — the pre-fix `Swarm_share_beat` shape | `kick:alive,started` — `quick` and `flying` both gone | **GATE** |
| 2 | *(same mutation)* | `underload,crossed` — `mid_flight` gone | **GATE** |
| 3 | await the cull between the two kicks of the singleflight scene | `kick:twin,started` — the twin ran; `singleflight,first_started` alone | **GATE** |
| 4 | run the thrown scene with the **`alive`** nav — nothing throws anywhere | `thrown,latch_cleared,did_throw,restarted` — **claim fired green** | **THEATRE → now a GATE** |
| 5 | run the goner scene with the `alive` nav | `goner,before=9,after=9` — nothing swept | **GATE** |
| 6 | ask zero times in the disclaim scene | `disclaim:ghostofatrack,asks=0` — no `told` | **GATE** |

**#1 and #2 fall together under one mutation, and that is correct, not sloppy.** They are the two halves
 of §3.7: if the janitor is awaited it cannot fly *and* the wire cannot move under it. Breaking the fix
  reds the Book on exactly the defect it was built for, and on nothing else — #3–#6 stayed green through
   it. That is the discriminator working, demonstrated rather than argued.

**#4 is the finding.** Its evidence was `cull_bg_ms >= jan_ms`, added hours earlier to stop it passing
 over a sweep that had been *throttled out*. That gate is real but it separates the wrong pair: it tells
  **ran** from **never started**, and says nothing about **threw** vs **finished**. `Swarm_cull_done`
   stamps the identical `cull_bg_ms` on the settle arm and the catch arm and records nothing about which,
    so **no duration can ever carry this claim** — the fix was not a better threshold, it was a different
     kind of evidence. The injected nav now counts its `expand()`s (`w.c.jan_expands`, a **count**, which
      is legal in a snap where a millisecond is not), and the sweep's ending is legible in the fixture:

    expands=0  throttled out, never ran        expands=1  entered and rejected at the first record
    expands=9  walked the whole shelf and settled

 `did_throw` is now `expands === 1` and the row snaps `expands` beside it, so a reader sees the number.
  Re-running the #4 mutation against the fix gives `thrown,expands=9,latch_cleared,restarted` — no
   `did_throw`, claim dark. **The lesson generalises past this Book:** #4's first patch was written from
    source-reading and looked exactly like a fix; it took a mutation, not a re-read, to find that it
     discriminated the wrong pair. Two rounds of *"the comment is not evidence"* on the same six lines.

Also fixed while in there: the disclaim row carried `asks: 3`, an **authored constant** — the loop bound
 written into the snap as though it were a measurement. It is `asks: i` now, which is why the #6 mutation
  can show `asks=0`. A constant in a fixture is a claim nobody made.

### What is still owed here

1. **The disclaim `%see` is still not writable, and §3.11 was half-wrong about why.** `Repli_missed_hot`
    did land (§3.9 item 2) — but its call sites are `Ra_mag_warm` and `Ra_restock_beat` (`Ra.g:1033`,
     `:1074`, `:2852`), and **this Book drives neither**; it calls `Repli_want_next` directly. So the
      claim would still be red at birth, for a different reason than before: not "no reader exists" but
       "no reader is on any path this Book walks". The move is to make the disclaim scene ask through
        `Ra_restock_beat` and then write the `%see` — one scene, and §3.8's other half closes.
     - Worth knowing, and it is a §2 tell: `Ra.g:1030` and `:1070` both say in comments that this path is
        *"inert in every Book"* / *"a state no Book can reach"* because `ra_missed` is empty there.
         **MusuNeGrind reaches it** — it stamps `ra_missed['ghostofatrack']` every run. The comments are
          still true in effect (the reader isn't on a path it drives) and already false in their reason.
2. **Rung 2 is untouched** — the payload stressors, unchanged from the list above.
3. §0 item 1 is closed by this. Anything in §4 may now be attributed by this Book, within the limits of
    what it actually covers (which is the janitor/wire seam, and nothing about audio or chunks).

---

## 3.12 The PCM belt livelocks — and it is the 32s ceiling, the pinned CPU, and the dropped music frames, all at once (2026-08-08, MEASURED + SOURCE-CONFIRMED — fixed)

*Full write-up, the console paste and the four-symptom derivation: `history/Composition_closed_2026-08.md`.
 The fix's own write-up is `Backpressure_todo` §3.1e.*

**The reading** (Righto, one paste, repeating every ~10s for twelve minutes): **eight records, every one
 stalled at exactly `from_idx=16`, none ever advancing** — including one that twenty minutes earlier had
  been watched climbing `off=16→18→20→22→24`. It advanced, then wedged. **So it was not a per-record
   wedge (§3.10 item 1) — it was total.** Every record that crossed the preview boundary on that tab
    died there.

**The mechanism, confirmed from source.** `Ra_pcm_sweep` runs a belt: `CAP = ra_pcm_cap || 402653184`
 — *"~384MB — roughly 4 tracks decoded at once"* — over `rec.c.pcm`, the decoded whole-file PCM, which
  is **~92MB per record** ([[pcm-pinned-on-records]]).

    8 records wanting PCM  ×  ~92MB  =  ~736MB   against a 384MB cap

The belt sheds oldest-touched first. An open encode is shed *last* but explicitly **never vetoed**
 (*"a belt that can be vetoed is not a belt"*). So each shed record's next `Ra_transcode_ensure` saw
  `!rec.c.pcm`, kicked a fresh whole-file decode, 92MB landed, the belt was over cap again, and it shed
   another. **Nothing ever survived long enough to encode two chunks.** `Ra_pcm_backoff` only brakes
    FAILURES, so a successful-then-shed decode re-kicked with no brake at all.

**One cause, four symptoms** — which is why nothing else explained the whole log:

| symptom | why |
|---|---|
| every track dies at 0:32 | chunk 16 is the first that needs PCM; none ever gets it |
| CPU pinned | continuous whole-file `decodeAudioData` of ~92MB payloads, forever |
| `inbox backstop … dropped … repli_lines/repli_page` | **music data frames DISCARDED** — the CPU is too busy for unemits to drain, so the inbox hits its 2000 cap |
| bytes flowing at 231KB/s the whole time | the wire was never the problem, which is why every rate reading looked innocent |

**The durable rule, and it is now in §2's table.** You cannot fix a livelock by changing *what* you
 shed, only by refusing to *start* work you cannot hold. **An eviction bound (a belt) and an admission
  bound are two different organs, and a belt without admission upstream of it is a livelock generator
   for any working set larger than the cap.** Check this before adding any new byte budget.

**FIXED, in two places (`Ra.g`).** A census gate in `Ra_transcode_pump` (a NEW whole-file decode is only
 kicked while counted PCM stays under CAP/2, an un-landed kick charged CAP/4; deferred ids simply **stay
  parked**, which is what a park is for) — verified live, decode-starts fell to zero and serves climbed
   1→16. And then `Ra_pcm_admit` at the decode kick itself: a real per-record estimate (`Ra_pcm_est`)
    against the full CAP, counting bytes held **and** bytes in flight, with a **playing-record override**
     and a **lone-candidate floor**. ⚠ `Ra_pcm_admit`'s own comment says the lone-candidate floor was
      *"found by an adversarial read, NOT by a run — nobody has yet watched a 20-minute track play"*.
       **That part is reasoning, not a measurement.** `Backpressure_todo` §3.1e is its home.

**On the demand side (helps, does not cure):** the restock gate (§0) holds deep speculative
 `Ra_restock_beat` traffic while the playhead has under 16s banked (`w.c.lead_s`, counted as
  `restock_held` in the skip line). `Ra_mag_warm` is deliberately NOT gated — it is chunk 0 of two
   records per mirror, the dial's whole domain ([[dial-domain-is-the-warm-window]]), and starving it
    leaves the radio nothing to turn TO. Lowering demand lowers how many records compete for the belt;
     it cannot fix a source whose belt is already thrashing.

**§3.6 was closer than I credited it.** Its instinct — *"the music's asks are queued behind the heist's
 work"* — is right in **spirit**: a heist pulling 11 tracks demands 8+ records past the preview boundary
  at once, and that demand is what overran the belt. It named the wrong *mechanism* (the share beat) and
   the refutation on that mechanism was correct. **The heist's demand destroys the radio's supply, via
    the PCM belt, not via the beat.**

**The `drain-lag` corpus is this section's fossil record (read 2026-08-08 late).** 5515 marks across
 the trace corpus — the most common event overall — but the decode forks the electrode was built for
  never fire: `calls==0` (lost wakeup) **zero**, `tries==0` (throttle bounce) **zero**. 66% are
   `why:EMPTY` = ordinary CPU backlog, the rest multi-second beliefs-mutex holds (`think`, p90 15s) —
    i.e. the belt thrash above, seen from the todo queue. **Today's post-fix boots are clean**: heron's
     20:17 boot has 0 drain-lag in 300 marks (old boots: 150–340 each). Leave the electrode in; do not
      chase drain-lag as its own animal.

**Not established, and do not build on it:** the `×2` on every `ws RECV` line in that console. Two
 sockets legitimately exist per tab (`?addr=<prepub>` from `Swarm_station_up`, `?addr=runner` from
  `LiesLies`), so two `control:hello_ok` are expected — but a `repli_missed` addressed to one prepub
   appearing twice is not obviously explained by that, and `reused-seq collision` in the same log is the
    tell of duplicate delivery. `runner_ask runners` reads the editor's registry, not the relay's live
     bind table, so it cannot settle this. **Someone has to read the relay's binds.** Possibly the same
      animal as §1 #11 / §4.6.

---

## 3.13 The serve path never looked at disk — 98% of the miss storm was content the source still had (2026-08-08, MEASURED + SHIPPED)

**The quantified root cause of the two-Sounditron starvation, and the reframe of §3.9's share of it.**

Cross-checking **every distinct `serve want … no record for id` id** on heron (the source) against its
 own `.jamsend/radiostock/`: **61 distinct missed ids — 50 standing on disk under heron's own pub, 10
  standing under another pub only, 1 genuinely not on disk at all.** So retirement (§3.9's territory)
   accounted for ~2% of the storm; the other 98% was **content the source still held, asked for by a
    mirror that was simply right.** Heron's Stoker read `stock=8` against **99** stock files on disk.

**Two mechanisms make a reload lose most of the shelf:**
- `Repli_find_record` searches the rummage libs and the serve lib **in memory only**; its one recovery
   hook was `Heist_reheal_id` (a runtime memo — also memory). Nothing on the serve path ever consulted
    `radiostock/`, while `Ra_stock_standing`'s own comment says *"Truth lives ON DISK (a fresh boot has
     no particles)"*.
- The Stoker's boot resurrect (`Stoker_look`, `Radio.g`) stands only the **newest 24 files, once**
   (`st.c.resurrected` latch, `k < 24` cap) — so a shelf of 99 comes back as ≤24, and the friend's
    mirror still lists everything offered before the reload ([[one-sided-reload-breaks-serving]]).

**SHIPPED — demand-driven resurrect on the serve path.** `Repli_serve_want` gains a second
 optional-by-typeof hook right after the Heist one: `Ra_reheal_id(w, lib, id)` (`Ra.g`). The id **is**
  the enid (content hash), so the disk lookup is exact: own-pub first via `Ra_stock_standing`, then a
   **cross-pub reach** (same enid ⇒ byte-identical source content; newest first; the card's own `id`
    claim cross-checked) — recovering 60 of the 61. The validation half of `Ra_stock_standing` is
     split out as `Ra_stock_open(nav, hit)` so both probes share the exact checks (fmt bump, size
      promise, seg count, Seam A signature). `Ra_record_from` mints into the serve lib, so the SAME
       want serves. Throttled one attempt per id per 30s (`w.c.reheal_ts`, stamped before the disk
        work), so a genuinely-gone id costs one dir listing per half-minute, not one per 4s re-ask.
         Books unchanged (no nav ⇒ null). Trace: `{ev:'serve-reheal', id, segs}`.
 **Deliberately NO preview-window check**, unlike the Stoker's resurrect: the Stoker can rebuild from
  source, the serve path's alternative is a starved sink — and per-chunk cids refuse a mis-cut resume
   at the sink anyway.

**⚠ THE TRAP THIS FIX WALKED INTO FIRST, because the next serve-path reader will walk into it too.**
 The first cut called `Ra_stock_standing` for the own-pub probe — the obvious reuse, and it is
  **write-side**: `Ra_stock_standing` → `Ra_stock_find` → `Ra_stock_drop` GC's older twins as a side
   effect (`Ra.g:574`). Right for the mint path that owns the shelf; **wrong on a serve, where it made
    a REMOTE PEER'S want delete files off our disk.** Caught the same evening by chasing an unrelated
     `serve-miss` mark. The reheal now does its OWN listing — one `dir_at`+`expand`, partitioned
      own-pub-then-foreign, `Ra_stock_open` (read-only) per candidate — which is also one listing
       instead of two. **Rule the next reader should inherit: nothing reachable from a peer's frame may
        mutate `.jamsend/`.** Worth noting the shape — the dangerous call looked like a pure probe, and
         its name says "standing", not "collect".

**Verification status: compile-gated (LocalGen CHECK), import-gated (`scripts/RehealSmoke.spec.ts` —
 mounts the written `.go`s and asserts the seam deposits + the Book-safety contract), and regression
  green on a live runner booted onto the new code (MusuNeGrind 11/11 `caveat:0`, VytoStaple 8/8,
   VytoCell 7/7). **Not yet proven to fire** — that needs a real starved pair. The live tell:
    `serve-reheal` marks in a source's trace, and a one-sided reload no longer flatlining the pair. A
     monitor is watching the trace corpus and the Cluster toc as of this landing.

**Also seen:** 393 stock files for 139 distinct enids (~2.8× duplication — the per-pub filename means
 each identity re-stocks the same content); filed, not fixed. `Stoker_cull`'s bare drop (no ledger, no
  barren-clear, no trace — latent: it could NOT have fired on heron at `stock=8` against its 44
   threshold, which is what refuted the first hypothesis) is **FIXED same evening**: the cull is now
    the third retire seam, wired exactly like the tour whittle (un-barren the path, push
     `retire_due`, `{ev:'stoker-cull'}` summary mark).

## 3.14 The players are visible now — `role:'player'`, and the production stance that bounds it (2026-08-08)

**The problem it solves is diagnostic blindness, and it was costing a session a night.** A Sounditron
 is a `humdinger` room, and `Lies_humdinger` suppressed its presence at **four** sites — `Lies_advertise`,
  `Lies_going_cold`, and the `from` on both `Lies_ping` and `Lies_pong` (that many because it has LEAKED
   once: a comment names "the exact leak that put someone's /BigSoundland into the editor's dispatch
    pool"). Net effect: no `%HostedIdentity` row, so `runner_ask` could not ping, dump, poke or reload
     the only two tabs that reproduce the bugs — every question had to go through the human, and the one
      experiment that matters (reload one side, watch the reheal fire) could not be run at all.

**The gate conflated VISIBLE with DISPATCHABLE and enforced both by silence.** The owner's constraint
 is only the second one: *"we just need to avoid shooting other Books at them, because they aren't free
  to borrow test runners like the runners are."*

**So they split — by ROLE VALUE, not a flag.** A diagnostic-armed room now beacons with `player:1` and
 the roster stamps `role:'player'`. That choice is the whole safety argument: **every** consumer of the
  registry already filters `role === 'runner'` — `Lies_dispatch_target`'s `dirPubs` (`:563`),
   `Lies_rungo_target` (`:1725`), the Brink counts (`LiesFunk:1902`/`:3426`), the roster's own second
    loop (`:1605`), and `scripts/runner_ask.mjs:77` — so a player is excluded from all of them **by
     construction, with no edit to any of them**. A boolean flag would have needed every site found and
      patched, and the leak history says there are always more sites than you think. It is also the
       repo's own data model: a player is not a runner-with-a-flag, it is a different kind of thing.
 The role transition is **one-way**: a row that has been a player stays one even if a later beacon omits
  the flag, because a going-cold beacon omits facets and promoting a music page back into the pool by
   omission is exactly the leak.

**`H.c.production` — the deployment stance, stamped in `BigQualand` beside `humdinger`.** The owner:
 *"in production we want no participation in any Cluster beyond sending to their peers via relay."*
  **Fail-closed**: non-production only when `import.meta.env.DEV` **and** not a known prod host
   (`jamsend.*`/`voula*`, mirroring `Trust.svelte`'s `P.PROD`). Every other combination reads
    production. The asymmetry is deliberate — a false "dev" puts an end-user's music page into a
     stranger's cluster; a false "production" means a developer notices their diagnostics are off. Two
      locks, different questions: `production` is the deployment stance no user-acquirable localStorage
       key can override; the diagnostic arm (🪪 / `?socklog` / `?watch`) is the per-tab opt-in *within*
        a dev build. **`H.c.production` is now the hook for the rest of that ruling** — the other Cluster
         participations (grants, ghost_compile, rungo) should consult it too; only presence does today.

**Live state at time of writing, stated exactly.** The beacon change shipped before the fold that
 classifies it, and HMR carried it into the live tabs — so both Sounditrons enrolled once as
  `role:runner` (toc written 22:35:46) and the rows still read that way, because **no editor tab was
   alive to re-fold**. That is not a dispatch window: `Lies_dispatch_target` requires `live(r)`
    (`last_heard` inside 45s), `last_heard` is stamped only from a beacon into the editor's `%Runner`
     roster, and a fresh editor rebuilds that roster from scratch — so a directory row with no beacon is
      never a candidate. And within a single fold pass the beacons loop (which flips the role) runs
       *before* the `role === 'runner'` filter that mints `%Runner` rows — and the roster's own cleanup
        (`for (const r of w.o({Runner:1})) if (!known.has(...)) w.drop(r)`, where `known` is populated
         ONLY inside that filtered loop) **actively drops** a flipped row's `%Runner` in the same pass,
          rather than leaving it to go stale. Four independent layers, verified by reading each.
 **They heal to `role:player` on the first fold by any live editor — which needs a human to open one.**
  Confirmed no editor was alive: zero `editor-`prefixed dumps in `_socklog`/`_trace` (every one is
   `runner-`), and the toc unwritten for 8min while runners beaconed continuously. Re-check the rows
    after the next editor session.
 **The transient that caused it cannot recur**: the advertise gate and the `player:1` marker live in
  the same file, so a build either doesn't advertise while humdinger (old) or advertises WITH the flag
   (new). Only a mid-edit HMR could produce the gap, and only once.

**THE CLI HALF LANDED AND IS PROVEN BOTH WAYS (same evening).** `runner_ask.mjs` gained
 `--player=<id>`: explicit only — no bare form, no latest-fallback, refuses alongside `--runner=` —
  because picking someone's music tab by accident is the exact mistake the role split exists to
   prevent. An allow-list refuses `run`/`accept`/`release`/`declare` and names them; `reload` IS
    permitted on purpose, being the one mutating verb with real diagnostic value (reproduce a one-sided
     reload) at the cost of a moment of the human's music. **Verified live**: `ping --player=f5da6599`
      answered from heron (`self:"f5da6599b8505881"` — the first time a Sounditron has ever been
       addressed from this container), `dump --player=` forced a 236-mark trace on demand, and
        `run --player=` refused. The blindness is over: the tabs that reproduce the bugs are now
         self-serve for ping / probe / world / dump / poke / reload.

**Still owed:** mutation-test the EDITOR-side exclusion ([[mutation-test-every-claim]]) — aim a Book at
 a `player` row from the editor UI and SEE it refuse. The CLI refusal is proven; the editor's rests on
  a grep for `role === 'runner'` being exhaustive, which is an argument, not a red test.

## 4. Open, grouped by where the work is

**4.1 The startup wait.** Boot electrode with phase timings first; the era-confirm ladder
 (`5000 * 2^kicks`, capped 60s, reset on confirm at `Swarm.g:820`) is ~15s worst case and does not
  account for what the human sees. Do not guess at this one.

> **First measurement (2026-08-06, one Sounditron run on a peerless runner tab).** Step 7's own snap
>  said it: `Session,alive=41,possibilities=0`. The arithmetic closes exactly — 15s `stoker_wait`
>   timeout + 20s `peer_wait` timeout + 6s `sound_wait` timeout = 41s, with `relay_wait` settling
>    instantly. So on a world with **nothing to find, every ceiling is consumed in full, serially,
>     silently** — a timeout is "graceful", so it never complains, and the boot cost is Σ(ceilings)
>      by construction. Three realisations for whoever picks this up:
>  1. **The waits need a third state: settled-by-absence.** Each `Sounditron_await` truth-fn answers
>      "true yet?" but never "could this EVER come true here?" Zero sealed `%Pier` rows and no runner
>       lease ⇒ `peer_wait`'s 20s cannot be won — settle at once with an honest note. The stoker
>        comment CLAIMS an at-rest stoker settles early; the 15s burn on this run says that
>         absent-branch is not firing (suspect: shareless runner leaves `st.sc.stock` null without
>          the stoker ever classifying itself spent/idle). Two of the six waits have already had this
>           exact bug (the old `stock==null` 30s burn; `peer_live` reading a Lies lease so it timed
>            out EVERY run) — a wrong truth-fn costs its full ceiling on every boot forever, and
>             nothing catches it. That is §2.1's untested-net shape wearing a countdown.
>  2. **The electrode is nearly free: `Sounditron_await` already knows everything.** It holds the
>      label, the start time, and the met/timed-out outcome — it stamps them into the Beat HUD and
>       throws them away. Ten lines: append `{beat, label, ms, met}` to a `w.c.boot_ledger` (`.c`,
>        never snapped) and mirror it as a `Radio_trace` `ev:'boot'` mark, and every future run
>         carries its own phase breakdown, readable via `runner_ask world`. Do this BEFORE touching
>          any wait, then re-measure the real two-tab boot — the live case (peer present) should
>           settle early on every rung, so whatever the human still feels is a wrong truth-fn, and
>            the ledger will name it.
>  3. **The greeting is already event-driven** (`Swarm_hi_all` rides every (re)connect behind the
>      hello-bind, `Swarm.g:655`); the 5s→60s kick ladder is only the backstop for a LOST first
>       contact. So do not start by tuning the ladder — measure first; the ladder shows up in the
>        ledger as a peer_wait that settles at ~5s/10s rather than sub-second.

**4.2 One-sided reload** (`Cluster_spec` heading 8, era-scoped seqs). The single change that would
 most improve the *iteration* loop rather than the product.

**4.3 The CPU.** Two real finds have landed — `o_query`'s O(M²) filter (§1 #5, reviewed and approved by
 the human) and the PCM decode livelock (§3.12), which was the larger of the two by a wide margin.
  Whether anything material remains is now unknown rather than assumed; the `deliver` electrode will
   say, and it stays silent when healthy so its own output cannot drown the 300-mark ring. **`Stuff`/
    `Housing` are the stable end — changes there need evidence and an explicit look, not a plausible
     reading.**

**4.4 The overrunning share beat.** §3.7 removed the two phases that dominated it in the one paste we
 have. What the residual is has **not** been measured since — likely a composite of 4.3, 4.6 and 4.7.
  It is the thing the Grind Book asserts on, so it gets measured either way.

**4.5 Reqs dropped under in-flight continuations.** The `reqyonciliation` warn. Ask whether a
 continuation should hold its target alive, or whether the drop should cancel the continuation.

**4.6 The `ive_got` duplicate storm.** Two live leads, since retransmits are ruled out: the relay's
 fan-out, and `Swarm_gossip_music` firing on **every** `swarm_hi` (`Swarm_hi_hear`) unthrottled.
  *Tried and backed out 2026-08-06:* adding `ive_got` to `Peeroleum_deliver`'s receive-side bypass —
   `SwarmGot` went 0.33 while its three sibling Books stayed green, which is past the fixture drift
    that move alone explains. Note left at the site. Settle whether that Book asserts on the boast
     being **booked** or being **delivered** before trying again. **See also §3.12's unresolved `×2`** —
      a relay bind that delivers twice would explain both, and neither can be settled without reading
       the relay's live bind table.

**4.7 Vyto never settling.** A cell whose `disp`/`drift` stays pinned, so the watchdog force-settles
 every 240 frames and the glass renders continuously. Cause is §3.5; no fix has shipped. Independent of
  the wire; belongs with the Vyto docs but is listed here because it is a load-bearing share of the 100%.

**4.8 A starved radio should self-heal** — dial what it holds instead of raising a badge. *"It should
 just work out somehow"* is the correct specification. §3.9 item 2 deliberately left the lead pass
  ungated for exactly this reason: a disclaimed *playing* record wants the radio to move on, which is
   this item's job, not a want gate's.

---

## 5. Where things live

- **`Backpressure_todo`** — the transfer control loop: the three clocks, the req refactor, the
   measured RTO, §3.1b/c/d/e's defects, and `MusuNeGrind`'s payload rung. Anything about *how the pull
    is paced* goes there, not here.
- **`Supervisor_todo`** — the runtime half of §0's arc: noticing a wedge while it happens and naming
   the organ. `beat_split` is the substrate both docs read.
- **`Cluster_spec`** — relay, boot→channel map, the Brink ladder, the epoch handshake (§4.2).
- **`Radio_todo`** — the dial, the glass, the Vyto cell trims (§4.8's home once specified).
- **`history/Composition_closed_2026-08.md`** — the full-length write-ups of §3.7, §3.8, §3.9 and
   §3.12, verbatim, with every console paste. Go there for the evidence behind a compressed lesson.
- **here** — the symptom ledger, the pattern (§2), and anything that is nobody's mechanism because
   it is everybody's.

*This is a `_todo`, not a `_spec`, and should stay one until the human reads and preens it.*
