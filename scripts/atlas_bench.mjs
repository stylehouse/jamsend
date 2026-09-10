#!/usr/bin/env node
// atlas_bench — stand Atlas on a live runner and report what the stand actually cost.
//
//  WHY THIS EXISTS.  Every speed claim about Atlas this project has made was either measured by hand
//   through a dozen `runner_ask minisnap` calls, or not measured at all — and three separate "obvious"
//    diagnoses turned out to be wrong the moment an instrument was pointed at them (the adopt-cap that
//     was not the bound, the "5 minutes of parsing" that was 68 seconds, the "second full corpus walk"
//      that was a 233-doc browsing history).  The measurement has to be cheaper than the guess or the
//       guess wins.  This makes it one command.
//
//  WHAT IT READS.  `see:atlas` carries the whole shape of a stand:
//     docs · mapped · errors            what the census holds
//     from_index                        docs rostered from the Waft — 0 means it WALKED
//     dige_hit / dige_read              reads skipped vs paid
//     cache_none / cache_old / cache_moved   why an adopt was refused, split three ways
//     passes / capped / pass_ms / ms    the convergence: belief-tick round trips and wall clock
//
//   node scripts/atlas_bench.mjs [--nocache] [--runner=<id>]
//     --nocache   stand it COLD: no Dexie adopt, every doc really parsed (the expensive case)
//
//  It refuses rather than guessing when no runner is up, because a bench that invents a number is
//   worse than no bench.
import { spawnSync } from 'node:child_process'

const argv    = process.argv.slice(2)
const runner  = (argv.find(a => a.startsWith('--runner=')) ?? '').split('=')[1]
const nocache = argv.includes('--nocache')
const pin     = runner ? [`--runner=${runner}`] : []

const ask = (args, ms = 150000) => {
    const r = spawnSync('node', ['scripts/runner_ask.mjs', ...args, ...pin],
                        { encoding: 'utf8', timeout: ms })
    return (r.stdout ?? '') + (r.stderr ?? '')
}
const sleep = ms => new Promise(r => setTimeout(r, ms))

const alive = ask(['runners'], 60000)
if (!/✓ live/.test(alive)) {
    console.error('✗ no live runner — open a tab on :9091?B=<Book> first.\n' + alive.trim())
    process.exit(2)
}

console.log(`standing Atlas ${nocache ? 'COLD (--nocache)' : 'warm'}…`)
const stand = ask(['ghost_load', 'Ghost/L/Atlas.g', '--stand=Atlas', '--fresh',
                   ...(nocache ? ['--nocache'] : [])])
if (!/"included":true/.test(stand)) {
    console.error('✗ the ghost did not load:\n' + stand.trim())
    process.exit(1)
}

// poll the census row until it carries `ms` — the field Atlas_report only stamps once a pass finds
//  nothing left to do, i.e. the stand has actually settled
const t0 = Date.now()
let row = ''
for (let i = 0; i < 90; i++) {
    const out = ask(['minisnap', 'mundo', '--depth=4', '--nodes=20000'])
    row = (out.match(/see:atlas[^\t\n]*/) ?? [''])[0]
    const elapsed = Math.round((Date.now() - t0) / 1000)
    if (row) process.stdout.write(`\r  ${elapsed}s  ${row.slice(0, 110)}`.padEnd(120))
    if (/,ms:/.test(row)) break
    await sleep(3000)
}
console.log('')

if (!/,ms:/.test(row)) {
    console.error('\n✗ it never settled — the tab may be wedged (see the memory note on "accepted but never starts")')
    process.exit(1)
}

const f = k => { const m = row.match(new RegExp(`,${k}:(\\d+)`)); return m ? +m[1] : 0 }
const docs = f('docs'), from_index = f('from_index'), ms = f('ms'), passes = f('passes')
console.log('')
console.log(`  docs          ${docs}   (mapped ${f('mapped')}, errors ${f('errors')})`)
console.log(`  roster        ${from_index ? `${from_index} from the index Waft — no walk` : 'WALKED the tree (no index Waft found)'}`)
console.log(`  reads         ${f('dige_hit')} skipped, ${f('dige_read')} paid`)
console.log(`  adopt refused none:${f('cache_none')} old:${f('cache_old')} moved:${f('cache_moved')}`)
console.log(`  convergence   ${passes} passes (capped ${f('capped')}), last pass ${f('pass_ms')}ms`)
// roster + convergence stated apart, because they are the two halves the index Waft changes in
//  opposite directions: it removes the walk (roster_ms) and touches convergence not at all.  `ms`
//   alone is convergence only and is blind to the whole point of the change.
console.log(`  roster took   ${(f('roster_ms') / 1000).toFixed(1)}s   (the walk, or the one file read)`)
console.log(`  then settled  ${(ms / 1000).toFixed(1)}s   (convergence after the roster)`)
console.log(`  WALL CLOCK    ${(f('total_ms') / 1000).toFixed(1)}s   ← the whole stand`)
console.log('')
// the number that decides whether the caps are the bound, stated rather than left to be re-derived
// work vs waiting, summed over the whole stand — the split that says whether to make the work
//  cheaper or the passes fewer.  They are completely different fixes and only this ratio picks one.
const work = f('work_ms'), total = f('total_ms')
if (passes && total) {
    const waiting = Math.max(0, total - work)
    console.log(`  ${Math.round(total / passes)}ms per pass · ${(work / 1000).toFixed(1)}s working, ${(waiting / 1000).toFixed(1)}s waiting for belief ticks (${Math.round(100 * waiting / total)}% wait)`)
}
