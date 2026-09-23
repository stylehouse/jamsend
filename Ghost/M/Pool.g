// Pool.g — SOUNDPOOLING's home (split out of Ra.g 2026-09-17, SoundPooling_todo.md §0.2a — the owner:
//  "yes to Pool.g, definitely looks big enough"). Three regions, in the order a reader should meet them:
//   1. THE SP ISLAND (Pool_*) — the pure policy: Pool_facts gathers once per steward pass off the live
//      world, Pool_policy returns a decision with no side effect and no world read of its own (a pure
//       twin of Ra_quarter_goal_pools + _diff + _roll for all six declared takes), Pool_policy_compare
//        runs it BESIDE the real pipeline and logs once per distinct disagreement shape — it decides
//         nothing yet; the real pipeline still rules. `MusuPoolPolicy` drives the table with hand-built facts.
//   2. THE QUARTERMASTER (Ra_quarter_* / Ra_pool_*) — the steward that RULES today: home, consent, excuse,
//      budget, caps, compartments, the goal→diff→roll pass, and the lone-body serve (press/evict).
//   3. THE POOL-FILL REACH (Ra_pool_fill_*) — the live doer: the standing %Reach per pull want, the
//      serving side on the holder, the landing tail, the head/preview heals, the pump.
//  The Ra_ prefix on regions 2–3 is HISTORY, not a home: they were moved verbatim (a file move, no
//   behaviour change) and every cross-ghost `this.` call resolves exactly as before. Rename to Pool_
//    when the island takes over (step 3), one sweep, fixtures re-sworn — not before.
//  STILL OUTSIDE (reads not redirected — they are not pure renames, or live in another ghost's policy):
//   · Swarm.g `w.c.reach_cap` 32 (the transport's cap, stays Swarm's)  · Heard.g `Heard_landed_cap`
//   · Radio.g `Radio_meh_ms` 20 s (the radio's reaction) and `top.c.pool_steward_cap` 24 + the steward's 120 s
//      busy latch (Radio_pool_steward)  · Heist.g's 45 s solo-wait → no_route and the
//       PRESS/no-route give-up classes (Heist_keep_pool_go / the keep lane)  · Cellui's `into:'pool'`.
IMPORT()
    import { sha256_hex } from "$lib/Common"

Pool_knobs():
    return {
        fill_budget: 3,           // fresh %Reach bookings per steward pass            (was w.c.pool_fill_budget ?? 3)
        fill_parallel: 3,         // pool keeps pulling at once                         (was w.c.pool_fill_parallel ?? 3)
        press_patience_ms: 300000, // a mid-pull stall is abandoned after this          (was w.c.pool_press_patience_ms ?? 300000)
        pump_latch_ms: 120000,    // a fill tick that never finished is taken back after (was a bare 120000 in Ra_pool_fill_pump)
        roll_ms: 600000,          // one non-barred displacement per window, live only   (was Ra_pool_roll_ms)
        track_mb_guess: 4,        // per-track weight before the pool can be weighed     (was the 4 in Ra_pool_track_mb)
        weigh_after: 3,           // pooled cards with bytes before weighing beats the guess
        resurrect_per_pass: 4,    // files re-catalogued per pass                        (was the 4 in Ra_pool_resurrect)
    }
// Pool_is_machinery — "a pool keep is machinery, not a haul" (Cellui, 2026-09-06), as ONE fact instead of five ifs.
Pool_is_machinery(keep):
    return !!(keep && keep.sc && String(keep.sc.into || '') === 'pool')
// Pool_facts — ONE READ of the world per steward pass, in two layers: the *_raw inputs Pool_policy draws
//  from (sources, pooled, held, recent, latest, tally, barred, the roll clock) and a SUMMARY (counts + the
//   consent/budget/standing/inflight picture) that is what the 🏊 facts log prints, once per change.
//  READS ONLY — every home is PROBED (w.o), never minted: a facts read that vivifies a %Mine shelf is a
//   writer wearing a reader's coat (this did, until 2026-09-17; the file's own "PROBE FIRST" law).
//  `consent_disagree` measures the two-resolver scattering (§0.2a b1) — a fact here, not yet a fix.
Pool_facts(w, ident):
    let M = this.top_House ? this.top_House() : null
    let f = { humdinger: !!(M && M.c && M.c.humdinger), now: Date.now() }
    let owner = ident || this.Ra_pool_owner(w)
    f.owner = owner && owner.sc ? String(owner.sc.prepub || owner.sc.name || '').slice(0, 8) : ''
    f.consent = this.Ra_pool_consent(w) ? 1 : 0
    f.consent_of = owner && this.Ra_pool_consent_of(owner) ? 1 : 0
    f.consent_disagree = f.consent !== f.consent_of ? 1 : 0
    f.excused = owner && this.Ra_pool_excused_of(owner) ? 1 : 0
    let home = this.Ra_pool_home(w)
    f.budget_mb = home && home.sc.budget_mb ? +home.sc.budget_mb : 0
    f.weight_mb = Math.round(this.Ra_pool_track_mb(w) * 10) / 10
    f.compartments = this.Ra_pool_defs(w, 0).filter((d) => d.name).map((d) => ({ name: d.name, take: d.take, who: d.who || '', share: d.share, cap: d.cap, salt: d.salt || '' }))
    let src = this.Ra_pool_sources(w)
    f.sources = { crew: src.filter((x) => x.crew).length, friend: src.filter((x) => !x.crew).length }
    f.sources_raw = src
    // the SAME pub expression Ra_quarter uses (`|| ''`): the twin diverged here (`|| 'me'`) and the compare
    //  read a different Mag from the pipeline it was checking whenever Radio_pub was empty (2026-09-17 review)
    let pub = this.Radio_pub(w) || ''
    let pool = this.Ra_pool_stock(w, pub)
    let cards = pool ? this.Ra_recs(pool) : []
    f.pooled = { cards: cards.length, playable: cards.filter((r) => +(r.sc.preview || 0) > 0 && r.o({ Preview: 1 }).length).length }
    f.pooled_raw = this.Pool_cards_raw(cards)
    let mineHome = w.o({ Mine: 1, pub: pub })[0] || null                       // PROBE — Ra_home_self would mint
    let mine = mineHome ? (mineHome.o({ stock: 1, pub: pub })[0] || null) : null
    f.held_raw = mine ? this.Ra_recs(mine).map((r) => String(r.sc.id || '')) : []
    f.held = f.held_raw.length
    f.recent_raw = this.Heard_landed_ids ? this.Heard_landed_ids(w, pub, mine) : []
    f.recent = f.recent_raw.length
    f.barred_raw = this.Heard_barred_ids ? this.Heard_barred_ids(w, pub) : {}
    f.barred = Object.keys(f.barred_raw).length
    f.latest_raw = this.Heard_latest ? this.Heard_latest(mine) : []
    f.latest = f.latest_raw.length
    f.tally_raw = this.Ra_quarter_tally(mine)
    f.tally = Object.keys(f.tally_raw).length
    f.pool_roll_at = +(w.c.pool_roll_at || 0)
    f.standing = {}
    let peering = (owner && this.Swarm_peering) ? this.Swarm_peering(owner) : null
    if (peering) { for (const r of peering.o({ Reach: 1 })) { let st = String(r.sc.state || ''); f.standing[st] = (f.standing[st] || 0) + 1 } }
    f.inflight = {}
    let shop = this.Ra_home_shop ? this.Ra_home_shop(w, pub) : null
    if (shop) { for (const k of shop.o({ Heist: 1 })) { if (!this.Pool_is_machinery(k)) { continue }; let st = String(k.sc.state || 'primed'); f.inflight[st] = (f.inflight[st] || 0) + 1 } }
    if (f.humdinger) {
        let fp = JSON.stringify(this.Pool_facts_summary(f))
        if (w.c.pool_facts_fp !== fp) { w.c.pool_facts_fp = fp; console.log('🏊 facts: ' + fp) }
    }
    return f
// Pool_facts_summary — the facts without their *_raw arrays (hundreds of ids) and without the clock: what gets logged.
Pool_facts_summary(f):
    let out = {}
    for (const k of Object.keys(f)) { if (k !== 'now' && !k.endsWith('_raw')) { out[k] = f[k] } }
    return out
// Pool_cards_raw — a pooled shelf's records as the plain rows the policy reads: {id, of, bytes}, shelf order kept
//  (the 'radio' draw uses that order as its clock).
Pool_cards_raw(recs):
    return (recs || []).filter((r) => r.sc && r.sc.id).map((r) => ({ id: String(r.sc.id || ''), of: String(r.sc.of || ''), bytes: +(r.sc.bytes || 0) }))
// THE POLICY, in the order a reader meets it: one DRAW per take kind (an ordered id list, nothing else),
//  one GOAL (fill each compartment to its cap in declared order, dedup across compartments, skip the barred),
//   one DIFF (goal vs pooled → press | pull | evict), one ROLL (which evictions go now).  Every function is pure
//    over the facts shape; the real pipeline (Ra_quarter_goal_pools / Ra_quarter_diff below) builds that shape
//     from its own arguments and calls the SAME functions — there is one copy of this logic, not a twin.
//
// The six take kinds:
//   'random'  circulation — unchosen music from everyone who shares with me, hash-ranked (the same draw every
//             sit-down, a new one per salt); what is ALREADY POOLED competes on the same hash (sediment, 09-06)
//   'radio'   what the dial already caught — the shelf's own order stands in for recency, trimmed from the FRONT
//   'recent'  my loved-and-landed takes, newest first (Heard_landed_ids)
//   'latest'  the last sitting, in the order it was heard (Heard_latest)
//   'liked'   taken tracks, most recently taken first    'kept' carried tracks by score    else: taste by score
Pool_draw_random(pd, f):
    // SELF-HELD IS NOT CIRCULATION (2026-09-23, owner: "this one mechanism works... for Radio as well
    //  as SP right?") — the same `held_raw` Pool_diff already reads to choose press-vs-pull (line ~198)
    //   says the same thing here: a source row whose id you already hold natively isn't NEW music
    //    arriving, it's your own library bouncing back off a friend's mirror (Grav re-serving Lump's
    //     own uploads, the live case that started this). Random circulation is for what a friend has
    //      that you DON'T — scoped to `sources_raw` only, never `pooled_raw`: an existing pool card
    //       keeps competing on its hash as before, this only stops NEW self-content from entering.
    let held = {}
    for (const id of (f.held_raw || [])) { held[id] = 1 }
    let ids = []
    for (const s of (f.sources_raw || [])) {
        if (!s || !s.id) { continue }
        if (held[s.id]) { continue }
        if (pd.who === 'none') { continue }
        if (pd.who === 'friends' && s.crew) { continue }
        if (pd.who === 'crew' && !s.crew) { continue }
        if (!ids.includes(s.id)) { ids.push(s.id) }
    }
    for (const c of (f.pooled_raw || [])) {
        let pid = String(c.of || c.id || '')          // a lofi copy competes as its ORIGINAL
        if (pid && !ids.includes(pid)) { ids.push(pid) }
    }
    let key = {}
    for (const id of ids) { key[id] = this.Ra_pool_hash(String(pd.name) + ':' + String(pd.salt || '') + ':' + id) }
    return ids.sort((a, b) => (key[a] < key[b] ? -1 : (key[a] > key[b] ? 1 : (a < b ? -1 : 1))))
Pool_draw_radio(pd, f):
    let hold = (f.pooled_raw || []).map((c) => c.id).filter(Boolean)
    return hold.slice(Math.max(0, hold.length - pd.cap))
Pool_draw_tally(kind, f):
    let tally = f.tally_raw || {}
    let ids = Object.keys(tally)
    if (kind === 'liked') {
        ids = ids.filter((id) => tally[id].took > 0)
        return ids.sort((a, b) => (tally[b].at - tally[a].at) || (tally[b].score - tally[a].score) || (a < b ? -1 : 1))
    }
    ids = ids.filter((id) => (kind === 'kept' ? tally[id].kept > 0 : tally[id].score > 0))
    return ids.sort((a, b) => (tally[b].score - tally[a].score) || (a < b ? -1 : 1))
Pool_draw(pd, f):
    if (pd.take === 'random') { return this.Pool_draw_random(pd, f) }
    if (pd.take === 'radio') { return this.Pool_draw_radio(pd, f) }
    if (pd.take === 'recent') { return (f.recent_raw || []).slice() }
    if (pd.take === 'latest') { return (f.latest_raw || []).slice() }
    return this.Pool_draw_tally(pd.take, f)
// Pool_holders — WHO HAS IT NOW, the one resolver (rung 5, SoundPooling_todo §0.0): every source row folded
//  to {id → from}, CREW FIRST (a sibling body's mirror is the cheap, consenting road), then by name so the
//   answer is the same on every sit-down.  Pure over the rows Ra_pool_sources / Pool_shared_rows shape;
//    Heard_holders is the same fold over the live mirrors, so a human take and a pool pull agree on the holder.
//     Until this, only a 'random' draw learned its holder (first mirror seen, not crew first) and every
//      recent/latest/liked/kept pull left `from` empty — a want no fill could ever book.
Pool_holders(sources):
    let best = {}
    for (const s of (sources || [])) {
        if (!s || !s.id || !s.from) { continue }
        let id = String(s.id)
        let from = String(s.from)
        let crew = s.crew ? 1 : 0
        let cur = best[id]
        if (!cur || crew > cur.crew || (crew === cur.crew && from < cur.from)) { best[id] = { from: from, crew: crew } }
    }
    let out = {}
    for (const id of Object.keys(best)) { out[id] = best[id].from }
    return out
// Pool_goal — fill each compartment to its cap, in declared order, from its draw; an id lands in ONE compartment
//  (the first that draws it); a Nay/Meh id lands in none.  A goal row: {id, score, why, pool, from?} — `from`
//   is the holder Pool_holders names, on EVERY row that has one (a draw with no holder is a wish with no road
//    yet; Pool_diff still carries it, and the fill leaves it standing until a mirror turns up).
Pool_goal(f):
    let barred = f.barred_raw || {}
    let tally = f.tally_raw || {}
    let holders = this.Pool_holders(f.sources_raw)
    let taken = {}
    let goal = []
    for (const pd of (f.compartments || [])) {
        let picked = 0
        for (const id of this.Pool_draw(pd, f)) {
            if (picked >= pd.cap) { break }
            if (taken[id] || barred[id]) { continue }
            taken[id] = 1
            let t = tally[id]
            let why = t ? t.why : (pd.take === 'random' ? 'circulating from ' + String(holders[id] || '').slice(0, 8) : (pd.take === 'radio' ? 'caught off the radio' : 'in the latest jam'))
            let g = { id: id, score: t ? t.score : 0, why: why, pool: pd.name }
            if (holders[id]) { g.from = holders[id] }
            goal.push(g)
            picked = picked + 1
        }
    }
    return goal
// Pool_diff — goal vs pooled.  In the goal and not pooled → 'press' (the library holds it: a local byte-copy) or
//  'pull' (known by reputation: a friend or the Cave serves it).  Pooled and out of the goal → 'evict'.  A pool
//   card stands for its ORIGINAL (id AND of both count as pooled — 09-12).  An EMPTY goal evicts nothing: right
//    after a reload the mirrors are thin and "nobody reachable" is no information, not a wish for an empty pool.
Pool_diff(goal, f):
    let pooled = {}
    for (const c of (f.pooled_raw || [])) { pooled[c.id] = 1; if (c.of) { pooled[c.of] = 1 } }
    let held = {}
    for (const id of (f.held_raw || [])) { held[id] = 1 }
    let wanted = {}
    let diff = []
    for (const g of goal) {
        wanted[g.id] = 1
        if (pooled[g.id]) { continue }
        diff.push({ of: g.id, do: held[g.id] ? 'press' : 'pull', why: g.why, pool: g.pool || '', from: g.from || '' })
    }
    if (goal.length) {
        for (const c of (f.pooled_raw || [])) {
            if (!wanted[c.id] && !(c.of && wanted[c.of])) { diff.push({ of: c.id, do: 'evict', why: 'not in the goal stash' }) }
        }
    }
    return diff
// Pool_policy — the whole decision from one facts read: goal → diff → roll.  The roll clock is a FACT here
//  (f.pool_roll_at); Ra_quarter_roll owns the write.  `MusuPoolPolicy` drives this with hand-built facts.
Pool_policy(f):
    let goal = this.Pool_goal(f)
    let diff = this.Pool_diff(goal, f)
    let rollDue = !f.pool_roll_at || (f.now - f.pool_roll_at) >= this.Pool_knobs().roll_ms
    return { goal: goal, diff: this.Pool_roll(diff, f.barred_raw || {}, rollDue, (f.pooled_raw || []).length, this.Pool_cap_sum(f.compartments)).diff }
// Pool_cap_sum — the pool's cap is its compartments' caps summed: the number the roll measures 'over' against.
Pool_cap_sum(compartments):
    let n = 0
    for (const pd of (compartments || [])) { n = n + (+pd.cap || 0) }
    return n
// Pool_policy_compare — the instrument (Cello_todo's Sounditron_crux_compare pattern): the live
//  pipeline's diff vs the pure table's, said once per distinct disagreement shape. Reads nothing back.
Pool_policy_compare(w, f, liveDiff):
    if (!f || !f.humdinger) { return 0 }
    let key = (d) => d.of + '|' + d.do
    let a = liveDiff.map(key).sort().join(',')
    let policy = this.Pool_policy(f)
    let b = policy.diff.map(key).sort().join(',')
    if (a === b) { return 0 }
    w.c.pool_policy_said = w.c.pool_policy_said || {}
    let shape = a + '→' + b
    if (w.c.pool_policy_said[shape]) { return 1 }
    w.c.pool_policy_said[shape] = 1
    console.log('🏊 policy differs: old=[' + a + '] new=[' + b + '] facts=' + JSON.stringify(this.Pool_facts_summary(f)))
    return 1
// Pool_roll — PURE: which of a diff's moves go NOW.  THE ONE LAW (the owner, 2026-09-17 evening, finding the
//  pool at 0 again): **nothing is evicted unless the pool holds more than its cap** — a card is never let go
//   for a replacement that has not landed.  Two things hide under 'evict', and only one of them is real:
//  TRIM — the pool holds MORE than its cap (files recovered from disk, a budget turned down, a compartment
//   dropped, a displacement that has just landed).  Exactly the overflow goes, at once — a cache over its cap
//    is nothing to protect (69 against a cap of 26 used to take seven hours at one per ten minutes).
//  DISPLACEMENT — the goal wants a card the pool has no room for.  The PULL goes (one per window,
//   Pool_knobs().roll_ms, live only), the pool stands at cap+1 when it lands, and THEN the next pass trims one —
//    so the evict waits on the arrival instead of being paired with a wish.  The old pairing (evict now, pull
//     hoped for) drained eed's pool by one card per window every time the pull never came: a friend gone
//      offline, a want that never landed, and the eviction had already happened.
//  Pulls that fit under the cap go at once (the pool just fills); pulls past it wait for their window.
//  `pooled_n` is what the pool HOLDS and `cap_n` the compartments' caps summed — the facts, not the diff.
Pool_roll(diff, barred, due, pooled_n, cap_n):
    let evicts = diff.filter((d) => d.do === 'evict' && !(barred && barred[d.of]))
    let pulls = diff.filter((d) => d.do === 'pull' || d.do === 'press')
    let over = Math.max(0, (+pooled_n || 0) - (+cap_n || 0))
    let room = Math.max(0, (+cap_n || 0) - (+pooled_n || 0))
    let rolled = due && pulls.length > room ? 1 : 0
    let dropE = evicts.slice(over)
    let dropP = pulls.slice(room + rolled)
    if (!dropE.length && !dropP.length) { return { diff: diff, rolled: rolled } }
    return { diff: diff.filter((d) => !dropE.includes(d) && !dropP.includes(d)), rolled: rolled }

//#region the Quartermaster — who THINKS about the pool (Portability_doc §6; name to preen)
// The steward the owner named 2026-08-27: replication ignores the pool, so SOMETHING decides what a
//  good stash is — and it is SCHEDULEY, not reactive ("once it has a good stash made, that's your
//   mobile device set for a while").  It sits down on real occasions, computes what the stash SHOULD
//    be, diffs that against what IS pooled, mints a want-list, and rests.  IT PROPOSES; FLOWS DISPOSE:
//     not one byte moves here — the press (Ra_press), the Cave pull, and the eviction machinery serve
//      the wants under their own gates (grants, reachability, battery).  So the whole surface is
//       legible: `%Provisions` under the world holding `%Want,of:<id>,do:press|pull|evict,why:…` — a
//        list a Door face can show as "what your phone wants next and why", and the stash-diff is
//         Book-testable at the model layer without a single real byte (MusuQuarter).
//  V1 POLICY — deterministic and legible, no wall clock (the fixture law): the HEARD MAG is the taste
//   record (Heard.g — one %Card,id,pub per track, carrying `take` · `keep` · `mire`), weighted
//    take 3 (a decision outranks exposure) · keep 2 (they carried it) · mire 1 each (played through with
//     someone in the room).  It read a %Jam ledger of %Spin/%Like/%Grab until 2026-09-04.
//      Recency and friend-freshness are v2 policy — the seams take them without reshaping anything.

// Ra_quarter_tally — score each track id off the listener's own heard Mag.  Returns a plain map
//  id → {score, why} (why = the compact sentence a %Want carries).  One line, because the scoring itself
//   belongs beside the Cards it reads (Heard_tally) — this is the seam, not a second copy of the policy.
Ra_quarter_tally(shelf):
    return this.Heard_tally(shelf)
// ── POOLS OF DEFINED SIZE (owner 2026-08-30: "Pools of defined size, so the overall composition of
//  the cache on the phone can be focused") — the goal is a COMPOSITION of %Pool compartments, each
//   with its own take-policy and cap, declared under a %Pools shelf on the world (the %Tags idiom).
//    No %Pool declared = ONE anonymous taste-pool of the passed cap — byte-identical to the old
//     single-goal steward, so every existing caller and fixture stands.  `cap` counts TRACKS in v1
//      (deterministic, Book-provable); a byte-budget is v2, once rec sizes are settled on the row.
// Ra_pool_define — declare|resize one compartment: %Pool,name:<n>,take:<policy>,cap:<tracks>.
//  Order of declaration IS priority: earlier pools pick first, later pools never double-claim a
//   track an earlier one took (dedup), so the composition adds up instead of overlapping.
Ra_pool_define(w, name, take, cap, who):
    let home = this.Ra_pool_home_mint(w)
    let p = home.oai({ Pool: 1, name: String(name) })
    p.c.up = home
    if (take) { p.sc.take = String(take) }
    // `who` — THE ONE REAL DECISION (owner 2026-09-03): 'friends' = random tracks to hear for the first time,
    //  'crew' = your own collection spread across your devices, 'all' = both.  Absent = all.
    if (who && String(who) !== 'all') { p.sc.who = String(who) } else if (who && p.sc.who) { delete p.sc.who }
    p.sc.cap = String(cap)
    p.bump()
    return p
// ── ONE HOME (SoundPooling_todo §0 — the owner, 2026-09-04: *"lets move all those into unison?
//  SoundPooling/Pool/* should have its scheme and content|state and everything it has"*).  The feature stood
//   in FOUR places: the declaration under a %Pools shelf on the identity, consent + budget beside it, the
//    want-list under %Provisions on the WORLD FLOOR, and the material under a %SoundPile,pub home on the
//     world.  Now it is ONE particle, `%SoundPooling,pub:<me>,budget_mb`, holding all four as children:
//       %Consent,at · %Pool,name,take,cap,salt,who,share · %Provisions > %Want · stock,pub > Mag:shuffle > …
//      ONE per owner — a budget is a fact about the device, never about a friend — so the PROBE ignores
//       `pub`: it is the label the home wears, not a key.  It rides the account snap when the owner is the
//        live identity (bump() does NOT propagate upward, so pool churn never rewrites the account file —
//         checked, not assumed) and the stash pillar Swarm_restash_pools walks it, unchanged in shape.
//          `SoundPooling` is an honest mainkey now that the compartments ARE underneath it (the objection to
//           the -ing name was only ever that a reader would look for them there and not find them).
// Ra_pool_owner — WHO OWNS the pooling: the live self's IDENTITY when `w` is the tab's radio world (so the
//  account snap carries it and a phone keeps it through the stash), the world itself for a Book or a lone
//   world.  One shape, two owners by ownership.
Ra_pool_owner(w):
    let top = this.top_House ? this.top_House() : null
    let self = this.Swarm_live_self ? this.Swarm_live_self() : null
    if (top && top.c && w && top.c.radio_w === w && self) { return self }
    return w
// Ra_pool_pub — the label the home wears: an explicit pub, else the owning identity's prepub, else 'me'.
//  NEVER Radio_pub here: on a runner tab it answers with the tab's live prepub even inside a Book world, and
//   the first gate run stamped `SoundPooling,pub:da060c94…` — a machine identity — into a fixture. A
//    world-owned home is a Book's or a lone world's, and every fixture it ever wore said `me`.
Ra_pool_pub(w, pub):
    if (pub) { return String(pub) }
    let owner = this.Ra_pool_owner(w)
    if (owner && owner !== w && owner.sc && owner.sc.prepub) { return String(owner.sc.prepub) }
    return 'me'
// Ra_pool_home — PROBE the one home, never mint: the owner's first, then the world's (a define that ran before
//  the live self hydrated wrote to the WORLD, and a read that only looked at the identity made that pool
//   invisible and undroppable — the 2026-09-03 review).  Null while nothing is declared.
Ra_pool_home(w):
    if (!w) { return null }
    let owner = this.Ra_pool_owner(w)
    let home = owner ? owner.o({ SoundPooling: 1 })[0] : null
    if (!home && owner !== w) { home = w.o({ SoundPooling: 1 })[0] }
    return home || null
// Ra_pool_homes — every home a drop or a taken-back consent must reach (both owners, deduped).
Ra_pool_homes(w):
    let out = []
    if (!w) { return out }
    for (const own of [this.Ra_pool_owner(w), w]) {
        let h = own ? own.o({ SoundPooling: 1 })[0] : null
        if (h && !out.includes(h)) { out.push(h) }
    }
    return out
// Ra_pool_home_mint — find-or-create the one home on the owner (a standing home anywhere wins: never split).
Ra_pool_home_mint(w, pub):
    let had = this.Ra_pool_home(w)
    if (had) { return had }
    let owner = this.Ra_pool_owner(w)
    let home = owner.oai({ SoundPooling: 1, pub: this.Ra_pool_pub(w, pub) })
    home.c.up = owner
    return home
// Ra_pool_provisions / Ra_pool_stock — the two READ seams a face polls, the want-list and the material shelf,
//  PROBED (the ShuffleFace law: a dial poll must not vivify a home).  Null while nothing stands.
Ra_pool_provisions(w):
    let home = this.Ra_pool_home(w)
    return home ? (home.o({ Provisions: 1 })[0] || null) : null
Ra_pool_stock(w, pub):
    let home = this.Ra_pool_home(w)
    return home ? (home.o({ stock: 1, pub: this.Ra_pool_pub(w, pub) })[0] || null) : null
// ── CONSENT (owner 2026-09-03: "we should get consent to start SoundPooling and one-paragraph explain it,
//  since it'll start putting big files in an obscure location on their phone, which might be low on space
//   already").  Pooling WRITES BYTES to browser storage — a place the person will never see in a files app
//    and which the browser may clear unasked — so nothing may press, catch or evict until this device has
//     said yes ONCE.  The yes is a particle, `%Consent,at` on the %Pools shelf: snapped, stashed with the
//      pools pillar (a phone keeps it through a reload), and takeable back.  Declaring a pool is still free —
//       it is a plan, and a plan costs nothing — but every act on bytes reads Ra_pool_consent first.
Ra_pool_consent(w):
    let home = this.Ra_pool_home(w)
    return home && home.o({ Consent: 1 })[0] ? 1 : 0

// Ra_pool_excused / Ra_pool_excuse -- A BODY THAT WILL NOT HOLD A POOL FOR ANYONE (2026-09-06, the owner,
//  tracing why the daemon's pool served eed the app's own testsounds fixtures alongside real music: "they're
//   eed's local music then. the daemon can excuse itself from holding any pool.").  CONSENT is a different
//    axis: it is the DEVICE's own yes to spend ITS bytes pooling FOR ITSELF, and it already gates the
//     self-press paths (Radio_pool_catch, Radio_pool_steward).  But the serve side was WIDENED this same
//      evening to press for a waiting friend REGARDLESS of the server's own consent (Swarm_reach_pump's
//       "...OR A FRIEND IS WAITING ON ME") -- the daemon never consented for itself, yet kept serving, and a
//        headless machine body has no taste to curate a pool with: whatever landed in its library (the
//         digger's testsounds tour, a known gotcha) is exactly what it will press and hand onward.  excused
//          is DURABLE (rides the %SoundPooling home like budget_mb) and orthogonal to consent -- it says
//           "never serve, never self-press, never hold a pool at all", and wipes any pool already standing
//            the moment it is set, the same way Ra_pool_off does (excusing IS an off that stays off).
Ra_pool_excused(w):
    let home = this.Ra_pool_home(w)
    return home && home.sc.excused ? 1 : 0
Ra_pool_excused_of(ident):
    let home = ident ? ident.o({ SoundPooling: 1 })[0] : null
    return home && home.sc.excused ? 1 : 0
async Ra_pool_excuse(w):
    let home = this.Ra_pool_home_mint(w)
    if (home.sc.excused) { return 0 }
    await this.Ra_pool_off(w)
    home.sc.excused = 1
    home.bump()
    console.log('🏊 SoundPooling excused -- this body will not hold or serve any SoundPooling')
    return 1
Ra_pool_unexcuse(w):
    let home = this.Ra_pool_home(w)
    if (!home || !home.sc.excused) { return 0 }
    delete home.sc.excused
    home.bump()
    console.log('🏊 SoundPooling un-excused -- this body may pool again')
    return 1

// Ra_pool_census — CARDS vs READY, because the two counts say opposite things and the face was showing one
//  while the dial obeyed the other (owner 2026-09-05: *"SoundPooling claims to have four but it says empty
//   when I click next"*).  A Want that has been booked mints its CARD on the pool shelf at once; the BYTES
//    land later (or never — a refused serve), and `Ra_dial_next` only dials a record whose `preview > 0`.
//     So `cards` is what the pool has ASKED for, `ready` is what it can PLAY — the same predicate the dial
//      uses, factored out so the chip, the menu row and the empty-rung note can never disagree with it.
Ra_pool_census(w, pub):
    let shelf = this.Ra_pool_stock(w, pub)
    let out = { cards: 0, ready: 0 }
    if (!shelf) { return out }
    for (const rec of this.Ra_recs(shelf)) {
        out.cards = out.cards + 1
        if (+(rec.sc.preview || 0) > 0) { out.ready = out.ready + 1 }
    }
    return out

// Ra_pool_files — WHAT IS ACTUALLY ON THIS DEVICE under pool/.  The bytes are the durable fact; the
//  catalog is not, and on a device with no folder the catalog is not durable AT ALL (a browser tab has no
//   `.jamsend/account/<prepub>/toc.snap`, so the pool shelf — which hangs on the %Identity — evaporates on
//    every reload while the OPFS files sit there uncatalogued).  Everything below exists to close that gap.
async Ra_pool_files(nav, w):
    if (!nav) { return [] }
    let paths = []
    try { paths = await this.Crate_nav_paths(nav, 'pool') } catch (er) { paths = [] }
    paths = paths || []
    // the last disk listing rides the radio world's .c so a SYNC reader (Ra_pocket_mirror, the snap-visible
    //  cell) can say "on disk" without a disk walk of its own.  Runtime cache, refreshed by every walk.
    if (w && w.c) { w.c.pool_files = paths }
    return paths

// Ra_pool_resurrect — REBUILD the pool catalog from the pool/ files, the way the Stoker rebuilds the
//  library from radiostock.  A pooled track that survives a reload as bytes but not as a card is
//   indistinguishable from one that was never pooled: the pocket reads "empty" while the disk fills up.
//  BOUNDED (default 4 a pass, `w.c.pool_resurrect_more` latches the rest) because each new file costs a
//   whole-file read + hash — the same shape and the same reason as the unity look's cap of 4.
//  MINTS NO CHUNKS, deliberately: the shelf rides the account snap where a Uint8Array in .sc is fatal, and
//   the preview a pool card needs comes from the carry (Ra_rec_previews_carry), not from a re-encode here.
async Ra_pool_resurrect(w, ident, cap):
    // PROBE FIRST, MINT ONLY FOR FILES (2026-09-05, MusuHeist went caveat:13 the moment the Stoker rung landed):
    //  Ra_pool_fill_homes MINTS the pool home on its live branch, so a resurrect that asked it for a shelf
    //   vivified a %SoundPooling home in every Book world whose Stoker has a nav — a new subtree in 13 snaps
    //    that never pooled a thing.  The files are the only reason a shelf should come to exist here.
    let homes = (ident && ident.c && ident.c.fill_mw) ? this.Ra_pool_fill_homes(w, ident) : null
    let rw = homes ? homes.mw : ((this.top_House && this.top_House().c && this.top_House().c.radio_w) ? this.top_House().c.radio_w : w)
    let nav = homes ? homes.nav : (rw.c.ra_nav || (this.Crate_nav ? this.Crate_nav() : null))
    if (!nav) { return 0 }
    let paths = await this.Ra_pool_files(nav, rw)
    if (!paths.length) { delete w.c.pool_resurrect_more; return 0 }
    if (!homes) {
        let pub = this.Radio_pub ? (this.Radio_pub(rw) || 'me') : 'me'
        homes = { mw: rw, nav: nav, pool: this.Ra_pool_shelf_live(rw) || this.Ra_home_pool(rw, pub) }
    }
    if (!homes.pool) { return 0 }
    // what the shelf already knows, by the path it was landed at (`rel` — the pool card's own sc.path)
    let known = {}
    let onDisk = {}
    for (const path of paths) { onDisk[String(path)] = 1 }
    for (const rec of this.Ra_recs(homes.pool)) {
        if (rec.sc.path) { known[String(rec.sc.path)] = 1 }
        // ONE OF ANYTHING: a card whose file is gone (an evict whose drop never landed, a reload between the
        //  two) is a husk beside its own re-pull — "Went to Hermes" twice, 2026-09-13. A card that has a path
        //   and no file, and no keep pulling it, goes; a card still being landed has no path yet and stands.
        if (rec.sc.path && !onDisk[String(rec.sc.path)] && rec.sc.preview) {
            try { await this.Ra_rec_drop(homes.pool, String(rec.sc.id)); console.log('🏊 pool: dropped a card with no file — ' + String(rec.sc.title || rec.sc.id).slice(0, 32)) } catch (er) {}
        }
    }
    // an evicted path is not "uncatalogued", it is THROWN OUT — skip it until the session ends or a fresh
    //  landing clears the mark (Ra_quarter_serve's evict branch stamps it).
    let evicted = homes.mw.c.pool_evicted || {}
    for (const p of Object.keys(evicted)) { known[p] = 1 }
    let bound = (+(cap || 0) > 0) ? +cap : this.Pool_knobs().resurrect_per_pass
    let built = 0
    let left = 0
    for (const path of paths) {
        if (known[String(path)]) { continue }
        if (built >= bound) { left = left + 1; continue }
        let parts = ('pool/' + path).split('/').filter(Boolean)
        let filename = parts.pop()
        let raw = null
        try { raw = await nav.bin_read(parts.join('/'), filename) } catch (er) { raw = null }
        if (!raw || !raw.byteLength) { continue }
        let bytes = (raw instanceof Uint8Array) ? raw : new Uint8Array(raw)
        let hash = await sha256_hex(bytes)
        let meta = await this.Crate_meta_from_tags(bytes, path)
        let card = this.Ra_rec_pool(homes.pool, hash.slice(0, 16), hash.slice(0, 16), String(path), null)
        card.sc.title = meta.title
        card.sc.artist = meta.artist
        card.sc.bytes = bytes.length
        card.sc.body_hash = hash
        if (meta.album) { card.sc.album = meta.album }
        let dot = filename.lastIndexOf('.')
        if (dot >= 0) { card.sc.ext = filename.slice(dot + 1) }
        card.bump()
        built = built + 1
    }
    if (left > 0) { w.c.pool_resurrect_more = left } else { delete w.c.pool_resurrect_more }
    if (built > 0) { console.log('🏊 pool: recovered ' + built + ' pooled track(s) from disk' + (left ? ' (' + left + ' more next pass)' : '')) }
    return built

// Ra_pool_shelf_live — THE POOL SHELF, FROM WHEREVER THIS BODY KEEPS IT.  Ra_pool_stock(w, pub) can only find
//  the home through Ra_pool_owner, which resolves to the identity ONLY when w IS top.c.radio_w — and a body
//   with no dial (the daemon: "no web audio here") never sets radio_w, so every probe from its Sounditron
//    world answered "no pool" while its identity held eight pressed records (measured 2026-09-05: pool
//     records 4 after resurrect, Pocket cell absent).  Probe the world's way first, then the live identity's
//      own %SoundPooling > stock directly.  Pure read; mints nothing.
Ra_pool_shelf_live(rw):
    let pub = this.Radio_pub ? (this.Radio_pub(rw) || 'me') : 'me'
    let shelf = rw ? this.Ra_pool_stock(rw, pub) : null
    if (shelf) { return shelf }
    let M = this.top_House ? this.top_House() : null
    let ident = (M && M.Swarm_live_self) ? M.Swarm_live_self() : null
    let home = ident ? ident.o({ SoundPooling: 1 })[0] : null
    return home ? (home.o({ stock: 1 })[0] || null) : null

// Ra_pool_whys — ONE SYNC SENTENCE of why the pocket is what it is (the owner 2026-09-05: *"some indications
//  in the console about how each NEXT button click is going … surely it's an intent that gives up at some
//   interesting point"*).  Counts the cards, the playable ones, and a histogram of the single reason each
//    unplayable one is not — the same three facts the %Pocket cell carries, folded to a line.  Pure read.
Ra_pool_whys(rw):
    let shelf = this.Ra_pool_shelf_live(rw)
    let files = (rw && rw.c && rw.c.pool_files) ? rw.c.pool_files : null
    let out = { cards: 0, ready: 0, whys: {}, uncatalogued: 0, line: '' }
    let carded = {}
    for (const rec of (shelf ? this.Ra_recs(shelf) : [])) {
        out.cards = out.cards + 1
        if (rec.sc.path) { carded[String(rec.sc.path)] = 1 }
        let why = ''
        if (files && rec.sc.path && !files.includes(String(rec.sc.path))) { why = 'no file' }
        if (!why && !(+(rec.sc.preview || 0) > 0)) { why = 'no preview' }
        if (!why && !rec.o({ Preview: 1 }).length) { why = 'no chunks' }
        if (why) { out.whys[why] = (out.whys[why] || 0) + 1 } else { out.ready = out.ready + 1 }
    }
    for (const path of (files || [])) { if (!carded[String(path)]) { out.uncatalogued = out.uncatalogued + 1 } }
    let bits = [out.cards + ' card' + (out.cards === 1 ? '' : 's'), out.ready + ' playable']
    for (const k of Object.keys(out.whys)) { bits.push(out.whys[k] + ' ' + k) }
    if (out.uncatalogued) { bits.push(out.uncatalogued + ' file' + (out.uncatalogued === 1 ? '' : 's') + ' on disk uncatalogued') }
    if (!files) { bits.push('disk not yet listed') }
    out.line = bits.join(' · ')
    return out

// Ra_pocket_mirror — THE POOL, SNAP-VISIBLE (the owner 2026-09-05: *"why can't you just get Story:Sounditron
//  to take a resnap … which should show you the C changed — as long as you have the relevant state
//   snap-visible, which is what my griping about .c is all about"*).  The camera IS the instrument, and it
//    was blind to the pool: `Mine > stock` is dontSnap and %SoundPooling hangs on the Identity under Mundo,
//     outside H:Sounditron,Run — so a resnap diff showed nothing when the pocket changed.
//  This mints ONE `%Pocket` cell in the Sounditron world (beside Census/Audio/Machine, the same legibility
//   idiom) carrying the shelf counts, and one `%pooled` child per track with the facts that decide whether
//    it plays: preview · chunks · disk · why.  A PURE MIRROR — reads the pool shelf (sync) and the cached
//     disk listing (Ra_pool_files stamps it); mints nothing on the pool, moves no byte.  ABSENT when there is
//      nothing to say (no cards, no files): the empty-pocket case snaps exactly as it always did, so no
//       fixture on a poolless runner moves, and "the cell appeared" is itself the first legible change.
//  `host` is the world the cell lives in (w:Sounditron); `rw` the radio world the shelf hangs off.
Ra_pocket_mirror(rw, host):
    if (!rw || !host) { return null }
    let shelf = this.Ra_pool_shelf_live(rw)
    let files = rw.c.pool_files || []
    let recs = shelf ? this.Ra_recs(shelf) : []
    let cell = host.o({ Pocket: 1 })[0]
    if (!recs.length && !files.length) {
        if (cell) { host.drop(cell) }
        return null
    }
    if (!cell) {
        cell = host.i({ Pocket: 1 })
        cell.c.up = host
    }
    let ready = 0
    let seen = {}
    for (const rec of recs) {
        let id = String(rec.sc.id || '')
        if (!id) { continue }
        seen[id] = 1
        let P = +(rec.sc.preview || 0)
        let chunks = rec.o({ Preview: 1 }).length
        let disk = (rec.sc.path && files.includes(String(rec.sc.path))) ? 1 : 0
        let why = ''
        if (!disk) { why = 'no file' }
        if (!why && !(P > 0)) { why = 'no preview' }
        if (!why && !chunks) { why = 'no chunks' }
        if (!why) { ready = ready + 1 }
        let row = cell.oai({ pooled: 1, id: id })
        row.c.up = cell
        let title = String(rec.sc.title || '')
        if (title && row.sc.title !== title) { row.sc.title = title }
        if (+(row.sc.preview || 0) !== P) { if (P > 0) { row.sc.preview = P } else { delete row.sc.preview } }
        if (+(row.sc.chunks || 0) !== chunks) { if (chunks > 0) { row.sc.chunks = chunks } else { delete row.sc.chunks } }
        if (why) { if (row.sc.why !== why) { row.sc.why = why } } else { if (row.sc.why) { delete row.sc.why } }
    }
    // rows for cards that are gone
    for (const row of cell.o({ pooled: 1 }).slice()) {
        if (!seen[String(row.sc.id || '')]) { cell.drop(row) }
    }
    let uncat = 0
    let carded = {}
    for (const rec of recs) { if (rec.sc.path) { carded[String(rec.sc.path)] = 1 } }
    for (const path of files) { if (!carded[String(path)]) { uncat = uncat + 1 } }
    let facts = { cards: recs.length, ready: ready, files: files.length, uncatalogued: uncat }
    let moved = 0
    for (const k of ['cards', 'ready', 'files', 'uncatalogued']) {
        let v = facts[k]
        if (v > 0) { if (+(cell.sc[k] || 0) !== v) { cell.sc[k] = v; moved = 1 } } else { if (cell.sc[k] != null) { delete cell.sc[k]; moved = 1 } }
    }
    if (moved) { cell.bump() }
    return cell

// Ra_pool_report — THE ONE LEGIBLE DUMP (the owner 2026-09-05: *"how can I verify that SoundPool works at
//  all — or give you feedback about how it doesn't"*).  Everything that decides whether a pooled track can
//   PLAY, in one object and one console block, so a human at a tab and a machine reading a snap are looking
//    at the SAME facts.  Pure read — it walks the shelf and the disk and touches nothing.
//  Per card it answers the only question that matters — `why` is empty when the track is dialable, and
//   otherwise names the single reason it is not.  The shelf-level counts sit beside the DISK count, because
//    "files on disk with no card" is its own failure and was invisible until now.
async Ra_pool_report(w, ident, quiet):
    // a world-only call (the CLI `poke Ra_pool_report` hands the radio world and nothing else) reports the
    //  LIVE owner — the same identity the dial's own dry-pool call passes (2026-09-12; it threw for a week)
    if (!ident) { let o = this.Ra_pool_owner(w); if (o && o !== w) { ident = o } }
    let homes = this.Ra_pool_fill_homes(w, ident)
    let pub = this.Radio_pub ? (this.Radio_pub(homes.mw) || 'me') : 'me'
    let out = { consent: 0, excused: 0, budget_mb: 0, cards: 0, ready: 0, files: 0, uncatalogued: 0, tracks: [] }
    let owner = ident || (this.Ra_pool_owner ? this.Ra_pool_owner(homes.mw) : null)
    if (owner && this.Ra_pool_consent_of) { out.consent = this.Ra_pool_consent_of(owner) ? 1 : 0 }
    if (owner && this.Ra_pool_excused_of) { out.excused = this.Ra_pool_excused_of(owner) ? 1 : 0 }
    let home = owner ? owner.o({ SoundPooling: 1 })[0] : null
    if (home && home.sc.budget_mb) { out.budget_mb = +home.sc.budget_mb }
    let paths = await this.Ra_pool_files(homes.nav, homes.mw)
    out.files = paths.length
    let carded = {}
    if (homes.pool) {
        for (const rec of this.Ra_recs(homes.pool)) {
            out.cards = out.cards + 1
            if (rec.sc.path) { carded[String(rec.sc.path)] = 1 }
            let P = +(rec.sc.preview || 0)
            let chunks = rec.o({ Preview: 1 }).length
            let why = ''
            if (!(P > 0)) {
                why = 'no preview — the dial cannot pick it'
            } else {
                if (!chunks) { why = 'preview claimed but no chunks stand behind it' } else { out.ready = out.ready + 1 }
            }
            let row = { id: String(rec.sc.id || ''), title: String(rec.sc.title || ''), artist: String(rec.sc.artist || ''), preview: P, chunks: chunks, on_disk: 0 }
            if (rec.sc.path && paths.includes(String(rec.sc.path))) { row.on_disk = 1 }
            if (why) { row.why = why }
            if (!row.on_disk) { row.why = 'card with no file under pool/ — the bytes are gone' }
            out.tracks.push(row)
        }
    }
    let evictedMap = (homes.mw && homes.mw.c && homes.mw.c.pool_evicted) || {}
    out.lingering = 0
    for (const path of paths) {
        if (evictedMap[String(path)]) { out.lingering = out.lingering + 1; continue }
        if (!carded[String(path)]) { out.uncatalogued = out.uncatalogued + 1 }
    }
    // the standing circulation asks, because "nothing is arriving" is a different fault from "nothing plays"
    let peering = (owner && this.Swarm_peering) ? this.Swarm_peering(owner) : null
    if (peering) {
        out.reaches = []
        for (const reach of peering.o({ Reach: 1 })) {
            let r = { of: String(reach.sc.of || '').slice(0, 8), state: String(reach.sc.state || ''),
                      to: String(reach.sc.to || '').slice(0, 8) }
            if (reach.sc.why) { r.why = String(reach.sc.why) }
            out.reaches.push(r)
        }
    }
    // the glass polls this every few seconds (PoolFace) — a quiet read returns the object and says nothing
    if (!quiet) {
        console.log('🏊 POOL REPORT — ' + pub.slice(0, 8) + (out.excused ? ' · EXCUSED (holds no pool)' : '') +
            ' · consent ' + (out.consent ? 'yes' : 'NO') +
            ' · budget ' + out.budget_mb + 'MB · ' + out.cards + ' card(s) · ' + out.ready + ' playable · ' +
            out.files + ' file(s) on disk · ' + out.uncatalogued + ' uncatalogued' + (out.lingering ? ' · ' + out.lingering + ' evicted but file lingering' : ''))
        for (const t of out.tracks) {
            console.log('   ' + (t.why ? '✗' : '✓') + ' ' + (t.artist ? t.artist + ' — ' : '') + t.title +
                '  [preview ' + t.preview + ' · chunks ' + t.chunks + (t.on_disk ? '' : ' · NO FILE') + ']' +
                (t.why ? '  ⟵ ' + t.why : ''))
        }
        if (out.uncatalogued) { console.log('   ⚠ ' + out.uncatalogued + ' file(s) under pool/ with no card — run Ra_pool_resurrect') }
        for (const r of (out.reaches || [])) {
            console.log('   ⇢ reach ' + r.of + ' → ' + r.to + ' : ' + r.state + (r.why ? ' — ' + r.why : ''))
        }
    }
    return out

// Ra_pool_consent_of — THE SAME YES, ASKED OF THE IDENTITY INSTEAD OF A WORLD.
//  ⚠ WHY THIS EXISTS (2026-09-05, measured on eed831f1).  `Ra_pool_consent(w)` can only find the home
//   through `Ra_pool_owner`, which resolves to the live identity ONLY when `w` IS the radio world
//    (`top.c.radio_w === w`) and otherwise hands back `w` itself.  So every caller holding some OTHER
//     world — the reach lane on the Swarm/Clustation world is the one that bit — probes a world that
//      never carries a `%SoundPooling` home and reads a confident 0.  That is a silent false NO: the
//       reach gates were switched to consent and stayed shut anyway, four fresh `state:booked` rows sat
//        undispatched for ten minutes, and the daemon holding the bytes served nobody.
//  The home is minted ON THE IDENTITY (`Ra_pool_home_mint` → `Ra_pool_owner`), so an identity in hand is
//   a STRICTLY better question than a world in hand — no `radio_w` coincidence required.  Books stay
//    inert exactly as before: a Book's identity carries no home either.
Ra_pool_consent_of(ident):
    let home = ident ? ident.o({ SoundPooling: 1 })[0] : null
    return home && home.o({ Consent: 1 })[0] ? 1 : 0
Ra_pool_consent_give(w, now):
    let shelf = this.Ra_pool_home_mint(w)
    let c = shelf.oai({ Consent: 1 })
    c.c.up = shelf
    if (now != null && !c.sc.at) { c.sc.at = String(now) }
    shelf.bump()
    return c
Ra_pool_consent_take(w):
    let n = 0
    for (const shelf of this.Ra_pool_homes(w)) {
        let hit = 0
        for (const c of shelf.o({ Consent: 1 })) { shelf.drop(c); hit = hit + 1 }
        if (hit) { shelf.bump(); n = n + hit }
    }
    return n
// ── THE BUDGET IS THE UNIT OF CONSENT (owner 2026-09-03: "aim for 3GB… or less than 1/3rd of what chrome
//  thinks it can use… that amount adjustment thing should be able to go back to 0 and turn off and clean
//   out it all").  `budget_mb` rides the %Pools shelf; 0/absent with no consent = off.  v1 turns megabytes
//    into a track cap at ~4 MB a lofi track (the byte-budget steward is v2 — Ra.g's own note above).
Ra_pool_budget(w):
    let shelf = this.Ra_pool_home(w)
    return shelf ? Number(shelf.sc.budget_mb || 0) : 0
Ra_pool_budget_set(w, mb):
    let shelf = this.Ra_pool_home_mint(w)
    let v = Math.max(0, Math.floor(Number(mb) || 0))
    if (v) { shelf.sc.budget_mb = String(v) } else if (shelf.sc.budget_mb) { delete shelf.sc.budget_mb }
    shelf.bump()
    this.Ra_pool_caps_apply(w)
    return v
// ── FRACTIONS, NOT CAPS (owner 2026-09-03: "why limit anything? they each should have a fraction, use sliders
//  that redistribute in a gang").  Every %Pool wears `share` (percent of the budget); its `cap` is DERIVED —
//   budget × share ÷ ~4 MB — never set by hand any more.  Moving one share rescales the others so the gang
//    always sums to 100.
// Ra_pool_track_mb — WEIGHED, NOT COUNTED (the owner 2026-09-15: "as long as it doesn't run out of space"):
//  the cap is a count, so the per-track weight decides whether N tracks fit the MB. Read it off what is
//   actually pooled (every card carries `bytes`) and fall back to the 4 MB guess while the pool is thin.
Ra_pool_track_mb(w):
    let M = this.top_House ? this.top_House() : null
    if (!M || !M.c.humdinger) { return this.Pool_knobs().track_mb_guess }   // a Book's caps are its fixtures' numbers
    let pub = this.Radio_pub ? (this.Radio_pub(w) || 'me') : 'me'
    let pool = this.Ra_pool_stock ? this.Ra_pool_stock(w, pub) : null
    let sum = 0
    let n = 0
    if (pool) { for (const r of this.Ra_recs(pool)) { let b = +(r.sc.bytes || 0); if (b > 0) { sum = sum + b; n = n + 1 } } }
    if (n < this.Pool_knobs().weigh_after) { return this.Pool_knobs().track_mb_guess }
    return Math.max(1, sum / n / 1048576)
Ra_pool_caps_apply(w):
    let shelf = this.Ra_pool_home(w)
    if (!shelf) { return 0 }
    let mb = Number(shelf.sc.budget_mb || 0)
    let per = this.Ra_pool_track_mb(w)
    let n = 0
    for (const p of shelf.o({ Pool: 1 })) {
        let share = Number(p.sc.share || 0)
        let cap = (p.sc.share != null && p.sc.share !== '') ? Math.max(1, Math.floor(mb * share / 100 / per)) : Number(p.sc.cap || 1)
        if (String(p.sc.cap || '') !== String(cap)) { p.sc.cap = String(cap); p.bump(); n = n + 1 }
    }
    return n
Ra_pool_share_set(w, name, pct):
    let shelf = this.Ra_pool_home(w)
    if (!shelf) { return 0 }
    let me = shelf.o({ Pool: 1, name: String(name) })[0]
    if (!me) { return 0 }
    let v = Math.max(0, Math.min(100, Math.round(Number(pct) || 0)))
    let others = shelf.o({ Pool: 1 }).filter((p) => p !== me)
    let rest = 100 - v
    let sum = 0
    for (const p of others) { sum = sum + Number(p.sc.share || 0) }
    for (const p of others) {
        let s = sum > 0 ? Math.round(Number(p.sc.share || 0) * rest / sum) : (others.length ? Math.round(rest / others.length) : 0)
        p.sc.share = String(s)
        p.bump()
    }
    me.sc.share = String(v)
    me.bump()
    this.Ra_pool_caps_apply(w)
    return v
// Ra_pool_recent_on / _set — THE THIRD CHECKBOX (owner 2026-09-04: *"perhaps soundpooling also defaults on
//  a [x] recent acquisitions"*).  On: a second compartment taking half the budget, drawing from the
//   newlyadded ledger.  Off: it goes and the rolling one takes the room back, so the budget the human typed
//    always means the same thing.  Two compartments is the most the one sentence can honestly describe.
Ra_pool_recent_on(w):
    return this.Ra_pool_defs(w, 0).some((p) => p.name === 'recent' && p.take === 'recent') ? 1 : 0
Ra_pool_recent_set(w, on):
    if (on) {
        if (this.Ra_pool_recent_on(w)) { return 0 }
        this.Ra_pool_gang(w, 'recent', 'recent', null, 50)
        return 1
    }
    if (!this.Ra_pool_recent_on(w)) { return 0 }
    this.Ra_pool_drop(w, 'recent')
    // rolling takes the room back.  Not "rescale what is left": with one compartment standing, anything
    //  short of 100 silently shrinks the budget the human typed.
    if (this.Ra_pool_defs(w, 0).some((p) => p.name === 'rolling')) { this.Ra_pool_share_set(w, 'rolling', 100) }
    return 1
// Ra_pool_gang — declare (or top up) a compartment at `pct`, taking that share from the others in proportion.
Ra_pool_gang(w, name, take, who, pct):
    this.Ra_pool_define(w, String(name), take, 1, who)
    return this.Ra_pool_share_set(w, String(name), pct)
// Ra_pool_start — THE ONE SENTENCE (owner 2026-09-03, the final cut: "SoundPool keeps rolling [ 300 ] MB of
//  music in browser storage, sourced from [ ] friends (less predictable) and [x] crew (your devices, see
//   Door)").  One random compartment at 100% of the budget, drawing from `who`: 'friends' | 'crew' | 'all' |
//    'none'.  The multi-pool gang (liked/taste/shares) stays as machinery and Books, but it is no longer what
//     the yes declares — the fair-share question it raises ("a pool that can't fill shouldn't hold the others
//      back, yet should claim its space back one day") is real and unsolved, and one pool makes it moot.
//  Idempotent: a second call only moves the budget and the who.  Returns 1 the first time.
Ra_pool_start(w, budget_mb, now, who):
    // AN EXCUSED BODY STAYS EXCUSED (2026-09-06 self-review): excuse is meant to be DURABLE ("never hold or
    //  serve a pool at all"), and this was the one door that could quietly undo it — anything calling start
    //   again (a re-press of the same button, a Book, a stray steward occasion) would re-give consent and
    //    re-declare a pool with no memory that the body had opted out.  Un-excuse first if that is truly wanted.
    if (this.Ra_pool_excused && this.Ra_pool_excused(w)) {
        console.log('🏊⚠ SoundPool start refused — this body is excused (Ra_pool_unexcuse first)')
        return -1
    }
    this.Ra_pool_consent_give(w, now)
    this.Ra_pool_budget_set(w, budget_mb)
    let had = this.Ra_pool_defs(w, 0).filter((p) => p.name)
    let w2 = who || 'crew'
    if (had.length) {
        for (const d of had) { if (d.take === 'random') { this.Ra_pool_define(w, d.name, 'random', d.cap, w2) } }
        return 0
    }
    this.Ra_pool_define(w, 'rolling', 'random', 1, w2)
    this.Ra_pool_share_set(w, 'rolling', 100)
    console.log('🏊 SoundPool keeps rolling ' + this.Ra_pool_budget(w) + ' MB from ' + w2)
    return 1
// Ra_pool_who — the two checkboxes as one word: 'all' | 'friends' | 'crew' | 'none' (read off the random pool)
Ra_pool_who(w):
    let d = this.Ra_pool_defs(w, 0).find((p) => p.name && p.take === 'random')
    return d ? String(d.who || 'all') : 'crew'
// Ra_pool_unfile — THE BYTES GO WITH THE CARD.  A pooled %Record's `path` is pool-relative ('A/B/t.ogg'; on disk
//  `pool/A/B/t.ogg` through the OPFS mount), so the file is one nav.bin_rm away.  Best-effort: a missing file
//   or a nav without bin_rm (a Book's mock) is not an error — the card still goes.  Returns 1 if a file went.
async Ra_pool_unfile(w, nav, rec):
    let path = String(rec && rec.sc && rec.sc.path || '')
    // NAME THE MISS (2026-09-05, eed's log: "evicted 4" then "recovered 4 from disk" every pass — the card went,
    //  the file did not, and this returned 0 in silence).  A file that will not go is a loop waiting to happen
    //   with the resurrect; say which of the three ways it failed, once per path.
    let say = (why) => { let k = 'unfile_said_' + path; if (w && w.c && !w.c[k]) { w.c[k] = 1; console.log('🏊⚠ pool evict: file not removed — ' + why + ' — ' + path) } }
    if (!rec) { return 0 }
    if (!path) { say('card has no path'); return 0 }
    if (!nav || typeof nav.bin_rm !== 'function') { say('this nav has no bin_rm'); return 0 }
    let parts = path.split('/').filter(Boolean)
    let fname = parts.pop()
    if (!fname) { return 0 }
    try {
        let ok = await nav.bin_rm('pool' + (parts.length ? '/' + parts.join('/') : ''), fname)
        if (!ok) { say('bin_rm answered false') }
        return ok ? 1 : 0
    } catch (e) { say('bin_rm threw ' + String(e).slice(0, 60)); return 0 }
// Ra_pool_off — BACK TO ZERO: the yes taken back, the budget gone, every compartment dropped and every pooled
//  card with it — AND its file (Ra_pool_unfile), so "off" means the space comes back.  Returns {pools, records, files}.
async Ra_pool_off(w):
    let out = { pools: 0, records: 0, files: 0 }
    if (w && w.c && w.c.pool_evicted) { delete w.c.pool_evicted }
    this.Ra_pool_consent_take(w)
    this.Ra_pool_budget_set(w, 0)
    for (const d of this.Ra_pool_defs(w, 0)) { if (d.name) { out.pools = out.pools + this.Ra_pool_drop(w, d.name) } }
    let me = (this.Radio_pub ? this.Radio_pub(w) : null) || 'me'
    let pshelf = this.Ra_pool_stock(w, me)
    let nav = w ? (w.c.ra_nav || (this.Crate_nav ? this.Crate_nav() : null)) : null
    if (pshelf) {
        for (const r of this.Ra_recs(pshelf)) {
            if (!r.sc.id) { continue }
            out.files = out.files + await this.Ra_pool_unfile(w, nav, r)
            if (await this.Ra_rec_drop(pshelf, String(r.sc.id))) { out.records = out.records + 1 }
        }
    }
    if (w && w.c) { delete w.c.pool_nohead }   // a fresh yes forgives the headless
    console.log('🏊 SoundPooling off — ' + out.pools + ' pool(s), ' + out.records + ' pooled card(s) and ' + out.files + ' file(s) gone')
    return out
// Ra_pool_drop — retire a compartment (the D of CRUD).  Its wants fall out at the next sit-down (the steward
//  re-derives the goal from what stands); its pooled copies are then 'evict' wants — the pool is expendable.
Ra_pool_drop(w, name):
    let n = 0
    // drop from BOTH homes (see Ra_pool_home): a pool minted before the self hydrated must still die.
    for (const shelf of this.Ra_pool_homes(w)) {
        let hit = 0
        for (const p of shelf.o({ Pool: 1, name: String(name) })) { shelf.drop(p); hit = hit + 1 }
        if (hit) { shelf.bump(); n = n + hit }
    }
    return n
// Ra_pool_defs — read the declared composition; fall back to the anonymous single pool.
Ra_pool_defs(w, cap):
    // both owners, identity first (Ra_pool_home) — probe-first: a read never mints a home.
    let shelf = this.Ra_pool_home(w)
    let defs = shelf ? shelf.o({ Pool: 1 }).map((p) => ({ name: String(p.sc.name || ''), take: String(p.sc.take || 'taste'), cap: Number(p.sc.cap || 0), salt: String(p.sc.salt || ''), who: String(p.sc.who || 'all'), share: Number(p.sc.share || 0) })).filter((p) => p.name) : []
    if (!defs.length) { return [{ name: '', take: 'taste', cap: cap }] }
    return defs
// Ra_pool_hash — the clockless shuffle key (FNV-1a over name:salt:id): a 'random' pool draws in an order
//  that is random-LOOKING yet the same on every sit-down and in every fixture; a new `salt` on the pool is
//   the human's "shuffle again".  No Math.random on a Book path — the fixture law.
Ra_pool_hash(s):
    let h = 2166136261
    for (let i = 0; i < s.length; i++) { h = h ^ s.charCodeAt(i); h = Math.imul(h, 16777619) >>> 0 }
    return ('00000000' + h.toString(16)).slice(-8)
// Ra_pool_sources — WHAT A 'random' POOL DRAWS FROM (owner 2026-09-03: "one that just acquires random whole
//  LOFI tracks from all Piers|Crewmates"): every mirrored catalog in the radio world — a %Theirs crate
//   stands only for a body that shared with me (Repli mirrors the granted), so crew and friends alike are
//    sources.  Plain rows {id, from, title}; `from` is the holder's routing name the fill will book toward.
//  Two layers since rung 5 (SoundPooling_todo §0.0): Pool_shared_rows is the CENSUS — every stocked, real
//   (non-husk) record on every mirror, who holds it, crew or not — and Ra_pool_sources is that census minus
//    what the POOL specifically gave up on (Ra_pool_nohead).  Heard_holders reads the census, so "who has it
//     now" for a human take and for a pool pull is one walk and one fold (Pool_holders), not two.
Ra_pool_sources(w):
    return this.Pool_shared_rows(w).filter((row) => !this.Ra_pool_nohead(w, row.id))
Pool_shared_rows(w):
    let out = []
    if (!w || !w.o) { return out }
    // crew or friend?  /Crew lives on the identity the pooling lives on (Ra_pool_owner) — a holder whose
    //  routing name prefix-matches a mate row is crew; everyone else sharing with me is a friend.
    let crew = this.Ra_pool_owner(w).o({ Crew: 1 })[0]
    let mates = crew ? crew.o({ mate: 1 }) : []
    let samec = (a, b) => a && b ? (String(a).startsWith(String(b)) || String(b).startsWith(String(a))) : false
    let crewish = (from) => mates.some((m) => samec(m.sc.mate, from) || (m.sc.pub && samec(m.sc.pub, from)))
    for (const them of w.o({ Theirs: 1 })) {
        let from = String(them.sc.pub || '')
        if (!from) { continue }
        let stock = them.o({ stock: 1 })[0]   // probe-first: a read never mints a shelf
        if (!stock) { continue }
        for (const r of this.Ra_recs(stock)) {
            let id = String(r.sc.id || '')
            if (!id) { continue }
            // A BROWSED HUSK IS NOT A SOURCE (2026-09-06, eed measured live: 17 of 18 reaches to S refused
            //  `not_in_library`, four reaches a second, forever).  A friend's mirror also carries the
            //   `husk,rummage` rows a folder describe-ask left behind -- the listing of a folder someone
            //    heisted from them, never stocked into their Mine.  The pool draw ranked those like tracks,
            //     booked fills for them, and the holder's verdict (Mine only) refused every one.  Skip them:
            //      a candidate must be something the holder has actually stocked.  (Owed on the holder's side:
            //       press from the RummageLib husk -- it has a path -- so a browsed folder becomes servable.)
            if (r.sc.husk || r.sc.rummage) { continue }
            let row = { id: id, from: from, title: String(r.sc.title || '') }
            if (crewish(from)) { row.crew = 1 }
            out.push(row)
        }
    }
    return out
// Ra_quarter_goal_pools / Ra_quarter_diff — the real pipeline's doors, kept for their callers (every pool fixture
//  hands these a hand-built shelf).  Each builds the facts SHAPE from its arguments and calls the one policy above.
Ra_quarter_goal_pools(shelf, pools, sources, pool, recent, barred):
    return this.Pool_goal({
        compartments: pools, sources_raw: sources || [], pooled_raw: this.Pool_cards_raw(pool ? this.Ra_recs(pool) : []),
        recent_raw: recent || [], latest_raw: this.Heard_latest(shelf), tally_raw: this.Ra_quarter_tally(shelf), barred_raw: barred || {},
    })
Ra_quarter_diff(goal, pool, lib):
    return this.Pool_diff(goal, {
        pooled_raw: this.Pool_cards_raw(pool ? this.Ra_recs(pool) : []),
        held_raw: (lib ? this.Ra_recs(lib) : []).map((r) => String(r.sc.id || '')).filter(Boolean),
    })
// Ra_quarter — the SIT-DOWN: goal → diff → provision, then rest.  Idempotent the way a steward must
//  be: wants oai-mint per (of, do) so an unchanged world re-sits to the SAME rows (zero mint, zero
//   drop — "a good stash stays the stash"), and a want whose reason left the diff is dropped (served
//    or displaced — either way stale).  Returns {goal, diff, wants} for a Book or a face.
// Ra_quarter_roll — THE ROLL IS A POLICY NUMBER, NOT A SIDE EFFECT (2026-09-15, the Daemon_todo §0.0 survey):
//  a holder whose shelf itself rolls (the daemon digs ~1 record/90s and culls past ~44) puts a fresh id
//   into the hash-ranked draw every pass, and at cap every fresh id that ranks in displaces a held copy —
//    one swap per steward pass ≈ one transcode on the holder + ~4 MB, forever, per pooler. "Keeps rolling"
//     is the sentence, so it rolls — at most one displacement per Ra_pool_roll_ms. A Nay/Meh evict always
//      goes through (it is a reaction, not the roll); under cap nothing is held back, the pool just fills.
//       Live pages only: a Book's passes are its fixtures' clock, not the wall's.
Ra_pool_roll_ms():
    return this.Pool_knobs().roll_ms
Ra_quarter_roll(w, diff, barred, pooled_n, cap_n):
    let M = this.top_House ? this.top_House() : null
    if (!M || !M.c.humdinger || !w) { return diff }
    let now = Date.now()
    let due = !w.c.pool_roll_at || (now - w.c.pool_roll_at) >= this.Ra_pool_roll_ms()
    let r = this.Pool_roll(diff, barred, due, pooled_n, cap_n)
    if (r.rolled) { w.c.pool_roll_at = now }
    return r.diff

Ra_quarter(w, shelf, pool, lib, cap, sources, facts):
    // RECENT ACQUISITIONS = MY LANDED TAKES, newest first, read HERE rather than inside the goal builder,
    //  which must stay pure and world-less (every pool fixture calls it directly with hand-built pools).
    //  It read a dontSnap %Hauls>%Newly>%Fresh mirror of the DISK's arrivals ledger until 2026-09-04 — a
    //   mirror that existed only because the ledger is an async disk read and this builder is synchronous.
    //    The heard Mag is both durable and already in memory, so there is nothing to mirror: a take Card
    //     whose track is now on my shelf IS an acquisition, and it carries the moment I asked (Heard.g).
    try { this.Ra_pool_caps_apply(w) } catch (er) {}   // re-weigh: the per-track MB moves as the pool fills
    let recent = this.Heard_landed_ids ? this.Heard_landed_ids(w, this.Radio_pub(w) || '', lib) : []
    let barred = this.Heard_barred_ids ? this.Heard_barred_ids(w, this.Radio_pub(w) || '') : {}
    let pdefs = this.Ra_pool_defs(w, cap)
    let goal = this.Ra_quarter_goal_pools(shelf, pdefs, sources, pool, recent, barred)
    let diff = this.Ra_quarter_roll(w, this.Ra_quarter_diff(goal, pool, lib), barred, (pool ? this.Ra_recs(pool) : []).length, this.Pool_cap_sum(pdefs))
    // step 2 (§0.2a): a pure comparison, never a decision — Pool_policy_compare only logs
    if (facts) { try { this.Pool_policy_compare(w, facts, diff) } catch (er) {} }
    let phome = this.Ra_pool_home_mint(w)
    let out = phome.oai({ Provisions: 1 })
    out.c.up = phome
    let fresh = {}
    for (const d of diff) fresh[d.of + '|' + d.do] = d
    for (const want of out.o({ Want: 1 }).slice()) {
        if (!fresh[String(want.sc.of) + '|' + String(want.sc.do)]) out.drop(want)
    }
    for (const k of Object.keys(fresh)) {
        let d = fresh[k]
        let want = out.oai({ Want: 1, of: d.of, do: d.do })
        want.c.up = out
        if (want.sc.why !== d.why) want.sc.why = d.why
        // the compartment the want provisions FOR — the Door face's composition column.  Only a
        //  declared pool stamps (the anonymous pool stamps nothing, keeping old snaps byte-identical).
        // the want particle is found-or-created on (of, do) ALONE, so a row re-used by a different
        //  compartment must SHED the old stamps — else a track that moved from the random pool to the
        //   liked one keeps booking fills at a holder it no longer comes from (2026-09-03 review).
        if (d.pool) { if (want.sc.pool !== d.pool) want.sc.pool = d.pool } else if (want.sc.pool != null) { delete want.sc.pool; want.bump() }
        // a circulation want names its HOLDER — the fill books toward it (Ra_pool_fill_wants)
        if (d.from) { if (want.sc.from !== d.from) want.sc.from = d.from } else if (want.sc.from != null) { delete want.sc.from; want.bump() }
    }
    return { goal: goal, diff: diff, wants: out.o({ Want: 1 }).length }
// Ra_quarter_serve — the DISPOSE half the doc's steward hands to the flows (§6 "proposes; flows dispose").
//  Ra_quarter PROPOSED the %Wants; this enacts the ones a LONE body can honour with no Cave and no friend
//   on the wire: `press` (the library holds the Original locally, so a v1 byte-copy lands it in the pool
//    through the SAME Heist_catalog_land door Ra_press owns — never a parallel minter) and `evict` (a
//     pooled track that fell out of the goal is dropped from the pool shelf).  A `pull` want is LEFT
//      STANDING — it needs a foreign body (the Cave's press-over-wire, or a friend's exchange), a flow this
//       seam cannot honour, so it stays a legible want for that flow to serve.  So this writes no pool
//        POLICY; it enacts the already-minted decision, and only the half one body owns.  Idempotent by
//         composition: a served press leaves the track pooled, so the NEXT Ra_quarter drops that want and a
//          re-serve finds nothing to press.  Returns {pressed, evicted, deferred, fails}.  Dormant until a
//           live steward occasion (a play-session end, a jam, the Cave reachable) calls it — no live caller
//            yet, so it is inert exactly like the pool landing it feeds (Portability_doc §6).

async Ra_quarter_serve(w, nav, shelf, pool, lib, cap, sources):
    try { this.Ra_pool_caps_apply(w) } catch (er) {}   // weigh FIRST, so the facts carry this pass's caps, not last pass's
    let facts = null
    try { facts = this.Pool_facts(w, null) } catch (er) { facts = null }
    this.Ra_quarter(w, shelf, pool, lib, cap, sources, facts)
    let prov = this.Ra_pool_provisions(w)
    let out = { pressed: 0, evicted: 0, deferred: 0, fails: 0 }
    if (!prov) return out
    for (const want of prov.o({ Want: 1 }).slice()) {
        let of = String(want.sc.of || '')
        let doo = String(want.sc.do || '')
        if (!of) continue
        if (doo === 'press') {
            let r = await this.Ra_press(w, nav, lib, pool, of)
            if (r && r.fail) { out.fails = out.fails + 1 } else { out.pressed = out.pressed + 1 }
        } else if (doo === 'evict') {
            let erec = this.Ra_rec_find(pool, { Record: 1, id: of })
            let egone = await this.Ra_pool_unfile(w, nav, erec)   // the bytes go with the card
            // REMEMBER THE EVICTION FOR THE SESSION (2026-09-06, eed's log: "evicted 6 → recovered 4 from disk →
            //  encoded a preview → evicted 6 …" every pass, six whole-file encodes a cycle).  Whatever the reason
            //   the file lingers (bin_rm answered true, the file was still there), the resurrect must not re-adopt
            //    what the steward just threw out, or the two fight forever.  .c on the radio world (session
            //     matter, never snapped); Ra_pool_off clears it; a fresh landing at the same path clears its mark.
            if (erec && erec.sc.path) {
                let ev = (w.c.pool_evicted = w.c.pool_evicted || {})
                ev[String(erec.sc.path)] = egone ? 'gone' : 'lingering'
            }
            let dropped = await this.Ra_rec_drop(pool, of)
            out.evicted = out.evicted + dropped
        } else {
            out.deferred = out.deferred + 1
        }
    }
    return out
// Ra_upgrade_scan — the SMUGGLE's Cave-side consequence (Portability_doc §8 Flow 4: "the backup is thereby
//  also the upgrade queue").  A pool copy that reaches the Cave for backup carries its `of:<origId>` +
//   `grade` cross-fidelity join, so the Cave can read it as "a lofi thing whose Original I may not hold" and
//    queue the fetch.  This walks the backup crate and, for every lofi copy (a Record wearing BOTH `of:` and
//     `grade` — the pool-press shape Ra_rec_pool mints) whose Original the library does NOT already hold,
//      mints an `%Upgrade,of:<origId>` under `%Upgrades` — a legible queue the heist flow (Flow 1) later
//       serves by fetching the Original under whatever grant the friendship carries.  A copy whose Original
//        IS held draws no upgrade (pure backup, nothing to fetch).  Idempotent the Ra_quarter way: upgrades
//         oai per `of:` so an unchanged crate re-scans to the SAME rows, and an upgrade whose Original has
//          since ARRIVED (or whose backup copy is gone) is dropped — the queue follows the hoard, the pool's
//           expendability underwritten (bytes may die with the browser; this ledger lives on the Cave disk).
//  Model-legible with no byte moving (MusuSmuggle), the propose-side twin of the steward — it queues; the
//   heist disposes.  Returns {queued, held} — how many upgrades stand, and how many copies needed none.
Ra_upgrade_scan(w, lib, backup):
    let held = {}
    for (const r of this.Ra_recs(lib)) {
        if (r.sc.id && !r.sc.of && !r.sc.grade) held[String(r.sc.id)] = 1
    }
    let need = {}
    let satisfied = 0
    for (const r of this.Ra_recs(backup)) {
        if (!r.sc.of || !r.sc.grade) continue
        let orig = String(r.sc.of)
        if (held[orig]) { satisfied = satisfied + 1; continue }
        need[orig] = 'lofi backed up — original not yet held'
    }
    let out = w.oai({ Upgrades: 1 })
    out.c.up = w
    for (const up of out.o({ Upgrade: 1 }).slice()) {
        if (!need[String(up.sc.of)]) out.drop(up)
    }
    for (const orig of Object.keys(need)) {
        let up = out.oai({ Upgrade: 1, of: orig })
        up.c.up = out
        if (up.sc.why !== need[orig]) up.sc.why = need[orig]
    }
    return { queued: out.o({ Upgrade: 1 }).length, held: satisfied }
//#endregion

//#region the POOL-FILL REACH — SoundPooling_todo §0.5 Flow 4 (Cave → Captain), the live doer binding
// "Cave will have a huge library and Captain wants some at all times via SoundPooling" (owner
//  2026-09-02).  The Captain BOOKS a standing %Reach (to:'Cave', for:'serve' — the boundary law:
//   standing intent = Reach; bytes+doing = the Heist/Siphon doers; the POOL is the liquid
//    destination) and the crew Cave's live doer serves it from its OWN library (the §3/§4
//     lib-mapping tripwire honoured: never press-what-streams-through).  Every verb here BINDS
//      proven parts — Swarm_reach_* (SwarmBody beats 10–23), Siphon_pull → Ra_press →
//       Heist_catalog_land (MusuPress / Siphonation) — and invents no transport: the artifact
//        crosses through a nav read (a crew-mirror lib the Captain's nav can read), which is the
//         same seam the live Repli byte-lane will stand behind when it lands.  Book-gated by
//          MusuPoolFill (Ghost/Story/HeistTesting.g).

// Ra_pool_fill_book — the Captain's booking seam: a standing %Reach toward my crew Cave asking it
//  to make `origId` servable for my pool.  Role-addressed (to:'Cave' — Swarm_reach_addr resolves
//   the roster row, so the booking survives the Cave re-keying) and it only books when a Cave
//    actually stands on my roster — no crew Cave, no intent to fake.  Dispatch is kicked once
//     (wire inert without a station; the settle loop is the retry), and the reach STANDS while
//      the Cave is away — that is the whole point of booking over calling.
Ra_pool_fill_book(w, ident, origId, to):
    if (!w || !ident || !origId) { return null }
    let target = String(to || 'Cave')
    // a ROLE target must stand on my roster (no crew Cave, no intent to fake); a NAMED holder (a friend's
    //  routing name off a circulation want) is the address itself — Swarm_reach_addr passes it through.
    let role = target === 'Cave' || target === 'Captain'
    if (role) {
        let body = this.Swarm_body_for ? this.Swarm_body_for(ident, target) : null
        if (!body) { return null }
    } else if (!/^[0-9a-f]{16}/.test(target)) {
        // A NAME MUST BE ROUTABLE (2026-09-03 review): a mirror crate keyed by a placeholder ('Crowd', the
        //  Repli fallback) would dispatch to a station pier that oai-mints itself — a %Pier per bogus
        //   holder.  A real routing name is a key-derived prepub; anything else books nothing.
        return null
    }
    let reach = this.Swarm_reach_book(w, ident, { to: target, of: String(origId), for: 'serve' })
    if (reach) { this.Swarm_reach_dispatch(w, ident, reach) }
    return reach
// Ra_pool_fill_wants — THE BRIDGE from the steward's wants to standing bookings: every 'pull' want that
//  names a holder (a circulation want) books a fill toward that holder; a pull with no holder stays a
//   legible want (nobody to ask).  Idempotent (reach_book finds-or-creates on to·of·for).  Declaring a
//    'random' pool IS the consent — the gesture is the compartment, not a button per track.
Ra_pool_fill_wants(w, ident):
    let out = this.Ra_pool_provisions(w)
    if (!out || !ident) { return 0 }
    let n = 0
    let fresh = 0
    // BUDGETED (2026-09-03 review): the %Reach shelf is capped and shared with the ceremony, the charter
    //  and the heist, and a circulation booking stands for as long as its holder is away.  Book a few per
    //   pass — the next sit-down books the next few — so a cap-12 pool can never crowd the shelf out.
    // SERIALLY (the owner 2026-09-05: *"is it downloading 4 at once? that's silly, do them serially"*).  Four
    //  in flight raced for the same wire the radio is streaming over, and four standing rows is four frames per
    //   re-dispatch pass.  One want at a time: it lands, the reach is dropped, the next sit-down books the next.
    //  A KNOB, DEFAULT ONE.  The live default is the owner's ruling; MusuPoolRandom pins it to 3 because what
    //   that Book actually swears is the FAN-OUT — three wants addressed to the right three holders — which is a
    //    different question from how many we choose to have in flight at once.  Pacing is policy; addressing is law.
    // SLOSH, DON'T TRICKLE (the owner 2026-09-12: "ten minutes and eed has only 1 SP, far too slow… I want it to
    //  slosh in. we have consented to 3gb").  Supersedes the 2026-09-05 "do them serially": three in flight, and
    //   the landing's in-flight gate below matches (POOL_PARALLEL).  `w.c.pool_fill_budget` still pins a Book.
    let budget = (w && w.c && w.c.pool_fill_budget != null) ? +w.c.pool_fill_budget : this.Pool_knobs().fill_budget
    // A RECENT FETCH FAILURE IS A MEMORY, NOT A RETRY-FOREVER INVITE (rung 4, SoundPooling_todo §0.0):
    //  Heard_pool_take/Heard_clone_beat now stamp a pool keep's verdict onto its OWN Card exactly as for
    //   a human keep, so `landing_failed_at` newer than the Mag's own heard_ttl means "already tried this
    //    recently, it didn't work" — skip re-booking until the memory ages out, the same clock a bare
    //     hearing forgets by.  Resolved once, outside the loop.  The stamp lives on the Card's POOL ROAD
    //      (Heard_road — the Card itself for a machine press, a %Road child under a human ♥ the pool is
    //       also fetching; rung 5), so a human take's own verdicts never gate the pool and vice versa.
    let hmag = this.Heard_mag_find ? this.Heard_mag_find(w, String(ident.sc.prepub || '')) : null
    let hnow = this.Heard_now ? this.Heard_now(w) : 0
    let hbadTtl = (+((hmag && hmag.sc.heard_ttl) || 30)) * 86400
    for (const want of out.o({ Want: 1, do: 'pull' })) {
        if (fresh >= budget) { break }
        let from = String(want.sc.from || '')
        let of = String(want.sc.of || '')
        if (!from || !of) { continue }
        let hcard = hmag ? this.Heard_find(hmag, of, from) : null
        let hroad = (hcard && this.Heard_road) ? this.Heard_road(hcard, 'pool') : null
        if (hroad && hroad.sc.landing_failed_at && (hnow - +hroad.sc.landing_failed_at) < hbadTtl) { continue }
        // ONLY WHAT IS NOT ALREADY IN FLIGHT (2026-09-05: *"steward: booked 4 circulation fill(s)"* hundreds of
        //  times in a row).  This pass runs from the pump's null-dial retry — every 800ms on an empty pool — and
        //   Ra_pool_fill_book is find-or-create + dispatch, so the same four wants were re-booked, re-stamped and
        //    RE-SENT on every retry.  The settle loop already re-dispatches a standing reach on its own cadence.
        //  The COUNT stays idempotent — a standing want is still a booked want (MusuPoolRandom's rebook_idempotent
        //   swears the second pass reports the same three) — only the re-book, re-stamp and re-send are skipped;
        //    `w.c.pool_fill_fresh` carries how many were actually NEW so the steward's line fires only on news.
        // ⚠ A STANDING WANT MUST NOT SPEND THE BUDGET (2026-09-06, eed measured live).  The budget is SERIAL
        //  (1 by the owner's ruling) and this line counted an ALREADY-STANDING reach against it — so the first
        //   such want broke the loop and no fresh want was ever booked again.  eed sat on six reaches to a closed
        //    Incognito window; they spent the whole budget every pass, forever, and the pool never filled from the
        //     one peer that was actually alive.  Pacing is about how many pulls are IN FLIGHT AT ONCE, and a reach
        //      to a dead peer is not a pull in flight: the budget bounds NEW bookings (fresh), never the tally.
        //  n still counts standing wants — the caller's idempotence contract (MusuPoolRandom's rebook_idempotent
        //   swears a second pass reports the same three) — it just no longer gates the loop.
        if (this.Swarm_reach_standing && this.Swarm_reach_standing(ident, from, of, 'serve')) { n = n + 1; continue }
        // A TERMINAL WANT IS DONE, NOT MERELY "NOT STANDING" (2026-09-06): Swarm_reach_standing correctly
        //  excludes refused|dead (they are not live work), but that made this loop treat them as "book it" —
        //   re-calling Ra_pool_fill_book on the same permanently-refused track every steward pass forever.
        //    Skip it outright; the goal draw naming it again next sit-down is a separate, honest question.
        if (this.Swarm_reach_terminal && this.Swarm_reach_terminal(ident, from, of, 'serve')) { continue }
        if (this.Ra_pool_fill_book(w, ident, of, from)) { n = n + 1; fresh = fresh + 1 }
    }
    if (w && w.c) { w.c.pool_fill_fresh = fresh }
    return n

// Ra_pool_fill_homes — WHERE the fill reads and lands, resolved once per pass.  A Book stands its
//  own homes on the IDENTITY's .c (fill_mw + fill_lib/fill_pool/fill_nav/fill_from — runtime refs,
//   never sc) and that override is the WHOLE story (never mixed with live homes — a Book on a live
//    runner must not leak into the tab's radio world).  Live: the radio world's own homes — lib is
//     probe-first (a body with no library home has nothing to serve; never mint on a read), the
//      pool home may mint (we are about to press into it), `from` is the crew mirror (probe-first
//       %Theirs of my roster Cave) the landing reads the served artifact out of.
Ra_pool_fill_homes(w, ident):
    let out = { mw: w, lib: null, pool: null, nav: null, from: null }
    if (ident && ident.c && ident.c.fill_mw) {
        out.mw = ident.c.fill_mw
        if (ident.c.fill_lib) { out.lib = ident.c.fill_lib }
        if (ident.c.fill_pool) { out.pool = ident.c.fill_pool }
        if (ident.c.fill_nav) { out.nav = ident.c.fill_nav }
        if (ident.c.fill_from) { out.from = ident.c.fill_from }
        return out
    }
    let top = this.top_House ? this.top_House() : null
    let rw = (top && top.c) ? top.c.radio_w : null
    if (!rw) { return out }
    out.mw = rw
    let pub = this.Radio_pub ? this.Radio_pub(rw) : null
    if (!pub) { return out }
    if (rw.oa({ Mine: 1, pub: pub })) { out.lib = this.Ra_home_self(rw, pub) }
    out.pool = this.Ra_home_pool(rw, pub)
    // THE LIVE NAV, NOT ONLY THE BOOK'S (2026-09-05, eed→daemon measured live).  `w.c.ra_nav` is pinned
    //  ONLY by Books (Heistation's MusuNeGrind_nav); a live tab never sets it.  Every sibling seam in this
    //   file reads `ra_nav || Crate_nav()` (:839 :1304 :2058 :2726 :2790) — this one alone read `|| null`,
    //    so on BOTH live ends `homes.nav` was null: the daemon's Ra_pool_fill_serve `continue`d every
    //     serving reach (stuck `serving`, never `refused`, no line), and eed's Ra_pool_fill_land skipped
    //      every arrival.  A silent skip on a missing nav is the worst shape — Siphon_pull already names
    //       `no nav` as a fail; let it get that far.
    out.nav = rw.c.ra_nav || (this.Crate_nav ? this.Crate_nav() : null)
    // PREFER A CAVE WE HAVE ACTUALLY HEARD FROM (2026-09-08 — Social_demarcation §1).  This exact line is
    //  where the 36-hour SoundPooling outage lived: it drew every circulation fill from a crew Cave that
    //   was a browser window closed several sessions earlier, and nothing anywhere said so.  The clock
    //    turns on the roster's liveness preference; with no Swarm (a Book) it is absent and the pick is
    //     byte-identical to before.
    let now_s = (typeof this.Swarm_now === 'function') ? this.Swarm_now(w) : 0
    // (no ident ⇒ no roster to pick from; a world-only caller — the CLI poke — used to throw here)
    let cave = (ident && this.Swarm_body_for) ? this.Swarm_body_for(ident, 'Cave', now_s) : null
    // AND SAY IT, when the only Cave on the roster is one the Door would call away.  A preference that
    //  falls back silently rebuilds the original defect one layer down: the fill still goes to a ghost,
    //   and the log still reads exactly like a slow peer.  Throttled to once a minute per identity —
    //    this resolves every pass, and a heartbeat is not a reason to shout.
    if (cave && now_s && this.Swarm_body_away && this.Swarm_body_away(cave, now_s)) {
        let said = ident.c ? (+ident.c.cave_away_said || 0) : 0
        if (!said || (now_s - said) > 60) {
            if (ident.c) { ident.c.cave_away_said = now_s }
            console.log('🏊⚠ pool fill is drawing from a Cave we have not heard from (' + String(this.Swarm_body_addr(cave) || '?').slice(0, 8) + ') — it may be a closed tab')
        }
    }
    let cavename = cave ? this.Swarm_body_addr(cave) : ''
    if (cavename && rw.oa({ Theirs: 1, pub: cavename })) { out.from = this.Ra_home_them(rw, cavename) }
    return out
// Ra_pool_fill_from — WHOSE mirror a landing reads, per reach (2026-09-03 review): a circulation fill
//  names its holder on `to:` — a friend as often as the crew Cave — and reading the Cave's crate for a
//   friend's track can only ever miss (a phone with friends and no Cave had NO `from` at all, so every
//    circulation fill stalled at 'arrived' forever).  Probe-first: no crate for that holder, no landing.
Ra_pool_fill_from(w, ident, reach, homes):
    let to = String(reach && reach.sc ? (reach.sc.to || '') : '')
    if (!to || to === 'Cave' || to === 'Captain') { return homes.from }
    let rw = homes.mw
    if (rw && rw.oa && rw.oa({ Theirs: 1, pub: to })) { return this.Ra_home_them(rw, to) }
    return homes.from

// Ra_pool_fill_verdict — the SYNC tri-state probe Swarm_reach_serve's doer contract wants (truthy →
//  arrived · falsy → stays serving · {refuse:why} → refused).  PURE READ of what the async serve
//   pass left standing: a pool card standing (by id — a v1 press coincides — or by of: join) IS
//    served; a library that provably lacks the Original refuses honestly; a recorded press fail
//     refuses with its named why; cold homes are "not yet" (the retry covers a booting tab).
//  A FOREIGN verb returns FALSY, never a refusal: another layer's reach (a ceremony verb, a future
//   for:) must be left standing for ITS doer — refusing here would bury someone else's intent.
Ra_pool_fill_verdict(w, ident, reach):
    if (String(reach.sc.for || '') !== 'serve') { return 0 }
    // AN EXCUSED BODY REFUSES BEFORE IT EVEN LOOKS (2026-09-06) — cleanly, the same shape as
    //  not_in_library, so the booker sees exactly why and never re-asks this holder for anything.
    if (this.Ra_pool_excused_of ? this.Ra_pool_excused_of(ident) : this.Ra_pool_excused(w)) { return { refuse: 'excused' } }
    let of = String(reach.sc.of || '')
    if (!of) { return { refuse: 'no_content' } }
    let homes = this.Ra_pool_fill_homes(w, ident)
    if (!homes.pool) { return 0 }
    let standing = this.Ra_rec_find(homes.pool, { Record: 1, id: of }) || this.Ra_rec_find(homes.pool, { Record: 1, of: of })
    if (standing) { return 1 }
    if (homes.lib && !this.Ra_rec_find(homes.lib, { Record: 1, id: of })) { return { refuse: 'not_in_library' } }
    if (reach.c.fill_fail) { return { refuse: String(reach.c.fill_fail) } }
    return 0

// Ra_pool_fill_serve — the CAVE-SIDE serve tick (the Reach_todo §0 "still owed" doer binding).
//  For each inbound serving for:'serve' reach: make the asked track servable in MY OWN pool via
//   Siphon_pull (idempotent — a standing card moves not one byte; the one Heist_catalog_land door
//    mints the card), THEN run the one sync tri-state gate (Swarm_reach_serve + the verdict), THEN
//     report each terminal inbound ONCE to its booker (reach_done over the sibling lane; wire-inert
//      in a Book) and graduate the arrived copies — scaffolding, not ledger.  Returns the serve count.
async Ra_pool_fill_serve(w, ident):
    // DEFENCE IN DEPTH: the verdict above should already keep a reach off this identity, but a reach can
    //  reach 'serving' the instant BEFORE excuse is set — never press a byte for an excused body regardless.
    if (this.Ra_pool_excused_of ? this.Ra_pool_excused_of(ident) : this.Ra_pool_excused(w)) { return 0 }
    let peering = this.Swarm_peering ? this.Swarm_peering(ident) : null
    if (!peering) { return 0 }
    let serving = peering.o({ Reach: 1, state: 'serving' }).filter((r) => String(r.sc.for || '') === 'serve')
    if (serving.length) {
        let homes = this.Ra_pool_fill_homes(w, ident)
        for (const reach of serving) {
            let of = String(reach.sc.of || '')
            if (!of) { continue }
            if (!homes.lib || !homes.pool || !homes.nav) { continue }
            let standing = this.Ra_rec_find(homes.pool, { Record: 1, id: of }) || this.Ra_rec_find(homes.pool, { Record: 1, of: of })
            if (standing) { continue }
            if (!this.Ra_rec_find(homes.lib, { Record: 1, id: of })) { continue }
            let r = await this.Siphon_pull(homes.mw, null, homes.pool, homes.lib, of, homes.nav)
            if (r && r.fail && !String(r.fail).startsWith('already pulling')) { reach.c.fill_fail = String(r.fail) }
        }
    }
    let n = this.Swarm_reach_serve(w, ident, (r) => this.Ra_pool_fill_verdict(w, ident, r))
    let mypub = String((this.Swarm_body_key ? this.Swarm_body_key(ident) : null)?.pub || '')
    for (const st of ['arrived', 'refused']) {
        for (const reach of peering.o({ Reach: 1, state: st })) {
            let by = String(reach.sc.by || '')
            if (!by) { continue }
            if (mypub && (mypub.startsWith(by) || by.startsWith(mypub))) { continue }
            if (reach.c.reported) { continue }
            reach.c.reported = 1
            this.Swarm_reach_report(w, ident, reach)
        }
    }
    if (n > 0) { console.log('🏊 pool-fill: served ' + n + ' reach(es) from my own library'); this.Swarm_reach_graduate(ident) }
    return n

// Ra_pool_fill_land — the CAPTAIN-SIDE landing: an outbound for:'serve' reach acked 'arrived' means
//  the Cave made the artifact servable — siphon it out of the crew mirror into MY OPFS pool (the
//   same Siphon_pull → Ra_press → Heist_catalog_land chain; the pool branch lights on mardir 'pool')
//    and drop the fulfilled reach.  No mirror / no nav → the reach STANDS 'arrived' as visible
//     awaiting-transport state (the live byte-lane is the named owed seam) — never a fake landing.
async Ra_pool_fill_land(w, ident):
    let peering = this.Swarm_peering ? this.Swarm_peering(ident) : null
    if (!peering) { return 0 }
    // AN EXCUSED BODY LANDS NOTHING FOR ITSELF EITHER (2026-09-06 self-review): excusing wipes consent and
    //  every %Pool def (Ra_pool_off), but never touched a booker's own STANDING reaches — this loop would
    //   still happily mint a %Heist,into:pool keep and pull bytes into a pool the body just declared it does
    //    not hold.  Whatever arrived while unexcused is stale intent now; drop it rather than land it, so an
    //     excuse actually means "holds no pool", not just "stops accepting new work".
    if (this.Ra_pool_excused_of ? this.Ra_pool_excused_of(ident) : this.Ra_pool_excused(w)) {
        let stale = peering.o({ Reach: 1, state: 'arrived' }).filter((r) => String(r.sc.for || '') === 'serve')
        for (const r of stale) { peering.drop(r) }
        return 0
    }
    let mypub = String((this.Swarm_body_key ? this.Swarm_body_key(ident) : null)?.pub || '')
    let landed = 0
    let arrived = peering.o({ Reach: 1, state: 'arrived' }).filter((r) => String(r.sc.for || '') === 'serve')
    for (const reach of arrived) {
        let by = String(reach.sc.by || '')
        // ⚠ THE BODY-KEY MISMATCH IS ALSO A SILENT SKIP, and it is the exact shape of drift this whole area is
        //  full of: eed's console this session logged "another live body … name contested" and a fresh "founding
        //   stamp" on EVERY reload.  If `Swarm_body_key` ever answers differently than the pub a reach was
        //    booked under, this row would sit 'arrived' FOREVER with no diagnostic — indistinguishable from the
        //     pool-fill homes miss below.  Name it the same way.
        if (by && mypub && !(mypub.startsWith(by) || by.startsWith(mypub))) {
            let miss = 'body key drifted (' + mypub.slice(0, 8) + ' vs booked-as ' + by.slice(0, 8) + ')'
            if (reach.sc.why !== miss) { reach.sc.why = miss; reach.bump(); console.log('🏊⚠ pool-fill cannot land ' + String(reach.sc.of || '').slice(0, 8) + ' — ' + miss) }
            continue
        }
        let of = String(reach.sc.of || '')
        if (!of) { continue }
        let homes = this.Ra_pool_fill_homes(w, ident)
        // ── LIVE: THE BYTES RIDE A HEIST KEEP (the plan, SoundPooling_todo §0.5 — the owner 2026-09-05: *"there's no
        //  byte-lane because it's reusing Heist isn't it?"*).  Reach carries the STANDING INTENT; the carry-out was
        //   always meant to delegate to the one byte doer every landing already rides — a `%Heist,into:pool` keep,
        //    the exact shape Radio_pool_catch mints for what is playing.  Heist_keep_step routes it to the holder
        //     (Swarm_station_pier), registers Repli, pulls the %Body chunks and lands through Heist_catalog_land's
        //      pool branch — which is where the preview carry lives.  Siphon_pull below stays as the BOOK's
        //       stand-in only (MusuPoolFill's world has no pier, no Repli, no relay — its lib IS local), gated by
        //        the same `fill_mw` override Ra_pool_fill_homes reads; a live tab never takes that road again.
        if (!(ident && ident.c && ident.c.fill_mw) && homes.pool && homes.mw) {
            let standingCard = this.Ra_rec_find(homes.pool, { Record: 1, id: of }) || this.Ra_rec_find(homes.pool, { Record: 1, of: of })
            if (standingCard) {
                landed = landed + 1
                peering.drop(reach)
                continue
            }
            let to = String(reach.sc.to || '')
            let me = this.Radio_pub ? (this.Radio_pub(homes.mw) || 'me') : 'me'
            let shop = this.Ra_home_shop(homes.mw, me)
            let keep = shop.o({ Heist: 1, seed: of })[0]
            if (keep) {
                // in flight — the keep's own state is the legible fact (HeistFace shows it); the reach waits.
                let kst = String(keep.sc.state || '')
                let why = 'heist ' + kst + (keep.sc.from_name ? ' from ' + String(keep.sc.from_name) : '')
                if (reach.sc.why !== why) { reach.sc.why = why; reach.bump() }
                continue
            }
            // K POOL HEISTS AT A TIME — three (the owner 2026-09-12: "I want it to slosh in"; was ONE, the owner 2026-09-05
            //  reading the live log: six rehydrated reaches arrived in
            //  one pass, six keeps were minted, and the one source stalled under all of them — "is it downloading
            //   four at once? that's silly, do them serially", one layer up).  A standing into:pool keep that is not
            //    done holds the rest in the queue; the reach says so on its row and waits its turn.
            let inflight = shop.o({ Heist: 1 }).filter((h) => this.Pool_is_machinery(h) && String(h.sc.state || '') !== 'done')
            let K = (w && w.c && w.c.pool_fill_parallel != null) ? +w.c.pool_fill_parallel : this.Pool_knobs().fill_parallel
            if (inflight.length >= K) {
                // A STUCK SINGLE-TRACK KEEP MUST NOT HOLD THE QUEUE HOSTAGE (2026-09-06, the owner's live log:
                //  "Giant Steps stalled 12/23" then nothing else ever landed).  The album heist's own bench
                //   escape ("one bad pick won't hold the whole album") has nothing to fall back to here -- a pool
                //    keep IS one pick -- so serialising to one-at-a-time turned one unreachable source into a
                //     permanent halt.  The pool's own law is liquid and expendable ("music kept moving"), so a
                //      keep that has sat 60s with no route AND no byte of progress is worth abandoning, not
                //       nursing: drop it and let the next want take this pass.  pull_progress_ts / no_route_ts
                //        are Heist_keep_step's own runtime fields (.c, never snapped) -- read, not duplicated.
                // ⚠ PATIENCE MUST OUTLAST THE SOURCE'S OWN WORK (2026-09-06, measured the moment the circuit first
                //  ran end to end).  The serving side answers a fill by TRANSCODING: the daemon's own log reads
                //   "lofi: 10 Sons of Light and Darkness.flac -> ogg128 (4021KB from 92690KB)" -- a 92MB FLAC, which
                //    takes minutes of ffmpeg, during which not one byte can move and the booker sees a frozen
                //     frontier.  A 60s give-up cancelled the keep at exactly the moment the source was working
                //      hardest, re-minted it, and cancelled it again forever: a livelock built out of impatience.
                //  So the windows are split by WHAT the silence means.  No ROUTE at all is a fast fact -- nobody is
                //   there, 60s is generous.  No PROGRESS while a route stands may be a source mid-encode, so it gets
                //    PRESS_PATIENCE (5 min): long enough for a big lossless file to render, short enough that a
                //     genuinely dead transfer still frees its slot within one sit-down.  The knob is world-side so a
                //      Book can shorten it, and the owner can lengthen it for a slow box without a recompile.
                let now = Date.now()
                let routeWait = 60000
                let pressWait = (w && w.c && w.c.pool_press_patience_ms != null) ? +w.c.pool_press_patience_ms : this.Pool_knobs().press_patience_ms
                let stuck = inflight.find((h) => {
                    let noRoute = +(h.c.no_route_ts || 0)
                    if (noRoute && now - noRoute > routeWait) { return true }
                    let started = +(h.c.pull_started_ts || 0)
                    if (!started) {
                        // A KEEP THAT NEVER STARTS IS THE WORST KIND OF STUCK (2026-09-06, eed measured live:
                        //  one keep sat 'primed' while TWENTY-ONE arrived reaches queued behind it, and the
                        //   give-up could not see it -- it only knew how to time a pull that had BEGUN).  A
                        //    keep with no route says so via no_route_ts above; this is the other silence, where
                        //     everything looks fine and nothing has happened.  Time it from when it was minted.
                        // …AND THE CLOCK MUST SURVIVE A RELOAD (2026-09-06, an hour later, the same keep: minted
                        //  20:32, the tab reloaded at 20:33, and the keep came back through the Berth with its
                        //   `.c` gone -- no fill_born, no pull timers -- so `born` read 0 and it was immortal
                        //    AGAIN, exactly the shape this block was written to end.  `sc.at` is the mint time
                        //     and it is snapped; it is the clock of last resort for a keep that has forgotten.
                        let born = +(h.c.fill_born || 0) || ((+(h.sc.at || 0)) * 1000)
                        return born > 0 && (now - born) > pressWait
                    }
                    let progressed = +(h.c.pull_progress_ts || started)
                    return (now - progressed) > pressWait
                })
                if (stuck) {
                    let name = String(stuck.sc.Heist || stuck.sc.seed || '?')
                    let stuckFor = Math.round((now - Math.max(+(stuck.c.pull_progress_ts || 0), +(stuck.c.pull_started_ts || 0), +(stuck.c.no_route_ts || 0))) / 1000)
                    console.log('🏊⚠ pool-fill: giving up on stalled heist "' + name.slice(0, 32) + '" (' + stuckFor + 's without a byte) -- trying the next track instead')
                    // THE PROPER ABANDON, NOT A RAW rm (2026-09-06 self-review): Heist_keep_cancel is the one road
                    //  that also drops the in-flight %Caper (Heist_job_drop) — a bare shop.rm leaves that job
                    //   pulling into an orphaned particle, the exact "close the Haul faster" bug Heist_keep_cancel's
                    //    own header was written to fix.  It no-ops the Heard_untake branch here (a fill keep carries
                    //     no `take`), so it is safe for a circulation keep, not just a human's ♥.
                    // THE REACH CAP EXPLAINED THE WALL (2026-09-12, eed: "reach cap reached (32)" flooding the
                    //  console — every NEW track was refused a booking outright, forever, because 32 standing
                    //   reaches never leaves 'arrived' — Swarm_reach_book counts anything not dead/refused, and
                    //    cancelling the LOCAL keep here never told the reach it was over.  A keep whose OWN husk
                    //     never arrived (no_route_ts — Heist_keep_pool_go's 45s wall-clock wait, tonight's other
                    //      fix) is not a transient failure to retry: the census genuinely cannot locate this
                    //       track under any name, and retrying changes nothing about that gap.  Refuse the reach
                    //        too, so it leaves 'arrived' and frees its cap slot for a track that CAN be found.
                    //  A mid-pull stall (PRESS_PATIENCE, no no_route_ts) stays retriable — that failure class can
                    //   be transient (a network hiccup), so only cancel+re-mint, same as before.
                    let permanent = !!stuck.c.no_route_ts
                    let stuckSeed = String(stuck.sc.seed || '')
                    if (typeof this.Heist_keep_cancel === 'function') {
                        try { await this.Heist_keep_cancel(homes.mw, stuck) } catch (er) {}
                    } else {
                        try { (stuck.c.up || shop).rm({ Heist: 1, seed: stuck.sc.seed }) } catch (er) {}
                    }
                    if (permanent && stuckSeed) {
                        let deadReach = peering.o({ Reach: 1, of: stuckSeed, for: 'serve' }).filter((r) => String(r.sc.state || '') !== 'refused')[0]
                        if (deadReach) {
                            this.Swarm_reach_refuse(w, ident, deadReach, 'never found on the source — census gave up locating it')
                            console.log('🏊✗ pool-fill: refusing ' + stuckSeed.slice(0, 8) + ' — its own file never turned up on the source, freeing the reach slot')
                        }
                    }
                } else {
                    let why = 'queued behind ' + inflight.length + ' pool heist' + (inflight.length === 1 ? '' : 's')
                    if (reach.sc.why !== why) { reach.sc.why = why; reach.bump() }
                    continue
                }
            }
            if (!to) {
                let miss = 'no holder to heist from'
                if (reach.sc.why !== miss) { reach.sc.why = miss; reach.bump(); console.log('🏊⚠ pool-fill cannot land ' + of.slice(0, 8) + ' — ' + miss) }
                continue
            }
            let srec = null
            if (homes.mw.oa({ Theirs: 1, pub: to })) { srec = this.Ra_rec_find(this.Ra_home_them(homes.mw, to), { Record: 1, id: of }) }
            let title = srec && srec.sc.title ? String(srec.sc.title) : of.slice(0, 8)
            let k = shop.i({ Heist: this.Radio_clean ? this.Radio_clean(title) : title, seed: of, pub: to, state: 'primed', into: 'pool', why: 'fill' })
            k.c.up = shop
            k.c.last_touch = Date.now()
            // THE MACHINE'S OWN PRESS (rung 4, SoundPooling_todo §0.0): the SAME Card a human ♥ mints,
            //  on the machine page (Heard_is_machine) — so Heard_clone_beat's verdict/listing machinery
            //   works identically, and a fetch failure becomes a real memory (Ra_pool_fill_wants' re-want
            //    guard below) instead of vanishing the moment the wedged keep flattens.
            if (this.Heard_pool_take) { try { this.Heard_pool_take(homes.mw, String(ident.sc.prepub || ''), of, to, title, srec ? srec.sc.artist : null) } catch (er) {} }
            // A BIRTH CLOCK NOBODY ELSE WINDS (2026-09-06).  The give-up below timed a never-started keep from
            //  last_touch -- which Heist.g rewrites in ten places as its "recently touched" focus marker, so the
            //   timer reset on every pass and a keep stuck at 'primed' was immortal.  eed measured it: ONE keep
            //    holding twelve arrived reaches behind it indefinitely.  fill_born is written here, once, and
            //     read only by the give-up; no other file touches it, so the age it reports is the real one.
            k.c.fill_born = Date.now()
            if (this.Heist_keep_born) { this.Heist_keep_born(k, this.Swarm_now ? this.Swarm_now(w) : 0) }
            if (this.Radio_friendly) { let fn = this.Radio_friendly(homes.mw, to); if (fn) { k.sc.from_name = fn } }
            if (srec && srec.sc.artist) { k.sc.artist = this.Radio_clean ? this.Radio_clean(srec.sc.artist) : String(srec.sc.artist) }
            let why = 'heist primed' + (k.sc.from_name ? ' from ' + String(k.sc.from_name) : '')
            reach.sc.why = why
            reach.bump()
            console.log('🏊⇊ pool-fill: heisting ' + title.slice(0, 32) + ' from ' + String(k.sc.from_name || to.slice(0, 8)) + ' into the pool')
            continue
        }
        let from = this.Ra_pool_fill_from(w, ident, reach, homes)
        // ⚠ NAME THE MISS (2026-09-05, eed measured live: four rows stuck 'arrived', pool empty, no line).
        //  A silent `continue` here is indistinguishable from "nothing to do" — and it is the state a listener
        //   experiences as "none playable". The holder pressed its copy, said arrived, and we had nowhere to pull
        //    FROM: `Ra_pool_fill_from` needs a %Theirs mirror of that holder, and mirrors are session matter that
        //     a reload sweeps. Stamp the reason on the row (legible in the snap) and say it once per reach.
        if (!homes.pool || !homes.nav || !from) {
            let miss = !homes.pool ? 'no pool shelf' : (!homes.nav ? 'no nav' : 'no mirror of ' + String(reach.sc.to || '').slice(0, 8) + ' to pull from')
            if (reach.sc.why !== miss) { reach.sc.why = miss; reach.bump(); console.log('🏊⚠ pool-fill cannot land ' + of.slice(0, 8) + ' — ' + miss) }
            continue
        }
        if (reach.sc.why) { delete reach.sc.why; reach.bump() }
        let got = await this.Siphon_pull(homes.mw, null, homes.pool, from, of, homes.nav)
        if (got && got.card) {
            landed = landed + 1
            if (homes.mw && homes.mw.c && homes.mw.c.pool_evicted && got.card.sc.path) { delete homes.mw.c.pool_evicted[String(got.card.sc.path)] }
            peering.drop(reach)
            continue
        }
        // ⚠ AND A PULL FAILURE MUST NAME ITSELF TOO (2026-09-05).  `Siphon_pull` already hands back `{fail:'…'}`
        //  on every dead end it knows about (no origId, no pool/lib shelf, no nav, already pulling) — this loop
        //   was throwing that reason away and looping forever with the exact same silence the homes-miss fix
        //    above was written to end.  `already pulling` is excluded: that is the NEXT pass about to succeed,
        //     not a fault worth alarming the row over.
        let why = got && got.fail ? String(got.fail) : 'pull returned nothing'
        if (!why.startsWith('already pulling') && reach.sc.why !== why) { reach.sc.why = why; reach.bump(); console.log('🏊⚠ pool-fill cannot land ' + of.slice(0, 8) + ' — ' + why) }
    }
    if (landed > 0) { console.log('🏊 pool-fill: landed ' + landed + ' pool cop' + (landed === 1 ? 'y' : 'ies') + ' from the crew mirror') }
    return landed

// Ra_pool_source_rec — WHO in this world holds a dialable %Record of this id: my own library first, then
//  any %Theirs mirror.  Pure read, probe-first (never mints a home or a shelf).  "Dialable" is the point —
//   a source with no preview of its own has nothing to lend.
Ra_pool_source_rec(rw, id):
    if (!rw || !id) { return null }
    let pub = this.Radio_pub ? this.Radio_pub(rw) : null
    if (pub && rw.oa({ Mine: 1, pub: pub })) {
        let mine = rw.o({ Mine: 1, pub: pub })[0]
        let stock = mine ? mine.o({ stock: 1 })[0] : null
        let hit = stock ? this.Ra_rec_find(stock, { Record: 1, id: id }) : null
        if (hit && +(hit.sc.preview || 0) > 0) { return hit }
    }
    for (const them of rw.o({ Theirs: 1 })) {
        let stock = them.o({ stock: 1 })[0]
        if (!stock) { continue }
        let hit = this.Ra_rec_find(stock, { Record: 1, id: id })
        if (hit && +(hit.sc.preview || 0) > 0) { return hit }
    }
    return null

// Ra_pool_previews_heal — the RETRO half of the carry.  Every track pooled BEFORE Ra_rec_previews_carry
//  existed is sitting on this device with its bytes present and no way to dial it, and nothing else will
//   ever go back for them: a landing happens once.  So the pump sweeps its own shelf — bounded at 4 a
//    pass, pure reads over records already standing in this world (never disk, never the wire) — and
//     lends each dark pool card the preview of whichever standing record shares its id.
//  It is also the ARRIVAL-ORDER fix, not only a migration: a keep can land its file before the source
//   mirror's own preview has finished crossing, and the carry at the landing tail would find nothing to
//    take.  This pass simply catches it on the next tick, so neither order strands a track.
async Ra_pool_previews_heal(w, ident):
    let homes = this.Ra_pool_fill_homes(w, ident)
    if (!homes.pool || !homes.mw) { return 0 }
    let healed = 0
    let encoded = 0
    for (const card of this.Ra_recs(homes.pool)) {
        if (healed >= 4) { break }
        if (+(card.sc.preview || 0) > 0) { continue }
        // A LOFI/GRADED CARD MAY NEVER *CARRY* A PREVIEW (2026-09-12, "SoundPool is a meagre 3" — found by
        //  watching, not guessing): carrying steals another record's waveform, wrong for a lofi rendition
        //   whose bytes genuinely differ (the comment on Ra_rec_previews_carry's own guard).  But that guard
        //    used to skip the card ENTIRELY, before the ENCODE rung below ever got a look — and encoding is
        //     exactly right for a lofi card: it re-reads THIS card's own bytes off disk and makes its own
        //      preview, no theft involved.  So: skip carrying, never skip encoding.
        if (!(card.sc.grade || card.sc.lofi)) {
            let src = this.Ra_pool_source_rec(homes.mw, String(card.sc.id || ''))
            if (src) { healed = healed + this.Ra_rec_previews_carry(card, src); continue }
        }
        // NOTHING TO BORROW → ENCODE ONE OURSELVES (2026-09-06, eed's log: "12 cards · 8 playable · 4 no
        //  preview" — and the four were exactly the daemon's real tracks).  The carry lends a preview from a
        //   standing record with the same id, and a track this body has NEVER HEARD has none anywhere: the
        //    mirror card for a circulation fill is a catalog row, its chunks only ever cross when you stream
        //     it.  So the last rung of "a track you never heard becomes dialable" is the pool encoding its
        //      OWN preview from the file it already holds — Ra_stock_one, the Stoker's per-file encoder,
        //       pointed at the pool shelf and the pool mount.  ONE a pass (a whole-file read + decode +
        //        opus encode), live only (a Book must never spin a real encoder), and only when the file is
        //         actually on disk (a card whose bytes are gone has nothing to encode).
        let top = this.top_House ? this.top_House() : null
        if (!top || !top.c || !top.c.humdinger || encoded > 0 || !homes.nav || !card.sc.path) { continue }
        let rel = String(card.sc.path)
        let files = homes.mw.c.pool_files || []
        if (!files.includes(rel)) { continue }
        encoded = encoded + 1
        let r = null
        try { r = await this.Ra_stock_one(homes.mw, homes.pool, homes.nav, 'pool', rel) } catch (er) { console.log('🏊⚠ pool encode failed for ' + rel.slice(0, 40) + ' — ' + String(er).slice(0, 80)); r = null }
        // Ra_record_from stamps path as base + '/' + path ('pool/<rel>'); a pool card's path is pool-relative
        //  (<rel>) everywhere else — unfile, resurrect, the report — so put it back the way the shelf keeps it.
        let again = this.Ra_rec_find(homes.pool, { Record: 1, id: String(card.sc.id || '') }) || card
        if (again && again.sc.path !== rel) { again.sc.path = rel; again.bump() }
        if (r && +(again.sc.preview || 0) > 0) {
            healed = healed + 1
            console.log('🏊 pool: ' + (r.stood ? 'resurrected the preview for ' : 'encoded a preview for ') + String(again.sc.title || rel).slice(0, 40) + ' — now dialable')
        }
    }
    if (healed > 0) { console.log('🏊 pool: ' + healed + ' pooled track(s) now dialable') }
    await this.Ra_pool_heads_heal(w, ident, homes)
    return healed

// Ra_pool_heads_heal — MAKE A POOLED TRACK START AT 0:00 (2026-09-10, the owner's two rulings: pool
//  items should begin "in the same conditions a remote radio track does", and the head "should be
//   generated like LOFI is" — i.e. holder-side, on demand).
//  A dialable pool card still opens a third to two thirds in, because its bytes ARE the offer and the
//   head run is a separate thing (`Ra_rec_heads_carry` carries the full account of why).  The head
//    machinery lives in `Ra_restock_beat`, which walks the MIRROR shelf only — pool cards are never
//     iterated by it, so nothing ever asked on their behalf.  This is that ask.
//  TWO RUNGS, the same shape as the preview heal above:
//   · the run already stands on a record of the same id here ⇒ CARRY it (free, no wire).
//   · else ASK ITS HOLDER — a `stream:'opus_head'` want, which is what makes the holder generate the
//      run (`Repli_serve_head` → `Ra_head_ensure` there), exactly the way the LOFI rendition is a
//       holder-side transcode.  The carry then picks it up on a later pass.
//  ONE CARD A PASS, deliberately.  A head is a median 47% of a song (measured over 54 records), so
//   fetching them is roughly a 1.95× on the pool's bytes — this must trickle, never sweep.  It also
//    rides the pool pump's own cadence rather than the streaming budget, which is the right pocket:
//     a pool head must never take a slot from the track someone is listening to right now.
async Ra_pool_heads_heal(w, ident, homes):
    if (!homes || !homes.pool || !homes.mw) { return 0 }
    for (const card of this.Ra_recs(homes.pool)) {
        if (+(card.sc.pv_off || 0) < 1) { continue }        // no cut point ⇒ the offer already starts at 0
        if (card.sc.grade || card.sc.lofi) { continue }
        if (this.Ra_head_whole(card)) { continue }          // already opens at the beginning
        let id = String(card.sc.id || '')
        let src = this.Ra_pool_source_rec(homes.mw, id)
        if (src && this.Ra_rec_heads_carry(card, src)) {
            if (w && w.c && w.c.ra_head_tries) { delete w.c.ra_head_tries[id] }   // it arrived — forget the count
            console.log('🏊 pool: carried the head run for ' + String(card.sc.title || id).slice(0, 40) + ' — starts at the beginning now')
            return 1
        }
        // GIVE UP EVENTUALLY (the restock beat's head ask has HEAD_ASK_CAP; this is its twin).  Without a
        //  bound, a head its holder will never serve — the peer is gone, the original file was moved, the
        //   encode fails there every time — costs one frame every pump pass, for ever, silently.  That
        //    trickle is exactly the shape this corpus keeps getting bitten by: nothing errors, nothing is
        //     obviously wrong, it simply never stops.  Bounded, and it SAYS SO when it stops, because a
        //      silent surrender is how you end up re-diagnosing this from scratch in a month.
        //  Cleared on success above, so a peer that comes back later is asked again from zero.
        let GIVEUP = +((w && w.c && w.c.pool_head_giveup) || 12)
        // ask the holder to make it.  Needs the source's live wire handles: a pool card is a local file
        //  and carries none of its own, which is why this asks THROUGH the standing source record.
        // ⚠ TWO WORLDS, AND THE WIRE IS NOT ON THE ONE THE SHELVES ARE ON.  `homes.mw` is the RADIO world
        //  (`Ra_pool_fill_homes`: `out.mw = top.c.radio_w`) — that is where Mine/Theirs/pool stock lives,
        //   which is why the lookup above uses it.  But `Repli_arm` and `repli_mirror_pier` are stamped on
        //    the SWARM world (`Swarm.g`, beside `w.c.repli_mirror_w = rw` — it keeps only a POINTER to the
        //     radio world).  So the ask must go through `w`, our own caller's world, not `homes.mw`.
        //  Written the wrong way first: gating on `homes.mw.c.repli_mirror_pier` is always falsy, so the
        //   ask would simply never fire — a silent no-op that looks exactly like "the feature does
        //    nothing", with no error to find. Check which world holds a `.c` key before reading it.
        if (!w || !w.c || !w.c.repli_mirror_pier) { continue }
        if (!src || !src.c || !src.c.from || !src.c.rx) { continue }
        let have = this.Ra_head_have(src)
        let hoff = 0
        let PAGE = +(w.c.repli_page || 2)
        while (hoff < +(card.sc.pv_off || 0) && have[hoff] != null) { hoff = hoff + PAGE }
        // one ask per id per 4s, the same throttle the restock beat's head ask uses
        w.c.ra_want_ts = w.c.ra_want_ts || {}
        let hkey = id + ':poolh' + hoff
        if (Date.now() - (w.c.ra_want_ts[hkey] || 0) < 4000) { continue }
        // THE POOL KEEPS ONLY WHAT STARTS AT THE BEGINNING (the owner 2026-09-12: "delete the non-full SP").  A copy
        //  its holder will not serve the head of is not worth its slot: bytes, card, and a session tombstone so the
        //   draw does not fetch the same id straight back (hash order never changes — it would churn 5 MB a pass).
        //  ⚠ COUNT ASKS, NOT PASSES (2026-09-12, the first cut emptied eed's whole pool within minutes of a reload):
        //   %Prehead never survives a reload (the protocol skips it by design), so every card is head-less at boot
        //    and the carry from the mirror takes a while; a counter that ticked on every pass — including passes
        //     where no holder could even be asked — reached 12 before anything had a chance.  The count now
        //      stands HERE, on a real ask to a live holder, 4 s apart: twelve unanswered asks is the verdict.
        w.c.ra_head_tries = w.c.ra_head_tries || {}
        let tries = +(w.c.ra_head_tries[id] || 0)
        if (tries + 1 >= GIVEUP) {
            await this.Ra_pool_cull_headless(w, homes, card, ident)
            delete w.c.ra_head_tries[id]
            return 1
        }
        w.c.ra_head_tries[id] = tries + 1
        w.c.ra_want_ts[hkey] = Date.now()
        await this.Repli_want_next(w, src.c.rx, w.c.repli_mirror_pier, src.c.from, id, 'opus_head', hoff)
        console.log('🏊 pool: asked ' + String(src.c.from).slice(0, 8) + ' to make the head run for ' + String(card.sc.title || id).slice(0, 40) + ' (from ' + hoff + '/' + card.sc.pv_off + ')')
        return 1
    }
    return 0

// Ra_pool_cull_headless — drop a pooled copy whose head run its holder never served, and tombstone the id
//  (`%Nohead,id` under the pool home — durable, so it rides the account snap with the rest of the shelf).
//   The pool's law is liquid and expendable; a track that can only ever open mid-song is the one thing the
//    listener said they do not want in it.  Bytes first, then the card, then the mark.
async Ra_pool_cull_headless(w, homes, card, ident):
    let id = String(card.sc.id || '')
    let nav = homes.nav || (w && w.c ? w.c.ra_nav : null) || (this.Crate_nav ? this.Crate_nav() : null)
    let gone = 0
    try { gone = await this.Ra_pool_unfile(w, nav, card) } catch (er) { gone = 0 }
    if (card.sc.path && w && w.c) {
        let ev = (w.c.pool_evicted = w.c.pool_evicted || {})
        ev[String(card.sc.path)] = gone ? 'gone' : 'lingering'
    }
    await this.Ra_rec_drop(homes.pool, id)
    if (w && w.c) { (w.c.pool_nohead = w.c.pool_nohead || {})[id] = 1 }
    console.log('🏊✂ pool: dropped ' + String(card.sc.title || id).slice(0, 40) + ' — its holder never served the head run; the pool keeps only tracks that start at the beginning')
    return 1
// Ra_pool_nohead — is this id tombstoned as headless THIS SESSION?  The draw (Ra_pool_sources) skips it; a reload
//  forgives (the holder may serve it next time).  Any durable %Nohead row (the 2026-09-12 first cut) is dropped
//   on sight — those were minted by the pass-counting bug, not by a holder's silence.
Ra_pool_nohead(w, id):
    let home = this.Ra_pool_home(w)
    if (home) { for (const t of home.o({ Nohead: 1 })) { home.drop(t) } }
    return !!(w && w.c && w.c.pool_nohead && w.c.pool_nohead[String(id)])

// Ra_pool_fill_pump — the ONE live tick (rides Swarm_reach_pump's cadence, knob-gated there by
//  w.c.reach_on): serve what my crew booked on me, land what my crew served for me.  Re-entrant
//   guard on .c (the async passes may outlive a 5s cadence under a real press).
async Ra_pool_fill_pump(w, ident):
    if (!w || !ident) { return 0 }
    // A BUSY LATCH MUST EXPIRE (2026-09-12, eed after Heist_start_over: the pump sat "busy" for ten minutes — an
    //  await inside outlived the files it was waiting on — and nothing booked, landed or healed again until a
    //   reload).  A tick that has held the latch past two minutes is not busy, it is dead; the next tick takes over.
    if (w.c.pool_fill_busy && Date.now() - (+w.c.pool_fill_busy) < this.Pool_knobs().pump_latch_ms) { return 0 }
    if (w.c.pool_fill_busy) { console.log('🏊⚠ pool-fill pump: the last tick never finished (' + Math.round((Date.now() - (+w.c.pool_fill_busy)) / 1000) + 's) — taking the latch back') }
    w.c.pool_fill_busy = Date.now()
    let n = 0
    try {
        n = await this.Ra_pool_fill_serve(w, ident)
        await this.Ra_pool_fill_land(w, ident)
        // and make what is ALREADY pooled dialable — the landing tail carries previews forward from now
        //  on, this catches everything that landed before it existed (and any keep whose source preview
        //   crossed after its bytes did).  Cheap when there is nothing dark: one shelf walk of scalars.
        await this.Ra_pool_resurrect(w, ident)
        await this.Ra_pool_previews_heal(w, ident)
        // THE STEWARD SITS DOWN WHILE THE MUSIC PLAYS, TOO (2026-09-12, eed: wants wiped by a start-over, the radio
        //  mid-track — and the pool stayed at 1 for ten minutes, because Radio_pump_tick only seats the steward on
        //   its `!rec` branch, i.e. between tracks.  A pool that refills only at the seams is not "always up".
        //    Once a minute from the fill pump is enough: the goal draw is cheap and the booking is budgeted.)
        let top = this.top_House ? this.top_House() : null
        let rw = top && top.c ? top.c.radio_w : null
        let radio = rw ? rw.o({ Radio: 1 })[0] : null
        if (rw && radio && typeof this.Radio_pool_steward === 'function' && Date.now() - (+(rw.c.pool_steward_at || 0)) > 60000) {
            rw.c.pool_steward_at = Date.now()
            await this.Radio_pool_steward(rw, radio)
        }
    } catch (er) { console.log('🏊⚠ pool-fill pump: ' + er) }
    delete w.c.pool_fill_busy
    return n
//#endregion
