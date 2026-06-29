<script module lang="ts">
    import type { TheC as TheCm } from "$lib/data/Stuff.svelte"
    // runner_run — the Runner Funkcion's pumped watcher (Lies pumps it once a tick, like
    //  storying_run).  Pure C-tree, no H: it reads the peer ping (%channel_peer, stamped by
    //   Lies_pong_recv) off w:Lies and, on a liveness TRANSITION (dialing→silent→live), stamps
    //    funk.c.latest = {state, event, at} + bumps so the hoisted Brink face can caption the
    //     latest thing the endpoint did.  The face still reads the live state itself; this is the
    //      change-log, the first sliver of %Aim's "describe the latest event from it".
    export function runner_run(_host: TheCm, funk: TheCm, ww: TheCm): void {
        const role   = ww.sc.runner ? 'runner' : ww.sc.editor ? 'editor' : ''
        const expect = role === 'editor' ? 'runner' : role === 'runner' ? 'editor' : ''
        if (!expect) return
        const now   = Date.now()
        const face  = ww.o({ channel_peer: expect })[0] as TheCm | undefined
        // liveness is max(last, last_heard) — SAME as the face's reader, else the watcher stamps
        //  'silent' off a stale `last` while the panel reads 'live' off fresh last_heard (a nonsense
        //   "silent 222s ago, yet heard 2s ago").  Inbound frames keep the peer honestly alive.
        const seen  = face ? Math.max(Number(face.sc.last ?? 0), Number(face.sc.last_heard ?? 0)) : 0
        const live  = seen > 0 && now - seen < 7000
        const state = !face ? 'dialing' : live ? 'live' : 'silent'
        if ((funk.c.latest as { state?: string } | undefined)?.state === state) return
        funk.c.latest = { state, event: `${expect} ${state}`, at: now }
        funk.bump_version()
    }
</script>

<script lang="ts">
    // Runner — the endpoint monitor, hoisted as a Lens:Brink (a tenant of the Liesui-pinned dock).
    //  It reads the live channel state on a w:Lies — the peer's
    //   liveness off %channel_peer (role + rtt + last, stamped by Lies_pong_recv on the ping/pong
    //    heartbeat), whether the socket carries at all (Lies_channel_live), and the in-flight
    //     run_phase blip — and shows, at a glance, whether the remote endpoint is up and what its
    //      run is doing.  Suggested by Lies_heartbeat whenever this instance holds an editor|runner
    //       role; the Aim layer will later point one of these at each endpoint it orchestrates.
    import { onDestroy }   from 'svelte'
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, lens, funk }: { H: House, lens?: TheC, funk?: TheC, w?: TheC } = $props()

    // the latest transition the watcher (runner_run) logged — a quiet caption under the link.
    let latest = $derived((funk?.vers && funk.c?.latest) as { state?: string, event?: string, at?: number } | undefined)

    // the w:Lies this panel monitors — stamped on the lens by the suggester (lens.c.w), else
    //  resolved the way Liesui does (the %examining signal's back-ref).
    let peers: TheC[]  = $state([])
    let run_phase: any = $state(undefined)
    let role           = $state('')
    let channel_live   = $state(false)
    let now            = $state(Date.now())

    // editor MULTIPLIED mode: when the suggester stamps lens.c.runner, this face monitors ONE
    //  advertised runner (its %Runner roster entry: pub + friendly + last_heard + ready + book),
    //   not the single-pair %channel_peer.  An editor coordinating a grid mounts one of these per pub.
    let is_roster  = $derived(!!lens?.c?.runner)
    let r_pub      = $state('')
    let r_friendly = $state('')
    let r_heard    = $state(0)
    let r_ready    = $state(false)
    let r_book     = $state('')

    const _tick = setInterval(() => { now = Date.now() }, 1000)
    onDestroy(() => clearInterval(_tick))

    $effect(() => {
        const w = (lens?.c?.w ?? H.ave.ob({ examining: 1 })[0]?.c?.w) as TheC | undefined
        if (!w) return
        w.ob()   // track w:Lies version (bumps on pong roai, advertise stamp + the ambient heartbeat)
        const rn = lens?.c?.runner as TheC | undefined
        H.clear(async () => {
            peers        = w.o({ channel_peer: 1 }) as TheC[]
            run_phase    = w.c?.run_phase
            role         = (H as any).Lies_role?.(w) ?? ''
            channel_live = !!(H as any).Lies_channel_live?.(w)
            now          = Date.now()
            if (rn) {
                r_pub      = (rn.sc.Runner as string) ?? ''
                r_friendly = (rn.sc.friendly as string) ?? ''
                r_heard    = Number(rn.sc.last_heard ?? 0)
                r_ready    = !!rn.sc.ready
                r_book     = (rn.sc.book as string) ?? ''
            }
        })
    })

    // the peer this instance faces (the opposite role) and its proven-liveness — the 7s window
    //  Liesui/Langui use, so a frozen channel reads as growing silence, not a stale "live" lie.
    //   Liveness is max(last, last_heard): `last` is our-ping-come-home (carries rtt), last_heard is
    //    ANY inbound frame from the peer (Lies_pong).  Over a half-open carrier `last` freezes while
    //     last_heard keeps advancing, so the panel reads the truth instead of a false silence.
    const heard = (p: any) => Math.max(Number(p?.sc?.last ?? 0), Number(p?.sc?.last_heard ?? 0))
    let expect_peer = $derived(role === 'editor' ? 'runner' : role === 'runner' ? 'editor' : '')
    let face        = $derived(peers.find(p => p.sc?.channel_peer === expect_peer))
    let live_face   = $derived(peers.filter(p => p.sc?.channel_peer === expect_peer && heard(p) && now - heard(p) < 7000))
    let peer_rtt    = $derived(live_face[0]?.sc?.rtt as number | undefined)
    let peer_age_s  = $derived(heard(face) ? Math.round((now - heard(face)) / 1000) : null)

    // the endpoint clue — the WATCHED peer is the subject (→RUNNER), the carrier state rides as a
    //  parenthetical, so a glance reads "who, and how is it".  Four honest states, not a binary
    //   up/down: no socket → dialing → silent (was proven, gone quiet) → live.  A clash (>1 facing
    //    peer) is the "freak out" Langui flags.
    let PEER = $derived((expect_peer || '').toUpperCase())
    // rtt rides `last` (our-ping-come-home); when we're live only via last_heard (inbound frames,
    //  half-open send leg), `last` is stale and so is its rtt — show "heard Ns" instead of a frozen,
    //   misleading round-trip number.
    let rtt_fresh = $derived(face?.sc?.last != null && now - Number(face.sc.last) < 7000)
    let link = $derived(
        !channel_live        ? { glyph: '✕', cls: 'down',   text: `→${PEER || '?'} (no channel)` }
      : live_face.length > 1 ? { glyph: '⚠', cls: 'clash',  text: `→${PEER} (clash ×${live_face.length})` }
      : live_face.length     ? { glyph: '●', cls: 'live',   text: rtt_fresh ? `→${PEER} (${peer_rtt ?? '?'}ms)` : `→${PEER} (heard ${peer_age_s ?? 0}s)` }
      : face                 ? { glyph: '◍', cls: 'silent', text: `→${PEER} (silent${peer_age_s != null ? ` ${peer_age_s}s` : ''})` }
      :                        { glyph: '◌', cls: 'dial',   text: `→${PEER || '…'} (dialing)` }
    )

    // the in-flight run blip (mirrors Liesui's PHASE_VIEW), shown while a run is bouncing and gone
    //  once it ages past 30s of silence.
    const base = (p: any) => String(p ?? '').split('/').pop()
    const bk   = (p: any) => p?.book ? `${base(p.book)} ` : ''
    const stall_band = (s: number) => { for (const t of [60, 30, 10, 5, 2]) if (s >= t) return `>${t}s`; return '' }
    const PHASE_VIEW: Record<string, { glyph: string, label: (p: any) => string }> = {
        rungo_ack:   { glyph: '📥', label: () => 'acked' },
        story_begun: { glyph: '▶',  label: (p) => `running ${p.book ? base(p.book) : p.path ? base(p.path) : ''}`.trimEnd() },
        step_done:   { glyph: '●',  label: (p) => `${bk(p)}step ${p.n}${p.total ? `/${p.total}` : ''}` },
        step_stall:  { glyph: '⏳', label: (p) => { const b = stall_band(Number(p.secs)); return `${bk(p)}step ${p.n}${p.total ? `/${p.total}` : ''}${b ? ` — ${b}…` : ''}` } },
        all_done:    { glyph: '🏁', label: (p) => `${bk(p)}done ${p.n ?? ''}${p.total ? `/${p.total}` : ''}` },
    }
    let phase_live = $derived(!!run_phase && now - (run_phase.at as number) < 30000)
    let phase_view = $derived(run_phase ? PHASE_VIEW[run_phase.phase as string] : undefined)
    let phase_pct  = $derived(run_phase?.total ? Math.min(100, Math.round((Number(run_phase.n ?? 0) / Number(run_phase.total)) * 100)) : null)

    // roster-mode link — liveness off the advertise beacon (cadence ~15s; allow ~2 missed before
    //  "silent", never heard ⇒ "dialing").  free = on the grid, no book; else running its book.
    let r_age_s = $derived(r_heard ? Math.round((now - r_heard) / 1000) : null)
    let r_live  = $derived(r_heard > 0 && now - r_heard < 45000)
    let r_title = $derived(r_friendly || (r_pub ? r_pub.slice(0, 8) : '?'))
    let r_link  = $derived(
        !r_heard ? { glyph: '◌', cls: 'dial',   text: 'dialing' }
      : r_live   ? { glyph: '●', cls: 'live',   text: r_book ? `running ${base(r_book)}` : 'free' }
      :            { glyph: '◍', cls: 'silent', text: `silent ${r_age_s ?? 0}s` }
    )
</script>

{#if is_roster}
    <!-- one advertised runner on the grid (editor multiplied view) — its own identity, its own liveness -->
    <div class="rp">
        <div class="rp-hd">runner · {r_pub ? r_pub.slice(0, 8) : '?'}</div>
        <div class="rp-link rp-{r_link.cls}" title={`advertised runner ${r_pub}${r_ready ? ' — ready' : ''}`}>
            <span class="rp-dot">{r_link.glyph}</span>
            <span class="rp-role">{r_title}</span>
            <span class="rp-txt">{r_link.text}</span>
        </div>
    </div>
{:else}
<div class="rp">
    <div class="rp-hd">runner</div>
    <div class="rp-link rp-{link.cls}" title="endpoint liveness — the ping/pong heartbeat (Lies_heartbeat)">
        <span class="rp-dot">{link.glyph}</span>
        <span class="rp-role">{role || 'lies'}</span>
        <span class="rp-txt">{link.text}</span>
    </div>
    {#if latest?.state && latest.at && now - latest.at < 5000}
        <!-- a transition TOAST: the last state-change, fading out after 5s (not a persistent
             growing-age line — that read as a broken gauge). -->
        <div class="rp-latest">↪ {latest.state} {Math.round((now - latest.at) / 1000)}s ago</div>
    {/if}
    {#if phase_live && phase_view}
        <div class="rp-phase" class:stall={run_phase.phase === 'step_stall'} class:done={run_phase.phase === 'all_done'}>
            <span class="rp-ph-g">{phase_view.glyph}</span>
            <span class="rp-ph-l">{phase_view.label(run_phase)}</span>
            {#if phase_pct != null}<span class="rp-bar"><span class="rp-bar-fill" style={`width:${phase_pct}%`}></span></span>{/if}
        </div>
    {/if}
</div>
{/if}

<style>
    .rp {
        display: flex; flex-direction: column; gap: 3px;
        min-width: 14rem; padding: 5px 8px;
        background: rgba(18, 15, 26, 0.96); border: 1px solid #2c3450; border-top-color: #3a4570;
        border-radius: 6px 6px 0 0; font-family: monospace; font-size: 11px; color: #9aa6cc;
        box-shadow: 0 -2px 10px #0006;
    }
    .rp-hd { font-size: 9px; letter-spacing: 0.08em; text-transform: uppercase; color: #5a6488; }
    .rp-link { display: flex; align-items: center; gap: 5px; }
    .rp-dot { font-size: 12px; line-height: 1; }
    .rp-role { color: #c4ccea; }
    .rp-txt { font-variant-numeric: tabular-nums; }
    .rp-live   .rp-dot { color: #6ad0a0; }
    .rp-silent .rp-dot { color: #d8b86a; }
    .rp-dial   .rp-dot { color: #889; }
    .rp-down   .rp-dot { color: #e06c75; }
    .rp-clash  .rp-dot { color: #e06c75; }
    .rp-down  .rp-txt, .rp-clash .rp-txt { color: #d68a90; }
    .rp-latest { font-size: 9.5px; color: #6a7398; }
    .rp-ago { color: #4e5676; }
    .rp-phase { display: flex; align-items: center; gap: 5px; color: #b6a8cc; }
    .rp-phase.stall { color: #d8b86a; }
    .rp-phase.done  { color: #8fe4c0; }
    .rp-ph-g { font-size: 12px; }
    .rp-bar { flex: 1; height: 3px; background: #2a2a3a; border-radius: 2px; overflow: hidden; }
    .rp-bar-fill { display: block; height: 100%; background: #6a86c0; transition: width 0.3s; }
</style>
