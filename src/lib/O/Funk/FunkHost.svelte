<script lang="ts">
    // FunkHost — the generic host for an embedded applet; the inline sibling of LensHost.
    //   Waft mounts it for any %Funkcion, passes the funk C.
    //   dispatches on the funk's kind → the registered INLINE component (kinds.ts)
    //     unknown kind, OR a hoisted-only kind (comp_<Lens> but no `component`, e.g. Runner/Relay)
    //      → a bare line, so a typo'd|unbound|UI-less embed stays visible.  (Waft renders such a kind
    //       as a plain-C row via funk_live; this {#if} is the defensive fallback if mounted directly.)
    //   the seam keeping Waft — which mounts the whole editable web — ignorant of any applet's specifics.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import { FUNK_KINDS } from "$lib/O/Funk/kinds"

    let { H, w, funk, raw = false, examining }: {
        H: House, w: TheC, funk: TheC, raw?: boolean, examining?: TheC
    } = $props()

    let kind  = $derived(funk.sc.Funkcion as string | undefined)
    let entry = $derived(kind ? FUNK_KINDS[kind] : undefined)
</script>

{#if entry?.component}
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
