// OriginNav.spec — the app tree served by the origin (src/lib/server/wormhole_serve.ts) and read by
//  OriginNav (src/lib/O/OriginNav.svelte.ts), end to end over a real node http server on a temp tree.
//
//  The claims: listing is ONE request and free afterwards; a read pulls a file once and then serves it
//   from memory UNTIL the server says it moved (the stamp) — the stale-forever class LazyGithubNav's
//    OPFS seed has is exactly what this must not have; the fence serves only what github would show
//     (no _socklog/_trace, dot-files, shots/, .crswap, the gen-dige store, nothing outside the four roots, no `..` escape); nothing writes; a server
//      without the route REJECTS the mount so the caller falls back to github; a build id that moves
//       under a living tab is noticed.

import { describe, it, expect, beforeAll, afterAll, vi } from 'vitest'
import { createServer, type Server } from 'node:http'
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, utimesSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import { serve_wormhole, wormhole_servable } from '../src/lib/server/wormhole_serve.ts'
import { OriginNav, mount_origin_nav } from '../src/lib/O/OriginNav.svelte.ts'

let root: string, server: Server, base: string
const put = (rel: string, text: string) => {
    const abs = join(root, rel)
    mkdirSync(abs.slice(0, abs.lastIndexOf('/')), { recursive: true })
    writeFileSync(abs, text)
}
// a fetch that counts what it asked for — "it didn't fetch" is invisible in a return value
function counted() {
    const asked: string[] = []
    const f = (async (u: any, o?: any) => { asked.push(String(u).replace(base, '')); return fetch(u, o) }) as typeof fetch
    return { asked, f }
}

beforeAll(async () => {
    root = mkdtempSync(join(tmpdir(), 'origin-nav-'))
    put('wormhole/Ground/Radio/toc.snap', 'Ground:Radio\n')
    put('wormhole/Story/Sounditron/toc.snap', 'Book:Sounditron\n')
    put('wormhole/Story/Sounditron/001.snap', 'step 1\n')
    put('Ghost/M/Radio.g', 'Radio\n')
    put('wormhole/_trace/dump.json', 'secret')
    put('wormhole/shots/a.png', 'png')
    put('wormhole/Cluster/toc.snap.crswap', 'swap')
    put('wormhole/Cluster/.hidden', 'dot')
    put('src/lib/server/relay.ts', 'served — the code, for a folderless hacker page')
    put('src/lib/gen-dige/Theory.abc.go', 'derived store')
    put('docs/notes.md', 'not a root')
    put('.env', 'TOKEN=no')
    server = createServer((req, res) => { if (!serve_wormhole(root, req, res)) { res.statusCode = 404; res.end() } })
    await new Promise<void>(r => server.listen(0, '127.0.0.1', () => r()))
    base = `http://127.0.0.1:${(server.address() as any).port}`
})
afterAll(() => { server?.close(); rmSync(root, { recursive: true, force: true }) })

describe('wormhole_serve — the fence', () => {
    it('serves the four roots only, never what github would not show', () => {
        expect(wormhole_servable('wormhole/Ground/Radio/toc.snap')).toBe(true)
        expect(wormhole_servable('Ghost/M/Radio.g')).toBe(true)
        expect(wormhole_servable('src/lib/server/relay.ts')).toBe(true)
        for (const bad of ['docs/notes.md', 'src/lib/gen-dige/Theory.abc.go', '.env', 'wormhole/_trace/dump.json', 'wormhole/shots/a.png',
            'wormhole/Cluster/toc.snap.crswap', 'wormhole/Cluster/.hidden', 'wormhole/../.env', 'wormhole//x', 'wormhole', 'wormhole\\x'])
            expect(wormhole_servable(bad), bad).toBe(false)
    })
    it('lists exactly the servable files', async () => {
        const body = await (await fetch(`${base}/__wormhole/tree`)).json()
        expect(Object.keys(body.files).sort()).toEqual(['Ghost/M/Radio.g', 'src/lib/server/relay.ts', 'wormhole/Ground/Radio/toc.snap',
            'wormhole/Story/Sounditron/001.snap', 'wormhole/Story/Sounditron/toc.snap'])
        expect(body.build).toMatch(/^dev:\d+$/)
    })
    it('refuses escapes, fenced files and writes', async () => {
        for (const p of ['/__wormhole/raw/wormhole/%2E%2E/.env', '/__wormhole/raw/docs/notes.md', '/__wormhole/raw/src/lib/gen-dige/Theory.abc.go',
            '/__wormhole/raw/wormhole/_trace/dump.json', '/__wormhole/raw/wormhole/Cluster/.hidden'])
            expect((await fetch(base + p)).status, p).toBe(404)
        expect((await fetch(`${base}/__wormhole/raw/wormhole/Ground/Radio/toc.snap`, { method: 'PUT', body: 'x' })).status).toBe(405)
    })
    it('answers a repeated listing with 304', async () => {
        const r1 = await fetch(`${base}/__wormhole/tree`)
        const r2 = await fetch(`${base}/__wormhole/tree`, { headers: { 'if-none-match': r1.headers.get('etag')! } })
        expect(r2.status).toBe(304)
    })
})

describe('OriginNav', () => {
    it('lists the tree from ONE request', async () => {
        const { asked, f } = counted()
        const nav = await mount_origin_nav({ base, fetch: f })
        const top = await nav.dir('wormhole')
        expect(top!.directories.map(d => d.name)).toEqual(['Ground', 'Story'])
        expect((await nav.dir('wormhole', 'Story', 'Sounditron'))!.files.map(f => f.name)).toEqual(['001.snap', 'toc.snap'])
        expect(await nav.dir('wormhole', 'Nope')).toBe(null)
        expect(asked).toEqual(['/__wormhole/tree'])
    })
    it('reads a file once, then from memory while its stamp holds', async () => {
        const { asked, f } = counted()
        const nav = await mount_origin_nav({ base, fetch: f })
        const [a, b] = await Promise.all([nav.read_file('wormhole/Ground/Radio', 'toc.snap'), nav.read_file('wormhole/Ground/Radio', 'toc.snap')])
        expect(a).toBe('Ground:Radio\n'); expect(b).toBe(a)
        expect(await nav.read_file('wormhole/Ground/Radio', 'toc.snap')).toBe(a)
        expect(asked.filter(u => u.includes('/raw/')).length).toBe(1)
        expect(await nav.read_file('wormhole/Ground/Nope', 'toc.snap')).toBe(null)
        expect(asked.filter(u => u.includes('/raw/')).length).toBe(1)   // not listed ⇒ no request
    })
    it('refetches an edited file — never stale-forever', async () => {
        const nav = await mount_origin_nav({ base })
        expect(await nav.read_file('wormhole/Story/Sounditron', '001.snap')).toBe('step 1\n')
        put('wormhole/Story/Sounditron/001.snap', 'step 1, edited\n')
        const later = new Date(Date.now() + 5000); utimesSync(join(root, 'wormhole/Story/Sounditron/001.snap'), later, later)
        await nav.manifest(true)
        expect(await nav.read_file('wormhole/Story/Sounditron', '001.snap')).toBe('step 1, edited\n')
    })
    it('lists a file with the mtime + size a walker keys on', async () => {
        const nav = await mount_origin_nav({ base })
        const f = (await nav.dir('src', 'lib', 'server'))!.files.find(x => x.name === 'relay.ts')!
        expect(f.size).toBe(Buffer.byteLength('served — the code, for a folderless hacker page'))
        expect(f.modified).toBeInstanceOf(Date)
        expect(await nav.read_file('src/lib/server', 'relay.ts')).toMatch(/^served/)
    })
    it('notices a Book added on the server', async () => {
        const nav = await mount_origin_nav({ base })
        put('wormhole/Story/NewBook/toc.snap', 'Book:NewBook\n')
        await nav.manifest(true)
        expect((await nav.dir('wormhole', 'Story'))!.directories.map(d => d.name)).toContain('NewBook')
    })
    it('is read-only without a scratch, and a scratch shadows reads', async () => {
        const nav = await mount_origin_nav({ base })
        await expect(nav.write_file('wormhole/X', 'toc.snap', 'x')).rejects.toThrow(/read-only/)
        const mem = new Map<string, string>()
        const scratch = { async read_file(d: string, n: string) { return mem.get(`${d}/${n}`) ?? null },
                          async write_file(d: string, n: string, c: string) { mem.set(`${d}/${n}`, c) } }
        const nav2 = await mount_origin_nav({ base, scratch })
        await nav2.write_file('wormhole/Ground/Radio', 'toc.snap', 'mine')
        expect(await nav2.read_file('wormhole/Ground/Radio', 'toc.snap')).toBe('mine')
    })
    it('rejects the mount on a server without the route — the caller falls back to github', async () => {
        const bare = createServer((_q, s) => { s.statusCode = 404; s.end() })
        await new Promise<void>(r => bare.listen(0, '127.0.0.1', () => r()))
        await expect(mount_origin_nav({ base: `http://127.0.0.1:${(bare.address() as any).port}` })).rejects.toThrow(/origin tree 404/)
        bare.close()
    })
    it('notices the build moving under a living tab', async () => {
        const nav = await mount_origin_nav({ base })
        const warn = vi.spyOn(console, 'warn').mockImplementation(() => {})
        process.env.JAMSEND_BUILD = 'b2'
        try { await nav.manifest(true) } finally { delete process.env.JAMSEND_BUILD }
        expect(nav.build_moved).toBe('b2')
        expect(warn).toHaveBeenCalledTimes(1)
        warn.mockRestore()
    })
})
