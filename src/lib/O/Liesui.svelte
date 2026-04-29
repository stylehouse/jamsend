<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Reactivity strategy
    // ───────────────────
    //   H.ave fires every think() tick (Housing reassigns the array whenever any
    //   enrolled particle bumps its version, which Lies does on every tick).
    //   The $effect runs on every such reassignment, but update_from_Lies is
    //   throttled so the actual $state writes (and thus DOM updates) happen at
    //   most once per interval — keeping focused inputs stable between ticks.
    //
    //   The Waft tree renders <WaftComp> components.  Components survive parent
    //   re-renders as long as their key (waft.sc.Waft) is stable.  All form state
    //   lives inside WaftComp.
    //
    //   doc_row is a snippet defined here (where loaded/pending context lives)
    //   and passed to WaftComp as a prop, keeping the rendering DRY.

    import type { House }   from "$lib/O/Housing.svelte"
    import type { TheC }    from "$lib/data/Stuff.svelte"
    import { throttle }     from "$lib/Y.svelte"
    import WaftComp         from "$lib/O/ui/Waft.svelte"
    import type { Snippet } from "svelte"

    let { H }: { H: House } = $props()

    // ── state ─────────────────────────────────────────────────────────
    let Lies:          TheC | undefined = $state()
    let loaded_docs:   TheC[]           = $state([])
    let errors:        TheC[]           = $state([])
    let all_wafts:     TheC[]           = $state([])
    let pending_paths: Set<string>      = $state(new Set())

    // Throttled updater — reads structural arrays from Lies's w at most
    // once per interval rather than on every think() tick.  This prevents
    // rapid $state writes from rebuilding DOM nodes and yanking focus.
    const update_from_Lies = throttle((found: TheC) => {
        loaded_docs   = found.o({ loaded_doc: 1 })     as TheC[]
        errors        = found.o({ compile_error: 1 })  as TheC[]
        all_wafts     = found.o({ Waft: 1 })           as TheC[]
        pending_paths = new Set(
            (found.o({ compile_pending: 1 }) as TheC[])
                .filter(p => !p.sc.done)
                .map(p => p.sc.path as string)
        )
    }, 66)

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        const found = ave.find((n: TheC) => n.sc.w === 'Lies') as TheC | undefined
        if (!found) return
        if (found !== Lies) {
            console.log(`🔪 Liesui: Lies found`)
            Lies = found
        }
        update_from_Lies(found)
    })

    // ── codetype ─────────────────────────────────────────────────────
    const SECOND_LEVEL_FILETYPES = ['svelte']
    function ls_codetype(path: string): string {
        const parts = path.split('.')
        if (parts.length <= 1) return ''
        const ext  = parts[parts.length - 1]
        const prev = parts.length >= 3 ? parts[parts.length - 2] : ''
        if (prev && SECOND_LEVEL_FILETYPES.includes(prev)) return `${prev}.${ext}`
        return ext
    }

    // ── header state ─────────────────────────────────────────────────
    let waft_input_open = $state(false)
    let new_waft_path   = $state('')

    function toggle_waft_input() {
        waft_input_open = !waft_input_open
        if (!waft_input_open) new_waft_path = ''
    }
    function submit_new_waft() {
        const path = new_waft_path.trim()
        if (!path) return
        H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
        new_waft_path = ''
        waft_input_open = false
    }
    function fire_now_waft() {
        H.i_elvisto('Lies/Lies', 'Lies_now_Waft', {})
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

    <!-- ── header ── -->
    <div class="ls-header">
        <span class="ls-title">🔪 Lies</span>
        <div class="ls-header-btns">
            <button class="ls-hdr-btn" class:ls-hdr-btn-active={waft_input_open}
                    onclick={toggle_waft_input}>+ Waft</button>
            <button class="ls-hdr-btn" onclick={fire_now_waft} title="Spawn hourly Look waft">+ Now</button>
        </div>
    </div>

    {#if waft_input_open}
        <div class="ls-waft-input-row">
            <input class="ls-input ls-waft-path-input" bind:value={new_waft_path}
                onkeydown={(ev) => { if (ev.key==='Enter') submit_new_waft(); if (ev.key==='Escape') toggle_waft_input() }}
                use:focus_on_mount />
            <button class="ls-add-btn" onclick={submit_new_waft} disabled={!new_waft_path.trim()}>+</button>
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

    <!-- ── loaded docs flat list ── -->
    {#if loaded_docs.length}
        <div class="ls-loaded-section">
            {#each loaded_docs as ld (ld.sc.path)}
                {@render doc_row(ld, null, null)}
            {/each}
        </div>
    {:else}
        <div class="ls-empty">no docs open</div>
    {/if}

    <!-- ── Waft tree ── -->
    {#if all_wafts.length}
        <div class="ls-waft-section">
            {#each all_wafts as waft (waft.sc.Waft)}
                <WaftComp {H} {waft} depth={0}
                    on_active={set_waft_active}
                    on_delete={delete_waft}
                    {doc_row} />
            {/each}
        </div>
    {/if}

    {/if}
</div>

<!-- ─────────────────────────────────────────────────────────────────────
     doc_row snippet — passed to WaftComp so Waft/Doc items use the same
     markup as the loaded-docs list.

     doc    — the Doc TheC from a Waft (has sc.new, sc.not_found, sc.path).
              For loaded-docs rows, pass the loaded_doc particle instead.
     waft   — parent Waft TheC (for delete/rename callbacks); null in flat list.
     on_del — deletion callback; null in flat list.

     pending and loaded status are derived from pending_paths / loaded_docs,
     which are captured from the Liesui closure and update via throttle.
──────────────────────────────────────────────────────────────────────── -->
{#snippet doc_row(doc: TheC, waft: TheC | null, on_del: ((doc: TheC) => void) | null)}
    {@const path     = doc.sc.path as string}
    {@const codetype = ls_codetype(path)}
    {@const is_new   = !!doc.sc.new}
    {@const show_nf  = !!doc.sc.not_found && !is_new}
    {@const is_pend  = pending_paths.has(path)}
    {@const is_loaded = loaded_docs.some(l => l.sc.path === path)}

    <div class="ls-doc-hdr">
        <span class="ls-doc-path">{path}</span>
        {#if codetype}<span class="ls-badge">{codetype}</span>{/if}
        {#if is_new}
            <span class="ls-flag ls-flag-new"
                title="created here, not yet written to disk — a spawning ghost">new</span>
        {:else if show_nf}
            <span class="ls-flag ls-flag-missing"
                title="file not found on disk — opened empty">?</span>
        {/if}
        {#if is_pend}
            <span class="ls-state-ind" title="writing…">⏳</span>
        {:else if !is_loaded && !is_new && !show_nf}
            <span class="ls-state-ind ls-dim" title="not yet loaded">…</span>
        {/if}
        <span class="ls-spacer"></span>
        {#if on_del && waft}
            <button class="ls-icon-btn ls-del-btn" title="remove"
                    onclick={() => on_del!(doc)}>×</button>
        {/if}
    </div>
{/snippet}

<script module>
    export function focus_on_mount(node: HTMLElement) {
        node.focus()
        if (node instanceof HTMLInputElement) node.select()
        return {}
    }
</script>

<style>
    .ls-ui {
        font-size: 0.83rem; padding: 0.5rem;
        border: 1px solid #444; border-radius: 4px;
        background: #111; color: #ccc; min-width: 360px;
    }
    .ls-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.3rem }
    .ls-title  { font-weight: bold; flex-shrink: 0 }
    .ls-header-btns { display: flex; gap: 0.25rem; margin-left: auto }
    .ls-hdr-btn {
        background: #1a1a28; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.74rem; padding: 0.15rem 0.4rem;
    }
    .ls-hdr-btn:hover     { background: #222238; color: #aac }
    .ls-hdr-btn-active    { background: #222238; border-color: #556; color: #aac }
    .ls-waft-input-row    { display: flex; gap: 0.25rem; margin-bottom: 0.3rem }
    .ls-waft-path-input   { flex: 1 }
    .ls-errors {
        background: #300; border: 1px solid #c44; border-radius: 3px;
        padding: 0.3rem 0.5rem; margin-bottom: 0.4rem;
        color: #f88; display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: flex-start;
    }
    .ls-dismiss   { margin-left: auto; background: none; border: none; color: #f88; cursor: pointer; font-size: 1rem; line-height: 1 }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }
    .ls-loaded-section { margin-bottom: 0.4rem }
    .ls-empty  { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-waft-section { margin-top: 0.4rem; border-top: 1px solid #222; padding-top: 0.3rem }

    /* doc_row shared styles (also used inside WaftComp via the snippet) */
    :global(.ls-doc-hdr) {
        display: flex; align-items: center; gap: 0.25rem;
        flex-wrap: wrap; min-height: 1.4rem;
        border-bottom: 1px solid #1c1c1c; padding: 0.1rem 0;
    }
    :global(.ls-doc-path)  { font-family: monospace; font-size: 0.76rem; color: #9ab; flex: 1 }
    :global(.ls-badge) {
        font-size: 0.68rem; background: #1c1c28;
        border: 1px solid #333; border-radius: 2px; padding: 0 0.2rem; color: #778; flex-shrink: 0;
    }
    :global(.ls-flag)        { font-size: 0.68rem; border-radius: 2px; padding: 0 0.2rem; flex-shrink: 0; cursor: default }
    :global(.ls-flag-new)    { background: #1a3a1a; color: #6a9; border: 1px solid #2a5a2a }
    :global(.ls-flag-missing){ background: #3a2010; color: #c84; border: 1px solid #5a3010 }
    :global(.ls-state-ind)   { font-size: 0.72rem; flex-shrink: 0 }
    :global(.ls-dim)         { color: #555 }
    :global(.ls-spacer)      { flex: 1 }
    :global(.ls-icon-btn) {
        background: none; border: none; color: #444;
        cursor: pointer; font-size: 0.8rem; line-height: 1;
        padding: 0 0.15rem; flex-shrink: 0;
    }
    :global(.ls-icon-btn:hover) { color: #aaa }
    :global(.ls-del-btn:hover)  { color: #f66 }

    .ls-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none;
    }
    .ls-input:focus { border-color: #446 }
    .ls-add-btn {
        background: #1a1a2a; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.4rem;
        white-space: nowrap; flex-shrink: 0;
    }
    .ls-add-btn:hover    { background: #222238; color: #aac }
    .ls-add-btn:disabled { opacity: 0.35; cursor: default }
</style>
