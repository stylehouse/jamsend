<script lang="ts">
    // Waft.svelte — one Waft item in the recursive Waft tree.
    //
    // Extracted from Liesui to be a stable component boundary:
    // Svelte reconciles {#each} items by component key (waft.sc.Waft) so
    // this component survives Liesui re-renders, keeping form state and
    // focused inputs stable across think() ticks.
    //
    // Single <PeelInput> callsite via pi(). Single item wrapper via waftitem(C, upC).
    //   waftitem detects type from C.sc mainkey, reads C.o({}) for children,
    //   renders .ls-item / .ls-item-hdr / .ls-items — all personality from ITEM_TYPES.
    //   The Waft header row itself is rendered as waftitem(waft, waft) via the Waft
    //   entry in ITEM_TYPES — no separate header block.

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
    //   Every behavioural difference between Point/Doc/What lives here.
    //
    //   mk_key:       sc key that identifies this type (first key in sc)
    //   mk_ph:        mainkey input placeholder
    //   sc_ph:        sc extras placeholder
    //   make_sc:      builds the oai() sc from (val, sc_str)
    //   on_open:      navigation action when the display value is clicked
    //   item_cls:     CSS class(es) on the .ls-item wrapper
    //   item_cls_fns: dynamic class predicates — {cls: string, when: (C)=>bool}[]
    //   child_types:  ItemTypes allowed as add-child options; undefined = leaf (no children)
    //   can_add:      whether this type shows + (add-child picker) in its header
    //   spotlight:    whether this type participates in the Spotlight glow
    //
    //   display is handled by the shared item_to_display() below
    //   < Doc: directory-list autocomplete for Ghost/* paths
    //   < Doc: bare name auto-prefixes Ghost/ and appends .g
    const ITEM_TYPES = {
        Waft: {
            mk_key:     'Waft' as const,
            mk_ph:      'path/to/waft',
            sc_ph:      'tag:foo',
            make_sc:    (val: string, sc_str: string) => ({
                Waft: val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            // < rename is a no-op here — backend rewrites %Waft on load/save to new path
            on_open:    (_item: TheC) => on_active(waft),
            item_cls:   'ls-item ls-item-waft',
            item_cls_fns: [
                { cls: 'ls-item-waft-active', when: (_c) => is_active },
            ] as { cls: string; when: (c: TheC) => boolean }[],
            child_types: ['What', 'Doc', 'Point'] as ItemType[],
            can_add:    true,
            spotlight:  false,
        },
        Point: {
            mk_key:     'Point' as const,
            mk_ph:      'fuzzyName',
            sc_ph:      'method:Name,call',
            make_sc:    (val: string, sc_str: string) => ({
                Point: val === '' ? 1 : val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            on_open:    (item: TheC, dpath?: string) =>
                H.i_elvisto('Lang/Lang', 'Dock_open', {
                    path:  dpath,
                    point: (item.sc as any).method ?? item.sc.Point,
                }),
            item_cls:   'ls-item ls-item-point',
            item_cls_fns: [] as { cls: string; when: (c: TheC) => boolean }[],
            child_types: undefined,   // leaf — no children
            can_add:    false,
            spotlight:  false,
        },
        Doc: {
            mk_key:     'Doc' as const,
            mk_ph:      'Ghost/…',
            sc_ph:      'tag:foo',
            make_sc:    (val: string, sc_str: string) => ({
                Doc: resolve_doc_path(val),
                ...(sc_str ? peel(sc_str) : {})
            }),
            on_open:    (item: TheC) => focus_doc(item),
            item_cls:   'ls-item ls-item-doc',
            item_cls_fns: [
                { cls: 'ls-item-doc-new',     when: (c) => !!c.sc.new },
                { cls: 'ls-item-doc-missing', when: (c) => !!c.sc.not_found && !c.sc.new },
            ],
            child_types: ['Point', 'What'] as ItemType[],
            can_add:    false,
            spotlight:  false,
        },
        What: {
            mk_key:     'What' as const,
            mk_ph:      'label',
            sc_ph:      'tag:foo',
            make_sc:    (val: string, sc_str: string) => ({
                What: val,
                ...(sc_str ? peel(sc_str) : {})
            }),
            on_open:    (item: TheC) =>
                H.i_elvisto('Lies/Lies', 'Lies_cursor_what', { what: item, dive: true }),
            item_cls:   'ls-item ls-item-what',
            item_cls_fns: [
                { cls: 'ls-item-what-active', when: (c) => is_spotlight(c) },
            ],
            child_types: ['Point', 'Doc', 'What'] as ItemType[],
            can_add:    true,
            spotlight:  true,
        },
    } as const
    type ItemType = keyof typeof ITEM_TYPES

    // ── item_to_display — split display for any item C ───────────────
    //
    //   Returns { val, sc } separately so PeelInput can style them at different sizes.
    //   val:  mainkey value string — empty when :1 (label alone covers it)
    //   sc:   extras as depeel string — keys beyond the mainkey
    //
    //   eg {Point:1, method:'transport'} → { val:'',           sc:'method:transport' }
    //      {Point:'MyThing'}             → { val:'MyThing',     sc:'' }
    //      {What:'label', tag:'foo'}     → { val:'label',       sc:'tag:foo' }
    //      {Doc:'Ghost/foo.g'}           → { val:'Ghost/foo.g', sc:'' }
    //   What val falls back to '·' when both empty so the row has a visible click target.
    //   Internal state keys (active, new, not_found) are excluded from sc extras.
    const DISPLAY_SKIP = new Set(['active', 'new', 'not_found'])
    function item_to_display(c: TheC, t: ItemType): { val: string; sc: string } {
        const sc_obj = c.sc as Record<string, any>
        const mk_key = ITEM_TYPES[t].mk_key
        const mk_val = sc_obj[mk_key]
        const sc = Object.entries(sc_obj)
            .filter(([k]) => k !== mk_key && !DISPLAY_SKIP.has(k))
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
        const val = (mk_val === 1 || mk_val === true) ? '' : String(mk_val ?? '')
        return { val: (!val && !sc && t === 'What') ? '·' : val, sc }
    }

    // ── PiProps — the full set of props pi() accepts ──────────────────
    type CrudProps = {
        orb_open:            boolean
        on_orb:              () => void   // opens irow AND immediately starts edit
        on_cancel_orb:       () => void   // cancel edit and close irow together
        on_del:              () => void
        // C inputs: first typed char seeds draft_mk and opens the add form
        on_start_after?:     (char: string) => void
        on_start_in?:        (char: string) => void
        // type buttons: open the add form without pre-seeding mainkey
        on_pick_after_type?: (t: string) => void
        on_pick_in_type?:    (t: string) => void
        add_types?:          string[]
    }
    type PiProps = {
        label:         string
        open:          boolean
        display_val?:  string          // idle: mainkey value (big)
        display_sc?:   string          // idle: extras sc string (small)
        mk_ph?:        string
        sc_ph?:        string
        mk_is_one?:    boolean         // mainkey value is :1 — label shows as comma-key
        mainkey?:      string
        on_mk?:        (v: string) => void
        sc_str?:       string
        on_sc?:        (v: string) => void
        focus_sc?:     boolean
        submit_label?: string
        on_open?:      () => void      // navigate — whole label/val row
        on_submit:     () => void
        on_cancel:     () => void
        on_crud?:      CrudProps       // orb + irow; absent on add-child forms
    }

    function resolve_doc_path(raw: string): string {
        const v = raw.trim()
        if (!v) return ''
        // bare name with no slash → Ghost/Name.g
        if (!v.includes('/')) return `Ghost/${v.includes('.') ? v : v + '.g'}`
        return v
    }

    // ── item_type_of — detect type from mainkey ───────────────────────
    //   Returns the ItemType whose mk_key is the first key in C.sc, or undefined.
    function item_type_of(c: TheC): ItemType | undefined {
        const first_key = Object.keys(c.sc ?? {})[0] as ItemType | undefined
        if (first_key && first_key in ITEM_TYPES) return first_key
        return undefined
    }

    // ── reactive reads ────────────────────────────────────────────────
    let wkey          = $derived(waft.sc.Waft as string)
    let is_active     = $derived(!!waft.sc.active)
    let waft_children = $derived((() => { void waft.version; return waft.o().filter((c: TheC) => !c.sc.Waft) as TheC[] })())
    let sub_wafts     = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs    = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())

    // ── unified item-edit form state ──────────────────────────────────
    //
    //   editing: the one C currently open for editing/adding.
    //   Since only one form is ever open, a single $state pair holds the draft.
    //   draft_type lives in a WeakMap (non-reactive; read only on submit).
    //
    //   add_type_C:    the chosen ItemType for the pending add-form.
    let editing      = new SvelteSet<TheC>()
    let orb_open_C   = new SvelteSet<TheC>()   // items whose irow is currently visible
    let draft_mk     = $state('')
    let draft_sc     = $state('')
    let draft_focus_sc = $state(false)   // focus sc field instead of mainkey on open
    const draft_type = new WeakMap<TheC, ItemType>()
    const add_type_C   = new WeakMap<TheC, ItemType>()
    const orb_trigger  = new WeakMap<TheC, TheC>()    // container → item whose orb opened this add

    // ── add-item form ─────────────────────────────────────────────────
    //
    //   pick_and_open: add a child inside container (appends to container.X.z).
    //   pick_and_open_after: add a sibling after item (splices into container.X.z).
    //     after_item is stored in a WeakMap so submit_add_after knows where to splice.
    const after_item_C = new WeakMap<TheC, TheC>()   // container → insert-after target

    function pick_and_open(container: TheC, t: ItemType, seed = '') {
        editing.clear()
        editing.add(container)
        add_type_C.set(container, t)
        draft_mk = seed
        draft_sc = ''
        // Point add: focus sc (mainkey is :1, sc is where the action is)
        // all others: focus mainkey — even if seed is ''
        draft_focus_sc = (t === 'Point')
    }
    function pick_and_open_after(container: TheC, after: TheC, t: ItemType, seed = '') {
        editing.clear()
        editing.add(container)
        add_type_C.set(container, t)
        after_item_C.set(container, after)
        draft_mk = seed
        draft_sc = ''
        draft_focus_sc = (t === 'Point')
    }
    function cancel_add(container: TheC) {
        editing.delete(container)
        after_item_C.delete(container)
        orb_trigger.delete(container)
    }
    function submit_add(container: TheC) {
        const t    = add_type_C.get(container)!
        const val  = draft_mk.trim()
        const sc_s = draft_sc.trim()
        if (!val && t !== 'Point') return
        const td   = ITEM_TYPES[t]
        const sc   = td.make_sc(val, sc_s)
        if (t === 'Doc' && !(sc as any).Doc) return
        const child = container.oai(sc)
        if (t === 'Doc') child.sc.new = 1

        // if after_item_C is set, splice child just after the target in X.z
        const after = after_item_C.get(container)
        if (after && container.X?.z) {
            const z   = container.X.z as TheC[]
            const idx = z.indexOf(child)    // oai() already pushed it
            const aft = z.indexOf(after)
            if (idx >= 0 && aft >= 0 && idx !== aft + 1) {
                z.splice(idx, 1)
                // aft may have shifted if child was before after
                const aft2 = z.indexOf(after)
                z.splice(aft2 + 1, 0, child)
            }
        }

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
        // focus sc when mainkey is bare :1 or when there are already extras to edit
        draft_focus_sc = (pval === 1 || pval === true) || draft_sc !== ''
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

    // ── Doc focus ─────────────────────────────────────────────────────
    function focus_doc(doc: TheC) {
        H.i_elvisto('Lies/Lies', 'Lies_set_cursor', { doc_C: doc, waft_key: wkey })
    }

    // ── props builders — feed into pi() ──────────────────────────────
    //
    //   item_props: edit/idle row for an existing item C.
    //     dpath threads through to Point's on_open for Dock_open navigation.
    //
    //   add_item_props: open add-form for a new child of container.
    //     Always open=true, submit_label='+', no edit/del buttons.

    function item_props(item: TheC, container: TheC, t: ItemType, dpath?: string): PiProps {
        const td      = ITEM_TYPES[t]
        const open    = editing.has(item)
        const mk_val  = (item.sc as any)[td.mk_key]
        const is_waft = t === 'Waft'
        const disp    = item_to_display(item, t)
        // after_types: sibling types allowed by the container
        const container_t  = item_type_of(container)
        const after_types  = (!is_waft && container_t)
            ? (ITEM_TYPES[container_t].child_types as string[] | undefined)
            : undefined
        // close_orb: shut irow without touching any add form that may be open on container
        function close_orb() { orb_open_C.delete(item) }
        // open_after: close this item's edit, open a sibling-add form on the parent container
        function open_after(typ: ItemType, seed = '') {
            close_orb()
            cancel_edit(item)
            orb_trigger.set(container, item)
            pick_and_open_after(container, item, typ, seed)
        }
        // open_in: close this item's edit, open a child-add form on this item
        function open_in(typ: ItemType, seed = '') {
            close_orb()
            cancel_edit(item)
            orb_trigger.set(item, item)
            pick_and_open(item, typ, seed)
        }
        // add_types: union of after_types and child_types, deduplicated
        const add_types_set = new Set<string>([
            ...(after_types ?? []),
            ...(td.child_types ?? []),
        ])
        const add_types = add_types_set.size ? [...add_types_set] : undefined
        return {
            label:        t,
            open,
            display_val:  disp.val,
            display_sc:   disp.sc,
            mk_ph:        td.mk_ph,
            sc_ph:        td.sc_ph,
            mk_is_one:    mk_val === 1 || mk_val === true,
            mainkey:      open ? draft_mk : '',
            on_mk:        (v: string) => { draft_mk = v },
            sc_str:       open ? draft_sc : '',
            on_sc:        (v: string) => { draft_sc = v },
            focus_sc:     open ? draft_focus_sc : false,
            submit_label: '✓',
            on_open:      () => td.on_open(item as any, dpath),
            // < Waft rename is a no-op — backend rewrites %Waft on load/save
            on_submit:    is_waft ? () => cancel_edit(item) : () => submit_edit(container, item),
            on_cancel:    () => { cancel_edit(item); close_orb() },
            on_crud: {
                orb_open: orb_open_C.has(item),
                on_orb: () => {
                    if (orb_open_C.has(item)) {
                        // second click on orb: close everything
                        close_orb()
                        cancel_edit(item)
                    } else {
                        // first click: open irow and immediately enter edit mode
                        orb_open_C.clear()
                        editing.clear()
                        orb_open_C.add(item)
                        start_edit(item, t)
                    }
                },
                on_cancel_orb: () => { close_orb(); cancel_edit(item) },
                on_del: is_waft ? () => on_delete(waft) : () => delete_item(item, container),
                // C inputs: first typed char opens the appropriate add form seeded with it
                on_start_after: after_types?.length
                    ? (char: string) => {
                        // default to first after_type when no type has been picked yet
                        open_after(after_types[0], char)
                    }
                    : undefined,
                on_start_in: td.can_add
                    ? (char: string) => {
                        const child_types = td.child_types!
                        open_in(child_types[0], char)
                    }
                    : undefined,
                // type buttons: open without seeding mainkey
                on_pick_after_type: after_types?.length
                    ? (typ: string) => open_after(typ as ItemType)
                    : undefined,
                on_pick_in_type: td.can_add
                    ? (typ: string) => open_in(typ as ItemType)
                    : undefined,
                add_types,
            },
        }
    }

    // add_item_props: open add-form for a new child/sibling of container.
    //   orb_item: the item whose orb triggered this add (to close it on cancel).
    //   Always open=true, submit_label='+', no on_crud.
    //   focus_sc only for Point (mainkey is :1 in that case).
    function add_item_props(container: TheC, orb_item: TheC): PiProps {
        const t  = add_type_C.get(container)!
        const td = ITEM_TYPES[t]
        return {
            label:        t,
            open:         true,
            mk_ph:        td.mk_ph,
            sc_ph:        td.sc_ph,
            mainkey:      draft_mk,
            on_mk:        (v: string) => { draft_mk = v },
            sc_str:       draft_sc,
            on_sc:        (v: string) => { draft_sc = v },
            focus_sc:     draft_focus_sc,
            submit_label: '+',
            on_submit:    () => submit_add(container),
            on_cancel:    () => { cancel_add(container); orb_open_C.delete(orb_item) },
        }
    }
</script>

<div class="ls-waft" style="margin-left: {depth * 14}px" class:ls-waft-active={is_active}>

    <!-- Waft header row — waft C rendered as a waftitem like any other -->
    {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
        <EncodingSplatter {waft} />
    {/if}
    {@render waftitem(waft, waft)}

    <!-- children — all types rendered through waftitem -->
    <!-- {#each waft_children as child (child)}
        {@render waftitem(child, waft)}
    {/each} -->

    <!-- sub-Wafts (recursive) -->
    {#each sub_wafts as sw (sw.sc.Waft)}
        <svelte:self {H} {w} waft={sw} depth={depth + 1} {examining}
            {on_active} {on_delete} />
    {/each}

</div>

<!-- pi — the one and only <PeelInput> callsite in this file. -->
{#snippet pi(p: PiProps)}
    <PeelInput
        label={p.label}
        open={p.open}
        display_val={p.display_val}
        display_sc={p.display_sc}
        mk_ph={p.mk_ph}
        sc_ph={p.sc_ph}
        mk_is_one={p.mk_is_one}
        mainkey={p.mainkey}
        on_mk={p.on_mk}
        sc_str={p.sc_str}
        on_sc={p.on_sc}
        focus_sc={p.focus_sc}
        submit_label={p.submit_label}
        on_open={p.on_open}
        on_submit={p.on_submit}
        on_cancel={p.on_cancel}
        on_crud={p.on_crud} />
{/snippet}


<!-- waftitem — the one wrapper for every Point/Doc/What in the tree.
     Detects type from C.sc mainkey, reads C.o({}) for children,
     renders .ls-item / .ls-item-hdr / .ls-items.
     All per-type personality (CSS, child_types, spotlight) comes from ITEM_TYPES.
     upC is the containing C — used for edit/delete keying and Doc dpath.
     Type selection now lives in the PeelInput irow via on_crud.on_pick_type. -->
{#snippet waftitem(C: TheC, upC: TheC)}
    {@const t = item_type_of(C)}
    {#if t}
        {@const td       = ITEM_TYPES[t]}
        {@const items    = (() => { void C.version; return C.o() as TheC[] })()} 
        {@const dpath    = t === 'Doc' ? C.sc.Doc as string : undefined}
        {@const dyn_cls  = td.item_cls_fns.filter(f => f.when(C)).map(f => f.cls).join(' ')}
        <div class="{td.item_cls} {dyn_cls}">
            <div class="ls-item-hdr">
                {@render pi(item_props(C, upC, t, dpath))}
            </div>
            {#if td.child_types}
                {#if editing.has(C) && add_type_C.has(C)}
                    <div class="ls-add-row">{@render pi(add_item_props(C, orb_trigger.get(C) ?? C))}</div>
                {/if}
                {#if items.length}
                    <div class="ls-items">
                        {#each items as child (child)}
                            {@render waftitem(child, C)}
                        {/each}
                    </div>
                {/if}
            {/if}
        </div>
    {/if}
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

    /* Waft header row — styled like a What but with active-glow on the key */
    .ls-item-waft {
        margin: 0 0 0.2rem 0;
        border-left: 2px solid #334;
        padding-left: 0.35rem;
    }
    .ls-item-waft :global(.pi-label) { color: #6a7fa8; font-weight: bold; }
    .ls-item-waft :global(.pi-display-val) { color: #8ab; font-weight: bold; }
    /* active waft: glow on the left border */
    .ls-item-waft-active { position: relative; }
    .ls-item-waft-active::before {
        content: '';
        position: absolute; left: -2px; top: 0; bottom: 0; width: 2px;
        background: #88c; box-shadow: 0 0 6px 2px #446a;
    }

    /* shared item wrapper */
    .ls-item { margin: 0.1rem 0; }
    .ls-item-hdr {
        display: flex; align-items: center; gap: 0.2rem; min-height: 1.4rem;
    }
    /* PeelInput fills the header row so cancel reaches the right edge */
    .ls-item-hdr :global(.pi-wrap) { flex: 1; min-width: 0; }
    .ls-item-hdr :global(.pi-row)  { flex: 1; min-width: 0; }
    /* children indented under any item type */
    .ls-items { padding-left: 0.5rem; }

    /* Point — pink left border, warm label */
    .ls-item-point {
        border-left: 2px solid #4a2a3a; padding-left: 0.3rem;
        border-bottom: 1px solid #1c1c28;
    }
    .ls-item-point:last-child { border-bottom: none }
    .ls-item-point :global(.pi-label) { color: #7a4a5a; }

    /* Doc — no left border by default; new/missing tint via modifier classes */
    .ls-item-doc { margin: 0.1rem 0 0.15rem 0; }
    .ls-item-doc-new     { border-left: 2px solid #3a5a3a; padding-left: 0.35rem; }
    .ls-item-doc-missing { border-left: 2px solid #5a3a2a; padding-left: 0.35rem; opacity: 0.8; }

    /* What — bordered left margin brackets header + all children; spotlight glow */
    .ls-item-what {
        margin: 0.15rem 0;
        border-left: 2px solid #2a3a4a;
        padding-left: 0.35rem;
    }
    /* nested Whats step the border colour cooler so depth reads visually */
    .ls-item-what .ls-item-what { border-left-color: #223040; }
    .ls-item-what .ls-item-what .ls-item-what { border-left-color: #1a2530; }
    /* What label brighter than the muted Doc/Point default; display larger */
    .ls-item-what > .ls-item-hdr :global(.pi-label)       { color: #7a8fa8; }
    .ls-item-what > .ls-item-hdr :global(.pi-display-val) { font-size: 0.9rem; color: #aac8dd; }
    /* Spotlight glow — overwrites left border with a glowing beam */
    .ls-item-what-active { position: relative; }
    .ls-item-what-active::before {
        content: '';
        position: absolute; left: -2px; top: 0; bottom: 0;
        width: 2px;
        background: #446a; box-shadow: 0 0 6px 2px #446a;
    }

    /* add-item row — PeelInput open for a new child */
    .ls-add-row { margin-top: 0.05rem; }

    .ls-input {
        background: #0d0d14; border: 1px solid #333; border-radius: 3px;
        color: #aaa; font-family: monospace; font-size: 0.76rem;
        padding: 0.2rem 0.35rem; outline: none;
    }
    .ls-input:focus  { border-color: #446 }

    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover  { color: #999 }
    .ls-cancel-right { margin-left: auto }

    .ls-type-picker {
        display: none;  /* < type picker now lives in the PeelInput irow */
    }
</style>
