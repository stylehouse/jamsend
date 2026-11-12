# Reaching a live tab — arm it, then read it or send it verbs

## 0. What to know first

A music page (`/Radio`, `/`) is **invisible to every tool until it is diagnostic-armed**.  Arming is the owner's consent, and it is
 the ONLY switch: there is no second option that "lets you command it" (asked 2026-11-12, after 855f stayed silent).
  `Lies_player_seen` (LiesLies.svelte) joins a humdinger tab to the diagnostic channel only when `socklog_armed()` (sockcap.ts) — or
   it has already captured relay traffic.  An unarmed tab answers nothing: not `ping`, not `minisnap`, not a verb.

**Arm it** — any one of:
- open it once with `&socklog` on the URL: `https://djamsend.duckdns.org:9999/Radio?I=<pub>&socklog` — this WRITES the arm (since
   2026-11-12; before, the URL only installed the tap and an Incognito/fresh profile stayed unreachable).  `&socklog=0|-1|off` disarms.
- in its DevTools: `localStorage.setItem('socklog','1')`, then reload
- from here, once it is ALREADY armed: `node scripts/runner_ask.mjs socklog on --player=<pub>` (keeps it armed across reloads)

**Then, from this container** (default `RUNNER_URL`; djamsend is Caddy in front of THIS box, not remote):
- `ping --player=<pub>` — alive?  `world --player=<pub>` — friends, routes, the supply trace, and the `🚰 drain` line (Mundo's queue,
   gate, mutex holder, last drain — the first look when a tab looks frozen)
- `minisnap '<root>>step' --player=<pub>` — roots `mundo|radio|story|self`; e.g. `radio>Mine>shop` (Heists), `radio>Answers`
   (what this tab told friends' folder asks), `self>Mag:heard`
- `console --player=<pub> --tail=N --grep=PAT` — its raw console ring; `⏮ last life` lines say why it last reloaded
- `verbs --player=<pub>` lists the controls its loaded ghosts offer; run one from the hole as `:verb args` (spec/Verbs_todo.md).
   A verb that `writes` is refused on a music page by design.  `poke <Verb> --player=` fires an allowlisted no-argument UI button.

**What an armed tab still will not do:** run a Book (it joins as `role:'player'`; every dispatcher filters on `runner`), or take a
 write verb.  It becomes VISIBLE, not dispatchable.

## 1. Addressing

`--player=` matches the tab's **identity** (its `self`, the prepub).  The census (`runners --live`) prints the tab's **relay address**,
 which can differ (a second tab of one soul stands at `<pub>_NNNN`; a sibling body at its own name).  If a census row will not
  answer `--player=<that row>`, ask it AT its address with **`--player=<row> --direct`** (skips the slot and the pub match; read-only ops
    only).  2026-11-12: the two "mystery" census rows 884fc599 / 4e5de1dd answered that way — `Identity:shape` tabs (gilded-fern,
     storm-ray), not music pages.  A `--direct` ask that only gets "acked the court then answered nothing" hit the tab's Swarm STATION
      socket: its Lies channel is not up, armed or not.

## 2. Traps (each cost the owner a re-grant of every folder)

- **`npx svelte-check` reloads every tab** — it rewrites `.svelte-kit/generated`, Vite full-reloads, and each music tab must be
   re-granted its folder by hand.  Don't run it while tabs are up.  `.g` compiles (LocalGen) and `src/lib/O/ui/*` face saves do not.
- A reloaded tab forgets `.c` state (its ask counters, the QR it was showing) — expected, not a fault.
- A tab with no AudioContext (never clicked) cannot render the small copies it serves its friends' pools.

## 3. Owed

- One `reach` verb that tells "unarmed" from "gone" from "different identity", instead of three silent timeouts.
- The service worker's `network_first` failing a document fetch (`/?I=855f…`, 2026-11-12) — a PWA fault that reloads the tab.
