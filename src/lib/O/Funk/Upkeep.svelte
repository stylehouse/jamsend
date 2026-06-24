<script lang="ts">
    // Upkeep — the %Upkeep Brink face: the machine's background work-ledger, the opposite pole of
    //  %Interest.  Where an Interest is a thing you lean TOWARD, an %Errand is work the machine owes
    //   itself — a ghost-compile in flight, a StoryTimes sweep grinding to green — that pops up here
    //    while it's live and fades once it settles, never courting attention.  It reads the ambient
    //     ledger off top_House().ave.{Upkeep} (the same C Upkeep_errand upserts hit) and ticks a
    //      local `now` so the fade stays live without a House pump (the Runner/Relay bomb-1 fix).
    import { onDestroy } from 'svelte'
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House, lens?: TheC, funk?: TheC, w?: TheC } = $props()

    let now = $state(Date.now())
    const _tick = setInterval(() => { now = Date.now() }, 1000)
    onDestroy(() => clearInterval(_tick))

    let bag = $derived((() => { void H.top_House().ave.version
        return (H.top_House().ave.o({ Upkeep: 1 })[0]) as TheC | undefined })())
    // live Errands first (newest atop), settled ones lingering ≤8s before Lies_upkeep reaps them.
    let errands = $derived.by(() => {
        void bag?.version; void now
        return ((bag?.o({ Errand: 1 }) ?? []) as TheC[])
            .filter(e => { const s = Number(e.sc.settled ?? 0); return !s || now - s < 8000 })
            .sort((a, b) => Number(b.sc.at ?? 0) - Number(a.sc.at ?? 0))
            .slice(0, 6)
    })

    const ico = (e: TheC) =>
        e.sc.phase === 'ok'     ? '✓'
      : e.sc.phase === 'failed' ? '✗'
      : e.sc.kind  === 'sweep'  ? '⇶'
      : e.sc.kind  === 'compile'? '🔄'
      :                           '◌'
    const caption = (e: TheC) =>
        e.sc.kind === 'sweep'
            ? `${e.sc.label} · pass ${Number(e.sc.pass ?? 0)} · ${Number(e.sc.green ?? 0)}/${Number(e.sc.total ?? 0)}`
      : e.sc.kind === 'compile'
            ? `${e.sc.label}${e.sc.dige ? ' @ ' + String(e.sc.dige).slice(0, 8) : ''}`
            : String(e.sc.label ?? e.sc.Errand)
</script>

{#if errands.length}
<div class="uk">
    <div class="uk-hd">upkeep</div>
    {#each errands as e (e.sc.Errand)}
        <div class="uk-row uk-{e.sc.phase ?? 'running'}" class:settling={e.sc.settled}
            title="%Errand:{e.sc.Errand} — {e.sc.kind ?? 'work'} {e.sc.phase ?? 'running'}">
            <span class="uk-ico">{ico(e)}</span>
            <span class="uk-cap">{caption(e)}</span>
        </div>
    {/each}
</div>
{/if}

<style>
    .uk {
        display: flex; flex-direction: column; gap: 2px;
        min-width: 11rem; padding: 5px 8px;
        background: rgba(18, 15, 26, 0.96); border: 1px solid #2c3450; border-top-color: #3a4570;
        border-radius: 6px 6px 0 0; font-family: monospace; font-size: 11px; color: #9aa6cc;
        box-shadow: 0 -2px 10px #0006;
    }
    .uk-hd { font-size: 9px; letter-spacing: 0.08em; text-transform: uppercase; color: #5a6488; }
    .uk-row { display: flex; align-items: center; gap: 5px; line-height: 1.3; }
    .uk-ico { font-size: 12px; line-height: 1; }
    .uk-cap { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .uk-running .uk-ico { color: #c4a86a; }
    .uk-ok      .uk-ico { color: #6ad0a0; }
    .uk-ok      .uk-cap { color: #8fe4c0; }
    .uk-failed  .uk-ico { color: #e06c75; }
    .uk-failed  .uk-cap { color: #f9a; }
    /* a settled Errand recedes (it's done — it shouldn't keep pulling the eye) before it's reaped. */
    .settling { opacity: 0.6; transition: opacity 0.4s; }
</style>
