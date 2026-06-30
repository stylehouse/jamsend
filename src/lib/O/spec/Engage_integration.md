# Engage_integration.md — the editor half of the runner-engagement layer

A hand-off **to the agent who owns the Lies/editor machine**, from the Peeroleum/runner arc.
The runner side + the CLI side of an "editor reserves a runner for a client, that client drives it
 offline" scheme are BUILT (type-clean, :9091-unverified). Three pieces remain, and they all land in
  the editor — the dispatch path, the roster Brink, and StoryTimes. This is the integration thinking
   I'd rather get right with you than bolt on as a sidearm to Peeroleum. Context in
    [Cluster_spec.md](Cluster_spec.md) (§3.2 `to:<pub>`, §7 build order step 2, §8 open decisions);
     the runner/CLI build is logged in the `clustation-identity-layer` memory.

## A. The seam in one breath

GRID layer (Auto: `?I=`→identity→advertise→hold channel) ⟂ LangLies (Lies+Lang: receive
 `become_book`/`rungo` → run Story → `run_result`). The engagement layer rides **above** the Story
  world, as particles on **Mundo** (children of `top_House()`, so they outlive a Story_reset — only the
   `H:Story` world is rebuilt) — a hang-up tears the Story world down to `H:Mundo` and the runner's
    *representation* (identity, favourite_client, lease) survives. Two things travel the seam today
     (work-in, verdict-out); this layer adds a third concern — **who may drive a given runner right
      now** — and it wants editor-side teeth.

## B. What's already BUILT (the contract you integrate to)

*Live-verified 2026-06-30: the full lifecycle ran green against a real `:9091` runner over `runner_ask`
 — engage→run→state→refuse-other-client→release→GC'd-run error→idle.*

Runner-side, all in `LiesFunk.svelte`:
- **The lease** = a singular **`Engagement` particle on Mundo** — `top/Engagement,client,status,at,of_Book`
   (`of_Book` follows the `of_$k` convention: a property naming a thing of another C-type than its host).
    It's **visible in the snap, not hidden on `.c`** — the whole point is that whose-runner-this-is is
     observable. `status` ∈ `active|released`, with `timed_out` folded in **lazily** at read time (no
      timer — an `active` lease older than the TTL *reads as* `timed_out`). TTL = **10 min**
       (`Lies_engage_ttl`, the think-between-runs window).
- **Loose & exclusive.** Exclusive by *others knowing whose a runner is* (the favourite_client/registry
   below + this `Engagement` record), NOT a hard lock — easy to break out of, a new client takes over
    after the timeout, and the durable truth we examine is the **completed run objects** (`Storyrun`
     records), not the lease. Whatever orchestrates many runners deals with contention; I'm not expecting
      trouble at this looseness. App-level only — no relay arbitration.
     Methods: `Lies_engagement` (898), `_check` (911, refuse if ANOTHER client's lease is live),
      `_engage` (921, stamp + GC the prior client's runs on client-change), `_touch` (931, any op from
       the holder refreshes the clock), `_release` (938, mark released + GC + quitStory), `_engage_gc`
        (949, drop the `Storyrun` records + their pins, record who triggered it). *(`last_gc` stays a
         transient `.c` breadcrumb — diagnostic, not lease state.)*
- **The runner_ask wiring** (`Lies_runner_ask_recv`, 741): `client = ask.client ?? header.from`; touch
   at the top of every op (753); `run` engages and **refuses-if-busy** (770-774); a `release` op (781);
    `ping`/`state` report `engagement` + `favourite_client` (761, 788); `@uid` on a reaped run reads
     `last_gc` to say "garbage-collected by `<who>` `<age>` ago", not a bare miss.
- **`favourite_client`** = a sticky SOFT prefer ("this runner is Claude's"), a client pub. The beacon
   plumbing is live — it rides the advertise frame (`Lies_advertise`, LiesLies:831/839) → editor captures
    it onto the roster (`Lies_advertise_recv`, LiesLies:846). **But its home is wrong and the SET-path is
     the gap:** the built code reads `top.c.favourite_client` (a `.c` blob, nothing writes it yet); the
      design (C1) moves it to a `Waft:Cluster`/`%HostedIdentity` registry entry.
- **Clean hang-up** (`Auto.svelte`): `auto_teardown_story()` + a `quitStory` elvis — IDLE teardown to
   `H:Mundo`, no rebuild (unlike `resetStory`, which reruns on a `?B=` runner that still has `H.c.book`).

CLI-side (`scripts/runner_ask.mjs`): sends a STABLE `ask.client` (the claude cluster prepub from
 `.env.cluster-claude`, or `RUNNER_CLIENT`), so "was it you?" answers and we re-attach to our own held
  runner; `release` op; refuse/GC reasons surface on stderr. **The CLI needs none of the editor work
   below** — it's a raw relay client and just sets `header.to`. This brief is entirely the editor's half.

## C. The three editor-side pieces

### C1. `favourite_client` — stable tab↔Story affinity, in `Waft:Cluster`

NOT a Thang, and NOT on `%Identity`/`%Peering`. It lives on the identity's **representation in
 `Waft:Cluster`** — the registry that tracks *all known objects* (claude, the editor, every runner),
  each a `%HostedIdentity,<pub>` entry that **auto-vivifies** on first reference. `favourite_client` is
   a property there (a client pub); `%HostedIdentity,favourite_client` is how claude and the editor look
    up whose-pub-is-whose. Its whole purpose is small and concrete: **the same tab runs the same Story
     every time** — a sticky tab↔Story affinity — so the allocator and the CLI keep returning to their
      own runner. Standing up that registry is the bit more for you to do in the Lies/editor machine.

**What `Waft:Cluster` IS — the shape (the spec never names it, so it confuses):**
- **`%equip` is a real, BUILT mechanism — `Keep` and `Cluster` are THE two `%equip` Wafts.** `equip:'<name>'`
   (an sc key, `Lies.svelte`) = a *backstage fixture*: out of the cursor's way, never a focus candidate, no
    nib, its guts fold from the snap, and **background-never-steals-foreground** (the boomerang focus arbiter
     skips `%equip` Wafts — `Lies.svelte:1052/1072`). `Lies_keep` stamps `equip:'Keep'`; `Lies_aim` already
      stamps `equip:'Cluster'` (`LiesFunk:345`). Both are `/*` containers — directories of children. So
       "Keep + Cluster, `/*`, `%equip`" is the EXISTING design, just never written down.
- **`Waft:Cluster/*` holds `%HostedIdentity,<pub>`** — one per identity ANY node knows (its own + everyone
   it's heard of): what a runner / editor / claude **claims to be**, and the directory peers **find each
    other through**. (Beside the `%Aim` already living there.)
- **`%HostedIdentity` is NOT a dontSnap mirror of the `%Runner` beacon roster** — but right now
   (`LiesLies:879`, `oai({HostedIdentity:from},{dontSnap:1})` rebuilt each advertise) it's wired exactly that
    way, which makes it a redundant copy of `%Runner`. That collapse is almost certainly the confusion. The
     intended split:
  - **`%Runner`** = *live presence* — dontSnap, rebuilt from beacons: who's advertising NOW + ready/book/
     last_heard. Keep as-is.
  - **`%HostedIdentity`** = the *persistent directory* — WHO EXISTS + their sticky facts (identity, friendly,
     **favourite_client**), independent of whether they're advertising this second. This is what makes
      `favourite_client` survive a reload ("same tab runs the same Story") and what lets a node be found when
       it's off the beacon. The two are complementary — **join** them at the Brink (HostedIdentity = who;
        `%Runner` = live-now).
- **`favourite_client` is therefore a DURABLE field on the runner's `%HostedIdentity`** (valued = the client
   pub it's reserved for; `Lies_favoured_runner` already reads "which HostedIdentity favours me"). Its SET is
    someone WRITING that durable entry — the editor blessing a runner, or the runner self-claiming — **not**
     the `top.c.favourite_client → beacon → dontSnap-mirror` path, which never gets set (the original gap, and
      it *stays* a gap while HostedIdentity is only the beacon copy). Dexie backs the write durable
       (`%Identity` in Dexie → `%HostedIdentity` the in-tree representation).
- **The dontSnap-vs-persist split (the "split the cluster Waft" wrinkle):** `Waft:Cluster` carries transient
   bits (the `%Aim`, UI open-state — dontSnap) AND now wants durable bits (the directory + sticky prefs). They
    can't share one `dontSnap` flag — split it: the directory persists (snaps / rides Dexie), the live overlay
     stays dontSnap.

- **Rewire the source:** the advertise beacon already carries `favourite_client` (`Lies_advertise`,
   LiesLies:839) → roster (`Lies_advertise_recv`, :859). Point its source at the runner's own
    `Waft:Cluster` HostedIdentity entry, not `top.c.favourite_client`, once that registry exists.
- **OPEN — the SET mechanism & whose pub.** Does the editor record "this runner is claude's" straight
   into its `Waft:Cluster` registry (runner reads/advertises its own), or push a frame to the runner?
    And where does the editor learn the claude pub — `.env.cluster-pubs`, a picker over known
     HostedIdentities, or free text? Both are registry-design calls that are yours. *(If SET is a
      direct-to-one-runner frame it inherits C2's `to:<prepub>`; if it's a local registry record it
       sidesteps C2 — turns on where you put `Waft:Cluster`'s truth.)* A natural gesture surface, if you
        do want a frame: the multiplied Runner Brink (`LiesFunk Lies_aim` 392-406, one
         `Lens:Brink,of_Funkcion:Runner,pub:<X>` per roster entry; `Funk/Runner.svelte` renders it).
- The runner-side stamp/read against its HostedIdentity is small and mine to add once the registry shape
   is set.

**Registry design notes (owner's, for whoever builds it):**
- The many **`%Identity`** persist in **Dexie** (the Thangs ghost); it's the **Lies protocol** that brings
   on **`%HostedIdentity`** to track them *somewhere* in-tree (`Waft:Cluster`). Dexie = the wider store,
    `%HostedIdentity` = the tracked representation.
- **Uniqueness / fatal-on-duplicate:** probably get **fatal if a second instance of one identity comes
   online while the first is still contactable** (don't let two tabs *be* the same identity live). Watch
    the **startup-latency** cost of that contactability probe — don't pay a relay round-trip on every boot.
- **Dexie `liveQuery` coordinates same-profile tabs** (the ones separated only by `?I=`): they share one
   Dexie db, so a `liveQuery` reacts across them via Dexie's own cross-tab channel — **no relay**. So the
    duplicate check is *local & instant* for same-profile dupes (LiveQuery), and only cross-machine dupes
     need the slower relay path — which is how the latency worry above mostly dissolves.
- **Pier pooling** is a follow-up at the **visual-extravaganza end** (the grid view of who's pooled with
   whom), not a blocker for the registry itself.

### C2. `to:<prepub>` dispatch — the per-Pier multiplication (the load-bearing one)

`Peeroleum_send_consumer` (gen `N/Peeroleum.go:240`, source `Peeroleum.g`) is **hardwired to ONE
 Pier**: `w.o({Peering:1})[0]?.o({Pier:1})[0]`, addresses `to: pier.sc.pub`, allocates *that* Pier's
  `Pier_next_seq`. Every editor→runner emit (become_book, rungo, ghost_compile, ping…) rides it, so the
   editor can talk to exactly one bridged runner.

The relay ALREADY routes `to:<prepub>` (Cluster_spec §3.2, BUILT 2026-06-29, proven in `relay-test.ts`:
 verified-hello binds `prepubOf(pub)`→socket). The **missing half is editor-side**, and it's the real
  design work:
- **Roster ≠ Piers.** The `%Runner` roster is N entries (advertise is role-broadcast — every runner→the
   one editor, no Pier needed to *hear* it). A Pier is a *handshaken* peer (hello+trust, its own
    seq/inseq). To SEND work to a specific runner you need a Pier with it. So: **promote a roster entry
     to a Pier on demand** (handshake when you first engage/dispatch) vs **eagerly handshake every
      advertised runner**? Lazy-promote is my instinct (cheap roster, Piers only for runners you drive).
- **The send variant:** a `Peeroleum_send_to(w, prepub, type, body)` that selects (or mints) the Pier
   whose pub matches, instead of `[0]`. `become_book` then carries the runner address.
- **inseq fan-out:** N Piers = N inbound seq cursors. The cold-cursor baseline bug
   (`inseq-reload-baseline` memory: a fresh inbound cursor gap-buffers a continuing far seq forever) now
    multiplies — each promoted Pier needs the baseline-adoption path. Worth a hard look before N>1.
- **`Lies_runner_count`** (LiesFunk:1304) counts Piers under the first Peering — once Piers multiply it
   becomes the true fleet size that StoryTimes reads.

### C3. StoryTimes parallel — fan the sweep across the fleet

Today `Lies_storytimes_width` (LiesFunk:1313) is `min(runner_count, ADDRESSABLE=1)` — capped at 1
 because a become_book is a single-address broadcast (firing two resets the one runner mid-run). The
  comment at the cap already states the lift: **once the frame carries a runner address, raise
   `ADDRESSABLE` to `Lies_runner_count(w)` and the same driver (`Lies_storytimes_dispatch`, 1291) fans
    out.** The remaining editor design:
- **Allocator:** pick a FREE runner per queued Book — skip runners busy under another client's lease,
   prefer your own/favourited. The lease is enforced runner-SIDE on `run`; should advertise ALSO carry
    the current `engagement` so the editor's allocator sees busy runners without a round-trip? (`ping`
     already returns it; the beacon could too — cheap, and it makes the allocator local.)
- **`inflight` keyed per-runner** (it's a flat list now), so two Books on two runners don't read as one
   runner double-booked.
- **Verdict correlation:** `run_result` carries `book` but, with N runners, which runner answered? The
   promoted Pier supplies the `from`; the sweep needs to match verdict→(runner,book).

## D. The load-bearing insight — order

**C3 (and any direct-to-a-runner control) sits on C2.** Fanning a sweep across the fleet, and the run
 dispatch + lease that ride with it, all address one specific runner → they need `to:<prepub>`. **C1 is
  separate** — a `Waft:Cluster` registry fact that may not need a direct frame at all (your call on where
   the registry's truth lives). So the editor critical path is:

1. **C2 first** — `Peeroleum_send_to` + roster→Pier promotion + per-Pier inseq baseline. This *is* the
    editor half of Cluster_spec §7 step 2 ("two tabs/two identities address each other"); it unlocks
     remote `%Rungo` to a *chosen* runner.
2. **C3** is then a width bump (`ADDRESSABLE` 1→`runner_count`) + an allocator that reads the roster /
    `Waft:Cluster` (lease-aware if advertise carries the engagement).
3. **C1** runs in parallel — `Waft:Cluster`/`%HostedIdentity` registry work, independent of the Pier
    plumbing; the runner-side stamp is mine once you've shaped the registry.

Doing C2 well — especially the inseq-per-Pier baseline — is the whole ballgame.

## E. Decisions — settled this round, and still-open

**Settled by the owner:**
- **Ownership = loose exclusive, app-level.** Exclusive by *visibility* (favourite_client + the
   `Engagement` record let others know whose a runner is), not a hard lock — easy to break out of, a new
    client after timeout, the completed `Storyrun` objects are the durable truth, the orchestrator
     handles contention. No relay arbitration (matches Cluster_spec §3.5's lean). Nothing arbitrates a
      simultaneous cross-editor double-engage today (the runner takes whoever's `run` lands first) — fine
       at this looseness.
- **favourite_client home = `Waft:Cluster`/`%HostedIdentity`** (auto-vivifying registry of all known
   objects), not `%Identity`/`%Peering`/a Thang. Purpose = stable tab↔Story affinity.
- **Engagement is a particle** (`top/Engagement`, snapped/visible), not a hidden `.c` blob.

**Still open (yours):**
- **Advertise carries engagement?** (C3 allocator) — cheap; lets the editor's allocator read busy-ness
   locally instead of round-tripping `ping`.
- **`Waft:Cluster` SET mechanism** (C1) — local registry record vs a frame to the runner; and the
   claude-pub source.
- **roster→Pier promotion** (C2) — lazy (on first dispatch) vs eager (handshake every advertised runner).

## F. What I'll do with your clues

Happy to build C1/C2/C3 myself once the shapes above are settled — the runner-side stamp/read against
 its `Waft:Cluster` HostedIdentity, the `Peeroleum_send_to` variant, the width lift — they're small
  against a clear seam. (The engagement particle itself, §B, is already flipped runner-side.) What I
   don't want is to guess the Pier-promotion / inseq-baseline design or the `Waft:Cluster` registry shape
    solo and have it fight the editor machine you own. Point me at the bits you want to keep, and I'll
     fold to them.
