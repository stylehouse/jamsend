<script lang="ts">
    // Story_cli — an Otro-type shell for running a Story Book outside the browser.
    // Constructs H inside a component $effect and mounts <Ghost> so the ghosts deposit
    //  their methods onto H. (The House's own $effect.root — the todo→beliefs pump —
    //  does NOT flush under node, so the driver cranks Atime by hand; see Story_cli.spec.ts.)
    //
    // `include` is an optional extra ghost component (the `-I` shim, e.g. SuchATest.svelte).
    //  It is mounted with the same M-shape M={eatfunc} the real ghosts get in Ghost.svelte,
    //   so its onMount eatfunc deposits onto the same H — the attach path Machinery uses for
    //    its test-case children, but injected at the CLI instead of wired into the template.
    import Ghost from '$lib/O/Ghost.svelte'
    import { House } from '$lib/O/Housing.svelte'

    let { onhouse, include } = $props<{ onhouse?: (h: any) => void, include?: any }>()
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
    {#if include}{@const Inc = include}<Inc {M} />{/if}
{/if}
