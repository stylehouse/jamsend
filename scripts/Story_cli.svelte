<script lang="ts">
    // Story_cli — an Otro-type shell for running a Story Book outside the browser.
    // Constructs H inside a component $effect and mounts <Ghost> so the ghosts deposit
    //  their methods onto H. (The House's own $effect.root — the todo→beliefs pump —
    //  does NOT flush under node, so the driver cranks Atime by hand; see Story_cli.spec.ts.)
    import Ghost from '$lib/O/Ghost.svelte'
    import { House } from '$lib/O/Housing.svelte'

    let { onhouse } = $props<{ onhouse?: (h: any) => void }>()
    let H = $state<any>(null)

    $effect(() => {
        const h = new House({ name: 'Mundo' })
        H = h
        onhouse?.(h)
    })
</script>

{#if H}<Ghost {H} />{/if}
