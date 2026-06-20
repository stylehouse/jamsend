<script lang="ts">
    // FunkHost — the generic host for an embedded applet.  Waft mounts this for any
    //  %Funkcion (or legacy %havoc) in the document and passes the funk C; FunkHost
    //   dispatches on the funk's KIND to the registered component (kinds.ts).  This is the
    //    seam that keeps Waft — which mounts the entire editable web — ignorant of any one
    //     applet's specifics: the kind module owns its UI and behaviour.  An unknown kind
    //      falls back to a bare line so an unbound/typo'd embed is still visible.
    //   A legacy `%havoc:<kind>` particle (mainkey havoc, no Funkcion key) is aliased to
    //    the Ballistics kind, so existing drum-pads route here without re-authoring.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import { FUNK_KINDS } from "$lib/O/Funk/kinds"

    let { H, w, funk, raw = false, examining }: {
        H: House, w: TheC, funk: TheC, raw?: boolean, examining?: TheC
    } = $props()

    let kind  = $derived((funk.sc.Funkcion ?? (funk.sc.havoc !== undefined ? 'Ballistics' : undefined)) as string | undefined)
    let entry = $derived(kind ? FUNK_KINDS[kind] : undefined)
</script>

{#if entry}
    {@const Kind = entry.component}
    <Kind {H} {w} {funk} {raw} {examining} />
{:else}
    {@const bound = (funk.sc.of_Book ?? funk.sc.of_dock) as string | undefined}
    <div class="fk-host-bare">Funkcion:{kind ?? '?'}{bound ? ` → ${bound}` : ''}</div>
{/if}

<style>
    .fk-host-bare {
        font-family: monospace; font-size: 0.74rem; color: #8a7a5a; padding: 0.1rem 0.2rem;
    }
</style>
