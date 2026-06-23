<script lang="ts">
    // LensHost — the generic host for a HOISTED face, the floating sibling of FunkHost.
    //  A Lens particle is Lens:<LensKind>,of_Funkcion:<funk-kind> — the Lens-KIND is the slot
    //   |intensity (Panel | InterestSmall | InterestBig), of_Funkcion names the source.  LensHost
    //    mounts that Funkcion's comp_<LensKind> face (kinds.ts).  The face gets the suggesting
    //     funk cell (if any) so it reads the same C its inline face does.  A Funkcion with no
    //      face for this Lens-kind falls back to a bare line so a typo'd suggest stays visible.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import { FUNK_KINDS } from "$lib/O/Funk/kinds"

    let { H, lens }: { H: House, lens: TheC } = $props()

    let funk     = $derived(lens.c.funk as TheC | undefined)
    let lensKind = $derived(lens.sc.Lens as string | undefined)         // Panel | InterestSmall | …
    let funkKind = $derived((lens.sc.of_Funkcion ?? funk?.sc.Funkcion) as string | undefined)
    let Face     = $derived((funkKind && lensKind
                            ? (FUNK_KINDS[funkKind] as any)?.['comp_' + lensKind]
                            : undefined) as any)
</script>

{#if Face}
    <Face {H} {lens} {funk} w={funk?.c?.up} />
{:else}
    <div class="lens-bare">Lens:{lensKind ?? '?'}/of_Funkcion:{funkKind ?? '?'} — no face</div>
{/if}

<style>
    .lens-bare {
        font-family: monospace; font-size: 0.72rem; color: #8a7a5a;
        padding: 0.2rem 0.4rem; background: #1a1622; border: 1px solid #2c2438; border-radius: 4px;
    }
</style>
