// LazyGithubNav.spec — the owner's rule for the mounted app tree (2026-08-12): *"just the Sounditron
//  toc.snap needs downloading initially, each step may only download if it wants diffing."*
//
// The property under test is therefore not "can it read a file" but **what does it NOT fetch**.
//  Listing must be free — a Story walk enumerates the tree from the manifest and touches the network
//   zero times — and a read must pull exactly one blob, once, even when two callers race for it.
//  Every test asserts against a counted fetch stub, because "it didn't download" is the whole claim
//   and is invisible in the returned value.

import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { LazyGithubNav, OpfsOverlayNav } from '../src/lib/O/WormholeOpfs.svelte.ts'

// An in-memory FileSystemDirectoryHandle, because the first version of this spec faked the OVERLAY
//  instead of the handles and so proved nothing: `_ensure` checks for an already-present file by
//   walking the real handles (`getDirectoryHandle`/`getFileHandle`), which a fake overlay never sees.
//    The "already written locally" test passed a fetch straight through and looked like a code bug.
//  Modelling the handle interface instead lets the REAL OpfsOverlayNav run underneath, so these tests
//   cover the scratch-shadows-seed rule as well as the laziness.
function dirh(name = '/'): any {
    const dirs = new Map<string, any>(), files = new Map<string, Uint8Array>()
    return {
        name, kind: 'directory', __dirs: dirs, __files: files,
        async getDirectoryHandle(n: string, o?: { create?: boolean }) {
            if (!dirs.has(n)) { if (!o?.create) throw new Error('NotFoundError'); dirs.set(n, dirh(n)) }
            return dirs.get(n)
        },
        async getFileHandle(n: string, o?: { create?: boolean }) {
            if (!files.has(n)) { if (!o?.create) throw new Error('NotFoundError'); files.set(n, new Uint8Array()) }
            return {
                name: n, kind: 'file',
                async getFile() {
                    const b = files.get(n)!
                    return { size: b.byteLength, async text() { return new TextDecoder().decode(b) },
                             async arrayBuffer() { return b.buffer }, slice() { return this } }
                },
                async createWritable() {
                    let buf = new Uint8Array()
                    return {
                        async write(d: any) {
                            const bytes = typeof d === 'string' ? new TextEncoder().encode(d)
                                : d instanceof ArrayBuffer ? new Uint8Array(d) : new Uint8Array(d.data ?? d)
                            buf = bytes
                        },
                        async close() { files.set(n, buf) },
                        async abort() {},
                    }
                },
            }
        },
        // `values()` is what OpfsOverlayNav.dir's expand() iterates — the fake must offer it or the
        //  scratch merge silently sees an empty directory.
        async *values() { for (const [, v] of dirs) yield v; for (const [k] of files) yield { kind: 'file', name: k } },
        async *entries() { for (const [k, v] of dirs) yield [k, v]; for (const [k] of files) yield [k, { kind: 'file', name: k }] },
    }
}

async function put(root: any, path: string, text: string) {
    const parts = path.split('/'), file = parts.pop()!
    let here = root
    for (const p of parts) here = await here.getDirectoryHandle(p, { create: true })
    const fh = await here.getFileHandle(file, { create: true })
    const w = await fh.createWritable(); await w.write(text); await w.close()
}

const SRC = { owner: 'stylehouse', repo: 'jamsend', ref: 'main' }

const TREE = [
    'wormhole/Story/Sounditron/toc.snap',
    'wormhole/Story/Sounditron/001.snap',
    'wormhole/Story/Sounditron/002.snap',
    'wormhole/Story/Radiation/toc.snap',
    'wormhole/Keep/toc.snap',
    'Ghost/M/Radio.g',
]

let fetches: string[] = []
const real_fetch = globalThis.fetch

// Each test gets fresh seed+scratch handles, so the persisted manifest cache starts empty and the
//  api-call count means what it says.
async function make(scratch: Record<string, string> = {}) {
    const seed = dirh('seed'), scr = dirh('scratch')
    for (const [p, text] of Object.entries(scratch)) await put(scr, p, text)
    const opfs = new OpfsOverlayNav(seed, scr, 'test')
    const nav = new LazyGithubNav(opfs, SRC, seed)
    return { nav, opfs, seed, scratch: scr }
}

let head = 'sha-aaa'          // what `main` points at; move it to simulate a push
let head_ok = true            // false = offline / rate-limited, so the sha cannot be resolved

beforeEach(() => {
    fetches = []
    head = 'sha-aaa'
    head_ok = true
    globalThis.fetch = (async (url: any) => {
        const u = String(url)
        fetches.push(u)
        if (u.includes('/commits/')) {
            if (!head_ok) return { ok: false, status: 403 } as any
            return { ok: true, async json() { return { sha: head } } } as any
        }
        if (u.includes('api.github.com')) {
            return { ok: true, async json() { return { tree: TREE.map(path => ({ path, type: 'blob' })) } } } as any
        }
        return { ok: true, async arrayBuffer() { return new TextEncoder().encode('BLOB').buffer } } as any
    }) as any
})
afterEach(() => { globalThis.fetch = real_fetch })

const commits = () => fetches.filter(u => u.includes('/commits/')).length
const trees = () => fetches.filter(u => u.includes('/git/trees/')).length
const api = () => trees()
const raw = () => fetches.filter(u => u.includes('raw.githubusercontent.com')).length

describe('LazyGithubNav', () => {

    it('indexes the repo in ONE api call and never re-asks', async () => {
        const { nav } = await make()
        await nav.manifest(); await nav.manifest(); await nav.dir('wormhole')
        expect(api()).toBe(1)
        expect(raw()).toBe(0)
    })

    it('lists the tree without downloading any of it — the whole point', async () => {
        const { nav } = await make()
        const story = await nav.dir('wormhole', 'Story')
        expect(story!.directories.map(d => d.name)).toEqual(['Radiation', 'Sounditron'])
        expect(story!.files).toEqual([])

        const sd = await nav.dir_at('wormhole/Story/Sounditron')
        expect(sd!.files.map(f => f.name)).toEqual(['001.snap', '002.snap', 'toc.snap'])
        expect(sd!.directories).toEqual([])

        const root = await nav.dir()
        expect(root!.directories.map(d => d.name)).toEqual(['Ghost', 'wormhole'])

        expect(raw()).toBe(0)          // ← not one blob pulled for any of that
    })

    it('answers null for a path the tree does not have, without a request', async () => {
        const { nav } = await make()
        expect(await nav.dir_at('wormhole/Story/Nope')).toBe(null)
        expect(raw()).toBe(0)
    })

    it('reading one step pulls exactly that one blob', async () => {
        const { nav } = await make()
        await nav.read_file('wormhole/Story/Sounditron', 'toc.snap')
        expect(raw()).toBe(1)
        expect(fetches.some(u => u.includes('Sounditron/toc.snap'))).toBe(true)
        // …and the sibling steps stayed on the server, which is the owner's rule verbatim
        expect(fetches.some(u => u.includes('001.snap'))).toBe(false)
    })

    it('two callers racing for the same file share one fetch', async () => {
        const { nav } = await make()
        await Promise.all([
            nav.read_file('wormhole/Story/Sounditron', 'toc.snap'),
            nav.read_file('wormhole/Story/Sounditron', 'toc.snap'),
        ])
        expect(raw()).toBe(1)
    })

    it('a path outside the tree is an honest miss, not a request', async () => {
        const { nav } = await make()
        expect(await nav._ensure('wormhole/Story/Sounditron/999.snap')).toBe(false)
        expect(raw()).toBe(0)
    })

    it('never re-fetches something already written locally', async () => {
        // scratch shadows seed, so a Story save must not be clobbered by a later read pulling github's
        const { nav } = await make({ 'wormhole/Story/Sounditron/toc.snap': 'MINE' })
        expect(await nav.read_file('wormhole/Story/Sounditron', 'toc.snap')).toBe('MINE')
        expect(raw()).toBe(0)
    })

    it('merges files this app wrote that github never had', async () => {
        const { nav } = await make({ 'wormhole/Story/Sounditron/003.snap': 'new' })
        const sd = await nav.dir_at('wormhole/Story/Sounditron')
        expect(sd!.files.map(f => f.name)).toEqual(['001.snap', '002.snap', '003.snap', 'toc.snap'])
    })

    // The cache key must be CONTENT-addressed, not ref-addressed: `main` moves, so a ref-keyed cache
    //  never invalidates and a listener who indexed once would never see a Book added afterwards.
    it('re-indexes when main moves, and not otherwise', async () => {
        const { nav, seed, scratch } = await make()
        await nav.manifest()
        expect(trees()).toBe(1)

        // a second nav over the SAME opfs (a reload) — the persisted manifest should be reused
        const again = new LazyGithubNav(new OpfsOverlayNav(seed, scratch, 't'), SRC, seed)
        await again.manifest()
        expect(trees()).toBe(1)              // ← no re-index…
        expect(commits()).toBe(2)            // ← …but it did ask what main points at

        head = 'sha-bbb'                     // somebody pushed
        const after = new LazyGithubNav(new OpfsOverlayNav(seed, scratch, 't'), SRC, seed)
        await after.manifest()
        expect(trees()).toBe(2)              // ← and now it re-indexes
    })

    it('keeps yesterday\'s tree when github cannot be reached', async () => {
        const { nav, seed, scratch } = await make()
        await nav.manifest()
        head_ok = false                      // offline, or 403 rate-limited
        const offline = new LazyGithubNav(new OpfsOverlayNav(seed, scratch, 't'), SRC, seed)
        const files = await offline.manifest()
        // a freshness check that can take the tree AWAY is worse than a stale tree
        expect(files.has('wormhole/Story/Sounditron/toc.snap')).toBe(true)
        expect(trees()).toBe(1)
    })

    it('hides its own bookkeeping files from a listing', async () => {
        const { nav } = await make({ '.tree_index.json': 'x', '.seed_ref': 'y', 'wormhole/Keep/toc.snap': 'z' })
        const root = await nav.dir()
        expect(root!.files.map(f => f.name)).not.toContain('.tree_index.json')
        expect(root!.files.map(f => f.name)).not.toContain('.seed_ref')
    })
})
