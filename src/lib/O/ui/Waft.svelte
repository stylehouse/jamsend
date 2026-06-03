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

    // ── item_to_display — unified display string for any item C ──────
    //
    //   Shows the mainkey value (omitted when :1 — the label covers it)
    //    followed by any extras sc as a depeel string.
    //   eg {Point:1, method:'transport'} → 'method:transport'
    //      {Point:'MyThing'}             → 'MyThing'
    //      {What:'label', tag:'foo'}     → 'label,tag:foo'
    //      {Doc:'Ghost/foo.g'}           → 'Ghost/foo.g'
    //   What falls back to '·' when empty so the row has visible click target.
    function item_to_display(c: TheC, t: ItemType): string {
        const sc     = c.sc as Record<string, any>
        const mk_key = ITEM_TYPES[t].mk_key
        const mk_val = sc[mk_key]
        const extras = Object.entries(sc)
            .filter(([k]) => k !== mk_key)
            .map(([k, v]) => v === 1 ? k : `${k}:${v}`)
            .join(',')
        const val_str = (mk_val === 1 || mk_val === true) ? '' : String(mk_val ?? '')
        if (!val_str && !extras) return t === 'What' ? '·' : ''
        return [val_str, extras].filter(Boolean).join(',')
    }

    // ── PiProps — the full set of props pi() accepts ──────────────────
    type PiProps = {
        label:         string
        open:          boolean
        display?:      string
        mk_ph?:        string
        sc_ph?:        string
        mainkey?:      string
        on_mk?:        (v: string) => void
        sc_str?:       string
        on_sc?:        (v: string) => void
        focus_sc?:     boolean
        submit_label?: string
        on_open?:      () => void
        on_submit:     () => void
        on_cancel:     () => void
        on_edit?:      () => void
        on_del?:       () => void
        on_add?:       () => void
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
    let waft_children = $derived((() => { void waft.version; return waft.o() as TheC[] })())
    let sub_wafts     = $derived((() => { void waft.version; return waft.o({ Waft: 1 }) as TheC[] })())
    let waft_mungs    = $derived((() => { void waft.version; return waft.o({ mung_error: 1 }) as TheC[] })())

    // ── unified item-edit form state ──────────────────────────────────
    //
    //   editing: the one C currently open for editing/adding.
    //   Since only one form is ever open, a single $state pair holds the draft.
    //   draft_type lives in a WeakMap (non-reactive; read only on submit).
    //
    //   add_picking_C: containers with the type-picker open.
    //   add_type_C:    the chosen ItemType for the pending add-form.
    //
    //   Waft rename also routes through editing/draft_mk.
    //    editing.has(waft) with no add_type_C entry distinguishes rename from add-child.
    let editing      = new SvelteSet<TheC>()
    let draft_mk     = $state('')
    let draft_sc     = $state('')
    let draft_focus_sc = $state(false)   // focus sc field instead of mainkey on open
    const draft_type = new WeakMap<TheC, ItemType>()

    let add_picking_C = new SvelteSet<TheC>()
    const add_type_C  = new WeakMap<TheC, ItemType>()

    // ── Waft rename form ──────────────────────────────────────────────
    //   Routes through editing/draft_mk like all other item edits.
    //   waft itself is the key — editing.has(waft) with no add_type_C entry
    //    distinguishes rename from add-child.
    function start_rename_waft() {
        editing.clear()
        editing.add(waft)
        draft_mk = wkey
        draft_sc = ''
    }
    function cancel_rename_waft() { editing.delete(waft) }
    function commit_rename_waft() {
        const n = draft_mk.trim()
        editing.delete(waft)
        if (!n || n === wkey) return
        H.i_elvisto('Lies/Lies', 'Lies_rename_waft', { old_path: wkey, new_path: n })
    }

    // ── add-item form ─────────────────────────────────────────────────
    function toggle_add_pick(container: TheC) {
        if (add_picking_C.has(container)) add_picking_C.delete(container)
        else add_picking_C.add(container)
    }
    function pick_and_open(container: TheC, t: ItemType) {
        add_picking_C.delete(container)
        editing.clear()
        editing.add(container)
        add_type_C.set(container, t)
        draft_mk = ''
        draft_sc = ''
        // Point with empty mainkey submits as :1 — sc is where the action is
        draft_focus_sc = (t === 'Point')
    }
    function cancel_add(container: TheC) {
        editing.delete(container)
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

    // ── waft_rename_props — feeds the Waft header rename into pi() ────
    //
    //   Fires e:Lies_rename_waft so Lies can persist a waft_rename_job before
    //   touching any wormhole files.  Lies mutates waft.sc.Waft after writing
    //   the new snap.  Renaming is a move; old snap is left in place.
    //   No sc_ph — waft path is a single string key, no extras field.
    function waft_rename_props(): PiProps {
        return {
            label:        'Waft',
            open:         true,
            mk_ph:        'path/to/waft',
            sc_ph:        '',
            mainkey:      draft_mk,
            on_mk:        (v) => { draft_mk = v },
            submit_label: 'rename',
            on_submit:    commit_rename_waft,
            on_cancel:    cancel_rename_waft,
        }
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
        const td   = ITEM_TYPES[t]
        const open = editing.has(item)
        return {
            label:        t,
            open,
            display:      item_to_display(item, t),
            mk_ph:        td.mk_ph,
            sc_ph:        td.sc_ph,
            mainkey:      open ? draft_mk : '',
            on_mk:        (v: string) => { draft_mk = v },
            sc_str:       open ? draft_sc : '',
            on_sc:        (v: string) => { draft_sc = v },
            focus_sc:     open ? draft_focus_sc : false,
            submit_label: '✓',
            on_open:      () => td.on_open(item as any, dpath),
            on_submit:    () => submit_edit(container, item),
            on_cancel:    () => cancel_edit(item),
            on_edit:      () => start_edit(item, t),
            on_del:       () => delete_item(item, container),
            on_add:       td.can_add ? () => toggle_add_pick(item) : undefined,
        }
    }

    function add_item_props(container: TheC): PiProps {
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
            on_cancel:    () => cancel_add(container),
        }
    }
</script>

<div class="ls-waft" style="margin-left: {depth * 14}px" class:ls-waft-active={is_active}>

    <!-- Waft header row — rename (via pi) or idle -->
    <div class="ls-waft-hdr">
        {#if editing.has(waft) && !add_type_C.has(waft)}
            {@render pi(waft_rename_props())}
        {:else}
            Waft:
            <span class="ls-waft-key">{wkey}</span>
            <span class="ls-spacer"></span>
            <button class="ls-icon-btn ls-active-btn" class:ls-is-active={is_active}
                    title={is_active ? 'active' : 'set active'}
                    onclick={() => on_active(waft)}>{is_active ? '●' : '○'}</button>
            <button class="ls-icon-btn" title="rename Waft"
                    onclick={start_rename_waft}>✎</button>
            <button class="ls-icon-btn ls-del-btn" title="delete Waft"
                    onclick={() => on_delete(waft)}>×</button>
            <button class="ls-icon-btn ls-add-btn-icon" title="add child"
                    onclick={() => toggle_add_pick(waft)}>+</button>
        {/if}
    </div>

    {#if waft_mungs.length || waft.oa({ encode_error: 1 })}
        <EncodingSplatter {waft} />
    {/if}

    <!-- Waft-level add picker + form -->
    {#if add_picking_C.has(waft)}
        {@render type_picker(waft, ['What', 'Doc', 'Point'])}
    {/if}
    {#if editing.has(waft) && add_type_C.has(waft)}
        <div class="ls-add-row">{@render pi(add_item_props(waft))}</div>
    {/if}

    <!-- children — all types rendered indifferently through waftitem -->
    {#each waft_children as child (child)}
        {@render waftitem(child, waft)}
    {/each}

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
        display={p.display}
        mk_ph={p.mk_ph}
        sc_ph={p.sc_ph}
        mainkey={p.mainkey}
        on_mk={p.on_mk}
        sc_str={p.sc_str}
        on_sc={p.on_sc}
        focus_sc={p.focus_sc}
        submit_label={p.submit_label}
        on_open={p.on_open}
        on_submit={p.on_submit}
        on_cancel={p.on_cancel}
        on_edit={p.on_edit}
        on_del={p.on_del}
        on_add={p.on_add} />
{/snippet}

<!-- type_picker — type button row before a new child type is chosen -->
{#snippet type_picker(container: TheC, types: ItemType[])}
    <div class="ls-type-picker">
        {#each types as t (t)}
            <button class="ls-pick-btn" onclick={() => pick_and_open(container, t)}>{t}</button>
        {/each}
        <button class="ls-cancel-btn" onclick={() => add_picking_C.delete(container)}>cancel</button>
    </div>
{/snippet}

<!-- waftitem — the one wrapper for every Point/Doc/What in the tree.
     Detects type from C.sc mainkey, reads C.o({}) for children,
     renders .ls-item / .ls-item-hdr / .ls-items.
     All per-type personality (CSS, child_types, spotlight) comes from ITEM_TYPES.
     upC is the containing C — used for edit/delete keying and Doc dpath. -->
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
                {#if add_picking_C.has(C)}
                    {@render type_picker(C, td.child_types)}
                {/if}
                {#if editing.has(C) && add_type_C.has(C)}
                    <div class="ls-add-row">{@render pi(add_item_props(C))}</div>
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
    .ls-waft-hdr {
        display: flex; align-items: center; gap: 0.25rem;
        min-height: 1.4rem; margin-bottom: 0.2rem;
    }
    .ls-waft-key { font-family: monospace; font-size: 0.76rem; color: #8ab; font-weight: bold }
    .ls-spacer   { flex: 1 }

    .ls-active-btn              { color: #446; font-size: 0.7rem }
    .ls-active-btn.ls-is-active { color: #88c }
    .ls-active-btn:hover        { color: #88c }

    /* shared item wrapper */
    .ls-item { margin: 0.1rem 0; }
    .ls-item-hdr {
        display: flex; align-items: center; gap: 0.2rem; min-height: 1.4rem;
    }
    /* PeelInput fills the header row so cancel reaches the right edge */
    .ls-item-hdr :global(.pi-row) { flex: 1; min-width: 0; }
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
    /* What label brighter than the muted Doc/Point default */
    .ls-item-what > .ls-item-hdr :global(.pi-label) { color: #7a8fa8; }
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

    .ls-add-btn {
        background: #1a1a2a; border: 1px solid #334; border-radius: 3px;
        color: #88a; cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.4rem;
        white-space: nowrap; flex-shrink: 0;
    }
    .ls-add-btn:hover    { background: #222238; color: #aac }
    .ls-add-btn:disabled { opacity: 0.35; cursor: default }
    .ls-add-btn-icon { color: #448; font-size: 0.8rem }
    .ls-add-btn-icon:hover { color: #88a }

    .ls-cancel-btn {
        background: none; border: none; color: #555;
        cursor: pointer; font-size: 0.76rem; padding: 0.2rem 0.3rem;
    }
    .ls-cancel-btn:hover  { color: #999 }
    .ls-cancel-right { margin-left: auto }

    :global(.ls-icon-btn) {
        background: none; border: none; color: #444;
        cursor: pointer; font-size: 0.8rem; line-height: 1;
        padding: 0 0.15rem; flex-shrink: 0;
    }
    :global(.ls-icon-btn:hover) { color: #aaa }
    :global(.ls-del-btn:hover)  { color: #f66 }

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
