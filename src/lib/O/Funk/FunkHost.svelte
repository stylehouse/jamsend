<script lang="ts">
    // FunkHost — the generic host for a %Funkcion embed.  Waft mounts this for any
    //  %Funkcion in the document and passes the funk C; FunkHost dispatches on the
    //   funk's KIND (its mainkey value) to the registered component (kinds.ts).  This is
    //    the seam that keeps Waft — which mounts the entire editable web — ignorant of any
    //     one applet's specifics: the kind module owns its UI and behaviour.  An unknown
    //      kind falls back to a bare line so an unbound/typo'd embed is still visible.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import { FUNK_KINDS } from "$lib/O/Funk/kinds"

    let { H, w, funk, raw = false }: { H: House, w: TheC, funk: TheC, raw?: boolean } = $props()

    let kind  = $derived(funk.sc.Funkcion as string)
    let entry = $derived(FUNK_KINDS[kind])
</script>

{#if entry}
    {@const Kind = entry.component}
    <Kind {H} {w} {funk} {raw} />
{:else}
    {@const bound = (funk.sc.of_Book ?? funk.sc.of_dock) as string | undefined}
    <div class="fk-host-bare">Funkcion:{kind}{bound ? ` → ${bound}` : ''}</div>
{/if}

<style>
    .fk-host-bare {
        font-family: monospace; font-size: 0.74rem; color: #8a7a5a; padding: 0.1rem 0.2rem;
    }
</style>
