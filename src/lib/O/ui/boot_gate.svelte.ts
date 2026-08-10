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
export function boot_gate(H: any, opts: { proactive?: boolean } = {}) {
    let poll = $state(0)
    let ac_poll = $state(0)
    let pending_gats: any[] = []
    let error = $state('')
    let opening = $state(false)

    // called from an $effect in the host component, so the interval belongs to that component's
    //  lifecycle — this module owns no timers of its own.
    function start() {
        const iv = setInterval(() => {
            poll++
            // proactive (the music toplevels): a page whose whole point is sound wants its ONE tap up
            //  front, so the gate stands until the AC is granted. The gat is created cold here
            //   (keep_awake_gat never starts audio); the tap wakes it inside the gesture.
            if (opts.proactive) {
                if (!H?.c?.musu_gat) { try { H?.keep_awake_gat?.() } catch {} }
                const g = H?.c?.musu_gat
                if (g && !g.AC_ready && !pending_gats.includes(g)) { pending_gats.push(g); ac_poll++ }
            }
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
        if (H?.c?.disk_gated) {
            // reuses DirectoryOpener's own open_dir action so the disk path can't drift from the
            //  data layer's wiring — the reason this was never inlined as a raw showDirectoryPicker.
            const act = H?.o({ watched: 'actions' })[0]?.o({ action: 1, role: 'open_dir' })[0]
            if (!act?.sc.fn) { error = 'wormhole not ready yet — a moment'; opening = false; return }
            disk_p = act.sc.fn()                          // requestDirectoryAccess() — same gesture
        }
        // the full keep-awake pin rides the same gesture (resume + silent source + re-advertise) —
        //  harmless when the AC is already up, exactly right when this tap is the grant.
        try { H?.keep_awake_acquire?.() } catch {}
        try {
            await Promise.all(wakes)
            if (disk_p) await disk_p
        } catch (e) { error = String(e) }
        finally {
            pending_gats = pending_gats.filter(g => !g?.AC_ready)
            ac_poll++
            opening = false
        }
    }

    return {
        start,
        open_share,
        get poll()       { return poll },
        get disk_gated() { poll; return !!H?.c?.disk_gated },
        get ac_wanted()  { poll; ac_poll; return pending_gats.some(g => !g?.AC_ready) },
        // WANTED = there is a permission to ask for. The one question a host needs in order to decide
        //  whether to show a button, so neither host re-derives it from the two halves.
        get wanted()     { poll; ac_poll; return !!H?.c?.disk_gated || pending_gats.some(g => !g?.AC_ready) },
        get opening()    { return opening },
        get error()      { return error },
    }
}
