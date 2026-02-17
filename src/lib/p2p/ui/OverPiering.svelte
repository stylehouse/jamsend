<script lang="ts">
    import type { TrustingModus } from "$lib/Trust.svelte"
    import { onMount } from "svelte";

    let { M }: { M: TrustingModus } = $props()


    // ──────────────────────────────────────────────────────────────────────────
    // View — reads %OverPiering nodes that Atime keeps current
    // ──────────────────────────────────────────────────────────────────────────

    // Poll ier properties (not $state) every 1.2s
    onMount(() => {
        M.OverPierings = []
    })
    let R = $derived(M.OverPierings || [])
    let serialno = 0
    let serial = $derived(R && serialno++)

    const sig = (s: string) => s?.slice(0, 8) ?? '?'
    function ago(ts: number) {
        if (!ts) return ''
        let s = Math.round(Date.now() / 1000 - ts)
        return s < 60 ? `${s}s` : `${Math.round(s/60)}m`
    }
</script>

{#if M.w}
{#key serial}
<div class="op">
    <div class="head">
        <b>OverPiering</b>
        <span class="us">us:{sig(M.mainPeering?.instance?.Id?.pretty_pubkey?.())}</span>
        {#if M.amTyrant}<em class="tag t">TYRANT</em>{/if}
         view version {serial}
        <span class="ct">{R.length}p</span>
    </div>

    <div class="body">
        {#each R as C (C.sc.prepub)}
        {@const s = C.sc}
        <div class="row"
            class:ready={s.lp_ready}
            class:disc={!s.con_open && s.has_instance}
            class:ghost={!s.has_instance}>

            <!-- identity -->
            <div class="c id">
                <span class="pub">{sig(s.prepub)}</span>
                {#if s.is_tyrant}<em class="tag t">T</em>{/if}
                {#if s.Good}<em class="tag g">G</em>{/if}
                {#if s.stealth}<em class="tag s">s</em>{/if}
                <span class="arr">{s.direction === 'received' ? '←' : s.direction === 'made' ? '→' : '·'}</span>
            </div>

            <!-- DataChannel + LP state -->
            <div class="c con">
                {#if !s.has_instance}
                    <span class="dim">no ier</span>
                {:else}
                    <span class:ok={s.con_open} class:bad={!s.con_open}>{s.dc_state}</span>
                    {#if s.lp_const}
                        <span class="lp" class:ok={s.lp_ready}>{s.lp_const}</span>
                    {/if}
                {/if}
            </div>

            <!-- hello / trust handshake flags -->
            <div class="c hs">
                <span class:y={s.said_hello}  class:n={!s.said_hello} title="said_hello">shlo</span>
                <span class:y={s.heard_hello} class:n={!s.heard_hello} title="heard_hello (Ud)">hhlo</span>
                <span class:y={s.said_trust}  class:n={!s.said_trust}  title="said_trust">str</span>
                <span class:y={s.heard_trust} class:n={!s.heard_trust} title="heard_trust">htr</span>
            </div>

            <!-- ping -->
            <div class="c ping">
                {#if s.ping_good}
                    <span class="ok">{s.ping_latency != null ? `${s.ping_latency}s` : '✓'}</span>
                {:else if s.ping_bad}
                    <span class="bad">{s.ping_bad}</span>
                {:else if s.lp_ready}
                    <span class="dim">…</span>
                {:else}
                    <span class="dim">-</span>
                {/if}
            </div>

            <!-- trust grants -->
            <div class="c tr">
                {#if s.trust_to?.length}<span>→{s.trust_to.join(',')}</span>{/if}
                {#if s.trust_from?.length}<span>←{s.trust_from.join(',')}</span>{/if}
            </div>

            <!-- garden -->
            <div class="c ga">
                {#if s.incommunicado}<em class="tag bad">✗</em>{/if}
                {#if s.perfect}<em class="tag g">✦</em>{/if}
                {#if s.initiative}<em class="tag" class:g={!s.incommunicado}>I</em>{/if}
                {#if s.engaged}<em class="tag e">E</em>{/if}
                {#if s.ringing_failed}<em class="tag bad">RF</em>{/if}
                {#if s.ringing && s.because?.length}
                    <span class="dim">{s.because.join('/')}</span>
                {/if}
            </div>

            <!-- idzeugnation -->
            <div class="c iz">
                {#if s.idzeugnation}
                    <em class="tag"
                        class:g={s.idzeugnation_finished}
                        class:bad={s.idzeugnation_dead}>
                        IDZ{s.idzeugnation_finished ? '✓' : s.idzeugnation_asked ? '…' : '?'}
                    </em>
                    {#if s.idzeugnation_waits}
                        <span class="dim">{s.idzeugnation_waits}</span>
                    {/if}
                {/if}
            </div>

            <!-- age -->
            <div class="c ts">
                {#if s.introduced_at}{ago(s.introduced_at)}{/if}
            </div>
        </div>
        {/each}

        {#if !R.length}
            <div class="empty">no peers</div>
        {/if}
    </div>
</div>
{/key}
{/if}


<style>
.op {
    font: 10px/1.5 'Courier New', monospace;
    background: #070d07;
    color: #5a8a5a;
    border: 1px solid #183018;
    border-radius: 3px;
    padding: 5px 6px;
    width: fit-content;
    min-width: 540px;
    max-width: 100%;
}
.head {
    display: flex;
    gap: 7px;
    align-items: baseline;
    border-bottom: 1px solid #183018;
    padding-bottom: 3px;
    margin-bottom: 3px;
}
.us  { color: #2a4a2a; font-size: 9px; }
.ct  { margin-left: auto; color: #2a4a2a; }

.body { display: flex; flex-direction: column; gap: 1px; }

.row {
    display: grid;
    grid-template-columns: 80px 105px 96px 55px 80px 100px 90px 28px;
    gap: 3px;
    align-items: center;
    padding: 1px 3px;
    border-left: 2px solid #183018;
    border-radius: 1px;
    background: #090f09;
}
.row.ready { border-left-color: #2a8a2a; background: #0a130a; }
.row.disc  { border-left-color: #7a3018; opacity: .6; }
.row.ghost { border-left-color: #1a1a1a; opacity: .35; }

.c { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }

/* identity */
.pub { color: #8aba8a; font-weight: bold; font-size: 11px; }
.arr { color: #3a6a3a; margin-left: 2px; }

/* con/LP */
.ok  { color: #2a8a2a; }
.bad { color: #ba4030; }
.dim { color: #1a3a1a; }
.lp  { margin-left: 3px; color: #3a5a3a; font-size: 9px; }
.lp.ok { color: #2a8a2a; }

/* handshake */
.hs span { margin-right: 3px; font-size: 9px; }
.y { color: #2a8a2a; }
.n { color: #182818; }

/* tags */
em.tag {
    font-style: normal;
    display: inline-block;
    padding: 0 2px;
    border-radius: 2px;
    font-size: 8px;
    background: #182818;
    margin-left: 1px;
    color: #5a8a5a;
}
em.tag.t   { background: #22183a; color: #8a60aa; }
em.tag.g   { background: #183018; color: #40ba40; }
em.tag.s   { background: #18223a; color: #508aaa; }
em.tag.e   { background: #18183a; color: #5858aa; }
em.tag.bad { background: #381818; color: #ba5040; }

/* trust */
.tr { font-size: 9px; color: #3a6a4a; display: flex; flex-direction: column; gap: 0; }

/* garden */
.ga { font-size: 9px; }

/* idzeug */
.iz { font-size: 9px; color: #6a8a6a; }

/* ts */
.ts { font-size: 8px; color: #2a4a2a; }

.empty { color: #182818; text-align: center; padding: 4px; }
</style>