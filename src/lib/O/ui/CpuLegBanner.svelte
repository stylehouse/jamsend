<script lang="ts">
    // CpuLegBanner — the on-screen announcer for the CpuLegs experiment (see CpuLegs.svelte.ts
    //  for the leg list + the reasoning). Renders nothing unless armed via ?cpu_legs=1.
    import { onMount } from "svelte"
    import { CPU_LEGS, CPU_LEGS_ARMED, cpu_leg_current, cpu_leg_index, cpu_leg_ms, cpu_leg_started_at, cpu_legs_start } from "./CpuLegs.svelte"

    onMount(() => { cpu_legs_start() })

    let now = $state(Date.now())
    $effect(() => {
        if (!CPU_LEGS_ARMED) return
        const id = setInterval(() => { now = Date.now() }, 250)
        return () => clearInterval(id)
    })

    const leg = $derived(cpu_leg_current())
    const remaining_s = $derived(Math.max(0, Math.round((cpu_leg_ms() - (now - cpu_leg_started_at())) / 1000)))
</script>

{#if CPU_LEGS_ARMED}
    <div class="cpu-leg-banner">
        CPU EXPERIMENT — leg {cpu_leg_index() + 1}/{CPU_LEGS.length}: <strong>{leg.label}</strong>
        · next leg in {remaining_s}s
    </div>
{/if}

<style>
    .cpu-leg-banner {
        position: fixed;
        top: 0; left: 0; right: 0;
        z-index: 999999;
        background: #b00020;
        color: #fff;
        font: 13px/1.4 monospace;
        padding: 4px 10px;
        text-align: center;
        pointer-events: none;
    }
</style>
