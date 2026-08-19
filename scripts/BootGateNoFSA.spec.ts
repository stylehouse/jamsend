// BootGateNoFSA — the no-picker browser gets a SENTENCE, not a dead button (2026-08-14).
//
//  Field report, first day the link went out: on Brave (FSA off by default — likewise Firefox,
//   Safari, every mobile browser) "OPEN SHARE just sits there".  The picker branch threw a
//    TypeError that Housing's opener swallowed as a cancelled picker, so the one visible control
//     on the whole screen did nothing, wordlessly, forever.  boot_gate now probes the capability
//      up front and both faces (Butler tap, BootGate) render `fsa_advice`.
//
//  jsdom is the RIGHT environment here, not a compromise: it has no window.showDirectoryPicker,
//   which is exactly the browser under test.  (An FSA-capable browser takes the other branch —
//    that path is every day of dev use; the incapable one is the path only this file walks.)
//
//  The claims (each seen red while writing — mutation-test-every-claim):
//   1. the gate KNOWS: fsa_missing is true and fsa_advice is a non-empty sentence.
//   2. a disk-gated open_share reports the advice as its error instead of throwing a TypeError.
//   3. the tap still serves its audio half — no early return: open_share resolves cleanly.
//
//   node_modules/.bin/vitest run -c scripts/Story_cli.vitest.config.mjs scripts/BootGateNoFSA.spec.ts
import { test, expect } from 'vitest'
import { boot_gate } from '../src/lib/O/ui/boot_gate.svelte.ts'

const stub_H = () => ({ c: { disk_gated: true }, o: () => [] })

test('no-FSA browser: the gate knows, and says the one sentence', async () => {
    expect(typeof (window as any).showDirectoryPicker, 'jsdom really is the no-picker browser').toBe('undefined')
    const gate = boot_gate(stub_H)
    expect(gate.fsa_missing, 'capability probed up front').toBe(true)
    expect(gate.fsa_advice.length > 0, 'a sentence exists for both faces to render').toBe(true)
    expect(gate.fsa_advice).toMatch(/Chrome/)
})

test('a disk-gated open_share answers with the advice, not a swallowed TypeError', async () => {
    const gate = boot_gate(stub_H)
    await gate.open_share()                      // must not throw, must not hang
    expect(gate.error, 'the tap answers in words').toBe(gate.fsa_advice)
    expect(gate.opening, 'and stands down').toBe(false)
})
