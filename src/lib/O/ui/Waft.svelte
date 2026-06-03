<script lang="ts">
    // Waft.svelte — one Waft item in the recursive Waft tree.
    //
    // Extracted from Liesui to be a stable component boundary:
    // Svelte reconciles {#each} items by component key (waft.sc.Waft) so
    // this component survives Liesui re-renders, keeping form state and
    // focused inputs stable across think() ticks.

    import type { TheC }    from "$lib/data/Stuff.svelte"
    import type { House }   from "$lib/O/Housing.svelte"
    import { peel, depeel } from "$lib/Y.svelte"
    import { SvelteSet }    from "svelte/reactivity"
    import { tick }         from "svelte"
    import EncodingSplatter from "$lib/O/ui/EncodingSplatter.svelte"
    import PeelInput        from "$lib/O/ui/PeelInput.svelte"

    let { H, w, waft, depth = 0, on_active, on_delete, examining }: {
        H:         House
        w:         TheC          // Lies's w particle — for live state downstream
        waft:      TheC
        depth?:    number
        on_active: (waft: TheC) => void
        on_delete: (waft: TheC) => void
        examining?: TheC         // from Liesui; derives Spotlight glow targets
    } = $props()

    // ── item-type descriptor table ────────────────────────────────────
    //
    //   Point, Doc, What all share the same PeelInput UX.
    //   mk_key:     sc key that carries the primary value
    //   mk_ph:      placeholder for the mainkey input
    //   sc_ph:      placeholder for the sc extras input; '' hides it
    //   mk_default: value used when mainkey is left empty on submit
    //   make_sc:    builds the full sc for oai() from (val, sc_str)
    //   to_display: renders a C as its peel string for the idle row
    //   on_open:    the navigation action for clicking the display value
    //
    //   < Doc: directory-list autocomplete for Ghost/* paths
    //   < Doc: bare name auto-prefixes Ghost/ and appends .g
    //   < Point: clicking 'method' part of placeholder focuses sc field
    //     with 'method:' pre-filled; clicking 'such' appends at end of value
    //   < What/Doc: extras sc field (tag:foo) not yet used by anything —
    //     stub it in now so the UX accepts it, wire it up when needed
    const ITEM_TYPES = {
        Point: {
            mk_key:     'Point' as const,
            mk_ph:      'fuzzyName',
            sc_ph:      'method:Name,call',
            mk_default: 1 as string | number,
            make_sc:    (val: string, sc_str: string) => ({
                Point: val === '' ? 1 : val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            to_display: (c: TheC) => {
                const sc = c.sc as Record<string, any>
                for (const [, v] of Object.entries(sc))
                    if (v === null || typeof v === 'object')
                        throw `to_display Point: non-scalar in sc`
                const d = depeel(sc)
                if (!d.startsWith('Point') && d !== 'Point')
                    throw `to_display Point: 'Point' not first: ${d}`
                return d
            },
            on_open: (item: TheC, ctx?: { dpath?: string }) =>
                H.i_elvisto('Lang/Lang', 'Dock_open', {
                    path:  ctx?.dpath,
                    point: (item.sc as any).method ?? item.sc.Point,
                }),
        },
        Doc: {
            mk_key:     'Doc' as const,
            mk_ph:      'Ghost/…',
            sc_ph:      '',
            mk_default: '' as string | number,
            make_sc:    (val: string, sc_str: string) => ({
                Doc: resolve_doc_path(val),
                ...(sc_str ? peel(sc_str) : {})
            }),
            to_display: (c: TheC) => String(c.sc.Doc ?? ''),
            on_open:    (item: TheC) => focus_doc(item),
        },
        What: {
            mk_key:     'What' as const,
            mk_ph:      'label',
            sc_ph:      '',
            mk_default: '' as string | number,
            make_sc:    (val: string, sc_str: string) => ({
                What: val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            to_display: (c: TheC) => String(c.sc.What ?? '·'),
            on_open:    (item: TheC) =>
                H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what: item, dive: true }),
        },
    } as const
    type ItemType = keyof typeof ITEM_TYPES

    function resolve_doc_path(raw: string): string {
        const v = raw.trim()
        if (!v) return ''
        // bare name with no slash → Ghost/Name.g
        if (!v.includes('/')) return `Ghost/${v.includes('.') ? v : v + '.g'}`
        return v
    }

    // ── reactive reads ────────────────────────────────────────────────
    let wkey          = $derived(waft.sc.Waft as string)
    let is_active     = $derived(!!waft.sc.active)
    let waft_children = $derived((() => { void waft.version; return waft.o() as TheC[] })())
    let sub_wafts     = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs    = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())

    // ── unified item-edit form state ──────────────────────────────────
    //
    //   editing: the one item C currently open for editing/adding.
    //   Since only one form is ever open, a single $state pair holds the draft.
    //   draft_type lives in a WeakMap (non-reactive; read only on submit).
    //
    //   add_picking_C: container Cs with the type-picker open.
    //   add_type_C:    the ItemType chosen for the pending add-form on a container.
    //
    //   Waft rename — kept separate; Waft path is special (fires e:Lies_rename_waft)
    let editing      = new SvelteSet<TheC>()
    let draft_mk     = $state('')
    let draft_sc     = $state('')
    const draft_type = new WeakMap<TheC, ItemType>()

    let add_picking_C = new SvelteSet<TheC>()
    const add_type_C  = new WeakMap<TheC, ItemType>()

    let renaming_waft = $state<string | null>(null)

    //   Seen:origin clone editing — keyed by clone spec string
    //   < migrate to C-keyed approach once origin clones have stable identity
    let clone_edit_open: Record<string, boolean> = $state({})
    let clone_edit_val:  Record<string, string>  = $state({})
    let clone_edit_sc:   Record<string, string>  = $state({})

    // ── add-item form ─────────────────────────────────────────────────
    function toggle_add_pick(container: TheC) {
        if (add_picking_C.has(container)) add_picking_C.delete(container)
        else add_picking_C.add(container)
    }
    function pick_and_open(container: TheC, t: ItemType) {
        add_picking_C.delete(container)
        open_add(container, t)
    }
    function open_add(container: TheC, t: ItemType) {
        editing.clear()
        editing.add(container)
        add_type_C.set(container, t)
        draft_mk = ''
        draft_sc = ''
    }
    function cancel_add(container: TheC) {
        editing.delete(container)
    }
    function submit_add(container: TheC) {
        const t    = add_type_C.get(container)!
        const val  = draft_mk.trim()
        const sc_s = draft_sc.trim()
        if (!val && t !== 'Point') return
        const td  = ITEM_TYPES[t]
        const sc  = td.make_sc(val, sc_s)
        if (t === 'Doc' && !(sc as any).Doc) return
        const child = container.oai(sc)
        if (t === 'Doc') child.sc.new = 1
        container.bump_version()
        waft.bump_version()
        cancel_add(container)
    }

    // ── edit existing item ────────────────────────────────────────────
    //
    //   The item C itself is the key — same C can't be edited twice simultaneously.
    //   For What "rename", the item IS the container (what === what), same pattern.
    function start_edit(item: TheC, t: ItemType) {
        const sc     = item.sc as Record<string, any>
        const mk_key = ITEM_TYPES[t].mk_key
        const pval   = sc[mk_key]
        editing.clear()
        editing.add(item)
        draft_type.set(item, t)
        draft_mk = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        draft_sc = Object.entries(sc)
            .filter(([ky]) => ky !== mk_key)
            .map(([ky, v]) => v === 1 ? ky : `${ky}:${v}`)
            .join(',')
    }
    function cancel_edit(item: TheC) {
        editing.delete(item)
    }
    async function submit_edit(container: TheC, item: TheC) {
        const t      = draft_type.get(item)!
        const td     = ITEM_TYPES[t]
        const val    = draft_mk.trim()
        const sc_str = draft_sc.trim()
        if (!val && t === 'What') return
        if (t === 'Doc' && !resolve_doc_path(val)) return
        const new_sc = td.make_sc(val, sc_str)
        // fire rename event before mutating sc, so Lies can drop the old open_req
        if (t === 'Doc') {
            const old_path = item.sc.Doc as string
            const new_path = (new_sc as any).Doc as string
            if (new_path && new_path !== old_path) {
                delete item.sc.not_found
                delete item.sc.new
                H.i_elvisto('Lies/Lies', 'Lies_rename_doc', { old_path, new_path, waft_path: wkey })
            }
        }
        Object.keys(item.sc).forEach(k => delete item.sc[k])
        Object.assign(item.sc, new_sc)
        container.bump_version()
        waft.bump_version()
        // await tick so derived display values re-read updated sc before edit mode clears
        await tick()
        editing.delete(item)
    }
    function delete_item(item: TheC, container: TheC) {
        container.drop(item)
        container.bump_version()
        waft.bump_version()
    }

    // ── What spotlight helper ─────────────────────────────────────────
    function is_spotlight(what: TheC): boolean {
        void examining?.vers
        const spot = examining?.o?.({ Spotlight: 1 })?.[0] as any
        if (!spot?.sc.src) return false
        let node: any = spot.sc.src
        while (node) { if (node === what) return true; node = node.c?.up }
        return false
    }

    // ── Seen:origin clone editing ─────────────────────────────────────
    //
    //   %Seem:origin is the immutable snapshot from the last pull.
    //   Editing a clone fires e:Lang_LE_edit { spec, patch } — Lang patches
    //   the working clone's sc in-place, and encode-compare on the next
    //   maneuvre tick factors in the new value.
    function get_LE(): TheC | undefined {
        const lang_w = (examining?.c as any)?.lang_w as TheC | undefined
        if (!lang_w) return undefined
        const workon = (lang_w.o({ req: 'workon' }) as TheC[])[0]
        return (workon?.o({ LE: 1 }) as TheC[])[0]
    }
    function get_origin_clones(): TheC[] {
        // %LE/%Seem:origin — the snapshot root; sc.C is the clone root TheC
        const LE = get_LE()
        if (!LE) return []
        const origin_seem = (LE.o({ Seem: 'origin' }) as TheC[])[0]
        const origin_root = origin_seem?.sc.C as TheC | undefined
        if (!origin_root) return []
        return origin_root.o({ Point: 1 }) as TheC[]
    }
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
        // e:Lang_LE_edit patches the working clone; encode-compare on next tick detects the change
        H.i_elvisto('Lang/Lang', 'Lang_LE_edit', { spec, patch })
        clone_edit_open[spec] = false
    }

    // ── Rename Waft ───────────────────────────────────────────────────
    //
    //   Fires e:Lies_rename_waft so Lies can persist a waft_rename_job before
    //   touching any wormhole files.  Lies mutates waft.sc.Waft after writing
    //   the new snap.  Renaming is a move; old snap is left in place.
    function cancel_rename_waft() { renaming_waft = null }
    function commit_rename_waft() {
        const n = renaming_waft?.trim() ?? ''
        renaming_waft = null
        if (!n || n === wkey) return
        H.i_elvisto('Lies/Lies', 'Lies_rename_waft', { old_path: wkey, new_path: n })
    }

    // ── Doc focus ─────────────────────────────────────────────────────
    function focus_doc(doc: TheC) {
        H.i_elvisto('Lies/Lies', 'Lies_set_cursor', { doc_C: doc, waft_key: wkey })
    }

    // ── peel_item_props ───────────────────────────────────────────────
    //
    //   Returns all PeelInput props for a given item C in its container,
    //   including on_edit, on_del, and optionally on_add — so the call site
    //   is always a single <PeelInput /> with no surrounding button markup.
    //
    //   on_open comes from ITEM_TYPES[t].on_open, parameterised by ctx.
    //   on_add is only supplied for What header rows (toggles the add-child picker).
    //
    //   Called once per item row — no duplication between render_doc/render_what.
    function peel_item_props(
        item:      TheC,
        container: TheC,
        t:         ItemType,
        ctx?:      { dpath?: string; on_add?: () => void }
    ) {
        const td   = ITEM_TYPES[t]
        const open = editing.has(item)
        return {
            label:        t,
            open,
            display:      td.to_display(item),
            mk_ph:        td.mk_ph,
            sc_ph:        td.sc_ph,
            mainkey:      open ? draft_mk : '',
            on_mk:        (v: string) => { draft_mk = v },
            sc_str:       open ? draft_sc : '',
            on_sc:        (v: string) => { draft_sc = v },
            submit_label: '✓' as string,
            on_open:      () => td.on_open(item, ctx),
            on_submit:    () => submit_edit(container, item),
            on_cancel:    () => cancel_edit(item),
            on_edit:      () => start_edit(item, t),
            on_del:       () => delete_item(item, container),
            on_add:       ctx?.on_add,
        }
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
            <button class="ls-icon-btn" title="rename Waft"
                    onclick={() => renaming_waft = wkey}>✎</button>
            <button class="ls-icon-btn ls-del-btn" title="delete Waft"
                    onclick={() => on_delete(waft)}>×</button>
            <button class="ls-icon-btn ls-add-btn-icon" title="add child"
                    onclick={() => toggle_add_pick(waft)}>+</button>
        {/if}
    </div>

    {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
        <EncodingSplatter {waft} />
    {/if}

    <!-- add-child picker + form at Waft level -->
    {#if add_picking_C.has(waft)}
        {@render render_type_picker(waft, ['What', 'Doc', 'Point'])}
    {/if}
    {#if editing.has(waft) && add_type_C.has(waft)}
        {@render render_add_form(waft)}
    {/if}

    <!-- children — iterated whole, switched by type key -->
    {#each waft_children as child (child)}
        {#if (child.sc as any).What}
            {@render render_what(child as TheC)}
        {:else if (child.sc as any).Doc}
            {@render render_doc(child as TheC, waft)}
        {/if}
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
                            display={ITEM_TYPES.Point.to_display(clone)}
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

    <!-- sub-Wafts (recursive) -->
    {#each sub_wafts as sw (sw.sc.Waft)}
        <svelte:self {H} {w} waft={sw} depth={depth + 1} {examining}
            {on_active} {on_delete} />
    {/each}

</div>

<!-- render_type_picker — type button row for adding a child to container -->
{#snippet render_type_picker(container: TheC, types: ItemType[])}
    <div class="ls-type-picker">
        {#each types as t (t)}
            <button class="ls-pick-btn" onclick={() => pick_and_open(container, t)}>{t}</button>
        {/each}
        <button class="ls-cancel-btn" onclick={() => add_picking_C.delete(container)}>cancel</button>
    </div>
{/snippet}

<!-- render_add_form — PeelInput open for a new child of container -->
{#snippet render_add_form(container: TheC)}
    {@const t = add_type_C.get(container)!}
    <div class="ls-add-row">
        <PeelInput
            label={t}
            open={true}
            mk_ph={ITEM_TYPES[t].mk_ph}
            sc_ph={ITEM_TYPES[t].sc_ph}
            mainkey={draft_mk}
            on_mk={(v) => draft_mk = v}
            sc_str={draft_sc}
            on_sc={(v) => draft_sc = v}
            submit_label="+"
            on_submit={() => submit_add(container)}
            on_cancel={() => cancel_add(container)} />
    </div>
{/snippet}

<!-- render_doc — Doc header + its Points.
     container is the parent C (Waft or What) — used for edit key scoping.
     Points are added via the containing What/Waft add-child form. -->
{#snippet render_doc(doc: TheC, container: TheC)}
    {@const dpath     = doc.sc.Doc as string}
    {@const pts       = (() => { void doc.version; return doc.o({ Point: 1 }) as TheC[] })()}
    {@const doc_whats = (() => { void doc.version; return doc.o({ What: 1 }) as TheC[] })()}

    <div class="ls-doc"
         class:ls-doc-new={!!doc.sc.new}
         class:ls-doc-missing={!!doc.sc.not_found && !doc.sc.new}>

        <!-- Doc header row — single PeelInput owns display + ✎ × -->
        <div class="ls-item-hdr">
            <PeelInput {...peel_item_props(doc, container, 'Doc')} />
        </div>

        <!-- Points and nested Whats sit inside an indented children block -->
        {#if pts.length || doc_whats.length}
            <div class="ls-doc-children">
                {#each pts as pt (pt)}
                    <div class="ls-point">
                        <PeelInput {...peel_item_props(pt, doc, 'Point', { dpath })} />
                    </div>
                {/each}
                <!-- %What children of this %Doc (Doc > What nesting, e.g. time-slices) -->
                {#each doc_whats as dw (dw)}
                    {@render render_what(dw)}
                {/each}
            </div>
        {/if}

    </div>
{/snippet}

<!-- render_what — What header + its children, all contained inside the bordered block.
     Spotlight beam glow when cursor is aimed at this What or any ancestor.
     No wdepth param — nesting ls-what inside ls-what-children inside ls-what
     stacks the borders naturally; each level indents via padding-left. -->
{#snippet render_what(what: TheC)}
    {@const what_children = (() => { void what.version; return what.o() as TheC[] })()}
    {@const what_pts_only = (() => { void what.version; return what.o({ Point: 1 }) as TheC[] })()}

    <div class="ls-what" class:ls-what-active={is_spotlight(what)}>

        <!-- What header — single PeelInput owns display + ✎ × + -->
        <div class="ls-what-hdr">
            <PeelInput {...peel_item_props(what, what, 'What', {
                on_add: () => toggle_add_pick(what),
            })} />
        </div>

        <div class="ls-what-children">

            <!-- add-child picker + form -->
            {#if add_picking_C.has(what)}
                {@render render_type_picker(what, ['Point', 'Doc', 'What'])}
            {/if}
            {#if editing.has(what) && add_type_C.has(what)}
                {@render render_add_form(what)}
            {/if}

            <!-- Points in one block so last-child border suppression works -->
            {#if what_pts_only.length}
                <div class="ls-points">
                    {#each what_pts_only as pt (pt)}
                        <div class="ls-point">
                            <PeelInput {...peel_item_props(pt, what, 'Point')} />
                        </div>
                    {/each}
                </div>
            {/if}

            <!-- non-Point children in insertion order, switched by type -->
            {#each what_children as child (child)}
                {#if (child.sc as any).Doc}
                    {@render render_doc(child as TheC, what)}
                {:else if (child.sc as any).What}
                    {@render render_what(child as TheC)}
                {/if}
            {/each}

        </div>
    </div>
{/snippet}

<script module>
    // place_cursor_at_stem — positions cursor before the stem's first dot,
    // selecting just the stem portion so it can be edited or suffixed.
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

    /* unified item header row — used directly for Docs; wrapped in ls-what-hdr for Whats */
    .ls-item-hdr {
        display: flex; align-items: center; gap: 0.2rem; min-height: 1.4rem;
    }
    /* PeelInput inside an item header fills the row so cancel reaches the right edge */
    .ls-item-hdr :global(.pi-row) { flex: 1; min-width: 0; }

    /* What — the whole block is bordered so it brackets header + all children */
    .ls-what {
        margin: 0.15rem 0;
        border-left: 2px solid #2a3a4a;
        padding-left: 0.35rem;
    }
    /* nested Whats step the border colour cooler so depth reads visually */
    .ls-what .ls-what { border-left-color: #223040; }
    .ls-what .ls-what .ls-what { border-left-color: #1a2530; }
    .ls-what-hdr {
        display: flex; align-items: center; gap: 0.2rem; min-height: 1.4rem;
    }
    /* PeelInput inside a What header fills the row */
    .ls-what-hdr :global(.pi-row) { flex: 1; min-width: 0; }
    /* What label brighter than the muted Doc/Point default */
    .ls-what-hdr :global(.pi-label) { color: #7a8fa8; }
    /* children sit indented inside the border — the border visually brackets them */
    .ls-what-children { padding-left: 0.5rem; }
    /* Spotlight glow — overwrites the left border with a glowing beam for full block height */
    .ls-what-active { position: relative; }
    .ls-what-active::before {
        content: '';
        position: absolute; left: -2px; top: 0; bottom: 0;
        width: 2px;
        background: #446a; box-shadow: 0 0 6px 2px #446a;
    }

    /* Doc — flat header row like a Point, no container border.
       new/missing states tint via a left stripe on the whole block. */
    .ls-doc         { margin: 0.1rem 0 0.15rem 0; }
    .ls-doc-new     { border-left: 2px solid #3a5a3a; padding-left: 0.35rem; }
    .ls-doc-missing { border-left: 2px solid #5a3a2a; padding-left: 0.35rem; opacity: 0.8 }
    /* Points and nested Whats under a Doc are indented */
    .ls-doc-children { padding-left: 0.5rem; }

    .ls-points { margin: 0.05rem 0; }
    .ls-point  {
        display: flex; align-items: center; gap: 0.25rem;
        min-height: 1.4rem;
        padding: 0.1rem 0; border-bottom: 1px solid #1c1c28; flex-wrap: wrap;
        /* pink left border — Points are a warm accent against the cool What/Doc palette */
        border-left: 2px solid #4a2a3a; padding-left: 0.3rem;
    }
    .ls-point:last-child { border-bottom: none }
    /* PeelInput inside a Point row fills the row so cancel reaches the right edge */
    .ls-point :global(.pi-row) { flex: 1; min-width: 0; }
    /* Points: label in pink family */
    .ls-point :global(.pi-label) { color: #7a4a5a; }

    /* add-item row — PeelInput open for a new child */
    .ls-add-row { margin-top: 0.05rem; }

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
    /* icon-sized + button in headers */
    .ls-add-btn-icon { color: #448; font-size: 0.8rem }
    .ls-add-btn-icon:hover { color: #88a }

    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover  { color: #999 }
    .ls-cancel-right { margin-left: auto }

    /* Shared icon button styles — declared :global so any child component can use them */
    :global(.ls-icon-btn) {
        background: none; border: none; color: #444;
        cursor: pointer; font-size: 0.8rem; line-height: 1;
        padding: 0 0.15rem; flex-shrink: 0;
    }
    :global(.ls-icon-btn:hover) { color: #aaa }
    :global(.ls-del-btn:hover)  { color: #f66 }

    /* type-picker row — appears after + is clicked, before a type is chosen */
    .ls-type-picker {
        display: flex; align-items: center; gap: 0.25rem;
        min-height: 1.4rem; margin-top: 0.05rem; flex-wrap: wrap;
    }
    .ls-pick-btn {
        background: none; border: 1px solid #334; border-radius: 3px;
        color: #668; cursor: pointer; font-family: monospace; font-size: 0.72rem;
        padding: 0.1rem 0.3rem;
    }
    .ls-pick-btn:hover { color: #99b; border-color: #558; }
</style>
