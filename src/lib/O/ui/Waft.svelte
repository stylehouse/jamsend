<script lang="ts">
    // Waft.svelte — one Waft item in the recursive Waft tree.
    //
    // Extracted from Liesui to be a stable component boundary:
    // Svelte reconciles {#each} items by component key (waft.sc.Waft) so
    // this component survives Liesui re-renders, keeping form state and
    // focused inputs stable across think() ticks.
    //
    // DocRow.svelte handles the doc header row reactively — it reads
    // doc.version and w.version directly so loaded/pending state stays live
    // even when Liesui is not re-rendering.

    import type { TheC }    from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { peel, depeel } from "$lib/Y.svelte"
    import DocRow           from "$lib/O/ui/DocRow.svelte"

    let { H, w, waft, depth = 0, on_active, on_delete, examining }: {
        H:         House
        w:         TheC          // Lies's w particle — passed to DocRow for live state
        waft:      TheC
        depth?:    number
        on_active: (waft: TheC) => void
        on_delete: (waft: TheC) => void
        examining?: TheC         // from Liesui; DocRow uses it to derive is_examining glow
    } = $props()

    // ── reactive reads — only waft.version ───────────────────────────
    let wkey       = $derived(waft.sc.Waft as string)
    let is_active  = $derived(!!waft.sc.active)
    let waft_docs  = $derived((() => { void waft.version; return waft.o({ Doc: 1 }) as TheC[] })())
    let sub_wafts  = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())

    // ── all form state is local ───────────────────────────────────────
    let renaming_waft = $state<string | null>(null)
    let adding_doc = $state<{ ghost: string, libsrc: string, free: string } | null>(null)

    let point_form_open: Record<string, boolean>       = $state({})
    let point_form_val:  Record<string, string>        = $state({})
    let point_form_sc:   Record<string, string>        = $state({})
    let point_edit_idx:  Record<string, number | null> = $state({})

    // ── focus refs (imperative, not use:action) ───────────────────────
    let doc_ghost_input: HTMLInputElement | null = $state(null)
    let point_val_inputs: Record<string, HTMLInputElement | null> = $state({})

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
            path = `src/lib/${adding_doc.libsrc.trim()}`
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
        if (!d.startsWith('Point') && d !== 'Point') throw `point_to_peel: 'Point' not first: ${d}`
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
        point_form_sc[dpath]  = Object.entries(sc)
            .filter(([k]) => k !== 'Point')
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
        setTimeout(() => point_val_inputs[dpath]?.focus(), 0)
    }

    function submit_point(doc: TheC) {
        const dpath  = doc.sc.path as string
        const val    = (point_form_val[dpath] ?? '').trim()
        const sc_str = (point_form_sc[dpath]  ?? '').trim()
        if (!val && !sc_str) return
        const sc = { Point: val === '' ? 1 : val, ...(sc_str ? peel(sc_str) : {}) }
        const pointsC = (doc.o({ Points: 1 })[0] as TheC | undefined) ?? doc.i({ Points: 1 })
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

    // ── Rename Waft ───────────────────────────────────────────────────
    //
    //   Fires e:Lies_rename_waft so Lies can persist a waft_rename_job before
    //   touching any wormhole files.  We do NOT mutate waft.sc.Waft here —
    //   Lies does that after writing the new snap successfully.
    //   Renaming a Waft is a move: Lies writes to the new snap path and leaves
    //   the old snap in place (no delete — user may have other references).
    function cancel_rename_waft() { renaming_waft = null }
    function commit_rename_waft() {
        const n = renaming_waft?.trim() ?? ''
        renaming_waft = null
        if (!n || n === wkey) return
        H.i_elvisto('Lies/Lies', 'Lies_rename_waft', { old_path: wkey, new_path: n })
    }

    // ── Rename Doc ────────────────────────────────────────────────────
    //
    //   Called by DocRow's on_rename.  Clears stale session flags, mutates
    //   doc.sc.path, bumps waft (triggers watch_c → Lies_sync_waft_docs which
    //   queues a fresh open_req for the new path), then fires e:Lies_rename_doc
    //   so Lies can drop the old open_req / loaded_doc.
    //
    //   If the doc was not_found, the rename lets Lies try to load the new
    //   path — the common case of fixing a typo or moving a file into place.
    function do_rename_doc(doc: TheC, old_path: string, new_path: string) {
        if (!new_path || new_path === old_path) return
        // Clear session flags before rename so DocRow shows the new path cleanly.
        // Lies will re-set not_found if the new path also can't be found.
        delete doc.sc.not_found
        delete doc.sc.new
        doc.sc.path = new_path
        waft.bump_version()   // triggers watch_c → Lies_sync_waft_docs → new open_req
        H.i_elvisto('Lies/Lies', 'Lies_rename_doc', { old_path, new_path, waft_path: wkey })
    }

    // ── Delete Doc ───────────────────────────────────────────────────
    function delete_doc(doc: TheC) {
        waft.drop(doc)
        waft.bump_version()
    }
</script>

<div class="ls-waft" style="margin-left: {depth * 14}px" class:ls-waft-active={is_active}>

    <!-- header -->
    <div class="ls-waft-hdr">
        {#if renaming_waft !== null}
            <!-- rename form: [rename] cancel, cursor placed at stem boundary -->
            <input class="ls-input ls-rename-input"
                value={renaming_waft}
                oninput={(ev) => renaming_waft = (ev.target as HTMLInputElement).value}
                onkeydown={(ev) => { if (ev.key==='Enter') commit_rename_waft(); if (ev.key==='Escape') cancel_rename_waft() }}
                use:place_cursor_at_stem />
            <button class="ls-add-btn ls-add-btn-sm" onclick={commit_rename_waft}
                    disabled={!renaming_waft?.trim() || renaming_waft.trim() === wkey}>rename</button>
            <button class="ls-cancel-btn" onclick={cancel_rename_waft}>cancel</button>
        {:else}
            <span class="ls-waft-key">{wkey}</span>
            <span class="ls-spacer"></span>
            <button class="ls-icon-btn ls-active-btn" class:ls-is-active={is_active}
                    title={is_active ? 'active' : 'set active'}
                    onclick={() => on_active(waft)}>{is_active ? '●' : '○'}</button>
            <button class="ls-icon-btn ls-adddoc-btn" title="add Doc"
                    onclick={toggle_add_doc}>+ Doc</button>
            <button class="ls-icon-btn" title="rename"
                    onclick={() => renaming_waft = wkey}>✎</button>
            <button class="ls-icon-btn ls-del-btn" title="delete"
                    onclick={() => on_delete(waft)}>×</button>
        {/if}
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
                <span class="ls-prefix-label">src/lib/</span>
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

    <!-- Doc list — keyed on path; key changes after rename so a fresh
         DocRow is mounted for the new path (old one commits rename first). -->
    {#each waft_docs as doc (doc.sc.path)}
        {@const dpath = doc.sc.path as string}
        {@const ptC   = doc.o({ Points: 1 })[0] as TheC | undefined}
        {@const pts   = (() => { void ptC?.version; return ptC ? ptC.o({ Point: 1 }) as TheC[] : [] })()}
        {@const pform = !!point_form_open[dpath]}

        <div class="ls-doc"
             class:ls-doc-new={!!doc.sc.new}
             class:ls-doc-missing={!!doc.sc.not_found && !doc.sc.new}>

            <!-- DocRow reads doc.version + w.version directly — stays live. -->
            <DocRow {H} {w} {doc} {waft} {examining}
                on_del={delete_doc}
                on_rename={(old_p, new_p) => do_rename_doc(doc, old_p, new_p)} />

            <!-- Points -->
            {#if pts.length}
                <div class="ls-points">
                    {#each pts as pt, idx (idx)}
                        <div class="ls-point">
                            {#if pform && point_edit_idx[dpath] === idx}
                                {@render point_input(dpath, doc, '✓')}
                            {:else}
                                <!-- clicking a Point label opens that doc and hints at the point to navigate to -->
                                <button class="ls-point-peel ls-point-open-btn"
                                        title="open {dpath} at this point"
                                        onclick={() => H.i_elvisto('Lang/Lang', 'Doc_open', { path: dpath, point: pt.sc.Point })}>
                                    {point_to_peel(pt)}
                                </button>
                                <button class="ls-icon-btn" title="edit"
                                        onclick={() => start_edit_point(dpath, idx, pt)}>✎</button>
                                <button class="ls-icon-btn ls-del-btn"
                                        onclick={() => delete_point(pt, ptC!)}>×</button>
                            {/if}
                        </div>
                    {/each}
                </div>
            {/if}

            <!-- +Point -->
            {#if pform && point_edit_idx[dpath] == null}
                {@render point_input(dpath, doc, '+')}
            {:else if !pform}
                <button class="ls-add-point-btn"
                        onclick={() => toggle_point_form(dpath)}>+ Point</button>
            {/if}

        </div>
    {/each}

    <!-- sub-Wafts (recursive) — pass w through so DocRow has live Lies state -->
    {#each sub_wafts as sw (sw.sc.Waft)}
        <svelte:self {H} {w} waft={sw} depth={depth + 1} {examining}
            {on_active} {on_delete} />
    {/each}

</div>

{#snippet point_input(dpath: string, doc: TheC, submit_label: string)}
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
        <button class="ls-add-btn ls-add-btn-sm"
                onclick={() => submit_point(doc)}>{submit_label}</button>
        <button class="ls-cancel-btn"
                onclick={() => { point_form_open[dpath]=false; point_edit_idx[dpath]=null }}>×</button>
    </div>
{/snippet}

<script module>
    // place_cursor_at_stem — positions cursor before the stem's first dot,
    // selecting just the stem portion so it can be edited or suffixed.
    // Imported by reference from DocRow but duplicated here to avoid cross-
    // component module imports which Svelte doesn't support cleanly.
    export function place_cursor_at_stem(node: HTMLInputElement) {
        node.focus()
        const val     = node.value
        const slash_i = val.lastIndexOf('/')
        const base    = slash_i >= 0 ? val.slice(slash_i + 1) : val
        const dot_i   = base.indexOf('.')
        const stem_end   = slash_i >= 0
            ? slash_i + 1 + (dot_i >= 0 ? dot_i : base.length)
            : (dot_i >= 0 ? dot_i : base.length)
        const stem_start = slash_i >= 0 ? slash_i + 1 : 0
        node.setSelectionRange(stem_start, stem_end)
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

    .ls-add-doc-form {
        margin-top: 0.2rem; background: #0e0e1a;
        border: 1px solid #2a2a40; border-radius: 3px;
        padding: 0.3rem 0.35rem; display: flex; flex-direction: column; gap: 0.18rem;
    }
    .ls-add-doc-row { display: flex; align-items: center; gap: 0.2rem }
    .ls-input-path  { flex: 1 }
    .ls-add-doc-actions { display: flex; gap: 0.3rem; margin-top: 0.1rem }

    .ls-doc {
        margin: 0.1rem 0 0.2rem 0.5rem;
        border-left: 2px solid #2a2a3a;
        padding-left: 0.35rem;
    }
    .ls-doc-new     { border-left-color: #3a5a3a }
    .ls-doc-missing { border-left-color: #5a3a2a; opacity: 0.8 }

    .ls-points { margin: 0.1rem 0 0.1rem 0.3rem }
    .ls-point  {
        display: flex; align-items: center; gap: 0.25rem;
        padding: 0.05rem 0; border-bottom: 1px solid #1c1c28; flex-wrap: wrap;
    }
    .ls-point-peel { font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1 }
    .ls-point-open-btn {
        background: none; border: none; cursor: pointer; text-align: left; padding: 0;
        font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1;
    }
    .ls-point-open-btn:hover { color: #d0b0f0; text-decoration: underline; }

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
    .ls-add-btn:hover  { background: #222238; color: #aac }
    .ls-add-btn-sm     { padding: 0.15rem 0.3rem }
    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover { color: #999 }

    /* Shared icon button styles — declared :global here so DocRow.svelte
       and any other child component can use these class names. */
    :global(.ls-icon-btn) {
        background: none; border: none; color: #444;
        cursor: pointer; font-size: 0.8rem; line-height: 1;
        padding: 0 0.15rem; flex-shrink: 0;
    }
    :global(.ls-icon-btn:hover) { color: #aaa }
    :global(.ls-del-btn:hover)  { color: #f66 }
</style>
