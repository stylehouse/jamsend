<script lang="ts">
    // Story_cli_runner — Story_cli's headless shell PLUS Otro's dynamic-UIs rendering.
    //  Story_cli.svelte mounts <Ghost> only (the static O/* ghosts), so it can run FIXTURE
    //   Books but NOT a wrangler Book that Creduler-ACQUIRES its spine: the acquire enrols each
    //    gen .go as a watched:UIs Pantheate-include, and nothing here mounts those includes →
    //     their onMount eatfunc never deposits → Run_A_<Book> + the spine stay absent.
    //  This shell renders each House's UIs the way Otro does, so an acquired gen mounts headless
    //   and deposits.  Same M-shape + bare-Mundo construction as Story_cli.svelte otherwise.
    import Ghost from '$lib/O/Ghost.svelte'
    import { House } from '$lib/O/Housing.svelte'
    import { keyser } from '$lib/data/Stuff.svelte'

    let { onhouse } = $props<{ onhouse?: (h: any) => void }>()
    let H = $state<any>(null)

    $effect(() => {
        const h = new House({ name: 'Mundo' })
        H = h
        onhouse?.(h)
    })

    const M = { eatfunc: (hash: Record<string, Function>) => H?.eatfunc(hash) }
</script>

{#if H}
    <Ghost {H} />
    {#each H.all_House as house (house.c.ip)}
        {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
            <svelte:component this={uiC.sc.component} H={house} />
        {/each}
    {/each}
{/if}
