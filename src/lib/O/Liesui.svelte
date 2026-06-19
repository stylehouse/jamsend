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

    let { H }: { H: House } = $props()

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

    // ── Cred — code credibility at a glance: the runner's green/red per dock ──
    let cred_total = $derived(run_results.length)
    let cred_green = $derived(run_results.filter(r => r.sc?.ok).length)
    const base = (p: any) => String(p ?? '').split('/').pop()

    // ── health card expand (Vexpandy block mode) ─────────────────────
    let health_open = $state(false)

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
         credible the code you're pushing is: ✓ green / ✗ red(N), plus a pass count.  Empty until a
         run_result comes home, so it's quiet on a fresh editor / a bare Lies. -->
    {#if cred_total}
        <div class="ls-cred" title="code credibility — the runner's verdict on the versions you pushed">
            <span class="ls-cred-h" class:all-green={cred_green === cred_total}>🧪 {cred_green}/{cred_total}</span>
            {#each run_results as rr (rr.sc.path)}
                <span class="ls-cred-dock" class:ok={rr.sc.ok} class:bad={!rr.sc.ok}
                      title="{rr.sc.path} @ {String(rr.sc.dige ?? '').slice(0,8)} — {rr.sc.ok ? 'green' : `red (${rr.sc.errors} err)`}">
                    {rr.sc.ok ? '✓' : '✗'} {base(rr.sc.path)}{#if !rr.sc.ok && rr.sc.errors}&nbsp;{rr.sc.errors}{/if}
                </span>
            {/each}
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
         runner, a runner watches its editor; the verdict glance reuses the Cred count. -->
    {#if expect_peer}
        <div class="ls-health" class:ls-health-live={peer_live} class:ls-health-open={health_open}>
            <div class="ls-health-line">
                <span class="ls-health-dot" class:on={peer_live}>{peer_live ? '●' : '○'}</span>
                <span class="ls-health-peer">{expect_peer}</span>
                {#if peer_live && peer_rtt != null}
                    <span class="ls-health-rtt" title="bridged round-trip">{peer_rtt}ms</span>
                {/if}
                {#if peer_clash}<span class="ls-health-clash" title="{live_face.length} {expect_peer}s live — verdicts may disagree">⚠{live_face.length}</span>{/if}
                <Vexpandy bind:expanded={health_open} />
            </div>
            {#if health_open}
                <div class="ls-health-sub">
                    {#if peer_live}heard {peer_age_s}s ago
                    {:else if face}silent {peer_age_s}s — no pong
                    {:else}no {expect_peer} has connected{/if}
                </div>
                {#if cred_total}
                    <div class="ls-health-verdict" class:all-green={cred_green === cred_total}>
                        🧪 {cred_green}/{cred_total} docks green
                    </div>
                {/if}
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
    .ls-health-line  { display: flex; align-items: center; gap: 0.3rem; }
    .ls-health-line :global(.vx-btn) { margin-left: auto; width: 16px; height: 16px; font-size: 13px; }
    .ls-health-dot   { color: #5a4a3a; }
    .ls-health-dot.on{ color: #6ad0c0; }
    .ls-health-peer  { color: #9ab0c4; letter-spacing: 0.04em; text-transform: uppercase; }
    .ls-health-rtt   { color: #6a8; font-variant-numeric: tabular-nums; }
    .ls-health-clash { color: #f0b040; font-weight: bold; }
    .ls-health-sub   { color: #556; font-style: italic; margin-top: 2px; }
    .ls-health-verdict          { margin-top: 2px; color: #8a9; }
    .ls-health-verdict.all-green{ color: #6ad0c0; }
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
