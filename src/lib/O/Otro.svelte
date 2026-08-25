<script lang="ts">
    // Otro
    import Ghost    from "$lib/O/Ghost.svelte"
    import { House } from "$lib/O/Housing.svelte"
    import { keyser } from "$lib/data/Stuff.svelte"
    import Actions from "$lib/O/ui/Actions.svelte"
    import Lens from "$lib/O/ui/Lens.svelte"
    import Stuffing from "$lib/data/Stuffing.svelte"
    import { onDestroy, onMount, untrack } from "svelte";
    import NaviScroll from "./ui/NaviScroll.svelte";
    import { boot_param } from "$lib/boot";
    import BootGate from "./ui/BootGate.svelte";
    import { sockcap_install, socklog_armed } from "$lib/O/sockcap";   // ALMOST-GONER: relay-socket tap (dumped via Wormhole) — sockcap.ts header
    // TEMP — CPU-attribution experiment (?cpu_legs=1): cycles which Lies/Lang/Cyto/Story panel
    //  is mounted, announcing the leg on screen + console, so CPU readings taken externally
    //  (Activity Monitor / Task Manager) can be attributed to a panel. Inert unless armed —
    //  see CpuLegs.svelte.ts. Remove once the experiment's table is in.
    import { cpu_leg_hides } from "$lib/O/ui/CpuLegs.svelte";
    import CpuLegBanner from "$lib/O/ui/CpuLegBanner.svelte";

    //#region H:Mundo
    // ── all House construction inside $effect ─────────────────────────────────
    let H: House = $state(null!)
    let R
    // ?A=<World> chooses which top-level world boots (default Auto, the Library/Story owner;
    //  may_begin stands up A:<A>/w:<A>).  The editor and test runner are Story Books, NOT their
    //  own top-level worlds — they boot via ?B=<Book> (below) under the default Auto.
    //  boot_param abstracts the source: URL query in the browser, env var (A=) in node.
    //  Computed ONCE out here, and set on the LOCAL `h` below — NEVER as `H.c.x = …` inside
    //  the $effect: reading the $state H there makes the effect depend on H, which it also
    //  reassigns (`H = new House()`), so it self-retriggers forever, allocating a House every
    //  tick → the tab OOMs to multi-GB.  (Svelte 5: an effect re-runs on any $state it reads.)
    const toplevel = boot_param('A') || 'Auto'
    // ?B=<Book> auto-activates a Story Book under the default A=Auto (the Library/Story owner) —
    //  ?B=Editron boots the editor as a Book, ?B=PereStaple the test runner, etc.  Auto reads
    //   H.c.book on first boot and activates it (see Auto.svelte).  ?W=<Waft> rides alongside for
    //    the Book that opens one.  Stamped on the LOCAL `h`, never inside the $effect — same
    //     self-retrigger trap as toplevel above.
    // The param LETTER is the authoritative role: ?E=<Book> boots that Book as the EDITOR
    //  (full Lang chrome — what ?B=Editron did before); ?B=<Book> boots it as a UIless RUNNER
    //   (no w:Lang; Story + the Creduler).  Mundo carries the choice as %book + %boot_role; a Run
    //    House inherits boot_role at Story_subHouse, and a Book recipe only falls back to its own
    //     role when neither param is set (a Library-driven boot).  Computed out here and set on the
    //      LOCAL h — never read $state H inside the effect (the self-retrigger OOM trap above).
    const editor_book = boot_param('E')
    const book        = boot_param('B')
    const on_grid     = boot_param('I')   // ?I=<tag> ALONE (no ?E/?B) — an idle runner-on-the-grid
    // &remoteWormhole=1: this tab has NO local tree — it acquires a method:remoteWormhole backend,
    //  begging a trusted editor to proxy its disk (a headless flock runner; see Cluster_spec "beg
    //   through the Brink").  Stamped on the LOCAL h (never read $state H inside the effect — the
    //    OOM trap above).  (Was &disk=proxy.)
    const remote_wormhole = boot_param('remoteWormhole') != null
    // ── investigation scaffold (TEMP — remove once roster/dispatch is confirmed healthy) ──────────
    //  Auto-reload a runner|editor tab every few minutes so fresh come-up + see-each-other handshakes
    //   keep cycling unattended (no human at the tab).  Cluster boots only (?E=/?B=/?I=), never the
    //    Library.  DEFAULT OFF now the dispatch fix is verified (was 3 during the investigation) — it
    //     disrupts a human at the tab + accretes socklog files; re-enable with &watch=<minutes>.
    //       Identity + edits persist to Dexie/.stashed across a reload.
    const watch_min = (() => { const v = boot_param('watch'); return v == null ? 0 : Number(v) })()
    // tap the relay socket (before the channel boots) so its traffic is captured for the Wormhole dump —
    //  ARMED opt-in ONLY: ?socklog (or implied by ?watch), never a plain tab.  OFF by default the tap never
    //   installs, sockcap stays empty, and Lies_dump_socklog early-returns — so no _socklog files and no
    //    rw-req blob every ~10s (which is what an always-on capture was parking in the snap).  Browser-guarded.
    if ((editor_book || book || on_grid) && (boot_param('socklog') != null || socklog_armed() || watch_min > 0)) sockcap_install()
    if (typeof window !== 'undefined' && (editor_book || book || on_grid) && watch_min > 0) {
        onMount(() => {
            const id = setInterval(() => { try { location.reload() } catch {} }, watch_min * 60_000)
            return () => clearInterval(id)
        })
    }
    $effect(() => {
        const h = new House({ name: 'Mundo' })
        h.c.toplevel = toplevel
        if (editor_book) { h.c.book = editor_book; h.c.boot_role = 'editor' }
        else if (book)   { h.c.book = book;        h.c.boot_role = 'runner' }
        // ?I= with no Book: a runner-on-the-grid.  Same runner role as ?B= (Creduler + channel), but
        //  NO H.c.book — so no Story starts at boot; the tab idles connected until the editor hands it
        //   a become_book.  /Otro?I=new is the whole on-ramp; the identity layer (Auto) does the rest.
        //  (?E=/?B= still win: an editor or booked runner that ALSO carries ?I just gains an identity.)
        else if (on_grid) {                        h.c.boot_role = 'runner' }
        if (remote_wormhole) h.c.remote_wormhole = true
        H = h
        setTimeout(() => {
            houses = [H]
        },1)
    })

    // ── once ghosts have arrived, wire child Houses ───────────────────────────
    let setup_done = $state(false)
    $effect(() => {
        if (!H?.started || setup_done) return
        setup_done = true

        H.may_begin()

        // < drop this?
        setTimeout(() => {
            houses = H.all_House
        },1)

        setTimeout(() => {
            // S.i_elvisto(S, 'think')
            // S.todo.push("Blanks")
        },444)

        go_busily()
    })

    // ── the todo popover — which House's drain queue is open (its c.ip), or null ─────────────
    //  One at a time: these are diagnostic, they overlap the headers below them, and two open at
    //   once is unreadable.  Keyed by c.ip rather than an index so it survives houses re-sorting.
    let todo_open: string | null = $state(null)
    // elvis_label — the headline for one queued item.  Two shapes ride H.todo (see _push_todo):
    //  a PLAIN elvis (sc.elvis = the method name, sc.Aw = the A/w it targets) and a post_do BLOCK
    //   (sc.fn = a closure, sc.see = its label).  A fn-carrying e never enters beliefs() at all —
    //    it runs directly — so naming which kind it is matters when you're reading a stuck queue.
    //  Mirrors the tag _push_todo traces, so the popup, the trace and the V.organise log agree.
    const elvis_label = (e: any) => e?.sc?.fn ? `fn:${e.sc.see ?? '?'}` : (e?.sc?.elvis ?? '?')
    // Ages tick on their OWN interval, armed only while a popover is open.  They must not ride the
    //  House's version or H.clear() — both of which STOP under the very wedge this is here to show,
    //   which would freeze the readout at the exact moment it matters (and read as "0s ago", a lie).
    let pop_now = $state(0)
    $effect(() => {
        if (!todo_open) return
        const iv = setInterval(() => pop_now = Date.now(), 500)
        return () => clearInterval(iv)
    })
    const age_s = (at: number) => { void pop_now; const s = Math.round((Date.now() - at) / 1000); return s < 1 ? 'just now' : `${s}s ago` }
    // the top House's beliefs mutex, live — held by ANY House's item, freezing them all.
    let wedge = $derived.by(() => { void pop_now; return todo_open ? (H?.top_House?.() as any)?.mutex_held?.('beliefs') ?? null : null })

    // Throttled snapshot — refreshes every 2 s so items don't vanish while you're reading them.
    //  The LIVE count in the badge header always shows truth; the rows show the last snap.
    //  `untrack` inside the refresh deliberately breaks reactivity on h.todo so the effect
    //   does NOT re-fire every time an item is pushed/shifted — only the timer drives it.
    let todo_snap: any[] = $state([])
    let snap_at: number  = $state(0)
    $effect(() => {
        if (!todo_open) { todo_snap = []; snap_at = 0; return }
        const refresh = () => {
            const h = houses.find(h => h.c.ip === todo_open)
            todo_snap = h ? untrack(() => (h as any).todo.slice()) : []
            snap_at = Date.now()
        }
        refresh()
        const iv = setInterval(refresh, 2000)
        return () => clearInterval(iv)
    })
    // push log — last 20 entries from H._push_log, updated every 500ms with pop_now.
    //  Non-reactive plain array on H; read here under untrack so this effect only fires
    //  when pop_now or todo_open changes, not on every individual push.
    let push_log_snap: any[] = $state([])
    $effect(() => {
        void pop_now   // re-run every 500ms while open
        if (!todo_open) { push_log_snap = []; return }
        const h = houses.find(h => h.c.ip === todo_open)
        push_log_snap = h ? untrack(() => ((h as any)._push_log ?? []).slice(-60)) : []
    })

    $effect(() => {
        if (!setup_done) return
        houses = H.all_House
    })

    // ── reactive house list via H.all_House ───────────────────────────────────
    // all_House lives on House so .o() / Xify() mutations stay inside H.*
    // and don't fire mid-derived in the template.
    let houses = $state([])

    function go_busily() {
        H.i_elvisto(H, 'think')
    }

    // ── disk|audio gate ────────────────────────────────────────────────────────
    // The fullscreen boot-permissions gate lives in ui/BootGate.svelte now (shared with
    //  BigWordland).  Otro's policy rides its defaults: the pure-audio beg defers to the
    //   Brink's Sound face under a dev boot, and the copy addresses the boot role.

    onDestroy(() => {
        H?.stop()
    })

    // Per-House toggle for the C** dump (the Stuffing tree).  Stored on the
    //  Dexie-backed .stashed, not in Opt/the C tree — it's a viewer preference,
    //   not Book state, so it shouldn't snap or bleed across Books.  Following
    //    the "lean stashed" doctrine we delete the key when off rather than
    //     storing a 0, so the autosave $effect (which tracks the key set) fires.
    function toggle_C(house) {
        if (house.stashed.showC) delete house.stashed.showC
        else house.stashed.showC = 1
    }
</script>

<BootGate {H} />

<NaviScroll {H} {houses}>
    {#snippet children({ scrollToHouseIdx, scrollToHouseIp, childrenOf })}
        {#each houses as house, i (house.c.ip)}
            {@const hasActions = house.actions.ob({}).length > 0}
            {@const stickyIndex = houses.slice(0, i).filter(h => h.actions.ob({}).length).length}
            {@const kids = childrenOf(house)}
            <div class="house-header"
                class:sticky={hasActions}
                class:has-open-todo={todo_open === house.c.ip}
                id="house-{house.c.ip}"
                style="--stack-index: {stickyIndex};">
                <h2 class="house-name" title="navigate to this House"
                    class:clickable={hasActions}
                    onclick={hasActions ? () => scrollToHouseIdx(i) : null}>
                    {house.name}
                    {#if !house.started}<span class='ungood'>off</span>{/if}
                    <!-- the drain queue, and a way IN to it.  The count alone said "8" without ever
                         saying eight of WHAT — click it for the standing elvises.  stopPropagation:
                         the h2 itself navigates, and inspecting a queue must not also scroll you away. -->
                    <span class="todo-count" class:open={todo_open === house.c.ip}
                        title={house.todo.length
                            ? `${house.todo.length} elvis${house.todo.length === 1 ? '' : 'es'} waiting to drain — click to see them`
                            : 'todo drained'}
                        onclick={(ev) => { ev.stopPropagation(); todo_open = todo_open === house.c.ip ? null : house.c.ip }}
                    >{house.todo.length || (todo_open === house.c.ip ? '0' : '')}</span>
                </h2>
                {#if todo_open === house.c.ip}
                    <!-- Throttled snapshot (2 s refresh) so rows don't vanish mid-read.
                         The header always shows the LIVE count; rows are from the last snap.
                         Each row is the elvis's headline + keyser(e) — same as the _push_todo
                         V.organise trace, so popup and console log read identically. -->
                    <div class="todo-pop" role="dialog" aria-label="{house.name} todo queue">
                        <div class="todo-pop-hd">
                            <!-- live count is always fresh; snap age shows how stale the rows are -->
                            <span>H:{house.name} · live:{house.todo.length} · snap:{todo_snap.length}{#if snap_at} ({age_s(snap_at)}){/if}{#if house.c.drain_at} · drained {age_s(house.c.drain_at)}{/if}</span>
                            <span class="todo-pop-x" title="close" onclick={() => todo_open = null}>✕</span>
                        </div>
                        <!-- THE WEDGE LINE.  Every House drains under the TOP House's one beliefs mutex
                             and all_clear() awaits it, so a single `fn` that never settles freezes the
                             whole machine — and the tab keeps LOOKING alive because the socket stamps
                             ride off-think.  A standing queue with a fresh `last drained` is an ordinary
                             backlog; a standing queue with a stale one and a holder named here is the
                             wedge, and this is the line that finally says which elvis is sitting on it. -->
                        {#if wedge}
                            <div class="todo-wedge" role="alert">⚠ beliefs mutex held {Math.round(wedge.ms / 1000)}s by <b>{wedge.who}</b> — no House can drain until it settles</div>
                        {:else if house.todo.length && house.c.drain_why}
                            <div class="todo-why">◍ not draining: {house.c.drain_why}</div>
                        {/if}
                        <!-- method histogram — compact count per unique elvis label, most common first -->
                        {#if todo_snap.length > 1}
                            {@const hist = Object.entries(todo_snap.reduce((m: Record<string, number>, e) => {
                                const k = elvis_label(e); m[k] = (m[k] ?? 0) + 1; return m
                            }, {} as Record<string, number>)).sort((a, b) => b[1] - a[1])}
                            <div class="todo-hist">{hist.map(([k, n]) => `${k}×${n}`).join(' · ')}</div>
                        {/if}
                        <!-- rows from the throttled snapshot — live count in header shows truth -->
                        {#each todo_snap as e, ti (ti)}
                            <div class="todo-row">
                                <span class="todo-i">{ti}</span>
                                {#if e.c?.push_t}<span class="todo-age">{age_s(e.c.push_t)}</span>{/if}
                                <span class="todo-elvis">{elvis_label(e)}</span>
                                {#if e.sc?.Aw}<span class="todo-aw">{e.sc.Aw}</span>{/if}
                                <span class="todo-keys">{keyser(e)}</span>
                            </div>
                        {/each}
                        {#if !todo_snap.length}
                            <div class="todo-empty">{house.todo.length ? `snap empty · live ${house.todo.length}` : 'drained — nothing waiting'}</div>
                        {/if}
                        <!-- push log — last 20 _push_todo calls, newest last; 500ms refresh.
                             Answers "who is generating all these think|rw_op items?" on an idle tab.
                             reqturn = this push came from a req-callback turnaround (reply landed). -->
                        <!-- push log window: entries appear at 1.5s old, drop off at 3s.
                             The lag keeps transient things (quick drain) out of the view;
                             the 1.5s width shows the settled burst before it fully clears. -->
                        <!-- {@const} must be the immediate child of a block, not of the wrapping
                             <div> — so the cheap push_log_snap.length guard is its parent (an empty
                             snapshot filters to an empty window anyway, so behaviour is unchanged). -->
                        {#if push_log_snap.length}
                            {@const log_window = push_log_snap.filter(p => { const a = Date.now() - p.t; return a >= 1500 && a < 3000 })}
                            {#if log_window.length}
                                <div class="push-log-hd">push log 1.5–3s window</div>
                                {#each [...log_window].reverse() as p (p.t + p.tag)}
                                    <div class="push-log-row">
                                        <span class="push-log-age">{age_s(p.t)}</span>
                                        <span class="push-log-tag" class:push-reqturn={p.reqturn}>{p.tag}</span>
                                        <span class="push-log-depth">+{p.depth}</span>
                                    </div>
                                {/each}
                            {/if}
                        {/if}
                    </div>
                {/if}
                <div class="house-nav">
                    <span class="arrow arrow-up" title="navigate to the previous House"
                        class:disabled={i === 0}
                        onclick={() => i > 0 && scrollToHouseIdx(i - 1)}>▲</span>
                    <span class="arrow arrow-down" title="navigate to the next House"
                        class:disabled={i === houses.length - 1}
                        onclick={() => i < houses.length - 1 && scrollToHouseIdx(i + 1)}>▼</span>
                </div>
                {#if kids.length}
                    <span class="kids-sep">/</span>
                    <div class="house-kids">
                        {#each kids as kid (kid.c.ip)}
                            <span class="kid" title="navigate to this House"
                                onclick={() => scrollToHouseIp(kid.c.ip)}>
                                {kid.name}
                            </span>
                        {/each}
                    </div>
                {/if}

                <div class="house-actions">
                    {#if hasActions}<Actions N={house.actions.ob({ action: 1 })} />{/if}
                    {#if house.stashed}
                        <button class="cstar" class:on={house.stashed.showC}
                            title="show this House's C** (Stuffing) tree"
                            onclick={() => toggle_C(house)}>C**</button>
                    {/if}
                </div>
            </div>
            {#each house.UIs.ob({ UI: 1 }) as uiC (keyser(uiC.sc))}
                {#if !cpu_leg_hides(uiC.sc.UI)}
                    <svelte:component this={uiC.sc.component} H={house} />
                {/if}
            {/each}
            {#if house.stashed?.showC}
                <Stuffing mem={house.imem('current')} stuff={house} H={house} M={house} />
            {/if}
        {/each}
    {/snippet}
</NaviScroll>


<CpuLegBanner />

{#if H}
    <Lens {H} kind="Panel" />
{/if}

{#if H}
    <Ghost {H} />
{/if}

<style>
    .ungood { color: red; }

    /* Sits in the .house-actions row beside the data-driven <Actions>; styled to match them
       (a toggle: faint when off, solid when on) so the C** dump reads as just another action. */
    .cstar {
        padding: 0.3rem 0.6rem;
        border: none;
        border-radius: 4px;
        cursor: pointer;
        line-height: 0.8;
        font-size: 0.8rem;
        background: #2196F3;
        color: white;
        opacity: 0.45;
    }
    .cstar:hover { opacity: 0.75; }
    .cstar.on { opacity: 1; }

    .house-header {
        display: flex;
        align-items: center;
        gap: 0.75rem;
        background: var(--background, rgb(215, 237, 255));
        padding: 0 0.5rem;
        min-height: 1.75rem;
        z-index: 100;
        position: relative;   /* the anchor .todo-pop hangs off */
    }
    .house-header.sticky {
        position: sticky;
        top: calc(var(--stack-index) * 1.75rem);
    }
    /* when a todo pop is open, lift this header above its siblings (they share z-index:100;
       later DOM order wins at equal z — so without this the popup hides behind headers below) */
    .house-header.has-open-todo { z-index: 200; }

    .house-name {
        margin: 0;
        flex: 0 0 auto;
        min-width: 4rem;
        display: flex;
        align-items: baseline;
        gap: 0.5rem;
        font-size: 1rem;
    }
    .house-name.clickable { cursor: pointer; }
    .house-name.clickable:hover { opacity: 0.7; }
    .todo-count {
        font-size: 0.7em;
        opacity: 0.5;
        margin-left: auto;
        cursor: pointer;
        /* a hit area even at one digit — the resting look is unchanged (transparent border) */
        padding: 0 0.25em;
        border: 1px solid transparent;
        border-radius: 3px;
    }
    .todo-count:hover { opacity: 0.95; border-color: #3a3a4a; }
    .todo-count.open  { opacity: 1; border-color: #4a5a7a; background: #1a1a24; }

    /* the queue popover — absolutely placed so it OVERLAYS what follows rather than shoving the
       House list around while you read it (a diagnostic must not move its own subject).  The
       header is position:relative for this; z-index clears the sticky headers below. */
    .todo-pop {
        position: absolute;
        top: 100%;
        right: 0;
        z-index: 3000;
        min-width: min(50vw, 92vw);
        max-width: min(56rem, 92vw);
        max-height: 22rem;
        overflow: auto;
        background: #14141c;
        border: 1px solid #3a3a4a;
        border-radius: 4px;
        padding: 0.3rem 0.4rem;
        box-shadow: 0 4px 14px #0009;
        font-family: monospace;
        font-size: 0.72rem;
        text-align: left;
        cursor: default;
    }
    .todo-pop-hd {
        display: flex; justify-content: space-between; gap: 1rem;
        opacity: 0.65; padding-bottom: 0.25rem; margin-bottom: 0.25rem;
        border-bottom: 1px solid #2a2a36;
        position: sticky; top: -0.3rem; background: #14141c;
    }
    .todo-pop-x { cursor: pointer; }
    .todo-pop-x:hover { color: #d68a90; }
    /* method histogram — compact counts above the row list */
    .todo-hist {
        font-size: 0.65rem; opacity: 0.6;
        padding: 0.1rem 0 0.2rem;
        border-bottom: 1px solid #2a2a36;
        margin-bottom: 0.1rem;
    }
    .todo-row { display: flex; gap: 0.5rem; align-items: baseline; padding: 0.1rem 0; white-space: nowrap; }
    .todo-i     { opacity: 0.35; min-width: 1.5em; text-align: right; }
    /* push age — how long ago the item entered the queue; short-reads the bottleneck instantly */
    .todo-age   { opacity: 0.35; min-width: 3.5em; text-align: right; font-size: 0.85em; }
    .todo-elvis { color: #7fb3ff; }
    .todo-aw    { color: #b48ead; }
    /* the full %k:v line can be long — let IT scroll inside the row, never the page */
    .todo-keys  { opacity: 0.5; overflow: hidden; text-overflow: ellipsis; }
    .todo-empty { opacity: 0.4; padding: 0.2rem 0; }
    .todo-wedge {
        color: #f0c674; background: #2a2013; border: 1px solid #5a4a20;
        border-radius: 3px; padding: 0.2rem 0.35rem; margin-bottom: 0.25rem; white-space: normal;
    }
    .todo-why { opacity: 0.6; padding: 0.1rem 0 0.25rem; white-space: normal; }

    /* push log — compact push-rate history below the queue rows */
    .push-log-hd  { opacity: 0.3; font-size: 0.6rem; padding: 0.3rem 0 0.1rem; border-top: 1px solid #2a2a36; margin-top: 0.2rem; }
    .push-log-row { display: flex; gap: 0.4rem; align-items: baseline; padding: 0.05rem 0; white-space: nowrap; font-size: 0.68rem; }
    .push-log-age { opacity: 0.3; min-width: 4em; text-align: right; }
    .push-log-tag { color: #9ab8e0; }
    .push-log-tag.push-reqturn { color: #6a8f68; }  /* muted green tint = came from a req reply */
    .push-log-depth { opacity: 0.25; }

    .house-nav {
        flex: 0 0 auto;
        position: relative;
        width: 0.1rem;
        align-self: stretch;
    }
    .arrow {
        position: absolute;
        left: 0;
        right: 0;
        text-align: center;
        font-size: 1rem;
        line-height: 1;
        cursor: pointer;
        opacity: 0.55;
        user-select: none;
    }
    .arrow-up   { top: 0; }
    .arrow-down { bottom: 0; }
    .arrow:hover { opacity: 1; }
    .arrow.disabled { opacity: 0.15; cursor: default; }

    .kids-sep {
        font-size: 1.3em;
        opacity: 0.4;
        flex: 0 0 auto;
        align-self: center;
    }
    .house-kids {
        flex: 0 1 auto;
        min-width: 0;
        max-height: 1.5rem;
        display: flex;
        flex-direction: column;
        flex-wrap: wrap;
        align-content: center;
        gap: 0 0.75rem;
        overflow: hidden;
    }
    .kid {
        font-size: 0.85em;
        opacity: 0.7;
        cursor: pointer;
        white-space: nowrap;
        line-height: 1.1;
    }
    .kid:hover { opacity: 1; }

    .house-actions {
        flex: 1 1 auto;
        display: flex;
        justify-content: flex-end;
        min-width: 0;
    }
</style>