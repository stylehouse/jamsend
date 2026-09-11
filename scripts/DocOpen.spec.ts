// DocOpen — the OTHER half of DocLoad.spec.ts, and the one that matters.
//
//  DocLoad measured the compiler by CALLING IT DIRECTLY: Peeroleum.g 315ms, Swarm.g (5x bigger)
//   898ms, cost sublinear in size.  So the compiler is not what the owner waits on.  Everything
//    between "click a Doc" and "it is on screen" that is NOT that work is the machine around it —
//     and the owner named it: *"there's just a lot of w:Lies elvises to get done to open a doc"*.
//      Each elvis re-arms the machine and is served on a later pass, so an open costs its chain
//       LENGTH in belief ticks, and in a real tab every tick pays a drain gate.
//
//  ⚠ WHAT HEADLESS CAN AND CANNOT ANSWER.  Story_cli's driver pumps `_really_answer_calls()` in a
//   tight loop (the House's own $effect.root pump does not flush under node), which BYPASSES the
//    drain gate completely.  So:
//      • the TICK COUNT here is real and deterministic — that is the structural number
//      • the SECONDS here are meaningless for the owner's wait — there is no gate in them
//    The owner's cost is therefore  ticks x gate, with gate = ANSWER_CALLS_TICK_MS (50) when the
//     todo is busy and AMBIENT_MAIN_TICK_MS (200) when it is not.  Count here, multiply there.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/DocOpen.spec.ts
//     DOC=Ghost/S/Swarm.g   # open something else
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import path from 'node:path'
import Story_cli from './Story_cli.svelte'
import { NodeWormholeNav } from './NodeWormholeNav'

const ROOT    = process.cwd()
const WANT    = process.env.DOC || 'Ghost/N/Peeroleum.g'
const nodeNav = new NodeWormholeNav(ROOT, '/tmp/DocOpen_fs', false)
const sleep   = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }

test('DocOpen: how many belief ticks does one doc open cost', async () => {
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 200 && !(H && typeof H.Lang_compile_dock === 'function'); i++) await sleep(50)
    expect(typeof H?.Lang_compile_dock, 'Lang ghost deposited').toBe('function')

    // the nav Lies reads documents through — without it every Store read misses
    const WA = H.i({ A: 'Wormhole' }); WA.i({ w: 'Wormhole' }); WA.c.nav = nodeNav
    // stand the ambient Lies the way Auto does for a runner boot (Auto.svelte ~:919): the role
    //  matters — `editor` is what has DOCKS (Lies_has_docks), and only an editor runs the want
    //   resolver that turns a %want into an open dock.
    H.c.role = 'editor'
    const A = H.i({ A: 'Lies' }); A.c.up = H
    const lw = A.i({ w: 'Lies', editor: 1, creduler: 1 }); lw.c.up = A
    const GA = H.i({ A: 'Lang' }); GA.c.up = H
    const gw = GA.i({ w: 'Lang' }); gw.c.up = GA
    const PA = H.i({ A: 'Pantheate' }); PA.c.up = H; PA.i({ w: 'Pantheate' }).c.up = PA

    // the pump — Story_cli.spec.ts's drain, verbatim in shape.  No gate: this is a COUNTER, not a clock.
    const drain = async () => { for (const h of allHouses(H)) { let g = 0; while (h.todo?.length && h.started && g++ < 300) { try { await h._really_answer_calls() } catch {} } } }
    const crank = async (turns: number) => {
        for (let t = 0; t < turns; t++) {
            for (const h of allHouses(H)) { if (!h.started) h.started = true; h.i_elvisto?.(h, 'think') }
            await drain(); await sleep(10)
        }
    }

    await crank(60)                                   // let the boot settle first
    const settled_ticks = lw.c.lies_ticks ?? 0
    console.log(`\n  boot settled after ${settled_ticks} Lies ticks`)

    // find the Doc particle a click would carry
    const docs: any[] = []
    const walk = (n: any, d = 0) => { if (d > 7) return
        for (const c of (n.o({ Doc: 1 }) ?? []) as any[]) docs.push(c)
        for (const c of (n.o({ What: 1 }) ?? []) as any[]) walk(c, d + 1) }
    for (const wf of (lw.o({ Waft: 1 }) ?? []) as any[]) walk(wf)
    console.log(`  wafts:${(lw.o({ Waft: 1 }) ?? []).length}  docs visible:${docs.length}`)
    if (docs.length) console.log('  e.g. ' + docs.slice(0, 6).map(d => String(d.sc.Doc)).join(', '))

    const target = docs.find(d => String(d.sc.Doc) === WANT)
    if (!target) {
        console.log(`\n  ⚠ ${WANT} not in any loaded Waft (${docs.length} docs seen) — cannot drive the`
                  + ` real want path yet. The Waft roster is the piece still missing.`)
        return
    }

    const t0 = lw.c.lies_ticks ?? 0
    H.i_elvisto(lw, 'Lies_want', { src: target, kind: 'click' })
    // AND ASK FOR THE CONTENT.  The want stands the dock (3 ticks) but the COMPILE is driven by text
    //  arriving, not by the dock opening — `e_Lang_texting` fires from the UI or `machine:1`, and the
    //   open path's own delivery is `e:dock_content`, produced by `Lies_provide_dock` (LiesStore:224).
    //    With no CodeMirror there is no typing, so headless the chain stalls at `job:0` forever.
    //  `force_compile` is the seam built for exactly this: *"a BACKGROUND compile that furnishes the
    //   dock and compiles it off disk text WITHOUT taking the active seat or mounting CodeMirror"*.
    //    Using it is not cheating the measurement — it is the same producer the cursor push calls; it
    //     only skips the editor seat this harness has no way to occupy.
    await H.Lies_provide_dock(lw, WANT, { force_compile: true })
    let dock: any, time: any, opened_at = 0
    // PROGRESS EVERY 25 TURNS.  The first cut ran 400 silent turns and hit the wall clock with
    //  nothing printed — a harness that can only report by finishing tells you nothing when it
    //   doesn't.  Now a timeout still says how far it got and what was standing.
    // BOUND BY WALL CLOCK, not turn count.  Once the spin engages each turn does ~75 Lies ticks of
    //  real work, so a fixed turn budget blows the test timeout and the run dies BEFORE the req dump
    //   — which is the only part that answers anything.  Deadline first, dump always.
    const deadline = Date.now() + 90000
    for (let t = 0; t < 250 && Date.now() < deadline; t++) {
        await crank(1)
        dock = gw.o({ docks: 1 })[0]?.o({ dock: WANT })[0]
        if (dock && !opened_at) opened_at = (lw.c.lies_ticks ?? 0) - t0
        time = dock?.o({ Compile: 1 })[0]?.o({ time: 1 })[0]
        if (t % 25 === 0) console.log(`    …turn ${t}  ticks:${(lw.c.lies_ticks ?? 0) - t0}`
            + `  dock:${dock ? 'yes' : 'no'}  job:${dock?.o({ Compile: 1 }).length ?? 0}`
            + `  pending:${dock?.o({ Compile: 1 })[0]?.sc.pending ?? '-'}`
            + `  time:${time?.sc.compile ?? '-'}`)
        if (time?.sc.compile != null) break
    }
    const ticks = (lw.c.lies_ticks ?? 0) - t0

    console.log(`\n  OPEN ${WANT}`)
    // ⚠ REPORT WHAT HAPPENED, NOT WHAT WAS HOPED FOR.  The first cut printed "compiled after N ticks"
    //  and a derived "N x 50ms = 114.5s busy" on a run where the compile NEVER happened — the loop had
    //   simply hit its deadline and `ticks` was the deadline's tick count.  A fabricated number in a
    //    fresh instrument is worse than no instrument; the completion is a SEPARATE fact from the count.
    const compiled = time?.sc.compile != null
    console.log(`    dock appeared after   ${opened_at || '—'} ticks`)
    if (compiled) {
        console.log(`    compiled after        ${ticks} ticks   ← the structural number`)
        console.log(`    compile work (self)   ${time.sc.compile}s`)
        console.log(`\n    at a real tab's gate: ${ticks} x 50ms = ${(ticks * 0.05).toFixed(1)}s busy`
                  + `  ·  x 200ms = ${(ticks * 0.2).toFixed(1)}s ambient`)
    } else {
        console.log(`    ⚠ NEVER COMPILED — deadline reached after ${ticks} ticks with no %time on the`
                  + ` job. The dock stands and req:Languish is on it, but no Compile job is ever minted`
                  + ` headless, so this run says nothing about compile cost. Do not derive gate seconds`
                  + ` from ${ticks}: it is the deadline's tick count, not an open's.`)
    }

    // ── WHO IS STILL WORKING? ────────────────────────────────────────────────────────────────
    //  The machine only re-arms `think` while some req still wants a turn: `needs_work =
    //   !finished && !ok` (Hovercraft).  So a House that never quiesces has at least one req that
    //    never finishes, and NAMING it is the whole question — a req that would complete in a live
    //     tab makes the spin a harness artifact; one that re-arms unconditionally is the defect.
    const dump = (world: any, label: string) => {
        const reqs = (world?.o({ req: 1 }) ?? []) as any[]
        console.log(`\n  ${label} — ${reqs.length} reqs`)
    //  ⚠ `!finished && !ok` IS THE NORMAL STANDING STATE OF AN ETERNAL REQ — it is not a defect and
    //   not a leak. An earlier version of this dump labelled it `● BUSY`, and four such rows
    //    (req:git, req:wants, req:workon, req:waft_roster) were read as "four reqs never finish" and
    //     promoted to the leading explanation for the owner's slowness. They are all standing reqs:
    //      `waft_roster` is declared `eternal:1` outright, the rest are open-ended `doai` reqs.
    //       `req:wants` holding children is likewise BY DESIGN — a %want is cursor-intent history,
    //        deliberately kept and bounded to 12 (Lies.svelte ~:1066). So the column that matters is
    //         ETERNAL, and it is now printed: `standing` is expected, a non-eternal req stuck
    //          unfinished is the only thing worth looking at.
        for (const r of reqs) {
            const unfinished = !r.sc.finished && !r.sc.ok
            const eternal = !!(r.sc.eternal || r.sc.permanent)
            const tt = (r.o({ ttlilt: 1 }) ?? []) as any[]
            console.log(`    ${!unfinished ? '  done  ' : eternal ? ' standing' : '● STUCK? '} req:${String(r.sc.req).padEnd(22)}`
                + ` ok:${r.sc.ok ?? '-'} finished:${r.sc.finished ?? '-'} eternal:${r.sc.eternal ?? '-'} maz:${r.sc.maz ?? '-'}`
                + ` kids:${r.o().length}${tt.length ? `  ttlilt×${tt.length}` : ''}`
                + `${r.sc.timed_out ? '  ⏰TIMED_OUT' : ''}`)
        }
    }
    dump(lw, 'w:Lies')
    dump(gw, 'w:Lang')
    // the dock's own sub-tree — req:Languish lives here and is what should mint the Compile job
    if (dock) {
        console.log(`\n  dock:${WANT} children: ${dock.o().map((c: any) => Object.keys(c.sc)[0] + ':' + Object.values(c.sc)[0]).join('  ')}`)
    }
}, 300000)
