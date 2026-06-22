<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Reactivity strategy
    // ───────────────────
    //   H.ave fires every think() tick (Housing reassigns the array whenever any
    //   enrolled particle bumps its version, which Lies does on every tick).
    //   The $effect runs on every such reassignment, but H.clear throttles the
    //   actual $state writes (and thus DOM updates) — keeping focused inputs
    //   stable between ticks.
    //
    //   The Waft tree renders <WaftComp> components.  Components survive parent
    //   re-renders as long as their key (waft.sc.Waft) is stable.  All form state
    //   lives inside WaftComp.
    //
    //   Doc header rows use DocRow.svelte, which reads doc.version and w.version
    //   directly — so loaded/pending state stays live without Liesui re-rendering.

    import type { House }   from "$lib/O/Housing.svelte"
    import type { TheC }    from "$lib/data/Stuff.svelte"
    import WaftComp         from "$lib/O/ui/Waft.svelte"
    import DocRow           from "$lib/O/ui/DocRow.svelte"
    import PeelInput        from "$lib/O/ui/PeelInput.svelte"
    import Vexpandy         from "$lib/O/ui/Vexpandy.svelte"
    import Actions         from "$lib/O/ui/Actions.svelte"
    import { browserTrustedPubs } from "$lib/p2p/cluster_trust"

    let { H }: { H: House } = $props()

    // Warn when this editor tab can't sign: the cluster is enforced (trusted pubs baked in) but no
    //  cluster signing key is on the top House's .stashed, so every gen_write is rejected. Reactive to
    //   .stashed, so the warning clears the moment a key is set.
    const no_cluster_key = $derived.by(() => {
        if (role !== 'editor' || !browserTrustedPubs().length) return false
        return !((H.top_House?.() as any)?.stashed?.cluster_idento)   // top House's stashed (the 🪪 Id hatch sets it)
    })
    // The 🪪 Id action — the SAME off-snap recipe Auto registered on the top House (its fn opens the
    //  IdHatch). Fed to <Actions> so the popup carries the button itself, not just a "click Id" hint.
    const id_action = $derived(
        ((H.top_House?.() as any)?.o?.({ watched: 'actions' })[0]?.o({ action: 1, role: 'identity' }) ?? []) as TheC[]
    )

    // ── state ─────────────────────────────────────────────────────────
    let Lies:        TheC | undefined = $state()
    let loaded_docs: TheC[]           = $state([])
    let errors:      TheC[]           = $state([])
    let all_wafts:   TheC[]           = $state([])

    // channel peers — %channel_peer stamped by Lies_pong_recv: the peer role is the VALUE
    //  ({channel_peer:'runner'|'editor'}), NOT a separate `role` key; rtt + last-pong ms ride as sc.
    //  We keep the whole set (not just [0]) so the health card can age each out, show rtt, and
    //   flag a clash when more than one peer of the faced role is live.  `now` is re-read each
    //    tick so liveness ages out a peer that stopped ponging.
    let peers: TheC[] = $state([])
    let now = $state(0)

    // Cred — the runner's verdict per dock (%run_result, stamped by Lies_run_result_recv on the
    //  editor's w:Lies): ok/errors/dige.  The header's credibility readout reads these.
    let run_results: TheC[] = $state([])

    // run_phase — the runner's latest in-flight progress blip (off-snap on the editor's w:Lies,
    //  stamped by Lies_run_phase_recv): {phase, n, total, secs, book, path, at}.  Transient — it
    //   describes a run bouncing, not its verdict; the panel below blips off it and goes quiet
    //    once it ages out.
    let run_phase: any = $state(undefined)

    // examining — the %examining particle from Lies's w, placed in watched:ave.
    // Passed down to Waft and DocRow; DocRow derives is_examining from it.
    // examining.sc.active_path mirrors Lang's active_doc so DocRow glows without
    // needing a Liesui re-render — DocRow's $derived tracks examining.version directly.
    let examining: TheC | undefined = $state()

    $effect(() => {
        const ex = H.ave.ob({ examining: 1 })[0] as TheC | undefined
        if (!ex) return
        ex.ob()   // track examining.version; re-runs when w:Lies bumps via watch_c
        const lies_w = ex.c?.w as TheC | undefined
        if (!lies_w) return
        if (lies_w !== Lies) Lies = lies_w
        H.clear(async () => {
            loaded_docs = lies_w.o({ loaded_doc: 1 })   as TheC[]
            errors      = lies_w.o({ compile_error: 1 }) as TheC[]
            all_wafts   = lies_w.o({ Waft: 1 })          as TheC[]
            examining   = ex
            peers       = lies_w.o({ channel_peer: 1 }) as TheC[]
            run_results = lies_w.o({ run_result: 1 })  as TheC[]
            run_phase   = lies_w.c?.run_phase
            now         = Date.now()
        })
    })

    // ── role badge ────────────────────────────────────────────────────
    // The instance's Lies flavour, surfaced ALWAYS-ON (not just as empty-state filler) so a
    //  runner tab is never mistaken for an editor and vice-versa.  w%runner / w%editor are
    //   stamped at stand-up (Editron lays Lies%editor; the Story loader lays Lies%runner).
    //    Relay-connected / peer-ready will join this badge once the websocket client wiring lands.
    let role = $derived(
        Lies?.sc?.runner ? 'runner' : Lies?.sc?.editor ? 'editor' : Lies ? 'lies' : ''
    )
    const ROLE_TITLE: Record<string, string> = {
        runner: 'runner — read · compile · include; runs the docks the editor compiles',
        editor: 'editor — edits & compiles docks; hosts the relay that runners dial in to',
        lies:   'lies — editor/runner role not yet stamped on this w',
    }
    // the peer this instance faces (the opposite role), and the channel-health it reports.
    //  `face` is the last peer of that role we heard from (may be stale); `live_face` are the
    //   ones proven live by a recent pong (7s window, same as Lang's editor side).  peer_age_s
    //    grows while silent, so a frozen channel reads as growing silence, not a stale "live" lie.
    let expect_peer = $derived(role === 'editor' ? 'runner' : role === 'runner' ? 'editor' : '')
    let face        = $derived(peers.find(p => p.sc?.channel_peer === expect_peer))
    let live_face   = $derived(peers.filter(p =>
        p.sc?.channel_peer === expect_peer && p.sc?.last && now - (p.sc.last as number) < 7000))
    let peer_live   = $derived(live_face.length > 0)
    let peer_rtt    = $derived(live_face[0]?.sc?.rtt as number | undefined)
    let peer_clash  = $derived(live_face.length > 1)
    let peer_age_s  = $derived(face?.sc?.last ? Math.round((now - (face.sc.last as number)) / 1000) : null)

    // ── Cred — code credibility at a glance ──
    const base = (p: any) => String(p ?? '').split('/').pop()

    // ── the verdict, step-level — the honest "this test passes" count ──────
    //   A dock's %run_result carries done (the Story's step count) + ok_pct (fraction
    //    of steps that stamped %ok); ok_pct*done is the passing steps, mirroring the
    //     runner's tlog.  We roll up across docks so the card reads "{passed}/{total}
    //      {Book}" — a partial pass shows as 4/5, NOT collapsed to a red "0/1 docks
    //       green" (the per-dock ok is all-or-nothing, which read as failing when one
    //        step of five was stale).  book rides the frame from storyFinished.
    const rr_pass  = (rr: TheC) => Math.round(Number(rr.sc?.ok_pct ?? (rr.sc?.ok ? 1 : 0)) * Number(rr.sc?.done ?? 1))
    const rr_total = (rr: TheC) => Number(rr.sc?.done ?? 1)

    // ── cred cull — let stale verdict rows age out ──────────────────────────
    //   A sweep (StoryTimes / become_book) piles up one row per Book; left forever they bury the
    //    panel.  So each %run_result fades on age (off rr.sc.at, stamped by Lies_run_result_recv)
    //     and is dropped from the strip past CRED_TTL — the data stays on w:Lies, only the LINE
    //      goes quiet.  now ticks on the 3s heartbeat bump, so the fade is coarse but free.  A
    //       row with no `at` (legacy) never ages.  The headline rolls up only what's still shown.
    const CRED_TTL  = 45000
    const CRED_FADE = 25000
    const rr_age    = (rr: TheC) => rr.sc?.at ? now - Number(rr.sc.at) : 0
    let cred_rows   = $derived(run_results.filter(rr => rr_age(rr) < CRED_TTL))
    let steps_pass  = $derived(cred_rows.reduce((n, rr) => n + rr_pass(rr), 0))
    let steps_total = $derived(cred_rows.reduce((n, rr) => n + rr_total(rr), 0))
    let all_green   = $derived(steps_total > 0 && steps_pass === steps_total)
    // the Book under test — the latest run_result carrying a book label (one runner, v1).
    let verdict_book = $derived(cred_rows.find(r => r.sc?.book)?.sc?.book as string | undefined)

    // ── runner panel — the run, felt bouncing (the run_phase relay) ──────────
    //   The latest progress blip, glyphed by flavour, shown while a run is in flight and faded
    //    out once it ages (30s of silence ⇒ the runner went quiet — stop pretending it's live).
    //     all_done lands a final "🏁 done n/n" that the verdict (run_result) then greens/reds.
    const bk = (p: any) => p.book ? `${base(p.book)} ` : ''
    // stall_band — coarse, calm staleness for the runner panel.  A localhost run should feel
    //  instant, so a per-second number counting up reads as alarm, not information.  Show only the
    //   largest threshold crossed (>2s, >5s, …): it steps at milestones and never ticks.
    const stall_band = (s: number) => { for (const t of [60, 30, 10, 5, 2]) if (s >= t) return `>${t}s`; return '' }
    const PHASE_VIEW: Record<string, { glyph: string, label: (p: any) => string }> = {
        rungo_ack:   { glyph: '📥', label: () => 'acked' },
        story_begun: { glyph: '▶',  label: (p) => `running ${p.book ? base(p.book) : p.path ? base(p.path) : ''}`.trimEnd() },
        step_done:   { glyph: '●',  label: (p) => `${bk(p)}step ${p.n}${p.total ? `/${p.total}` : ''}` },
        step_stall:  { glyph: '⏳', label: (p) => { const b = stall_band(Number(p.secs)); return `${bk(p)}step ${p.n}${p.total ? `/${p.total}` : ''}${b ? ` — ${b}…` : ''}` } },
        all_done:    { glyph: '🏁', label: (p) => `${bk(p)}done ${p.n ?? ''}${p.total ? `/${p.total}` : ''}` },
    }
    let phase_age_s = $derived(run_phase?.at ? Math.round((now - (run_phase.at as number)) / 1000) : null)
    let phase_live  = $derived(!!run_phase && now - (run_phase.at as number) < 30000)
    let phase_view  = $derived(run_phase ? PHASE_VIEW[run_phase.phase as string] : undefined)
    let phase_stall = $derived(run_phase?.phase === 'step_stall')
    let phase_done  = $derived(run_phase?.phase === 'all_done')
    // the fill of the little progress bar — n/total when the blip carries a count, else empty.
    let phase_pct   = $derived(run_phase?.total ? Math.min(100, Math.round((Number(run_phase.n ?? 0) / Number(run_phase.total)) * 100)) : null)

    // ── health card expand (Vexpandy block mode) ─────────────────────
    //   Opens by default: the channel + verdict glance is the panel's headline, so a
    //    runner tab reads "does my pushed code pass?" without a click.
    let health_open = $state(true)

    // ── + Waft form ──────────────────────────────────────────────────
    let waft_form_open = $state(false)
    let new_waft_path  = $state('')

    function submit_new_waft() {
        const path = new_waft_path.trim()
        if (!path) return
        H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
        new_waft_path  = ''
        waft_form_open = false
    }

    // ── active / delete (need Lies to touch siblings) ─────────────────
    function set_waft_active(waft: TheC) {
        if (!Lies) return
        for (const w of Lies.o({ Waft: 1 }) as TheC[]) delete w.sc.active
        waft.sc.active = 1
        Lies.bump_version()
    }
    function delete_waft(waft: TheC) {
        if (!Lies) return
        Lies.drop(waft)
        Lies.bump_version()
    }

    // ── errors ───────────────────────────────────────────────────────
    function dismiss_errors() {
        if (!Lies) return
        for (const e of errors) Lies.drop(e)
        Lies.bump_version()
    }
</script>

<div class="ls-ui">

    <!-- header — role badge (always-on, so a runner tab is unmistakable) + the + Waft row -->
    <div class="ls-header">
        {#if role}
            <span class="ls-role ls-role-{role}" title={ROLE_TITLE[role]}>{role}</span>
        {/if}
        <PeelInput
            label="Waft"
            open={waft_form_open}
            mk_ph="path/to/waft"
            sc_ph=""
            mainkey={new_waft_path}
            on_mk={(v) => new_waft_path = v}
            submit_label="+"
            on_open={() => { waft_form_open = true }}
            on_submit={submit_new_waft}
            on_cancel={() => { waft_form_open = false; new_waft_path = '' }} />
    </div>

    <!-- Cred readout — the runner's verdict per dock (%run_result over the channel).  Shows how
         credible the code you're pushing is: step pass-count per dock, green when every step
         passed.  Step-level (not the all-or-nothing dock ok) so it agrees with the .ls-health
         headline; the runner's .ls-health card is the at-a-glance home, this is the detail strip.
         Empty until a run_result comes home, so it's quiet on a fresh editor / a bare Lies. -->
    {#if cred_rows.length}
        <div class="ls-cred" title="code credibility — the runner's verdict on the versions you pushed">
            <span class="ls-cred-h" class:all-green={all_green}>🧪 {steps_pass}/{steps_total}</span>
            {#each cred_rows as rr (rr.sc.path)}
                <span class="ls-cred-dock" class:ok={rr_pass(rr) === rr_total(rr)} class:bad={rr_pass(rr) !== rr_total(rr)}
                      class:aging={rr_age(rr) > CRED_FADE}
                      title="{rr.sc.path} @ {String(rr.sc.dige ?? '').slice(0,8)} — {rr_pass(rr)}/{rr_total(rr)} steps{rr.sc.errors ? `, ${rr.sc.errors} err` : ''}">
                    {rr_pass(rr) === rr_total(rr) ? '✓' : '✗'} {base(rr.sc.path)}&nbsp;{rr_pass(rr)}/{rr_total(rr)}
                </span>
            {/each}
        </div>
    {/if}

    <!-- runner panel — the live progress of the run on the other end of the channel.  One row
         that blips through the flavour arc (acked → running → step n/total → done); the glyph BANGS
         on each blip ({#key} replays the pop), a count rides a shimmering fill bar, a stalled step
         pulses amber.  Present only while a run is in flight (fades out after 30s of silence). -->
    {#if phase_live && phase_view}
        <div class="ls-runphase" class:stall={phase_stall} class:done={phase_done}
             title="runner progress — {run_phase.phase}{phase_age_s != null ? `, ${phase_age_s}s ago` : ''}">
            {#key run_phase.at}<span class="ls-runphase-g">{phase_view.glyph}</span>{/key}
            <span class="ls-runphase-l">{phase_view.label(run_phase)}</span>
            {#if phase_pct != null}
                <span class="ls-runphase-bar"><span class="ls-runphase-bar-fill" style="width:{phase_pct}%"></span></span>
            {/if}
        </div>
    {/if}

    {#if !Lies}
        <div class="ls-empty">waiting for Lies…</div>
    {:else}

    {#if errors.length}
        <div class="ls-errors">
            <strong>⛔ compile errors</strong>
            <button class="ls-dismiss" onclick={dismiss_errors}>×</button>
            {#each errors as err}
                <div class="ls-error-msg">{err.sc.path ?? ''} — {err.sc.msg}</div>
            {/each}
        </div>
    {/if}

    <!-- loaded docs flat list — w/{loaded_doc:1} entries confirm Lies handed
         each doc to Lang.  DocRow reads w.version directly so pending/active
         state is live without Liesui re-rendering. -->
    {#if loaded_docs.length}
        <div class="ls-loaded-section">
            {#each loaded_docs as ld (ld.sc.path)}
                <DocRow {H} w={Lies} doc={ld} {examining} />
            {/each}
        </div>
    {/if}

    <!-- Waft tree — pass Lies (w particle) as w so DocRow inside WaftComp has
         live state.  WaftComp is keyed by waft.sc.Waft so it survives re-renders. -->
    {#if all_wafts.length}
        <div class="ls-waft-section">
            {#each all_wafts as waft (waft.sc.Waft)}
                <WaftComp {H} w={Lies} {waft} depth={0}
                    {examining}
                    on_active={set_waft_active}
                    on_delete={delete_waft} />
            {/each}
        </div>
    {:else}
        <!-- gap filler: a runner-flavoured Lies (w%runner) has no GhostList index and
             opens no editor Wafts, so the list is legitimately empty — say so with the
             w's quality flags instead of a bare "no wafts". -->
        {@const quals = ['runner', 'dontSnap'].filter(k => Lies?.sc?.[k])}
        {#if quals.length}
            <div class="ls-empty ls-quals"
                 title="runner-flavoured Lies — read · compile · include only; no editor index, no Wafts">
                {#each quals as q}<span class="ls-qual">{q}</span>{/each}
                <span class="ls-qnote">read · compile · include</span>
            </div>
        {:else}
            <div class="ls-empty">no wafts</div>
        {/if}
    {/if}

    {/if}

    <!-- connection-health card — the channel relationship (editor↔runner): the unclickable
         status readout that used to float over the Lang minimap.  It now lives in Lies, its
         more natural home, pinned to the panel's bottom-right with a Vexpandy to tuck it slim
         so it never buries the waft list.  The peer is the faced role — an editor watches its
         runner, a runner watches its editor.  It carries the headline verdict glance — the
         step-level "this test passes" badge ({passed}/{total} {Book}) — and opens by default so a
         glance answers "did my pushed code pass?" without a click. -->
    <!-- Cluster-identity alert — a SurprisePopup-style notice pinned to the bottom of the panel (by
         the runner/cluster status card), so a keyless editor — which can't sign gen_write and is
         silently rejected by the relay — is impossible to miss. Reactive to .stashed: clears the
         instant the 🪪 Id hatch loads a key. -->
    {#if no_cluster_key}
        <div class="ls-nokey" role="alert"
             title="this editor has no cluster signing key — gen_write is rejected unsigned. Load one →">
            <span class="ls-nokey-hd">⚠ no cluster identity</span>
            <Actions N={id_action} />
        </div>
    {/if}

    {#if expect_peer}
        <div class="ls-health" class:ls-health-live={peer_live} class:ls-health-open={health_open}>
            <div class="ls-health-line">
                <span class="ls-health-dot" class:on={peer_live}>{peer_live ? '●' : '○'}</span>
                <span class="ls-health-peer">{expect_peer}</span>
                {#if peer_live && peer_rtt != null}
                    <span class="ls-health-rtt" title="bridged round-trip">{peer_rtt}ms</span>
                {/if}
                {#if peer_clash}<span class="ls-health-clash" title="{live_face.length} {expect_peer}s live — verdicts may disagree">⚠{live_face.length}</span>{/if}
                <!-- the verdict glance — the headline.  Steps passed / total, with the Book.
                     Green only when every step passed; a partial pass reads honestly (4/5). -->
                {#if steps_total}
                    <span class="ls-health-pass" class:all-green={all_green}
                          title="{steps_pass} of {steps_total} steps passed on the runner — green only when all do">
                        🧪 {steps_pass}/{steps_total}{#if verdict_book}&nbsp;{verdict_book}{/if}
                    </span>
                {/if}
                <Vexpandy bind:expanded={health_open} />
            </div>
            {#if health_open}
                <div class="ls-health-sub">
                    {#if peer_live}heard {peer_age_s}s ago
                    {:else if face}silent {peer_age_s}s — no pong
                    {:else}no {expect_peer} has connected{/if}
                </div>
                <!-- per-dock breakdown — each pushed dock's step pass count, so a multi-dock
                     run shows which dock is dragging the roll-up red.  Ages out with the strip
                     (cred_rows): a sweep's Book rows dim past CRED_FADE and cull at CRED_TTL. -->
                {#each cred_rows as rr (rr.sc.path)}
                    <div class="ls-health-dock" class:all-green={rr_pass(rr) === rr_total(rr)}
                         class:aging={rr_age(rr) > CRED_FADE}
                         title="{rr.sc.path} @ {String(rr.sc.dige ?? '').slice(0,8)}">
                        {rr_pass(rr) === rr_total(rr) ? '✓' : '✗'} {rr_pass(rr)}/{rr_total(rr)} {base(rr.sc.path)}
                    </div>
                {/each}
            {/if}
        </div>
    {/if}
</div>

<style>
    .ls-ui {
        position: relative;     /* anchors the bottom-right .ls-health card */
        font-size: 0.83rem; padding: 0.5rem;
        padding-bottom: 1.7rem; /* reserve a strip so the collapsed card never sits over a list row */
        border: 1px solid #444; border-radius: 4px;
        background: #111; color: #ccc; min-width: 360px;
    }
    .ls-header { margin-bottom: 0.3rem; display: flex; align-items: center; gap: 0.4rem }
    .ls-header :global(.peel-input), .ls-header > :last-child { flex: 1 }
    .ls-role {
        font-size: 0.7rem; text-transform: uppercase; letter-spacing: 0.04em;
        border-radius: 3px; padding: 0.05rem 0.4rem; line-height: 1.5;
        border: 1px solid currentColor; cursor: help; flex: none;
    }
    .ls-role-runner { color: #c4aaee; background: rgba(196, 170, 238, 0.12) }
    .ls-role-editor { color: #6ad0c0; background: rgba(106, 208, 192, 0.12) }
    .ls-role-lies   { color: #888;    background: rgba(136, 136, 136, 0.12) }
    /* SurprisePopup-style: sticks to the bottom of the panel so it stays in view (by the status
       card) however the waft list scrolls, with a loud border + shadow so it reads as a popup. */
    .ls-nokey {
        position: sticky; bottom: 0; z-index: 5;
        margin: 0.4rem 0 0; padding: 0.55rem 0.75rem; border-radius: 5px; font-size: 1rem;
        display: flex; align-items: center; gap: 0.5rem;
        color: #f0c674; background: #2a1d08; border: 1px solid rgba(240, 198, 116, 0.55);
        box-shadow: 0 -2px 14px rgba(0,0,0,0.5);
    }
    .ls-nokey-hd { font-weight: bold; }
    .ls-nokey :global(.btn) { font-size: 1.15rem; padding: 0.2rem 0.6rem; }
    /* ── connection-health card — bottom-right channel status, ex-Lang minimap floater ── */
    .ls-health {
        position: absolute;
        bottom: 6px; right: 6px;
        box-sizing: border-box;
        max-width: calc(100% - 12px);
        padding: 3px 6px;
        background: rgba(9, 11, 13, 0.93);
        border: 1px solid #1a1a1a; border-radius: 4px;
        font-family: monospace; font-size: 0.62rem; line-height: 1.4;
        color: #678; z-index: 6;
    }
    .ls-health-live  { border-color: rgba(106, 208, 192, 0.3); }
    .ls-health-line  { display: flex; align-items: center; gap: 0.3rem; flex-wrap: wrap; }
    .ls-health-line :global(.vx-btn) { margin-left: auto; width: 16px; height: 16px; font-size: 13px; }
    .ls-health-dot   { color: #5a4a3a; }
    .ls-health-dot.on{ color: #6ad0c0; }
    .ls-health-peer  { color: #9ab0c4; letter-spacing: 0.04em; text-transform: uppercase; }
    .ls-health-rtt   { color: #6a8; font-variant-numeric: tabular-nums; }
    .ls-health-clash { color: #f0b040; font-weight: bold; }
    .ls-health-sub   { color: #556; font-style: italic; margin-top: 2px; }
    /* verdict glance — sits on the always-visible line, the panel's headline.  Amber
       (partial / failing) until every step passes, then green. */
    .ls-health-pass  {
        margin-left: 4px; padding: 0 4px; border-radius: 3px;
        color: #f0b040; background: rgba(240, 176, 64, 0.12);
        font-variant-numeric: tabular-nums; white-space: nowrap;
    }
    .ls-health-pass.all-green { color: #6ad0c0; background: rgba(106, 208, 192, 0.14); }
    .ls-health-dock           { margin-top: 2px; color: #c98; }
    .ls-health-dock.all-green { color: #8a9; }
    .ls-health-dock.aging     { opacity: 0.4; transition: opacity 0.6s ease }
    .ls-cred {
        display: flex; flex-wrap: wrap; gap: 0.3rem; align-items: center;
        margin-bottom: 0.4rem; padding: 0.2rem 0.3rem; border-radius: 3px;
        background: rgba(196, 170, 238, 0.06);
    }
    .ls-cred-h {
        font-size: 0.72rem; letter-spacing: 0.03em; color: #c4aaee;
        padding: 0.05rem 0.4rem; border-radius: 3px; border: 1px solid currentColor; cursor: help;
    }
    .ls-cred-h.all-green { color: #6ad0c0 }
    .ls-cred-dock {
        font-size: 0.72rem; font-family: monospace; padding: 0.05rem 0.4rem;
        border-radius: 3px; cursor: help; white-space: nowrap;
    }
    .ls-cred-dock.ok  { color: #6ad0c0; background: rgba(106, 208, 192, 0.12) }
    .ls-cred-dock.bad { color: #f88;    background: rgba(255, 136, 136, 0.12) }
    /* runner panel — the live run blip.  A quiet purple row that pulses amber on a stall and
       settles green on all_done; the glyph BANGS on each blip, the count rides a shimmering bar. */
    .ls-runphase {
        display: flex; gap: 0.4rem; align-items: center;
        margin-bottom: 0.4rem; padding: 0.2rem 0.45rem; border-radius: 3px;
        font-size: 0.74rem; color: #c4aaee; background: rgba(196, 170, 238, 0.08);
        border-left: 2px solid #c4aaee; cursor: help;
    }
    /* the glyph re-mounts on every blip ({#key run_phase.at}) and replays this pop — the bang. */
    .ls-runphase-g {
        display: inline-block; font-size: 0.82rem; line-height: 1; transform-origin: center;
        animation: ls-runphase-pop 0.34s cubic-bezier(0.3, 1.5, 0.5, 1);
    }
    .ls-runphase-l { font-family: monospace; letter-spacing: 0.02em; white-space: nowrap }
    /* the fill bar: a sliding sheen while running, freezing solid on done. */
    .ls-runphase-bar {
        flex: 1; min-width: 28px; height: 3px; margin-left: 0.1rem;
        background: rgba(196, 170, 238, 0.16); border-radius: 2px; overflow: hidden;
    }
    .ls-runphase-bar-fill {
        display: block; height: 100%; border-radius: 2px; transition: width 0.35s ease;
        background: linear-gradient(90deg, #8d6fce 0%, #c4aaee 40%, #8fd6ff 50%, #c4aaee 60%, #8d6fce 100%);
        background-size: 220% 100%; animation: ls-runphase-shimmer 1.3s linear infinite;
    }
    .ls-runphase.stall { color: #e7b15a; border-left-color: #e7b15a;
        background: rgba(231, 177, 90, 0.10); animation: ls-runphase-pulse 1s ease-in-out infinite }
    .ls-runphase.stall .ls-runphase-bar-fill { background: #e7b15a; animation: none }
    .ls-runphase.done  { color: #6ad0c0; border-left-color: #6ad0c0; background: rgba(106, 208, 192, 0.10) }
    .ls-runphase.done  .ls-runphase-bar-fill { background: #6ad0c0; animation: none }
    @keyframes ls-runphase-pulse   { 0%, 100% { opacity: 1 } 50% { opacity: 0.55 } }
    @keyframes ls-runphase-pop     { 0% { transform: scale(1.7); filter: brightness(1.9) }
                                     55% { transform: scale(0.9) } 100% { transform: scale(1); filter: none } }
    @keyframes ls-runphase-shimmer { 0% { background-position: 220% 0 } 100% { background-position: 0 0 } }
    /* a verdict row past CRED_FADE dims toward its cull at CRED_TTL — visibly going quiet. */
    .ls-cred-dock.aging { opacity: 0.4; transition: opacity 0.6s ease }
    .ls-errors {
        background: #300; border: 1px solid #c44; border-radius: 3px;
        padding: 0.3rem 0.5rem; margin-bottom: 0.4rem;
        color: #f88; display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: flex-start;
    }
    .ls-dismiss   { margin-left: auto; background: none; border: none; color: #f88; cursor: pointer; font-size: 1rem; line-height: 1 }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }
    .ls-loaded-section { margin-bottom: 0.4rem }
    .ls-empty  { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-quals  { display: flex; flex-wrap: wrap; gap: 0.3rem; align-items: center; font-style: normal }
    .ls-qual   {
        font-size: 0.7rem; color: #c4aaee;
        background: rgba(196, 170, 238, 0.1);
        border: 1px solid rgba(196, 170, 238, 0.35); border-radius: 3px;
        padding: 0 0.35rem; line-height: 1.5;
    }
    .ls-qnote  { color: #667; font-size: 0.72rem; font-style: italic }
    .ls-waft-section { margin-top: 0.2rem }
</style>
