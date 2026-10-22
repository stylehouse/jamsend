// WorkshopTesting.g — the Workshop's proof (Ghost/L/Workshop.g; spec/Verbs_todo.md §5).  Book: WorkshopStaple.
//
//  The Workshop is MAKE · SEE · PROVE in one room; this is the PROVE half, and it doubles as the pattern a kid's own
//   creation Book would copy: stand the creation, step it by hand (deterministic — its own clock is skipped), and swear
//    in plain sentences what happened.  The starter, Ghost/Play/Garden.g, is the creation sworn about.
//  A Book steps the garden ITSELF rather than waiting on the Workshop's heart: the heart only beats while the cave is
//   watching (a Book has no cave), and a Story step must never ride a wall-clock (CLAUDE.md).  Beat 5 swears that too.

IMPORT()

WorkshopStaple(A,w):
    w oai %req:wrangle,eternal
        await &WorkshopStaple_drive,w,req
        req%ok = 1

async WorkshopStaple_drive(w, req):
    let run = this.c.run
    if (run && run.sc && run.sc.mode === 'new') run.sc.total = 6
    let n = run?.c.step_n
    if (n != null && n !== req.c.did_step) {
        req.c.did_step = n
        if (n === 2) this.WorkshopStaple_stand(w)
        if (n === 3) this.WorkshopStaple_grow(w)
        if (n === 4) this.WorkshopStaple_cycle(w)
        if (n === 5) this.WorkshopStaple_heart(w)
        if (n === 6) this.WorkshopStaple_list(w)
    }
    this.WorkshopStaple_witness(w)

// the garden's world, on this Run House
WorkshopStaple_gw(w):
    return this.o({ A: 'Garden' })[0]?.o({ w: 'Garden' })[0] ?? null

// one garden step, by hand: open the creation's own clock for exactly one step, then FREEZE it again.  The Run House ticks
//  every world it holds, Garden included, so a garden left on its own clock takes steps between beats — the first recording
//   caught exactly that (one stray step shifted every snapshot: a petal at step 7 the rules never grow).  Frozen (last = ∞),
//    Garden's own gate returns on every tick, and only these hand steps move it.
WorkshopStaple_step(gw):
    gw.c.last = 0
    this.Garden(null, gw)
    gw.c.last = Infinity

// what the garden holds, said plainly: Kind:name[petals] in order
WorkshopStaple_say(gw):
    let bits = []
    for (const p of gw.o()) {
        let mk = Object.keys(p.sc)[0]
        if (mk === 'self' || mk === 'see' || mk === 'req') continue
        let petals = p.o({ Petal: 1 }).length
        bits.push(mk + ':' + p.sc[mk] + (petals ? '[' + petals + ']' : ''))
    }
    return bits.join(' ')

WorkshopStaple_stand(w):
    i %desc:'load the Workshop and the Garden — stand the garden on this run'
    this.expecting(w, 'stand_wait', 20, async () => {
        let top = this.top_House()
        if (typeof top.verbs_Workshop !== 'function') {
            await top.Lies_ghost_set('Ghost/L/Workshop.g')
            await this.WorkshopStaple_await(w, 12, () => typeof top.verbs_Workshop === 'function')
        }
        if (typeof top.Garden !== 'function') {
            await top.Lies_ghost_set('Ghost/Play/Garden.g')
            await this.WorkshopStaple_await(w, 12, () => typeof top.Garden === 'function')
        }
        let old = this.o({ A: 'Garden' })[0]
        if (old) this.drop(old)
        let gw = this.i({ A: 'Garden' }).i({ w: 'Garden' })
        gw.c.last = Infinity
        w.c.stood = typeof this.Garden === 'function' && !!this.WorkshopStaple_gw(w) ? 1 : 0
    })

WorkshopStaple_grow(w):
    i %desc:'step the garden — a seed is planted then sprouts then flowers with five petals'
    let gw = this.WorkshopStaple_gw(w)
    if (!gw) return
    let seen = []
    // the rules, traced: planted at step 1, sprouts at 4 (SPROUT_AT 3), flowers at 7 (BLOOM_AT 3), a petal a step from 8 to
    //  12, drops a seed at 13 (age 6)
    for (let k = 1; k <= 13; k++) {
        this.WorkshopStaple_step(gw)
        if (k === 1 || k === 4 || k === 7 || k === 13) seen.push(this.WorkshopStaple_say(gw))
    }
    w.c.grow = seen
    w.i({ saw: 'garden', steps: '13', at: seen.join(' / ') })

WorkshopStaple_cycle(w):
    i %desc:'keep stepping — the flower drops a new seed and in its time wilts away'
    let gw = this.WorkshopStaple_gw(w)
    if (!gw) return
    // the rose wilts at age 14 (step 20); the tulip has flowered by 19 and grown its petals by 24
    for (let k = 14; k <= 24; k++) this.WorkshopStaple_step(gw)
    w.c.cycle = this.WorkshopStaple_say(gw)
    w.i({ saw: 'garden', steps: '24', now: w.c.cycle })

WorkshopStaple_heart(w):
    i %desc:'a creation nobody watches gets no heart — it stops itself'
    this.expecting(w, 'heart_wait', 10, async () => {
        let gw = this.WorkshopStaple_gw(w)
        if (!gw) return
        this.Workshop_heart('Garden', this, gw)
        let armed = gw.c.heart ? 1 : 0
        await new Promise(res => setTimeout(res, 900))
        w.c.heart_armed = armed
        w.c.heart_stopped = gw.c.heart ? 0 : 1
    })

WorkshopStaple_list(w):
    i %desc:'the Workshop lists its creations — the Garden among them'
    let r = this.Workshop_play(w, {})
    w.c.listed = (r.creations || []).map(c => c.name).join(' ')
    w.i({ saw: 'play', creations: w.c.listed })

async WorkshopStaple_await(w, secs, truth_fn):
    let deadline = Date.now() + secs * 1000
    while (Date.now() < deadline) {
        if (truth_fn()) return
        await new Promise(res => setTimeout(res, 200))
    }

WorkshopStaple_at(w, n):
    let run = this.c.run
    return (run?.c.step_n ?? 0) >= n

WorkshopStaple_witness(w):
    if (w.c.stood && this.WorkshopStaple_at(w, 2)) {
        this.story_swear(w, 'a creation is a ghost with one world — the Workshop loads it and stands its world')
    }
    let g = w.c.grow || []
    if (g[0] === 'Seed:rose 1' && this.WorkshopStaple_at(w, 3)) {
        this.story_swear(w, 'an empty garden plants its first seed')
    }
    if (g[1] === 'Sprout:rose 1' && g[2] === 'Flower:rose 1' && this.WorkshopStaple_at(w, 3)) {
        this.story_swear(w, 'a seed sprouts and a sprout flowers — the same plant by name')
    }
    if (String(g[3] || '').indexOf('Flower:rose 1[5]') === 0 && String(g[3] || '').indexOf('tulip 2') > 0 && this.WorkshopStaple_at(w, 3)) {
        this.story_swear(w, 'a flower grows five petals and drops a new seed')
    }
    if (w.c.cycle && String(w.c.cycle).indexOf('rose 1') < 0 && this.WorkshopStaple_at(w, 4)) {
        this.story_swear(w, 'a flower wilts away in its time and the garden goes on without it')
    }
    if (w.c.heart_armed && w.c.heart_stopped && this.WorkshopStaple_at(w, 5)) {
        this.story_swear(w, 'a creation gets a heart only while it is watched — unwatched it stops itself')
    }
    if (String(w.c.listed || '').split(' ').indexOf('Garden') >= 0 && this.WorkshopStaple_at(w, 6)) {
        this.story_swear(w, 'the Workshop lists its creations — the Garden among them')
    }
