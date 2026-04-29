<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Lies'}.
    // Receives H (the root Mundo house).
    //
    // Layout
    // ──────
    //   [🔪 Lies]  [+ Waft] [+ Now]
    //              [____________] [+]   ← +Waft input when toggled
    //
    //   Loaded docs (uses render_doc_row snippet — same as Waft tree items)
    //
    //   Waft** recursive tree
    //     Ghost/Tour  [○] [+ Doc] [✎] [×]
    //       Doc row (render_doc_row)
    //         Points (peel-style display)
    //           method:Idzeugnosis  [edit] [×]
    //         [+ Point]  →  Point: [________________] [+]
    //
    // render_doc_row snippet
    // ──────────────────────
    //   Shared by both the loaded-docs list and each Waft/Doc item.
    //   Shows: path, codetype badge, is_new/not_found flags with tooltips,
    //   pending indicator or '...' when not yet loaded, and (when doc+waft
    //   supplied) edit+delete buttons.
    //
    //   is_new   "created here, not yet written to disk — a spawning ghost"
    //            stays until file has non-empty content.  Display priority.
    //   not_found "file not found on disk — opened empty"
    //            stays while file absent.  Hidden when is_new also set.
    //
    // Codetype detection
    // ──────────────────
    //   SECOND_LEVEL_FILETYPES: middle extensions that combine with their
    //   terminal extension.  'svelte' → 'svelte.ts'.
    //   No dot in path → codetype ''.
    //
    // Point editing
    // ─────────────
    //   Form: Point:[val],[extra sc]
    //     val input (focused): the Point's value — empty string → 1 when extra sc present.
    //     sc input: extra peelable sc, e.g. method:Idzeugnosis or key:val,key2:val2.
    //   Examples:
    //     val='story_save / if runH', sc=''           → { Point: 'story_save / if runH' }
    //     val='',                     sc='method:Foo' → { Point: 1, method: 'Foo' }
    //     val='Whatever',             sc='method:Foo' → { Point: 'Whatever', method: 'Foo' }
    //   [✎] (edit) splits the existing sc back into val + extra fields.
    //
    // +Doc form
    // ─────────
    //   Ghost/[___].g  lib/src/[___]  path:[___]
    //   Ghost/ auto-appends .g when the typed value has no extension.

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"
    import { peel, depeel } from "$lib/Y.svelte"

    let { H }: { H: House } = $props()

    // ── codetype detection ───────────────────────────────────────────
    // Middle parts that form compound codetypes: Foo.svelte.ts → svelte.ts
    const SECOND_LEVEL_FILETYPES = ['svelte']

    function ls_codetype(path: string): string {
        const parts = path.split('.')
        if (parts.length <= 1) return ''   // no extension
        const ext  = parts[parts.length - 1]
        const prev = parts.length >= 3 ? parts[parts.length - 2] : ''
        if (prev && SECOND_LEVEL_FILETYPES.includes(prev)) return `${prev}.${ext}`
        return ext
    }

    // ── locate Lies's w via H.ave ────────────────────────────────────
    // Lies places its w into H.ave in setup (ave.i(w)).
    // w carries sc.w:'Lies' so we can find it reliably even before
    // it exists — the $effect re-runs whenever ave changes.
    let LS: TheC | undefined = $state()

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        for (const p of ave) void p.version
        LS = ave.find((n: TheC) => n.sc.w === 'Lies') as TheC | undefined
    })

    let loaded_docs = $derived(LS ? LS.o({ loaded_doc: 1 }) as TheC[] : [])
    let pending     = $derived(LS ? (LS.o({ compile_pending: 1 }) as TheC[]).filter(p => !p.sc.done) : [])
    let errors      = $derived(LS ? LS.o({ compile_error: 1 }) as TheC[] : [])

    let all_wafts = $derived((() => {
        if (!LS) return []
        void LS.version
        return LS.o({ Waft: 1 }) as TheC[]
    })())

    // ── find waft/doc helpers ─────────────────────────────────────────
    // Used when rendering loaded_docs so render_doc_row gets the same
    // doc TheC that the Waft tree items use (for flags and CRUD).
    function find_waft_doc(path: string): TheC | undefined {
        for (const waft of all_wafts) {
            const d = waft.o({ Doc: 1, path })[0] as TheC | undefined
            if (d) return d
        }
    }
    function find_waft_for_doc(path: string): TheC | undefined {
        for (const waft of all_wafts) {
            if (waft.o({ Doc: 1, path }).length) return waft
        }
    }

    // ── header state ─────────────────────────────────────────────────
    let waft_input_open = $state(false)
    let new_waft_path   = $state('')

    // ── rename/edit state: particle key → value (null = not editing) ──
    let renaming: Record<string, string | null> = $state({})

    // ── +Doc form per waft ───────────────────────────────────────────
    let adding_doc: Record<string, { ghost: string, libsrc: string, free: string } | null> = $state({})

    // ── Point add/edit state per doc path ────────────────────────────
    let point_form_open: Record<string, boolean>       = $state({})  // +Point form toggle
    let point_form_val:  Record<string, string>        = $state({})  // Point's value (empty → 1)
    let point_form_sc:   Record<string, string>        = $state({})  // extra peelable sc
    let point_edit_idx:  Record<string, number | null> = $state({})  // which point is being edited

    // ── errors ───────────────────────────────────────────────────────
    function dismiss_errors() {
        if (!LS) return
        for (const e of LS.o({ compile_error: 1 }) as TheC[]) LS.drop(e)
        LS.bump_version()
    }

    // ── +Waft ────────────────────────────────────────────────────────
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

    // ── active toggle ─────────────────────────────────────────────────
    // active is session-only — not persisted (encode root is {Waft:path} only)
    function set_waft_active(waft: TheC) {
        if (!LS) return
        for (const w of LS.o({ Waft: 1 }) as TheC[]) delete w.sc.active
        waft.sc.active = 1
        LS.bump_version()
    }

    // ── +Doc ─────────────────────────────────────────────────────────
    function toggle_add_doc(waft: TheC) {
        const key = waft.sc.Waft as string
        adding_doc[key] = adding_doc[key] ? null : { ghost: '', libsrc: '', free: '' }
    }
    function submit_add_doc(waft: TheC) {
        const key  = waft.sc.Waft as string
        const form = adding_doc[key]
        if (!form) return
        let path = ''
        if (form.ghost.trim()) {
            let g = form.ghost.trim()
            if (!g.includes('.')) g += '.g'   // auto-append .g when no extension
            path = `Ghost/${g}`
        } else if (form.libsrc.trim()) {
            path = `lib/src/${form.libsrc.trim()}`
        } else if (form.free.trim()) {
            path = form.free.trim()
        }
        if (!path) return
        const doc = waft.oai({ Doc: 1, path })
        doc.sc.new = 1   // Lies clears this when the file has non-empty content
        waft.bump_version()
        adding_doc[key] = null
    }

    // ── Points ───────────────────────────────────────────────────────

    // Render a Point's sc as depeel text for display.
    // Format: Point,method:Foo  (depeel of the full sc, then strip leading 'Point,')
    // depeel produces comma-separated scalar k:v pairs — throws via us if non-scalar
    // values sneak in (object, null), or if 'Point' doesn't appear first in the output.
    function point_to_peel(pt: TheC): string {
        const sc = pt.sc as Record<string, any>
        for (const [, v] of Object.entries(sc)) {
            if (v === null || typeof v === 'object') throw `point_to_peel: non-scalar value in Point sc`
        }
        const d = depeel(sc)   // e.g. 'Point,method:Idzeugnosis'
        if (!d.startsWith('Point,') && d !== 'Point') throw `point_to_peel: 'Point' not first in depeel: ${d}`
        return d   // keep the full string including Point — displayed as Point,method:Foo
    }

    function toggle_point_form(dpath: string) {
        const was = point_form_open[dpath]
        point_form_open[dpath] = !was
        point_edit_idx[dpath]  = null
        if (!was) { point_form_val[dpath] = ''; point_form_sc[dpath] = '' }
    }

    function start_edit_point(dpath: string, idx: number, pt: TheC) {
        point_form_open[dpath] = true
        point_edit_idx[dpath]  = idx
        // Split the Point sc back into val + extra sc for the two-field form.
        // sc = { Point: val, method: 'Foo', ... } → val field + 'method:Foo,...'
        const sc   = pt.sc as Record<string, any>
        const pval = sc.Point
        point_form_val[dpath] = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        const extras = Object.entries(sc)
            .filter(([k]) => k !== 'Point')
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
        point_form_sc[dpath]  = extras
    }

    function submit_point(doc: TheC, waft: TheC) {
        const dpath  = doc.sc.path as string
        const val    = (point_form_val[dpath] ?? '').trim()
        const sc_str = (point_form_sc[dpath]  ?? '').trim()
        if (!val && !sc_str) return

        // Point value: empty → 1 when extra sc present, otherwise the typed string.
        // { Point: 'story_save / if runH' }         — vague, matches broadly
        // { Point: 1, method: 'Idzeugnosis' }        — val blank, extra sc given
        // { Point: 'Whatever', method: 'Foo' }       — both fields filled
        const point_val: any = val === '' ? 1 : val
        const extra_sc = sc_str ? peel(sc_str) : {}
        const sc = { Point: point_val, ...extra_sc }

        const pointsC  = (doc.o({ Points: 1 })[0] as TheC | undefined) ?? doc.i({ Points: 1 })
        const edit_idx = point_edit_idx[dpath] ?? null
        const all_pts  = pointsC.o({ Point: 1 }) as TheC[]

        if (edit_idx !== null && all_pts[edit_idx]) {
            // update existing — replace sc in-place
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

    function delete_point(pt: TheC, pointsC: TheC, waft: TheC) {
        pointsC.drop(pt)
        pointsC.bump_version()
        waft.bump_version()
    }

    // ── Doc rename / delete ───────────────────────────────────────────
    function start_rename(key: string, current: string) {
        renaming[key] = current
    }
    function commit_rename_waft(waft: TheC) {
        const old     = waft.sc.Waft as string
        const newPath = renaming[old]?.trim() ?? ''
        renaming[old] = null
        if (!newPath || newPath === old) return
        waft.sc.Waft  = newPath
        LS?.bump_version()
    }
    function commit_rename_doc(doc: TheC, waft: TheC) {
        const old     = doc.sc.path as string
        const newPath = renaming[old]?.trim() ?? ''
        renaming[old] = null
        if (!newPath || newPath === old) return
        doc.sc.path = newPath
        waft.bump_version()
    }
    function delete_waft(waft: TheC) {
        if (!LS) return
        LS.drop(waft)
        LS.bump_version()
    }
    function delete_doc(doc: TheC, waft: TheC) {
        waft.drop(doc)
        waft.bump_version()
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

    <!-- ── loaded docs (same render_doc_row snippet as Waft tree) ── -->
    {#if loaded_docs.length}
        <div class="ls-loaded-section">
            {#each loaded_docs as ld (ld.sc.path)}
                {@const path    = ld.sc.path as string}
                {@const gen     = ld.sc.gen_path as string | undefined}
                {@const pend    = pending.some(p => p.sc.path === path)}
                {@const wdoc    = find_waft_doc(path)}
                {@const wwaft   = find_waft_for_doc(path)}
                <div class="ls-loaded-row">
                    {@render render_doc_row(path, gen, pend, wdoc, wwaft)}
                </div>
            {/each}
        </div>
    {:else}
        <div class="ls-empty">no docs open</div>
    {/if}

    <!-- ── Waft** recursive tree ── -->
    {#if all_wafts.length}
        <div class="ls-waft-section">
            {#each all_wafts as waft (waft.sc.Waft)}
                {@render render_waft(waft, 0)}
            {/each}
        </div>
    {/if}

    {/if}
</div>

<!-- ─────────────────────────────────────────────────────────────────────
     render_doc_row snippet — shared by loaded-docs list and Waft tree.
     path, gen_path: file identity.
     is_pending: compile write in flight.
     doc: TheC from Waft (for flags + CRUD); absent for standalone rows.
     waft: parent Waft TheC (for mutations).
──────────────────────────────────────────────────────────────────────── -->
{#snippet render_doc_row(path: string, gen_path: string | undefined, is_pending: boolean, doc?: TheC, waft?: TheC)}
    {@const codetype  = ls_codetype(path)}
    {@const is_new    = !!doc?.sc.new}
    {@const not_found = !!doc?.sc.not_found}
    {@const show_new  = is_new}
    {@const show_nf   = not_found && !is_new}
    {@const is_loaded = gen_path !== undefined || (!is_new && !not_found)}

    <div class="ls-doc-hdr">
        {#if doc && waft && renaming[path] !== null && renaming[path] !== undefined}
            <input class="ls-input ls-rename-input"
                value={renaming[path]}
                oninput={(ev) => renaming[path] = (ev.target as HTMLInputElement).value}
                onblur={() => commit_rename_doc(doc, waft)}
                onkeydown={(ev) => { if (ev.key==='Enter') commit_rename_doc(doc, waft); if (ev.key==='Escape') renaming[path]=null }}
                use:focus_on_mount />
        {:else}
            <span class="ls-doc-path">{path}</span>
        {/if}

        {#if codetype}<span class="ls-badge">{codetype}</span>{/if}

        {#if show_new}
            <span class="ls-flag ls-flag-new"
                title="created here, not yet written to disk — a spawning ghost">new</span>
        {:else if show_nf}
            <span class="ls-flag ls-flag-missing"
                title="file not found on disk — opened empty">?</span>
        {/if}

        {#if is_pending}
            <span class="ls-state-ind" title="writing…">⏳</span>
        {:else if !is_loaded}
            <span class="ls-state-ind ls-dim" title="not yet loaded">…</span>
        {/if}

        <span class="ls-spacer"></span>

        {#if doc && waft}
            <button class="ls-icon-btn" title="edit path" onclick={() => start_rename(path, path)}>✎</button>
            <button class="ls-icon-btn ls-del-btn" title="remove" onclick={() => delete_doc(doc, waft)}>×</button>
        {/if}
    </div>
{/snippet}

<!-- ─────────────────────────────────────────────────────────────────────
     Recursive Waft snippet.
──────────────────────────────────────────────────────────────────────── -->
{#snippet render_waft(waft: TheC, depth: number)}
    {@const wkey      = waft.sc.Waft as string}
    {@const is_active = !!waft.sc.active}
    {@const waft_docs = (() => { void waft.version; return waft.o({ Doc: 1 }) as TheC[] })()}
    {@const sub_wafts = (() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })()}
    {@const waft_mungs = waft.o({ mung_error: 1 }) as TheC[]}
    {@const add_form   = adding_doc[wkey]}

    <div class="ls-waft" style="margin-left: {depth * 14}px" class:ls-waft-active={is_active}>

        <!-- Waft header: [key] [spacer] [●/○] [+ Doc] [✎] [×] -->
        <div class="ls-waft-hdr">
            {#if renaming[wkey] !== null && renaming[wkey] !== undefined}
                <input class="ls-input ls-rename-input" value={renaming[wkey]}
                    oninput={(ev) => renaming[wkey] = (ev.target as HTMLInputElement).value}
                    onblur={() => commit_rename_waft(waft)}
                    onkeydown={(ev) => { if (ev.key==='Enter') commit_rename_waft(waft); if (ev.key==='Escape') renaming[wkey]=null }}
                    use:focus_on_mount />
            {:else}
                <span class="ls-waft-key">{wkey}</span>
            {/if}
            <span class="ls-spacer"></span>
            <button class="ls-icon-btn ls-active-btn" class:ls-is-active={is_active}
                    title={is_active ? 'active' : 'set active'}
                    onclick={() => set_waft_active(waft)}>{is_active ? '●' : '○'}</button>
            <button class="ls-icon-btn ls-adddoc-btn" title="add Doc"
                    onclick={() => toggle_add_doc(waft)}>+ Doc</button>
            <button class="ls-icon-btn" title="edit name"
                    onclick={() => start_rename(wkey, wkey)}>✎</button>
            <button class="ls-icon-btn ls-del-btn" title="delete"
                    onclick={() => delete_waft(waft)}>×</button>
        </div>

        {#if waft_mungs.length}
            <div class="ls-mung-errors">
                {#each waft_mungs as m}<div class="ls-error-msg">⛔ {m.sc.msg}</div>{/each}
            </div>
        {/if}

        <!-- +Doc form, expanded below header when + Doc clicked -->
        {#if add_form}
            <div class="ls-add-doc-form">
                <div class="ls-add-doc-row">
                    <span class="ls-prefix-label">Ghost/</span>
                    <input class="ls-input ls-input-path" bind:value={add_form.ghost}
                        onkeydown={(ev) => ev.key==='Enter' && submit_add_doc(waft)}
                        use:focus_on_mount />
                    <span class="ls-prefix-dim">.g</span>
                </div>
                <div class="ls-add-doc-row">
                    <span class="ls-prefix-label">lib/src/</span>
                    <input class="ls-input ls-input-path" bind:value={add_form.libsrc}
                        onkeydown={(ev) => ev.key==='Enter' && submit_add_doc(waft)} />
                </div>
                <div class="ls-add-doc-row">
                    <span class="ls-prefix-dim">path:</span>
                    <input class="ls-input ls-input-path" bind:value={add_form.free}
                        onkeydown={(ev) => ev.key==='Enter' && submit_add_doc(waft)} />
                </div>
                <div class="ls-add-doc-actions">
                    <button class="ls-add-btn" onclick={() => submit_add_doc(waft)}>Add Doc</button>
                    <button class="ls-cancel-btn" onclick={() => adding_doc[wkey]=null}>cancel</button>
                </div>
            </div>
        {/if}

        <!-- Doc list — uses shared render_doc_row, then Points section below -->
        {#each waft_docs as doc (doc.sc.path)}
            {@const dpath  = doc.sc.path as string}
            {@const ld     = loaded_docs.find(l => l.sc.path === dpath)}
            {@const gen    = ld?.sc.gen_path as string | undefined}
            {@const pend   = pending.some(p => p.sc.path === dpath)}
            {@const ptC    = doc.o({ Points: 1 })[0] as TheC | undefined}
            {@const pts    = (() => { void ptC?.version; return ptC ? ptC.o({ Point: 1 }) as TheC[] : [] })()}
            {@const pform  = !!point_form_open[dpath]}

            <div class="ls-doc" class:ls-doc-new={!!doc.sc.new} class:ls-doc-missing={!!doc.sc.not_found && !doc.sc.new}>

                <!-- shared doc header row -->
                {@render render_doc_row(dpath, gen, pend, doc, waft)}

                <!-- Points: peel-style display -->
                {#if pts.length}
                    <div class="ls-points">
                        {#each pts as pt, idx (idx)}
                            <div class="ls-point">
                                {#if point_form_open[dpath] && point_edit_idx[dpath] === idx}
                                    <!-- edit mode: same input as +Point -->
                                    {@render point_input_row(dpath, doc, waft, 'update')}
                                {:else}
                                    <span class="ls-point-peel">{point_to_peel(pt)}</span>
                                    <button class="ls-icon-btn" title="edit"
                                            onclick={() => start_edit_point(dpath, idx, pt)}>✎</button>
                                    <button class="ls-icon-btn ls-del-btn" title="remove"
                                            onclick={() => delete_point(pt, ptC!, waft)}>×</button>
                                {/if}
                            </div>
                        {/each}
                    </div>
                {/if}

                <!-- +Point: button toggles the form; form is for add (edit_idx null) -->
                {#if pform && point_edit_idx[dpath] == null}
                    {@render point_input_row(dpath, doc, waft, 'add')}
                {:else if !pform}
                    <button class="ls-add-point-btn" onclick={() => toggle_point_form(dpath)}>+ Point</button>
                {/if}

            </div>
        {/each}

        <!-- sub-Wafts (recursive) -->
        {#each sub_wafts as sw (sw.sc.Waft)}
            {@render render_waft(sw, depth + 1)}
        {/each}

    </div>
{/snippet}

<!-- ─────────────────────────────────────────────────────────────────────
     Point input row — shared by +Point (add) and edit-point.
     Point: prefix label shown; user types peel sc (method:Foo,...).
     On submit: { Point:1, ...peel(val) }
──────────────────────────────────────────────────────────────────────── -->
{#snippet point_input_row(dpath: string, doc: TheC, waft: TheC, mode: 'add' | 'update')}
    <div class="ls-point-form">
        <span class="ls-prefix-label">Point:</span>
        <input class="ls-input ls-point-val-input"
            placeholder="story_save / if runH"
            title="Point's value — empty defaults to 1 when extra sc is given"
            bind:value={point_form_val[dpath]}
            onkeydown={(ev) => { if (ev.key==='Enter') submit_point(doc, waft); if (ev.key==='Escape') { point_form_open[dpath]=false; point_edit_idx[dpath]=null } }}
            use:focus_on_mount />
        <span class="ls-prefix-dim">,</span>
        <input class="ls-input ls-point-sc-input"
            placeholder="method:Idzeugnosis"
            title="extra peelable sc: method:Foo or key:val,key2:val2"
            bind:value={point_form_sc[dpath]}
            onkeydown={(ev) => { if (ev.key==='Enter') submit_point(doc, waft); if (ev.key==='Escape') { point_form_open[dpath]=false; point_edit_idx[dpath]=null } }} />
        <button class="ls-add-btn ls-add-btn-sm"
                onclick={() => submit_point(doc, waft)}>{mode === 'add' ? '+' : '✓'}</button>
        <button class="ls-cancel-btn"
                onclick={() => { point_form_open[dpath]=false; point_edit_idx[dpath]=null }}>×</button>
    </div>
{/snippet}

<script module>
    // Action: focus and select an element on mount.
    export function focus_on_mount(node: HTMLElement) {
        node.focus()
        if (node instanceof HTMLInputElement) node.select()
        return {}
    }
</script>

<style>
    .ls-ui {
        font-size: 0.83rem;
        padding: 0.5rem;
        border: 1px solid #444;
        border-radius: 4px;
        background: #111;
        color: #ccc;
        min-width: 360px;
    }

    /* ── header ── */
    .ls-header { display: flex; align-items: center; gap: 0.5rem; margin-bottom: 0.3rem }
    .ls-title  { font-weight: bold; flex-shrink: 0 }
    .ls-header-btns { display: flex; gap: 0.25rem; margin-left: auto }
    .ls-hdr-btn {
        background: #1a1a28; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.74rem; padding: 0.15rem 0.4rem;
    }
    .ls-hdr-btn:hover      { background: #222238; color: #aac }
    .ls-hdr-btn-active     { background: #222238; border-color: #556; color: #aac }

    .ls-waft-input-row { display: flex; gap: 0.25rem; margin-bottom: 0.3rem }
    .ls-waft-path-input { flex: 1 }

    /* ── errors ── */
    .ls-errors {
        background: #300; border: 1px solid #c44; border-radius: 3px;
        padding: 0.3rem 0.5rem; margin-bottom: 0.4rem;
        color: #f88; display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: flex-start;
    }
    .ls-dismiss { margin-left: auto; background: none; border: none; color: #f88; cursor: pointer; font-size: 1rem; line-height: 1 }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }
    .ls-mung-errors { margin: 0.15rem 0 }

    /* ── loaded docs list ── */
    .ls-loaded-section { margin-bottom: 0.4rem }
    .ls-loaded-row { border-bottom: 1px solid #1c1c1c; padding: 0.1rem 0 }
    .ls-empty { color: #666; padding: 0.2rem 0; font-style: italic }

    /* ── shared doc header row ── */
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
    .ls-state-ind { font-size: 0.72rem; flex-shrink: 0 }
    .ls-dim       { color: #555 }
    .ls-spacer    { flex: 1 }

    /* ── Waft tree ── */
    .ls-waft-section { margin-top: 0.4rem; border-top: 1px solid #222; padding-top: 0.3rem }
    .ls-waft {
        background: #13131d; border: 1px solid #252535;
        border-radius: 3px; padding: 0.3rem 0.4rem; margin-bottom: 0.25rem;
    }
    .ls-waft-active { border-color: #446 }
    .ls-waft-hdr {
        display: flex; align-items: center; gap: 0.25rem;
        min-height: 1.4rem; margin-bottom: 0.2rem;
    }
    .ls-waft-key { font-family: monospace; font-size: 0.76rem; color: #8ab; font-weight: bold }

    .ls-active-btn         { color: #446; font-size: 0.7rem }
    .ls-active-btn.ls-is-active { color: #88c }
    .ls-active-btn:hover   { color: #88c }
    .ls-adddoc-btn         { font-size: 0.72rem; color: #558; padding: 0 0.2rem }
    .ls-adddoc-btn:hover   { color: #88a }

    /* ── Doc items in Waft ── */
    .ls-doc {
        margin: 0.1rem 0 0.2rem 0.5rem;
        border-left: 2px solid #2a2a3a;
        padding-left: 0.35rem;
    }
    .ls-doc-new     { border-left-color: #3a5a3a }
    .ls-doc-missing { border-left-color: #5a3a2a; opacity: 0.8 }

    /* ── +Doc form ── */
    .ls-add-doc-form {
        margin-top: 0.2rem; background: #0e0e1a;
        border: 1px solid #2a2a40; border-radius: 3px;
        padding: 0.3rem 0.35rem; display: flex; flex-direction: column; gap: 0.18rem;
    }
    .ls-add-doc-row  { display: flex; align-items: center; gap: 0.2rem }
    .ls-input-path   { flex: 1 }
    .ls-add-doc-actions { display: flex; gap: 0.3rem; margin-top: 0.1rem }

    /* ── Points ── */
    .ls-points { margin: 0.1rem 0 0.1rem 0.3rem }
    .ls-point  {
        display: flex; align-items: center; gap: 0.25rem;
        padding: 0.05rem 0; border-bottom: 1px solid #1c1c28;
    }
    .ls-point-peel {
        font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1;
    }
    .ls-add-point-btn {
        margin-top: 0.15rem;
        background: none; border: none; color: #448; cursor: pointer;
        font-size: 0.74rem; font-family: monospace; padding: 0.05rem 0;
        text-align: left;
    }
    .ls-add-point-btn:hover { color: #88a }
    .ls-point-form { display: flex; align-items: center; gap: 0.2rem; margin-top: 0.15rem }
    .ls-point-val-input { width: 9rem }
    .ls-point-sc-input  { flex: 1; min-width: 5rem }

    /* ── shared controls ── */
    .ls-prefix-label { font-family: monospace; font-size: 0.74rem; color: #556; flex-shrink: 0; white-space: nowrap }
    .ls-prefix-dim   { font-family: monospace; font-size: 0.74rem; color: #444; flex-shrink: 0 }
    .ls-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none;
    }
    .ls-input:focus   { border-color: #446 }
    .ls-input-sm      { min-width: 6rem; flex: 1 }
    .ls-rename-input  { flex: 1; min-width: 6rem }
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
    .ls-cancel-btn:hover { color: #999 }
    .ls-icon-btn {
        background: none; border: none; color: #444;
        cursor: pointer; font-size: 0.8rem; line-height: 1;
        padding: 0 0.15rem; flex-shrink: 0;
    }
    .ls-icon-btn:hover { color: #aaa }
    .ls-del-btn:hover  { color: #f66 }
</style>
