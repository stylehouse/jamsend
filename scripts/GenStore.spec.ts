// GenStore.spec — compiled ghosts named by their content (src/lib/server/gen_store.ts), on a temp tree.
//
//  The claims: the store's dige IS the one /__gen/dige serves (dige.ts), so a tab's existing map indexes it; a build is
//   stored once by content and never rewritten; a recompile is a NEW file and the old one stays; `moved` names exactly the
//    rows that changed (a vanished build as dige ''), across flavour trees; gc keeps the manifest and the young.

import { describe, it, expect, beforeAll, afterAll } from 'vitest'
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, readdirSync, rmSync, utimesSync, existsSync, unlinkSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { gen_store_new, gen_store_sync, gen_store_gc, gen_store_name, gen_dig } from '../src/lib/server/gen_store.ts'
import { gen_diges } from '../src/lib/server/dige.ts'

let root: string
const lib = (rel: string) => join(root, 'src/lib', rel)
const put = (rel: string, text: string) => {
    const abs = lib(rel)
    mkdirSync(abs.slice(0, abs.lastIndexOf('/')), { recursive: true })
    writeFileSync(abs, text)
    const later = new Date(Date.now() + Math.random() * 1e6); utimesSync(abs, later, later)   // a distinct mtime per write
}
const store = () => readdirSync(lib('gen-dige')).filter(f => !f.startsWith('.')).sort()

beforeAll(() => {
    root = mkdtempSync(join(tmpdir(), 'gen-store-'))
    put('gen/A/Theory.go', '<script>theory v1</script>\n')
    put('gen/N/Peeroleum.go', '﻿<script>spine</script>\n')
    put('gen-electrode/M/Heist.go', '<script>heist measured</script>\n')
})
afterAll(() => rmSync(root, { recursive: true, force: true }))

describe('gen_store', () => {
    const st = gen_store_new()
    it('stores every flavour by content, with the dige /__gen/dige serves', () => {
        const { manifest, moved } = gen_store_sync(root, st)
        expect(Object.keys(manifest).sort()).toEqual(['gen-electrode/M/Heist.go', 'gen/A/Theory.go', 'gen/N/Peeroleum.go'])
        expect(moved.length).toBe(3)                                   // the first sync reports all
        const served = gen_diges(root)
        expect(manifest['gen/A/Theory.go']).toBe(served['gen/A/Theory.go'][0])
        expect(manifest['gen/N/Peeroleum.go']).toBe(served['gen/N/Peeroleum.go'][0])   // BOM dropped alike
        for (const [g, d] of Object.entries(manifest))
            expect(readFileSync(lib(gen_store_name(g, d)), 'utf8').replace(/^﻿/, '')).toBe(readFileSync(lib(g), 'utf8').replace(/^﻿/, ''))
        expect(store()).toContain(`Theory.${manifest['gen/A/Theory.go']}.go`)
    })
    it('a quiet resync moves nothing', () => {
        expect(gen_store_sync(root, st).moved).toEqual([])
    })
    it('a recompile is a new name; the old build stays', () => {
        const old = st.manifest['gen/A/Theory.go']
        put('gen/A/Theory.go', '<script>theory v2</script>\n')
        const { moved } = gen_store_sync(root, st)
        expect(moved).toEqual([{ gen: 'gen/A/Theory.go', dige: gen_dig('<script>theory v2</script>\n') }])
        expect(existsSync(lib(gen_store_name('gen/A/Theory.go', old)))).toBe(true)
        expect(readFileSync(lib(gen_store_name('gen/A/Theory.go', old)), 'utf8')).toBe('<script>theory v1</script>\n')
    })
    it('a touched-but-identical build moves nothing', () => {
        put('gen-electrode/M/Heist.go', '<script>heist measured</script>\n')
        expect(gen_store_sync(root, st).moved).toEqual([])
    })
    it('a vanished build moves to dige ""', () => {
        unlinkSync(lib('gen-electrode/M/Heist.go'))
        expect(gen_store_sync(root, st).moved).toEqual([{ gen: 'gen-electrode/M/Heist.go', dige: '' }])
    })
    it('gc drops only old builds outside the manifest', () => {
        const before = store().length
        expect(gen_store_gc(root, st.manifest, 3600_000)).toBe(0)         // all young
        const n = gen_store_gc(root, st.manifest, 0, Date.now() + 1e7)    // all old
        expect(n).toBe(before - 2)                                         // Theory v1 + Heist went
        expect(store()).toEqual(Object.entries(st.manifest).map(([g, d]) => gen_store_name(g, d).slice('gen-dige/'.length)).sort())
    })
})
