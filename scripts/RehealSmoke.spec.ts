// RehealSmoke (2026-08-08) — the IMPORT gate LocalGen lacks: does the written gen/M/Ra.go +
//  gen/N/Repli.go COMPILE (svelte), MOUNT, and DEPOSIT Ra_reheal_id / Repli_serve_want onto H?
//  LocalGen's CHECK gate proves the .g TRANSLATED; it does not prove the produced JS PARSES —
//   the .g one-line-callback footgun class fails exactly there, at import, which on a live tab
//    wedges %Creduler_pending forever (Story waits:loadingcoding has no timeout).  Run this after
//     any LocalGen write that bypasses the editor's compile chain.  Also pins the reheal seam's
//      Book-safety contract: no nav ⇒ null, and no throttle stamp before the nav gate.
import { test, expect } from 'vitest'
import { mount } from 'svelte'
import { House } from '../src/lib/O/Housing.svelte'
import Ra from '../src/lib/gen/M/Ra.go'
import Repli from '../src/lib/gen/N/Repli.go'
import Radio from '../src/lib/gen/M/Radio.go'
import Vyto from '../src/lib/gen/V/Vyto.go'
// ⚠ HEIST WAS MISSING FROM THIS GATE UNTIL 2026-08-14, AND IT IS THE FILE MOST OFTEN HAND-COMPILED.
//  A LocalGen write of Heist.g produced a .go with a duplicate `let` in one function — a hard parse
//   error — and BOTH gates waved it through: CHECK=1 passed (it proves the .g TRANSLATED, which is
//    exactly the distinction this file's header draws) and so did this smoke test, because it did not
//     import Heist.go. Only an unrelated spec that happened to import it caught the break. A gate that
//      names four ghosts is a gate for four ghosts; the fifth was the one being edited.
import Heist from '../src/lib/gen/M/Heist.go'

const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))

test('gen Ra.go + Repli.go mount and deposit the reheal seam', async () => {
    const H: any = new House({ name: 'Mundo' })
    mount(Ra, { target: document.body, props: { H } })
    mount(Repli, { target: document.body, props: { H } })
    mount(Radio, { target: document.body, props: { H } })
    mount(Vyto, { target: document.body, props: { H } })
    mount(Heist, { target: document.body, props: { H } })
    for (let i = 0; i < 40 && !(typeof H.Ra_reheal_id === 'function' && typeof H.Repli_serve_want === 'function'
        && typeof H.Stoker_cull === 'function' && typeof H.Vyto_strength_now === 'function'
        && typeof H.Heist_newlyadded_note === 'function'); i++) await sleep(50)
    // the import itself is the assertion — a .go that will not parse throws before this line. The verb
    //  check just proves the mount actually eatfunc'd, rather than silently mounting an empty component.
    expect(typeof H.Heist_newlyadded_note, 'Heist_newlyadded_note deposited (Heist.go imports)').toBe('function')
    expect(typeof H.Heist_scrub_one, 'Heist_scrub_one deposited').toBe('function')
    expect(typeof H.Stoker_cull, 'Stoker_cull deposited (Radio.go imports)').toBe('function')
    expect(typeof H.Vyto_strength_now, 'Vyto_strength_now deposited (Vyto.go imports)').toBe('function')
    // the strength contract: absent damp = FREE, configured 0 = full hold, pin = pin, garbage = free
    expect(H.Vyto_strength_now({}, { sc: {} }, 0), 'bare %Hold reads free').toBe(1)
    expect(H.Vyto_strength_now({}, { sc: { damp: 0 } }, 0), 'damp:0 still holds fully').toBe(0)
    expect(H.Vyto_strength_now({}, { sc: { pin: 1 } }, 0), 'pin pins').toBe(0)
    expect(H.Vyto_strength_now({}, { sc: { damp: 'x' } }, 0), 'garbage damp reads free').toBe(1)
    expect(typeof H.Ra_reheal_id, 'Ra_reheal_id deposited').toBe('function')
    expect(typeof H.Ra_stock_open, 'Ra_stock_open deposited').toBe('function')
    expect(typeof H.Ra_stock_standing, 'Ra_stock_standing deposited').toBe('function')
    expect(typeof H.Repli_serve_want, 'Repli_serve_want deposited').toBe('function')
    // the no-nav fast path: a Book-shaped w (no ra_nav, no Crate_nav on H) must return null untouched
    const w: any = { c: {}, sc: {} }
    const out = await H.Ra_reheal_id(w, { o: () => [] }, 'deadbeefdeadbeef')
    expect(out, 'no nav ⇒ null (Book-identical)').toBeNull()
    expect(w.c.reheal_ts, 'no throttle stamped before the nav gate').toBeUndefined()
})
