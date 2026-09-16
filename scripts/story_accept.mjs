// story_accept.mjs — RE-SWEAR FIXTURES BY FILTERED DIFF (2026-09-03, the keys-as-particles migration).
//   node scripts/story_accept.mjs <Book>... [--allow=<regex>] [--force] [--dry] [--full]
//   STORY_RUNNER=<id> pins every runner_ask call to one tab; --full prints the whole residual.
//  For each Book: run it on the LIVE runner (runner_ask); green ⇒ say so.  Red ⇒ for every RED step with a
//   fixture, fetch the live snap and compute the RESIDUAL: both sides minus the crew-particle lines
//    (Crew / Key / mate / self,round — the lines a model change is allowed to move) minus any --allow
//     regex, compared as SORTED line multisets (a moved block is not a change).  Empty residual (or --force)
//      ⇒ copy the live snaps over the fixtures, re-run, patch the toc diges LAST (the runner rewrites
//       toc.snap, so patching earlier is lost), re-run once more and demand ok (a caveat is the runner's own
//        forgiveness under EntropyArrest — counted and printed, never a failure here).  A non-empty
//        residual is PRINTED and the Book left alone — that is the review.  Hollow runs retry once.
//  Prints one verdict line per Book.  Churn (Credulate/Credulation/TimeTotal) is NOT swept here — git
//   checkout those after.  Run from the repo root.
import { execSync, spawnSync } from 'node:child_process'
import fs from 'node:fs'

const args = process.argv.slice(2)
const books = args.filter(a => !a.startsWith('--'))
const allow = args.filter(a => a.startsWith('--allow=')).map(a => new RegExp(a.slice(8)))
const force = args.includes('--force')
const dry = args.includes('--dry')
const full = args.includes('--full')   // print EVERY residual line, untruncated (default: 12 per step, 200 chars)
const FILTER = /^\s*(Crew\b|Crew,|Key,pub:|mate:|self,round)/

const sh = (cmd, ms = 400000) => {
    const r = spawnSync('bash', ['-c', cmd], { encoding: 'utf8', timeout: ms, maxBuffer: 64 * 1024 * 1024 })
    return { out: (r.stdout || '') + (r.stderr || ''), stdout: r.stdout || '', code: r.status }
}
const lastJson = (txt) => {
    const lines = txt.trim().split('\n').reverse()
    for (const l of lines) { const i = l.indexOf('{'); if (i >= 0) { try { return JSON.parse(l.slice(i)) } catch (e) {} } }
    return null
}
// SETTLE — the gap between a `release` and the next `run`.  Measured 2026-09-04 on MusuHeist back to
//  back: release→run with no gap wedged the standup 2 of 6 runs (`phase:begun, n:null, steps=0`; in the
//   tab, `▶ Story subHouse created` then total silence — no story_analysis, no drive started), a 6s gap
//    wedged 0 of 6.  auto_reset_story tears down (hand-walking A→w→run, stop(), drop(), Supervisor cull)
//     and only THEN posts the new subHouse whose body ends `i_elvisto(S,'think')`; re-engaging mid-drain
//      loses that posted think.  Story_hygiene_todo.md §0a.2; the real cure is a req-owned teardown
//       (Story_future.md §8.3), and this is the workaround until then.  A dropped Book here costs a whole
//        re-record, so the seconds are cheap.
// STORY_RUNNER=<id> pins every runner_ask to one tab (two live runners split ops per-op otherwise).
const PIN = process.env.STORY_RUNNER ? ` --runner=${process.env.STORY_RUNNER}` : ''
const SETTLE_MS = Number(process.env.STORY_SETTLE_MS ?? 6000)
const settle = () => { try { execSync(`sleep ${SETTLE_MS / 1000}`) } catch (e) {} }
const run = (book) => {
    for (let attempt = 0; attempt < 2; attempt++) {
        settle()
        const r = sh(`node scripts/runner_ask.mjs run ${book} --watch${PIN}`)
        const j = lastJson(r.out)
        const st = sh(`node scripts/runner_ask.mjs steps${PIN}`)
        const sj = lastJson(st.out)
        if (!sj || !sj.steps) { console.log(`  ${book}: no steps (${(r.out || '').slice(-200).replace(/\n/g, ' ')})`); sh(`node scripts/runner_ask.mjs release${PIN}`); continue }
        const fixtures = fs.existsSync(`wormhole/Story/${book}`) ? fs.readdirSync(`wormhole/Story/${book}`).filter(f => /^\d+\.snap$/.test(f)) : []
        const maxfix = fixtures.length ? Math.max(...fixtures.map(f => +f.replace('.snap', ''))) : 0
        // hollow run (fewer steps than the fixtures know) → retry once
        if (sj.steps.length < maxfix && attempt === 0) { console.log(`  ${book}: hollow (n=${sj.steps.length} < ${maxfix}) — retry`); sh(`node scripts/runner_ask.mjs release${PIN}`); continue }
        return { run: j, steps: sj.steps, fixtures }
    }
    return null
}
// NORMALISE what the runner's own EntropyArrest forgives (2026-09-17).  wormhole/Trope/Lies/NormalEntropy
//  spays `want={NUM}` (tol band ×1.5) — an epoch-ms that IS the particle's mainkey value, so it can neither
//   be dropped nor ever match across runs.  The runner reads such a step ok+caveat; this text diff saw two
//    different numbers and called it OTHER (HohoNets/Search/Surprise, 2026-09-16).  Same mask here, so the
//     residual shows only what the runner would not itself forgive.  Extend NORMALISE as NormalEntropy grows;
//      it is a mirror, not a second judge — the runner's verdict stays the gate.
const NORMALISE = [[/\bwant=\d+/g, 'want=NUM']]
const norm = (l) => NORMALISE.reduce((x, [re, to]) => x.replace(re, to), l)
const filt = (txt) => txt.split('\n').filter(l => !FILTER.test(l) && !allow.some(re => re.test(l))).map(norm).sort()
const residual = (fix, live) => {
    const a = filt(fix), b = filt(live)
    const A = new Map(), B = new Map()
    for (const l of a) A.set(l, (A.get(l) || 0) + 1)
    for (const l of b) B.set(l, (B.get(l) || 0) + 1)
    const out = []
    for (const [l, n] of A) { const m = B.get(l) || 0; if (m < n) out.push('< ' + l) }
    for (const [l, n] of B) { const m = A.get(l) || 0; if (m < n) out.push('> ' + l) }
    return out
}
const patchToc = (book, steps) => {
    const p = `wormhole/Story/${book}/toc.snap`
    if (!fs.existsSync(p)) return
    let t = fs.readFileSync(p, 'utf8')
    for (const s of steps) {
        const re = s.n === 1 ? /^(\s*step),dige:[0-9a-f]+/m : new RegExp(`^(\\s*step=${s.n}),dige:[0-9a-f]+`, 'm')
        t = t.replace(re, `$1,dige:${s.dige}`)
    }
    fs.writeFileSync(p, t)
}

for (const book of books) {
    const got = run(book)
    if (!got) { console.log(`✗ ${book}: could not run`); continue }
    // ok+caveat = the runner FORGAVE value-noise under its EntropyArrest (a spay creates the caveat; only
    //  `means,drop` mutes it).  That is the runner's verdict, not a red: count it and say so, don't fail on it.
    const cav = got.steps.filter(s => s.ok && s.caveat).length
    const red = got.steps.filter(s => !s.ok)
    if (!red.length) { console.log(`✓ ${book}: GREEN (${got.steps.length} steps, caveat ${cav})`); sh(`node scripts/runner_ask.mjs release${PIN}`); continue }
    // diff each fixture step
    let allClean = true
    let bookConfused = false
    const lives = {}
    for (const f of got.fixtures) {
        const n = +f.replace('.snap', '')
        const stepj = got.steps.find(s => s.n === n)
        if (stepj && stepj.ok) continue   // green step (a caveat is the runner's forgiveness): fixture stands
        const live = sh(`node scripts/runner_ask.mjs snap ${n}${PIN}`).stdout
        if (/^snap: \{/.test(live.trim())) { console.log(`  ${book} step ${n}: no live snap (${live.trim().slice(0, 80)})`); allClean = false; continue }
        // ⚠ THE SNAP MUST BE THIS BOOK'S (2026-09-03: a degraded runner served SwarmBody's snap for a
        //  SwarmPost step, and this script wrote it into SwarmPost's fixture — cross-Book corruption that
        //   only a `H:<Book>,Run` check catches).  Refuse the whole Book on any mismatch.
        const head = (live.split('\n')[1] || '')
        const owner = (head.match(/H:([A-Za-z0-9_]+),/) || [])[1] || ''
        if (owner !== book) { console.log(`  ${book} step ${n}: ⚠ live snap belongs to ${owner || '?'} — RUNNER CONFUSED, refusing`); allClean = false; bookConfused = true; continue }
        lives[n] = live
        const fix = fs.readFileSync(`wormhole/Story/${book}/${f}`, 'utf8')
        const res = residual(fix, live)
        if (res.length) {
            allClean = false
            console.log(`  ${book} step ${n}: residual ${res.length} line(s)`)
            for (const l of (full ? res : res.slice(0, 12))) console.log('     ' + (full ? l : l.slice(0, 200)))
        }
    }
    const errs = got.steps.filter(s => s.error).map(s => `${s.n}:${String(s.error).slice(0, 120)}`)
    if (errs.length) { allClean = false; console.log(`  ${book} errors: ${errs.join(' | ')}`) }
    if (bookConfused) { console.log(`✗ ${book}: RUNNER SERVED ANOTHER BOOK — reload the runner and retry; nothing written`); sh(`node scripts/runner_ask.mjs release${PIN}`); continue }
    if (!(allClean || force) || dry) {
        console.log(`✗ ${book}: RED — red steps ${red.map(s => s.n + (s.caveat ? 'c' : '')).join(',')}${dry ? ' (dry)' : ' — NOT accepted'}`)
        sh(`node scripts/runner_ask.mjs release${PIN}`)
        continue
    }
    for (const f of got.fixtures) { const n = +f.replace('.snap', ''); if (lives[n]) fs.writeFileSync(`wormhole/Story/${book}/${f}`, lives[n]) }
    sh(`node scripts/runner_ask.mjs release${PIN}`)
    // re-run on the accepted fixtures, THEN patch the toc diges last and verify once more
    const again = run(book)
    if (!again) { console.log(`✗ ${book}: re-run failed`); continue }
    patchToc(book, again.steps)
    sh(`node scripts/runner_ask.mjs release${PIN}`)
    const fin = run(book)
    const bad = fin ? fin.steps.filter(s => !s.ok) : null
    const fcav = fin ? fin.steps.filter(s => s.ok && s.caveat).length : 0
    if (fin && !bad.length) console.log(`✓ ${book}: ACCEPTED → GREEN (${fin.steps.length} steps, caveat ${fcav})${force ? ' [forced]' : ''}`)
    else console.log(`✗ ${book}: accepted but still red: ${bad ? bad.map(s => s.n + (s.caveat ? 'c' : '') + (s.error ? '!' : '')).join(',') : '?'}`)
    sh(`node scripts/runner_ask.mjs release${PIN}`)
}
