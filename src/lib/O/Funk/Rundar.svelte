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
    // Rundar — the runner RADAR (was Runner; renamed for the fleet multiplicity).  Hoisted as a Lens:Brink
    //  (a tenant of the Liesui-pinned dock), it has TWO modes off one kind:
    //   • editor RACK (lens.sc.rack): the snapped w:Lies/%Runner roster — ONE row per known runner (1:1
    //      with the %HostedIdentity registry) plus the anonymous single-pair peer — the grid the editor
    //       dispatches to, each runner with its own liveness|book|engaged.
    //   • runner single-pair (no rack): a runner's view of its ONE editor — the %channel_peer liveness
    //      (role + rtt + last, stamped by Lies_pong_recv on the ping/pong heartbeat), whether the socket
    //       carries (Lies_channel_live), and the in-flight run_phase blip.
    //  Suggested by Lies_aim whenever this instance holds an editor|runner role.
    import { onDestroy }   from 'svelte'
    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H, lens, funk, mini = false }: { H: House, lens?: TheC, funk?: TheC, w?: TheC, mini?: boolean } = $props()

    // the latest transition the watcher (runner_run) logged — a quiet caption under the link.
    let latest = $derived((funk?.vers && funk.c?.latest) as { state?: string, event?: string, at?: number } | undefined)

    // the w:Lies this panel monitors — stamped on the lens by the suggester (lens.c.w), else
    //  resolved the way Liesui does (the %examining signal's back-ref).
    let peers: TheC[]  = $state([])
    let run_phase: any = $state(undefined)
    let role           = $state('')
    let channel_live   = $state(false)
    let now            = $state(Date.now())

    // editor RACK mode: when the suggester stamps lens.sc.rack, this ONE face reads the whole snapped
    //  %Runner roster off w:Lies (1:1 with the %HostedIdentity registry, projected by Lies_runner_roster)
    //   and renders a single titled box — a row per known runner + the anon single-pair peer.  The
    //    single-pair {:else} mode below serves a runner's view of its editor (→EDITOR).
    let is_rack = $derived(!!lens?.sc?.rack)
    let rack = $state<{ pub: string, heard: number, ready: boolean, book: string, engaged: string, sent: string, sent_at: number, begs: boolean, granted: boolean, ac: boolean }[]>([])
    // the live w:Lies (for the rack's grant control) + this runner's remote-Wormhole acquire state.
    let w_lies = $state<TheC | undefined>(undefined)
    let wormhole_state = $state('')
    // the CRYPTO axis of the remote-Wormhole grant (absent|invalid|valid) + its reason — kept SEPARATE
    //  from liveness (channel_live) so the badge never says "granted" over a dead grant.
    let grant_status = $state('')
    let grant_reason = $state('')

    const _tick = setInterval(() => { now = Date.now() }, 1000)
    onDestroy(() => clearInterval(_tick))

    $effect(() => {
        const w = (lens?.c?.w ?? H.ave.ob({ examining: 1 })[0]?.c?.w) as TheC | undefined
        if (!w) return
        w_lies = w
        w.ob()   // track w:Lies version (bumps on pong roai, advertise stamp + the ambient heartbeat)
        const rack_mode = !!lens?.sc?.rack
        H.clear(async () => {
            peers        = w.o({ channel_peer: 1 }) as TheC[]
            run_phase    = w.c?.run_phase
            role         = (H as any).Lies_role?.(w) ?? ''
            channel_live = !!(H as any).Lies_channel_live?.(w)
            wormhole_state = (w.c?.wormhole_state as string) ?? ''   // remote-Wormhole acquire (runner)
            grant_status   = (w.c?.wormhole_grant_status as string) ?? ''
            grant_reason   = (w.c?.wormhole_grant_reason as string) ?? ''
            now          = Date.now()
            // the snapped %Runner carries the STABLE facts in .sc (friendly|ready|book|engaged, 1:1 with the
            //  registry); the VOLATILE timing (last_heard, the ☎ sent/sent_at) rides .c off-snap, so the snap
            //   doesn't churn on the ~15s beacon.  Read both halves here.
            if (rack_mode) rack = (w.o({ Runner: 1 }) as TheC[]).map(rn => ({
                pub:      (rn.sc.Runner as string) ?? '',
                heard:    Number(rn.c?.last_heard ?? 0),
                ready:    !!rn.sc.ready,
                book:     (rn.sc.book as string) ?? '',
                engaged:  (rn.sc.engaged as string) ?? '',
                sent:     (rn.c?.sent as string) ?? '',
                sent_at:  Number(rn.c?.sent_at ?? 0),
                begs:     !!rn.sc.begs_wormhole,      // begging for remote Wormhole (disk proxy)
                granted:  !!rn.sc.granted_wormhole,   // we granted it
                ac:       !!rn.sc.ac,                 // its AudioContext is gesture-unlocked (needAC dispatch prefers it)
            }))
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

    // the single-pair channel peer as an ANONYMOUS runner row — ONLY when the roster is genuinely EMPTY
    //  (we know of NO identified runner): a pure ?B= runner connected with no ?I, no pub to claim.  We do
    //   NOT borrow the global run_phase to caption it: run_phase is the editor's ONE collapsed "latest
    //    blip" (often a local Doc/compile path like Radiola.g — a ghost source — NOT this peer's Story
    //     %w), so attributing it to the anon peer was a lie.  When identified runners EXIST but none reads
    //      fresh, show NO anon — the live channel is one of THEM with a stale beacon (see stale_hint), not
    //       a different anonymous runner.
    let any_live_runner = $derived(rack.some(v => v.heard && now - v.heard < 45000))

    // cull the stale-live from the DISPLAY: a runner we HEARD this session but that has gone silent
    //  past OFFLINE_CULL_MS drops out of the rack, so dead icons don't accumulate.  Only the heard
    //   ones cull on age — a never-heard-this-session identity (heard:0, e.g. a fresh editor reload
    //    where last_heard rides .c off-snap and resets) stays as the durable roster ('offline'), else
    //     every reload would blank the rack until the ~15s beacons re-land.  Display-only — the snapped
    //      %Runner roster (owner-recorded, 1:1 with %HostedIdentity) is untouched.
    const OFFLINE_CULL_MS = 5 * 60 * 1000
    let rack_shown = $derived(rack.filter(v => !(v.heard && now - v.heard > OFFLINE_CULL_MS)))

    let anon = $derived.by(() => {
        if (!is_rack || rack_shown.length || !live_face.length) return null
        return { glyph: '●', cls: 'live', text: 'connected — no identity' }
    })
    // the channel CARRIES but no known runner's beacon is fresh: they're connected (ping/pong, ~1s) yet
    //  their advertise (~15s) isn't landing — the signature of a flapping editor socket dropping the
    //   sparse beacon while the frequent ping slips through.  Surface it instead of faking liveness.
    let stale_hint = $derived(is_rack && rack.length > 0 && !any_live_runner && live_face.length > 0)

    // a runner's at-a-glance link — the activation LADDER: liveness rides the runner's OWN ~5s ping
    //  (ping-borne last_heard, not the sparse ~15s advertise), so it grades into rungs instead of one
    //   flat cutoff:
    //     talking (<15s ≈ 2 missed pings) ▸ lagging (<45s — heard lately but pings stopped landing;
    //      the keepalive timer survives a think-quiesce, so this is real wobble, not idleness) ▸
    //       silent (the roster lapses book|engaged claims at this same window) ▸ offline (never heard
    //        this session — known in the registry only).  Job state outranks the rung while it can
    //         honestly claim: ▶ playing its book ▸ ☎ a job WE rang, unacked (30s).
    const runner_link = (v: { heard: number, book: string, engaged: string, sent: string, sent_at: number }) => {
        const sent_live = !!v.sent && (!v.sent_at || now - v.sent_at < 30000)
        const age  = v.heard ? Math.round((now - v.heard) / 1000) : 0
        const rung = !v.heard ? 'offline' : now - v.heard < 15000 ? 'talking' : now - v.heard < 45000 ? 'lagging' : 'silent'
        return rung === 'offline' ? { glyph: '○', cls: 'dial',    text: 'offline' }
             : rung === 'silent'  ? { glyph: '◍', cls: 'silent',  text: `silent ${age}s` }
             : v.book             ? { glyph: '▶', cls: 'live',    text: `playing ${base(v.book)}` }
             : sent_live          ? { glyph: '☎', cls: 'sent',    text: `calling ${base(v.sent)}` }
             : rung === 'lagging' ? { glyph: '◔', cls: 'lagging', text: `lagging ${age}s` }
             : v.engaged          ? { glyph: '◑', cls: 'engaged', text: 'engaged' }
             :                      { glyph: '●', cls: 'live',    text: 'free' }
    }
</script>

{#if mini}
    <!-- collapsed MiniBrink: the whole rack (or the single-pair peer) as a one-row string of liveness
         dots — connectivity at a glance, the Brink HUD's resting state. -->
    {#if is_rack}
        <div class="rp-mini" title="runners · {rack_shown.length} known{anon ? ' + anon' : ''}">
            {#each rack_shown as v (v.pub)}
                {@const lk = runner_link(v)}
                <span class="rp-dot rp-{lk.cls}" title={`${v.pub || '?'} — ${lk.text}${v.ac ? ' · AC live' : ''}`}>{lk.glyph}</span>
                {#if v.begs && !v.granted}
                    <!-- an ACTIONABLE beg must survive the collapse: grant remote-Wormhole right off the mini row -->
                    <button class="rp-grant rp-grant-mini" title={`${v.pub} begs remote-Wormhole disk access — click to grant`}
                            onclick={() => w_lies && (H as any).Lies_grant_wormhole(w_lies, v.pub)}>🛰</button>
                {/if}
            {/each}
            {#if anon}<span class="rp-dot rp-{anon.cls}" title={anon.text}>{anon.glyph}</span>{/if}
            {#if !rack_shown.length && !anon}<span class="rp-mini-empty" title="no runners">○</span>{/if}
        </div>
    {:else}
        <div class="rp-mini" title={link.text}>
            <span class="rp-dot rp-{link.cls}">{link.glyph}</span>
            {#if grant_status || wormhole_state}
                <!-- the runner's remote-Wormhole crypto verdict survives the collapse too: valid+live=green,
                     valid+silent=amber (grant good, editor mute), invalid=red (refused), absent=amber (begging). -->
                <span class="rp-dot rp-{grant_status === 'invalid' ? 'bad' : (grant_status === 'valid' && channel_live) || grant_status === 'local' ? 'live' : 'silent'}"
                      title={grant_status === 'invalid' ? `INVALID grant — ${grant_reason}; re-begging`
                           : grant_status === 'local' ? 'local share open — remote proxy stood down'
                           : grant_status === 'valid' ? (channel_live ? 'remote Wormhole granted · crypto valid' : 'grant valid · editor not answering')
                           : 'begging the editor for remote-Wormhole disk access'}>🛰</span>
            {/if}
        </div>
    {/if}
{:else if is_rack}
    <!-- the RUNNER rack (Rundar): the editor's snapped roster, ONE row per %HostedIdentity(role:runner) —
         friendly|pub · liveness — plus the anonymous single-pair peer (a ?B= runner with no identity) if it
         isn't already one of the identified rows.  No →EDITOR carrier line here — that's the Relay's job. -->
    <div class="rp">
        <div class="rp-hd">runner{(rack_shown.length + (anon ? 1 : 0)) ? ` · ${rack_shown.length + (anon ? 1 : 0)}` : ''}</div>
        {#each rack_shown as v (v.pub)}
            {@const lk = runner_link(v)}
            <div class="rp-link rp-{lk.cls}" title={`runner ${v.pub}${v.ready ? ' — ready' : ''}${v.engaged ? ` — engaged by ${v.engaged.slice(0, 8)}` : ''}${v.ac ? ' — AC live (a needAC Book lands here first)' : ''}`}>
                <span class="rp-dot">{lk.glyph}</span>
                <span class="rp-role rp-pub" title={v.pub}>{v.pub || '?'}</span>
                <span class="rp-txt">{lk.text}</span>
                <!-- remote-Wormhole grant control: a begging runner gets a grant button; a granted one a tick.
                     mint+sign a %Grant (Lies_grant_wormhole) keyed by this runner's prepub (v.pub). -->
                {#if v.granted}
                    <span class="rp-grant on" title="remote Wormhole granted (method:remoteWormhole)">🛰️</span>
                {:else if v.begs}
                    <button class="rp-grant" title="grant this runner remote-Wormhole disk-proxy access"
                            onclick={() => w_lies && (H as any).Lies_grant_wormhole(w_lies, v.pub)}>grant 🛰️</button>
                {/if}
            </div>
        {/each}
        {#if anon}
            <!-- a runner connected on the single-pair channel but advertising no identity (a ?B= runner,
                 no ?I) — no roster row (no pub to key on), and shown ONLY when no identified runner is known. -->
            <div class="rp-link rp-{anon.cls}" title="a connected runner with no cluster identity (?B=, can't advertise a pub — boot it ?I= to roster it)">
                <span class="rp-dot">{anon.glyph}</span>
                <span class="rp-role">anon</span>
                <span class="rp-txt">{anon.text}</span>
            </div>
        {/if}
        {#if stale_hint}
            <!-- the runners are connected but their identity beacons aren't landing (flapping socket) -->
            <div class="rp-stale" title="the channel carries (ping/pong) but the ~15s advertise beacons aren't landing — usually a flapping socket. The runners above are connected; their identity just isn't refreshing.">◍ channel live · beacons stale</div>
        {/if}
        {#if !rack_shown.length && !anon}
            <div class="rp-empty">no runners</div>
        {/if}
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
    {#if grant_status || wormhole_state}
        <!-- &remoteWormhole=1 grant status — TWO AXES, never merged:
             • crypto (grant_status): absent → begging · invalid → a forged/stale/foreign atom, refused ·
               valid → we hold a cryptographically real grant.  This is the "does the crypto work" signal.
             • liveness (channel_live): even a VALID grant can't serve if the relay/editor is silent.
             A valid grant + dead channel says exactly that, not a bare "granted" that lies as "working". -->
        {#if grant_status === 'invalid'}
            <div class="rp-grant-status rp-bad" role="alert"
                 title={`the held remote-Wormhole grant failed crypto verification — ${grant_reason}. It is refused and NOT used; the runner is re-begging for a fresh one.`}>
                ⚠ INVALID Wormhole grant{grant_reason ? ` — ${grant_reason}` : ''} · re-begging
            </div>
        {:else if grant_status === 'valid'}
            <div class="rp-grant-status rp-{channel_live ? 'live' : 'silent'}"
                 title="remote Wormhole (method:remoteWormhole) — a cryptographically valid signed grant, presented per-op over the relay channel">
                {channel_live ? '🛰️ Wormhole granted · crypto valid' : '🛰️ grant valid · editor not answering — ops stall'}
            </div>
        {:else if grant_status === 'local'}
            <div class="rp-grant-status rp-live"
                 title="a local directory share is open on this remoteWormhole tab — it is strictly more capable (direct disk, bin_write) so the editor proxy stood down; disk reads/writes go through the local handle, no grant needed">
                📁 local share · remote proxy stood down
            </div>
        {:else}
            <div class="rp-grant-status rp-silent"
                 title="no valid remote-Wormhole grant held — begging the editor for disk access (grant it from the editor's runner rack)">
                🛰️ begging for Wormhole…
            </div>
        {/if}
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
    /* a runner's prepub, truncated by CSS to ~6 chars (no friendly label — the pub IS the name); full pub on hover */
    .rp-pub { display: inline-block; max-width: 7ch; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; vertical-align: bottom; font-family: monospace; }
    .rp-txt { font-variant-numeric: tabular-nums; }
    .rp-live    .rp-dot { color: #6ad0a0; }
    .rp-sent    .rp-dot { color: #79b0d0; }   /* ☎ a dispatched job ringing — not yet acked */
    .rp-engaged .rp-dot { color: #7aa0d8; }   /* reserved (lease held), idle between runs */
    .rp-lagging .rp-dot { color: #c2c47c; }   /* heard lately, pings not landing — between live and silent */
    .rp-silent .rp-dot { color: #d8b86a; }
    .rp-dial   .rp-dot { color: #889; }
    .rp-down   .rp-dot { color: #e06c75; }
    .rp-clash  .rp-dot { color: #e06c75; }
    .rp-bad    .rp-dot { color: #e06c75; }   /* an INVALID (forged/stale/foreign) grant — refused */
    .rp-down  .rp-txt, .rp-clash .rp-txt { color: #d68a90; }
    .rp-latest { font-size: 9.5px; color: #6a7398; }
    .rp-empty { font-size: 10px; color: #5a6488; font-style: italic; }
    .rp-stale { font-size: 9.5px; color: #d8b86a; }   /* connected but advertise beacons not landing */
    .rp-grant { margin-left: auto; font-size: 9.5px; cursor: pointer; background: #2c3358;
        color: #b8c2ee; border: 1px solid #3d4680; border-radius: 4px; padding: 0 5px; line-height: 15px; }
    .rp-grant:hover { background: #3a437a; }
    .rp-grant.on { background: none; border: none; cursor: default; padding: 0; }
    .rp-grant-status { font-size: 9.5px; color: #6a7398; }
    .rp-grant-status.rp-live   { color: #6ad0a0; }                    /* valid + channel live — actually working */
    .rp-grant-status.rp-silent { color: #d8b86a; }                    /* valid but editor mute, or begging */
    .rp-grant-status.rp-bad    { color: #e06c75; font-weight: bold; } /* crypto INVALID — loud, refused */
    .rp-ago { color: #4e5676; }
    .rp-phase { display: flex; align-items: center; gap: 5px; color: #b6a8cc; }
    .rp-phase.stall { color: #d8b86a; }
    .rp-phase.done  { color: #8fe4c0; }
    .rp-ph-g { font-size: 12px; }
    .rp-bar { flex: 1; height: 3px; background: #2a2a3a; border-radius: 2px; overflow: hidden; }
    .rp-bar-fill { display: block; height: 100%; background: #6a86c0; transition: width 0.3s; }
    /* collapsed MiniBrink: a one-row string of dots.  The cls rides the dot span itself (the .rp-mini
       ancestor carries none), so colour it directly rather than via the .rp-live .rp-dot descendant rule. */
    .rp-mini { display: flex; align-items: center; gap: 3px; }
    .rp-mini .rp-dot { font-size: 12px; line-height: 1; cursor: default; }
    .rp-mini .rp-live    { color: #6ad0a0; }
    .rp-mini .rp-sent    { color: #79b0d0; }
    .rp-mini .rp-engaged { color: #7aa0d8; }
    .rp-mini .rp-lagging { color: #c2c47c; }
    .rp-mini .rp-silent  { color: #d8b86a; }
    .rp-mini .rp-dial    { color: #889; }
    .rp-mini .rp-down, .rp-mini .rp-clash { color: #e06c75; }
    .rp-mini-empty { color: #5a6488; font-size: 11px; }
    /* the mini grant beg: same chip as .rp-grant, shrunk to ride the dot row (no margin-left:auto —
       it sits beside its runner's dot, not at the row's far edge) */
    .rp-grant-mini { margin-left: 0; font-size: 10px; line-height: 13px; padding: 0 3px; }
</style>
