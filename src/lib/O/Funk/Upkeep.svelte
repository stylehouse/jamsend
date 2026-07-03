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

    let { H, mini = false }: { H: House, lens?: TheC, funk?: TheC, w?: TheC, mini?: boolean } = $props()

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
      : e.sc.kind  === 'audio'  ? '🎤'
      :                           '◌'
    const caption = (e: TheC) =>
        e.sc.kind === 'sweep'
            ? `${e.sc.label} · pass ${Number(e.sc.pass ?? 0)} · ${Number(e.sc.green ?? 0)}/${Number(e.sc.total ?? 0)}`
      : e.sc.kind === 'compile'
            ? `${e.sc.label}${e.sc.dige ? ' @ ' + String(e.sc.dige).slice(0, 8) : ''}`
      : e.sc.kind === 'audio'
            ? `needs AudioContext · ${e.sc.label}`
            : String(e.sc.label ?? e.sc.Errand)

    // the collapsed-Brink beg: only a LIVE audio errand pops out of the MiniBrink (the Sound-face
    //  bubble idiom).  Both roles mint the errand (the runner in Lies_secure_audio, the editor in
    //   Lies_run_phase_recv), so the pill's CLICK is role-aware: when THIS tab holds the cold gat
    //    (the begging runner), the click IS the user gesture — wake it right here, one tap, done.
    //     When it doesn't (the editor), the gesture can only happen in the runner's tab, so the
    //      click just dismisses the beacon.  Everything else in the ledger (compiles, sweeps)
    //       stays full-face only — background work never begs.
    let audio_begs = $derived(errands.filter(e => e.sc.kind === 'audio' && (e.sc.phase ?? 'running') === 'running'))
    let local_gat  = $derived.by(() => { void now   // AC_ready is ephemeral — the 1s tick re-derives
        const g = (H.top_House().c as any).musu_gat
        return g && !g.AC_ready ? g : undefined })
    // dismiss = acknowledge: settle the errand (it fades like any done one) — the run itself still
    //  times out or proceeds on its own; this only quiets the beacon.
    const dismiss = (e: TheC) => { e.sc.phase = 'ok'; e.sc.settled = Date.now(); bag?.bump_version() }
    // the gesture rule (Sound.svelte's wake): kick resume|init SYNCHRONOUSLY inside the click.
    //  A woken gat un-wedges Lies_secure_audio's poll, which settles the errand itself — no dismiss.
    const tap = (e: TheC) => {
        const g = local_gat
        if (!g) { dismiss(e); return }
        try { (g.AC ? g.AC_OK?.() : g.init?.())?.catch?.(() => {}) } catch { /* a refused gesture just leaves the beg up */ }
    }
</script>

{#if mini}
    {#each audio_begs as e (e.sc.Errand)}
        <button class="uka-mini" onclick={() => tap(e)}
                title={local_gat
                    ? `${e.sc.label} is wedged awaiting an AudioContext gesture — this click grants it (this tab holds the audio)`
                    : `a runner is wedged awaiting an AudioContext gesture for ${e.sc.label} — the tap must happen in ITS tab (an ac-live runner is preferred at dispatch); click here to dismiss this beacon`}>
            <span class="uka-bubble">🎤 {local_gat ? `tap for sound — ${e.sc.label}` : `${e.sc.label} needs a sound tap`}</span>
            <span class="uka-glyph">🔇</span>
        </button>
    {/each}
{:else if errands.length}
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

    /* the MiniBrink audio beg — the Sound-face "tap for sound" idiom, re-keyed to a REMOTE runner's
       wedge: same pulsing pop-up bubble out of a muted glyph, amber like its sibling. */
    .uka-mini { position: relative; background: none; border: none; padding: 0; cursor: pointer; line-height: 1; }
    .uka-glyph { font-size: 13px; line-height: 1; }
    .uka-bubble {
        position: absolute; bottom: calc(100% + 6px); left: 50%; transform: translateX(-50%);
        white-space: nowrap; font-family: monospace; font-size: 10px; color: #f0c674;
        background: #2a1d08; border: 1px solid rgba(240, 198, 116, 0.55); border-radius: 5px;
        padding: 2px 6px; box-shadow: 0 2px 10px #0008;
        animation: uka-pulse 1.6s ease-in-out infinite;
    }
    .uka-bubble::after {   /* the downward tail toward the glyph */
        content: ''; position: absolute; top: 100%; left: 50%; transform: translateX(-50%);
        border: 4px solid transparent; border-top-color: rgba(240, 198, 116, 0.55);
    }
    @keyframes uka-pulse { 0%, 100% { opacity: 0.72; } 50% { opacity: 1; } }
    .uka-mini:hover .uka-glyph { filter: brightness(1.25); }
</style>
