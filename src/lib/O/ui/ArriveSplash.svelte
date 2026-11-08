<script lang="ts">
    // ArriveSplash — the tree splash as the Ground's Face (spec/AtheoryArrive_todo.md §1.5, §5): the same Splash, told by rows.
    //  BigSoundland derives the splash's label + fraction from boot facts it names by hand (its boot_progress ladder); here every
    //   number comes from the Supervisor's fold of the page Ground's Arrive: rows (Ground.g Ground_arrive) — the label is the first
    //    row not yet met, the fraction is met (or moot) over declared, ready is the Lift arriving (Supervisor_arrived), urge is it
    //     giving up.  It judges nothing: Supervisor_lines does.  Asked twice a second; the Splash's own stall clock re-arms on a new
    //      label or a bigger fraction, so a row moving is what keeps the tree up.
    import Splash from "$lib/O/ui/Splash.svelte"
    let { H = null }: { H?: any } = $props()

    let fold = $state({ ready: false, urge: false, phase: 'starting…', frac: 0 })
    $effect(() => {
        const ask = () => {
            const M = H?.top_House ? H.top_House() : H
            const sw = M?.Supervisor_w?.(M)
            if (!sw || typeof M.Supervisor_lines !== 'function') return
            const rows = (M.Supervisor_lines(sw) as any[]).filter(l => l.key.startsWith('arrive.'))
            if (!rows.length) return
            const settled = (l: any) => l.done || l.tone === 'moot' || l.mark === '–'
            const next = rows.find(l => !settled(l))
            const arrived = M.Supervisor_arrived?.(sw)
            const got = {
                ready: arrived === 'arrived',
                urge: arrived === 'gaveup',
                phase: next ? `${next.sentence}…` : 'here',
                frac: rows.filter(settled).length / rows.length,
            }
            if (got.ready !== fold.ready || got.urge !== fold.urge || got.phase !== fold.phase || got.frac !== fold.frac) fold = got
        }
        ask()
        const iv = setInterval(ask, 500)
        return () => clearInterval(iv)
    })
</script>

<Splash ready={fold.ready} urge={fold.urge} phase={fold.phase} frac={fold.frac} />
