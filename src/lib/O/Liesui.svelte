<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Lies'}.
    // Receives H (the root Mundo house).
    //
    // Layout
    // ──────
    //   [🔪 Lies]  [+ Waft] [+ Now]       ← header
    //              [____________] [+]       ← +Waft input when toggled
    //
    //   loaded docs table (flat, all open docs)
    //
    //   Waft** recursive tree
    //     Waft:Ghost/Tour  [○] [+ Doc] [✎] [×]   ← ○ = set active
    //       Doc  Ghost/test/Hello.g  [g]  [✎] [×]
    //         Point  Idzeugnosis  [×]
    //         [Point: ___________  +]
    //       [+ Doc form when expanded]
    //       Sub-Waft (recursive…)
    //     Waft:Look/2025-04-29/14  (hourly scratch, treated same as any Waft)
    //
    // CRUD mechanics
    // ──────────────
    //   +Waft button: toggles an input; Enter or + submits (empty path blocked).
    //     Fires i_elvisto 'Lies_open_Waft'.
    //   +Now button: fires 'Lies_now_Waft' — spawns/reuses Look/YMD/HH, sets active.
    //   ○/● active button (per Waft): sets sc.active=1 on this, clears others.
    //     active is session-only — the encode root for snapshots is {Waft:path}
    //     only, so active never appears in the saved toc.snap.
    //   +Doc (per Waft, on header line): expands 3-input form in the Waft body.
    //     Ghost/ input is auto-focused.  First non-empty prefix wins on submit.
    //     New Doc gains sc.new=1; Lies clears it on successful load.
    //   codetype never stored — always derived from path.split('.').pop().
    //
    // < doc tabs (switch active doc)
    // < per-doc opt overrides
    // < compile history log
    // < Look waft rename → persist on save

    import type { House } from "$lib/O/Housing.svelte"
    import type { TheC }  from "$lib/data/Stuff.svelte"

    let { H }: { H: House } = $props()

    // ── locate Lies's w via H.ave ───────────────────────────────────
    // Lies places its w into H.ave in setup (ave.i(w)).
    // w carries sc.w:'Lies' so we can find it reliably even before
    // it exists — the $effect re-runs whenever ave changes.
    let LS: TheC | undefined = $state()

    $effect(() => {
        const ave = H.ave
        if (!ave?.length) return
        for (const p of ave) void p.version   // touch all to track additions
        LS = ave.find((n: TheC) => n.sc.w === 'Lies') as TheC | undefined
    })

    let loaded_docs = $derived(LS ? LS.o({ loaded_doc: 1 }) as TheC[] : [])
    let pending     = $derived(LS ? (LS.o({ compile_pending: 1 }) as TheC[]).filter(p => !p.sc.done) : [])
    let errors      = $derived(LS ? LS.o({ compile_error: 1 }) as TheC[] : [])

    // All Waft particles on LS, version-tracked for CRUD reactivity.
    let all_wafts = $derived((() => {
        if (!LS) return []
        void LS.version
        return LS.o({ Waft: 1 }) as TheC[]
    })())

    // ── header UI state ──────────────────────────────────────────────
    let waft_input_open = $state(false)
    let new_waft_path   = $state('')

    // ── rename state: particle key → text being typed (null = closed) ──
    let renaming: Record<string, string | null> = $state({})

    // ── +Doc form state per waft key ─────────────────────────────────
    let adding_doc: Record<string, { ghost: string, libsrc: string, free: string } | null> = $state({})

    // ── +Point input per doc path ────────────────────────────────────
    let adding_point: Record<string, string> = $state({})

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
        if (!path) return   // never open Waft:''
        // i_elvisto without e_ prefix — the dispatcher prepends it
        H.i_elvisto('Lies/Lies', 'Lies_open_Waft', { path })
        new_waft_path   = ''
        waft_input_open = false
    }

    // ── +Now ─────────────────────────────────────────────────────────
    function fire_now_waft() {
        H.i_elvisto('Lies/Lies', 'Lies_now_Waft', {})
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
        if (form.ghost.trim())       path = `Ghost/${form.ghost.trim()}`
        else if (form.libsrc.trim()) path = `lib/src/${form.libsrc.trim()}`
        else if (form.free.trim())   path = form.free.trim()
        if (!path) return
        // codetype is not stored — derived from path at display time
        const doc = waft.oai({ Doc: 1, path })
        doc.sc.new = 1   // Lies clears this on successful load
        waft.bump_version()
        adding_doc[key] = null
    }

    // ── +Point ───────────────────────────────────────────────────────
    function add_point(doc: TheC, waft: TheC) {
        const method = (adding_point[doc.sc.path as string] ?? '').trim()
        if (!method) return
        const pointsC = (doc.o({ Points: 1 })[0] as TheC | undefined) ?? doc.i({ Points: 1 })
        pointsC.oai({ Point: 1, method })
        pointsC.bump_version()
        waft.bump_version()
        adding_point[doc.sc.path as string] = ''
    }

    // ── Rename ───────────────────────────────────────────────────────
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

    // ── set active ───────────────────────────────────────────────────
    // active is session-only — not persisted (encode root is {Waft:path} only).
    function set_waft_active(waft: TheC) {
        if (!LS) return
        for (const w of LS.o({ Waft: 1 }) as TheC[]) delete w.sc.active
        waft.sc.active = 1
        LS.bump_version()
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

    function delete_point(pt: TheC, pointsC: TheC, waft: TheC) {
        pointsC.drop(pt)
        pointsC.bump_version()
        waft.bump_version()
    }
</script>

<div class="ls-ui">

    <!-- ── header row ── -->
    <div class="ls-header">
        <span class="ls-title">🔪 Lies</span>
        <div class="ls-header-btns">
            <button
                class="ls-hdr-btn"
                class:ls-hdr-btn-active={waft_input_open}
                onclick={toggle_waft_input}
                title="Open a Waft"
            >+ Waft</button>
            <button class="ls-hdr-btn" onclick={fire_now_waft} title="Spawn a Look/Now waft">+ Now</button>
        </div>
    </div>

    <!-- +Waft input row — only visible when toggled -->
    {#if waft_input_open}
        <div class="ls-waft-input-row">
            <input
                class="ls-input ls-waft-path-input"
                bind:value={new_waft_path}
                onkeydown={(ev) => { if (ev.key === 'Enter') submit_new_waft(); if (ev.key === 'Escape') toggle_waft_input() }}
                use:focus_on_mount
            />
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

    <!-- ── loaded docs flat table ── -->
    {#if loaded_docs.length}
        <table class="ls-table">
            <thead><tr><th>source path</th><th>gen path</th><th>state</th></tr></thead>
            <tbody>
                {#each loaded_docs as doc (doc.sc.path)}
                    {@const isPending = pending.some(p => p.sc.path === doc.sc.path)}
                    <tr class:ls-pending={isPending}>
                        <td class="ls-path">{doc.sc.path}</td>
                        <td class="ls-gen">{doc.sc.gen_path ?? '— soft only'}</td>
                        <td class="ls-state">
                            {#if isPending}<span class="ls-writing">⏳ writing…</span>
                            {:else}<span class="ls-ok">✓</span>{/if}
                        </td>
                    </tr>
                {/each}
            </tbody>
        </table>
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

<!-- ─────────────────────────────────────────────────────────────────────────
     Recursive Waft snippet.
     version touches establish Svelte 5 fine-grained reactivity on mutations.
     Sub-Wafts (Waft children of Waft) recurse at depth+1.
──────────────────────────────────────────────────────────────────────────── -->
{#snippet render_waft(waft: TheC, depth: number)}
    {@const wkey      = waft.sc.Waft as string}
    {@const is_active = !!waft.sc.active}
    {@const waft_docs = (() => { void waft.version; return waft.o({ Doc: 1 }) as TheC[] })()}
    {@const sub_wafts = (() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })()}
    {@const waft_mungs = waft.o({ mung_error: 1 }) as TheC[]}
    {@const add_form  = adding_doc[wkey]}

    <div class="ls-waft" style="margin-left: {depth * 14}px" class:ls-waft-active={is_active}>

        <!-- Waft header row: [key] [spacer] [●/○ active] [+ Doc] [✎] [×] -->
        <div class="ls-waft-hdr">
            {#if renaming[wkey] !== undefined && renaming[wkey] !== null}
                <input
                    class="ls-input ls-rename-input"
                    value={renaming[wkey]}
                    oninput={(ev) => renaming[wkey] = (ev.target as HTMLInputElement).value}
                    onblur={() => commit_rename_waft(waft)}
                    onkeydown={(ev) => {
                        if (ev.key === 'Enter') commit_rename_waft(waft)
                        if (ev.key === 'Escape') renaming[wkey] = null
                    }}
                    use:focus_on_mount
                />
            {:else}
                <span class="ls-waft-key">{wkey}</span>
            {/if}
            <span class="ls-spacer"></span>
            <button
                class="ls-icon-btn ls-active-btn"
                class:ls-is-active={is_active}
                title={is_active ? 'active' : 'set active'}
                onclick={() => set_waft_active(waft)}
            >{is_active ? '●' : '○'}</button>
            <button class="ls-icon-btn ls-adddoc-btn" title="add Doc" onclick={() => toggle_add_doc(waft)}>+ Doc</button>
            <button class="ls-icon-btn" title="rename" onclick={() => start_rename(wkey, wkey)}>✎</button>
            <button class="ls-icon-btn ls-del-btn" title="delete" onclick={() => delete_waft(waft)}>×</button>
        </div>

        <!-- mung errors -->
        {#if waft_mungs.length}
            <div class="ls-mung-errors">
                {#each waft_mungs as m}<div class="ls-error-msg">⛔ {m.sc.msg}</div>{/each}
            </div>
        {/if}

        <!-- +Doc form — expands when header +Doc is clicked -->
        {#if add_form}
            <div class="ls-add-doc-form">
                <div class="ls-add-doc-row">
                    <span class="ls-prefix-label">Ghost/</span>
                    <input
                        class="ls-input ls-input-path"
                        bind:value={add_form.ghost}
                        onkeydown={(ev) => ev.key === 'Enter' && submit_add_doc(waft)}
                        use:focus_on_mount
                    />
                </div>
                <div class="ls-add-doc-row">
                    <span class="ls-prefix-label">lib/src/</span>
                    <input
                        class="ls-input ls-input-path"
                        bind:value={add_form.libsrc}
                        onkeydown={(ev) => ev.key === 'Enter' && submit_add_doc(waft)}
                    />
                </div>
                <div class="ls-add-doc-row">
                    <span class="ls-prefix-label ls-prefix-dim">path:</span>
                    <input
                        class="ls-input ls-input-path"
                        bind:value={add_form.free}
                        onkeydown={(ev) => ev.key === 'Enter' && submit_add_doc(waft)}
                    />
                </div>
                <div class="ls-add-doc-actions">
                    <button class="ls-add-btn" onclick={() => submit_add_doc(waft)}>Add Doc</button>
                    <button class="ls-cancel-btn" onclick={() => adding_doc[wkey] = null}>cancel</button>
                </div>
            </div>
        {/if}

        <!-- Doc list -->
        {#each waft_docs as doc (doc.sc.path)}
            {@const dpath     = doc.sc.path as string}
            {@const codetype  = dpath.split('.').pop() ?? ''}
            {@const pointsC   = doc.o({ Points: 1 })[0] as TheC | undefined}
            {@const points    = (() => { void pointsC?.version; return pointsC ? pointsC.o({ Point: 1 }) as TheC[] : [] })()}
            {@const is_new    = !!doc.sc.new}
            {@const not_found = !!doc.sc.not_found}

            <div class="ls-doc" class:ls-doc-new={is_new} class:ls-doc-missing={not_found}>

                <!-- Doc header row -->
                <div class="ls-doc-hdr">
                    {#if renaming[dpath] !== undefined && renaming[dpath] !== null}
                        <input
                            class="ls-input ls-rename-input"
                            value={renaming[dpath]}
                            oninput={(ev) => renaming[dpath] = (ev.target as HTMLInputElement).value}
                            onblur={() => commit_rename_doc(doc, waft)}
                            onkeydown={(ev) => {
                                if (ev.key === 'Enter') commit_rename_doc(doc, waft)
                                if (ev.key === 'Escape') renaming[dpath] = null
                            }}
                            use:focus_on_mount
                        />
                    {:else}
                        <span class="ls-doc-path">{dpath}</span>
                    {/if}
                    {#if codetype}<span class="ls-badge">{codetype}</span>{/if}
                    {#if is_new}<span class="ls-flag ls-flag-new">new</span>{/if}
                    {#if not_found}<span class="ls-flag ls-flag-missing">?</span>{/if}
                    <span class="ls-spacer"></span>
                    <button class="ls-icon-btn" title="rename" onclick={() => start_rename(dpath, dpath)}>✎</button>
                    <button class="ls-icon-btn ls-del-btn" title="remove" onclick={() => delete_doc(doc, waft)}>×</button>
                </div>

                <!-- Points -->
                {#if points.length}
                    <div class="ls-points">
                        {#each points as pt (pt.sc.method)}
                            <div class="ls-point">
                                <span class="ls-point-method">{pt.sc.method}</span>
                                <button class="ls-icon-btn ls-del-btn" onclick={() => delete_point(pt, pointsC!, waft)}>×</button>
                            </div>
                        {/each}
                    </div>
                {/if}

                <!-- +Point — always shown; creates Points container on first use -->
                <div class="ls-add-point">
                    <span class="ls-prefix-dim">Point:</span>
                    <input
                        class="ls-input ls-input-sm"
                        placeholder="method name"
                        bind:value={adding_point[dpath]}
                        onkeydown={(ev) => ev.key === 'Enter' && add_point(doc, waft)}
                    />
                    <button class="ls-add-btn ls-add-btn-sm" onclick={() => add_point(doc, waft)}>+</button>
                </div>

            </div>
        {/each}

        <!-- sub-Wafts (recursive) -->
        {#each sub_wafts as sw (sw.sc.Waft)}
            {@render render_waft(sw, depth + 1)}
        {/each}

    </div>
{/snippet}

<script module>
    // Action: focus and select the element immediately on mount.
    // Used for rename inputs and the first +Doc path input.
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
    .ls-header {
        display: flex;
        align-items: center;
        gap: 0.5rem;
        margin-bottom: 0.3rem;
    }
    .ls-title { font-weight: bold; flex-shrink: 0 }
    .ls-header-btns { display: flex; gap: 0.25rem; margin-left: auto }
    .ls-hdr-btn {
        background: #1a1a28;
        border: 1px solid #334;
        border-radius: 3px;
        color: #88a;
        cursor: pointer;
        font-size: 0.74rem;
        padding: 0.15rem 0.4rem;
    }
    .ls-hdr-btn:hover      { background: #222238; color: #aac }
    .ls-hdr-btn-active     { background: #222238; border-color: #556; color: #aac }

    .ls-waft-input-row {
        display: flex;
        gap: 0.25rem;
        margin-bottom: 0.3rem;
    }
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

    /* ── loaded docs table ── */
    .ls-empty  { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-table  { width: 100%; border-collapse: collapse; margin-bottom: 0.4rem }
    .ls-table th { text-align: left; color: #888; font-weight: normal; padding: 0.1rem 0.3rem; border-bottom: 1px solid #333 }
    .ls-table td { padding: 0.2rem 0.3rem; border-bottom: 1px solid #1c1c1c; vertical-align: middle }
    .ls-pending td { background: #1a1a2a }
    .ls-path   { font-family: monospace; font-size: 0.76rem; color: #9ab }
    .ls-gen    { font-family: monospace; font-size: 0.76rem; color: #777 }
    .ls-state  { white-space: nowrap }
    .ls-writing { color: #aa8; font-style: italic }
    .ls-ok      { color: #4a8 }

    /* ── Waft tree ── */
    .ls-waft-section { margin-top: 0.4rem; border-top: 1px solid #222; padding-top: 0.3rem }
    .ls-waft {
        background: #13131d;
        border: 1px solid #252535;
        border-radius: 3px;
        padding: 0.3rem 0.4rem;
        margin-bottom: 0.25rem;
    }
    .ls-waft-active { border-color: #446 }
    .ls-waft-hdr {
        display: flex;
        align-items: center;
        gap: 0.25rem;
        min-height: 1.4rem;
        margin-bottom: 0.2rem;
    }
    .ls-waft-key { font-family: monospace; font-size: 0.76rem; color: #8ab; font-weight: bold }
    .ls-spacer   { flex: 1 }
    .ls-active-btn    { color: #446; font-size: 0.7rem }
    .ls-active-btn.ls-is-active { color: #88c }
    .ls-active-btn:hover { color: #88c }
    .ls-adddoc-btn    { font-size: 0.72rem; color: #558; padding: 0 0.2rem }
    .ls-adddoc-btn:hover { color: #88a }

    /* ── Doc row ── */
    .ls-doc {
        margin: 0.1rem 0 0.2rem 0.5rem;
        border-left: 2px solid #2a2a3a;
        padding-left: 0.35rem;
    }
    .ls-doc-new     { border-left-color: #3a5a3a }
    .ls-doc-missing { border-left-color: #5a3a2a; opacity: 0.8 }
    .ls-doc-hdr {
        display: flex;
        align-items: center;
        gap: 0.2rem;
        flex-wrap: wrap;
        min-height: 1.4rem;
    }
    .ls-doc-path { font-family: monospace; font-size: 0.76rem; color: #9ab }
    .ls-badge {
        font-size: 0.68rem;
        background: #1c1c28;
        border: 1px solid #333;
        border-radius: 2px;
        padding: 0 0.2rem;
        color: #778;
        flex-shrink: 0;
    }
    .ls-flag { font-size: 0.68rem; border-radius: 2px; padding: 0 0.2rem; flex-shrink: 0 }
    .ls-flag-new     { background: #1a3a1a; color: #6a9; border: 1px solid #2a5a2a }
    .ls-flag-missing { background: #3a2010; color: #c84; border: 1px solid #5a3010 }

    /* ── Points ── */
    .ls-points { margin: 0.1rem 0 0.1rem 0.3rem }
    .ls-point  { display: flex; align-items: center; gap: 0.3rem; padding: 0.05rem 0; border-bottom: 1px solid #1c1c28 }
    .ls-point-method { font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1 }

    /* ── +Doc form ── */
    .ls-add-doc-form {
        margin-top: 0.2rem;
        background: #0e0e1a;
        border: 1px solid #2a2a40;
        border-radius: 3px;
        padding: 0.3rem 0.35rem;
        display: flex;
        flex-direction: column;
        gap: 0.18rem;
    }
    .ls-add-doc-row { display: flex; align-items: center; gap: 0.2rem }
    .ls-input-path  { flex: 1 }
    .ls-add-doc-actions { display: flex; gap: 0.3rem; margin-top: 0.1rem }

    /* ── +Point ── */
    .ls-add-point { display: flex; align-items: center; gap: 0.2rem; margin-top: 0.15rem }
    .ls-prefix-label { font-family: monospace; font-size: 0.74rem; color: #556; flex-shrink: 0; white-space: nowrap }
    .ls-prefix-dim   { font-family: monospace; font-size: 0.74rem; color: #444; flex-shrink: 0 }

    /* ── shared controls ── */
    .ls-input {
        background: #0d0d14;
        border: 1px solid #333;
        border-radius: 3px;
        color: #aaa;
        font-family: monospace;
        font-size: 0.76rem;
        padding: 0.2rem 0.35rem;
        outline: none;
    }
    .ls-input:focus   { border-color: #446 }
    .ls-input-sm      { width: 8.5rem }
    .ls-rename-input  { flex: 1; min-width: 6rem }
    .ls-add-btn {
        background: #1a1a2a;
        border: 1px solid #334;
        border-radius: 3px;
        color: #88a;
        cursor: pointer;
        font-size: 0.76rem;
        padding: 0.2rem 0.4rem;
        white-space: nowrap;
        flex-shrink: 0;
    }
    .ls-add-btn:hover    { background: #222238; color: #aac }
    .ls-add-btn:disabled { opacity: 0.35; cursor: default }
    .ls-add-btn-sm       { padding: 0.15rem 0.3rem }
    .ls-cancel-btn {
        background: none;
        border: none;
        color: #555;
        cursor: pointer;
        font-size: 0.76rem;
        padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover { color: #999 }
    .ls-icon-btn {
        background: none;
        border: none;
        color: #444;
        cursor: pointer;
        font-size: 0.8rem;
        line-height: 1;
        padding: 0 0.15rem;
        flex-shrink: 0;
    }
    .ls-icon-btn:hover { color: #aaa }
    .ls-del-btn:hover  { color: #f66 }
</style>
