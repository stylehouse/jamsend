<script lang="ts">
    // Waft.svelte — one Waft item in the recursive Waft tree.
    //
    // Extracted from Liesui to avoid the LS.version subscription cascade:
    // Liesui re-renders when LS (=w) bumps on every think() tick, which was
    // destroying and recreating snippet DOM including focused inputs.
    // As a component keyed by waft.sc.Waft, Svelte reconciles in-place and
    // only re-renders this component when its own $derived reads change.
    //
    // Props
    // ─────
    //   waft       — the Waft TheC particle; subscribe via $derived for CRUD.
    //   H          — root House, for i_elvisto.
    //   depth      — indent level (recursive).
    //   on_active  — callback to set active (needs to clear siblings in LS).
    //   on_delete  — callback to drop this waft from LS.
    //
    // Doc status (pending/loaded) is NOT shown in the Waft tree — it lives in
    // the flat loaded-docs list in Liesui.  The Waft tree shows only the
    // persistent registry (Doc particles) and their flags (new, not_found).

    import type { TheC }  from "$lib/data/Stuff.svelte"
    import type { House } from "$lib/O/Housing.svelte"
    import { peel, depeel } from "$lib/Y.svelte"

    let { H, waft, depth = 0, on_active, on_delete }: {
        H:         House
        waft:      TheC
        depth?:    number
        on_active: (waft: TheC) => void
        on_delete: (waft: TheC) => void
    } = $props()

    // ── reactive reads — only subscribe to waft.version ──────────────
    let wkey      = $derived(waft.sc.Waft as string)
    let is_active = $derived(!!waft.sc.active)
    let waft_docs = $derived((() => { void waft.version; return waft.o({ Doc: 1 }) as TheC[] })())
    let sub_wafts = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())

    // ── form state (all local — not shared up) ────────────────────────
    let renaming_waft    = $state<string | null>(null)
    let renaming_doc:    Record<string, string | null>   = $state({})
    let adding_doc       = $state<{ ghost: string, libsrc: string, free: string } | null>(null)
    let point_form_open: Record<string, boolean>       = $state({})
    let point_form_val:  Record<string, string>        = $state({})
    let point_form_sc:   Record<string, string>        = $state({})
    let point_edit_idx:  Record<string, number | null> = $state({})

    // ── focus refs (imperative, not use:action) ───────────────────────
    let doc_ghost_input: HTMLInputElement | null = $state(null)
    let point_val_inputs: Record<string, HTMLInputElement | null> = $state({})

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

    // ── +Doc ─────────────────────────────────────────────────────────
    function toggle_add_doc() {
        adding_doc = adding_doc ? null : { ghost: '', libsrc: '', free: '' }
        if (adding_doc) setTimeout(() => doc_ghost_input?.focus(), 0)
    }
    function submit_add_doc() {
        if (!adding_doc) return
        let path = ''
        if (adding_doc.ghost.trim()) {
            let g = adding_doc.ghost.trim()
            if (!g.includes('.')) g += '.g'
            path = `Ghost/${g}`
        } else if (adding_doc.libsrc.trim()) {
            path = `lib/src/${adding_doc.libsrc.trim()}`
        } else if (adding_doc.free.trim()) {
            path = adding_doc.free.trim()
        }
        if (!path) return
        const doc = waft.oai({ Doc: 1, path })
        doc.sc.new = 1
        waft.bump_version()
        adding_doc = null
    }

    // ── Points ───────────────────────────────────────────────────────
    function point_to_peel(pt: TheC): string {
        const sc = pt.sc as Record<string, any>
        for (const [, v] of Object.entries(sc)) {
            if (v === null || typeof v === 'object') throw `point_to_peel: non-scalar in Point sc`
        }
        const d = depeel(sc)
        if (!d.startsWith('Point,') && d !== 'Point') throw `point_to_peel: 'Point' not first: ${d}`
        return d
    }

    function toggle_point_form(dpath: string) {
        const was = point_form_open[dpath]
        point_form_open[dpath] = !was
        point_edit_idx[dpath]  = null
        if (!was) {
            point_form_val[dpath] = ''
            point_form_sc[dpath]  = ''
            setTimeout(() => point_val_inputs[dpath]?.focus(), 0)
        }
    }

    function start_edit_point(dpath: string, idx: number, pt: TheC) {
        point_form_open[dpath] = true
        point_edit_idx[dpath]  = idx
        const sc   = pt.sc as Record<string, any>
        const pval = sc.Point
        point_form_val[dpath] = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        const extras = Object.entries(sc)
            .filter(([k]) => k !== 'Point')
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
        point_form_sc[dpath]  = extras
        setTimeout(() => point_val_inputs[dpath]?.focus(), 0)
    }

    function submit_point(doc: TheC) {
        const dpath  = doc.sc.path as string
        const val    = (point_form_val[dpath] ?? '').trim()
        const sc_str = (point_form_sc[dpath]  ?? '').trim()
        if (!val && !sc_str) return
        const point_val: any = val === '' ? 1 : val
        const sc = { Point: point_val, ...(sc_str ? peel(sc_str) : {}) }
        const pointsC  = (doc.o({ Points: 1 })[0] as TheC | undefined) ?? doc.i({ Points: 1 })
        const edit_idx = point_edit_idx[dpath] ?? null
        const all_pts  = pointsC.o({ Point: 1 }) as TheC[]
        if (edit_idx !== null && all_pts[edit_idx]) {
            Object.keys(all_pts[edit_idx].sc).forEach(k => delete all_pts[edit_idx].sc[k])
            Object.assign(all_pts[edit_idx].sc, sc)
        } else {
            pointsC.oai(sc)
        }
        pointsC.bump_version()
        waft.bump_version()
        point_form_open[dpath] = false
        point_edit_idx[dpath]  = null
        point_form_val[dpath]  = ''
        point_form_sc[dpath]   = ''
    }

    function delete_point(pt: TheC, pointsC: TheC) {
        pointsC.drop(pt)
        pointsC.bump_version()
        waft.bump_version()
    }

    // ── Rename ───────────────────────────────────────────────────────
    function commit_rename_waft() {
        const newPath = renaming_waft?.trim() ?? ''
        renaming_waft = null
        if (!newPath || newPath === wkey) return
        waft.sc.Waft = newPath
    }

    function commit_rename_doc(doc: TheC) {
        const old     = doc.sc.path as string
        const newPath = renaming_doc[old]?.trim() ?? ''
        renaming_doc[old] = null
        if (!newPath || newPath === old) return
        doc.sc.path = newPath
        waft.bump_version()
    }

    // ── Delete ───────────────────────────────────────────────────────
    function delete_doc(doc: TheC) {
        waft.drop(doc)
        waft.bump_version()
    }
</script>

<div class="ls-waft" style="margin-left: {depth * 14}px" class:ls-waft-active={is_active}>

    <!-- Waft header: [key] [spacer] [●/○] [+ Doc] [✎] [×] -->
    <div class="ls-waft-hdr">
        {#if renaming_waft !== null}
            <input class="ls-input ls-rename-input"
                value={renaming_waft}
                oninput={(ev) => renaming_waft = (ev.target as HTMLInputElement).value}
                onkeydown={(ev) => { if (ev.key==='Enter') commit_rename_waft(); if (ev.key==='Escape') renaming_waft=null }}
                use:focus_on_mount />
        {:else}
            <span class="ls-waft-key">{wkey}</span>
        {/if}
        <span class="ls-spacer"></span>
        <button class="ls-icon-btn ls-active-btn" class:ls-is-active={is_active}
                title={is_active ? 'active' : 'set active'}
                onclick={() => on_active(waft)}>{is_active ? '●' : '○'}</button>
        <button class="ls-icon-btn ls-adddoc-btn" title="add Doc"
                onclick={toggle_add_doc}>+ Doc</button>
        <button class="ls-icon-btn" title="edit name"
                onclick={() => renaming_waft = wkey}>✎</button>
        <button class="ls-icon-btn ls-del-btn" title="delete"
                onclick={() => on_delete(waft)}>×</button>
    </div>

    {#if waft_mungs.length}
        <div class="ls-mung-errors">
            {#each waft_mungs as m}<div class="ls-error-msg">⛔ {m.sc.msg}</div>{/each}
        </div>
    {/if}

    <!-- +Doc form -->
    {#if adding_doc}
        <div class="ls-add-doc-form">
            <div class="ls-add-doc-row">
                <span class="ls-prefix-label">Ghost/</span>
                <input class="ls-input ls-input-path" bind:value={adding_doc.ghost}
                    bind:this={doc_ghost_input}
                    onkeydown={(ev) => ev.key==='Enter' && submit_add_doc()} />
                <span class="ls-prefix-dim">.g</span>
            </div>
            <div class="ls-add-doc-row">
                <span class="ls-prefix-label">lib/src/</span>
                <input class="ls-input ls-input-path" bind:value={adding_doc.libsrc}
                    onkeydown={(ev) => ev.key==='Enter' && submit_add_doc()} />
            </div>
            <div class="ls-add-doc-row">
                <span class="ls-prefix-dim">path:</span>
                <input class="ls-input ls-input-path" bind:value={adding_doc.free}
                    onkeydown={(ev) => ev.key==='Enter' && submit_add_doc()} />
            </div>
            <div class="ls-add-doc-actions">
                <button class="ls-add-btn" onclick={submit_add_doc}>Add Doc</button>
                <button class="ls-cancel-btn" onclick={() => adding_doc=null}>cancel</button>
            </div>
        </div>
    {/if}

    <!-- Doc list -->
    {#each waft_docs as doc (doc.sc.path)}
        {@const dpath    = doc.sc.path as string}
        {@const codetype = ls_codetype(dpath)}
        {@const is_new   = !!doc.sc.new}
        {@const show_nf  = !!doc.sc.not_found && !is_new}
        {@const ptC      = doc.o({ Points: 1 })[0] as TheC | undefined}
        {@const pts      = (() => { void ptC?.version; return ptC ? ptC.o({ Point: 1 }) as TheC[] : [] })()}
        {@const pform    = !!point_form_open[dpath]}

        <div class="ls-doc" class:ls-doc-new={is_new} class:ls-doc-missing={show_nf}>

            <!-- doc header row -->
            <div class="ls-doc-hdr">
                {#if renaming_doc[dpath] !== null && renaming_doc[dpath] !== undefined}
                    <input class="ls-input ls-rename-input"
                        value={renaming_doc[dpath]}
                        oninput={(ev) => renaming_doc[dpath] = (ev.target as HTMLInputElement).value}
                        onkeydown={(ev) => { if (ev.key==='Enter') commit_rename_doc(doc); if (ev.key==='Escape') renaming_doc[dpath]=null }}
                        use:focus_on_mount />
                {:else}
                    <span class="ls-doc-path">{dpath}</span>
                {/if}
                {#if codetype}<span class="ls-badge">{codetype}</span>{/if}
                {#if is_new}
                    <span class="ls-flag ls-flag-new" title="created here, not yet written to disk — a spawning ghost">new</span>
                {:else if show_nf}
                    <span class="ls-flag ls-flag-missing" title="file not found on disk — opened empty">?</span>
                {/if}
                <span class="ls-spacer"></span>
                <button class="ls-icon-btn" title="edit path"
                        onclick={() => renaming_doc[dpath] = dpath}>✎</button>
                <button class="ls-icon-btn ls-del-btn" title="remove"
                        onclick={() => delete_doc(doc)}>×</button>
            </div>

            <!-- Points -->
            {#if pts.length}
                <div class="ls-points">
                    {#each pts as pt, idx (idx)}
                        <div class="ls-point">
                            {#if pform && point_edit_idx[dpath] === idx}
                                <span class="ls-prefix-label">Point:</span>
                                <input class="ls-input ls-point-val-input" placeholder="fuzzyName"
                                    title="Point's value — empty defaults to 1 when extra sc is given"
                                    bind:value={point_form_val[dpath]}
                                    bind:this={point_val_inputs[dpath]}
                                    onkeydown={(ev) => { if (ev.key==='Enter') submit_point(doc); if (ev.key==='Escape') { point_form_open[dpath]=false; point_edit_idx[dpath]=null } }} />
                                <span class="ls-prefix-dim">,</span>
                                <input class="ls-input ls-point-sc-input" placeholder="method:Name,call"
                                    title="extra peelable sc"
                                    bind:value={point_form_sc[dpath]}
                                    onkeydown={(ev) => { if (ev.key==='Enter') submit_point(doc); if (ev.key==='Escape') { point_form_open[dpath]=false; point_edit_idx[dpath]=null } }} />
                                <button class="ls-add-btn ls-add-btn-sm" onclick={() => submit_point(doc)}>✓</button>
                                <button class="ls-cancel-btn" onclick={() => { point_form_open[dpath]=false; point_edit_idx[dpath]=null }}>×</button>
                            {:else}
                                <span class="ls-point-peel">{point_to_peel(pt)}</span>
                                <button class="ls-icon-btn" title="edit"
                                        onclick={() => start_edit_point(dpath, idx, pt)}>✎</button>
                                <button class="ls-icon-btn ls-del-btn" title="remove"
                                        onclick={() => delete_point(pt, ptC!)}>×</button>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}

            <!-- +Point -->
            {#if pform && point_edit_idx[dpath] == null}
                <div class="ls-point-form">
                    <span class="ls-prefix-label">Point:</span>
                    <input class="ls-input ls-point-val-input" placeholder="fuzzyName"
                        title="Point's value — empty defaults to 1 when extra sc is given"
                        bind:value={point_form_val[dpath]}
                        bind:this={point_val_inputs[dpath]}
                        onkeydown={(ev) => { if (ev.key==='Enter') submit_point(doc); if (ev.key==='Escape') { point_form_open[dpath]=false; point_edit_idx[dpath]=null } }} />
                    <span class="ls-prefix-dim">,</span>
                    <input class="ls-input ls-point-sc-input" placeholder="method:Name,call"
                        title="extra peelable sc"
                        bind:value={point_form_sc[dpath]}
                        onkeydown={(ev) => { if (ev.key==='Enter') submit_point(doc); if (ev.key==='Escape') { point_form_open[dpath]=false; point_edit_idx[dpath]=null } }} />
                    <button class="ls-add-btn ls-add-btn-sm" onclick={() => submit_point(doc)}>+</button>
                    <button class="ls-cancel-btn" onclick={() => { point_form_open[dpath]=false; point_edit_idx[dpath]=null }}>×</button>
                </div>
            {:else if !pform}
                <button class="ls-add-point-btn" onclick={() => toggle_point_form(dpath)}>+ Point</button>
            {/if}

        </div>
    {/each}

    <!-- sub-Wafts (recursive component) -->
    {#each sub_wafts as sw (sw.sc.Waft)}
        <svelte:self H={H} waft={sw} depth={depth + 1} {on_active} {on_delete} />
    {/each}

</div>

<script module>
    // Rename inputs are truly once-mounted (inside {#if renaming ...}).
    // focus_on_mount is safe here — these inputs only exist while renaming is open.
    export function focus_on_mount(node: HTMLElement) {
        node.focus()
        if (node instanceof HTMLInputElement) node.select()
        return {}
    }
</script>

<style>
    .ls-waft {
        background: #13131d; border: 1px solid #252535;
        border-radius: 3px; padding: 0.3rem 0.4rem; margin-bottom: 0.25rem;
        font-size: 0.83rem; color: #ccc;
    }
    .ls-waft-active { border-color: #446 }
    .ls-waft-hdr {
        display: flex; align-items: center; gap: 0.25rem;
        min-height: 1.4rem; margin-bottom: 0.2rem;
    }
    .ls-waft-key { font-family: monospace; font-size: 0.76rem; color: #8ab; font-weight: bold }
    .ls-spacer   { flex: 1 }
    .ls-active-btn              { color: #446; font-size: 0.7rem }
    .ls-active-btn.ls-is-active { color: #88c }
    .ls-active-btn:hover        { color: #88c }
    .ls-adddoc-btn              { font-size: 0.72rem; color: #558; padding: 0 0.2rem }
    .ls-adddoc-btn:hover        { color: #88a }
    .ls-mung-errors { margin: 0.15rem 0 }
    .ls-error-msg   { font-size: 0.76rem; font-family: monospace; color: #f88 }

    /* +Doc form */
    .ls-add-doc-form {
        margin-top: 0.2rem; background: #0e0e1a;
        border: 1px solid #2a2a40; border-radius: 3px;
        padding: 0.3rem 0.35rem; display: flex; flex-direction: column; gap: 0.18rem;
    }
    .ls-add-doc-row { display: flex; align-items: center; gap: 0.2rem }
    .ls-input-path  { flex: 1 }
    .ls-add-doc-actions { display: flex; gap: 0.3rem; margin-top: 0.1rem }

    /* Doc rows */
    .ls-doc {
        margin: 0.1rem 0 0.2rem 0.5rem;
        border-left: 2px solid #2a2a3a;
        padding-left: 0.35rem;
    }
    .ls-doc-new     { border-left-color: #3a5a3a }
    .ls-doc-missing { border-left-color: #5a3a2a; opacity: 0.8 }
    .ls-doc-hdr {
        display: flex; align-items: center; gap: 0.25rem;
        flex-wrap: wrap; min-height: 1.4rem;
    }
    .ls-doc-path { font-family: monospace; font-size: 0.76rem; color: #9ab }
    .ls-badge {
        font-size: 0.68rem; background: #1c1c28;
        border: 1px solid #333; border-radius: 2px; padding: 0 0.2rem; color: #778; flex-shrink: 0;
    }
    .ls-flag { font-size: 0.68rem; border-radius: 2px; padding: 0 0.2rem; flex-shrink: 0; cursor: default }
    .ls-flag-new     { background: #1a3a1a; color: #6a9; border: 1px solid #2a5a2a }
    .ls-flag-missing { background: #3a2010; color: #c84; border: 1px solid #5a3010 }

    /* Points */
    .ls-points { margin: 0.1rem 0 0.1rem 0.3rem }
    .ls-point  {
        display: flex; align-items: center; gap: 0.25rem;
        padding: 0.05rem 0; border-bottom: 1px solid #1c1c28; flex-wrap: wrap;
    }
    .ls-point-peel { font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1 }
    .ls-add-point-btn {
        background: none; border: none; color: #448; cursor: pointer;
        font-size: 0.74rem; font-family: monospace; padding: 0.05rem 0; text-align: left;
    }
    .ls-add-point-btn:hover { color: #88a }
    .ls-point-form {
        display: flex; align-items: center; gap: 0.2rem; margin-top: 0.15rem; flex-wrap: wrap;
    }
    .ls-point-val-input { width: 9rem }
    .ls-point-sc-input  { flex: 1; min-width: 5rem }

    /* shared controls */
    .ls-prefix-label { font-family: monospace; font-size: 0.74rem; color: #556; flex-shrink: 0; white-space: nowrap }
    .ls-prefix-dim   { font-family: monospace; font-size: 0.74rem; color: #444; flex-shrink: 0 }
    .ls-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none;
    }
    .ls-input:focus  { border-color: #446 }
    .ls-rename-input { flex: 1; min-width: 6rem }
    .ls-add-btn {
        background: #1a1a2a; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.4rem;
        white-space: nowrap; flex-shrink: 0;
    }
    .ls-add-btn:hover    { background: #222238; color: #aac }
    .ls-add-btn-sm       { padding: 0.15rem 0.3rem }
    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover { color: #999 }
    .ls-icon-btn {
        background: none; border: none; color: #444;
        cursor: pointer; font-size: 0.8rem; line-height: 1;
        padding: 0 0.15rem; flex-shrink: 0;
    }
    .ls-icon-btn:hover { color: #aaa }
    .ls-del-btn:hover  { color: #f66 }
</style>
