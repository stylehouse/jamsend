// scripts/checks.mjs — THE ONE COMMAND THAT RUNS WHAT A COMMIT CAN BREAK.  `npm run checks`.
//
//  WHY IT EXISTS (2026-08-13).  `scripts/relay-test.ts` asserts contracts nothing else covers — the
//   individuation contract most of all: *"a directed rungo to:<prepubA> must reach A ALONE"*.  A relay
//    fix landed that morning broke it, and because NOTHING RUNS THAT FILE it stayed red for hours while
//     every addressed `runner_ask` op — ping, state, steps, snap, supervisor, run — went silent.  The
//      whole flock read as disconnected with every tab alive and healthy; a day of work went unverified
//       on the strength of a diagnosis ("no runner is answering") that was simply the bug talking.
//  The test was right, present, and unread.  That is the failure this file exists to make impossible.
//
//  WHY NOT `npm test`.  That is `vitest --run` over the whole workspace and is RED AT BASELINE — 15 of
//   20 spec files fail environmentally (the vitest workspace block is commented out).  A check that is
//    always red is a check nobody reads, which is the same disease one layer up.  So this names the
//     specs that actually pass, under the config they need, and adds the relay proof beside them.
//      Keep it curated: a spec earns its place here by being green and by covering something real.
//
//  WHAT IT DOES NOT COVER, said plainly so a green here is not over-read:
//   • no browser — Playwright's chromium cannot launch in the claude container (non-root, no libglib).
//   • no Books — a live runner is still the only thing that proves the wiring end to end.
//   • nothing here proves a ghost verb is ever CALLED by a beat, or that a cell is ever COMMISSIONED.
//  Read a green as "the contracts and the pure logic hold", never as "it works".
//
//  ⚠ CORRECTION 2026-08-13, and it widened what this file can do: "no browser" was read for weeks as "no
//   face can be tested", and that was never true.  A Svelte face is a COMPONENT — `mount(Face, {target,
//    props:{n, H}})` in jsdom, beside a compiled `.go` mounted for its real verbs, renders it and runs its
//     handlers.  No layout, no Vyto, no real House; but the derives, the branches, the button wiring and
//      the empty states are all reachable, and that is where the bugs the owner reports actually live.
//  `HaulFace.spec.ts` and `HeistCostLine.spec.ts` are that, and neither could have been written under the
//   old reading.  Two habits carry over: a face has more than one SHAPE (a spec must say which — HeistFace
//    renders a compact fold unless `sc.dose === '2'`), and a face refreshes on its own INTERVAL as well as
//     on `H.version`, so wait the tick out rather than wiring propagation the live cell does not rely on.
import { spawn } from 'node:child_process'

// HaulFace.spec.ts is a FACE, not a ghost — mounted in jsdom.  It earns its place here because Sounditron
//  stopped budding heists individually, which makes that one cell the only way into a running heist: an
//   empty live list is now a lost download, not a cosmetic bug, and there is no browser here to look with.
const VITEST = ['scripts/HeistUnity.spec.ts', 'scripts/MultiHeist.spec.ts', 'scripts/HaulFace.spec.ts',
    'scripts/HeistCostLine.spec.ts', 'scripts/KeepMemoDurable.spec.ts']

const jobs = [
    {
        name: 'unit — ghost logic on a stub House',
        cmd: 'node_modules/.bin/vitest',
        args: ['run', '-c', 'scripts/Story_cli.vitest.config.mjs', ...VITEST],
    },
    {
        name: 'relay — routing, individuation, who, r2r bridge',
        cmd: 'npx',
        args: ['vite-node', 'scripts/relay-test.ts'],
    },
]

const run = (job) => new Promise((res) => {
    const t0 = Date.now()
    const p = spawn(job.cmd, job.args, { stdio: ['ignore', 'pipe', 'pipe'] })
    let out = ''
    p.stdout.on('data', (d) => { out += d })
    p.stderr.on('data', (d) => { out += d })
    p.on('close', (code) => res({ ...job, code, out, ms: Date.now() - t0 }))
    p.on('error', (er) => res({ ...job, code: 1, out: String(er), ms: Date.now() - t0 }))
})

const results = []
for (const job of jobs) {
    process.stdout.write(`▸ ${job.name} … `)
    const r = await run(job)
    results.push(r)
    console.log(`${r.code === 0 ? '✓' : '✗ FAILED'}  ${(r.ms / 1000).toFixed(1)}s`)
    // the OUTPUT of a failure, not just its name — a check that makes you re-run it by hand to find out
    //  what broke has spent your attention twice for one fact.
    if (r.code !== 0) {
        const lines = r.out.split('\n')
        const interesting = lines.filter((l) => /✗|FAIL|Error|error|expected|AssertionError/.test(l))
        console.log((interesting.length ? interesting : lines.slice(-25)).slice(-25).map((l) => '    ' + l).join('\n'))
    }
}

const bad = results.filter((r) => r.code !== 0)
console.log(bad.length ? `\n✗ ${bad.length}/${results.length} FAILED — ${bad.map((b) => b.name.split(' —')[0]).join(', ')}` : `\n✓ all ${results.length} green`)
process.exit(bad.length ? 1 : 0)
