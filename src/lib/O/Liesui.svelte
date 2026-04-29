<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Lies'}.
    // Receives H (the root Mundo house).
    //
    // Reactivity strategy
    // ───────────────────
    //   LS (the Lies w particle) is found once from H.ave and cached in $state.
    //   The $effect that finds it does NOT subscribe to any particle versions —
    //   it only re-runs when H.ave (the array reference) is replaced.
    //
    //   loaded_docs, errors, all_wafts are $state arrays updated from the same
    //   $effect, avoiding $derived subscriptions to LS.version.  Without this,
    //   every think() tick that calls w.i({see:...}) would bump LS.version,
    //   re-derive those arrays, and rebuild DOM nodes — losing focused inputs.
    //
    //   The Waft tree is rendered via <WaftComp> components (Waft.svelte).
    //   Components survive parent re-renders as long as their key (waft.sc.Waft)
    //   doesn't change — Svelte reconciles in-place.  All form state lives inside
    //   WaftComp so it is never affected by Liesui re-renders.
    //
    // Layout
    // ──────
    //   [🔪 Lies]  [+ Waft] [+ Now]
    //              [____________] [+]   ← +Waft input when toggled
    //   loaded docs (flat — path, codetype, pending/loaded state)
    //   Waft** tree (WaftComp components)

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import WaftComp       from "$lib/O/ui/Waft.svelte"

    let { H }: { H: House } = $props()

    // ── reactive state — updated only from $effect ────────────────────
    // None of these subscribe to LS.version; the $effect re-runs only when
    // H.ave itself is reassigned (new particle enrolled or ave rebuilt).
    let LS:          TheC | undefined    = $state()
    let loaded_docs: TheC[]              = $state([])
    let errors:      TheC[]              = $state([])
    let all_wafts:   TheC[]              = $state([])

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        const found = ave.find((n: TheC) => n.sc.w === 'Lies') as TheC | undefined
        if (found !== LS) {
            console.log(`🔪 Liesui: LS ${LS ? 'changed' : 'found'}`)
            LS = found
        }
        if (!found) return
        // Read structural lists — no version subscription.
        // These update when H.ave changes; fine-grained version tracking
        // lives inside WaftComp and the Lies loop, not here.
        loaded_docs = found.o({ loaded_doc: 1 }) as TheC[]
        errors      = found.o({ compile_error: 1 }) as TheC[]
        all_wafts   = found.o({ Waft: 1 }) as TheC[]
    })


    // pending: compile writes in flight — keyed by path for render_doc_row
    // Also from $effect so it doesn't subscribe independently to LS.version.
    let pending_paths: Set<string> = $state(new Set())
    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        const found = ave.find((n: TheC) => n.sc.w === 'Lies') as TheC | undefined
        if (!found) return
        const ps = (found.o({ compile_pending: 1 }) as TheC[])
            .filter(p => !p.sc.done)
            .map(p => p.sc.path as string)
        pending_paths = new Set(ps)
        console.log("The pending path")
    })

    // ── codetype (same as in Waft.svelte) ────────────────────────────
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

    // ── +Waft ─────────────────────────────────────────────────────────
    function toggle_waft_input() {
        waft_input_open = !waft_input_open
        if (!waft_input_open) new_waft_path = ''
    }
    function submit_new_waft() {
        const path = new_waft_path.trim()
        if (!path) return
        H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
        new_waft_path   = ''
        waft_input_open = false
    }

    // ── +Now ─────────────────────────────────────────────────────────
    function fire_now_waft() {
        H.i_elvisto('Lies/Lies', 'Lies_now_Waft', {})
    }

    // ── active toggle (needs LS to clear siblings) ────────────────────
    function set_waft_active(waft: TheC) {
        if (!LS) return
        for (const w of LS.o({ Waft: 1 }) as TheC[]) delete w.sc.active
        waft.sc.active = 1
        LS.bump_version()
    }

    // ── delete waft (needs LS) ────────────────────────────────────────
    function delete_waft(waft: TheC) {
        if (!LS) return
        LS.drop(waft)
        LS.bump_version()
    }

    // ── errors ───────────────────────────────────────────────────────
    function dismiss_errors() {
        if (!LS) return
        for (const e of errors) LS.drop(e)
        LS.bump_version()
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

    {#if !LS}
        <div class="ls-empty">waiting for Lies…</div>
    {:else}

    <!-- ── compile errors ── -->
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
    <input />
    {#if loaded_docs.length}
        <div class="ls-loaded-section">
            {#each loaded_docs as ld (ld.sc.path)}
                {@const path    = ld.sc.path as string}
                {@const ct      = ls_codetype(path)}
                {@const pend    = pending_paths.has(path)}
                {@const not_yet = !pend && !ld.sc.gen_path && !(ld.sc.path)}
                <div class="ls-loaded-row">
                    <span class="ls-doc-path">{path}</span>
                    {#if ct}<span class="ls-badge">{ct}</span>{/if}
                    {#if pend}
                        <span class="ls-state-ind" title="writing…">⏳</span>
                    {:else}
                        <span class="ls-state-ind ls-dim" title="not yet loaded">…</span>
                    {/if}
                </div>
            {/each}
        </div>
    {:else}
        <div class="ls-empty">no docs open</div>
    {/if}

    <!-- ── Waft tree (WaftComp — stable component boundary) ── -->
    <input placeholder="outside" />
    {#if all_wafts.length}
        <input />
        <div class="ls-waft-section">
            {#each all_wafts as waft (waft.sc.Waft)}
                <WaftComp {H} {waft} depth={0}
                    on_active={set_waft_active}
                    on_delete={delete_waft} />
            {/each}
        </div>
    {/if}

    {/if}
</div>

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
    .ls-dismiss  { margin-left: auto; background: none; border: none; color: #f88; cursor: pointer; font-size: 1rem; line-height: 1 }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }

    .ls-loaded-section { margin-bottom: 0.4rem }
    .ls-loaded-row {
        display: flex; align-items: center; gap: 0.25rem;
        border-bottom: 1px solid #1c1c1c; padding: 0.1rem 0; flex-wrap: wrap;
    }
    .ls-empty     { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-doc-path  { font-family: monospace; font-size: 0.76rem; color: #9ab; flex: 1 }
    .ls-badge {
        font-size: 0.68rem; background: #1c1c28;
        border: 1px solid #333; border-radius: 2px; padding: 0 0.2rem; color: #778; flex-shrink: 0;
    }
    .ls-state-ind { font-size: 0.72rem; flex-shrink: 0 }
    .ls-dim       { color: #555 }

    .ls-waft-section { margin-top: 0.4rem; border-top: 1px solid #222; padding-top: 0.3rem }

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
