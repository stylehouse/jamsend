<script module lang="ts">
    import type { TheC as TheCm } from "$lib/data/Stuff.svelte"
    // relay_run — the Relay Funkcion's pumped watcher, the second ping (the relay/socket carrier,
    //  distinct from the peer).  Pure C-tree, no H: it inlines Lies_channel_live (channel_up + a
    //   live active_transport connection) off w:Lies and stamps funk.c.latest on a TRANSITION
    //    (up↔down), so the Brink can caption when the relay last came or went.  Mature %Aim will
    //     feed this the relay's control:log lines (relay.ts relayLog) for a real event stream.
    export function relay_run(_host: TheCm, funk: TheCm, ww: TheCm): void {
        const at   = ww.o({ active_transport: 1 })[0] as TheCm | undefined
        const up   = !!(ww.c.channel_up && at?.c.connection)
        const state = up ? 'up' : 'down'
        if ((funk.c.latest as { state?: string } | undefined)?.state === state) return
        funk.c.latest = { state, event: up ? 'relay up' : 'relay down', at: Date.now() }
        funk.bump_version()
    }
</script>

<script lang="ts">
    // Relay — the relay/socket monitor, hoisted as a Lens:Brink beside the Runner.  Where the
    //  Runner watches the PEER (a remote editor/runner, via %channel_peer pongs), the Relay watches
    //   the CARRIER itself: is the websocket to the relay up?  The two are distinct signals —
    //    the relay can be up while no peer has dialed in, or a peer can go silent on a live relay.
    //     It reads the same w:Lies the suggester backlinks on the lens (lens.c.w) and ticks a local
    //      `now` so the "last changed Ns ago" stays live without a w bump (the Runner-bomb fix).
    import { onDestroy } from 'svelte'
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, lens, funk }: { H: House, lens?: TheC, funk?: TheC, w?: TheC } = $props()

    let now = $state(Date.now())
    const _tick = setInterval(() => { now = Date.now() }, 1000)
    onDestroy(() => clearInterval(_tick))

    let live = $state(false)
    let wref = $state<TheC | undefined>(undefined)
    $effect(() => {
        const w = (lens?.c?.w ?? H.ave.ob({ examining: 1 })[0]?.c?.w) as TheC | undefined
        if (!w) return
        wref = w
        w.ob()
        H.clear(async () => {
            const at = w.o({ active_transport: 1 })[0] as TheC | undefined
            live = !!(w.c?.channel_up && at?.c?.connection)
        })
    })

    // the relay/carrier event stream — relay control:log lines + the carrier's SEND/RECV/dial events,
    //  ringed onto w.c.relay_log by Tribunal.g's `note` (off-snap, capped, NO version bump). Polled on
    //   the 1s `now` tick, so it's a live in-UI console for "what is the channel actually doing" without
    //    re-pumping the House — the Relay Brink's "real event stream" TODO, the msgs-other-than-pong view.
    // event lines fade out 5s after they land (depend on the tick) — a live "what just happened"
    //  toast stream, not a growing backlog.  Quiet when nothing's happening, which is the honest
    //   resting state.  (No funk.c.latest caption here: it just duplicated the link line + grew a
    //    misleading age; the link is the steady state, this is the events.)
    // important state-changes (reconnect, a compile landing) persist 60s so you can't miss them in a
    //  blink; routine SEND/RECV chatter fades at 5s.  Both depend on the tick (the ring mutates w.c in
    //   place, no C version bump to react off).
    let log = $derived.by(() => {
        return ((wref?.c?.relay_log ?? []) as { line: string, at: number, important?: number }[])
            .filter(e => now - e.at < (e.important ? 60000 : 5000)).slice(-8)
    })

    let link   = $derived(live
        ? { glyph: '🛰', cls: 'up',   text: 'relay up' }
        : { glyph: '⚠', cls: 'down', text: 'relay down' })
</script>

<div class="rl">
    <div class="rl-hd">relay</div>
    <div class="rl-link rl-{link.cls}" title="relay/socket carrier — is the websocket to the relay live (Lies_channel_live)">
        <span class="rl-dot">{link.glyph}</span>
        <span class="rl-txt">{link.text}</span>
    </div>
    {#if log.length}
        <div class="rl-log" title="relay/carrier event stream — Tribunal note() → w.c.relay_log (ping/pong filtered)">
            {#each log as e (e.at + e.line)}
                <div class="rl-log-line" class:important={e.important}>{e.line}</div>
            {/each}
        </div>
    {/if}
</div>

<style>
    .rl {
        display: flex; flex-direction: column; gap: 3px;
        min-width: 11rem; padding: 5px 8px;
        background: rgba(18, 15, 26, 0.96); border: 1px solid #2c3450; border-top-color: #3a4570;
        border-radius: 6px 6px 0 0; font-family: monospace; font-size: 11px; color: #9aa6cc;
        box-shadow: 0 -2px 10px #0006;
    }
    .rl-hd { font-size: 9px; letter-spacing: 0.08em; text-transform: uppercase; color: #5a6488; }
    .rl-link { display: flex; align-items: center; gap: 5px; }
    .rl-dot { font-size: 12px; line-height: 1; }
    .rl-up   .rl-dot { color: #6ad0a0; }
    .rl-down .rl-dot { color: #e06c75; }
    .rl-down .rl-txt { color: #d68a90; }
    .rl-log { margin-top: 4px; border-top: 1px solid #2c3450; padding-top: 3px; max-height: 9rem; overflow-y: auto; display: flex; flex-direction: column; gap: 1px; }
    .rl-log-line { font-size: 9px; line-height: 1.25; color: #7c86ad; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
    .rl-log-line.important { color: #e7c06a; font-weight: bold; }
</style>
