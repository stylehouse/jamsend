// CredRunner — run a Creduler-ACQUIRED wrangler Book (PereStaple et al.) headless and dump
//  the pile, exactly like Story_cli but for the Books that acquire their spine instead of
//   reading on-disk fixtures.  The ONLY structural difference from Story_cli.spec.ts is the
//    acquire prelude: a runner shell that mounts dynamic watched:UIs includes (Story_cli_runner
//     .svelte) + a Creduler_ensure crank that loads CREDULER_GHOSTS before the Story stands up,
//      so Run_A_<Book> + the spine are live.  Proven by CredulerProbe.spec.ts.
//
//   BOOK=PereStaple node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/CredRunner.spec.ts
//   ACCEPT=1 …                                          # re-record the fixtures from a headless run
//
// Writes /tmp/Story_cli/<Book>/ : NNN.got.snap / NNN.exp.snap / NNN.trace.txt / wstory.json / run.json
import { test, expect } from 'vitest'
import { mount, flushSync } from 'svelte'
import { readFileSync, writeFileSync, mkdirSync, rmSync } from 'node:fs'
import path from 'node:path'
import Runner from './Story_cli_runner.svelte'
import { NodeWormholeNav } from './NodeWormholeNav'

const ROOT   = process.cwd()
const BOOK   = process.env.BOOK || 'PereStaple'
const ACCEPT = !!process.env.ACCEPT
const OUT    = path.join('/tmp/Story_cli', BOOK)

const OVERLAY = '/tmp/CredRunner_fs'
try { rmSync(OVERLAY, { recursive: true, force: true }) } catch {}
const nodeNav = new NodeWormholeNav(ROOT, OVERLAY, ACCEPT)

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const allHouses = (H: any): any[] => { const out=[H]; const w=(h:any)=>{for(const s of (h.o?.({H:1})??[])) if(!out.includes(s)){out.push(s);w(s)}}; w(H); return out }
const now_s = () => Date.now() / 1000
const liveTtlilts = (H: any): { count: number, soonest: number } => {
    let count = 0, soonest = Infinity
    const visit = (n: any) => {
        if (n?.sc?.ttlilt !== undefined && !n.sc.timed_out) { count++; const u = n.sc.until_ts; if (typeof u === 'number' && u < soonest) soonest = u }
        for (const k of (n.o?.({}) ?? [])) visit(k)
    }
    visit(H); return { count, soonest }
}
const hide = (s: string) => s.split('\n').filter(l => !/\bmo:main\b/.test(l)).join('\n')
const pad  = (n: number) => String(n).padStart(3, '0')
const traceDump = (trace: any): string => {
    if (!Array.isArray(trace)) return String(trace)
    const t0 = trace[0]?.t ?? 0
    return trace.map((e: any) => `${((e.t ?? t0) - t0).toFixed(1).padStart(8)}  ${e.kind}\t${e.tag ?? ''}`).join('\n')
}
const dumpC = (n: any, d = 0): any => d > 12 ? '…' : { sc: { ...n.sc }, kids: (n.o?.({}) ?? []).map((k: any) => dumpC(k, d + 1)) }

// CREDULER methods that prove the acquire landed (the spine + this Book's Run recipe)
// acquire landed when the spine + this Book's ghost are live.  A Book needs EITHER a Run_A_<Book>
//  recipe OR just its world-named per-beat handler (H[BOOK]) — the trivial books that lean on
//   Story_subHouse's default A:<Book>/w:<Book> standup have no Run_A_ at all.
const SPINE_READY = (H: any) => typeof H.Peeroleum_deliver === 'function'
    && (typeof H[`Run_A_${BOOK}`] === 'function' || typeof H[BOOK] === 'function')

test(`CredRunner: ${BOOK} runs headless (acquire → drive → pile)`, async () => {
    let H: any
    mount(Runner, { target: document.body, props: { onhouse: (h: any) => { H = h } } })
    for (let i = 0; i < 40 && !(H && typeof H.Creduler_ensure === 'function'); i++) await sleep(50)
    expect(typeof H?.Creduler_ensure, 'shell booted (Lies ghost deposited)').toBe('function')

    // Headless has no ?B= boot param, so give the top House the runner boot_role the LIVE runner gets
    //  from the URL — Story_subHouse defaults Run.c.role from top_House().c.boot_role, so a Book needs
    //   no per-recipe `this.c.role ??= 'runner'`.  That ceremony belongs here, in the runner harness,
    //    not stamped into every Book's (now-deleted) Run_A_<Book>.
    H.c.boot_role ??= 'runner'

    const WA = H.i({ A: 'Wormhole' }); WA.i({ w: 'Wormhole' }); WA.c.nav = nodeNav

    const drain = async () => { for (const h of allHouses(H)) { let g=0; while (h.todo?.length && h.started && g++<300) { try { await h._really_answer_calls() } catch {} } } }

    // ── acquire prelude: load CREDULER_GHOSTS so Run_A_<Book> + spine are live ──
    const liesW = H.i({ A: 'Lies' }).i({ w: 'Lies', runner: 1, creduler: 1 })
    for (let t = 0; t < 160 && !SPINE_READY(H); t++) {
        for (const h of allHouses(H)) if (!h.started) h.started = true
        try { await H.Creduler_ensure(liesW) } catch (e) { console.log('acquire threw:', (e as any)?.message) }
        flushSync()
        for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')
        await drain(); flushSync()
        await sleep(50)
    }
    expect(SPINE_READY(H), `spine + Run_A_${BOOK} acquired`).toBe(true)
    console.log(`[CredRunner] spine acquired — Run_A_${BOOK} live`)

    // ── stand up the Story Run (same as Story_cli) ──
    const S = H.subHouse('Story')
    S.i({ A: 'Story' }).i({ w: 'Story', Book: BOOK })
    S.i_elvisto(S, 'think')

    const find_w = () => H.o({ H: 'Story' })[0]?.o({ A: 'Story' })[0]?.o({ w: 'Story' })[0]
    let w: any, run: any
    const got: Record<number, any> = {}

    for (let t = 0; t < 600; t++) {
        for (const h of allHouses(H)) {
            if (!h.started) h.started = true
            const o = h.The_Opt_val?.bind(h)
            if (o && !h._noc) { h._noc = true; h.The_Opt_val = (ww: any, k: string) => k === 'useCyto' ? false : o(ww, k) }
        }
        if (w && !w.c.lenient) w.c.lenient = true
        if (ACCEPT && w && !w.c.keep_snaps) w.c.keep_snaps = true
        flushSync()
        const tt = liveTtlilts(H)
        if (!run?.c?.driving || tt.count > 0) for (const h of allHouses(H)) h.i_elvisto?.(h, 'think')
        await drain(H)
        await sleep(tt.count > 0 ? Math.max(25, Math.min(120, Math.round((tt.soonest - now_s()) * 1000))) : 60)
        w ||= find_w(); run ||= w?.o({ run: 1 })[0]
        for (const st of (w?.c?.This?.o({ Step: 1 }) ?? []) as any[]) {
            const n = st.sc.Step
            if (st.sc.got_snap && got[n] === undefined)
                got[n] = { snap: String(st.sc.got_snap), ok: !!st.sc.ok, trace: st.sc.Run_trace ?? [] }
        }
        if (run && run.c.driving === false && Object.keys(got).length) break
    }

    // ── accept (re-record) ──
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
        for (let i = 0; i < 30; i++) { await drain(H); await sleep(40) }
        accepted.sort((a, b) => a - b)
        console.log(`[CredRunner] ACCEPT ${BOOK}: rewrote ${accepted.length} snaps [${accepted.join(',')}]`)
    }

    // ── pile + diff ──
    try { rmSync(OUT, { recursive: true, force: true }) } catch {}
    mkdirSync(OUT, { recursive: true })
    const spayers = (() => { try { return S.collect_spayers([...(S.story_matching ?? []), ...S.entropy_rules(w?.c.The)]) } catch { return [] } })()
    const steps: any[] = []
    for (const n of Object.keys(got).map(Number).sort((a, b) => a - b)) {
        const g = hide(got[n].snap).trimEnd()
        let exp = ''
        try { exp = hide(readFileSync(path.join(ROOT, `wormhole/Story/${BOOK}/${pad(n)}.snap`), 'utf8')).trimEnd() } catch {}
        writeFileSync(path.join(OUT, `${pad(n)}.got.snap`), g + '\n')
        writeFileSync(path.join(OUT, `${pad(n)}.exp.snap`), exp + '\n')
        writeFileSync(path.join(OUT, `${pad(n)}.trace.txt`), traceDump(got[n].trace) + '\n')
        const exact = g === exp && !!exp
        const match = !!exp && (exact || (spayers.length ? S.spay_graft(g, exp, spayers, n).forgiven : false))
        steps.push({ n, story_ok: got[n].ok, match, exact, caveat: match && !exact,
                     got_lines: g.split('\n').length, exp_lines: exp ? exp.split('\n').length : 0 })
    }
    if (w) writeFileSync(path.join(OUT, 'wstory.json'), JSON.stringify(dumpC(w), null, 1))
    const summary = { book: BOOK, captured: steps.length, mode: run?.sc.mode, surprises: steps.filter(s => !s.match).map(s => s.n), steps }
    writeFileSync(path.join(OUT, 'run.json'), JSON.stringify(summary, null, 2))

    console.log(`[CredRunner] ${BOOK}: ${steps.length} steps → ${OUT}`)
    console.log(`[CredRunner] match: ${steps.filter(s => s.match).length}/${steps.length}`
        + `  exact: ${steps.filter(s => s.exact).length}/${steps.length}`
        + `  surprises: [${summary.surprises.join(',')}]`
        + `  forgiven: [${steps.filter(s => s.caveat).map(s => s.n).join(',')}]`)

    try { if (run) run.c.driving = false; for (const h of allHouses(H)) h.stop?.() } catch {}
    expect(steps.length, 'captured at least one step').toBeGreaterThan(0)
})
