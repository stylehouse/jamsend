// LakeRace.run — one command for the headless ghost_compile lag-proof + cost curve.
//   node scripts/LakeRace.run.mjs
import { spawnSync } from 'node:child_process'
import path from 'node:path'
const ROOT = process.cwd()
const r = spawnSync(path.join(ROOT, 'node_modules/.bin/vitest'),
    ['run', '-c', 'scripts/LakeRace.vitest.config.mjs', 'scripts/LakeRace.spec.ts'],
    { cwd: ROOT, stdio: 'inherit', timeout: 240_000 })
process.exit(r.status ?? 1)
