<script lang="ts">
    // Liesui.svelte — reactive UI for Lies.
    //
    // Mounted by Otro via H/{watched:UIs}/{UI:'Lies'}.
    // Receives H (the root Mundo house).
    //
    // Layout
    // ──────
    //   [🔪 Lies]  [Waft: _____ +]       ← header row: +Waft inline
    //
    //   loaded docs table (flat, all open docs)
    //
    //   Waft** recursive tree
    //     Waft:Ghost/Tour  [rename] [×]
    //       Doc  Ghost/test/Hello.g  [g]  [rename] [×]
    //         Points  Idzeugnosis  [×]
    //         [+ Point ___]
    //       [+ Doc] → expands 3-input form:
    //         Ghost/[_____]    lib/src/[_____]    [_____]
    //       Sub-Waft (recursive…)
    //     Waft:Look/2025-04-29/14_1  (look_doc: …)
    //
    // CRUD mechanics
    // ──────────────
    //   Waft / Doc / Point mutations go directly to the TheC particles;
    //   watch_c in Lies fires the throttled waft_save.
    //
    //   +Waft (header): fires e:Lies_open_waft{path} — same as a Plan Prep.
    //   +Doc (per Waft): expands a 3-input form; first non-empty prefix wins.
    //     Ghost/[___]  →  Ghost/${input}
    //     lib/src/[___]  →  lib/src/${input}
    //     [___]  →  ${input}  (any path)
    //   The Doc particle gains sc.new=1; Lies clears it on successful load.
    //
    //   Rename: inline input replaces label on click; Enter/blur commits.
    //   Delete: drop() the particle and bump_version() the parent.
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

    // ── UI state ─────────────────────────────────────────────────────

    // +Waft inline form in header
    let new_waft_path = $state('')

    // Rename state: key → new value being typed (null = not renaming)
    let renaming: Record<string, string | null> = $state({})

    // +Doc form state per waft key: null = closed, obj = open
    let adding_doc: Record<string, { ghost: string, libsrc: string, free: string } | null> = $state({})

    // +Point form state per doc path
    let adding_point: Record<string, string> = $state({})

    // ── errors ───────────────────────────────────────────────────────

    function dismiss_errors() {
        if (!LS) return
        for (const e of LS.o({ compile_error: 1 }) as TheC[]) LS.drop(e)
        LS.bump_version()
    }

    // ── +Waft ────────────────────────────────────────────────────────
    function open_new_waft() {
        const path = new_waft_path.trim()
        if (!path || !LS) return
        H.i_elvisto('Lies/Lies', 'e_Lies_open_waft', { path })
        new_waft_path = ''
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
        if (form.ghost.trim())  path = `Ghost/${form.ghost.trim()}`
        else if (form.libsrc.trim()) path = `lib/src/${form.libsrc.trim()}`
        else if (form.free.trim())   path = form.free.trim()
        if (!path) return
        const codetype = path.split('.').pop() ?? ''
        const doc = waft.oai({ Doc: 1, path })
        doc.sc.codetype = codetype
        doc.sc.new = 1   // Lies clears this on successful load
        waft.bump_version()
        adding_doc[key] = null
    }

    // ── +Point ───────────────────────────────────────────────────────
    function add_point(doc: TheC, waft: TheC) {
        const method = (adding_point[doc.sc.path as string] ?? '').trim()
        if (!method) return
        let pointsC = doc.o({ Points: 1 })[0] as TheC | undefined
        if (!pointsC) { pointsC = doc.i({ Points: 1 }); doc.bump_version() }
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
        const key     = waft.sc.Waft as string
        const newPath = renaming[key]?.trim()
        renaming[key] = null
        if (!newPath || newPath === key) return
        waft.sc.Waft  = newPath
        LS?.bump_version()
    }

    function commit_rename_doc(doc: TheC, waft: TheC) {
        const key     = doc.sc.path as string
        const newPath = renaming[key]?.trim()
        renaming[key] = null
        if (!newPath || newPath === key) return
        doc.sc.path     = newPath
        doc.sc.codetype = newPath.split('.').pop() ?? ''
        waft.bump_version()
    }

    // ── Delete ───────────────────────────────────────────────────────
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

    <!-- ── header row with inline +Waft form ── -->
    <div class="ls-header">
        <span class="ls-title">🔪 Lies</span>
        <form class="ls-new-waft" onsubmit={(ev) => { ev.preventDefault(); open_new_waft() }}>
            <span class="ls-prefix-label">Waft:</span>
            <input
                class="ls-input ls-input-sm"
                placeholder="Ghost/Tour"
                bind:value={new_waft_path}
            />
            <button class="ls-add-btn ls-add-btn-sm" type="submit">+</button>
        </form>
    </div>

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
            <thead>
                <tr>
                    <th>source path</th>
                    <th>gen path</th>
                    <th>state</th>
                </tr>
            </thead>
            <tbody>
                {#each loaded_docs as doc (doc.sc.path)}
                    {@const isPending = pending.some((p: TheC) => p.sc.path === doc.sc.path)}
                    <tr class:ls-pending={isPending}>
                        <td class="ls-path">{doc.sc.path}</td>
                        <td class="ls-gen">{doc.sc.gen_path ?? '— soft only'}</td>
                        <td class="ls-state">
                            {#if isPending}
                                <span class="ls-writing">⏳ writing…</span>
                            {:else}
                                <span class="ls-ok">✓</span>
                            {/if}
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

<!-- ── recursive Waft snippet ────────────────────────────────────────────── -->
<!--
    Renders one Waft and all its children (Docs, Points, sub-Wafts) at the
    given indent depth.  Sub-Wafts recurse via {@render render_waft(sw, depth+1)}.
    version touches establish Svelte 5 fine-grained reactivity on mutations.
-->
{#snippet render_waft(waft: TheC, depth: number)}
    {@const wkey      = waft.sc.Waft as string}
    {@const is_look   = wkey.startsWith('Look/')}
    {@const waft_docs = (() => { void waft.version; return waft.o({ Doc: 1 }) as TheC[] })()}
    {@const sub_wafts = (() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })()}
    {@const waft_mungs = waft.o({ mung_error: 1 }) as TheC[]}
    {@const add_form  = adding_doc[wkey]}

    <div class="ls-waft" style="margin-left: {depth * 14}px">

        <!-- Waft header row -->
        <div class="ls-waft-hdr">
            {#if renaming[wkey] !== undefined && renaming[wkey] !== null}
                <input
                    class="ls-input ls-rename-input"
                    value={renaming[wkey]}
                    oninput={(ev) => renaming[wkey] = (ev.target as HTMLInputElement).value}
                    onblur={() => commit_rename_waft(waft)}
                    onkeydown={(ev) => { if (ev.key === 'Enter') commit_rename_waft(waft); if (ev.key === 'Escape') { renaming[wkey] = null } }}
                    use:focus_on_mount
                />
            {:else}
                <span class="ls-waft-key" class:ls-look={is_look}>
                    Waft:{wkey}
                    {#if is_look}<span class="ls-look-doc"> ↳ {waft.sc.look_doc}</span>{/if}
                </span>
            {/if}
            <span class="ls-spacer"></span>
            {#if !is_look}
                <button class="ls-icon-btn" title="rename" onclick={() => start_rename(wkey, wkey)}>✎</button>
            {/if}
            <button class="ls-icon-btn ls-del-btn" title="delete" onclick={() => delete_waft(waft)}>×</button>
        </div>

        <!-- mung errors -->
        {#if waft_mungs.length}
            <div class="ls-mung-errors">
                {#each waft_mungs as m}<div class="ls-error-msg">⛔ {m.sc.msg}</div>{/each}
            </div>
        {/if}

        <!-- Doc list -->
        {#each waft_docs as doc (doc.sc.path)}
            {@const dpath     = doc.sc.path as string}
            {@const codetype  = doc.sc.codetype as string || dpath.split('.').pop() || ''}
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
                            onkeydown={(ev) => { if (ev.key === 'Enter') commit_rename_doc(doc, waft); if (ev.key === 'Escape') { renaming[dpath] = null } }}
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
                    <button class="ls-icon-btn ls-del-btn" title="remove doc" onclick={() => delete_doc(doc, waft)}>×</button>
                </div>

                <!-- Points -->
                {#if points.length}
                    <div class="ls-points">
                        {#each points as pt (pt.sc.method)}
                            <div class="ls-point">
                                <span class="ls-point-method">{pt.sc.method}</span>
                                <button class="ls-icon-btn ls-del-btn" title="remove point" onclick={() => delete_point(pt, pointsC!, waft)}>×</button>
                            </div>
                        {/each}
                    </div>
                {/if}

                <!-- +Point form (shown when Points container exists or always as a stub) -->
                <div class="ls-add-point">
                    <input
                        class="ls-input ls-input-sm"
                        placeholder={pointsC ? 'method name' : '+ Points: method'}
                        bind:value={adding_point[dpath]}
                        onkeydown={(ev) => ev.key === 'Enter' && add_point(doc, waft)}
                    />
                    <button class="ls-add-btn ls-add-btn-sm" onclick={() => add_point(doc, waft)}>+</button>
                </div>

            </div>
        {/each}

        <!-- +Doc button / 3-input form -->
        {#if !is_look}
            {#if add_form}
                <div class="ls-add-doc-form">
                    <div class="ls-add-doc-row">
                        <span class="ls-prefix-label">Ghost/</span>
                        <input
                            class="ls-input ls-input-path"
                            placeholder="test/Foo.g"
                            bind:value={add_form.ghost}
                            onkeydown={(ev) => ev.key === 'Enter' && submit_add_doc(waft)}
                            use:focus_on_mount
                        />
                    </div>
                    <div class="ls-add-doc-row">
                        <span class="ls-prefix-label">lib/src/</span>
                        <input
                            class="ls-input ls-input-path"
                            placeholder="some/file.ts"
                            bind:value={add_form.libsrc}
                            onkeydown={(ev) => ev.key === 'Enter' && submit_add_doc(waft)}
                        />
                    </div>
                    <div class="ls-add-doc-row">
                        <span class="ls-prefix-label ls-prefix-any">path:</span>
                        <input
                            class="ls-input ls-input-path"
                            placeholder="any/path"
                            bind:value={add_form.free}
                            onkeydown={(ev) => ev.key === 'Enter' && submit_add_doc(waft)}
                        />
                    </div>
                    <div class="ls-add-doc-actions">
                        <button class="ls-add-btn" onclick={() => submit_add_doc(waft)}>Add Doc</button>
                        <button class="ls-cancel-btn" onclick={() => adding_doc[wkey] = null}>cancel</button>
                    </div>
                </div>
            {:else}
                <button class="ls-add-doc-btn" onclick={() => toggle_add_doc(waft)}>+ Doc</button>
            {/if}
        {/if}

        <!-- sub-Wafts (recursive) -->
        {#each sub_wafts as sw (sw.sc.Waft)}
            {@render render_waft(sw, depth + 1)}
        {/each}

    </div>
{/snippet}

<!-- ── focus_on_mount Svelte 5 action ── -->
<script module>
    // Action: focus the element as soon as it mounts (rename inputs, first Doc path input).
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
        gap: 0.4rem;
        margin-bottom: 0.4rem;
        flex-wrap: wrap;
    }
    .ls-title  { font-weight: bold; flex-shrink: 0 }
    .ls-new-waft {
        display: flex;
        align-items: center;
        gap: 0.2rem;
        margin-left: auto;
    }
    .ls-prefix-label {
        font-family: monospace;
        font-size: 0.76rem;
        color: #666;
        white-space: nowrap;
        flex-shrink: 0;
    }
    .ls-prefix-any { color: #555 }

    /* ── errors ── */
    .ls-errors {
        background: #300; border: 1px solid #c44; border-radius: 3px;
        padding: 0.3rem 0.5rem; margin-bottom: 0.4rem;
        color: #f88; display: flex; flex-wrap: wrap; gap: 0.2rem; align-items: flex-start;
    }
    .ls-dismiss { margin-left: auto; background: none; border: none; color: #f88; cursor: pointer; font-size: 1rem; line-height: 1 }
    .ls-error-msg { width: 100%; font-size: 0.76rem; font-family: monospace }
    .ls-mung-errors { margin: 0.2rem 0 }

    /* ── loaded docs table ── */
    .ls-empty { color: #666; padding: 0.2rem 0; font-style: italic }
    .ls-table { width: 100%; border-collapse: collapse; margin-bottom: 0.4rem }
    .ls-table th { text-align: left; color: #888; font-weight: normal; padding: 0.1rem 0.3rem; border-bottom: 1px solid #333 }
    .ls-table td { padding: 0.2rem 0.3rem; border-bottom: 1px solid #1c1c1c; vertical-align: middle }
    .ls-pending td { background: #1a1a2a }
    .ls-path  { font-family: monospace; font-size: 0.76rem; color: #9ab }
    .ls-gen   { font-family: monospace; font-size: 0.76rem; color: #777 }
    .ls-state { white-space: nowrap }
    .ls-writing { color: #aa8; font-style: italic }
    .ls-ok      { color: #4a8 }

    /* ── Waft section ── */
    .ls-waft-section { margin-top: 0.5rem; border-top: 1px solid #222; padding-top: 0.4rem }
    .ls-waft {
        background: #13131d;
        border: 1px solid #252535;
        border-radius: 3px;
        padding: 0.3rem 0.4rem;
        margin-bottom: 0.3rem;
    }
    .ls-waft-hdr {
        display: flex;
        align-items: center;
        gap: 0.3rem;
        margin-bottom: 0.25rem;
        min-height: 1.4rem;
    }
    .ls-waft-key {
        font-family: monospace;
        font-size: 0.76rem;
        color: #8ab;
        font-weight: bold;
    }
    .ls-look { color: #778; font-style: italic }
    .ls-look-doc { color: #556; font-weight: normal }
    .ls-spacer { flex: 1 }

    /* ── Doc row ── */
    .ls-doc {
        margin: 0.15rem 0 0.2rem 0.6rem;
        border-left: 2px solid #2a2a3a;
        padding-left: 0.4rem;
    }
    .ls-doc-new     { border-left-color: #3a5a3a }
    .ls-doc-missing { border-left-color: #5a3a2a; opacity: 0.8 }
    .ls-doc-hdr {
        display: flex;
        align-items: center;
        gap: 0.25rem;
        flex-wrap: wrap;
    }
    .ls-doc-path { font-family: monospace; font-size: 0.76rem; color: #9ab }
    .ls-badge {
        font-size: 0.68rem;
        background: #222;
        border: 1px solid #333;
        border-radius: 2px;
        padding: 0 0.2rem;
        color: #888;
        flex-shrink: 0;
    }
    .ls-flag {
        font-size: 0.68rem;
        border-radius: 2px;
        padding: 0 0.2rem;
        flex-shrink: 0;
    }
    .ls-flag-new     { background: #1a3a1a; color: #6a9; border: 1px solid #2a5a2a }
    .ls-flag-missing { background: #3a2010; color: #c84; border: 1px solid #5a3010 }

    /* ── Points ── */
    .ls-points { margin: 0.15rem 0 0.1rem 0.4rem }
    .ls-point {
        display: flex;
        align-items: center;
        gap: 0.3rem;
        padding: 0.05rem 0;
        border-bottom: 1px solid #1c1c28;
    }
    .ls-point-method { font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1 }

    /* ── +Doc form ── */
    .ls-add-doc-btn {
        margin-top: 0.2rem;
        background: #1a1a28;
        border: 1px dashed #334;
        border-radius: 3px;
        color: #668;
        font-size: 0.74rem;
        cursor: pointer;
        padding: 0.15rem 0.4rem;
        width: 100%;
        text-align: left;
    }
    .ls-add-doc-btn:hover { color: #88a; border-color: #446 }
    .ls-add-doc-form {
        margin-top: 0.25rem;
        background: #0e0e1a;
        border: 1px solid #2a2a40;
        border-radius: 3px;
        padding: 0.35rem 0.4rem;
        display: flex;
        flex-direction: column;
        gap: 0.2rem;
    }
    .ls-add-doc-row {
        display: flex;
        align-items: center;
        gap: 0.25rem;
    }
    .ls-input-path { flex: 1 }
    .ls-add-doc-actions {
        display: flex;
        gap: 0.3rem;
        margin-top: 0.1rem;
    }

    /* ── +Point ── */
    .ls-add-point {
        display: flex;
        gap: 0.2rem;
        margin-top: 0.2rem;
    }

    /* ── shared controls ── */
    .ls-input {
        background: #0d0d14;
        border: 1px solid #333;
        border-radius: 3px;
        color: #aaa;
        font-family: monospace;
        font-size: 0.76rem;
        padding: 0.2rem 0.4rem;
        outline: none;
    }
    .ls-input:focus  { border-color: #446 }
    .ls-input-sm     { width: 9rem }
    .ls-rename-input { flex: 1; min-width: 6rem }
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
    .ls-add-btn:hover   { background: #222238; color: #aac }
    .ls-add-btn-sm      { padding: 0.15rem 0.35rem }
    .ls-cancel-btn {
        background: none;
        border: none;
        color: #666;
        cursor: pointer;
        font-size: 0.76rem;
        padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover { color: #999 }
    .ls-icon-btn {
        background: none;
        border: none;
        color: #555;
        cursor: pointer;
        font-size: 0.8rem;
        line-height: 1;
        padding: 0 0.15rem;
        flex-shrink: 0;
    }
    .ls-icon-btn:hover { color: #aaa }
    .ls-del-btn:hover  { color: #f66 }
</style>
