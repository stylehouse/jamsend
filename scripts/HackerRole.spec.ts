// HackerRole — UNIT TESTS FOR role:hacker, with no runner, no browser and no wire.
//
//  WHY THIS FILE EXISTS.  There is exactly ONE editor and Lies enforces it: the `%HostedIdentity` claim
//   ("the editor that is claiming supersedes every other editor row", LiesFunk ~:499) and
//    `Lies_aim_setup`'s `=== 'editor'` gate.  So a second editor tab EVICTS the human from their own
//     slot.  `role:hacker` (2026-09-08) exists so a code-wandering room can stand docks beside a working
//      editor without being that kind of editor.
//
//  THE SAFETY CLAIM IS A PURE FUNCTION OF ROLE, which is why it gates here rather than in a Book: every
//   duty in the spine is an EQUALITY test against `'editor'`, so a third value opts out of all of them
//    and no future duty can forget to exclude it.  That property is what these tests pin — not the
//     browser behaviour (which is owed separately), but the invariant the browser behaviour rests on.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/HackerRole.spec.ts
import { test, expect } from 'vitest'
import { readFileSync } from 'node:fs'
import path from 'node:path'

const ROOT = process.cwd()
const read = (p: string) => readFileSync(path.join(ROOT, p), 'utf8')

// The role resolver, lifted verbatim from LiesLies.svelte's `Lies_role`.  Mounting the whole ghost
//  headless would drag the relay, Dexie and the Creduler in for a question that is four lines of logic;
//   instead the SOURCE is asserted to still match (test 1), so this copy cannot drift silently.
function role_of(H: any, w?: any): string | undefined {
    const role = H.c.role
    if (role === 'editor' || role === 'runner' || role === 'hacker') return role
    if (w?.sc?.editor) return 'editor'
    if (w?.sc?.runner) return 'runner'
    if (w?.sc?.hacker) return 'hacker'
    return undefined
}
const is_editor  = (H: any, w?: any) => role_of(H, w) === 'editor'
const has_docks  = (H: any, w?: any) => { const r = role_of(H, w); return r === 'editor' || r === 'hacker' }

test('the resolver under test still matches LiesLies (this copy cannot drift silently)', () => {
    const src = read('src/lib/O/LiesLies.svelte')
    expect(src).toContain("if (role === 'editor' || role === 'runner' || role === 'hacker') return role")
    expect(src).toContain("if (w?.sc?.hacker) return 'hacker'")
    // and the two predicates this file leans on
    expect(src).toContain("Lies_is_editor(w?: TheC): boolean { return (this as House).Lies_role(w) === 'editor' }")
    expect(src).toContain('Lies_has_docks(w?: TheC): boolean')
})

test('a hacker is a hacker, by House role or by world flag', () => {
    expect(role_of({ c: { role: 'hacker' } })).toBe('hacker')
    expect(role_of({ c: {} }, { sc: { hacker: 1 } })).toBe('hacker')
    // and the two it must never be mistaken for
    expect(role_of({ c: { role: 'editor' } })).toBe('editor')
    expect(role_of({ c: { role: 'runner' } })).toBe('runner')
})

test('THE SAFETY CLAIM — a hacker is never the editor, so it never claims the editor row', () => {
    const hacker = { c: { role: 'hacker' } }
    expect(is_editor(hacker)).toBe(false)
    // every duty in the spine is spelled this way, so this one assertion covers all of them:
    //  Lies_aim_setup, the %HostedIdentity claim, Lies_send_rungo, Lies_drain_rungo,
    //   Lies_send_gen_write, Lies_ledger_broadcast, Lies_transport_up.
    expect(role_of(hacker) === 'editor').toBe(false)
})

test('a hacker HAS DOCKS — the capability it exists for', () => {
    expect(has_docks({ c: { role: 'hacker' } })).toBe(true)
    expect(has_docks({ c: { role: 'editor' } })).toBe(true)
    expect(has_docks({ c: { role: 'runner' } })).toBe(false)
    expect(has_docks({ c: {} })).toBe(false)
})

test('a hacker stands NO CHANNEL — the reason it cannot collide with the editor', () => {
    const src = read('src/lib/O/LiesLies.svelte')
    // Lies_channel_up returns bare for anything that is not editor|runner|armed-player…
    expect(src).toContain("if (role !== 'editor' && role !== 'runner' && !player) return")
    // …and Lies_transport_up is editor-only, so a hacker never even opens the socket.
    expect(src).toContain("if (role !== 'editor') return   // EDITOR-only")
    // the caller gates the whole trio the same way
    expect(read('src/lib/O/Lies.svelte'))
        .toContain('if (H.Lies_is_editor(w) || H.Lies_is_runner(w) || H.Lies_player_seen(w)) {')
})

test('a hacker READS — the write gates stay editor-only', () => {
    const lies = read('src/lib/O/Lies.svelte')
    // the Waft save, and the two Keep cursor WRITES: still `=== 'editor'`
    expect(lies).toContain("H.Lies_role(w) === 'editor' && !H.Lies_nowriting(w, path)) H.Lies_waft_save(w, waft)")
    expect(lies).toContain("if (H.Lies_role(w) === 'editor') H.Lies_keep_mark_focus(w, waft_key)")
    expect(lies).toContain("H.Lies_role(w) === 'editor')\n            H.Lies_keep_note_cursor(w, waft_key, src)")
    // …while the cursor RESUME, a read, is shared with a hacker
    expect(lies).toContain('const resume = H.Lies_has_docks(w) ? H.Lies_keep_resume_what(w, waft, path) : undefined')
    // and the compile's dock_source stays editor-only
    expect(read('src/lib/O/LangCompiling.svelte')).toContain('...(H.Lies_is_editor(w) ? { dock_source:')
})

test('the spine still loads for a hacker — Creduler is gated on the flag, not the role', () => {
    expect(read('src/lib/O/Lies.svelte')).toContain('if (w.sc.creduler) await H.Creduler_ensure(w)')
})

test('the two rooms that boot a hacker do so without taking the editor slot', () => {
    // Otro's ?H= — boot_role editor (world layout + disk gating) but role hacker (duties miss)
    expect(read('src/lib/O/Otro.svelte'))
        .toContain("else if (hacker_book) { h.c.book = hacker_book; h.c.boot_role = 'editor'; h.c.role = 'hacker' }")
    // BigWordland defaults to the hacker road; ?E= is the explicit opt-in to the old editor room
    const bw = read('src/lib/L/BigWordland.svelte')
    expect(bw).toContain("boot_qualand({ book: hacker_book, role: 'hacker' })")
    expect(bw).toContain("boot_param('H') || 'Hackarium'")
    // and boot_qualand stamps the role for it
    expect(read('src/lib/O/BigQualand.svelte.ts')).toContain("if (opts.role === 'hacker') h.c.role = 'hacker'")
})

test('Hackarium lays a hacker Lies, a flagless Lang, and stands its own land', () => {
    const rec = read('src/lib/L/Hackarium.svelte')
    expect(rec).toContain("H.c.role ??= 'hacker'")
    expect(rec).toContain("H.i({ A: 'Lies' }).i({ w: 'Lies', hacker: 1 })")
    expect(rec).toContain("H.i({ A: 'Lang' }).i({ w: 'Lang' })")
    // no editor flag anywhere — that would make Lies_role answer 'editor' and undo the whole thing
    expect(rec).not.toContain('editor: 1')
    // it stands the land itself (no ghost_load, no relay) and never awaits the import from the do_fn
    expect(rec).toContain("['Ghost/L/Atlas.g', 'Atlas']")
    expect(rec).toContain("['Ghost/L/Lagoon.g', 'Lagoon']")
    expect(rec).toContain('top.Lies_ghost_set(path)\n                    .then(')
})
