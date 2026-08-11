// MountNav.spec — the mount table is pure logic over a duck-typed nav, so it is the one piece of the
//  credentials|virtual-wormhole work that can be proven without a browser, a share, or a live tab.
//
// The property that MATTERS most here is the first test: a MountNav with NO mounts must be
//  indistinguishable from the nav it wraps.  That is what makes it safe to install at the grant seam
//   ahead of any mount existing — on a developer's share (the repo, which really does carry
//    `wormhole/` on disk) nothing is ever mounted, so nothing changes.  If that test ever goes red the
//     wrapper is no longer a no-op and the seam install must come back out.

import { describe, it, expect } from 'vitest'
import { MountNav, app_tree_decision, type NavLike } from '../src/lib/O/MountNav.svelte.ts'

// a nav that records what it was asked for, so a test can assert the REBASE rather than the result
type Call = { m: string, args: any[] }
function spy(label: string): NavLike & { calls: Call[] } {
    const calls: Call[] = []
    const rec = (m: string) => (...args: any[]) => { calls.push({ m, args }); return Promise.resolve(`${label}:${m}(${args.join(',')})`) }
    return {
        calls, label,
        dir: rec('dir'), mkdirp: rec('mkdirp'),
        read_file: rec('read_file') as any, bin_read: rec('bin_read') as any,
        read_range: rec('read_range') as any, write_file: rec('write_file') as any,
        bin_write: rec('bin_write') as any, bin_append: rec('bin_append') as any,
        bin_writer: rec('bin_writer'),
    }
}
const last = (n: { calls: Call[] }) => n.calls[n.calls.length - 1]

describe('MountNav', () => {

    it('with no mounts is a pass-through — every call reaches the base unchanged', async () => {
        const base = spy('base')
        const mn = new MountNav(base)
        await mn.read_file('wormhole/Story/Sounditron', 'toc.snap')
        expect(last(base)).toEqual({ m: 'read_file', args: ['wormhole/Story/Sounditron', 'toc.snap'] })
        await mn.dir('wormhole', 'Story')
        expect(last(base)).toEqual({ m: 'dir', args: ['wormhole', 'Story'] })
        await mn.bin_write('a/b', 'c.bin', new Uint8Array(2))
        expect(last(base).m).toBe('bin_write')
        expect(last(base).args[0]).toBe('a/b')
        expect(mn.whose('anything/at/all')).toBe('base')
    })

    it('rebases a mounted path onto the mounted nav', async () => {
        const base = spy('base'), creds = spy('creds')
        const mn = new MountNav(base)
        mn.mount('.jamsend', creds)
        await mn.read_file('.jamsend/account/abc123', 'toc.snap')
        // the credentials nav has no idea it is mounted: it is asked for its OWN top-level path
        expect(last(creds)).toEqual({ m: 'read_file', args: ['account/abc123', 'toc.snap'] })
        expect(base.calls.length).toBe(0)
    })

    it('an inner prefix maps the app tree back onto itself through another backend', async () => {
        const base = spy('music'), cloud = spy('opfs')
        const mn = new MountNav(base)
        mn.mount('wormhole', cloud, { inner: 'wormhole', label: 'cloud' })
        await mn.read_file('wormhole/Story/Sounditron', 'toc.snap')
        // same path, different disk — the identity map that makes a listener's music folder carry Books
        expect(last(cloud)).toEqual({ m: 'read_file', args: ['wormhole/Story/Sounditron', 'toc.snap'] })
        expect(mn.whose('wormhole/Story')).toBe('cloud')
        // the music itself still comes off the share
        await mn.bin_read('Albums/Bowie', 'Heroes.mp3')
        expect(last(base).m).toBe('bin_read')
    })

    it('matches whole segments, never string prefixes', async () => {
        const base = spy('base'), cloud = spy('cloud')
        const mn = new MountNav(base)
        mn.mount('wormhole', cloud)
        await mn.read_file('wormholey/Story', 'x.snap')     // a sibling that merely starts the same
        expect(cloud.calls.length).toBe(0)
        expect(last(base).args[0]).toBe('wormholey/Story')
        expect(mn.whose('wormhole')).toBe('cloud')          // the mount point itself resolves to the mount
    })

    // BOTH registration orders, deliberately: with only the deep-first order this test passes even if
    //  _pick takes the FIRST match rather than the longest (a mutation run caught exactly that).  The
    //   claim is order-independence, so it has to be asserted from both sides or it is not asserted.
    it.each([['deep first', ['a/b/c', 'a']], ['shallow first', ['a', 'a/b/c']]])(
        'longest prefix wins — %s', (_name, order) => {
            const mn = new MountNav(spy('base'))
            for (const at of order as string[]) mn.mount(at, spy(at), { label: at === 'a' ? 'shallow' : 'deep' })
            expect(mn.whose('a/b/c/d')).toBe('deep')
            expect(mn.whose('a/b/c')).toBe('deep')
            expect(mn.whose('a/b/x')).toBe('shallow')
            expect(mn.whose('z')).toBe('base')
        })

    it('re-mounting a point replaces it rather than stacking', async () => {
        const base = spy('base'), first = spy('first'), second = spy('second')
        const mn = new MountNav(base)
        mn.mount('.jamsend', first, { label: 'first' })
        mn.mount('.jamsend', second, { label: 'second' })
        expect(mn.mounts.length).toBe(1)
        await mn.read_file('.jamsend', 'toc.snap')
        expect(first.calls.length).toBe(0)
        expect(second.calls.length).toBe(1)
        mn.unmount('.jamsend')
        expect(mn.whose('.jamsend')).toBe('base')
    })

    it('refuses to mount at the root', () => {
        const mn = new MountNav(spy('base'))
        expect(() => mn.mount('', spy('x'))).toThrow(/root/)
        expect(() => mn.mount('/', spy('x'))).toThrow(/root/)
    })

    it('a backend missing a method answers ABSENT — except bin_writer, which must be loud', async () => {
        const mn = new MountNav(spy('base'))
        mn.mount('thin', { label: 'thin' })                       // implements nothing at all
        expect(await mn.read_file('thin/x', 'a.snap')).toBe(null)
        expect(await mn.bin_read('thin/x', 'a.bin')).toBe(null)
        expect(await mn.dir('thin')).toBe(null)
        await mn.write_file('thin/x', 'a.snap', 'hi')             // a no-op, not a TypeError
        // …and the streaming capability is not merely absent-answering, it is GONE from the object, so
        //  the path-blind `typeof` probes never offer it in the first place
        expect(typeof mn.bin_writer).not.toBe('function')
    })

    it('still refuses to swallow a stream if a backend loses bin_writer after it was mounted', async () => {
        const base = spy('base')
        const shifty = spy('shifty')
        const mn = new MountNav(base)
        mn.mount('x', shifty, { label: 'shifty' })
        expect(typeof mn.bin_writer).toBe('function')             // narrowing saw it at mount time
        delete (shifty as any).bin_writer                          // …and it went away afterwards
        await expect(mn.bin_writer('x/y', 'a.bin')).rejects.toThrow(/bin_writer/)
    })

    // The probes in Heist.g:689 / Heist.g:3003 / Heistation.g:414 are path-BLIND: they ask the nav
    //  object whether it can stream before they have a path to route on.  An un-narrowed wrapper answers
    //   yes for a backend that cannot, and Heist lands zero-byte tracks with nothing thrown.
    it('presents optional capabilities as the intersection, so a typeof probe cannot be lied to', () => {
        const full = spy('base')
        const mn = new MountNav(full)
        expect(typeof mn.bin_append).toBe('function')
        expect(typeof mn.bin_writer).toBe('function')
        expect(typeof mn.read_range).toBe('function')

        const thin: NavLike = { label: 'thin', read_file: async () => null }   // no streaming at all
        mn.mount('.jamsend', thin, { label: 'thin' })
        expect(typeof mn.bin_append).not.toBe('function')
        expect(typeof mn.bin_writer).not.toBe('function')
        expect(typeof mn.read_range).not.toBe('function')

        // and it is narrowing, not damage: drop the thin mount and the capability comes back
        mn.unmount('.jamsend')
        expect(typeof mn.bin_append).toBe('function')
        expect(typeof mn.bin_writer).toBe('function')
    })

    it('narrows from the base too — wrapping a thin nav never invents a capability', () => {
        const mn = new MountNav({ label: 'thin', read_file: async () => null })
        expect(typeof mn.bin_append).not.toBe('function')
        expect(typeof mn.read_range).not.toBe('function')
    })

    it('dir_at resolves through the same table as dir', async () => {
        const base = spy('base'), cloud = spy('cloud')
        const mn = new MountNav(base)
        mn.mount('wormhole', cloud, { inner: 'wormhole' })
        await mn.dir_at('wormhole/Story/Sounditron')
        expect(last(cloud)).toEqual({ m: 'dir', args: ['wormhole', 'Story', 'Sounditron'] })
    })
})

// The asymmetry is the whole point: saying 'share' wrongly costs a listener their Books (recoverable,
//  visible, they just see no arrival).  Saying 'mount' wrongly redirects a DEVELOPER's Story writes
//   into OPFS scratch — work that reports saved and is gone.  So every uncertain input must answer
//    'unknown', and only a clean listing that positively lacks `wormhole` may answer 'mount'.
describe('app_tree_decision', () => {
    const D = (o: Partial<{ expanded: boolean, names: string[], boot_role: string | null }>) =>
        app_tree_decision({ expanded: true, names: ['Albums'], ...o })

    it("finds the app tree on a developer's repo share and mounts nothing", () => {
        expect(D({ names: ['wormhole', 'src', 'Ghost', 'scripts'] })).toBe('share')
    })

    it("mounts under a listener's music folder", () => {
        expect(D({ names: ['Albums', 'Singles', 'Bootlegs'] })).toBe('mount')
    })

    it('refuses every uncertain listing rather than risk a wrong mount', () => {
        expect(D({ expanded: false, names: [] })).toBe('unknown')          // never walked
        expect(D({ expanded: false, names: ['Albums'] })).toBe('unknown')  // names from a stale cache
        expect(D({ names: [] })).toBe('unknown')                           // expanded but listed nothing
    })

    it('gates an editor boot, whose real project tree is the thing it would lose', () => {
        expect(D({ names: ['Music'], boot_role: 'editor' })).toBe('gated')
        // a runner or a player has no such tree, and is exactly who this is for
        expect(D({ names: ['Music'], boot_role: 'runner' })).toBe('mount')
        expect(D({ names: ['Music'], boot_role: null })).toBe('mount')
    })

    it('an editor sitting on the real repo still just reads it', () => {
        expect(D({ names: ['wormhole', 'src'], boot_role: 'editor' })).toBe('share')
    })
})
