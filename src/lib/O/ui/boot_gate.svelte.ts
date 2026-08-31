// boot_gate — THE ONE IMPLEMENTATION of the boot permission tap (disk share + audio gesture),
//  shared by BootGate (the standalone gate) and Butler (the loading screen that absorbs it).
//
// WHY IT WAS EXTRACTED (2026-08-10, the owner: *"there's a from-page-load FaceSucker that says
//  'starting up', then it vanishes but then another FaceSucker comes for 'one tap to open the music'…
//   the second one of those FaceSuckers needs keeping out of happening by the first"*).  Two
//    fullscreen gates in a row is a bad arrival, and the naive fix — copy BootGate's logic into the
//     Butler — is exactly the spaghetti the same message worried about: two implementations of one
//      permission, drifting, with the FSA picker's user-gesture rule to get wrong twice.
//   So the MECHANICS live here once and the two components are just two ways of asking.
//
// THE GESTURE RULE IS THE WHOLE DIFFICULTY and it survives the move intact: the FSA picker and the
//  AudioContext resume must each be INITIATED synchronously inside the click, so open_share() kicks
//   both off and only then awaits.  Anything that awaits first has already lost the gesture and the
//    browser refuses, silently, in a way that looks like the button not working.
//
// `disk_gated` / the gats live on plain `.c`, not $state, so this POLLS (400ms) rather than deriving
//  — the same trade BootGate always made, and ample for a one-time gate.
//
// H IS A GETTER, AND MUST BE (2026-08-11).  On a BigQualand page the House is assigned inside an
//  $effect (the OOM-trap pattern), so the component mounts with its `H` prop still null — and a
//   VALUE passed here is captured once, at that moment, forever.  That bound this whole gate to
//    null on every /BigSoundland and /BigWordland tab: `null?.c?.disk_gated` polled false for the
//     life of the page, no musu_gat was ever minted, and the share/audio tap could not appear —
//      the "nobody asked for the FSA" a freshly-invited listener actually hit.  (Otro constructs H
//       before render, which is why the same gate looked healthy on dev pages.)  A plain value is
//        still accepted for that synchronous case.
export function boot_gate(H_in: any, opts: { proactive?: boolean } = {}) {
    const H = typeof H_in === 'function' ? H_in : () => H_in
    let poll = $state(0)
    let ac_poll = $state(0)
    let pending_gats: any[] = []
    let error = $state('')
    let opening = $state(false)
    // THE DECLINE IS AN ANSWER (owner 2026-08-31: "can I just decline the FSA request to get it to
    //  store only with OPFS?").  A cancelled picker used to land as a raw "AbortError…" in the error
    //   line with the gate re-armed forever — Chrome had no road to the listen-only life that
    //    no-picker browsers get automatically (Housing's stand-down).  Now a decline is remembered
    //     (not shouted) and the faces offer the alternative: `listen_only()` raises the runtime
    //      `listen_choice` flag, and Housing's listen-only branch (extended to honor choice beside
    //       incapability) stands the gate down, pins Dexie persistence, and mounts the OPFS pool —
    //        the phone-shaped life, chosen on a desktop.  `.c` only, never snapped.
    let declined = $state(false)
    function listen_only() {
        const hc: any = H()?.c
        if (hc) {
            hc.listen_choice = 1
            hc.disk_gated = false      // drop the gate NOW; the Wormhole tick re-affirms + mounts the pool
        }
        // PERSIST THE CHOICE (Onboarding §3 — owner confirmed "don't ask again later").  Until now
        //  listen_choice rode `.c` only and a reload forgot it, so a decliner got re-nagged every visit.
        //   Stash it (Dexie-backed, survives reload) so the next boot stands straight into listen-only.
        //    Escapable: "open a folder" (reopen_share / OPEN SHARE) clears it back to a folder life.
        try { (H() as any)?.top_House?.()?.imem?.('share')?.set?.('mode', 'thin') } catch {}
        declined = false
        error = ''
        poll++
    }

    // THE CAPABILITY, PROBED UP FRONT (2026-08-14, field report: "OPEN SHARE just sits there").
    //  Firefox, Safari, Brave-by-default and EVERY mobile browser have no window.showDirectoryPicker,
    //   so the picker branch below threw a TypeError that the callers read as a cancelled picker —
    //    the tap sat there doing nothing, forever, with no word why.  A capability the browser lacks
    //     is not an error the user caused; it is a fact to say out loud, once, in the gate's own face
    //      (both hosts render fsa_advice so the sentence can't drift).  There is NO open-in-chrome
    //       URL to offer instead: desktop has no such scheme, and mobile Chrome lacks the directory
    //        picker anyway — the honest advice is a desktop Chromium, said plainly.  This tempers,
    //         not repeals, the 2026-07-19 "no situation talk" ruling: that ruling assumed the tap
    //          WORKS, and a button that cannot ever succeed is worse noise than one sentence.
    const no_fsa = typeof window !== 'undefined' && typeof (window as any).showDirectoryPicker !== 'function'
    const braveish = typeof navigator !== 'undefined' && !!(navigator as any).brave
    const fsa_advice = !no_fsa ? '' : braveish
        ? 'Brave blocks folder access — enable brave://flags → "File System Access API", or use Chrome on a computer'
        : 'this browser can’t open a music folder — use Chrome (or Edge) on a computer'

    // called from an $effect in the host component, so the interval belongs to that component's
    //  lifecycle — this module owns no timers of its own.
    function start() {
        const iv = setInterval(() => {
            poll++
            // proactive (the music toplevels): a page whose whole point is sound wants its ONE tap up
            //  front, so the gate stands until the AC is granted. The gat is created cold here
            //   (keep_awake_gat never starts audio); the tap wakes it inside the gesture.
            if (opts.proactive) {
                if (!H()?.c?.musu_gat) { try { H()?.keep_awake_gat?.() } catch {} }
                const g = H()?.c?.musu_gat
                if (g && !g.AC_ready && !pending_gats.includes(g)) { pending_gats.push(g); ac_poll++ }
            }
            // MIRROR the AC-wanted fact onto the top-House .c so the toplevel authority (Screen_decide) can SEE it
            //  — the ghost can't read this store, and `disk_gated` already rides .c the same way (Housing).  Without
            //   this the splash never yields for an AUDIO-ONLY OPEN SHARE (a mobile listener's AC-resume tap, no
            //    folder gate) and the tree covers the button for the full 2.2s cap.  `.c` is never snapped; 1-or-absent
            //     to keep it a clean flag (CLAUDE.md).
            try { const hc: any = H()?.c; if (hc) { if (pending_gats.some(g => !g?.AC_ready)) hc.ac_wanted = 1; else delete hc.ac_wanted } } catch {}
        }, 400)
        const on_want = (e: any) => {
            const g = e?.detail?.gat
            if (g && !g.AC_ready && !pending_gats.includes(g)) { pending_gats.push(g); ac_poll++ }
        }
        window.addEventListener('AudioContext_wanted', on_want)
        return () => { clearInterval(iv); window.removeEventListener('AudioContext_wanted', on_want) }
    }

    async function wake_gat(g: any): Promise<boolean> {
        try {
            if (!g) return false
            if (!g.AC) { await g.init?.(); return !!g.AC_ready }
            return !!(await g.AC_OK?.())
        } catch { return false }
    }

    async function open_share() {
        error = ''
        opening = true
        const wakes = pending_gats.map(wake_gat)          // AC resume|init — within the gesture
        let disk_p: Promise<any> | null = null
        if (H()?.c?.disk_gated) {
            // a browser with no picker gets the sentence, not a TypeError dressed as a cancel —
            //  and NOT an early return: the AC wakes above already rode this same gesture and must
            //   still be awaited below, so a Brave listener's tap still grants the audio half.
            if (no_fsa) { error = fsa_advice }
            else {
                // reuses DirectoryOpener's own open_dir action so the disk path can't drift from the
                //  data layer's wiring — the reason this was never inlined as a raw showDirectoryPicker.
                const act = H()?.o({ watched: 'actions' })[0]?.o({ action: 1, role: 'open_dir' })[0]
                if (!act?.sc.fn) { error = 'wormhole not ready yet — a moment'; opening = false; return }
                disk_p = act.sc.fn()                      // requestDirectoryAccess() — same gesture
            }
        }
        // the full keep-awake pin rides the same gesture (resume + silent source + re-advertise) —
        //  harmless when the AC is already up, exactly right when this tap is the grant.
        try { H()?.keep_awake_acquire?.() } catch {}
        let granted_disk = false
        try {
            await Promise.all(wakes)
            if (disk_p) { await disk_p; granted_disk = true }
        } catch (e: any) {
            // a cancelled picker is a choice, not a fault — remember it quietly and let the faces
            //  offer "listen without a folder" instead of dressing the cancel up as an error.
            if (e?.name === 'AbortError' || /abort/i.test(String(e))) { declined = true; error = '' }
            else { error = String(e) }
        }
        finally {
            pending_gats = pending_gats.filter(g => !g?.AC_ready)
            ac_poll++
            opening = false
        }
        // RE-BOOT CLEAN WITH THE NEW NAV (owner 2026-08-31: "it's only the time that it stalled to acquire the
        //  FSA, a reload gets me into 'become'").  A tab that booted with NO share already committed its Story
        //   and glass in no-nav mode — granting the folder now can't retro-fit the stood boot, so the tab sits
        //    half-alive until a manual reload.  Do that reload FOR them, but ONLY when the boot actually ran
        //     degraded (top.c.account_mirror_owed — the "account write OWED" tell) AND the folder truly opened;
        //      a share granted EARLY (before any owed write) never reloads.  The FSA handle persists in
        //       IndexedDB, so the reload re-acquires it silently → straight into "become", no loop.  The
        //        device-link ceremony survives (its #Iz URL + stashed twin re-park on standup).
        try {
            const tc: any = H()?.top_House?.()?.c
            if (granted_disk && !error && tc?.account_mirror_owed && typeof location !== 'undefined') {
                console.log('🪪 share opened after a no-share boot — reloading to boot clean with the folder')
                location.reload()
            }
        } catch {}
    }

    return {
        start,
        open_share,
        get poll()       { return poll },
        get disk_gated() { poll; return !!H()?.c?.disk_gated },
        // the gate was raised because the BOOT needs a folder to load (BigSoundland's solicit), not the
        //  proactive audio nicety — so the face can say WHY (owner 2026-08-31: "no explanation at all that
        //   this new tab needs an FSA").  `.c` flag, set beside disk_gated, cleared with it when a share opens.
        get boot_need()  { poll; const c: any = H()?.c; return !!c?.disk_gated && !!c?.disk_gated_boot },
        get ac_wanted()  { poll; ac_poll; return pending_gats.some(g => !g?.AC_ready) },
        // WANTED = there is a permission to ask for. The one question a host needs in order to decide
        //  whether to show a button, so neither host re-derives it from the two halves.
        get wanted()     { poll; ac_poll; return !!H()?.c?.disk_gated || pending_gats.some(g => !g?.AC_ready) },
        get opening()    { return opening },
        get error()      { return error },
        // the no-picker fact + the one sentence both faces render for it (empty when capable) —
        //  shown WITHOUT waiting for a doomed tap, so the button never has to lie first.
        get fsa_missing() { return no_fsa },
        get fsa_advice()  { return fsa_advice },
        // the picker was CANCELLED — a choice worth answering with the listen-only road, not an error.
        get declined()    { return declined },
        listen_only,
    }
}
