<script lang="ts">
    import type { TrustingModus } from "$lib/Trust.svelte"
    import { onDestroy, onMount } from "svelte";

    let { M }: { M: TrustingModus } = $props()


    // ──────────────────────────────────────────────────────────────────────────
    // View — reads %OverPiering nodes that Atime keeps current
    // ──────────────────────────────────────────────────────────────────────────

    // Poll ier properties (not $state) every 1.2s
    onMount(() => {
        M.OverPierings_rows = []
    })
    onDestroy(() => {
        M.OverPierings_rows = null
    })
    let R = $derived(M.OverPierings_rows || [])

    const sig = (s: string) => s?.slice(0, 8) ?? '?'
    function ago(ts: number) {
        if (!ts) return ''
        let s = Math.round(Date.now() / 1000 - ts)
        return s < 60 ? `${s}s` : `${Math.round(s/60)}m`
    }
</script>

{#if M.w && R}
<div class="op">
    <div class="head">
        <b title="All known peers, joined from every data source in M:Trusting">OverPiering</b>
        <span class="us" title="Our own prepub (listen address)">us:{sig(M.mainPeering?.instance?.Id?.pretty_pubkey?.())}</span>
        {#if M.amTyrant}<em class="tag t" title="This instance is the trust authority">TYRANT</em>{/if}
        <span class="ct" title="Total known peers">{R.length}p</span>
    </div>

    <div class="body">
        {#each R as s (s.prepub)}
        <div class="row"
            class:ready={s.lp_ready}
            class:disc={!s.con_open && s.has_instance}
            class:ghost={!s.has_instance}
            title="prepub: {s.prepub}">

            <!-- identity -->
            <div class="c id">
                <span class="pub" title="prepub (first 8 of 16 hex chars)">{sig(s.prepub)}</span>
                {#if s.is_tyrant}<em class="tag t" title="Instance Tyrant — trust authority">T</em>{/if}
                {#if s.Good}<em class="tag g" title="Good=true: passed Idzeugnation, trusted peer">G</em>{/if}
                {#if s.stealth}<em class="tag s" title="Stealth: hidden from Garden/UI">s</em>{/if}
                <span class="arr" title="Direction: ← received (inbound) / → made (outbound)">{s.direction === 'received' ? '←' : s.direction === 'made' ? '→' : '·'}</span>
            </div>

            <!-- DataChannel + LP state -->
            <div class="c con" title="DataChannel readyState + LP (Listening/Pier) slot state">
                {#if !s.has_instance}
                    <span class="dim" title="No Pier instance created yet">no ier</span>
                {:else}
                    <span class:ok={s.con_open} class:bad={!s.con_open}
                        title="DataChannel.readyState — ground truth of connection">{s.dc_state}</span>
                    {#if s.lp_const}
                        <span class="lp" class:ok={s.lp_ready}
                            title="LP const state: ok+ready means RingUp() will pass">{s.lp_const}</span>
                    {/if}
                {/if}
            </div>

            <!-- hello / trust handshake -->
            <div class="c hs">
                <span class:y={s.said_hello}  class:n={!s.said_hello}
                    title="↑hi — said_hello: we sent our full publicKey to them">↑hi</span>
                <span class:y={s.heard_hello} class:n={!s.heard_hello}
                    title="hi↓ — heard_hello: received their full publicKey (Ud set)">hi↓</span>
                <span class:y={s.said_trust}  class:n={!s.said_trust}
                    title="↑trust — said_trust: we sent our stashed trust certificates">↑trust</span>
                <span class:y={s.heard_trust} class:n={!s.heard_trust}
                    title="trust↓ — heard_trust: received their trust certs, features can activate">trust↓</span>
            </div>

            <!-- ping -->
            <div class="c ping" title="Ping health — requires LP ready + heard_trust">
                {#if s.ping_good}
                    <span class="ok" title="Ping healthy, latency: {s.ping_latency}s">{s.ping_latency != null ? `${s.ping_latency}s` : '✓'}</span>
                {:else if s.ping_bad}
                    <span class="bad" title="Ping failing: {s.ping_bad}">{s.ping_bad}</span>
                {:else if s.lp_ready}
                    <span class="dim" title="LP ready, waiting for first ping round-trip">…</span>
                {:else}
                    <span class="dim" title="Not connected yet">-</span>
                {/if}
            </div>

            <!-- trust grants -->
            <div class="c tr" title="Trust grants: → what we grant them / ← what they grant us">
                {#if s.trust_to?.length}<span title="Features we grant them access to">→{s.trust_to.join(',')}</span>{/if}
                {#if s.trust_from?.length}<span title="Features they grant us access to">←{s.trust_from.join(',')}</span>{/if}
            </div>

            <!-- garden -->
            <div class="c ga" title="Gardening state: initiative/perfect/incommunicado/engaged">
                {#if s.incommunicado}<em class="tag bad" title="Incommunicado: gave up connecting">✗</em>{/if}
                {#if s.perfect}<em class="tag g" title="Perfect: connected + ping good">✦</em>{/if}
                {#if s.initiative}<em class="tag" class:g={!s.incommunicado}
                    title="Initiative: actively trying to connect">I</em>{/if}
                {#if s.engaged}<em class="tag e" title="Engaged: active feature session (eg music)">E</em>{/if}
                {#if s.ringing_failed}<em class="tag bad" title="Ringing failed to connect">RF</em>{/if}
                {#if s.ringing && s.because?.length}
                    <span class="dim" title="Reasons we want this Ringing: {s.because.join(', ')}">{s.because.join('/')}</span>
                {/if}
            </div>

            <!-- idzeugnation -->
            <div class="c iz" title="Idzeugnation (invite flow) state">
                {#if s.idzeugnation}
                    <em class="tag"
                        class:g={s.idzeugnation_finished}
                        class:bad={s.idzeugnation_dead}
                        title="IDZ{s.idzeugnation_finished ? ': finished ✓' : s.idzeugnation_asked ? ': asked, awaiting response' : ': started, not yet asked'}">
                        IDZ{s.idzeugnation_finished ? '✓' : s.idzeugnation_asked ? '…' : '?'}
                    </em>
                    {#if s.idzeugnation_waits}
                        <span class="dim" title="Currently waiting on: {s.idzeugnation_waits}">{s.idzeugnation_waits}</span>
                    {/if}
                {/if}
            </div>

            <!-- age -->
            <div class="c ts" title="{s.introduced_at ? 'Introduced ' + ago(s.introduced_at) + ' ago' : 'Not yet introduced'}">
                {#if s.introduced_at}{ago(s.introduced_at)}{/if}
            </div>
        </div>
        {/each}

        {#if !R.length}
            <div class="empty">no peers</div>
        {/if}
    </div>
</div>
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
    min-width: 580px;
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
    /* id  con   handshake  ping  trust  garden  idzeug  age */
    grid-template-columns: 80px 105px 130px 55px 80px 100px 90px 28px;
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

/* handshake — slightly wider col, arrows make it readable */
.hs { display: flex; gap: 4px; }
.hs span { font-size: 9px; }
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