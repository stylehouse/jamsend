<script module lang="ts">
    // ONE spool open at a time, ACROSS every instance on the page (Otro headers + the guts sprawl
    //  headers share this) — they're diagnostic, they overlay what follows, and two at once is
    //   unreadable.  Module-scope $state so every instance reads|writes the same choice; keyed by
    //    the House's c.ip so it survives lists re-sorting.
    export const spool_open = $state({ ip: null as string | null })
</script>

<script lang="ts">
    // TodoSpool — the drain-queue badge + popover, EXTRACTED from Otro's house header (2026-08-30,
    //  owner: "did we get the ActionButton to trace the elvises? there's probably a flood of some
    //   type of them … lets have them on by default … only in 'show guts' mode") so the same
    //    flood-tracer rides every H heading in BigSoundland's sprawl, not just /Otro.
    //  Everything diagnostic in here deliberately does NOT ride the House's version or H.clear() —
    //   both stop under the very wedge this exists to show; own intervals only.
    import { untrack } from "svelte"
    import { keyser } from "$lib/data/Stuff.svelte"

    let { house, H }: { house: any, H: any } = $props()

    const open = $derived(spool_open.ip === house.c.ip)

    // elvis_label — the headline for one queued item.  Two shapes ride H.todo (see _push_todo):
    //  a PLAIN elvis (sc.elvis = the method name, sc.Aw = the A/w it targets) and a post_do BLOCK
    //   (sc.fn = a closure, sc.see = its label).  A fn-carrying e never enters beliefs() at all —
    //    it runs directly — so naming which kind it is matters when you're reading a stuck queue.
    const elvis_label = (e: any) => e?.sc?.fn ? `fn:${e.sc.see ?? '?'}` : (e?.sc?.elvis ?? '?')

    // Ages tick on their OWN interval, armed only while the popover is open — never the House's
    //  version, which STOPS under a wedge and would freeze the readout at the moment it matters.
    let pop_now = $state(0)
    $effect(() => {
        if (!open) return
        const iv = setInterval(() => pop_now = Date.now(), 500)
        return () => clearInterval(iv)
    })
    const age_s = (at: number) => { void pop_now; const s = Math.round((Date.now() - at) / 1000); return s < 1 ? 'just now' : `${s}s ago` }
    // the top House's beliefs mutex, live — held by ANY House's item, freezing them all.
    let wedge = $derived.by(() => { void pop_now; return open ? (H?.top_House?.() as any)?.mutex_held?.('beliefs') ?? null : null })

    // Throttled snapshot — refreshes every 2 s so items don't vanish while you're reading them.
    //  The LIVE count in the badge always shows truth; the rows show the last snap.  `untrack`
    //   breaks reactivity on house.todo so only the timer drives the rows.
    let todo_snap: any[] = $state([])
    let snap_at: number  = $state(0)
    $effect(() => {
        if (!open) { todo_snap = []; snap_at = 0; return }
        const refresh = () => {
            todo_snap = untrack(() => (house as any).todo.slice())
            snap_at = Date.now()
        }
        refresh()
        const iv = setInterval(refresh, 2000)
        return () => clearInterval(iv)
    })
    // push log — last entries from H._push_log, updated every 500ms with pop_now.  Non-reactive
    //  plain array on H; read under untrack so only the timer fires this, not every push.
    let push_log_snap: any[] = $state([])
    $effect(() => {
        void pop_now
        if (!open) { push_log_snap = []; return }
        push_log_snap = untrack(() => ((house as any)._push_log ?? []).slice(-60))
    })
</script>

<!-- the drain queue, and a way IN to it.  The count alone said "8" without ever saying eight of
     WHAT — click it for the standing elvises.  stopPropagation: headers this rides in often
      navigate on click, and inspecting a queue must not also scroll you away. -->
<span class="todo-count" class:open={open}
    title={house.todo.length
        ? `${house.todo.length} elvis${house.todo.length === 1 ? '' : 'es'} waiting to drain — click to see them`
        : 'todo drained'}
    onclick={(ev) => { ev.stopPropagation(); spool_open.ip = open ? null : house.c.ip }}
>{house.todo.length || (open ? '0' : '')}</span>

{#if open}
    <!-- Throttled snapshot (2 s refresh) so rows don't vanish mid-read.  The header always shows
         the LIVE count; rows are from the last snap.  Each row is the elvis's headline + keyser(e)
         — same as the _push_todo V.organise trace, so popup and console log read identically. -->
    <div class="todo-pop" role="dialog" aria-label="{house.name} todo queue">
        <div class="todo-pop-hd">
            <!-- live count is always fresh; snap age shows how stale the rows are -->
            <span>H:{house.name} · live:{house.todo.length} · snap:{todo_snap.length}{#if snap_at} ({age_s(snap_at)}){/if}{#if house.c.drain_at} · drained {age_s(house.c.drain_at)}{/if}</span>
            <span class="todo-pop-x" title="close" onclick={() => spool_open.ip = null}>✕</span>
        </div>
        <!-- THE WEDGE LINE.  Every House drains under the TOP House's one beliefs mutex and
             all_clear() awaits it, so a single `fn` that never settles freezes the whole machine —
             and the tab keeps LOOKING alive because the socket stamps ride off-think.  A standing
             queue with a fresh `last drained` is an ordinary backlog; a standing queue with a stale
             one and a holder named here is the wedge, and this line says which elvis sits on it. -->
        {#if wedge}
            <div class="todo-wedge" role="alert">⚠ beliefs mutex held {Math.round(wedge.ms / 1000)}s by <b>{wedge.who}</b> — no House can drain until it settles</div>
        {:else if house.todo.length && house.c.drain_why}
            <div class="todo-why">◍ not draining: {house.c.drain_why}</div>
        {/if}
        <!-- method histogram — compact count per unique elvis label, most common first: the
             "there's probably a flood of some type of them" line, answered in one row. -->
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
        <!-- push log window: entries appear at 1.5s old, drop off at 3s.  The lag keeps transient
             things (quick drain) out of the view; the 1.5s width shows the settled burst before it
             fully clears.  Answers "who is GENERATING all these think|rw_op items?" on an idle tab. -->
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

<style>
    .todo-count {
        font-size: 0.7em;
        opacity: 0.5;
        cursor: pointer;
        /* a hit area even at one digit — the resting look is unchanged (transparent border) */
        padding: 0 0.25em;
        border: 1px solid transparent;
        border-radius: 3px;
    }
    .todo-count:hover { opacity: 0.95; border-color: #3a3a4a; }
    .todo-count.open  { opacity: 1; border-color: #4a5a7a; background: #1a1a24; }

    /* the queue popover — absolutely placed so it OVERLAYS what follows rather than shoving the
       page around while you read it (a diagnostic must not move its own subject).  The host header
       must be position:relative|sticky for the anchor; z-index clears sticky headers below. */
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
        color: #c8ccd8;
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
    .todo-hist {
        font-size: 0.65rem; opacity: 0.6;
        padding: 0.1rem 0 0.2rem;
        border-bottom: 1px solid #2a2a36;
        margin-bottom: 0.1rem;
    }
    .todo-row { display: flex; gap: 0.5rem; align-items: baseline; padding: 0.1rem 0; white-space: nowrap; }
    .todo-i     { opacity: 0.35; min-width: 1.5em; text-align: right; }
    .todo-age   { opacity: 0.35; min-width: 3.5em; text-align: right; font-size: 0.85em; }
    .todo-elvis { color: #7fb3ff; }
    .todo-aw    { color: #b48ead; }
    .todo-keys  { opacity: 0.5; overflow: hidden; text-overflow: ellipsis; }
    .todo-empty { opacity: 0.4; padding: 0.2rem 0; }
    .todo-wedge {
        color: #f0c674; background: #2a2013; border: 1px solid #5a4a20;
        border-radius: 3px; padding: 0.2rem 0.35rem; margin-bottom: 0.25rem; white-space: normal;
    }
    .todo-why { opacity: 0.6; padding: 0.1rem 0 0.25rem; white-space: normal; }

    .push-log-hd  { opacity: 0.3; font-size: 0.6rem; padding: 0.3rem 0 0.1rem; border-top: 1px solid #2a2a36; margin-top: 0.2rem; }
    .push-log-row { display: flex; gap: 0.4rem; align-items: baseline; padding: 0.05rem 0; white-space: nowrap; font-size: 0.68rem; }
    .push-log-age { opacity: 0.3; min-width: 4em; text-align: right; }
    .push-log-tag { color: #9ab8e0; }
    .push-log-tag.push-reqturn { color: #6a8f68; }  /* muted green tint = came from a req reply */
    .push-log-depth { opacity: 0.25; }
</style>
