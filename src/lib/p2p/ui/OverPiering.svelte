<script lang="ts">
    import type { TrustingModus } from "$lib/Trust.svelte"
    import { onDestroy, onMount } from "svelte";

    let { M }: { M: TrustingModus } = $props()

    onMount(() => {
        M.OverPierings_rows ||= []
    })
    let R = $derived(M.OverPierings_rows || [])

    const sig = (s: string) => s?.slice(0, 8) ?? '?'
    function ago(ts: number) {
        if (!ts) return ''
        let s = Math.round(Date.now() / 1000 - ts)
        return s < 60 ? `${s}s` : `${Math.round(s/60)}m`
    }
    let our_prepub = $derived(R && M.mainPeering?.instance?.Id?.pretty_pubkey?.())
</script>

{#if M.w && R}
<div class="op">
    <div class="head">
        <b title="All known peers, joined from every data source in M:Trusting">OverPiering</b>
        <span class="us" title="Our own prepub (listen address)">us:{sig(our_prepub)}</span>
        {#if M.amTyrant}<em class="tag t" title="This instance is the trust authority">TYRANT</em>{/if}
    </div>

    <div class="body">
        {#each R as s (s.prepub)}
        {@const hello_ok = s.said_hello || s.heard_hello}
        {@const trust_ok = s.said_trust || s.heard_trust}
        <div class="peer" title="prepub: {s.prepub}">

            <!-- ROW 1 -->
            <div class="row row1"
                class:ready={s.lp_ready}
                class:disc={!s.con_open && s.has_instance}
                class:ghost={!s.has_instance}>

                <!-- identity -->
                <div class="c id">
                    <span class="pub" title="prepub">{sig(s.prepub)}</span>
                    {#if s.is_tyrant}<em class="tag t" title="Instance Tyrant">T</em>{/if}
                    {#if s.Good}<em class="tag g" title="Good=true: passed Idzeugnation">G</em>{/if}
                    {#if s.stealth}<em class="tag s" title="Stealth: hidden from Garden/UI">s</em>{/if}
                    <span class="arr" title="← received (inbound) / → made (outbound)">{s.direction === 'received' ? '←' : s.direction === 'made' ? '→' : '·'}</span>
                </div>

                <!-- DataChannel + LP -->
                <div class="c con" title="DataChannel readyState + LP slot state">
                    {#if !s.has_instance}
                        <span class="dim" title="No Pier instance yet">no ier</span>
                    {:else}
                        <span class:ok={s.con_open} class:bad={!s.con_open}
                            title="DataChannel.readyState">{s.dc_state}</span>
                        {#if s.lp_const}
                            <span class="lp" class:ok={s.lp_ready}
                                title="LP const: ok+ready means RingUp() passes">{s.lp_const}</span>
                        {/if}
                    {/if}
                </div>

                <!-- hello handshake -->
                <div class="c hs" title="Hello handshake: exchange of full publicKeys">
                    <span class="arrow up" class:y={s.said_hello} class:n={!s.said_hello}
                        title="↑ said_hello: we sent our publicKey">↑</span>
                    <span class="word" class:y={hello_ok} class:n={!hello_ok}
                        class:never={s.neversaidhello}
                        title="hi — lit if either side has said hello">hi</span>
                    <span class="arrow dn" class:y={s.heard_hello} class:n={!s.heard_hello}
                        title="↓ heard_hello: got their publicKey (Ud)">↓</span>
                </div>

                <!-- trust handshake -->
                <div class="c hs" title="Trust handshake: exchange of signed trust certs">
                    <span class="arrow up" class:y={s.said_trust} class:n={!s.said_trust}
                        title="↑ said_trust: we sent our trust certs">↑</span>
                    <span class="word" class:y={trust_ok} class:n={!trust_ok}
                        title="trust — lit if either side has sent trust">trust</span>
                    <span class="arrow dn" class:y={s.heard_trust} class:n={!s.heard_trust}
                        title="↓ heard_trust: got their trust certs, features can activate">↓</span>
                </div>

            </div>

            <!-- ROW 2 -->
            <div class="row row2"
                class:ready={s.lp_ready}
                class:disc={!s.con_open && s.has_instance}
                class:ghost={!s.has_instance}>

                <!-- spacer to align with id col -->
                <div class="c id dim" title="introduced: {s.introduced_at ? ago(s.introduced_at)+' ago' : 'never'}">
                    {#if s.introduced_at}<span>{ago(s.introduced_at)}</span>{/if}
                </div>

                <!-- garden -->
                <div class="c con ga" title="Gardening state">
                    {#if s.incommunicado}<em class="tag bad" title="Incommunicado: gave up connecting">✗incm</em>{/if}
                    {#if s.perfect}<em class="tag g" title="Perfect: connected + ping good">✦perf</em>{/if}
                    {#if s.initiative}<em class="tag" class:g={!s.incommunicado}
                        title="Initiative: actively trying to connect">init</em>{/if}
                    {#if s.engaged}<em class="tag e" title="Engaged: active feature session">eng</em>{/if}
                    {#if s.ringing_failed}<em class="tag bad" title="Ringing failed to connect">ring✗</em>{/if}
                    {#if s.ringing && s.because?.length}
                        <span class="dim" title="Ringing because: {s.because.join(', ')}">{s.because.join('/')}</span>
                    {/if}
                </div>

                <!-- idzeugnation spans remaining cols -->
                <div class="c iz span4" title="Idzeugnation (invite flow) state">
                    {#if s.idzeugnation}
                        <em class="tag"
                            class:g={s.idzeugnation_finished}
                            class:bad={s.idzeugnation_dead}
                            title="IDZ{s.idzeugnation_finished ? ': done' : s.idzeugnation_asked ? ': asked, waiting' : ': started'}">
                            IDZ{s.idzeugnation_finished ? '✓' : s.idzeugnation_asked ? '…' : '?'}
                        </em>
                        {#if s.idzeugnation_waits}
                            <span class="dim" title="Waiting on: {s.idzeugnation_waits}">{s.idzeugnation_waits}</span>
                        {/if}
                    {/if}
                </div>


                <!-- ping -->
                <div class="c ping" title="Ping health">
                    {#if s.ping_good}
                        <span class="ok" title="Ping healthy, latency: {s.ping_latency}s">{s.ping_latency != null ? `${s.ping_latency}s` : '✓'}</span>
                    {:else if s.ping_bad}
                        <span class="bad" title="Ping failing: {s.ping_bad}">{s.ping_bad}</span>
                    {:else if s.lp_ready}
                        <span class="dim" title="LP ready, waiting for first pong">…</span>
                    {:else}
                        <span class="dim" title="Not connected">-</span>
                    {/if}
                </div>

                <!-- trust grants -->
                <div class="c tr" title="→ we grant them / ← they grant us">
                    {#if s.trust_to?.length}<span title="Features we grant them"><span class="arrow">↑</span>{s.trust_to.join(',')}</span>{/if}
                    {#if s.trust_from?.length}<span title="Features they grant us"><span class="arrow">↓</span>{s.trust_from.join(',')}</span>{/if}
                </div>
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

.body { display: flex; flex-direction: column; gap: 2px; }

/* each peer is two rows sharing the same column widths */
.peer { display: flex; flex-direction: column; gap: 0; }

.row {
    display: grid;
    align-items: center;
    padding: 1px 3px;
    border-left: 2px solid #183018;
    background: #090f09;
}
.row1 {
    grid-template-columns: 80px 105px 60px 80px 50px 80px;
    border-radius: 2px 2px 0 0;
}
.row2 {
    grid-template-columns: 80px 130px 1fr;
    border-radius: 0 0 2px 2px;
    background: #070d07;
    opacity: 0.85;
    margin-bottom: 1px;
}
.row.ready { border-left-color: #2a8a2a; }
.row1.ready { background: #0a130a; }
.row2.ready { background: #080f08; }
.row.disc  { border-left-color: #7a3018; opacity: .6; }
.row.ghost { border-left-color: #1a1a1a; opacity: .35; }

.c { overflow: hidden; white-space: nowrap; text-overflow: ellipsis; }
.row1 { gap: 3px; }
.row2 { gap: 3px; }

/* identity */
.pub { color: #8aba8a; font-weight: bold; font-size: 11px; }
.arr { color: #3a6a3a; margin-left: 2px; }

/* con/LP */
.ok  { color: #2a8a2a; }
.bad { color: #ba4030; }
.dim { color: #1a3a1a; }
.lp  { margin-left: 3px; color: #3a5a3a; font-size: 9px; }
.lp.ok { color: #2a8a2a; }

/* handshake — arrow + word + arrow */
.hs {
    display: flex;
    align-items: center;
    gap: 1px;
}
.arrow {
    font-size: 1.5em;
    line-height: 0.6em;
    display: inline-block;
}
.word {
    font-size: 9px;
}
.y { color: #2a8a2a; }
.n { color: #182818; }
/* neversaidhello: Ud not set at all, more alarming dim */
.never { color: #2a1818; }

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

/* trust grants */
.tr { font-size: 9px; color: #3a6a4a; display: flex; flex-direction: column; gap: 0; }

/* garden row2 */
.ga { font-size: 9px; }
.iz { font-size: 9px; color: #6a8a6a; }

.empty { color: #182818; text-align: center; padding: 4px; }
</style>