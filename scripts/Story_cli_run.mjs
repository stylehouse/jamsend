// Story_cli_run — run one headless Story Book, with -I to include a test shim.
//
//   node scripts/Story_cli_run.mjs -I SuchATest          # include shim, Book defaults to SuchATest
//   node scripts/Story_cli_run.mjs -I SuchATest -b Probe  # include shim, run Book:Probe
//   node scripts/Story_cli_run.mjs MundaneStation         # no shim, just run a Book
//   node scripts/Story_cli_run.mjs -I SuchATest --accept  # record fixtures (mode:new)
//
// Thin wrapper over the vitest runner: maps -I/-b/--accept to the INCLUDE/BOOK/ACCEPT
//  env vars the spec reads (vitest doesn't forward arbitrary flags to a test), then
//   spawns one fresh vitest process and points you at the pile it writes.
import { spawnSync } from 'node:child_process'
import path from 'node:path'

const ROOT = process.cwd()
const argv = process.argv.slice(2)
let include, book, accept = false
for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a === '-I' || a === '--include') include = argv[++i]
    else if (a === '-b' || a === '--book') book = argv[++i]
    else if (a === '--accept') accept = true
    else if (!a.startsWith('-')) book ??= a   // first bare arg is the Book
}
book ??= include   // default the Book to the shim name (SuchATest worker → Book:SuchATest)
if (!book) { console.error('need a Book: pass one positionally, via -b, or via -I'); process.exit(2) }

const env = { ...process.env, BOOK: book }
if (include) env.INCLUDE = include
if (accept)  env.ACCEPT  = '1'

const r = spawnSync(path.join(ROOT, 'node_modules/.bin/vitest'),
    ['run', '-c', 'scripts/Story_cli.vitest.config.mjs', 'scripts/Story_cli.spec.ts'],
    { env, cwd: ROOT, stdio: 'inherit', timeout: 240_000 })
console.log(`\npile → /tmp/Story_cli/${book}/   (run.json, NNN.got.snap, wstory.json)`)
process.exit(r.status ?? 1)
