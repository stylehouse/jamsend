// Story_cli — run a Story Book outside the browser and DUMP the whole w:Story to a
//  pile of files you can grep/diff offline, so "seeing" a run is iterative bash, not
//  a wall of console output.
//
//   BOOK=PortPlanet node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/Story_cli.spec.ts
//
// Set ACCEPT=1 to re-record: the got snaps become the new fixtures (toc.snap +
//  NNN.snap rewritten in wormhole/Story/<Book>/ via the machine's own story_save).
//
// Writes /tmp/Story_cli/<Book>/ :
//   NNN.got.snap   the produced Snap:H for step N (mo:main already dropped by story_matching)
//   NNN.exp.snap   the recorded fixture for step N, mo:main-normalized (for clean diff)
//   NNN.trace.txt  the Run_trace event stream for step N
//   wstory.json    the entire w:Story C-tree (sc + children), recursively
//   run.json       summary: per-step story-ok / fixture-match / line counts / surprises
//
// Then query the pile, e.g.:
//   diff /tmp/Story_cli/PortPlanet/005.got.snap /tmp/Story_cli/PortPlanet/005.exp.snap
//   grep -rn surprise /tmp/Story_cli/PortPlanet/
//   jq '.steps[] | select(.match==false)' /tmp/Story_cli/PortPlanet/run.json
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs'
import path from 'node:path'
import Story_cli from './Story_cli.svelte'
import { NodeWormholeNav } from './NodeWormholeNav'

const ROOT   = process.cwd()
const BOOK   = process.env.BOOK || 'PortPlanet'
const ACCEPT = !!process.env.ACCEPT   // re-record: accept the got snaps as the new fixtures
const OUT    = path.join('/tmp/Story_cli', BOOK)

// node backend for w:Wormhole — an overlay: reads fall through repo→sandbox, writes land
//  in the sandbox so compile-pipeline Books (Peregrination et al.) write their gen/+Ghost/
//   output without touching the tree.  Fixture writes under wormhole/ pass through to the
//    real repo only when recording (ACCEPT).  Fresh overlay per run.
const OVERLAY = '/tmp/Story_cli_fs'
try { rmSync(OVERLAY, { recursive: true, force: true }) } catch {}
const nodeNav = new NodeWormholeNav(ROOT, OVERLAY, ACCEPT)
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }
const hide = (s: string) => s.split('\n').filter(l => !/\bmo:main\b/.test(l)).join('\n')   // mo:main lives only in stale fixtures now
const pad  = (n: number) => String(n).padStart(3, '0')
// recursive sc+children dump of a C particle → plain JSON (sc is scalar; .c is skipped)
const dumpC = (n: any, d = 0): any =>
    d > 12 ? '…' : { sc: { ...n.sc }, kids: (n.o?.({}) ?? []).map((k: any) => dumpC(k, d + 1)) }

test(`Story_cli: run + dump Book:${BOOK}`, async () => {
    // -I shim: INCLUDE=<name> (a scripts/<name>.svelte, just ghost code) mounts an extra ghost
    //  alongside Ghost, depositing its worker onto H — runs a Book without touching Machinery.
    let include: any = undefined
    if (process.env.INCLUDE) {
        const name = process.env.INCLUDE.replace(/\.svelte$/, '').replace(/^\.?\//, '')
        include = (await import(`./${name}.svelte`)).default
    }
    let H: any
    mount(Story_cli, { target: document.body, props: { onhouse: (h: any) => { H = h }, include } })
    for (let i = 0; i < 40 && !(H && typeof H.story_drive === 'function'); i++) await sleep(50)
    expect(typeof H?.story_drive, 'ghosts deposited').toBe('function')

    const WA = H.i({ A: 'Wormhole' }); WA.i({ w: 'Wormhole' }); WA.c.nav = nodeNav
    const S = H.subHouse('Story')
    S.i({ A: 'Story' }).i({ w: 'Story', Book: BOOK })
    S.i_elvisto(S, 'think')

    const drain = async () => { for (const h of allHouses(H)) { let g=0; while (h.todo?.length && h.started && g++<300) { try { await h._really_answer_calls() } catch {} } } }
    const find_w = () => H.o({ H: 'Story' })[0]?.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0]
    let w: any, run: any
    const got: Record<number, any> = {}     // n → { snap, ok, trace }

    for (let t = 0; t < 400; t++) {
        for (const h of allHouses(H)) {
            if (!h.started) h.started = true
            const o = h.The_Opt_val?.bind(h)
            if (o && !h._noc) { h._noc = true; h.The_Opt_val = (ww: any, k: string) => k === 'noCyto' ? true : o(ww, k) }
        }
        if (w && !w.c.lenient) w.c.lenient = true                  // walk all steps; never pause on a mismatch
        if (ACCEPT && w && !w.c.keep_snaps) w.c.keep_snaps = true   // disable the 5-step got_snap trim so every step survives to be re-recorded
        if (!run?.c?.driving) { S.i_elvisto(S, 'think'); H.i_elvisto(H, 'think') }   // kick only until the drive owns the clock
        await drain(H); await sleep(60)
        w ||= find_w(); run ||= w?.o({ run: 1 })[0]
        for (const st of (w?.c?.This?.o({ Step: 1 }) ?? []) as any[]) {
            const n = st.sc.Step
            if (st.sc.got_snap && got[n] === undefined)
                got[n] = { snap: String(st.sc.got_snap), ok: !!st.sc.ok, trace: st.sc.Run_trace ?? [] }
        }
        if (run && run.c.driving === false && Object.keys(got).length) break
    }

    // ── accept: promote the captured got snaps into the new fixtures ─────────
    // The check pass already set each live Step's got_snap + dige (= got_dige).
    // Promote them — accepted=true so story_save writes NNN.snap, and push the
    //  got dige into The so encode_toc_snap stamps the matching toc.snap.  The
    //   machine's own Wormhole→nav write path (story_save) lands the files in
    //    /app/wormhole/Story/<Book>/, exactly where the check side reads them.
    const accepted: number[] = []
    if (ACCEPT && w) {
        for (const st of (w.c.This?.o({ Step: 1 }) ?? []) as any[]) {
            if (!st.sc.got_snap) continue
            const n = st.sc.Step as number
            st.sc.accepted = true; st.sc.ok = true; st.sc.saved = false
            S.The_step(w, n).sc.dige = st.sc.dige
            accepted.push(n)
        }
        run && (run.sc.frontier = 0); S.The_set_frontier(w, 0)
        S.story_analysis(w)
        await S.story_save()
        // story_save defers its writes (setTimeout → post_do → Wormhole reqs);
        //  keep cranking so those reqs flush through nav before we read back.
        for (let i = 0; i < 30; i++) { await drain(H); await sleep(40) }
        accepted.sort((a, b) => a - b)
        console.log(`[Story_cli] ACCEPT ${BOOK}: rewrote ${accepted.length} snaps [${accepted.join(',')}] + toc.snap`)
    }

    // ── serialise the pile ───────────────────────────────────────────────────
    try { rmSync(OUT, { recursive: true, force: true }) } catch {}
    mkdirSync(OUT, { recursive: true })
    const steps: any[] = []
    for (const n of Object.keys(got).map(Number).sort((a, b) => a - b)) {
        const g = hide(got[n].snap).trimEnd()
        let exp = ''
        try { exp = hide(readFileSync(path.join(ROOT, `wormhole/Story/${BOOK}/${pad(n)}.snap`), 'utf8')).trimEnd() } catch {}
        writeFileSync(path.join(OUT, `${pad(n)}.got.snap`), g + '\n')
        writeFileSync(path.join(OUT, `${pad(n)}.exp.snap`), exp + '\n')
        writeFileSync(path.join(OUT, `${pad(n)}.trace.txt`),
            (Array.isArray(got[n].trace) ? got[n].trace.map((e: any) => `${e.kind}\t${e.tag ?? ''}`).join('\n') : String(got[n].trace)) + '\n')
        steps.push({ n, story_ok: got[n].ok, match: g === exp && !!exp, got_lines: g.split('\n').length, exp_lines: exp ? exp.split('\n').length : 0 })
    }
    if (w) writeFileSync(path.join(OUT, 'wstory.json'), JSON.stringify(dumpC(w), null, 1))
    const summary = { book: BOOK, captured: steps.length, mode: run?.sc.mode,
                      surprises: steps.filter(s => !s.match).map(s => s.n), steps }
    writeFileSync(path.join(OUT, 'run.json'), JSON.stringify(summary, null, 2))

    // ── tiny console: just the pointer + headline ────────────────────────────
    console.log(`[Story_cli] ${BOOK}: ${steps.length} steps → ${OUT}`)
    console.log(`[Story_cli] match: ${steps.filter(s => s.match).length}/${steps.length}  surprises at steps: [${summary.surprises.join(',')}]`)

    // halt the machine so its drive timers/elvises stop firing after the test
    try { if (run) run.c.driving = false; for (const h of allHouses(H)) h.stop?.() } catch {}

    expect(steps.length, 'captured at least one step').toBeGreaterThan(0)
})
