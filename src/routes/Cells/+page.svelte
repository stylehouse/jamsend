<script lang="ts">
    // /Cells — every cell kind in one place, for a look (owner 2026-11-09: "we must have all these Cells defined somewhere I can eye
    //  them all?"; spec/AtheoryArrive_todo.md §6 (3)).  Each Face in GLASS_KINDS mounted on a bare particle (its mainkey, face:<Kind>)
    //   and a bare House (no ghosts loaded), at both poses: the minicell (small) and the main (big).  So this shows each face's EMPTY
    //    state — what it draws before anything is in it — and which faces can't stand without a live page (their tile says the
    //     error, caught by the boundary).  Seeing them full needs /Radio; this is the inventory, not the show.
    import { onMount } from 'svelte'
    import { House } from '$lib/O/Housing.svelte'
    import { TheC } from '$lib/Stuff.svelte'
    import { GLASS_KINDS } from '$lib/O/glass_kinds'

    let H = $state<any>(null)
    let errs = $state<Record<string, string>>({})
    const kinds = Object.keys(GLASS_KINDS)
    // one particle per kind and pose, made once
    const parts: Record<string, any> = {}
    function part(kind: string, pose: string) {
        const k = kind + ':' + pose
        if (!parts[k]) {
            const n = new TheC({ c: {}, sc: { [kind]: 1, face: kind } })
            n.c.pose = pose
            parts[k] = n
        }
        return parts[k]
    }
    onMount(() => { H = new House({ name: 'Cells' }) })
    function failed_with(k: string, e: any) { errs = { ...errs, [k]: String(e?.message || e).slice(0, 160) } }
</script>

<svelte:head><title>Cells</title></svelte:head>

<div class="cells">
    <h1>Every cell kind <span>{kinds.length} faces in glass_kinds.ts, each empty, on a House with no ghosts</span></h1>
    {#if H}
        <div class="grid">
            {#each kinds as kind (kind)}
                {@const Face = GLASS_KINDS[kind]}
                <section>
                    <h2>{kind}</h2>
                    <div class="poses">
                        {#each ['small', 'big'] as pose (pose)}
                            {@const k = kind + ':' + pose}
                            <div class="tile {pose}">
                                <div class="mold">
                                    <svelte:boundary onerror={(e) => failed_with(k, e)}>
                                        <Face n={part(kind, pose)} {H} />
                                        {#snippet failed()}
                                            <div class="err">✗ {errs[k] ?? 'would not draw'}</div>
                                        {/snippet}
                                    </svelte:boundary>
                                </div>
                                <span class="pose">{pose}</span>
                            </div>
                        {/each}
                    </div>
                </section>
            {/each}
        </div>
    {/if}
</div>

<style>
    .cells { min-height: 100vh; background: #12131a; color: #ccd; font: 13px/1.35 system-ui, sans-serif; padding: 16px; box-sizing: border-box; }
    h1 { font-size: 18px; margin: 0 0 12px; }
    h1 span { font-size: 12px; font-weight: 400; color: #889; margin-left: 8px; }
    .grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 520px), 1fr)); gap: 14px; }
    section { border: 1px solid #2a2c3a; border-radius: 8px; padding: 8px; background: #181a24; }
    h2 { font-size: 14px; margin: 0 0 6px; color: #ffd479; }
    .poses { display: flex; gap: 8px; align-items: flex-start; flex-wrap: wrap; }
    .tile { position: relative; overflow: hidden; border-radius: 50%; background: radial-gradient(#22283a, #0c0e16); flex: none; }
    .tile.small { width: 140px; height: 140px; }
    .tile.big { width: 340px; height: 270px; border-radius: 40%; }
    /* the inscribed box a face is molded into (Cellui's .cello-face-mold, roughly) */
    .mold { position: absolute; inset: 14% 12%; display: flex; align-items: center; justify-content: center; overflow: auto; }
    .tile.small .mold { inset: 16%; }
    .pose { position: absolute; bottom: 4px; left: 50%; transform: translateX(-50%); font-size: 10px; color: #667; pointer-events: none; }
    .err { padding: 30% 12px 0; color: #e77; font-size: 11px; text-align: center; }
</style>
