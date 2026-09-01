# Statehome_todo — where a datum lives, and why

*A chapter of the Phenomenology, regarding the computer.* Commissioned by the owner 2026-08-31:
 *"what Hegel particles do `.c` and `.sc` refer to… make excerpts from another chapter for the Phenomenology
  regarding the computer, to explain why we put what where"* — and *"there should be a LOT of `.oa(blah)`
   rather than `.c.blah`."* The point is not decoration: the placement rules should FOLLOW from what these
    substances ARE, not be decided case-by-case by taste. This is the grounding every `.c`-vs-particle call
     should be read back against.

---

## The Two Substances of a Datum, and the Truth that is Standing

**§1 — Two ways of being.** A datum in the C-tree has two modes. It can be **for-itself** — held in the
 running instance's private interior, meaning something only in this instant, to this one body, vanishing when
  the tab closes: this is **`.c`**. Or it can be **for-the-community** — encoded, snapped, carried on the wire,
   read by the mesh and Cyto and the daemon's `/c`, asserted by a Book, rewritten by a hand that never met this
    instance: this is **`.sc`**, the child particle. The first is the runtime's inwardness; the second is its
     speech.

**§2 — What counts as true differs.** In `.c`, truth is **assignment**: `x = 1`, and the instance believes it
 because it wrote it. In `.sc`, truth is **standing**: the child *is* in the tree, and everyone who walks the
  tree finds it there — truth is not a value held but a presence witnessed. The **snap is the moment of
   recognition**: a datum becomes true-for-the-group by showing itself in the serialisation. What never shows
    itself was never recognised — it was only ever believed, privately, by one body, now gone.

**§3 — The sin the owner keeps catching.** To write `top.c.disk_gated = 1` is to take a *fact about the world*
 — a folder is wanted — and imprison it in one instance's interior, where no snap, no mesh, no Book can see it.
  A fact that WANTS recognition, denied it. The "6th mirror," the "big fat system," the state that "drifts
   unchecked" are one disease: **a for-the-community datum living a for-itself life.** The ferry was invisible
    for a year because its whole self lived on `.c`.

**§4 — The passage out is the `oa`.** A boolean does not want to be a *value*; it wants to be a **presence**.
 `n.oa({want:'open-share'})` asks not "what is the value of `want`" but "does the community find such a child
  standing here" — and the answer is the child's existence: unambiguous, snapped, un-mungeable. This is why the
   snapped boolean is **1-or-absent, never false/0** (CLAUDE.md): a boolean-as-value munges (a flat `dim:false`
    one tick, a JSON `{"dim":false}` the next — the night in which all cows are black); a boolean-as-standing
     cannot, because a thing either stands in the tree or it does not. **So: a LOT of `.oa(blah)`, little
      `.c.blah`. Truth is standing.**

**§5 — What genuinely belongs to interiority.** Not everything can face the community without ceasing to be
 itself. These are not *hidden state* — they are the runtime's **flesh**, and flesh does not snap:
- **The secret** (`req.c.secret`): a secret that shows itself is spent. Recognition would betray it. For-itself
   by its very concept.
- **The finger, not the thing** (`top.c.ferry_world`, `source_n`, `.c.up`, `req.c.pending = {frame}`): a
   *reference* to a particle is not the particle; the world it points at is snapped, the pointing is not. An
    object in `.sc` is fatal at encode — because you cannot *speak a gesture*.
- **The organ** (the ws handle, the AudioContext, the CryptoKey, `w.c.on[kind] = hear`): a live socket, a
   decoder, a function. A verb is a *doing*, not a *said*; it cannot stand in a tree.
- **The vanishing** (poll counters, reconnect backoff, `link_unlive_at`): a mid-count that means nothing
   between two ticks. Time's own interior, not a fact worth recognising.

The line is therefore NOT "small vs big," NOR "churny vs stable." It is: **"a fact the group would SEE, PROVE,
 and REWRITE" vs "a secret, a ref, an organ, or a vanishing that would cease to be itself if seen."**

**§6 — The false objection, dissolved (the owner: "seen EntropyArrest?").** One is tempted to hide a *churny*
 fact — presence, a heartbeat, a heard-at — on `.c`, "to spare the snap." This confuses two questions: *whether*
  a datum is for-the-community, and *how violently its value wobbles*. **EntropyArrest answers the second so the
   first need not be compromised**: a volatile value may stand as a legible particle, and its wobble is
    *forgiven on a stable line* (the `Entcase` — Radio_todo "the noise law"). So **churn is never a reason to
     hide.** Presence is a fact the group wants to see ("who is aboard"); it becomes a particle; EntropyArrest
      forgives its trembling. *(This corrects a call I made this session — I reached for `.c` on presence
       pleading churn; EntropyArrest is exactly the answer the plea does not hold against.)*

---

## The rule it cashes out to

ONE test, applied to every datum: **"Would the community want to SEE this, PROVE it, or REWRITE it while it
 runs?"**
- **Yes** → a **child particle**. Truth = standing; `i` to make, `oa` to probe, `o`/`oai` to read/find. It
   snaps. If its value wobbles, an `Entcase` forgives it — do **not** flee to `.c`.
- **No — because it is a secret / a ref / an organ / a vanishing** → **`.c`**. Not hidden state; flesh.
- **If you cannot say which, it is a particle.** The default is speech; `.c` is the earned exception.

## The verbs of standing (say it in code)
- `n.i({k:v})` — bring a child into being (recognition begins). Bumps version; watchers react.
- `n.oa({k:v})` — does such a child stand? (a boolean probe ONLY — never retrieve with it).
- `n.o({k:v})[0]` — read the standing child. `n.oai({k:v})` — find-or-make.
- A **magnitude** (a size, an `era`, a count) is a genuine value — then it rides a standing child as a scalar
   (`%Charter,era:3`), never a bare `.c` number. The child stands; the magnitude rides it.
- `{k:1}` in a query is a **presence wildcard** (has key `k`, any value); `exactly()` forces a literal and
   turns a `1` marker into `"1"` (no longer a wildcard — the footgun).

## The ledger — good `.c`, and the `.c` that owes the tree

**GOOD `.c` (flesh — rightly interior):**
| `X.c.y` | what it is | why interior |
|---|---|---|
| `req.c.secret` | the ceremony's unspeakable half | a shown secret is spent |
| `top.c.ferry_world`, `.c.up`, `source_n` | a ref to a particle | the finger, not the thing |
| `req.c.pending = {frame}` | a frame object | an object in sc is fatal |
| `w.c.on[kind] = hear` | a handler | a verb is a doing, not a said |
| ws handle, AudioContext, CryptoKey | live organs | flesh does not snap |
| poll counters, backoff, `link_unlive_at` | mid-counts | vanishings, true to no one between ticks |

**THE SHARP CASE — the body key.** Its *object* (`ident.c.bodykey`, the keypair, the Thang device-local row)
 is **flesh** — a key that never leaves the device, a finger. But the *fact* "this body exists, at this seat,
  playing this role" is a **`%Body` particle** — speech, snapped, the Crew's own record. The finger is flesh;
   the standing is speech. Never conflate them (a body key in `.sc` would ferry to every sibling and fork
    identity — the owner's law, Onboarding §1).

**THE DEBTS — `.c` that should STAND (this session's rulings):**
| today (`.c`) | becomes | ruled |
|---|---|---|
| `w.c.focused` / `link_surfaced` / `link_decided` | **`%Focus`** (cell · surfaced · decided) | ✅ LANDED 2026-09-01 |
| offline-sibling backlog (the eed storm) | **`%Owed`** under `%Crew` (bounded, seen, gated) | ✅ owner |
| body-key fork-suspicion (remint-not-read) | a **`%Body` caveat field** (a fork must be seen) | ✅ owner |
| presence / `heard_at` ("who's aboard") | a **particle**, EntropyArrest-forgiven | ✅ (corrected §6) |
| `top.c.disk_gated` / `listen_only` / `butler_up` / `ac_wanted` | `%Arrival` / `%Share` | Arrival_todo §A |

## 0. What to get on with next
- These rulings are the build list for the **Crew** work (see `Statemap_todo.md`): `%Focus` ✅, `%Owed` ✅,
   the `%Body` caveat ✅, presence-as-particle. Each is "a `.c` debt paid to the tree."
- **LANDED 2026-09-01 — `%Focus`** (the owner: "the kind of rebuild I've been wanting the whole time").
   `w.c.focused`/`link_surfaced`/`link_decided` now live on a `%Focus` particle (`cell`/`surfaced`/`decided`)
    on the client world — accessors `Sounditron_focus_get/set`, `Sounditron_surfaced_get/set`,
     `Sounditron_decided_get/set` (Sounditron.g), read through by Cellui's `commissioner_focus`. It is the
      STORE, not a mirror. **BOOK-INERT by the humdinger gate**: a Book sets no humdinger → the writer falls
       to `.c` (never encoded) → byte-identical fixtures (proven: InvWalk/InvFerry/InvSeal green with the
        change; CHECK `=` on the gen; no `%Focus` in any Story snap). Writes are **change-gated** (no-op when
         unchanged) — strictly less flap-prone than the old unconditional `.c` writes — and do NOT bump
          (reactivity rides `now_tick` + `feebly_ponder` exactly as before). `link_unlive_at` (a debounce
           clock) and `focused_keep` (the bud pin) stay `.c` — runtime timing, not standing facts (the §5
            test). The WIN is live: on a humdinger tab focus is now a particle Cyto/the daemon/`/c` can SEE.
             ⚠ Live flap-check is the owner's (the humdinger landmine) — the logic is unchanged, only storage.
- **LANDED 2026-08-31 — the `%Body` caveat.** `Swarm_body_remint_caveat(ident, pub)` (Swarm.g, beside
   `Swarm_body_key_ensure` which now calls it after its mint): reaching the MINT branch while the division
    already stands keyed (a roster `%Body` whose pub ≠ the soul prepub) means this store lost its durable
     key — the fresh row is stamped `caveat:remint`, a STANDING fact. Nothing clears it automatically; a
      re-charter retires it. Proven by SwarmBody beat 5 (Rema reminted+stamped / Vera virgin+clean),
       fixture 005.snap + `%see` "a reminted body wears its caveat…", 5/5 green on the live runner.
- **LANDED 2026-09-01 — the caveat's EXIT.** `Swarm_caveat_retire(ident, fam)` (called from
   `Swarm_family_heal`, the re-attestation walk): a LIVING My\* grant for the marked pub — the Seat has
    since run the real ceremony over that key — retires the mark; remint itself still clears nothing.
     Proven by SwarmBody beat 8 (`caveat_retired`), which also gates the heal applied end-to-end:
      member-from-grant seated · unbacked junk retired (founding-gap Captain survives) · pre-key ghost
       dropped · the Seat's charter listing exactly the standing division · a settled family healing to
        no change. 8/8 green on the live runner.
- **LANDED 2026-08-31 — `%Owed`, hung on the counterparty's OWN row** (the owner's call: Body/Owed for a
   sibling, Pier/Owed for a friend — the row is the relationship's locality, drops with it, and the Door
    can read "owed N" in place). `Swarm_owed_note/paid/settle` in Swarm.g beside the body verbs. A
     `Swarm_deliver` that returns false at the station-gated send sites (the share-up repli_ready blast,
      the reaccept pier_accept heal) NOTES the debt — the eed storm becomes standing rows instead of
       per-tick noise. Items dedup by kind (retries cannot grow it); cap 8 folds into a visible
        `dropped=N` that outlives full payment; the frame is never stored — re-derived by kind at pay
         time. `Swarm_owed_settle` fires on the presence EDGE in the hear funnel (silent >30s →
          speaking) but is **default-off behind `w.c.owed_settle`** (the backpressure-knob discipline):
           until flipped, the ledger only observes. Proven by SwarmBody beat 6 + the `%see` "a frame
            that could not go stands as a debt…", 6/6 green on the live runner.
- **THE DEBT IT EXPOSED: `Swarm_body_key_ensure` is called by NO production path** (only the SwarmBody
   Book). The live paths hand the key over directly (`adopt_absorb`, the ferry become) or fall back to the
    soul prepub (the undivided Captain, Swarm.g ~1140). Until ensure is wired into stand-up, a real device
     that loses its Dexie key just runs keyless — the caveat never fires. Wiring it in belongs to the Crew
      arc (it gives Captains real body keys → roster pubs change → charter/fixture implications), not a
       solo brick.
- The `.svelte`/hot-path ones (`%Focus` especially — Cellui's belly read) land **with the owner testing** (the
   humdinger landmine rule). The pure ones (`%Owed`, the caveat) are single-node Book-gateable.
- When you reach for `top.c.somebool = 1`, stop and apply §5's test. That reflex IS the bug this doc exists to
   catch.
