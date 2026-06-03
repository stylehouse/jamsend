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
    import EncodingSplatter from "$lib/O/ui/EncodingSplatter.svelte"
    import PeelInput        from "$lib/O/ui/PeelInput.svelte"

    let { H, w, waft, depth = 0, on_active, on_delete, examining }: {
        H:         House
        w:         TheC          // Lies's w particle — passed to DocRow for live state
        waft:      TheC
        depth?:    number
        on_active: (waft: TheC) => void
        on_delete: (waft: TheC) => void
        examining?: TheC         // from Liesui; DocRow uses it to derive is_examining glow
    } = $props()

    // ── reactive reads ────────────────────────────────────────────────
    let wkey       = $derived(waft.sc.Waft as string)
    let is_active  = $derived(!!waft.sc.active)
    let waft_docs  = $derived((() => { void waft.version; return waft.o({ Doc: 1 }) as TheC[] })())
    let waft_whats = $derived((() => { void waft.version; return waft.o({ What: 1 }) as TheC[] })())
    let sub_wafts  = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())

    // ── form state — all keyed by stable string ───────────────────────
    //
    //   Waft rename
    let renaming_waft = $state<string | null>(null)

    //   +Doc
    let adding_doc = $state<{ ghost: string, libsrc: string, free: string } | null>(null)

    //   Point forms — keyed by doc path string (same as DocRow key)
    let point_form_open: Record<string, boolean>       = $state({})
    let point_form_val:  Record<string, string>        = $state({})
    let point_form_sc:   Record<string, string>        = $state({})
    let point_edit_idx:  Record<string, number | null> = $state({})

    //   What forms — keyed by What label string (same as wlabel())
    //     what_renaming:  null = not renaming, string = draft new label
    //     what_pform:     whether the Point add/edit form is open
    //     what_pedit_idx: null = adding new, number = editing existing Point at that index
    let what_renaming:  Record<string, string | null>  = $state({})
    let what_pform:     Record<string, boolean>        = $state({})
    let what_pform_val: Record<string, string>         = $state({})
    let what_pform_sc:  Record<string, string>         = $state({})
    let what_pedit_idx: Record<string, number | null>  = $state({})

    //   Seen:origin clone editing — keyed by clone spec string
    let clone_edit_open: Record<string, boolean> = $state({})
    let clone_edit_val:  Record<string, string>  = $state({})
    let clone_edit_sc:   Record<string, string>  = $state({})

    //   +Doc ghost input ref — only external ref needed; PeelInput focuses itself
    let doc_ghost_input: HTMLInputElement | null = $state(null)

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

    function open_point_form(key: string) {
        point_form_open[key] = true
        point_edit_idx[key]  = null
        point_form_val[key]  = ''
        point_form_sc[key]   = ''
    }

    function start_edit_point(key: string, idx: number, pt: TheC) {
        point_form_open[key] = true
        point_edit_idx[key]  = idx
        const sc   = pt.sc as Record<string, any>
        const pval = sc.Point
        point_form_val[key] = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        point_form_sc[key]  = Object.entries(sc)
            .filter(([k]) => k !== 'Point')
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
    }

    function cancel_point_form(key: string) {
        point_form_open[key] = false
        point_edit_idx[key]  = null
    }

    function submit_point(doc: TheC, key: string) {
        const val    = (point_form_val[key] ?? '').trim()
        const sc_str = (point_form_sc[key]  ?? '').trim()
        if (!val && !sc_str) return
        // Points live directly on doc — no Points:1 container
        const sc = { Point: val === '' ? 1 : val, ...(sc_str ? peel(sc_str) : {}) }
        const edit_idx = point_edit_idx[key] ?? null
        const all_pts  = doc.o({ Point: 1 }) as TheC[]
        if (edit_idx !== null && all_pts[edit_idx]) {
            Object.keys(all_pts[edit_idx].sc).forEach(k => delete all_pts[edit_idx].sc[k])
            Object.assign(all_pts[edit_idx].sc, sc)
        } else {
            doc.oai(sc)
        }
        doc.bump_version()
        waft.bump_version()
        cancel_point_form(key)
    }

    function delete_point(pt: TheC, doc: TheC) {
        doc.drop(pt)
        doc.bump_version()
        waft.bump_version()
    }

    // ── What rename ──────────────────────────────────────────────────
    //
    //   Whats carry sc.label as their visible name, keyed by that label in
    //   the what_* Records.  Commit clears the old key so no stale entry lingers.
    function wlabel(what: TheC): string {
        return String(what.sc.label ?? '·')
    }

    function start_rename_what(what: TheC) {
        what_renaming[wlabel(what)] = wlabel(what)
    }
    function cancel_rename_what(what: TheC) {
        what_renaming[wlabel(what)] = null
    }
    function commit_rename_what(what: TheC) {
        const old_k = wlabel(what)
        const n = (what_renaming[old_k] ?? '').trim()
        what_renaming[old_k] = null
        if (!n) return
        what.sc.label = n
        waft.bump_version()
    }

    // ── What-level Points ────────────────────────────────────────────
    //
    //   Points that sit directly on a %What (time-slice style — no Doc container).
    //   The Point add/edit form lives at the end of the What header row via PeelInput.
    function open_what_pform(what: TheC) {
        const k = wlabel(what)
        what_pform[k]     = true
        what_pedit_idx[k] = null
        what_pform_val[k] = ''
        what_pform_sc[k]  = ''
    }

    function start_edit_what_point(what: TheC, idx: number, pt: TheC) {
        const k    = wlabel(what)
        what_pform[k]     = true
        what_pedit_idx[k] = idx
        const sc   = pt.sc as Record<string, any>
        const pval = sc.Point
        what_pform_val[k] = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        what_pform_sc[k]  = Object.entries(sc)
            .filter(([k2]) => k2 !== 'Point')
            .map(([k2, v]) => v === 1 ? k2 : `${k2}:${v}`)
            .join(',')
    }

    function cancel_what_pform(what: TheC) {
        const k = wlabel(what)
        what_pform[k]     = false
        what_pedit_idx[k] = null
    }

    function submit_what_point(what: TheC) {
        const k      = wlabel(what)
        const val    = (what_pform_val[k] ?? '').trim()
        const sc_str = (what_pform_sc[k]  ?? '').trim()
        if (!val && !sc_str) return
        const sc = { Point: val === '' ? 1 : val, ...(sc_str ? peel(sc_str) : {}) }
        const edit_idx = what_pedit_idx[k] ?? null
        const all_pts  = what.o({ Point: 1 }) as TheC[]
        if (edit_idx !== null && all_pts[edit_idx]) {
            Object.keys(all_pts[edit_idx].sc).forEach(k2 => delete all_pts[edit_idx].sc[k2])
            Object.assign(all_pts[edit_idx].sc, sc)
        } else {
            what.oai(sc)
        }
        what.bump_version()
        waft.bump_version()
        cancel_what_pform(what)
    }

    function delete_what_point(pt: TheC, what: TheC) {
        what.drop(pt)
        what.bump_version()
        waft.bump_version()
    }

    // ── Seen:origin clone editing ────────────────────────────────────
    //
    //   The %Seem:origin tree on workon/%LE is the immutable snapshot from
    //   the last pull.  %Seem:working is the mutable clone tree Lang edits.
    //   When the user edits a clone here we fire e:Lang_LE_edit with
    //   { spec, patch } — Lang patches the working clone's sc in-place, and
    //   the encode-compare on the next maneuvre tick will factor in the new value.
    //   If LE still points at this origin src, Lies will want a fresh pull
    //   to reconcile the change with disk.
    //
    //   We reach LE via examining.c.lang_w → workon → /{LE:1}.
    function get_LE(): TheC | undefined {
        const lang_w = (examining?.c as any)?.lang_w as TheC | undefined
        if (!lang_w) return undefined
        const workon = (lang_w.o({ req: 'workon' }) as TheC[])[0]
        return (workon?.o({ LE: 1 }) as TheC[])[0]
    }

    function get_origin_clones(): TheC[] {
        // %LE/%Seem:origin — the snapshot root.  Its sc.C is the clone root TheC.
        // Points live directly on that root (same layout as on a %Doc).
        const LE = get_LE()
        if (!LE) return []
        const origin_seem = (LE.o({ Seem: 'origin' }) as TheC[])[0]
        const origin_root = origin_seem?.sc.C as TheC | undefined
        if (!origin_root) return []
        return origin_root.o({ Point: 1 }) as TheC[]
    }

    // Identity spec used as the key for e:Lang_LE_edit and for clone_edit_* Records
    function clone_spec(clone: TheC): string {
        return String((clone.sc as any).method ?? (clone.sc as any).Point ?? '')
    }

    function open_clone_edit(clone: TheC) {
        const spec = clone_spec(clone)
        const sc   = clone.sc as Record<string, any>
        const pval = sc.Point
        clone_edit_val[spec]  = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        clone_edit_sc[spec]   = Object.entries(sc)
            .filter(([k]) => k !== 'Point')
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
        clone_edit_open[spec] = true
    }

    function submit_clone_edit(clone: TheC) {
        const spec   = clone_spec(clone)
        const val    = (clone_edit_val[spec] ?? '').trim()
        const sc_str = (clone_edit_sc[spec]  ?? '').trim()
        const patch: Record<string, any> = { Point: val === '' ? 1 : val }
        if (sc_str) Object.assign(patch, peel(sc_str))
        // e:Lang_LE_edit patches the working clone; encode-compare on next tick
        // detects the change.  If LE still lives at this origin src, Lies will
        // want a fresh pull to reconcile.
        H.i_elvisto('Lang/Lang', 'Lang_LE_edit', { spec, patch })
        clone_edit_open[spec] = false
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

    function delete_doc(doc: TheC) {
        waft.drop(doc)
        waft.bump_version()
    }

    function focus_doc(doc: TheC) {
        H.i_elvisto('Lies/Lies', 'Lies_set_cursor', { doc_C: doc, waft_key: wkey })
    }
</script>

<div class="ls-waft" style="margin-left: {depth * 14}px" class:ls-waft-active={is_active}>

    <!-- Waft header row — rename or idle -->
    <div class="ls-waft-hdr">
        {#if renaming_waft !== null}
            <input class="ls-input ls-rename-input"
                value={renaming_waft}
                oninput={(ev) => renaming_waft = (ev.target as HTMLInputElement).value}
                onkeydown={(ev) => { if (ev.key==='Enter') commit_rename_waft(); if (ev.key==='Escape') cancel_rename_waft() }}
                use:place_cursor_at_stem />
            <button class="ls-add-btn ls-add-btn-sm" onclick={commit_rename_waft}
                    disabled={!renaming_waft?.trim() || renaming_waft.trim() === wkey}>rename</button>
            <button class="ls-cancel-btn ls-cancel-right" onclick={cancel_rename_waft}>cancel</button>
        {:else}
            <span class="ls-waft-key">{wkey}</span>
            <span class="ls-spacer"></span>
            <button class="ls-icon-btn ls-active-btn" class:ls-is-active={is_active}
                    title={is_active ? 'active' : 'set active'}
                    onclick={() => on_active(waft)}>{is_active ? '●' : '○'}</button>
            <button class="ls-icon-btn ls-adddoc-btn" title="add Doc"
                    onclick={toggle_add_doc}>+ Doc</button>
            <button class="ls-icon-btn" title="rename Waft"
                    onclick={() => renaming_waft = wkey}>✎</button>
            <button class="ls-icon-btn ls-del-btn" title="delete Waft"
                    onclick={() => on_delete(waft)}>×</button>
        {/if}
    </div>

    {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
        <EncodingSplatter {waft} />
    {/if}

    <!-- +Doc form — multi-field path selector; stays separate from PeelInput
         because it offers Ghost/, src/lib/, and free-path variants -->
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
                <button class="ls-cancel-btn ls-cancel-right" onclick={() => adding_doc=null}>cancel</button>
            </div>
        </div>
    {/if}

    <!-- Whats and Docs -->
    {#each waft_whats as what (what)}
        {@render render_what(what, 0)}
    {/each}

    {#each waft_docs as doc (doc.sc.path)}
        {@render render_doc(doc, '')}
    {/each}

    <!-- Seen:origin clones from workon/%LE/%Seem:origin.  Editing a clone
         fires e:Lang_LE_edit to patch the working tree; Lies is told to want
         a fresh pull if LE still points at this src. -->
    {#if get_LE()}
        {@const origin_clones = get_origin_clones()}
        {#if origin_clones.length}
            <div class="ls-origin-section">
                <span class="ls-origin-label">origin</span>
                {#each origin_clones as clone (clone)}
                    {@const spec = clone_spec(clone)}
                    <div class="ls-origin-clone">
                        <PeelInput
                            label="Point"
                            open={!!clone_edit_open[spec]}
                            display={point_to_peel(clone)}
                            mainkey={clone_edit_val[spec] ?? ''}
                            on_mk={(v) => clone_edit_val[spec] = v}
                            sc_str={clone_edit_sc[spec] ?? ''}
                            on_sc={(v) => clone_edit_sc[spec] = v}
                            submit_label="✓"
                            on_open={() => open_clone_edit(clone)}
                            on_submit={() => submit_clone_edit(clone)}
                            on_cancel={() => { clone_edit_open[spec] = false }} />
                    </div>
                {/each}
            </div>
        {/if}
    {/if}

    <!-- sub-Wafts (recursive) — pass w through so DocRow has live Lies state -->
    {#each sub_wafts as sw (sw.sc.Waft)}
        <svelte:self {H} {w} waft={sw} depth={depth + 1} {examining}
            {on_active} {on_delete} />
    {/each}

</div>

<!-- render_doc — Doc header + its Points; used at Waft level and inside Whats.
     scope prefixes point_form keys so the same doc path under different Whats
     within the same Waft component instance doesn't share form state. -->
{#snippet render_doc(doc: TheC, scope: string)}
    {@const dkey     = scope ? scope + ':' + (doc.sc.path as string) : doc.sc.path as string}
    {@const dpath    = doc.sc.path as string}
    {@const pts      = (() => { void doc.version; return doc.o({ Point: 1 }) as TheC[] })()}
    {@const pform    = !!point_form_open[dkey]}
    {@const doc_whats = (() => { void doc.version; return doc.o({ What: 1 }) as TheC[] })()}

    <div class="ls-doc"
         class:ls-doc-new={!!doc.sc.new}
         class:ls-doc-missing={!!doc.sc.not_found && !doc.sc.new}>

        <!-- DocRow header — path, load state, rename, delete -->
        <DocRow {H} {w} {doc} {waft} {examining}
            on_del={delete_doc}
            on_focus={focus_doc}
            on_rename={(old_p, new_p) => do_rename_doc(doc, old_p, new_p)} />

        <!-- existing Points — each row shows the peel string + pencil + × -->
        {#if pts.length}
            <div class="ls-points">
                {#each pts as pt, idx (idx)}
                    <div class="ls-point">
                        {#if pform && point_edit_idx[dkey] === idx}
                            <!-- edit form replaces the Point row inline -->
                            <PeelInput
                                label="Point"
                                open={true}
                                mainkey={point_form_val[dkey] ?? ''}
                                on_mk={(v) => point_form_val[dkey] = v}
                                sc_str={point_form_sc[dkey] ?? ''}
                                on_sc={(v) => point_form_sc[dkey] = v}
                                submit_label="✓"
                                on_submit={() => submit_point(doc, dkey)}
                                on_cancel={() => cancel_point_form(dkey)} />
                        {:else}
                            <!-- method is set by fuzzify/export; Point value is the fallback for hand-entered Points -->
                            <button class="ls-point-open-btn"
                                    title="open {dpath} at this point"
                                    onclick={() => H.i_elvisto('Lang/Lang', 'Dock_open', { path: dpath, point: pt.sc.method ?? pt.sc.Point })}>
                                {point_to_peel(pt)}
                            </button>
                            <button class="ls-icon-btn" title="edit Point"
                                    onclick={() => start_edit_point(dkey, idx, pt)}>✎</button>
                            <button class="ls-icon-btn ls-del-btn"
                                    onclick={() => delete_point(pt, doc)}>×</button>
                        {/if}
                    </div>
                {/each}
            </div>
        {/if}

        <!-- Doc: Point add row — always present at the bottom of this Doc.
             Collapsed: Doc: path  +     Open: Doc: [mk] [sc] + cancel -->
        <div class="ls-doc-add-row">
            <PeelInput
                label="Doc"
                open={pform && point_edit_idx[dkey] == null}
                display={dpath}
                mk_ph="fuzzyName"
                sc_ph="method:Name,call"
                mainkey={point_form_val[dkey] ?? ''}
                on_mk={(v) => point_form_val[dkey] = v}
                sc_str={point_form_sc[dkey] ?? ''}
                on_sc={(v) => point_form_sc[dkey] = v}
                submit_label="+"
                on_open={() => open_point_form(dkey)}
                on_submit={() => submit_point(doc, dkey)}
                on_cancel={() => cancel_point_form(dkey)} />
        </div>

        <!-- %What children of this %Doc (Doc > What nesting, e.g. time-slices).
             Cursor candidates don't reach these yet — one-Doc-per-What restructuring
             avoids the nesting. -->
        {#each doc_whats as dw (dw)}
            {@render render_what(dw, 1)}
        {/each}

    </div>
{/snippet}

<!-- render_what — What header row + its Points + nested Docs and Whats.
     The What header IS a PeelInput row:
       Collapsed rename:   What: label  ✎
       Renaming:           What: [label input]  rename  cancel
       Adding/editing Pt:  the Point PeelInput sits on its own row below.  -->
{#snippet render_what(what: TheC, wdepth: number)}
    {@const wk            = wlabel(what)}
    {@const what_docs     = (() => { void what.version; return what.o({ Doc: 1 })   as TheC[] })()}
    {@const what_pts      = (() => { void what.version; return what.o({ Point: 1 }) as TheC[] })()}
    {@const what_subwhats = (() => { void what.version; return what.o({ What: 1 })  as TheC[] })()}
    {@const is_what_active = (() => {
        // beam glow: this %What is the target, or any ancestor of the target via c.up
        void examining?.vers
        const spot = examining?.o?.({ Spotlight: 1 })?.[0] as any
        if (!spot?.sc.src) return false
        let node: any = spot.sc.src
        while (node) { if (node === what) return true; node = node.c?.up }
        return false
    })()}

    <div class="ls-what" style="margin-left: {wdepth * 10}px">

        <!-- What header — PeelInput handles both idle and rename states.
             When renaming, mainkey is the draft label (bound to what_renaming[wk]).
             The + at the right opens the Point form below. -->
        <div class="ls-what-hdr" class:ls-what-active={is_what_active}>
            {#if what_renaming[wk] !== null && what_renaming[wk] !== undefined}
                <!-- rename: What: [new label input]  rename  cancel -->
                <PeelInput
                    label="What"
                    open={true}
                    mk_ph={wk}
                    sc_ph=""
                    mainkey={what_renaming[wk] ?? ''}
                    on_mk={(v) => what_renaming[wk] = v}
                    submit_label="rename"
                    on_submit={() => commit_rename_what(what)}
                    on_cancel={() => cancel_rename_what(what)} />
            {:else}
                <!-- idle: What: label  [cursor btn]  ✎  [Point +] -->
                <span class="pi-label">What:</span>
                <button class="ls-what-label"
                        title="cursor to What:{wk}"
                        onclick={() => H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what, dive: true })}>
                    {wk}
                </button>
                <span class="ls-spacer"></span>
                <button class="ls-icon-btn" title="rename What"
                        onclick={() => start_rename_what(what)}>✎</button>
                <button class="ls-icon-btn ls-add-pt-hdr" title="add Point"
                        onclick={() => open_what_pform(what)}>+</button>
            {/if}
        </div>

        <!-- existing Points on this What -->
        {#if what_pts.length}
            <div class="ls-points ls-what-pts">
                {#each what_pts as pt, idx (idx)}
                    <div class="ls-point">
                        {#if what_pform[wk] && what_pedit_idx[wk] === idx}
                            <PeelInput
                                label="Point"
                                open={true}
                                mainkey={what_pform_val[wk] ?? ''}
                                on_mk={(v) => what_pform_val[wk] = v}
                                sc_str={what_pform_sc[wk] ?? ''}
                                on_sc={(v) => what_pform_sc[wk] = v}
                                submit_label="✓"
                                on_submit={() => submit_what_point(what)}
                                on_cancel={() => cancel_what_pform(what)} />
                        {:else}
                            <button class="ls-point-open-btn"
                                    title="point in What:{wk}"
                                    onclick={() => H.i_elvisto('Lang/Lang', 'Dock_open', { point: pt.sc.method ?? pt.sc.Point })}>
                                {point_to_peel(pt)}
                            </button>
                            <button class="ls-icon-btn" title="edit Point"
                                    onclick={() => start_edit_what_point(what, idx, pt)}>✎</button>
                            <button class="ls-icon-btn ls-del-btn"
                                    onclick={() => delete_what_point(pt, what)}>×</button>
                        {/if}
                    </div>
                {/each}
            </div>
        {/if}

        <!-- Point add row for this What -->
        <div class="ls-what-add-row">
            <PeelInput
                label="Point"
                open={what_pform[wk] && what_pedit_idx[wk] == null}
                display=""
                mk_ph="fuzzyName"
                sc_ph="method:Name,call"
                mainkey={what_pform_val[wk] ?? ''}
                                on_mk={(v) => what_pform_val[wk] = v}
                sc_str={what_pform_sc[wk] ?? ''}
                                on_sc={(v) => what_pform_sc[wk] = v}
                submit_label="+"
                on_open={() => open_what_pform(what)}
                on_submit={() => submit_what_point(what)}
                on_cancel={() => cancel_what_pform(what)} />
        </div>

        <!-- %Doc children of this %What -->
        {#each what_docs as doc (doc.sc.path)}
            {@render render_doc(doc, wk)}
        {/each}

        <!-- nested %What children -->
        {#each what_subwhats as subwhat (subwhat)}
            {@render render_what(subwhat, wdepth + 1)}
        {/each}

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

    .ls-add-doc-form {
        margin-top: 0.2rem; background: #0e0e1a;
        border: 1px solid #2a2a40; border-radius: 3px;
        padding: 0.3rem 0.35rem; display: flex; flex-direction: column; gap: 0.18rem;
    }
    .ls-add-doc-row { display: flex; align-items: center; gap: 0.2rem }
    .ls-input-path  { flex: 1 }
    .ls-add-doc-actions { display: flex; align-items: center; gap: 0.3rem; margin-top: 0.1rem }

    .ls-what {
        margin: 0.1rem 0 0.15rem 0;
        border-left: 2px solid #2a3a4a;
        padding-left: 0.35rem;
    }
    /* nested Whats step the border colour cooler so depth reads visually */
    .ls-what .ls-what { border-left-color: #223040; }
    .ls-what .ls-what .ls-what { border-left-color: #1a2530; }
    .ls-what-hdr {
        display: flex; align-items: center; gap: 0.2rem; min-height: 1.4rem;
    }
    /* Spotlight glow — left-margin beam when the cursor is aimed at this What */
    .ls-what-hdr.ls-what-active { position: relative; }
    .ls-what-hdr.ls-what-active::before {
        content: '';
        position: absolute; left: 0;
        width: 3px; height: 1.2rem;
        background: #446a; box-shadow: 0 0 6px 2px #446a; border-radius: 2px;
    }
    /* What label — clickable to set graft cursor at the What level */
    .ls-what-label {
        background: none; border: none; cursor: pointer;
        font-family: monospace; font-size: 0.76rem;
        color: #7a9ab0; padding: 0; text-align: left;
    }
    .ls-what-label:hover { color: #a8c8e0; text-decoration: underline; }
    /* + button in the What header that opens the Point add form below */
    .ls-add-pt-hdr { color: #448; font-size: 0.8rem }
    .ls-add-pt-hdr:hover { color: #88a }
    /* Direct Points on a What (time-slice style) — slightly indented */
    .ls-what-pts   { margin-left: 0.2rem; }
    /* What: add-Point row sits after existing Points */
    .ls-what-add-row { margin-top: 0.05rem }

    .ls-doc {
        margin: 0.1rem 0 0.2rem 0.5rem;
        border-left: 2px solid #2a2a3a;
        padding-left: 0.35rem;
    }
    .ls-doc-new     { border-left-color: #3a5a3a }
    .ls-doc-missing { border-left-color: #5a3a2a; opacity: 0.8 }
    /* Doc: Point add row sits after existing Points; slightly separated */
    .ls-doc-add-row { margin-top: 0.05rem }

    .ls-points { margin: 0.05rem 0 0.05rem 0.3rem }
    .ls-point  {
        display: flex; align-items: center; gap: 0.25rem;
        min-height: 1.4rem;
        padding: 0.1rem 0; border-bottom: 1px solid #1c1c28; flex-wrap: wrap;
    }
    .ls-point:last-child { border-bottom: none }
    .ls-point-open-btn {
        background: none; border: none; cursor: pointer; text-align: left; padding: 0;
        font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1;
    }
    .ls-point-open-btn:hover { color: #d0b0f0; text-decoration: underline; }

    /* Seen:origin clone section — muted purple tint to distinguish from live Points */
    .ls-origin-section {
        margin: 0.2rem 0 0.1rem 0.3rem;
        border-left: 2px solid #3a2a4a;
        padding-left: 0.35rem;
    }
    .ls-origin-label {
        display: block; font-family: monospace; font-size: 0.68rem;
        color: #553a66; margin-bottom: 0.08rem; letter-spacing: 0.04em;
    }
    .ls-origin-clone {
        min-height: 1.4rem;
        padding: 0.1rem 0; border-bottom: 1px solid #1c1424;
    }
    .ls-origin-clone:last-child { border-bottom: none }

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
    .ls-add-btn:disabled { opacity: 0.35; cursor: default }
    .ls-add-btn-sm       { padding: 0.15rem 0.3rem }
    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover  { color: #999 }
    /* push cancel to the far right in any flex row */
    .ls-cancel-right { margin-left: auto }

    /* Shared icon button styles — declared :global here so DocRow.svelte
       and any other child component can use these class names. */
    :global(.ls-icon-btn) {
        background: none; border: none; color: #444;
        cursor: pointer; font-size: 0.8rem; line-height: 1;
        padding: 0 0.15rem; flex-shrink: 0;
    }
    :global(.ls-icon-btn:hover) { color: #aaa }
    :global(.ls-del-btn:hover)  { color: #f66 }

    /* pi-label used directly in the What idle header row (mirrors PeelInput's class) */
    .pi-label {
        font-family: monospace; font-size: 0.74rem;
        color: #556; flex-shrink: 0; white-space: nowrap;
    }
</style>
