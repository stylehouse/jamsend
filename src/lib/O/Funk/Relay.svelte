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
    $effect(() => {
        const w = (lens?.c?.w ?? H.ave.ob({ examining: 1 })[0]?.c?.w) as TheC | undefined
        if (!w) return
        w.ob()
        H.clear(async () => {
            const at = w.o({ active_transport: 1 })[0] as TheC | undefined
            live = !!(w.c?.channel_up && at?.c?.connection)
        })
    })

    let latest = $derived((funk?.vers && funk.c?.latest) as { event?: string, at?: number } | undefined)
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
    {#if latest?.event}
        <div class="rl-latest">{latest.event}{#if latest.at}<span class="rl-ago"> · {Math.round((now - latest.at) / 1000)}s</span>{/if}</div>
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
    .rl-latest { font-size: 9.5px; color: #6a7398; }
    .rl-ago { color: #4e5676; }
</style>
