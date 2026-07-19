<script lang="ts">
    // BootGate — the fullscreen boot-permissions gate (disk share + audio gesture), shared
    //  by the toplevels (Otro, BigWordland) so the two rooms can't drift.
    //  Under a dev boot (?E=/?B=) the OPFS-from-github shadow disk is illegal —
    //   DirectoryOpener raises H.c.disk_gated until a real share opens, and we seize the
    //    screen until the user opens one.  A gat (SoundSystem voice) that can't auto-start
    //     fires AudioContext_wanted — that event IS the "audio was actually attempted"
    //      signal, so a tab that never plays never grows an audio gate.  The FSA picker and
    //       the AC resume must each be INITIATED inside the click's user gesture, so
    //        open_share kicks both off synchronously and awaits after.
    //  disk_gated / pending_gats live on plain .c|arrays (not $state) — a slow poll samples
    //   them; ample for a one-time gate dismiss, free of House-reactivity guesswork.
    //  audio_fullscreen: a dev boot normally leaves the PURE-audio beg to the Brink's Sound
    //   face (MiniBrink) — pass true when the host hides the Brink (BigWordland hides Lies,
    //    and the Brink lives inside Liesui), so this gate stays the reachable beg.
    //  who: the gate's addressee in the copy — defaults to the boot role (Editor|Runner).
    import FaceSucker from "$lib/p2p/ui/FaceSucker.svelte"
    import { onMount } from "svelte"
    import type { House } from "$lib/O/Housing.svelte"

    let { H, who, audio_fullscreen = false, proactive = false }: {
        H: House | null, who?: string, audio_fullscreen?: boolean, proactive?: boolean } = $props()

    let disk_poll = $state(0)
    let ac_poll   = $state(0)
    let pending_gats: any[] = []
    onMount(() => {
        const iv = setInterval(() => {
            disk_poll++
            // proactive (the music toplevels): don't wait for a hard audio demand — a page whose
            //  whole point is sound wants its ONE tap up front, so the gate stands until the AC
            //   is granted.  The gat is created cold here (keep_awake_gat never starts audio);
            //    the tap wakes it inside the gesture.
            if (proactive) {
                if (!H?.c?.musu_gat) { try { (H as any)?.keep_awake_gat?.() } catch {} }
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
    })
    let disk_gated   = $derived.by(() => { disk_poll; return !!H?.c.disk_gated })
    // event-driven only: shows when a hard audio DEMAND fired AudioContext_wanted and the
    //  gat is still cold.  No proactive nag.
    let ac_wanted    = $derived.by(() => { disk_poll; ac_poll; return pending_gats.some(g => !g?.AC_ready) })
    let ac_via_brink = $derived(!audio_fullscreen
        && (H?.c.boot_role === 'editor' || H?.c.boot_role === 'runner'))
    let role_label   = $derived(who ?? (H?.c.boot_role === 'editor' ? 'Editor' : 'Runner'))
    let share_error   = $state('')
    let opening_share = $state(false)

    // Bring a blocked gat to life: init() a fresh context, or AC_OK() a suspended one.
    async function wake_gat(g: any): Promise<boolean> {
        try {
            if (!g) return false
            if (!g.AC) { await g.init?.(); return !!g.AC_ready }
            return !!(await g.AC_OK?.())
        } catch { return false }
    }
    // ONE affordance for both permissions; reuses DirectoryOpener's own open_dir action so
    //  the disk path can't drift from the data layer's wiring.
    async function open_share() {
        share_error = ''
        opening_share = true
        const wakes = pending_gats.map(wake_gat)          // AC resume|init — within the gesture
        let disk_p: Promise<any> | null = null
        if (disk_gated) {
            const act = H?.o({ watched: 'actions' })[0]?.o({ action: 1, role: 'open_dir' })[0]
            if (!act?.sc.fn) { share_error = 'wormhole not ready yet — a moment'; opening_share = false; return }
            disk_p = act.sc.fn()                          // requestDirectoryAccess() — same gesture
        }
        // the full keep-awake pin rides the same gesture (resume + silent source + re-advertise) —
        //  harmless when the AC is already up, exactly right when this tap is the grant.
        try { (H as any)?.keep_awake_acquire?.() } catch {}
        try {
            await Promise.all(wakes)
            if (disk_p) await disk_p
        } catch (e) { share_error = String(e) }
        finally {
            pending_gats = pending_gats.filter(g => !g?.AC_ready)
            ac_poll++
            opening_share = false
        }
    }
</script>

{#if disk_gated || (ac_wanted && !ac_via_brink)}
    <FaceSucker altitude={77} fullscreen={true}>
        {#snippet content()}
            <!-- ONE standard gate, no situation talk (the human 2026-07-19: it's either needFSA
                 or needAC and naming either is noise — a nice app kids can use asks ONCE, warmly).
                 The tap harvests the gesture: AC wakes always; the folder picker fires ONLY when a
                 share is actually wanted (disk_gated) — never for a bare audio grant. -->
            <div class="disk-gate">
                <h2>one tap to open the music</h2>
                <button class="big" onclick={open_share} disabled={opening_share}>
                    {opening_share ? 'opening…' : '▶ open'}
                </button>
                {#if share_error}<p class="gate-err">{share_error}</p>{/if}
            </div>
        {/snippet}
    </FaceSucker>
{/if}

<style>
    .disk-gate {
        position: absolute;
        inset: 0;
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        gap: 1rem;
        text-align: center;
        color: #d7edff;
        padding: 2rem;
        font-family: Arial, Helvetica, sans-serif;
    }
    .disk-gate h2 { margin: 0; font-size: 1.6rem; }
    .disk-gate p  { max-width: 28rem; opacity: 0.8; }
    .disk-gate button.big {
        font-size: 1.4rem;
        padding: 0.7em 1.2em;
        cursor: pointer;
    }
    .disk-gate button:disabled { opacity: 0.5; cursor: default; }
    .disk-gate .gate-err { color: #ff8a8a; font-size: 0.9rem; }
</style>
