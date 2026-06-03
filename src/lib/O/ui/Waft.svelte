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

    // ── stable C identity ─────────────────────────────────────────────
    //
    //   Form-state Records are keyed by stable strings.  TheC objects don't
    //   carry a unique id, so we assign one lazily via a module-level WeakMap.
    //   This avoids touching Stuff.svelte and survives re-renders cleanly.
    //   < assign ids in Stuff.svelte oai/i so they're globally unique and
    //     survive serialisation — useful for persistence and deep linking.
    const _cids = new WeakMap<object, string>()
    let   _cid_next = 0
    function cid(c: TheC): string {
        let id = _cids.get(c)
        if (!id) { id = String(++_cid_next); _cids.set(c, id) }
        return id
    }

    // ── item-type descriptor table ────────────────────────────────────
    //
    //   Point, Doc, What all share the same PeelInput UX.
    //   mk_key:     sc key that carries the primary value
    //   mk_ph:      placeholder for the mainkey input
    //   sc_ph:      placeholder for the sc extras input; '' hides it
    //   mk_default: value used when mainkey is left empty on submit
    //   make_sc:    builds the full sc for oai() from (val, sc_str)
    //   to_display: renders a C as its peel string for the idle row
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
    //   All editable items (Point/Doc/What at any nesting level) share one
    //   set of Records, keyed by a scope string:
    //     add:    cid(container) + '+' + ItemType    e.g. "3+Point"
    //     edit:   cid(container) + '/' + cid(item)   e.g. "3/7"
    //   This keeps form state isolated per-C regardless of label collisions
    //   across different Whats or Docs.
    //
    //   item_open:     whether the PeelInput is in edit/add mode
    //   item_mk:       draft mainkey value
    //   item_sc:       draft sc extras string
    //   item_type:     ItemType for the active form (needed on submit)
    let item_open: Record<string, boolean>   = $state({})
    let item_mk:   Record<string, string>    = $state({})
    let item_sc:   Record<string, string>    = $state({})
    let item_type: Record<string, ItemType>  = $state({})

    //   Waft rename — kept separate; Waft path is special (fires e:Lies_rename_waft)
    let renaming_waft = $state<string | null>(null)

    //   type picker — cid(container) → true while choosing what type to add
    let add_picking: Record<string, boolean> = $state({})

    //   Seen:origin clone editing — keyed by clone spec string
    let clone_edit_open: Record<string, boolean> = $state({})
    let clone_edit_val:  Record<string, string>  = $state({})
    let clone_edit_sc:   Record<string, string>  = $state({})

    // ── add-item form ─────────────────────────────────────────────────
    //
    //   add key = cid(container) + '+' + type
    function add_key(container: TheC, t: ItemType): string {
        return cid(container) + '+' + t
    }
    function toggle_add_pick(container: TheC) {
        const k = cid(container)
        add_picking[k] = !add_picking[k]
    }
    function pick_and_open(container: TheC, t: ItemType) {
        add_picking[cid(container)] = false
        open_add(container, t)
    }
    function open_add(container: TheC, t: ItemType) {
        const k = add_key(container, t)
        item_open[k] = true
        item_mk[k]   = ''
        item_sc[k]   = ''
        item_type[k] = t
    }
    function cancel_add(container: TheC, t: ItemType) {
        item_open[add_key(container, t)] = false
    }
    function submit_add(container: TheC, t: ItemType) {
        const k   = add_key(container, t)
        const val = (item_mk[k] ?? '').trim()
        const sc_s = (item_sc[k] ?? '').trim()
        if (!val && t !== 'Point') return
        const td  = ITEM_TYPES[t]
        const sc  = td.make_sc(val, sc_s)
        if (t === 'Doc' && !(sc as any).Doc) return
        const child = container.oai(sc)
        if (t === 'Doc') child.sc.new = 1
        container.bump_version()
        waft.bump_version()
        cancel_add(container, t)
    }

    // ── edit existing item ────────────────────────────────────────────
    //
    //   edit key = cid(container) + '/' + cid(item)
    //   For What/Doc "rename", the item IS the container — same key pattern.
    function edit_key(container: TheC, item: TheC): string {
        return cid(container) + '/' + cid(item)
    }
    function start_edit(container: TheC, item: TheC, t: ItemType) {
        const k   = edit_key(container, item)
        const sc  = item.sc as Record<string, any>
        const mk_key = ITEM_TYPES[t].mk_key
        const pval   = sc[mk_key]
        item_open[k] = true
        item_type[k] = t
        item_mk[k]   = (pval === 1 || pval === true) ? '' : String(pval ?? '')
        item_sc[k]   = Object.entries(sc)
            .filter(([ky]) => ky !== mk_key)
            .map(([ky, v]) => v === 1 ? ky : `${ky}:${v}`)
            .join(',')
    }
    function cancel_edit(container: TheC, item: TheC) {
        item_open[edit_key(container, item)] = false
    }
    async function submit_edit(container: TheC, item: TheC) {
        const k      = edit_key(container, item)
        const t      = item_type[k]
        const td     = ITEM_TYPES[t]
        const val    = (item_mk[k] ?? '').trim()
        const sc_str = (item_sc[k] ?? '').trim()
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
        Object.keys(item.sc).forEach(k2 => delete item.sc[k2])
        Object.assign(item.sc, new_sc)
        container.bump_version()
        waft.bump_version()
        // await tick so derived display values re-read updated sc before edit mode clears
        await tick()
        item_open[k] = false
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

    <!-- add-child picker + forms at Waft level -->
    {#if add_picking[cid(waft)]}
        <div class="ls-type-picker">
            {#each (['What', 'Doc', 'Point'] as ItemType[]) as t (t)}
                <button class="ls-pick-btn" onclick={() => pick_and_open(waft, t)}>{t}</button>
            {/each}
            <button class="ls-cancel-btn" onclick={() => add_picking[cid(waft)] = false}>cancel</button>
        </div>
    {/if}
    {#each (['What', 'Doc', 'Point'] as ItemType[]) as t (t)}
        {@const ak = add_key(waft, t)}
        {#if item_open[ak]}
            <div class="ls-add-row">
                <PeelInput
                    label={t}
                    open={true}
                    mk_ph={ITEM_TYPES[t].mk_ph}
                    sc_ph={ITEM_TYPES[t].sc_ph}
                    mainkey={item_mk[ak] ?? ''}
                    on_mk={(v) => item_mk[ak] = v}
                    sc_str={item_sc[ak] ?? ''}
                    on_sc={(v) => item_sc[ak] = v}
                    submit_label="+"
                    on_submit={() => submit_add(waft, t)}
                    on_cancel={() => cancel_add(waft, t)} />
            </div>
        {/if}
    {/each}

    <!-- children — iterated whole, switched by type key -->
    {#each waft_children as child (child)}
        {#if (child.sc as any).What}
            {@render render_what(child as TheC, 0)}
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

<!-- render_doc — Doc row: display/edit + existing Points (edit only).
     container is the parent C (Waft or What) — used for edit key scoping.
     Points are added via the containing What/Waft add-child form. -->
{#snippet render_doc(doc: TheC, container: TheC)}
    {@const dpath    = doc.sc.Doc as string}
    {@const pts      = (() => { void doc.version; return doc.o({ Point: 1 }) as TheC[] })()}
    {@const ek       = edit_key(container, doc)}
    {@const editing  = !!item_open[ek]}
    {@const doc_whats = (() => { void doc.version; return doc.o({ What: 1 }) as TheC[] })()}

    <div class="ls-doc"
         class:ls-doc-new={!!doc.sc.new}
         class:ls-doc-missing={!!doc.sc.not_found && !doc.sc.new}>

        <!-- Doc row — idle or edit -->
        {#if editing}
            <div class="ls-item-hdr">
                <PeelInput
                    label="Doc"
                    open={true}
                    mk_ph={ITEM_TYPES.Doc.mk_ph}
                    sc_ph={ITEM_TYPES.Doc.sc_ph}
                    mainkey={item_mk[ek] ?? ''}
                    on_mk={(v) => item_mk[ek] = v}
                    sc_str={item_sc[ek] ?? ''}
                    on_sc={(v) => item_sc[ek] = v}
                    submit_label="✓"
                    on_submit={() => submit_edit(container, doc)}
                    on_cancel={() => cancel_edit(container, doc)} />
            </div>
        {:else}
            <div class="ls-item-hdr">
                <span class="pi-label">Doc:</span>
                <button class="ls-doc-open-btn" title="open {dpath} in editor"
                        onclick={() => focus_doc(doc)}>{dpath}</button>
                <button class="ls-icon-btn" title="rename Doc"
                        onclick={() => start_edit(container, doc, 'Doc')}>✎</button>
                <button class="ls-icon-btn ls-del-btn" title="remove Doc"
                        onclick={() => delete_item(doc, container)}>×</button>
            </div>
        {/if}

        <!-- existing Points on this Doc — editable in-place, added via container's + -->
        {#if pts.length}
            <div class="ls-points">
                {#each pts as pt, idx (idx)}
                    {@const pek = edit_key(doc, pt)}
                    <div class="ls-point">
                        {#if item_open[pek]}
                            <PeelInput
                                label="Point"
                                open={true}
                                mk_ph={ITEM_TYPES.Point.mk_ph}
                                sc_ph={ITEM_TYPES.Point.sc_ph}
                                mainkey={item_mk[pek] ?? ''}
                                on_mk={(v) => item_mk[pek] = v}
                                sc_str={item_sc[pek] ?? ''}
                                on_sc={(v) => item_sc[pek] = v}
                                submit_label="✓"
                                on_submit={() => submit_edit(doc, pt)}
                                on_cancel={() => cancel_edit(doc, pt)} />
                        {:else}
                            <!-- method is set by fuzzify/export; Point value is the fallback -->
                            <button class="ls-point-open-btn"
                                    title="open {dpath} at this point"
                                    onclick={() => H.i_elvisto('Lang/Lang', 'Dock_open', { path: dpath, point: pt.sc.method ?? pt.sc.Point })}>
                                {ITEM_TYPES.Point.to_display(pt)}
                            </button>
                            <button class="ls-icon-btn" title="edit Point"
                                    onclick={() => start_edit(doc, pt, 'Point')}>✎</button>
                            <button class="ls-icon-btn ls-del-btn"
                                    onclick={() => delete_item(pt, doc)}>×</button>
                        {/if}
                    </div>
                {/each}
            </div>
        {/if}

        <!-- %What children of this %Doc (Doc > What nesting, e.g. time-slices) -->
        {#each doc_whats as dw (dw)}
            {@render render_what(dw, 1)}
        {/each}

    </div>
{/snippet}

<!-- render_what — What header + its Points + nested Docs and Whats.
     Spotlight beam glow when cursor is aimed at this What or any ancestor. -->
{#snippet render_what(what: TheC, wdepth: number)}
    {@const what_children = (() => { void what.version; return what.o() as TheC[] })()}
    {@const what_pts_only = (() => { void what.version; return what.o({ Point: 1 }) as TheC[] })()}
    {@const ek            = edit_key(what, what)}
    {@const editing       = !!item_open[ek]}

    <div class="ls-what" style="margin-left: {wdepth * 10}px"
         class:ls-what-active={is_spotlight(what)}>

        <!-- What header — edit or idle -->
        {#if editing}
            <div class="ls-item-hdr ls-what-hdr">
                <PeelInput
                    label="What"
                    open={true}
                    mk_ph={ITEM_TYPES.What.mk_ph}
                    sc_ph={ITEM_TYPES.What.sc_ph}
                    mainkey={item_mk[ek] ?? ''}
                    on_mk={(v) => item_mk[ek] = v}
                    sc_str={item_sc[ek] ?? ''}
                    on_sc={(v) => item_sc[ek] = v}
                    submit_label="✓"
                    on_submit={() => submit_edit(what, what)}
                    on_cancel={() => cancel_edit(what, what)} />
            </div>
        {:else}
            <div class="ls-item-hdr ls-what-hdr">
                <span class="pi-label">What:</span>
                <button class="ls-what-label"
                        title="cursor to What:{what.sc.What}"
                        onclick={() => H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what, dive: true })}>
                    {what.sc.What}
                </button>
                <span class="ls-spacer"></span>
                <button class="ls-icon-btn" title="rename What"
                        onclick={() => start_edit(what, what, 'What')}>✎</button>
                <button class="ls-icon-btn ls-del-btn" title="delete What"
                        onclick={() => delete_item(what, waft)}>×</button>
                <button class="ls-icon-btn ls-add-btn-icon" title="add child"
                        onclick={() => toggle_add_pick(what)}>+</button>
            </div>
        {/if}

        <!-- add-child picker + forms for this What -->
        {#if add_picking[cid(what)]}
            <div class="ls-type-picker">
                {#each (['Point', 'Doc', 'What'] as ItemType[]) as t (t)}
                    <button class="ls-pick-btn" onclick={() => pick_and_open(what, t)}>{t}</button>
                {/each}
                <button class="ls-cancel-btn" onclick={() => add_picking[cid(what)] = false}>cancel</button>
            </div>
        {/if}
        {#each (['Point', 'Doc', 'What'] as ItemType[]) as t (t)}
            {@const ak = add_key(what, t)}
            {#if item_open[ak]}
                <div class="ls-add-row">
                    <PeelInput
                        label={t}
                        open={true}
                        mk_ph={ITEM_TYPES[t].mk_ph}
                        sc_ph={ITEM_TYPES[t].sc_ph}
                        mainkey={item_mk[ak] ?? ''}
                        on_mk={(v) => item_mk[ak] = v}
                        sc_str={item_sc[ak] ?? ''}
                        on_sc={(v) => item_sc[ak] = v}
                        submit_label="+"
                        on_submit={() => submit_add(what, t)}
                        on_cancel={() => cancel_add(what, t)} />
                </div>
            {/if}
        {/each}

        <!-- Points in one block so last-child border suppression works -->
        {#if what_pts_only.length}
            <div class="ls-points ls-what-pts">
                {#each what_pts_only as pt, idx (idx)}
                    {@const pek = edit_key(what, pt)}
                    <div class="ls-point">
                        {#if item_open[pek]}
                            <PeelInput
                                label="Point"
                                open={true}
                                mk_ph={ITEM_TYPES.Point.mk_ph}
                                sc_ph={ITEM_TYPES.Point.sc_ph}
                                mainkey={item_mk[pek] ?? ''}
                                on_mk={(v) => item_mk[pek] = v}
                                sc_str={item_sc[pek] ?? ''}
                                on_sc={(v) => item_sc[pek] = v}
                                submit_label="✓"
                                on_submit={() => submit_edit(what, pt)}
                                on_cancel={() => cancel_edit(what, pt)} />
                        {:else}
                            <button class="ls-point-open-btn"
                                    title="point in What:{what.sc.What}"
                                    onclick={() => H.i_elvisto('Lang/Lang', 'Dock_open', { point: pt.sc.method ?? pt.sc.Point })}>
                                {ITEM_TYPES.Point.to_display(pt)}
                            </button>
                            <button class="ls-icon-btn" title="edit Point"
                                    onclick={() => start_edit(what, pt, 'Point')}>✎</button>
                            <button class="ls-icon-btn ls-del-btn"
                                    onclick={() => delete_item(pt, what)}>×</button>
                        {/if}
                    </div>
                {/each}
            </div>
        {/if}

        <!-- non-Point children in insertion order, switched by type -->
        {#each what_children as child (child)}
            {#if (child.sc as any).Doc}
                {@render render_doc(child as TheC, what)}
            {:else if (child.sc as any).What}
                {@render render_what(child as TheC, wdepth + 1)}
            {/if}
        {/each}

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

    /* unified item header row — Doc, What idle/edit, Waft rename all use this */
    .ls-item-hdr {
        display: flex; align-items: center; gap: 0.2rem; min-height: 1.4rem;
    }
    /* PeelInput inside an item header fills the row so cancel reaches the right edge */
    .ls-item-hdr :global(.pi-row) { flex: 1; min-width: 0; }

    .ls-what {
        margin: 0.1rem 0 0.15rem 0;
        border-left: 2px solid #2a3a4a;
        padding-left: 0.35rem;
    }
    /* nested Whats step the border colour cooler so depth reads visually */
    .ls-what .ls-what { border-left-color: #223040; }
    .ls-what .ls-what .ls-what { border-left-color: #1a2530; }
    .ls-what-hdr { gap: 0.2rem }
    /* Spotlight glow — left-margin beam when the cursor is aimed at this What */
    .ls-what-active { position: relative; }
    .ls-what-active > .ls-item-hdr::before {
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

    .ls-doc {
        margin: 0.1rem 0 0.2rem 0;
        border-left: 2px solid #2a2a3a;
        padding-left: 0.35rem;
    }
    .ls-doc-new     { border-left-color: #3a5a3a }
    .ls-doc-missing { border-left-color: #5a3a2a; opacity: 0.8 }
    /* Doc path button — clickable to open in editor */
    .ls-doc-open-btn {
        background: none; border: none; cursor: pointer; text-align: left; padding: 0;
        font-family: monospace; font-size: 0.74rem;
        color: #7a9ab0; flex: 1; white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
    }
    .ls-doc-open-btn:hover { color: #a8c8e0; text-decoration: underline; }

    .ls-points { margin: 0.05rem 0 0.05rem 0.3rem }
    .ls-point  {
        display: flex; align-items: center; gap: 0.25rem;
        min-height: 1.4rem;
        padding: 0.1rem 0; border-bottom: 1px solid #1c1c28; flex-wrap: wrap;
    }
    .ls-point:last-child { border-bottom: none }
    /* PeelInput inside a Point row fills the row so cancel reaches the right edge */
    .ls-point :global(.pi-row) { flex: 1; min-width: 0; }
    .ls-point-open-btn {
        background: none; border: none; cursor: pointer; text-align: left; padding: 0;
        font-family: monospace; font-size: 0.74rem; color: #a8c; flex: 1;
    }
    .ls-point-open-btn:hover { color: #d0b0f0; text-decoration: underline; }
    /* Direct Points on a What (time-slice style) — slightly indented */
    .ls-what-pts { margin-left: 0.2rem; }

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

    /* pi-label used directly in item header rows (mirrors PeelInput's class) */
    .pi-label {
        font-family: monospace; font-size: 0.74rem;
        color: #556; flex-shrink: 0; white-space: nowrap;
    }
</style>
