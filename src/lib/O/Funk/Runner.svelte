<script lang="ts">
    // Runner — the endpoint monitor, hoisted as a Lens:Panel (the first docked tenant of the
    //  bottom-accreting Lens stack).  It reads the live channel state on a w:Lies — the peer's
    //   liveness off %channel_peer (role + rtt + last, stamped by Lies_pong_recv on the ping/pong
    //    heartbeat), whether the socket carries at all (Lies_channel_live), and the in-flight
    //     run_phase blip — and shows, at a glance, whether the remote endpoint is up and what its
    //      run is doing.  Suggested by Lies_heartbeat whenever this instance holds an editor|runner
    //       role; the Aim layer will later point one of these at each endpoint it orchestrates.
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, lens }: { H: House, lens?: TheC, funk?: TheC, w?: TheC } = $props()

    // the w:Lies this panel monitors — stamped on the lens by the suggester (lens.c.w), else
    //  resolved the way Liesui does (the %examining signal's back-ref).
    let peers: TheC[]  = $state([])
    let run_phase: any = $state(undefined)
    let role           = $state('')
    let channel_live   = $state(false)
    let now            = $state(0)

    $effect(() => {
        const w = (lens?.c?.w ?? H.ave.ob({ examining: 1 })[0]?.c?.w) as TheC | undefined
        if (!w) return
        w.ob()   // track w:Lies version (bumps on pong roai + the ambient heartbeat)
        H.clear(async () => {
            peers        = w.o({ channel_peer: 1 }) as TheC[]
            run_phase    = w.c?.run_phase
            role         = (H as any).Lies_role?.(w) ?? ''
            channel_live = !!(H as any).Lies_channel_live?.(w)
            now          = Date.now()
        })
    })

    // the peer this instance faces (the opposite role) and its proven-liveness — the 7s window
    //  Liesui/Langui use, so a frozen channel reads as growing silence, not a stale "live" lie.
    let expect_peer = $derived(role === 'editor' ? 'runner' : role === 'runner' ? 'editor' : '')
    let face        = $derived(peers.find(p => p.sc?.channel_peer === expect_peer))
    let live_face   = $derived(peers.filter(p => p.sc?.channel_peer === expect_peer && p.sc?.last && now - (p.sc.last as number) < 7000))
    let peer_rtt    = $derived(live_face[0]?.sc?.rtt as number | undefined)
    let peer_age_s  = $derived(face?.sc?.last ? Math.round((now - (face.sc.last as number)) / 1000) : null)

    // the endpoint clue — four honest states, not a binary up/down: no socket → dialing → silent
    //  (was proven, gone quiet) → live.  A clash (>1 facing peer) is the "freak out" Langui flags.
    let link = $derived(
        !channel_live        ? { glyph: '✕', cls: 'down',   text: `no channel${expect_peer ? ` to ${expect_peer}` : ''}` }
      : live_face.length > 1 ? { glyph: '⚠', cls: 'clash',  text: `${live_face.length} ${expect_peer}s — clash` }
      : live_face.length     ? { glyph: '●', cls: 'live',   text: `${expect_peer} ${peer_rtt ?? '?'}ms` }
      : face                 ? { glyph: '◍', cls: 'silent', text: `${expect_peer} silent${peer_age_s != null ? ` ${peer_age_s}s` : ''}` }
      :                        { glyph: '◌', cls: 'dial',   text: `dialing ${expect_peer || '…'}` }
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
</script>

<div class="rp">
    <div class="rp-hd">runner</div>
    <div class="rp-link rp-{link.cls}" title="endpoint liveness — the ping/pong heartbeat (Lies_heartbeat)">
        <span class="rp-dot">{link.glyph}</span>
        <span class="rp-role">{role || 'lies'}</span>
        <span class="rp-txt">{link.text}</span>
    </div>
    {#if phase_live && phase_view}
        <div class="rp-phase" class:stall={run_phase.phase === 'step_stall'} class:done={run_phase.phase === 'all_done'}>
            <span class="rp-ph-g">{phase_view.glyph}</span>
            <span class="rp-ph-l">{phase_view.label(run_phase)}</span>
            {#if phase_pct != null}<span class="rp-bar"><span class="rp-bar-fill" style={`width:${phase_pct}%`}></span></span>{/if}
        </div>
    {/if}
</div>

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
    .rp-phase { display: flex; align-items: center; gap: 5px; color: #b6a8cc; }
    .rp-phase.stall { color: #d8b86a; }
    .rp-phase.done  { color: #8fe4c0; }
    .rp-ph-g { font-size: 12px; }
    .rp-bar { flex: 1; height: 3px; background: #2a2a3a; border-radius: 2px; overflow: hidden; }
    .rp-bar-fill { display: block; height: 100%; background: #6a86c0; transition: width 0.3s; }
</style>
