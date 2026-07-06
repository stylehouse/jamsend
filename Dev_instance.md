# Dev_instance.md — the autonomous sandbox brief

You are (maybe) running in the **dev instance**: an isolated copy of this repo on a separate machine,
 dockers-app + Claude, where the point is to *develop autonomously* on branches. The human runs the real
  **Radio app construction site** elsewhere and **pulls mature branches** from here when they're green.

> **Am I actually in the sandbox?** This relaxation is in effect ONLY if a `.dev-instance` marker file exists
> at the repo root (the human drops it here, gitignored, so it never travels to the construction site) **or**
> the human told you so in this session. If neither is true, you are in the construction site — **ignore this
> file and follow `CLAUDE.md`'s "never commit" rule.** When in doubt, ask; do not assume.

## The one rule that changes here: you may commit

In the sandbox, `CLAUDE.md`'s "never stage/commit/push" rule is **relaxed** — because the human's review gate
 has *moved from commit-time to pull-time*. Concretely:
- **Commit freely on feature branches.** One branch per lever/feature (`perf/dige-gate-organise`,
   `perf/gallop-tighten`, …). Branches are the unit of "a mature feature the human can pull."
- **Keep branches independently pullable** — don't stack unrelated work on one branch; the human cherry-picks.
- **Never merge into / push the construction site's `main` yourself.** The pull is the human's gate. You own
   the branch; they own the merge.
- Commit messages: normal discipline, end with the `Co-Authored-By: Claude …` trailer per `CLAUDE.md`.
- Everything else in `CLAUDE.md` still holds (the data model, the ghost machinery, the verify-live rule below).

## The setup this assumes (the cheap path, not the built one)

The runner-fleet infra (`Cluster_spec.md` §3.4 restart service / host-exec socket) is the *robust* answer to
 "keep a headless runner alive." The sandbox skips it with two crude stand-ins the human operates:
- **Editor + runner both run here** (Chrome on this box, :9092 editor / :9091 runner), the runner joining the
   editor's cluster over `/relay` exactly as a remote runner would.
- **FSA is granted to the runner by hand, occasionally.** The human ssh/VNCs in and clicks *Allow* on the
   share when needed — so the fragile FSA handle problem (§3.4) is solved by "a human is reachable sometimes,"
    not by building the network Wormhole backend.
- **A "reload every ~30 min" Chrome extension** periodically reloads the runner tab to shake out wedged
   tab-state — the dumb stand-in for the Mode-4 human-reload (`runner_ask` has no reload op) and the §3.4
    restart service. Coarse, but "regularly enough."

## Standing it up on one box (the self-contained recipe)

Editor + runner on ONE dev server, no r2r bridge to staging — the singular-role clean case (one editor, one
 runner, one relay). Checklist, in order:

1. **Free `172.17.0.1:9091` — an SSH tunnel squats it, not a docker.** `ty/jamsend-dev-ssh-tunnel.service`
    (`ssh -N -R 172.17.0.1:9091:172.17.0.1:9091 wi`) is a **`systemctl --user`** unit — so it's invisible to the
     *system* `systemctl status` (that "could not be found" is the tell); find it under `systemctl --user
      status`. It exposes dev across to `wi`/prod and collides with docker-compose.yml's `- "172.17.0.1:9091:9091"`
       publish. Either **`systemctl --user stop/disable jamsend-dev-ssh-tunnel`**, or keep it and **publish dev
        on `127.0.0.1:9091` only** (comment the `172.17.0.1:9091:9091` line) — a same-origin local editor+runner
         only need localhost, and localhost is a secure context so WebRTC is happy.
2. **Two same-origin tabs → give them distinct `?I=<tag>`.** Collapsing to one server means editor (`?E=`) and
    runner (`?B=`) share the origin, hence the **Dexie `.stashed` store**. Distinct `?I=` tags key distinct
     identities out of that shared store; reuse one (or let both default) and they mint two peers on the *same*
      prepub → relay bind collision, last-hello-wins, the other goes dark (the `${prepub}_2` open case,
       `Cluster_spec.md` §3.2a). They also share Keep/registry state — usually fine, just know it.
3. **Grant the runner its own FSA** (the manual click) → `needsFSA` Books run locally with no wormhole proxy,
    since both tabs see the same `wormhole/**`.
4. **Cluster trust:** the editor self-provisions (🪪 *Set up cluster trust* → `Lies_cluster_setup`), or the
    relay warn-and-allows un-minted — either is fine for a sandbox.
5. **Music mount** (`jamsend-mount-verify`): `/music` must actually bind-mount, or real-audio Books (MusuReco &
    friends) go red. The perf/engallop levers need no `/music`, so this can wait — but fix it before you run the
     full fleet to prove a gallop change.

## Verification still comes from a LIVE runner — headless is still banned

`[[verify-via-live-runner]]` holds unchanged: `scripts/runner_ask.mjs` against the live :9091 runner is the
 gate; the headless Story_cli is BANNED (false greens). The periodic-reload harness + the already-shipped
  send-side retry-climb (`[[reconnect-epoch-seq-collision]]`) are what make *unattended* verification viable.
   Operate it with these caveats:
- **Reload between runs, not during.** A reload mid-good-run loses it — just re-dispatch. If you can, run the
   Book fleet in a window you expect to be reload-free, or accept the occasional lost run and retry.
- **After any reload, wait ~10 s before trusting `runner_ask`.** A reload restarts the runner's per-Pier seq
   low → a ~4-8 s mute while the retry-climb self-heals (`[[reconnect-epoch-seq-collision]]`). `ping` first;
    treat an immediate red right after a reload as the hiccup, not a failure.
- **A tab that wedges early wastes up to the reload interval.** If that bites, shorten the interval or (later)
   wire a `ping`-fail-triggered reload — the first real slice of the §3.4 restart service.

## The thing to do: engallop

The headline work this instance exists for is **making the Lies|Lang shakeout fast** — "the engallop."
- **Design:** `src/lib/O/spec/Story_future_directions.md` §3 — Technique A (gallop-tighten: drain the 50 ms
   gate greedy when the todo is deep+sustained, causality-agnostic), Technique B (finish→re-pump the upper
    `req**` on inner-finish, poll→event, killing §4's per-level 150 ms), and the **snap-tension reconciliation**
     (quiescence is a trailing-edge timeout, so tightening moves the snap *earlier, not different*).
- **Causal map + levers:** `src/lib/O/spec/Perf_todo.md` (the six layers; levers 1-2 done, 3/4/6 open, 5 = the
   engallop).
- **Measure:** `scripts/reactap.mjs` gives before/after (bump churn; a todo-depth sibling is the gallop
   detector) — autonomy needs "did it help" to be a *number*, and this is it.

**Scoping order (do NOT open with the belief-loop surgery):**
0. **Prove the harness.** Confirm the periodic reload + `runner_ask` survive a reload and you can run a Book
    unattended end-to-end. Until this works, everything downstream is theatre.
1. **Shake down the branch→commit→verify loop on a LOW-RISK lever first** — Perf lever #4 (dige-gate
    `organise`/`attend`) or #6 (digest-gate `Lang_build_mapules`). Real speedup, **no belief-loop semantics
     touched**, clean before/after. Prove you can branch → commit → verify-live → leave-for-pull on something
      that can't brick a runner.
2. **Then the gallop** — Technique A, then B, each its own branch, each proved against the **whole Book fleet**
    (Lake*/Musu*/Pere*/Swarm*) on the live runner. A gallop change touches *every* Book's settle, so "green"
     means the fleet is green, not one Book.

## Load-bearing cautions (a gallop change can brick every Book)

- **The belief loop is core.** `[[fight-back-on-core-changes]]`: prove each change in ISOLATION first; a
   tentative idea is not a mandate to charge into `answer_calls`/`do()`/ttlilt.
- **Read `src/lib/O/spec/Coding_guide.md`** before touching the loop — wake ≠ hold, the ttlilt rules, the
   all-holds compile→rerun chain, "verify a timing fix by re-running."
- **The ttlilt/snap coupling is load-bearing** (`[[ttlilt-in-snap-means-timeout]]`, `[[ttlilt-not-a-keepalive]]`).
   The reconciliation in §3 shows step-snaps stay safe, but this is prove-in-isolation territory, not a casual
    edit. Gate the tightening per designated-system (opt-in), never globally in one leap.
- **Re-run the full fleet to claim no regression.** That's the whole reason this instance wants "heaps of
   testing" — and the same appetite that motivates the distributed-Story conductor + coverage meter
    (`Cluster_spec.md` §5/§6). The engallop and the flock pull the same rope.
