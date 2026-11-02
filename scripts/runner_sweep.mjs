// scripts/runner_sweep.mjs — run many Story Books on a live runner and say ONE LINE per Book.
//
//  Owner 2026-11-02: "running tests … should be peeking just a little information" — a day of sweeps through
//   `runner_ask run --watch` + `assertions` + `steps` + `snap` + `console` per Book put ~900k tokens into a runner agent.
//    This wraps runner_ask.mjs (which owns courting, liveness and the watch loop) and prints only verdicts; a red gets a
//     short digest — the first failing step, its oath gaps, the snap diff against the fixture on disk cut to the changed
//      lines, and that run's console warnings — capped.  Story_future.md "Open / deferred" has the wider wish.
//
//  Usage:
//    node scripts/runner_sweep.mjs [--runner=<id>] [--reload] [--swap=Ghost/A/X.g,Ghost/A/Y.g] [--no-rerun]
//                                  [--lines=40] [--quiet] <Book | Glob*> ...
//      AthePond* AtheStory* LeafFarm        globs match wormhole/Story/<dir>
//      --reload        runner_ask reload first, then wait for 3 green pings
//      --swap=…        runner_ask ghost_load <g> --swap for each (a LocalGen'd .go is NOT picked up by a reload —
//                       memory new-book-hollow-first-runs); done after --reload
//      --no-rerun      a red is reported as is (default: rerun once; green the second time prints ~)
//      --lines=N       cap on each red's digest (default 40)
//      --quiet         print only reds, hollows and the tally
//      --list          print the Books a pattern picks (after Credence's unusual: skips) and run NOTHING
//    Exit 0 when nothing stayed red or hollow.
//
//  Verdicts:
//    ✓ Book 3/3                    green, done = the fixtures on disk
//    ~ Book 3/3  (red, then green) a flake
//    ✗ Book 2/3  step 2 …          red twice; digest follows, indented
//    ∅ Book  HOLLOW …              the Book's own A/w and nothing else: its method never ran (stale ghost code?)
//    ? Book  no fixtures …         a new Book: ran, nothing to compare — oaths said, not judged
import { spawnSync } from 'node:child_process'
import { readdirSync, existsSync, readFileSync, writeFileSync, mkdtempSync } from 'node:fs'
import { join } from 'node:path'
import { tmpdir } from 'node:os'

const argv = process.argv.slice(2)
const flag = (k) => argv.find(a => a === `--${k}` || a.startsWith(`--${k}=`))
const val = (k) => flag(k)?.split('=').slice(1).join('=')
const runner = val('runner')
const LINES = Number(val('lines') || 40)
const quiet = !!flag('quiet')
const STORY = 'wormhole/Story'

// ── which Books ─────────────────────────────────────────────────────────────
// Credence says which to leave out: a Book whose Funkcion:Storying row carries `unusual:<why>` (hand-edited — a data migration, a
//  destination like Editron, a real-environment probe, stale fixtures) is not a regression test, so a glob never picks it — the same
//   rule as the editor's run-all (LiesFunk Lies_storytimes_books).  A Book named outright still runs.  Owner 2026-11-02: "Credence is
//    supposed to hold knowledge"
const skip = {}
try {
    for (const l of readFileSync('wormhole/Credence/toc.snap', 'utf8').split('\n')) {
        const m = /of_Book:([A-Za-z0-9_]+),(?:.*,)?unusual:([^,]*)/.exec(l)
        if (m) skip[m[1]] = m[2] || 'unusual'
    }
} catch {}
const dirs = readdirSync(STORY).filter(d => existsSync(join(STORY, d, 'toc.snap'))).sort()
const books = []
const skipped = []
for (const pat of argv.filter(a => !a.startsWith('--'))) {
    const glob = /[*?]/.test(pat)
    const re = new RegExp('^' + pat.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*').replace(/\?/g, '.') + '$')
    const hit = dirs.filter(d => re.test(d))
    if (!hit.length) console.log(`? ${pat}  no Book matches`)
    for (const b of hit) {
        if (glob && skip[b]) { if (!skipped.includes(b)) skipped.push(b); continue }
        if (!books.includes(b)) books.push(b)
    }
}
for (const b of skipped) if (!quiet) console.log(`- ${b}  unusual: ${skip[b]}`)
// --list: say what would run, run nothing
if (flag('list')) { for (const b of books) console.log(b); process.exit(0) }
if (!books.length) {
    console.error('usage: node scripts/runner_sweep.mjs [--runner=<id>] [--reload] [--swap=a.g,b.g] [--no-rerun] [--lines=N] [--quiet] <Book|Glob*> ...')
    process.exit(2)
}

// ── runner_ask, captured ────────────────────────────────────────────────────
const ask = (...a) => {
    const r = spawnSync('node', ['scripts/runner_ask.mjs', ...a, ...(runner ? [`--runner=${runner}`] : [])],
        { encoding: 'utf8', maxBuffer: 64 << 20, timeout: 30 * 60 * 1000 })
    return { code: r.status ?? 1, out: (r.stdout || '') + (r.stderr || '') }
}
const json_after = (out, prefix) => {
    const line = out.split('\n').find(l => l.startsWith(prefix))
    try { return line ? JSON.parse(line.slice(prefix.length)) : null } catch { return null }
}
const sleep = (ms) => new Promise(r => setTimeout(r, ms))

// ── setup ───────────────────────────────────────────────────────────────────
// ready = 3 green pings in a row whose reply says the spine has landed (ghosts:'ready'; a tab that predates that field
//  counts on pings alone) — a tab answers pings while its ghosts are still loading, and a Book run then finds half a machine
const ready = async (why) => {
    let green = 0
    for (let i = 0; i < 60 && green < 3; i++) {
        await sleep(2000)
        const p = ask('ping')
        green = p.code === 0 && !/"ghosts":"loading"/.test(p.out) ? green + 1 : 0
    }
    if (green < 3) { console.log(`✗ runner not ready ${why} (3 green pings, ghosts loaded)`); process.exit(1) }
}
if (flag('reload')) {
    ask('reload')
    await ready('after reload')
}
for (const g of (val('swap') || '').split(',').filter(Boolean)) {
    const r = ask('ghost_load', g, '--swap')
    if (r.code !== 0 || !/"ok":true/.test(r.out)) console.log(`✗ swap ${g}: ${r.out.trim().split('\n').pop()}`)
}
if (val('swap')) { await sleep(5000); await ready('after swap') }

// ── one Book ────────────────────────────────────────────────────────────────
const fixtures = (b) => readdirSync(join(STORY, b)).filter(f => /^\d{3}\.snap$/.test(f)).length

const once = (b) => {
    const r = ask('run', b, '--watch', ...(flag('desk') ? ['--desk'] : []))
    const polls = r.out.split('\n').filter(l => l.startsWith('… {')).map(l => { try { return JSON.parse(l.slice(2)) } catch { return null } }).filter(Boolean)
    const last = polls[polls.length - 1]
    const out = last?.outcome || {}
    const gaps = r.out.split('\n').filter(l => /✗ assertion «/.test(l)).map(l => l.trim())
    let dead = /runner DEAD|REFUSED|BLOCKED/.exec(r.out)?.[0]
    // never started: no poll ever showed this Book's run stepping — engaged by another client, refused, or the ask lost.
    //  Not a test result; say what runner_ask last said instead of an empty digest
    const ours = polls.filter(p => p.run?.book === b)
    if (!dead && !ours.some(p => p.run?.n != null)) {
        const tail = r.out.trim().split('\n').filter(l => l && !/^\s*(failing steps|one step snap|release:|⚠ run went RED|run settled)/.test(l.trim())).slice(-2).join(' / ')
        dead = 'NEVER STARTED — ' + (tail || 'no reply').slice(0, 200)
    }
    return { ok: r.code === 0 && !!out.ok, done: out.done ?? last?.run?.done ?? 0, total: last?.run?.total ?? 0, caveat: out.caveat || 0, gaps, dead }
}

// the Book's own A/w and nothing under it — its method never ran
const hollow = (b, total) => {
    if (total < 2) return false
    const s = ask('snap', '2').out
    const body = s.split('\n').filter(l => l && !l.startsWith('snap:') && !/self,round/.test(l))
    return body.length <= 4 && !body.some(l => /req:/.test(l)) && body.some(l => l.includes(`A:${b}`))
}

const digest = (b, r) => {
    const lines = []
    for (const g of r.gaps) lines.push(g)
    const steps = json_after(ask('steps').out, 'steps: ')?.steps || []
    const bad = steps.find(s => !s.ok && !s.caveat)
    if (bad) {
        lines.push(`step ${bad.n}${bad.desc ? ' — ' + bad.desc : ''}${bad.error ? ' — error: ' + bad.error : ''}`)
        const file = join(STORY, b, String(bad.n).padStart(3, '0') + '.snap')
        if (existsSync(file)) {
            const live = ask('snap', String(bad.n)).out.split('\n').filter(l => !l.startsWith('snap:')).join('\n')
            const tmp = mkdtempSync(join(tmpdir(), 'sweep-'))
            writeFileSync(join(tmp, 'live'), live.endsWith('\n') ? live : live + '\n')
            const d = spawnSync('diff', ['-U1', file, join(tmp, 'live')], { encoding: 'utf8' }).stdout || ''
            for (const l of d.split('\n').slice(2)) if (l) lines.push(l)
        }
    }
    // this run's console warnings: from its become_book line on, warn|error only, deduped
    const con = ask('console', '--tail=600').out.split('\n')
    const from = con.map((l, i) => l.includes(`become_book drive → ${b}`) ? i : -1).filter(i => i >= 0).pop() ?? 0
    const seen = new Set()
    for (const l of con.slice(from)) {
        if (!/ (WARN|ERROR) /.test(l) || /mismatch accepted|Cyto_animation_done|wheel sensitivity|diagonal satan/.test(l)) continue
        const key = l.replace(/^\S+\s+/, '')
        if (seen.has(key)) continue
        seen.add(key)
        lines.push('console: ' + key)
    }
    const cut = lines.slice(0, LINES)
    if (lines.length > LINES) cut.push(`… ${lines.length - LINES} more lines`)
    return cut.map(l => '    ' + l).join('\n')
}

// ── the sweep ───────────────────────────────────────────────────────────────
const tally = { '✓': 0, '~': 0, '✗': 0, '∅': 0, '?': 0 }
const SETTLE_MS = Number(process.env.RUNNER_SWEEP_SETTLE_MS || 3000)
let first = true
for (const b of books) {
    if (!first) await sleep(SETTLE_MS)
    first = false
    const fx = fixtures(b)
    let r = once(b)
    // a run that never started (another client's run, a lost ask) is tried once more before it is reported
    // a runner wants a beat between runs (memory fleet-sweep-measurement-confounds: release + settle) — back to back, one Book in
    //  ~36 sat at phase:begun (trial 2026-11-02); a non-start waits longer before its one retry
    if (r.dead?.startsWith('NEVER STARTED') && !flag('no-rerun')) { await sleep(12000); r = once(b) }
    let mark = '✓', note = ''
    if (r.dead) { mark = '✗'; note = r.dead }
    else if (!fx) { mark = '?'; note = `no fixtures — ran ${r.done}${r.gaps.length ? ', ' + r.gaps.length + ' oath gaps' : ''}` }
    const green = (x) => x.ok && (!fx || x.done === fx)
    if (!r.dead && fx && !green(r)) {
        if (hollow(b, r.total)) { mark = '∅'; note = 'HOLLOW — method never ran (its toc lacks Stands:<Ground>?)' }
        else if (!flag('no-rerun')) {
            const r2 = once(b)
            if (green(r2)) { mark = '~'; note = '(red, then green)'; r = r2 }
            else { mark = '✗'; r = r2 }
        } else mark = '✗'
    }
    if (mark === '?' && hollow(b, r.total)) { mark = '∅'; note = 'HOLLOW — method never ran (its toc lacks Stands:<Ground>?)' }
    tally[mark]++
    // steps that ENDED ON A TIMEOUT (a ttlilt ran out — Story stamps Step%timeout): a green made of waiting is not a pass, said
    const timeouts = mark === '∅' ? [] : (json_after(ask('steps').out, 'steps: ')?.steps || []).filter(s => s.timeout).map(s => s.n)
    const counts = mark === '∅' || mark === '?' ? '' : ` ${r.done}/${fx || r.total}${r.caveat ? ` caveat ${r.caveat}` : ''}`
        + (timeouts.length ? `  ⏱ timeout step ${timeouts.join(',')}` : '')
    if (!quiet || mark === '✗' || mark === '∅') console.log(`${mark} ${b}${counts}${note ? '  ' + note : ''}`)
    if (mark === '✗' && !r.dead) console.log(digest(b, r))
}
console.log(`${books.length} Books: ${tally['✓']} ✓ · ${tally['~']} ~ · ${tally['✗']} ✗ · ${tally['∅']} hollow · ${tally['?']} new`)
process.exit(tally['✗'] || tally['∅'] ? 1 : 0)
